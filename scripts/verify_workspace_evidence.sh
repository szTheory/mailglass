#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'workspace evidence verification failed: %s\n' "$*" >&2
  exit 1
}

usage() {
  fail "usage: $0 static INVENTORY.md RECONCILIATION.tsv | live REPO_ROOT INVENTORY.md RECONCILIATION.tsv"
}

trim_file_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$PWD" "$1" ;;
  esac
}

code_value() {
  value=$1
  value=${value#\`}
  printf '%s\n' "${value%%\`*}"
}

[ "$#" -ge 3 ] || usage
mode=$1
shift

case "$mode" in
  static)
    [ "$#" -eq 2 ] || usage
    repo=''
    inventory=$(trim_file_path "$1")
    tsv=$(trim_file_path "$2")
    ;;
  live)
    [ "$#" -eq 3 ] || usage
    repo=$(trim_file_path "$1")
    inventory=$(trim_file_path "$2")
    tsv=$(trim_file_path "$3")
    ;;
  *) usage ;;
esac

[ -f "$inventory" ] || fail "inventory is missing: $inventory"
[ -f "$tsv" ] || fail "TSV is missing: $tsv"
[ "$mode" = static ] || git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || fail "not a Git repository: $repo"
if [ "$mode" = live ]; then
  repo=$(cd "$repo" && pwd -P)
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
rows="$tmpdir/rows.tsv"

awk -F '|' '
  function trim(value) {
    sub(/^[[:space:]]+/, "", value)
    sub(/[[:space:]]+$/, "", value)
    return value
  }
  /^## Expansion Command Evidence/ { exit }
  /^\|/ {
    id = trim($2)
    if (id ~ /^(CANONICAL|WT-[0-9]+|STASH-[0-9]+|REF-[A-Z0-9-]+|RANGE-[0-9]+|REL-[0-9]+|OBJ-[0-9]+|NONE-[A-Z0-9-]+)$/) {
      for (i = 2; i <= 12; i++) {
        value = trim($i)
        gsub(/\t/, " ", value)
        printf "%s%s", value, (i == 12 ? "\n" : "\t")
      }
    }
  }
' "$inventory" > "$rows"

[ -s "$rows" ] || fail "inventory parser found no identity rows"
awk -F '\t' 'NF != 11 { exit 1 }' "$rows" || fail "inventory contains a malformed identity row"

duplicate_id=$(cut -f1 "$rows" | LC_ALL=C sort | uniq -d | head -1)
[ -z "$duplicate_id" ] || fail "duplicate stable ID: $duplicate_id"

duplicate_identity=$(awk -F '\t' '{ print $2 "\t" $3 }' "$rows" | LC_ALL=C sort | uniq -d | head -1)
[ -z "$duplicate_identity" ] || fail "duplicate category/identity: $duplicate_identity"

awk -F '\t' '
  function lower(value) { return tolower(value) }
  $8 !~ /^(retain|handoff|merge|archive|remove)$/ { exit 1 }
  $1 !~ /^NONE-/ && ($5 == "" || $6 == "" || $7 == "") { exit 2 }
  $1 !~ /^NONE-/ && lower($7) ~ /^(missing|unreadable|stale|unknown|pending)$/ { exit 3 }
  $1 !~ /^(CANONICAL|NONE-)/ && $7 !~ /^EVID-[A-Z0-9-]+$/ { exit 4 }
  $1 == "CANONICAL" && $7 != "CM-01" { exit 5 }
' "$rows" || {
  status=$?
  case "$status" in
    1) fail "inventory contains an unknown disposition" ;;
    2) fail "inventory row lacks content, reachability, or evidence" ;;
    3) fail "inventory represents stale or unreadable evidence as settled" ;;
    4) fail "inventory row lacks a stable EVID reference" ;;
    5) fail "canonical row lacks CM-01 evidence" ;;
    *) fail "inventory semantic validation failed" ;;
  esac
}

require_category() {
  pattern=$1
  label=$2
  awk -F '\t' -v pattern="$pattern" '$1 ~ pattern { found = 1 } END { exit(found ? 0 : 1) }' "$rows" ||
    fail "$label category is neither inventoried nor represented by an explicit zero sentinel"
}

require_category '^WT-' worktree
require_category '^(STASH-|NONE-STASH)' stash
require_category '^(REF-|NONE-REF)' ref
require_category '^(RANGE-|NONE-RANGE)' range
require_category '^(REL-|NONE-RELEASE)' release
require_category '^(OBJ-|NONE-OBJECT)' unreachable-object

