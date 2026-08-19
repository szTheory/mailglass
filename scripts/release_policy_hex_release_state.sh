#!/usr/bin/env bash
set -euo pipefail

package=${1:?usage: release_policy_hex_release_state.sh PACKAGE VERSION CHECKSUM}
version=${2:?usage: release_policy_hex_release_state.sh PACKAGE VERSION CHECKSUM}
expected_checksum=${3:?usage: release_policy_hex_release_state.sh PACKAGE VERSION CHECKSUM}
[[ "$expected_checksum" =~ ^[0-9a-f]{64}$ ]] || {
  echo "ERROR: expected package checksum is malformed" >&2
  exit 1
}
body=$(mktemp)
trap 'rm -f "$body"' EXIT
status=$(curl --silent --show-error --output "$body" --write-out '%{http_code}' \
  "https://hex.pm/api/packages/${package}/releases/${version}") || {
  echo "ERROR: Hex release lookup transport failed for ${package} ${version}" >&2
  exit 1
}

case "$status" in
  200)
    jq -e --arg version "$version" --arg checksum "$expected_checksum" \
      'type == "object" and .version == $version and .retirement == null and
       (.checksum | type == "string" and test("^[0-9a-f]{64}$")) and .checksum == $checksum' \
      "$body" >/dev/null || {
        echo "ERROR: existing Hex release is retired, malformed, or checksum-mismatched" >&2
        exit 1
      }
    echo exists
    ;;
  404) echo absent ;;
  *) echo "ERROR: Hex release lookup failed for ${package} ${version} (HTTP ${status:-transport})" >&2; exit 1 ;;
esac
