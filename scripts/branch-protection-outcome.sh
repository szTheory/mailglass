#!/usr/bin/env bash
# branch-protection-outcome.sh — shared truthful branch-protection outcome seam.
#
# Usage:
#   GH_TOKEN=<admin-PAT> scripts/branch-protection-outcome.sh probe [--reassert] [branch]
#   scripts/branch-protection-outcome.sh report <clean|drift|cannot_check|unknown>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="${SCRIPT_DIR}/verify-branch-protection.sh"
SETUP_SCRIPT="${SCRIPT_DIR}/setup_branch_protection.sh"

cannot_check() {
  echo "cannot_check"
}

probe() {
  local reassert=false branch="main" output status classification

  if [ "${1:-}" = "--reassert" ]; then
    reassert=true
    shift
  fi

  branch="${1:-main}"

  if [ -z "${GH_TOKEN:-}" ] || ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    cannot_check
    return 0
  fi

  set +e
  output="$("${VERIFY_SCRIPT}" "${branch}" 2>&1)"
  status=$?
  set -e

  if [ "${status}" -eq 0 ]; then
    classification="clean"
  elif printf '%s\n' "${output}" | grep -q '^DRIFT:'; then
    classification="drift"
  else
    classification="cannot_check"
  fi

  # The scheduled owner path deliberately reasserts only after the canonical
  # read-only comparison. Its conclusion records the original observation so a
  # successful repair cannot make observed drift appear clean.
  if [ "${reassert}" = true ] && [ "${classification}" = "drift" ]; then
    set +e
    "${SETUP_SCRIPT}" "${branch}" >&2
    set -e
  fi

  echo "${classification}"
}

report() {
  local classification="${1:-unknown}" destination="/dev/stdout"

  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    destination="${GITHUB_STEP_SUMMARY}"
  fi

  {
    echo "## Branch Protection Outcome"
    echo ""

    case "${classification}" in
      clean)
        echo "Live branch protection matches the expected read-only ruleset."
        ;;
      drift)
        echo "Live branch protection drifted from the expected ruleset."
        echo "Re-apply the owner-controlled ruleset with \`./scripts/setup_branch_protection.sh main\`."
        ;;
      cannot_check)
        echo "Could not verify live branch protection (missing credential, tooling, or API access)."
        echo "Configure \`BRANCH_PROTECTION_PAT\` and ensure \`gh\` and \`jq\` can reach GitHub, then rerun verification."
        ;;
      *)
        echo "Could not classify the branch-protection verification result."
        echo "Rerun the verifier after checking workflow logs and credentials."
        ;;
    esac
  } >> "${destination}"

  [ "${classification}" = "clean" ]
}

case "${1:-}" in
  probe)
    shift
    probe "$@"
    ;;
  report)
    shift
    report "$@"
    ;;
  *)
    echo "Usage: $0 probe [--reassert] [branch] | report <classification>" >&2
    exit 64
    ;;
esac
