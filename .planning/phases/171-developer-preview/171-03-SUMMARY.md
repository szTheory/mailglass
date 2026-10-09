---
phase: 171-developer-preview
plan: 03
subsystem: ui
tags: [phoenix-liveview, preview, renderer, accessibility, playwright]
requires:
  - phase: 171-02
    provides: "Selected scenario rendering state and retained last-success artifacts."
provides:
  - "Truthful Renderer HTML/plaintext, illustrative Raw, and preview header panes with complete panel relationships."
  - "Manual-activation keyboard tabs with wrapping focus, Home/End, visible focus, and keyboard-scrollable output panels."
affects: [171-04, preview, guides]
actuals:
  tokens: 7252
  tasks: 2
  commits: 5
plan_head_before: 606a23e9540486926632900bd64d4103b0478f96
plan_head_after: 0827bb7c81c02ce0d1b90659808b616fa785712c
tech-stack:
  added: []
  patterns:
    - "Use APG manual-activation tabs: roving focus stays local while Enter, Space, or click activates the LiveView tab."
    - "Keep tabpanel IDs stable and expose only the selected panel's representation content."
key-files:
  created: []
  modified:
    - guides/preview.md
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/e2e/structural.spec.js
key-decisions:
  - "Label each output by its provenance and describe Renderer as the shared content-rendering stage, with preflight and delivery downstream."
  - "Use manual tab activation so arrow-key travel does not send LiveView events."
  - "Mount the script-disabled HTML iframe only while the HTML panel is selected, preserving its resource behavior without loading it from a hidden panel."
patterns-established:
  - "A tablist-scoped hook handles focus movement and preserves the roving tab stop across LiveView patches."
  - "Focusable output panels handle PageUp/PageDown and arrow-key scrolling within their bounded scroll region."
requirements-completed: [PRVUX-03, PRVUX-04]
coverage:
  - id: D1
    description: "Four output tabs identify Renderer HTML/plaintext, illustrative MIME-shaped Raw, and scenario or preview header values; panel relationships resolve and long Unicode content remains complete."
    requirement: PRVUX-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs — output provenance, renderer equality, panel relationships, and long content"
        status: pass
    human_judgment: false
  - id: D2
    description: "Browser keyboard users can enter one tab stop, navigate with wrapping arrows and Home/End, manually activate, and scroll long output; selected state survives a failed render."
    requirement: PRVUX-04
    verification:
      - kind: e2e
        ref: "npm run test:operator-browser -- --grep 'Phase 171 tabs'"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-09
status: complete
---

# Phase 171 Plan 03: Developer Preview Output Summary

**The preview now distinguishes renderer output from illustrative MIME and generated preview values, with complete keyboard-operable tabs for all four representations.**

## Performance

- **Duration:** 17 minutes
- **Started:** 2026-10-09T13:58:48Z
- **Completed:** 2026-10-09T14:16:09Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Matched the HTML iframe `srcdoc` and Text pane to `Mailglass.Renderer` output. Raw is explicitly illustrative, and Message-ID/Date are described as preview values generated when the scenario omits them.
- Added stable, labelled panel targets for all four tabs, keyboard-focusable bounded output panels, explicit empty-HTML guidance, and complete long/non-ASCII plaintext rendering.
- Corrected Preview page and guide copy about delivery and telemetry. The guide also states that remote resource URLs may trigger browser requests and that iframe sandboxing is not sanitization or a privacy boundary.
- Added manual-activation keyboard navigation through the existing asset bootstrap and connected browser proof for focus movement, activation, scrolling, and selected-state retention after a render failure.

## Task Commits

1. **Task 1 RED: output provenance and panel assertions** — `03eb3d33` (`test`)
2. **Task 1 GREEN: truthful output and panel semantics** — `6602c575` (`feat`)
3. **Task 2 RED: manual preview tabs browser journey** — `c48507f6` (`test`)
4. **Task 2 GREEN: accessible keyboard tabs and scrolling** — `35df4674` (`feat`)
5. **Renderer-boundary comment correction** — `0827bb7c` (`docs`)

The RED tests failed on the intended missing output labels and four tabbable controls. Green verification passed after implementation.

## Files Created/Modified

