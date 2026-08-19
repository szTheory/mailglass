#!/usr/bin/env bash
set -euo pipefail

package=${1:?usage: release_policy_hex_release_state.sh PACKAGE VERSION}
version=${2:?usage: release_policy_hex_release_state.sh PACKAGE VERSION}
body=$(mktemp)
trap 'rm -f "$body"' EXIT
status=$(curl --silent --show-error --output "$body" --write-out '%{http_code}' \
  "https://hex.pm/api/packages/${package}/releases/${version}") || {
  echo "ERROR: Hex release lookup transport failed for ${package} ${version}" >&2
  exit 1
}

case "$status" in
  200) jq -e 'type == "object" and (.version == "'"$version"'")' "$body" >/dev/null; echo exists ;;
  404) echo absent ;;
  *) echo "ERROR: Hex release lookup failed for ${package} ${version} (HTTP ${status:-transport})" >&2; exit 1 ;;
esac
