# External Setup and Release Tasks

## Project and account setup

- [x] Supabase project reference recorded: `uwvjvlkkcknwiapvrwng` (Singapore region).
- [x] Firebase Android configuration files and Gradle plugin are present in the working tree; verify their project/app IDs before release.
- [ ] Apply all three ordered SQL migrations (`20261017000000`, `20261017010000`, `20261017020000`) to staging and production.
- [ ] Set a one-time random `BOOTSTRAP_SECRET` in Supabase Edge Function secrets. Never place privileged keys in Flutter or source control.
- [ ] Deploy `manage-user` and `bootstrap-company`; run the one-time bootstrap to invite the first company admin.
- [ ] Create staging company/vehicle/service records through the app. No sample data has been inserted into production.
- [ ] Create the Render Blueprint in `backend/ocr_service/render.yaml`; it provisions private Render Key Value and the combined OCR/AI backend. Set the backend's Supabase URL/public key and rotated NVIDIA key. The app defaults to `https://fleetpulse-ocr.onrender.com`; use `OCR_SERVICE_URL` only to override it.
- [ ] Add authorized fleet maintenance manuals to a local Markdown/text corpus and run `backend/knowledge/ingest.py` with service-role and NVIDIA credentials. Scope company documents with `FLEET_KNOWLEDGE_COMPANY_ID`.

## Verification and release

- [x] Local static analysis: `flutter analyze` reports zero issues.
- [x] Local test suite: 53 tests pass.
- [ ] Run the live checks in `docs/ACCEPTANCE_TEST.md` after cloud deployment.
- [ ] Add the organization's protected Android release keystore and signing values to the local Gradle release configuration. The current Gradle release variant uses debug signing and is not suitable for distribution.
- [ ] Build and install a signed release APK after live acceptance passes.
