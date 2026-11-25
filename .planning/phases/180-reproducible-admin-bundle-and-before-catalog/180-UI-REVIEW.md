# Phase 180 — UI Review

**Audited:** 2026-11-17  
**Baseline:** No Phase 180 UI-SPEC exists. Audited against the applicable Preview and shared-shell contracts in `171-UI-SPEC.md` and `177-UI-SPEC.md`, the admin design-system spacing/type/color rules, and the abstract six-pillar standards.  
**Source scope:** Read-only source audit. The workspace contains later uncommitted UI changes; Phase 180 findings are identified separately from those current worktree edits.  
**Screenshots:** Not captured. The preserved favicon source-hash stop prohibits browser/server activity. The committed before-catalog is historical: it records source `9eb9dee`, has a `superseded.json`, and does not represent the current worktree. I sampled existing catalog images read-only; they are not current visual evidence.  
**Interaction captures:** off (`interaction_capture=false`; no live interaction checks under the preserved stop).

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Preview empty states and browser-rendering limits are explicit and task-specific. |
| 2. Visuals | 3/4 | The fixed 768px preview frame can extend beyond a 375px pane; overflow is scrollable but has no visible cue. |
| 3. Color | 3/4 | Theme ownership and semantic tokens are consistent, but several Preview guidance elements use the reserved primary accent. |
| 4. Typography | 4/4 | The audited surfaces use semantic type roles, mono for technical values, and the approved weights. |
| 5. Spacing | 3/4 | Preview tabs and output panels use raw Tailwind spacing utilities where the contract calls for named tokens. |
| 6. Experience Design | 3/4 | Theme and output contracts hold in source and tests; current live interactions were not observed. |

**Overall: 20/24**

---

## Top 3 Priority Fixes

1. **Keep Preview guidance colors within the accent contract** — informational icons and inline setup code compete with active/focus cues — use neutral/semantic info styling for the guidance elements in `preview_live.ex` and reserve `primary` for the active tab and focus emphasis.
2. **Use the named spacing scale in Preview tabs** — raw values make spacing harder to keep consistent — replace `space-y-4`, `px-4`, `py-2`, and the two `p-4` utilities in `preview/tabs.ex` with their named-token equivalents.
3. **Complete current visual verification after the existing stop clears** — source review cannot establish rendered clipping, typography, or color balance at target widths — capture and review the current page only when the favicon source-hash stop is resolved.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- **PASS:** The HTML and plain-text empty messages say exactly what is absent (`preview/tabs.ex:102-105,130-132`), and the Preview background help text limits its claim to browser framing rather than email-client compatibility (`preview_live.ex:530-534`).
- **PASS:** Render failures preserve the correction path and distinguish stale output from current output (`preview_live.ex:458-460,473-478`). The Preview controls use specific labels rather than generic “Submit” or “OK” copy.

### Pillar 2: Visuals (3/4)

- **WARNING — source-derived responsive framing:** The Preview iframe is rendered at the selected fixed width inside an `overflow-auto` wrapper (`preview/tabs.ex:101-115`); Preview defaults to 768px (`preview_live.ex:75,737`). On a 375px viewport, this can show only part of the frame until the user scrolls horizontally or selects 375px. A read-only historical 375px catalog image shows this state, but it is tied to superseded source and is not proof of the current rendering. Add a visible scroll cue or choose a width that fits the available pane on narrow screens.
- **PASS:** The shell has a clear hierarchy: global brand/theme controls, account navigation, then one main content region (`admin_shell.ex:30-83`). Current visual quality cannot be confirmed without a permitted current capture.

### Pillar 3: Color (3/4)

- **PASS:** The root layout is the sole theme owner (`layouts/root.html.heex:1-2`). The audited HEEx contains no hard-coded hex or `rgb()` values; the Preview backdrop uses the system `Canvas` color and token-backed borders (`preview/tabs.ex:107-118`). Phase 180’s historical browser evidence measured the backdrop as light white and dark `rgb(18,18,18)` under both admin themes (`180-03-SUMMARY.md:125`). This is historical evidence only.
- **WARNING:** The applicable Preview color contract reserves the accent for the selected output tab, a real primary action, and focus. The Preview empty-state guidance still uses `text-primary` on the command and decorative icons (`preview_live.ex:583,594,605`); keep these neutral or use the semantic info role. The retained account-control accents in `operator/shell.ex` are explicitly allowed by the shared-shell contract.

### Pillar 4: Typography (4/4)

- **PASS:** Page and component hierarchy uses the semantic `text-label`, `text-body`, `text-heading`, and `text-display` roles; technical output uses mono (`preview_live.ex:356-357`, `preview/tabs.ex:133-147`). The sampled source uses the approved normal/bold weights and does not introduce a new type scale.
- **Historical visual evidence:** Existing catalog captures show distinct page headings, section labels, and body copy, but they are from the superseded `9eb9dee` source and do not establish current font rendering.

### Pillar 5: Spacing (3/4)

- **WARNING:** The Preview tab strip and panels use `space-y-4`, `px-4`, `py-2`, and two `p-4` values (`preview/tabs.ex:33,53,71,135,147`) instead of the named 4px-grid utilities specified by the project. These map to on-grid values, so the issue is token consistency rather than an observed off-grid gap. Use `space-y-md`, `px-md`, `py-sm`, and `p-md` equivalents.
- **PASS:** The shared shell and frame wrapper otherwise use named spacing utilities (`admin_shell.ex:36,57,71,76`; `preview/tabs.ex:100,109`).

### Pillar 6: Experience Design (3/4)

- **PASS:** Theme state is represented at `<html>`; system mode can leave the attribute absent. Preview separates admin theme, frame color-scheme, and CSS-pixel width, and the iframe remains script-disabled (`layouts/root.html.heex:2`; `preview/tabs.ex:110-118`). The tab panel is keyboard-focusable and the tab strip has one active tab stop (`preview/tabs.ex:42-71`).
- **Resolved historical issue:** Phase 180’s before-catalog recorded 39 duplicate IDs after collapsing theme columns (`180-02-SUMMARY.md:45,127`; `deferred-items.md:33-41`). The current source propagates an `id_prefix` and its contract asserts zero duplicates. The current Admin lane ran 1,824 tests with one failure only: the separate `FaviconCatalogTest` producer-SHA mismatch; the gallery ID contract passed. No current browser interaction was observed.
- **Evidence limitation:** The Phase 180 browser summary recorded 353 passes, one unrelated Preview axe-cell timeout, and one skip (`180-03-SUMMARY.md:86,148-149`). No current browser or interaction evidence was collected.

---

## Files Audited

- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/lib/mailglass_admin/preview_live.ex`
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` (read only)
- `mailglass_admin/docs/design-system.md`
- `.planning/milestones/v2.9-phases/171-developer-preview/171-UI-SPEC.md`
- `.planning/milestones/v2.10-phases/177-readable-health-and-coherent-account-navigation/177-UI-SPEC.md`
- Phase 180 summaries, deferred-items ledger, and historical before-catalog manifest/sample PNGs
