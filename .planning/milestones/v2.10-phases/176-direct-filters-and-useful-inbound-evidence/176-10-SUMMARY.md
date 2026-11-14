---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "10"
subsystem: testing
tags: [prohibition-contract, mutation-proof, playwright, axe, liveview, validation]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plans 01-09: direct-commit filters, Inbound parity, truthful read states, evidence card, retained stories"
provides:
  - "phase176_prohibition_contract_test.exs: eight mutation-proven Phase 176 must-NOTs in the merge-blocking admin suite"
  - "Connected Playwright proof of the client-only filter behaviors on LV 1.2.13 (admin) and LV 1.1.33 (demo)"
  - "Filled 176-VALIDATION.md (nyquist_compliant and wave_0_complete true)"
  - "Coupled browser specs aligned with Phase 175 and 176 markup and copy: zero failed cases"
affects: [phase-176-verification, v3.0-planning]

plan_head_before: 665ef6854aac78b985e54a03b7b52307f01767fd
plan_head_after: 25b3cdd06975d8738be8e47f487fd0b74a55435d
actuals:
  tokens: 62000
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Prohibition contract with a teeth case per detector and one restored source mutation per prohibition"
    - "Axe 'no new violations' = findings beyond the neutral page of the same collection and theme (UUIDs normalized)"
    - "Invalid window draft injected by appending an unlisted option and dispatching a bubbling change event"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
  modified:
    - mailglass_admin/e2e/phase176-filters.spec.js
    - reference/demo_app/assets/e2e/phase176-filters.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VALIDATION.md
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/deferred-items.md

key-decisions:
  - "Coupled-spec reds were triaged as drift (Phase 175 REPLAY-05 removed the dead-end replay CTA; Phase 175 changed replay copy and made technical details non-collapsible; D-01 removed the Apply button) and fixed in the specs, never the product"
  - "Axe cases compare against a per-collection, per-theme neutral baseline because the Deliveries row buttons carry a Phase 113 aria-selected-on-button defect that coupled specs assert on"
  - "The contract file defines its own unavailable-repo module so it runs alone"

patterns-established:
  - "Mutation records: clean-check, cp snapshot, mutate, run, cp restore, cmp exit 0, git diff --quiet"

requirements-completed: ["FILTER-01", "FILTER-02", "FILTER-03", "FILTER-04", "INUX-05", "INUX-06"]

