#!/usr/bin/env bash
# Fail CI if any design-system violation appears in mailglass_admin/lib/*.ex files.
# Five-gate design-system conformance check — gate definitions committed at Phase 76-06.
# Sources: VERIF-03 (Phase 79), D-07 (single source of truth for visual decisions).
# Gate patterns from 76-06-SUMMARY.md: five greps that confirmed zero violations on
# the Phase 76 codebase. All gates scope to .ex files only (HEEx lives in LiveView modules;
# no .heex partials exist in this codebase).
#
# Footgun-6 exclusion (TYPE-GATE): text-base-content is a DaisyUI semantic color token
# (base-content text color), not a raw type-scale utility. Without the exclusion, every
# file using text-base-content produces a false failure on the text-base pattern.

set -euo pipefail

LIB="mailglass_admin/lib"
errors=0

# BADGE-GATE: defp badge_class must not exist anywhere in lib/.
# Components.status_badge/1 is the single canonical status→color definition (Phase 76-02).
# Any private badge_class helper is a divergence point and must be routed through it.
if grep -rE 'defp badge_class' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BADGE-GATE — defp badge_class found; route through Components.status_badge/1" >&2
  errors=$((errors + 1))
fi

# TYPE-GATE: raw Tailwind type-scale utilities in HEEx (text-sm, text-base, text-xs).
# Use semantic tokens instead: text-label (12px), text-body (14px), text-heading (20px),
# text-display (28px) — defined in the @theme block.
# Exclusion: text-base-content is a DaisyUI semantic color class (Footgun-6), not a size
# utility. Piping through grep -v ensures it is never flagged as a violation.
if grep -rE 'text-(sm|base|xs)' "$LIB" --include="*.ex" 2>/dev/null | grep -v 'text-base-content'; then
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
if grep -rE 'gap-(3|4|6)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: GAP-GATE — off-grid gap token found (use gap-sm/md/lg)" >&2
  errors=$((errors + 1))
fi

# HEX-GATE: hard-coded hex color values in HEEx.
# All colors must flow through daisyUI semantic tokens or @theme CSS variables.
# A literal #RRGGBB or #RGB in a template is a design-system violation.
if grep -rE '#[0-9a-fA-F]{3,6}' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: HEX-GATE — hard-coded hex color found (use semantic tokens)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: design-system conformance violations found ($errors gate(s) failed)" >&2
  exit 1
fi

echo "OK: design-system conformance clean."
