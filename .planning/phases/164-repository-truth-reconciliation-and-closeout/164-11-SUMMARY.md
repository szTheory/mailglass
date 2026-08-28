---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 11
subsystem: phase-finalization
tags: [gsd-extension, repository-truth, ci-provenance, scheduled-control, closeout]
status: complete
requires:
  - phase: 164-10
    provides: repository-truth closeout and scheduled-control evidence foundations
provides:
  - guarded `/finalize-phase 164` GSD command with pre-verification mode
  - attempt-one CI and scheduled-control provenance enforcement
  - independently validated raw closeout evidence and ignored finalization reports
  - exact-one tracked/current/retain truth-disposition coverage for durable finalization artifacts
affects: [164-12, phase-verification, repository-closeout]
tech-stack:
  added: [project-local GSD extension]
  patterns: [fail-closed provenance validation, ignored evidence outputs, stable-porcelain guard]
key-files:
  created:
    - .gsd/extensions/finalize-phase/extension-manifest.json
    - .gsd/extensions/finalize-phase/index.ts
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh
    - scripts/finalize_phase_164.sh
  modified:
    - .gitignore
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - scripts/ci_monitor.cjs
    - scripts/closeout_repository_truth.sh
    - scripts/scheduled_control_evidence.sh
    - test/scripts/phase_164_closeout_test.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - test/scripts/scheduled_control_evidence_test.exs
key-decisions:
  - "The finalizer selects the newest completed attempt-one CI run for the exact main-branch SHA; callers cannot supply a run ID."
  - "Finalization evidence remains ignored runtime output while the command, scripts, lifecycle contract, and truth ledger remain tracked repository truth."
  - "The finalizer independently validates raw CI and scheduled-control provenance instead of trusting only lower-level aggregate status."
requirements-completed: [TRTH-02, TRTH-03]
actuals:
  tokens: 15947
  tasks: 3
  commits: 8
metrics:
  duration: 12m
  completed: 2026-08-28
coverage:
  - id: D1
    description: "The project-local command, manifest, and narrow ignore boundary load under pinned GSD 2.80.0 and fail closed at the stable-porcelain guard."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: 'ASDF_NODEJS_VERSION=22.14.0 gsd --print --no-session "/finalize-phase 164 --pre-verification"'
        status: pass
      - kind: unit
        ref: "mix test test/scripts/phase_164_closeout_test.exs test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI and scheduled-control evidence carry exact attempt-one provenance through capture, closeout, raw validation, and ignored finalization reports."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check"
        status: pass
      - kind: other
        ref: "bash -n scripts/finalize_phase_164.sh .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every durable finalization artifact has exactly one tracked, current, retain authority row in the repository-truth ledger."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check"
        status: pass
    human_judgment: false
---

# Phase 164 Plan 11: Finalization Boundary Summary

A guarded, fail-closed GSD finalization command that selects exact-SHA attempt-one CI evidence, validates scheduled-control provenance, and writes only ignored runtime reports.

## Performance

- **Duration:** 12 minutes
- **Started:** 2026-08-28T20:30:28Z
- **Completed:** 2026-08-28T20:42:02Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments

- Added a project-local `/finalize-phase` command and tracked shim with strict phase, repository, branch, SHA, and stable-porcelain guards.
- Made CI and scheduled-control evidence attempt-aware and required exact attempt 1 throughout capture, closeout, and finalization.
- Added independent raw-evidence validation plus ignored pre-verification and terminal report artifacts.
- Reconciled every durable finalization artifact into the truth-disposition ledger with exactly one tracked/current/retain row.

## Task Commits

Each task was committed atomically using TDD where required:

1. **Task 1: Guarded GSD command and repository boundary**
   - `1d5d3255` — `test(164-11): add failing finalize-phase command contracts`
   - `4f2ddf6c` — `feat(164-11): add guarded finalize-phase command`
2. **Task 2: Attempt-one finalization and raw provenance validation**
   - `f226ac77` — `test(164-11): add failing attempt-one finalization contracts`
   - `e0ad4fa8` — `feat(164-11): implement attempt-one phase finalization`
   - `8f212b09` — `fix(164-11): align finalizer command with GSD exec results`
3. **Task 3: Repository-truth reconciliation**
   - `c8807e1e` — `docs(164-11): reconcile finalization truth authority`

## Files Created/Modified

