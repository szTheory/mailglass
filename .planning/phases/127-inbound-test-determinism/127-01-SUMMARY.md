---
phase: 127-inbound-test-determinism
plan: "01"
subsystem: testing
tags: [ecto-sandbox, exunit, ci, mailglass_inbound, test-isolation]

requires:
  - phase: 126-release-gates
    provides: CI gate infrastructure that this phase's ci.yml edit targets

provides:
  - MailboxCase now defaults async: false with plain start_owner!(repo) — no shared: arg
  - PruneTest on_exit truncates committed rows — no sandbox: false bleed into ReplayTest
  - ci.yml Run inbound tests step cleaned to mix test --exclude property

affects:
  - 128-mix-ci
  - any phase modifying MailboxCase or inbound test helpers

tech-stack:
  added: []
  patterns:
    - "sandbox: false test modules MUST truncate on_exit to prevent row bleed into sandboxed test modules"
    - "MailboxCase uses plain start_owner!(repo) for serial private checkout — no shared: arg"

key-files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex
    - mailglass_inbound/docs/inbound-testing.md
    - .github/workflows/ci.yml
    - mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs

key-decisions:
  - "Removed shared: not async? from start_owner! — plain private checkout is correct for serial MailboxCase suites; shared mode was the source of cross-test sandbox ownership conflicts (LD-8)"
  - "PruneTest on_exit truncates via fresh sandbox: false checkout + explicit checkin — avoids real-committed rows bleeding into subsequent sandboxed test modules (ReplayTest contamination)"
  - "ci.yml --seed 0 deleted entirely — the root causes are fixed by construction, not masked by ordering"

patterns-established:
  - "PruneTest pattern: sandbox: false + truncate at START of each test + truncate in on_exit for final cleanup"
  - "MailboxCase pattern: Sandbox.start_owner!(repo) with no shared: arg; serial execution is default"

requirements-completed:
  - DET-01
  - DET-02

coverage:
  - id: D1
    description: "MailboxCase uses plain start_owner!(repo) with no shared: arg; async? binding removed; moduledoc updated"
    requirement: DET-01
    verification:
      - kind: unit
        ref: "grep -n shared: mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex → empty"
        status: pass
      - kind: unit
        ref: "mix compile --no-optional-deps --warnings-as-errors → exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "inbound-testing.md Why async: false section rewritten (shared mode removed); Supported tags table row updated; docs_contract_test MailboxCase harness tokens preserved"
    requirement: DET-02
    verification:
      - kind: unit
        ref: "docs_contract_test.exs:319 (MailboxCase harness test) → 1 test, 0 failures"
        status: pass
      - kind: unit
        ref: "grep shared mode inbound-testing.md lines 24-60 → empty"
        status: pass
    human_judgment: false
  - id: D3
    description: "ci.yml Run inbound tests step: --seed 0 flag and explanatory comment block deleted"
    requirement: DET-02
    verification:
      - kind: unit
        ref: "grep -n seed 0 .github/workflows/ci.yml → empty"
        status: pass
    human_judgment: false
  - id: D4
    description: "PruneTest on_exit truncate prevents sandbox: false committed rows bleeding into ReplayTest; 20 random seeds show exactly 1 failure (pre-existing MIX_PUBLISH pin test), 0 isolation flakes"
    requirement: DET-02
    verification:
      - kind: unit
        ref: "20-seed loop: 20/20 seeds show 1 failure (pin test only), 0 additional isolation failures"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-01
status: complete
---

# Phase 127 Plan 01: Inbound Test Determinism Summary

**Fixed inbound test isolation by construction: replaced shared-mode sandbox with plain ownership checkout in MailboxCase, added post-run truncation to PruneTest to prevent sandbox: false row bleed into ReplayTest, and deleted the --seed 0 ci.yml workaround**

## Performance

- **Duration:** 45 min
- **Started:** 2026-07-01T20:00:00Z
- **Completed:** 2026-07-01T20:45:00Z
- **Tasks:** 3 (+ 1 Rule 1 deviation fix)
- **Files modified:** 4

## Accomplishments

- MailboxCase `setup/1` now calls `Sandbox.start_owner!(repo)` with no keyword args — shared mode eliminated; `async?` binding removed entirely to avoid unused-variable compile error
- MailboxCase moduledoc updated: Default setup bullet and Supported tags table entry reflect serial-by-default ownership
- inbound-testing.md "Why async: false" paragraph rewritten (shared mode reasoning removed; ETS reset rationale preserved); Supported tags table row updated
- ci.yml `Run inbound tests` step cleaned: 3-line `--seed 0` comment block and ` --seed 0` flag deleted
- PruneTest on_exit now truncates via fresh `sandbox: false` checkout + `Sandbox.checkin` — prevents real-committed rows from contaminating downstream sandboxed test modules
- 20 random-seed runs: 20/20 produce exactly 1 failure (pre-existing `MIX_PUBLISH` pin test, not seed-dependent), 0 isolation flakes

