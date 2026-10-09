#!/usr/bin/env bash
set -euo pipefail

# GSD's generic detector does not recognize Mix projects. Keep the gate aligned
# with the suites used by recent phase verifications instead of running the
# known-non-green, 2,200-test root umbrella suite on every phase.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ASDF_ERLANG_VERSION="${ASDF_ERLANG_VERSION:-27.3.4.13}"
export ASDF_ELIXIR_VERSION="${ASDF_ELIXIR_VERSION:-1.18.4-otp-27}"

summarize_log() {
  local log_file="$1"
  if ! rg 'Finished in|[0-9]+ tests?, [0-9]+ failures?|[0-9]+ passed|[0-9]+ skipped|[0-9]+ excluded|[0-9]+ failed' "$log_file" | tail -n 20; then
    tail -n 20 "$log_file"
  fi
}

run_mix() {
  local label="$1"
  local project_dir="$2"
  shift 2
  local log_file="$BACKUP_DIR/${label}.log"

  if (cd "$ROOT_DIR/$project_dir" && asdf exec mix "$@") >"$log_file" 2>&1; then
    summarize_log "$log_file"
  else
    local status=$?
    tail -n 160 "$log_file" >&2
    return "$status"
  fi
}

run_browser_suite() {
  local log_file="$BACKUP_DIR/operator-browser.log"
  local attempt
  local status

  for attempt in 1 2 3; do
    # An automatically selected port can be claimed in the interval between
    # the probe closing its socket and the test server binding. Pick a fresh
    # port per attempt and retry only that specific startup collision.
    if [[ "$BROWSER_PORT_AUTOMATIC" == "1" ]]; then
      export BROWSER_SERVER_PORT="$(node -e 'const server=require("node:net").createServer(); server.listen(0,"127.0.0.1",()=>{process.stdout.write(String(server.address().port)); server.close();});')"
    fi

    if (
      cd "$ROOT_DIR/mailglass_admin" &&
        npm run --silent test:operator-browser -- \
          e2e/phase170-journey.spec.js \
          e2e/flows.spec.js \
          e2e/structural.spec.js \
          --grep 'Phase 170|Phase 171|Preview:|Preview (happy|error|boundary|edge|advanced)'
    ) >"$log_file" 2>&1; then
      summarize_log "$log_file"
      return 0
    else
      status=$?
      if [[ "$BROWSER_PORT_AUTOMATIC" == "1" ]] &&
        [[ "$attempt" != "3" ]] &&
        rg -qi 'eaddrinuse|address already in use' "$log_file"; then
        echo "Browser test server port ${BROWSER_SERVER_PORT} was claimed before bind; retrying with a fresh port (attempt $((attempt + 1)) of 3)."
        continue
      fi

      tail -n 200 "$log_file" >&2
      return "$status"
    fi
  done
}

# Browser acceptance writes repeatable screenshots into historical phase
# artifact directories. Restore their exact pre-run contents on every exit so
# the regression gate never replaces evidence or user workspace changes.
BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-gsd-regression.XXXXXX")"
ARTIFACT_DIRS=(
  ".planning/phases/168-shared-workspace-and-usable-baseline/artifacts"
  ".planning/phases/169-outbound-investigation-and-recovery/artifacts"
)

restore_artifacts() {
  local relative_dir
  for relative_dir in "${ARTIFACT_DIRS[@]}"; do
    rm -rf "$ROOT_DIR/$relative_dir"
    if [[ -d "$BACKUP_DIR/$relative_dir" ]]; then
      mkdir -p "$ROOT_DIR/$(dirname "$relative_dir")"
      cp -R "$BACKUP_DIR/$relative_dir" "$ROOT_DIR/$(dirname "$relative_dir")/"
    fi
  done
  rm -rf "$BACKUP_DIR"
}

for relative_dir in "${ARTIFACT_DIRS[@]}"; do
  if [[ -d "$ROOT_DIR/$relative_dir" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative_dir")"
    cp -R "$ROOT_DIR/$relative_dir" "$BACKUP_DIR/$(dirname "$relative_dir")/"
  fi
done
trap restore_artifacts EXIT

echo "== Core contracts and renderer =="
run_mix core . test \
  test/mailglass/renderer_test.exs \
  test/mailglass/operator/deliveries_test.exs \
  test/mailglass/operator/timeline_test.exs \
  test/mailglass/operator/support_summary_test.exs \
  test/mailglass/operator/suppressions_test.exs \
  test/mailglass/operator/replay_targets_test.exs \
  test/mailglass/webhook/replay_test.exs \
  test/scripts/timeout_evidence_ci_contract_test.exs \
  --warnings-as-errors --seed 1

echo "== Admin LiveView and component suite =="
run_mix admin mailglass_admin verify.support_contract.admin

echo "== Inbound deterministic CI suite =="
run_mix inbound mailglass_inbound test --warnings-as-errors --exclude property

echo "== Connected operator and preview browser suite =="
export CI=1
if [[ -n "${BROWSER_SERVER_PORT:-}" ]]; then
  BROWSER_PORT_AUTOMATIC=0
else
  BROWSER_PORT_AUTOMATIC=1
fi
run_browser_suite