- `.gsd/extensions/finalize-phase/extension-manifest.json` — Declares the community extension and its single command.
- `.gsd/extensions/finalize-phase/index.ts` — Validates arguments and invokes the tracked finalizer with bounded output and correct exit semantics.
- `.gitignore` — Tracks only the intended finalizer extension boundary while keeping runtime `.gsd` state ignored.
- `scripts/finalize_phase_164.sh` — Performs guarded pre-verification or terminal finalization without tracked output.
- `scripts/ci_monitor.cjs` — Exposes workflow attempt provenance.
- `scripts/scheduled_control_evidence.sh` — Requires and records scheduled attempt 1.
- `scripts/closeout_repository_truth.sh` — Enforces exact attempt-one CI and scheduled-control provenance.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh` — Stable tracked entrypoint.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — Lifecycle and operator contract.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md` — Updated closeout evidence contract.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` — Exact-one authority rows for all durable finalization artifacts.
- `test/scripts/phase_164_closeout_test.exs` — Finalizer and CI selector contract coverage.
- `test/scripts/phase_164_repository_truth_test.exs` — Extension boundary and ledger uniqueness coverage.
- `test/scripts/scheduled_control_evidence_test.exs` — Attempt-one scheduled evidence coverage.

## Decisions Made

- Callers cannot choose a CI run. The finalizer deterministically selects the newest completed attempt-one CI run matching workflow, push event, main branch, and exact HEAD SHA.
- Runtime evidence remains ignored and disposable; only the executable contract and authority metadata are tracked.
- Terminal success requires independent validation of the raw CI and scheduled-control sources as well as a passing lower-level closeout result.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected installed GSD execution-result handling**

- **Found during:** Task 3 pinned GSD 2.80.0 invocation
- **Issue:** The installed runtime returns `pi.exec` status as `code`, while the extension guidance example used `exitCode`; the mismatch falsely reported a failed finalizer as successful.
- **Fix:** Read the installed runtime contract, switched to `code`, and added regression coverage.
- **Files modified:** `.gsd/extensions/finalize-phase/index.ts`, `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `8f212b09`

**2. [Rule 3 - Blocking] Preserved nonzero status in GSD print mode**

- **Found during:** Task 3 real command verification
- **Issue:** GSD print mode rendered extension exceptions but returned process status 0, violating the required automation contract.
- **Fix:** Added explicit print-mode stderr and process-exit handling while retaining interactive exception behavior.
- **Files modified:** `.gsd/extensions/finalize-phase/index.ts`, `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `8f212b09`

**3. [Rule 3 - Blocking] Split ignore checks into single-path invocations**

- **Found during:** Task 2 closeout verification
- **Issue:** This Git version rejects `git check-ignore -q` when passed multiple pathnames, causing a false closeout failure.
- **Fix:** Check each required ignored evidence path independently; verification uses the same compatible form.
- **Files modified:** `scripts/closeout_repository_truth.sh`
- **Commit:** `e0ad4fa8`

**4. [Rule 2 - Missing Critical Functionality] Ignored the canonical volatile GSD lifecycle lock**

- **Found during:** Post-plan integration via official GSD 2.80 `state begin-phase`
- **Issue:** GSD creates `.planning/milestone.lock` with volatile session, PID, and timestamp metadata while a phase is active. Because the lock was unignored, the finalizer's stable-porcelain prerequisite could never pass during canonical GSD execution.
- **Fix:** Added one exact root ignore rule, proved the lock is ignored while neighboring planning proof remains visible, and reconciled the rule as unique ledger row `I-072`.
- **Files modified:** `.gitignore`, `test/scripts/phase_164_repository_truth_test.exs`, `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv`
- **Commit:** This atomic Plan 164-11 follow-up fix.

## Verification

- `mix test test/scripts/phase_164_closeout_test.exs test/scripts/phase_164_repository_truth_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check` — 27 tests, 0 failures.
- `bash -n scripts/finalize_phase_164.sh .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh` — passed.
- `mix format --check-formatted` for all modified Elixir tests — passed.
- Repository-truth validator — valid.
- Narrow `.gsd` ignore-boundary assertions — passed.
- Canonical `.planning/milestone.lock` ignore and neighboring planning-proof visibility assertions — passed.
- Pinned `gsd` version — 2.80.0.
- Real `gsd --print --no-session "/finalize-phase 164 --pre-verification"` — command loaded and correctly failed nonzero at the stable-porcelain guard in the intentionally dirty integration checkout.
- `git diff --check` — passed.

## Operational Notes

- Pre-verification is intentionally fail-closed until it runs from a clean, synchronized `main` checkout with summaries through Plan 11 present.
- The observed GSD ecosystem trust warning did not prevent this project-local command from loading or invoking the finalizer.
- The recurring missing OTLP exporter warning is pre-existing and did not affect the test results.

## Self-Check: PASSED

- All created files exist.
- All six task commits exist in repository history.
- Full targeted verification passed in the current execution session.
- No goal-blocking stubs, skipped tests, or unrun verification steps remain.
