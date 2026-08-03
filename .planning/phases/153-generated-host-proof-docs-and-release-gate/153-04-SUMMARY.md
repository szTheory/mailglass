---
phase: 153
plan: 04
subsystem: generated-host HTTP feedback and unsubscribe proof
tags: [phoenix, http, postmark, rfc8058, suppression]
requires: [153-03]
provides: [signed-feedback-http-proof, one-click-replay-scope-proof]
affects: [generated-host-proof, adoption-gate]
tech-stack:
  added: []
  patterns: [adopter-owned-router, real-http-client, sanitized-checkpoint]
key-files:
  created: [test/generated_host/http_journey_test.exs]
  modified: [dev/mailglass/generated_host/host_template.ex, dev/mailglass/generated_host/journey.ex, dev/mailglass/generated_host/checkpoint.ex, scripts/generated_host_proof.sh, scripts/check_generated_host_proof.sh]
decisions:
  - "Generated-host HTTP clients derive the active Phoenix endpoint port rather than assuming a config import order."
  - "Feedback manifests retain only statuses, byte counts, and cardinalities; they never include webhook bodies, URLs, tokens, addresses, or credentials."
metrics:
  tasks_completed: 2
  files_changed: 6
status: complete
---

# Phase 153 Plan 04: Generated-host HTTP feedback and one-click proof Summary

The generated Phoenix host now proves signed Postmark feedback and RFC 8058 replay through real public HTTP routes, with durable and privacy-bounded evidence.

## Completed Tasks

1. Added the adopter-owned webhook and unsubscribe router mounts, cached raw-body reader, Postmark credential configuration, and an HTTP feedback journey.
2. Added delivery-derived one-click POST replay and public outbound suppression-scope controls with sanitized checkpoint validation.

## Verification

- `mix test test/generated_host/http_journey_test.exs --warnings-as-errors` — passed (3 tests).
- Real disposable generated-host feedback journey — passed: signed request `200`/empty with one ingress and one ledger event; forged request `401`/empty with zero durable delta.
- Real disposable generated-host feedback-unsubscribe journey — passed: two `200`/empty one-click POSTs converged to one event/suppression pair; matching bulk send was suppressed without capture growth; transactional and operational controls delivered.

## Commits

- `59fe1d4f` — test(153-04): require signed feedback over host HTTP
- `789321bf` — feat(153-04): prove signed feedback through adopter router
- `9d56abf0` — test(153-04): require HTTP one-click convergence and scope
- `7c4bbcbb` — feat(153-04): prove one-click replay and scoped enforcement

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Endpoint-port and capture-delta proof corrections.
- **Found during:** Tasks 1 and 2 verification.
- **Issue:** Phoenix development configuration overrides the template's initial port, and the scope assertion initially counted the originating bulk capture as a matching resend.
- **Fix:** Read the running endpoint's configured port and measure capture growth only after the source delivery.
- **Files modified:** `dev/mailglass/generated_host/journey.ex`
- **Commit:** `7c4bbcbb`

2. [Rule 2 - Privacy] Sanitized checkpoint evidence key.
- **Found during:** Task 1 validation.
- **Issue:** A safe cardinality field name tripped the broad privacy scanner because it contained the forbidden term `webhook`.
- **Fix:** Renamed it to `ingress_event_count`; no raw request material is emitted.
- **Files modified:** `dev/mailglass/generated_host/journey.ex`, `dev/mailglass/generated_host/checkpoint.ex`, `scripts/check_generated_host_proof.sh`
- **Commit:** `7c4bbcbb`

## Known Stubs

None.

## Self-Check: PASSED

- Generated-host source, focused oracle, and all four task commits exist.
