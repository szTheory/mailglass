#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/reference/demo_app/tmp/demo_browser_evidence"

export DEMO_EVIDENCE_RESET_TOKEN="${DEMO_EVIDENCE_RESET_TOKEN:-phase69-ci-evidence}"
export CI="${CI:-true}"

cleanup() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    docker compose -f "$ROOT_DIR/compose.demo.yml" logs --no-color demo demo_e2e || true
  fi
  docker compose -f "$ROOT_DIR/compose.demo.yml" down --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p "$EVIDENCE_DIR"
rm -f "$EVIDENCE_DIR/playwright-report.json" "$EVIDENCE_DIR/checkpoint.json"

docker compose -f "$ROOT_DIR/compose.demo.yml" down --remove-orphans
docker compose -f "$ROOT_DIR/compose.demo.yml" up --build --abort-on-container-exit --exit-code-from demo_e2e demo_e2e

test -f "$EVIDENCE_DIR/checkpoint.json"
