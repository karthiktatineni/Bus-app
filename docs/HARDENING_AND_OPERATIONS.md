# HARDENING AND OPERATIONS: Git, Skills, Security, Monitoring, Maintenance, Crash Testing

Save as `docs/HARDENING_AND_OPERATIONS.md`. This extends `MASTER_AGENT_PROMPT.md`.
Cross-cutting rules (sections 1, 2, 3) apply from NOW, in every phase. Sections 4 to 8 are
delivered in Phase 4, Phase 5 and Phase 8 as marked.

"Perfect" is not a testable word. Everything below is measured against the targets in
section 0. A phase is not done until its targets are met and evidence is attached.

---

## 0. TARGETS (release gates)

| Area | Target |
|---|---|
| Crash-free sessions (Crashlytics) | 99.5% or better in pilot; zero known crashes at release |
| Crash-free users | 99.8% or better |
| Cold start (mid-range Android) | under 2.5 s |
| Scrolling | no dropped-frame jank on a 200-vehicle list (profile mode) |
| API latency (Supabase, p95, from India) | under 500 ms for reads, under 1 s for writes |
| Photo upload success rate | 99% or better with automatic retry |
| Security | all RLS tests pass; 0 critical and 0 high findings open; OWASP MASVS L1 checklist complete |
| Backup | restore drill completed and timed; RPO and RTO written in the runbook |
| Tests | analyze clean; unit, widget, integration, RLS and golden tests all green in CI |
| Alerts | every alert has an owner, a threshold, and a runbook link |

---

## 1. GIT AND VERSION CONTROL (now)

- Private remote repository (GitHub or GitLab). Push after every milestone.
- Branching: `main` is always releasable and protected. Work on `feature/<name>`,
  `fix/<name>`, `chore/<name>`. Merge only by pull request.
- Commits: Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
- Pull request template with: what changed, screenshots (for UI), tests added, migration
  included (yes/no), security impact (yes/no), rollback plan.
- Required CI checks before merge: `flutter analyze`, `flutter test`, backend SQL/RLS tests,
  secret scan, dependency audit, debug build.
- Versioning: semantic versions and git tags (`v0.1.0`, ...). Android `versionCode` and iOS
  build number increase on every release build.
- `.gitignore` must exclude: `.env*` (keep `.env.example`), keystores, `key.properties`,
  `*.p12`, `*.mobileprovision`, `service_role` keys, local Supabase volumes, build output.
- Secret scanning (gitleaks or GitHub secret scanning) in CI and as a pre-commit hook. If a
  secret is ever committed: rotate it immediately, do not just delete the commit.
- Dependabot or Renovate for Dart, GitHub Actions, and npm/Deno dependencies.
- `CODEOWNERS` for `backend/`, `supabase/migrations/`, and security-related folders.
- Database changes ONLY through versioned migration files in the repo. Never edit the
  production database by hand.

---

## 2. SKILLS (now)

Create reusable agent skills so every task follows the same procedure. Put them in
`.agents/skills/<name>/SKILL.md` (and mirror to `.claude/skills/` if the tool uses that
path). Each skill has: when to use it, step-by-step procedure, checklist, and a definition
of done. Read the relevant skill before starting any task of that kind.

Required skills:
1. `flutter-feature`: how to add a feature using our folder layout, shared widgets, design
   tokens, Riverpod controller, repository interface, tests.
2. `stitch-to-flutter`: how to rebuild a Stitch screen in Flutter (tokens only, never paste
   exported HTML), then do the side-by-side visual QA.
3. `supabase-migration-rls`: how to write a migration, add RLS policies for admin/staff and
   company isolation, write SQL tests that prove cross-company and staff-escalation
   attempts fail.
4. `security-review`: the checklist in section 4, run before every PR that touches auth,
   storage, permissions, networking, or secrets.
5. `crash-and-chaos-testing`: the scenarios in section 7 and how to record results.
6. `observability`: how to add logging, non-fatal error reporting, metrics, and alerts for a
   new feature.
7. `release-checklist`: versioning, signing, store assets, rollout, rollback.
8. `incident-response`: severity levels, first 15 minutes, communication, post-mortem.

Rule: if a task has a matching skill, the agent states which skill it used in the PR
description. If a skill is wrong or incomplete, fix the skill in the same PR.

