# Phase 183 — UI Review

**Audited:** 2026-11-17
**Baseline:** `183-UI-SPEC.md` (frontmatter says draft; the document's sign-off says approved with one non-blocking inventory provenance flag)
**Screenshots:** not captured (no positively identified Phase 183 server; localhost:8080 belongs to the owner-demo Docker services and was not contacted)
**Interaction captures:** off (workflow.ui_interaction_capture is false)
**Evidence update (2026-11-17):** The current Admin suite run found one `FaviconCatalogTest` producer-SHA mismatch in `favicon-299c1aa-20261116T231912Z`. Earlier catalog and browser results cited below are historical; this refresh did not retry the alias, recapture favicon evidence, or run a browser.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | README names and tagline meet the contract, but package docs retain broken cross-package links and unresolved internal API references. |
| 2. Visuals | 3/4 | Pinned lockups and final theme/narrow-layout browser checks pass; no audit screenshots were captured. |
| 3. Color | 3/4 | Accent use is scoped to pinned artwork and syntax tokens; rendered ExDoc contrast was not captured. |
| 4. Typography | 2/4 | The UI contract, pinned tokens, and published design guide specify conflicting type scales. |
| 5. Spacing | 2/4 | The contract, pinned spacing tokens, root sidecar, and Admin scale disagree on the available steps. |
| 6. Experience Design | 3/4 | Static asset failures and the native theme-switch behavior are verified; package documentation links still lose readers. |

**Overall: 16/24**

No BLOCKER findings. All findings are WARNINGs: they reduce documentation quality or leave an acceptance behavior unverified, but the evidence does not show a broken primary application flow.

---

## Top 3 Priority Fixes

1. **Reconcile the type and spacing authorities** — maintainers cannot apply a stable contract when `UI-SPEC.md`, `brandbook/tokens.json`, `DESIGN.md`, and the Admin guide give different scales; update the contract to the pinned authorities, then align the design docs and sidecar.
2. **Resolve generated-doc link warnings** — readers of Inbound docs cannot follow the compatibility links as shipped, and Admin API pages reference hidden functions; use package-local pages or checked absolute links, and render hidden internals as code unless they are intended public targets.
3. **Add a rendered syntax-color contrast assertion** — CSS scope and token values match the contract, but the browser contract does not assert contrast after ExDoc's native code-block styles are applied; verify both light and dark token/background pairs in the generated output contract.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**WARNING —** The README header copy follows the contract across all three packages: one lowercase `mailglass` H1, lowercase image alt text, and the separate exact tagline (`README.md:1-8`, `mailglass_admin/README.md:1-8`, `mailglass_inbound/README.md:1-8`). The generated docs still have content-navigation gaps recorded by the final docs summary: Inbound links outside its package to `guides/compatibility-and-deprecations.md` (`mailglass_inbound/README.md:202-213`, `mailglass_inbound/docs/inbound-install.md:272-278`), and the Admin API guide names hidden methods that ExDoc cannot link (`mailglass_admin/docs/api_stability.md:146-156`). Ship an in-package compatibility page or use a verified core-docs URL; use plain code formatting for internal method names that should not link.

### Pillar 2: Visuals (3/4)

**WARNING —** The three README headers use the exact immutable light/dark SVG URLs and constrain a 580px source width with `max-width:100%;height:auto` (`README.md:3-8`; same markup in both sibling READMEs). The ExDoc setup copies theme marks and adds a class-following hook (`mix.exs:495-503`, `mailglass_admin/mix.exs:247-255`, `mailglass_inbound/mix.exs:174-182`). The original phase validation records the all-package theme/layout browser contract passing in the matching Docker image (`183-VALIDATION.md:126,139`; the corrected final gate is summarized in `183-03-SUMMARY.md:220-230`); this remains historical evidence, not a current rerun. Those checks cover both themes, image decode, and the 375px ratio/overflow assertions. The current refresh found the separate FaviconCatalogTest producer-SHA mismatch and captured no audit screenshots, so current layout and renderer chrome remain unobserved.

### Pillar 3: Color (3/4)

**WARNING —** Source-level color use is appropriately narrow: the ExDoc stylesheet changes only Makeup syntax-token text colors, with light `#0a6488` and dark `#46b6e8` under ExDoc's `.dark` class (`brandbook/exdoc/code-colors.css:1-22`). These values correspond to the declared syntax-only accent use; the 108-cell favicon catalog and independent legibility check were reported as passing in the original phase evidence (`183-02-SUMMARY.md:134-148`). The current source-hash mismatch means that catalog result is not revalidated by this refresh. No current docs-page screenshot was available to confirm the final stylesheet cascade and token contrast against both native code-block backgrounds.

### Pillar 4: Typography (2/4)

**WARNING —** The contract calls for four sizes—body 16px, code 13px, heading 28px, display 56px—and two weights (`183-UI-SPEC.md:42-53`). The published root design metadata instead specifies display 36px, body 16px, mono 14px, with no separate heading/code roles (`DESIGN.md:15-27`). The Admin guide describes 14/16/20/28px (`mailglass_admin/docs/design-system.md:85-98`), while the pinned token file declares display 44, h1 36, h2 30, h3 24, body 16, small 14, and code 14 (`brandbook/tokens.json:291-299`). ExDoc correctly keeps Lato and receives no general font override, but the authoring guidance is not a single usable scale. Resolve the UI-spec/source discrepancy before regenerating `DESIGN.md` and its sidecar.

### Pillar 5: Spacing (2/4)

**WARNING —** The UI contract names 4/8/16/24/32/48/64px (`183-UI-SPEC.md:36-40`) and the Admin guide and CSS use that grid (`mailglass_admin/docs/design-system.md:85-89`, `mailglass_admin/assets/css/app.css:116-121`). The root `DESIGN.md` sidecar instead names `xl: 40px` (`DESIGN.md:33-39`), matching the pinned global token (`brandbook/tokens.json:301-308`) but not the contract's Admin scale. The current documents do not say clearly which scale applies to brand-authored guidance versus the Admin UI. Define that boundary and make the design docs name the same scale for the same surface. No README or ExDoc layout CSS was added, consistent with the renderer-owned spacing rule.

### Pillar 6: Experience Design (3/4)

**WARNING —** This phase adds static docs and brand assets, not dashboard controls; the spec therefore correctly has no CTA, empty data, destructive action, or loading UI. Missing or mismatched assets fail the docs verifier, README images retain `alt="mailglass"`, and no custom loader was added (`scripts/brand_docs_check.exs:21-43,48-75`; `README.md:3-5`). The ExDoc hook follows the native body `.dark` class through a `MutationObserver` and avoids OS preference or network access (`brandbook/exdoc/theme-mark.js:1-18`). The original phase browser contract reported native theme selection, mark decode, opposite OS-scheme cases, and 375px width passing in the matching Docker image (`183-VALIDATION.md:126,139`); it remains historical evidence. Cross-package compatibility links remain a documentation navigation gap under Pillar 1; no dashboard interaction was added by this phase.

## Files Audited

- `.planning/phases/183-docs-packaging-and-launch-prep/183-UI-SPEC.md`
- `.planning/phases/183-docs-packaging-and-launch-prep/183-01-PLAN.md`, `183-02-PLAN.md`, `183-03-PLAN.md`
- `.planning/phases/183-docs-packaging-and-launch-prep/183-01-SUMMARY.md`, `183-02-SUMMARY.md`, `183-03-SUMMARY.md`
- `README.md`, `mailglass_admin/README.md`, `mailglass_inbound/README.md`
- `DESIGN.md`, `.impeccable/design.json`, `mailglass_admin/docs/design-system.md`
- `brandbook/tokens.json`, `brandbook/exdoc/code-colors.css`, `brandbook/exdoc/theme-mark.js`
- `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`
- `mailglass_admin/e2e/docs-theme-contract.cjs`, `scripts/brand_docs_check.exs`, `ci/contracts/brand_docs_output_test.exs`
- `mailglass_inbound/docs/inbound-install.md`, `mailglass_admin/docs/api_stability.md`
- ExDoc `sidebar_template.eex`; one existing Chromium light-theme 32px favicon catalog image

The local capture directory already ignored image outputs before this audit; the gitignore gate was checked before considering screenshots. `components.json` is absent and the UI spec states that no shadcn or third-party registry is used, so registry inspection was skipped. No tests or browser commands were run during this audit.
