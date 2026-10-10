# PHASE 4 PROMPT: TURN THE MOCK APP INTO THE REAL APP

DO NOT USE THIS PROMPT until Phase 3 is complete and you have typed `PHASE 3 APPROVED`
(all 8 milestones done, analyze clean, tests green, client demo done). Save as
`docs/PHASE4_REAL_APP_PROMPT.md`. Then paste everything below the line to the agent.

---

# PASTE FROM HERE

PHASE 3 IS APPROVED. We now stop building demos and build the REAL product: real
database, real login, real photo storage, real data. Goal: when you finish, the app
contains NO fake data, NO demo logins, and NO mock code in production paths.

Read first: `docs/MASTER_AGENT_PROMPT.md` (Phases 4 and 5), `docs/ARCHITECTURE.md`
(sections 4 and 9), `docs/HARDENING_AND_OPERATIONS.md` (sections 1 to 4), `docs/DECISIONS.md`,
and the skills in `.agents/skills/` (especially `supabase-migration-rls` and
`security-review`). Same rules as before: work on feature branches, one PR per
milestone, real `flutter analyze` and `flutter test` output in every report (say
UNVERIFIED if you cannot run them), no changes outside this repo, and ask me for
anything that needs my accounts.

## STEP 0: SAFETY NET (before changing anything)

1. Make sure `main` is green. Tag it `demo-mock-v1` and push the tag, so the full mock
   demo can always be restored from git.
2. Build and keep a release APK of the mock version as `demo-mock-v1.apk` (do not commit
   the APK; store it in the GitHub release for the tag).
3. Create branch `feature/phase4-real-backend`.

## STEP 1: PREREQUISITES CHECK (stop and ask me if any is missing)

List which of these exist and which I still owe you, as a numbered checklist in
`docs/HUMAN_TASKS.md`:
- Supabase projects `dev`, `staging`, `prod` in ap-south-1 (Mumbai), with URLs and anon
  keys provided to me through a safe channel (never pasted in chat or committed)
- Supabase CLI installed and logged in; Docker installed for local Supabase
- final org / bundle ID confirmed (it is tied to Firebase and Supabase config)
- Firebase project created (for Crashlytics and push)
Do not invent keys. Do not create paid resources. Use the local Supabase stack
(`supabase start`) for development until the hosted projects are ready.

## STEP 2: DATABASE (Milestone 4A)

Use `supabase-migration-rls`. Everything as versioned SQL migrations in
`supabase/migrations/`.
1. Create all tables from `IMPLEMENTATION_PLAN.md` plus the approved additions
   (`notifications`, `service_schedules`, `vehicle_photos`, `audit_log`, `device_tokens`,
   soft delete on vehicles, `maintenance_tasks` links, `numeric(12,2)` money,
   `created_by` and `updated_at` everywhere). Remove the circular bill link.
2. Row Level Security on every table, company isolation, admin/staff rules per the role
   matrix in ARCHITECTURE.md.
3. Triggers: `updated_at`; saving a service record updates the matching
   `service_schedules` and closes the related task; audit log on sensitive actions.
4. Storage: private buckets, policies, MIME and size limits, signed URLs.
5. SQL tests (pgTAP or equivalent) proving: cross-company access is blocked on every
   table and bucket; staff cannot do admin actions; disabled users lose access.
6. Edge Functions: `invite-user` (admin only), `daily-reminders`, `bootstrap-company`
   (see Step 3). Verify the JWT and role inside each function.
7. Report: the schema diagram, test output, and `docs/api.md`.

## STEP 3: FIRST-RUN WITHOUT MOCK DATA (Milestone 4B)

A real app starts empty, so design how the first account is created. No public sign-up.
- A one-time, secure `bootstrap-company` process (a CLI script or a protected function)
  that I run once to create the company and the first admin account.
- That admin invites everyone else through the app.
- A development seed script (`supabase/seed.sql`) that is used ONLY for dev and staging
  and never runs on prod. It may reuse the 10 realistic buses so development is pleasant.
  It is test data in the backend, not mock code in the app.
