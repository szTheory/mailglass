#!/usr/bin/env bash
# setup_branch_protection.sh — idempotently configure branch protection on main.
#
# Usage:
#   GH_TOKEN=<admin-PAT> scripts/setup_branch_protection.sh [branch]
#   scripts/setup_branch_protection.sh --print-expected
#   scripts/setup_branch_protection.sh --print-expected-json

set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-szTheory}"
REPO_NAME="${GITHUB_REPOSITORY:-}"
REPO_NAME="${REPO_NAME##*/}"
REPO_NAME="${REPO_NAME:-mailglass}"
REPO="${OWNER}/${REPO_NAME}"

REQUIRED_CHECKS=(
  "CI Green"
  "Guard Release Trigger"
)

print_expected_text() {
  cat <<'TEXT'
Expected required status checks:
  - CI Green
  - Guard Release Trigger

Expected non-context branch protection fields:
  - required_status_checks.strict: true
  - enforce_admins: false
  - required_pull_request_reviews: null
  - restrictions: null
  - allow_force_pushes: false
  - allow_deletions: false
  - block_creations: false
  - required_conversation_resolution: false
  - lock_branch: false
  - allow_fork_syncing: false
TEXT
}

expected_json() {
  local contexts_json
  contexts_json=$(printf '%s\n' "${REQUIRED_CHECKS[@]}" | jq -R . | jq -s .)

  jq -n \
    --argjson contexts "${contexts_json}" \
    '{
      required_status_checks: {
        strict: true,
        contexts: $contexts
      },
      enforce_admins: false,
      required_pull_request_reviews: null,
      restrictions: null,
      allow_force_pushes: false,
      allow_deletions: false,
      block_creations: false,
      required_conversation_resolution: false,
      lock_branch: false,
      allow_fork_syncing: false
    }'
}

case "${1:-}" in
  --print-expected)
    print_expected_text
    exit 0
    ;;
  --print-expected-json)
    expected_json
    exit 0
    ;;
esac

BRANCH="${1:-main}"

echo "Configuring branch protection for ${REPO}@${BRANCH}..."

gh api -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<<"$(expected_json)"

echo "OK: branch protection configured for ${REPO}@${BRANCH}."
print_expected_text