- `guides/preview.md` — distinguishes Renderer output from preflight, adapter transformations, and delivery; documents iframe resource limits.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — corrects page copy, telemetry notes, and the renderer boundary comment.
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` — labels four representations, adds stable panel relationships, and keeps inactive iframe content unmounted.
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` — adds scoped manual-tab focus and panel scrolling hooks.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` — proves renderer equality, provenance, panel relationships, empty HTML, and complete Unicode output.
- `mailglass_admin/e2e/structural.spec.js` — proves real browser focus, wrapping, manual activation, scrolling, and recovery behavior.

## Decisions Made

- HTML/Text are Renderer content; the Raw envelope is illustrative and Headers show scenario or preview values. Neither preview values nor browser output are provider or recipient proof.
- Arrow/Home/End moves focus only. Enter, Space, and click keep using the existing `set_tab` event.
- The HTML iframe remains script-disabled and only mounts while its panel is selected, so inactive panels do not initiate its resource loads.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the existing active-pane test selector unambiguous**
- **Found during:** Task 2 browser integration
- **Issue:** Four real tabpanels made the existing `preview-pane` test ID resolve to multiple elements.
- **Fix:** Keep stable IDs and ARIA relationships on all panels, but expose the existing test ID only on the active panel.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- **Verification:** Focused LiveView suite and connected browser journey pass.
- **Committed in:** `35df4674`

**2. [Rule 1 - Bug] Removed stale claims about telemetry and delivery equivalence**
- **Found during:** Task 1 and final changed-file scan
- **Issue:** Existing module and renderer comments said Preview emitted no telemetry and matched the production send path exactly.
- **Fix:** State that Preview adds no preview-specific telemetry, the shared Renderer emits normal lifecycle telemetry, and this path ends before outbound preflight and delivery.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`
- **Verification:** Source scan confirms the old claims are absent; output and documentation checks pass.
- **Committed in:** `6602c575`, `0827bb7c`

**3. [Rule 2 - Missing Critical Functionality] Added keyboard scrolling to bounded panels**
- **Found during:** Task 2 connected browser verification
- **Issue:** Chromium focused the overflow panel, but native PageDown and ArrowDown did not scroll its long content.
- **Fix:** Add a panel-scoped listener for PageUp/PageDown, Space, and ArrowUp/ArrowDown that scrolls only the focused panel.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- **Verification:** The connected browser test confirms a long Unicode panel scrolls with PageDown.
- **Committed in:** `35df4674`

**4. [Rule 2 - Missing Critical Functionality] Avoided mounting hidden HTML iframe content**
- **Found during:** Task 2 panel integration
- **Issue:** Keeping all panel relationships in the DOM would also mount the HTML iframe when another representation was selected, potentially loading remote resources before the author opened HTML.
- **Fix:** Keep each panel target present but mount its representation content only when selected; the iframe retains its original script-disabled sandbox and resource behavior.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- **Verification:** Focused LiveView and connected browser checks pass; the guide documents remote-resource behavior.
- **Committed in:** `35df4674`

**5. [Rule 3 - Blocking Issue] Added the required stable ID to the hook host**
- **Found during:** Task 2 compilation
- **Issue:** Phoenix LiveView requires an `id` on elements with `phx-hook`.
- **Fix:** Added a stable ID to the tablist hook host.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- **Verification:** Asset build, LiveView tests, and connected browser test pass.
- **Committed in:** `35df4674`

**Total deviations:** 5 auto-fixed (2 Rule 1, 2 Rule 2, 1 Rule 3)
**Impact on plan:** These fixes preserve existing browser-test behavior, resource semantics, and complete keyboard access within the requested scope.

## Issues Encountered

- The first browser attempt was blocked before Chromium launch by workspace sandbox permissions. The same focused command was rerun with elevated execution permission and completed in Chromium.
- The browser test locator initially used a non-existent field name; it was corrected to the form's `assigns[user_name]` field before final verification.

## Verification

- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` — 40 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 npm run test:operator-browser -- --grep "Phase 171 tabs"` — 1 browser test passed.
- The connected Operator Browser Gate remains an advisory lane per the phase context; it is not described as a required CI Green leaf.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 171-04 can build on the stable representation panels and preview boundary copy. The browser journey is proven through the existing advisory browser server.

---
*Phase: 171-developer-preview*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary exists at the required phase path.
- Task commits `03eb3d33`, `6602c575`, `c48507f6`, `35df4674`, and `0827bb7c` are ancestors of HEAD.
- `gsd_run check evaluation-scope --plan "171-03" --commits-only --raw` resolved all five plan commits with no unreachable or missing commits.
- Both task acceptance criteria and plan verification commands passed: focused LiveView suite (40 tests) and the connected Chromium tab journey (1 passed).
- `git diff --check` passes.
