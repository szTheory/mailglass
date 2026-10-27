#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/reference/demo_app/tmp/demo_browser_evidence"
PHASE174=false
PILOT=false
for argument in "$@"; do
  case "$argument" in
    --phase174) PHASE174=true ;;
    --pilot) PILOT=true ;;
    *) echo "Unknown option: $argument" >&2; exit 2 ;;
  esac
done
if [[ "$PILOT" == true && "$PHASE174" != true ]]; then
  echo "--pilot requires --phase174" >&2
  exit 2
fi

if [[ "${GITHUB_ACTIONS:-false}" == true ]]; then
  if [[ -z "${GITHUB_RUN_ID:-}" || -z "${GITHUB_RUN_ATTEMPT:-}" ]]; then
    echo "Hosted evidence requires GITHUB_RUN_ID and GITHUB_RUN_ATTEMPT" >&2
    exit 1
  fi
  RUN_SUFFIX="${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
else
  RUN_SUFFIX="$(date -u +%Y%m%d%H%M%S)-$$-$RANDOM"
fi
COMPOSE_PROJECT="mailglass-evidence-$RUN_SUFFIX"
RUN_ID="$COMPOSE_PROJECT"
RUN_EVIDENCE_ROOT="$EVIDENCE_DIR/$COMPOSE_PROJECT"
if [[ "$PHASE174" == true ]]; then
  if [[ -e "$RUN_EVIDENCE_ROOT" ]]; then
    echo "Refusing to reuse existing evidence output owned by another run: $RUN_EVIDENCE_ROOT" >&2
    exit 1
  fi
  mkdir -p "$RUN_EVIDENCE_ROOT/phase174"
fi

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
if [[ "$PHASE174" == true ]]; then
  export GITHUB_ACTIONS="${GITHUB_ACTIONS:-false}"
  export GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
  export GITHUB_RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-}"
  export GITHUB_JOB="${GITHUB_JOB:-}"
  export GITHUB_SHA="${GITHUB_SHA:-}"
  export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
  export RUNNER_NAME="${RUNNER_NAME:-}"
  export RUNNER_OS="${RUNNER_OS:-}"
  export RUNNER_ARCH="${RUNNER_ARCH:-}"
  export DEMO_EVIDENCE_RESET_TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
else
  export DEMO_EVIDENCE_RESET_TOKEN="${DEMO_EVIDENCE_RESET_TOKEN:-phase173-ci-evidence}"
fi
export CI="${CI:-true}"
export DEMO_CANDIDATE_REVISION="$(git -C "$ROOT_DIR" rev-parse HEAD)"
if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  export DEMO_CANDIDATE_DIRTY=true
else
  export DEMO_CANDIDATE_DIRTY=false
fi
export DEMO_EVIDENCE_RUN_ID="$COMPOSE_PROJECT"
export DEMO_EVIDENCE_PROJECT_ID="$COMPOSE_PROJECT"

