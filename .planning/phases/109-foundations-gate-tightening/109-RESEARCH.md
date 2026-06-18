# Phase 109: foundations-gate-tightening - Research

**Researched:** 2026-06-18
**Domain:** mailglass_admin CSS token substrate, Phoenix HEEx conformance gates, ExUnit ratchet, Playwright structural accessibility
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied verbatim from `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md`. [VERIFIED: codebase read]

### Token-Layer Structure (FND-01, FND-02, FND-03)

- **D-01:** Tokens are **mostly already present** — this is a *tokenize-the-stragglers-and-tighten*
  job, not build-from-scratch. The type scale (`--text-label/body/heading/display`), spacing
  (`--spacing-xs..3xl`), elevation (`--shadow-flat/raised/overlay`), and easing tokens live in the
  `@theme` block (`mailglass_admin/assets/css/app.css:107-144`); durations
  (`--duration-instant/fast/reveal/flash`), control sizes, and a z-index tier set live in `:root`
  (`app.css:192-223`). **Net-new semantic tokens go into these existing blocks — do not create a
  parallel token source** (that triggers an override war, e.g. two definitions of `--text-heading`).

- **D-02:** **Color stays only in the daisyUI theme blocks** (`mailglass-light` default /
  `mailglass-dark` `prefersdark`) per the existing TOKEN-01 rule documented at `app.css:99-106`.
  No new color literals anywhere outside those blocks.

- **D-03 (FND-01, stale-research correction):** **Z-index tokens already exist** at
  `app.css:216-223` (`--z-sticky:10 / --z-dropdown:20 / --z-overlay:30 / --z-modal:40 /
  --z-toast:50`) — the v1.13 research's "no z-index tokens in app.css" claim is **stale/wrong**.
  The real FND-01 defect is they are **unconsumed**: HEEx uses literal Tailwind `z-*` utilities.
  Fix = (a) introduce the formal named layer system **including a `--z-overlay-scrim` vs
  `--z-overlay-panel` split and a `--z-base`** (today scrim+panel share one `z-40` band); (b)
  replace the three literal `z-*` usages in HEEx — `operator/replay_modal.ex:20` (scrim `z-40`),
  `inbound/replay_modal.ex:24` (scrim `z-40`), `components.ex:104` (toast `z-50`) — with
  token-driven classes; (c) the modal **panel** (currently no explicit z, stacks by source order
  only — the literal modal-behind-scrim fragility) gets the explicit panel layer; (d) add
  `isolation: isolate` on the mount root for host-safe stacking.

- **D-04 (FND-02, focus-ring):** The focus ring is currently an **un-tokenized string copy-pasted
  ~14×** (`focus-visible:ring-2 focus-visible:ring-primary` across `shell.ex`, `tabs.ex`,
  `sidebar.ex`, `deliveries_list.ex`, `gallery_live.ex`, `preview_live.ex`) plus a **divergent**
  idiom (`focus:outline focus:outline-2 focus:outline-offset-2` at `preview_live.ex:385`).
  Consolidate to a **single focus-ring token/utility** and converge both idioms — and do this
  **before** the FOCUS-RING-GATE is added so the gate proves green on current code (FND-05).

- **D-05 (FND-02):** Motion, elevation, and overlay values are likewise defined as semantic tokens
  resolving correctly in light/dark/system. Reuse/extend existing `--duration-*`/easing/`--shadow-*`
  tokens; only add what's genuinely missing (e.g. overlay-scrim color/opacity token if inlined).

### Gate-Tightening Mechanics (FND-05)

- **D-06:** New gates are **additional grep blocks in the existing
  `mailglass_admin/scripts/check-conformance.sh`**, following the established 6-gate pattern
  (BADGE/TYPE/BOLD/GAP/HEX/MOTION): shared `errors` counter, `--include="*.ex"`, scoped to
  `${SCRIPT_DIR}/../lib` via the `BASH_SOURCE` anchoring (cwd-independent — preserves the WR-02
  footgun guard). Add: **Z-INDEX gate** (no literal `z-*` in admin `lib/`), **FOCUS-RING gate**
  (no raw inline focus-ring string), **SCOPE/isolation gate**. **TYPE-GATE is *extended*** (not
  replaced) to also match `text-xl|2xl|3xl`. Do NOT add gates to a new script or with different
  scoping — CI invokes the existing script.

