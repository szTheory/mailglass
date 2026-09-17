#!/usr/bin/env bash
# Offline fixture test for guard-release-trigger decision logic.
#
# No GitHub round-trip. This sources the REAL decision library the workflow
# sources — it does not re-implement it. The previous version of this file
# carried a hand-maintained copy annotated "logically identical to the
# workflow's inline shell", which is a drift hazard: nothing enforced the
# claim. Sourcing removes the second copy entirely.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/guard_release_trigger.sh"

FAILURES=0

# assert_case <label> <expected: PASS|FAIL> <title> <file_list_string> [body]
assert_case() {
  local label="$1" expected="$2" title="$3" file_list="$4" body="${5:-}"

  local result="PASS"
  guard_decision "$title" "$file_list" "$body" || result="FAIL"

  if [[ "$result" == "$expected" ]]; then
    echo "  OK  [$label]"
  else
    echo "  FAIL [$label]: expected $expected, got $result"
    echo "       title='$title'"
    echo "       files=$(echo "$file_list" | tr '\n' ' ')"
    FAILURES=$(( FAILURES + 1 ))
  fi
}

# assert_hygiene <label> <expected: PASS|FAIL> <subject>
assert_hygiene() {
  local label="$1" expected="$2" subject="$3"

  local result="PASS"
  guard_subject_hygiene "$subject" || result="FAIL"

  if [[ "$result" == "$expected" ]]; then
    echo "  OK  [$label]"
  else
    echo "  FAIL [$label]: expected $expected, got $result"
    echo "       subject='$subject'"
    FAILURES=$(( FAILURES + 1 ))
  fi
}

echo "guard-release-trigger offline fixture test"
echo "------------------------------------------"

# --- The original five edge cases from 93-RESEARCH.md Open Item 1 -----------

# Case 1: Mixed — feat: touching brandbook/ AND real lib/ code -> PASS
assert_case "1: mixed feat: + lib/ code" "PASS" \
  "feat: add sealed-flap brand" \
  "$(printf 'brandbook/x.svg\nlib/mailglass/foo.ex')"

# Case 2: Brand/planning-only, NON-bumping type (docs:) -> PASS
assert_case "2: docs: brand/planning-only" "PASS" \
  "docs: update brand book" \
  "$(printf 'brandbook/x.svg\n.planning/y.md')"

# Case 3: Brand/planning-only, BUMPING type (feat:) -> FAIL (the 1.6.x bug)
assert_case "3: feat: brand-only (the 1.6.x bug)" "FAIL" \
  "feat: add sealed-flap brand" \
  "$(printf 'brandbook/x.svg')"

# Case 3b: Planning-only, bumping type (fix:) -> FAIL
assert_case "3b: fix: .planning-only" "FAIL" \
  "fix: correct roadmap entry" \
  "$(printf '.planning/ROADMAP.md')"

# Case 4: Bang on a non-feat/fix type, brand-only -> FAIL (major via the bang)
assert_case "4: chore!: .planning-only (bang)" "FAIL" \
  "chore!: overhaul planning docs" \
  "$(printf '.planning/y.md')"

# Case 5: Non-conventional title -> PASS (defer to pr-title.yml)
assert_case "5: non-conventional title" "PASS" \
  "Update the README" \
  "$(printf 'README.md')"

# Case 6: Bumping type, EMPTY file list -> PASS (proves the 0-element branch is
# reachable; guards against the WR-01 echo/printf drift).
assert_case "6: feat: empty file list" "PASS" \
  "feat: nothing changed" \
  ""

# --- Shipped-documentation cases (the #222 defect) --------------------------
# These are the cases the path-prefix-only guard could not see: documentation
# that lives INSIDE a package and inside its Hex `files` allowlist.

# Case 7: #222 verbatim — feat: on a package README alone -> FAIL.
# d272e824 changed only mailglass_inbound/README.md and proposed 2.3.0.
assert_case "7: feat: package README only (#222)" "FAIL" \
  "feat(164-03): clarify current package compatibility" \
  "$(printf 'mailglass_inbound/README.md')"

# Case 8: Same edit, correctly typed -> PASS.
assert_case "8: docs: package README only" "PASS" \
  "docs(inbound): clarify current package compatibility" \
  "$(printf 'mailglass_inbound/README.md')"

# Case 9: fix: on a package docs/ tree alone -> FAIL.
assert_case "9: fix: package docs/ only" "FAIL" \
  "fix(inbound): correct the operator guide" \
  "$(printf 'mailglass_inbound/docs/inbound-operator.md')"

# Case 10: fix: on root guides/ alone -> FAIL.
assert_case "10: fix: root guides/ only" "FAIL" \
  "fix: correct the jobs guide" \
  "$(printf 'guides/jobs.md')"

# Case 11: Non-markdown asset inside a docs tree -> FAIL.
assert_case "11: feat: docs/ image asset only" "FAIL" \
  "feat: add an architecture diagram" \
  "$(printf 'mailglass_admin/docs/architecture.png')"

# Case 12: README alongside real code -> PASS. A feature landing with its
# documentation is the normal, intended shape and must not be blocked.
assert_case "12: feat: README + lib/ code" "PASS" \
  "feat(inbound): add a routing predicate" \
  "$(printf 'mailglass_inbound/README.md\nmailglass_inbound/lib/mailglass_inbound/router.ex')"

