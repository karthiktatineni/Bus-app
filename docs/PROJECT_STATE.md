# FleetPulse Project State

Updated 17 October 2026.

This is the verified handover after the latest service/OCR and Fleet AI memory pass. It distinguishes local verification from checks that still require signed-in production data or authorized manuals.

## Current status

- The current application/backend changes were committed as `0b680ca` and pushed to GitHub `main` (remote `main` matches this commit).
- Supabase migration history is reconciled. Migrations `20261017150000` and `20261017170000` are applied remotely.
- After the push, Render's health uptime reset and `/health` returned `status: ok`; Redis, Supabase auth, and OCR checks passed, and NVIDIA is configured. A signed-in AI request was not exercised against production.
- Debug-signed `fleetpulse.apk` was rebuilt, installed, and launched on the connected OnePlus 7T (`3b038054`). SHA-256: `64F3A53E87040732BB7D028B5D15467F920D24FD6123D9251D8476BD1BC8B106`. The release APK is not signed because no Android release key is configured.
- Manual RAG corpus is empty. Fleet-data/tool questions can use live tenant data after sign-in; manual retrieval and citations need authorized manuals ingested first.

## Changes in this pass

- Fleet AI uses NVIDIA `nvidia/nemotron-3-embed-1b` with `input_type=query`, validates 2048-element vectors, and keys Redis cache entries by model.
- Offline knowledge ingestion uses the same model with `input_type=passage`, retries transient embedding calls, and writes to the new corpus.
- Migration `20261017170000_nemotron_embedding_dimension.sql` creates a `halfvec(2048)` corpus and updates the RAG RPCs while retaining the legacy 1024-vector corpus. `halfvec` is used because pgvector's HNSW index supports larger dimensions than `vector` indexes.
- Backend startup now uses FastAPI lifespan handling for Redis initialization and shutdown; the Python tests no longer emit lifecycle deprecation warnings.
- Flutter vehicle status parsing handles storage values such as `in_workshop` and `due_soon`.
- Added admin delete/archive actions for bills/images, service records/photos, and vehicle photos/archive, retaining historical records where appropriate.
- Added vehicle photo and document capture during add/edit; existing bus documents/photos can be viewed, and service records support image attachments. Vehicle overview now reflects actual documents rather than placeholder certificates.
- Fixed narrow layout issues in dashboard, vehicle list, and service details. Image preview now displays the actual uploaded photo and supports zoom.
- Added a **Service history → Add service record** action on each vehicle, preselecting the bus. The flow captures work notes, service type/date/odometer/workshop/mechanic, replaced parts/costs, labour and before/after/part photos.
- Bill capture now explicitly chooses camera or gallery, sends the image with the signed-in bearer token to Render OCR, and exposes vendor, invoice number, date and amount for review. Saving stores the bill image and OCR confidence in the private `bills` bucket and `bills` table; bill/service links are resolved in service detail.
- User-entered service parts are copied to `bill_items`. OCR does not reliably extract individual part names/quantities; parts must be entered and checked in the form.
- Removed the hard-coded oil/filter/coolant rows from service detail. Blank part rows are ignored; no default parts are inserted. New service UI requires one service photo, a bill image, the bill total entered/reviewed by the user, and a next-service task/date. GST is no longer auto-added or calculated.
- Bill scanner now sends the compressed file with explicit `image/jpeg` multipart content type and shows the backend error detail. This is intended to address the reported HTTP 415; verify with a signed-in physical bill scan.
- Legacy mock repositories and generated sample data have been moved from `lib/` into `test/fakes/`; production providers point to Supabase repositories.
- Fixed an OCR parser false positive where a generic “Tax Invoice” heading could be mistaken for an invoice number; extraction now requires a label and value on the same line. Added authenticated-upload response and missing-session tests.
- Dashboard To do and Maintenance Reminders now include Due Soon/Overdue vehicle statuses when no open maintenance task exists for that bus. Date-only comparison treats a task due today as due today, not overdue.
- Fleet AI stores up to 50 recent transcript messages in encrypted device storage scoped to the signed-in user and sends the newest 12 messages as short-term context. The backend uses conversation context for follow-ups, includes context in Redis cache keys and RAG queries, and routes cost questions to the cost RPC. “All vehicles” is forced to a null vehicle filter; an unspecified period defaults to the last 30 calendar days. Operational data questions skip embedding/RAG calls; maintenance knowledge questions continue through vector retrieval.
- Fleet AI memory is currently per-user on this device; it does not sync between devices or survive uninstall/device loss. Cross-device cloud conversation memory requires an authenticated/RLS-protected persistence design and is not implemented.
- Service OCR requests use a JPEG multipart content type after image compression. Empty OCR vendor results must be entered by the user; no fake vendor/parts are inserted.
- The Add Service Record stepper switches to vertical on phone widths; the bus selector expands and truncates long labels instead of overflowing. Added a 320 px form regression test.
- Added [SERVICE_RECORD_WORKFLOW.md](SERVICE_RECORD_WORKFLOW.md) for the user steps, request/data flow, tables/buckets, OCR limits and live acceptance test.

## Verification completed

- `flutter analyze`: no issues found.
- `flutter test`: all 60 tests passed, including 320 px service-form, vehicle-status To do and vehicle service-entry regressions.
- Python OCR/backend tests: 9 passed, including signed-in bill-image upload/field extraction, missing-session rejection, bounded chat history, contextual cost routing and RAG routing.
- `npx supabase migration list --project-ref uwvjvlkkcknwiapvrwng`: local and remote migration versions matched, including `20261017170000`.
- Render health endpoint returned healthy Redis, Supabase auth, and OCR checks.
- Android debug APK installed successfully and app launch was triggered on the OnePlus 7T.

## Still required before production sign-off

- Run a signed-in Fleet AI spending follow-up and manual question from the app to verify live database tool use, RAG retrieval, and chat memory. The health endpoint does not exercise those paths.
- Test OCR, fleet-data AI answers, and tenant isolation using staging accounts. The health endpoint alone does not verify the end-to-end path.
- Ingest manuals the company is authorized to use, then test retrieval, citations, tenant separation, and abstention when evidence is missing.
- Run end-to-end upload/view/delete checks for vehicle documents/photos, service photos, bill images, and role boundaries against Supabase Storage/RLS.
- Complete a signed-in live service + invoice OCR + parts/photos save-and-reopen flow on the client/staging account; local tests do not replace cloud acceptance.
- Configure protected Android release signing before distributing a production APK. `fleetpulse.apk` in the root is a debug build for device evaluation.
- Review the Android plugin warning about `flutter_image_compress_common` and Built-in Kotlin compatibility before a future Flutter/Gradle upgrade.

See [PROJECT_HANDOVER.md](PROJECT_HANDOVER.md) for resume order and [WORKING_CHECKLIST.md](WORKING_CHECKLIST.md) for individual acceptance items.
