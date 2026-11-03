---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "14"
subsystem: testing
tags: [prohibition-contract, mutation-proof, gates, liveview, d-30, d-52, tdd]
status: complete
gap_closure: true

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plans 11, 12, 13 and 15: raw_source/1 selector, value-bearing copy names, non_default_window?/1 and class toggle, filter_url_invalid and Not applied option"
provides:
  - "Contract describes P9..P13 in the merge-blocking phase176_prohibition_contract_test.exs, each with a teeth case (P13 reuses the P8 detector) and a recorded red source mutation"
  - "Eleven gap task rows in 176-VALIDATION.md (176-11-01 .. 176-14-02)"
  - "176-REVIEW-DISPOSITION.md: nine findings fixed with plan refs, WR-08 deferred (D-29), open: 5, plus nine UI-review warning rows"
  - "Every Phase 176 gate re-run after the gap round as an independent command with counts"
affects: [phase-176-verification]

plan_head_before: 984e991103b15540931fbd689d831b6fac0ea977
plan_head_after: b03900dadeade210ce07d5763eb4724a41b069c7
actuals:
  tokens: 14500
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Gap must-NOTs become contract describes with a private detector, a teeth case that feeds the detector a known violation, and one recorded source mutation"
    - "Detectors refuse a vacuous pass: P9 requires a revealed pre and a parseable byte count, P10 asserts a minimum button count and the seeded values, P12 asserts a toggle_class op exists"

key-files:
  created: []
  modified:
    - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VALIDATION.md
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-REVIEW-DISPOSITION.md

key-decisions:
  - "P11's detector flags an empty Deliveries pane (filtered or genuine) rendered without #operator-filters, and is applied only to states with a committed non-default window; a genuine no-data pane without a toolbar remains correct elsewhere"
  - "P13 asserts the URL note is present after a re-post and that the draft note is present too (D-12 co-occurrence); it never asserts the draft note is absent"
  - "Gate (7) is advisory (D-29): the two full-run failures were not hidden, they are reported and the isolated re-run is recorded beside them"

requirements-completed: ["FILTER-01", "FILTER-04", "INUX-05", "INUX-06"]

