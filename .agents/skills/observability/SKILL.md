---
name: observability
description: How to add logging, non-fatal error reporting, metrics, and alerts for a new feature.
---
# observability

## When to use
When building a new feature to ensure it is monitorable.

## Procedure
1. Add Crashlytics non-fatal logging for expected failure points (e.g. OCR failure, network timeout).
2. Add breadcrumb logs for key user actions.
3. If on backend, ensure Grafana metrics capture the feature's success/failure rates.
4. Define alerts for the feature if it is mission-critical.

## Definition of Done
- No PII is logged.
- Failures are visible in dashboards.
