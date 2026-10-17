-- NVIDIA's currently supported nvidia/nemotron-3-embed-1b endpoint returns
-- 2048-dimensional vectors. pgvector limits indexed vector columns to 2,000
-- dimensions, so store/index this corpus as halfvec(2048), which supports up
-- to 4,000 dimensions. Preserve the old corpus and records unchanged.
CREATE TABLE IF NOT EXISTS public.fleet_knowledge_chunks_v2 (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
  source_name text NOT NULL,
  chunk_text text NOT NULL,
  embedding extensions.halfvec(2048) NOT NULL,
  content_key text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS fleet_knowledge_chunks_v2_embedding_idx
  ON public.fleet_knowledge_chunks_v2 USING hnsw (embedding extensions.halfvec_cosine_ops);
CREATE INDEX IF NOT EXISTS fleet_knowledge_chunks_v2_company_idx
  ON public.fleet_knowledge_chunks_v2(company_id);
ALTER TABLE public.fleet_knowledge_chunks_v2 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.fleet_knowledge_chunks_v2 FROM PUBLIC, anon, authenticated;

-- PostgreSQL identifies vector overloads without the typmod, so drop the old
-- 1024-dimension signatures before recreating the same RPC names at 2048.
DROP FUNCTION IF EXISTS public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector);
CREATE FUNCTION public.rpc_ingest_fleet_knowledge(
  p_company_id uuid, p_source_name text, p_chunk_text text, p_embedding extensions.vector(2048)
) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  INSERT INTO public.fleet_knowledge_chunks_v2(company_id, source_name, chunk_text, embedding, content_key)
  VALUES (p_company_id, left(p_source_name, 300), left(p_chunk_text, 10000),
    p_embedding::extensions.halfvec(2048),
    md5(COALESCE(p_company_id::text, 'shared') || '|' || p_source_name || '|' || p_chunk_text))
  ON CONFLICT (content_key) DO UPDATE
    SET embedding = EXCLUDED.embedding, chunk_text = EXCLUDED.chunk_text;
$$;
REVOKE ALL ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector)
  TO service_role;

DROP FUNCTION IF EXISTS public.rpc_search_fleet_knowledge(extensions.vector, integer);
CREATE FUNCTION public.rpc_search_fleet_knowledge(
  p_embedding extensions.vector(2048), p_limit integer DEFAULT 5
) RETURNS TABLE(source_name text, chunk_text text, similarity double precision)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT k.source_name, k.chunk_text,
    (1 - (k.embedding <=> p_embedding::extensions.halfvec(2048)))::double precision AS similarity
  FROM public.fleet_knowledge_chunks_v2 k
  JOIN public.profiles p ON p.id = auth.uid()
  WHERE p.status = 'active'
    AND (k.company_id IS NULL OR k.company_id = p.company_id)
  ORDER BY k.embedding <=> p_embedding::extensions.halfvec(2048)
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 5), 1), 10);
$$;
REVOKE ALL ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer)
  TO authenticated;
