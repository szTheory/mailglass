# Phase 178 — UI Review

**Audited:** 2026-11-02  
**Baseline:** Abstract six-pillar standards; Phase 178 has no UI-SPEC. Treat the current palette as interim ahead of the planned Mailglass brand refresh.  
**Screenshots:** Not captured: the desktop (1440×900), mobile (375×812), and tablet (768×1024) Playwright captures all failed against the already-running localhost:8080. I inspected the retained 375px Cycle 04 Preview image at reference/demo_app/tmp/phase178_candidate/recovery-cycle-04/41386942453-attempt-1/demo-browser-evidence/phase174/warm/retained/preview-current.png; the relevant Preview component and CSS files match the current tree.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The compact selector is readable, but the Preview directory still exposes raw, truncated scenario atoms. |
| 2. Visuals | 3/4 | The detail view has a clear hierarchy; mobile technical identity breaks mid-token and the directory view truncates labels. |
| 3. Color | 4/4 | Components use semantic theme tokens with four primary accents and no hard-coded color literals. |
| 4. Typography | 4/4 | Three semantic text sizes and two weights provide a restrained hierarchy; monospace is reserved for technical values. |
| 5. Spacing | 3/4 | Spacing stays on the 4px grid, but named and numeric utility styles are mixed in the same component. |
| 6. Experience Design | 2/4 | Loading, validation, render-error, and empty states exist, but same-named scenarios lack Mailable context in link names for assistive technology. |

**Overall: 19/24**

---

## Top 3 Priority Fixes

1. **WARNING — Include Mailable context in scenario links’ accessible names.** When different Mailables expose the same scenario atom, a screen-reader links list can show indistinguishable options. Associate each option list with its Mailable label or include that label in each link’s accessible name.
2. **WARNING — Make the Preview directory picker readable.** Its list variant still renders raw atoms with truncation. Reuse the label logic from the compact selector and preserve the distinguishing text at narrow widths.
3. **WARNING — Keep disambiguating Mailable labels visible without hover.** The compact selector truncates group labels and relies on a title tooltip for the full name. Wrap the distinguishing suffix or otherwise expose the full label on touch and keyboard layouts.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**WARNING — The two Preview selection surfaces use different label quality.** The compact selector humanizes scenario names and shows Mailable and technical identity in sidebar.ex:128-160. The directory picker still renders Atom.to_string(scenario_name) as a truncated link in sidebar.ex:353-371. This leaves code-like labels such as welcome_enterprise in the Preview directory and can hide the part that distinguishes long names. Apply the shared scenario label rules to the directory variant, with wrapping or a visible disambiguator.

The changed form copy is direct: “Restore defaults” and the single read-only explanation identify the action and why a value cannot be edited (assigns_form.ex:35-37, 70-90). The no-editable state also gives a next step (assigns_form.ex:78-81). No generic “Submit” or “Save” copy was found in these components.

### Pillar 2: Visuals (3/4)

**WARNING — The overview picker and compact group headings can hide distinguishing text.** sidebar.ex:366-371 applies truncate to each directory scenario link and displays the raw atom. Long or similarly prefixed names lose their distinguishing suffix in that view. In the compact menu, sidebar.ex:325-331 also truncates the Mailable group label and relies on a title tooltip for the full identity. Wrap the disambiguating text or otherwise keep it visible on touch and keyboard layouts.

The compact menu provides a clear hierarchy: humanized scenario, Mailable, then smaller monospace identity (sidebar.ex:128-160). In the retained 375px capture, however, overflow-wrap:anywhere breaks the technical identity inside “AccountMailer” (“AccountMai” / “ler.invite_admin”). The text remains present, but is harder to scan. Prefer breaks at identifier separators where practical while retaining the narrow-screen no-overflow behavior.

The current audit did not produce fresh viewport captures, so the visual score is based on source analysis and the retained mobile image; desktop and tablet appearance remain unobserved in this review.

### Pillar 3: Color (4/4)

No color defect found in the audited Preview components. Their 36 semantic color-class occurrences use base, primary, secondary, or error roles; primary appears four times for active selection, the selected check, the Preview heading, and a subtle selected background. There are no hard-coded color literals in assigns_form.ex or sidebar.ex. The source theme maps these roles to the shared light and dark tokens (assets/css/app.css:28-49, 66-87).

The retained Phase 178 summary records measured light and dark contrast above 4.5:1 for the compact selector’s secondary identity and primary scenario text (178-04-SUMMARY.md:137). The exact page-wide 60/30/10 distribution was not measured from a current full-page capture.

### Pillar 4: Typography (4/4)

No typography defect found in the audited component code. It uses three semantic sizes—text-label, text-body, and text-heading—and two weights, font-normal and font-bold; the full technical identity uses font-mono (assigns_form.ex:259-262, 278-291; sidebar.ex:113-160). The source design scale defines normal and bold weights as 400 and 700 (assets/css/app.css:103-120). The retained Phase 178 StatCard receipt also compares production font roles against Storybook in light and dark themes (178-07-SUMMARY.md:106-108).

### Pillar 5: Spacing (3/4)

**WARNING — The component mixes named and numeric spacing utilities.** The new compact menu uses tokens such as gap-sm, px-sm, and p-md, while the directory variant in the same module uses gap-2, px-3, py-2, and space-y-1 (sidebar.ex:51-63, 126, 177, 221-249, 348-368). These remain on the 4px grid, and no arbitrary px/rem spacing value was found. Consolidate equivalent values on one vocabulary to make later layout tuning more predictable. The max-h-[70vh] dropdown cap is a viewport constraint, not an arbitrary spacing value.

### Pillar 6: Experience Design (2/4)

**WARNING — Mailable grouping is visual, not part of each scenario link’s accessible name.** The menu renders the module label separately from a nested list (sidebar.ex:217-260, 323-331). Each scenario link’s name comes from its primary label and raw atom; it does not include the Mailable. If two Mailables expose the same scenario name, assistive-technology users reviewing links outside the surrounding list context may not be able to tell them apart. Associate the nested list with its visible group label or include the Mailable in each option’s accessible name.

Positive state coverage is substantial: pending updates and stale output are announced through status regions, validation errors are described and summarized, render failures have recovery guidance, and the no-mailables state explains how to create a Mailable (preview_live.ex:365-408, 432-465, 467-486, 570-589; assigns_form.ex:107-120, 270-273). Historical Phase 178 browser coverage includes responsive selector checks, keyboard selection, reduced-motion behavior, focus geometry, and real 200% zoom (structural.spec.js:1955-2075, 2610-2735; phase178-real-zoom.spec.js:75-277). Those tests were not rerun for this audit.

---

## Files Audited

- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
- mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
- mailglass_admin/lib/mailglass_admin/preview_live.ex
- mailglass_admin/assets/css/app.css
- mailglass_admin/e2e/structural.spec.js
- mailglass_admin/e2e/phase178-real-zoom.spec.js
- reference/demo_app/storybook/preview_authoring.story.exs
- reference/demo_app/assets/e2e/phase178-stories.spec.js
- Phase 178 PLAN/SUMMARY artifacts 178-01 through 178-38 where present; plans 178-18 and 178-19 are superseded and have no matching summaries.

