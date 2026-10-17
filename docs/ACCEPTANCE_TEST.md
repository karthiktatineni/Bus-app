# FleetPulse Acceptance Test

Run these steps against a Supabase staging project after all three migrations, the two remaining Edge Functions, and the Render OCR/AI backend with its private Key Value cache are deployed. Use two test companies and separate admin/staff accounts so tenant boundaries can be checked.

1. **Bootstrap and sign in:** call `bootstrap-company` once with the configured bootstrap secret. Confirm the admin invite email, accept it, then sign in from the mobile app.
2. **Tenant isolation:** sign in to Company A and confirm no Company B vehicles, users, service records, documents, bills, or notifications are visible. Repeat as Company B.
3. **Role access:** as staff, confirm fleet reads work and vehicle/user/company setting writes are denied. As admin, confirm authorized vehicle and user management works.
4. **Vehicle lifecycle:** create and edit a vehicle with its documents and a camera/gallery photo. Confirm the record and private photo are present in Supabase. Delete the vehicle and confirm it is soft-deleted and audited.
5. **Service entry:** as staff, create a service record with parts, costs, and before/after/part photos. Confirm odometer and matching schedule updates, and matching open tasks close.
6. **Task completion:** mark an open task done from the dashboard. Confirm `is_done`, completion timestamp, and user are persisted. Reopen only if the current role policy allows the action.
7. **Bills and OCR:** while signed in, scan a clear invoice and an intentionally poor image. Confirm an unauthenticated OCR request is rejected, extracted fields are editable, fields under 85% confidence get a warning, and the saved bill image is private.
8. **Settings and notifications:** save user preferences and admin company settings. Mark one and all notifications read and confirm the database changes.
9. **Fleet AI:** ask about fleet totals, a known and unknown registration, expiring documents, maintenance, and costs over a date range. Compare every number and identifier with the database RPC result.
10. **Release build:** run `flutter analyze`, `flutter test`, and create a release APK using the organization's protected signing keystore. Install it on a clean Android device and repeat sign-in, image capture, service entry, OCR, and assistant checks.

Record the staging project, build version, test accounts (never passwords), and pass/fail evidence in the release record. Do not use real customer or driver data in staging.
