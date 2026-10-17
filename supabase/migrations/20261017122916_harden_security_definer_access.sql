-- Tighten callable privileges and pin search_path on every public SECURITY DEFINER
-- function.  The old rpc_bootstrap_company RPC is unused by the app; the deployed
-- bootstrap Edge Function is the only supported bootstrap path.

CREATE OR REPLACE FUNCTION public.get_auth_company_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT p.company_id
  FROM public.profiles AS p
  WHERE p.id = auth.uid()
    AND p.status = 'active';
$$;

CREATE OR REPLACE FUNCTION public.is_auth_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
      AND p.status = 'active'
  );
$$;

ALTER FUNCTION public.set_updated_at() SET search_path = pg_catalog, public;
ALTER FUNCTION public.activate_confirmed_profile() SET search_path = pg_catalog, public;
ALTER FUNCTION public.soft_delete_vehicle() SET search_path = pg_catalog, public;
ALTER FUNCTION public.on_service_record_created() SET search_path = pg_catalog, public;
ALTER FUNCTION public.bump_company_cache_generation() SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_get_fleet_summary() SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_query_vehicle_status(text) SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_get_due_maintenance(integer) SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_get_expiring_documents(integer) SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_get_cost_breakdown(date, date, uuid) SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_get_cache_generation() SET search_path = pg_catalog, public;
ALTER FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer)
  SET search_path = pg_catalog, public, extensions;
ALTER FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector)
  SET search_path = pg_catalog, public, extensions;
-- These two legacy functions are present in the linked project but not created by
-- this repository's baseline migration. Guard them so fresh installs also migrate.
DO $$
BEGIN
  IF to_regprocedure('public.rls_auto_enable()') IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.rls_auto_enable() SET search_path = pg_catalog';
  END IF;
  IF to_regprocedure('public.rpc_bootstrap_company(text,uuid,text,text)') IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.rpc_bootstrap_company(text, uuid, text, text) SET search_path = pg_catalog, public';
  END IF;
END;
$$;

-- Tenant helpers are invoked by authenticated RLS policies, never by anonymous callers.
REVOKE ALL ON FUNCTION public.get_auth_company_id() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_auth_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_auth_company_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_auth_admin() TO authenticated;

-- These functions run only as installed triggers/event triggers.  They are not API RPCs.
REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.activate_confirmed_profile() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.soft_delete_vehicle() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_service_record_created() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.bump_company_cache_generation() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO service_role;
GRANT EXECUTE ON FUNCTION public.activate_confirmed_profile() TO service_role;
GRANT EXECUTE ON FUNCTION public.soft_delete_vehicle() TO service_role;
GRANT EXECUTE ON FUNCTION public.on_service_record_created() TO service_role;
GRANT EXECUTE ON FUNCTION public.bump_company_cache_generation() TO service_role;
DO $$
BEGIN
  IF to_regprocedure('public.rls_auto_enable()') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO service_role';
  END IF;
END;
$$;

-- This legacy SECURITY DEFINER RPC could create a company and assign an arbitrary
-- auth user as its active admin.  Bootstrap now happens only in the guarded Edge Function.
DO $$
BEGIN
  IF to_regprocedure('public.rpc_bootstrap_company(text,uuid,text,text)') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.rpc_bootstrap_company(text, uuid, text, text) FROM PUBLIC, anon, authenticated, service_role';
  END IF;
END;
$$;

-- Keep operational reads and RAG search authenticated and tenant-scoped.
REVOKE ALL ON FUNCTION public.rpc_get_fleet_summary() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_query_vehicle_status(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_due_maintenance(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_expiring_documents(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_cost_breakdown(date, date, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_cache_generation() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_fleet_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_query_vehicle_status(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_due_maintenance(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_expiring_documents(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_cost_breakdown(date, date, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_cache_generation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_search_fleet_knowledge(extensions.vector, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_ingest_fleet_knowledge(uuid, text, text, extensions.vector) TO service_role;

DO $$
BEGIN
  IF to_regprocedure('public.rpc_bootstrap_company(text,uuid,text,text)') IS NOT NULL
     AND has_function_privilege('anon', 'public.rpc_bootstrap_company(text,uuid,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous access to legacy rpc_bootstrap_company remains enabled';
  END IF;
  IF to_regprocedure('public.rpc_bootstrap_company(text,uuid,text,text)') IS NOT NULL
     AND has_function_privilege('authenticated', 'public.rpc_bootstrap_company(text,uuid,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated access to legacy rpc_bootstrap_company remains enabled';
  END IF;
  IF has_function_privilege('anon', 'public.get_auth_company_id()', 'EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous access to get_auth_company_id remains enabled';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.get_auth_company_id()', 'EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated RLS helper access was removed';
  END IF;
END;
$$;
