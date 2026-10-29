---
phase: 178-preview-authoring-and-milestone-review
plan: "04"
subsystem: ui
tags: [phoenix-liveview, heex, a11y, playwright, mailglass_admin, preview, unicode]

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-01 AssignsForm changes (Restore defaults, id-closed describedby) that this plan's humanize delegation builds on"
provides:
  - "MailglassAdmin.Preview.ScenarioLabel: pure humanize/technical/build/module_label/scenario_label"
  - "Preview menu trigger: humanized scenario, Mailable, and exact Module.scenario as visible wrapping text"
  - "Preview menu options: humanized primary plus raw atom as wrapping monospace text; no truncation"
  - "Sidebar.menu/1 open attr (default false) for plan 178-05's story"
  - "HappyMailer sixth scenario that forces the raw-atom collision fallback"
affects: [178-05, 178-08, 178-11]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: 41ad32314d9dd262f3bcb7ef9a84f9b0972daa3c
plan_head_after: cc2df76f0329f28bf91cb23b549de61f61c7aed1

actuals:
  tokens: 9800
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Pure label table over Discovery output, looked up by {module, scenario}; lookups total with raw-atom fallback"
    - "Collision key = NFC-normalized, downcased humanized label; same-Mailable collisions fall back to raw atoms"
    - "Leaf-sharing Mailables take the shortest trailing namespace suffix that is unique across the group"
    - "assert_trigger_identity/4 ExUnit helper scoping namespace refutes to the primary and secondary spans"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
    - mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
    - mailglass_admin/test/support/fixtures/mailables.ex
    - mailglass_admin/test/mailglass_admin/discovery_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
    - mailglass_admin/e2e/structural.spec.js

key-decisions:
  - "Technical identity is inspect(mod) <> \".\" <> scenario (module alone for :__error__); it lives inside the trigger's identity block so aria-labelledby stays complete"
  - "A mailable selected with no scenario renders the Mailable as the bold primary plus the module-only technical line (undefined by the plan; chosen so no state renders an empty trigger)"
  - "The affordance rotation uses the CSS rotate property, so the polling assertion reads rotate and transform together rather than transform alone"
  - "Only classes already in the committed bundle were used; priv/static is untouched"

requirements-completed: ["PRVUX-07"]

coverage:
  - id: D1
    description: "Trigger reads humanized scenario, then Mailable, then the exact technical identity as visible wrapping monospace text; no middle-dot join, no truncate, no title on the identity, aria-labelledby unchanged"
    requirement: "PRVUX-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#compact picker exposes long non-ASCII scenario identity without truncation"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: 390px mobile email picker reaches a real scenario link"
        status: pass
    human_judgment: false
  - id: D2
    description: "Options show the humanized scenario as primary and the raw atom as wrapping monospace text, hrefs byte-identical to scenario_path/6 output with and without Phase 177 return context"
    requirement: "PRVUX-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#option hrefs are the unchanged scenario_path/6 output, with and without return context"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs#no option span truncates and each wraps"
        status: pass
    human_judgment: false
  - id: D3
    description: "Label table is pure and total: humanize, scenario and Mailable collisions (case, NFC/NFD, leaf across namespaces, :no_previews and error entries), unique {module_label, primary} pairs, no atom creation, hostile names escaped"
    requirement: "PRVUX-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "At 320px and 390px the two colliding long Unicode options and the trigger wrap without page overflow, are distinguishable by visible text, are at least 44px tall, open with Enter and Space and are selectable by keyboard; identity contrast holds in light and dark; reduced motion completes with no new animation and the affordance transition is at most 0.01ms"
    requirement: "PRVUX-07"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 selector distinguishes duplicate long Unicode scenarios at 320px and 390px"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 selector identity reads in light and dark"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview: Phase 178 selector under reduced motion"
        status: pass
    human_judgment: false
  - id: D5
    description: "AssignsForm field labels share ScenarioLabel.humanize/1: :user_name renders User name, :admin? renders Admin?"
    requirement: "PRVUX-07"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview_live_test.exs (assigns form describe)"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Preview assigns and operator replay radios keep explicit labels and descriptions"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 04: Readable Preview selector Summary

