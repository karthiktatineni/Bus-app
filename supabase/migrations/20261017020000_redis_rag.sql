-- Tenant-aware cache generations invalidate Redis entries after committed writes.
CREATE TABLE IF NOT EXISTS public.company_cache_generations (
  company_id uuid PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
  generation bigint NOT NULL DEFAULT 1
);
ALTER TABLE public.company_cache_generations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.company_cache_generations FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.bump_company_cache_generation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE cid uuid;
BEGIN
  cid := CASE WHEN TG_OP = 'DELETE' THEN OLD.company_id ELSE NEW.company_id END;
  INSERT INTO public.company_cache_generations(company_id, generation) VALUES (cid, 2)
  ON CONFLICT (company_id) DO UPDATE SET generation = public.company_cache_generations.generation + 1;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['vehicles','vehicle_documents','maintenance_tasks','service_records','service_parts','bills','bill_items'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_bump_company_cache_generation ON public.%I', tbl);
    EXECUTE format('CREATE TRIGGER trg_bump_company_cache_generation AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.bump_company_cache_generation()', tbl);
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_get_cache_generation()
RETURNS bigint LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE((SELECT g.generation FROM public.company_cache_generations g
    JOIN public.profiles p ON p.company_id = g.company_id
    WHERE p.id = auth.uid() AND p.status = 'active'), 1);
$$;
REVOKE ALL ON FUNCTION public.rpc_get_cache_generation() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_get_cache_generation() TO authenticated;

-- RAG corpus: only authorized company content or explicitly shared public manuals are returned.
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
CREATE TABLE IF NOT EXISTS public.fleet_knowledge_chunks (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
  source_name text NOT NULL,
  chunk_text text NOT NULL,
  embedding extensions.vector(1024) NOT NULL,
  content_key text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS fleet_knowledge_chunks_embedding_idx
  ON public.fleet_knowledge_chunks USING hnsw (embedding extensions.vector_cosine_ops);
CREATE INDEX IF NOT EXISTS fleet_knowledge_chunks_company_idx
  ON public.fleet_knowledge_chunks(company_id);
ALTER TABLE public.fleet_knowledge_chunks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.fleet_knowledge_chunks FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.rpc_ingest_fleet_knowledge(
  p_company_id uuid, p_source_name text, p_chunk_text text, p_embedding extensions.vector(1024)
) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions AS $$
  INSERT INTO public.fleet_knowledge_chunks(company_id, source_name, chunk_text, embedding, content_key)
  VALUES (p_company_id, left(p_source_name, 300), left(p_chunk_text, 10000), p_embedding,
    md5(COALESCE(p_company_id::text, 'shared') || '|' || p_source_name || '|' || p_chunk_text))
  ON CONFLICT (content_key) DO UPDATE SET embedding = EXCLUDED.embedding, chunk_text = EXCLUDED.chunk_text;
$$;
REVOKE ALL ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector) TO service_role;

CREATE OR REPLACE FUNCTION public.rpc_search_fleet_knowledge(p_embedding extensions.vector(1024), p_limit integer DEFAULT 5)
RETURNS TABLE(source_name text, chunk_text text, similarity double precision)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
  SELECT k.source_name, k.chunk_text, (1 - (k.embedding <=> p_embedding))::double precision AS similarity
  FROM public.fleet_knowledge_chunks k
  JOIN public.profiles p ON p.id = auth.uid()
  WHERE p.id = auth.uid() AND p.status = 'active'
    AND (k.company_id IS NULL OR k.company_id = p.company_id)
  ORDER BY k.embedding <=> p_embedding
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 5), 1), 10);
$$;
REVOKE ALL ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer) TO authenticated;
