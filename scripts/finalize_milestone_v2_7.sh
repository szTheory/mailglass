#!/usr/bin/env bash
set -euo pipefail

: "${MAILGLASS_GIT:?missing validated MAILGLASS_GIT}"
: "${MAILGLASS_JQ:?missing validated MAILGLASS_JQ}"

expected_repository=szTheory/mailglass
archive_root=.planning/milestones
phase_root="$archive_root/v2.7-phases"

fail() {
  printf 'finalize-milestone v2.7: %s\n' "$1" >&2
  return 1
}

stable_porcelain() {
  "$MAILGLASS_GIT" -C "$1" status --porcelain=v1 --untracked-files=all 2>/dev/null || printf 'git_status_failed\n'
}

require_authority() {
  local repo="$1" expected_oid="$2" observed
  [[ "$expected_oid" =~ ^[0-9a-f]{40}$ ]] || fail "authority OID is not full lowercase hexadecimal"
  observed=$("$MAILGLASS_GIT" -C "$repo" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)
  [ "$observed" = "$expected_oid" ] || fail "authority commit changed"
}

frontmatter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "")
      gsub(/^\"|\"$/, "")
      print
      exit
    }
  ' "$file"
}

require_archive_contract() {
  local authority_root="$1" expected_oid="$2" audit phase dir validation phases=()
  audit="$authority_root/$archive_root/v2.7-MILESTONE-AUDIT.md"
  [ "$(frontmatter_value "$audit" status)" = passed ] || fail "canonical audit status is not passed"
  grep -F -- 'requirements: 16/16' "$audit" >/dev/null || fail "canonical audit requirements score is not 16/16"
  grep -F -- 'phases: 5/5' "$audit" >/dev/null || fail "canonical audit phase score is not 5/5"
  grep -F -- 'integration: 16/16' "$audit" >/dev/null || fail "canonical audit integration score is not 16/16"
  grep -F -- 'flows: 5/5' "$audit" >/dev/null || fail "canonical audit flow score is not 5/5"
  grep -F -- '14-PR accepted policy debt' "$audit" >/dev/null || fail "canonical audit omits accepted 14-PR policy debt"

  shopt -s nullglob
  for dir in "$authority_root/$phase_root"/*; do
    [ -d "$dir" ] || continue
    phases+=("$(basename "$dir" | sed -E 's/^([0-9]+)-.*/\1/')")
  done
  [ "${phases[*]}" = "161 162 163 164 165" ] || fail "archived phase layout is not exactly phases 161-165"
  for phase in 161 162 163 164 165; do
    dir=("$authority_root/$phase_root/$phase-"*)
    [ "${#dir[@]}" -eq 1 ] || fail "archived phase $phase is missing or ambiguous"
    validation="${dir[0]}/$phase-VALIDATION.md"
    [ -f "$validation" ] || fail "archived phase $phase validation is missing"
    [ "$(frontmatter_value "$validation" status)" = validated ] || fail "archived phase $phase is not validated"
  done
  shopt -u nullglob

  grep -F -- 'v2.7' "$authority_root/.planning/MILESTONES.md" >/dev/null || fail "milestone ledger omits v2.7"
  grep -F -- 'archived' "$authority_root/.planning/STATE.md" >/dev/null || fail "state does not record archived milestone"
  grep -F -- 'v2.7' "$authority_root/.planning/PROJECT.md" >/dev/null || fail "project does not record v2.7"
  "$MAILGLASS_JQ" -e '.milestone == "v2.7" and (.status == "archived" or .milestone_status == "archived")' \
    "$authority_root/.planning/state.json" >/dev/null || fail "machine state does not agree that v2.7 is archived"
  [ -f "$authority_root/$archive_root/v2.7-ROADMAP.md" ] || fail "archived ROADMAP is missing"
  [ -f "$authority_root/$archive_root/v2.7-REQUIREMENTS.md" ] || fail "archived REQUIREMENTS is missing"
  ! compgen -G "$authority_root/.planning/phases/16[1-5]-*" >/dev/null || fail "live/archive lifecycle disagreement"
}

require_selected_evidence() {
  local inputs="$1" expected_oid="$2"
  "$MAILGLASS_JQ" -e --arg sha "$expected_oid" '
    type == "object" and
    (.ci | type == "object") and
    .ci.workflowName == "CI" and .ci.event == "push" and .ci.attempt == 1 and
    .ci.headBranch == "main" and .ci.headSha == $sha and .ci.status == "completed" and
    .ci.conclusion == "success" and
    (.schedules | type == "array" and length == 3) and
    ([.schedules[].workflowName] | sort) == (["Post Publish", "Release Please", "Repository Hygiene"] | sort) and
    all(.schedules[];
      .event == "schedule" and .attempt == 1 and .headBranch == "main" and
      .headSha == $sha and .status == "completed" and .conclusion == "success")
  ' "$inputs" >/dev/null || fail "selected CI or schedule evidence is not exact attempt-1 natural evidence"
}

