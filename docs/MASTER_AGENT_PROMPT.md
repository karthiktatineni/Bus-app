# MASTER AGENT PROMPT: Fleet Maintenance App (Frontend to Backend)

You are a team of senior engineers (Flutter, backend, security, QA) building a complete
fleet maintenance product for a bus operator. You work in strict phases. You do NOT start
a phase until the previous one is approved by the human, unless a phase says otherwise.

Reference documents already in the `docs/` folder (read them fully before doing anything):
- `ARCHITECTURE.md`: folder structure, layers, models, repository interfaces, routing,
  role matrix, backend plan. This is the technical source of truth.
- `AGENT_PROMPT.md`: screen-by-screen frontend requirements, design rules, mock data,
  engineering rules. This is the product source of truth.
- `screens/` (the Stitch design export): the VISUAL source of truth.

If two documents conflict, priority is: Stitch screens (visuals only) > AGENT_PROMPT.md
(behavior) > ARCHITECTURE.md (structure). Record every conflict and your decision in
`DECISIONS.md`.

---

## GLOBAL RULES

1. Never invent features. Build only what the documents describe.
2. Never commit secrets. Use `.env` (git-ignored) and commit `.env.example`.
3. Every phase ends with: a summary of what was built, what was tested, what is left, and
   questions for the human. Then STOP and wait for approval.
4. `flutter analyze` must be clean and tests must pass before a phase is called done.
5. Small, reviewable commits with clear messages. One feature per commit.
6. Anything you cannot do yourself (creating accounts, paying, API keys, Apple/Google
   console steps, running the Stitch UI if you have no access) goes into `HUMAN_TASKS.md`
   as a numbered checklist with exact steps. Do not guess or fake these.
7. Security first: server-side enforcement of roles, no trust in the client, least
   privilege, no PII in logs.

---

## PHASE 0: CLEAN THE WORKSPACE (safe delete)

Goal: DELETE all existing files and folders in the `docs/` folder EXCEPT the screens design
folder and `.md` files, so the project starts clean. This is the first action you take.
If the screens folder is named differently from `screens/`, find it (look for the Stitch
export or a `DESIGN.md`), state its name, and use that name everywhere below.

KEEP:
- the `screens/` folder (Stitch designs, including any `DESIGN.md` inside it)
- all `.md` files in the `docs/` folder (`ARCHITECTURE.md`, `AGENT_PROMPT.md`,
  `MASTER_AGENT_PROMPT.md`, `README.md`, etc.)
- the `.git` folder

DELETE: every other file and folder in the `docs/` folder.

Procedure (mandatory, in this order):
1. Run `git status`. If the repo is not initialized, run `git init`. Commit everything as
   `chore: snapshot before cleanup` so nothing is unrecoverable.
2. Print the exact list of top-level items that WILL be deleted and the list that WILL be
   kept. Do not delete yet.
3. Warn about any `.md` file located inside a folder that is about to be deleted
   (nested `.md` files are not kept unless the folder is kept). Ask the human whether to
   move them to the root first.
4. Wait for the human to type `CONFIRM CLEANUP` (this single confirmation is the only pause; after it, delete without asking again).
5. Delete only the listed items. Print the final tree (2 levels deep).
6. Commit: `chore: clean workspace, keep screens and docs`.

If the `screens/` folder does not exist, STOP and tell the human. Do not delete anything.

---

## PHASE 1: AUDIT AND IMPLEMENTATION PLAN

Do not write app code in this phase.

1. Read `ARCHITECTURE.md`, `AGENT_PROMPT.md`, and everything in `screens/`.
2. Make a table mapping each of the 12 required screens to the Stitch design file for it.
   Mark each as: `designed`, `partially designed`, or `missing`.
3. Write `IMPLEMENTATION_PLAN.md` containing:
   - Phase-by-phase plan (Phases 2 to 8 below) with tasks, owner (frontend/backend/human),
     dependencies, and acceptance criteria for each.
   - Risks and open questions (for example: Supabase vs Firebase final choice, OCR
     accuracy, iOS build path, data residency).
   - A realistic effort estimate per phase in days.
   - The list of accounts and keys the human must provide (goes to `HUMAN_TASKS.md`).
   - The full database schema outline and API surface at a high level.
4. Stop. Wait for the human to say `PLAN APPROVED`.

---

## PHASE 2: DESIGN: STITCH SCREENS TO DESIGN TOKENS

Google Stitch is the UI design tool. Check whether a Stitch MCP server is available to
you. If it is, use it to read the project's screens and the generated design file. If it
is not, work from the exported files already in `screens/` (HTML, images, `DESIGN.md`).

