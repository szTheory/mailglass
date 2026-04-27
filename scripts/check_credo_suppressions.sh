#!/usr/bin/env bash
# Fail CI if any `false`-tuple entry in `.credo.exs` :disabled_checks
# is missing BOTH a `# Reason: ...` line AND a `# Tracking: ...` line
# in the comment block immediately above it.
#
# Convention (D-08-27): paired with scripts/check_dialyzer_ignore.sh.
# Every suppression is a documented decision, not a silent suppression.

set -euo pipefail

FILE=".credo.exs"
errors=0

# Find every `{Credo.Check..., false}` tuple line; assert the preceding
# comment block contains BOTH "# Reason:" AND "# Tracking:".
# Note: use [[:space:]]* instead of \s* for POSIX awk compatibility (macOS).
awk '
  /\{Credo\.Check\.[^,]+, false\}/ {
    has_reason = 0
    has_tracking = 0
    # Walk backwards through comment-prefixed lines until first blank or non-comment.
    for (i = NR - 1; i >= 1 && lines[i] ~ /^[[:space:]]*#/; i--) {
      if (lines[i] ~ /^[[:space:]]*#[[:space:]]*Reason:/)   has_reason = 1
      if (lines[i] ~ /^[[:space:]]*#[[:space:]]*Tracking:/) has_tracking = 1
    }
    if (!has_reason || !has_tracking) {
      printf "%s:%d  missing %s%s comment\n", FILENAME, NR,
        (has_reason ? "" : "# Reason: "),
        (has_tracking ? "" : "# Tracking: ")
      rc = 1
    }
  }
  { lines[NR] = $0 }
  END { exit rc + 0 }
' "$FILE" || errors=$((errors + 1))

if [[ $errors -gt 0 ]]; then
  echo "FAIL: credo disabled-check entries missing # Reason: or # Tracking: comments" >&2
  exit 1
fi

echo "OK: all credo suppressions are documented."