canonical_observed=$(awk -F '\t' '$1 == "CANONICAL" { print $4; exit }' "$rows")
if printf '%s\n' "$canonical_observed" | grep -Eq '(ahead|behind)[[:space:]]+[1-9][0-9]*'; then
  printf '%s\n' "$canonical_observed" | grep -Fq 'non-release-clean' ||
    fail "canonical divergence requires an explicit non-release-clean verdict"
fi

unsafe_remove=$(awk -F '\t' '$8 == "remove" && tolower($9) !~ /safe removal authorized/ { print $1; exit }' "$rows")
[ -z "$unsafe_remove" ] || fail "$unsafe_remove is remove without positive safe removal proof"

expected_header=$'source_row\tdisposition\tevidence_ref\tpreservation_requirement\tmechanism\texpected_oid\ttarget\tobserved_oid\thandoff_location\tblocking_condition\tpermitted_next_action\tstatus'
IFS= read -r header < "$tsv" || fail "TSV is empty"
[ "$header" = "$expected_header" ] || fail "TSV header is not exact"
awk -F '\t' 'NR > 1 && NF != 12 { exit 1 }' "$tsv" || fail "TSV contains malformed rows"

duplicate_source=$(awk -F '\t' 'NR > 1 { count[$1]++ } END { for (id in count) if (count[id] != 1) { print id; exit } }' "$tsv")
[ -z "$duplicate_source" ] || fail "TSV contains duplicate source rows: $duplicate_source"

awk -F '\t' '$8 == "archive" || $8 == "remove" { print $1 "\t" $8 "\t" $7 }' "$rows" | LC_ALL=C sort > "$tmpdir/inventory-eligible"
awk -F '\t' 'NR > 1 { print $1 "\t" $2 "\t" $3 }' "$tsv" | LC_ALL=C sort > "$tmpdir/tsv-eligible"
[ -s "$tmpdir/inventory-eligible" ] || fail "eligible archive/remove inventory set is empty"
cmp -s "$tmpdir/inventory-eligible" "$tmpdir/tsv-eligible" ||
  fail "inventory and TSV source-ID/disposition/evidence sets differ"

while IFS=$'\t' read -r source disposition _evidence requirement mechanism expected target observed handoff_location blocking permitted status; do
  [ -n "$source" ] || fail "TSV source row is empty"
  case "$disposition" in archive|remove) ;; *) fail "$source has unknown disposition" ;; esac
  case "$requirement" in required|not-required) ;; *) fail "$source has unknown preservation requirement" ;; esac
  case "$mechanism" in ref|handoff|none) ;; *) fail "$source has non-durable preservation mechanism" ;; esac
  [ "$status" = verified ] || fail "$source is not verified"

  if [ "$mechanism" = ref ]; then
    [[ "$target" =~ ^refs/heads/preserve/[a-z0-9-]+$ ]] || fail "$source has an invalid durable preservation ref"
    [[ "$expected" =~ ^[0-9a-f]{40}$ ]] || fail "$source lacks a full expected OID"
    [ "$expected" = "$observed" ] || fail "$source expected and observed OIDs differ"
  elif [ "$mechanism" = handoff ]; then
    [[ "$target" =~ ^HANDOFF-[A-Z0-9-]+$ ]] || fail "$source handoff target is not stable"
    [ -n "$handoff_location" ] && [ "$handoff_location" != - ] || fail "$source handoff lacks a concrete location"
    [ -n "$blocking" ] && [ "$blocking" != - ] || fail "$source handoff lacks a blocking condition"
    [ -n "$permitted" ] && [ "$permitted" != - ] || fail "$source handoff lacks a permitted next action"
  else
    [ "$requirement" = not-required ] || fail "$source required preservation has no durable mechanism"
  fi
done < <(tail -n +2 "$tsv")

grep -Fq '## Final Reconciliation' "$inventory" || fail "final reconciliation is missing"
grep -Eiq 'zero[^\n]*(remove|cleanup)|zero[^\n]*action queue|cleanup queue[^\n]*empty' "$inventory" ||
  fail "final reconciliation lacks an explicit zero cleanup/remove result"
grep -Eiq 'force removal|force-updated|force-push' "$inventory" || fail "destructive force-operation prohibition is missing"
grep -Eiq 'prun(e|ing)|garbage collection' "$inventory" || fail "prune/garbage-collection prohibition is missing"
grep -Eiq 'stash[^\n]*(consum|drop|clear|remain)' "$inventory" || fail "stash preservation prohibition is missing"
grep -Eiq '(existing ref|preservation ref).*(moved|mutated|overwrit|force)|ref overwrite' "$inventory" ||
  fail "existing-ref preservation prohibition is missing"
