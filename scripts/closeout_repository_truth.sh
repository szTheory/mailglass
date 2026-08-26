#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 --repo PATH --ledger PATH --ci-run-id ID --output PATH" >&2; exit 2; }

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
[ -f "$ledger" ] || usage
mkdir -p "$(dirname "$output")"
output_dir=$(cd "$(dirname "$output")" && pwd -P)
output="$output_dir/$(basename "$output")"
components_dir="$output_dir/components"
mkdir -p "$components_dir"

component() {
  local name="$1" status="$2" reason="$3" source="$4"
  jq -n --arg status "$status" --arg reason "$reason" --arg source "$source" \
    '{status: $status, reason: $reason, source: $source}' >"$components_dir/$name.tmp"
  mv "$components_dir/$name.tmp" "$components_dir/$name.json"
}

head_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)
origin_main_sha=$(git -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)
branch=$(git -C "$repo" branch --show-current 2>/dev/null || true)
porcelain=$(git -C "$repo" status --porcelain=v1 --untracked-files=all 2>/dev/null || true)
git_source="$components_dir/git.source"
printf '%s\n' "$branch $head_sha $origin_main_sha $porcelain" >"$git_source"
if [[ "$head_sha" =~ ^[0-9a-f]{40}$ ]] && [[ "$origin_main_sha" =~ ^[0-9a-f]{40}$ ]] && [ "$branch" = main ] && [ "$head_sha" = "$origin_main_sha" ] && [ -z "$porcelain" ]; then component git pass exact_main_clean "$git_source"; else component git blocked exact_main_or_porcelain_mismatch "$git_source"; fi

hygiene_raw="$components_dir/hygiene.source"
if (cd "$repo" && mix mailglass.repo.hygiene --check --format json) >"$hygiene_raw" 2>&1 && jq -e 'type == "object" and (.status | type == "string") and (.reason | type == "string")' "$hygiene_raw" >/dev/null 2>&1; then
  component hygiene "$(jq -r '.status' "$hygiene_raw")" "$(jq -r '.reason' "$hygiene_raw")" "$hygiene_raw"
else component hygiene cannot-check malformed_or_unavailable_hygiene "$hygiene_raw"; fi

workspace_raw="$components_dir/workspace.source"
if bash "$repo/scripts/verify_workspace_evidence.sh" static "$repo/.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md" "$repo/.planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv" >"$workspace_raw" 2>&1; then component workspace pass preservation_verified "$workspace_raw"; else component workspace cannot-check preservation_verification_failed "$workspace_raw"; fi

ledger_raw="$components_dir/ledger.source"
if awk -F '\t' 'NR == 1 { ok = ($0 == "stable_id\tsubject\tkind\tproducer\tstate\tauthority\treproducibility\tcurrentness\tdurable_consumer\tevidence\tdisposition\trationale"); next } NF != 12 { ok = 0 } $2 == "" || $11 !~ /^(retain|update|archive|remove|ignore)$/ { ok = 0 } seen[$2]++ > 0 { ok = 0 } END { exit(ok && NR > 1 ? 0 : 1) }' "$ledger" >"$ledger_raw" 2>&1; then component ledger pass exact_one_disposition "$ledger_raw"; else component ledger cannot-check malformed_or_duplicate_ledger "$ledger_raw"; fi

ci_raw="$components_dir/ci.source"
if (cd "$repo" && node scripts/ci_monitor.cjs inspect "$ci_run_id") >"$ci_raw" 2>&1 && jq -e --arg sha "$head_sha" 'type == "object" and .headSha == $sha and .status == "completed" and .conclusion == "success"' "$ci_raw" >/dev/null 2>&1; then component ci pass exact_successful_ci "$ci_raw"; else component ci cannot-check missing_malformed_or_wrong_identity_ci "$ci_raw"; fi

scheduled_raw="$components_dir/scheduled.source"
if (cd "$repo" && bash scripts/scheduled_control_evidence.sh sweep --output "$scheduled_raw") >/dev/null 2>&1 && jq -e --arg sha "$head_sha" 'type == "object" and .expected_main_sha == $sha and (.status == "pass" or .status == "blocked") and .evidence_valid == true and (.controls | type == "array" and length > 0) and all(.controls[]; .evidence_valid == true and .source_run.event == "schedule" and .source_run.status == "completed" and .source_run.head_branch == "main" and .source_run.head_sha == $sha and .result.workflow_sha == $sha and (.source_run.updated_at | fromdateiso8601) >= (now - 10800) and (.result.status == "pass" or (.result.status == "blocked" and (.result.payload_sha256 | type == "string" and length > 0))))' "$scheduled_raw" >/dev/null 2>&1; then
  component scheduled pass current_provenance_valid "$scheduled_raw"
elif jq -e 'type == "object" and (.status == "pending" or .status == "cannot-check")' "$scheduled_raw" >/dev/null 2>&1; then
  component scheduled "$(jq -r '.status' "$scheduled_raw")" "$(jq -r '.reason // "scheduled_evidence_incomplete"' "$scheduled_raw")" "$scheduled_raw"
else component scheduled cannot-check malformed_stale_or_mismatched_scheduled_evidence "$scheduled_raw"; fi

captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
report_tmp=$(mktemp "$output.XXXXXX")
jq -n --arg schema "mailglass.repository-closeout/v1" --arg captured_at "$captured_at" --arg repo "$repo" --arg branch "$branch" --arg head_sha "$head_sha" --arg origin_main_sha "$origin_main_sha" --arg ci_run_id "$ci_run_id" --slurpfile git "$components_dir/git.json" --slurpfile hygiene "$components_dir/hygiene.json" --slurpfile workspace "$components_dir/workspace.json" --slurpfile ledger "$components_dir/ledger.json" --slurpfile ci "$components_dir/ci.json" --slurpfile scheduled "$components_dir/scheduled.json" '
  [$git[0], $hygiene[0], $workspace[0], $ledger[0], $ci[0], $scheduled[0]] as $all |
  (if any($all[]; .status == "cannot-check") then "cannot-check" elif any($all[]; .status == "pending") then "pending" elif any($all[]; .status == "blocked") then "blocked" elif all($all[]; .status == "pass") then "pass" else "cannot-check" end) as $status |
  {schema: $schema, captured_at: $captured_at, repo: $repo, branch: $branch, head_sha: $head_sha, origin_main_sha: $origin_main_sha, ci_run_id: $ci_run_id, components: {git: $git[0], hygiene: $hygiene[0], workspace: $workspace[0], ledger: $ledger[0], ci: $ci[0], scheduled: $scheduled[0]}, status: $status, reason: (if $status == "pass" then "all_authorities_exact_and_current" else "closeout_" + $status end)}' >"$report_tmp"
mv "$report_tmp" "$output"
[ "$(jq -r '.status' "$output")" = pass ]
