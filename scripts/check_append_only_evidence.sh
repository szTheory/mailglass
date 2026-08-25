#!/usr/bin/env bash
# Reject edits or removals from retained evidence while allowing append-only additions.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <base-sha> <head-sha>" >&2
  exit 2
fi

base_sha="$1"
head_sha="$2"
repo_root=$(git rev-parse --show-toplevel)
config_path="${EVIDENCE_CONFIG_PATH:-$repo_root/.github/scheduled-controls.json}"

if ! [[ "$base_sha" =~ ^[0-9a-f]{40}$ ]] || [ "$base_sha" = "0000000000000000000000000000000000000000" ]; then
  echo "Append-only evidence check skipped: no comparable base SHA."
  exit 0
fi

if ! [[ "$head_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Append-only evidence check failed: invalid head SHA '$head_sha'." >&2
  exit 1
fi

git cat-file -e "$base_sha^{commit}"
git cat-file -e "$head_sha^{commit}"

while IFS= read -r path; do
  [ -n "$path" ] || continue

  if ! git cat-file -e "$base_sha:$path" 2>/dev/null; then
    echo "Append-only evidence check: new retained file $path"
    continue
  fi

  if ! git cat-file -e "$head_sha:$path" 2>/dev/null; then
    echo "Append-only evidence check failed: retained file removed: $path" >&2
    exit 1
  fi

  removed_lines=$(git diff --unified=0 "$base_sha" "$head_sha" -- "$path" |
    awk '/^--- / {next} /^-/ {print}')

  if [ -n "$removed_lines" ]; then
    echo "Append-only evidence check failed: retained evidence was edited or removed: $path" >&2
    printf '%s\n' "$removed_lines" >&2
    exit 1
  fi

  echo "Append-only evidence check passed: $path"
done < <(jq -er '.append_only_evidence_paths[]' "$config_path")
