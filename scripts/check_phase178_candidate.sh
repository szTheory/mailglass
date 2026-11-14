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
  "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar"
  "/dev/mail"
  "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin"
  "/dev/storybook/preview_authoring"
  "/dev/storybook/preview_chrome"
  "/dev/storybook/primitives/stat_card"
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
  match="$(grep -oE "href=[\"']/dev/mail/css-[a-f0-9]{32}[\"']" "$file" | head -n 1 || true)"
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

# same_origin_redirect <current URL> <Location>
# Prints a resolved redirect URL only when its scheme, hostname and port match
# the candidate origin. Reject malformed URLs and URL credentials.
same_origin_redirect() {
  python3 - "$1" "$2" <<'PY'
import sys
from urllib.parse import urljoin, urlsplit

current, location = sys.argv[1:]
try:
    source = urlsplit(current)
    target = urlsplit(urljoin(current, location))
    source_port = source.port or (443 if source.scheme.lower() == "https" else 80)
    target_port = target.port or (443 if target.scheme.lower() == "https" else 80)
    valid = (
        source.scheme.lower() == target.scheme.lower()
        and (source.hostname or "").lower() == (target.hostname or "").lower()
        and source_port == target_port
        and target.username is None
        and target.password is None
        and target.scheme.lower() in ("http", "https")
    )
except ValueError:
    valid = False
if not valid:
    raise SystemExit(1)
print(target.geturl())
PY
}

# resolve_candidate_route <base URL> <route>
# Accepts one root-relative path only, then resolves it through the same origin
# check used for redirect targets before any request can be made.
resolve_candidate_route() {
  local base_url="$1" route="$2"
  python3 - "$route" <<'PY' || return 1
import sys
import unicodedata
from urllib.parse import urlsplit

route = sys.argv[1]
if not route.startswith("/") or route.startswith("//") or "\\" in route:
    raise SystemExit(1)
if any(unicodedata.category(char) == "Cc" for char in route):
    raise SystemExit(1)
try:
    parts = urlsplit(route)
except ValueError:
    raise SystemExit(1)
if parts.scheme or parts.netloc or parts.username is not None or parts.password is not None:
    raise SystemExit(1)
PY
  same_origin_redirect "$base_url" "$route"
}

# probe_route <private probe directory> <cookie jar> <base URL> <route>
# Prints "<final HTTP status> <effective URL>". Redirects are resolved one at
# a time and rejected before another request unless they stay on the exact
# candidate origin. Every route shares the short-lived synthetic cookie jar.
probe_route() {
  local probe_dir="$1" cookie_jar="$2" base_url="$3" route="$4"
  local response_file="${5:-$1/route.body}"
  local status="000" final_url="" out attempt current_url initial_url location next_url hop
  [[ "$response_file" == "$probe_dir/"* ]] || return 1
  if ! initial_url="$(resolve_candidate_route "$base_url" "$route")"; then
    note "rejected unsafe candidate route before request"
    printf 'route_rejected %s\n' "$base_url"
    return 0
  fi
  for attempt in 1 2 3; do
    current_url="$initial_url"
    for hop in 0 1 2 3 4 5 6 7 8 9 10; do
      : >"$probe_dir/route.headers"
      out="$(curl --silent --show-error --globoff --max-redirs 0 \
        --cookie "$cookie_jar" --cookie-jar "$cookie_jar" \
        --dump-header "$probe_dir/route.headers" --output "$response_file" \
        --write-out '%{http_code} %{url_effective}' --max-time 30 "$current_url" 2>/dev/null || true)"
      status="${out%% *}"
      final_url="${out#* }"
      [[ -n "$status" && "$status" != "$out" ]] || { status="000"; final_url="$current_url"; break; }

      if [[ "$status" =~ ^30[12378]$ ]]; then
        location="$(awk '
          /^HTTP\// { count = 0; value = ""; next }
          tolower($1) == "location:" {
            count += 1
            sub(/^[^:]*:[[:space:]]*/, "")
            sub(/\r$/, "")
            value = $0
          }
          END { if (count == 1) print value; else if (count > 1) exit 2 }
        ' "$probe_dir/route.headers" 2>/dev/null)" || {
          status="redirect_rejected"
          final_url="$current_url"
          break 2
        }
        if [[ -z "$location" ]] || ! next_url="$(same_origin_redirect "$current_url" "$location")"; then
          note "rejected redirect from $current_url to ${location:-<missing Location>} (outside the candidate origin)"
          status="redirect_rejected"
          final_url="$current_url"
          break 2
        fi
        current_url="$next_url"
        if [[ "$hop" -eq 10 ]]; then
          status="redirect_limit"
          final_url="$current_url"
          break 2
        fi
        continue
      fi

      final_url="$current_url"
      break
    done
    [[ "$status" == "redirect_rejected" || "$status" == "redirect_limit" ]] && break
    [[ "$status" == 200 ]] && break
    sleep 5
  done
  printf '%s %s\n' "$status" "$final_url"
}

