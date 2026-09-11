#!/usr/bin/env bash
set -euo pipefail

: "${MAILGLASS_GIT:?missing validated MAILGLASS_GIT}"
: "${MAILGLASS_BASH:?missing validated MAILGLASS_BASH}"
: "${MAILGLASS_GH:?missing validated MAILGLASS_GH}"
: "${MAILGLASS_JQ:?missing validated MAILGLASS_JQ}"
: "${MAILGLASS_MIX:?missing validated MAILGLASS_MIX}"
: "${MAILGLASS_NODE:?missing validated MAILGLASS_NODE}"
: "${MAILGLASS_ELIXIR:?missing validated MAILGLASS_ELIXIR}"
: "${MAILGLASS_ERL:?missing validated MAILGLASS_ERL}"

canonical_repo=/Users/jon/projects/mailglass
phase_rel=.planning/phases/164-repository-truth-reconciliation-and-closeout
ledger_rel="$phase_rel/164-TRUTH-DISPOSITION.tsv"
registry_rel=.github/scheduled-controls.json
expected_repository=szTheory/mailglass
terminal_first_plan=1
terminal_last_plan=39

fail() {
  printf 'finalize-phase 164: %s\n' "$1" >&2
  return 1
}

stable_porcelain() {
  "$MAILGLASS_GIT" -C "$1" status --porcelain=v1 --untracked-files=all 2>/dev/null || printf 'git_status_failed\n'
}

require_expected_authority() {
  local repo="$1" expected_authority_oid="$2" observed

  [[ "$expected_authority_oid" =~ ^[0-9a-f]{40}$ ]] || fail "expected authority OID is not a full lowercase commit OID"
  "$MAILGLASS_GIT" -C "$repo" cat-file -e "$expected_authority_oid^{commit}" 2>/dev/null ||
    fail "expected authority OID does not name a commit"
  observed=$("$MAILGLASS_GIT" -C "$repo" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)
  [ "$observed" = "$expected_authority_oid" ] || fail "authority commit changed"
}

repository_identity_is_authoritative() {
  local repo="$1" github_repository="$2" origin_url

  [ -z "${GH_REPO:-}" ] || return 1
  [ -z "${GH_HOST:-}" ] || [ "$GH_HOST" = github.com ] || return 1
  [ "$github_repository" = "$expected_repository" ] || return 1
  origin_url=$("$MAILGLASS_GIT" -C "$repo" remote get-url origin 2>/dev/null) || return 1

  case "$origin_url" in
    "git@github.com:$expected_repository"|"git@github.com:$expected_repository.git"|\
    "https://github.com/$expected_repository"|"https://github.com/$expected_repository.git"|\
    "ssh://git@github.com/$expected_repository"|"ssh://git@github.com/$expected_repository.git") return 0 ;;
    *) return 1 ;;
  esac
}

mark_report_non_pass() {
  local report="$1" reason="$2" report_dir report_tmp
  report_dir=$(cd "$(dirname "$report")" 2>/dev/null && pwd -P) || return 1
  report_tmp=$(mktemp "$report_dir/.report.XXXXXX") || return 1
  "$MAILGLASS_JQ" --arg reason "$reason" '.status = "blocked" | .reason = $reason' "$report" >"$report_tmp" || {
    rm -f "$report_tmp"
    return 1
  }
  mv "$report_tmp" "$report"
}

revalidate_final_main() {
  local repo="$1" expected_sha="$2" report="$3" scheduled_source

  if ! "$MAILGLASS_GIT" -C "$repo" fetch origin main >/dev/null 2>&1 ||
     [ "$("$MAILGLASS_GIT" -C "$repo" rev-parse HEAD 2>/dev/null || true)" != "$expected_sha" ] ||
     [ "$("$MAILGLASS_GIT" -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)" != "$expected_sha" ]; then
    mark_report_non_pass "$report" protected_main_advanced
    return 1
  fi

  scheduled_source=$("$MAILGLASS_JQ" -er '.components.scheduled.source | strings | select(length > 0)' "$report") || {
    mark_report_non_pass "$report" scheduled_main_identity_missing
    return 1
  }

  "$MAILGLASS_JQ" -e --arg sha "$expected_sha" '.expected_main_sha == $sha' "$scheduled_source" >/dev/null || {
    mark_report_non_pass "$report" scheduled_main_identity_mismatch
    return 1
  }
}

