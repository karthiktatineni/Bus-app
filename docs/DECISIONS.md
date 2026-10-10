# Decisions Log

- **Phase 0 (Cleanup):** The screens folder was found under the name `screen_designs/`. We proceeded with cleanup deleting everything except `.git`, `screen_designs`, and markdown files in the `docs/` level.
- **Backend & Region**: Supabase chosen. Region set to `ap-south-1` (Mumbai) to keep data in India.
- **Schema Fixes for Phase 4**:
  - Added `notifications` table (user, type, title, body, link_target, read_at).
  - `maintenance_tasks`: added schedule_id, completed_at, completed_by, service_record_id.
  - Removed `service_records.bill_id` (kept `bills.service_id` only).
  - Database trigger: saving a `service_record` updates the matching `service_schedules` (last_done_date, last_done_km) and closes the related `maintenance_task`.
  - Vehicles use soft delete (`deleted_at`); deletions go to `audit_log`.
  - Money columns are `numeric(12,2)`.
- **Docs location**: Moved `README.md` back to repo root. All other `.md` docs will remain in `docs/` and paths are updated.
- **Hardening & Operations**: Extended MASTER_AGENT_PROMPT.md. Created private Git workflow files (.gitignore, CODEOWNERS, CI, PR Template) and added 8 required agent skills.
- **Typography**: Chosen fonts are Hanken Grotesk (primary) and JetBrains Mono (data) as per `DESIGN.md`. These will be bundled locally as assets (`pubspec.yaml` assets) to ensure offline availability and prevent network latency issues.
