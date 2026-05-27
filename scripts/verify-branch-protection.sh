#!/usr/bin/env bash
# verify-branch-protection.sh — read-only branch protection verifier.
#
# Usage:
#   scripts/verify-branch-protection.sh [branch]
#   scripts/verify-branch-protection.sh --print-expected
#   scripts/verify-branch-protection.sh --print-expected-json

set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-szTheory}"
REPO_NAME="${GITHUB_REPOSITORY:-}"
REPO_NAME="${REPO_NAME##*/}"
REPO_NAME="${REPO_NAME:-mailglass}"
REPO="${OWNER}/${REPO_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SCRIPT_DIR}/setup_branch_protection.sh"

case "${1:-}" in
  --print-expected)
    exec "${SETUP_SCRIPT}" --print-expected
    ;;
  --print-expected-json)
    exec "${SETUP_SCRIPT}" --print-expected-json
    ;;
esac

BRANCH="${1:-main}"
EXPECTED_JSON="$("${SETUP_SCRIPT}" --print-expected-json)"

LIVE_RAW="$(
  gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/${REPO}/branches/${BRANCH}/protection"
)"

LIVE_NORMALIZED="$(
  jq '{
    required_status_checks: {
      strict: .required_status_checks.strict,
      contexts: (.required_status_checks.contexts // (.required_status_checks.checks // [] | map(.context)))
    },
    enforce_admins: (if (.enforce_admins | type) == "object" then .enforce_admins.enabled else (.enforce_admins // false) end),
    required_pull_request_reviews: (
      if .required_pull_request_reviews == null then
        null
      else
        .required_pull_request_reviews
      end
    ),
    restrictions: (
      if .restrictions == null then
        null
      elif ((.restrictions.users // []) | length) == 0 and
           ((.restrictions.teams // []) | length) == 0 and
           ((.restrictions.apps // []) | length) == 0 then
        null
      else
        .restrictions
      end
    ),
    allow_force_pushes: (if (.allow_force_pushes | type) == "object" then .allow_force_pushes.enabled else (.allow_force_pushes // false) end),
    allow_deletions: (if (.allow_deletions | type) == "object" then .allow_deletions.enabled else (.allow_deletions // false) end),
    block_creations: (if (.block_creations | type) == "object" then .block_creations.enabled else (.block_creations // false) end),
    required_conversation_resolution: (if (.required_conversation_resolution | type) == "object" then .required_conversation_resolution.enabled else (.required_conversation_resolution // false) end),
    lock_branch: (if (.lock_branch | type) == "object" then .lock_branch.enabled else (.lock_branch // false) end),
    allow_fork_syncing: (if (.allow_fork_syncing | type) == "object" then .allow_fork_syncing.enabled else (.allow_fork_syncing // false) end)
  }' <<<"${LIVE_RAW}"
)"

if [ "$(jq -S . <<<"${EXPECTED_JSON}")" = "$(jq -S . <<<"${LIVE_NORMALIZED}")" ]; then
  echo "OK: branch protection matches expected ruleset for ${REPO}@${BRANCH}."
  exit 0
fi

echo "DRIFT: branch protection differs from expected ruleset for ${REPO}@${BRANCH}." >&2
diff -u \
  <(jq -S . <<<"${EXPECTED_JSON}") \
  <(jq -S . <<<"${LIVE_NORMALIZED}") || true
exit 1
