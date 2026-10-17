# FleetPulse Project Handover

Updated 17 October 2026.

This is the operational handover for getting the current FleetPulse checkout from locally implemented code to a working staging app, then a production release. The short status checklist is in `docs/WORKING_CHECKLIST.md`; the detailed acceptance scenarios are in `docs/ACCEPTANCE_TEST.md`.

## 1. Current state at a glance

### Implemented in this checkout

- Flutter app with Supabase-backed authentication and data repositories for vehicles, services, bills, users, settings, and notifications.
- Fleet dashboard and feature screens for maintenance, vehicles, bills, settings, notifications, and users.
- Camera/gallery selection, JPEG compression, private company-scoped Supabase Storage paths, and signed media URLs.
- Three ordered Supabase SQL migrations for the fleet schema, tenant/role security, and Redis-generation/RAG schema.
- Supabase Edge Function source for admin invitations and one-time company bootstrap.
- One Render FastAPI service for Tesseract OCR and authenticated fleet AI, plus Flutter clients for both routes.
- Render Key Value wiring and Redis caching for fleet AI and OCR using Render's private network.
- AI answer path using NVIDIA NIM, fleet data RPC tools, NVIDIA `baai/bge-m3` embeddings, tenant-scoped pgvector retrieval, source labels, and abstention instructions.
- A manual ingestion script for authorized Markdown and text references.

### Verified locally

- `flutter analyze`: no issues found.
- `flutter test`: 53 tests passed.
- Python syntax compilation completed for the OCR service and knowledge ingestion script.

### Not yet live

- Supabase migrations and the remaining Edge Functions have not been deployed or validated against the configured project.
- Render Key Value and the backend have not been deployed, so Redis cache hits and API requests have not been verified live.
- OCR has not been deployed to Render or evaluated on a representative bill set.
- No maintenance manual corpus has been provided or ingested, so RAG has no project-specific reference material yet.
- No signed production APK has been created. The current Android release build configuration uses debug signing.

## 2. Services and ownership boundaries

| Component | Runs where | What it owns | Required configuration |
|---|---|---|---|
| Flutter client | Android/iOS device | UI, session, client-side uploads, user interactions | Supabase URL, public anon/publishable key, OCR URL |
| Supabase Auth/Postgres/Storage | Supabase project `uwvjvlkkcknwiapvrwng` | Sign-in, tenant data, RLS, private media, RPCs, vector corpus | Ordered SQL migrations, invitation email setup, function secrets |
| `manage-user` and `bootstrap-company` | Supabase Edge Functions | Admin invites and initial tenant setup | Supabase service credentials; one-time bootstrap secret |
| Fleet API and OCR API | Same Render Docker web service | Authenticated fleet AI, Supabase RPC/RAG orchestration, image-to-text extraction | Supabase URL/public key and NVIDIA key; Flutter receives one service URL |
| Render Key Value | Same Render project/private network | Short-lived Redis-compatible cache only; not the system of record | Private connection URL is injected by Blueprint; no external Redis account or REST token |
| NVIDIA NIM | NVIDIA-hosted APIs | Chat completion and `baai/bge-m3` embeddings | `NVIDIA_NIM_API_KEY` stored server-side only |
| Knowledge corpus | Supabase pgvector table | Tenant-specific or shared maintenance references | Authorized Markdown/text files ingested by operator |

## 3. Required configuration inventory

### Flutter build-time defines

Use public client configuration only:

- `SUPABASE_URL` — the Supabase project URL.
- `SUPABASE_ANON_KEY` — public anon/publishable client key.
- `OCR_SERVICE_URL` — deployed Render OCR base URL.

Never pass the service-role key, NVIDIA key, bootstrap secret, or Redis connection URL through Flutter build defines.

### Supabase Edge Function secrets

Set these in the Supabase project’s Edge Function secrets:

- `BOOTSTRAP_SECRET` — long random secret used only for the initial bootstrap call; rotate/remove after setup.
- The user/bootstrap Edge Functions use Supabase's server-side service-role credential. Never expose it to the app or commit it.

