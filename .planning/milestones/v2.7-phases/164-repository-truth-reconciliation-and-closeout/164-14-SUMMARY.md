---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 14
subsystem: repository-truth-evidence
tags: [github-actions, protected-main, scheduled-controls, repository-truth, pre-verification]
requires:
  - phase: 164-13
    provides: adversarial regression locks for authoritative-ledger and closeout boundaries
provides:
  - exact protected-main pre-verification evidence for the integrated Phase 164 repair
  - independently checked attempt-one CI and complete natural scheduled-control provenance
  - explicit non-terminal handoff to ordinary verification and post-completion finalization
affects: [phase-verification, terminal-finalization, TRTH-01, TRTH-02, TRTH-03]
actuals:
  tokens: 3555
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns: [transient keyring credential injection, exact-SHA evidence selection, non-circular two-boundary closeout]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-14-SUMMARY.md
  modified: []
key-decisions:
  - "The accepted capture is pre-verification-only evidence for protected-main SHA d903b040c72fff62a69a57cacbcc7e7d7c2f6167; this tracked summary intentionally makes that capture non-terminal."
  - "Natural attempt-one scheduled failures are accepted only through their evidence-valid policy-blocked artifacts; no workflow was dispatched, rerun, or otherwise operated."
patterns-established:
  - "GitHub credentials are injected transiently from the CLI keyring into only the evidence process and are never printed or persisted."
  - "The report, inputs, and raw sources must independently agree on exact main, CI identity, registry set, provenance, freshness, and digest fields."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "The complete documentation, package, authoritative-ledger, and closeout regression surface passes on the integrated protected-main repair."
    requirement: TRTH-01
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check"
        status: pass
      - kind: other
        ref: "elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
        status: pass
    human_judgment: false
  - id: D2
    description: "Protected main has exact attempt-one normal push CI and a complete naturally scheduled attempt-one control set with valid policy outcomes and digests."
    requirement: TRTH-03
    verification:
      - kind: e2e
        ref: ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh /Users/jon/projects/mailglass --pre-verification"
        status: pass
      - kind: other
        ref: "independent jq validation of tmp/phase-164-finalize.A0oI0M inputs/report and referenced raw CI/scheduled sources"
        status: pass
    human_judgment: false
  - id: D3
    description: "The tracked closeout preserves the causal boundary between pre-verification evidence and later terminal operational proof."
    requirement: TRTH-03
    verification:
      - kind: other
        ref: ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md lifecycle contract"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-09-09
status: complete
---

# Phase 164 Plan 14: Protected Pre-Verification Evidence Summary

**Exact protected-main pre-verification passed with attempt-one CI and complete naturally scheduled evidence, while terminal proof remains deliberately deferred until all tracked completion metadata is integrated.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-09-09T18:44:33Z
- **Completed:** 2026-09-09T18:51:33Z
- **Tasks:** 1
- **Files modified:** 1 tracked summary plus ignored runtime evidence

## Accomplishments

- Reconfirmed both tagged Plan 164-13 groups, the complete focused suite, authoritative production ledger, shell syntax, and formatting on exact protected main.
- Captured a passing ignored pre-verification report for SHA `d903b040c72fff62a69a57cacbcc7e7d7c2f6167` with selected CI run `34284583200`.
- Independently verified the raw CI source and exact three-control scheduled registry set, including attempts, events, branches, head/workflow SHAs, statuses, reasons, freshness, payload digests, and archive digests.

## Evidence Identities

- Protected `main`, local `HEAD`, and fetched `origin/main`: `d903b040c72fff62a69a57cacbcc7e7d7c2f6167`.
- Normal push CI: run `34284583200`, workflow `CI`, attempt 1, branch `main`, completed successfully at the exact SHA.
- Pre-verification report: `tmp/phase-164-finalize.A0oI0M/pre-verification-report.json` (`pass`, `all_authorities_exact_and_current`).
- Release Please schedule: run `34389605975`, attempt 1, evidence-valid blocked result `proposal_identity_mismatch`.
- Repository Hygiene schedule: run `34352583454`, attempt 1, evidence-valid blocked result `12 open PR(s) require disposition before release.`
- Post-publish Smoke schedule: run `34350507454`, attempt 1, evidence-valid blocked result `scheduled_target_not_published`.
- Stable porcelain was empty before capture, after capture, and after independent validation.

