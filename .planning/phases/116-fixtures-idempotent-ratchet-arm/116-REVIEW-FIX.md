---
phase: 116-fixtures-idempotent-ratchet-arm
fixed_at: 2026-06-21T16:00:00Z
review_path: .planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: all_fixed
---

# Phase 116: Code Review Fix Report

**Fixed at:** 2026-06-21T16:00:00Z (WR-01/IN-04 completed in a follow-up pass — see below)
**Source review:** .planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (5 Warning + 4 Info; fix_scope = all)
- Fixed: 9
- Skipped: 0

> **Follow-up pass (2026-06-21):** The initial fixer pass left WR-01 and IN-04
> skipped because regenerating the axe baseline needs a live Phoenix browser
> server + Playwright. That environment turned out to be available
> (`node_modules` + cached Chromium present; the Playwright config auto-boots the
> operator browser server), so both were resolved by running the real producer —
> see the **Resolved in follow-up pass** section. The demo-reset count
> assertion flagged under WR-04 as "pre-existing, out of scope" was also
> reconciled (it was in fact a Phase-116 regression, not pre-existing). Net:
> all 9 review findings fixed, plus the demo-reset regression.

All seven fixed findings were validated against the actual touched files. The
admin ExUnit suites that exercise the changes ran green in an isolated worktree
(deps/_build borrowed from the main repo to avoid a network refetch, then
unlinked before committing):

- `mix test test/mailglass_admin/axe_baseline_test.exs` — 12 tests, 0 failures
  (includes 3 new verify-by-construction tests added by WR-02/WR-03).
- `mix test test/mailglass_admin/bucket_a_coverage_test.exs test/mailglass_admin/persona_drift_guard_test.exs`
  — 17 tests, 0 failures (includes the new IN-02 cross-check).
- `bash mailglass_admin/scripts/check-conformance.sh` — exit 0, "conformance
  clean" (IN-03 non-empty assertion satisfied by real icon usage).
- The demo-app `Personas.seed!/2` anchor-threading (WR-04/WR-05) was exercised
  via `demo_data_reset_test.exs`: its determinism assertion (`Map.take(rerun,
  deterministic_keys()) == Map.take(baseline, ...)`) passed across two
  `reset!/0` runs, confirming the anchor threading preserved determinism. See
  the note under WR-04 about a **pre-existing, unrelated** count-assertion
  failure in that test.

## Fixed Issues

### WR-02: Bucket-A `A16-axe` cites a "system cell <= dark cell" property that no guard enforces

**Files modified:** `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs`
**Commit:** 3c3bac2a
**Applied fix:** Took the reviewer's option (a) — added a real, fail-closed
parity assertion (`"system cell never carries more violations than the dark
cell (A16-axe parity)"`) that compares the `current` block's `system` cell to
its `dark` cell per-total AND per-rule across all three surfaces. The committed
data (every cell `total: 1`) already satisfies it, so the test passes; the
A16-axe ledger desc is now genuinely backed rather than vacuous. The
bucket_a_coverage `:axe` citation literal (`axe-baseline.json`) still resolves,
so no manifest edit was needed.

### WR-03: `compare_axe` per-rule diff tolerates a `nil`/missing rules map under a flat total

**Files modified:** `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs`
**Commit:** 3c3bac2a (same file as WR-02)
**Applied fix:** Added a `cond` branch in `compare_axe/2` that fails closed when
a present cell has a non-zero `total` but a missing/non-map `rules` map
(`{total: n, rules: null}`), so a producer regression that drops rule detail
under a flat total is now caught. The guard is scoped to `total > 0` so a
legitimately clean `{total: 0, rules: nil}` cell does not trip it. Added two
verify-by-construction tests (one asserting the new failure, one asserting the
zero-total tolerance).

### WR-04: Demo fjordline materializer uses raw `utc_now`, bypassing the deterministic seed anchor

**Files modified:** `reference/persona_spec/personas.ex`, `reference/demo_app/lib/mailglass_demo/demo_data.ex`
**Commit:** fc5b7332
**Applied fix:** Threaded the time origin through the materializer instead of
re-reading the clock inside `Personas`. `Personas.seed!/1` → `seed!/2` and
`materialize!/2` → `materialize!/3` now take an explicit `occurred_at`
`DateTime`. `DemoData.reset!/0` passes its shared `seed_anchor()` (the same
anchor `minutes_ago/1` uses), so the fjordline delivery/event timestamps — and
the event `idempotency_key` derived from `DateTime.to_unix(occurred_at)` — are
now anchor-relative like the rest of the seed. Validated determinism: the
`demo_data_reset_test.exs` deterministic-keys comparison passed across two
resets.

**Note — RESOLVED in follow-up pass (commit f71b2cc5):** `demo_data_reset_test.exs`
asserted `rerun.deliveries == 16` / `rerun.events == 35`. This was *not*
pre-existing as first reported: Phase 116-01 (commit fcf56362) added
`Personas.seed!` to `DemoData.reset!/0`, which materializes the fjordline-aps
single-Delivery persona (1 Delivery + 1 `:delivered` Event), so the determinism
guard had been red since 116-01. Reconciled the literal assertions to the true
post-persona snapshot: 17 deliveries, 36 events, and the long_delivery_id
`del_01JXW9ZQKB3V1N4P2RMT7FHCG` at the head of `delivery_message_ids`
(lowercase `d` sorts before `p`/`s`). Verified: `mix test
demo_data_reset_test.exs --seed 0` → 1 test, 0 failures.

