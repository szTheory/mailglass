#!/usr/bin/env bash
# Three-way live audit of `.planning/STATE.md`'s `#NNN` PR/issue references
# against live GitHub state.
#
# STATE.md is prohibited (DOCS-01) from hardcoding an open-PR/open-issue
# snapshot; any `#NNN` reference it does carry must describe a fact that is
# permanently true (e.g. "PR #222 is closed"). This script is how that claim
# class stays machine-checkable rather than proofread-once-and-forgotten.
#
# This is a human- or `workflow_dispatch`-invokable audit, NOT a registered
# scheduled control -- the milestone's alert budget permits exactly one new
# scheduled control (STAND-01's Dependabot grouping) and this is not it.
# Registering this script as a second scheduled workflow would spend budget
# this phase was not given. See 167-04-PLAN.md execution preamble.
#
# Exit codes (D-34: a non-verdict must be observably distinct from a pass):
#   0 - pass: every reference resolved and STATE.md's prose does not
#       contradict live GitHub state (or zero references were found).
#   1 - blocked: at least one reference resolved but STATE.md's prose
#       contradicts its live state (says "open" for a closed/merged PR, or
#       vice versa).
#   2 - cannot_check: `gh` is unavailable, unauthenticated, or its response
#       could not be parsed for at least one reference.
#
# usage: check_state_md_pr_refs.sh [--target PATH] [--format text|json]
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: check_state_md_pr_refs.sh [--target PATH] [--format text|json]

  --target PATH     File to scan for #NNN references (default: .planning/STATE.md)
  --format text|json  Output format (default: text)
EOF
}

target=".planning/STATE.md"
format="text"
repo="szTheory/mailglass"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) target=${2:?}; shift 2 ;;
    --format) format=${2:?}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 64 ;;
  esac
done

if [ "$format" != "text" ] && [ "$format" != "json" ]; then
  echo "ERROR: --format must be text or json" >&2
  exit 64
fi

if [ ! -f "$target" ]; then
  echo "ERROR: target file not found: $target" >&2
  exit 64
fi

# --- Step 1: extract #NNN references, excluding URL-embedded ones, preserving
# first-appearance order, deduplicated. ---
#
# A reference is excluded if the '#' is immediately preceded by '/' (a URL
# path segment, e.g. "github.com/owner/repo/pull#123") or if the token is
# preceded on the same line by "github.com" anywhere before it. We keep the
# extraction simple and conservative: grep every #NNN token with its
# preceding character, then filter in a second pass.
mapfile -t raw_matches < <(
  grep -noE '(^|[^/A-Za-z0-9_])#[0-9]+' "$target" 2>/dev/null || true
)

declare -a ordered_refs=()
declare -A seen=()

