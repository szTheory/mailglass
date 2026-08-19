#!/usr/bin/env bash
set -euo pipefail

target=${1:?usage: release_policy_validate_target.sh TARGET RELEASE_REF [ROOT]}
release_ref=${2:?usage: release_policy_validate_target.sh TARGET RELEASE_REF [ROOT]}
root=${3:-.}

if [ ! -r "$target" ]; then
  echo "active=false"
  exit 0
fi

status=$(jq -er '.status' "$target")
if [ "$status" != "active" ]; then
  echo "active=false"
  exit 0
fi

expected_core=$(jq -er '.packages.mailglass' "$target")
expected_admin=$(jq -er '.packages.mailglass_admin' "$target")
expected_inbound=$(jq -er '.packages.mailglass_inbound' "$target")
actual_core=$(sed -nE 's/^[[:space:]]*@version "([^"]+)"/\1/p' "$root/mix.exs" | head -1)
actual_admin=$(sed -nE 's/^[[:space:]]*@version "([^"]+)"/\1/p' "$root/mailglass_admin/mix.exs" | head -1)
actual_inbound=$(sed -nE 's/^[[:space:]]*@version "([^"]+)"/\1/p' "$root/mailglass_inbound/mix.exs" | head -1)

if [ "$actual_core" != "$expected_core" ] || \
   [ "$actual_admin" != "$expected_admin" ] || \
   [ "$actual_inbound" != "$expected_inbound" ]; then
  echo "Release target mismatch: expected core/admin/inbound $expected_core/$expected_admin/$expected_inbound; source has $actual_core/$actual_admin/$actual_inbound" >&2
  exit 1
fi

if [ "$release_ref" != "mailglass-v${expected_core}" ] && \
   [ "$release_ref" != "mailglass_admin-v${expected_admin}" ]; then
  echo "Release target mismatch: ref '$release_ref' is not an authorized linked release tag" >&2
  exit 1
fi

printf 'active=true\ncore=%s\nadmin=%s\ninbound=%s\n' \
  "$actual_core" "$actual_admin" "$actual_inbound"
