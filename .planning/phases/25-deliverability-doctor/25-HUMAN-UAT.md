---
status: partial
phase: 25-deliverability-doctor
source: [25-VERIFICATION.md]
started: 2026-05-01T21:02:03Z
updated: 2026-05-01T21:02:03Z
---

## Current Test

awaiting human testing

## Tests

### 1. Run mix mail.doctor against one real domain with explicit DKIM selectors
expected: The task prints grouped SPF, DKIM, DMARC, MX, and BIMI findings, preserves cannot_verify where DNS is inconclusive, and does not crash on live resolver behavior.
result: pending

### 2. Compare human and JSON output for the same real domain
expected: Human output and --format json reflect the same findings and summary counts, with JSON exposing schema_version 1 and the shared result contract.
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
