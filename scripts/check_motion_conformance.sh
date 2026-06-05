#!/usr/bin/env bash
# Fail CI if any banned motion CSS token appears in mailglass_admin/lib/ or app.css.
# Banned tokens defined by UI-SPEC Motion Rules (Phase 74 FROZEN contract, GAP-19 sev 3).
# Two-pass structure to avoid false positive on --ease-in-out CSS custom property at app.css:120.
# Reused at Phase 79 as part of the full conformance check.
#
# Pass A: layout-thrashing tokens — grep both lib/ AND app.css
# Pass B: banned easing classes — grep lib/ ONLY (app.css legitimately defines --ease-in-out)

set -euo pipefail

LIB="mailglass_admin/lib"
CSS="mailglass_admin/assets/css/app.css"
errors=0

# Pass A: layout-thrashing + duration tokens
# Covers both mailglass_admin/lib/ and app.css (no false-positive risk for these tokens).
THRASH_PATTERN='transition-height|transition-max-height|transition-padding|transition-all|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}'
if grep -rE "$THRASH_PATTERN" "$LIB" "$CSS" 2>/dev/null; then
  echo "FAIL: banned layout-thrashing or duration token found (see above)" >&2
  errors=$((errors + 1))
fi

# Pass B: banned easing classes — lib/ ONLY.
# app.css:120 defines --ease-in-out as a CSS custom property (design token, not a Tailwind class).
# Grepping app.css for ease-in-out would produce a false positive on every run.
# ease-in[^-] matches bare ease-in without matching ease-in-out (BSD/GNU grep portable form).
EASE_PATTERN='ease-in-out|ease-linear|ease-in[^-]'
if grep -rE "$EASE_PATTERN" "$LIB" 2>/dev/null; then
  echo "FAIL: banned easing class found in lib/ (see above)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: motion conformance violations found (see above)" >&2
  exit 1
fi

echo "OK: motion conformance clean."