# add_candidate_worktree <path> <sha>
# Keeps Git's failure diagnostic visible so launch stops are actionable.
add_candidate_worktree() {
  local worktree_path="$1" sha="$2" output
  if ! output="$(git worktree add --detach "$worktree_path" "$sha" 2>&1)"; then
    fail "could not create detached worktree at $sha: ${output:-git worktree add failed without a diagnostic}"
  fi
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
# Ownership marker and record writing (whitelisted variables only; no env dump)
# ---------------------------------------------------------------------------

write_ownership_marker() {
  local marker="$1"
  read -r -d '' js <<'NODE' || true
const fs = require("node:fs");
const env = process.env;
const marker = {
  schema_version: "phase178-owner.v1",
  compose_project: env.PHASE178_OWNER_PROJECT,
  source_sha: env.PHASE178_OWNER_SHA,
  run_id: env.PHASE178_OWNER_RUN_ID,
  run_parent: env.PHASE178_OWNER_RUN_PARENT,
  worktree: env.PHASE178_OWNER_WORKTREE
};
if (!marker.compose_project || !marker.source_sha || !marker.run_id || !marker.run_parent || !marker.worktree) {
  throw new Error("incomplete Phase 178 ownership binding");
}
fs.writeFileSync(process.argv[1], JSON.stringify(marker, null, 2) + "\n", { flag: "wx", mode: 0o600 });
fs.chmodSync(process.argv[1], 0o600);
NODE
  node -e "$js" "$marker"
}

# verify_owner_binding <record> <marker>
# The record is user-editable evidence, so its cleanup identity is accepted
# only when every identity field agrees with the private run marker.
verify_owner_binding() {
  node - "$1" "$2" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const [recordPath, markerPath] = process.argv.slice(2);
try {
  const record = JSON.parse(fs.readFileSync(recordPath, "utf8"));
  const markerStat = fs.lstatSync(markerPath);
  const runParent = record.run_parent;
  if (!runParent || !/^\/tmp\/mailglass-phase178\.[A-Za-z0-9]+$/.test(runParent)) throw new Error("invalid run parent");
  if (path.resolve(runParent) !== runParent) throw new Error("run parent is not canonical");
  if (record.ownership_marker !== path.join(runParent, ".phase178-owner.json")) throw new Error("ownership marker path does not match the run parent");
  if (markerPath !== path.join(runParent, ".phase178-owner.json")) throw new Error("unexpected ownership marker path");
  if (record.schema_version !== "phase178-candidate.v1") throw new Error("unsupported candidate record schema");
  if (record.worktree !== path.join(runParent, "candidate")) throw new Error("worktree path does not match the run parent");
  if (!/^[0-9a-f]{40}$/.test(record.source_sha || "")) throw new Error("invalid source SHA");
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(record.run_id || "")) throw new Error("invalid run identifier");
  if (!markerStat.isFile() || markerStat.uid !== process.getuid() || (markerStat.mode & 0o777) !== 0o600) throw new Error("ownership marker must be a private regular file");
  const parentStat = fs.lstatSync(runParent);
  if (!parentStat.isDirectory() || parentStat.uid !== process.getuid() || (parentStat.mode & 0o777) !== 0o700) throw new Error("run parent must be a private directory");
  try {
    const worktreeStat = fs.lstatSync(record.worktree);
    if (!worktreeStat.isDirectory()) throw new Error("candidate worktree is not a real directory");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  const marker = JSON.parse(fs.readFileSync(markerPath, "utf8"));
  if (marker.schema_version !== "phase178-owner.v1") throw new Error("unsupported ownership marker schema");
  for (const field of ["compose_project", "source_sha", "run_id", "run_parent", "worktree"]) {
    if (!record[field] || record[field] !== marker[field]) throw new Error(`${field} does not match the ownership marker`);
  }
  if (!/^mailglass-phase178-review-[A-Za-z0-9][A-Za-z0-9._-]*$/.test(marker.compose_project)) throw new Error("unsafe Compose project");
  if (marker.source_sha !== record.source_sha || marker.run_parent !== runParent || marker.worktree !== record.worktree) throw new Error("ownership binding is inconsistent");
  process.exit(0);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
NODE
}

verify_owner_marker() {
  node - "$1" "$2" "$3" "$4" "$5" "$6" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const [markerPath, project, sha, runId, runParent, worktree] = process.argv.slice(2);
try {
  const stat = fs.lstatSync(markerPath);
  const parent = fs.lstatSync(runParent);
  const marker = JSON.parse(fs.readFileSync(markerPath, "utf8"));
  if (!stat.isFile() || stat.uid !== process.getuid() || (stat.mode & 0o777) !== 0o600) throw new Error("ownership marker is not private");
  if (!parent.isDirectory() || parent.uid !== process.getuid() || (parent.mode & 0o777) !== 0o700) throw new Error("run parent is not private");
  try {
    const worktreeStat = fs.lstatSync(worktree);
    if (!worktreeStat.isDirectory()) throw new Error("candidate worktree is not a real directory");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  if (marker.schema_version !== "phase178-owner.v1" || marker.compose_project !== project || marker.source_sha !== sha || marker.run_id !== runId || marker.run_parent !== runParent || marker.worktree !== worktree) throw new Error("ownership marker does not match this run");
  if (markerPath !== path.join(runParent, ".phase178-owner.json")) throw new Error("ownership marker path is inconsistent");
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
NODE
}

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
  run_id: env.PHASE178_REC_RUN_ID,
  worktree: env.PHASE178_REC_WORKTREE,
  run_parent: env.PHASE178_REC_RUN_PARENT,
  ownership_marker: env.PHASE178_REC_OWNERSHIP_MARKER,
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
  local record="$1" project worktree run_parent sha run_id marker fields
  [[ -f "$record" ]] || fail "teardown record not found: $record"
  run_parent="$(node -e '
const r = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
if (!/^\/tmp\/mailglass-phase178\.[A-Za-z0-9]+$/.test(r.run_parent || "")) process.exit(1);
process.stdout.write(r.run_parent);
' "$record")" || fail "teardown refused: record has an invalid or missing run parent"
  marker="$run_parent/.phase178-owner.json"
  verify_owner_binding "$record" "$marker" || fail "teardown refused: record does not match the private ownership marker"
  fields="$(node -e '
const r = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
process.stdout.write([r.compose_project, r.worktree, r.run_parent, r.source_sha, r.run_id].join("\n") + "\n");
' "$record")" || fail "teardown record is not readable JSON: $record"
  { read -r project; read -r worktree; read -r run_parent; read -r sha; read -r run_id; } <<<"$fields"

  assert_safe_project "$project" || fail "teardown refused: unsafe Compose project in record"

  local dispositions="" docker_commands_ok=true docker_verified=true cleanup_ok=true
  add_disposition() { dispositions+="$1"$'\t'"$2"$'\t'"$3"$'\n'; printf 'teardown %-22s %-10s %s\n' "$1" "$2" "$3"; }
  local_resource_list() {
    case "$1" in
      containers) docker ps -aq --filter "label=com.docker.compose.project=$project" ;;
      volumes) docker volume ls -q --filter "label=com.docker.compose.project=$project" ;;
      networks) docker network ls -q --filter "label=com.docker.compose.project=$project" ;;
      *) return 2 ;;
    esac
  }
  remove_local_resource() {
    case "$1" in
      containers) docker rm -f "$2" ;;
      volumes) docker volume rm -f "$2" ;;
      networks) docker network rm "$2" ;;
      *) return 2 ;;
    esac
  }

  if [[ -d "$worktree" && "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    if restore_worktree_demo_lock "$worktree" "$sha"; then
      add_disposition demo_mix_lock restored "reference/demo_app/mix.lock equals the blob at ${sha:0:8}"
    else
      add_disposition demo_mix_lock failed "could not restore reference/demo_app/mix.lock"
      cleanup_ok=false
    fi
  else
    add_disposition demo_mix_lock skipped "worktree already absent"
  fi

  if [[ -f "$worktree/compose.demo.yml" ]]; then
    if docker compose -p "$project" -f "$worktree/compose.demo.yml" down --volumes --remove-orphans >/dev/null 2>&1; then
      add_disposition compose_down stopped "project $project (containers, network, volumes)"
    else
      add_disposition compose_down failed "docker compose -p $project down failed"
      docker_commands_ok=false
    fi
  else
    add_disposition compose_down label_sweep "Compose file unavailable; sweeping resources labelled project=$project only"
  fi

  # Sweep by exact Compose project label even after `compose down`, then query
  # all three resource classes again. A command error is a failed cleanup even
  # if a later query happens to show no resources.
  local kind items item query_failed
  for kind in containers volumes networks; do
    if ! items="$(local_resource_list "$kind" 2>/dev/null)"; then
      add_disposition "${kind}_sweep" failed "could not list project-labeled $kind"
      docker_commands_ok=false
      continue
    fi
    query_failed=false
    while IFS= read -r item; do
      [[ -n "$item" ]] || continue
      if ! remove_local_resource "$kind" "$item" >/dev/null 2>&1; then
        add_disposition "${kind}_remove" failed "could not remove project-labeled $kind resource $item"
        docker_commands_ok=false
        query_failed=true
      fi
    done <<<"$items"
    [[ "$query_failed" == true ]] || add_disposition "${kind}_sweep" removed "removed project-labeled $kind"
  done

  for kind in containers volumes networks; do
    if ! items="$(local_resource_list "$kind" 2>/dev/null)"; then
      add_disposition "${kind}_verification" failed "could not verify project-labeled $kind are absent"
      docker_verified=false
      continue
    fi
    if [[ -n "$items" ]]; then
      add_disposition "${kind}_verification" failed "project-labeled $kind remain: ${items//$'\n'/, }"
      docker_verified=false
    else
      add_disposition "${kind}_verification" verified "no project-labeled $kind remain"
    fi
  done
  [[ "$docker_commands_ok" == true ]] || docker_verified=false
  if [[ "$docker_verified" != true ]]; then cleanup_ok=false; fi

  if [[ "$cleanup_ok" == true && -d "$worktree" ]]; then
    if git -C "$REPO_ROOT" worktree remove --force "$worktree" >/dev/null 2>&1; then
      add_disposition worktree removed "$worktree"
    else
      add_disposition worktree failed "git worktree remove failed for $worktree"
      cleanup_ok=false
    fi
  elif [[ -d "$worktree" ]]; then
    add_disposition worktree retained "cleanup was not verified; retained $worktree for recovery"
  else
    add_disposition worktree absent "$worktree"
  fi

  if [[ "$cleanup_ok" != true ]]; then
    add_disposition run_parent retained "cleanup was not verified; recovery marker and configuration retained at $run_parent"
  elif [[ -d "$run_parent" ]]; then
    add_disposition run_parent removing "Docker resources and candidate worktree verified clean"
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

  if [[ "$cleanup_ok" != true ]]; then
    fail "teardown could not verify complete cleanup; retained recovery files at $run_parent and updated $record"
  fi
  if [[ -d "$run_parent" ]]; then
    if rm -rf "$run_parent"; then
      dispositions+="run_parent"$'\t'"removed"$'\t'"$run_parent"$'\n'
      PHASE178_REC_DISPOSITIONS="$dispositions" node -e '
const fs = require("node:fs");
const file = process.argv[1];
const record = JSON.parse(fs.readFileSync(file, "utf8"));
record.teardown.dispositions = (process.env.PHASE178_REC_DISPOSITIONS || "").split("\n").filter(Boolean).map((line) => {
  const [name, status, detail] = line.split("\t");
  return { name, status, detail };
});
fs.writeFileSync(file, JSON.stringify(record, null, 2) + "\n");
' "$record"
    else
      dispositions+="run_parent"$'\t'"failed"$'\t'"could not remove $run_parent"$'\n'
      PHASE178_REC_DISPOSITIONS="$dispositions" node -e '
const fs = require("node:fs");
const file = process.argv[1];
const record = JSON.parse(fs.readFileSync(file, "utf8"));
record.teardown.dispositions = (process.env.PHASE178_REC_DISPOSITIONS || "").split("\n").filter(Boolean).map((line) => {
  const [name, status, detail] = line.split("\t");
  return { name, status, detail };
});
fs.writeFileSync(file, JSON.stringify(record, null, 2) + "\n");
' "$record"
      fail "teardown could not remove verified-clean run directory $run_parent; see $record"
    fi
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
if ! read -r HTTP_PORT DB_PORT < <(allocate_ports); then fail "could not allocate review ports"; fi
RUN_ID="$(date -u +%Y%m%d%H%M%S)-$$"
PROJECT="${PROJECT_PREFIX}${SHA:0:8}-${RUN_ID}"
assert_safe_project "$PROJECT" || fail "generated an unsafe Compose project name"
BASE_URL="http://127.0.0.1:$HTTP_PORT"
RUN_PARENT="$(mktemp -d /tmp/mailglass-phase178.XXXXXXXX)"
WORKTREE="$RUN_PARENT/candidate"
OWNERSHIP_MARKER="$RUN_PARENT/.phase178-owner.json"
COMPOSE_STARTED=false
if [[ -z "$RECORD_PATH" ]]; then RECORD_PATH="$REPO_ROOT/$RECORD_DIR_REL/$PROJECT.json"; fi
TEARDOWN_CMD="bash scripts/check_phase178_candidate.sh --teardown $RECORD_PATH"
declare -a FAILURES=()

cleanup_before_compose() {
  if [[ "$COMPOSE_STARTED" == false && -n "${RUN_PARENT:-}" && -d "$RUN_PARENT" ]]; then
    if ! verify_owner_marker "$OWNERSHIP_MARKER" "$PROJECT" "$SHA" "$RUN_ID" "$RUN_PARENT" "$WORKTREE" >/dev/null 2>&1; then
      note "pre-Compose cleanup refused: ownership marker is missing or inconsistent; recovery directory retained at $RUN_PARENT"
      return
    fi
    if [[ -d "$WORKTREE" ]] && ! git -C "$REPO_ROOT" worktree remove --force "$WORKTREE" >/dev/null 2>&1; then
      note "pre-Compose cleanup could not remove candidate worktree; recovery directory retained at $RUN_PARENT"
      return
    fi
    if ! rm -rf "$RUN_PARENT"; then
      note "pre-Compose cleanup could not remove run directory; retained at $RUN_PARENT"
    fi
  fi
}
on_exit() {
  local rc=$?
  if [[ -n "${PROBE_DIR:-}" && -d "$PROBE_DIR" ]]; then rm -rf "$PROBE_DIR"; fi
  if [[ $rc -ne 0 ]]; then
    cleanup_before_compose
    if [[ "$COMPOSE_STARTED" == true && -n "${RECORD_PATH:-}" ]]; then
      printf 'phase178 candidate: run incomplete. Tear down with:\n  bash scripts/check_phase178_candidate.sh --teardown %q\n' "$RECORD_PATH" >&2
    fi
  fi
}
trap on_exit EXIT

PHASE178_OWNER_PROJECT="$PROJECT" PHASE178_OWNER_SHA="$SHA" PHASE178_OWNER_RUN_ID="$RUN_ID" \
  PHASE178_OWNER_RUN_PARENT="$RUN_PARENT" PHASE178_OWNER_WORKTREE="$WORKTREE" \
  write_ownership_marker "$OWNERSHIP_MARKER"

add_candidate_worktree "$WORKTREE" "$SHA"
[[ "$(git -C "$WORKTREE" rev-parse HEAD)" == "$SHA" ]] || fail "worktree HEAD differs from requested SHA"
[[ -z "$(git -C "$WORKTREE" status --porcelain --untracked-files=all)" ]] || fail "new candidate worktree is not clean"
[[ -f "$WORKTREE/compose.demo.yml" ]] || fail "candidate $SHA has no compose.demo.yml"

mkdir -p "$(dirname "$RECORD_PATH")"

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
# Write a provisional record first so --teardown works even if the launch dies.
PHASE178_REC_SHA="$SHA" PHASE178_REC_RUN_ID="$RUN_ID" PHASE178_REC_OWNERSHIP_MARKER="$OWNERSHIP_MARKER" \
  PHASE178_REC_WORKTREE="$WORKTREE" PHASE178_REC_RUN_PARENT="$RUN_PARENT" \
  PHASE178_REC_PROJECT="$PROJECT" PHASE178_REC_BASE_URL="$BASE_URL" PHASE178_REC_HTTP_PORT="$HTTP_PORT" \
  PHASE178_REC_DB_PORT="$DB_PORT" PHASE178_REC_FINAL_STATUS="fail" PHASE178_REC_CI_STATUS="$CI_STATUS" \
  PHASE178_REC_FAILURES="launch in progress" PHASE178_REC_TEARDOWN="$TEARDOWN_CMD" \
  PHASE178_REC_RETAINED="$PROJECT (demo + demo_db) at $BASE_URL" \
  write_record "$RECORD_PATH"
COMPOSE_STARTED=true

PROBE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-phase178-probe.XXXXXX")"
chmod 700 "$PROBE_DIR"
COOKIE_JAR="$PROBE_DIR/cookies.txt"
(umask 077; : >"$COOKIE_JAR")
chmod 600 "$COOKIE_JAR"
launch_ok=false
if compose up --build --detach --wait --wait-timeout 600 demo; then
  launch_ok=true
  restore_worktree_demo_lock "$WORKTREE" "$SHA" || FAILURES+=("could not restore the worktree demo mix.lock")
  if [[ -n "$(git -C "$WORKTREE" status --porcelain --untracked-files=no)" ]]; then
    FAILURES+=("candidate worktree has tracked changes after launch")
  fi
else
  FAILURES+=("isolated review Compose project did not become healthy")
  # Keep the demo container's own output next to the record: the cause is in
  # its log, and --teardown removes the container afterwards.
  COMPOSE_LOG="${RECORD_PATH%.json}.compose.log"
  compose logs --no-color --tail 120 demo >"$COMPOSE_LOG" 2>&1 || true
  FAILURES+=("demo container log saved to $COMPOSE_LOG")
  tail -n 25 "$COMPOSE_LOG" >&2 || true
fi

if [[ "$launch_ok" == true ]]; then
  for route in "${ROUTES[@]}"; do
    read -r status final_url < <(probe_route "$PROBE_DIR" "$COOKIE_JAR" "$BASE_URL" "$route")
    ROUTE_ROWS+="$route"$'\t'"$status"$'\t'"$final_url"$'\n'
    [[ "$status" == 200 ]] || FAILURES+=("HTTP route $route returned ${status:-no-response}")
  done

  html_probe="$(probe_route "$PROBE_DIR" "$COOKIE_JAR" "$BASE_URL" "/dev/mail" "$PROBE_DIR/preview.html")"
  read -r html_status _ <<<"$html_probe"
  if [[ "$html_status" == 200 ]]; then
    if SERVED_CSS_PATH="$(extract_css_href "$PROBE_DIR/preview.html")" &&
      [[ "$SERVED_CSS_PATH" =~ ^/dev/mail/css-[a-f0-9]{32}$ ]]; then
      css_probe="$(probe_route "$PROBE_DIR" "$COOKIE_JAR" "$BASE_URL" "$SERVED_CSS_PATH" "$PROBE_DIR/served.css")"
      read -r css_status _ <<<"$css_probe"
      if [[ "$css_status" == 200 ]]; then
        css_line="$(css_triple "$WORKTREE/mailglass_admin/assets/css/app.css" "$WORKTREE/mailglass_admin/priv/static/app.css" "$PROBE_DIR/served.css" || true)"
        read -r css_verdict SOURCE_CSS_SHA BUILT_CSS_SHA SERVED_CSS_SHA <<<"$css_line"
        [[ "$css_verdict" == match ]] || FAILURES+=("served Admin CSS bytes differ from the candidate bundle")
      else
        FAILURES+=("versioned Admin CSS route could not be fetched: ${css_status:-no-response}")
      fi
    else
      SERVED_CSS_PATH=""
      FAILURES+=("/dev/mail has no root-relative versioned Admin CSS link")
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
PHASE178_REC_SHA="$SHA" PHASE178_REC_RUN_ID="$RUN_ID" PHASE178_REC_OWNERSHIP_MARKER="$OWNERSHIP_MARKER" \
  PHASE178_REC_WORKTREE="$WORKTREE" PHASE178_REC_RUN_PARENT="$RUN_PARENT" \
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
