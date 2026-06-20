---
phase: 116-fixtures-idempotent-ratchet-arm
fixed_at: 2026-06-20T19:21:00Z
review_path: .planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 7
skipped: 2
status: partial
---

# Phase 116: Code Review Fix Report

**Fixed at:** 2026-06-20T19:21:00Z
**Source review:** .planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (5 Warning + 4 Info; fix_scope = all)
- Fixed: 7
- Skipped: 2

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

**Note (pre-existing, out of scope):** `demo_data_reset_test.exs` also asserts
`rerun.deliveries == 16` / `rerun.events == 35`. Those hardcoded counts predate
Phase 116 (last touched in commit 466544f3, the Docker-DX PR #65) and do not
account for the fjordline persona this phase adds (now 17 deliveries). That
count-assertion failure exists on the committed Phase-116 baseline independent
of this fix — no review finding cites it, so it was not touched here. It should
be reconciled by the phase's own verification (update the expected counts to the
post-116 cohort).

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

## Skipped Issues

### WR-01: Committed `current` axe baseline was not produced by the committed producer

**File:** `mailglass_admin/docs/axe-baseline.json:69`
**Reason:** skipped — cannot regenerate a real scan in this environment, and a
cosmetic relabel is explicitly forbidden. The only honest fix (per the review
and the phase guidance) is to regenerate the `current` block from the live
operator surfaces:
`cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js`.
That requires a running Phoenix browser server + Playwright/@axe-core, and
`node_modules` is gitignored/absent here (no network fetch + no live server in
this sandbox). Hand-editing `current.run_id` to a timestamp-shaped string would
fabricate provenance for data that is still hand-typed — exactly the "paper over
it with a cosmetic label change" the phase brief prohibits. The honest
strengthening (making the anti-vacuity guard require `current.run_id` to match
the producer's `axe-<ISO>` format) would turn the committed hand-typed data red,
which cannot be committed clean. Left for a human to run the producer and commit
a real measured `current` block.
**Original issue:** The committed `current.run_id` (`axe-2026-06-20-phase-116`)
does not match the producer's `axe-<ISO-timestamp>` format and the `current`
violations block is byte-identical to `prior`, so the "current" half of the
ratchet is a hand-authored placeholder, not a measured scan.

### IN-04: `axe-baseline.json` `prior.run_id` is a hand-typed label, eroding run_id provenance

**File:** `mailglass_admin/docs/axe-baseline.json:4`
**Reason:** skipped — same root cause as WR-01. `prior.run_id`
(`2026-06-20-phase-116-axe`) is hand-typed because the matching `current` was
never produced by a real scan; the producer preserves `prior` verbatim, so the
honest fix is to promote a *real* `current.run_id` (a producer timestamp) into
`prior` during the next re-baseline (plan 116-06's `current → prior`
promotion). That depends on first having a producer-generated `current`
(WR-01), which cannot be done here. Editing `prior.run_id` in isolation would
not restore the audit trail and would still leave both blocks untraceable to a
producer run.
**Original issue:** `prior.run_id` is a hand-authored milestone label rather
than a producer timestamp, so neither committed block traces to a producer run.

---

_Fixed: 2026-06-20T19:21:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
