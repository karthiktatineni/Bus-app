# FleetPulse Project Handover

Updated 17 October 2026.

## Current verified state

- The RAG/media base was committed as `348edf7`; the vehicle service/OCR and reminder changes were committed as `9852dbf` and pushed to `main`.
- Remote Supabase migrations through `20261017170000` are applied and match local migration history.
- After the push, Render health uptime reset; `/health` is currently healthy. This indicates a restart after the push, but the Render dashboard's deployed revision and a signed-in AI request still need direct confirmation.
- The OnePlus 7T is connected as ADB device `3b038054`. Debug APK `fleetpulse.apk` was installed and launched.
- All 58 Flutter tests, `flutter analyze`, and 5 Python tests passed. Python syntax compilation passed.
- No authorized manuals are currently in the RAG corpus; manual-grounded answers are not ready until ingestion.

## Changes made

1. Replaced retired NVIDIA embedding model usage with `nvidia/nemotron-3-embed-1b` for queries and passage ingestion, expecting 2048 values.
2. Added/applied a RAG migration using `halfvec(2048)` storage and HNSW index while retaining the old vector table.
3. Added retry and response validation to knowledge ingestion, and modernized Redis startup/shutdown to FastAPI lifespan events.
4. Added admin media delete/archive flows for bills, service history, and vehicles; added bus photo/document attachment on add/edit and service-history photo attachments.
5. Replaced placeholder vehicle document rows with database-backed data and made uploaded media previewable/zoomable.
6. Fixed and regression-tested responsive layouts at 320 px width.
7. Added a vehicle-scoped **Service history → Add service record** flow with a preselected bus, work details, parts/costs, service photos, invoice capture and editable OCR results.
8. Saved service parts as bill line items and resolved linked bills when a service detail is opened.
9. Included Due Soon/Overdue vehicle status in dashboard To do and the full reminder page when no corresponding open maintenance task exists; corrected date-only due comparisons.
10. Added [SERVICE_RECORD_WORKFLOW.md](SERVICE_RECORD_WORKFLOW.md) with the user flow, data architecture, storage mapping, OCR limits and live acceptance checks.
11. Tightened bill-number extraction so the generic heading “Tax Invoice” cannot be mistaken for the invoice number; the OCR endpoint contract is covered with an authenticated upload test.

## Remaining work

1. Confirm the Render dashboard shows commit `348edf7` deployed. Check service logs and run a signed-in Fleet AI question in the app; `/health` does not confirm successful database/RAG/model calls.
3. Test a real OCR bill scan and fleet-data question, then verify two test tenants cannot read each other's fleet data or RAG chunks.
4. Ingest authorized manuals and verify citations, retrieval quality, tenant scoping, and abstention for unsupported questions.
5. Test photo/document upload, display, and deletion with admin and staff accounts against live RLS/Storage.
6. Set up protected Android release signing for customer distribution. The root APK is debug-signed and suitable for evaluation only.

OCR extracts likely vendor, invoice number, date and total; it does not reliably infer parts/quantities. Enter replacement parts in the Parts step and review all OCR values. The service workflow is locally covered by Flutter tests, but a signed-in live service/bill/image save still needs acceptance on the connected account.

## Build and device notes

- `fleetpulse.apk` is at the repository root and is a debug APK; package `com.fleetpulse.bus_app`.
- The initial release APK was unsigned because `android/key.properties` and a release keystore are absent. Do not distribute that file.
- `flutter build apk --debug` succeeded, and ADB installation plus launch succeeded on `3b038054`.
- The Android build logs a future compatibility warning from `flutter_image_compress_common` concerning Built-in Kotlin migration; current build succeeds.

For the concise progress snapshot, see [PROJECT_STATE.md](PROJECT_STATE.md). For acceptance tracking, see [WORKING_CHECKLIST.md](WORKING_CHECKLIST.md).
