# Phase 173 — UI Review

**Audited:** 2026-10-10
**Baseline:** `.planning/phases/173-consistency-and-delivery-evidence/173-UI-SPEC.md` and Mailglass brand references
**Screenshots:** not captured (the supplied preview at `http://127.0.0.1:65125/dev/mail` returned HTTP 200, but all three local Playwright captures failed because sandbox Chromium could not register its Mach port: `bootstrap_check_in … Permission denied`)
**Interaction captures:** off

Phase 173 adds maintainer guidance, evidence tooling, and a narrow Storybook ThemePicker fixture correction. It adds no application screen or product CTA. The visual pillars below therefore describe scope and available evidence, not a claim that an unchanged product screen was freshly validated. The 320px Admin Gallery overflow remains a documented pre-existing limitation and is not attributed to this phase.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Guidance names the preview, review surfaces, and browser/email-client limits; no new user-flow copy was added. |
| 2. Visuals | 3/4 | No screen composition changed; static captures could not be produced in this environment. |
| 3. Color | 3/4 | Guide documents the shipped light/dark semantic mapping; this phase did not change application color styling. |
| 4. Typography | 3/4 | Guide aligns the Admin roles to shipped 14/16/20/28px and 400/700; no rendered typography capture was available. |
| 5. Spacing | 3/4 | Guide states the shipped 4px grid and control sizes; no screen spacing change was in scope. |
| 6. Experience Design | 3/4 | ThemePicker Storybook groups are isolated and browser checks passed at 768px; current interaction capture is off. |

**Overall: 18/24**

Scores of 3 on visual-system pillars reflect the absence of a phase-owned screen change and the lack of fresh screenshots, not observed product defects. The only observed/documented responsive defect is the pre-existing 320px Gallery overflow.

---

## Top 3 Priority Fixes

1. **Complete the exact-candidate delivery proof** — UIQ-03 remains incomplete because exact-SHA `CI Green` is absent and retained evidence was rejected for `candidate_dirty: true` ([173-06-SUMMARY.md:71-78](173-06-SUMMARY.md)); rerun the gate only after those inputs are resolved and keep the record incomplete until then.
2. **Capture the preview in a browser-enabled environment** — screenshots could not be captured here, so visual comparison is unverified; capture desktop, tablet, and mobile from the supplied candidate preview where Chromium can launch.
3. **Track the known 320px Gallery overflow as a responsive follow-up** — Plan 02 verified at 768px and explicitly did not pass 320px ([173-02-SUMMARY.md:87-89, 123-128](173-02-SUMMARY.md)); add a narrow-width geometry check and address the fixed-width logo/card sizing in the owning UI phase.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS, maintainer guidance:** the design guide precisely separates brand/token ownership and describes the Gallery versus curated Storybook purpose ([design-system.md:3-11, 124-149](../../../mailglass_admin/docs/design-system.md)).
- **PASS, claim boundary:** the delivery runbook says synthetic browser preview does not certify Gmail, Outlook, Apple Mail, delivered-email dark mode, or remote image loading ([173-DELIVERY.md:97-101](173-DELIVERY.md)). This matches the spec and Brand Book's plain, exact voice.
- **N/A:** no new end-user CTA, empty state, or error state was introduced; UI-SPEC explicitly says there is no new app CTA ([173-UI-SPEC.md, Copywriting Contract](173-UI-SPEC.md)).
- No generic `Submit`, `Click Here`, `OK`, or `Cancel` copy was added in the audited phase-owned UI-facing changes.

### Pillar 2: Visuals (3/4)

- **N/A, no new screen:** UI-SPEC states there is no new primary screen or focal composition ([173-UI-SPEC.md, Design System](173-UI-SPEC.md)). The phase-owned visual-facing source is the Storybook ThemePicker fixture; its variations cover system/light/dark and disabled cases ([theme_picker.story.exs:20-39](../../../reference/demo_app/storybook/primitives/theme_picker.story.exs)).
- The fixture gives each radio group a distinct name, preventing one rendered example from unchecking another ([173-02-SUMMARY.md:87-89, 109-118](173-02-SUMMARY.md)). This is interaction-state isolation; no composition, icon, or hierarchy redesign occurred.
- **WARNING — evidence gap:** no fresh pixels could be inspected because Chromium failed to launch in the sandbox. Plan 02's prior browser evidence covered the review surfaces at 768px, not 320px ([173-02-SUMMARY.md:95, 123-128](173-02-SUMMARY.md)).