select_ci_run_id() {
  local runs_json="$1" expected_sha="$2"

  "$MAILGLASS_JQ" -er --arg sha "$expected_sha" '
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

  for plan in $(seq -w 1 13); do
    [ -f "$phase_dir/164-$plan-SUMMARY.md" ] || fail "missing implementation summary 164-$plan-SUMMARY.md"
  done
}

require_terminal_state() {
  local repo="$1" phase_dir="$2" authority_root="$3" plan plan_file summary verification verified_implementation_sha commit path

  for plan in $(seq -w "$terminal_first_plan" "$terminal_last_plan"); do
    plan_file="$phase_dir/164-$plan-PLAN.md"
    summary="$phase_dir/164-$plan-SUMMARY.md"
    [ -f "$plan_file" ] || fail "missing terminal plan 164-$plan-PLAN.md"
    [ -f "$summary" ] || fail "missing terminal summary 164-$plan-SUMMARY.md"
  done

  grep -F -- '- [x] **Phase 164: Repository Truth Reconciliation and Closeout**' "$authority_root/.planning/ROADMAP.md" >/dev/null ||
    fail "ROADMAP does not mark Phase 164 complete"

  for requirement in TRTH-01 TRTH-02 TRTH-03; do
    grep -F -- "- [x] **$requirement**" "$authority_root/.planning/REQUIREMENTS.md" >/dev/null ||
      fail "$requirement is not complete"
  done

  verification="$phase_dir/164-VERIFICATION.md"
  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && $0 == "status: passed" { passed = 1 }
    END { exit(passed ? 0 : 1) }
  ' "$verification" || fail "164-VERIFICATION.md has not passed"

  [ "$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^verified_implementation_sha: / { count += 1 }
    END { print count + 0 }
  ' "$verification")" -eq 1 ] || fail "164-VERIFICATION.md must name one verified_implementation_sha"

  verified_implementation_sha=$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^verified_implementation_sha: / {
      sub(/^verified_implementation_sha: /, "")
      print
    }
  ' "$verification")
  [[ "$verified_implementation_sha" =~ ^[0-9a-f]{40}$ ]] ||
    fail "verified_implementation_sha is not exactly 40 lowercase hexadecimal characters"
  "$MAILGLASS_GIT" -C "$repo" cat-file -e "$verified_implementation_sha^{commit}" 2>/dev/null ||
    fail "verified_implementation_sha does not name a commit"
  "$MAILGLASS_GIT" -C "$repo" merge-base --is-ancestor "$verified_implementation_sha" HEAD 2>/dev/null ||
    fail "verified_implementation_sha is not an ancestor of terminal HEAD"

  while IFS= read -r commit; do
    [ -n "$commit" ] || continue
    while IFS= read -r path; do
      case "$path" in
        "$phase_rel/164-VERIFICATION.md"|.planning/ROADMAP.md|.planning/REQUIREMENTS.md|.planning/STATE.md) ;;
        *) fail "commit $commit changes $path outside completion metadata" ;;
      esac
    done < <("$MAILGLASS_GIT" -C "$repo" diff-tree --no-commit-id --name-only -r "$commit^1" "$commit")
  done < <("$MAILGLASS_GIT" -C "$repo" rev-list --first-parent --reverse "$verified_implementation_sha..HEAD")
}

