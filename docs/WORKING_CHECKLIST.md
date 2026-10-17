# FleetPulse Working Checklist

Updated 17 October 2026. See [PROJECT_HANDOVER.md](PROJECT_HANDOVER.md) for sequence and limits.

## Verified in this pass

- [x] Flutter analysis clean.
- [x] Full Flutter suite: 56 tests passed.
- [x] Narrow 320 px dashboard, vehicle list, service detail/history layout regression passed.
- [x] Python backend/ingestion tests: 3 passed; Python syntax compilation passed.
- [x] Supabase migration list reconciled through `20261017170000`.
- [x] Render `/health`: status ok, Redis ok, Supabase auth ok, OCR ok, NVIDIA configured.
- [x] Debug APK built at repository root as `fleetpulse.apk`, installed and launched on OnePlus 7T.
- [x] Vehicle form offers photo/document attachments; service history allows photo attachments; media preview and delete/archive paths are implemented.
- [x] Vehicle overview shows actual attached documents instead of static sample rows.

## Remaining before production sign-off

- [ ] Review diff/secrets, commit and push source to `main`.
- [ ] Verify Render deploys new backend revision; inspect logs and run signed-in Fleet AI from app.
- [ ] Test OCR against representative bills and verify results persist to the signed-in company.
- [ ] Run live CRUD/media tests for bus docs/photos, service photos, bill images, and role permissions.
- [ ] Test tenant isolation with at least two staging companies/accounts.
- [ ] Ingest authorized manuals into the RAG corpus; verify citations, tenant scoping, retrieval, and abstention. Current corpus has 0 chunks.
- [ ] Configure protected Android release signing and build a release APK before customer distribution.
- [ ] Review the Flutter plugin's Built-in Kotlin migration warning before upgrading Flutter/Gradle.

## Verified limits

- Render health shows service dependencies are configured/reachable; it does not prove a signed-in Fleet AI request, RAG retrieval, or OCR persistence path.
- An empty manual corpus means maintenance-manual questions cannot be grounded in manual passages yet.
- `fleetpulse.apk` is debug-signed for evaluation, not a production release.
