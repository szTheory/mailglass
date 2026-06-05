---
phase: 77-motion-and-microinteraction-polish
plan: "04"
subsystem: mailglass_admin
tags:
  - bundle
  - asset-build
  - verify-preview
  - motion
dependency_graph:
  requires:
    - phase: 77-01
      provides: record-keyed id on motion-reveal divs
    - phase: 77-02
      provides: check_motion_conformance.sh gate
    - phase: 77-03
      provides: e2e regression tests for delivery id-presence + reduced-motion
  provides:
    - mix verify.preview exits 0 (compile + ExUnit + bundle rebuild + git diff gate)
    - priv/static/ confirmed clean / bit-identical (no-op bundle rebuild)
    - MOTION-02 SC4 bundle-clean gate (D-08) satisfied
  affects:
    - mailglass_admin/test/support/citext_probe.ex
    - mailglass_admin/test/mailglass_admin/voice_test.exs
tech_stack:
  added: []
  patterns:
    - "Boundary top_level? ignored declaration for test support cross-boundary access"
    - "Script-content strip before brand-voice regex check"
key_files:
  created: []
  modified:
    - mailglass_admin/test/support/citext_probe.ex
    - mailglass_admin/test/mailglass_admin/voice_test.exs
key_decisions:
  - "[Rule 1 - Bug] citext_probe.ex boundary warnings: used `use Boundary, top_level?: true, check: [in: false, out: false]` per Boundary docs §Ignoring checks for test support — pre-existing since reconcile commit 6b4732fc"
  - "[Rule 1 - Bug] voice_test script noise: strip <script>…</script> before brand-voice regex so phoenix.mjs dep-JS is not matched — pre-existing false positive documented in project memory"
  - "Bundle rebuild confirmed no-op: HEEx id-attribute changes (Plan 77-01) added no new Tailwind classes; priv/static/ bit-identical to committed baseline"
metrics:
  duration: ~7 minutes
  completed: "2026-06-04"
  tasks_completed: 1
  files_modified: 2
---

# Phase 77 Plan 04: Asset Bundle Gate and verify.preview Clean Summary

Ran `mix verify.preview` from `mailglass_admin/` end-to-end. Fixed two pre-existing test blockers that prevented the alias from exiting 0, then confirmed the bundle rebuild is a no-op (bit-identical to baseline). Phase 77 motion vocabulary is self-verified and ready for `/gsd:verify-work`.

## Performance

- **Duration:** ~7 minutes
- **Tasks:** 1 (bundle gate + verify.preview)
- **Files modified:** 2 (test support fixes only; no priv/static/ changes)

## Accomplishments

### Task 1: Rebuild admin asset bundle and confirm priv/static/ clean (D-08 / GAP-19)

**verify.preview result:** EXIT 0 — all four stages passed:

1. `compile --no-optional-deps --warnings-as-errors`: 0 warnings, exits 0
2. `test --warnings-as-errors --exclude flaky`: 189 tests, 0 failures (2 excluded), exits 0
3. `mailglass_admin.assets.build`: tailwindcss v4.1.12 + daisyUI 5.5.19, done in ~105ms
4. `cmd git diff --exit-code priv/static/`: exits 0 — bundle is clean / no-op

**Bundle rebuild:** No-op as expected. The HEEx id-attribute changes from Plan 77-01 (`id={"delivery-detail-#{...}"}` and `id={"inbound-detail-#{...}"}`) add no new Tailwind classes. The bundle output is bit-identical to the Phase 76-06 committed baseline.

**Motion conformance:** `bash scripts/check_motion_conformance.sh` exits 0 — "OK: motion conformance clean." No banned layout-thrashing, duration, or easing tokens found in `mailglass_admin/lib/` or `assets/css/app.css`.

## Task Commit

1. **fix(77-04): fix verify.preview blockers — boundary warning + voice_test script noise** — `3390b8fe`

## Files Modified

