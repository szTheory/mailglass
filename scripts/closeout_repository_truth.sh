#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 --repo PATH --ledger PATH --ci-run-id ID --output PATH" >&2; exit 2; }

scheduled_report_is_acceptable() {
  local report_path="$1" expected_sha="$2" registry="$3"

  jq -e --arg sha "$expected_sha" --slurpfile registry "$registry" '
    ($registry[0].controls | map({key: .id, value: .workflow_name}) | from_entries) as $workflow_names |
    type == "object" and
    .kind == "sweep" and
    .expected_main_sha == $sha and
    .status == "pass" and
    .reason == "all_controls_current" and
    .evidence_valid == true and
    (.controls | type == "array") and
    ([.controls[].control] | sort) == ($registry[0].controls | map(.id) | sort) and
    all(.controls[];
      .evidence_valid == true and
      (.source_run.id | tostring | test("^[1-9][0-9]*$")) and
      .source_run.name == $workflow_names[.control] and
      .source_run.attempt == 1 and
      .source_run.event == "schedule" and
      .source_run.status == "completed" and
      .source_run.head_branch == "main" and
      .source_run.head_sha == $sha and
      (.source_run.conclusion | type == "string" and length > 0) and
      (.source_run.updated_at | type == "string" and length > 0) and
      .result.workflow_sha == $sha and
      (.result.reason | type == "string" and length > 0) and
      (.result.status == "pass" or .result.status == "blocked") and
      (.result.payload_sha256 | type == "string" and test("^[0-9a-f]{64}$")) and
      (.result.artifact_archive_digest | type == "string" and test("^sha256:[0-9a-f]{64}$"))
    )
  ' "$report_path" >/dev/null 2>&1
}

main() {
canonical_repo=/Users/jon/projects/mailglass
repo=""; ledger=""; ci_run_id=""; output=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo|--ledger|--ci-run-id|--output)
      [ "$#" -ge 2 ] || usage
      case "$1" in
        --repo) repo="$2" ;;
        --ledger) ledger="$2" ;;
        --ci-run-id) ci_run_id="$2" ;;
        --output) output="$2" ;;
      esac
      shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$repo" ] && [ -n "$ledger" ] && [ -n "$ci_run_id" ] && [ -n "$output" ] || usage
[[ "$ci_run_id" =~ ^[1-9][0-9]*$ ]] || usage

repo=$(cd "$repo" 2>/dev/null && pwd -P) || usage
[ "$repo" = "$canonical_repo" ] || usage
canonical_ledger="$repo/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
ledger=$(cd "$(dirname "$ledger")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$ledger")") || usage
[ "$ledger" = "$canonical_ledger" ] || usage
[ -f "$canonical_ledger" ] || usage

