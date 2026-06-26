---
phase: 114-component-groups
plan: 02
subsystem: ui
tags: [phoenix, liveview, heex, gallery, floki, exunit, mailglass_admin, composed-groups]

# Dependency graph
requires:
  - phase: 114-component-groups
    provides: "Plan 114-01 — MailglassAdmin.Components.card/1 group-surface shell + conformance gates (SPACE-GATE, GROUP-GATE, PRIMITIVE-DRIFT)"
provides:
  - "Three PUBLIC composed-group fns in gallery_live.ex (composed_support_triage/1, composed_routing_evidence/1, composed_detail_timeline/1) capturable as &GalleryLive.composed_*/1"
  - "Three gallery-composed-* specimens whose dispatcher branches delegate to the public composed_* fns (gallery route + Floki proof render the identical tree)"
  - "data-region on both production detail-column wrappers (operator_live.ex + inbound_live.ex)"
  - "One live-view smoke assertion binding the composed specimen to the production operator detail column (D-10)"
affects: ["114-03 (sweep)", "114-04 (Floki/Playwright proofs)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Composed-group specimen = public arity-1 fn wrapping the SAME group-assembling fns the live view calls (never a hand-copied HEEx tree, Pitfall 5)"
    - "nil-typed component attrs routed through assigns to keep --warnings-as-errors clean while preserving runtime nil semantics"

key-files:
  created: []
  modified:
    - "mailglass_admin/lib/mailglass_admin/gallery_live.ex"
    - "mailglass_admin/lib/mailglass_admin/operator_live.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound_live.ex"
    - "mailglass_admin/test/mailglass_admin/operator_live_test.exs"

key-decisions:
  - "Placed the live-view smoke assertion in operator_live_test.exs (the harness-bearing sibling) rather than shell_test.exs — shell_test.exs lacks the delivery-mount fixtures; the plan explicitly permits a sibling test file 'if cleaner'."
  - "Gave the composed dispatcher branches their own data-testid wrapper (gallery-composed-*) instead of relying on the generic gallery-{component}-{state} cell testid, because the component atom underscores (composed_support_triage) would not produce the required hyphenated gallery-composed-* testid."
  - "Routed nil-valued :map / :string attrs (suppression_state, latest_replay, highlight_event_id, evidence) through assign/3 so HEEx compile-time attr type-checking does not raise under --warnings-as-errors."

patterns-established:
  - "Composed-group public fn: assign data-free/minimal structural assigns, then ~H wrap <div data-region class=\"space-y-4\"> around real group fns in live-view order"
  - "Specimen↔reality binding: a live-view smoke ExUnit assertion renders the real detail column (#delivery-detail-<id>) and asserts data-region + each group testid"

requirements-completed: [GROUP-01]

# Metrics
duration: 12 min
completed: 2026-06-20
status: complete
---

# Phase 114 Plan 02: Composed-Group Specimens + data-region Instrumentation Summary

**Three public composed-group fns in gallery_live.ex (assembling the operator/inbound detail columns by calling the SAME group fns the live views call), data-region on both production detail-column wrappers, and one live-view smoke assertion binding specimen structure to reality.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-20T09:22Z (approx)
- **Completed:** 2026-06-20T09:30Z (approx)
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added bare `data-region` to the `motion-reveal space-y-4` detail-column wrapper in BOTH operator_live.ex and inbound_live.ex (scopes the plan-04 Floki ancestor-depth proof) without touching `motion-reveal`/`space-y-4` (D-12).
- Extracted three PUBLIC arity-1 fns — `composed_support_triage/1`, `composed_routing_evidence/1`, `composed_detail_timeline/1` — each wrapping `<div data-region class="space-y-4">` around the real group-assembling component functions in the same order the live views compose them.
- Wired `render_specimen/1` dispatcher branches + specimen-list + component_label registry entries so the gallery route and the plan-04 Floki proof render the IDENTICAL tree (delegation, not duplication).
- Added a live-view smoke assertion that renders the production operator detail column and asserts `data-region` + the four group testids — a specimen that drifts from production composition now fails the suite (D-10).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add data-region to operator + inbound detail-column wrappers** - `1c953a69` (feat)
2. **Task 2: Extract three public composed-group fns + gallery specimens** - `4b67928a` (feat)
3. **Task 3: Live-view smoke assertion binding specimen to reality** - `dc2e5e2c` (test)

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - 3 public composed_*/1 fns, 3 dispatcher branches delegating to them, specimen-list + component_label entries.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - data-region on the delivery detail-column wrapper.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - data-region on the inbound detail-column wrapper.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - one smoke test asserting the production detail column carries data-region + group testids.

## Decisions Made
- **Smoke test home:** placed in `operator_live_test.exs` not `shell_test.exs`. shell_test.exs renders components via `rendered_to_string`/`render_component` and has no delivery-mount harness; operator_live_test.exs already has `operator_conn`, `operator_path`, and `insert_support_summary_fixture!`, giving a genuine production-column render. The plan's action text explicitly allows "a sibling test file in the same dir if cleaner."
- **Dedicated composed testids:** the generic `gallery-{component}-{state}` cell builds `gallery-composed_support_triage-...` (underscore), which would not satisfy the required `gallery-composed-support-triage`. Each composed dispatcher branch therefore emits its own `data-testid` wrapper with the exact hyphenated value.
- **nil-attr handling:** `<EvidenceCard.evidence_card evidence={nil} ...>`, `SuppressionCard suppression_state={nil}`, `Timeline highlight_event_id={nil}`, and `DetailHeader latest_replay={nil}` raise HEEx compile-time attr-type warnings (`:map`/`:string` got nil). Routed each nil through `assign/3` so the value is dynamic at compile time, matching how the existing per-component specimens pass `@assigns_map[:...]`. Preserves identical runtime semantics.

## Deviations from Plan

### Deviation 1: smoke test file placement (plan-permitted alternative)
- **Found during:** Task 3
- **Issue:** The plan's `<files>` / `key_links` name `shell_test.exs`, but shell_test.exs lacks the delivery-mount fixtures required to render the production operator detail column; reproducing them there would duplicate the entire operator harness.
- **Fix:** Added the smoke assertion to `operator_live_test.exs` (same `test/mailglass_admin/` tree, harness present). The plan's action text explicitly permits "a sibling test file in the same dir if cleaner." Not a Rule 1-4 auto-fix — an in-bounds choice the plan delegated.
- **Verification:** `mix test test/mailglass_admin/operator_live_test.exs` → 57/57 pass (new test at :292 passes). `mix test test/mailglass_admin/operator/shell_test.exs` → 21/21 still pass (unchanged, plan verify command honored).
- **Committed in:** `dc2e5e2c`

### Deviation 2: dedicated composed-specimen testids
- **Found during:** Task 2
- **Issue:** The required testids are hyphenated (`gallery-composed-support-triage`) but the component atoms are underscored (`composed_support_triage`), so the generic dispatcher cell testid would not match.
- **Fix:** Each composed dispatcher branch wraps the public fn in a `<div data-testid="gallery-composed-...">` with the exact required value.
- **Verification:** `grep -c "gallery-composed-"` → 3.
- **Committed in:** `4b67928a`

### Deviation 3: nil-typed attrs routed through assigns (Rule 3 - blocking)
- **Found during:** Task 2
- **Issue:** Literal `nil` passed to `:map`/`:string`-typed component attrs failed `mix compile --warnings-as-errors`.
- **Fix:** Assigned the nil values via `assign/3` (mirrors existing specimens' dynamic `@assigns_map[:...]` access), keeping the compile clean and runtime behavior identical.
- **Verification:** `mix compile --force --warnings-as-errors` clean.
- **Committed in:** `4b67928a`

---

**Total deviations:** 3 (1 plan-permitted file placement, 1 testid mechanics, 1 Rule 3 blocking-compile fix).
**Impact on plan:** No scope creep. All within the plan's stated intent and the D-12 scope fence (only gallery_live.ex + the two detail-column wrappers + one operator test touched). No nav/auth/preview/list/overview file changed.

## Issues Encountered
- A `mix run` smoke script using `render_component(&GalleryLive.composed_*/1, %{})` failed with `Module.get_attribute/2 ... module nil already compiled` — this is a `render_component`-macro-in-`mix run` limitation, NOT a code defect. The composed fns compile cleanly and the production-column smoke assertion (which runs in ExUnit context) passes; plan 04 will capture the public fns inside ExUnit where the macro resolves correctly.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 114-03 (sweep) has a stable `data-region` / group-testid tree to swap `<.card>` into; `data-group-card` will land on each group's outer shell via that swap.
- Plan 114-04 (Floki/Playwright proofs) can capture the public `composed_*/1` fns and scope the ancestor-depth assertion to `data-region`.
- No CSS changed, so no `priv/static` bundle rebuild was needed (CI `git diff --exit-code` unaffected). No mix.lock drift introduced.
- Conformance script (`scripts/check-conformance.sh`) still exits 1 by design — Plan 03 sweeps it green, not this plan.

## Self-Check: PASSED
- All three task commits present in git log: `1c953a69`, `4b67928a`, `dc2e5e2c`.
- All four modified files exist on disk.
- `mix compile --force --warnings-as-errors` clean.
- `mix test test/mailglass_admin/operator/shell_test.exs` → 21/21 pass.
- `mix test test/mailglass_admin/operator_live_test.exs` → 57/57 pass (incl. new smoke test).
- `mix test test/mailglass_admin/inbound_live_test.exs` → 63/63 pass (Task 1 regression check).
- `grep -c data-region` operator_live.ex = 1, inbound_live.ex = 1; `grep -c gallery-composed-` = 3; composed_*/1 fn count = 3.

---
*Phase: 114-component-groups*
*Completed: 2026-06-20*
