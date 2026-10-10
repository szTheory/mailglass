#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="$ROOT_DIR/scripts/run_demo_browser_evidence.sh"
TEMP_DIR="$(mktemp -d)"
EVIDENCE_DIR="$ROOT_DIR/reference/demo_app/tmp/demo_browser_evidence"
mkdir -p "$EVIDENCE_DIR"
for file in playwright-report.json phase173-captures.json checkpoint.json; do
  if [[ -f "$EVIDENCE_DIR/$file" ]]; then
    cp "$EVIDENCE_DIR/$file" "$TEMP_DIR/$file.saved"
    touch "$TEMP_DIR/$file.existed"
  fi
done
if [[ -d "$EVIDENCE_DIR/retained" ]]; then
  cp -a "$EVIDENCE_DIR/retained" "$TEMP_DIR/retained.saved"
  touch "$TEMP_DIR/retained.existed"
fi
restore_evidence_files() {
  for file in playwright-report.json phase173-captures.json checkpoint.json; do
    if [[ -f "$TEMP_DIR/$file.existed" ]]; then
      cp "$TEMP_DIR/$file.saved" "$EVIDENCE_DIR/$file"
    else
      rm -f "$EVIDENCE_DIR/$file"
    fi
  done
  rm -rf "$EVIDENCE_DIR/retained"
  if [[ -f "$TEMP_DIR/retained.existed" ]]; then
    cp -a "$TEMP_DIR/retained.saved" "$EVIDENCE_DIR/retained"
  fi
  rm -rf "$TEMP_DIR"
}
trap restore_evidence_files EXIT
mkdir -p "$TEMP_DIR/bin"
mkdir -p "$EVIDENCE_DIR/retained"
printf 'stale\n' >"$EVIDENCE_DIR/retained/stale.txt"

cat >"$TEMP_DIR/bin/docker" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\t%s\t%s\n' "$*" "${MAILGLASS_DEMO_HTTP_PORT:-}" "${MAILGLASS_DEMO_DB_PORT:-}" >>"$DEMO_FAKE_DOCKER_LOG"
if [[ " $* " == *" up "* && -e "$DEMO_FAKE_EVIDENCE_DIR/retained" ]]; then
  echo "wrapper did not remove stale retained evidence before the run" >&2
  exit 24
fi
if [[ "${DEMO_FAKE_DOCKER_FAIL:-}" == run && " $* " == *" run "* ]]; then
  exit 23
fi
if [[ " $* " == *" run "* ]]; then
  mkdir -p "$DEMO_FAKE_EVIDENCE_DIR"
  : >"$DEMO_FAKE_EVIDENCE_DIR/playwright-report.json"
  : >"$DEMO_FAKE_EVIDENCE_DIR/phase173-captures.json"
fi
if [[ " $* " == *" exec "* ]]; then
  printf '%064d  fake-runtime.beam\n' 0
fi
SH

cat >"$TEMP_DIR/bin/node" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$DEMO_FAKE_NODE_LOG"
SH
chmod +x "$TEMP_DIR/bin/docker" "$TEMP_DIR/bin/node"

run_contract() {
  local mode="$1"
  : >"$DEMO_FAKE_DOCKER_LOG"
  : >"$DEMO_FAKE_NODE_LOG"
  if [[ "$mode" == failure ]]; then
    if PATH="$TEMP_DIR/bin:$PATH" \
      DEMO_FAKE_DOCKER_LOG="$DEMO_FAKE_DOCKER_LOG" \
      DEMO_FAKE_NODE_LOG="$DEMO_FAKE_NODE_LOG" \
      DEMO_FAKE_EVIDENCE_DIR="$EVIDENCE_DIR" \
      DEMO_FAKE_DOCKER_FAIL=run \
      bash "$WRAPPER"; then
      echo "failure contract unexpectedly returned success" >&2
      return 1
    fi
  else
    PATH="$TEMP_DIR/bin:$PATH" \
      DEMO_FAKE_DOCKER_LOG="$DEMO_FAKE_DOCKER_LOG" \
      DEMO_FAKE_NODE_LOG="$DEMO_FAKE_NODE_LOG" \
      DEMO_FAKE_EVIDENCE_DIR="$EVIDENCE_DIR" \
      bash "$WRAPPER"
  fi
}

