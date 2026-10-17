-- Preserve historical fleet records while allowing their Auth users to be deleted.
DO $$
DECLARE
  fk record;
BEGIN
  FOR fk IN
    SELECT c.conrelid::regclass AS table_name, c.conname AS constraint_name,
           a.attname AS column_name
    FROM pg_constraint c
    JOIN LATERAL unnest(c.conkey) AS key_column(attnum) ON true
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = key_column.attnum
    WHERE c.contype = 'f'
      AND c.confrelid = 'public.profiles'::regclass
      AND c.confdeltype <> 'n'
      AND array_length(c.conkey, 1) = 1
      AND a.attname IN ('created_by', 'completed_by')
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', fk.table_name, fk.constraint_name);
    EXECUTE format(
      'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.profiles(id) ON DELETE SET NULL',
      fk.table_name, fk.constraint_name, fk.column_name
    );
  END LOOP;
END;
$$;

-- Supabase Storage can restrict Auth deletion while objects still name that user as owner.
-- Reassign object ownership to the same-company admin performing the deletion; paths and
-- contents remain unchanged. This RPC is callable only with the server service-role key.
CREATE OR REPLACE FUNCTION public.rpc_transfer_user_storage_ownership(
  p_user_id uuid,
  p_new_owner_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  owner_column_type text;
BEGIN
  IF p_user_id IS NULL OR p_new_owner_id IS NULL OR p_user_id = p_new_owner_id THEN
    RAISE EXCEPTION 'Valid distinct user ids are required.';
  END IF;

  SELECT data_type INTO owner_column_type
  FROM information_schema.columns
  WHERE table_schema = 'storage' AND table_name = 'objects' AND column_name = 'owner_id';

  IF owner_column_type = 'uuid' THEN
    EXECUTE 'UPDATE storage.objects SET owner_id = $1 WHERE owner_id = $2'
      USING p_new_owner_id, p_user_id;
    RETURN;
  ELSIF owner_column_type IS NOT NULL THEN
    EXECUTE 'UPDATE storage.objects SET owner_id = $1::text WHERE owner_id = $2::text'
      USING p_new_owner_id, p_user_id;
    RETURN;
  END IF;

  SELECT data_type INTO owner_column_type
  FROM information_schema.columns
  WHERE table_schema = 'storage' AND table_name = 'objects' AND column_name = 'owner';

  IF owner_column_type = 'uuid' THEN
    EXECUTE 'UPDATE storage.objects SET owner = $1 WHERE owner = $2'
      USING p_new_owner_id, p_user_id;
  ELSIF owner_column_type IS NOT NULL THEN
    EXECUTE 'UPDATE storage.objects SET owner = $1::text WHERE owner = $2::text'
      USING p_new_owner_id, p_user_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.rpc_transfer_user_storage_ownership(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_transfer_user_storage_ownership(uuid, uuid)
  TO service_role;
