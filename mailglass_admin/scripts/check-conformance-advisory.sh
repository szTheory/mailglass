#!/usr/bin/env bash
# Advisory conformance gates for mailglass_admin — TYPE-GATE (text-lg/xl/2xl/3xl/4xl/5xl)
# and TRACK-GATE (tracking-[arbitrary]).
# These patterns have known violations deferred to Phase 98/99; run CI with
# continue-on-error: true until those markup phases flip them to hard-fail.
# See CONTEXT.md D-08 for the advisory/hard-fail split rationale.
#
# Known violations:
#   TYPE-GATE: 5 text-xl/lg sites (preview_live, detail_header ×2, replay_modal ×2)
#   TRACK-GATE: ~43 tracking-[0.08em] sites (all in lib/ HEEx)
#
# This script ALWAYS exits 0 — it is purely advisory. Violations are printed
# to stderr so CI logs them, but main stays green.
#
# Phase 99 task: flip this script's exit-code contract to hard-fail after
# migrating the 5 text-xl/lg sites and defining --tracking-eyebrow token in
# brandbook/tokens.css, then migrating all ~43 tracking-[0.08em] sites.
# Steps: (1) remove `exit 0` at the bottom, (2) add the fail-closed error
# counter from check-conformance.sh, (3) remove continue-on-error from ci.yml step.

set -euo pipefail

# Resolve LIB relative to this script's own location, not the caller's cwd.
# BASH_SOURCE anchor — cwd-independent (same as check-conformance.sh lines 22-24)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }

# TYPE-GATE (advisory): text-lg/xl/2xl/3xl/4xl/5xl in HEEx.
# Use semantic tokens instead: text-heading (20px), text-display (28px).
# 5 known violations (preview_live, detail_header ×2, replay_modal ×2) — Phase 98/99.
# Named variants (text-lg/xl/etc.) are type-scale utilities; they bypass the semantic
# token contract defined in the @theme block.
if grep -rEn 'text-(lg|xl|2xl|3xl|4xl|5xl)\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "WARN: TYPE-GATE (advisory) — text-lg/xl found; fix in Phase 98/99 (use text-heading/display tokens)" >&2
fi

# TRACK-GATE (advisory): arbitrary tracking-[…] JIT utilities in HEEx.
# Named tracking-tight/wide/normal are allowed. tracking-[0.08em] bypasses
# the token contract; define --tracking-eyebrow in brandbook/tokens.css first,
# then migrate all sites in Phase 98/99.
# ~43 known violations (all tracking-[0.08em]) — Phase 98/99.
if grep -rEn 'tracking-\[' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "WARN: TRACK-GATE (advisory) — arbitrary tracking-[…] found; define --tracking-eyebrow token first, then migrate in Phase 98/99" >&2
fi

echo "OK: advisory conformance check complete (violations above are logged, not blocking)."
exit 0
