---
phase: 58-verify-first-webhook-operator-path
plan: 01
subsystem: testing
tags: [reference-host, webhook, postmark, trust-runner, checkpoint]

requires:
  - phase: 52-trust-scope-lock-reference-host-baseline
    provides: maintained reference host router and public-seam boundary
  - phase: 57-deterministic-trust-runner-fixtures
    provides: canonical trust runner command and checkpoint schema
provides:
  - Route-level Postmark webhook proof through MailglassReferenceHostWeb.Router
  - Forged Postmark verify-first rejection evidence before tenant/persistence/execution
  - webhook_ingest trust-runner checkpoint evidence
affects: [phase-58, phase-59, phase-60, trust-runner, webhook-ingest]

tech-stack:
  added: []
  patterns:
    - Shared reference-host proof helper used by ExUnit and trust-runner evidence
    - Additive checkpoint evidence under existing trust_runner.v1 rows

key-files:
  created:
    - lib/mailglass/reference_host/webhook_operator_proof.ex
    - test/reference_host/webhook_operator_path_test.exs
  modified:
    - lib/mix/tasks/mailglass.trust.run.ex
    - lib/mailglass/reference_host/trust_checkpoint.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - test/support/reference_host/trust_runner_fixtures.ex
    - test/reference_host/trust_runner_checkpoint_contract_test.exs

key-decisions:
  - "Use Postmark as the representative verify-first route proof path."
  - "Keep trust_runner.v1 and existing stage names; add bounded evidence to webhook_ingest only on non-dry-run runs."
  - "Preserve dry-run compatibility by skipping live route proof and evidence emission in dry-run mode."

patterns-established:
  - "WebhookOperatorProof.run/0 executes signed and forged requests through MailglassReferenceHostWeb.Router.call/2."
  - "Trust checkpoint rows may carry additive evidence while checkpoint hash remains based on stage/status/fixture identity."

requirements-completed: [JOUR-03]

duration: 10min
completed: 2026-05-27
---

# Phase 58 Plan 01: Route-Level Webhook Proof Summary

**Postmark webhook evidence now proves the maintained reference-host route verifies before tenant, persistence, or execution work.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-27T22:16:26Z
- **Completed:** 2026-05-27T22:26:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `WebhookOperatorProof.run/0`, which executes signed and forged Postmark requests through `MailglassReferenceHostWeb.Router.call/2`.
- Added route-level ExUnit coverage proving signed input returns 200 and forged input returns 401 `bad_credentials` before side-effect markers are set.
- Extended `webhook_ingest` checkpoint rows with deterministic Postmark proof evidence on non-dry-run trust-runner executions.

## Task Commits

1. **Task 1 RED: route proof tests** - `ee54398` (test)
2. **Task 1 GREEN: proof helper** - `67b0706` (feat)
3. **Task 2 RED: checkpoint evidence test** - `44ac040` (test)
4. **Task 2 GREEN: runner evidence** - `1bb707a` (feat)

## Files Created/Modified

- `lib/mailglass/reference_host/webhook_operator_proof.ex` - Shared deterministic signed/forged Postmark route proof helper.
- `test/reference_host/webhook_operator_path_test.exs` - Route-level proof tests for signed and forged webhook behavior.
- `lib/mix/tasks/mailglass.trust.run.ex` - Emits non-dry-run `webhook_ingest` evidence from the shared proof helper.
- `lib/mailglass/reference_host/trust_checkpoint.ex` - Preserves additive evidence on normalized checkpoint rows.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - Adds app-env fallback seams for proof persistence/execution modules.
- `test/support/reference_host/trust_runner_fixtures.ex` - Provides deterministic expected webhook evidence.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` - Asserts checkpoint evidence shape and values.

## Decisions Made

Used Postmark for the representative route because the reference host already exposes `/inbound/:tenant_id/postmark` and Basic Auth gives a deterministic signed/forged pair.

Kept checkpoint hash identity scoped to `stage|status|fixture_id`; evidence is emitted in the row but does not perturb the existing deterministic identity contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added ingress persistence/execution app-env fallback seams**
- **Found during:** Task 1 (route-level Postmark webhook proof tests)
- **Issue:** The maintained reference-host route passes only `provider: :postmark`, so the proof could not inject fake persistence/execution markers through router opts.
- **Fix:** Added app-env fallbacks for `:ingress_persistence` and `:ingress_execution`, which the proof saves, sets, and restores.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`, `lib/mailglass/reference_host/webhook_operator_proof.ex`
- **Verification:** `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors`
- **Committed in:** `67b0706`

**2. [Rule 3 - Blocking] Preserved checkpoint evidence in the encoder**
- **Found during:** Task 2 (webhook_ingest proof evidence)
- **Issue:** `TrustCheckpoint.encode/1` normalized rows down to stage/status/fixture fields, dropping evidence emitted by the runner.
- **Fix:** Preserved additive `"evidence"` maps during row normalization.
- **Files modified:** `lib/mailglass/reference_host/trust_checkpoint.ex`
- **Verification:** `MIX_ENV=test mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors`
- **Committed in:** `1bb707a`

---

**Total deviations:** 2 auto-fixed (Rule 2: 1, Rule 3: 1)  
**Impact on plan:** Both fixes were required to make the planned route-level proof and checkpoint evidence real; no new command, stage name, schema version, or provider breadth was added.

## Issues Encountered

The root test process does not compile the maintained reference host app by default. `WebhookOperatorProof.run/0` loads the reference-host compiled route and sibling package beams so the proof can call the maintained router from root-level tests.

The scoped test command logs a module redefinition warning when the proof loads the current local ingress plug over the reference-host dependency beam. The command exits 0 and the warning is confined to the proof harness.

## User Setup Required

None - no external service configuration required.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: config_surface | `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | Added app-env module override seams for ingress persistence/execution used by the route proof; production defaults remain unchanged. |

## Next Phase Readiness

Plan 02 can build operator troubleshooting evidence on top of the existing `trust_runner.v1` checkpoint rows. Phase 59 can consume `webhook_ingest.evidence` without changing the runner command or stage names.

## Verification

- `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` - passed, 4 tests / 0 failures.
- `MIX_ENV=test mix verify.reference_host.journey --dry-run --checkpoint-out tmp/mailglass_trust_runner/phase58-plan01-dry-run.json` - passed, emitted all five dry-run stages.

## Self-Check: PASSED

- Created files exist: `lib/mailglass/reference_host/webhook_operator_proof.ex`, `test/reference_host/webhook_operator_path_test.exs`, and this summary.
- Task commits exist: `ee54398`, `67b0706`, `44ac040`, `1bb707a`.

---
*Phase: 58-verify-first-webhook-operator-path*
*Completed: 2026-05-27*
