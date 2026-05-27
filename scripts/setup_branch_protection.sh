#!/usr/bin/env bash
# setup_branch_protection.sh — idempotently configure branch protection on main.
#
# Adds the required CI checks to main's required_status_checks:
#   - Support Contract Core (Elixir 1.18 / OTP 27)
#   - Support Contract Admin (Elixir 1.18 / OTP 27)
#   - Compile No Optional Deps (Elixir 1.18 / OTP 27)
#
# Usage:
#   GH_TOKEN=<admin-PAT> scripts/setup_branch_protection.sh
#
# Or via the .github/workflows/branch-protection-drift.yml scheduled
# workflow (which uses the BRANCH_PROTECTION_PAT secret).
#
# Reason: REL-10 PR-C requires branch protection to mark Tests as
# required. This script makes it a one-line operation, replaces the
# manual GitHub UI click-through, and is idempotent (safe to re-run).
set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-szTheory}"
REPO_NAME="${GITHUB_REPOSITORY##*/}"
REPO_NAME="${REPO_NAME:-mailglass}"
REPO="${OWNER}/${REPO_NAME}"
BRANCH="${1:-main}"

# Required status checks. Names must EXACTLY match the GitHub Actions
# job names as they appear in CI (with matrix expansion).
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
)

# Build the JSON contexts array.
CONTEXTS_JSON=$(printf '"%s",' "${REQUIRED_CHECKS[@]}" | sed 's/,$//')
CONTEXTS_JSON="[${CONTEXTS_JSON}]"

PAYLOAD=$(cat <<JSON
{
  "required_status_checks": {
    "strict": true,
    "contexts": ${CONTEXTS_JSON}
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON
)

case "${1:-}" in
  --print-expected-json)
    jq . <<<"${PAYLOAD}"
    exit 0
    ;;
  --print-expected)
    echo "Expected branch protection payload for ${REPO}@main:"
    jq . <<<"${PAYLOAD}"
    exit 0
    ;;
esac

if [ -z "${GH_TOKEN:-}" ]; then
  echo "Delivery blocked: GH_TOKEN not set. Provide an admin PAT with 'repo' scope."
  exit 1
fi

echo "Configuring branch protection for ${REPO}@${BRANCH}..."

# PUT replaces the entire protection rule. Idempotent — re-running with
# the same payload is a no-op as far as observable state goes.
gh api -X PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<< "$PAYLOAD"

echo "OK: branch protection configured for ${REPO}@${BRANCH}."
echo "Required checks:"
printf '  - %s\n' "${REQUIRED_CHECKS[@]}"