---

## 3. ENVIRONMENTS (Phase 4)

Three separate Supabase projects (all in `ap-south-1`): `dev`, `staging`, `prod`. Separate
keys for each. The app takes its config from build flavors, never from hardcoded values.
Production data is never copied into dev. Use the seed script for dev and staging.
Staging must mirror production settings (RLS, storage rules, functions).

---

## 4. SECURITY (Phase 4 for backend, Phase 5 for app, Phase 8 for review)

### 4.1 Secure connections
- HTTPS/TLS only. Android: `cleartextTrafficPermitted="false"` in the network security
  config. iOS: keep App Transport Security enabled with no exceptions.
- Never log or print tokens, passwords, or full API responses.
- Certificate pinning: evaluate and DECIDE in `DECISIONS.md`. Pinning to a managed
  provider's certificates can cause an outage when certificates rotate. If used, pin public
  keys with a backup pin and a remote kill-switch. Default recommendation: no pinning for
  the pilot; rely on TLS plus short-lived tokens.

### 4.2 Authentication and sessions
- Supabase Auth with short-lived access tokens and refresh tokens.
- Store the session in the platform secure store (`flutter_secure_storage`: Keychain on
  iOS, encrypted storage on Android). Never in plain preferences.
- Password rules: minimum length 10, breached-password check if available, rate limiting
  and lockout on repeated failures.
- Admin accounts: enable MFA (TOTP) and require it for admins before release.
- Sign out of all devices must actually revoke sessions server-side.
- Invited users get single-use, expiring invite links.

### 4.3 Authorization (the most important part)
- Every table has Row Level Security enabled with no gaps. No table without a policy.
- Roles and `company_id` come from the database (`profiles`), never from client input.
- The `service_role` key exists ONLY inside Edge Functions and CI. It must never be in the
  app, the repo, or logs. Add a CI check that fails if it appears anywhere in the app.
- SQL tests that PROVE: (a) user A cannot read or write company B's rows in any table,
  (b) staff cannot delete vehicles, edit/delete service records, manage users, or edit
  company settings, (c) a disabled user loses access immediately, (d) storage objects obey
  the same rules.
- Storage: all buckets private; access through short-lived signed URLs (minutes, not days);
  enforce MIME types and size limits server-side.
- Edge Functions: verify the caller's JWT and role inside the function, validate inputs
  with a schema, rate limit, return generic errors.
- Audit log for sensitive actions: user invited/removed/role changed, vehicle deleted,
  service edited/deleted, settings changed, login failures.

### 4.4 App hardening
- Release builds use `--obfuscate --split-debug-info` and upload the symbols to Crashlytics.
- Disable debug banners, logs, and test menus in release.
- Hide app content in the app switcher for screens showing bills or user data (optional,
  decide in `DECISIONS.md`).
- Biometric lock (already in Settings) must really gate app resume after the chosen timeout.
- Validate all user input client-side for UX AND server-side for safety.
- Treat OCR text as untrusted input.

### 4.5 Process
- OWASP MASVS Level 1 checklist completed and saved in `docs/security.md`.
- Dependency audit in CI (`flutter pub outdated`, `npm audit`/OSV scanner).
- Written threat model (1 page): assets, actors, top 10 risks, mitigations.
- Before pilot: a manual attack pass using the "security-review" skill, plus an
  independent review if the budget allows.
- Privacy: collect the minimum; scrub PII from crash reports and logs; document what data
  is stored and where in the privacy policy.

---

## 5. MONITORING AND OBSERVABILITY (Phase 8, with hooks added from Phase 3)

Principle: the mobile app, the backend, and the business processes each need their own
monitoring. Grafana does not see inside the phone; Crashlytics does not see the database.

### 5.1 App: Firebase Crashlytics (+ optional Performance Monitoring)
- Wire BOTH Flutter error hooks, otherwise Dart errors are missed:
  `FlutterError.onError` -> `recordFlutterFatalError`, and
  `PlatformDispatcher.instance.onError` -> `recordError(fatal: true)`. Also capture errors
  from isolates.
- Android: Crashlytics Gradle plugin and mapping/symbol upload. iOS: dSYM upload as a build
  phase or CI step. Verify symbolicated stack traces with a deliberate test crash.