for entry in "${raw_matches[@]}"; do
  # entry looks like "LINE:PREFIX#NNN" or "LINE:#NNN"
  lineno=${entry%%:*}
  rest=${entry#*:}
  # Extract just the #NNN part
  num_token=$(printf '%s' "$rest" | grep -oE '#[0-9]+$')
  [ -n "$num_token" ] || continue

  line_content=$(sed -n "${lineno}p" "$target")

  # Exclude if this #NNN occurs inside a github.com URL on the same line by
  # checking whether the token is preceded on that line by "github.com" with
  # only URL-safe characters (no whitespace) in between, or immediately
  # preceded by '/'.
  excluded=false
  # immediately preceded by '/'
  if printf '%s' "$line_content" | grep -qE "/${num_token}([^0-9]|$)"; then
    excluded=true
  fi
  if printf '%s' "$line_content" | grep -qE "github\.com[^[:space:]]*${num_token}([^0-9]|$)"; then
    excluded=true
  fi

  if [ "$excluded" = true ]; then
    continue
  fi

  if [ -z "${seen[$num_token]:-}" ]; then
    seen[$num_token]=1
    ordered_refs+=("$num_token")
  fi
done

generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Step 2: empty-input contract. ---
if [ "${#ordered_refs[@]}" -eq 0 ]; then
  if [ "$format" = "json" ]; then
    jq -n --arg status "pass" --arg target "$target" --arg generated_at "$generated_at" \
      '{status: $status, target: $target, generated_at: $generated_at, checks: []}'
  else
    echo "pass: 0 references found in $target"
  fi
  exit 0
fi

# --- Step 3-4: resolve each reference against live GitHub, classify. ---
gh_available=true
if ! command -v gh >/dev/null 2>&1; then
  gh_available=false
elif ! gh auth status >/dev/null 2>&1; then
  gh_available=false
fi

declare -a check_names=()
declare -a check_statuses=()
declare -a check_messages=()
declare -a check_details=()

for num in "${ordered_refs[@]}"; do
  n="${num#\#}"
  name="#${n}"

  if [ "$gh_available" = false ]; then
    check_names+=("$name")
    check_statuses+=("cannot_check")
    check_messages+=("gh is unavailable or unauthenticated; $name was not checked.")
    check_details+=("{}")
    continue
  fi

  json_out=""
  live_state=""
  live_title=""
  resolved=false

  if json_out=$(gh pr view "$n" --repo "$repo" --json state,title 2>/dev/null); then
    if live_state=$(printf '%s' "$json_out" | jq -er '.state' 2>/dev/null); then
      live_title=$(printf '%s' "$json_out" | jq -er '.title' 2>/dev/null || echo "")
      resolved=true
    fi
  fi

  if [ "$resolved" = false ]; then
    if json_out=$(gh issue view "$n" --repo "$repo" --json state,title 2>/dev/null); then
      if live_state=$(printf '%s' "$json_out" | jq -er '.state' 2>/dev/null); then
        live_title=$(printf '%s' "$json_out" | jq -er '.title' 2>/dev/null || echo "")
        resolved=true
      fi
    fi
  fi

  if [ "$resolved" = false ]; then
    check_names+=("$name")
    check_statuses+=("cannot_check")
    check_messages+=("$name could not be resolved via gh pr view or gh issue view.")
    check_details+=("{}")
    continue
  fi

  # Find the line(s) mentioning this reference, to inspect STATE.md's prose.
  line_with_ref=$(grep -n "$name" "$target" | head -1 | cut -d: -f2- || true)
  lower_line=$(printf '%s' "$line_with_ref" | tr '[:upper:]' '[:lower:]')

  says_open=false
  says_closed=false
  if printf '%s' "$lower_line" | grep -qE '\bopen\b'; then
    says_open=true
  fi
  if printf '%s' "$lower_line" | grep -qE '\b(closed|merged)\b'; then
    says_closed=true
  fi

  status="pass"
  message="$name ($live_state) is consistent with STATE.md's prose."

  if [ "$says_open" = true ] && { [ "$live_state" = "CLOSED" ] || [ "$live_state" = "MERGED" ]; }; then
    status="blocked"
    message="$name is described as open in STATE.md but GitHub reports $live_state."
  elif [ "$says_closed" = true ] && [ "$live_state" = "OPEN" ]; then
    status="blocked"
    message="$name is described as closed/merged in STATE.md but GitHub reports OPEN."
  fi

  check_names+=("$name")
  check_statuses+=("$status")
  check_messages+=("$message")
  details_json=$(jq -n --arg state "$live_state" --arg title "$live_title" '{state: $state, title: $title}')
  check_details+=("$details_json")
done

# --- Step 5: aggregate. ---
overall="pass"
for s in "${check_statuses[@]}"; do
  if [ "$s" = "cannot_check" ]; then
    overall="cannot_check"
    break
  fi
done
if [ "$overall" != "cannot_check" ]; then
  for s in "${check_statuses[@]}"; do
    if [ "$s" = "blocked" ]; then
      overall="blocked"
      break
    fi
  done
fi

external_status() {
  case "$1" in
    cannot_check) echo "cannot-check" ;;
    *) echo "$1" ;;
  esac
}

# --- Step 6/7: emit. ---
if [ "$format" = "json" ]; then
  checks_json="[]"
  for i in "${!check_names[@]}"; do
    entry=$(jq -n \
      --arg name "${check_names[$i]}" \
      --arg status "$(external_status "${check_statuses[$i]}")" \
      --arg message "${check_messages[$i]}" \
      --argjson details "${check_details[$i]}" \
      '{name: $name, status: $status, message: $message, details: $details}')
    checks_json=$(printf '%s' "$checks_json" | jq --argjson entry "$entry" '. + [$entry]')
  done
  jq -n \
    --arg status "$(external_status "$overall")" \
    --arg target "$target" \
    --arg generated_at "$generated_at" \
    --argjson checks "$checks_json" \
    '{status: $status, target: $target, generated_at: $generated_at, checks: $checks}'
else
  echo "$(external_status "$overall"): ${#check_names[@]} check(s) against $target"
  for i in "${!check_names[@]}"; do
    echo "$(external_status "${check_statuses[$i]}") ${check_names[$i]}: ${check_messages[$i]}"
  done
fi

case "$overall" in
  pass) exit 0 ;;
  cannot_check) exit 2 ;;
  *) exit 1 ;;
esac
