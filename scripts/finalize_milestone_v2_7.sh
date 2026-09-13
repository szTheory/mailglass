#!/usr/bin/env bash
set -euo pipefail
PATH=/usr/bin:/bin
export PATH

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
  awk -v path="$key" '
    BEGIN {
      parts = split(path, key_parts, ".")
      if (parts < 1 || parts > 2) exit 64
    }
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { closed = 1; in_frontmatter = 0; next }
    !in_frontmatter { next }
    parts == 1 && $0 ~ ("^" key_parts[1] ":[[:space:]]*") {
      count++
      value = $0
      sub("^" key_parts[1] ":[[:space:]]*", "", value)
      next
    }
    parts == 2 && $0 ~ ("^" key_parts[1] ":[[:space:]]*$") {
      parent_count++
      in_parent = 1
      next
    }
    parts == 2 && in_parent && $0 ~ /^[^[:space:]]/ { in_parent = 0 }
    parts == 2 && in_parent && $0 ~ ("^  " key_parts[2] ":[[:space:]]*") {
      count++
      value = $0
      sub("^  " key_parts[2] ":[[:space:]]*", "", value)
    }
    END {
      if (!closed || count != 1 || (parts == 2 && parent_count != 1)) exit 65
      gsub(/^\"|\"$/, "", value)
      print value
    }
  ' "$file"
}

require_frontmatter_value() {
  local file="$1" key="$2" expected="$3" diagnostic="$4" observed
  observed=$(frontmatter_value "$file" "$key") || fail "$diagnostic is missing or duplicated"
  [ "$observed" = "$expected" ] || fail "$diagnostic is not $expected"
}

require_heading() {
  local file="$1" pattern="$2" diagnostic="$3"
  grep -E -- "$pattern" "$file" >/dev/null || fail "$diagnostic"
}

require_archive_contract() {
  local authority_root="$1" expected_oid="$2" repo="$3" audit audit_oid phase dir validation phases=()
  audit="$authority_root/$archive_root/v2.7-MILESTONE-AUDIT.md"
  require_frontmatter_value "$audit" status passed "canonical audit status"
  audit_oid=$(frontmatter_value "$audit" audited_head)
  [[ "$audit_oid" =~ ^[0-9a-f]{40}$ ]] || fail "stale audit: audited_head is not one full OID"
  "$MAILGLASS_GIT" -C "$repo" cat-file -e "$audit_oid^{commit}" 2>/dev/null ||
    fail "stale audit: audited_head does not name a commit"
  "$MAILGLASS_GIT" -C "$repo" merge-base --is-ancestor "$audit_oid" "$expected_oid" 2>/dev/null ||
    fail "stale audit: audited_head is not an ancestor of terminal authority"
  require_frontmatter_value "$audit" scores.requirements 16/16 "canonical audit requirements score"
  require_frontmatter_value "$audit" scores.phases 5/5 "canonical audit phase score"
  require_frontmatter_value "$audit" scores.integration 16/16 "canonical audit integration score"
  require_frontmatter_value "$audit" scores.flows 5/5 "canonical audit flow score"
  require_frontmatter_value "$audit" accepted_policy_debt.open_pull_requests 14 "canonical audit accepted policy-debt PR count"
  require_frontmatter_value "$audit" accepted_policy_debt.disposition accepted "canonical audit policy-debt disposition"

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
    require_frontmatter_value "$validation" status validated "archived phase $phase status"
  done
  shopt -u nullglob

  require_heading "$authority_root/.planning/MILESTONES.md" '^## v2\.7 Repository Stewardship & Operational Hygiene \((Completed|Shipped):' "milestone ledger omits the completed v2.7 record"
  require_frontmatter_value "$authority_root/.planning/STATE.md" milestone v2.7 "state milestone"
  require_frontmatter_value "$authority_root/.planning/STATE.md" status archived "state status"
  require_heading "$authority_root/.planning/PROJECT.md" '^## Completed Milestone: v2\.7 Repository Stewardship & Operational Hygiene$' "project omits the completed v2.7 record"
  "$MAILGLASS_JQ" -e '.milestone == "v2.7" and (.status == "archived" or .milestone_status == "archived")' \
    "$authority_root/.planning/state.json" >/dev/null || fail "machine state does not agree that v2.7 is archived"
  [ -f "$authority_root/$archive_root/v2.7-ROADMAP.md" ] || fail "archived ROADMAP is missing"
  [ -f "$authority_root/$archive_root/v2.7-REQUIREMENTS.md" ] || fail "archived REQUIREMENTS is missing"
  ! compgen -G "$authority_root/.planning/phases/16[1-5]-*" >/dev/null || fail "live/archive lifecycle disagreement"
}

mark_report_blocked() {
  local report="$1" reason="$2" tmp
  tmp="${report}.blocked"
  "$MAILGLASS_JQ" --arg reason "$reason" '.status = "blocked" | .reason = $reason' "$report" >"$tmp" || return 1
  mv "$tmp" "$report"
}