assert_project_and_ports() {
  local project_prefix="mailglass-evidence-"
  local line
  local project=""
  local http_port=""
  local db_port=""
  while IFS= read -r line; do
    local command project_argument http_argument db_argument
    IFS=$'\t' read -r command http_argument db_argument <<<"$line"
    project_argument="$(sed -nE 's/.* -p (mailglass-evidence-[^ ]+).*/\1/p' <<<"$command")"
    [[ "$project_argument" == "$project_prefix"* ]] || {
      echo "Compose command is not scoped to a run-owned evidence project: $line" >&2
      return 1
    }
    [[ "$http_argument" =~ ^[0-9]+$ && "$db_argument" =~ ^[0-9]+$ && "$http_argument" != "$db_argument" ]] || {
      echo "Compose command did not receive distinct isolated ports: $line" >&2
      return 1
    }
    [[ "$http_argument" != 4015 && "$db_argument" != 5415 ]] || {
      echo "Compose command reused a retained demo default port: $line" >&2
      return 1
    }
    if [[ -z "$project" ]]; then
      project="$project_argument"
      http_port="$http_argument"
      db_port="$db_argument"
    elif [[ "$project" != "$project_argument" || "$http_port" != "$http_argument" || "$db_port" != "$db_argument" ]]; then
      echo "Compose lifecycle changed project identity or host ports: $line" >&2
      return 1
    fi
  done <"$DEMO_FAKE_DOCKER_LOG"
}

DEMO_FAKE_DOCKER_LOG="$TEMP_DIR/docker.log"
DEMO_FAKE_NODE_LOG="$TEMP_DIR/node.log"

run_contract success
assert_project_and_ports
grep -F 'phase173-evidence.spec.js' "$DEMO_FAKE_DOCKER_LOG" >/dev/null || {
  echo "success path did not select phase173-evidence.spec.js" >&2
  exit 1
}
grep -F 'npm --silent --prefix assets run test:e2e -- phase173-evidence.spec.js --reporter=json' "$DEMO_FAKE_DOCKER_LOG" >/dev/null || {
  echo "success path did not use the focused existing Playwright script" >&2
  exit 1
}
grep -F 'sha256sum /workspace/reference/demo_app/_build/dev/lib/mailglass_demo/ebin/Elixir.MailglassDemoWeb.PageController.beam' "$DEMO_FAKE_DOCKER_LOG" >/dev/null || {
  echo "success path did not fingerprint the compiled demo route template" >&2
  exit 1
}
if grep -E 'test:e2e:ci|demo\.spec\.js' "$DEMO_FAKE_DOCKER_LOG" >/dev/null; then
  echo "success path selected the full suite or the dirty Phase 172 demo spec" >&2
  exit 1
fi
grep -F 'check-demo-browser-evidence.cjs' "$DEMO_FAKE_NODE_LOG" >/dev/null || {
  echo "success path did not run the evidence checkpoint" >&2
  exit 1
}
run_contract failure
assert_project_and_ports
grep -E 'logs .*demo demo_e2e' "$DEMO_FAKE_DOCKER_LOG" >/dev/null || {
  echo "failure path did not collect owned service logs" >&2
  exit 1
}
grep -E 'down .*--volumes .*--remove-orphans' "$DEMO_FAKE_DOCKER_LOG" >/dev/null || {
  echo "failure path did not remove only the owned project resources" >&2
  exit 1
}
if grep -E 'down .*mailglass-demo|down .*--all|down .*--rmi|prune|reset' "$DEMO_FAKE_DOCKER_LOG" >/dev/null; then
  echo "failure path attempted broad or retained-project cleanup" >&2
  exit 1
fi

echo "demo browser evidence wrapper contract passed"
