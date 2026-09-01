#!/usr/bin/env bash
set -euo pipefail

canonical_repo=/Users/jon/projects/mailglass
phase_rel=.planning/phases/164-repository-truth-reconciliation-and-closeout
ledger_rel="$phase_rel/164-TRUTH-DISPOSITION.tsv"
registry_rel=.github/scheduled-controls.json
expected_repository=szTheory/mailglass

fail() {
  printf 'finalize-phase 164: %s\n' "$1" >&2
  return 1
}

stable_porcelain() {
  git -C "$1" status --porcelain=v1 --untracked-files=all 2>/dev/null || printf 'git_status_failed\n'
}

repository_identity_is_authoritative() {
  local repo="$1" github_repository="$2" origin_url

  [ -z "${GH_REPO:-}" ] || return 1
  [ "$github_repository" = "$expected_repository" ] || return 1
  origin_url=$(git -C "$repo" remote get-url origin 2>/dev/null) || return 1

  case "$origin_url" in
    "git@github.com:$expected_repository"|"git@github.com:$expected_repository.git"|\
    "https://github.com/$expected_repository"|"https://github.com/$expected_repository.git"|\
    "ssh://git@github.com/$expected_repository"|"ssh://git@github.com/$expected_repository.git") return 0 ;;
    *) return 1 ;;
  esac
}

select_ci_run_id() {
  local runs_json="$1" expected_sha="$2"

  jq -er --arg sha "$expected_sha" '
    [ .[] |
      select(
        .workflowName == "CI" and
        .event == "push" and
        .attempt == 1 and
        .headBranch == "main" and
        .headSha == $sha and
        .status == "completed" and
        .conclusion == "success" and
        (.databaseId | type == "number" and . > 0) and
        (.createdAt | type == "string" and length > 0)
      )
    ] |
    sort_by(.createdAt, .databaseId) |
    last |
    .databaseId
  ' "$runs_json"
}

require_pre_verification_state() {
  local repo="$1" phase_dir="$2" plan

  for plan in $(seq -w 1 11); do
    [ -f "$phase_dir/164-$plan-SUMMARY.md" ] || fail "missing implementation summary 164-$plan-SUMMARY.md"
  done
}

require_terminal_state() {
  local repo="$1" phase_dir="$2" plan_file summary

  for plan_file in "$phase_dir"/164-[0-9][0-9]-PLAN.md; do
    [ -f "$plan_file" ] || fail "no numbered phase plans found"
    summary=${plan_file%-PLAN.md}-SUMMARY.md
    [ -f "$summary" ] || fail "missing terminal summary $(basename "$summary")"
  done

  grep -F -- '- [x] **Phase 164: Repository Truth Reconciliation and Closeout**' "$repo/.planning/ROADMAP.md" >/dev/null ||
    fail "ROADMAP does not mark Phase 164 complete"

  for requirement in TRTH-01 TRTH-02 TRTH-03; do
    grep -F -- "- [x] **$requirement**" "$repo/.planning/REQUIREMENTS.md" >/dev/null ||
      fail "$requirement is not complete"
  done

  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && $0 == "status: passed" { passed = 1 }
    END { exit(passed ? 0 : 1) }
  ' "$phase_dir/164-VERIFICATION.md" || fail "164-VERIFICATION.md has not passed"
}

canonical_component_source() {
  local report="$1" selector="$2" components_dir="$3" source_path source_real

  source_path=$(jq -er "$selector | strings | select(length > 0)" "$report") || return 1
  [ -f "$source_path" ] || return 1
  source_real=$(realpath "$source_path") || return 1
  case "$source_real" in "$components_dir"/*) printf '%s\n' "$source_real" ;; *) return 1 ;; esac
}

raw_sources_are_acceptable() {
  local report="$1" expected_sha="$2" capture_root="$3" registry="$4" expected_ci_run_id="$5"
  local components_dir ci_source scheduled_source

  ci_source=$(jq -er '.components.ci.source | strings | select(length > 0)' "$report") || return 1
  components_dir=$(cd "$(dirname "$ci_source")" 2>/dev/null && pwd -P) || return 1
  capture_root=$(cd "$capture_root" 2>/dev/null && pwd -P) || return 1
  case "$components_dir" in "$capture_root/components"|"$capture_root/"*/components) ;; *) return 1 ;; esac
  ci_source=$(canonical_component_source "$report" '.components.ci.source' "$components_dir") || return 1
  scheduled_source=$(canonical_component_source "$report" '.components.scheduled.source' "$components_dir") || return 1

  jq -e --arg sha "$expected_sha" --arg run_id "$expected_ci_run_id" '
    type == "object" and
    (.databaseId | tostring) == $run_id and
    .workflowName == "CI" and
    .event == "push" and
    .attempt == 1 and
    .headBranch == "main" and
    .headSha == $sha and
    .status == "completed" and
    .conclusion == "success"
  ' "$ci_source" >/dev/null || return 1

  jq -e --arg sha "$expected_sha" --slurpfile registry "$registry" '
    ($registry[0].controls | map({key: .id, value: .workflow_name}) | from_entries) as $workflow_names |
    type == "object" and
    .kind == "sweep" and
    .status == "pass" and
    .reason == "all_controls_current" and
    .evidence_valid == true and
    .expected_main_sha == $sha and
    (.controls | type == "array") and
    ([.controls[].control] | sort) == ($registry[0].controls | map(.id) | sort) and
    all(.controls[];
      .evidence_valid == true and
      (.source_run.id | tostring | test("^[1-9][0-9]*$")) and
      .source_run.name == $workflow_names[.control] and
      .source_run.attempt == 1 and
      .source_run.event == "schedule" and
      .source_run.head_branch == "main" and
      .source_run.head_sha == $sha and
      .source_run.status == "completed" and
      (.source_run.conclusion | type == "string" and length > 0) and
      (.source_run.updated_at | type == "string" and length > 0) and
      .result.workflow_sha == $sha and
      (.result.reason | type == "string" and length > 0) and
      (.result.status == "pass" or .result.status == "blocked") and
      (.result.payload_sha256 | type == "string" and test("^[0-9a-f]{64}$")) and
      (.result.artifact_archive_digest | type == "string" and test("^sha256:[0-9a-f]{64}$"))
    )
  ' "$scheduled_source" >/dev/null
}

