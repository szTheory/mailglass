# Phase 80: Brand Audit and Gap Register - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 1 implementation target
**Analogs found:** 1 / 1 target, with 5 supporting analog families

## File Extraction

Phase 80 has one source artifact to modify:

- `brandbook/brand-audit.md`

This conclusion comes from the locked phase boundary and downstream validation:

- `80-CONTEXT.md:13-15` says Phase 80 does not finalize brandbook source assets, logo sets, README/Hex/HexDocs presentation, product UI code, public APIs, package code, or release workflows.
- `80-RESEARCH.md:157-159` recommends one Markdown artifact at `brandbook/brand-audit.md` with executive judgment, stress test matrix, row-addressable gap register, handoff map, validation expectations, and final quality gate.
- `80-VALIDATION.md:41-45` maps every automated Phase 80 check to `brandbook/brand-audit.md` or to read-only parse/diff checks proving other artifacts were not changed.

Read-only references for the audit:

- Brandbook source inputs: `brandbook/brand-book.md`, `brandbook/README.md`, `brandbook/index.html`, `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/assets/*.svg`, `brandbook/examples/*.svg`.
- Admin/product constraint: `mailglass_admin/docs/design-system.md`.
- Public/package constraint: `README.md`, `mix.exs`, `mailglass_admin/mix.exs`.
- Planning constraints: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`, `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/brand-audit.md` | documentation / audit register | file-I/O Markdown transform; evidence-to-handoff register | `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` plus existing `brandbook/brand-audit.md` | exact for register shape; exact for target structure |

## Read-Only Classification

| Reference File | Role | Data Flow | Use In Phase 80 | Warning |
|----------------|------|-----------|-----------------|---------|
| `brandbook/brand-book.md` | source brand guidance | read-only evidence | Preserve concept, voice, visual and artifact rules | Do not revise source brandbook in Phase 80; Phase 81 owns it |
| `brandbook/README.md` | directory operating guide | read-only evidence | Source-native artifact policy and admin design-system constraint | Do not change export policy here |
| `brandbook/index.html` | static brandbook preview | read-only evidence | Direct-open HTML, token usage, surfaces, artifact policy | Do not edit HTML/CSS layout; Phase 81 owns source brandbook refinements |
| `brandbook/tokens.json` | token source | read-only evidence | Role token groups and borderline contrast evidence | Do not finalize token values; Phase 81/84 own token edits/checks |
| `brandbook/tokens.css` | direct-open token CSS | read-only evidence | CSS variables, dark mode, focus, reduced motion | Do not edit CSS in Phase 80 |
| `brandbook/assets/*.svg` | logo draft assets | read-only evidence | Logo draft direction, SVG metadata, duplicate ID risk | Treat as one draft direction; Phase 82 owns logo decisions |
| `brandbook/examples/*.svg` | surface specimens | read-only evidence | README/docs/UI state stress-test evidence | Do not replace examples; Phase 83 owns copy/specimens |
| `mailglass_admin/docs/design-system.md` | implemented admin UI constraint | read-only constraint | Token, conformance, motion, accessibility, audit-loop rules | Brandbook must not become a second admin UI framework |
| `mix.exs`, `mailglass_admin/mix.exs` | package/docs config | read-only constraint | Package file allowlists exclude broad `brandbook/` inclusion | Do not change package allowlists in Phase 80 |

## Pattern Assignments

### `brandbook/brand-audit.md` (documentation / audit register, file-I/O Markdown transform)

**Primary analog:** `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`

Copy the stable-register contract and no-source-edit warning:

```markdown
---
artifact: gap-register
stable_ids: true
---

> Stable `GAP-NN` row IDs are the anti-churn citation gate for Phases 75-78.
> **Zero production code was changed to produce this register. All cited files are read-only.**
```

Source lines: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:1-13`.

Copy the row schema pattern, but adapt fields to Phase 80:

```markdown
| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID - never renumber once assigned |
| `surface` | Deliveries / Inbound / Preview / Operator Overview / All |
| `component:line` | Path relative to `mailglass_admin/lib/` (or `docs/`) and line number |
| `pillar` | One of the six conformance pillars below |
| `sev` | 1-5 per severity rubric below |
| `evidence PNG` | `tmp/ui-audit/{surface}-{viewport}-{theme}.png` |
| `fix sketch` | Concise implementation direction referencing the frozen UI-SPEC taxonomy |
```

Source lines: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:25-35`.

Phase 80 adaptation:

```markdown
| BRAND-GAP-NN | Classification | Severity | Surface | Evidence | Rationale | Target Phase | Acceptance / Closeout Cue |
|--------------|----------------|----------|---------|----------|-----------|--------------|---------------------------|
```

Severity should preserve the closeout pressure:

```markdown
| Sev | Meaning | Phase 79 effect |
|-----|---------|----------------|
| 5 | Blocks correct usage or accessibility | **Blocks Phase 79 closeout** |
| 4 | Visible quality regression | **Blocks Phase 79 closeout** |
| 3 | Meaningful inconsistency | Does not block closeout on its own |
```

Source lines: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:52-63`.

Use Phase 74's concrete row style: each row has a stable ID, concrete surface, file/line evidence, severity, and a terse fix/handoff sketch. Source lines: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:111-123`.

Copy the "summary by phase target" pattern after the register:

```markdown
| Phase | Build Requirement | Citing Rows | Min Sev |
|-------|------------------|-------------|---------|
```

Source lines: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:189-203`.

### Closeout / Frozen-Artifact Pattern

**Analog:** `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`

Use this as the model for future Phase 84 closure, and to explain why Phase 80 rows must be stable:

```markdown
The frozen `74-GAP-REGISTER.md` was NOT modified; this file is the write target per the frozen-artifact + separate-closeout precedent.
```

Source lines: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md:9-12`.

Closure rows aggregate original row, resolving phase, evidence path, and disposition:

```markdown
| GAP-NN | Surface | Description | Sev | Resolving Phase | Resolving Commit(s) | Evidence Path | Phase-79 Disposition |
|--------|---------|-------------|-----|----------------|---------------------|---------------|----------------------|
```

Source lines: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md:25-35`.

Carry forward the zero-open-severity threshold:

```markdown
**Zero open severity-4 or severity-5 rows. Phase 79 closeout criterion met.**
```

Source lines: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md:141-157`.

Phase 80 should not create the closeout file now. It should make `BRAND-GAP-NN` rows closeout-ready so Phase 84 can record closure or deferral without rewriting the audit.

### Existing Draft Audit Structure

**Analog:** `brandbook/brand-audit.md`

Keep the broad structure but harden it into a traceable register. Existing sections already cover:

- Executive judgment: `brandbook/brand-audit.md:12-35`.
- Brand DNA: `brandbook/brand-audit.md:36-62`.
- Scorecard: `brandbook/brand-audit.md:63-81`.
- Stress tests: `brandbook/brand-audit.md:83-112`.
- Gaps and risks: `brandbook/brand-audit.md:114-134`.
- Artifact plan: `brandbook/brand-audit.md:322-348`.
- Prioritized action plan and final gate: `brandbook/brand-audit.md:349-387`.

The risky pattern is completion language that must be rewritten. Current examples:

```markdown
Implemented in:

- `tokens.json`
- `tokens.css`
```

Source lines: `brandbook/brand-audit.md:174-180`.

```markdown
- Could an engineer implement from this? Yes: tokens JSON/CSS and SVG assets are committed.
- Could it survive dark mode, small sizes, docs pages, and social previews? Yes, with the provided token and mark variants.
```

Source lines: `brandbook/brand-audit.md:378-387`.

Phase 80 should recast these as draft-input evidence and downstream handoffs, not approved v1.8 completion.

### Source-Native Brandbook Constraint Pattern

**Analog:** `brandbook/README.md`

Use the operating rules and export policy as the audit's repo-hygiene baseline:

```markdown
- Keep the brand self-contained in this directory unless product code needs a
  specific token or asset.
- Do not commit font binaries, large raster exports, Figma files, screenshots,
  or generated PNG batches by default.
- Prefer SVG, Markdown, JSON, CSS, and plain HTML.
```

Source lines: `brandbook/README.md:20-32`.

```markdown
Commit:

- SVG logos and specimens.
- JSON/CSS tokens.
- Markdown and HTML guidance.
```

Source lines: `brandbook/README.md:34-53`.

**Analog:** `brandbook/index.html`

Use these as evidence that direct-open, source-native HTML already exists:

```html
<link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="tokens.css">
```

Source lines: `brandbook/index.html:1-9`.

Use the HTML artifact-policy table as evidence, not as an edit target:

```html
<td>Markdown, HTML, SVG, JSON, CSS</td>
<td>PNG exports, screenshots, contrast reports</td>
<td>Font binaries, PDFs, Figma files, raster packs</td>
```

Source lines: `brandbook/index.html:465-476`.

### Admin Design-System Constraint Pattern

**Analog:** `mailglass_admin/docs/design-system.md`

The audit must explicitly state that this file governs implemented product UI:

```markdown
> **One rule above all:** there is a single source of truth for every visual
> decision. Color lives in the daisyUI theme blocks; size / type / elevation /
> motion live in the `@theme` block and `:root` tokens. Components compose those
> tokens - they never hardcode hex, pixels, or durations.
```

Source lines: `mailglass_admin/docs/design-system.md:8-12`.

Token and accent constraints to cite:

```markdown
The **only** place light and dark diverge. Brand palette mapped to daisyUI
semantic tokens. Use the semantic names, never raw Tailwind palette
(`text-gray-500`) and never hex in HEEx.
```

Source lines: `mailglass_admin/docs/design-system.md:31-54`.

Conformance checklist to cite for admin UI surface stress:

```markdown
- **Color:** semantic tokens + opacity tints only; no hex, no raw palette;
  accent obeys the 10% rule.
- **A11y:** selected state via `aria-current`/`aria-selected` (not color alone);
  semantic list/table markup; visible focus ring; `role="dialog"`/`aria-modal`
  on modals.
```

Source lines: `mailglass_admin/docs/design-system.md:104-121`.

Known limitation / deferred seam pattern:

```markdown
**GAP-22 disposition (Phase 75 / IA-04):** ... tracked as GAP-22 and deferred to Phase 79 (VERIF-04).
```

Source lines: `mailglass_admin/docs/design-system.md:160-178`.

### Token, SVG, and Specimen Evidence Patterns

**Analog:** `brandbook/tokens.json` and `brandbook/tokens.css`

Use token groups as evidence for Phase 80 rows; do not edit values:

```json
"notes": "Source-control-friendly tokens for brand, docs, marketing, and lightweight UI examples. Product admin UI may map these into its own Tailwind/daisyUI layer."
```

Source lines: `brandbook/tokens.json:3-8`.

```json
"color": {
  "light": { "background": { "value": "{palette.paper.value}" } },
  "dark": { "background": { "value": "{palette.ink.value}" } },
  "state": { "success": { "value": "{palette.pine.value}" } },
  "callout": { "infoBackground": { "value": "#EAF6FB" } },
  "code": { "background": { "value": "#0A1521" } }
}
```

Source lines: `brandbook/tokens.json:25-95`.

```css
[data-theme="dark"] {
  color-scheme: dark;
  --mg-bg: var(--mg-ink);
  --mg-surface: #152538;
  --mg-focus-ring: var(--mg-ice);
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --mg-duration-instant: 1ms;
  }
}
```

Source lines: `brandbook/tokens.css:106-141`.

**Analog:** `brandbook/assets/logo-primary.svg` and `brandbook/assets/favicon.svg`

Use SVG metadata and duplicate-ID risk as evidence:

```xml
<svg ... role="img" aria-labelledby="title desc">
  <title id="title">Mailglass primary logo</title>
  <desc id="desc">Mailglass wordmark with a pane mark that implies visible email.</desc>
```

Source lines: `brandbook/assets/logo-primary.svg:1-3`.

```xml
<svg ... role="img" aria-labelledby="title desc">
  <title id="title">Mailglass favicon</title>
  <desc id="desc">Compact pane mark for Mailglass.</desc>
```

Source lines: `brandbook/assets/favicon.svg:1-3`.

This is valid for standalone SVGs, but repeated `id="title"` / `id="desc"` is a register-worthy inline-use risk.

**Analog:** `brandbook/examples/readme-header.svg`

Use the generic Phoenix command as concrete evidence for a Phase 83 handoff row:

```xml
<text x="24" y="44" fill="#A6EAF2">mix archive.install hex phx_new</text>
```

Source lines: `brandbook/examples/readme-header.svg:16-19`.

**Analog:** `brandbook/examples/ui-primitives.svg`

Use state examples as evidence for non-color indicator review:

```xml
<circle cx="34" cy="34" r="7" fill="#166534"/>
<text x="58" y="29" fill="#0D1B2A" font-size="16" font-weight="700">Delivered</text>
...
<circle cx="34" cy="34" r="7" fill="#A95F10"/>
<text x="58" y="29" fill="#0D1B2A" font-size="16" font-weight="700">Suppressed</text>
```

Source lines: `brandbook/examples/ui-primitives.svg:34-50`.

## Shared Patterns

### Required Surface Coverage

**Source:** `.planning/REQUIREMENTS.md`
**Apply to:** `brandbook/brand-audit.md`

The audit must pressure-test every named BRAND-02 surface:

```markdown
GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page,
social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states.
```

Source lines: `.planning/REQUIREMENTS.md:17-25`.

Recommended matrix columns:

```markdown
| Surface | Current Evidence | Brand Risk | Classification | Target Phase | Closeout Cue |
|---------|------------------|------------|----------------|--------------|--------------|
```

Each surface row should then be backed by `BRAND-GAP-NN` register rows only when there is a downstream action or explicit keep/defer decision.

### Handoff By Phase

**Source:** `.planning/ROADMAP.md`
**Apply to:** all actionable `BRAND-GAP-NN` rows

Use target phases exactly:

- Phase 81: source brandbook and token system; roadmap lines `.planning/ROADMAP.md:56-72`.
- Phase 82: logo and SVG asset system; roadmap lines `.planning/ROADMAP.md:73-87`.
- Phase 83: visual specimens and copy blocks; roadmap lines `.planning/ROADMAP.md:89-104`.
- Phase 84: quality gate and repo hygiene; roadmap lines `.planning/ROADMAP.md:106-119`.

Do not use Phase 80 rows to implement those changes early.

### Existing Validation Pattern

**Source:** `80-VALIDATION.md`
**Apply to:** Phase 80 planning and task verification

Quick validation is CLI + Markdown review, no new test framework:

```markdown
git diff --check -- brandbook/brand-audit.md &&
jq -e . brandbook/tokens.json &&
xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg &&
xmllint --html --noout brandbook/index.html
```

Source lines: `.planning/phases/80-brand-audit-and-gap-register/80-VALIDATION.md:16-24`.

Register grep checks:

```markdown
rg -n 'draft input|draft inputs|not approved|KEEP|TIGHTEN|REWORK|ADD|REMOVE|BRAND-GAP-[0-9]+' brandbook/brand-audit.md
rg -n 'Severity|Surface|Evidence|Rationale|Target|Closeout|acceptance|BRAND-GAP-[0-9]+' brandbook/brand-audit.md
rg -n 'GitHub|README|Hex\.pm|HexDocs|docs UI|code|terminal|landing|social|favicon|monochrome|dark|light|diagram|UI states' brandbook/brand-audit.md
```

Source lines: `.planning/phases/80-brand-audit-and-gap-register/80-VALIDATION.md:37-45`.

Manual checks are required for judgment quality and phase boundary:

```markdown
Confirm Phase 80 edits only the audit/register artifact and routes final tokens,
logo choices, copy refresh, and validation scripts to Phases 81-84.
```

Source lines: `.planning/phases/80-brand-audit-and-gap-register/80-VALIDATION.md:60-68`.

### Conformance / Contract Check Style

**Source:** `mailglass_admin/scripts/check-conformance.sh`
**Apply to:** Phase 80 validation language and Phase 84 handoff rows

Existing committed gates are fail-loud shell scripts with `set -euo pipefail`, cwd-independent path resolution, scoped grep checks, accumulated errors, and one clean success message:

```bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
errors=0
```

Source lines: `mailglass_admin/scripts/check-conformance.sh:13-25`.

Do not create a brandbook equivalent in Phase 80. Register the expected Phase 84 checks instead.

### Contrast Check Style

**Source:** `mailglass_admin/test/mailglass_admin/accessibility_test.exs`
**Apply to:** accessibility risk rows and Phase 84 handoff

Existing contrast tests pin literal hex pairs and use standard luminance math:

```elixir
test "Slate on Paper - 5.1:1 (AA body text)" do
  assert contrast_ratio("#5C6B7A", "#F8FBFD") >= 4.5
end

ratio = contrast_ratio("#277B96", "#F8FBFD")
assert ratio >= 4.5
assert ratio < 5.0
```

Source lines: `mailglass_admin/test/mailglass_admin/accessibility_test.exs:15-66`.

Phase 80 should name contrast risks and allowed-use distinctions; Phase 84 should own executable brandbook contrast checks if needed.

### Package Allowlist Pattern

**Source:** `mix.exs`, `mailglass_admin/mix.exs`
**Apply to:** repo hygiene rows and no-source-edit warnings

Core package allowlist excludes `brandbook/`:

```elixir
files:
  ~w(lib priv/gettext guides mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)
```

Source lines: `mix.exs:343-352`.

Admin package allowlist also excludes broad `brandbook/`:

```elixir
files: ~w(lib priv/static docs .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
```

Source lines: `mailglass_admin/mix.exs:197-211`.

Use this as evidence for the "brand assets stay out of Hex tarballs by default" policy. Do not modify package files in Phase 80.

## No Analog Found

| File / Need | Role | Data Flow | Reason |
|-------------|------|-----------|--------|
| Committed brandbook-specific validation script | validation script | file parse / grep | None exists yet, and Phase 80 validation explicitly defers executable JSON/SVG/HTML/file-size/package-hygiene scripts to Phase 84. |
| Brand-specific gap closeout artifact | closeout artifact | evidence aggregation | No `BRAND-GAP` closeout exists yet because Phase 80 creates the register. Use Phase 79 closeout as the generic precedent. |

## No Source Edits Warnings

- Phase 80 should modify `brandbook/brand-audit.md` only.
- Do not edit `brandbook/brand-book.md`, `brandbook/index.html`, `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/assets/*.svg`, or `brandbook/examples/*.svg`; those are draft evidence and later-phase implementation targets.
- Do not edit `README.md`, `mix.exs`, `mailglass_admin/mix.exs`, package metadata, public API code, release workflows, or `mailglass_admin/docs/design-system.md`.
- Do not create committed validation scripts, contrast scripts, package tarball checks, PNG exports, screenshots, PDFs, font binaries, or vendor design files in Phase 80.
- Do not approve the current SVG logo set as final. It is one credible draft direction for Phase 82 comparison.
- Do not turn brandbook token guidance into a second admin UI framework. `mailglass_admin/docs/design-system.md` remains the implemented product UI constraint source.

## Metadata

**Analog search scope:** `.planning/phases/74-*`, `.planning/phases/79-*`, `brandbook/`, `mailglass_admin/docs/`, `mailglass_admin/scripts/`, `mailglass_admin/test/`, root/admin `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`.

**Files directly read for patterns:** `80-CONTEXT.md`, `80-RESEARCH.md`, `80-VALIDATION.md`, `74-GAP-REGISTER.md`, `79-GAP-CLOSEOUT.md`, `brandbook/brand-audit.md`, `brandbook/brand-book.md`, `brandbook/README.md`, `brandbook/index.html`, `brandbook/tokens.json`, `brandbook/tokens.css`, representative SVG assets/specimens, `mailglass_admin/docs/design-system.md`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/test/mailglass_admin/accessibility_test.exs`, `mailglass_admin/test/mailglass_admin/stability_contract_test.exs`, `mailglass_admin/e2e/operator.spec.js`, `mix.exs`, `mailglass_admin/mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`.

**Pattern extraction date:** 2026-06-06