**The Preview selector now reads humanized scenario first, Mailable second, and the exact `Module.scenario` identity as visible wrapping monospace text; colliding long Unicode scenarios fall back to raw atoms, leaf-sharing Mailables get a distinguishing suffix, and every URL is unchanged.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-29T13:15Z
- **Completed:** 2026-10-29
- **Tasks:** 3
- **Files modified:** 9 (2 created, 7 modified)

## Recorded values (plan output spec)

- **Task 1 gate:** `preview_live_test.exs`, `phase177_return_navigation_test.exs`, `return_context_test.exs` `--seed 0`: 134 tests, 0 failures. Browser (`structural` + `phase177`, grep `Phase 171|Phase 177|Preview:`): 24 passed, no flaky on the second full run (see Issues Encountered for the first).
- **Task 2 red/green:** `scenario_label_test.exs` has 24 tests. Run against the task 1 implementation (scenario labels humanized only, no collision handling) 7 failed: raw-atom collision, case-only, NFC/NFD, shared-leaf suffix, one-segment vs namespaced leaf, `:no_previews`/error leaf collision, and the synthetic unique-pairs set. 24 passed after `build/1` gained the collision rules. The tests that passed before by construction are the humanize table, `technical/2`, dedupe, total lookups, the source scan and the hostile-name escape test.
- **Task 3 red/green:** the new `Phase 178 selector options` describe has 8 tests. The tests were written after the markup (see Deviations), so red was measured by restoring the task 1 `sidebar.ex` temporarily: 5 of 8 failed (option label/technical, distinguishable Unicode primaries, no-truncate, `open` attr, shared-leaf group label); the other three (hrefs unchanged, empty/single/unselected, render-error trigger) are regression guards that hold both ways. `sidebar.ex` was then restored from a saved copy.
- **Full admin suite:** `mix verify.support_contract.admin --seed 0`: 1159 tests, 0 failures, 1 excluded, no compile warnings (the `:aliases option in eval` lines are the Elixir toolchain, not this change).
- **Browser, task 3 gate** (`structural` + `flows` + `phase177`, grep `Phase 171|Phase 177|Phase 178|Preview:`): 27 passed; the three `Phase 178 selector` cases passed (848ms, 194ms, 283ms).
- **Measured contrast** (WCAG ratio, canvas-normalized colors, 390px): light technical/mailable `rgb(92, 107, 122)` 5.26, scenario `rgb(13, 27, 42)` 16.74; dark technical/mailable `rgb(184, 202, 212)` 10.30, scenario `rgb(234, 246, 251)` 15.80. The case asserts at least 4.5.
- **Reduced-motion proof for the affordance:** with `emulateMedia({reducedMotion: "reduce"})`, the new spans report `animation-name: none` and `preview-email-menu-affordance` reports a maximum computed `transition-duration` of `0.01ms` (the global reduce block, `assets/css/app.css:663-669`). After Enter opens the menu the case waits for `details[open]` and then polls the final state: computed `rotate` is `180deg` and `transform` is `none` (`180deg|none`). The rotation is therefore suppressed to a 0.01ms transition and no remedy, no new utility class, and no asset rebuild was needed.
- **Rewritten pins (old assertion -> new assertion):**
  - `preview_live_test.exs` show-page trigger: `trigger_text =~ "HappyMailer"`, `=~ "welcome_default"`, `refute =~ "MailglassAdmin.Fixtures"` -> `assert_trigger_identity/4`: primary `Welcome default`, mailable `HappyMailer`, technical `MailglassAdmin.Fixtures.HappyMailer.welcome_default`, namespace refuted only in the primary and mailable spans, and no ` · ` in the trigger markup.
  - `preview_live_test.exs` after clicking `welcome_enterprise`: substring checks -> `assert_trigger_identity/4` with `Welcome enterprise` / `HappyMailer` / `...HappyMailer.welcome_enterprise`.
  - `preview_live_test.exs` long Unicode compact picker: `text =~ <raw atom>` -> `assert_trigger_identity/4` with the raw double-underscore atom as primary (collision fallback) and the full `Module.atom` technical line; aria-labelledby, no-truncate, whitespace-normal, overflow-wrap and no-title assertions kept.
  - `preview_live_test.exs` Preview index count: `"5 emails"` -> `"6 emails"`.
  - `discovery_test.exs`: scenario key list gains `:welcome_überraschung_東京_with_a_deliberately_long_name` at the end.
  - `structural.spec.js` 390px picker, desktop picker, and Phase 171 narrow case: `identity` substring checks -> scoped `-active-scenario`, `-active-mailable` (namespace refuted there) and `-active-technical` (carries the raw atom). The group-label title assertion and the panel namespace refute are unchanged. The Phase 171 200% zoom case (identity contains the raw atom) still holds through the technical line, so it needed no edit.

