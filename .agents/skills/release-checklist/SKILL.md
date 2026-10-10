---
name: release-checklist
description: Versioning, signing, store assets, rollout, rollback.
---
# release-checklist

## When to use
When preparing to release the app to pilot or production.

## Procedure
1. Bump semantic version and build numbers.
2. Build with `--obfuscate --split-debug-info` and upload symbols.
3. Prepare store assets.
4. Execute staged rollout plan.
5. Monitor Crashlytics and Grafana for 24 hours.

## Definition of Done
- Release gate checklist from `HARDENING_AND_OPERATIONS.md` is complete.
