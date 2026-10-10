# Human Tasks

This document contains a numbered checklist of actions that the human operator must perform. These involve third-party accounts, credentials, physical devices, or out-of-scope manual operations.

## Phase 2: Design
- [ ] 1. Generate missing screens in Stitch using the prompts provided in `STITCH_PROMPTS.md` and export them to `screen_designs/`.

## Phase 4: Backend Setup
- [ ] 2. Decide between Supabase (default) and Firebase.
- [ ] 3. Create the backend project (e.g. Supabase project).
- [ ] 4. Retrieve the Project URL and Anon Key. Add them to an `.env` file in the project root.
- [ ] 5. Confirm the region selection (e.g., `ap-south-1` for Indian data residency if required).

## Phase 6: OCR Setup
- [ ] 6. Gather and provide an evaluation set of at least 30 real or realistic Indian maintenance/parts bills to test OCR accuracy.
- [ ] 7. (Optional) If on-device OCR fails the 85% accuracy mark, provision a Google Cloud Service Account with Document AI enabled (or AWS Textract) and supply the API keys to the backend.

## Phase 7: Notifications & iOS Setup
- [ ] 8. Provide an Apple Developer Account.
- [ ] 9. Create and provide an APNs (Apple Push Notification service) key for iOS push notifications.
- [ ] 10. Provision a transactional email provider account (e.g., Resend, SendGrid) and provide its API key to the backend.

## Phase 8: Hardening and Release
- [ ] 11. Setup a Sentry (or Firebase Crashlytics) project and provide the DSN for crash reporting.
- [ ] 12. Create a secure Android signing key and safely back it up.
- [ ] 13. Set up the iOS App ID, provisioning profiles, and TestFlight deployment (requires macOS or Codemagic).
- [ ] 14. Create the Google Play Console application and prepare for Internal Testing.

## Hardening and Operations (Phase 8 & Ongoing)
- [ ] 15. Create Firebase project; enable Crashlytics (and Performance if wanted); add Android and iOS apps; provide config files via secure channel.
- [ ] 16. Create Grafana Cloud account; create an API token; choose the alert channel.
- [ ] 17. Create three Supabase projects (dev, staging, prod) in Mumbai; upgrade prod to a plan with daily backups; enable log drains if the plan allows.
- [ ] 18. Provide a private Git remote and enable branch protection and secret scanning.
- [ ] 19. Provide test devices (one low-end Android, one mid/high Android, one iPhone) and a Firebase Test Lab quota.
- [ ] 20. Decide who receives alerts and who is the incident owner.
- [ ] 21. Provide 30 sample bills for OCR evaluation, and 2 to 3 pilot users.
- [ ] 22. Write or review the privacy policy and terms with a lawyer if possible.
