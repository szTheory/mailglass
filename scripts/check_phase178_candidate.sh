#!/usr/bin/env bash
# Isolated exact-SHA candidate preview launcher (Phase 178, UIQ-08, D-14).
#
# Slim sibling of scripts/check_phase173_candidate.sh. It reuses that script's
# mechanics (detached worktree, port refusal, unique Compose project, route
# probes, source/built/served CSS triple, exact-SHA CI lookup, printed teardown)
# without its Phase 168-173 summary and baseline-PNG requirements, so it runs for
# any candidate SHA.
#
#   check_phase178_candidate.sh --sha <40-hex> [--route <path>]... [--require-ci] [--record <path>]
#   check_phase178_candidate.sh --teardown <record.json>
#
# The launcher leaves the services running and prints the teardown command.
# It never touches the owner's retained review demo (Compose project
# mailglass-storybook-review-demo on 127.0.0.1:4015/5415) and performs no GitHub
# write: GitHub access is read-only `gh api`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_PREFIX="mailglass-phase178-review-"
OWNER_REVIEW_PROJECT="mailglass-storybook-review-demo"
RECORD_DIR_REL="reference/demo_app/tmp/phase178_candidate"
GITHUB_REPO="szTheory/mailglass"
REQUIRED_CI_CONTEXTS=("CI Green" "Guard Release Trigger")
DEFAULT_ROUTES=(
  "/dev/mail"
  "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin"
  "/dev/storybook/preview_authoring"
  "/dev/storybook/preview_chrome"
  "/dev/storybook/primitives/stat_card"
  "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar"
)

# Pinned toolchain defaults for any host-side mix the caller runs next to this
# launcher. These are the .tool-versions-compatible installed versions (D-11).
export ASDF_ERLANG_VERSION="${ASDF_ERLANG_VERSION:-27.3.4.15}"
export ASDF_ELIXIR_VERSION="${ASDF_ELIXIR_VERSION:-1.18.4-otp-27}"

