# Implementation Plan

## Screen Audit
The following table maps the 12 required screens to the existing Stitch design files:

| Screen | Status | File Path |
| --- | --- | --- |
| 1. Login | Designed | `c861c16ce1994f0c9dcc4df505f8d68f.html` |
| 2. Home (Dashboard) | Designed | `5b8d663eb3ce45c0a5033c31b1385f96.html` |
| 3. Navigation Drawer | Missing | N/A |
| 4. Vehicles list | Missing | N/A |
| 5. Vehicle Detail | Designed | `07975011626b499699467cd905e700c6.html`, `6cc8c8dfca034d56bcc707936b61f601.html` |
| 6. Add / Edit Vehicle | Missing | N/A |
| 7. Service Detail | Missing | N/A |
| 8. Add Service Record | Missing | N/A |
| 9. Service history and Bills | Missing | N/A |
| 10. Reminders | Missing | N/A |
| 11. Users | Missing | N/A |
| 12. Settings | Missing | N/A |

## Phase-by-Phase Plan

### Phase 2: Design: Stitch Screens to Design Tokens
- **Tasks**: Generate prompts for the 9 missing screens in batches of 3 to 4 screens and write to `STITCH_PROMPTS.md`. Tell the human to export these to `screen_designs/` and crucially to export `DESIGN.md` from Stitch into `screen_designs/`. Extract design tokens from `DESIGN.md` and exported HTML into `docs/design_tokens.md`. Create `docs/screen_map.md`.
- **Owner**: Frontend (Agent) / Human (to run Stitch prompts).
- **Dependencies**: Phase 1 approval.
- **Acceptance Criteria**: `STITCH_PROMPTS.md`, `docs/design_tokens.md`, and `docs/screen_map.md` created. Human provides missing Stitch screens.
- **Estimated Effort**: 1 Day

### Phase 3: Flutter Frontend on Mock Data
- **Tasks**: Setup Flutter architecture. Implement token-based theme. Build all screens using mock data layer (repositories/providers). Implement camera/photo capture flow.
- **Owner**: Frontend (Agent).
- **Dependencies**: Phase 2 approval.
- **Acceptance Criteria**: Fully runnable app covering all screens with mock data, no overflow errors, clean `flutter analyze`, tests passing, dark/light mode supported.
- **Estimated Effort**: 4 Days

### Phase 4: Backend
- **Tasks**: Set up Supabase/Firebase schema. Create RLS policies. Define storage buckets. Implement Edge functions for user invite and daily reminders. Write seed script. Write `docs/api.md`.
- **Owner**: Backend (Agent) / Human (Project setup).
- **Dependencies**: Phase 3 approval.
- **Acceptance Criteria**: Migrations/schema defined. SQL tests pass. API docs generated. Seed script runs successfully.
- **Estimated Effort**: 2 Days

### Phase 5: Connect Frontend to Backend
- **Tasks**: Replace mock repository implementations with real data layer connecting to the backend. Wire up real auth, photo/bill uploading via signed URLs. Implement robust error mapping and offline fallback.
- **Owner**: Frontend (Agent).
- **Dependencies**: Phase 4 approval, Human configuring env keys.
- **Acceptance Criteria**: App functions on real backend. Real login/logout, uploading images successfully stores in buckets. Integration tests pass.
- **Estimated Effort**: 2 Days

### Phase 6: OCR for Bills
- **Tasks**: Implement ML Kit text recognition for on-device OCR. Map extracted text (vendor, bill no, date, total, GST). Evaluate accuracy using 30 real bills.
- **Owner**: Frontend/Backend (Agent).
- **Dependencies**: Phase 5 approval. Human provides 30 test bills.
- **Acceptance Criteria**: On-device OCR hits >85% accuracy on critical fields, or Cloud-based OCR is integrated if necessary. Output fields are editable by user.
- **Estimated Effort**: 2 Days

### Phase 7: Notifications
- **Tasks**: Configure Firebase Cloud Messaging. Implement settings toggles (push/email). Deep link routing.
- **Owner**: Frontend/Backend (Agent) / Human (APNs/iOS setup).
- **Dependencies**: Phase 6 approval.
- **Acceptance Criteria**: Notifications triggered properly based on lead-time settings. Deep links route to intended screen.
- **Estimated Effort**: 1 Day

