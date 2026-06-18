#!/usr/bin/env bash
# Fail CI if any design-system violation appears in mailglass_admin/lib/*.ex files.
# Design-system conformance check — initial gate definitions committed at Phase 76-06.
# Sources: VERIF-03 (Phase 79), D-07 (single source of truth for visual decisions).
# Gate patterns from 76-06-SUMMARY.md: five greps that confirmed zero violations on
# the Phase 76 codebase. All gates scope to .ex files only (HEEx lives in LiveView modules;
# no .heex partials exist in this codebase).
#
# Footgun-6 exclusion (TYPE-GATE): text-base-content is a DaisyUI semantic color token
# (base-content text color), not a raw type-scale utility. Without the exclusion, every
# file using text-base-content produces a false failure on the text-base pattern.

set -euo pipefail

# Resolve LIB relative to this script's own location, not the caller's cwd.
# mailglass_admin is its own Hex package; its CI lane may run with cwd at the
# package root (mailglass_admin/) rather than the monorepo root. A cwd-relative
# path would resolve to a non-existent dir, grep would print to the swallowed
# stderr and exit non-zero, no error would be counted, and the script would
# print "clean" while scanning zero files (WR-02). Anchoring to BASH_SOURCE and
# asserting the dir exists makes the gate cwd-independent and fail-loud.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
errors=0

# BADGE-GATE: defp badge_class must not exist anywhere in lib/.
# Components.status_badge/1 is the single canonical status→color definition (Phase 76-02).
# Any private badge_class helper is a divergence point and must be routed through it.
if grep -rE 'defp badge_class' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BADGE-GATE — defp badge_class found; route through Components.status_badge/1" >&2
  errors=$((errors + 1))
fi

# TYPE-GATE: raw Tailwind type-scale utilities in HEEx
# (text-sm, text-base, text-xs, text-xl, text-2xl, text-3xl).
# Use semantic tokens instead: text-label (12px), text-body (14px), text-heading (20px),
# text-display (28px) — defined in the @theme block.
# Exclusion: text-base-content is a DaisyUI semantic color class (Footgun-6), not a size
# utility. The old implementation piped through `grep -v 'text-base-content'`, which
# filters at the LINE level — so a genuine violation sharing a line with the (very common)
# base-content color class, e.g. class="text-sm text-base-content", was silently dropped
# (WR-01). Instead, anchor the size match so text-base-content can never match the pattern
# in the first place: text-sm/text-xs as whole tokens, and text-base only when NOT followed
# by a hyphen (which excludes text-base-content while still catching the raw text-base size).
if grep -rEn 'text-(sm|xs|xl|2xl|3xl)\b|text-base($|[^-])' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TYPE-GATE — raw text-scale utility found (use text-label/body/heading/display)" >&2
  errors=$((errors + 1))
fi

# BOLD-GATE: faux-bold tokens font-medium and font-semibold.
# Only weights 400 and 700 are loaded; font-medium (500) and font-semibold (600) trigger
# browser synthesis. Use font-bold or the default weight only.
if grep -rE 'font-(medium|semibold)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BOLD-GATE — faux-bold token found (use font-bold or default only)" >&2
  errors=$((errors + 1))
fi

# GAP-GATE: off-grid gap tokens gap-3, gap-4, gap-6.
# The 4px spacing grid uses semantic tokens: gap-sm (8px), gap-md (16px), gap-lg (24px).
# Bare numeric Tailwind gap utilities land off-grid and bypass the theme contract.
# The trailing boundary [^0-9a-z-]|$ is required (WR-04): without it the pattern matched
# gap-32, gap-64, and gap-3xl, all of which are valid documented spacing tokens
# (--spacing-...3xl / 32 / 48 / 64). The boundary restricts the gate to the standalone
# off-grid tokens gap-3, gap-4, gap-6.
if grep -rEn 'gap-(3|4|6)([^0-9a-z-]|$)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: GAP-GATE — off-grid gap token found (use gap-sm/md/lg)" >&2
  errors=$((errors + 1))
fi

# HEX-GATE: hard-coded hex color values in HEEx.
# All colors must flow through daisyUI semantic tokens or @theme CSS variables.
# A literal #RRGGBB or #RGB in a template is a design-system violation.
# The old pattern `#[0-9a-fA-F]{3,6}` was over-broad (WR-04): it matched HTML anchor
# fragments and DOM id refs (href="#abc123", phx-value-id="#deadbeef"), 4-/5-char runs that
# are not valid CSS hex, and brand-palette hexes quoted in a @moduledoc (#0D1B2A). Scope to
# a color context (require `color` before the hash) and to valid CSS hex lengths (exactly 3
# or 6 digits) with a trailing word boundary, so only genuine hard-coded color literals trip
# the gate.
if grep -rEn 'color[^#]*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: HEX-GATE — hard-coded hex color found (use semantic tokens)" >&2
  errors=$((errors + 1))
fi

# Z-INDEX-GATE: raw numeric/arbitrary z-index utilities in HEEx.
# Stacking contexts must consume the semantic .mg-layer-* utilities backed by
# --z-base/dropdown/overlay-scrim/overlay-panel/toast in app.css.
if grep -rEn '\bz-([0-9]+|\[[^]]+\])\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: Z-INDEX-GATE — raw z-index utility found (use mg-layer-* utilities)" >&2
  errors=$((errors + 1))
fi

# FOCUS-RING-GATE: pre-consolidation focus-ring idioms.
# All visible focus affordances in admin HEEx should use .mg-focus-ring or
# .mg-focus-ring-inset so width, color, offset, and timing stay centralized.
if grep -rEn 'focus-visible:ring-2 focus-visible:ring-primary|focus:outline|focus:outline-2|focus:outline-primary' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: FOCUS-RING-GATE — raw focus-ring idiom found (use mg-focus-ring utilities)" >&2
  errors=$((errors + 1))