require_report_boundary() {
  local repo="$1" report="$2" rel
  case "$report" in "$repo"/tmp/*/report.json) ;; *) fail "terminal report path is outside ignored capture storage" ;; esac
  rel=${report#"$repo"/}
  ! "$MAILGLASS_GIT" -C "$repo" --literal-pathspecs ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 ||
    fail "terminal report target is tracked"
  "$MAILGLASS_GIT" -C "$repo" check-ignore -q -- "$rel" || fail "terminal report target is not ignored"
}

main() {
  local repo_arg="${1:-}" authority_arg="${2:-}" expected_oid="${3:-}" report_arg="${4:-}" inputs_arg="${5:-}"
  local repo authority_root report inputs origin branch report_tmp
  [ "$#" -eq 5 ] || fail "usage: $0 REPO AUTHORITY_ROOT EXPECTED_OID REPORT INPUTS"
  repo=$(cd "$repo_arg" 2>/dev/null && pwd -P) || fail "repository does not exist"
  authority_root=$(cd "$authority_arg" 2>/dev/null && pwd -P) || fail "authority root does not exist"
  [ "$authority_root" != "$repo" ] || fail "authority root must be private"
  case "$(basename "$authority_root")" in mailglass-finalize-v2-7-*) ;; *) fail "authority root is unexpected" ;; esac
  report=$(cd "$(dirname "$report_arg")" 2>/dev/null && pwd -P)/$(basename "$report_arg") || fail "report parent is missing"
  inputs=$(cd "$(dirname "$inputs_arg")" 2>/dev/null && pwd -P)/$(basename "$inputs_arg") || fail "inputs parent is missing"
  case "$inputs" in "$authority_root"/*) ;; *) fail "terminal inputs escaped authenticated stage" ;; esac

  require_authority "$repo" "$expected_oid"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain is not empty"
  require_archive_contract "$authority_root" "$expected_oid"
  require_selected_evidence "$inputs" "$expected_oid"
  require_report_boundary "$repo" "$report"

  if [ "${MAILGLASS_MILESTONE_FIXTURE:-}" != 1 ]; then
    branch=$("$MAILGLASS_GIT" -C "$repo" branch --show-current 2>/dev/null || true)
    [ "$branch" = main ] || fail "canonical checkout is not on main"
    origin=$("$MAILGLASS_GIT" -C "$repo" remote get-url origin 2>/dev/null || true)
    case "$origin" in
      "git@github.com:$expected_repository"|"git@github.com:$expected_repository.git"|\
      "https://github.com/$expected_repository"|"https://github.com/$expected_repository.git"|\
      "ssh://git@github.com/$expected_repository"|"ssh://git@github.com/$expected_repository.git") ;;
      *) fail "origin is not $expected_repository" ;;
    esac
    "$MAILGLASS_GIT" -C "$repo" fetch origin main >/dev/null || fail "git fetch origin main failed"
    [ "$("$MAILGLASS_GIT" -C "$repo" rev-parse refs/remotes/origin/main 2>/dev/null || true)" = "$expected_oid" ] ||
      fail "HEAD does not equal origin/main"
  fi

  require_authority "$repo" "$expected_oid"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed before report write"
  report_tmp=$(mktemp "$(dirname "$report")/.report.XXXXXX") || fail "could not allocate terminal report"
  "$MAILGLASS_JQ" -n --arg sha "$expected_oid" --slurpfile evidence "$inputs" '
    {
      schema: "mailglass-finalize-milestone-report-v1",
      milestone: "v2.7",
      status: "pass",
      expected_main_sha: $sha,
      components: {
        archive: {status: "pass", phases: [161, 162, 163, 164, 165]},
        audit: {status: "pass", requirements: "16/16", phases: "5/5", integration: "16/16", flows: "5/5"},
        ci: $evidence[0].ci,
        schedules: $evidence[0].schedules
      }
    }
  ' >"$report_tmp" || { rm -f "$report_tmp"; fail "could not serialize terminal report"; }
  chmod 600 "$report_tmp"
  mv "$report_tmp" "$report"

  # The report move above is the final filesystem effect. Everything below is read-only.
  require_authority "$repo" "$expected_oid"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed after report write"
  "$MAILGLASS_JQ" -e --arg sha "$expected_oid" '.status == "pass" and .expected_main_sha == $sha' "$report" >/dev/null ||
    fail "terminal report is not pass"
  printf 'finalize-milestone v2.7: terminal evidence passed at %s\n' "$expected_oid"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