require_selected_evidence() {
  local inputs="$1" expected_oid="$2"
  "$MAILGLASS_JQ" -e --arg sha "$expected_oid" '
    type == "object" and
    (.ci | type == "object") and
    .ci.workflowName == "CI" and .ci.event == "push" and .ci.attempt == 1 and
    .ci.headBranch == "main" and .ci.headSha == $sha and .ci.status == "completed" and
    .ci.conclusion == "success" and
    (.executable | type == "object") and
    (.executable.path | type == "string" and length > 0) and
    (.executable.sha256 | test("^[0-9a-f]{64}$")) and
    .executable.source_oid == $sha and .executable.mode == "0500" and
    (.runtime_closure | type == "array" and length == 5) and
    all(.runtime_closure[];
      (.name | type == "string" and length > 0) and
      (.path | type == "string" and startswith("/")) and
      (.sha256 | test("^[0-9a-f]{64}$")) and
      (.version | type == "string" and length > 0)) and
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
  [ ! -e "$report" ] && [ ! -L "$report" ] || fail "terminal report target already exists"
}

main() {
  local repo_arg="${1:-}" authority_arg="${2:-}" expected_oid="${3:-}" report_arg="${4:-}" inputs_arg="${5:-}"
  local repo authority_root report inputs origin branch report_tmp report_schema report_status
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
  require_archive_contract "$authority_root" "$expected_oid" "$repo"
  require_selected_evidence "$inputs" "$expected_oid"
  require_report_boundary "$repo" "$report"

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

  require_authority "$repo" "$expected_oid"
  [ -z "$(stable_porcelain "$repo")" ] || fail "stable porcelain changed before report write"
  report_tmp=$(mktemp "$(dirname "$report")/.report.XXXXXX") || fail "could not allocate terminal report"
  if [ "${MAILGLASS_MILESTONE_FIXTURE:-}" = 1 ]; then
    report_schema=mailglass-finalize-milestone-fixture-v1
    report_status=fixture-only
  else
    report_schema=mailglass-finalize-milestone-report-v1
    report_status=pass
  fi
  "$MAILGLASS_JQ" -n --arg sha "$expected_oid" --arg schema "$report_schema" --arg status "$report_status" --slurpfile evidence "$inputs" '
    {
      schema: $schema,
      milestone: "v2.7",
      status: $status,
      expected_main_sha: $sha,
      executable: $evidence[0].executable,
      runtime_closure: $evidence[0].runtime_closure,
      components: {
        archive: {status: "pass", phases: [161, 162, 163, 164, 165]},
        audit: {status: "pass", requirements: "16/16", phases: "5/5", integration: "16/16", flows: "5/5"},
        ci: $evidence[0].ci,
        schedules: $evidence[0].schedules
      }
    }
  ' >"$report_tmp" || { rm -f "$report_tmp"; fail "could not serialize terminal report"; }
  chmod 600 "$report_tmp"
  mv -n "$report_tmp" "$report" || { rm -f "$report_tmp"; fail "could not publish terminal report"; }
  [ ! -e "$report_tmp" ] || { rm -f "$report_tmp"; fail "terminal report target appeared before publication"; }

  case "${MAILGLASS_MILESTONE_MUTATE_AFTER_REPORT:-}" in
    "") ;;
    move-head)
      [ "${MAILGLASS_MILESTONE_FIXTURE:-}" = 1 ] || fail "post-report mutation hook is fixture-only"
      printf 'move\n' >"$repo/.phase-165-after-report"
      "$MAILGLASS_GIT" -C "$repo" add -- .phase-165-after-report
      "$MAILGLASS_GIT" -C "$repo" commit -q -m "fixture head move after report"
      ;;
    dirty-worktree)
      [ "${MAILGLASS_MILESTONE_FIXTURE:-}" = 1 ] || fail "post-report mutation hook is fixture-only"
      printf 'dirty\n' >"$repo/.phase-165-after-report"
      ;;
    *) fail "unknown post-report mutation hook" ;;
  esac

  # The report move above is the final filesystem effect. Everything below is read-only.
  if ! require_authority "$repo" "$expected_oid"; then
    mark_report_blocked "$report" "authority commit changed after report write"
    fail "authority commit changed after report write"
  fi
  if [ -n "$(stable_porcelain "$repo")" ]; then
    mark_report_blocked "$report" "stable porcelain changed after report write"
    fail "stable porcelain changed after report write"
  fi
  if [ "${MAILGLASS_MILESTONE_FIXTURE:-}" = 1 ]; then
    "$MAILGLASS_JQ" -e --arg sha "$expected_oid" \
      '.schema == "mailglass-finalize-milestone-fixture-v1" and .status == "fixture-only" and .expected_main_sha == $sha' \
      "$report" >/dev/null || fail "fixture report crossed the production report boundary"
    printf 'finalize-milestone v2.7: fixture evidence validated at %s\n' "$expected_oid"
  else
    "$MAILGLASS_JQ" -e --arg sha "$expected_oid" \
      '.schema == "mailglass-finalize-milestone-report-v1" and .status == "pass" and .expected_main_sha == $sha' \
      "$report" >/dev/null || fail "terminal report is not pass"
    printf 'finalize-milestone v2.7: terminal evidence passed at %s\n' "$expected_oid"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