## Accomplishments

- `ScenarioLabel` (`@moduledoc false`): `humanize/1` (split on `_`, drop empty segments, capitalize only the first, raw string if nothing remains), `technical/2`, `build/1` with NFC+downcase collision keys and shortest-suffix leaf disambiguation, and total `module_label/2` / `scenario_label/3` lookups. No `String.to_atom`, `Logger`, or `:telemetry`.
- `Sidebar.menu/1`: trigger shows three blocks (`-active-scenario`, `-active-mailable`, `-active-technical`), options show `-option-label` plus `-option-technical`, `mailable_menu_entry/1` takes a `labels` attr (default builds its own), and `menu/1` takes `open` (default false). `scenario_path/6`, the picker (Gallery), and `preview_live.ex` are untouched.
- `HappyMailer` gains a sixth, single-underscore Unicode scenario so the collision fallback is exercised by real fixtures without a new Mailable.
- Three Phase 178 browser cases: duplicate Unicode options at 320 (Enter) and 390 (Space), light/dark identity contrast, and reduced motion.

## Task Commits

1. **Task 1: Readable trigger end to end** - `c03220ca` (feat)
2. **Task 2: Exhaustive label table and shared humanize rule** - `fce51b6b` (feat)
3. **Task 3: Readable options, colliding fixture, open attr, browser proof** - `cc2df76f` (feat)

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` - pure label table
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` - trigger, options, `open` and `labels` attrs, group label from the table
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` - private `humanize/1` delegates to `ScenarioLabel.humanize/1`
- `mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs` - 24 table tests
- `mailglass_admin/test/support/fixtures/mailables.ex`, `discovery_test.exs`, `preview_live_test.exs`, `mailglass_admin.preview.capture_test.exs` - fixture scenario, count pins, behavior tests
- `mailglass_admin/e2e/structural.spec.js` - rewritten pins and three new cases

## Decisions Made

- See `key-decisions` above. Trailer model name follows the session attribution (see Deviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hidden capture-matrix count pin**
- **Found during:** Task 3 full-suite run
- **Issue:** `test/mix/tasks/mailglass_admin.preview.capture_test.exs` asserted `matrix entries: 10` (5 HappyMailer scenarios x 2 widths). The new fixture scenario makes it 12. The plan anticipated an undiscovered count pin ("run the full admin suite once to find any other count pin") but did not list this file.
- **Fix:** Updated the pin to 12 and added an assertion that the new scenario's capture URL is planned.
- **Files modified:** `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs`
- **Verification:** full suite 1159 tests, 0 failures.
- **Committed in:** `cc2df76f`

**2. [Rule 1 - Bug] Plan's rotation assertion names the wrong CSS property**
- **Found during:** Task 3 reduced-motion case
- **Issue:** The plan asks for the computed `transform` to equal the rotated matrix. The bundle applies `group-open:rotate-180` through the individual `rotate` property, so `transform` stays `none` and `rotate` becomes `180deg`.
- **Fix:** The polling expectation reads `rotate|transform` and accepts `180deg|...` or a `matrix(-1,` transform. It still waits for `details[open]` and polls instead of sampling one frame. The `transition-duration` assertion is unchanged.
- **Files modified:** `mailglass_admin/e2e/structural.spec.js`
- **Committed in:** `cc2df76f`

**3. [Rule 3 - Process] TDD red step skipped for the Task 3 behavior tests**
- **Found during:** Task 3
- **Issue:** The markup was written before the tests, so the red run did not happen naturally.
- **Fix:** Measured red afterwards by restoring the task 1 `sidebar.ex` temporarily (5 of 8 new tests fail; the other 3 are regression guards). The copy was restored byte for byte before committing.
- **Files modified:** none (transient)

**4. [Rule 3 - Blocking] Commit trailer model name**
- **Issue:** The plan prescribes `Co-Authored-By: Claude Opus 5.5`; the session attribution names `Claude Sonnet 5.5`, the model that authored the commits.
- **Fix:** Used the session trailer. Explicit-path `git add` / `git commit -- <paths>` discipline was otherwise followed; `gsd-sdk query commit` was not used for code.

**5. [Rule 3 - Blocking] Fewer than six trigger-refute sites in the browser file**
- **Issue:** The plan listed six `structural.spec.js` sites (1518, 1520, 1590, 1651, 1698, 1824) from an older line map. In the current file only three assert the namespace against the trigger identity (390px picker, desktop picker, Phase 171 narrow case); the 200% zoom case asserts the raw atom, which the technical line still satisfies.
- **Fix:** Rewrote the three real sites; no other pin was affected.

---

**Total deviations:** 5 (1 hidden count pin, 1 wrong-property assertion, 3 process/plan-drift). **Impact on plan:** none on scope or behavior; the markup, URLs and bundle are as planned.

## Issues Encountered

- The first full run of the Task 1 browser gate reported `1 flaky`: `Preview: Phase 178 axe cell matches the committed baseline` timed out at 90s on attempt one (Playwright `newPage` closed during `AxeBuilder.analyze`) and passed on retry. It does not touch the selector. Re-running that case alone passed in 3.4s, and a full rerun of the whole gate passed 24/24 with no flaky. Recorded as a one-off cold-start stall, not fixed by a timeout edit.
- The plan's `git add <variable>` commit block word-splits only under bash; under zsh it passed a single path. Re-ran under `bash -c` with an explicit path list before any commit landed.
- The tracked Phase 168/169 artifact directories and `mailglass_admin/priv/static` were clean before and after every Playwright block.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or schema changes. T-178-10 is covered by the hostile-name render test (`<script>` plus U+202E is HEEx-escaped), T-178-11 by the source-scan test, and T-178-12 by the NFC+downcase collision key plus the visible technical identity.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 178-05 can use `Sidebar.menu/1` with `open: true` for its story and the `labels` attr for fixtures.
- Plan 178-11 can mutation-prove rules P3 (technical identity only in `title`) and P4 (raw atom as the only primary of a non-colliding scenario) against the testids pinned here.
- Plan 178-09 should expect the Preview Capture Advisory to plan 12 matrix entries (6 scenarios x 2 widths); RESEARCH Pitfall 4's cold-start flake is unrelated and must not be fixed by a timeout edit.
- No blockers.

## Self-Check: PASSED

- `scenario_label.ex`, `scenario_label_test.exs`, `sidebar.ex`, `structural.spec.js` exist; commits `c03220ca`, `fce51b6b`, `cc2df76f` are ancestors of HEAD.
- Acceptance greps: `{" · "}` 0 in sidebar.ex; `preview-email-menu-active-technical` 1; `defp scenario_path(...)` signature 1 (unchanged); `String.to_atom` 0 in scenario_label.ex; `ScenarioLabel.humanize` 1 in assigns_form.ex; truncating option span 0; `open={@open}` 1; fixture scenario present in mailables.ex.
- `mix format --check-formatted` clean for all touched Elixir files; `check-conformance.sh` printed "OK: design-system conformance clean."; `git status --short mailglass_admin/priv/static` empty.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-10-29*