SOURCE_IDENTITY_JSON=""
SOURCE_DIGEST=""
if [[ "$PHASE174" == true ]]; then
  if [[ "$GITHUB_ACTIONS" == true && "$GITHUB_SHA" != "$DEMO_CANDIDATE_REVISION" ]]; then
    echo "GITHUB_SHA does not match the checked out candidate revision" >&2
    exit 1
  fi
  SOURCE_IDENTITY_JSON="$(node -e 'const checker=require(process.argv[1]); process.stdout.write(JSON.stringify(checker.computeSourceIdentity(process.argv[2],process.argv[3])));' \
    "$ROOT_DIR/scripts/check_phase174_evidence.cjs" "$ROOT_DIR" "$DEMO_CANDIDATE_REVISION")"
  SOURCE_DIGEST="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).source_digest);' "$SOURCE_IDENTITY_JSON")"
  if [[ ! "$SOURCE_DIGEST" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Could not compute the selected-source digest" >&2
    exit 1
  fi
fi

compose() {
  docker compose -p "$COMPOSE_PROJECT" -f "$ROOT_DIR/compose.demo.yml" "$@"
}

now_ms() {
  node -e 'process.stdout.write(String(Number(process.hrtime.bigint() / 1000000n)));'
}

now_iso() {
  node -e 'process.stdout.write(new Date().toISOString());'
}

copy_phase173_outputs() {
  local target="$1"
  if [[ "$PHASE174" == true ]]; then return 0; fi
  mkdir -p "$target"
  for file in playwright-report.json phase173-captures.json checkpoint.json; do
    if [[ -f "$EVIDENCE_DIR/$file" ]]; then cp "$EVIDENCE_DIR/$file" "$target/$file"; fi
  done
  if [[ -d "$EVIDENCE_DIR/retained" ]]; then
    rm -rf "$target/retained"
    cp -a "$EVIDENCE_DIR/retained" "$target/retained"
  fi
}

save_failure_outputs() {
  local condition="${1:-failure}"
  local failure_code="${2:-1}"
  local target="$RUN_EVIDENCE_ROOT/phase174/$condition"
  if [[ "$PHASE174" != true ]]; then return 0; fi
  mkdir -p "$target"
  copy_phase173_outputs "$target/phase173"
  if [[ -d "$ROOT_DIR/mailglass_admin/test-results" ]]; then
    mkdir -p "$target/admin-test-results"
    cp -a "$ROOT_DIR/mailglass_admin/test-results/." "$target/admin-test-results/" || true
  fi
  if [[ -d "$ROOT_DIR/reference/demo_app/assets/test-results" ]]; then
    python3 - "$ROOT_DIR/reference/demo_app/assets/test-results" "$target/demo-test-failures" <<'PY' || true
import pathlib
import shutil
import sys

source, target = map(pathlib.Path, sys.argv[1:])
for item in source.rglob("error-context.md"):
    target.mkdir(parents=True, exist_ok=True)
    shutil.copy2(item, target / f"{item.parent.name}.md")
PY
  fi
  node -e 'const fs=require("node:fs"); const path=require("node:path"); const p=process.argv[1]; const data={schema_version:"phase174-failure.v1",run_id:process.argv[2],condition:process.argv[3],source_revision:process.argv[4],source_digest:process.argv[5],exit_code:Number(process.argv[6]),recorded_at:new Date().toISOString()}; fs.writeFileSync(p,JSON.stringify(data,null,2)+"\n");' \
    "$RUN_EVIDENCE_ROOT/phase174/failure.json" "$RUN_ID" "$condition" "$DEMO_CANDIDATE_REVISION" "$SOURCE_DIGEST" "$failure_code" || true
}

SERVICES_STARTED=false
cleanup() {
  local exit_code=$?
  local down_status=0
  if [[ "$exit_code" -ne 0 ]]; then
    compose logs --no-color --tail 50 demo demo_e2e || true
    if [[ "$PHASE174" != true && -s "$EVIDENCE_DIR/playwright-report.json" ]]; then
      node "$ROOT_DIR/reference/demo_app/assets/scripts/summarize-playwright-failures.cjs" \
        "$EVIDENCE_DIR/playwright-report.json" || true
    fi
    save_failure_outputs "failed" "$exit_code" || true
  fi
  if [[ "$SERVICES_STARTED" == true ]]; then
    compose down --volumes --remove-orphans >/dev/null 2>&1 || down_status=$?
    SERVICES_STARTED=false
  fi
  if [[ "$exit_code" -eq 0 && "$down_status" -ne 0 ]]; then exit_code=$down_status; fi
  return "$exit_code"
}
trap cleanup EXIT

if [[ "$PHASE174" != true ]]; then
  node "$ROOT_DIR/scripts/prepare_phase173_baselines.cjs"
  mkdir -p "$EVIDENCE_DIR/captures"
  rm -rf "$EVIDENCE_DIR/retained"
  rm -f \
    "$EVIDENCE_DIR/playwright-report.json" \
    "$EVIDENCE_DIR/phase173-captures.json" \
    "$EVIDENCE_DIR/checkpoint.json"
fi

PAGE_CONTROLLER_BEAM="/workspace/reference/demo_app/_build/dev/lib/mailglass_demo/ebin/Elixir.MailglassDemoWeb.PageController.beam"
UNSUBSCRIBE_BEAM="/workspace/reference/demo_app/_build/dev/lib/mailglass/ebin/Elixir.Mailglass.Compliance.UnsubscribeHTML.beam"

if [[ "$PHASE174" != true ]]; then
  SERVICES_STARTED=true
  compose up --build --detach --wait --wait-timeout 300 demo
  export DEMO_PAGE_CONTROLLER_BEAM_SHA256="$(compose exec -T demo sha256sum "$PAGE_CONTROLLER_BEAM" | awk '{print $1}')"
  export DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256="$(compose exec -T demo sha256sum "$UNSUBSCRIBE_BEAM" | awk '{print $1}')"
  for digest in "$DEMO_PAGE_CONTROLLER_BEAM_SHA256" "$DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256"; do
    if [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
      echo "Could not identify the compiled route templates in the run-owned demo container" >&2
      exit 1
    fi
  done
  compose run --build --no-deps --rm \
    --env DEMO_CANDIDATE_REVISION \
    --env DEMO_CANDIDATE_DIRTY \
    --env DEMO_EVIDENCE_RUN_ID \
    --env DEMO_EVIDENCE_RESET_TOKEN \
    --env DEMO_PAGE_CONTROLLER_BEAM_SHA256 \
    --env DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256 \
    --env PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright \
    demo_e2e sh -lc \
    'mkdir -p /workspace/reference/demo_app/tmp/demo_browser_evidence && node assets/scripts/check-demo-browser-deps.cjs --lock-only && npm --prefix assets ci --no-audit --no-fund && npm --silent --prefix assets run test:e2e -- --reporter=json > /workspace/reference/demo_app/tmp/demo_browser_evidence/playwright-report.json'

  test -f "$EVIDENCE_DIR/playwright-report.json"
  test -f "$EVIDENCE_DIR/phase173-captures.json"
  DEMO_CANDIDATE_REVISION="$DEMO_CANDIDATE_REVISION" \
    node "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"
  exit 0
fi

if [[ "$GITHUB_ACTIONS" == true ]]; then
  PHASE174_JOB_ID="$GITHUB_JOB"
else
  PHASE174_JOB_ID=local
fi
export PHASE174_JOB_ID

if [[ "$PILOT" == true ]]; then
  CONDITIONS=(cold warm)
else
  CONDITIONS=(single)
fi

read -r -d '' PHASE174_CONTAINER_COMMAND <<'CONTAINER' || true
set -eu
now_ms() { node -e 'process.stdout.write(String(Number(process.hrtime.bigint() / 1000000n)))'; }
condition_dir="$PHASE174_EVIDENCE_DIR"
mkdir -p "$condition_dir"
if [ ! -d /cache/playwright ]; then mkdir -p /cache/playwright; fi
export PLAYWRIGHT_BROWSERS_PATH=/cache/playwright
demo_evidence_dir="${DEMO_BROWSER_EVIDENCE_DIR:-/workspace/reference/demo_app/tmp/demo_browser_evidence}"

mark=$(now_ms)
node assets/scripts/check-demo-browser-deps.cjs --lock-only
demo_lock_audit_ms=$(( $(now_ms) - mark ))

mark=$(now_ms)
npm --prefix assets ci --no-audit --no-fund
demo_npm_ci_ms=$(( $(now_ms) - mark ))

demo_cli=/workspace/reference/demo_app/assets/node_modules/.bin/playwright
demo_version=$("$demo_cli" --version | sed 's/^Version //')
demo_revision=$(node -e 'const b=require("./assets/node_modules/playwright-core/browsers.json").browsers.find(item=>item.name==="chromium"&&item.installByDefault); if(!b) process.exit(2); process.stdout.write(String(b.revision));')
demo_cache=miss
if [ -d "$PLAYWRIGHT_BROWSERS_PATH/chromium-$demo_revision" ] && [ -d "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-$demo_revision" ]; then demo_cache=hit; fi
mark=$(now_ms)
npx --prefix assets playwright install chromium
demo_browser_install_ms=$(( $(now_ms) - mark ))
DEMO_PLAYWRIGHT_VERSION="$demo_version" DEMO_CHROMIUM_REVISION="$demo_revision" DEMO_CACHE_STATE="$demo_cache" DEMO_INSTALL_MS="$demo_browser_install_ms" node -e 'const fs=require("node:fs"); const data={schema_version:"phase174-demo-browser.v1",run_identity:{run_id:process.env.PHASE174_RUN_ID,condition:process.env.PHASE174_CONDITION,source_revision:process.env.PHASE174_SOURCE_REVISION,source_digest:process.env.PHASE174_SOURCE_DIGEST},version:process.env.DEMO_PLAYWRIGHT_VERSION,chromium_revision:process.env.DEMO_CHROMIUM_REVISION,cache_directory:process.env.PLAYWRIGHT_BROWSERS_PATH,cache_state:process.env.DEMO_CACHE_STATE,installer_ms:Number(process.env.DEMO_INSTALL_MS)}; fs.writeFileSync(process.env.PHASE174_EVIDENCE_DIR+"/demo-browser.json",JSON.stringify(data,null,2)+"\n");'

mark=$(now_ms)
if npm --silent --prefix assets run test:e2e -- --reporter=json > "$demo_evidence_dir/playwright-report.json"; then
  demo_scan_status=0
else
  demo_scan_status=$?
fi
demo_scan_ms=$(( $(now_ms) - mark ))
if [ "$demo_scan_status" -ne 0 ]; then
  DEMO_LOCK_AUDIT_MS="$demo_lock_audit_ms" DEMO_NPM_CI_MS="$demo_npm_ci_ms" DEMO_BROWSER_INSTALL_MS="$demo_browser_install_ms" DEMO_SCAN_MS="$demo_scan_ms" node -e 'const fs=require("node:fs"); const data={demo_lock_audit_ms:Number(process.env.DEMO_LOCK_AUDIT_MS),demo_npm_ci_ms:Number(process.env.DEMO_NPM_CI_MS),demo_browser_install_ms:Number(process.env.DEMO_BROWSER_INSTALL_MS),demo_scan_ms:Number(process.env.DEMO_SCAN_MS)}; fs.writeFileSync(process.env.PHASE174_EVIDENCE_DIR+"/partial-timings.json",JSON.stringify(data,null,2)+"\n");'
  exit "$demo_scan_status"
fi

cd /workspace
mark=$(now_ms)
npm --prefix mailglass_admin ci --no-audit --no-fund
admin_npm_ci_ms=$(( $(now_ms) - mark ))
admin_cli=/workspace/mailglass_admin/node_modules/.bin/playwright
admin_version=$("$admin_cli" --version | sed 's/^Version //')
admin_revision=$(node -e 'const b=require("./mailglass_admin/node_modules/playwright-core/browsers.json").browsers.find(item=>item.name==="chromium"&&item.installByDefault); if(!b) process.exit(2); process.stdout.write(String(b.revision));')
admin_cache=miss
if [ -d "$PLAYWRIGHT_BROWSERS_PATH/chromium-$admin_revision" ] && [ -d "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-$admin_revision" ]; then admin_cache=hit; fi
admin_install_log="$condition_dir/admin-browser-install.log"
mark=$(now_ms)
if "$admin_cli" install chromium > "$admin_install_log" 2>&1; then admin_install_status=0; else admin_install_status=$?; fi
admin_browser_install_ms=$(( $(now_ms) - mark ))
cat "$admin_install_log"
ADMIN_PLAYWRIGHT_VERSION="$admin_version" ADMIN_CHROMIUM_REVISION="$admin_revision" ADMIN_CACHE_STATE="$admin_cache" ADMIN_INSTALL_MS="$admin_browser_install_ms" ADMIN_INSTALL_STATUS="$admin_install_status" node -e 'const fs=require("node:fs"); const data={schema_version:"phase174-admin-browser.v1",run_identity:{run_id:process.env.PHASE174_RUN_ID,condition:process.env.PHASE174_CONDITION,source_revision:process.env.PHASE174_SOURCE_REVISION,source_digest:process.env.PHASE174_SOURCE_DIGEST},cli:"/workspace/mailglass_admin/node_modules/.bin/playwright",version:process.env.ADMIN_PLAYWRIGHT_VERSION,chromium_revision:process.env.ADMIN_CHROMIUM_REVISION,cache_directory:process.env.PLAYWRIGHT_BROWSERS_PATH,cache_state:process.env.ADMIN_CACHE_STATE,installer_ms:Number(process.env.ADMIN_INSTALL_MS),install_exit_code:Number(process.env.ADMIN_INSTALL_STATUS)}; fs.writeFileSync(process.env.PHASE174_EVIDENCE_DIR+"/admin-browser.json",JSON.stringify(data,null,2)+"\n");'
if [ "$admin_install_status" -ne 0 ]; then exit "$admin_install_status"; fi

mark=$(now_ms)
if npm --prefix mailglass_admin run test:storybook-axe; then admin_scan_status=0; else admin_scan_status=$?; fi
admin_axe_scan_ms=$(( $(now_ms) - mark ))
if [ -d /workspace/mailglass_admin/test-results ]; then
  mkdir -p "$condition_dir/admin-test-results"
  cp -a /workspace/mailglass_admin/test-results/. "$condition_dir/admin-test-results/"
fi
ADMIN_NPM_CI_MS="$admin_npm_ci_ms" ADMIN_BROWSER_INSTALL_MS="$admin_browser_install_ms" ADMIN_AXE_SCAN_MS="$admin_axe_scan_ms" DEMO_LOCK_AUDIT_MS="$demo_lock_audit_ms" DEMO_NPM_CI_MS="$demo_npm_ci_ms" DEMO_BROWSER_INSTALL_MS="$demo_browser_install_ms" DEMO_SCAN_MS="$demo_scan_ms" node -e 'const fs=require("node:fs"); const data={demo_lock_audit_ms:Number(process.env.DEMO_LOCK_AUDIT_MS),demo_npm_ci_ms:Number(process.env.DEMO_NPM_CI_MS),demo_browser_install_ms:Number(process.env.DEMO_BROWSER_INSTALL_MS),demo_scan_ms:Number(process.env.DEMO_SCAN_MS),admin_npm_ci_ms:Number(process.env.ADMIN_NPM_CI_MS),admin_browser_install_ms:Number(process.env.ADMIN_BROWSER_INSTALL_MS),admin_axe_scan_ms:Number(process.env.ADMIN_AXE_SCAN_MS)}; fs.writeFileSync(process.env.PHASE174_EVIDENCE_DIR+"/container-timings.json",JSON.stringify(data,null,2)+"\n");'
exit "$admin_scan_status"
CONTAINER

PHASE174_ENV_ARGS=(
  --env DEMO_CANDIDATE_REVISION="$DEMO_CANDIDATE_REVISION"
  --env DEMO_CANDIDATE_DIRTY="$DEMO_CANDIDATE_DIRTY"
  --env DEMO_EVIDENCE_RUN_ID="$DEMO_EVIDENCE_RUN_ID"
  --env DEMO_EVIDENCE_PROJECT_ID="$DEMO_EVIDENCE_PROJECT_ID"
  --env DEMO_EVIDENCE_RESET_TOKEN="$DEMO_EVIDENCE_RESET_TOKEN"
  --env PLAYWRIGHT_BROWSERS_PATH=/cache/playwright
  --env CI=true
)
for key in GITHUB_ACTIONS GITHUB_RUN_ID GITHUB_RUN_ATTEMPT GITHUB_JOB GITHUB_SHA GITHUB_REPOSITORY RUNNER_NAME RUNNER_OS RUNNER_ARCH; do
  value="${!key:-}"
  PHASE174_ENV_ARGS+=(--env "$key=$value")
done

condition_records=()
PILOT_START_MS="$(now_ms)"
PILOT_START_ISO="$(now_iso)"
SERVICE_START_MS=0
SERVICE_START_AT=""
for condition in "${CONDITIONS[@]}"; do
  condition_dir="$RUN_EVIDENCE_ROOT/phase174/$condition"
  mkdir -p "$condition_dir"
  DEMO_BROWSER_EVIDENCE_DIR="$condition_dir" node "$ROOT_DIR/scripts/prepare_phase173_baselines.cjs"
  mkdir -p "$condition_dir/captures"
  if [[ "$condition" == cold || "$condition" == single ]]; then
    SERVICE_START_AT="$(now_iso)"
    service_start_begin="$(now_ms)"
    SERVICES_STARTED=true
    compose up --build --detach --wait --wait-timeout 300 demo
    SERVICE_START_MS=$(( $(now_ms) - service_start_begin ))
    condition_started_at="$SERVICE_START_AT"
    condition_started_ms="$service_start_begin"
    export DEMO_PAGE_CONTROLLER_BEAM_SHA256="$(compose exec -T demo sha256sum "$PAGE_CONTROLLER_BEAM" | awk '{print $1}')"
    export DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256="$(compose exec -T demo sha256sum "$UNSUBSCRIBE_BEAM" | awk '{print $1}')"
    for digest in "$DEMO_PAGE_CONTROLLER_BEAM_SHA256" "$DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256"; do
      if [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
        echo "Could not identify the compiled route templates in the run-owned demo container" >&2
        exit 1
      fi
    done
  else
    SERVICE_START_MS=0
    condition_started_at="$(now_iso)"
    condition_started_ms="$(now_ms)"
  fi

  CONDITION_RUN_ID="$RUN_ID-$condition"
  PHASE174_CONDITION_DIR="/workspace/reference/demo_app/tmp/demo_browser_evidence/$COMPOSE_PROJECT/phase174/$condition"
  COMPOSE_BUILD_ARGS=()
  if [[ "$condition" == cold || "$condition" == single ]]; then COMPOSE_BUILD_ARGS+=(--build); fi
  if compose run "${COMPOSE_BUILD_ARGS[@]}" --no-deps --rm \
    "${PHASE174_ENV_ARGS[@]}" \
    --env PHASE174_CONDITION="$condition" \
    --env PHASE174_EVIDENCE_DIR="$PHASE174_CONDITION_DIR" \
    --env DEMO_BROWSER_EVIDENCE_DIR="$PHASE174_CONDITION_DIR" \
    --env PHASE174_RUN_ID="$CONDITION_RUN_ID" \
    --env PHASE174_SOURCE_REVISION="$DEMO_CANDIDATE_REVISION" \
    --env PHASE174_SOURCE_DIGEST="$SOURCE_DIGEST" \
    --env PHASE174_JOB_ID="$PHASE174_JOB_ID" \
    --env STORYBOOK_BASE_URL=http://demo:4015 \
    --env STORYBOOK_AXE_RUN_ID="$CONDITION_RUN_ID" \
    --env STORYBOOK_AXE_EXECUTION_TOKEN="$CONDITION_RUN_ID" \
    --env STORYBOOK_SOURCE_REVISION="$DEMO_CANDIDATE_REVISION" \
    --env STORYBOOK_SOURCE_DIGEST="$SOURCE_DIGEST" \
    --env STORYBOOK_AXE_REPORT="$PHASE174_CONDITION_DIR/axe.json" \
    --env DEMO_PAGE_CONTROLLER_BEAM_SHA256="$DEMO_PAGE_CONTROLLER_BEAM_SHA256" \
    --env DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256="$DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256" \
    demo_e2e sh -lc "$PHASE174_CONTAINER_COMMAND"; then
    :
  else
    run_status=$?
    save_failure_outputs "$condition" "$run_status" || true
    exit "$run_status"
  fi

  phase173_output_dir="$EVIDENCE_DIR"
  if [[ "$PHASE174" == true ]]; then phase173_output_dir="$condition_dir"; fi
  for report in playwright-report.json phase173-captures.json checkpoint.json; do
    if [[ -f "$phase173_output_dir/$report" && "$phase173_output_dir/$report" != "$condition_dir/$report" ]]; then
      cp "$phase173_output_dir/$report" "$condition_dir/demo-${report}"
    fi
  done
  DEMO_BROWSER_EVIDENCE_DIR="$phase173_output_dir" DEMO_CANDIDATE_REVISION="$DEMO_CANDIDATE_REVISION" \
    node "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"
  if [[ "$phase173_output_dir" == "$condition_dir" ]]; then
    cp "$phase173_output_dir/playwright-report.json" "$condition_dir/demo-playwright-report.json"
  else
    cp "$phase173_output_dir/playwright-report.json" "$condition_dir/demo-playwright-report.json"
    cp "$phase173_output_dir/phase173-captures.json" "$condition_dir/phase173-captures.json"
    cp "$phase173_output_dir/checkpoint.json" "$condition_dir/phase173-checkpoint.json"
  fi

  node -e 'const fs=require("node:fs"); const path=require("node:path"); const dir=process.argv[1]; const identity={run_id:process.argv[2],condition:process.argv[3],source_revision:process.argv[4],source_digest:process.argv[5]}; for(const file of ["hooks.json","fidelity.json"]){const p=path.join(dir,file); const data=JSON.parse(fs.readFileSync(p,"utf8")); data.run_identity=identity; fs.writeFileSync(p,JSON.stringify(data,null,2)+"\n");}' \
    "$condition_dir" "$CONDITION_RUN_ID" "$condition" "$DEMO_CANDIDATE_REVISION" "$SOURCE_DIGEST"

  comparison_start="$(now_ms)"
  node "$ROOT_DIR/mailglass_admin/e2e/support/storybook-axe.cjs" \
    --report "$condition_dir/axe.json" \
    --approved "$ROOT_DIR/mailglass_admin/docs/storybook-axe-approved.json" \
    --manifest "$ROOT_DIR/reference/persona_spec/quick_view_scenarios.json" \
    --run-id "$CONDITION_RUN_ID" \
    --revision "$DEMO_CANDIDATE_REVISION" \
    --source-digest "$SOURCE_DIGEST"
  comparison_ms=$(( $(now_ms) - comparison_start ))

  condition_completed_at="$(now_iso)"
  condition_completed_ms="$(now_ms)"
  container_timings="$condition_dir/container-timings.json"
  if [[ ! -f "$container_timings" ]]; then
    echo "Phase174 setup/test timing receipt is missing for $condition" >&2
    exit 1
  fi
  node - "$ROOT_DIR" "$condition_dir" "$RUN_ID" "$condition" "$DEMO_CANDIDATE_REVISION" "$SOURCE_DIGEST" \
    "$PHASE174_JOB_ID" "$condition_started_at" "$condition_completed_at" "$condition_started_ms" "$condition_completed_ms" "$SERVICE_START_MS" "$comparison_ms" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const { collectTests } = require(path.join(process.argv[2], "reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"));
const { selectedCases } = require(path.join(process.argv[2], "mailglass_admin/e2e/support/storybook-axe.cjs"));
const root = process.argv[2];
const conditionDir = process.argv[3];
const runId = process.argv[4];
const condition = process.argv[5];
const revision = process.argv[6];
const sourceDigest = process.argv[7];
const jobId = process.argv[8];
const startedAt = process.argv[9];
const completedAt = process.argv[10];
const startedMs = Number(process.argv[11]);
const completedMs = Number(process.argv[12]);
const serviceStartMs = Number(process.argv[13]);
const comparisonMs = Number(process.argv[14]);
const report = JSON.parse(fs.readFileSync(path.join(conditionDir, "demo-playwright-report.json"), "utf8"));
const tests = collectTests(report.suites);
const hooks = JSON.parse(fs.readFileSync(path.join(conditionDir, "hooks.json"), "utf8"));
const fidelity = JSON.parse(fs.readFileSync(path.join(conditionDir, "fidelity.json"), "utf8"));
const axe = JSON.parse(fs.readFileSync(path.join(conditionDir, "axe.json"), "utf8"));
const manifest = JSON.parse(fs.readFileSync(path.join(root, "reference/persona_spec/quick_view_scenarios.json"), "utf8"));
const expectedAxe = selectedCases(manifest).cases.map(item => item.case_id);
const counts = { demo: tests.length, hooks: 6, fidelity: fidelity.selectedCaseIds.length, axe: axe.executed.length };
counts.total = counts.demo + counts.hooks + counts.fidelity + counts.axe;
const timing = JSON.parse(fs.readFileSync(path.join(conditionDir, "container-timings.json"), "utf8"));
const timingsMs = {
  service_start: serviceStartMs,
  demo_lock_audit: timing.demo_lock_audit_ms,
  demo_npm_ci: timing.demo_npm_ci_ms,
  demo_browser_install: timing.demo_browser_install_ms,
  demo_scan: timing.demo_scan_ms,
  admin_npm_ci: timing.admin_npm_ci_ms,
  admin_browser_install: timing.admin_browser_install_ms,
  admin_axe_scan: timing.admin_axe_scan_ms,
  comparison: comparisonMs
};
const row = {
  condition,
  run_id: `${runId}-${condition}`,
  job_id: jobId,
  source_revision: revision,
  source_digest: sourceDigest,
  status: "passed",
  started_at: startedAt,
  completed_at: completedAt,
  timings_ms: timingsMs,
  expected_counts: counts,
  executed_counts: counts,
  demo_case_ids: tests.map(item => item.case_id),
  hook_case_ids: ["storybook:mounted-preview","delivery:escape-focus-return","delivery:close-focus-return","delivery:reconnect-focus-return","inbound:close-focus-return","inbound:escape-focus-return"],
  fidelity_case_ids: fidelity.selectedCaseIds,
  axe_case_ids: expectedAxe,
  setup_ms: serviceStartMs + timing.demo_lock_audit_ms + timing.demo_npm_ci_ms + timing.demo_browser_install_ms + timing.admin_npm_ci_ms + timing.admin_browser_install_ms,
  execution_ms: timing.demo_scan_ms + timing.admin_axe_scan_ms + comparisonMs,
  wall_ms: completedMs - startedMs,
  admin_browser: JSON.parse(fs.readFileSync(path.join(conditionDir, "admin-browser.json"), "utf8")),
  demo_browser: JSON.parse(fs.readFileSync(path.join(conditionDir, "demo-browser.json"), "utf8"))
};
fs.writeFileSync(path.join(conditionDir, "execution-condition.json"), JSON.stringify(row, null, 2) + "\n");
NODE
  condition_records+=("$condition_dir/execution-condition.json")
  copy_phase173_outputs "$RUN_EVIDENCE_ROOT"
done

mkdir -p "$RUN_EVIDENCE_ROOT/phase174"
if [[ "$PILOT" == true ]]; then
  cp "$RUN_EVIDENCE_ROOT/phase174/warm/axe.json" "$RUN_EVIDENCE_ROOT/phase174/axe.json"
  cp "$RUN_EVIDENCE_ROOT/phase174/warm/hooks.json" "$RUN_EVIDENCE_ROOT/phase174/hooks.json"
  cp "$RUN_EVIDENCE_ROOT/phase174/warm/fidelity.json" "$RUN_EVIDENCE_ROOT/phase174/fidelity.json"
else
  cp "$RUN_EVIDENCE_ROOT/phase174/single/axe.json" "$RUN_EVIDENCE_ROOT/phase174/axe.json"
  cp "$RUN_EVIDENCE_ROOT/phase174/single/hooks.json" "$RUN_EVIDENCE_ROOT/phase174/hooks.json"
  cp "$RUN_EVIDENCE_ROOT/phase174/single/fidelity.json" "$RUN_EVIDENCE_ROOT/phase174/fidelity.json"
fi

node - "$ROOT_DIR" "$RUN_EVIDENCE_ROOT" "$RUN_ID" "$PILOT" "$SOURCE_IDENTITY_JSON" "$GITHUB_ACTIONS" "$GITHUB_RUN_ID" "$GITHUB_RUN_ATTEMPT" "$GITHUB_JOB" "$GITHUB_SHA" "$GITHUB_REPOSITORY" "$RUNNER_NAME" "$RUNNER_OS" "$RUNNER_ARCH" "${condition_records[@]}" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const evidenceRoot = process.argv[3];
const runId = process.argv[4];
const pilot = process.argv[5] === "true";
const source = JSON.parse(process.argv[6]);
const github = {
  actions: process.argv[7] === "true",
  run_id: process.argv[8],
  run_attempt: process.argv[9],
  job: process.argv[10],
  sha: process.argv[11],
  repository: process.argv[12],
  runner_name: process.argv[13],
  runner_os: process.argv[14],
  runner_arch: process.argv[15]
};
const rows = process.argv.slice(16).map(file => JSON.parse(fs.readFileSync(file, "utf8")));
const phaseDir = path.join(evidenceRoot, "phase174");
const execution = {
  schema_version: "phase174-execution.v1",
  phase: 174,
  run_id: runId,
  mode: github.actions ? "ci" : "local",
  pilot,
  source_revision: source.source_revision,
  source_digest: source.source_digest,
  source,
  github,
  reset: { compose_project: process.env.DEMO_EVIDENCE_PROJECT_ID, host_http_port: process.env.MAILGLASS_DEMO_HTTP_PORT, host_db_port: process.env.MAILGLASS_DEMO_DB_PORT, token_recorded: false },
  serialization: { playwright_workers: 1, conditions_run_serially: true },
  conditions: rows
};
const costConditions = rows.map(row => {
  const runnerMinutes = github.actions ? row.wall_ms / 60000 : null;
  return {
    condition: row.condition,
    run_id: row.run_id,
    job_id: row.job_id,
    source_revision: row.source_revision,
    source_digest: row.source_digest,
    timings_ms: row.timings_ms,
    setup_ms: row.setup_ms,
    execution_ms: row.execution_ms,
    teardown_ms: 0,
    wall_ms: row.wall_ms,
    runner_count: 1,
    runner_minutes: runnerMinutes,
    runner_minutes_status: github.actions ? "wrapper-condition-elapsed" : "awaiting-hosted-job",
    expected_counts: row.expected_counts,
    executed_counts: row.executed_counts,
    admin_browser: row.admin_browser,
    demo_browser: row.demo_browser
  };
});
const cost = {
  schema_version: "phase174-cost.v1",
  run_id: runId,
  source_revision: source.source_revision,
  source_digest: source.source_digest,
  pilot,
  conditions: costConditions,
  pilot_wall_ms: rows.reduce((sum, row) => sum + row.wall_ms, 0),
  added_cost: { status: "unmeasured", reason: "A same-profile existing-lane baseline has not yet been compared; Task 2 must record the actual hosted job and cost disposition." },
  budget: { added_wall_minutes: 5, added_runner_minutes: 10, disposition: github.actions ? "awaiting-baseline-review" : "awaiting-hosted-job" }
};
fs.writeFileSync(path.join(phaseDir, "execution.json"), JSON.stringify(execution, null, 2) + "\n");
fs.writeFileSync(path.join(phaseDir, "cost.json"), JSON.stringify(cost, null, 2) + "\n");
NODE

teardown_start="$(now_ms)"
if compose down --volumes --remove-orphans >/dev/null 2>&1; then
  SERVICES_STARTED=false
else
  echo "Run-owned Demo services could not be fully torn down" >&2
  exit 1
fi
TEARDOWN_MS=$(( $(now_ms) - teardown_start ))
PILOT_WALL_MS=$(( $(now_ms) - PILOT_START_MS ))
node - "$RUN_EVIDENCE_ROOT/phase174/cost.json" "$TEARDOWN_MS" "$PILOT_WALL_MS" <<'NODE'
const fs=require("node:fs");
const file=process.argv[2];
const cost=JSON.parse(fs.readFileSync(file,"utf8"));
cost.conditions[cost.conditions.length-1].teardown_ms=Number(process.argv[3]);
cost.pilot_wall_ms=Number(process.argv[4]);
cost.teardown_completed_at=new Date().toISOString();
fs.writeFileSync(file,JSON.stringify(cost,null,2)+"\n");
NODE

CHECK_ARGS=(--evidence-dir "$RUN_EVIDENCE_ROOT")
if [[ "$PILOT" == true ]]; then CHECK_ARGS+=(--pilot); fi
node "$ROOT_DIR/scripts/check_phase174_evidence.cjs" "${CHECK_ARGS[@]}"

echo "Phase174 evidence retained at $RUN_EVIDENCE_ROOT"
