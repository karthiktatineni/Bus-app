-- Staff may submit bills and their extracted line items for their own company.
-- Only administrators may modify or delete submitted billing data.

DROP POLICY IF EXISTS bills_admin_write ON public.bills;
DROP POLICY IF EXISTS bills_insert ON public.bills;
DROP POLICY IF EXISTS bills_admin_update ON public.bills;
DROP POLICY IF EXISTS bills_admin_delete ON public.bills;

CREATE POLICY bills_insert ON public.bills FOR INSERT
  WITH CHECK (
    company_id = public.get_auth_company_id()
    AND created_by = auth.uid()
  );
CREATE POLICY bills_admin_update ON public.bills FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY bills_admin_delete ON public.bills FOR DELETE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS bill_items_admin_write ON public.bill_items;
DROP POLICY IF EXISTS bill_items_insert ON public.bill_items;
DROP POLICY IF EXISTS bill_items_admin_update ON public.bill_items;
DROP POLICY IF EXISTS bill_items_admin_delete ON public.bill_items;

CREATE POLICY bill_items_insert ON public.bill_items FOR INSERT
  WITH CHECK (
    company_id = public.get_auth_company_id()
    AND EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = bill_id
        AND b.company_id = public.get_auth_company_id()
        AND b.created_by = auth.uid()
    )
  );
CREATE POLICY bill_items_admin_update ON public.bill_items FOR UPDATE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin())
  WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());
CREATE POLICY bill_items_admin_delete ON public.bill_items FOR DELETE
  USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- New uploads remain available to company staff; replacing an existing object is admin-only.
DROP POLICY IF EXISTS fleet_media_update ON storage.objects;
CREATE POLICY fleet_media_update ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text
    AND public.is_auth_admin()
  )
  WITH CHECK (
    bucket_id IN ('vehicle-photos','service-photos','bills','avatars')
    AND (storage.foldername(name))[1] = public.get_auth_company_id()::text
    AND public.is_auth_admin()
  );
