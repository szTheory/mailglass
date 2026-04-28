#!/usr/bin/env bash
# check_tests_gate.sh — fail CI if the Tests job in ci.yml is advisory.
#
# Reason: Phase 8 plan 08-05 PR-C flipped the Tests lane from
# `continue-on-error: true` to halt-on-failure. This script prevents
# silent regression by failing if the advisory line creeps back into
# the Tests job (e.g., via a debugging PR that forgets to revert).
#
# Runs in the actionlint job in CI. Exit 1 on regression.
set -euo pipefail

CI_FILE=".github/workflows/ci.yml"

if [ ! -f "$CI_FILE" ]; then
  echo "Delivery blocked: $CI_FILE not found"
  exit 1
fi

# Find the line where the Tests job starts (the literal `  tests:` key
# at column 2 in the jobs block).
TESTS_LINE=$(grep -n "^  tests:" "$CI_FILE" | head -1 | cut -d: -f1)
if [ -z "$TESTS_LINE" ]; then
  echo "Delivery blocked: tests job not found in $CI_FILE"
  exit 1
fi

# Find the next job header (one that starts with `^  [a-z_]+:` at column 2)
# AFTER the tests job. That bounds the tests job block.
NEXT_JOB_LINE=$(awk -v start="$TESTS_LINE" 'NR > start && /^  [a-z_]+:/ {print NR; exit}' "$CI_FILE")
if [ -z "$NEXT_JOB_LINE" ]; then
  # Tests is the last job — bound at EOF.
  NEXT_JOB_LINE=$(wc -l < "$CI_FILE" | tr -d ' ')
fi

# Look for `continue-on-error: true` inside the tests job block.
TESTS_BLOCK=$(sed -n "${TESTS_LINE},${NEXT_JOB_LINE}p" "$CI_FILE")
if echo "$TESTS_BLOCK" | grep -q "continue-on-error: true"; then
  echo "Delivery blocked: Tests job in $CI_FILE has continue-on-error: true"
  echo "The Tests gate must be halt-on-failure (REL-10 PR-C, plan 08-07)."
  echo "If this is intentional, update plan 08-07 to document the regression."
  exit 1
fi

echo "OK: Tests job is halt-on-failure."
