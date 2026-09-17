#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
target_path="$repo_root/.planning/release-target.json"
repo_path="$repo_root"
write=false

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      target_path=${2:?usage: release_policy_close_out.sh [--target PATH] [--repo PATH] [--write]}
      shift 2
      ;;
    --repo)
      repo_path=${2:?usage: release_policy_close_out.sh [--target PATH] [--repo PATH] [--write]}
      shift 2
      ;;
    --write)
      write=true
      shift
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[ -f "$target_path" ] || fail "release target not found: $target_path"

status=$(jq -er '.status' "$target_path") || fail "release target status is missing or unreadable"

case "$status" in
  authorized | published | completed) ;;
  *) fail "release target status '${status}' is not eligible for close-out" ;;
esac

packages=(mailglass mailglass_admin mailglass_inbound)
target_dir=$(dirname "$target_path")
checksums_tmp=$(mktemp)
body_tmp=$(mktemp)
successor_tmp=$(mktemp "$target_dir/.release-target-close-out.XXXXXX")

cleanup() {
  rm -f "$checksums_tmp" "$body_tmp" "$successor_tmp"
}
trap cleanup EXIT

checksum_args=()
for package in "${packages[@]}"; do
  version=$(jq -er --arg pkg "$package" '.candidate_versions[$pkg]' "$target_path") ||
    fail "candidate version is missing for ${package}"

  http_status=$(curl --silent --show-error --output "$body_tmp" --write-out '%{http_code}' \
    "https://hex.pm/api/packages/${package}/releases/${version}") ||
    fail "Hex release lookup transport failed for ${package} ${version}"

  [ "$http_status" = "200" ] ||
    fail "Hex release lookup failed for ${package} ${version} (HTTP ${http_status})"

  checksum=$(jq -er '.checksum' "$body_tmp") ||
    fail "Hex release checksum is missing for ${package} ${version}"

  hex_state=$("$repo_root/scripts/release_policy_hex_release_state.sh" "$package" "$version" "$checksum") ||
    fail "Hex release verification failed for ${package} ${version}"

  [ "$hex_state" = exists ] ||
    fail "Hex release is not present, is retired, or is checksum-mismatched for ${package} ${version}"

  checksum_args+=(--arg "$package" "$checksum")
done

jq -n "${checksum_args[@]}" \
  '{mailglass: $mailglass, mailglass_admin: $mailglass_admin, mailglass_inbound: $mailglass_inbound}' \
  >"$checksums_tmp"

core_version=$(jq -er '.candidate_versions.mailglass' "$target_path") ||
  fail "core candidate version is missing"

tag="mailglass-v${core_version}"
tag_sha=$(git -C "$repo_path" rev-parse --verify "refs/tags/${tag}^{commit}" 2>/dev/null) ||
  fail "release tag ${tag} does not resolve to a commit"

[[ "$tag_sha" =~ ^[0-9a-f]{40}$ ]] || fail "release tag ${tag} resolved to a malformed commit SHA"

cd "$repo_root"
mix deps.get >/dev/null 2>&1
mix compile >/dev/null 2>&1
mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs \
  -e 'Mailglass.ReleasePolicy.cli(System.argv())' \
  -- close-out "$target_path" "$tag_sha" "$checksums_tmp" >"$successor_tmp" ||
  fail "release policy refused the close-out transition"

if [ "$write" = true ]; then
  mv "$successor_tmp" "$target_path"
else
  cat "$successor_tmp"
fi