coverage:
  - id: D1
    description: "P9..P13 are merge-blocking contract describes, each mutation-proven"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs (38 tests, 0 failures, --seed 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase 176 gates re-run after the gap round with recorded counts"
    requirement: "INUX-06"
    verification:
      - kind: integration
        ref: "mix verify.support_contract.admin (878 tests, 0 failures, 1 excluded); bash scripts/gsd-regression-gate.sh exit 0"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-28
---

# Phase 176 Plan 14: Gap Prohibitions P9..P13 and Gate Re-run Summary

**The five gap must-NOTs (Payload size vs revealed bytes, copy-control names, Deliveries toolbar under a narrower window, inline display on the filter panel, URL-invalid label after an edit or reconnect) are now mutation-proven contract describes P9..P13 in the merge-blocking admin suite, and every Phase 176 gate was re-run against its recorded baseline.**

## Performance

- **Duration:** about 25 min (start time was not captured at launch; estimated from the first and last tool timestamps)
- **Completed:** 2026-10-28
- **Tasks:** 2 (176-14-01 tracer, 176-14-02 auto)
- **Files modified:** 3

## Accomplishments

- Four teeth cases appended to "detectors have teeth" (P9, P10, P11, P12). P13 reuses the P8 `note_violations/2` detector, whose teeth case already existed.
- Describes P9..P13 added after P8 with private detectors `payload_size_violations/1`, `copy_name_violations/1`, `toolbar_violations/1`, `toggle_op_violations/1` and helper `draft_note_present?/1`. The moduledoc now says thirteen prohibitions and names the owning requirements. Contract file: 38 tests, 0 failures at `--seed 0` (was 24 before this plan).
- Eleven gap rows added to the 176-VALIDATION.md verification map; `nyquist_compliant: true` and `wave_0_complete: true` kept.
- 176-REVIEW-DISPOSITION.md: WR-01..WR-07, IN-04 and IN-07 set to fixed with the fixing plan, WR-08 deferred ("advisory browser lane under D-29, not merge-blocking"), `open: 5` (9 fixed, 1 deferred, 5 open, `total: 15`). New section "UI review warnings (176-UI-REVIEW.md)" with nine rows: eight deferred (UI-TF2, UI-TF4, UI-TF5, UI-HELP-TARGET, UI-TOGGLE-HEIGHT, UI-STALE-TITLE, UI-STALE-REPEAT, UI-SPACING-GAP2) and UI-WINDOW-NOTE reconciled by 176-15-02.

## Task Commits

1. **176-14-01: P9..P13 with teeth** - `c09e23d3` (test)
2. **176-14-02: validation rows, review disposition** - `b03900da` (docs)

The SUMMARY and STATE/ROADMAP commit follows these.

## Mutation records (176-14-01)

Protocol per mutation: `git diff --quiet -- <file>` before, `cp` to a `mktemp -d` snapshot, mutate, run the contract file, `cp` back, `cmp` against the snapshot, `git diff --quiet` on the file, rerun green. No `git checkout` of a mutated file.

| # | Describe | Source mutation | Red test(s) under the mutant | cmp / git diff | Rerun |
|---|----------|-----------------|------------------------------|----------------|-------|
| 1 | P9 | `evidence_card.ex`: a `payload_byte_size/1` clause measuring a non-empty `raw_mime` before the shared selector | "P9 ... the component with both fields stored sizes the exact revealed text" (`Payload size states 21 bytes, the revealed text is 34 bytes`); "P9 ... the live authorized reveal of a record seeded with both fields agrees" (16 vs 27 bytes). 2 failures | cmp 0, diff 0 | 38 tests, 0 failures |
| 2 | P10 | `components.ex`: `copy_value/1` aria-label changed to `"Copy #{@label}"` | "P10 ... the full Inbound detail names every contact and record copy control" (From, To, Cc, Delivered to, Record, Run controls named without values); "P10 ... the full Deliveries detail names the provider message id control". 2 failures | cmp 0, diff 0 | 38 tests, 0 failures |
| 3 | P11 | `operator_live.ex`: `or non_default_window?(...)` removed from `filters_active?/1` | "P11 ... keeps the toolbar (commit)" and "P11 ... keeps the toolbar (URL)". 2 failures | cmp 0, diff 0 | 38 tests, 0 failures |
| 4 | P12 | `operator_live.ex`: toggle `phx-click` starts with `JS.toggle(to: "#operator-filter-panel")` again | "P12 ... the mobile toggle switches a class and the panel carries no style". 1 failure | cmp 0, diff 0 | 38 tests, 0 failures |
| 5 | P13 | `operator_live.ex`: URL note `:if` reverted to `@filter_error_source == :url` | "P13 ... Deliveries keeps the event note when Search re-posts the invalid value" (`no filters-url-invalid-note rendered`). 1 failure; P8 stayed green under the same mutant, which is what P13 adds over P8 | cmp 0, diff 0 | 38 tests, 0 failures |

After the task: `git status --porcelain -- mailglass_admin/lib` empty, and the same held after every gate.

## Gate results (176-14-02)

All run from `mailglass_admin/` (or the repo root where noted) with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`, each as its own command.

| Gate | Command | Exit | Counts |
|------|---------|------|--------|
| 1 Targeted ExUnit set | `mix test` over the contract file, operator_live, inbound_live, components, inbound/components, evidence_card, quick_view_projection tests, `--seed 0` | 0 | 532 tests, 0 failures |
| 2 Full admin suite | `mix verify.support_contract.admin` | 0 | 878 tests, 0 failures, 1 excluded |
| 3 Scoped format | `mix format --check-formatted` over the fourteen gap-round Elixir files | 0 | clean |
| 4 Credo vs baseline | `mix credo --strict --format oneline`, normalized and compared with `comm -13` against the six-finding HEAD baseline | 0 | 6 findings parsed, 0 new. Identical to baseline, including `operator_live.ex` complexity 24 (no increase). Credo prints 23 pre-existing "Ignoring an undefined check" config lines |
| 5 Conformance | `bash scripts/check-conformance.sh` | 0 | "OK: design-system conformance clean." |
| 6 Fresh bundle | `mix mailglass_admin.assets.build`, `git diff --exit-code --stat priv/static/` | 0 | no diff; `priv/static` clean before and after (restored by path regardless) |
| 7 Browser (advisory, D-29) | wrapped `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters flows inbound-layout phase169-journey phase175-inbound structural phase170-journey` | 1 | first run 220 passed, 2 failed, 1 skipped (see below). Isolated rerun of the two failing spec files: 16 passed, exit 0 |
| 8 Regression gate | `bash scripts/gsd-regression-gate.sh` | 0 | storybook evidence node tests 42 pass / 0 fail; core 81 tests, 0 failures; admin 878 tests, 0 failures, 1 excluded; inbound 3 properties, 480 tests, 0 failures, 3 excluded; connected browser suite 31 passed |

Document checks: VALIDATION gap-row count `grep -c '^| 176-1[1-5]-0[1-3] |'` = 11 with `nyquist_compliant: true` kept (exit 0); the 11-clause REVIEW-DISPOSITION check (9 fixed, WR-08 deferred, 5 open frontmatter entries, `open: 5`, UI section, 8 deferred plus 1 reconciled UI rows, 9 UI rows total) exit 0.

### Gate 7 detail

- The four gap-round browser tests all passed: "Phase 176 gap: deliveries filter panel is visible at desktop width after a mobile close", the inbound equivalent, "Phase 176 URL-invalid labelling: deliveries keeps the URL note after reconnect and Search", and the inbound equivalent. "the mobile Filters toggle reaches 44px and does not clip at 200% zoom" (UI-TOGGLE-HEIGHT) also passed.
- First-run failures, neither in a file or behaviour this gap round touches:
  1. `phase169-journey.spec.js:208` "current suppression stays distinct from history, totals, and an unavailable refresh": `operator-suppression-unavailable` not found within 5 s after the refresh click.
  2. `phase170-journey.spec.js:292` "responsive themes, touch, focus, reduced motion, and current evidence at each viewport": `locator.evaluate: Execution context was destroyed, most likely because of a navigation`.
- Rerunning `phase169-journey.spec.js phase170-journey.spec.js` alone through the same wrapper: 16 passed, 0 failed, exit 0. Both behave as order- or timing-dependent in the seven-spec run. They are reported as observed, not dismissed: the lane is advisory (D-29), they pass in isolation, and no Phase 176 behaviour was involved. Verify-work should treat gate 7 as 220 + 16 verified with a known flaky pair, not a clean 222.
- The wrapper's clean-check passed before each run and the by-path restore left `app.css` and the Phase 168/169 artifact directories identical to HEAD (verified after both runs; `git status` shows only the user's pre-existing `.planning` WIP and `prompt.txt`).
- Demo specs: `grep -nE '...' reference/demo_app/assets/e2e/phase176-filters.spec.js reference/demo_app/assets/e2e/inbound-evidence.spec.js` printed nothing and exited 1, so both are recorded as unaffected and not run.

### Informational whole-tree format

`mix format --check-formatted` over the whole admin tree exits 1 on exactly the ten baseline files from deferred-items.md and no other: `lib/mailglass_admin/auth.ex`, `lib/mailglass_admin/operator/replay_modal.ex`, `lib/mailglass_admin/operator/timeline.ex`, and under `test/mailglass_admin/`: `brand_test.exs`, `bucket_a_coverage_test.exs`, `inbound/replay_modal_test.exs`, `mix_config_test.exs`, `persona_drift_guard_test.exs`, `preview/chromium_test.exs`, `stability_contract_test.exs`. Pre-existing format and credo debt stays deferred; this plan fixed none of it.

## Placement

Merge-blocking: the contract file runs inside `mix verify.support_contract.admin` (gate 2) and the regression gate (gate 8). Advisory (D-29): gate 7 (Playwright). REQUIREMENTS.md checkboxes for FILTER-01, INUX-05 and INUX-06 are not edited here; verify-work owns them.

## Deviations from Plan

None - plan executed exactly as written. The only unplanned action was the isolated rerun of the two failing browser specs, which is recorded above beside the original failure.

## Issues Encountered

- Gate 7 first run: 2 failed (phase169 suppression refresh, phase170 viewport evidence), both green on an isolated rerun. See Gate 7 detail.
- A local `sed -i` using macOS syntax failed once while trimming a stray `%{}` test context argument; the same edit was applied with python and the file was formatted and re-checked.

## Known Stubs

None.

## Threat Flags

None. This plan adds tests and planning documents only; no library source changed (`git status --porcelain mailglass_admin/lib` empty throughout).

## Next Phase Readiness

All four gap-round plans plus this one are complete. `/gsd-verify-work 176` can re-close FILTER-01, INUX-05 and INUX-06 and confirm FILTER-04 against the counts above.

## Self-Check: PASSED

- `mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs`: present; commit `c09e23d3` is an ancestor of HEAD.
- `176-VALIDATION.md` and `176-REVIEW-DISPOSITION.md`: present; commit `b03900da` is an ancestor of HEAD.
- `git status --porcelain -- mailglass_admin/lib` empty; no mutation left in source.