coverage:
  - id: D1
    description: "Eight Phase 176 must-NOTs enforced by a merge-blocking, mutation-proven contract test"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs (24 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Client-only filter behaviors proven in a connected browser on LV 1.2.13 and LV 1.1.33"
    requirement: "FILTER-03"
    verification:
      - kind: e2e
        ref: "npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js (34 passed); demo phase176-filters.spec.js (5 passed with inbound-evidence)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every coupled browser spec passes after aligning stale Phase 175 and 176 expectations"
    requirement: "FILTER-04"
    verification:
      - kind: e2e
        ref: "coupled run of 8 specs: 209 passed, 0 failed, 1 skipped"
        status: pass
    human_judgment: false
  - id: D4
    description: "Validation map filled; no owner UAT remains"
    requirement: "INUX-06"
    verification:
      - kind: other
        ref: "grep '^nyquist_compliant: true$' 176-VALIDATION.md"
        status: pass
    human_judgment: false

duration: 35 min
completed: 2026-10-28
status: complete
---

# Phase 176 Plan 10: Prohibition Contract, Connected Browser Proof and Final Gates Summary

**Eight mutation-proven Phase 176 prohibitions in the merge-blocking admin suite, 34 admin and 5 demo connected browser cases on LiveView 1.2.13 and 1.1.33, and a coupled browser run that ends at 209 passed, 0 failed.**

## Performance

- **Duration:** 35 min (2026-10-28T15:39:00Z to 16:14Z, plus summary)
- **Tasks:** 4 of 4
- **Files modified:** 9 (1 created)

## Accomplishments

- `phase176_prohibition_contract_test.exs` (24 tests): a teeth case per detector plus P1..P8 over the component and the live Deliveries and Inbound routes.
- `176-VALIDATION.md` carries a 28-row per-task map, Wave 0 ticked, `nyquist_compliant: true`, `wave_0_complete: true`, and no manual-only items.
- Connected cases cover history deltas, the rapid select, search, Enter sequence, page reset, Enter and Clear during a pending debounce, focus and caret, Back and Forward, reconnect recovery, status region, the implicit-submission guard, 360px and 200% overflow, the mobile toggle, no results animation, and axe in light and dark.
- Every coupled spec was triaged and aligned; the final run has no failed case.

## Task Commits

1. **Task 1: P1 tracer** - `8ca9ce01` (test)
2. **Task 2: P2-P8 and validation map** - `22693b68` (test)
3. **Task 3: connected browser proof, both clients** - `f69ad34e` (test)
4. **Task 4: coupled specs aligned** - `25b3cdd0` (test)

**Plan metadata:** committed separately (docs: complete plan).

## Mutation Records (D-30, T-176-21, T-176-22)

Each mutation: `git diff --quiet -- <file>` first, `cp` snapshot, one edit, contract file run, `cp` restore, `cmp` exit 0, `git diff --quiet` exit 0. `git status --porcelain mailglass_admin/lib` was empty after every step.

| Prohibition | Mutated file and edit | Red test | cmp |
|---|---|---|---|
| P1 no Apply or submit control | `operator_live.ex`: add `<button type="submit">Go</button>` in `#operator-filters` | "P1 ... Deliveries #operator-filters carries no apply, submit or disable-with control" | 0 |
| P2 masked routing trace | `inbound/routing_trace.ex`: `masked_recipient` returns `value` | both P2 tests (component, full route) | 0 |
| P3 Delivered to / To bindings | `inbound/detail_header.ex`: the To list renders the envelope recipient | "P3 ... the component binds each label to its own source" | 0 |
| P4 no raw bytes unless revealed | `inbound/evidence_card.ex`: the `:revealed` branch also matches `:denied` | both P4 tests (component, live denied route) | 0 |
| P5 reveal telemetry keys | `inbound_live.ex`: add a `recipient:` key to `emit_reveal_telemetry/2` metadata | "P5 ... allowed and denied reveals emit exactly the whitelisted keys" | 0 |
| P6 unknown is not zero | `inbound/evidence_card.ex`: `payload_byte_size(_evidence)` returns 0 | "P6 ... the component reads Unavailable for unknown evidence" | 0 |
| P7 failed read, Deliveries | `operator/deliveries_list.ex`: drop the `@data_state in [nil, :ready]` count guard | "P7 ... Deliveries" | 0 |
| P7 failed read, Inbound | `inbound/records_list.ex`: drop the `is_nil(@data_state)` count guard | "P7 ... Inbound" | 0 |
| P8 labelled fallback, Deliveries | `operator_live.ex`: `:if={@filter_error_source == :url}` becomes `:if={false}` | "P8 ... Deliveries names the excluded event filter" | 0 |
| P8 labelled fallback, Inbound | `inbound_live.ex`: same edit | "P8 ... Inbound names the excluded outcome filter" | 0 |

The connected no-evidence P6 route case is an additional assertion and not the mutation target. The documented residual stands: unknown size or count with an evidence row present is unreachable through persisted rows (`NOT NULL DEFAULT '{}'`), so that state is proven at component level.

## Verification

| Command | Result |
|---|---|
| `mix test test/mailglass_admin/phase176_prohibition_contract_test.exs --trace` (mailglass_admin) | 24 tests, 0 failures; teeth, P1..P8 all listed |
| `mix verify.support_contract.admin` (full admin suite, merge-blocking) | 842 tests, 0 failures, 1 excluded |
| `mix test test/mailglass_admin/persona_drift_guard_test.exs test/mailglass_admin/group_nesting_test.exs --seed 0` | 12 tests, 0 failures |
| `bash scripts/check-conformance.sh` | OK: design-system conformance clean. |
| `mix mailglass_admin.assets.build` then `git diff --exit-code priv/static/` | exit 0 (committed bundle equals a fresh build; TokenParityTest is part of the green suite) |
| `grep -c "Status was not applied"` on `gallery_live.ex` and `structural.spec.js` | 0 and 0 (baseline 2 and 2) |

### Browser lanes (advisory, D-29; not in `ci_green.needs`)

| Lane | Command | Counts |
|---|---|---|
| Admin, LV 1.2.13, new file | `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js` | **34 passed**, 0 failed, 0 skipped, 0 flaky (8 prior cases plus 26 "Phase 176 connected" cases) |
| Admin, structural | `... structural.spec.js --grep "gallery certifies ...\|operator and inbound filter patches keep focus ..."` | **2 passed**, titles unrenamed |
| Demo, LV 1.1.33 | `DEMO_BASE_URL=http://127.0.0.1:4718 npm --prefix reference/demo_app/assets run test:e2e -- phase176-filters.spec.js inbound-evidence.spec.js --grep "Phase 176"` | **5 passed**, 0 failed, demo-e2e-exit=0 (2 spikes, 2 new connected cases, 1 retained-inventory case) |
| Coupled, first run (before spec fixes) | 8 specs: inbound-layout, phase175-inbound, phase169-journey, structural, phase168-plan03-acceptance, phase170-journey, flows, operator | 197 passed, **12 failed**, 1 skipped |
| **Coupled, final run** | same 8 specs | **209 passed, 0 failed, 1 skipped** (the skip is the guarded `header-anchored overlay transform-origin ... IF such an overlay exists` case, unchanged) |

The demo lane was served from a throwaway database (`mailglass_demo_176_10_tmp`, port 4718, external-server mode as in plans 176-06 and 176-08) because the Playwright-managed server cannot start on this host (stale dev database, Docker holding 4015). The server was stopped and the database dropped. `reference/demo_app/mix.lock` and `mailglass_admin/priv/static/app.css` were byte-identical to HEAD after every run; the tracked Phase 168 and 169 artifact PNGs the browser runs rewrote were restored by path.

## Decisions Made

- The 12 coupled reds were spec drift. Evidence: Phase 175 (`replay_action.ex`, `b5b15dad`, covered by its own prohibition contract) renders the replay button only for a replayable or retryable target, so the first, unlinked seed row can never show `operator-replay-open`; the replay copy and `:review_changed` text are the Phase 175 strings; `technical_details` stopped being a disclosure in `1e4aae4c`; D-01 removed the Apply button `structural.spec.js:947` measured. No product file was changed to satisfy a spec.
- "No new axe violations" is measured against a neutral baseline of the same collection and theme, with record UUIDs normalized. The Deliveries row buttons carry a Phase 113 `aria-selected` on `<button>` defect (critical `aria-allowed-attr`); coupled specs assert that attribute, so it is logged in `deferred-items.md` rather than altered here.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stale coupled browser specs (12 cases, 4 files)**
- **Found during:** Task 4 (first coupled run)
- **Issue:** `flows.spec.js` (:538, :747, :824, :1215 x3, plus the real-zoom case's `summary` click), `operator.spec.js` (:80, :194, :227, :264), `phase169-journey.spec.js` (:459), `structural.spec.js:947` asserted markup or copy that Phase 175 or plan 176-03 or D-01 changed.
- **Fix:** see Decisions Made; each assertion now matches the shipped contract while keeping its title.
- **Files modified:** `flows.spec.js`, `operator.spec.js`, `phase169-journey.spec.js`, `structural.spec.js`
- **Commit:** `25b3cdd0`
- **Owning plan (D-31 note):** `flows.spec.js`, `operator.spec.js` and `phase169-journey.spec.js` belonged to plans 176-03, 176-04 and 176-07, which logged the reds in `deferred-items.md` without fixing them.

**2. [Rule 3 - Blocking] Axe cannot be zero on Deliveries**
- **Found during:** Task 3
- **Issue:** the neutral Deliveries page already reports `aria-allowed-attr` on the row buttons (Phase 113).
- **Fix:** compare against a per-collection, per-theme neutral baseline (see Decisions Made).
- **Commit:** `f69ad34e`

**3. [Rule 3 - Blocking] No second Inbound page in the browser seed**
- **Found during:** Task 3
- **Issue:** the Inbound browser fixtures hold fewer than one page of records, so a real `page=2` cannot be seeded without editing test-support files outside this plan.
- **Fix:** the Inbound reset case opens an out-of-range `page=2`, commits a select, and asserts the URL has no `page` key and page 1 rows show. Deliveries uses the 22-row `phase169-exact` scenario and asserts "Page 2 of" before and "Page 1 of" after.
- **Commit:** `f69ad34e`

### Plan gates not fully clean (pre-existing, logged in `deferred-items.md`)

- `mix format --check-formatted` lists 10 files that no Phase 176 commit touches; the files this plan added or changed are formatted.
- `mix credo --strict` reports 1 warning and 5 readability or refactor items, none in a file this plan added (`operator_live.ex` `assign_delivery_state/5` complexity is now 24, was 23 at plan 01).

### Residual, recorded not hidden

- Long and Unicode Inbound address overflow is not exercised on a connected route: the browser seed has no such addresses. The 500-character query is covered at 360px and 200% zoom on both collections; address layout is covered by the plan 176-02 and 176-08 ExUnit tables and the retained story composition.
- IME composition (assumption A6) stays unverified, as in plans 06 and 07.

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3) plus 2 pre-existing gate findings. **Impact:** no product change; scope stays within the plan's test and planning files plus `gallery_live.ex` copy.

## Known Stubs

None.

## Threat Flags

None. T-176-21 and T-176-22 are mitigated (teeth plus restored mutations, byte-identity proven). T-176-26 is mitigated by P5 (exact keys, no `@` values, allowed and denied). No packages or lockfiles changed (T-176-SC).

## Issues Encountered

- A bare `mix verify.support_contract.admin` output shows large crash reports from the intentional failing-repo tests; they are expected and the suite ends 0 failures.
- `deferred-items.md` was extended with the resolution of every earlier browser red and the pre-existing gate findings.

## Next Phase Readiness

Phase 176 plans are all complete. Remaining lifecycle: phase verification and `phase.complete`.

## Self-Check: PASSED

- Files: contract test, both spec files, `176-VALIDATION.md` exist; `git diff --exit-code mailglass_admin/priv/static/` clean.
- Commits `8ca9ce01`, `22693b68`, `f69ad34e`, `25b3cdd0` are on `main`; `git rev-list --count 665ef685..HEAD` = 4 before this summary.
