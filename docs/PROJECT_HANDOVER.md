# FleetPulse Project Handover

Updated 17 October 2026.

## Current verified state

- Checkout: `feature/client-preview`, based on the latest `origin/main`. Changes from this pass remain uncommitted pending final review/push.
- Remote Supabase migrations through `20261017170000` are applied and match local migration history.
- Render health at `https://fleetpulse-ocr.onrender.com/health` is currently healthy. The deployed backend may still be the older revision until the source changes are pushed and Render redeploys.
- The OnePlus 7T is connected as ADB device `3b038054`. Debug APK `fleetpulse.apk` was installed and launched.
- All 56 Flutter tests, `flutter analyze`, and 3 Python tests passed. Python syntax compilation passed.
- No authorized manuals are currently in the RAG corpus; manual-grounded answers are not ready until ingestion.

## Changes made

1. Replaced retired NVIDIA embedding model usage with `nvidia/nemotron-3-embed-1b` for queries and passage ingestion, expecting 2048 values.
2. Added/applied a RAG migration using `halfvec(2048)` storage and HNSW index while retaining the old vector table.
3. Added retry and response validation to knowledge ingestion, and modernized Redis startup/shutdown to FastAPI lifespan events.
4. Added admin media delete/archive flows for bills, service history, and vehicles; added bus photo/document attachment on add/edit and service-history photo attachments.
5. Replaced placeholder vehicle document rows with database-backed data and made uploaded media previewable/zoomable.
6. Fixed and regression-tested responsive layouts at 320 px width.

## Remaining work

1. Review staged files for secrets and generated content, then commit and push the changes to `main`. `origin/main` currently equals the starting commit of this work.
2. Confirm Render deploys the commit. Check service logs and run a signed-in Fleet AI question in the app; `/health` does not confirm successful database/RAG/model calls.
3. Test a real OCR bill scan and fleet-data question, then verify two test tenants cannot read each other's fleet data or RAG chunks.
4. Ingest authorized manuals and verify citations, retrieval quality, tenant scoping, and abstention for unsupported questions.
5. Test photo/document upload, display, and deletion with admin and staff accounts against live RLS/Storage.
6. Set up protected Android release signing for customer distribution. The root APK is debug-signed and suitable for evaluation only.

## Build and device notes

- `fleetpulse.apk` is at the repository root and is a debug APK; package `com.fleetpulse.bus_app`.
- The initial release APK was unsigned because `android/key.properties` and a release keystore are absent. Do not distribute that file.
- `flutter build apk --debug` succeeded, and ADB installation plus launch succeeded on `3b038054`.
- The Android build logs a future compatibility warning from `flutter_image_compress_common` concerning Built-in Kotlin migration; current build succeeds.

For the concise progress snapshot, see [PROJECT_STATE.md](PROJECT_STATE.md). For acceptance tracking, see [WORKING_CHECKLIST.md](WORKING_CHECKLIST.md).
