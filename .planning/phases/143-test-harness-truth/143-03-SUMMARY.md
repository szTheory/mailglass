---
phase: 143-test-harness-truth
plan: 03
subsystem: testing
tags: [ecto, sandbox, dbconnection, mechanism-account, harness-01, d-31, docs-contract]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 01)
    provides: "SuiteTruthFormatter, SandboxOwnership.probe/1, SandboxOwnership.baseline_tables_present?/1 — the read-only boundary-probe instrument this plan's ledgers were captured with"
provides:
  - "143-MECHANISM.md — HARNESS-01's evidence artifact: a seven-section mechanism account citing and codifying the already-confirmed Class C causal chain (CI run 30464215272, job 90617762038), independently reproduced in this plan's own local instrumented capture (mailer_case.ex's leak window, in Mailglass.Webhook.PlugSESTest), widened to Classes A and B, with both D-04 falsifiable predictions recorded PASS on two independent evidence sources"
  - "143-LEDGER-public.txt, 143-LEDGER-mailglass.txt — committed instrumented pre-fix ledgers from real MAILGLASS_SANDBOX_TRACE=1 mix test runs on both schema axes, plus the --max-cases 1 negative control, each recording the SuiteTruthFormatter's own zero-violation result alongside the same run's genuine raw-failure evidence (145/0 already_shared, 46/10 42P01, on public/mailglass respectively) and an explicit account of why the boundary-only probe missed it"
  - "test/scripts/mechanism_account_contract_test.exs — a docs-contract test in the required mix_task_tests lane (auto-collected, no mix.exs change) that fails closed if the account loses its run citation, its MatchError term shape, its PASS/FAIL predictions, or its class-A/B module naming"
  - "D-31 upstream amendments landed in REQUIREMENTS.md (HARNESS-01 exoneration + three-class inventory + HARNESS-02/04 scope split), ROADMAP.md (Phase 143 criterion 1's heal-not-collide correction), and ci_lanes.ex (moduledoc-only correction of the Core Full Suite 'schedule-only' misclassification)"
