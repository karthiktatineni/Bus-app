-- Harden role boundaries and define tenant-scoped access to private media.
CREATE INDEX IF NOT EXISTS vehicles_company_active_idx ON public.vehicles(company_id, registration_no) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS tasks_company_due_idx ON public.maintenance_tasks(company_id, due_date) WHERE is_done = false;
CREATE INDEX IF NOT EXISTS documents_company_expiry_idx ON public.vehicle_documents(company_id, expiry_date);
CREATE INDEX IF NOT EXISTS services_company_date_idx ON public.service_records(company_id, date DESC);
CREATE INDEX IF NOT EXISTS notifications_user_unread_idx ON public.notifications(user_id, created_at DESC) WHERE read_at IS NULL;

-- Activate invited profiles after the user accepts the Supabase Auth invite.
CREATE OR REPLACE FUNCTION public.activate_confirmed_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    UPDATE public.profiles SET status = 'active', updated_at = now()
    WHERE id = NEW.id AND status = 'invited';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_activate_confirmed_profile ON auth.users;
CREATE TRIGGER trg_activate_confirmed_profile AFTER UPDATE OF email_confirmed_at ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.activate_confirmed_profile();

-- A user cannot create a profile in an arbitrary tenant or promote their own role.
DROP POLICY IF EXISTS profiles_insert ON public.profiles;
DROP POLICY IF EXISTS profiles_update ON public.profiles;
CREATE POLICY profiles_admin_insert ON public.profiles FOR INSERT
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY profiles_admin_update ON public.profiles FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY profiles_admin_delete ON public.profiles FOR DELETE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS service_records_insert ON public.service_records;
CREATE POLICY service_records_insert ON public.service_records FOR INSERT
  WITH CHECK (company_id = public.get_auth_company_id() AND created_by = auth.uid());

-- Read-only vehicle metadata for staff; writes require an active company admin.
DROP POLICY IF EXISTS vehicle_documents_all ON public.vehicle_documents;
CREATE POLICY vehicle_documents_select ON public.vehicle_documents FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY vehicle_documents_admin_write ON public.vehicle_documents FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
DROP POLICY IF EXISTS vehicle_photos_all ON public.vehicle_photos;
CREATE POLICY vehicle_photos_select ON public.vehicle_photos FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY vehicle_photos_admin_write ON public.vehicle_photos FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
DROP POLICY IF EXISTS service_schedules_all ON public.service_schedules;
CREATE POLICY service_schedules_select ON public.service_schedules FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY service_schedules_admin_write ON public.service_schedules FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- Staff can read tasks and change only completion fields.
DROP POLICY IF EXISTS maintenance_tasks_all ON public.maintenance_tasks;
CREATE POLICY tasks_select ON public.maintenance_tasks FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY tasks_admin_write ON public.maintenance_tasks FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY tasks_staff_complete ON public.maintenance_tasks FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND NOT public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND NOT public.is_auth_admin());
REVOKE UPDATE ON public.maintenance_tasks FROM authenticated;
GRANT UPDATE (is_done, completed_at, completed_by) ON public.maintenance_tasks TO authenticated;

DROP POLICY IF EXISTS service_parts_all ON public.service_parts;
CREATE POLICY service_parts_select ON public.service_parts FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY service_parts_insert ON public.service_parts FOR INSERT
  WITH CHECK (company_id = public.get_auth_company_id());
CREATE POLICY service_parts_admin_update ON public.service_parts FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY service_parts_admin_delete ON public.service_parts FOR DELETE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS service_photos_all ON public.service_photos;
CREATE POLICY service_photos_select ON public.service_photos FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY service_photos_insert ON public.service_photos FOR INSERT
  WITH CHECK (company_id = public.get_auth_company_id());
CREATE POLICY service_photos_admin_update ON public.service_photos FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY service_photos_admin_delete ON public.service_photos FOR DELETE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS bills_all ON public.bills;
CREATE POLICY bills_select ON public.bills FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY bills_admin_write ON public.bills FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
DROP POLICY IF EXISTS bill_items_all ON public.bill_items;
CREATE POLICY bill_items_select ON public.bill_items FOR SELECT
  USING (company_id = public.get_auth_company_id());
CREATE POLICY bill_items_admin_write ON public.bill_items FOR ALL
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- The profile_id/tenant relationship stays server controlled; users may only write own prefs.
DROP POLICY IF EXISTS user_settings_all ON public.user_settings;
CREATE POLICY user_settings_self ON public.user_settings FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS company_settings_update ON public.company_settings;
CREATE POLICY company_settings_update ON public.company_settings FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- DELETE requests become audited soft deletes; restore is a controlled admin update.
CREATE OR REPLACE FUNCTION public.soft_delete_vehicle()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.vehicles SET deleted_at = now(), updated_at = now() WHERE id = OLD.id;
  INSERT INTO public.audit_log(company_id, user_id, action, resource_type, resource_id, details)
  VALUES (OLD.company_id, auth.uid(), 'soft_delete', 'vehicle', OLD.id::text,
    jsonb_build_object('registration_no', OLD.registration_no));
  RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS trg_soft_delete_vehicle ON public.vehicles;
CREATE TRIGGER trg_soft_delete_vehicle BEFORE DELETE ON public.vehicles
FOR EACH ROW EXECUTE FUNCTION public.soft_delete_vehicle();

INSERT INTO storage.buckets(id, name, public)
VALUES ('vehicle-photos','vehicle-photos',false), ('service-photos','service-photos',false),
       ('bills','bills',false), ('avatars','avatars',false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS fleet_media_read ON storage.objects;
CREATE POLICY fleet_media_read ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text);
DROP POLICY IF EXISTS fleet_media_insert ON storage.objects;
CREATE POLICY fleet_media_insert ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text);
DROP POLICY IF EXISTS fleet_media_update ON storage.objects;
CREATE POLICY fleet_media_update ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text)
  WITH CHECK (bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text);
DROP POLICY IF EXISTS fleet_media_delete ON storage.objects;
CREATE POLICY fleet_media_delete ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text AND public.is_auth_admin());

REVOKE ALL ON FUNCTION public.rpc_get_fleet_summary() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_query_vehicle_status(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_due_maintenance(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_expiring_documents(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rpc_get_cost_breakdown(date,date,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_get_fleet_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_query_vehicle_status(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_due_maintenance(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_expiring_documents(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_cost_breakdown(date,date,uuid) TO authenticated;
