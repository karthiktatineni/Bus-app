# FleetPulse Project Handover

Updated 17 October 2026.

## Current verified state

- Current service/OCR and Fleet AI memory changes are committed as `0b680ca` and pushed to GitHub `main`.
- Remote Supabase migrations through `20261017170000` are applied and match local migration history.
- After the push, Render health uptime reset and `/health` returned healthy Redis, Supabase auth, OCR, and NVIDIA configuration. A signed-in AI request still needs live verification.
- The OnePlus 7T is connected as ADB device `3b038054`. Debug APK `fleetpulse.apk` was installed and launched.
- All 60 Flutter tests, `flutter analyze`, and 9 Python backend tests passed.
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
12. The service form uses a vertical stepper on narrow phones and expanded, ellipsized vehicle dropdowns; a 320 px regression test confirms it does not overflow.
13. Fleet AI now keeps up to 50 transcript messages in encrypted, per-user device storage and sends its most recent 12 messages as working context. Backend follow-ups resolve against this history; cost totals are routed to the database RPC, “all vehicles” forces a fleet-wide scope, and omitted dates default to the last 30 days. Operational data questions avoid unnecessary embedding calls; knowledge questions still use vector RAG.
14. Chat memory is device-local. It does not sync across devices and will not survive uninstall or device loss. Cloud-synced conversation memory would need a separate authenticated, RLS-protected storage design.

## Remaining work

1. Run a signed-in Fleet AI cost question followed by “all vehicles,” then ask a manual-grounded question. Verify the database amount, date range, cross-turn interpretation, RAG citations and abstention on missing manual evidence; `/health` does not confirm these paths.
3. Test a real OCR bill scan and fleet-data question, then verify two test tenants cannot read each other's fleet data or RAG chunks.
4. Ingest authorized manuals and verify citations, retrieval quality, tenant scoping, and abstention for unsupported questions.
5. Test photo/document upload, display, and deletion with admin and staff accounts against live RLS/Storage.
6. Set up protected Android release signing for customer distribution. The root APK is debug-signed and suitable for evaluation only.

OCR extracts vendor, invoice number, date and total when readable; it does not identify replacement parts. Parts begin empty and only names entered by the user are saved. To save a service record, attach at least one service photo and a bill image, enter/review the bill total, and specify the next maintenance task and due date. The app does not add GST or calculate the bill total. The service workflow is locally covered by Flutter tests, but a signed-in live service/bill/image save still needs acceptance on the connected account.

## Build and device notes

- `fleetpulse.apk` is at the repository root and is a debug APK; package `com.fleetpulse.bus_app`. Current SHA-256: `64F3A53E87040732BB7D028B5D15467F920D24FD6123D9251D8476BD1BC8B106`.
- The initial release APK was unsigned because `android/key.properties` and a release keystore are absent. Do not distribute that file.
- `flutter build apk --debug` succeeded, and ADB installation plus launch succeeded on `3b038054`.
- The Android build logs a future compatibility warning from `flutter_image_compress_common` concerning Built-in Kotlin migration; current build succeeds.

For the concise progress snapshot, see [PROJECT_STATE.md](PROJECT_STATE.md). For acceptance tracking, see [WORKING_CHECKLIST.md](WORKING_CHECKLIST.md).