affects: [143-04, 143-05, 143-06, 143-07, 143-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A zero-violation ledger from a boundary-only (:module_finished-only) probe must never be read as 'no leak occurred' — state the instrument's blind spot explicitly, in the artifact itself, every time a quiet ledger coincides with a genuinely red run."
    - "When an instrument's own granularity cannot resolve a claim to a single culprit, narrow the candidate set from direct read and record the narrowing honestly (2-4 named files) rather than manufacturing false single-file precision the evidence does not support."
    - "Upstream artifact amendment follows the Phase 141 TRUTH-09 precedent: original text stays readable, the correction is appended inline in italics with its reason and a pointer to the deciding artifact — never delete-and-rewrite a requirement in place."

key-files:
  created:
    - .planning/phases/143-test-harness-truth/143-MECHANISM.md
    - .planning/phases/143-test-harness-truth/143-LEDGER-public.txt
    - .planning/phases/143-test-harness-truth/143-LEDGER-mailglass.txt
    - test/scripts/mechanism_account_contract_test.exs
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - test/support/ci_lanes.ex

key-decisions:
  - "The first ledger-capture attempt (public axis) ran against a database left in a broken state by an unrelated prior exploratory run (documented in 143-01-SUMMARY.md); it produced 198 failures with a zero-record ledger from the very first module and was discarded as contaminated rather than reported. Both real captures in this SUMMARY were taken against a freshly reset (mix ecto.drop + mix ecto.create) Mailglass.TestRepo."
  - "Both committed ledgers genuinely recorded zero SuiteTruthFormatter violations despite real, live Class A/B/C symptoms in the same runs (145/0 already_shared, 46/10 42P01). This is reported as-is, not massaged — it is a direct, local confirmation of the boundary-only blind spot 143-01-SUMMARY flagged in advance, and both ledger files and the mechanism account state explicitly that a quiet ledger must not be read as 'no leak occurred.'"
  - "Class A's historically-blamed migration_test.exs is REFUTED by this run's own evidence (zero failures in both local captures); SEED-007's 'already ruled out' entry for it is re-opened per D-31 rather than left silently contradicted, and the narrowed candidate set (upgrade_v2_schema_migration_test.exs, schema_prefix_hardening_test.exs) is recorded instead of the original single name."
  - "Class B's six :schema_isolation-tagged candidates are narrowed to three confirmed schema-flipping files, plus a fourth structural candidate outside the original tag set (schema_prefix_hardening_test.exs, discovered by direct read, not assumed from the tag)."
  - "Neither Class A nor Class B resolves to one named file — the ledger's :module_finished-only granularity cannot see per-test drift-and-restore cycles inside a single module's own lifecycle, which is exactly how all four candidate files operate. This is recorded as the confirmed reason for the narrowing's limit, not a gap to paper over."
  - "ci_lanes.ex's moduledoc correction is scoped precisely: Core Full Suite Advisory and Provider Compatibility Advisory (both in advisory-matrix.yml, which triggers on push/pull_request/schedule/workflow_dispatch) are corrected; Provider Live Advisory (its own workflow, schedule + workflow_dispatch only) keeps its accurate classification rather than being swept into an over-broad fix."

patterns-established:
  - "Restore the test database explicitly (mix ecto.drop + mix ecto.create) before any 'before the fix' instrumented capture — a shared TestRepo can carry forward corruption from an unrelated prior run, and a contaminated first attempt should be discarded and documented, not silently blended into the reported evidence."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "Two committed instrumented pre-fix ledgers (public, mailglass schema axes) plus the --max-cases 1 negative control on the public axis, each with a header recording command/toolchain/schema/seed/counts, a per-class tally including explicit zeros, and no PII"
    requirement: "HARNESS-01"
    verification:
      - kind: other
        ref: "grep -Eq 'pool_mode_leaked|config_schema_drift|baseline_missing' 143-LEDGER-public.txt; grep -Eic '@example\\.com|subject:|recipient' 143-LEDGER-*.txt == 0; mailglass-axis excluded count (14) exceeds public-axis (13) by exactly 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "143-MECHANISM.md: seven-section HARNESS-01 evidence artifact citing run 30464215272/job 90617762038, the nested MatchError term shape, both D-04 predictions marked PASS with evidence, and the three-class inventory with A2/A3 verdicts"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "test/scripts/mechanism_account_contract_test.exs (9 tests: existence, section headings, anti-vacuity guard, run/job citation, MatchError shape, PASS/FAIL markers, class naming, ledger header counts, PII scrub)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-31 upstream amendments landed in REQUIREMENTS.md, ROADMAP.md, and ci_lanes.ex's moduledoc, each correction appended inline with its reason per the Phase 141 TRUTH-09 precedent, with no registry constant, accessor, or count changed"
    requirement: "HARNESS-01"
    verification:
      - kind: other
        ref: "mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors (23 tests, 0 failures — 24-row/set-equality assertions untouched); git diff -- test/support/ci_lanes.ex shows changes only inside the moduledoc; grep -c 'cron-only' test/support/ci_lanes.ex == 0"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-07-29
status: complete
---

# Phase 143 Plan 03: Instrumented Ledger, Mechanism Account, and Upstream Amendments Summary

**HARNESS-01's evidence artifact — a written mechanism account citing the already-confirmed CI causal chain (run 30464215272/job 90617762038) and independently reproducing it locally in `mailer_case.ex`'s leak window, backed by two committed pre-fix ledgers that both recorded zero boundary-probe violations despite genuine live Class A/B/C failures — a direct confirmation, not a contradiction, of the boundary-only blind spot 143-01 flagged in advance.**

## Performance

- **Duration:** ~25 min (three full-suite instrumented runs plus a negative control, ~65-90s each, plus DB resets and mechanism analysis)
- **Started:** 2026-07-29T19:13:00Z (approx., following 143-02's completion)
- **Completed:** 2026-07-29T19:37:49Z
- **Tasks:** 3 (all `type="auto"`)
- **Files modified:** 7 (4 created, 3 modified), plus this SUMMARY

## Accomplishments

- Captured genuinely fresh instrumented pre-fix ledgers on both schema axes
  (`MAILGLASS_SANDBOX_TRACE=1 mix test --warnings-as-errors --exclude requires_workspace --seed
  0`, and the same with `MAILGLASS_SCHEMA=mailglass`), each against a freshly reset
  `Mailglass.TestRepo`, plus the `--max-cases 1` negative control on the public axis (D-05: tally
  materially unchanged, confirming the async/sync serialization non-answer).
- Both real production ledgers recorded **zero** `SuiteTruthFormatter` violations — yet the same
  runs' raw failure output shows 145 (public) / 0 (mailglass) `already_shared` occurrences and 46
  (public) / 10 (mailglass) `42P01` occurrences, several matching the exact confirmed
  `{:error, {{:badmatch, :already_shared}, _stack}}` shape from RESEARCH.md's CI-log account. This
  is recorded, explicitly, as live local confirmation of the boundary-only (`:module_finished`
  only) blind spot 143-01-SUMMARY flagged for schema-manipulating modules that drift-and-restore
  `Mailglass.Config.schema()` per-test rather than per-module.
- Wrote `143-MECHANISM.md`: seven required sections (Verdict, Proven Causal Chain, Blast Radius,
  Three-Class Inventory, D-04 Predictions, Rejected Diagnostics, What This Account Does NOT
  Claim). Cites and codifies the already-confirmed Class C chain (CI run `30464215272`, job
  `90617762038`) and independently reproduces the identical acquire→raise-before-release shape
  locally in `Mailglass.Webhook.PlugSESTest`/`mailer_case.ex` — a different confirmed site than
  the CI evidence's `webhook_idempotency_convergence_test.exs`, both matching D-02's documented
  92-line/gap shape. Both D-04 predictions verified PASS on two independent evidence sources.
- Named Class B's candidates precisely: narrowed CONTEXT.md's six `:schema_isolation`-tagged
  files to three confirmed schema-flipping files (`schema_isolation_integration_test.exs`,
  `schema_isolation_immutability_test.exs`, `schema_prefix_hardening_test.exs` — the last outside
  the original tag set, found by direct read). Refuted Class A's historically-blamed
  `migration_test.exs` (zero failures in both local runs) and re-opened SEED-007's "already ruled
  out" entry per D-31, naming the two other files that perform the same public-schema
  drop/restore cycle instead.
- `test/scripts/mechanism_account_contract_test.exs` (9 tests) is auto-collected into the
  required `mix_task_tests` lane via `verify.ci_lane_contract`'s directory glob — no `mix.exs`
  change — and fails closed if the account loses its run citation, MatchError shape, PASS/FAIL
  verdicts, or class-A/B module naming.
- Landed all D-31 upstream amendments: HARNESS-01 (exonerates `Mailglass.DataCase`, names the
  confirmed sites, corrects the `mailer_case.ex:158`/`:248` no-op reasoning, records the
  three-class close, re-opens SEED-007's stale entry), the explicit HARNESS-02 (four legs) versus
  HARNESS-04 (two legs) scope split, ROADMAP.md's criterion 1 heal-not-collide correction (citing
  `manager.ex:169-172`), and `ci_lanes.ex`'s moduledoc-only correction (Core Full Suite Advisory
  and Provider Compatibility Advisory are not schedule-only; Provider Live Advisory's accurate
  classification is preserved) — each following the Phase 141 TRUTH-09 inline-correction
  precedent, with zero registry constants, accessors, or counts touched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Capture the instrumented pre-fix ledger on both schema axes** - `8920ab5f` (docs)
2. **Task 2: Write the mechanism account and its docs-contract test** - `2c48a5fc` (docs)
3. **Task 3: Land the D-31 upstream artifact amendments** - `2b36a618` (docs)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `.planning/phases/143-test-harness-truth/143-LEDGER-public.txt` - instrumented pre-fix ledger,
  public schema axis, plus the `--max-cases 1` negative control
- `.planning/phases/143-test-harness-truth/143-LEDGER-mailglass.txt` - instrumented pre-fix
  ledger, mailglass schema axis
- `.planning/phases/143-test-harness-truth/143-MECHANISM.md` - the HARNESS-01 evidence artifact
- `test/scripts/mechanism_account_contract_test.exs` - docs-contract guard, required lane
- `.planning/REQUIREMENTS.md` - HARNESS-01 amendment + HARNESS-02/04 scope split
- `.planning/ROADMAP.md` - Phase 143 criterion 1 heal-not-collide correction
- `test/support/ci_lanes.ex` - exclusions moduledoc correction (moduledoc-only)

## Decisions Made

See `key-decisions` in frontmatter. The load-bearing ones: (1) a contaminated first ledger
capture was discarded and documented rather than blended into the reported evidence; (2) both
real ledgers' zero-violation result is reported honestly, with an explicit in-artifact statement
that it must not be read as "no leak occurred"; (3) Class A/B are narrowed to 2-4 named
candidates rather than resolved to a single file the evidence does not support, with the
resolution limit itself recorded as confirmed instrument behavior, not an open question.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Discarded a contaminated first ledger-capture attempt**
- **Found during:** Task 1
- **Issue:** The first attempt at the public-axis ledger ran against a `Mailglass.TestRepo`
  database left in a broken state (missing baseline tables) by an unrelated prior exploratory run
  documented in 143-01-SUMMARY.md's Issues Encountered. It produced 198 failures with a
  zero-record ledger from the very first module — not representative "before the fix" evidence,
  since the corruption predated this run entirely.
- **Fix:** Reset the database (`mix ecto.drop -r Mailglass.TestRepo --quiet && mix ecto.create -r
  Mailglass.TestRepo --quiet`) before every subsequent capture (public run, mailglass run,
  negative-control run), and documented the discarded attempt in both ledger files' header
  sections so a future reader understands why the reported counts start from a clean baseline.
- **Files modified:** none beyond the ledgers themselves (documented in their headers)
- **Verification:** All three subsequent captures ran against freshly created databases; the
  `mailglass`-axis ledger's `excluded` count (14) exceeds the public-axis ledger's (13) by exactly
  1, confirming the axis switch worked correctly post-reset.
- **Committed in:** `8920ab5f`

**2. [Rule 2 - Missing critical functionality] Formatted `mechanism_account_contract_test.exs` after `mix format` auto-corrected it**
- **Found during:** Task 2, pre-commit verification
- **Issue:** The initial draft of the contract test had a `Path.join/2` call that did not match
  the project's `.formatter.exs` line-length rules.
- **Fix:** Ran `mix format test/scripts/mechanism_account_contract_test.exs`; re-ran `mix test
  test/scripts/ --warnings-as-errors` to confirm the reformatted file still passes all 49 tests in
  the directory.
- **Files modified:** `test/scripts/mechanism_account_contract_test.exs`
- **Verification:** `mix format --check-formatted` exits 0; `mix test test/scripts/
  --warnings-as-errors` exits 0 (49 tests, 0 failures)
- **Committed in:** `2c48a5fc`

---

**Total deviations:** 2 auto-fixed (1 Rule 1 data-integrity fix, 1 Rule 2 formatting fix)
**Impact on plan:** Both were necessary for the ledger's "before the fix" evidence to be honest
and for the docs-contract test to pass the project's own formatting gate. No scope creep — no
fix code was written, no file's `async:` value changed, no new dependency added.

## Issues Encountered

- The `SuiteTruthFormatter` ledger's own violation list recorded zero entries in both real
  instrumented runs, despite genuine Class A/B/C symptoms occurring in the same runs. This is not
  a defect discovered in this plan's own deliverable — it is the confirmed manifestation of the
  boundary-only blind spot 143-01-SUMMARY flagged in advance ("a module whose internal
  test-to-test transitions corrupt then restore state within its own lifecycle is invisible to
  it"). Both ledger files and `143-MECHANISM.md` §7 state this explicitly so a future reader
  encountering a quiet ledger on a red run is not misled into reading it as "no leak occurred."
  This does mean Class A and Class B could not be resolved to a single named module from the
  ledger's own violation records alone — both are reported as narrowed candidate sets (2-4 files
  each), sourced from direct code read cross-referenced against the same run's raw relation-name
  evidence, with the resolution limit recorded as a confirmed instrument property rather than
  papered over. A finer-grained (per-test, not per-module) probe is a real, buildable extension
  not attempted in this plan.

## User Setup Required

None - no external service configuration required. (This plan does require a reachable
PostgreSQL instance for `Mailglass.TestRepo`, verified via `scripts/preflight_postgres.sh` before
Task 1's captures — the precondition held throughout, so no fallback to dispatching
`advisory-matrix.yml` was needed.)

## Next Phase Readiness

- HARNESS-01's "empirically confirmed before the fix is written" bar is met: the mechanism
  account exists, cites its confirming CI run, records both D-04 predictions with evidence from
  two independent sources, names narrowed Class A/B candidate sets from direct read plus ledger
  evidence, and is guarded by a docs-contract test in the required lane.
- Plan 143-04 (the sanctioned ownership door and its mechanism-level regression test) can proceed
  with `143-MECHANISM.md` as its confirmed causal-chain reference — in particular, the confirmed
  `mailer_case.ex` leak window (this plan's local reproduction) and `webhook_idempotency_convergence_test.exs`
  (CI evidence) as the two sites the door must route through.
- Plan 143-07 (close Class A and Class B) should read `143-MECHANISM.md` §4's narrowed candidate
  lists (`upgrade_v2_schema_migration_test.exs` + `schema_prefix_hardening_test.exs` for Class A;
  `schema_isolation_integration_test.exs` + `schema_isolation_immutability_test.exs` +
  `schema_prefix_hardening_test.exs` for Class B) as its starting point rather than re-deriving
  candidates from scratch.
- No blockers for Wave 3 (`143-04`). The database was reset to a clean state
  (`mix ecto.drop`/`mix ecto.create`) at the end of this plan's execution.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 created/modified deliverable files confirmed present on disk; all 3 task commit hashes
(`8920ab5f`, `2c48a5fc`, `2b36a618`) confirmed present in `git log --oneline --all`.