fail() {
  printf 'phase178 candidate: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'phase178 candidate: %s\n' "$*" >&2
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# ---------------------------------------------------------------------------
# Pure helpers (exercised by scripts/test_check_phase178_candidate.sh)
# ---------------------------------------------------------------------------

# extract_css_href <html-file>
# Prints the versioned Admin CSS href (…/dev/mail/css-<32 hex>); returns 1 and
# prints nothing when the page has none.
extract_css_href() {
  local file="$1" match
  [[ -f "$file" ]] || return 1
  match="$(grep -oE "href=[\"'][^\"']*/dev/mail/css-[a-f0-9]{32}[\"']" "$file" | head -n 1 || true)"
  [[ -n "$match" ]] || return 1
  match="${match#href=}"
  match="${match#[\"\']}"
  match="${match%[\"\']}"
  printf '%s\n' "$match"
}

# css_triple <source-css> <built-css> <served-css>
# Prints "<match|mismatch> <source sha256> <built sha256> <served sha256>".
# Returns 0 only when built == served.
css_triple() {
  local source_sha built_sha served_sha verdict=mismatch rc=1
  source_sha="$(sha256_file "$1")"
  built_sha="$(sha256_file "$2")"
  served_sha="$(sha256_file "$3")"
  if [[ "$built_sha" == "$served_sha" ]]; then
    verdict=match
    rc=0
  fi
  printf '%s %s %s %s\n' "$verdict" "$source_sha" "$built_sha" "$served_sha"
  return "$rc"
}

# allocate_ports
# Prints "<http port> <db port>": two distinct free loopback ports, never the
# owner review demo defaults 4015 / 5415. PHASE178_TEST_PORTS="a b" is a
# test-only override that is subject to the same refusals.
allocate_ports() {
  local http_port db_port attempt
  for attempt in 1 2 3 4 5; do
    if [[ -n "${PHASE178_TEST_PORTS:-}" ]]; then
      read -r http_port db_port <<<"$PHASE178_TEST_PORTS"
    else
      read -r http_port db_port < <(python3 - <<'PY'
import socket
ports = []
sockets = []
for _ in range(2):
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    sockets.append(sock)
    ports.append(sock.getsockname()[1])
print(*ports)
for sock in sockets:
    sock.close()
PY
      )
    fi
    if ! [[ "${http_port:-}" =~ ^[0-9]+$ && "${db_port:-}" =~ ^[0-9]+$ && "$http_port" != "$db_port" ]]; then
      note "could not allocate two distinct numeric ports (got '${http_port:-} ${db_port:-}')"
      return 1
    fi
    if [[ "$http_port" == 4015 || "$http_port" == 5415 || "$db_port" == 4015 || "$db_port" == 5415 ]]; then
      note "refusing ports $http_port/$db_port: 4015 and 5415 belong to the retained owner review demo"
      [[ -z "${PHASE178_TEST_PORTS:-}" ]] || return 1
      continue
    fi
    printf '%s %s\n' "$http_port" "$db_port"
    return 0
  done
  note "port allocation kept colliding with the owner review demo ports"
  return 1
}

# assert_safe_project <name>
# Accepts only names this launcher creates. Refuses the owner review demo,
# empty names and anything that merely resembles the prefix.
assert_safe_project() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    note "refusing empty Compose project name"
    return 1
  fi
  if [[ "$name" == "$OWNER_REVIEW_PROJECT" || "$name" == "$OWNER_REVIEW_PROJECT"-* ]]; then
    note "refusing to touch the owner review demo project: $name"
    return 1
  fi
  if ! [[ "$name" =~ ^mailglass-phase178-review-[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    note "refusing Compose project '$name': not a ${PROJECT_PREFIX}* project created by this launcher"
    return 1
  fi
  return 0
}

# ci_contexts_status <check-runs.json | ->
# Reads GitHub check-runs JSON (one or several concatenated pages) from a file
# or stdin. Prints {"status":"pass|fail","contexts":{<name>:<conclusion|missing>}}.
# Returns 0 only when every required context is completed/success.
ci_contexts_status() {
  local input="${1:--}" js
  read -r -d '' js <<'NODE' || true
const fs = require("node:fs");
const required = JSON.parse(process.argv[1]);
const source = process.argv[2];
const text = fs.readFileSync(source === "-" ? 0 : source, "utf8");
const docs = [];
let depth = 0, inString = false, escaped = false, start = -1;
for (let i = 0; i < text.length; i += 1) {
  const c = text[i];
  if (inString) {
    if (escaped) escaped = false;
    else if (c === "\\") escaped = true;
    else if (c === '"') inString = false;
    continue;
  }
  if (c === '"') inString = true;
  else if (c === "{" || c === "[") { if (depth === 0) start = i; depth += 1; }
  else if (c === "}" || c === "]") {
    depth -= 1;
    if (depth === 0) docs.push(JSON.parse(text.slice(start, i + 1)));
  }
}
const runs = docs.flatMap((doc) => Array.isArray(doc) ? doc : (doc && doc.check_runs) || []);
const contexts = {};
const failing = [];
for (const name of required) {
  const named = runs.filter((run) => run && run.name === name).sort((a, b) => (b.id || 0) - (a.id || 0));
  const latest = named[0];
  let state = "missing";
  if (latest) state = latest.status === "completed" ? String(latest.conclusion) : String(latest.status);
  contexts[name] = state;
  if (state !== "success") failing.push(`${name}=${state}`);
}
const status = failing.length === 0 ? "pass" : "fail";
process.stdout.write(JSON.stringify({ status, contexts }) + "\n");
if (failing.length > 0) process.stderr.write(`ci contexts not green: ${failing.join(", ")}\n`);
process.exit(failing.length === 0 ? 0 : 1);
NODE
  local required_json
  required_json="$(node -e 'process.stdout.write(JSON.stringify(process.argv.slice(1)))' "${REQUIRED_CI_CONTEXTS[@]}")"
  node -e "$js" "$required_json" "$input"
}

# restore_worktree_demo_lock <worktree> <sha>
# Compose runs mix inside the container against the bind-mounted worktree and
# can drift reference/demo_app/mix.lock. Restore it to the SHA's blob.
restore_worktree_demo_lock() {
  local worktree="$1" sha="$2" lock_path="reference/demo_app/mix.lock" expected actual
  expected="$(git -C "$worktree" rev-parse "$sha:$lock_path")" || return 1
  if ! git -C "$worktree" diff --quiet -- "$lock_path"; then
    git -C "$worktree" restore --worktree -- "$lock_path" || return 1
  fi
  actual="$(git -C "$worktree" hash-object -- "$lock_path")" || return 1
  [[ "$actual" == "$expected" ]]
}

# ---------------------------------------------------------------------------
# Record writing (reads only whitelisted PHASE178_REC_* variables: no env dump)
# ---------------------------------------------------------------------------

write_record() {
  local out="$1" js
  read -r -d '' js <<'NODE' || true
const fs = require("node:fs");
const path = require("node:path");
const env = process.env;
const lines = (value) => (value || "").split("\n").filter(Boolean);
const routes = lines(env.PHASE178_REC_ROUTES).map((line) => {
  const [route, status, finalUrl] = line.split("\t");
  return { route, status: Number(status) || 0, final_url: finalUrl || null };
});
const record = {
  schema_version: "phase178-candidate.v1",
  source_sha: env.PHASE178_REC_SHA,
  worktree: env.PHASE178_REC_WORKTREE,
  run_parent: env.PHASE178_REC_RUN_PARENT,
  compose_project: env.PHASE178_REC_PROJECT,
  base_url: env.PHASE178_REC_BASE_URL || null,
  ports: { http: Number(env.PHASE178_REC_HTTP_PORT) || null, database: Number(env.PHASE178_REC_DB_PORT) || null },
  routes,
  served_css_path: env.PHASE178_REC_SERVED_CSS_PATH || null,
  source_css_sha256: env.PHASE178_REC_SOURCE_CSS || null,
  built_css_sha256: env.PHASE178_REC_BUILT_CSS || null,
  served_css_sha256: env.PHASE178_REC_SERVED_CSS || null,
  ci_status: env.PHASE178_REC_CI_STATUS || "not_checked",
  ci_contexts: env.PHASE178_REC_CI_CONTEXTS ? JSON.parse(env.PHASE178_REC_CI_CONTEXTS) : null,
  final_status: env.PHASE178_REC_FINAL_STATUS,
  failures: lines(env.PHASE178_REC_FAILURES),
  teardown_commands: lines(env.PHASE178_REC_TEARDOWN),
  retained_services: lines(env.PHASE178_REC_RETAINED),
  teardown: null,
  created_at: new Date().toISOString()
};
fs.mkdirSync(path.dirname(process.argv[1]), { recursive: true });
fs.writeFileSync(process.argv[1], JSON.stringify(record, null, 2) + "\n");
NODE
  node -e "$js" "$out"
}

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------

do_teardown() {
  local record="$1" fields project worktree run_parent
  [[ -f "$record" ]] || fail "teardown record not found: $record"
  fields="$(node -e '
const r = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
process.stdout.write([r.compose_project || "", r.worktree || "", r.run_parent || ""].join("\n") + "\n");
' "$record")" || fail "teardown record is not readable JSON: $record"
  { read -r project; read -r worktree; read -r run_parent; } <<<"$fields"

  assert_safe_project "$project" || fail "teardown refused: unsafe Compose project in record"
  [[ "$run_parent" =~ ^/tmp/mailglass-phase178\.[A-Za-z0-9]+$ ]] ||
    fail "teardown refused: run parent '$run_parent' is not a /tmp/mailglass-phase178.* directory created by this launcher"
  [[ "$worktree" == "$run_parent/candidate" ]] ||
    fail "teardown refused: worktree '$worktree' is not <run parent>/candidate"

  local dispositions="" status detail sha
  add_disposition() { dispositions+="$1"$'\t'"$2"$'\t'"$3"$'\n'; printf 'teardown %-22s %-10s %s\n' "$1" "$2" "$3"; }

  sha="$(node -e 'process.stdout.write(JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8")).source_sha || "")' "$record")"

  if [[ -d "$worktree" && "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    if restore_worktree_demo_lock "$worktree" "$sha"; then
      add_disposition demo_mix_lock restored "reference/demo_app/mix.lock equals the blob at ${sha:0:8}"
    else
      add_disposition demo_mix_lock failed "could not restore reference/demo_app/mix.lock"
    fi
  else
    add_disposition demo_mix_lock skipped "worktree already absent"
  fi

  if [[ -f "$worktree/compose.demo.yml" ]]; then
    if docker compose -p "$project" -f "$worktree/compose.demo.yml" down --volumes --remove-orphans >/dev/null 2>&1; then
      add_disposition compose_down stopped "project $project (containers, network, volumes)"
    else
      add_disposition compose_down failed "docker compose -p $project down failed"
    fi
  else
    # Worktree already gone: remove only resources labelled with this exact project.
    local ids
    ids="$(docker ps -aq --filter "label=com.docker.compose.project=$project" 2>/dev/null || true)"
    if [[ -n "$ids" ]]; then
      # shellcheck disable=SC2086
      docker rm -f $ids >/dev/null 2>&1 || true
    fi
    local vols
    vols="$(docker volume ls -q --filter "label=com.docker.compose.project=$project" 2>/dev/null || true)"
    if [[ -n "$vols" ]]; then
      # shellcheck disable=SC2086
      docker volume rm -f $vols >/dev/null 2>&1 || true
    fi
    docker network rm "${project}_default" >/dev/null 2>&1 || true
    add_disposition compose_down label-sweep "worktree absent; removed resources labelled project=$project only"
  fi

  if [[ -d "$worktree" ]]; then
    if git -C "$REPO_ROOT" worktree remove --force "$worktree" >/dev/null 2>&1; then
      add_disposition worktree removed "$worktree"
    else
      add_disposition worktree failed "git worktree remove failed for $worktree"
    fi
  else
    add_disposition worktree absent "$worktree"
  fi
  git -C "$REPO_ROOT" worktree prune >/dev/null 2>&1 || true

  if [[ -d "$run_parent" ]]; then
    rm -rf "$run_parent" && add_disposition run_parent removed "$run_parent" || add_disposition run_parent failed "$run_parent"
  else
    add_disposition run_parent absent "$run_parent"
  fi

  PHASE178_REC_DISPOSITIONS="$dispositions" node -e '
const fs = require("node:fs");
const file = process.argv[1];
const record = JSON.parse(fs.readFileSync(file, "utf8"));
record.teardown = {
  completed_at: new Date().toISOString(),
  dispositions: (process.env.PHASE178_REC_DISPOSITIONS || "").split("\n").filter(Boolean).map((line) => {
    const [name, status, detail] = line.split("\t");
    return { name, status, detail };
  })
};
fs.writeFileSync(file, JSON.stringify(record, null, 2) + "\n");
' "$record"
  if printf '%s' "$dispositions" | awk -F'\t' '$2=="failed"{bad=1} END{exit bad?0:1}'; then
    fail "teardown finished with failed dispositions; see $record"
  fi
  printf 'phase178 candidate teardown complete: %s\n' "$record"
}

# ---------------------------------------------------------------------------
# Library mode: define everything above, run nothing.
# ---------------------------------------------------------------------------
if [[ "${PHASE178_CANDIDATE_LIB_ONLY:-}" == "1" ]]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
SHA=""
RECORD_PATH=""
TEARDOWN_RECORD=""
REQUIRE_CI=false
declare -a ROUTES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sha) [[ $# -ge 2 ]] || fail "--sha needs a value"; SHA="$2"; shift 2 ;;
    --sha=*) SHA="${1#--sha=}"; shift ;;
    --route) [[ $# -ge 2 ]] || fail "--route needs a value"; ROUTES+=("$2"); shift 2 ;;
    --route=*) ROUTES+=("${1#--route=}"); shift ;;
    --record) [[ $# -ge 2 ]] || fail "--record needs a value"; RECORD_PATH="$2"; shift 2 ;;
    --record=*) RECORD_PATH="${1#--record=}"; shift ;;
    --require-ci) REQUIRE_CI=true; shift ;;
    --teardown) [[ $# -ge 2 ]] || fail "--teardown needs a record path"; TEARDOWN_RECORD="$2"; shift 2 ;;
    --teardown=*) TEARDOWN_RECORD="${1#--teardown=}"; shift ;;
    *) fail "unknown option: $1" ;;
  esac