- **D-07 (ratchet schema → v3):** In `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs`:
  add `"system"` to the `@themes` attr (currently `["light","dark"]`, line ~28), bump the schema
  assertion `== 2` → `== 3` (line ~41), and update the derived cell-count math (3 surfaces × 6
  pillars × 3 themes). **Seed the new `system` cells in BOTH `prior` and `current` blocks** of
  `docs/ui-baseline-scores.json` (the comparator fails closed on `nil` cells), by **copying each
  surface's existing light-or-dark scores into the `system` slot** — system resolves to one of
  them — so **no cell regresses and no new pillar judgment is introduced this phase.** The real
  `system` re-score is deferred to Phase 116. (FND-05 says "ratchet schema bumped to include
  `system`" — the decisive reading is `system` as a 3rd theme axis, not viewport-structural-only.)

- **D-08 (WCAG 2.2 SC):** Add WCAG 2.2 success criteria as **additions to the existing structural
  matrix** in `mailglass_admin/e2e/structural.spec.js`, not a rewrite: an `elementFromPoint`
  **hit-test for opened overlays** (SC 2.4.11 / modal-above-scrim) is **net-new** (no
  `elementFromPoint`/`isolation`/`focus-not-obscured` assertion exists today); **target-size**
  (2.5.8, extend the existing `touch targets >= 44px` block ~`:286`) and **contrast** (1.4.11,
  extend `assertTextContrastAA`/`assertNonTextContrastAA` ~`:222/:232`) extend existing assertions.
  Add `emulateMedia({colorScheme})` for the system case (same shape as the existing
  `emulateMedia({reducedMotion})` at ~`:780`).

- **D-09 (FND-05 ordering — binding):** Every gate is tightened → **proven green on CURRENT code**
  → only then is the token layer re-baselined. No pillar re-score. If a gate would fail on current
  code, the underlying code is consolidated first (e.g. D-04 focus-ring before FOCUS-RING-GATE).

### System-Theme Plumbing (FND-04)

- **D-10:** The CSS-layer system-theme plumbing FND-04 requires is **already correct and in place**
  — `layouts/root.html.heex:2` emits `<html data-theme={root_theme(assigns)}>`; `layouts.ex:82-97`
  returns `mailglass-dark`/`mailglass-light` only for explicit `theme=dark|light` and `nil`
  otherwise, so `data-theme={nil}` emits **no attribute**, and daisyUI's `prefersdark: true` on the
  `mailglass-dark` block (`app.css:60-64`) resolves system via `prefers-color-scheme` — **no JS
  hook, no host-global CSS.** Phase 109 **proves and locks** this (a structural assertion + the
  SCOPE gate), it does **not** rebuild it. Do NOT add a `phx-hook` or a head script that
  force-sets `data-theme` for the system case (re-creates the DARK-LD-08 split-brain where OS
  changes stop tracking).

- **D-11 (scope hold):** The operator surface still carries a **2-state `dark_chrome?` boolean**
  (`?theme=dark` only, `operator/shell.ex`, `operator_live.ex`) that doesn't model `system`. Phase
  109 owns **only the token/CSS-layer system plumbing + the gate/structural proof** — it does NOT
  rebuild the toggle into a 3-way picker. The 3-way picker primitive is Phase 110; shell wiring is
  Phase 112. Hold this line to avoid pulling forward Phase 112's `surface_paths`/`build_path`
  plumbing that PR #86 just stabilized.

### REL-01 / PR #86 (precondition)

- **D-12:** REL-01 is satisfied by a **one-time admin-override merge of PR #86 into `main` BEFORE
  any Phase 109 code lands** — captured as the **first step of phase execution**, NOT done during
  discussion (user decision 2026-06-18). PR #86 (`fix/admin-preview-mount-aware-urls`) is verified
  OPEN, all 24 CI checks SUCCESS, `mergeable: MERGEABLE`, blocked **only** by review-required
  branch protection (`reviewDecision: ""`) — resolve with `gh pr merge 86 --admin` (the documented
  `enforce_admins:false` / `--admin` override). Foundation edits touch the same
  `shell.ex`/`layouts.ex`/`app.css`/`root.html.heex` regions #86 carries held fixes for, so merging
  first is mandatory to avoid conflicts and to honor the "build on the merged #86 baseline"
  precondition. Confirm main CI is green post-merge before the first uplift commit.

### the agent's Discretion

- Exact token names for the scrim/panel split and focus-ring (follow existing `--z-*`/`--text-*`
  naming convention in `app.css`).
- Whether the focus-ring becomes a CSS custom property + utility class or a Tailwind `@utility` —
  pick whichever the existing `app.css` structure makes cleanest.
- Exact placement of the new grep gates within `check-conformance.sh` (preserve the shared counter).

### Deferred Ideas (OUT OF SCOPE)

- **3-way system/light/dark picker UI** — Phase 110 (primitive) + Phase 112 (shell wiring). Phase
  109 is CSS-layer plumbing + proof only.
- **`@axe-core/playwright` JSON baseline + the one test-only npm devDep** — Phase 116 (ratchet-arm).
- **Multi-tenant stress-fixture cohort** — Phase 116 (the keystone proving substrate).
- **Full pillar re-score** — Phase 116 only.
- **Operator `dark_chrome?` → tri-state reconciliation in the UI** — Phase 112.

### Reviewed Todos (not folded)
None — `todo.match-phase 109` returned 0 matches.

## Project Constraints

No `AGENTS.md` exists at the project root, and no project-local `.codex/skills` or `.agents/skills` files were found. [VERIFIED: shell check]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | PR #86 is merged into `main` before uplift work begins. | Treat as the first execution gate; GitHub currently reports PR #86 OPEN, mergeable, all PR checks success, and `reviewDecision` empty, so it is not satisfied until the PR is merged and main CI is rechecked. [VERIFIED: `gh pr view 86`; VERIFIED: `gh run list`] |
| FND-01 | Formal z-index layer system consumed by every stacking context; no literal `z-*` in admin `lib/`. | Existing `--z-*` tokens are present but unconsumed; literal `z-40` appears in both replay scrims and `z-50` in `Components.flash/1`. [VERIFIED: `app.css`; VERIFIED: `rg z-*`] |
| FND-02 | Motion, elevation, focus-ring, overlay values are semantic tokens resolving in light/dark/system. | Motion/elevation tokens exist; focus-ring is duplicated in HEEx and must be consolidated before the gate. [VERIFIED: `app.css`; VERIFIED: `rg focus-visible`] |
| FND-03 | Type-scale, spacing, radius, shadow, border token coverage audited complete. | Current hard conformance/advisory gates are clean; Phase 109 should extend TYPE and spacing coverage without replacing the script. [VERIFIED: `bash check-conformance.sh`; VERIFIED: `bash check-conformance-advisory.sh`] |
| FND-04 | System-theme plumbing exists at CSS/token layer with no JS hook and no picker UI. | Root layout and CSS theme blocks already support explicit light/dark and nil/system at the root; operator 3-way UI is deliberately deferred. [VERIFIED: `layouts.ex`; VERIFIED: `root.html.heex`; CITED: https://daisyui.com/docs/config/?lang=en] |
| FND-05 | Gates tightened first and proven green; ratchet schema includes `system`; WCAG 2.2 structural additions. | Existing conformance, ratchet, and Playwright seams are in place; ratchet is currently schema v2 with `["light","dark"]`; Playwright has existing contrast, target-size, reduced-motion, focus, and gallery tests to extend. [VERIFIED: `ratchet_baseline_test.exs`; VERIFIED: `structural.spec.js`] |

## Summary

Phase 109 should be planned as a foundation/gate phase, not a visible redesign phase. The implementation-ready path is: satisfy REL-01 first, extend the existing token blocks in `app.css`, migrate the few literal z-index call sites to semantic layer classes, consolidate focus-ring styling, then add fail-closed grep gates in `check-conformance.sh` using the existing `errors` counter and `LIB` scoping. [VERIFIED: `109-CONTEXT.md`; VERIFIED: `app.css`; VERIFIED: `check-conformance.sh`]

The stale assumption to avoid is "there are no z-index tokens." Existing `:root` tokens define `--z-sticky`, `--z-dropdown`, `--z-overlay`, `--z-modal`, and `--z-toast`; the defect is that they are not consumed and they do not split scrim from panel. The safe migration is to add the formal layer vocabulary, keep compatibility aliases if useful, and replace only the three literal HEEx `z-*` classes before adding the Z-INDEX gate. [VERIFIED: `app.css:216-223`; VERIFIED: `rg '\bz-*' mailglass_admin/lib`]

No package install belongs in this phase. WCAG 2.2 and system-theme proof should extend the existing structural Playwright suite and CSS/root-theme behavior only. `@axe-core/playwright`, the axe JSON baseline, the 3-way picker UI, and the full pillar re-score are explicitly later-phase work. [VERIFIED: `109-CONTEXT.md`; CITED: https://playwright.dev/docs/emulation; CITED: https://www.w3.org/TR/WCAG22/]

**Primary recommendation:** Plan Phase 109 as three ordered slices: REL-01 merge verification, token/class consolidation, then gate/ratchet/structural-test tightening with no pillar re-score. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| REL-01 merge and main CI gate | SCM / CI | Local workspace | PR #86 is an upstream baseline precondition and must be resolved before local uplift commits. [VERIFIED: `gh pr view 86`; VERIFIED: `.planning/REQUIREMENTS.md`] |
| Token definitions | CSS / Static asset layer | Phoenix HEEx consumers | `app.css` owns theme-independent sizes/elevation/easing and `:root` owns motion/control/z variables. [VERIFIED: `app.css`] |
| Z-index layer consumption | CSS / Static asset layer | Phoenix HEEx | Layer values should be CSS variables/classes; HEEx should consume semantic classes and stop carrying literal `z-*`. [VERIFIED: `app.css`; VERIFIED: `rg z-*`] |
| Focus-ring consolidation | CSS / Static asset layer | Phoenix HEEx | A shared utility/token should own focus appearance; HEEx should opt into it without duplicating raw ring strings. [VERIFIED: `rg focus-visible`] |
| Conformance gates | CI shell gate | Source tree | `check-conformance.sh` is already wired in CI and scans `mailglass_admin/lib` cwd-independently. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `check-conformance.sh`] |
| Ratchet schema v3 | ExUnit / JSON docs | CI | `ratchet_baseline_test.exs` owns schema/cell coverage and fails closed on missing or regressed cells. [VERIFIED: `ratchet_baseline_test.exs`] |
| Structural WCAG 2.2 proof | Playwright browser tests | CSS/HEEx | Existing structural tests already measure computed contrast, target sizes, focus visibility, reduced motion, and modal ARIA. [VERIFIED: `structural.spec.js`] |
| System-theme proof | CSS/root layout | Playwright | daisyUI `prefersdark` handles dark default when no explicit theme is set; Playwright can emulate `colorScheme` for system checks. [VERIFIED: `app.css`; CITED: https://daisyui.com/docs/config/?lang=en; CITED: https://playwright.dev/docs/emulation] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Phoenix LiveView | 1.1.28 locked | Renders operator/inbound/preview/gallery LiveViews and HEEx. | Existing admin architecture is stateless Phoenix.Component plus LiveView state owners. [VERIFIED: `mailglass_admin/mix.lock`; VERIFIED: `.planning/research/v1.13/ARCHITECTURE.md`] |
| Tailwind Hex wrapper | 0.4.1 locked | Runs the standalone Tailwind asset build that compiles `app.css` to committed `priv/static/app.css`. | Existing zero-Node asset pipeline and bundle-clean gate depend on this path. [VERIFIED: `mailglass_admin/mix.lock`; VERIFIED: `mailglass_admin/mix.exs`] |
| Tailwind standalone binary | v4.1.12 per CSS comment | Inlines `brandbook/tokens.css`, Tailwind v4 `@theme`, daisyUI plugins, and admin source classes. | Existing `app.css` is authored for Tailwind v4 syntax and source scanning. [VERIFIED: `app.css`] |
| Vendored daisyUI JS plugins | fetched 2026-04-24 from latest release URLs | Provides daisyUI base/theme plugin behavior, including custom theme blocks in `app.css`. | Existing CSS uses `@plugin "../vendor/daisyui"` and `@plugin "../vendor/daisyui-theme"`. [VERIFIED: `assets/vendor/daisyui.js`; VERIFIED: `assets/vendor/daisyui-theme.js`] |
| Playwright Test | 1.59.1 resolved | Runs the structural browser suite. | Existing operator browser gate runs Playwright via `npm run test:operator-browser`. [VERIFIED: `package-lock.json`; VERIFIED: `.github/workflows/ci.yml`] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `check-conformance.sh` | local script | Hard-fail design-system grep gates. | Extend for Z-INDEX, FOCUS-RING, SCOPE/isolation, and wider TYPE/SPACING checks. [VERIFIED: `check-conformance.sh`] |
| `ratchet_baseline_test.exs` | local ExUnit test | Validates score-baseline schema, coverage, range, and only-forward comparison. | Bump to schema v3 and `@themes ["light","dark","system"]`. [VERIFIED: `ratchet_baseline_test.exs`] |
| `structural.spec.js` | local Playwright spec | Runtime structural/a11y assertions without screenshots. | Add system-theme and WCAG 2.2 structural checks here, not in a new axe phase. [VERIFIED: `structural.spec.js`] |
| GitHub CLI | 2.94.0 local | PR #86 and main CI precondition checks. | Use before uplift commits and after admin merge. [VERIFIED: local command; VERIFIED: `gh pr view 86`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Playwright structural suite | `@axe-core/playwright` | Deferred to Phase 116 by user constraint; adding it now violates Phase 109 scope. [VERIFIED: `109-CONTEXT.md`] |
| Semantic CSS utility classes for z/focus | Tailwind arbitrary classes like `z-[var(--z-toast)]` | Arbitrary `z-*` defeats a simple Z-INDEX grep gate; named CSS classes let the gate ban all literal `z-*` in HEEx. [VERIFIED: `check-conformance.sh` pattern style] |
| Existing `check-conformance.sh` | A new script | CI already invokes the existing script; new script risks a dead gate. [VERIFIED: `.github/workflows/ci.yml`] |

**Installation:** No install for Phase 109. [VERIFIED: `109-CONTEXT.md`]

```bash
# Phase 109 should not add dependencies.
# Do not install @axe-core/playwright in this phase.
```

## Package Legitimacy Audit

No external package is installed in Phase 109, so the Package Legitimacy Gate is not applicable. `@axe-core/playwright` is explicitly deferred to Phase 116. [VERIFIED: `109-CONTEXT.md`; VERIFIED: `.planning/REQUIREMENTS.md`]

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no Phase 109 package install]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no Phase 109 package install]

## Architecture Patterns

### System Architecture Diagram

```text
REL-01 GitHub precondition
  -> merge PR #86 into main
  -> confirm main CI / required checks green
  -> Phase 109 local uplift begins
      -> app.css token extension
          -> z layer + focus + overlay utilities
      -> HEEx class migration
          -> replay scrims, replay panels, toast, focusable controls, shell roots
      -> asset rebuild if CSS/classes change
      -> hard gates
          -> check-conformance.sh
          -> ratchet_baseline_test.exs schema v3
          -> structural.spec.js WCAG/system additions
      -> prove current code green
      -> no pillar re-score until Phase 116
```

### Recommended Project Structure

```text
mailglass_admin/
├── assets/css/app.css                         # existing token source; add z/focus/overlay utility classes here
├── lib/mailglass_admin/components.ex          # toast layer consumer
├── lib/mailglass_admin/operator/replay_modal.ex
├── lib/mailglass_admin/inbound/replay_modal.ex
├── lib/mailglass_admin/operator/shell.ex      # operator mount root and duplicated focus consumers
├── lib/mailglass_admin/layouts.ex
├── lib/mailglass_admin/layouts/root.html.heex # root system-theme proof surface
├── scripts/check-conformance.sh               # add hard gates in existing counter style
├── test/mailglass_admin/ratchet_baseline_test.exs
├── docs/ui-baseline-scores.json
└── e2e/structural.spec.js                     # add system/WCAG structural checks
```

### Pattern 1: Tokenize Before Gate

**What:** Migrate current violations or duplications to semantic tokens/classes first, then add the grep gate. [VERIFIED: `109-CONTEXT.md`]

**When to use:** Use this for z-index and focus-ring gates because current code has known literal z classes and raw focus copies. [VERIFIED: `rg z-*`; VERIFIED: `rg focus-visible`]

**Example:**

```css
/* Source: app.css token pattern plus Phase 109 contract */
:root {
  --z-base: 0;
  --z-overlay-scrim: 30;
  --z-overlay-panel: 40;
  --z-toast: 50;
}

.mg-z-overlay-scrim { z-index: var(--z-overlay-scrim); }
.mg-z-overlay-panel { z-index: var(--z-overlay-panel); }
.mg-z-toast { z-index: var(--z-toast); }
```

### Pattern 2: Shared Focus Utility

**What:** Replace raw `focus-visible:ring-2 focus-visible:ring-primary` and `focus:outline...` class strings with a reusable utility such as `mg-focus-ring` and a documented inset variant. [VERIFIED: `rg focus-visible`; VERIFIED: `preview_live.ex:385`]

**When to use:** Use `mg-focus-ring` for normal focusable elements; use the inset variant only where offset rings clip inside full-width row/tab boundaries. [VERIFIED: `.planning/STATE.md` ring-inset decisions]

**Example:**

```css
/* Source: Phase 109 UI-SPEC focus-ring contract */
.mg-focus-ring:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
  transition-duration: var(--duration-instant);
}

.mg-focus-ring-inset:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: -2px;
  transition-duration: var(--duration-instant);
}
```

### Pattern 3: Existing Gate Style

**What:** Add grep blocks to `check-conformance.sh` using the existing `errors` counter, `"$LIB"`, `--include="*.ex"`, and fail-loud final exit. [VERIFIED: `check-conformance.sh`]

**When to use:** Use this for Z-INDEX, FOCUS-RING, and SCOPE/isolation gates. [VERIFIED: `109-CONTEXT.md`]

**Example:**

```bash
# Source: check-conformance.sh existing gate style
if grep -rEn '\\bz-([0-9]+|\\[[^]]+\\])\\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: Z-INDEX-GATE - literal z-index utility found (use semantic layer classes)" >&2
  errors=$((errors + 1))
fi
```

### Anti-Patterns to Avoid

- **Creating a parallel token source:** `app.css` already owns the structural token blocks; a second token file creates override ambiguity. [VERIFIED: `app.css`; VERIFIED: `109-CONTEXT.md`]
- **Adding the focus gate before migration:** current code has many raw focus class copies, so the gate would fail on the baseline. [VERIFIED: `rg focus-visible`]
- **Using arbitrary `z-[...]` classes:** this preserves the literal z-index class shape the gate is meant to remove. [VERIFIED: `109-CONTEXT.md`]
- **Adding axe in this phase:** axe JSON baseline and dependency are Phase 116, not Phase 109. [VERIFIED: `109-CONTEXT.md`]
- **Adding JS theme hooks or a 3-way picker:** Phase 109 proves CSS/root plumbing only; UI picker work is later. [VERIFIED: `109-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stacking order | Ad hoc `z-40`/`z-50` per component | Formal CSS variable layers plus semantic classes | Prevents scrim/panel collisions and enables a simple grep gate. [VERIFIED: `rg z-*`; VERIFIED: `109-UI-SPEC.md`] |
| Focus ring style | Per-call-site Tailwind focus strings | Shared focus utility/token | Prevents copy drift and makes gate tightening green. [VERIFIED: `rg focus-visible`] |
| Structural a11y scan | A new browser/a11y runner | Existing `structural.spec.js` | Current suite already has computed contrast, target-size, focus, reduced-motion, and modal ARIA seams. [VERIFIED: `structural.spec.js`] |
| Ratchet schema migration | One-off JSON edits without test updates | Update `@themes`, schema assertion, messages, and both JSON blocks together | Comparator fails closed on missing cells. [VERIFIED: `ratchet_baseline_test.exs`] |
| PR baseline management | Local cherry-picks around #86 | Merge PR #86 into main first, then uplift | Foundation files overlap with #86 tenant/theme fixes; PR is the binding baseline. [VERIFIED: `gh pr view 86`; VERIFIED: `109-CONTEXT.md`] |

**Key insight:** Phase 109 is mostly about making existing machinery stricter after consolidating current drift; custom one-off fixes undermine the gates that this phase is supposed to arm. [VERIFIED: `.planning/research/v1.13/SUMMARY.md`; VERIFIED: `check-conformance.sh`]

## Common Pitfalls

### Pitfall 1: Treating Z-Index As Missing Instead Of Unconsumed

**What goes wrong:** Planner creates new z tokens from scratch while leaving old `--z-overlay`/`--z-modal` semantics and HEEx literals in place. [VERIFIED: `app.css`; VERIFIED: `rg z-*`]

**Why it happens:** v1.13 pitfalls research contained a stale "no z-index tokens" claim, corrected by Phase 109 context. [VERIFIED: `109-CONTEXT.md`]

**How to avoid:** Extend the existing `:root` z tier block with `--z-base`, `--z-overlay-scrim`, and `--z-overlay-panel`; retain old names as aliases only if useful; migrate the three literal call sites before adding the gate. [VERIFIED: `109-CONTEXT.md`]

**Warning signs:** `z-40`, `z-50`, or `z-[...]` remains in `mailglass_admin/lib`. [VERIFIED: `rg z-*`]

### Pitfall 2: Focus Gate Before Focus Consolidation

**What goes wrong:** A new FOCUS-RING gate fails immediately on baseline code. [VERIFIED: `rg focus-visible`]

**Why it happens:** Raw focus-ring strings are duplicated across operator, preview, and gallery modules; `preview_live.ex` also uses a divergent `focus:outline...` idiom. [VERIFIED: `rg focus-visible`; VERIFIED: `preview_live.ex:385`]

**How to avoid:** Add the focus utility first, migrate raw strings, then add a gate that bans the old strings and divergent outline idiom. [VERIFIED: `109-CONTEXT.md`]

**Warning signs:** `focus-visible:ring-2 focus-visible:ring-primary`, `focus:outline`, `focus:outline-2`, or `focus:outline-primary` remains in HEEx. [VERIFIED: `rg focus-visible`]

### Pitfall 3: Re-Scoring While Adding `system`

**What goes wrong:** A full pillar re-score happens in Phase 109, changing the ratchet floor before the new gates are armed. [VERIFIED: `.planning/research/v1.13/PITFALLS.md`; VERIFIED: `109-CONTEXT.md`]

**Why it happens:** `system` is a new axis, so it can be mistaken for new subjective scoring work. [VERIFIED: `ratchet_baseline_test.exs`; VERIFIED: `ui-baseline-scores.json`]

**How to avoid:** Bump schema to v3, add `system` to `@themes`, and seed `system` cells in both `prior` and `current` by copying the existing per-block score values; leave full judgement to Phase 116. [VERIFIED: `109-CONTEXT.md`]

**Warning signs:** Changed pillar scores, new run IDs without a Phase 116 score procedure, or missing `system` cells in either block. [VERIFIED: `ratchet_baseline_test.exs`]

### Pitfall 4: Expanding Scope Into Theme UI

**What goes wrong:** Phase 109 pulls in the 3-way picker, cookie persistence, or JS theme hook. [VERIFIED: `109-CONTEXT.md`]

**Why it happens:** FND-04 mentions `system`, but Phase 109 owns CSS/root plumbing proof only. [VERIFIED: `109-CONTEXT.md`; VERIFIED: `109-UI-SPEC.md`]

**How to avoid:** Prove no explicit root `data-theme` for system/default and prove `prefersdark` through Playwright media emulation; defer picker/UI reconciliation to Phases 110/112. [VERIFIED: `layouts.ex`; CITED: https://daisyui.com/docs/config/?lang=en; CITED: https://playwright.dev/docs/emulation]

**Warning signs:** New `phx-hook`, new head script, localStorage/cookie theme persistence, or visible System/Light/Dark control in Phase 109. [VERIFIED: `109-CONTEXT.md`]

### Pitfall 5: Treating WCAG 2.2 As Axe-Only

**What goes wrong:** Planner adds `@axe-core/playwright` early, violating Phase 109 scope. [VERIFIED: `109-CONTEXT.md`]

**Why it happens:** v1.13 milestone-level stack research approves axe for the milestone, but Phase 109 explicitly defers that dependency to Phase 116. [VERIFIED: `.planning/research/v1.13/STACK.md`; VERIFIED: `109-CONTEXT.md`]

**How to avoid:** Add structural checks for 2.4.11 focus not obscured, 2.5.8 target size, and existing 1.4.11/focus appearance contrast using Playwright DOM/computed-style assertions. [CITED: https://www.w3.org/TR/WCAG22/; VERIFIED: `structural.spec.js`]

**Warning signs:** `package.json` or `package-lock.json` changes that add axe during Phase 109. [VERIFIED: no Phase 109 install scope]

## Code Examples

Verified patterns from existing sources:

### Current Gate Counter Style

```bash
# Source: mailglass_admin/scripts/check-conformance.sh
errors=0

if grep -rEn 'text-(sm|xs)\b|text-base($|[^-])' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TYPE-GATE - raw text-scale utility found" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  exit 1
fi
```

### Current Ratchet Shape

```elixir
# Source: mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
@surfaces ["deliveries", "inbound", "preview"]
@pillars ["Spacing", "Radius", "Color", "Type", "Elevation", "Motion+A11y"]
@themes ["light", "dark"]
```

### Current Playwright Media Pattern

```javascript
// Source: mailglass_admin/e2e/structural.spec.js + Playwright docs
await page.emulateMedia({ reducedMotion: "reduce" });
await openOperator(page);
```

Phase 109 should use the same pattern with `colorScheme` before navigation for system-theme checks. [CITED: https://playwright.dev/docs/emulation]

```javascript
await page.emulateMedia({ colorScheme: "dark" });
await openPreviewScenario(page, "");
```

### Overlay Hit-Test Pattern

```javascript
// Source: Phase 109 UI-SPEC + WCAG 2.4.11 structural strategy
const modal = page.getByTestId("inbound-replay-modal");
const box = await modal.boundingBox();
const topElementTestId = await page.evaluate(({ x, y }) => {
  const el = document.elementFromPoint(x, y);
  return el && el.closest("[data-testid]") && el.closest("[data-testid]").dataset.testid;
}, { x: box.x + box.width / 2, y: box.y + box.height / 2 });

expect(topElementTestId).toBe("inbound-replay-modal");
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Literal z-index utilities on overlays/toasts | Semantic z-index variables plus HEEx migration target | Phase 109 target | Makes modal-above-scrim and Z-INDEX gate deterministic. [VERIFIED: `109-UI-SPEC.md`] |
| Raw copied focus-ring class strings | Shared focus-ring utility/token | Phase 109 target | Enables FOCUS-RING gate and reduces drift. [VERIFIED: `rg focus-visible`] |
| Ratchet schema v2, 36 cells per block | Ratchet schema v3, 54 cells per block after adding `system` | Phase 109 target | Adds system axis without re-scoring. [VERIFIED: `ratchet_baseline_test.exs`; VERIFIED: `109-CONTEXT.md`] |
| WCAG 2.1-ish structural coverage | WCAG 2.2 structural additions in existing Playwright suite | Phase 109 target | Adds focus-not-obscured and target-size proof before axe baseline phase. [CITED: https://www.w3.org/TR/WCAG22/; VERIFIED: `structural.spec.js`] |

**Deprecated/outdated:**
- "No z-index tokens exist in app.css" is stale; tokens exist but are unconsumed and incomplete for scrim/panel split. [VERIFIED: `app.css`; VERIFIED: `109-CONTEXT.md`]
- Adding `@axe-core/playwright` in Phase 109 is out of scope; it belongs to Phase 116. [VERIFIED: `109-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The local GSD `research-plan` and `classify-confidence` seams are unavailable, so confidence is assigned from direct source hierarchy rather than seam output. [ASSUMED after tool failure] | Sources / Metadata | Low; official docs and repo-local evidence still support implementation planning, but the GSD cache was not populated. |

## Open Questions

1. **Post-merge main CI definition for REL-01**
   - What we know: PR #86 is currently open and mergeable with successful PR checks; main has a scheduled `repo-hygiene` failure, and the required branch-protection check is `guard-release-trigger`. [VERIFIED: `gh pr view 86`; VERIFIED: `gh run list`; VERIFIED: `gh api branches/main`]
   - What's unclear: Which exact non-required main lanes the executor should treat as "main CI green" after the admin merge if scheduled advisory/hygiene lanes remain red. [ASSUMED]
   - Recommendation: Planner should add an explicit REL-01 checkpoint: merge PR #86, then verify required branch protection plus the latest `CI` workflow run for the merge SHA; document any scheduled advisory failure separately before uplift. [VERIFIED: `.planning/REQUIREMENTS.md`]

2. **Exact focus utility implementation**
   - What we know: raw focus strings and one outline idiom must converge before the FOCUS-RING gate. [VERIFIED: `rg focus-visible`]
   - What's unclear: Whether the final utility should be outline-based plain CSS or Tailwind `@utility`.
   - Recommendation: Use plain CSS classes in `app.css` unless implementation proves Tailwind `@utility` is cleaner; either way, HEEx consumes one semantic class plus a documented inset variant. [VERIFIED: `109-CONTEXT.md`]

3. **Local dependency state before ExUnit verification**
   - What we know: `bash check-conformance.sh` and advisory gate are clean; `mix test test/mailglass_admin/ratchet_baseline_test.exs` did not start because local `floki` and `premailex` deps are stale against the lock. [VERIFIED: local command]
   - What's unclear: Whether the executor will run after PR #86 merge and `mix deps.get`, which should refresh local dependency state.
   - Recommendation: Planner should put dependency refresh before ExUnit verification, without treating it as a Phase 109 product change. [VERIFIED: local command]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| GitHub CLI `gh` | REL-01 PR/CI verification | yes | 2.94.0 | GitHub web UI/API manual check. [VERIFIED: local command] |
| Node.js | Playwright structural tests | yes | 22.14.0 local; CI uses Node 22 | CI runner. [VERIFIED: local command; VERIFIED: `.github/workflows/ci.yml`] |
| npm | Playwright install/run | yes | 11.1.0 | CI `npm ci`. [VERIFIED: local command] |
| Playwright CLI | Structural browser tests | yes | 1.59.1 | CI operator browser gate. [VERIFIED: `npx playwright --version`] |
| Elixir/Mix | ExUnit, assets, conformance aliases | yes | Elixir 1.19.5 / OTP 28 local; CI uses Elixir 1.18 / OTP 27 | CI matrix. [VERIFIED: local command; VERIFIED: `.github/workflows/ci.yml`] |
| PostgreSQL | Browser/admin tests | yes | `/tmp:5432` accepting connections | CI Postgres service. [VERIFIED: `pg_isready`; VERIFIED: `.github/workflows/ci.yml`] |
| Docker | Demo/main evidence if needed | yes | 29.5.2 | Not required for Phase 109 core validation. [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: environment probes]

**Missing dependencies with fallback / caveats:**
- Local admin deps are stale for `floki` and `premailex`; run `cd mailglass_admin && mix deps.get` before ExUnit validation. [VERIFIED: failed ratchet test command]
- `package.json` says `@playwright/test ^1.59.1`, while package-lock root metadata still says `^1.54.2` even though the resolved package is 1.59.1; do not change this in Phase 109 unless npm install becomes necessary. [VERIFIED: `package.json`; VERIFIED: `package-lock.json`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| ExUnit | Mix/ExUnit via `mailglass_admin/mix.exs`. [VERIFIED: `mix.exs`] |
| Browser | Playwright Test 1.59.1 via `mailglass_admin/package-lock.json`. [VERIFIED: `package-lock.json`] |
| Config file | `mailglass_admin/playwright.config.cjs`. [VERIFIED: codebase grep] |
| Quick run command | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` [VERIFIED: existing files] |
| Full suite command | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` [VERIFIED: `mailglass_admin/mix.exs`; VERIFIED: `package.json`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| REL-01 | PR #86 merged into main and post-merge CI green before uplift. | SCM/CI checkpoint | `gh pr view 86 --json state,mergedAt,mergeable,reviewDecision,statusCheckRollup` and `gh run list --workflow CI --branch main --limit 1` | yes, external CLI |
| FND-01 | Literal z-index classes removed; modal panel hit-tests above scrim. | grep + Playwright | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && npm run test:operator-browser -- --grep "replay modal"` | yes, needs extension |
| FND-02 | Focus, motion, elevation, overlay values use semantic tokens/classes. | grep + browser computed style | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && npm run test:operator-browser -- --grep "visible focus"` | yes, needs extension |
| FND-03 | Type/spacing/radius/shadow/border one-offs blocked. | grep + bundle | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix verify.preview` | yes, needs extension |
| FND-04 | System theme is proven at CSS/root layer with no JS hook/picker. | ExUnit + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors`; `cd mailglass_admin && npm run test:operator-browser -- --grep "system"` | yes, needs extension |
| FND-05 | Ratchet schema v3 includes `system`; tightened gates prove green. | ExUnit + shell + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors`; `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && npm run test:operator-browser` | yes, needs extension |

### Sampling Rate

- **Per task commit:** run the focused gate touched by the task: conformance for grep/token tasks, ratchet test for schema JSON, or Playwright `--grep` for structural additions. [VERIFIED: existing scripts]
- **Per wave merge:** `cd mailglass_admin && mix verify.support_contract.admin` plus `bash mailglass_admin/scripts/check-conformance.sh`. [VERIFIED: `mailglass_admin/mix.exs`; VERIFIED: `.github/workflows/ci.yml`]
- **Phase gate:** `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`, after dependency refresh and PR #86 merge. [VERIFIED: `mailglass_admin/mix.exs`; VERIFIED: `package.json`]

### Wave 0 Gaps

- [ ] Extend `mailglass_admin/scripts/check-conformance.sh` with Z-INDEX, FOCUS-RING, SCOPE/isolation, and wider TYPE/SPACING gates. [VERIFIED: current script exists]
- [ ] Extend `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` and `mailglass_admin/docs/ui-baseline-scores.json` to schema v3/system. [VERIFIED: current files exist]
- [ ] Extend `mailglass_admin/e2e/structural.spec.js` with system theme, WCAG 2.2 focus-not-obscured/target-size, and modal hit-test assertions. [VERIFIED: current file exists]
- [ ] Refresh local deps before ExUnit validation if the same lock mismatch appears. [VERIFIED: local command]

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct change | Phase 109 does not alter auth, but REL-01 PR must preserve existing operator auth tests. [VERIFIED: scope files] |
| V3 Session Management | no direct change | Do not add theme cookies/storage or JS hooks in this phase. [VERIFIED: `109-CONTEXT.md`] |
| V4 Access Control | yes, guardrail | Preserve tenant scope carried by PR #86; do not bypass core read models or host auth. [VERIFIED: `109-CONTEXT.md`; VERIFIED: `operator/shell.ex`] |
| V5 Input Validation | yes, structural | Gate regexes must be scoped to `mailglass_admin/lib/*.ex` and avoid false positives like `text-base-content`. [VERIFIED: `check-conformance.sh`] |
| V6 Cryptography | no | No cryptographic behavior changes. [VERIFIED: Phase 109 scope] |
| V14 Configuration | yes | CI/gate configuration must fail closed and use existing CI-invoked scripts. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `check-conformance.sh`] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Host CSS/stacking collision in mountable admin | Tampering / Denial of Service | Add scoped `isolation: isolate` on admin shell roots and avoid host-global CSS/JS. [VERIFIED: `109-CONTEXT.md`] |
| Cross-tenant navigation losing scope | Information Disclosure | REL-01 merge first; preserve `tenant_id` across surfaces and do not regress PR #86. [VERIFIED: `gh pr view 86`; VERIFIED: `109-CONTEXT.md`] |
| Dead conformance gate due cwd mismatch | Tampering | Preserve `BASH_SOURCE`-anchored `LIB` and shared `errors` counter. [VERIFIED: `check-conformance.sh`] |
| Regex false positives/false negatives | Tampering | Use boundary-aware grep patterns like current TYPE/GAP gates. [VERIFIED: `check-conformance.sh`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` - locked decisions, deferred scope, and code context. [VERIFIED: codebase read]
- `.planning/phases/109-foundations-gate-tightening/109-UI-SPEC.md` - z-index, focus, gate, and phase-scope contracts. [VERIFIED: codebase read]
- `.planning/REQUIREMENTS.md` - REL-01 and FND-01..05 acceptance criteria. [VERIFIED: codebase read]
- `.planning/ROADMAP.md` and `.planning/STATE.md` - v1.13 order, REL-01 sequencing, no-re-score rule. [VERIFIED: codebase read]
- `mailglass_admin/assets/css/app.css` - token blocks, daisyUI theme blocks, motion and z-tier variables. [VERIFIED: codebase read]
- `mailglass_admin/scripts/check-conformance.sh` - existing hard gate style and scoping. [VERIFIED: codebase read]
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` and `mailglass_admin/docs/ui-baseline-scores.json` - schema v2 and 36-cell shape. [VERIFIED: codebase read]
- `mailglass_admin/e2e/structural.spec.js` - Playwright structural test seams. [VERIFIED: codebase read]
- GitHub PR #86 via `gh pr view 86` - current PR state, checks, and mergeability as of 2026-06-18. [VERIFIED: GitHub CLI]

### Secondary (MEDIUM confidence)

- daisyUI docs - `--prefersdark` marks a theme as the dark-mode default. [CITED: https://daisyui.com/docs/config/?lang=en]
- Playwright docs - `colorScheme` / `page.emulateMedia()` emulate `prefers-color-scheme` with light/dark values. [CITED: https://playwright.dev/docs/emulation]
- W3C WCAG 2.2 - new criteria include 2.4.11 Focus Not Obscured, 2.4.13 Focus Appearance, and 2.5.8 Target Size. [CITED: https://www.w3.org/TR/WCAG22/]
- W3C Understanding 2.4.11 - modal/focus content should not obscure focused components. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html]

### Tertiary (LOW confidence)

- GSD `research-plan` and `classify-confidence` seams were attempted but unavailable in this environment: global `gsd-tools` lacked the commands, and the explicit Codex copy failed due a missing `package.json` artifact. [VERIFIED: local command failure]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current versions and tools were verified from lockfiles, Mix deps, local commands, and workflow files. [VERIFIED: `mix.lock`; VERIFIED: `package-lock.json`; VERIFIED: local commands]
- Architecture: HIGH - all implementation seams are repo-local and directly inspected. [VERIFIED: codebase reads]
- Pitfalls: HIGH - literal z-index and focus duplication are confirmed by grep; scope boundaries are locked in Phase 109 context. [VERIFIED: `rg z-*`; VERIFIED: `rg focus-visible`; VERIFIED: `109-CONTEXT.md`]
- External standards: MEDIUM - official docs were read directly, but the GSD confidence classifier seam was unavailable. [CITED: daisyUI/Playwright/W3C docs]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for repo-local planning assumptions; recheck PR #86 and GitHub CI immediately before execution because those are time-sensitive. [VERIFIED: current date; VERIFIED: GitHub CLI]
