#!/usr/bin/env bash
# Fail CI if any `.dialyzer_ignore.exs` entry is missing a `# Reason: ...`
# comment on the immediately-preceding non-blank line.
#
# Convention (D-08-27): every suppression is a documented decision, not a
# silent suppression. Paired with scripts/check_credo_suppressions.sh.
# Note: use [[:space:]]* instead of \s* for POSIX awk compatibility (macOS).

set -euo pipefail

FILES=(".dialyzer_ignore.exs" "mailglass_admin/.dialyzer_ignore.exs")
errors=0

for file in "${FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  awk '
    /^[[:space:]]*\{/ {
      if (prev !~ /^[[:space:]]*#[[:space:]]*Reason:/) {
        printf "%s:%d  missing # Reason: comment above tuple\n", FILENAME, NR
        rc = 1
      }
    }
    /^[[:space:]]*[^[:space:]]/ { prev = $0 }
    END { exit rc + 0 }
  ' "$file" || errors=$((errors + 1))
done

if [[ $errors -gt 0 ]]; then
  echo "FAIL: dialyzer ignore entries missing # Reason: comments" >&2
  exit 1
fi

echo "OK: all dialyzer ignore entries are documented."
