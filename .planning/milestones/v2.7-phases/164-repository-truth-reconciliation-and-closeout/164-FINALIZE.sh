#!/usr/bin/env bash
set -euo pipefail

repo="${1:-}"
shift || true

[ -n "$repo" ] || { echo "usage: $0 REPO [--pre-verification]" >&2; exit 2; }
exec "$repo/scripts/finalize_phase_164.sh" "$repo" "$@"
