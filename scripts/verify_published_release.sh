#!/usr/bin/env bash
set -euo pipefail

target_input=${1:?usage: verify_published_release.sh RELEASE_TARGET_JSON}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

case "$target_input" in
  /*) target_path=$target_input ;;
  *) target_path="$PWD/$target_input" ;;
esac

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

# The policy validator is intentionally the first evidence operation. It
# rejects the wrong lifecycle, schema drift, digest mismatch, duplicate release
# IDs, and incomplete package maps before any external lookup occurs.
policy_output=$(
  cd "$repo_root"
  mix run --no-start \
    --require scripts/release_policy.exs \
    -e 'Mailglass.ReleasePolicy.cli(System.argv())' \
    -- verify-published "$target_path"
) || fail "release policy rejected the published target"

[[ "$policy_output" == *"published=true"* ]] ||
  fail "release policy did not confirm the published target"

candidate_digest=$(jq -er '.final_identity.publication_evidence.candidate_digest' "$target_path") ||
  fail "published candidate digest is missing"
workflow_run_url=$(jq -er '.final_identity.publication_evidence.workflow_run_url' "$target_path") ||
  fail "publication workflow run URL is missing"
tag_sha=$(jq -er '.final_identity.tag_sha' "$target_path") ||
  fail "final tag SHA is missing"

repository=szTheory/mailglass
if [[ ! "$workflow_run_url" =~ ^https://github\.com/szTheory/mailglass/actions/runs/([1-9][0-9]*)$ ]]; then
  fail "publication workflow run URL is not repository-bound"
fi

run_id=${BASH_REMATCH[1]}
workflow_json=$(gh api "repos/${repository}/actions/runs/${run_id}") ||
  fail "publication workflow run lookup failed"

jq -e \
  --argjson run_id "$run_id" \
  --arg run_url "$workflow_run_url" \
  --arg repository "$repository" \
  'type == "object" and
   .id == $run_id and
   .html_url == $run_url and
   .repository.full_name == $repository and
   .event == "workflow_dispatch" and
   .status == "completed" and
   .conclusion == "success" and
   .head_branch == "main" and
   .head_repository.full_name == $repository and
   (.head_sha | type == "string" and test("^[0-9a-f]{40}$")) and
   .path == ".github/workflows/publish-hex.yml"' \
  <<<"$workflow_json" >/dev/null ||
  fail "publication workflow run is malformed, unsuccessful, or identity-mismatched"

# A successful run record alone is not publication provenance: dry runs and
# compatibility no-ops can also conclude successfully. Require the complete,
# current live job graph so the cited run proves it crossed the protected gate,
# published every package in order, and dispatched the exact post-publish smoke.
jobs_json=$(gh api "repos/${repository}/actions/runs/${run_id}/jobs?per_page=100&filter=latest") ||
  fail "publication workflow job lookup failed"

jq -e '
  def required_jobs:
    ["prepublish-summary", "ensure-live-ci-runs", "gate-ci-green",
     "publish-core", "publish-admin", "publish-inbound",
     "dispatch-post-publish-smoke"];
  type == "object" and
  .total_count == (required_jobs | length) and
  (.jobs | type == "array" and length == (required_jobs | length)) and
  ([.jobs[].name] | sort) == (required_jobs | sort) and
  all(.jobs[]; .status == "completed" and .conclusion == "success")' \
  <<<"$jobs_json" >/dev/null ||
  fail "publication workflow did not complete the exact protected live job graph"

workflow_head_sha=$(jq -er '.head_sha' <<<"$workflow_json") ||
  fail "publication workflow run head SHA is missing"

packages=(mailglass mailglass_admin mailglass_inbound)
versions=(
  "$(jq -er '.candidate_versions.mailglass' "$target_path")"
  "$(jq -er '.candidate_versions.mailglass_admin' "$target_path")"
  "$(jq -er '.candidate_versions.mailglass_inbound' "$target_path")"
)
release_ids=(
  "$(jq -er '.final_identity.publication_evidence.release_ids.mailglass' "$target_path")"
  "$(jq -er '.final_identity.publication_evidence.release_ids.mailglass_admin' "$target_path")"
  "$(jq -er '.final_identity.publication_evidence.release_ids.mailglass_inbound' "$target_path")"
)
checksums=(
  "$(jq -er '.final_identity.publication_evidence.hex_release_checksums.mailglass' "$target_path")"
  "$(jq -er '.final_identity.publication_evidence.hex_release_checksums.mailglass_admin' "$target_path")"
  "$(jq -er '.final_identity.publication_evidence.hex_release_checksums.mailglass_inbound' "$target_path")"
)

for index in 0 1 2; do
  package=${packages[$index]}
  version=${versions[$index]}
  release_id=${release_ids[$index]}
  checksum=${checksums[$index]}

  if [[ "$package" == mailglass ]]; then
    tag="mailglass-v${version}"
  else
    tag="${package}-v${version}"
  fi

  release_json=$(gh api "repos/${repository}/releases/${release_id}") ||
    fail "GitHub release lookup failed for ${package}"

  jq -e \
    --argjson release_id "$release_id" \
    --arg tag "$tag" \
    'type == "object" and
     .id == $release_id and
     .tag_name == $tag and
     .draft == false and
     .prerelease == false' \
    <<<"$release_json" >/dev/null ||
    fail "GitHub release evidence is malformed or mismatched for ${package}"

  tag_json=$(gh api "repos/${repository}/git/ref/tags/${tag}") ||
    fail "GitHub tag lookup failed for ${package}"

  jq -e \
    --arg ref "refs/tags/${tag}" \
    --arg tag_sha "$tag_sha" \
    'type == "object" and
     .ref == $ref and
     .object.type == "commit" and
     .object.sha == $tag_sha' \
    <<<"$tag_json" >/dev/null ||
    fail "GitHub tag evidence is malformed or SHA-mismatched for ${package}"

  hex_state=$("$script_dir/release_policy_hex_release_state.sh" "$package" "$version" "$checksum") ||
    fail "Hex release verification failed for ${package} ${version}"
  [[ "$hex_state" == exists ]] ||
    fail "Hex release is not present for ${package} ${version}"
done

echo "published_release_verified=true"
echo "candidate_digest=${candidate_digest}"
echo "tag_sha=${tag_sha}"
echo "workflow_head_sha=${workflow_head_sha}"
