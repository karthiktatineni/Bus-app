# FleetPulse End-to-End Working Checklist

Updated 17 October 2026.

## How to read this checklist

- **Implemented** means the source code/configuration is present in this checkout.
- **Locally verified** means a check was run in this checkout; it does not prove cloud services are deployed.
- **Live pending** means the feature needs credentials, deployment, real data, or an end-to-end staging check.

## Mobile frontend

- [x] Flutter app entry point, navigation, route guards, and Supabase session restoration are implemented.
- [x] Login and password reset call the Supabase auth repository; demo login defaults were removed.
- [x] Feature providers use Supabase repositories for vehicles, services, bills, users, settings, and notifications.
- [x] Dashboard and fleet screens use repository data; demo metric fallbacks were removed.
- [x] Vehicle, service, bill, notification, settings, and user-management screens are present.
- [x] Maintenance tasks can be completed from the app and saved through the repository.
- [x] Fleet AI chat screen calls the authenticated `/ai/fleet-assistant` route on the Render backend and displays Markdown answers and retrieved source labels.
- [x] Camera/gallery selection and JPEG compression are wired into media workflows.
- [x] Android network/camera/media permissions and iOS camera/photo descriptions are configured.
- [ ] Run the app against a deployed staging backend and verify each role and screen with real accounts.

## Supabase data and backend

- [x] Initial migration defines the 16-table fleet schema, helper functions, operational RPCs, and storage buckets.
- [x] Security migration defines tenant RLS, role-specific write rules, storage folder policies, indexes, and vehicle soft-delete audit behavior.
- [x] Redis/RAG migration adds per-company cache generations, generation bump triggers, vector extension/table, and scoped knowledge RPCs.
- [x] User management and one-time bootstrap Edge Function source is present; the Render AI route uses the signed-in user's JWT for Supabase Auth and RLS.
- [ ] Apply all three migrations to staging and production, then verify RLS, RPC access, storage uploads, auth invitations, and bootstrap.
- [ ] Deploy `manage-user` and `bootstrap-company`, then configure their required secrets.

## OCR service and image handling

- [x] FastAPI OCR service exposes `/health` and `/ocr/scan-bill`; OCR validates the Supabase access token and derives its cache scope from the verified user.
- [x] Tesseract OCR extracts candidate vendor, GSTIN, invoice number, bill date, total, raw lines, and a heuristic confidence value.
- [x] Flutter bill entry calls the configured OCR URL and handles the returned fields.
- [x] Dockerfile and Render service configuration are present.
- [x] Optional Redis cache stores successful parsed OCR output for 24 hours, partitioned by app user scope and image digest; a Redis failure falls back to OCR processing.
- [ ] Create the Render Blueprint to deploy the combined OCR/AI service and private Key Value cache; set the service URL as Flutter's `OCR_SERVICE_URL`.
- [ ] Evaluate OCR against representative real bills. The current confidence is a field-presence heuristic, not a calibrated accuracy score.

## AI model and RAG chatbot

- [x] Render's authenticated AI route validates the caller and uses NVIDIA NIM chat completion (`meta/llama-3.3-70b-instruct`).
- [x] Tool calls retrieve fleet summary, vehicle status, due maintenance, expiring documents, and service costs from tenant-scoped database RPCs.
- [x] NVIDIA `baai/bge-m3` embeddings and Supabase pgvector retrieval are wired for maintenance knowledge chunks.
- [x] Retrieval is tenant-scoped, limited to the most relevant passages, and filtered by a similarity threshold.
- [x] The assistant is instructed to cite retrieved document labels, avoid unsupported claims, and abstain when evidence is insufficient.
- [x] `backend/knowledge/ingest.py` ingests authorized Markdown/text documents; company-specific documents can be scoped with `FLEET_KNOWLEDGE_COMPANY_ID`.
- [ ] Configure the NVIDIA API key, apply the RAG migration, ingest the correct manuals, and verify retrieval/citations on representative questions.
- [ ] Measure answer quality against a reviewed question/answer set. RAG improves grounding but cannot guarantee every generated sentence is correct.
- [ ] Token streaming and interactive vehicle/task answer cards are not implemented.

## Redis caching

- [x] Render FastAPI AI route uses Render Key Value via the private network for Redis `GET`/`SET` with expiry for repeated RPC results and final answers.
- [x] Cache keys include tenant/user scope and the current database generation; writes to fleet data tables increment that generation.
- [x] Query embeddings are cached per user for one hour; final AI answers for 20 seconds; fleet RPC results for 30 seconds.
- [x] Render OCR caches a successful parsed result for 24 hours using image digest and user cache scope.
- [x] Redis is optional at runtime: cache misses, timeouts, or Redis failures fall back to the underlying backend/model.
- [ ] Create the Render Blueprint; it provisions a private Render Key Value instance and wires its private connection URL into the backend. No separate Redis provider or REST credentials are required.
- [ ] Confirm cache hits and generation invalidation in staging after configuration.

## Local checks and release

- [x] `flutter analyze`: no issues found.
- [x] `flutter test`: all 53 tests passed.
- [x] Python OCR and ingestion files passed `py_compile`.
- [ ] SQL migrations and Edge Functions were not deployed or validated against a live Supabase project in this session.
- [ ] Live OCR, NIM, Redis, and RAG flows were not end-to-end tested because service credentials/deployments and a knowledge corpus are not configured.
- [ ] Existing APKs in `apk/` predate this implementation; they were not replaced.
- [ ] Configure a protected Android release keystore. Current release Gradle configuration uses debug signing and is not distribution-ready.
- [ ] Complete the staging acceptance flow in `docs/ACCEPTANCE_TEST.md` before production release.

## Deployment handoff

1. Apply `supabase/migrations/20261017000000_initial_fleet_schema.sql`, `supabase/migrations/20261017010000_tenant_security_storage.sql`, and `supabase/migrations/20261017020000_redis_rag.sql` in order.
2. Set `BOOTSTRAP_SECRET` for Supabase Edge Functions; set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `NVIDIA_NIM_API_KEY` for the Render backend. The Blueprint injects `REDIS_URL`.
3. Deploy the two Edge Functions, bootstrap a staging company, accept the admin invitation, and add test fleet records.
4. Create the Render Blueprint to deploy the combined OCR/AI backend and private Render Key Value cache; set its URL in the mobile build configuration.
5. Ingest authorized manuals with `backend/knowledge/ingest.py`; use company scope for tenant-specific manuals.
6. Complete live acceptance checks, then configure release signing and produce a new signed APK.