done

if [[ -n "$TEARDOWN_RECORD" ]]; then
  do_teardown "$TEARDOWN_RECORD"
  exit 0
fi

[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || fail "--sha must be a full 40-character lowercase hex commit SHA"
cd "$REPO_ROOT"
git cat-file -e "$SHA^{commit}" 2>/dev/null || fail "commit $SHA does not exist in this repository"
if [[ ${#ROUTES[@]} -eq 0 ]]; then ROUTES=("${DEFAULT_ROUTES[@]}"); fi

command -v docker >/dev/null 2>&1 || fail "Docker CLI is unavailable"
docker info >/dev/null 2>&1 || fail "Docker daemon is not running"
for tool in curl node python3; do command -v "$tool" >/dev/null 2>&1 || fail "$tool is required"; done
if [[ "$REQUIRE_CI" == true ]]; then command -v gh >/dev/null 2>&1 || fail "--require-ci needs the gh CLI"; fi

# ---------------------------------------------------------------------------
# Detached worktree at exactly the SHA
# ---------------------------------------------------------------------------
RUN_PARENT="$(mktemp -d /tmp/mailglass-phase178.XXXXXXXX)"
WORKTREE="$RUN_PARENT/candidate"
COMPOSE_STARTED=false
PROJECT=""
HTTP_PORT=""
DB_PORT=""
BASE_URL=""
declare -a FAILURES=()

cleanup_before_compose() {
  if [[ "$COMPOSE_STARTED" == false && -n "${RUN_PARENT:-}" && -d "$RUN_PARENT" ]]; then
    git -C "$REPO_ROOT" worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" worktree prune >/dev/null 2>&1 || true
    rm -rf "$RUN_PARENT"
  fi
}
on_exit() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    cleanup_before_compose
    if [[ "$COMPOSE_STARTED" == true && -n "${RECORD_PATH:-}" ]]; then
      printf 'phase178 candidate: run incomplete. Tear down with:\n  bash scripts/check_phase178_candidate.sh --teardown %q\n' "$RECORD_PATH" >&2
    fi
  fi
}
trap on_exit EXIT

git worktree add --detach "$WORKTREE" "$SHA" >/dev/null 2>&1 || fail "could not create detached worktree at $SHA"
[[ "$(git -C "$WORKTREE" rev-parse HEAD)" == "$SHA" ]] || fail "worktree HEAD differs from requested SHA"
[[ -z "$(git -C "$WORKTREE" status --porcelain --untracked-files=all)" ]] || fail "new candidate worktree is not clean"
[[ -f "$WORKTREE/compose.demo.yml" ]] || fail "candidate $SHA has no compose.demo.yml"

if ! read -r HTTP_PORT DB_PORT < <(allocate_ports); then fail "could not allocate review ports"; fi
RUN_SUFFIX="$(date -u +%Y%m%d%H%M%S)-$$"
PROJECT="${PROJECT_PREFIX}${SHA:0:8}-${RUN_SUFFIX}"
assert_safe_project "$PROJECT" || fail "generated an unsafe Compose project name"
BASE_URL="http://127.0.0.1:$HTTP_PORT"

if [[ -z "$RECORD_PATH" ]]; then RECORD_PATH="$REPO_ROOT/$RECORD_DIR_REL/$PROJECT.json"; fi
mkdir -p "$(dirname "$RECORD_PATH")"

TEARDOWN_CMD="bash scripts/check_phase178_candidate.sh --teardown $RECORD_PATH"

compose() {
  MAILGLASS_DEMO_HTTP_PORT="$HTTP_PORT" MAILGLASS_DEMO_DB_PORT="$DB_PORT" \
    docker compose -p "$PROJECT" -f "$WORKTREE/compose.demo.yml" "$@"
}

ROUTE_ROWS=""
SERVED_CSS_PATH=""
SOURCE_CSS_SHA=""
BUILT_CSS_SHA=""
SERVED_CSS_SHA=""
CI_STATUS="not_checked"
CI_CONTEXTS_JSON=""
FINAL_STATUS="fail"

note "project $PROJECT, ports http=$HTTP_PORT db=$DB_PORT, worktree $WORKTREE"
COMPOSE_STARTED=true
# Write a provisional record first so --teardown works even if the launch dies.
PHASE178_REC_SHA="$SHA" PHASE178_REC_WORKTREE="$WORKTREE" PHASE178_REC_RUN_PARENT="$RUN_PARENT" \
  PHASE178_REC_PROJECT="$PROJECT" PHASE178_REC_BASE_URL="$BASE_URL" PHASE178_REC_HTTP_PORT="$HTTP_PORT" \
  PHASE178_REC_DB_PORT="$DB_PORT" PHASE178_REC_FINAL_STATUS="fail" PHASE178_REC_CI_STATUS="$CI_STATUS" \
  PHASE178_REC_FAILURES="launch in progress" PHASE178_REC_TEARDOWN="$TEARDOWN_CMD" \
  PHASE178_REC_RETAINED="$PROJECT (demo + demo_db) at $BASE_URL" \
  write_record "$RECORD_PATH"

PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-phase178-probe.XXXXXX")"
launch_ok=false
if compose up --build --detach --wait --wait-timeout 600 demo; then
  launch_ok=true
  restore_worktree_demo_lock "$WORKTREE" "$SHA" || FAILURES+=("could not restore the worktree demo mix.lock")
  if [[ -n "$(git -C "$WORKTREE" status --porcelain --untracked-files=no)" ]]; then
    FAILURES+=("candidate worktree has tracked changes after launch")
  fi
else
  FAILURES+=("isolated review Compose project did not become healthy")
fi

if [[ "$launch_ok" == true ]]; then
  for route in "${ROUTES[@]}"; do
    status="000"; final_url=""
    for attempt in 1 2 3; do
      out="$(curl --silent --show-error --globoff --location --output "$PROBE_DIR/route.body" \
        --write-out '%{http_code} %{url_effective}' --max-time 30 "$BASE_URL$route" 2>/dev/null || true)"
      status="${out%% *}"; final_url="${out#* }"
      [[ "$status" == 200 ]] && break
      sleep 5
    done
    ROUTE_ROWS+="$route"$'\t'"$status"$'\t'"$final_url"$'\n'
    [[ "$status" == 200 ]] || FAILURES+=("HTTP route $route returned ${status:-no-response}")
  done

  if curl --silent --show-error --globoff --location --fail --output "$PROBE_DIR/preview.html" --max-time 30 "$BASE_URL/dev/mail"; then
    if SERVED_CSS_PATH="$(extract_css_href "$PROBE_DIR/preview.html")"; then
      if curl --silent --show-error --globoff --location --fail --output "$PROBE_DIR/served.css" --max-time 30 "$BASE_URL$SERVED_CSS_PATH"; then
        css_line="$(css_triple "$WORKTREE/mailglass_admin/assets/css/app.css" "$WORKTREE/mailglass_admin/priv/static/app.css" "$PROBE_DIR/served.css" || true)"
        read -r css_verdict SOURCE_CSS_SHA BUILT_CSS_SHA SERVED_CSS_SHA <<<"$css_line"
        [[ "$css_verdict" == match ]] || FAILURES+=("served Admin CSS bytes differ from the candidate bundle")
      else
        FAILURES+=("versioned Admin CSS route could not be fetched")
      fi
    else
      SERVED_CSS_PATH=""
      FAILURES+=("/dev/mail has no versioned mount-rooted Admin CSS link")
    fi
  else
    FAILURES+=("/dev/mail HTML could not be fetched for CSS identity")
  fi
fi
rm -rf "$PROBE_DIR"

# Read-only exact-SHA GitHub lookup (no write verbs are used anywhere here).
if [[ "$REQUIRE_CI" == true ]]; then
  CHECK_RUNS_FILE="$(mktemp "${TMPDIR:-/tmp}/mailglass-phase178-ci.XXXXXX")"
  if gh api "repos/$GITHUB_REPO/commits/$SHA/check-runs?per_page=100" --paginate >"$CHECK_RUNS_FILE" 2>/dev/null; then
    if CI_CONTEXTS_JSON="$(ci_contexts_status "$CHECK_RUNS_FILE" 2>/dev/null)"; then
      CI_STATUS="pass"
    else
      CI_STATUS="fail"
      FAILURES+=("required CI contexts are not green for the exact candidate SHA")
    fi
    CI_CONTEXTS_JSON="$(printf '%s' "$CI_CONTEXTS_JSON" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.stringify(JSON.parse(s).contexts))}catch{}})')"
  else
    CI_STATUS="unavailable"
    FAILURES+=("GitHub check-run read access is unavailable")
  fi
  rm -f "$CHECK_RUNS_FILE"
fi

if [[ ${#FAILURES[@]} -eq 0 && "$launch_ok" == true ]]; then
  FINAL_STATUS="pass"
fi
if [[ "$REQUIRE_CI" == true && "$CI_STATUS" != pass ]]; then FINAL_STATUS="fail"; fi

FAILURE_TEXT=""
if [[ ${#FAILURES[@]} -gt 0 ]]; then FAILURE_TEXT="$(printf '%s\n' "${FAILURES[@]}")"; fi
PHASE178_REC_SHA="$SHA" PHASE178_REC_WORKTREE="$WORKTREE" PHASE178_REC_RUN_PARENT="$RUN_PARENT" \
  PHASE178_REC_PROJECT="$PROJECT" PHASE178_REC_BASE_URL="$BASE_URL" PHASE178_REC_HTTP_PORT="$HTTP_PORT" \
  PHASE178_REC_DB_PORT="$DB_PORT" PHASE178_REC_ROUTES="$ROUTE_ROWS" PHASE178_REC_SERVED_CSS_PATH="$SERVED_CSS_PATH" \
  PHASE178_REC_SOURCE_CSS="$SOURCE_CSS_SHA" PHASE178_REC_BUILT_CSS="$BUILT_CSS_SHA" PHASE178_REC_SERVED_CSS="$SERVED_CSS_SHA" \
  PHASE178_REC_CI_STATUS="$CI_STATUS" PHASE178_REC_CI_CONTEXTS="$CI_CONTEXTS_JSON" PHASE178_REC_FINAL_STATUS="$FINAL_STATUS" \
  PHASE178_REC_FAILURES="$FAILURE_TEXT" PHASE178_REC_TEARDOWN="$TEARDOWN_CMD" \
  PHASE178_REC_RETAINED="$PROJECT (demo + demo_db) at $BASE_URL" \
  write_record "$RECORD_PATH"

printf 'phase178 candidate record: %s\n' "$RECORD_PATH"
printf 'phase178 candidate final_status=%s source_sha=%s base_url=%s\n' "$FINAL_STATUS" "$SHA" "$BASE_URL"
printf 'phase178 candidate retained services (leave running for review, then tear down):\n  %s\n' "$TEARDOWN_CMD"
for failure in ${FAILURES[@]+"${FAILURES[@]}"}; do printf 'phase178 candidate failure: %s\n' "$failure" >&2; done

[[ "$FINAL_STATUS" == pass ]] || exit 1
