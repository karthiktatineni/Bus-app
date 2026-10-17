# FleetPulse Project State

Updated 17 October 2026.

For the ordered cloud setup and production handoff, see `docs/PROJECT_HANDOVER.md`. The compact status checklist is `docs/WORKING_CHECKLIST.md`.

## What is implemented in this checkout

- Flutter feature providers use Supabase implementations for auth, vehicles, services, bills, users, settings, and notifications. Login restores the persisted Supabase session and no longer fills demo credentials.
- Camera/gallery image picking and JPEG compression are wired in. Vehicle, service, and bill images upload to private company-scoped Storage paths and reads use expiring signed URLs.
- Service entry starts empty, persists parts and photos, can mark tasks complete in the database, and invokes the OCR service instead of a fake delay.
- A FastAPI/Tesseract OCR service is defined at `backend/ocr_service/`, with Supabase-token authentication and deterministic GSTIN, invoice number, date, total, vendor, and confidence extraction.
- Fleet AI has a chat screen and authenticated `/ai/fleet-assistant` route in the Render FastAPI backend. It verifies the signed-in user with Supabase Auth, calls fleet RPCs with that user's JWT, and sends returned records to NVIDIA NIM for a grounded response.
- Render Key Value provides Redis-compatible storage over Render's private network. The shared Render backend uses it for short-lived tenant/user-scoped RPC and answer caches, per-user query embeddings, and 24-hour OCR image digest results. Cache failures fall back to the source service/model.
- The AI now retrieves tenant-authorized maintenance chunks through pgvector using NVIDIA `baai/bge-m3` embeddings, uses a similarity threshold, asks the model to cite sources, and displays retrieved source labels. `backend/knowledge/ingest.py` ingests authorized Markdown/text references.
- SQL migrations define the 16-table schema, RLS, indexes, Storage buckets, role policies, vehicle soft-delete audit, and session activation after invitation acceptance. Edge Function sources cover company bootstrap and admin user invitations.
- Android camera/network permissions and iOS camera/photo usage descriptions are present. README and acceptance instructions are in place.

## Local verification

- `flutter analyze`: **0 issues**.
- `flutter test`: **53 tests passed**.
- The existing APK files in `apk/` predate this work; they were not replaced.

## What is not live or verified yet

- The Supabase CLI and Supabase MCP are unavailable in this session. The migrations and remaining Edge Functions have **not** been applied or deployed to project `uwvjvlkkcknwiapvrwng`; live RLS, buckets, RPCs, bootstrap, and auth therefore remain unverified.
- Render Key Value has not been provisioned. The Render Blueprint defines it as an internal-only service and wires its private URL into the backend; deploy the Blueprint to enable caching. Requests remain functional without Redis but will not receive cache benefits.
- No authorized maintenance manual corpus is present or ingested yet. The RAG code is ready, but factual manual answers require loading the correct manuals; without relevant retrieval evidence the assistant is instructed to abstain. LLM wording still cannot be guaranteed 100% correct.
- The NVIDIA key must be configured as a Render backend secret. It must never be added to Flutter build defines.
- The combined OCR/AI backend has not been deployed to Render, so the mobile OCR and AI flows need the final backend URL.
- No live tenant seed has been created. There is no fabricated 10-bus seed in the production migration.
- The AI response is database-grounded, but an LLM cannot guarantee zero hallucinations or mathematically 100% factual wording. The Render AI route and OCR need live acceptance checks.
- The assistant currently returns a completed Markdown response; token streaming and interactive vehicle/task cards are not implemented.
- Android Gradle is still configured to sign release builds with the debug key. A production APK requires the owner's protected release keystore and signing configuration.
- The existing Firebase configuration was not tested end-to-end.

## Deployment order

1. Apply all three ordered SQL migrations to a staging Supabase project and inspect the policies/RPCs.
2. Configure a one-time `BOOTSTRAP_SECRET`; deploy `manage-user` and `bootstrap-company`.
3. Bootstrap a staging company, accept the administrator invitation, and create a staff account.
4. Create the Render Blueprint; it provisions private Render Key Value and the combined OCR/AI backend. Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `NVIDIA_NIM_API_KEY` for that backend, then use its URL as Flutter's `OCR_SERVICE_URL`.
5. Ingest authorized maintenance manuals using `backend/knowledge/ingest.py`, with company scope for private manuals.
6. Complete `docs/ACCEPTANCE_TEST.md`, configure release signing, then create and install the release APK.