fi

# SCOPE-GATE: host-safe admin roots.
# The operator shell and preview shell are mountable inside host apps; each
# root must own an isolated stacking context so host CSS/z-index values cannot
# accidentally interleave with admin overlays.
if ! grep -q 'mg-admin-root' "${LIB}/mailglass_admin/operator/shell.ex" 2>/dev/null; then
  echo "FAIL: SCOPE-GATE — operator shell root missing mg-admin-root isolation" >&2
  errors=$((errors + 1))
fi
if ! grep -q 'mg-admin-root' "${LIB}/mailglass_admin/preview_live.ex" 2>/dev/null; then
  echo "FAIL: SCOPE-GATE — preview shell root missing mg-admin-root isolation" >&2
  errors=$((errors + 1))
fi

# TOKEN-SCOPE-GATE: Phase 109 must not pull forward later theme-picker work.
# System theme remains CSS/root-layer behavior only: no JS storage, client hook,
# theme-controller input, matchMedia script, or explicit "system" data-theme.
if grep -rEn 'phx-hook=.*theme|localStorage|sessionStorage|document\.documentElement|window\.matchMedia|theme-controller|data-theme="system"|data-theme=\{[^}]*system|system[/-]light[/-]dark|light[/-]dark[/-]system' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TOKEN-SCOPE-GATE — theme hook/storage/system picker creep found" >&2
  errors=$((errors + 1))
fi

# RADIUS-GATE: raw radius scale or arbitrary radius utilities.
# Allow semantic rounded-box / rounded-field and intentional rounded-full
# indicators; reject Tailwind scale/arbitrary radius values.
if grep -rEn '\brounded-(none|sm|md|lg|xl|2xl|3xl|\[[^]]+\])\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: RADIUS-GATE — raw radius utility found (use rounded-box/field/full contract)" >&2
  errors=$((errors + 1))
fi

# SHADOW-GATE: raw shadow utilities.
# Only semantic elevation tokens are allowed: shadow-flat, shadow-raised,
# and shadow-overlay.
if grep -rEn '\bshadow($|-(sm|md|lg|xl|2xl|inner|\[[^]]+\]))' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: SHADOW-GATE — raw shadow utility found (use shadow-flat/raised/overlay)" >&2
  errors=$((errors + 1))
fi

# BORDER-GATE: raw border width/style/palette/arbitrary utilities.
# Preserve semantic default edges and semantic colors such as border-base-*,
# border-primary, border-secondary, border-error, border-warning/success, and
# border-transparent. Reject palette-scale colors and arbitrary border values.
if grep -rEn '\bborder-(0|2|4|8|\[[^]]+\]|solid|dashed|dotted|double|none|(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone)-[0-9]{2,3})\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BORDER-GATE — raw border utility found (use semantic border contract)" >&2
  errors=$((errors + 1))
fi

# SIZE-GATE: arbitrary size and spacing utilities.
# Fixed sizes and spacing must use the 4px grid or semantic tokens; arbitrary
# bracket utilities make the gate unable to reason about token discipline.
if grep -rEn '\b(?:w|h|min-w|max-w|min-h|max-h|p[trblxy]?|m[trblxy]?|gap|space-[xy])-\[[^]]+\]' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: SIZE-GATE — arbitrary size/spacing utility found (use token/grid utilities)" >&2
  errors=$((errors + 1))
fi

# MOTION-GATE: banned animation properties and stray ease-in tokens (MOTION-LD-01/10).
#
# Part 1 — layout-property transition utilities.
# Animating height/width/padding/margin/top/left/right/bottom/max-height triggers
# layout thrash and is banned by MOTION-LD-10. Only transform/opacity (and fast-token
# color) are permitted. Ban:
#   - Named Tailwind utilities:  transition-height, transition-width, transition-padding,
#     transition-margin, transition-top, transition-left, transition-right,
#     transition-bottom, transition-max-height
#   - Arbitrary JIT utilities:   transition-[height], transition-[max-height], etc.
# Anchor with a leading non-word character or start-of-token so transition-colors,
# transition-all, transition-transform, transition-opacity are NOT matched.
#
# Part 2 — stray ease-in token (MOTION-LD-01 — ease-out only).
# Ban `ease-in` as a whole token (word boundary on both sides) while allowing:
#   - ease-in-out  (standard CSS function — boundary suffix -out means it won't match)
#   - var(--ease-symmetric)  (the one documented exception for the tab-swap crossfade;
#     the grep-E pattern (?!var\() uses a POSIX-incompatible lookahead so we instead
#     exclude the literal construction "(--ease-" with a second -v pass at the pipe)
#
# Running both greps: the first flags layout-property violations, the second flags
# ease-in violations. Each increments `errors` independently so a file with both
# defects is counted only once per gate.
if grep -rEn '(^|[^a-zA-Z0-9-])transition-(height|width|padding|margin|top|left|right|bottom|max-height)\b|transition-\[([^]]*\b(height|width|padding|margin|top|left|right|bottom|max-height)\b[^]]*)\]' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: MOTION-GATE — layout-property transition found (animate transform/opacity only, MOTION-LD-10)" >&2
  errors=$((errors + 1))
fi
if grep -rEn '\bease-in\b' "$LIB" --include="*.ex" 2>/dev/null | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out' | grep -q .; then
  grep -rEn '\bease-in\b' "$LIB" --include="*.ex" 2>/dev/null | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out'
  echo "FAIL: MOTION-GATE — stray ease-in found (ease-out only except --ease-symmetric, MOTION-LD-01)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: design-system conformance violations found ($errors gate(s) failed)" >&2
  exit 1
fi

echo "OK: design-system conformance clean."
