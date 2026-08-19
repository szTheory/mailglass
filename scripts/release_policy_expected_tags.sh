#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?usage: release_policy_expected_tags.sh MANIFEST [TARGET]}
target=${2:-}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$repo_root"

if [ -n "$target" ]; then
  exec mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- expected-tags "$manifest" "$target"
else
  exec mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- expected-tags "$manifest"
fi