- Empty states in the app must now look right for a brand-new company (no vehicles yet,
  no tasks, first-time guidance).

## STEP 4: REAL REPOSITORIES IN THE APP (Milestone 5A)

1. For every feature, add a real implementation next to the mock one, behind the existing
   repository interface (`SupabaseAuthRepository`, `SupabaseVehicleRepository`, and so
   on). UI files must not change except provider wiring and genuine bug fixes.
2. Config through build flavors (`dev`, `staging`, `prod`) with `--dart-define` values.
   No keys in source. `.env.example` documents the variables.
3. Auth: real sign-in, secure session storage (`flutter_secure_storage`), sign-out of all
   devices, password reset, change password, invite acceptance, disabled-user handling.
   Admin MFA per the hardening doc.
4. Real photo and bill upload: use the existing `MediaService`; compress, upload with
   progress, retry, queue on failure, signed URLs for display, delete (admin only).
5. Settings: persist user and company settings to the database.
6. Map backend errors to friendly messages; handle offline gracefully; session expiry
   mid-flow must not lose in-progress work.
7. Integration tests against local Supabase: login, create vehicle, add service with
   photos, staff denial, cross-company denial.

## STEP 5: REMOVE ALL MOCK AND USELESS CODE (Milestone 5B)

Only after Step 4 passes against the real backend:
1. Delete `lib/mock/`, every `Mock*Repository`, `MockOcrService`, `mock_delay.dart`,
   `mock_data.dart`, and the mock providers from production code.
2. Delete `assets/mock/` and any placeholder images, fake bill files, and demo-only
   assets. Remove them from `pubspec.yaml`.
3. Remove the demo credentials hint from the login screen and any "demo mode" switch.
4. Remove fake "Scanning..." OCR behavior. Until Phase 6, the bill step lets the user
   capture the bill image and type the fields manually; the scan button is hidden behind
   a feature flag that defaults to off. Do not ship fake OCR output.
5. Remove unused packages, unused assets, unused strings, dead code, commented-out code,
   and TODOs. Run `dart fix --apply` and a dead-code check.
6. Tests: do NOT delete tests. Move the in-memory fakes into `test/fakes/` (or
   `test/support/`) so widget and unit tests still run fast without a network. Fakes live
   only under `test/` and must never be imported from `lib/`.
7. Keep `demo-mock-v1` as the only home of the old demo. Do not keep a demo mode in the
   production app.
8. Write the verification: run these checks and paste the output
   - search `lib/` and `pubspec.yaml` for: `mock`, `Mock`, `fake`, `demo`, `lorem`,
     `admin@demo.com`, `demo1234`, `mock_data` (expected: zero hits, or each remaining
     hit justified)
   - `flutter analyze`, `flutter test`, and the integration tests
   - release build size before and after
   - a short list of every file deleted

## STEP 6: REAL-DEVICE ACCEPTANCE

I will test on real phones against the `staging` backend. Provide:
- a release APK built from the `staging` flavor
- a 10-step test script in `docs/ACCEPTANCE_TEST.md` covering: first admin login, invite a
  staff user, add a bus with photos, add a service with before/after/parts photos and a
  bill photo, see it appear on the dashboard and history, staff restrictions, sign out,
  airplane-mode behavior, and password reset
- the exact commands to build each flavor

## DONE WHEN

- The app runs against the real backend in dev and staging, with zero mock code or mock
  data in `lib/` and `assets/`
- RLS and storage tests pass in CI; integration tests pass
- No keys or secrets in the repository or the app source
- A brand-new company can be created, populated, and used end to end
- Report in the standard phase format, then wait for `PHASE 5 APPROVED` before starting
  OCR (Phase 6 in MASTER_AGENT_PROMPT.md), notifications, monitoring, and release
  hardening per the remaining phases and `HARDENING_AND_OPERATIONS.md`.