- Non-fatal logging for: failed uploads, OCR failures, sync/network errors, permission
  denied states. Add custom keys: app version, flavor, role, screen, and company id (hashed).
  NEVER log names, phone numbers, emails, or bill contents.
- Breadcrumb logs for the last user actions before a crash.
- Collection is disabled in debug builds and enabled in staging/prod. Respect a
  user-facing privacy statement.
- Firebase Performance (optional): app start time, screen rendering, network traces for the
  slowest calls.

### 5.2 Backend: Grafana
- Use Grafana Cloud (free tier is a sensible start; check current limits) or self-hosted
  Grafana.
- Data sources: the Supabase project metrics endpoint (Prometheus-compatible; verify the
  current setup in Supabase docs), plus Supabase log drains if available on the plan, plus
  synthetic uptime checks.
- Dashboards (provisioned as code and stored in `ops/grafana/`):
  1. Database: CPU, memory, disk, connections, slow queries, replication/backup status.
  2. API: request rate, error rate (4xx/5xx), latency p50/p95/p99.
  3. Auth: sign-ins, failures, lockouts.
  4. Storage: bytes stored, upload errors.
  5. Edge Functions: invocations, errors, duration (invite, reminders, OCR).
  6. Business: reminders sent per day, tasks overdue per company, services created, bills
     scanned, OCR confidence average.
- Alerts (to email plus Slack or WhatsApp-bridge/Telegram; pick one in Phase 1 notes):
  database CPU or disk above 80%, error rate above 2% for 5 minutes, p95 latency above
  threshold, daily-reminders job missed or failed, storage near quota, auth failure spike,
  backup failed, uptime check failing for 2 minutes.
- Every alert links to a runbook entry that says what to check and how to fix it.

### 5.3 Business and client-side health
- A `client_events` table (or Crashlytics custom events) records failed uploads and failed
  OCR with error codes only, no personal data, so Grafana can chart them.
- A scheduled "heartbeat" function that checks: reminders ran today, no stuck uploads, no
  orphaned storage files; it alerts if not.

### 5.4 Cost and quota watch
Alerts for Supabase plan limits (database size, egress, storage) and Firebase/Grafana
free-tier limits so the pilot never stops unexpectedly.

---

## 6. MAINTENANCE (Phase 8)

Write `docs/runbook.md` and `docs/maintenance_calendar.md`:

- **Daily (automated):** backups, uptime checks, heartbeat, alert review.
- **Weekly:** review Crashlytics top issues and fix or triage; review Grafana error trends;
  check failed jobs; review the audit log for anomalies.
- **Monthly:** dependency updates (Dart, Flutter, npm/Deno, GitHub Actions) via PRs with full
  CI; rotate non-expiring secrets that policy requires; **backup restore drill** (restore
  into a scratch project, verify data, record time taken); review user accounts and
  remove unused ones; cost review.
- **Quarterly:** Flutter stable upgrade on a branch with full regression; security review
  re-run; load test re-run; disaster-recovery rehearsal; review SLOs and alert noise.
- **Releases:** staged rollout (Android 10 to 20 to 50 to 100 percent; iOS phased release),
  watch Crashlytics and Grafana for 24 hours at each step, documented rollback plan
  (previous build available, backend migrations backward compatible for one version).
- **Backward compatibility:** the backend must tolerate the previous app version. Use
  expand-then-contract migrations. A minimum supported version check lets you force an
  update when needed.
- **Incident response:** severity levels SEV1 to SEV3, who is contacted, first 15 minutes,
  customer communication template, blameless post-mortem template.
- **Data lifecycle:** retention policy for photos and bills, export-all-data function for
  the client, deletion on request.

---

## 7. CRASH, CHAOS, AND QUALITY TESTING (Phase 5 for integration, Phase 8 for full pass)

Record every result in `docs/test_report.md` (scenario, device, result, bug link). Fix all
crashes and data-loss bugs. Retest after fixes.

### 7.1 Automated test layers
- Unit tests: validators, date/money formatting, OCR parser, schedule/due-date logic.
- Widget tests: every screen's loading, empty, error states; role-based UI.
- Golden tests: key components in light and dark.
- Integration tests (against a local or staging Supabase): login, add vehicle, add service
  with photos, staff permission denial, offline behavior.