Supabase injects project URL/public key values into Edge Functions. Confirm the expected values exist in the deployed runtime without logging secret contents.

### Render backend environment

- `SUPABASE_URL` — Supabase project URL used by the Render AI route.
- `SUPABASE_ANON_KEY` — public key used with the caller's JWT; database RLS remains applied.
- `NVIDIA_NIM_API_KEY` — server-side key for chat and embedding requests.
- `REDIS_URL` — injected by the Blueprint from Render Key Value's private connection URL.
- Render provides `PORT`; the container uses it automatically.

### Manual ingestion environment

Run the operator ingestion script from a trusted local machine with:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NVIDIA_NIM_API_KEY`
- `FLEET_KNOWLEDGE_COMPANY_ID` for a tenant-private manual; omit only for content deliberately shared across all tenants.

The service-role credential has elevated database access. Keep it in a local secret manager or temporary shell environment and do not commit it.

## 4. Staging bring-up, in order

### A. Prepare staging accounts and services

- [ ] Confirm access to the Supabase project, NVIDIA NIM, Render, and an email delivery configuration for Supabase Auth invitations.
- [ ] Create a separate staging Supabase project if the recorded project is production. Do not test with real customer/driver data.
- [ ] Use the Render Blueprint to provision Render Key Value in the same region as the backend. No separate Redis provider or Redis REST API credentials are used; the backend gets its private `REDIS_URL` from the Blueprint.
- [ ] Confirm the NVIDIA account/API key can access chat completions and the `baai/bge-m3` embedding endpoint.
- [ ] Collect authorized maintenance manuals and decide which are company-private versus globally shared.

### B. Apply database migrations

Apply the SQL files in the Supabase SQL editor, in this exact order, reviewing each result before continuing:

1. `supabase/migrations/20261017000000_initial_fleet_schema.sql`
2. `supabase/migrations/20261017010000_tenant_security_storage.sql`
3. `supabase/migrations/20261017020000_redis_rag.sql`

Afterward verify that tables, storage buckets, RPCs, RLS policies, cache generation triggers, the `vector` extension, and the knowledge-chunk table exist. Do not proceed to app acceptance if a migration reports an error.

### C. Configure and deploy Supabase functions

1. Add the required secrets listed above in the Supabase Dashboard. Do not paste secret values into this handover or a repository file.
2. Install the Supabase CLI and link this checkout to the intended project if CLI deployment is preferred.
3. Deploy `manage-user` with JWT verification enabled.
4. Deploy `bootstrap-company`; because this endpoint authenticates with its one-time `x-bootstrap-secret` header, deploy it with gateway JWT verification disabled and retain the function’s own secret check. Do not make other functions public without their own authentication checks. Fleet AI is served by the authenticated Render backend, not a Supabase Edge Function.
5. Bootstrap the first company once, accept the admin invitation, sign in, invite a staff user, and confirm both profiles are active.
6. Rotate or remove `BOOTSTRAP_SECRET` after the first company is created.

### D. Provision sample staging data

- [ ] Create Company A through the one-time bootstrap. For Company B, use a trusted staging-only admin procedure to create a second company and invite/profile in the same Supabase project; the bootstrap endpoint intentionally refuses a second bootstrap and the app has no public company-creation flow.
- [ ] Add test vehicles, vehicle documents, service schedules, maintenance tasks, service records, bills, and notifications through the app or approved staging tooling.
- [ ] Confirm each company has distinct records so tenant isolation can be verified.
- [ ] Do not insert fabricated demo rows into production.

### E. Deploy the combined OCR/AI backend and Render Key Value

1. Connect the repository to Render and create the Blueprint from `backend/ocr_service/render.yaml`. It provisions an internal-only Render Key Value instance and the existing Docker web service in the same region, then injects the private `REDIS_URL`. The Blueprint sets the Docker context to `backend/ocr_service` so the Dockerfile can copy its requirements and application file.
2. Add `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `NVIDIA_NIM_API_KEY` to the Render service when prompted by the Blueprint. Never put the NVIDIA key or Redis URL in Flutter defines.
3. Wait for `/health` to report healthy; then test `/ocr/scan-bill` with a non-sensitive staging bill image and call `/ai/fleet-assistant` from a signed-in staging app.
4. Use the resulting HTTPS base URL as Flutter `OCR_SERVICE_URL`. The AI screen uses `FLEET_BACKEND_URL` if provided, otherwise it shares `OCR_SERVICE_URL`.
5. Repeat OCR and AI requests to confirm cache behavior. If Render exposes cache metrics for the selected Key Value plan, verify hits and generation-based invalidation there; cache outages should not block the app.