case "$output" in *".."*) usage ;; esac
case "$output" in /*) output_candidate="$output" ;; *) output_candidate="$(pwd -P)/$output" ;; esac
output_name=$(basename "$output_candidate")
output_dir=$(dirname "$output_candidate")
suffix=""
while [ ! -d "$output_dir" ]; do
  parent=$(dirname "$output_dir")
  [ "$parent" != "$output_dir" ] || usage
  suffix="/$(basename "$output_dir")$suffix"
  output_dir="$parent"
done
output_dir="$(cd "$output_dir" 2>/dev/null && pwd -P)$suffix" || usage
canonical_tmp="$repo/tmp"
case "$output_dir" in "$canonical_tmp"|"$canonical_tmp"/*) ;; *) usage ;; esac
output="$output_dir/$output_name"
capture_dir=$(mktemp -d "$canonical_tmp/phase-164-closeout.XXXXXX") || usage
capture_dir=$(cd "$capture_dir" 2>/dev/null && pwd -P) || usage
case "$capture_dir" in "$canonical_tmp/"*) ;; *) usage ;; esac
components_dir="$capture_dir/components"
output_rel=${output#"$repo"/}
components_rel=${components_dir#"$repo"/}
[ "$output_rel" != "$output" ] && [ "$components_rel" != "$components_dir" ] || usage
git -C "$repo" check-ignore -q -- "$output_rel" || usage
git -C "$repo" check-ignore -q -- "$components_rel" || usage
mkdir -m 700 "$components_dir"

stable_porcelain() {
  git -C "$repo" status --porcelain=v1 --untracked-files=all 2>/dev/null || printf 'git_status_failed\n'
}

component() {
  local name="$1" status="$2" reason="$3" source="$4" component_tmp
  component_tmp=$(mktemp "$components_dir/$name.XXXXXX")
  jq -n --arg status "$status" --arg reason "$reason" --arg source "$source" \
    '{status: $status, reason: $reason, source: $source}' >"$component_tmp"
  mv "$component_tmp" "$components_dir/$name.json"
  if [ -n "$(stable_porcelain)" ]; then
    component_tmp=$(mktemp "$components_dir/$name.XXXXXX")
    jq -n --arg source "$source" '{status: "blocked", reason: "post_write_porcelain_dirty", source: $source}' >"$component_tmp"
    mv "$component_tmp" "$components_dir/$name.json"
  fi
}

head_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)
origin_main_sha=$(git -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)
branch=$(git -C "$repo" branch --show-current 2>/dev/null || true)
porcelain=$(stable_porcelain)
git_source=$(mktemp "$components_dir/git.source.XXXXXX")
printf '%s\n' "$branch $head_sha $origin_main_sha $porcelain" >"$git_source"
if [[ "$head_sha" =~ ^[0-9a-f]{40}$ ]] && [[ "$origin_main_sha" =~ ^[0-9a-f]{40}$ ]] && [ "$branch" = main ] && [ "$head_sha" = "$origin_main_sha" ] && [ -z "$porcelain" ]; then component git pass exact_main_clean "$git_source"; else component git blocked exact_main_or_porcelain_mismatch "$git_source"; fi

hygiene_raw=$(mktemp "$components_dir/hygiene.source.XXXXXX")
set +e
(cd "$repo" && mix mailglass.repo.hygiene --check --format json) >"$hygiene_raw" 2>&1
hygiene_exit=$?
set -e
if jq -e '
  type == "object" and
  (.status == "pass" or .status == "blocked" or .status == "pending" or .status == "cannot-check") and
  (.reason | type == "string" and length > 0) and
  (.status != "blocked" or ((.checks | type == "array" and length > 0) and any(.checks[]; .status == "blocked" and (.message | type == "string" and length > 0) and (.details | type == "object"))))
' "$hygiene_raw" >/dev/null 2>&1; then
  hygiene_status=$(jq -r '.status' "$hygiene_raw")
  if [ "$hygiene_status" = pass ] && [ "$hygiene_exit" -ne 0 ]; then component hygiene cannot-check command_status_mismatch "$hygiene_raw"; else component hygiene "$hygiene_status" "$(jq -r '.reason' "$hygiene_raw")" "$hygiene_raw"; fi
else component hygiene cannot-check malformed_or_unavailable_hygiene "$hygiene_raw"; fi

workspace_raw=$(mktemp "$components_dir/workspace.source.XXXXXX")
if bash "$repo/scripts/verify_workspace_evidence.sh" static "$repo/.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md" "$repo/.planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv" >"$workspace_raw" 2>&1; then component workspace pass preservation_verified "$workspace_raw"; else component workspace cannot-check preservation_verification_failed "$workspace_raw"; fi

ledger_raw=$(mktemp "$components_dir/ledger.source.XXXXXX")
if elixir "$repo/scripts/validate_repository_truth.exs" --repo "$repo" --ledger "$canonical_ledger" >"$ledger_raw" 2>&1; then component ledger pass complete_authoritative_disposition_ledger "$ledger_raw"; else component ledger cannot-check invalid_or_incomplete_authoritative_ledger "$ledger_raw"; fi

ci_raw=$(mktemp "$components_dir/ci.source.XXXXXX")
ci_diagnostics=$(mktemp "$components_dir/ci.diagnostics.XXXXXX")
if (cd "$repo" && node scripts/ci_monitor.cjs inspect "$ci_run_id") >"$ci_raw" 2>"$ci_diagnostics" && jq -e --arg sha "$head_sha" 'type == "object" and .workflowName == "CI" and .event == "push" and .attempt == 1 and .headBranch == "main" and .headSha == $sha and .status == "completed" and .conclusion == "success"' "$ci_raw" >/dev/null 2>&1; then component ci pass exact_successful_ci "$ci_raw"; else component ci cannot-check missing_malformed_or_wrong_identity_ci "$ci_raw"; fi

scheduled_raw=$(mktemp "$components_dir/scheduled.source.XXXXXX")
if (cd "$repo" && bash scripts/scheduled_control_evidence.sh sweep --output "$scheduled_raw") >/dev/null 2>&1 && scheduled_report_is_acceptable "$scheduled_raw" "$head_sha" "$repo/.github/scheduled-controls.json"; then component scheduled pass current_provenance_valid "$scheduled_raw"; elif jq -e 'type == "object" and (.status == "pending" or .status == "cannot-check")' "$scheduled_raw" >/dev/null 2>&1; then component scheduled "$(jq -r '.status' "$scheduled_raw")" "$(jq -r '.reason // "scheduled_evidence_incomplete"' "$scheduled_raw")" "$scheduled_raw"; else component scheduled cannot-check malformed_stale_or_mismatched_scheduled_evidence "$scheduled_raw"; fi

write_report() {
  local captured_at report_tmp
  captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  report_tmp=$(mktemp "$output_dir/.$output_name.XXXXXX")
  jq -n --arg schema "mailglass.repository-closeout/v1" --arg captured_at "$captured_at" --arg repo "$repo" --arg branch "$branch" --arg head_sha "$head_sha" --arg origin_main_sha "$origin_main_sha" --arg ci_run_id "$ci_run_id" --slurpfile git "$components_dir/git.json" --slurpfile hygiene "$components_dir/hygiene.json" --slurpfile workspace "$components_dir/workspace.json" --slurpfile ledger "$components_dir/ledger.json" --slurpfile ci "$components_dir/ci.json" --slurpfile scheduled "$components_dir/scheduled.json" '
    [$git[0], $hygiene[0], $workspace[0], $ledger[0], $ci[0], $scheduled[0]] as $all |
    (if any($all[]; .status == "cannot-check") then "cannot-check" elif any($all[]; .status == "pending") then "pending" elif ($git[0].status == "pass" and ($hygiene[0].status == "pass" or $hygiene[0].status == "blocked") and $workspace[0].status == "pass" and $ledger[0].status == "pass" and $ci[0].status == "pass" and $scheduled[0].status == "pass") then "pass" elif any($all[]; .status == "blocked") then "blocked" else "cannot-check" end) as $status |
    {schema: $schema, captured_at: $captured_at, repo: $repo, branch: $branch, head_sha: $head_sha, origin_main_sha: $origin_main_sha, ci_run_id: $ci_run_id, components: {git: $git[0], hygiene: $hygiene[0], workspace: $workspace[0], ledger: $ledger[0], ci: $ci[0], scheduled: $scheduled[0]}, status: $status, reason: (if $status == "pass" then "all_authorities_exact_and_current" else "closeout_" + $status end)}' >"$report_tmp"
  mv "$report_tmp" "$output"
}

write_report
final_porcelain=$(stable_porcelain)
if [ -n "$final_porcelain" ]; then
  component git blocked post_write_porcelain_dirty "$git_source"
  write_report
  final_porcelain=$(stable_porcelain)
fi
[ -z "$final_porcelain" ] && [ "$(jq -r '.status' "$output")" = pass ]
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
