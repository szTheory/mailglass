# Phase 181 Deferred Items

Out-of-scope discoveries logged during execution. None blocks a Phase 181 requirement.

## 1. Placeholder text is below 4.5:1 (found in plan 181-04)

- **What:** daisyUI draws `::placeholder` as the text colour at 50% over the field. In the compiled bundle that is about 3.1:1 over the light page and 3.2:1 over White under the v2 palette, and 4.5 to 4.7:1 in the dark theme. The one rendered placeholder is the `Subject or recipient` hint in `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` (line 34).
- **Why it is deferred:** the retired v1 palette measured about 3.3:1 for the same rule, so this phase did not make it new, and axe does not evaluate placeholder pseudo-text, so the baseline never counted it. Fixing it means choosing a placeholder colour for every input, which is a visual judgment Phase 182 owns.
- **How it is held:** `contrast_contract_test.exs` carries a reasoned `::placeholder` exemption in `@component_alpha_text`. The entry is checked for staleness, so if the bundle stops mixing that rule the exemption fails and has to be removed.
- **Suggested fix for Phase 182:** an unlayered or utilities-layer `::placeholder` rule that uses the secondary text role (it is paired with the page and cards at 4.5:1 or better), then delete the exemption.

## 2. Demo storybook page still draws an arrow entity (found in plan 181-04)

- **What:** `reference/demo_app/storybook/foundations.story.exs` still contains `class&rarr;data-theme` in the theme-bridge paragraph. The brand fonts have no arrow glyphs.
- **Why it is deferred:** the glyph contract scans admin lib only, no spec pins this text, and the plan scoped the story edits to the colour swatches, type names and the two middle dots. It is advisory demo copy.

## 3. The axe producer can scan a dialog mid fade-in (found in plan 181-04)

- **What:** `mailglass_admin/e2e/axe-baseline.spec.js` runs axe immediately after `expect(modal).toBeVisible()`. While the replay dialog is still fading in, its text is partly transparent, so axe reports transient `color-contrast` nodes (ratios 1.1 to 3.9 on the dialog title and the identity `dt` labels) in the deliveries and inbound cells. A 12-run probe of the inbound cell (system, dark and light, four runs each) measured the same page immediately and after `document.getAnimations()` settled: the immediate scan reported 3 to 6 nodes in 6 of 12 runs and the settled scan reported 0 in all 12. One producer run during plan 181-04 persisted nothing because of it (`inbound / system` showed `color-contrast: 5`).
- **Why it is deferred:** plan 181-04 and RESEARCH Open Question 1 say not to change the producer's scan in this phase, and the settled state is clean. The persisted baseline came from a run whose cells show no `color-contrast`; the discarded runs are recorded in the plan summary.
- **Suggested fix:** in `scanSurface`, wait for `await page.evaluate(() => Promise.all(document.getAnimations().map(a => a.finished.catch(() => null))))` before `analyze()`, so the producer measures the settled page every time. This does not change scan scope.
