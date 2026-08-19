#!/usr/bin/env bash
set -euo pipefail

target=${1:?usage: release_policy_validate_target.sh TARGET RELEASE_REF [ROOT]}
release_ref=${2:?usage: release_policy_validate_target.sh TARGET RELEASE_REF [ROOT]}
root=${3:-.}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$repo_root"
exec mix run --no-start --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- validate-target "$target" "$release_ref" "$root"