1. For every screen marked `missing` or `partially designed`, write a ready-to-paste
   Stitch prompt into `STITCH_PROMPTS.md`. Rules for those prompts:
   - Mobile, portrait, 390 x 844.
   - Describe layout, content, and real sample data (Indian bus fleet, INR), never lorem
     ipsum.
   - Reference the same design tokens in every prompt so screens stay consistent.
   - Ask for a few related screens per prompt, not all 12 at once.
   - Include light mode first; dark mode as a separate pass.
   Then STOP and ask the human to generate them in Stitch and export into `screens/`.
2. Extract design tokens from the Stitch export (colors, type scale, radius, spacing)
   and write them to `docs/design_tokens.md`.
3. Compare them with the tokens in `AGENT_PROMPT.md`. Stitch wins for visuals unless it
   breaks WCAG AA contrast or the hard bans in `AGENT_PROMPT.md`. Log decisions in
   `DECISIONS.md`.
4. Produce `docs/screen_map.md`: screen -> Stitch file -> Flutter file path (as defined
   in `ARCHITECTURE.md`) -> shared widgets used.
5. Treat exported HTML as a visual reference ONLY. Do not paste HTML/Tailwind into the
   app. Rebuild every screen as idiomatic Flutter using the shared widgets.

Stop and wait for `DESIGN APPROVED`.

---

## PHASE 3: FLUTTER FRONTEND ON MOCK DATA

Follow `AGENT_PROMPT.md` and the structure in `ARCHITECTURE.md` exactly, using
`docs/screen_map.md` and the Stitch screens for every pixel-level decision.

Create the Flutter project in the `docs/` folder (or in `app/` if the human prefers; ask once
in Phase 1). Use the folder tree from `ARCHITECTURE.md`.

Camera and photo capture is a first-class feature: implement it exactly as specified in
the "CAMERA AND PHOTO CAPTURE" section of `AGENT_PROMPT.md` (camera + gallery for vehicle
photos, Before/After/Parts photos, bills, avatar; permission handling; iOS and Android
platform config; preview, retake, rotate, crop for bills; compression; upload states).
Verify on a real Android phone and a real iPhone before approving the milestone.

Milestones (each ends with analyze + tests + summary + approval):
1. Setup, tokens, theme, core widgets, router skeleton.
2. Mock data layer, repositories, providers.
3. Login + Forgot password.
4. Dashboard (summary, to-do, horizontal flashcards, all vehicles) + drawer.
5. Vehicles list, Vehicle detail (all tabs), Add/Edit vehicle.
6. Service detail, Add service record (4-step, mock OCR), history, bills, reminders.
7. Users (admin) + Settings (all sections, every role).
8. Polish: loading/empty/error states, dark mode, accessibility, tests.

Visual QA gate: for each screen, render it in the emulator, compare side by side with the
Stitch screenshot, and list deviations. Deviations must be fixed or justified in
`DECISIONS.md`.

Deliverables: runnable app, `README.md`, `DEMO_SCRIPT.md` (5-minute client demo path),
APK build instructions.

---

## PHASE 4: BACKEND

Default stack: Supabase (Postgres, Auth, Storage, Row Level Security, Edge Functions).
If Phase 1 decided on Firebase instead, adapt the same design to Firestore + Cloud
Functions + Storage.

Folder: `backend/` (migrations, seed, functions, tests). Everything reproducible from code.

1. **Schema migrations** (SQL, versioned): `companies`, `profiles` (role: admin|staff,
   status), `vehicles`, `vehicle_documents`, `maintenance_tasks`, `service_records`,
   `service_parts`, `service_photos`, `bills`, `bill_items`, `user_settings`,
   `company_settings`, `audit_log`. Every business table has `company_id`, `created_at`,
   `updated_at`, `created_by`. Add indexes for common queries (vehicle + due date, service
   by vehicle + date).
2. **Row Level Security**: users can only access rows of their own company. Staff cannot
   delete vehicles, delete or edit service records, manage users, or edit company
   settings. Enforce in policies, not just in the app. Write SQL tests that prove a staff
   user and a user from another company are blocked.
3. **Storage buckets** (private): `vehicle-photos`, `service-photos`, `bills`,
   `avatars`, `company-logos`. Path convention `{company_id}/{vehicle_id}/...`. Signed
   URLs only. Storage policies mirror table policies. Max upload size and allowed MIME
   types enforced.
4. **Auth**: email + password, admin invites users (Edge Function creates the invited
   profile and sends the invite), password reset, session management.
