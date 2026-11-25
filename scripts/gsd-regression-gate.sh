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

stop_docker_browser_server() {
  if [[ -n "${BROWSER_SERVER_PID:-}" ]]; then
    kill "$BROWSER_SERVER_PID" >/dev/null 2>&1 || true
    wait "$BROWSER_SERVER_PID" >/dev/null 2>&1 || true
    BROWSER_SERVER_PID=""
  fi
}

run_browser_suite_docker() {
  local log_file="$1"
  local server_log="$BACKUP_DIR/operator-browser-server.log"
  local readiness_url
  local runner_file="$BACKUP_DIR/docker-playwright-runner.cjs"
  local ready=0
  local status=0
  local playwright_version
  local image
  local attempt

  playwright_version="$(node -e 'process.stdout.write(require("./mailglass_admin/node_modules/playwright/package.json").version)')"
  image="mcr.microsoft.com/playwright:v${playwright_version}-noble"
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "Matching Playwright Docker image is not present locally: ${image}."
    return 1
  fi

  if [[ "$BROWSER_PORT_AUTOMATIC" == "1" ]]; then
    export BROWSER_SERVER_PORT="$(node -e 'const server=require("node:net").createServer(); server.listen(0,"127.0.0.1",()=>{process.stdout.write(String(server.address().port)); server.close();});')"
    BROWSER_PORT_AUTOMATIC=0
  fi

  run_mix browser-assets mailglass_admin mailglass_admin.assets.build

  cat >"$runner_file" <<'NODE'
const net = require('node:net');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const appPort = Number(process.env.BROWSER_SERVER_PORT);
fs.mkdirSync(process.env.XDG_CACHE_HOME, { recursive: true });
const relay = net.createServer((client) => {
  const upstream = net.connect(appPort, 'host.docker.internal', () => client.pipe(upstream).pipe(client));
  client.once('error', () => upstream.destroy());
  upstream.once('error', () => client.destroy());
});
relay.once('error', (error) => {
  console.error(`[gsd-regression-docker] relay failed: ${error.message}`);
  process.exit(1);
});
relay.listen(appPort, '127.0.0.1', () => {
  console.log(`[gsd-regression-docker] host loopback relay ready on 127.0.0.1:${appPort}`);
  const env = { ...process.env };
  delete env.PW_TEST_CONNECT_WS_ENDPOINT;
  delete env.PW_TEST_CONNECT_HEADERS;
  delete env.PW_TEST_CONNECT_EXPOSE_NETWORK;
  const child = spawn(process.execPath, [
    'node_modules/playwright/cli.js', 'test', '--config=playwright.config.cjs',
    '--workers=1', '--retries=0',
    'e2e/phase170-journey.spec.js',
    'e2e/flows.spec.js',
    'e2e/structural.spec.js',
    '--grep', 'Phase 170|Phase 171|Preview:|Preview (happy|error|boundary|edge|advanced)'
  ], { cwd: '/workspace/mailglass/mailglass_admin', env, stdio: 'inherit' });
  const stop = () => child.kill('SIGTERM');
  process.once('SIGTERM', stop);
  process.once('SIGINT', stop);
  child.once('exit', (code, signal) => {
    relay.close();
    process.exit(signal ? 1 : (code ?? 1));
  });
});
NODE

  (
    cd "$ROOT_DIR/mailglass_admin"
    export MIX_ENV=test
    export BROWSER_SERVER_PORT
    export MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH="$BACKUP_DIR/operator-browser-server.ndjson"
    exec asdf exec mix run --no-halt -e "MailglassAdmin.TestSupport.OperatorBrowserServer.run!()"
  ) >"$server_log" 2>&1 &
  BROWSER_SERVER_PID=$!

  readiness_url="http://127.0.0.1:${BROWSER_SERVER_PORT}/ops/browser-ready"
  for attempt in {1..300}; do
    if curl -fsS "$readiness_url" >/dev/null 2>&1; then
      ready=1
      break
    fi
    if ! kill -0 "$BROWSER_SERVER_PID" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  if [[ "$ready" != "1" ]]; then
    echo "Docker browser test server did not become ready at ${readiness_url}."
    tail -n 120 "$server_log" >&2
    stop_docker_browser_server
    return 1
  fi

  if ! docker run --rm --init --network=bridge --memory=512m --cpus=1 \
    --name "mailglass-gsd-regression-preflight-$$" \
    --entrypoint node "$image" -e '
      const http = require("node:http");
      let timeout;
      const request = http.get(process.argv[1], (response) => {
        clearTimeout(timeout);
        response.resume();
        if (response.statusCode !== 200) {
          console.error(`[gsd-regression-docker] host readiness returned HTTP ${response.statusCode}`);
          process.exitCode = 1;
          return;
        }
        console.log("[gsd-regression-docker] container-to-host readiness preflight passed");
      });
      timeout = setTimeout(() => request.destroy(new Error("request timed out")), 3000);
      request.once("error", (error) => {
        clearTimeout(timeout);
        console.error(`[gsd-regression-docker] container-to-host readiness preflight failed: ${error.message}`);
        process.exitCode = 1;
      });
    ' "http://host.docker.internal:${BROWSER_SERVER_PORT}/ops/browser-ready"; then
    echo "Docker could not reach the host operator browser server; skipping the full browser suite."
    tail -n 120 "$server_log" >&2
    stop_docker_browser_server
    return 1
  fi

  if docker run --rm --init --read-only --network=bridge \
    --name "mailglass-gsd-regression-browser-$$" \
    --tmpfs /tmp:rw,nosuid,size=1g --shm-size=512m --memory=2g --cpus=2 --pids-limit=512 \
    --volume "$ROOT_DIR:/workspace/mailglass:rw" \
    --volume "$runner_file:/runner.cjs:ro" \
    --workdir /workspace/mailglass/mailglass_admin \
    --env BROWSER_SERVER_PORT="$BROWSER_SERVER_PORT" \
    --env OPERATOR_BASE_URL="http://127.0.0.1:${BROWSER_SERVER_PORT}" \
    --env XDG_CACHE_HOME=/tmp/.cache \
    --env OPERATOR_BROWSER_EXTERNAL_SERVER=1 --env CI=1 \
    --entrypoint node "$image" /runner.cjs >"$log_file" 2>&1; then
    status=0
  else
    status=$?
  fi

  stop_docker_browser_server
  if [[ "$status" == "0" ]]; then
    summarize_log "$log_file"
    return 0
  fi

  tail -n 200 "$log_file" >&2
  return "$status"
}

run_browser_suite() {
  local log_file="$BACKUP_DIR/operator-browser.log"
  local attempt
  local status

  if [[ "${GSD_REGRESSION_DOCKER_BROWSER:-0}" == "1" ]]; then
    run_browser_suite_docker "$log_file"
    return $?
  fi

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
BROWSER_SERVER_PID=""
ARTIFACT_DIRS=(
  ".planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts"
  ".planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts"
)

restore_artifacts() {
  local relative_dir
  stop_docker_browser_server
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

echo "== Storybook evidence and review contracts =="
node --test "$ROOT_DIR/scripts/check_phase174_evidence.test.cjs" \
  "$ROOT_DIR/scripts/check_phase175_evidence.test.cjs" \
  "$ROOT_DIR/scripts/phase174-review-claims.test.cjs" \
  "$ROOT_DIR/mailglass_admin/e2e/support/storybook-axe.test.cjs"

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
