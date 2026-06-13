#!/usr/bin/env bash
# Offline fixture test for guard-release-trigger decision logic.
# No GitHub round-trip — the decision function is factored out and exercised
# against all five edge cases from the research edge-case table.
# Exits 0 only if all five cases assert correctly.
set -euo pipefail

GUARDED=( "brandbook/" ".planning/" "prompts/" )
FAILURES=0

# ---------------------------------------------------------------------------
# Decision function — logically identical to the workflow's inline shell.
# Args: $1 = PR title string, $2 = newline-delimited file list string
# Returns: 0 (PASS) or 1 (FAIL — the guard fires)
# ---------------------------------------------------------------------------
guard_decision() {
  local pr_title="$1"
  local file_list="$2"

  # 1. Extract conventional-commit type + bang from PR title.
  local type="" bang=""
  if [[ "$pr_title" =~ ^([a-z]+)(\([^\)]*\))?(!)?: ]]; then
    type="${BASH_REMATCH[1]}"
    bang="${BASH_REMATCH[3]}"
  else
    # Non-conventional title — defer to pr-title.yml; PASS here.
    return 0
  fi

  # 2. Is this a bump-triggering title?
  #    Title-level breaking change is the "!" marker; "BREAKING CHANGE:" is a body
  #    footer release-please reads from the commit body, not the PR title (mirrors
  #    the workflow — see guard-release-trigger.yml step 2).
  local is_bump="false"
  case "$type" in
    feat|fix) is_bump="true" ;;
  esac
  [[ -n "$bang" ]] && is_bump="true"

  if [[ "$is_bump" != "true" ]]; then
    # Non-bumping type — short-circuit PASS.
    return 0
  fi

  # 3. Parse the file list. Use printf '%s' (not echo) so an empty string yields
  #    ZERO bytes -> a 0-element array, faithfully matching the workflow's
  #    `gh pr view --json files --jq` (which emits nothing for an empty file set).
  #    `echo ""` would emit a lone newline -> a 1-element array of "", making the
  #    0-element branch below unreachable and silently untested (WR-01).
  mapfile -t files < <(printf '%s' "$file_list")

  if [[ "${#files[@]}" -eq 0 ]]; then
    return 0
  fi

  # 4. Subset test — are ALL changed files inside the guarded path set?
  local all_guarded="true"
  for f in "${files[@]}"; do
    local in_guard="false"
    for g in "${GUARDED[@]}"; do
      if [[ "$f" == "$g"* ]]; then in_guard="true"; break; fi
    done
    if [[ "$in_guard" != "true" ]]; then all_guarded="false"; break; fi
  done

  # 5. Decision.
  if [[ "$all_guarded" == "true" ]]; then
    return 1  # FAIL — the 1.6.x accidental-release pattern
  fi

  return 0  # PASS — bump-triggering type touches real package code
}

# ---------------------------------------------------------------------------
# Test harness helper.
# assert_case <label> <expected: PASS|FAIL> <title> <file_list_string>
# ---------------------------------------------------------------------------
assert_case() {
  local label="$1"
  local expected="$2"
  local title="$3"
  local file_list="$4"

  local result="PASS"
  if ! guard_decision "$title" "$file_list"; then
    result="FAIL"
  fi

  if [[ "$result" == "$expected" ]]; then
    echo "  OK  [$label]"
  else
    echo "  FAIL [$label]: expected $expected, got $result"
    echo "       title='$title'"
    echo "       files=$(echo "$file_list" | tr '\n' ' ')"
    FAILURES=$(( FAILURES + 1 ))
  fi
}

# ---------------------------------------------------------------------------
# The five edge cases from 93-RESEARCH.md Open Item 1 edge-case table.
# ---------------------------------------------------------------------------
echo "guard-release-trigger offline fixture test"
echo "------------------------------------------"

# Case 1: Mixed — feat: touching brandbook/ AND real lib/ code -> PASS
# (A real release is intended when at least one non-guarded file is present.)
assert_case "1: mixed feat: + lib/ code" "PASS" \
  "feat: add sealed-flap brand" \
  "$(printf 'brandbook/x.svg\nlib/mailglass/foo.ex')"

# Case 2: Brand/planning-only, NON-bumping type (docs:) -> PASS
# (Short-circuits at the is_bump check; no files are even fetched.)
assert_case "2: docs: brand/planning-only" "PASS" \
  "docs: update brand book" \
  "$(printf 'brandbook/x.svg\n.planning/y.md')"

# Case 3: Brand/planning-only, BUMPING type (feat:) -> FAIL
# (The 1.6.x bug: feat: confined to brandbook/ should not cut a core release.)
assert_case "3: feat: brand-only (the 1.6.x bug)" "FAIL" \
  "feat: add sealed-flap brand" \
  "$(printf 'brandbook/x.svg')"

# Case 3b: Planning-only, bumping type (fix:) -> FAIL
assert_case "3b: fix: .planning-only" "FAIL" \
  "fix: correct roadmap entry" \
  "$(printf '.planning/ROADMAP.md')"

# Case 4: Bang/breaking on a non-feat/fix type, brand-only -> FAIL
# (A "chore!:" is a major bump via the bang — must be caught even on chore.)
assert_case "4: chore!: .planning-only (bang)" "FAIL" \
  "chore!: overhaul planning docs" \
  "$(printf '.planning/y.md')"

# Case 5: Non-conventional title -> PASS (defer to pr-title.yml, no double-failure)
assert_case "5: non-conventional title" "PASS" \
  "Update the README" \
  "$(printf 'README.md')"

# Case 6: Bumping type with an EMPTY file list -> PASS (the "no files reported"
# branch; proves the 0-element array path the workflow relies on is reachable —
# guards against the WR-01 echo/printf drift).
assert_case "6: feat: empty file list" "PASS" \
  "feat: nothing changed" \
  ""

echo "------------------------------------------"
if [[ "$FAILURES" -eq 0 ]]; then
  echo "All cases passed."
  exit 0
else
  echo "$FAILURES case(s) failed."
  exit 1
fi