### Pillar 3: Color (3/4)

- **N/A, no application color change:** the guide records Paper/Ink grounds, White/Ink-raised surfaces, Glass/Ice accent, and semantic roles ([design-system.md:36-55](../../../mailglass_admin/docs/design-system.md)); UI-SPEC reserves accent for primary emphasis/focus. The phase did not modify Admin CSS or add new UI color usage (Plan 02 summary, [173-02-SUMMARY.md:82-89](173-02-SUMMARY.md)).
- The actual 60/30/10 rendered distribution cannot be measured without a current screenshot. No claim of a fresh color-composition pass is made.
- **No registry audit required:** UI-SPEC sets `shadcn_initialized: false` and lists no registry entries ([173-UI-SPEC.md front matter and Registry Safety](173-UI-SPEC.md)).

### Pillar 4: Typography (3/4)

- **PASS, guidance:** the Admin guide specifies label/body/heading/display at 14/16/20/28px and only 400/700 weights ([design-system.md:61-73](../../../mailglass_admin/docs/design-system.md)), matching UI-SPEC's Admin mapping. It also keeps the brandbook as identity and voice owner.
- **N/A, no rendered type change:** phase summaries identify documentation/evidence and the Storybook radio-name correction, not a typography change. The supplied UI was not screenshot-verifiable here.

### Pillar 5: Spacing (3/4)

- **PASS, guidance:** the guide lists the 4px spacing grid (4/8/16/24/32/48/64px), control sizes 36/44/52px, and a 44px minimum hit target ([design-system.md:61-69, 109-110](../../../mailglass_admin/docs/design-system.md)), matching UI-SPEC.
- **N/A, no layout change:** phase-owned screen work did not introduce spacing classes or a new layout. Rendered conformance could not be rechecked without screenshots.
- **Existing limitation, not a phase regression:** the Admin Gallery's 320px overflow from its fixed-width logo and expanded card remains deferred; do not count it as passed ([173-02-SUMMARY.md:123-128](173-02-SUMMARY.md)).

### Pillar 6: Experience Design (3/4)

- **PASS, Storybook interaction:** each ThemePicker variation now has an independent radio name ([theme_picker.story.exs:22-37](../../../reference/demo_app/storybook/primitives/theme_picker.story.exs)); the focused Gallery/Storybook browser check passed for route, themes, and served CSS at 768px ([173-02-SUMMARY.md:93-99](173-02-SUMMARY.md)).
- **PASS, evidence boundaries:** the Admin preview manifest rejects incomplete or unsafe actual capture evidence and hashes actual PNG bytes; dry-run output is explicitly identity-only ([173-02-SUMMARY.md:86, 93-94](173-02-SUMMARY.md)). The delivery record truthfully remains incomplete when required proof is absent ([173-06-SUMMARY.md:71-78](173-06-SUMMARY.md)).
- **WARNING — delivery walkthrough remains incomplete:** exact-SHA `CI Green` is missing and the retained checkpoint has `candidate_dirty: true` ([173-06-SUMMARY.md:71-76](173-06-SUMMARY.md)). This blocks a complete delivery claim, though it does not break the preview UI flow.
- Interaction captures were configured off. No hover, focus, or submitted state is claimed from this audit.

---

## Files Audited

- `.planning/phases/173-consistency-and-delivery-evidence/173-01-PLAN.md` and `173-01-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-02-PLAN.md` and `173-02-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-03-PLAN.md` and `173-03-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-04-PLAN.md` and `173-04-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-05-PLAN.md` and `173-05-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-06-PLAN.md` and `173-06-SUMMARY.md`
- `.planning/phases/173-consistency-and-delivery-evidence/173-CONTEXT.md`, `173-UI-SPEC.md`, and `173-DELIVERY.md`
- `mailglass_admin/docs/design-system.md`
- `reference/demo_app/storybook/primitives/theme_picker.story.exs`
- `prompts/mailglass-brand-book.md`
- `brandbook/brand-book.md`