grep -Eiq '(immutable|append-only|appended separately)' "$inventory" || fail "immutable evidence policy is missing"
grep -Fq 'non-release-clean' "$inventory" || fail "release verdict separation is missing"

printf 'workspace evidence static contract: PASS (%s identities, %s preservation rows)\n' \
  "$(wc -l < "$rows" | tr -d ' ')" "$(tail -n +2 "$tsv" | wc -l | tr -d ' ')"

[ "$mode" = live ] || exit 0

snapshot() {
  destination=$1
  {
    printf '%s\n' '[worktrees]'
    git -C "$repo" worktree list --porcelain
    printf '%s\n' '[stash]'
    git -C "$repo" stash list --format='%H%x09%gd%x09%P%x09%gs'
    printf '%s\n' '[refs]'
    git -C "$repo" for-each-ref --format='%(refname)%09%(objectname)' refs/heads refs/remotes refs/tags | LC_ALL=C sort
    printf '%s\n' '[unreachable-commits]'
    git -C "$repo" fsck --full --no-reflogs --unreachable --no-dangling 2>/dev/null |
      awk '$1 == "unreachable" && $2 == "commit" { print $3 }' | LC_ALL=C sort
    printf '%s\n' '[release-artifacts]'
    awk -F '\t' '$1 ~ /^REL-/ { print $3 }' "$rows" | while IFS= read -r encoded; do
      path=$(code_value "$encoded")
      [ -n "$path" ] || continue
      shasum -a 256 "$repo/$path"
    done | LC_ALL=C sort
  } > "$destination"
}

snapshot "$tmpdir/snapshot-before"

[ "$(git -C "$repo" branch --show-current)" = main ] || fail "canonical repository is not on main"
upstream=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) ||
  fail "canonical main has no upstream"
[ "$upstream" = origin/main ] || fail "canonical main upstream is not origin/main"
[ -z "$(git -C "$repo" status --porcelain --untracked-files=all)" ] || fail "canonical main working tree is not clean"

read -r behind ahead < <(git -C "$repo" rev-list --left-right --count '@{upstream}...HEAD')
if [ "$behind" -ne 0 ] || [ "$ahead" -ne 0 ]; then
  grep -Fq 'non-release-clean' "$inventory" || fail "live upstream drift lacks a non-release-clean verdict"
fi

git -C "$repo" worktree list --porcelain > "$tmpdir/worktrees"
live_worktree_count=$(grep -c '^worktree ' "$tmpdir/worktrees")
ledger_worktree_count=$(awk -F '\t' '$1 ~ /^WT-/ { count++ } END { print count + 0 }' "$rows")
[ "$live_worktree_count" -eq "$ledger_worktree_count" ] ||
  fail "live worktree count differs from the ledger"

while IFS=$'\t' read -r id _category identity _observed _content reachability _evidence _disposition _preservation _permitted _outcome; do
  path=$(code_value "$identity")
  [ -n "$path" ] || fail "$id lacks a parseable worktree path"
  path=$(cd "$path" 2>/dev/null && pwd -P) || fail "$id worktree path is unreadable: $path"
  grep -Fqx "worktree $path" "$tmpdir/worktrees" || fail "$id worktree path is not registered: $path"
  if [ "$path" != "$repo" ]; then
    expected_oid=$(printf '%s\n' "$reachability" | grep -Eo '[0-9a-f]{40}' | head -1)
    actual_oid=$(git -C "$path" rev-parse HEAD)
    [ "$actual_oid" = "$expected_oid" ] || fail "$id worktree HEAD differs from captured evidence"
  fi
done < <(awk -F '\t' '$1 ~ /^WT-/ { print }' "$rows")

git -C "$repo" stash list --format='%H' | LC_ALL=C sort > "$tmpdir/live-stash"
awk -F '\t' '$1 ~ /^STASH-/ { if (match($3, /[0-9a-f]{40}/)) print substr($3, RSTART, RLENGTH) }' "$rows" |
  LC_ALL=C sort > "$tmpdir/expected-stash"
cmp -s "$tmpdir/live-stash" "$tmpdir/expected-stash" || fail "live stash identities differ from the ledger"