canonical_component_source() {
  local report="$1" selector="$2" components_dir="$3" source_path source_real

  source_path=$("$MAILGLASS_JQ" -er "$selector | strings | select(length > 0)" "$report") || return 1
  [ -f "$source_path" ] || return 1
  source_real=$(realpath "$source_path") || return 1
  case "$source_real" in "$components_dir"/*) printf '%s\n' "$source_real" ;; *) return 1 ;; esac
}

raw_sources_are_acceptable() {
  local report="$1" expected_sha="$2" capture_root="$3" registry="$4" expected_ci_run_id="$5"
  local components_dir ci_source scheduled_source

  ci_source=$("$MAILGLASS_JQ" -er '.components.ci.source | strings | select(length > 0)' "$report") || return 1
  components_dir=$(cd "$(dirname "$ci_source")" 2>/dev/null && pwd -P) || return 1
  capture_root=$(cd "$capture_root" 2>/dev/null && pwd -P) || return 1
  case "$components_dir" in "$capture_root/components"|"$capture_root/"*/components) ;; *) return 1 ;; esac
  ci_source=$(canonical_component_source "$report" '.components.ci.source' "$components_dir") || return 1
  scheduled_source=$(canonical_component_source "$report" '.components.scheduled.source' "$components_dir") || return 1

  "$MAILGLASS_JQ" -e --arg sha "$expected_sha" --arg run_id "$expected_ci_run_id" '
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

  "$MAILGLASS_JQ" -e --arg sha "$expected_sha" --slurpfile registry "$registry" '
    ($registry[0].controls |
      map({key: .id, value: {workflow_name: .workflow_name, max_age_seconds: .max_age_seconds}}) |
      from_entries) as $control_contracts |
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
      .source_run.name == $control_contracts[.control].workflow_name and
      .source_run.attempt == 1 and
      .source_run.event == "schedule" and
      .source_run.head_branch == "main" and
      .source_run.head_sha == $sha and
      .source_run.status == "completed" and
      (.source_run.conclusion | type == "string" and length > 0) and
      ($control_contracts[.control].max_age_seconds | type == "number" and . > 0) and
      (.source_run.updated_at | type == "string" and length > 0) and
      ((now - (.source_run.updated_at | fromdateiso8601)) as $age |
        $age >= 0 and $age <= $control_contracts[.control].max_age_seconds) and
      .result.workflow_sha == $sha and
      (.result.reason | type == "string" and length > 0) and
      (.result.status == "pass" or .result.status == "blocked") and
      (.result.payload_sha256 | type == "string" and test("^[0-9a-f]{64}$")) and
      (.result.artifact_archive_digest | type == "string" and test("^sha256:[0-9a-f]{64}$"))
    )
  ' "$scheduled_source" >/dev/null
}