- `mailglass_admin/test/support/citext_probe.ex` — added `use Boundary, top_level?: true, check: [in: false, out: false]` to suppress cross-boundary warnings during test compilation
- `mailglass_admin/test/mailglass_admin/voice_test.exs` — strip `<script>` blocks before brand-voice regex to avoid phoenix.mjs dep-JS false positive

## Decisions Made

- Bundle rebuild confirmed no-op: `git diff --exit-code mailglass_admin/priv/static/` exits 0. No changes to priv/static/ needed or committed for this plan.
- Two pre-existing blockers fixed inline per Rule 1 (auto-fix bugs): both issues existed since reconcile commit `6b4732fc` (May 2026) and prevented `verify.preview` from ever completing as a whole.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] citext_probe.ex: Boundary cross-boundary warnings failed `--warnings-as-errors` during test step**

- **Found during:** Task 1 — initial `mix verify.preview` run
- **Issue:** `mailglass_admin/test/support/citext_probe.ex` directly references `Mailglass.SuppressionStore.Ecto` and `Mailglass.Suppression.Entry`, both of which are internal to the `Mailglass` boundary (not exported). When `verify.preview` runs the `test` step with `--warnings-as-errors`, the Boundary compiler emits warnings that fail the compile of test support files. The standard `@compile {:no_warn_undefined, ...}` does not suppress Boundary compiler warnings. The Boundary-idiomatic solution is `use Boundary, top_level?: true, check: [in: false, out: false]`, per Boundary docs §"Ignoring checks can be useful for test support modules." Issue pre-existed since reconcile commit `6b4732fc` (May 2026); `verify.preview` was never run as a whole before this plan.
- **Fix:** Added `use Boundary, top_level?: true, check: [in: false, out: false]` with explanatory comment to `citext_probe.ex`.
- **Files modified:** `mailglass_admin/test/support/citext_probe.ex`
- **Commit:** `3390b8fe`

**2. [Rule 1 - Bug] voice_test.exs: `refute lower =~ "oops"` false positive on phoenix.mjs dep-JS**

- **Found during:** Task 1 — `mix verify.preview` test stage (exit code 2, 1 failure)
- **Issue:** The brand-voice test `"are absent from rendered UI"` calls `live(conn, "/dev/mail")` which returns HTML including inlined `<script>` blocks containing phoenix.mjs. That JS file contains the string "noops" (a logger no-op utility). `String.downcase(html) =~ "oops"` matched `n**oops**` in the dep JS, causing a false positive. Documented in project memory: "voice_test 'Oops' is dep-JS noise — exclude from phase pass/fail, don't weaken the test." Pre-existing since Phoenix began inlining phoenix.mjs; the test was never updated to scope its check to UI markup only.
- **Fix:** Strip `<script>…</script> blocks via `Regex.replace(~r/<script\b[^>]*>.*?<\/script>/si, html, "")` before running brand-voice checks. The assertion is unchanged (same `refute lower =~ "oops"` logic) — only the input is scoped to rendered markup, which is what the brand-voice rule intends.
- **Files modified:** `mailglass_admin/test/mailglass_admin/voice_test.exs`
- **Commit:** `3390b8fe`

## Known Stubs

None — this plan runs verification only; no data flows or UI rendering paths are stubbed.

## Threat Flags

None. No new auth surface, no new endpoints, no new data access patterns. Two test support files modified.

## Self-Check

Files modified:
- [x] `mailglass_admin/test/support/citext_probe.ex` — FOUND
- [x] `mailglass_admin/test/mailglass_admin/voice_test.exs` — FOUND

Commits:
- [x] `3390b8fe` — FOUND

Verification gates:
- [x] `mix verify.preview` exits 0 — CONFIRMED (189 tests, 0 failures, 2 excluded)
- [x] `git diff --exit-code priv/static/` exits 0 — CONFIRMED (bundle clean / no-op)
- [x] `bash scripts/check_motion_conformance.sh` exits 0 — CONFIRMED ("OK: motion conformance clean.")
- [x] No priv/static/ changes needed (bundle bit-identical) — CONFIRMED

## Self-Check: PASSED

---
*Phase: 77-motion-and-microinteraction-polish*
*Completed: 2026-06-04*