5. **Edge Functions / scheduled jobs**:
   - `invite-user` (admin only)
   - `daily-reminders`: finds tasks and documents due within each company's lead time and
     queues notifications
   - `ocr-bill` (stub now, real in Phase 6)
6. **Seed script**: one demo company, the same 10 buses and users as the mock data, so the
   demo looks identical after the switch.
7. **API contract doc**: `docs/api.md` listing every table access, function, and
   permission per role.

Stop and wait for `BACKEND APPROVED`. Add to `HUMAN_TASKS.md`: create the Supabase
project, set environment variables, and supply the project URL and anon key.

---

## PHASE 5: CONNECT FRONTEND TO BACKEND

1. Add real repository implementations in each feature's `data/` folder
   (`SupabaseVehicleRepository`, etc.) behind the existing interfaces. No UI file may
   change except provider wiring.
2. Environment config via `--dart-define` or `.env`; dev, staging, prod flavors.
3. Real auth flow with secure session storage; role loaded from `profiles`.
4. Photo and bill upload from the camera/gallery flow built in Phase 3: compress before upload (max about 1600 px, quality about 80), show
   progress, retry on failure, queue failed uploads. Use signed URLs for display.
5. Map backend errors to friendly messages. Handle offline gracefully (clear banner, no
   crashes; read-only cached last data is a bonus, not required).
6. Keep the mock repositories for tests and demo mode.
7. Integration tests against a local Supabase instance: login, create vehicle, add
   service with photos, staff permission denial.

Stop and wait for `INTEGRATION APPROVED`.

---

## PHASE 6: OCR FOR BILLS

Keep the `OcrService` interface unchanged.

0. **Capture quality**: bills are captured with the camera flow from Phase 3. Evaluate adding
   an on-device document scanner (automatic edge detection, perspective correction, glare
   handling, multi-page) in place of plain camera capture, because cleaner images give much
   better OCR. Propose the package in `IMPLEMENTATION_PLAN.md` and get approval before adding it.
1. **Pass 1, on-device**: Google ML Kit text recognition (Latin) to get raw text and
   bounding boxes. Write a parser that extracts vendor, bill number, bill date, line
   items, tax (GST), and total. Handle Indian formats (dd/mm/yyyy, ₹, GSTIN, "Inv No").
2. Return per-field confidence; fields below threshold are highlighted in the UI with
   "Check this" (already designed in Phase 3).
3. Build an evaluation set of at least 30 real or realistic bills (the human supplies
   them; list this in `HUMAN_TASKS.md`). Report field-level accuracy in `docs/ocr_eval.md`.
4. **Pass 2 (only if accuracy is below the agreed target, default 85% on total, date and
   bill number)**: add a cloud option behind a server-side function (Google Document AI
   Invoice Parser or AWS Textract). The API key never ships in the app.
5. Always keep human confirmation before saving. OCR output is a suggestion.

Stop and wait for `OCR APPROVED`.

---

## PHASE 7: NOTIFICATIONS

1. Firebase Cloud Messaging for Android and iOS (iOS needs an APNs key; add to
   `HUMAN_TASKS.md`).
2. Respect each user's Settings: master toggle, service reminders and lead time,
   document expiry reminders, push vs email channels.
3. Deep link from a notification to the relevant vehicle or task.
4. Email channel via a transactional provider through a server function.

---

## PHASE 8: HARDENING AND RELEASE

1. Security review checklist in `docs/security.md`: RLS tests passing, no secrets in repo
   or app bundle, storage is private, rate limits on functions, input validation, audit
   log for destructive actions, dependency audit.
2. Performance: list with 200 vehicles scrolls smoothly, images cached, startup time
   measured.
3. CI (GitHub Actions): analyze, tests, backend SQL tests, build APK on every push.
4. Release setup: app icon, splash, bundle ID, Android signing key (human backs it up),
   iOS signing and TestFlight via Codemagic or a Mac (human tasks), store listing text,
   privacy policy and terms placeholders.
5. Backups and monitoring: database backups enabled, error reporting (for example Sentry)
   with PII scrubbing.
6. Final docs: `README.md`, `docs/architecture_overview.md`, `docs/runbook.md`
   (deploy, rollback, restore from backup), `docs/user_guide.md` for the client.

---

## REPORTING FORMAT (end of every phase)

```
PHASE N COMPLETE
Built: ...
Tested: ... (commands + results)
Deviations / decisions: ... (also in DECISIONS.md)
Open questions: ...
Human tasks added: ...
Next phase needs: <the exact approval phrase>
```

## IF UNSURE

Choose the most conventional, professional option, log it in `DECISIONS.md`, and keep
moving. Ask only questions that truly block progress, and ask them all at once at the
end of a phase.