### WR-05: Persona materializers use a positional catch-all clause that silently mis-materializes unknown payload kinds

**Files modified:** `mailglass_admin/test/support/operator_fixtures.ex`, `reference/persona_spec/personas.ex`
**Commits:** be9130d6 (admin `operator_fixtures.ex`), fc5b7332 (`personas.ex`, bundled with WR-04 since both edit the same fjordline clause)
**Applied fix:** Replaced both bare catch-all clauses with an explicit
`payload: %{kind: :single_delivery} = payload` match. An unknown/typo'd
`payload.kind` now raises `FunctionClauseError` (fail-closed) at materialize
time instead of being silently routed into the fjordline single-delivery branch
and crashing mid-insert on a missing field. Applied to both
`OperatorFixtures.materialize_persona!/1` (admin) and `Personas.materialize!/3`
(demo).

### IN-01: `bucket_a_coverage_test.exs` A24 `do: "—"` citation is brittle to gate reformatting

**Files modified:** `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs`
**Commit:** f3f447bb
**Applied fix:** Took the reviewer's option — changed the A24 `:grep_gate`
locator from the verbatim em-dash token `do: "—"` to the stable gate name
`STATCARD-GATE` (the gate whose negative-grep pattern contains that token), with
a comment explaining why. A whitespace-only reformat of the gate pattern can no
longer surface as a confusing "STALE CITATION (A24)". `STATCARD-GATE` is present
in `check-conformance.sh`, so the citation still resolves; A12 already cites the
same gate (duplicate locators are an established manifest pattern, e.g. A4/A23).

### IN-02: `gallery_intends_literal?` state strings are duplicated, uncross-checked, in the matrix spec

**Files modified:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs`
**Commit:** 83dfd1a1
**Applied fix:** Added a test asserting every state in
`@fjordline_specimen_states` appears in `gallery-matrix.spec.js` STRESS_CELLS as
a `gallery-fjordline_stress-<state>` testid, plus a `matrix_spec_path/0` helper.
A dropped specimen now fails one obvious place rather than relaxing the
drift-guard silently. Also relocated the `@fjordline_specimen_states` attribute
to the top of the module (module attributes are read at point of use during
compilation, so it had to precede the new test that references it); the
explanatory comment stays with the helper.

### IN-03: ICON-EXISTS-GATE cannot distinguish "zero icons used" from "scan found nothing"

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`
**Commit:** ec386349
**Applied fix:** Added `[[ -s "$used_icons" ]] || { echo "FAIL: ICON-EXISTS-GATE
— zero hero-* usages scanned ..."; exit 2; }` after building `used_icons`. Under
`set -euo pipefail` the masked `grep` exit on zero matches would otherwise read
as "no missing icons" and pass vacuously; the admin lib always references
`hero-*` icons, so an empty scan is now treated as a path/scan error and fails
loud. Verified: `bash check-conformance.sh` still exits 0 (real icons are
scanned, assertion satisfied) and `bash -n` syntax check passes.

## Resolved in follow-up pass (2026-06-21)

### WR-01: Committed `current` axe baseline was not produced by the committed producer

**File:** `mailglass_admin/docs/axe-baseline.json`
**Commit:** 5c32f7e4
**Applied fix:** Ran the real producer against the live operator surfaces —
`PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js`.
The Playwright config auto-boots the operator browser server
(`reuseExistingServer` off-CI), and `node_modules` + cached Chromium were
present, so the scan ran for real (9 cells: deliveries/inbound/preview ×
light/dark/system, overlays folded in — all green). The `current` block now
carries a genuine producer `run_id` (`axe-2026-06-21T15-53-05-411Z`) and
measured violations. The measured values matched the previously hand-typed ones
exactly (every cell `total: 1` — `scrollable-region-focusable` on the operator
surfaces, `aria-allowed-attr` on preview), confirming the old hand-typed data
was *accurate* but now it is provenance-backed rather than authored. The
12-test ExUnit comparator passes.

### IN-04: `axe-baseline.json` `prior.run_id` is a hand-typed label, eroding run_id provenance

**File:** `mailglass_admin/docs/axe-baseline.json`
**Commit:** 5c32f7e4 (bundled with WR-01)
**Applied fix:** Did the `current → prior` promotion the review's fix called
for. After the first genuine producer run, promoted that measured scan into
`prior` (so `prior.run_id` = `axe-2026-06-21T15-51-22-195Z`, a real producer
timestamp), then ran the producer again to capture a fresh `current`. Both
blocks now trace to genuine producer runs with distinct ISO timestamps; the
anti-vacuity guard (`prior.run_id != current.run_id`) holds on real data, and
the two blocks are legitimately equal (no accessibility regression in the
current tree), which the comparator explicitly permits. No hand-typed `run_id`
remains in the file.

---

_Initial fix pass: 2026-06-20T19:21:00Z (7 fixed, 2 skipped)_
_Follow-up pass: 2026-06-21 (WR-01 + IN-04 resolved; demo-reset regression reconciled)_
_Fixer: Claude (gsd-code-fixer) + orchestrator follow-up_
_Iteration: 1_
