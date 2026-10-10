#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/reference/demo_app/tmp/demo_browser_evidence"
RUN_SUFFIX="$(date -u +%Y%m%d%H%M%S)-$$-$RANDOM"
COMPOSE_PROJECT="mailglass-evidence-$RUN_SUFFIX"

read -r HTTP_PORT DB_PORT < <(
  python3 -c '
import socket
sockets = []
ports = []
for _ in range(2):
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    sockets.append(sock)
    ports.append(sock.getsockname()[1])
print(*ports)
for sock in sockets:
    sock.close()
'
)

if [[ ! "$HTTP_PORT" =~ ^[0-9]+$ || ! "$DB_PORT" =~ ^[0-9]+$ || "$HTTP_PORT" == "$DB_PORT" ]]; then
  echo "Could not allocate distinct host ports for the evidence project" >&2
  exit 1
fi
if [[ "$HTTP_PORT" == 4015 || "$DB_PORT" == 5415 ]]; then
  echo "Evidence project unexpectedly selected a retained demo default port" >&2
  exit 1
fi

export MAILGLASS_DEMO_HTTP_PORT="$HTTP_PORT"
export MAILGLASS_DEMO_DB_PORT="$DB_PORT"
export DEMO_EVIDENCE_RESET_TOKEN="${DEMO_EVIDENCE_RESET_TOKEN:-phase173-ci-evidence}"
export CI="${CI:-true}"
export DEMO_CANDIDATE_REVISION="$(git -C "$ROOT_DIR" rev-parse HEAD)"
if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  export DEMO_CANDIDATE_DIRTY=true
else
  export DEMO_CANDIDATE_DIRTY=false
fi
export DEMO_EVIDENCE_RUN_ID="$COMPOSE_PROJECT"

compose() {
  docker compose -p "$COMPOSE_PROJECT" -f "$ROOT_DIR/compose.demo.yml" "$@"
}

cleanup() {
  local exit_code=$?
  if [[ "$exit_code" -ne 0 ]]; then
    compose logs --no-color demo demo_e2e || true
  fi
  compose down --volumes --remove-orphans >/dev/null 2>&1 || true
  return "$exit_code"
}
trap cleanup EXIT

mkdir -p "$EVIDENCE_DIR/captures"
rm -f \
  "$EVIDENCE_DIR/playwright-report.json" \
  "$EVIDENCE_DIR/phase173-captures.json" \
  "$EVIDENCE_DIR/checkpoint.json"

compose up --build --detach --wait --wait-timeout 300 demo
compose run --build --no-deps --rm \
  --env DEMO_CANDIDATE_REVISION \
  --env DEMO_CANDIDATE_DIRTY \
  --env DEMO_EVIDENCE_RUN_ID \
  demo_e2e sh -lc \
  'npm --prefix assets ci --no-audit --no-fund && npx --prefix assets playwright install chromium && npm --prefix assets run test:e2e -- phase173-evidence.spec.js'

test -f "$EVIDENCE_DIR/playwright-report.json"
test -f "$EVIDENCE_DIR/phase173-captures.json"
DEMO_CANDIDATE_REVISION="$DEMO_CANDIDATE_REVISION" \
  node "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"
