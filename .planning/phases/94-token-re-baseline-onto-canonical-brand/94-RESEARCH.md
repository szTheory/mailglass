# Phase 94: Token Re-Baseline onto Canonical Brand — Research

**Researched:** 2026-06-13
**Domain:** CSS token system / daisyUI theme layer / conformance gates / ExUnit test seams
**Confidence:** HIGH — all findings derived by direct file reads of the authoritative sources
(brandbook/tokens.css, brandbook/tokens.json, mailglass_admin/assets/css/app.css,
check-conformance.sh, check_motion_conformance.sh, ci.yml, brand_test.exs,
accessibility_test.exs, bundle_test.exs, mix.exs). No inferences from training data for
factual slot values.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Token consumption mechanism (TOKEN-01)**
`app.css` consumes `brandbook/tokens.css` via `@import "../../../brandbook/tokens.css"` (three
levels up from `assets/css/`). daisyUI `--color-*` declarations rewritten to `var(--mg-*)`.
No duplicate hex literals. Empirically proven via standalone Tailwind v4.1.12 binary spike.
Not vendored (same git repo, no drift surface). Drift detection free via existing
`verify.preview` `git diff --exit-code priv/static/` gate.

**D-02 — Token-parity test (TOKEN-04)**
New `mailglass_admin/test/mailglass_admin/token_parity_test.exs`. Fail-closed, always-run.
Reads compiled `priv/static/app.css`. Resolves `var(--mg-*)` indirection against inlined
`--mg-*` block. Compares to oracle (`brandbook/tokens.json`, W3C design-token format; Jason
already a dep). Structural assertion: no `#hex` on a `--color-*` line inside a daisyUI theme
selector. Single hand-maintained `@mapping` of `{theme, daisyui_var} => {tier, mg_role}`.
Added to `verify.support_contract.admin` alias. `@tag :token_parity` convenience selector only.

**D-03 — Surface/border role remap + dark-mode AA fixes (TOKEN-02, TOKEN-03)**
Full per-slot rewrite via `var(--mg-*)`. Headline corrections enumerated (see mapping table
below). Map by value, not name.

**D-04 — Contrast proof via accessibility_test.exs (TOKEN-03)**
Extend existing `accessibility_test.exs` (reuse `contrast_ratio/2`/`luminance/1`). Assert
every changed dark value clears AA 4.5:1 on its actual surface. Read hex from
`brandbook/tokens.css`. Pin border role `< 3.0` intentionally with docstring.

**D-05 — Extend shell scripts in place (RATCHET-03)**
Do NOT port to Credo. Extend `check-conformance.sh` and `check_motion_conformance.sh` in place.

**D-06 — Wire dead check-conformance.sh into CI (RATCHET-03)**
Add `bash mailglass_admin/scripts/check-conformance.sh` step in `credo_strict` job immediately
after the motion step (after line 402 in ci.yml). Script is cwd-independent (BASH_SOURCE).
Run from repo root, no `working-directory:`.

**D-07 — Gate-pattern additions**
- TYPE-GATE: add `text-(lg|xl|2xl|3xl|4xl|5xl)\b` to check-conformance.sh TYPE-GATE arm.
- New TRACK-GATE: ban `tracking-\[` in check-conformance.sh (named tracking-tight/wide still
  pass).
- Motion THRASH_PATTERN: add `transition-(width|spacing|margin|inset|top|right|bottom|left)\b`
  plus arbitrary `transition-\[` arm to check_motion_conformance.sh Pass A.
- Motion `ease-in` coverage: verify only (Pass B already handles it).

**D-08 — Advisory-now, hard-fail-at-99 sequencing (escalated fork, owner decision)**
TOKEN-layer gates (HEX/BOLD/GAP/BADGE/TYPE-base) hard-fail now. New typography/tracking
patterns (TYPE-lg/xl and TRACK-GATE) run in CI but `continue-on-error: true` (advisory) until
Phases 98/99 clean the 5 text-lg/xl sites and ~43 tracking-[0.08em] sites. Phase 99 plan must
include a flip-to-hard task.

**D-09 — Bundle rebuild + commit (TOKEN-05)**
`mix mailglass_admin.assets.build` after all edits, commit `priv/static/app.css`. The
`verify.preview` alias enforces `git diff --exit-code priv/static/`.

**D-10 — Commit ordering (gates-first)**
1. Wire + tighten gates (D-06, D-07, D-08) — no CSS/markup.
2. Add token_parity_test.exs (D-02) — green against current tree or bundled with step 3.
3. Rewrite app.css (D-01, D-03), update brand_test.exs + accessibility_test.exs (D-04),
   rebuild + commit bundle (D-09).

### Claude's Discretion
- Exact regex shapes for gate additions (validate by running scripts + `mix test`).
- Whether parity-test oracle parses `tokens.json` vs `tokens.css` (either; pick one).
- Exact split of test commits in D-10 step 2/3.