while IFS=$'\t' read -r id category identity observed _content _reachability _evidence _disposition _preservation _permitted _outcome; do
  name=$(code_value "$identity")
  expected_oid=$(printf '%s\n' "$observed" | grep -Eo '[0-9a-f]{40}' | head -1)
  case "$category" in
    'archive ref'|'branch') ref="refs/heads/$name" ;;
    'remote ref') ref="refs/remotes/$name" ;;
    'release tag'|'milestone tag') ref="refs/tags/$name" ;;
    *) continue ;;
  esac
  actual_oid=$(git -C "$repo" rev-parse "$ref" 2>/dev/null) || fail "$id ref does not resolve: $ref"
  [ "$actual_oid" = "$expected_oid" ] || fail "$id ref $name differs from captured OID"
done < <(awk -F '\t' '$1 ~ /^REF-[0-9]+$/ { print }' "$rows")

while IFS=$'\t' read -r id _category identity _rest; do
  range=$(code_value "$identity")
  git -C "$repo" rev-list --left-right --count "$range" >/dev/null 2>&1 || fail "$id range no longer resolves: $range"
done < <(awk -F '\t' '$1 ~ /^RANGE-/ { print }' "$rows")

while IFS=$'\t' read -r id _category identity observed _rest; do
  path=$(code_value "$identity")
  expected_hash=$(printf '%s\n' "$observed" | grep -Eo '[0-9a-f]{64}' | head -1)
  [ -f "$repo/$path" ] || fail "$id release evidence is missing: $path"
  actual_hash=$(shasum -a 256 "$repo/$path" | awk '{ print $1 }')
  [ "$actual_hash" = "$expected_hash" ] || fail "$id release evidence hash differs: $path"
done < <(awk -F '\t' '$1 ~ /^REL-/ { print }' "$rows")

git -C "$repo" fsck --full --no-reflogs --unreachable --no-dangling 2>/dev/null |
  awk '$1 == "unreachable" && $2 == "commit" { print $3 }' | LC_ALL=C sort > "$tmpdir/live-objects"
awk -F '\t' '$1 ~ /^OBJ-/ { if (match($3, /[0-9a-f]{40}/)) print substr($3, RSTART, RLENGTH) }' "$rows" |
  LC_ALL=C sort > "$tmpdir/expected-objects"
cmp -s "$tmpdir/live-objects" "$tmpdir/expected-objects" || fail "live unreachable-commit identities differ from the ledger"

while IFS=$'\t' read -r source _disposition _evidence _requirement mechanism expected target observed _rest; do
  [ "$mechanism" = ref ] || continue
  actual=$(git -C "$repo" rev-parse "${target}^{commit}" 2>/dev/null) || fail "$source preservation ref does not resolve"
  [ "$actual" = "$expected" ] && [ "$actual" = "$observed" ] || fail "$source preservation ref/OID reconciliation failed"
done < <(tail -n +2 "$tsv")

expected_ref_count=$(sed -n 's/^| refs | \([0-9][0-9]*\) refs:.*/\1/p' "$inventory" | tail -1)
if [ -n "$expected_ref_count" ]; then
  live_ref_count=$(git -C "$repo" for-each-ref --format='%(refname)' refs/heads refs/remotes refs/tags | wc -l | tr -d ' ')
  [ "$live_ref_count" -eq "$expected_ref_count" ] || fail "live ref count differs from final reconciliation"
fi

sync_dir=${WORKSPACE_EVIDENCE_TEST_SYNC_DIR:-}
if [ -n "$sync_dir" ]; then
  mkdir -p "$sync_dir"
  : > "$sync_dir/ready"
  attempts=0
  while [ ! -f "$sync_dir/continue" ]; do
    attempts=$((attempts + 1))
    [ "$attempts" -lt 200 ] || fail "test synchronization timed out"
    sleep 0.025
  done
fi

snapshot "$tmpdir/snapshot-after"
cmp -s "$tmpdir/snapshot-before" "$tmpdir/snapshot-after" ||
  fail "monitored assessment inputs changed; discard results and perform a full append-only recapture"

for item in \
  '01 enumeration-to-ledger completeness' \
  '02 concurrent input mutation abort' \
  '03 durable preservation prerequisite adequacy' \
  '04 final identity-by-identity reconciliation' \
  '05 stale-evidence fail-closed policy' \
  '06 release-clean verdict separation' \
  '07 disposable-work prohibition' \
  '08 equal-OID identity separation' \
  '09 durable recoverability' \
  '10 preservation mutation boundary' \
  '11 destructive cleanup prohibition' \
  '12 immutable pre-mutation evidence' \
  '13 historical capture retention' \
  '14 read-only capture contract' \
  '15 clean-tree/release-verdict distinction'
do
  printf 'PASS [UAT-%s]\n' "$item"
done

printf 'workspace evidence live contract: PASS (15/15 automated UAT checks passed)\n'
