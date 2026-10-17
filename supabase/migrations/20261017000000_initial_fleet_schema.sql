-- 20261017000000_initial_fleet_schema.sql
-- FleetPulse Fleet Maintenance & Intelligence Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. COMPANIES
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    logo_url TEXT,
    default_reminder_lead_days INT NOT NULL DEFAULT 14,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'invited')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. VEHICLES
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    registration_no TEXT NOT NULL,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INT NOT NULL,
    chassis_no TEXT,
    engine_no TEXT,
    seats INT,
    fuel_type TEXT DEFAULT 'Diesel',
    odometer_km INT NOT NULL DEFAULT 0,
    depot TEXT,
    purchase_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'due_soon', 'overdue', 'in_workshop')),
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_company_reg_no UNIQUE(company_id, registration_no)
);

-- 4. VEHICLE DOCUMENTS
CREATE TABLE IF NOT EXISTS public.vehicle_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('insurance', 'fitness', 'permit', 'puc')),
    number TEXT NOT NULL,
    expiry_date DATE NOT NULL,
    file_url TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. VEHICLE PHOTOS
CREATE TABLE IF NOT EXISTS public.vehicle_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    caption TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. SERVICE SCHEDULES
CREATE TABLE IF NOT EXISTS public.service_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    task_name TEXT NOT NULL,
    interval_km INT,
    interval_months INT,
    last_done_date DATE,
    last_done_km INT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. MAINTENANCE TASKS
CREATE TABLE IF NOT EXISTS public.maintenance_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    schedule_id UUID REFERENCES public.service_schedules(id) ON DELETE SET NULL,
    service_record_id UUID,
    title TEXT NOT NULL,
    due_date DATE,
    due_km INT,
    is_done BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    completed_by UUID REFERENCES public.profiles(id),
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. SERVICE RECORDS
CREATE TABLE IF NOT EXISTS public.service_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    odometer_km INT NOT NULL,
    workshop TEXT NOT NULL,
    mechanic TEXT,
    notes TEXT,
    labour_cost NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    tax NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. SERVICE PARTS
CREATE TABLE IF NOT EXISTS public.service_parts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    service_record_id UUID NOT NULL REFERENCES public.service_records(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    qty NUMERIC(10,2) NOT NULL DEFAULT 1.0,
    cost NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10. SERVICE PHOTOS
CREATE TABLE IF NOT EXISTS public.service_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    service_record_id UUID NOT NULL REFERENCES public.service_records(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('before', 'after', 'part', 'bill')),
    caption TEXT,
    part_id UUID REFERENCES public.service_parts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11. BILLS
CREATE TABLE IF NOT EXISTS public.bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.service_records(id) ON DELETE SET NULL,
    vendor TEXT NOT NULL,
    bill_no TEXT,
    bill_date DATE NOT NULL DEFAULT CURRENT_DATE,
    tax NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    image_url TEXT,
    ocr_confidence NUMERIC(4,3),
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 12. BILL ITEMS
CREATE TABLE IF NOT EXISTS public.bill_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    bill_id UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    qty NUMERIC(10,2) NOT NULL DEFAULT 1.0,
    cost NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 13. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    link_target TEXT,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 14. USER SETTINGS
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    theme_mode TEXT NOT NULL DEFAULT 'system',
    distance_unit TEXT NOT NULL DEFAULT 'km',
    currency TEXT NOT NULL DEFAULT 'INR',
    date_format TEXT NOT NULL DEFAULT 'dd MMM yyyy',
    service_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    service_reminders_lead_days INT NOT NULL DEFAULT 14,
    doc_expiry_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    doc_expiry_reminders_lead_days INT NOT NULL DEFAULT 15,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 15. COMPANY SETTINGS
CREATE TABLE IF NOT EXISTS public.company_settings (
    company_id UUID PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
    default_reminder_lead_days INT NOT NULL DEFAULT 14,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 16. AUDIT LOG
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- HELPER FUNCTIONS & TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_auth_company_id()
RETURNS UUID AS $$
    SELECT company_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_auth_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Trigger: auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    tbl text;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['companies', 'profiles', 'vehicles', 'vehicle_documents', 'service_schedules', 'maintenance_tasks', 'service_records', 'bills', 'user_settings', 'company_settings']
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON public.%I', tbl);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()', tbl);
    END LOOP;
END;
$$;

-- Trigger: when service_record is created, update vehicle odometer, advance schedule, complete matching task
CREATE OR REPLACE FUNCTION public.on_service_record_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Update vehicle odometer if service odometer is higher
    UPDATE public.vehicles
    SET odometer_km = GREATEST(odometer_km, NEW.odometer_km),
        status = CASE WHEN status = 'in_workshop' THEN 'active' ELSE status END,
        updated_at = now()
    WHERE id = NEW.vehicle_id;

    -- Update matching schedule
    UPDATE public.service_schedules
    SET last_done_date = NEW.date,
        last_done_km = NEW.odometer_km,
        updated_at = now()
    WHERE vehicle_id = NEW.vehicle_id AND task_name ILIKE ('%' || NEW.type || '%');

    -- Mark matching open tasks as done
    UPDATE public.maintenance_tasks
    SET is_done = true,
        completed_at = now(),
        completed_by = NEW.created_by,
        service_record_id = NEW.id,
        updated_at = now()
    WHERE vehicle_id = NEW.vehicle_id AND is_done = false AND title ILIKE ('%' || NEW.type || '%');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_service_record_created ON public.service_records;
CREATE TRIGGER trg_service_record_created
AFTER INSERT ON public.service_records
FOR EACH ROW EXECUTE FUNCTION public.on_service_record_created();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

DO $$
DECLARE
    tbl text;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'companies', 'profiles', 'vehicles', 'vehicle_documents', 'vehicle_photos',
        'service_schedules', 'maintenance_tasks', 'service_records', 'service_parts',
        'service_photos', 'bills', 'bill_items', 'notifications', 'user_settings',
        'company_settings', 'audit_log'
    ]
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
    END LOOP;
