#!/usr/bin/env bash
# Verify that every record of the published baseline agrees with the release
# evidence, before close-out returns the ledger to `inactive`.
#
# The repo records what is published to Hex in four places. The ledger is one of
# them; `release_policy_close_out.sh` advances it. The other three are advanced
# by hand:
#
#   1. baseline_versions/0          test/scripts/reconcile_release_versions_test.exs
#   2. evidence_identifiers/0       (same file)
#   3. the published-baseline branch of inbound_summary_expectation/1
#   4. .planning/publish/*-publish-summary.json
#
# ReconcileReleaseVersionsTest routes on ledger status: while the ledger is
# `captured`/`authorized`/`published`/`completed` it takes a release-candidate
# branch and only asserts versions advanced. The moment close-out writes
# `inactive` it switches to the published-baseline branch and compares the tree
# against those records exactly. So a close-out that advances only the ledger is
# guaranteed to turn Core Full Suite red on both schemas -- which is what
# happened at 2.6.0 (commit 29464056).
#
# This check runs BEFORE the ledger write so the disagreement is reported while
# the evidence is still in hand, rather than as a red required check two commits
# later. A release ceremony that reliably ends red trains the maintainer to
# expect red at close-out, which is exactly when a real regression gets waved
# through.
#
# Checksums are never computed here. They arrive already read from the Hex
# release API and verified by the caller.
set -euo pipefail

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
versions_path=""
checksums_path=""
tag=""
tag_sha=""

usage='usage: check_published_baseline_of_record.sh --versions FILE --checksums FILE --tag TAG --tag-sha SHA [--repo PATH]'

fail() {
  echo "ERROR: $*" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --versions) versions_path=${2:?$usage}; shift 2 ;;
    --checksums) checksums_path=${2:?$usage}; shift 2 ;;
    --tag) tag=${2:?$usage}; shift 2 ;;
    --tag-sha) tag_sha=${2:?$usage}; shift 2 ;;
    --repo) repo_root=${2:?$usage}; shift 2 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

[ -n "$versions_path" ] && [ -n "$checksums_path" ] && [ -n "$tag" ] && [ -n "$tag_sha" ] || fail "$usage"
[ -f "$versions_path" ] || fail "versions file not found: $versions_path"
[ -f "$checksums_path" ] || fail "checksums file not found: $checksums_path"

packages=(mailglass mailglass_admin mailglass_inbound)
test_file="$repo_root/test/scripts/reconcile_release_versions_test.exs"
[ -f "$test_file" ] || fail "baseline-of-record test not found: $test_file"

for package in "${packages[@]}"; do
  jq -er --arg p "$package" '.[$p]' "$versions_path" >/dev/null || fail "version missing for ${package}"
  jq -er --arg p "$package" '.[$p]' "$checksums_path" >/dev/null || fail "checksum missing for ${package}"
done

core_version=$(jq -er '.mailglass' "$versions_path")
inbound_version=$(jq -er '.mailglass_inbound' "$versions_path")
core_series="${core_version%.*}"
inbound_pin="~> ${core_series} and >= ${core_version}"

disagreements=()

note() {
  disagreements+=("$1")
}

# Extract one function body from the test file, so a value that merely appears
# somewhere else in the file cannot satisfy a check for this record.
function_body() {
  # Matches `defp name do` and `defp name(args) do` alike, and stops at the
  # first top-level `end` so a later function's literals cannot leak in.
  awk -v name="$1" '
    $0 ~ "^  defp " name "(\\(| do$)" { inside = 1; next }
    inside && $0 == "  end" { exit }
    inside { print }
  ' "$test_file"
}

require_in_body() {
  local fn="$1" needle="$2" label="$3" body
  body=$(function_body "$fn")
  [ -n "$body" ] || { note "${fn} not found in $(basename "$test_file") -- the record moved or was renamed"; return; }
  case "$body" in
    *"$needle"*) ;;
    *) note "${label}: expected ${needle} in ${fn}" ;;
  esac
}

# 1. baseline_versions/0
for package in "${packages[@]}"; do
  version=$(jq -er --arg p "$package" '.[$p]' "$versions_path")
  require_in_body baseline_versions "\"${package}\" => \"${version}\"" "published baseline version"
done

# 2. evidence_identifiers/0 -- release endpoints, Hex checksums, historical tag
for package in "${packages[@]}"; do
  version=$(jq -er --arg p "$package" '.[$p]' "$versions_path")
  checksum=$(jq -er --arg p "$package" '.[$p]' "$checksums_path")
  require_in_body evidence_identifiers \
    "\"https://hex.pm/api/packages/${package}/releases/${version}\"" "release endpoint"
  require_in_body evidence_identifiers "\"${checksum}\"" "Hex release checksum (${package})"
done
require_in_body evidence_identifiers "\"${tag}\"" "historical tag"
require_in_body evidence_identifiers "\"${tag_sha}\"" "historical tag SHA"

# 3. the published-baseline branch of inbound_summary_expectation/1
require_in_body inbound_summary_expectation "\"version\" => \"${inbound_version}\"" "inbound summary version"
require_in_body inbound_summary_expectation "\"manifest_version\" => \"${inbound_version}\"" "inbound manifest version"
require_in_body inbound_summary_expectation "\"source_ref\" => \"v${inbound_version}\"" "inbound source ref"
require_in_body inbound_summary_expectation "\"${inbound_pin}\"" "inbound publish pin"

# 4. the publish summaries -- publication evidence, produced by
#    `mix mailglass.publish.check`. Never hand-edit them to satisfy this check;
#    regenerate them.
for package in "${packages[@]}"; do
  summary="$repo_root/.planning/publish/${package}-publish-summary.json"
  version=$(jq -er --arg p "$package" '.[$p]' "$versions_path")

  if [ ! -f "$summary" ]; then
    note "publish summary missing: .planning/publish/${package}-publish-summary.json"
    continue
  fi

  found=$(jq -er '.version // "<absent>"' "$summary")
  [ "$found" = "$version" ] ||
    note "publish summary (${package}): version is ${found}, expected ${version} -- regenerate with 'mix mailglass.publish.check --package ${package}'"

  if ! jq -e --slurpfile want "$versions_path" '.linked_versions == $want[0]' "$summary" >/dev/null; then
    note "publish summary (${package}): linked_versions disagree with the released set -- regenerate with 'mix mailglass.publish.check --package ${package}'"
  fi
done

if [ "${#disagreements[@]}" -gt 0 ]; then
  {
    echo "ERROR: the published baseline of record does not yet describe this release."
    echo
    echo "Close-out would return the ledger to 'inactive', which switches"
    echo "ReconcileReleaseVersionsTest to its published-baseline branch. These"
    echo "records must agree first, or the close-out commit lands red:"
    echo
    for item in "${disagreements[@]}"; do
      echo "  - ${item}"
    done
    echo
    echo "Released set: $(jq -c . "$versions_path")"
    echo "Tag:          ${tag} @ ${tag_sha}"
    echo
    echo "Checksums (read from the Hex release API -- copy, never recompute):"
    jq -r 'to_entries[] | "  \(.key): \(.value)"' "$checksums_path"
  } >&2
  exit 1
fi

echo "published baseline of record agrees with the released set"
