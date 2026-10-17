# FleetPulse Working Checklist

Updated 17 October 2026. See [PROJECT_HANDOVER.md](PROJECT_HANDOVER.md) for sequence and limits.

## Verified in this pass

- [x] Flutter analysis clean.
- [x] Full Flutter suite: 60 tests passed.
- [x] Narrow 320 px dashboard, vehicle list, service detail/history layout regression passed.
- [x] Python backend suite: 9 tests passed, including bill OCR upload, chat-history validation, contextual cost routing, and RAG/operational path selection.
- [x] Supabase migration list reconciled through `20261017170000`.
- [x] Render `/health`: status ok, Redis ok, Supabase auth ok, OCR ok, NVIDIA configured.
- [x] Debug APK built at repository root as `fleetpulse.apk`, installed and launched on OnePlus 7T.
- [x] Vehicle form offers photo/document attachments; service history allows photo attachments; media preview and delete/archive paths are implemented.
- [x] Vehicle overview shows actual attached documents instead of static sample rows.
- [x] Vehicle Service history exposes a vehicle-preselected service entry form.
- [x] Service entry collects work details, parts/costs and photos; bill-image OCR values are editable and linked bills are retrievable from service detail.
- [x] Dashboard To do and Maintenance Reminders include Due Soon/Overdue vehicles without open maintenance tasks, without duplicate reminders.
- [x] Widget regressions cover due-status reminders and the vehicle-level add-service action.
- [x] 320 px narrow-phone regression covers the service form stepper and vehicle selector.

## Remaining before production sign-off

- [x] Commit (`0b680ca`) and push source to `main`; Render health uptime reset and returned healthy after the push.
- [~] Run signed-in Fleet AI cost follow-up (“all vehicles”) and manual RAG question; health alone does not verify these full paths.
- [ ] Test OCR against representative bills and verify results persist to the signed-in company.
- [ ] Complete one signed-in service + bill OCR + parts + photos save/reopen on the OnePlus or client test account; confirm private image display.
- [ ] Run live CRUD/media tests for bus docs/photos, service photos, bill images, and role permissions.
- [ ] On the OnePlus, verify signed-in bill OCR accepts the JPEG, saves the invoice, and stores only explicitly entered parts plus the next due reminder.
- [ ] Test tenant isolation with at least two staging companies/accounts.
- [ ] Ingest authorized manuals into the RAG corpus; verify citations, tenant scoping, retrieval, and abstention. Current corpus has 0 chunks.
- [ ] Configure protected Android release signing and build a release APK before customer distribution.
- [ ] Review the Flutter plugin's Built-in Kotlin migration warning before upgrading Flutter/Gradle.

## Verified limits

- Render health shows service dependencies are configured/reachable; it does not prove a signed-in Fleet AI request, RAG retrieval, or OCR persistence path.
- An empty manual corpus means maintenance-manual questions cannot be grounded in manual passages yet.
- `fleetpulse.apk` is debug-signed for evaluation, not a production release.
- Fleet AI retains up to 50 messages in encrypted device storage per user and sends the latest 12 as context; it does not sync to another device or survive uninstall.
