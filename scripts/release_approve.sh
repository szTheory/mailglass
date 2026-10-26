#!/usr/bin/env bash
# Approve the single `hex-publish` gate (the `approve-release` job) of one
# publish-hex.yml run, from the terminal instead of the run page.
#
#   scripts/release_approve.sh <run-id>          # prompts before approving
#   scripts/release_approve.sh <run-id> --yes    # approves without the prompt
#
# This is the maintainer's own approval, made with the maintainer's gh
# credential. Nothing in CI calls it, and it approves only when the caller is a
# configured reviewer (`current_user_can_approve`) for the `hex-publish`
# environment, which is resolved by name, never by a hardcoded ID. Without
# `--yes` it needs an interactive terminal and an explicit confirmation.
set -euo pipefail

repository=szTheory/mailglass
environment_name=hex-publish
workflow_path=.github/workflows/publish-hex.yml

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "usage: scripts/release_approve.sh <run-id> [--yes]" >&2
  exit 2
}

run_id=""
assume_yes=false
for arg in "$@"; do
  case "$arg" in
    --yes) assume_yes=true ;;
    -h | --help) usage ;;
    *)
      [[ -z "$run_id" ]] || usage
      run_id=$arg
      ;;
  esac
done

[[ -n "$run_id" ]] || usage
[[ "$run_id" =~ ^[1-9][0-9]*$ ]] || fail "run id must be a positive integer, got '$run_id'"

command -v gh >/dev/null 2>&1 || fail "gh is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

run_json=$(gh api "repos/${repository}/actions/runs/${run_id}") ||
  fail "could not read run ${run_id}"

jq -e --arg path "$workflow_path" '.path == $path' <<<"$run_json" >/dev/null ||
  fail "run ${run_id} is not a ${workflow_path} run; refusing to approve it"

run_status=$(jq -r '.status' <<<"$run_json")
[[ "$run_status" == "waiting" ]] ||
  fail "run ${run_id} is '${run_status}', not waiting for an approval"

environment_id=$(gh api "repos/${repository}/environments/${environment_name}" --jq '.id') ||
  fail "could not resolve the ${environment_name} environment"
[[ "$environment_id" =~ ^[1-9][0-9]*$ ]] ||
  fail "the ${environment_name} environment id is malformed: '${environment_id}'"

pending_json=$(gh api "repos/${repository}/actions/runs/${run_id}/pending_deployments") ||
  fail "could not list pending deployments for run ${run_id}"

echo "Pending deployments for run ${run_id}:"
jq -r '.[] | "  - \(.environment.name) (id \(.environment.id)), can approve: \(.current_user_can_approve), waiting since \(.wait_timer_started_at // "n/a")"' \
  <<<"$pending_json"

pending=$(jq -c --argjson id "$environment_id" --arg name "$environment_name" \
  '[.[] | select(.environment.id == $id and .environment.name == $name)]' <<<"$pending_json")

[[ "$(jq 'length' <<<"$pending")" == "1" ]] ||
  fail "run ${run_id} has no single pending ${environment_name} deployment"

jq -e '.[0].current_user_can_approve == true' <<<"$pending" >/dev/null ||
  fail "the authenticated gh user is not an allowed reviewer for ${environment_name}"

head_sha=$(jq -r '.head_sha' <<<"$run_json")
run_url=$(jq -r '.html_url' <<<"$run_json")
echo
echo "Run:         ${run_url}"
echo "Head SHA:    ${head_sha}"
echo "Environment: ${environment_name} (id ${environment_id})"
echo "Approving releases the whole publish fan-out: mailglass, mailglass_admin, mailglass_inbound."

if [[ "$assume_yes" != true ]]; then
  [[ -t 0 ]] || fail "no terminal to confirm on; re-run interactively or pass --yes"
  read -r -p "Type 'approve' to publish this release to Hex: " answer
  [[ "$answer" == "approve" ]] || fail "not approved"
fi

payload=$(jq -n --argjson id "$environment_id" \
  --arg comment "Approved with scripts/release_approve.sh for run ${run_id} at ${head_sha}" \
  '{environment_ids: [$id], state: "approved", comment: $comment}')

gh api -X POST "repos/${repository}/actions/runs/${run_id}/pending_deployments" --input - \
  <<<"$payload" >/dev/null ||
  fail "approval request failed"

echo "Approved ${environment_name} for run ${run_id}: ${run_url}"