END;
$$;

-- Companies: Members can read their company, only admins can update
DROP POLICY IF EXISTS "company_select" ON public.companies;
CREATE POLICY "company_select" ON public.companies FOR SELECT
    USING (id = public.get_auth_company_id());

DROP POLICY IF EXISTS "company_update" ON public.companies;
CREATE POLICY "company_update" ON public.companies FOR UPDATE
    USING (id = public.get_auth_company_id() AND public.is_auth_admin());

-- Profiles: Members can view profiles in company, admin can manage
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT
    USING (company_id = public.get_auth_company_id());

DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT
    WITH CHECK (company_id = public.get_auth_company_id() AND (public.is_auth_admin() OR auth.uid() = id));

DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE
    USING (company_id = public.get_auth_company_id() AND (public.is_auth_admin() OR auth.uid() = id));

-- Generic policy helper for company tenant tables
-- Vehicles:
DROP POLICY IF EXISTS "vehicles_select" ON public.vehicles;
CREATE POLICY "vehicles_select" ON public.vehicles FOR SELECT
    USING (company_id = public.get_auth_company_id() AND deleted_at IS NULL);

DROP POLICY IF EXISTS "vehicles_insert" ON public.vehicles;
CREATE POLICY "vehicles_insert" ON public.vehicles FOR INSERT
    WITH CHECK (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS "vehicles_update" ON public.vehicles;
CREATE POLICY "vehicles_update" ON public.vehicles FOR UPDATE
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS "vehicles_delete" ON public.vehicles;
CREATE POLICY "vehicles_delete" ON public.vehicles FOR DELETE
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- Vehicle Documents:
DROP POLICY IF EXISTS "vehicle_documents_all" ON public.vehicle_documents;
CREATE POLICY "vehicle_documents_all" ON public.vehicle_documents FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Vehicle Photos:
DROP POLICY IF EXISTS "vehicle_photos_all" ON public.vehicle_photos;
CREATE POLICY "vehicle_photos_all" ON public.vehicle_photos FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Service Schedules:
DROP POLICY IF EXISTS "service_schedules_all" ON public.service_schedules;
CREATE POLICY "service_schedules_all" ON public.service_schedules FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Maintenance Tasks:
DROP POLICY IF EXISTS "maintenance_tasks_all" ON public.maintenance_tasks;
CREATE POLICY "maintenance_tasks_all" ON public.maintenance_tasks FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Service Records:
DROP POLICY IF EXISTS "service_records_select" ON public.service_records;
CREATE POLICY "service_records_select" ON public.service_records FOR SELECT
    USING (company_id = public.get_auth_company_id());

DROP POLICY IF EXISTS "service_records_insert" ON public.service_records;
CREATE POLICY "service_records_insert" ON public.service_records FOR INSERT
    WITH CHECK (company_id = public.get_auth_company_id());

DROP POLICY IF EXISTS "service_records_modify" ON public.service_records;
CREATE POLICY "service_records_modify" ON public.service_records FOR UPDATE
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

DROP POLICY IF EXISTS "service_records_delete" ON public.service_records;
CREATE POLICY "service_records_delete" ON public.service_records FOR DELETE
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- Service Parts:
DROP POLICY IF EXISTS "service_parts_all" ON public.service_parts;
CREATE POLICY "service_parts_all" ON public.service_parts FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Service Photos:
DROP POLICY IF EXISTS "service_photos_all" ON public.service_photos;
CREATE POLICY "service_photos_all" ON public.service_photos FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Bills & Items:
DROP POLICY IF EXISTS "bills_all" ON public.bills;
CREATE POLICY "bills_all" ON public.bills FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

DROP POLICY IF EXISTS "bill_items_all" ON public.bill_items;
CREATE POLICY "bill_items_all" ON public.bill_items FOR ALL
    USING (company_id = public.get_auth_company_id())
    WITH CHECK (company_id = public.get_auth_company_id());

-- Notifications:
DROP POLICY IF EXISTS "notifications_all" ON public.notifications;
CREATE POLICY "notifications_all" ON public.notifications FOR ALL
    USING (company_id = public.get_auth_company_id() AND user_id = auth.uid())
    WITH CHECK (company_id = public.get_auth_company_id() AND user_id = auth.uid());

-- User Settings:
DROP POLICY IF EXISTS "user_settings_all" ON public.user_settings;
CREATE POLICY "user_settings_all" ON public.user_settings FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Company Settings:
DROP POLICY IF EXISTS "company_settings_select" ON public.company_settings;
CREATE POLICY "company_settings_select" ON public.company_settings FOR SELECT
    USING (company_id = public.get_auth_company_id());

DROP POLICY IF EXISTS "company_settings_update" ON public.company_settings;
CREATE POLICY "company_settings_update" ON public.company_settings FOR UPDATE
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- Audit Log:
DROP POLICY IF EXISTS "audit_log_select" ON public.audit_log;
CREATE POLICY "audit_log_select" ON public.audit_log FOR SELECT
    USING (company_id = public.get_auth_company_id() AND public.is_auth_admin());

-- ============================================================================
-- LIVE DATABASE INSPECTION RPC FUNCTIONS (FOR 100% ACCURATE FLEET AI)
-- ============================================================================

-- 1. Fleet Summary
CREATE OR REPLACE FUNCTION public.rpc_get_fleet_summary()
RETURNS JSONB AS $$
DECLARE
    cid UUID;
    result JSONB;
BEGIN
    cid := public.get_auth_company_id();
    SELECT jsonb_build_object(
        'total_vehicles', (SELECT count(*) FROM public.vehicles WHERE company_id = cid AND deleted_at IS NULL),
        'active_vehicles', (SELECT count(*) FROM public.vehicles WHERE company_id = cid AND deleted_at IS NULL AND status = 'active'),
        'in_workshop', (SELECT count(*) FROM public.vehicles WHERE company_id = cid AND deleted_at IS NULL AND status = 'in_workshop'),
        'overdue_vehicles', (SELECT count(*) FROM public.vehicles WHERE company_id = cid AND deleted_at IS NULL AND status = 'overdue'),
        'tasks_due_14_days', (SELECT count(*) FROM public.maintenance_tasks WHERE company_id = cid AND is_done = false AND due_date <= CURRENT_DATE + interval '14 days'),
        'overdue_tasks', (SELECT count(*) FROM public.maintenance_tasks WHERE company_id = cid AND is_done = false AND due_date < CURRENT_DATE)
    ) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. Query Vehicle Status
CREATE OR REPLACE FUNCTION public.rpc_query_vehicle_status(search_query TEXT)
RETURNS JSONB AS $$
DECLARE
    cid UUID;
    result JSONB;
BEGIN
    cid := public.get_auth_company_id();
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', v.id,
            'registration_no', v.registration_no,
            'make_model', v.make || ' ' || v.model,
            'year', v.year,
            'odometer_km', v.odometer_km,
            'depot', v.depot,
            'status', v.status,
            'open_tasks', (
                SELECT jsonb_agg(jsonb_build_object('title', t.title, 'due_date', t.due_date, 'due_km', t.due_km))
                FROM public.maintenance_tasks t
                WHERE t.vehicle_id = v.id AND t.is_done = false
            ),
            'last_service', (
                SELECT jsonb_build_object('date', s.date, 'type', s.type, 'total', s.total, 'workshop', s.workshop)
                FROM public.service_records s
                WHERE s.vehicle_id = v.id
                ORDER BY s.date DESC LIMIT 1
            )
        )
    ) INTO result
    FROM public.vehicles v
    WHERE v.company_id = cid AND v.deleted_at IS NULL
      AND (v.registration_no ILIKE ('%' || search_query || '%') OR v.make ILIKE ('%' || search_query || '%') OR v.model ILIKE ('%' || search_query || '%') OR search_query = 'all');
    
    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3. Get Due Maintenance
