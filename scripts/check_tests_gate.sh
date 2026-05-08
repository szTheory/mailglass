#!/usr/bin/env bash
# check_tests_gate.sh — fail CI if the canonical test gate in ci.yml is advisory.
#
# Reason: Phase 8 plan 08-05 PR-C flipped the canonical test gate from
# `continue-on-error: true` to halt-on-failure. CI has since evolved from
# a single `tests:` job to multiple explicit gates; this script prevents
# silent regression by checking the current canonical gate(s), not by
# assuming the old job name still exists.
#
# Runs in the actionlint job in CI. Exit 1 on regression.
set -euo pipefail

CI_FILE=".github/workflows/ci.yml"

if [ ! -f "$CI_FILE" ]; then
  echo "Delivery blocked: $CI_FILE not found"
  exit 1
fi

TEST_JOB_KEYS=(
  "tests"
  "support_contract_core"
)

find_job_line() {
  local job_key="$1"
  grep -n "^  ${job_key}:" "$CI_FILE" | head -1 | cut -d: -f1 || true
}

JOB_LINE=""
JOB_KEY=""

for candidate in "${TEST_JOB_KEYS[@]}"; do
  line=$(find_job_line "$candidate")
  if [ -n "$line" ]; then
    JOB_LINE="$line"
    JOB_KEY="$candidate"
    break
  fi
done

if [ -z "$JOB_LINE" ]; then
  echo "Delivery blocked: no canonical test gate found in $CI_FILE"
  echo "Expected one of: ${TEST_JOB_KEYS[*]}"
  exit 1
fi

# Find the next job header (one that starts with `^  [a-z_]+:` at column 2)
# AFTER the selected job. That bounds the job block.
NEXT_JOB_LINE=$(awk -v start="$JOB_LINE" 'NR > start && /^  [a-z_]+:/ {print NR; exit}' "$CI_FILE")
if [ -z "$NEXT_JOB_LINE" ]; then
  NEXT_JOB_LINE=$(wc -l < "$CI_FILE" | tr -d ' ')
fi

JOB_BLOCK=$(sed -n "${JOB_LINE},${NEXT_JOB_LINE}p" "$CI_FILE")
if echo "$JOB_BLOCK" | grep -q "continue-on-error: true"; then
  echo "Delivery blocked: canonical test gate '${JOB_KEY}' in $CI_FILE has continue-on-error: true"
  echo "The test gate must be halt-on-failure."
  exit 1
fi

echo "OK: canonical test gate '${JOB_KEY}' is halt-on-failure."
