---
name: crash-and-chaos-testing
description: The scenarios in section 7 and how to record results.
---
# crash-and-chaos-testing

## When to use
During Phase 5 (integration) and Phase 8 (full pass).

## Procedure
1. Execute lifecycle scenarios (kill app, rotate, memory pressure).
2. Execute network scenarios (airplane mode, flaky 2G, timeout).
3. Execute data scenarios (long text, empty strings, duplicates).
4. Record all results in `docs/test_report.md`.

## Definition of Done
- All scenarios executed.
- Zero crashes or data loss.