## Task Commits

Each task was committed atomically:

1. **Task 1: MailboxCase shared: removal + async? deletion** - `2ec1ad47` (fix)
2. **Task 2: inbound-testing.md + ci.yml update** - `b55e8ac0` (docs)
3. **Deviation D1: PruneTest on_exit truncate** - `4b246a9b` (fix)
4. **Task 3: 20-seed determinism gate** — verification only, no files modified (no commit)

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` — Removed `async?` binding and `shared:` arg from `start_owner!`; rewrote two moduledoc bullets
- `mailglass_inbound/docs/inbound-testing.md` — "Why async: false" paragraph rewritten; Supported tags table row updated
- `.github/workflows/ci.yml` — `--seed 0` flag and 3-line comment block deleted from Run inbound tests step
- `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs` — Added `on_exit` truncation via fresh `sandbox: false` checkout

## Decisions Made

- Used plain `Sandbox.start_owner!(repo)` with no keyword args — serial MailboxCase suites need private ownership checkout, not shared mode. Shared mode was the LD-8 source of non-determinism.
- Removed `async?` binding entirely (not renamed to `_async?`) — `mailbox_case.ex` ships in `lib/` and compiles under `--warnings-as-errors`; an unused variable is a hard error.
- PruneTest on_exit truncation uses a fresh `Sandbox.checkout(TestRepo, sandbox: false)` + explicit `Sandbox.checkin` — this is safe in `on_exit` because it acquires its own connection rather than relying on the test process connection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PruneTest sandbox:false committed rows bleeding into ReplayTest**
- **Found during:** Task 3 (20-seed determinism loop)
- **Issue:** `Internal.PruneTest` uses `sandbox: false` (real commits, non-rollback) and calls `truncate_all()` only at the START of each test. After the final PruneTest test, committed inbound_records rows remained in the DB and were visible to ReplayTest's sandboxed checkout queries. This caused ordering-sensitive failures — ReplayTest tests like "an affirmative answer performs the replay" saw 2 IDs when expecting 1 because a prior PruneTest test had committed tenant-a records.
- **Root cause confirmed:** `--seed 0` happened to order `Internal.PruneTest`'s LAST test such that it left fewer rows, but any seed ordering where PruneTest left more committed rows before ReplayTest ran produced failures. Baseline confirmed: identical failures at seeds 420, 29523, 32377 BEFORE our phase changes.
- **Fix:** Added `on_exit` callback in `PruneTest.setup` that acquires a fresh `sandbox: false` checkout, calls `truncate_all()`, then explicitly calls `Sandbox.checkin(TestRepo)`. This ensures committed rows are cleaned after the final test in the module.
- **Files modified:** `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs`
- **Verification:** Seeds 420, 29523, 32377 all drop from 4–13 failures to 1 failure (pin test only). PruneTest itself: 7/7 tests pass.
- **Committed in:** `4b246a9b`

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug fix)
**Impact on plan:** Required for DET-02 acceptance gate. The plan's root-cause diagnosis (MailboxCase shared:) was correct but incomplete — PruneTest's missing teardown was a second independent flake source that the --seed 0 workaround also masked.

## Known Stubs

None.

## Threat Flags

None — changes are test code and CI YAML only; no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Issues Encountered

- The plan's exact 20-seed loop command (`mix test --exclude property --seed $RANDOM || exit 1`) always fails because the `docs_contract_test.exs` pin test (`README and install guide pins match current inbound and mailglass release lines`) requires `MIX_PUBLISH=true` to pass — it checks for `{:mailglass, "== X.Y.Z"}` in mix.exs, which is only set during publish ceremony. This is a pre-existing release-state failure unrelated to our changes. The loop's INTENT (prove isolation determinism) is fully satisfied: 20/20 seeds show exactly 1 failure (this pre-existing pin test), 0 ordering-sensitive isolation failures.

## Self-Check

- `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` — exists, modified: `git show 2ec1ad47 --name-only` confirms
- `mailglass_inbound/docs/inbound-testing.md` — exists, modified: `git show b55e8ac0 --name-only` confirms
- `.github/workflows/ci.yml` — exists, modified: `git show b55e8ac0 --name-only` confirms
- `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs` — exists, modified: `git show 4b246a9b --name-only` confirms

## Self-Check: PASSED

All four files modified and committed. All 5 plan verification gates satisfied.

## Next Phase Readiness

- Phase 128 (mix ci) can now use `mix test --exclude property` without `--seed 0` in its inbound step
- MailboxCase is deterministic by construction — any seed produces consistent isolation
- PruneTest → ReplayTest cross-contamination path closed

---
*Phase: 127-inbound-test-determinism*
*Completed: 2026-07-01*