- RLS/SQL tests in CI (section 4.3).
- Test coverage reported in CI; critical logic (due dates, schedules, permissions, money)
  at 90% or better.

### 7.2 Crash and chaos scenarios (manual + scripted)
App lifecycle and device:
- Kill the app mid-save of a service record; reopen: draft is restored or clearly lost with
  a message, never silent corruption.
- Background the app during camera capture and during upload; return.
- Rotate, split-screen, font scale 1.3x and above, dark mode toggle mid-flow.
- Low memory (many photos in one service), low storage, battery saver.
- Revoke camera/photo permission while the app is open; deny permanently.
- Time zone change and wrong device clock (token validity and due-date labels).
Network:
- Airplane mode at every step of every flow; flaky 2G throttling; switching Wi-Fi to mobile
  data during an upload; request timeouts; server returning 500; DNS failure.
- Upload interrupted at 50%: resumes or retries without duplicates.
- Token expires mid-session: silent refresh or clean re-login without losing work.
Data:
- 1,000 vehicles and 20,000 service records: lists stay smooth, search stays fast.
- Very long text, emoji, RTL text, special characters in every field; empty strings;
  duplicate registration numbers; huge images (20 MB+); corrupted image files.
- Two users editing the same record at once: last-write handling is defined and tested.
Automated monkey testing:
- Run `adb shell monkey` (Android) and a Flutter integration "random tap" test for at
  least 30 minutes per release candidate; zero crashes allowed.
Cloud device lab:
- Firebase Test Lab (or equivalent) on a matrix: low-end Android (2 GB RAM, Android 10),
  mid-range Android 12/13, recent Android 14/15, small iPhone, current iPhone. Run the
  robo test and the integration suite.
Backend and security:
- Load test with k6: ramp to 10x expected users; report p95 latency and error rate against
  the targets; watch Grafana during the test.
- Abuse tests: cross-company ID guessing, staff calling admin functions, expired/forged
  tokens, oversized payloads, rapid-fire requests (rate limit works).
- Simulated outage: Supabase unreachable. The app shows a friendly state, never a crash, and
  recovers automatically when the backend returns.
- Backup restore drill (section 6).
Observability proof:
- Trigger a deliberate non-fatal and a deliberate crash in staging and confirm they appear in
  Crashlytics with a readable stack trace. Trigger a test alert and confirm it reaches the
  channel.

### 7.3 Real-world pilot
- Two or three real drivers/mechanics use it for one to two weeks on their own phones.
- Collect feedback and every crash. Fix, then expand.

---

## 8. RELEASE GATE CHECKLIST (all must be YES)

- [ ] All section 0 targets met, with evidence linked
- [ ] CI green on `main`; release built from a tagged commit
- [ ] RLS and cross-company tests pass; no service_role key in the app bundle
- [ ] All traffic is HTTPS; cleartext disabled; secure session storage verified
- [ ] Admin MFA enabled
- [ ] Crashlytics receiving symbolicated crashes from a staging build
- [ ] Grafana dashboards live; alerts tested end to end
- [ ] Backup restore drill done and timed
- [ ] Crash/chaos scenarios executed and recorded; no open crash or data-loss bugs
- [ ] Monkey test 30 min clean on Android; Test Lab matrix clean
- [ ] Privacy policy and terms published; data collection documented
- [ ] Runbook, maintenance calendar, incident process, and rollback plan written
- [ ] Staged rollout plan prepared

---

## 9. HUMAN TASKS TO ADD TO `HUMAN_TASKS.md`

1. Create Firebase project; enable Crashlytics (and Performance if wanted); add Android and
   iOS apps; provide config files via secure channel.
2. Create Grafana Cloud account; create an API token; choose the alert channel.
3. Create three Supabase projects (dev, staging, prod) in Mumbai; upgrade prod to a plan
   with daily backups; enable log drains if the plan allows.
4. Provide a private Git remote and enable branch protection and secret scanning.
5. Provide test devices (one low-end Android, one mid/high Android, one iPhone) and a
   Firebase Test Lab quota.
6. Decide who receives alerts and who is the incident owner.
7. Provide 30 sample bills for OCR evaluation, and 2 to 3 pilot users.
8. Write or review the privacy policy and terms with a lawyer if possible.
