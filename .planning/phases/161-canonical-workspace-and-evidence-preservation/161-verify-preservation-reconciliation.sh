#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'preservation reconciliation failed: %s\n' "$*" >&2; exit 1; }
usage() { fail "usage: $0 partial|complete INVENTORY.md RECONCILIATION.tsv"; }

[ "$#" -eq 3 ] || usage
mode=$1
inventory=$2
tsv=$3
case "$mode" in partial|complete) ;; *) usage ;; esac
[ -f "$inventory" ] || fail "inventory is missing: $inventory"
[ -f "$tsv" ] || fail "TSV is missing: $tsv"

expected_header=$'source_row\tdisposition\tevidence_ref\tpreservation_requirement\tmechanism\texpected_oid\ttarget\tobserved_oid\thandoff_location\tblocking_condition\tpermitted_next_action\tstatus'
IFS= read -r header < "$tsv" || fail "TSV is empty"
[ "$header" = "$expected_header" ] || fail "TSV header is not exact"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

awk '
  function trim(value) { sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); return value }
  /^\|/ && $0 !~ /^\|[[:space:]-]+\|/ {
    count = split($0, fields, "|")
    id = trim(fields[2]); disposition = trim(fields[9]); evidence = trim(fields[8])
    if (id != "" && id !~ /^(CANONICAL|NONE-)/ && (disposition == "archive" || disposition == "remove")) {
      print id "\t" disposition "\t" evidence
    }
  }
' "$inventory" | LC_ALL=C sort > "$tmpdir/inventory-rows"

[ -s "$tmpdir/inventory-rows" ] || fail "eligible archive/remove inventory set is empty"
awk -F '\t' 'NF != 12 { exit 1 } NR > 1 { print $1 "\t" $2 "\t" $3 }' "$tsv" | LC_ALL=C sort > "$tmpdir/tsv-rows" || fail "TSV contains malformed rows"
if [ "$(awk -F '\t' 'NR > 1 { count[$1]++ } END { for (id in count) if (count[id] != 1) exit 1 }' "$tsv"; echo $?)" -ne 0 ]; then
  fail "TSV contains duplicate source rows"
fi
cmp -s "$tmpdir/inventory-rows" "$tmpdir/tsv-rows" || fail "inventory and TSV source-ID/disposition/evidence sets differ"

eligible_count=$(wc -l < "$tmpdir/inventory-rows" | tr -d ' ')
required_count=$(awk -F '\t' 'NR > 1 && $4 == "required" { count++ } END { print count + 0 }' "$tsv")
[ "$eligible_count" -gt 0 ] || fail "eligible count is zero"
[ "$required_count" -gt 0 ] || fail "required preservation set is empty"

ref_count=0
while IFS=$'\t' read -r source disposition evidence requirement mechanism expected target observed handoff_location blocking permitted status; do
  [ -n "$source" ] || fail "source row is empty"
  case "$disposition" in archive|remove) ;; *) fail "$source has unknown disposition" ;; esac
  [[ "$evidence" =~ ^EVID-[A-Z0-9-]+$ ]] || fail "$source lacks an EVID reference"
  case "$requirement" in required|not-required) ;; *) fail "$source has unknown preservation requirement" ;; esac
  case "$mechanism" in ref|handoff|pending|none) ;; *) fail "$source has unknown mechanism" ;; esac
  case "$status" in verified|pending) ;; *) fail "$source has unknown status" ;; esac
  if [ "$mechanism" = ref ]; then
    ref_count=$((ref_count + 1))
    [[ "$target" =~ ^refs/heads/preserve/phase-161-[a-z0-9-]+$ ]] || fail "$source has an invalid preservation ref"
    [[ "$expected" =~ ^[0-9a-f]{40}$ ]] || fail "$source lacks a full expected OID"
    [[ "$observed" =~ ^[0-9a-f]{40}$ ]] || fail "$source lacks a full observed OID"
    actual=$(git rev-parse "${target}^{commit}") || fail "$source preservation ref does not resolve"
    [ "$actual" = "$expected" ] || fail "$source preservation ref resolves to a different expected OID"
    [ "$actual" = "$observed" ] || fail "$source preservation ref resolves to a different observed OID"
    [ "$status" = verified ] || fail "$source ref row is not verified"
  fi
  if [ "$requirement" = not-required ]; then
    [ "$mechanism" = none ] && [ "$status" = verified ] || fail "$source not-required row lacks evidence-backed verified none mechanism"
  fi
  if [ "$mode" = partial ] && [ "$requirement" = required ] && [ "$mechanism" = pending ]; then
    [ "$status" = pending ] || fail "$source pending partial row is not pending"
  fi
  if [ "$mode" = complete ]; then
    [ "$status" != pending ] || fail "$source remains pending in complete mode"
    if [ "$requirement" = required ]; then
      case "$mechanism" in ref) ;; handoff)
        [[ "$target" =~ ^HANDOFF-[A-Z0-9-]+$ ]] || fail "$source handoff target is not stable"
        [ -n "$handoff_location" ] && [ "$handoff_location" != - ] || fail "$source handoff lacks a concrete location"
        [ -n "$blocking" ] && [ "$blocking" != - ] || fail "$source handoff lacks a blocking condition"
        [ -n "$permitted" ] && [ "$permitted" != - ] || fail "$source handoff lacks a permitted next action"
        grep -Fq "$target" "$inventory" || fail "$source handoff is missing from inventory"
        ;; *) fail "$source required row lacks a ref or handoff" ;; esac
    fi
  fi
done < <(tail -n +2 "$tsv")

[ "$ref_count" -gt 0 ] || fail "no ref preservation row exists"
printf 'preservation reconciliation %s: PASS (%s eligible, %s required, %s refs)\n' "$mode" "$eligible_count" "$required_count" "$ref_count"