### Deferred Ideas (OUT OF SCOPE)
- Hard-flip typography/tracking gates to fail-closed (Phase 98/99).
- Stronger active-row/hover states on dark (`--mg-color-surface-selected` #1B3E55) — markup, deferred to Phase 98/99.
- Quality-ratchet apparatus (score baseline, GAP-NN, Playwright, LLM matrix) — Phase 95.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKEN-01 | `assets/css/app.css` consumes `brandbook/tokens.css` `--mg-*` tokens as single source of truth — daisyUI vars reference `var(--mg-*)`, no duplicate hex literals | D-01; @import path `../../../brandbook/tokens.css` confirmed by build-cwd = `mailglass_admin/`; all `--mg-*` tokens enumerated in §Full Slot Mapping Table |
| TOKEN-02 | Surface/border role mapping corrected — accent confined to 10% allowlist, borders use border role, cards use surface-raised | D-03; every daisyUI slot mapped by value; headline corrections enumerated with before/after hex |
| TOKEN-03 | Dark-mode token values corrected, every changed value's contrast re-verified to WCAG AA on its actual surface | D-04; concrete contrast ratios computed; border exemption documented; test seam in accessibility_test.exs |
| TOKEN-04 | Fail-closed token-parity ExUnit check asserts admin theme values equal brandbook token values | D-02; test seam in brand_test.exs / compiled priv/static/app.css; oracle = tokens.json via Jason |
| TOKEN-05 | Standalone-binary CSS bundle rebuilt and committed after re-baseline (`git diff --exit-code priv/static/` clean) | D-09; `mix mailglass_admin.assets.build` runs `tailwind default --minify`; cwd = mailglass_admin/ |
| RATCHET-03 | Conformance + motion grep gates tightened to close current escapes and run in CI | D-05..D-08; 5 text-lg/xl sites and 43 tracking-[ sites confirmed advisory; THRASH_PATTERN extended; check-conformance.sh wired at ci.yml line 403 insertion point |
</phase_requirements>

---

## Summary

Phase 94 is a focused CSS-layer surgery: make `mailglass_admin/assets/css/app.css` consume
`brandbook/tokens.css` as the single source of truth, correct seven documented token
mis-mappings (two surface-role swaps, five dark-mode value errors), wire a dead CI gate that
has never run, extend two gate scripts with three new pattern arms, and prove correctness
through a new fail-closed ExUnit parity test and an extended WCAG contrast proof. No HEEx
markup changes; no component uplift. The rebuilt CSS bundle is committed bit-for-bit.

The work divides cleanly into three commits ordered gates-first (D-10): the gate
infra lands first so the re-baseline cannot regress silently; the parity test lands second (or
alongside the re-baseline if the no-hex structural assertion requires the var rewrite to be
green first); the CSS rewrite + test updates + bundle rebuild land third.

**Primary recommendation:** Follow D-10 commit ordering exactly. The advisory/hard-fail
split on the new TYPE/TRACK gates (D-08) is the one piece requiring careful CI YAML
authorship — use `continue-on-error: true` on those two new steps, not on the entire gate
script invocation, so the existing five hard-closed arms remain blocking.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token values (canonical hex) | `brandbook/` source files | — | Single physical file; both themes derive from it |
| daisyUI theme wiring | CSS (app.css `@plugin daisyui-theme`) | — | daisyUI v5 plugin consumes `--color-*` at build time |
| Compiled artifact | `priv/static/app.css` (Tailwind binary) | — | The bundle the browser loads; the parity test reads this, not source |
| Parity assertion | ExUnit (`token_parity_test.exs`) | `verify.support_contract.admin` CI lane | Reads compiled artifact; pure file I/O + Jason; no Postgres/Node |
| Contrast assertion | ExUnit (`accessibility_test.exs`) | same CI lane | Pure math on hex pairs; no external deps |
| Conformance gates | Shell scripts (`check-conformance.sh`, `check_motion_conformance.sh`) | `credo_strict` CI job | Grep-on-lib-*.ex; cwd-independent via BASH_SOURCE |
| Bundle drift detection | `verify.preview` alias (`git diff --exit-code priv/static/`) | — | Already wired; no new infra |

---

## Full Per-Slot daisyUI `--color-*` → `var(--mg-*)` Mapping Table

This table is the build-ready contract. The planner drops this directly into the `@mapping`
in `token_parity_test.exs` and the `--color-*` assignments in `app.css`.

Values derived by reading `brandbook/tokens.css` (resolved hex) and `brandbook/tokens.json`
(palette aliases). Every hex value verified by direct file read.

[VERIFIED: direct read of brandbook/tokens.css and tokens.json 2026-06-13]

### mailglass-light theme

Current `app.css` has `@plugin "../vendor/daisyui-theme" { name: "mailglass-light"; ... }`.
After rewrite, each `--color-*` line becomes `var(--mg-*)`.

| daisyUI slot | Current hex (source app.css) | Target `--mg-*` token | Resolved hex | Change? | Notes |
|---|---|---|---|---|---|
| `--color-base-100` | `#F8FBFD` | `--mg-color-background` | `#F8FBFD` | No value change | Role correct (page background = Paper). Was already right. |
| `--color-base-200` | `#EAF6FB` (Mist) | `--mg-color-surface-raised` | `#FFFFFF` | **YES** | Bug: Mist is `surface-sunken`, not a raised card surface. Cards need white. D-03 headline correction. |
| `--color-base-300` | `#A6EAF2` (Ice) | `--mg-color-border` | `#C7DCE5` | **YES** | Bug: Ice (accent) was used for borders/dividers. Every real use is a hairline. D-03 headline correction (accent-as-border bug). |
| `--color-base-content` | `#0D1B2A` (Ink) | `--mg-color-text` | `#0D1B2A` | No value change | Primary text on light. |
| `--color-primary` | `#277B96` (Glass) | `--mg-color-accent` | `#277B96` | No value change | Primary action = Glass accent. |
| `--color-primary-content` | `#F8FBFD` (Paper) | `--mg-color-background` | `#F8FBFD` | No value change | Text on Glass fill. Paper is the lightest light token, appropriate here. |
| `--color-secondary` | `#5C6B7A` (Slate) | `--mg-color-text-muted` | `#5C6B7A` | No value change | Secondary/muted text on light. Same hex via different token name. |
| `--color-secondary-content` | `#F8FBFD` | `--mg-color-background` | `#F8FBFD` | No value change | Text on secondary fill. |
| `--color-accent` | `#0D1B2A` (Ink) | `--mg-color-accent` | `#277B96` (Glass) | **YES** | Bug: v1.7 codex-era artifact. daisyUI `accent` must carry Glass, not Ink. D-03 headline correction. Ink is base content, not an accent role. |
| `--color-accent-content` | `#F8FBFD` | `--mg-color-text-inverse` | `#FFFFFF` | No value change | Text on Glass accent fill. |
| `--color-neutral` | `#5C6B7A` (Slate) | `--mg-color-text-muted` | `#5C6B7A` | No value change | Neutral = muted text role. |
| `--color-neutral-content` | `#F8FBFD` | `--mg-color-background` | `#F8FBFD` | No value change | Text on neutral fill. |
| `--color-info` | `#277B96` (Glass) | `--mg-color-info-solid` | `#1D637A` | **YES** | Info solid should use `glass-deep` (#1D637A) per tokens.json `info-solid`. Glass (#277B96) is info-border. Use `--mg-color-info-solid`. |
| `--color-info-content` | *(not set in current app.css)* | `--mg-color-text-inverse` | `#FFFFFF` | Add | Text on solid info fill. |
| `--color-success` | `#166534` (Pine) | `--mg-color-success-solid` | `#166534` | No value change | Correct. |
| `--color-success-content` | *(not set in current app.css)* | `--mg-color-success-on-solid` | `#FFFFFF` | Add | Text on solid success fill. |
| `--color-warning` | `#A95F10` (Amber) | `--mg-color-warning-solid` | `#A95F10` | No value change | Correct. |
| `--color-warning-content` | *(not set in current app.css)* | `--mg-color-warning-on-solid` | `#FFFFFF` | Add | Text on solid warning fill. |
| `--color-error` | `#B42318` (Crimson) | `--mg-color-error-solid` | `#B42318` | No value change | Correct. |
| `--color-error-content` | *(not set in current app.css)* | `--mg-color-error-on-solid` | `#FFFFFF` | Add | Text on solid error fill. |

**Non-color slots in light (unchanged):**
`--radius-selector: 0.25rem` / `--radius-field: 0.25rem` / `--radius-box: 0.5rem` /
`--border: 1px` / `--depth: 0` / `--noise: 0` — these stay as literal values; they are not
color tokens and `brandbook/tokens.css` expresses them differently (`--mg-radius-sm: 4px`).
Do not rewrite these to `var(--mg-radius-*)` — daisyUI expects unitless fractions for its own
radius tokens (`--radius-*`), not px values from `--mg-radius-*`. Keep as-is.

### mailglass-dark theme

| daisyUI slot | Current hex (source app.css) | Target `--mg-*` token | Resolved hex | Change? | Notes |
|---|---|---|---|---|---|
| `--color-base-100` | `#0D1B2A` (Ink) | `--mg-color-background` | `#0D1B2A` | No value change | Dark page background. Correct. |
| `--color-base-200` | `#152538` (ink-raised) | `--mg-color-surface-raised` | `#152538` | No value change | Dark card surface. Correct by value. |
| `--color-base-300` | `#1F3049` (ink-overlay) | `--mg-color-border` | `#315069` | **YES** | Bug: ink-overlay (#1F3049) is an *overlay/modal surface*, not a border. The canonical dark border is `ink-edge` (#315069). D-03 headline correction. |
| `--color-base-content` | `#EAF6FB` (Mist) | `--mg-color-text` | `#EAF6FB` | No value change | Dark primary text. Correct. |
| `--color-primary` | `#A6EAF2` (Ice) | `--mg-color-accent` | `#A6EAF2` | No value change | Dark accent (Ice). Correct. |
| `--color-primary-content` | `#0D1B2A` (Ink) | `--mg-color-text-inverse` | `#0D1B2A` | No value change | Text on Ice fill on dark. Already passes AA (12.98:1 Ice on Ink). D-03: keep Ink. |
| `--color-secondary` | `#5C6B7A` (Slate) | `--mg-color-text-muted` | `#B8CAD4` | **YES** | Critical AA bug: Slate (#5C6B7A) on Ink (#0D1B2A) = 3.18:1 — fails AA 4.5:1. Canonical dark muted-text = `mist-soft` (#B8CAD4) ≈ 10:1 on Ink. D-03 headline correction. `text-secondary` is used ~110× in the markup — this is the highest-impact fix. |
| `--color-secondary-content` | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | **YES** | On dark, text on secondary fill should use Ink (dark inverse), not Paper. |
| `--color-accent` | `#277B96` (Glass) | `--mg-color-accent` | `#A6EAF2` | **YES** | Dark accent should be Ice (#A6EAF2), not Glass (#277B96). Glass is the *light* accent. D-03: accent on dark = Ice. |
| `--color-accent-content` | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | **YES** | Text on Ice fill on dark = Ink, not Paper. |
| `--color-neutral` | `#5C6B7A` (Slate) | `--mg-color-text-muted` | `#B8CAD4` | **YES** | Same fix as secondary — Slate fails AA on dark. |
| `--color-neutral-content` | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | **YES** | Text on dark neutral fill = Ink. |
| `--color-info` | `#A6EAF2` (Ice) | `--mg-color-info-solid` | `#A6EAF2` | No value change | Dark info solid = Ice. Correct. |
| `--color-info-content` | *(not set in current app.css)* | `--mg-color-info-on-solid` | `#0D1B2A` | Add | Text on solid info fill on dark. |
| `--color-success` | `#8BB77F` (pine-bright) | `--mg-color-success-solid` | `#8BB77F` | No value change | Correct. |
| `--color-success-content` | *(not set in current app.css)* | `--mg-color-success-on-solid` | `#0D1B2A` | Add | Text on dark success fill. |
| `--color-warning` | `#E0A955` (amber-bright) | `--mg-color-warning-solid` | `#E0A955` | No value change | Correct. |
| `--color-warning-content` | *(not set in current app.css)* | `--mg-color-warning-on-solid` | `#0D1B2A` | Add | Text on dark warning fill. |
| `--color-error` | `#D47368` (**off-palette**) | `--mg-color-error-solid` | `#E29089` | **YES** | Off-palette value — `#D47368` appears nowhere in `brandbook/tokens.css` or `tokens.json`. Canonical dark error = `crimson-bright` (#E29089). D-03 headline correction. |
| `--color-error-content` | *(not set in current app.css)* | `--mg-color-error-on-solid` | `#0D1B2A` | Add | Text on dark error fill. |

**Non-color slots in dark (unchanged):**
Same as light: `--radius-*`, `--border`, `--depth: 0`, `--noise: 0` — keep as literal values.

### Summary: changed slots (token re-baseline diffs)

| Slot | Theme | Before (hex) | After (`var(--mg-*)`) | Resolved hex | Root cause |
|------|-------|-------------|----------------------|-------------|------------|
| `--color-base-200` | light | `#EAF6FB` (Mist/sunken) | `--mg-color-surface-raised` | `#FFFFFF` | Mist is sunken, not raised |
| `--color-base-300` | light | `#A6EAF2` (Ice/accent) | `--mg-color-border` | `#C7DCE5` | Accent used as border hairline |
| `--color-accent` | light | `#0D1B2A` (Ink) | `--mg-color-accent` | `#277B96` (Glass) | Ink as accent is codex artifact |
| `--color-info` | light | `#277B96` | `--mg-color-info-solid` | `#1D637A` | Info solid = glass-deep, not glass |
| `--color-base-300` | dark | `#1F3049` (overlay surface) | `--mg-color-border` | `#315069` | ink-overlay ≠ border role |
| `--color-secondary` | dark | `#5C6B7A` (Slate, 3.18:1) | `--mg-color-text-muted` | `#B8CAD4` | AA failure: Slate on Ink fails |
| `--color-secondary-content` | dark | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | Content on dark fill uses Ink |
| `--color-accent` | dark | `#277B96` (Glass/light) | `--mg-color-accent` | `#A6EAF2` (Ice) | Dark accent is Ice, not Glass |
| `--color-accent-content` | dark | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | Text on Ice fill = Ink |
| `--color-neutral` | dark | `#5C6B7A` (Slate, 3.18:1) | `--mg-color-text-muted` | `#B8CAD4` | Same AA failure as secondary |
| `--color-neutral-content` | dark | `#F8FBFD` | `--mg-color-text-inverse` | `#0D1B2A` | Text on dark neutral fill = Ink |
| `--color-error` | dark | `#D47368` (off-palette) | `--mg-color-error-solid` | `#E29089` | Off-palette value, canonical fix |

---

## Gate Script Edit Points — Concrete Locations

### `mailglass_admin/scripts/check-conformance.sh`

**Current state:** DEAD — not referenced in ci.yml; runs locally only. Five gates: BADGE, TYPE
(text-sm/xs/base), BOLD, GAP, HEX. All currently hard-closed and clean (zero violations on
Phase 76 codebase, per script header).

**Edit 1 — Extend TYPE-GATE (line 45)**

Current regex (line 45):
```
text-(sm|xs)\b|text-base($|[^-])
```

New regex (D-07):
```
text-(sm|xs|lg|xl|2xl|3xl|4xl|5xl)\b|text-base($|[^-])
```

The new `lg|xl|2xl|3xl|4xl|5xl` arm uses `\b` (word boundary), consistent with the existing
`sm|xs` arm. This correctly excludes `text-xl-something` hypothetical suffixes while catching
`text-xl` as a bare class. The `text-base-content` exclusion mechanism (the `($|[^-])` arm
for `text-base`) is unchanged — it applies only to `text-base`, not to the new size tokens.

Per D-08: this arm is **advisory** (`continue-on-error: true` in CI). Existing violations:

| File | Line | Violation |
|------|------|-----------|
| `lib/mailglass_admin/preview_live.ex` | 256 | `text-xl` |
| `lib/mailglass_admin/inbound/detail_header.ex` | 37 | `text-xl` |
| `lib/mailglass_admin/inbound/replay_modal.ex` | 31 | `text-lg` |
| `lib/mailglass_admin/operator/replay_modal.ex` | 27 | `text-lg` |
| `lib/mailglass_admin/operator/detail_header.ex` | 21 | `text-xl` |

5 sites total. Markup fix deferred to Phase 98/99; Phase 99 plan must flip this arm to hard-fail.

**Edit 2 — New TRACK-GATE (add after HEX-GATE block, before the final error-count check)**

```bash
# TRACK-GATE: arbitrary tracking-[…] utilities in HEEx.
# Named tracking-tight / tracking-wide / tracking-normal are allowed (system design).
# Arbitrary tracking-[0.08em] and similar JIT values bypass the token contract;
# a named --tracking-eyebrow token must be defined in brandbook/tokens.css first,
# then sites migrated (Phase 98/99). Only match the bracket form.
if grep -rEn 'tracking-\[' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TRACK-GATE — arbitrary tracking-[…] found (define a named token first)" >&2
  errors=$((errors + 1))
fi
```

Per D-08: this gate is **advisory** (`continue-on-error: true` in CI). Existing violations: 43
sites, all `tracking-[0.08em]` (eyebrow-label pattern). Markup fix deferred to Phase 98/99.

**Critical D-08 implementation note:** The advisory/hard distinction CANNOT be handled by
`continue-on-error` on the script invocation itself (that would make ALL five existing gates
advisory). Instead, the two new advisory arms must be split into a separate invocation or
the script must emit a different exit code. The cleanest approach is:

Option A (recommended): The two advisory arms run as a separate script call with
`continue-on-error: true` in a second CI step; the five hard arms remain in the existing
step without `continue-on-error`. This means splitting the new arms into a helper script
(e.g., `check-conformance-advisory.sh`) OR using `|| true` at the script level with a
documented advisory output.

Option B: Add a `--advisory` flag to `check-conformance.sh` that runs only the advisory
arms and exits 0 regardless — wires as a second step in CI.

The planner should pick Option A (separate script) for clarity and to avoid mutating the
hard-fail script's exit-code contract. The exact split is Claude's discretion (D-08 leaves
"Exact regex shapes" to Claude).

### `scripts/check_motion_conformance.sh`

**Current state:** WIRED — runs in `credo_strict` job, line 402 of ci.yml. Two passes: Pass A
(layout-thrashing + duration, scans both lib/ AND app.css); Pass B (easing classes, lib/ only).

**Current THRASH_PATTERN (line 18):**
```
transition-height|transition-max-height|transition-padding|transition-all|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}
```

**Extended THRASH_PATTERN (D-07) — add layout-property transitions:**
```
transition-(height|max-height|padding|width|spacing|margin|inset|top|right|bottom|left)\b|transition-all|transition-\[(width|height|margin|padding|inset|top|right|bottom|left)|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}
```

Breakdown of additions:
- `transition-width`, `transition-spacing`, `transition-margin`, `transition-inset`,
  `transition-top`, `transition-right`, `transition-bottom`, `transition-left` — named
  layout-property Tailwind transition utilities.
- `transition-\[(width|height|margin|padding|inset|top|right|bottom|left)` — arbitrary JIT
  form for those same properties.
- Existing `transition-height`, `transition-max-height`, `transition-padding` stay (the `\b`
  form replaces the bare substring match for precision).
- `transition-colors`, `transition-transform`, `transition-opacity`, `transition-shadow` remain
  allowed (not in the pattern).

**Pass B (ease-in):** No change needed. `ease-in[^-]` already catches bare `ease-in` without
matching `ease-in-out` or `--ease-in-out`. D-07 says "verify only, no change."

### `.github/workflows/ci.yml` — `credo_strict` job

**Insertion point:** After line 402 (end of `Verify motion conformance` step), before line 403
(`Run Credo strict`). Current lines 399-404:

```yaml
      - name: Verify suppression docs (shell gate)
        run: bash scripts/check_credo_suppressions.sh
      - name: Verify motion conformance (shell gate)
        run: bash scripts/check_motion_conformance.sh
      - name: Run Credo strict
        run: mix credo --strict
```

**New steps to insert between motion step and Credo step (D-06, D-08):**

```yaml
      - name: Verify design-system conformance (shell gate — hard-fail arms)
        # Wires the previously-DEAD check-conformance.sh (D-06). Five hard-closed gates:
        # BADGE / TYPE-base / BOLD / GAP / HEX. Script is BASH_SOURCE-anchored, cwd-independent.
        run: bash mailglass_admin/scripts/check-conformance.sh
      - name: Verify design-system conformance (advisory arms — TYPE-lg/xl + TRACK)
        # Advisory until Phases 98/99 clean the 5 text-xl/lg and ~43 tracking-[0.08em] sites.
        # continue-on-error keeps main green; flip to hard-fail in Phase 99 plan.
        continue-on-error: true
        run: bash mailglass_admin/scripts/check-conformance-advisory.sh
```

The motion conformance step (line 402) runs first (gates THRASH + ease-in), then
`check-conformance.sh` (BADGE/TYPE-base/BOLD/GAP/HEX hard-closed), then the advisory script.

**`support_contract_admin` job (lines 576+):** No structural changes. The new
`token_parity_test.exs` is added to the `verify.support_contract.admin` alias in `mix.exs`
(see §Test Seams below), which this job already calls at line 633:
`cd mailglass_admin && mix verify.support_contract.admin`. That alias update is sufficient.

---

## Test Seams — Concrete File Analysis

### `mailglass_admin/test/mailglass_admin/brand_test.exs`

**How it reads the compiled bundle (lines 15-23):**
```elixir
@css_path Path.join([
            Application.app_dir(:mailglass_admin, "priv"),
            "static",
            "app.css"
          ])

setup do
  css = File.read!(@css_path)
  {:ok, css: css}
end
```

This is the reusable seam: `Application.app_dir(:mailglass_admin, "priv")` resolves to
`mailglass_admin/priv/` at test time (the app is loaded). `token_parity_test.exs` should
copy this exact path pattern.

**Assertions that WILL GO RED on the var-rewrite (D-02):**

1. Line 31: `assert lowered =~ "#0d1b2a"` — Ink will still appear in the `--mg-color-text` /
   `--mg-color-background` inlined block, so this remains green. Ink appears in the compiled
   `--mg-*` declarations that Tailwind inlines from `brandbook/tokens.css`.

2. Lines 44-45: `assert lowered =~ "--color-base-100: #f8fbfd"` — WILL GO RED. After the
   var-rewrite, this becomes `--color-base-100: var(--mg-color-background)`. The literal hex
   will no longer appear on that CSS line inside the daisyUI theme selector.

3. Lines 47-48: `assert lowered =~ "--color-primary: #277b96"` — WILL GO RED. Becomes
   `--color-primary: var(--mg-color-accent)`.

4. Lines 50-52: `assert lowered =~ "--color-base-content: #0d1b2a"` — WILL GO RED. Becomes
   `--color-base-content: var(--mg-color-text)`.

**How to fix brand_test.exs (D-02 spec):** Replace literal-hex assertions with two tiers:
a) Assert `var(--mg-*)` wiring in the theme selector block.
b) Assert the resolved hex appears in the `--mg-*` declarations block (from the inlined
   `brandbook/tokens.css` import).

Example replacement for line 44-45:
```elixir
# After: assert the var reference in the theme block
assert css =~ "--color-base-100: var(--mg-color-background)" or
         css =~ "--color-base-100:var(--mg-color-background)",
       "mailglass-light --color-base-100 must reference --mg-color-background"

# And: assert the token value is inlined from brandbook/tokens.css
assert String.downcase(css) =~ "--mg-color-background: #f8fbfd",
       "--mg-color-background token (#F8FBFD Paper) must be inlined in compiled CSS"
```

The "visual DON'Ts" tests (lines 69-82: `backdrop-filter`, `--depth: 0`, `--noise: 0`) are
UNAFFECTED by the var-rewrite and stay as-is.

The "brand palette hex values" test (lines 26-37: the six canonical hex assertions) will
remain green IF the inlined `--mg-*` block carries all six palette members — which it does
(Ink, Glass, Ice, Mist, Paper, Slate all appear in `brandbook/tokens.css` light block). No
change needed there.

The "mailglass-dark exists" test (lines 62-65: `assert css =~ "[data-theme=mailglass-dark]"`)
is unaffected. No change.

### `token_parity_test.exs` — New File Seam

**Oracle resolution flow:**

1. Read `priv/static/app.css` (compiled bundle) — same `@css_path` pattern as brand_test.exs.
2. From the compiled CSS, extract the `--mg-*` declarations block (inlined from the
   `brandbook/tokens.css` @import). These appear as plain CSS custom property declarations
   outside any daisyUI theme selector — Tailwind inlines them into the bundle at build time.
3. For each `{theme, daisyui_var}` in `@mapping`:
   - Find the daisyUI theme selector block (`[data-theme=mailglass-light]` or
     `[data-theme=mailglass-dark]`).
   - Extract the value for that `--color-*` var within that block.
   - If it is `var(--mg-something)`, resolve by looking up `--mg-something` in the inlined
     `--mg-*` block from step 2.
   - Compare resolved hex to oracle value from `brandbook/tokens.json`.
4. Structural assertion: scan the daisyUI theme selector blocks; assert NO line matches
   `--color-[a-z-]+: #[0-9a-fA-F]` (the no-raw-hex-in-theme rule).

**Oracle lookup via `tokens.json`:**
```elixir
# Jason.decode! the tokens.json file at test time.
# De-alias {palette.x} refs using the "palette" map.
tokens_path = Path.join([
  Application.app_dir(:mailglass_admin),  # resolves to mailglass_admin/
  "..",                                    # up to monorepo root
  "brandbook",
  "tokens.json"
])
```
Note: `Application.app_dir(:mailglass_admin)` returns the OTP app dir in `_build/`; the
`brandbook/` path relative to it requires navigating to the repo root. An alternative:
use `File.cwd!()` (the mix project root, `mailglass_admin/`) and compute `../brandbook/tokens.json`.
Or use `__DIR__` in the test file (`test/mailglass_admin/token_parity_test.exs`) and navigate
upward: `Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"])`.

The `__DIR__`-relative approach is the most reliable: `test/mailglass_admin/` → `test/` →
`mailglass_admin/` → project root → `brandbook/tokens.json`. That is three `..` levels up
from `__DIR__`: `Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"]) |> Path.expand()`.

**`@mapping` for `token_parity_test.exs`:**

Use the full per-slot table above. Each entry is:
```elixir
# {theme_name, daisyui_slot} => {mg_token_name, oracle_tier, oracle_key}
{"mailglass-light", "--color-base-100"} => {"--mg-color-background", "light", "background"},
{"mailglass-light", "--color-base-200"} => {"--mg-color-surface-raised", "light", "surface-raised"},
{"mailglass-light", "--color-base-300"} => {"--mg-color-border", "light", "border"},
# ... etc.
```

The oracle `tier` ("light" / "dark") corresponds to `tokens.json["color"]["light"]` or
`["color"]["dark"]`, from which the `key` value is read and `{palette.x}` aliases are
resolved via `tokens.json["palette"][x]["$value"]`.

### `mailglass_admin/test/mailglass_admin/accessibility_test.exs`

**Reusable functions:**
- `contrast_ratio/2` (line 72): takes two `"#RRGGBB"` strings, returns float.
- `luminance/1` (line 81): WCAG 2.1 relative luminance.
- These are `defp` — accessible only within the module. The new contrast assertions extend
  this same module (not a new file).

**Assertions to add (D-04):**

New `describe` block: `"dark-mode token fixes (TOKEN-03)"`:

```elixir
test "muted text #B8CAD4 on Ink #0D1B2A — AA 4.5:1" do
  # Was Slate #5C6B7A = 3.18:1 (FAIL). Fix = mist-soft #B8CAD4.
  assert contrast_ratio("#B8CAD4", "#0D1B2A") >= 4.5
end

test "error solid #E29089 on Ink #0D1B2A — AA 4.5:1" do
  # Was off-palette #D47368. Fix = crimson-bright #E29089.
  assert contrast_ratio("#E29089", "#0D1B2A") >= 4.5
end

test "primary-content Ink #0D1B2A on Ice #A6EAF2 — AA 4.5:1 (unchanged, verify holds)" do
  # Already passes at 12.98:1. Pin as regression test.
  assert contrast_ratio("#0D1B2A", "#A6EAF2") >= 4.5
end
```

New `describe` block: `"border role is intentionally sub-3:1 (WCAG 1.4.11 decorative exemption)"`:

```elixir
test "light border #C7DCE5 on Paper #F8FBFD — decorative, exempt, pinned < 3.0" do
  # WCAG 1.4.11 only applies to *control boundaries*. Decorative hairlines/dividers
  # are exempt. This assertion intentionally pins the ratio BELOW 3.0 so a well-
  # intentioned future contributor cannot silently darken the border token to "fix"
  # a false violation — that would change the visual character of the design.
  ratio = contrast_ratio("#C7DCE5", "#F8FBFD")
  assert ratio < 3.0,
         "Light border is intentionally decorative (sub-3:1). " <>
         "If this fails, the border token was darkened — this requires explicit design approval."
end

test "dark border #315069 on Ink #0D1B2A — decorative, exempt, pinned < 3.0" do
  ratio = contrast_ratio("#315069", "#0D1B2A")
  assert ratio < 3.0,
         "Dark border is intentionally decorative (sub-3:1). Same exemption as light border."
end
```

Read hex values directly from `brandbook/tokens.css` at test time (D-04 spec) rather than
hardcoding them, OR hardcode and add a comment pointing to the token source — consistent with
how the existing tests hardcode palette hex values (the `describe "canonical contrast pairs"`
block hardcodes all six original pairings).

### `mailglass_admin/mix.exs` — `verify.support_contract.admin` alias

Current (line 189-192):
```elixir
"verify.support_contract.admin": [
  "test test/mailglass_admin/post_installer_smoke_test.exs " <>
  "test/mailglass_admin/operator_live_test.exs ..."
  " --warnings-as-errors"
]
```

After Phase 94, add `token_parity_test.exs` to the list:
```
test/mailglass_admin/token_parity_test.exs
```

This alias is what the `support_contract_admin` CI job calls (`cd mailglass_admin && mix verify.support_contract.admin`). Adding the file here makes TOKEN-04 a required branch-protection check automatically.

**Note:** `accessibility_test.exs` and `brand_test.exs` are NOT currently in
`verify.support_contract.admin`. They appear to run in the normal `mix test` sweep via
`verify.preview`. This is fine — the parity test is the new required check; the contrast
and brand tests run in the broader `verify.preview` suite.

---

## Dark-Mode Contrast Verification (Pre-computed)

Using the WCAG 2.1 formula from `accessibility_test.exs`:

| Pair | Foreground | Background | Estimated ratio | AA pass (≥4.5)? |
|------|-----------|-----------|----------------|----------------|
| muted text fix | `#B8CAD4` | `#0D1B2A` (Ink) | ≈ 10.1:1 | YES |
| muted text bug | `#5C6B7A` (Slate) | `#0D1B2A` (Ink) | ≈ 3.18:1 | NO — this is what we're fixing |
| error fix | `#E29089` | `#0D1B2A` (Ink) | ≈ 6.3:1 | YES |
| error bug | `#D47368` | `#0D1B2A` (Ink) | ≈ 4.2:1 | NO (and off-palette) |
| primary-content (unchanged) | `#0D1B2A` (Ink) | `#A6EAF2` (Ice) | ≈ 12.98:1 | YES |
| light border (decorative) | `#C7DCE5` | `#F8FBFD` (Paper) | ≈ 1.37:1 | Exempt — pin `< 3.0` |
| dark border (decorative) | `#315069` | `#0D1B2A` (Ink) | ≈ 2.06:1 | Exempt — pin `< 3.0` |
| accent (light, Glass) | `#277B96` | `#F8FBFD` (Paper) | ≈ 4.63:1 | YES (borderline — already tested) |

[VERIFIED: hex values from brandbook/tokens.css; ratios estimated per WCAG 2.1 formula;
exact values will be computed at runtime by the test]

---

## Existing Violation Inventory (D-08 Advisory Gate Sites)

### TYPE-GATE violations (text-lg/xl) — 5 sites

| File | Line | Class | Deferred to |
|------|------|-------|------------|
| `lib/mailglass_admin/preview_live.ex` | 256 | `text-xl` | Phase 98/99 |
| `lib/mailglass_admin/inbound/detail_header.ex` | 37 | `text-xl` | Phase 98/99 |
| `lib/mailglass_admin/inbound/replay_modal.ex` | 31 | `text-lg` | Phase 98/99 |
| `lib/mailglass_admin/operator/replay_modal.ex` | 27 | `text-lg` | Phase 98/99 |
| `lib/mailglass_admin/operator/detail_header.ex` | 21 | `text-xl` | Phase 98/99 |

### TRACK-GATE violations (tracking-[0.08em]) — 43 sites

All are the `tracking-[0.08em]` eyebrow-label pattern used in section headers and form labels.
Sample (first 10 of 43):

| File | Line | Pattern |
|------|------|---------|
| `lib/mailglass_admin/operator_live.ex` | 403 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound_live.ex` | 309 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/evidence_card.ex` | 55 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/evidence_card.ex` | 59 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/evidence_card.ex` | 63 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/evidence_card.ex` | 69 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/evidence_card.ex` | 85 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/filters_form.ex` | 20 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/filters_form.ex` | 33 | `tracking-[0.08em]` |
| `lib/mailglass_admin/inbound/filters_form.ex` | 46 | `tracking-[0.08em]` |

Fix path: define `--tracking-eyebrow: 0.08em` in `brandbook/tokens.css`, create a named
Tailwind utility `tracking-eyebrow`, migrate all 43 sites. Deferred to Phase 98/99.

---

## Architecture Patterns

### Compiled-bundle test seam

All test assertions read `priv/static/app.css` (the compiled artifact), not the source
`assets/css/app.css`. This is the established project pattern (`brand_test.exs`, `bundle_test.exs`).
The Tailwind binary inlines all `@import`-ed declarations into the output — `brandbook/tokens.css`
`--mg-*` declarations will appear verbatim in the compiled bundle alongside the daisyUI theme
blocks. The parity test exploits this: the oracle (tokens.json) and the compiled facts (the
`--mg-*` inlined block) are independently readable and comparable without running a CSS parser.

### daisyUI v5 theme block compilation

daisyUI v5 transforms `@plugin "../vendor/daisyui-theme" { name: "mailglass-light"; ... }` into:
- `[data-theme=mailglass-light] { --color-base-100: ...; ... }` in the compiled CSS.
- `input.theme-controller[value=mailglass-light] { ... }` (mirror selector).
The brand_test.exs already accounts for this (line 62-65 tests `[data-theme=mailglass-dark]`
not the source-level `name:` string). The parity test must likewise search for
`[data-theme=mailglass-light]` and `[data-theme=mailglass-dark]` blocks in the compiled CSS.

### @import path resolution

The Tailwind binary runs with `cd: Path.expand("..", __DIR__)` in `config.exs`, which resolves
to `mailglass_admin/` (the package root). From there, `assets/css/app.css` is the input.
The relative import `../../../brandbook/tokens.css` resolves as:
- From `mailglass_admin/assets/css/app.css`
- `../` → `mailglass_admin/assets/`
- `../../` → `mailglass_admin/`
- `../../../` → the monorepo root (one level above `mailglass_admin/`)
- `../../../brandbook/tokens.css` → `brandbook/tokens.css` at monorepo root.

This is confirmed by D-01: "Empirically proven (research spike)". No further verification
needed. Comment the import line in app.css:
```css
/* Resolves to: <monorepo-root>/brandbook/tokens.css (build cwd = mailglass_admin/) */
@import "../../../brandbook/tokens.css";
```

### Placement of @import in app.css

The import must come before the `@plugin "../vendor/daisyui-theme"` blocks so `--mg-*` tokens
are in scope when daisyUI resolves them. In Tailwind v4 CSS, source ordering follows standard
CSS cascade; `@import` at the top of the file ensures `--mg-*` custom properties are declared
in `:root` / `[data-theme=*]` before the daisyUI plugin attempts to use `var(--mg-*)`. Since
the `--mg-*` tokens are on `:root` (light) and `[data-theme=dark]`, and daisyUI emits its
own `[data-theme=mailglass-light]` / `[data-theme=mailglass-dark]` selectors, the `var(--mg-*)`
references in the daisyUI block resolve at render time in the browser, not at build time —
so order matters for parse order, not for static resolution. The import at the top is correct
and sufficient.

### Bundle size impact

The `brandbook/tokens.css` file adds ~100-150 lines of custom property declarations to the
compiled bundle. The current `bundle_test.exs` budget is 150KB for `app.css`. The token file
is small (the CSS file read is ~192 lines, under 6KB); total bundle size impact is negligible.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| WCAG contrast math | Custom luminance formula | Existing `contrast_ratio/2` + `luminance/1` in `accessibility_test.exs` |
| Token JSON parsing | Manual string parser | Jason (already a dep, `{:jason, "~> 1.4"}`) |
| CSS bundle compilation | Custom CSS preprocessor | Existing `mix mailglass_admin.assets.build` (Tailwind binary) |
| Palette alias resolution | Regex substitution on JSON | Walk `tokens.json["palette"]` map via Jason — one pass |
| Drift detection | File hash comparison | Existing `verify.preview` `git diff --exit-code priv/static/` |

---

## Common Pitfalls

### Pitfall 1: Advisory flag applied to the wrong CI scope

**What goes wrong:** Using `continue-on-error: true` on the step that calls
`check-conformance.sh` makes ALL five existing hard-closed gates advisory, letting
BADGE/BOLD/GAP/HEX violations through.

**Why it happens:** D-08 says "advisory" but does not specify the implementation boundary.

**How to avoid:** Split the two new advisory arms into a separate script file
(`check-conformance-advisory.sh`) and use `continue-on-error: true` only on that second CI
step. The original `check-conformance.sh` MUST keep its existing hard-closed exit behavior.

**Warning signs:** Running `grep -rE 'defp badge_class'` etc. returns matches but CI still
shows green.

### Pitfall 2: Stale bundle makes parity test test the wrong values

**What goes wrong:** `token_parity_test.exs` reads `priv/static/app.css` but the file on
disk is the old bundle (before `mix mailglass_admin.assets.build` is run). Every parity
assertion fails because the vars haven't been written yet.

**Why it happens:** The test reads the compiled artifact, not source — this is intentional
(the stale-bundle footgun is exactly what makes TOKEN-05 enforcement free). But during local
development, running `mix test` without first building updates the tests against the wrong
artifact.

**How to avoid:** In `token_parity_test.exs` docstring, state explicitly: "If this test
fails with 'expected var(--mg-*) but got #hex', the bundle is stale — run `mix
mailglass_admin.assets.build` and commit `priv/static/app.css`." Match the `bundle_test.exs`
and `brand_test.exs` message style.

**Warning signs:** All structural assertions fail; the `--mg-*` block is absent from the CSS.

### Pitfall 3: `var(--mg-*)` references not resolving in the inlined bundle

**What goes wrong:** The compiled `priv/static/app.css` contains `--color-primary:
var(--mg-color-accent)` in the daisyUI theme block, but the `--mg-color-accent: #277B96`
declaration is NOT present elsewhere in the file (the @import was not inlined).

**Why it happens:** The standalone Tailwind binary should inline `@import`-ed declarations,
but if the relative path is wrong (wrong number of `../` levels) the import silently fails and
no `--mg-*` declarations appear.

**How to avoid:** After the first `mix mailglass_admin.assets.build` run with the @import,
inspect `priv/static/app.css` and verify `--mg-color-background: #F8FBFD` (or similar)
appears at the top. If absent, recount the `../` levels.

**Warning signs:** `grep '--mg-color-background' priv/static/app.css` returns empty.

### Pitfall 4: `verify.support_contract.admin` alias not updated with new test file

**What goes wrong:** `token_parity_test.exs` exists but is not added to the
`verify.support_contract.admin` mix alias, so it never runs in the `support_contract_admin`
CI job. The parity check exists but is not branch-protection-required.

**How to avoid:** After creating the test file, immediately add its path to the alias in
`mailglass_admin/mix.exs` in the same commit (or at latest the same wave).

### Pitfall 5: Parity test oracle path breaks in CI vs local

**What goes wrong:** The relative path to `brandbook/tokens.json` computed from `__DIR__`
works locally but fails in CI because CI runs from a different working directory.

**How to avoid:** Use `Path.expand(path)` and `File.exists?!/1` as a startup assertion in the
test so it fails loudly with the actual resolved path rather than a `Jason.decode!` error on
empty content. Example: `assert File.exists?(tokens_path), "tokens.json not found at #{tokens_path}"`.

### Pitfall 6: The `--color-info-content` slots not added (unidiomatic daisyUI)

**What goes wrong:** Current `app.css` sets `--color-info` but not `--color-info-content`.
daisyUI v5 generates a default content color for unset `-content` slots. Leaving them unset
means the content color is daisyUI's auto-derived value, not the brand token, which may drift.

**How to avoid:** Explicitly set all `-content` slots in the daisyUI theme block alongside
their base slot, using the appropriate `--mg-color-*-on-solid` or `--mg-color-text-inverse`
token. See the per-slot table above (the "Add" rows).

---

## Validation Architecture

This section maps each Phase 94 requirement to its proof mechanism (test file, command,
pass/fail signal). This is the Nyquist sampling plan for TOKEN-01..05 and RATCHET-03.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir/OTP — no external dep) |
| Config file | `mailglass_admin/test/test_helper.exs` (existing) |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/accessibility_test.exs test/mailglass_admin/brand_test.exs` |
| Full suite command | `cd mailglass_admin && mix verify.preview` |
| Support contract command | `cd mailglass_admin && mix verify.support_contract.admin` |

### Phase Requirements → Test/Gate Map

| Req ID | Behavior to prove | Proof mechanism | Automated command | File exists? |
|--------|------------------|-----------------|-------------------|-------------|
| TOKEN-01 | No raw `#hex` in any daisyUI `--color-*` line in the compiled bundle; every such line uses `var(--mg-*)` | Structural assertion in `token_parity_test.exs` (the no-raw-hex scan) | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs` | ❌ Wave 0 |
| TOKEN-01 | `--mg-*` declarations are present in compiled `priv/static/app.css` (confirms @import inlined) | Structural assertion in `token_parity_test.exs` (assert `--mg-color-background` present) | same | ❌ Wave 0 |
| TOKEN-02 | `base-200` = `surface-raised` (#FFFFFF), `base-300` = `border` (#C7DCE5), `accent` = `Glass` (#277B96) in light | `token_parity_test.exs` `@mapping` assertions for those three light slots | same | ❌ Wave 0 |
| TOKEN-02 | `base-300` = `border` (#315069), `accent` = `Ice` (#A6EAF2) in dark | `token_parity_test.exs` `@mapping` assertions for those dark slots | same | ❌ Wave 0 |
| TOKEN-02 | Updated assertions in `brand_test.exs` for `--color-base-100/primary/base-content` now check `var(--mg-*)` wiring | `brand_test.exs` updated assertions | `cd mailglass_admin && mix test test/mailglass_admin/brand_test.exs` | ✅ (needs update) |
| TOKEN-03 | Dark muted `#B8CAD4` on Ink passes AA 4.5:1 | New contrast test in `accessibility_test.exs` | `cd mailglass_admin && mix test test/mailglass_admin/accessibility_test.exs` | ✅ (needs extension) |
| TOKEN-03 | Dark error `#E29089` on Ink passes AA 4.5:1 | New contrast test in `accessibility_test.exs` | same | ✅ (needs extension) |
| TOKEN-03 | Primary-content Ink on Ice passes AA 4.5:1 (regression pin) | New contrast test in `accessibility_test.exs` | same | ✅ (needs extension) |
| TOKEN-03 | Light border `#C7DCE5` on Paper is sub-3:1 (decorative exemption pinned) | New contrast test in `accessibility_test.exs` with `< 3.0` assertion | same | ✅ (needs extension) |
| TOKEN-03 | Dark border `#315069` on Ink is sub-3:1 (decorative exemption pinned) | New contrast test in `accessibility_test.exs` with `< 3.0` assertion | same | ✅ (needs extension) |
| TOKEN-04 | Every daisyUI `--color-*` slot in both themes resolves to the oracle hex from `tokens.json` | `token_parity_test.exs` value-equality assertions (one per mapping entry) | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs` | ❌ Wave 0 |
| TOKEN-04 | Oracle file path resolves (startup assertion) | `File.exists!/1` assert in test setup | same | ❌ Wave 0 |
| TOKEN-05 | Compiled bundle is bit-for-bit current (no drift from source) | `mix verify.preview` step 4: `cmd git diff --exit-code priv/static/` | `cd mailglass_admin && mix verify.preview` | ✅ (already wired) |
| TOKEN-05 | Bundle is under 150KB (no token explosion) | `bundle_test.exs` line 24: `assert size < 150_000` | `cd mailglass_admin && mix test test/mailglass_admin/bundle_test.exs` | ✅ (already exists) |
| RATCHET-03 | `check-conformance.sh` runs in CI and is not silently skipped | New CI step in `credo_strict` job; `bash mailglass_admin/scripts/check-conformance.sh` | Local: `bash mailglass_admin/scripts/check-conformance.sh` | ✅ (script exists; CI step new) |
| RATCHET-03 | All five existing hard gates (BADGE/TYPE-base/BOLD/GAP/HEX) return exit 0 on current codebase | `check-conformance.sh` exits 0 | same | ✅ (no violations exist) |
| RATCHET-03 | TYPE-GATE extended to cover `text-(lg|xl|2xl|3xl|4xl|5xl)` (advisory arm) | `check-conformance-advisory.sh` new step with `continue-on-error: true` | Local: `bash mailglass_admin/scripts/check-conformance-advisory.sh` | ❌ Wave 0 |
| RATCHET-03 | TRACK-GATE covers `tracking-[` (advisory arm) | same advisory script | same | ❌ Wave 0 |
| RATCHET-03 | THRASH_PATTERN extended with layout-property transition arms | `check_motion_conformance.sh` Pass A | `bash scripts/check_motion_conformance.sh` | ✅ (needs extension) |
| RATCHET-03 | Motion `ease-in` coverage verified (no change needed) | `check_motion_conformance.sh` Pass B already covers it | same | ✅ (no change) |

### Wave 0 Gaps (files to create or extend before implementation)

- [ ] `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — new; covers TOKEN-01, TOKEN-02, TOKEN-04
- [ ] `mailglass_admin/scripts/check-conformance-advisory.sh` — new; covers RATCHET-03 advisory arms
- [ ] `mailglass_admin/test/mailglass_admin/accessibility_test.exs` — extend with 5 new tests; covers TOKEN-03
- [ ] `mailglass_admin/test/mailglass_admin/brand_test.exs` — update 3 assertions (lines 44-52) from hex to var+hex; covers TOKEN-01/02 from existing test
- [ ] `mailglass_admin/scripts/check-conformance.sh` — extend TYPE-GATE regex; covers RATCHET-03
- [ ] `scripts/check_motion_conformance.sh` — extend THRASH_PATTERN; covers RATCHET-03
- [ ] `.github/workflows/ci.yml` — add 2 new steps in `credo_strict` job; covers RATCHET-03 CI wiring
- [ ] `mailglass_admin/mix.exs` — add `token_parity_test.exs` to `verify.support_contract.admin` alias; covers TOKEN-04 CI gate

### Sampling rate

- **Per-task commit (after gates step):** `bash mailglass_admin/scripts/check-conformance.sh && bash scripts/check_motion_conformance.sh`
- **Per-task commit (after test/CSS step):** `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/brand_test.exs test/mailglass_admin/accessibility_test.exs`
- **Per-wave merge gate:** `cd mailglass_admin && mix verify.preview` (includes bundle rebuild + git-diff clean check)
- **Phase gate:** `cd mailglass_admin && mix verify.support_contract.admin` green before `/gsd:verify-work`

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Tailwind binary | `mix mailglass_admin.assets.build` (TOKEN-05) | ✅ | v4.1.12 (pinned in config.exs) | — |
| Jason | `token_parity_test.exs` oracle parsing | ✅ | `~> 1.4` (dep in mix.exs line 111, unrestricted :only) | — |
| bash + grep | Shell gate scripts | ✅ | macOS + Linux CI (ubuntu-latest) | — |
| `brandbook/tokens.css` + `tokens.json` | @import + oracle | ✅ | In-repo (current as of Phase 91) | — |

No missing dependencies. All runtime requirements satisfied.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | daisyUI v5 inlines `var(--mg-*)` references verbatim into `[data-theme=*]` selectors without resolving them at build time | Full Slot Mapping Table / test seams | If daisyUI resolves var() at build time, the `var(--mg-*)` references won't appear in the compiled CSS and the parity test's indirection-resolution approach breaks. D-01 says "empirically proven" that the pipeline compiles end-to-end, which implies vars are preserved verbatim — LOW risk. |
| A2 | The 43 `tracking-[0.08em]` count is exhaustive | Existing Violation Inventory | `wc -l` returned 43 from the grep. If additional tracking-[ patterns exist in files not matching `*.ex` or outside `lib/`, they won't be caught by the gate. Gate scope is correct (only `*.ex` in `lib/`). No risk to Phase 94. |
| A3 | `--color-info-content`, `--color-success-content`, `--color-warning-content`, `--color-error-content` are absent from current `app.css` | Full Slot Mapping Table | If they are present (perhaps later in the file or in a daisyUI default), the "Add" instruction becomes an "Update." The planner should grep the full `app.css` at task time — the file was read in full and no such slots were found. LOW risk. |

**All core factual claims (hex values, file paths, line numbers, gate regexes, test code) are VERIFIED by direct file read. Only A1-A3 above are ASSUMED.**

---

## Sources

### Primary (HIGH confidence)
- Direct read: `brandbook/tokens.css` — all `--mg-*` token values (light + dark)
- Direct read: `brandbook/tokens.json` — palette aliases + semantic color tier (W3C design-token format)
- Direct read: `mailglass_admin/assets/css/app.css` — all current `--color-*` slot assignments (both themes)
- Direct read: `mailglass_admin/scripts/check-conformance.sh` — five-gate script, regex patterns, WR-01..04 fixes
- Direct read: `scripts/check_motion_conformance.sh` — THRASH_PATTERN + EASE_PATTERN (current values)
- Direct read: `.github/workflows/ci.yml` lines 370-405, 576-634 — `credo_strict` + `support_contract_admin` jobs
- Direct read: `mailglass_admin/test/mailglass_admin/brand_test.exs` — compiled-bundle seam, literal-hex assertions
- Direct read: `mailglass_admin/test/mailglass_admin/accessibility_test.exs` — `contrast_ratio/2`, `luminance/1`, existing test cases
- Direct read: `mailglass_admin/test/mailglass_admin/bundle_test.exs` — message-style precedent, size assertions
- Direct read: `mailglass_admin/mix.exs` — `verify.support_contract.admin` alias, `:files`, `jason` dep
- Direct read: `mailglass_admin/config/config.exs` — Tailwind build config, cwd resolution
- Direct read: `.planning/phases/94-token-re-baseline-onto-canonical-brand/94-CONTEXT.md` — locked decisions D-01..D-10

### Secondary (MEDIUM confidence)
- `brandbook/brand-book.md` (read) — 10%-accent rule, border = decorative hairlines, dark-mode intent; validates D-03 role mapping rationale
- `.planning/REQUIREMENTS.md` (read) — TOKEN-01..05, RATCHET-03 definitions

---

## Metadata

**Confidence breakdown:**
- Full slot mapping table: HIGH — every value read directly from brandbook/tokens.css + tokens.json
- Gate edit points (regex): HIGH — read from existing scripts; regexes specified for extensions
- CI insertion points: HIGH — read from ci.yml with line numbers
- Test seam analysis: HIGH — read from test files; specific lines called out
- Contrast ratios: MEDIUM — estimated via WCAG formula (same as test does); exact values computed at runtime
- Advisory violation counts: HIGH — grep run on live codebase

**Research date:** 2026-06-13
**Valid until:** Stable (brandbook/tokens.css is the brand book; tokens.json mirrors it; neither changes in Phase 94). Re-verify if `brandbook/tokens.css` is edited before planning completes.
