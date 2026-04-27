#!/usr/bin/env bash
# Regression test for the release-please sed step.
#
# Asserts the sed regex in .github/workflows/release-please.yml correctly
# rewrites {:mailglass, "== <old_ver>"} to {:mailglass, "== <new_ver>"}.
#
# Note: this script targets GNU sed (used on ubuntu-latest in CI). On macOS
# the BSD sed requires `sed -i ''` instead of `sed -i`. Run this script in CI
# or via a GNU sed environment. This is intentional — adding a portability
# shim would diverge from the actual CI behaviour and mask real failures.
#
# Usage:
#   bash test/fixtures/release_please_sed_test.sh
#   echo $?   # 0 = PASS, non-zero = FAIL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="${SCRIPT_DIR}/mix_exs_release_please_sed"
TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

cp "${FIXTURE_DIR}/mix.exs.before" "${TMP}/mix.exs"
NEW_VERSION="0.99.99"

sed -i -E "s/\{:mailglass, \"== [0-9]+\.[0-9]+\.[0-9]+\"\}/{:mailglass, \"== ${NEW_VERSION}\"}/" "${TMP}/mix.exs"

diff -u "${FIXTURE_DIR}/mix.exs.after" "${TMP}/mix.exs"
echo "OK: release-please sed regression test passed."