main() {
  local repo_arg="${1:-}" mode_arg="${2:-}" mode=terminal
  local repo phase_dir capture_dir inputs report runs_json ci_run_id main_sha branch porcelain
  local github_repository
  local closeout_status=0

  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || fail "usage: $0 REPO [--pre-verification]"
  if [ "$#" -eq 2 ]; then
    [ "$mode_arg" = "--pre-verification" ] || fail "unknown mode: $mode_arg"
    mode=pre-verification
  fi

  repo=$(cd "$repo_arg" 2>/dev/null && pwd -P) || fail "repository does not exist"
  [ "$repo" = "$canonical_repo" ] || fail "repository is not the canonical checkout"
  phase_dir="$repo/$phase_rel"

  branch=$(git -C "$repo" branch --show-current 2>/dev/null || true)
  [ "$branch" = main ] || fail "canonical checkout is not on main"

  porcelain=$(stable_porcelain "$repo")
  [ -z "$porcelain" ] || fail "stable porcelain is not empty"

  repository_identity_is_authoritative "$repo" "$expected_repository" ||
    fail "origin or GitHub repository override is not authoritative"
  github_repository=$(gh repo view "$expected_repository" --json nameWithOwner --jq '.nameWithOwner') ||
    fail "could not resolve the authoritative GitHub repository identity"
  repository_identity_is_authoritative "$repo" "$github_repository" ||
    fail "GitHub repository identity is not $expected_repository"

  git -C "$repo" fetch origin main >/dev/null || fail "git fetch origin main failed"
  main_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)
  [[ "$main_sha" =~ ^[0-9a-f]{40}$ ]] || fail "HEAD is not a full commit SHA"
  [ "$main_sha" = "$(git -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)" ] ||
    fail "HEAD does not equal origin/main"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed after fetch"

  if [ "$mode" = pre-verification ]; then
    require_pre_verification_state "$repo" "$phase_dir"
    inputs=pre-verification-inputs.json
    report=pre-verification-report.json
  else
    require_terminal_state "$repo" "$phase_dir"
    inputs=finalization-inputs.json
    report=report.json
  fi

  capture_dir=$(mktemp -d "$repo/tmp/phase-164-finalize.XXXXXX") || fail "could not allocate private capture directory"
  capture_dir=$(cd "$capture_dir" 2>/dev/null && pwd -P) || fail "could not resolve private capture directory"
  case "$capture_dir" in "$repo/tmp/"*) ;; *) fail "capture directory escaped canonical tmp" ;; esac
  chmod 700 "$capture_dir"
  runs_json=$(mktemp "$capture_dir/ci-runs.XXXXXX") || fail "could not allocate CI capture"

  gh run list \
    --workflow CI \
    --branch main \
    --event push \
    --status completed \
    --limit 100 \
    --json databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,url,createdAt \
    >"$runs_json"
  ci_run_id=$(select_ci_run_id "$runs_json" "$main_sha") || fail "no exact attempt-1 normal push CI run passed for HEAD"
  inputs_tmp=$(mktemp "$capture_dir/$inputs.XXXXXX") || fail "could not allocate input capture"
  jq -n --arg main_sha "$main_sha" --arg ci_run_id "$ci_run_id" \
    '{main_sha: $main_sha, ci_run_id: $ci_run_id}' >"$inputs_tmp"
  mv "$inputs_tmp" "$capture_dir/$inputs"

  set +e
  GITHUB_REPOSITORY="$github_repository" "$repo/scripts/closeout_repository_truth.sh" \
    --repo "$repo" \
    --ledger "$repo/$ledger_rel" \
    --ci-run-id "$ci_run_id" \
    --output "$capture_dir/$report"
  closeout_status=$?
  set -e

  [ -f "$capture_dir/$report" ] || fail "closeout did not preserve a report"
  raw_sources_are_acceptable "$capture_dir/$report" "$main_sha" "$repo/tmp" "$repo/$registry_rel" "$ci_run_id" ||
    fail "raw CI or scheduled evidence failed independent finalization validation"

  [ "$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)" = "$main_sha" ] || fail "HEAD changed during finalization"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed during finalization"
  [ "$closeout_status" -eq 0 ] || fail "closeout preserved a non-pass report"
  [ "$(jq -r '.status' "$capture_dir/$report")" = pass ] || fail "closeout report is not pass"

  printf 'finalize-phase 164: %s evidence passed at %s\n' "$mode" "$main_sha"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
