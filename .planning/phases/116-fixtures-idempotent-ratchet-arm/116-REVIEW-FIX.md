---
phase: 116-fixtures-idempotent-ratchet-arm
fixed_at: 2026-06-20T00:00:00Z
review_path: .planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 116: Code Review Fix Report

**Fixed at:** 2026-06-20
**Source review:** `.planning/phases/116-fixtures-idempotent-ratchet-arm/116-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (Warnings WR-01..WR-04; the 4 Info findings IN-01..IN-04 were out of scope and not touched)
- Fixed: 4
- Skipped: 0

All fixes preserve and strengthen the phase's core property — idempotent,
fail-closed gates — and leave the FROZEN baselines (`reference/demo_app`,
`host_app`) untouched. The committed `docs/axe-baseline.json` was not modified;
its existing `current.run_id` (`axe-2026-06-20-phase-116`) remains distinct from
`prior.run_id` (`2026-06-20-phase-116-axe`), so the existing baseline stays
valid under the hardened producer.

## Fixed Issues

### WR-01: Axe producer's hardcoded run_id collides with committed `prior.run_id` on a same-day re-run

**Files modified:** `mailglass_admin/e2e/axe-baseline.spec.js`
**Commit:** `705c6a6b`
**Applied fix:** Replaced the date-stamped literal
`${date}-phase-116-axe` with a per-invocation unique id
`axe-${ISO timestamp with :/. flattened to -}`, decoupled from any milestone
date. Added a fail-closed pre-write check: the producer reads
`existing.prior.run_id` and throws rather than writing a `current.run_id` equal
to it, so a re-baseline can never produce a vacuous self-comparison that trips
the ExUnit anti-vacuity guard.

### WR-02: Persona drift-guard "fails closed" test was a tautology

**Files modified:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs`
**Commit:** `e72697f1`
**Applied fix:** Extracted the guard's real derivation (`spec_bearing/1`) and
query (`materialized_tenant_ids/0`) into shared helpers and rewired the
production assertion ("deliveries-bearing personas ... are exactly the ones
materialized") to use them. The fail-closed test now drives that *same*
comparison (`materialized == spec_bearing`) against a genuinely drifted spec — a
phantom deliveries-bearing persona injected into `spec()` but absent from the DB
— asserts an undrifted spec passes as a precondition, then `refute`s the equality
under drift and confirms the phantom is the detected drift. Renamed the test to
"the guard's own comparison fails closed when spec() gains an unmaterialized
persona" so the name no longer overstates coverage.

### WR-03: Gallery drift-guard intent heuristic ignored its `label` argument

**Files modified:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs`
**Commit:** `e72697f1`
**Applied fix:** `gallery_intends_literal?/2` now honors `label`, mapping each
literal to its OWN per-specimen namespaced state
(`fjordline-non-ascii-names`, `fjordline-long-id`, `fjordline-long-mailable`) —
the source-literal `state` strings that assemble into each specimen's
`gallery-fjordline_stress-<state>` testid and are byte-present in
`gallery_live.ex`. (The full testid is interpolated at render time, so the guard
— which reads the gallery as text — keys on the byte-present per-specimen state
rather than the assembled testid.) Each literal is now governed independently:
dropping one specimen's state releases only that literal's byte-consistency
requirement, instead of a single shared `fjordline-aps` caption token activating
all four at once. Confirmed all three states are byte-present in the gallery, so
the assertions are active (non-vacuous) and the values match.

### WR-04: Axe producer's best-effort overlay open could silently under-count and still promote

**Files modified:** `mailglass_admin/e2e/axe-baseline.spec.js`
**Commit:** `296adf6a`
**Applied fix:** Removed the unconditional `catch` in `openOverlay` that
swallowed every opener error and scanned the surface overlay-free. The two
scrim-backed surfaces (`deliveries`, `inbound`) are now in
`OVERLAY_REQUIRED_SURFACES`; their opener failure throws (a real producer
failure). Each cell records `overlay_opened`, and the producer asserts it stays
`true` for the required surfaces, so an overlay-free scan can never be promoted
unnoticed. `preview` legitimately has no overlay and returns
`overlay_opened: false` without being a failure. The flag is stripped before
persistence, so the committed `axe-baseline.json` keeps its `{ total, rules }`
cell shape (the ExUnit comparator is unaffected).

## Verification

- **WR-02 / WR-03** (`persona_drift_guard_test.exs`): the edited test was run
  against the main repo's built admin app and live test DB
  (`mix test test/mailglass_admin/persona_drift_guard_test.exs --seed 0`):
  **7 tests, 0 failures**. The main working tree was restored to its original
  (clean) state after the run; nothing was committed there. The file also passes
  an Elixir parse check (`Code.string_to_quoted`).
- **WR-01 / WR-04** (`axe-baseline.spec.js`): `node -c` syntax check passes.
  These are CommonJS Playwright producer changes; the full end-to-end run
  requires a live operator browser server and `@axe-core/playwright`, which is
  not exercisable in this environment. WR-04 changes gate *behavior* (failing
  the producer when a required overlay won't open) and could not be run
  end-to-end here — **flagged for human verification**: run
  `cd mailglass_admin && npm run test:operator-browser -- axe-baseline.spec.js`
  against the browser server to confirm the deliveries/inbound overlays still
  open under the strict (no-catch) path and the `overlay_opened` assertion holds.
  WR-01's logic (unique id + prior-collision guard) is mechanical and verified by
  inspection.

## Out of scope (not fixed)

The four Info findings were intentionally left untouched per the fix scope
(`critical_warning`):

- **IN-01** fjordline event uses wall-clock `utc_now` (determinism-convention drift)
- **IN-02** demo landing summary count now includes the fjordline delivery under the northstar label
- **IN-03** `mailglass_admin/mix.exs` inbound-dep comment (`~> 0.2`) vs. live constraint (`~> 1.1`) drift
- **IN-04** `bucket_a_coverage_test.exs` declares a `:playwright_testid` guard kind no manifest row uses

---

_Fixed: 2026-06-20_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