main() {
  local repo_arg="${1:-}" authority_arg="${2:-}" expected_authority_oid="${3:-}" mode_arg="${4:-}" mode=terminal
  local repo authority_root phase_dir capture_dir inputs report runs_json ci_run_id main_sha branch porcelain
  local github_repository
  local closeout_status=0

  [ "$#" -ge 3 ] && [ "$#" -le 4 ] || fail "usage: $0 REPO AUTHORITY_ROOT EXPECTED_AUTHORITY_OID [--pre-verification]"
  [[ "$expected_authority_oid" =~ ^[0-9a-f]{40}$ ]] || fail "expected authority OID is not a full lowercase commit OID"
  if [ "$#" -eq 4 ]; then
    [ "$mode_arg" = "--pre-verification" ] || fail "unknown mode: $mode_arg"
    mode=pre-verification
  fi

  repo=$(cd "$repo_arg" 2>/dev/null && pwd -P) || fail "repository does not exist"
  [ "$repo" = "$canonical_repo" ] || fail "repository is not the canonical checkout"
  require_expected_authority "$repo" "$expected_authority_oid"
  authority_root=$(cd "$authority_arg" 2>/dev/null && pwd -P) || fail "authenticated authority root does not exist"
  [ "$authority_root" != "$repo" ] || fail "authenticated authority root must be private"
  case "$(basename "$authority_root")" in mailglass-finalize-164-*) ;; *) fail "authenticated authority root is unexpected" ;; esac
  phase_dir="$authority_root/$phase_rel"

  branch=$("$MAILGLASS_GIT" -C "$repo" branch --show-current 2>/dev/null || true)
  [ "$branch" = main ] || fail "canonical checkout is not on main"

  porcelain=$(stable_porcelain "$repo")
  [ -z "$porcelain" ] || fail "stable porcelain is not empty"

  repository_identity_is_authoritative "$repo" "$expected_repository" ||
    fail "origin or GitHub repository override is not authoritative"
  github_repository=$(GH_HOST=github.com "$MAILGLASS_GH" repo view "github.com/$expected_repository" --json nameWithOwner --jq '.nameWithOwner') ||
    fail "could not resolve the authoritative GitHub repository identity"
  repository_identity_is_authoritative "$repo" "$github_repository" ||
    fail "GitHub repository identity is not $expected_repository"

  "$MAILGLASS_GIT" -C "$repo" fetch origin main >/dev/null || fail "git fetch origin main failed"
  require_expected_authority "$repo" "$expected_authority_oid"
  main_sha="$expected_authority_oid"
  [ "$expected_authority_oid" = "$("$MAILGLASS_GIT" -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)" ] ||
    fail "HEAD does not equal origin/main"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed after fetch"

  if [ "$mode" = pre-verification ]; then
    require_pre_verification_state "$repo" "$phase_dir"
    inputs=pre-verification-inputs.json
    report=pre-verification-report.json
  else
    require_terminal_state "$repo" "$phase_dir" "$authority_root"
    inputs=finalization-inputs.json
    report=report.json
  fi

  capture_dir=$(mktemp -d "$repo/tmp/phase-164-finalize.XXXXXX") || fail "could not allocate private capture directory"
  capture_dir=$(cd "$capture_dir" 2>/dev/null && pwd -P) || fail "could not resolve private capture directory"
  case "$capture_dir" in "$repo/tmp/"*) ;; *) fail "capture directory escaped canonical tmp" ;; esac
  chmod 700 "$capture_dir"
  runs_json=$(mktemp "$capture_dir/ci-runs.XXXXXX") || fail "could not allocate CI capture"

  GH_HOST=github.com "$MAILGLASS_GH" run list \
    --repo "$expected_repository" \
    --workflow CI \
    --branch main \
    --event push \
    --status completed \
    --limit 100 \
    --json databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,url,createdAt \
    >"$runs_json"
  ci_run_id=$(select_ci_run_id "$runs_json" "$main_sha") || fail "no exact attempt-1 normal push CI run passed for HEAD"
  inputs_tmp=$(mktemp "$capture_dir/$inputs.XXXXXX") || fail "could not allocate input capture"
  "$MAILGLASS_JQ" -n --arg main_sha "$main_sha" --arg ci_run_id "$ci_run_id" \
    '{main_sha: $main_sha, ci_run_id: $ci_run_id}' >"$inputs_tmp"
  mv "$inputs_tmp" "$capture_dir/$inputs"

  require_expected_authority "$repo" "$expected_authority_oid" || return 1
  set +e
  GH_HOST=github.com \
  GITHUB_REPOSITORY="$github_repository" \
  SCHEDULED_CONTROL_CONFIG="$authority_root/$registry_rel" \
    "$MAILGLASS_BASH" "$authority_root/scripts/closeout_repository_truth.sh" \
    --repo "$repo" \
    --authority-root "$authority_root" \
    --expected-main-sha "$expected_authority_oid" \
    --ledger "$repo/$ledger_rel" \
    --ci-run-id "$ci_run_id" \
    --output "$capture_dir/$report"
  closeout_status=$?
  set -e

  [ -f "$capture_dir/$report" ] || fail "closeout did not preserve a report"
  raw_sources_are_acceptable "$capture_dir/$report" "$main_sha" "$repo/tmp" "$authority_root/$registry_rel" "$ci_run_id" ||
    fail "raw CI or scheduled evidence failed independent finalization validation"

  revalidate_final_main "$repo" "$expected_authority_oid" "$capture_dir/$report" ||
    fail "protected main changed during finalization"

  require_expected_authority "$repo" "$expected_authority_oid"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed during finalization"
  [ "$closeout_status" -eq 0 ] || fail "closeout preserved a non-pass report"
  [ "$("$MAILGLASS_JQ" -r '.status' "$capture_dir/$report")" = pass ] || fail "closeout report is not pass"

  printf 'finalize-phase 164: %s evidence passed at %s\n' "$mode" "$main_sha"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
