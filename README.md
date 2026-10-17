# FleetPulse

Flutter fleet maintenance app with Supabase Auth, PostgreSQL, private Storage, and one Render backend for OCR and fleet AI. Render Key Value provides the private Redis-compatible cache.

## Local setup

1. Install Flutter, Android Studio (Android SDK), Python 3, and Docker.
2. Run `flutter pub get`.
3. Configure the Supabase project and apply the ordered SQL files in `supabase/migrations/` using the Supabase CLI or SQL editor.
4. Deploy `bootstrap-company` from `supabase/functions/` only when provisioning a new company and its first admin; set `BOOTSTRAP_SECRET` in Supabase for that one-time operation. Admins create and permanently delete company users through the authenticated Render backend; no user-management Edge Function or invitation email is used.
5. Create the Render Blueprint from `backend/ocr_service/render.yaml`. It provisions the Render Key Value cache and wires its private URL into the backend. Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `NVIDIA_NIM_API_KEY` in the Render service settings. The service-role key is server-only: never put it in Flutter, a build define, `.env` used for Flutter, or source control.
6. The backend exposes a dependency health report at `/health` and Prometheus-format request, dependency, and Redis cache metrics at `/metrics`. The Blueprint generates a private `METRICS_BEARER_TOKEN`; use that value from Render's environment settings when scraping `/metrics`. Never put it in Flutter or source control.
7. Start the app with public client configuration supplied at build time:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY `
  --dart-define=OCR_SERVICE_URL=https://fleetpulse-ocr.onrender.com
```

`SUPABASE_ANON_KEY` is the public client key. The NVIDIA key is used by the Render backend and must never be included in Flutter build defines. Render Key Value is reached over Render's private network; no Upstash/Redis Cloud REST token is needed. The app intentionally does not contain demo login credentials.

Flutter reads its Supabase settings from `--dart-define`; it does not load `.env` files. The local `.env` is ignored by Git and is read by the Python OCR/AI service and ingestion script for local development. On Render, add the backend secrets in the service settings; the Blueprint injects `REDIS_URL` automatically.

## Data and setup

Use `bootstrap-company` once to create the company and initial admin. Admin-created users are created directly as confirmed Supabase Auth accounts with the password supplied in the app; no invite is emailed. Apply `20261017180000_user_auth_hard_delete.sql` before using permanent user deletion; it preserves historical attribution and uploaded files. For RAG, place authorized maintenance references (`.md` or `.txt`) in a local corpus folder, set the ingestion environment variables, and run `python backend/knowledge/ingest.py PATH_TO_CORPUS`. Set `FLEET_KNOWLEDGE_COMPANY_ID` to scope company-specific references; leave it unset only for genuinely shared general manuals. The model abstains when retrieval evidence is weak or unavailable. `docs/HUMAN_TASKS.md` lists external setup actions and `docs/ACCEPTANCE_TEST.md` describes the live acceptance flow.

For an end-to-end checklist and step-by-step environment handover, see `docs/WORKING_CHECKLIST.md`, `docs/PROJECT_STATE.md`, and `docs/PROJECT_HANDOVER.md`.

## Checks and release

```powershell
flutter analyze
flutter test
.\scripts\build_android.ps1
```

The build script reads only `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the local, ignored `.env`. Release builds use the deployed Render OCR/AI URL (`https://fleetpulse-ocr.onrender.com`) by default, independently of a developer's local `OCR_SERVICE_URL`; use `-OcrServiceUrl` only to select a different externally reachable HTTPS backend. Localhost URLs are rejected for release builds. The script never passes backend secrets to Flutter. For production distribution, configure an Android release keystore in the ignored `android/key.properties`; without it, the script requires the local internal test key and warns that the APK is not a production release. Startup configuration failures are shown in an in-app diagnostic screen instead of leaving a blank screen.