# Case 13: mix.exs is shippable code, not documentation -> PASS.
# A dependency bump or version change typed fix: is legitimate.
assert_case "13: fix: mix.exs only" "PASS" \
  "fix(deps): bump the swoosh floor" \
  "$(printf 'mailglass_inbound/mix.exs')"

# Case 14: priv/ assets are shippable -> PASS.
assert_case "14: fix: priv/static bundle" "PASS" \
  "fix(admin): rebuild the stylesheet bundle" \
  "$(printf 'mailglass_admin/priv/static/app.css')"

# --- Subject hygiene cases (the literal backslash-n defect) -----------------

# Case 15-17: the three phase-164 subjects, verbatim.
assert_hygiene "15: d272e824 literal escape" "FAIL" \
  'feat(164-03): clarify current package compatibility\n\n- Mark each package README'

assert_hygiene "16: cb5020c7 literal escape" "FAIL" \
  'feat(162-08): recover idle scheduled release control\n\n- Discover exact open'

assert_hygiene "17: eff68923 literal escape" "FAIL" \
  'fix(162-09): select CI by checkout SHA\n\n- Query ci.yml runs with'

# Case 18: a clean subject -> PASS.
assert_hygiene "18: clean subject" "PASS" \
  "fix(inbound): select CI by checkout SHA"

# Case 19: a subject legitimately discussing escapes is still rejected.
# Documented as accepted strictness: the guard cannot distinguish intent, and
# the correct home for that discussion is the commit body.
assert_hygiene "19: subject mentioning an escape" "FAIL" \
  'docs: explain why \n must not appear in a subject'

# --- Test-tree cases -------------------------------------------------------

# Case 25: a test-only commit typed fix: is mistyped and must FAIL. Since #265
# mailglass_admin/test is also in that package's exclude-paths, so config alone
# would stop the bump today — the guard still fails it, because the rule is
# about the commit type matching its content, not about the current config.
assert_case "25: fix: admin test tree only" "FAIL" \
  "fix(admin): correct the replay assertion" \
  "$(printf 'mailglass_admin/test/mailglass_admin/inbound_live_test.exs')"

# Case 26: correctly typed -> PASS.
assert_case "26: test: admin test tree only" "PASS" \
  "test(admin): correct the replay assertion" \
  "$(printf 'mailglass_admin/test/mailglass_admin/inbound_live_test.exs')"

# Case 27: a fix landing with its regression test is the normal shape -> PASS.
assert_case "27: fix: lib + test together" "PASS" \
  "fix(admin): name the real cause when replay is unavailable" \
  "$(printf 'mailglass_admin/lib/mailglass_admin/inbound_live.ex\nmailglass_admin/test/mailglass_admin/inbound_live_test.exs')"

# Case 28: scripts/ is deliberately NOT classified — it is in core's
# exclude-paths and outside both sibling roots, so it cannot bump anything.
# Flagging it would fail commits that cannot cause the defect -> PASS.
assert_case "28: fix: scripts/ only (cannot bump)" "PASS" \
  "fix(release): correct the close-out gate" \
  "$(printf 'scripts/release_policy_close_out.sh')"

# --- Release-As: escape-hatch cases ----------------------------------------
# A deliberate docs-only release must remain possible, or the guard becomes the
# thing that strands a release.

# Case 20: 3edc95f0's real shape — MAINTAINING.md alone, typed fix: -> FAIL
# without the footer. MAINTAINING.md is in the core package `files` allowlist
# and is NOT in release-please exclude-paths, so this genuinely bumps core.
assert_case "20: fix: MAINTAINING.md only, no footer" "FAIL" \
  "fix(publish): document tarball allowlist protocol" \
  "$(printf 'MAINTAINING.md')"

# Case 21: the same change with an explicit Release-As: footer -> PASS.
assert_case "21: fix: MAINTAINING.md only + Release-As" "PASS" \
  "fix(publish): document tarball allowlist protocol and release 2.2.1" \
  "$(printf 'MAINTAINING.md')" \
  "$(printf 'Cut a patch release for the documented protocol.\n\nRelease-As: 2.2.1')"

# Case 22: the footer overrides the brand/planning case too.
assert_case "22: feat: brand-only + Release-As" "PASS" \
  "feat: add sealed-flap brand" \
  "$(printf 'brandbook/x.svg')" \
  "$(printf 'Release-As: 1.9.0')"

# Case 23: prose merely mentioning the footer name does NOT open the hatch —
# the pattern requires the footer form followed by a version number.
assert_case "23: body mentions Release-As in prose" "FAIL" \
  "fix: correct roadmap entry" \
  "$(printf '.planning/ROADMAP.md')" \
  "$(printf 'We should document how Release-As works one day.')"

# Case 24: a body with no footer at all behaves as before.
assert_case "24: fix: planning-only, ordinary body" "FAIL" \
  "fix: correct roadmap entry" \
  "$(printf '.planning/ROADMAP.md')" \
  "$(printf 'Just a routine correction.')"

echo "------------------------------------------"
if [[ "$FAILURES" -eq 0 ]]; then
  echo "All cases passed."
  exit 0
else
  echo "$FAILURES case(s) failed."
  exit 1
fi