### Phase 8: Hardening and Release
- **Tasks**: Security review, performance profiling, CI/CD setup, app icon/splash screens, final release docs (`runbook.md`, `user_guide.md`, `architecture_overview.md`).
- **Owner**: Frontend (Agent) / Human (Apple/Google store provisioning).
- **Dependencies**: Phase 7 approval.
- **Acceptance Criteria**: Zero security vulnerabilities, smooth scrolling, functional CI, all final docs authored. Ready for TestFlight / Internal Testing.
- **Estimated Effort**: 2 Days

**Estimated Agent Working Days**: 14 Days
**Realistic Calendar Estimate**: 21-25 Days (Includes time for human approvals, Stitch generation, real-device camera testing, Apple developer account setup, and gathering 30 sample bills).

## Risks and Open Questions
- **Backend Choice**: Supabase has been chosen. Row Level Security will be strictly implemented.
- **OCR Accuracy**: ML Kit (on-device) might struggle with varied Indian bill formats. We may need to pivot to Google Document AI (Cloud) if the 85% accuracy threshold fails during the Phase 6 evaluation.
- **iOS Build Path**: Creating TestFlight builds requires an Apple Developer account and a macOS environment (or a tool like Codemagic). The Human must set this up.
- **Data Residency**: The backend will be provisioned in `ap-south-1` (Mumbai) to ensure data stays in India.

## Database Schema Outline (Supabase / Postgres)
- `companies`: id, name, logo_url, default_reminder_lead_days, created_at, updated_at
- `profiles`: id (fk auth.users), company_id, name, email, phone, role(admin/staff), status, avatar_url, created_at, updated_at
- `vehicles`: id, company_id, registration_no, make, model, year, chassis_no, engine_no, seats, fuel_type, odometer_km, depot, purchase_date, status, created_by, created_at, updated_at
- `vehicle_documents`: id, company_id, vehicle_id, type, number, expiry_date, file_url, created_by, created_at, updated_at
- `vehicle_photos`: id, company_id, vehicle_id, url, caption, created_by, created_at, updated_at
- `service_schedules`: id, company_id, vehicle_id, task_name, interval_km, interval_months, last_done_date, last_done_km, created_by, created_at, updated_at (Note: A scheduled edge function uses these to auto-generate `maintenance_tasks`).
- `maintenance_tasks`: id, company_id, vehicle_id, title, due_date, due_km, is_done, created_by, created_at, updated_at
- `service_records`: id, company_id, vehicle_id, type, date, odometer_km, workshop, mechanic, notes, labour_cost, tax, total, bill_id, created_by, created_at, updated_at
- `service_parts`: id, company_id, service_record_id, name, qty, cost, created_by, created_at, updated_at
- `service_photos`: id, company_id, service_record_id, url, type, caption, part_id, created_by, created_at, updated_at
- `bills`: id, company_id, vehicle_id, service_id, vendor, bill_no, bill_date, tax, total, image_url, ocr_confidence, created_by, created_at, updated_at
- `bill_items`: id, company_id, bill_id, name, qty, cost, created_by, created_at, updated_at
- `audit_log`: id, company_id, user_id, action, resource_type, resource_id, details, created_at
- `device_tokens`: id, company_id, user_id, device_id, token, platform, created_at, updated_at
- `user_settings`: user_id, theme_mode, language, distance_unit, currency, date_format, notifications_enabled, service_reminders_enabled, service_reminders_lead_days, doc_expiry_reminders_enabled, doc_expiry_reminders_lead_days, push_enabled, email_enabled, biometric_lock, updated_at
- `company_settings`: id, company_id, default_reminder_lead_days, updated_at

## API Surface (High-Level)
- **Auth**: signIn, signOut, resetPassword, changePassword
- **Users**: inviteUser (Edge Function), removeUser, updateUserRole
- **Vehicles**: list, get, create (admin), update (admin), delete (admin)
- **Services**: listAll, get, create, update (admin), delete (admin)
- **Tasks**: upcomingTasks, setTaskDone
- **Bills**: scanBill (on-device or edge function)
- **Settings**: getUserSettings, saveUserSettings, getCompanySettings, saveCompanySettings