### F. Ingest knowledge for RAG

1. Install ingestion dependencies: `python -m pip install -r backend/knowledge/requirements.txt`.
2. Set the temporary ingestion environment variables listed above in the shell/secret manager.
3. Put authorized `.md` or `.txt` files in a local corpus directory. Do not commit proprietary manuals unless the organization permits it.
4. Run `python backend/knowledge/ingest.py PATH_TO_CORPUS`.
5. For company-private manuals set `FLEET_KNOWLEDGE_COMPANY_ID` to that company UUID. Leave it empty only when the reference is approved for all tenants.
6. Ask representative questions and confirm the returned source labels are relevant; test a question unrelated to the corpus and confirm the assistant says it cannot verify rather than inventing details.

### G. Build the app against staging

Run from the repository root, using staging URLs and the public Supabase key:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_STAGING_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_STAGING_PUBLIC_KEY `
  --dart-define=OCR_SERVICE_URL=https://YOUR_OCR_SERVICE.onrender.com
```

Then complete every scenario in `docs/ACCEPTANCE_TEST.md`, recording environment, app version, pass/fail, and non-secret evidence.

## 5. Production readiness and release

- [ ] Repeat migrations, function secrets, function deployment, Render Blueprint setup (including its Key Value instance), and knowledge ingestion in production only after staging passes.
- [ ] Review tenant isolation and RLS behavior with separate production-role test accounts before onboarding customers.
- [ ] Add a protected Android release keystore and local/untracked signing configuration. Do not distribute the current debug-signed release variant.
- [ ] Build and install a signed release APK from the production defines; repeat sign-in, image capture, service entry, OCR, and AI checks on a clean device.
- [ ] Store release version, migration version, deployed function versions, OCR URL, Redis health, and acceptance results in the release record. Do not store secrets or user passwords.
- [ ] Confirm backup/restore, auth email delivery, support ownership, privacy/retention policy for bill images and OCR text, and production monitoring before real fleet data is used.

## 6. Known limitations and risk notes

- The OCR confidence field counts extracted fields; it is not a measured probability of correctness. OCR values need human review before saving financial records.
- RAG answers depend on the completeness and authority of the uploaded manuals. Similarity filtering and source labels reduce unsupported answers but cannot promise perfect model output.
- Redis is an optimization, not durable storage. Supabase remains the source of truth; cache errors should not block app functionality.
- The SQL migrations, Edge Function code, and Render backend have not had live project validation in this session. Treat staging migration and acceptance results as required gates.
- Streaming responses and interactive action cards in the AI chat are not implemented.
- Existing APKs in `apk/` predate this work and are not current release builds.

## 7. Immediate next actions

1. Choose/confirm the staging Supabase project and get access to Supabase, Render, NVIDIA, and Auth email delivery.
2. Apply the three SQL migrations in order and stop if any SQL fails.
3. Configure secrets and deploy the two remaining Edge Functions; run one-time staging bootstrap.
4. Create the Render Blueprint to deploy the combined OCR/AI service and private Key Value cache, then build the staging Flutter app.
5. Add two isolated test tenants, ingest approved manuals, and run the acceptance scenarios.
6. Fix any staging failures, then repeat setup in production and create a signed APK.
