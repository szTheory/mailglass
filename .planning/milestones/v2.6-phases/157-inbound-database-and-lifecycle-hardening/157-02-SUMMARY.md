---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 02
subsystem: inbound-s3
tags: [ses, s3, retry, optional-dependencies, dos-hardening]
requires: [157-01]
provides: [metadata-first-s3-retrieval, bounded-s3-body, closed-s3-retry-classification]
affects: [mailglass_inbound]
tech-stack:
  added: []
  patterns: [head-before-get, post-fetch-byte-guard, closed-transient-matrix]
key-files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/ex_aws_s3.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/fake.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/retry.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex
    - mailglass_inbound/lib/mailglass_inbound/optional_deps.ex
    - mailglass_inbound/test/mailglass_inbound/s3_fetcher_test.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs
decisions:
  - SES defaults to a validated 40 MiB S3 limit and rejects unbounded or dishonest adapter data before it can continue through ingress.
  - Only an explicit transport, timeout, throttling, 5xx, or not-ready S3 outcome is transient; unknown outcomes fail closed.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 157 Plan 02: Inbound Database and Lifecycle Hardening Summary

SES inbound S3 content resolution now reads bounded metadata before a body download, enforces a 40 MiB default limit, and preserves honest permanent failure classification.

## Completed Tasks

1. Added the optional-adapter `head/3` contract, ExAws `HeadObject` gateway, test fake metadata seam, configurable 40 MiB validation, and post-fetch byte guard. Commit: `61f2019c`.
2. Centralized a closed retry matrix for S3 body and metadata calls; known transient errors exhaust as `:s3_object_not_ready`, while authorization, missing, malformed, oversized, and unknown results fail once as `:s3_fetch_failed`. Commit: `a9ce4970`.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/s3_fetcher_test.exs test/mailglass_inbound/ingress/ses_provider_test.exs --warnings-as-errors` — 37 tests, 0 failures.
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` — passed.
- Scoped `mix format --check-formatted` and `git diff --check` — passed.

The optional ExAws test environment logs its expected unavailable Hackney credential-path error, but the gateway catches it and the test suite passes.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Security/optional dependency] Extended the optional ExAws gateway with `head_object/2`.
- **Found during:** Task 1.
- **Issue:** The real adapter could not perform `HeadObject` without directly referencing optional ExAws modules, which would violate the no-optional compilation boundary.
- **Fix:** Added the minimum gateway method alongside the existing guarded `get_object/2`; production adapter code remains free of bare optional dependency references.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`.
- **Commit:** `61f2019c`.

## Known Stubs

None.

## Self-Check: PASSED

- Verified commits `61f2019c` and `a9ce4970` exist.
- Verified the S3 fetcher, retry classifier, SES provider, optional gateway, and focused tests exist.