## Pre-Verification Boundary

This is **pre-verification-only evidence**, not terminal operational proof. Creating and integrating this tracked summary, the refreshed passing `164-VERIFICATION.md`, and normal STATE/ROADMAP/REQUIREMENTS completion metadata necessarily advances protected `main` beyond the captured SHA. Only after those tracked outputs reach protected `main` may the separate terminal `/finalize-phase 164` mode recapture exact evidence at the then-current SHA, with no later tracked write, workflow dispatch, rerun, release, publication, or authority change.

## Task Commits

This checkpoint intentionally changed no production source. Its ignored runtime capture and this plan-completion metadata are committed together in the plan metadata commit recorded after this summary is written.

## Files Created/Modified

- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-14-SUMMARY.md` — Records exact pre-verification identities and the explicit terminal handoff.
- `tmp/phase-164-finalize.A0oI0M/` — Ignored inputs/report capture; regenerable and intentionally untracked.
- `tmp/phase-164-closeout.p1UtwK/` — Ignored raw component evidence referenced by the report; intentionally untracked.

## Decisions Made

- Accepted only the finalizer-selected exact-SHA attempt-one CI run; no caller-selected run identity was supplied.
- Accepted scheduled workflow failures only because each natural attempt-one run carried a complete evidence-valid `blocked` result authorized by the existing contract.
- Treated this summary as the boundary that invalidates terminal status for the current capture; terminal finalization remains a later operation after ordinary verification and protected integration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the tracked finalizer shim when the `gsd` launcher was unavailable**
- **Found during:** Task 1 automated pre-verification invocation
- **Issue:** The shell had no `gsd` executable on `PATH`, so the documented extension command could not launch.
- **Fix:** Invoked the tracked `164-FINALIZE.sh` shim that the extension itself resolves and executes, preserving the identical finalizer, arguments, and evidence contract.
- **Files modified:** None
- **Verification:** The finalizer passed, and the generated inputs/report/raw sources passed independent exact-identity validation.
- **Committed in:** Plan metadata commit

**Total deviations:** 1 auto-fixed (1 blocking environment issue).
**Impact on plan:** No authority or evidence predicate changed; only the unavailable launcher layer was bypassed in favor of its tracked execution target.

## Issues Encountered

- The repository `.tool-versions` selects an unavailable local Elixir version. Commands used already-installed Erlang `28.4.1` and Elixir `1.19.5-otp-28` through per-process ASDF variables; `.tool-versions` remained untouched.
- The focused suite retained one pre-existing skipped historical test and emitted the existing optional OTLP-exporter warning; neither affects the Phase 164 evidence contract.

## Authentication Gates

- The prior checkpoint was resolved with the existing GitHub CLI keyring credential for `szTheory`. The token was injected only into individual processes, never printed or persisted, and its existing scopes were sufficient for protected-branch, Actions, artifact, and repository reads.

## Known Stubs

None.

## Threat Flags

None — this plan introduced no network endpoint, authentication path, file-access implementation, schema, workflow authority, or remote mutation surface.

## User Setup Required

None.

## Next Phase Readiness

- Ordinary Phase 164 verification can now replace the stale verifier result using exact pre-verification evidence at `d903b040c72fff62a69a57cacbcc7e7d7c2f6167`.
- After the passing verifier and all tracked completion metadata reach protected `main`, terminal `/finalize-phase 164` must run at the new exact SHA and be followed by no tracked write.

## Self-Check: PASSED

- The Plan 164-14 summary, pre-verification inputs, report, and all referenced raw component sources exist.
- Plan 164-13 commits `695f0d0b`, `177f1fd2`, and `a0b55e75` are present in the protected-main history ending at `d903b040`.
- The report status is `pass`; its input, report, CI, scheduled, local HEAD, and fetched origin identities all equal the exact protected-main contract.
- STATE, ROADMAP, and REQUIREMENTS tracking reflects Plan 164-14 completion while leaving the phase itself in progress for refreshed verification and terminal finalization.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-09*
