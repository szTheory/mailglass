#!/usr/bin/env bash
# Fail CI if any remaining large type-scale or arbitrary tracking utilities
# appear in mailglass_admin/lib/*.ex files.
# Phase 99 locked the rule: arbitrary tracking is removed rather than backed by
# a new eyebrow token; use semantic type classes and named tracking utilities.

set -euo pipefail

# Resolve LIB relative to this script's own location, not the caller's cwd.
# BASH_SOURCE anchor — cwd-independent (same as check-conformance.sh lines 22-24)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
errors=0

# TYPE-GATE: text-lg/xl/2xl/3xl/4xl/5xl in HEEx.
# Use semantic tokens instead: text-heading (20px), text-display (28px).
# Named variants (text-lg/xl/etc.) are type-scale utilities; they bypass the semantic
# token contract defined in the @theme block.
if grep -rEn 'text-(lg|xl|2xl|3xl|4xl|5xl)\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TYPE-GATE - raw large text-scale utility found (use text-heading/display tokens)" >&2
  errors=$((errors + 1))
fi

# TRACK-GATE: arbitrary tracking-[...] JIT utilities in HEEx.
# Named tracking-tight/wide/normal are allowed. tracking-[0.08em] bypasses
# the locked Phase 96/99 semantic label contract.
if grep -rEn 'tracking-\[' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TRACK-GATE - arbitrary tracking utility found (use text-label uppercase font-bold text-secondary)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: advisory design-system conformance violations found (${errors} gate(s) failed)" >&2
  exit 1
fi

echo "OK: advisory design-system conformance clean."
exit 0