CREATE OR REPLACE FUNCTION public.rpc_get_due_maintenance(days_ahead INT DEFAULT 14)
RETURNS JSONB AS $$
DECLARE
    cid UUID;
    result JSONB;
BEGIN
    cid := public.get_auth_company_id();
    SELECT jsonb_agg(
        jsonb_build_object(
            'task_id', t.id,
            'task_title', t.title,
            'due_date', t.due_date,
            'due_km', t.due_km,
            'is_overdue', (t.due_date < CURRENT_DATE),
            'vehicle_reg', v.registration_no,
            'vehicle_model', v.make || ' ' || v.model,
            'current_odometer', v.odometer_km
        ) ORDER BY t.due_date ASC
    ) INTO result
    FROM public.maintenance_tasks t
    JOIN public.vehicles v ON v.id = t.vehicle_id
    WHERE t.company_id = cid AND t.is_done = false
      AND (t.due_date <= CURRENT_DATE + (days_ahead || ' days')::interval OR t.due_date < CURRENT_DATE);

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 4. Get Expiring Documents
CREATE OR REPLACE FUNCTION public.rpc_get_expiring_documents(within_days INT DEFAULT 30)
RETURNS JSONB AS $$
DECLARE
    cid UUID;
    result JSONB;
BEGIN
    cid := public.get_auth_company_id();
    SELECT jsonb_agg(
        jsonb_build_object(
            'document_id', d.id,
            'vehicle_reg', v.registration_no,
            'type', d.type,
            'number', d.number,
            'expiry_date', d.expiry_date,
            'is_expired', (d.expiry_date < CURRENT_DATE),
            'days_remaining', (d.expiry_date - CURRENT_DATE)
        ) ORDER BY d.expiry_date ASC
    ) INTO result
    FROM public.vehicle_documents d
    JOIN public.vehicles v ON v.id = d.vehicle_id
    WHERE d.company_id = cid
      AND d.expiry_date <= CURRENT_DATE + (within_days || ' days')::interval;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5. Cost Breakdown Analytics
