# FleetPulse

Flutter fleet maintenance app with Supabase Auth, PostgreSQL, private Storage, and one Render backend for OCR and fleet AI. Render Key Value provides the private Redis-compatible cache.

## Local setup

1. Install Flutter, Android Studio (Android SDK), Python 3, and Docker.
2. Run `flutter pub get`.
3. Configure the Supabase project and apply the ordered SQL files in `supabase/migrations/` using the Supabase CLI or SQL editor.
4. Deploy `manage-user` and `bootstrap-company` from `supabase/functions/`; set `BOOTSTRAP_SECRET` in Supabase. Never place a service-role key in Flutter or source control.
5. Create the Render Blueprint from `backend/ocr_service/render.yaml`. It provisions the Render Key Value cache and wires its private URL into the existing backend service. Set the Render service variables `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `NVIDIA_NIM_API_KEY`.
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

Use `bootstrap-company` once to create the company and send the initial administrator invitation. The invited user becomes active after confirming their email. For RAG, place authorized maintenance references (`.md` or `.txt`) in a local corpus folder, set the ingestion environment variables, and run `python backend/knowledge/ingest.py PATH_TO_CORPUS`. Set `FLEET_KNOWLEDGE_COMPANY_ID` to scope company-specific references; leave it unset only for genuinely shared general manuals. The model abstains when retrieval evidence is weak or unavailable. `docs/HUMAN_TASKS.md` lists external setup actions and `docs/ACCEPTANCE_TEST.md` describes the live acceptance flow.

For an end-to-end checklist and step-by-step environment handover, see `docs/WORKING_CHECKLIST.md`, `docs/PROJECT_STATE.md`, and `docs/PROJECT_HANDOVER.md`.

## Checks and release

```powershell
flutter analyze
flutter test
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY `
  --dart-define=OCR_SERVICE_URL=https://fleetpulse-ocr.onrender.com
```

Configure an Android release keystore and signing values in a local, untracked Gradle properties file before distributing a release APK.
