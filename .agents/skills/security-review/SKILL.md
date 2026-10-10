---
name: security-review
description: The checklist in section 4, run before every PR that touches auth, storage, permissions, networking, or secrets.
---
# security-review

## When to use
Before submitting a PR that touches auth, storage, permissions, networking, or secrets.

## Procedure
Run through the Section 4 checklist from `HARDENING_AND_OPERATIONS.md`.
1. Check HTTPS/TLS only.
2. Check token storage (secure storage only).
3. Verify RLS is enabled on all touched tables.
4. Ensure `service_role` key is not used.
5. Verify storage buckets are private and use signed URLs.

## Definition of Done
- No critical or high findings.
- RLS tests verify changes.