CREATE OR REPLACE FUNCTION public.rpc_get_cost_breakdown(start_date DATE, end_date DATE, p_vehicle_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
    cid UUID;
    result JSONB;
BEGIN
    cid := public.get_auth_company_id();
    SELECT jsonb_build_object(
        'total_spent', COALESCE(SUM(s.total), 0),
        'total_labour', COALESCE(SUM(s.labour_cost), 0),
        'total_tax', COALESCE(SUM(s.tax), 0),
        'services_count', count(s.id),
        'services', jsonb_agg(
            jsonb_build_object(
                'service_id', s.id,
                'vehicle_reg', v.registration_no,
                'type', s.type,
                'date', s.date,
                'workshop', s.workshop,
                'total', s.total
            )
        )
    ) INTO result
    FROM public.service_records s
    JOIN public.vehicles v ON v.id = s.vehicle_id
    WHERE s.company_id = cid
      AND s.date >= start_date AND s.date <= end_date
      AND (p_vehicle_id IS NULL OR s.vehicle_id = p_vehicle_id);

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 6. Storage Buckets Setup
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('vehicle-photos', 'vehicle-photos', false),
    ('service-photos', 'service-photos', false),
    ('bills', 'bills', false),
    ('avatars', 'avatars', false)
ON CONFLICT (id) DO NOTHING;
