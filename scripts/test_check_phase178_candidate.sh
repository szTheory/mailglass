#!/usr/bin/env bash
# Offline self-test for scripts/check_phase178_candidate.sh (Phase 178, UIQ-08).
# No Docker daemon, no network, no GitHub: docker and gh are stubbed on PATH and
# record every invocation, so refusals can be proven to happen before any call.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT_DIR/scripts/check_phase178_candidate.sh"
COST_TOOL="$ROOT_DIR/scripts/phase178_cost_disposition.cjs"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/phase178-candidate-selftest.XXXXXX")"
STUB_BIN="$TEST_DIR/bin"
STUB_LOG="$TEST_DIR/stub-calls.log"
CURL_LOG="$TEST_DIR/curl-calls.log"
PASSED=0
declare -a TEST_RECOVERY_DIRS=()

cleanup() {
  local dir name
  for dir in "${TEST_RECOVERY_DIRS[@]}"; do
    case "$dir" in
      /tmp/mailglass-phase178.*|/private/tmp/mailglass-phase178.*)
        name="${dir##*/}"
        if [[ "$name" =~ ^mailglass-phase178\.[A-Za-z0-9]+$ && -d "$dir" && ! -L "$dir" ]]; then
          rm -rf "$dir"
        fi
        ;;
    esac
  done
  [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}
trap cleanup EXIT

die() {
  printf 'FAIL %s\n' "$*" >&2
  exit 1
}

ok() {
  PASSED=$((PASSED + 1))
  printf 'ok %s\n' "$1"
}

mkdir -p "$STUB_BIN"
: >"$STUB_LOG"
for tool in docker gh git; do
  cat >"$STUB_BIN/$tool" <<STUB
#!/usr/bin/env bash
printf '%s %s\n' "$tool" "\$*" >>"$STUB_LOG"
if [[ "$tool" == git && "\${1:-}" == cat-file ]]; then exit 1; fi
if [[ "$tool" == docker ]]; then
  case "\${DOCKER_TEST_MODE:-}" in
    query-failure)
      if [[ "\$1 \$2 \$3" == "ps -aq --filter" ]]; then exit 41; fi
      ;;
    remove-failure)
      if [[ "\$1 \$2 \$3" == "ps -aq --filter" ]]; then printf 'container-123\\n'; exit 0; fi
      if [[ "\$1 \$2" == "rm -f" ]]; then exit 42; fi
      ;;
  esac
fi
exit 0
STUB
  chmod +x "$STUB_BIN/$tool"
done
export CURL_LOG
cat >"$STUB_BIN/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
cookie="" cookie_jar="" output="" headers="" url="" location=false write_out=""
while (($#)); do
  case "$1" in
    --cookie) cookie="$2"; shift 2 ;;
    --cookie-jar) cookie_jar="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    --dump-header) headers="$2"; shift 2 ;;
    --write-out) write_out="$2"; shift 2 ;;
    --location) location=true; shift ;;
    --max-redirs) [[ "$2" == 0 ]] || { printf 'curl did not disable automatic redirects\n' >&2; exit 102; }; shift 2 ;;
    --silent|--show-error|--globoff) shift ;;
    --max-time) shift 2 ;;
    *) url="$1"; shift ;;
  esac
done
[[ -n "$cookie" && "$cookie" == "$cookie_jar" ]] || { printf 'curl did not receive one shared cookie jar\n' >&2; exit 90; }
[[ -f "$cookie" && -d "$(dirname "$cookie")" ]] || { printf 'curl cookie jar is not pre-created\n' >&2; exit 91; }
[[ "$(dirname "$cookie")" == "$TEST_PROBE_DIR" ]] || { printf 'curl cookie jar escaped the private test probe directory\n' >&2; exit 99; }
[[ "$location" == false ]] || { printf 'curl automatic redirect following is enabled\n' >&2; exit 92; }
[[ "$write_out" == '%{http_code} %{url_effective}' ]] || { printf 'curl does not report final status and URL\n' >&2; exit 93; }
[[ "$headers" == "$(dirname "$cookie")/route.headers" ]] || { printf 'curl response headers escaped probe directory\n' >&2; exit 103; }
[[ "$output" == "$(dirname "$cookie")/"* ]] || { printf 'curl response output escaped probe directory\n' >&2; exit 94; }
[[ "$(stat -f '%Lp' "$cookie" 2>/dev/null || stat -c '%a' "$cookie")" == 600 ]] || { printf 'cookie jar mode is not 0600\n' >&2; exit 95; }
[[ "$(stat -f '%Lp' "$(dirname "$cookie")" 2>/dev/null || stat -c '%a' "$(dirname "$cookie")")" == 700 ]] || { printf 'probe directory mode is not 0700\n' >&2; exit 100; }
printf '%s\n' "$url" >>"$CURL_LOG"
http_status=200
location_value=""
if [[ -n "${CURL_REDIRECT_URL:-}" && "$url" == "$CURL_REDIRECT_URL" ]]; then
  grep -q 'synthetic-session' "$cookie" || { printf 'HTML/CSS probe did not receive the shared session cookie\n' >&2; exit 105; }
  http_status=302
  location_value="${CURL_REDIRECT_LOCATION:-}"
else
case "$url" in
  http://127.0.0.1:5000/demo/login\?return_to=*)
    [[ ! -s "$cookie" ]] || { printf 'login bootstrap was not first\n' >&2; exit 96; }
    printf '# Netscape HTTP Cookie File\n127.0.0.1\tFALSE\t/\tFALSE\t0\t_demo_session\tsynthetic-session\n' >"$cookie"
    http_status=302
    location_value='http://127.0.0.1:5000/ops/mail?tenant_id=northstar'
    ;;
  http://127.0.0.1:5000/redirect-cross-origin)
    http_status=302
    location_value='https://outside.example/collect'
    ;;
  http://127.0.0.1:5000/redirect-alternate-port)
    http_status=302
    location_value='http://127.0.0.1:5001/collect'
    ;;
  http://127.0.0.1:5000/ops/mail\?tenant_id=northstar)
    grep -q 'synthetic-session' "$cookie" || { printf 'same-origin redirect did not receive login cookie\n' >&2; exit 104; }
    ;;
  *)
    grep -q 'synthetic-session' "$cookie" || { printf 'protected route did not receive login cookie\n' >&2; exit 97; }
    ;;
esac
fi
printf 'stub response for %s\n' "$url" >"$output"
if [[ -n "$location_value" ]]; then
  printf 'HTTP/1.1 302 Found\r\nLocation: %s\r\n\r\n' "$location_value" >"$headers"
else
  printf 'HTTP/1.1 200 OK\r\n\r\n' >"$headers"
fi
printf '%s %s' "$http_status" "$url"
STUB
chmod +x "$STUB_BIN/curl"

# shellcheck source=scripts/check_phase178_candidate.sh
PHASE178_CANDIDATE_LIB_ONLY=1 source "$LAUNCHER" || die "could not source the launcher in library mode"
set +e # the launcher enables errexit; this harness asserts return codes itself

# --- worktree diagnostic visibility ---------------------------------------
WORKTREE_STUB_BIN="$TEST_DIR/worktree-stub-bin"
mkdir -p "$WORKTREE_STUB_BIN"
cat >"$WORKTREE_STUB_BIN/git" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-} ${2:-}" == "worktree add" ]] || exit 99
printf '%s\n' 'fatal: simulated Git metadata permission denial' >&2
exit 1
STUB
chmod +x "$WORKTREE_STUB_BIN/git"
WORKTREE_STUB_PATH="$TEST_DIR/candidate-worktree"
WORKTREE_STUB_SHA="8e501960bc975ed44b632ba5c74522e0c5d66f8c"
WORKTREE_FAILURE_OUTPUT="$(
  PATH="$WORKTREE_STUB_BIN:$PATH" bash -c '
    PHASE178_CANDIDATE_LIB_ONLY=1 source "$1"
    add_candidate_worktree "$2" "$3"
  ' _ "$LAUNCHER" "$WORKTREE_STUB_PATH" "$WORKTREE_STUB_SHA" 2>&1
)"
WORKTREE_FAILURE_STATUS=$?
[[ "$WORKTREE_FAILURE_STATUS" -eq 1 ]] || die "failed git worktree helper returned the wrong status"
[[ "$WORKTREE_FAILURE_OUTPUT" == *"could not create detached worktree at $WORKTREE_STUB_SHA"* ]] || die "launcher context was missing from the worktree error"
[[ "$WORKTREE_FAILURE_OUTPUT" == *"simulated Git metadata permission denial"* ]] || die "Git's underlying worktree diagnostic was hidden"
[[ ! -e "$WORKTREE_STUB_PATH" ]] || die "the offline worktree test created a real candidate path"
ok worktree-failure-diagnostic-visible

# --- extract_css_href ------------------------------------------------------
HASH32="0123456789abcdef0123456789abcdef"
printf '<html><link rel="stylesheet" href="/dev/mail/css-%s"></html>' "$HASH32" >"$TEST_DIR/with.html"
printf '<html><link rel="stylesheet" href="/assets/app.css"></html>' >"$TEST_DIR/without.html"
printf '<html><link rel="stylesheet" href="https://outside.example/dev/mail/css-%s"></html>' "$HASH32" >"$TEST_DIR/external-css.html"
got="$(extract_css_href "$TEST_DIR/with.html")"
[[ "$got" == "/dev/mail/css-$HASH32" ]] || die "extract_css_href returned '$got'"
none="$(extract_css_href "$TEST_DIR/without.html")"
rc=$?
[[ $rc -ne 0 && -z "$none" ]] || die "extract_css_href must fail silently without a versioned link (rc=$rc out='$none')"
none="$(extract_css_href "$TEST_DIR/external-css.html")"
rc=$?
[[ $rc -ne 0 && -z "$none" ]] || die "extract_css_href accepted an external mount-rooted lookalike (rc=$rc out='$none')"
ok extract_css_href

# --- css_triple ------------------------------------------------------------
printf 'body{color:#123}' >"$TEST_DIR/source.css"
printf 'body{color:#123456}' >"$TEST_DIR/built.css"
cp "$TEST_DIR/built.css" "$TEST_DIR/served-same.css"
printf 'body{color:#123457}' >"$TEST_DIR/served-diff.css"
line="$(css_triple "$TEST_DIR/source.css" "$TEST_DIR/built.css" "$TEST_DIR/served-same.css")"
rc=$?
[[ $rc -eq 0 && "${line%% *}" == match ]] || die "css_triple should match identical built/served (rc=$rc '$line')"
read -r _ src_sha built_sha served_sha <<<"$line"
[[ "$built_sha" == "$served_sha" && "$src_sha" != "$built_sha" && ${#src_sha} -eq 64 ]] || die "css_triple digests are wrong"
line="$(css_triple "$TEST_DIR/source.css" "$TEST_DIR/built.css" "$TEST_DIR/served-diff.css")"
rc=$?
[[ $rc -ne 0 && "${line%% *}" == mismatch ]] || die "css_triple should report a one-byte difference (rc=$rc '$line')"
ok css_triple

# --- assert_safe_project ---------------------------------------------------
assert_safe_project mailglass-phase178-review-abcd1234-x 2>/dev/null || die "assert_safe_project rejected a launcher-created name"
for bad in "mailglass-storybook-review-demo" "" "mailglass-phase178-reviewX" "mailglass-demo" "mailglass-storybook-review-demo-1"; do
  if assert_safe_project "$bad" 2>/dev/null; then die "assert_safe_project accepted '$bad'"; fi
done
ok assert_safe_project

# --- allocate_ports --------------------------------------------------------
for _ in 1 2 3; do
  ports="$(allocate_ports)" || die "allocate_ports failed"
  read -r hp dp <<<"$ports"
  [[ "$hp" =~ ^[0-9]+$ && "$dp" =~ ^[0-9]+$ && "$hp" != "$dp" ]] || die "allocate_ports returned '$ports'"
  [[ "$hp" != 4015 && "$hp" != 5415 && "$dp" != 4015 && "$dp" != 5415 ]] || die "allocate_ports returned a reserved port: $ports"
done
if PHASE178_TEST_PORTS="4015 6000" allocate_ports >/dev/null 2>&1; then die "allocate_ports accepted 4015"; fi
if PHASE178_TEST_PORTS="6000 5415" allocate_ports >/dev/null 2>&1; then die "allocate_ports accepted 5415"; fi
if PHASE178_TEST_PORTS="6000 6000" allocate_ports >/dev/null 2>&1; then die "allocate_ports accepted identical ports"; fi
[[ "$(PHASE178_TEST_PORTS="6001 6002" allocate_ports)" == "6001 6002" ]] || die "allocate_ports override did not pass through valid ports"
ok allocate_ports

# --- route probe cookie reuse ---------------------------------------------
[[ "${DEFAULT_ROUTES[0]}" == "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar" ]] || die "demo login bootstrap is not the first default route"
TEST_PROBE_DIR="$TEST_DIR/private-probe"
mkdir -m 700 "$TEST_PROBE_DIR"
COOKIE_JAR="$TEST_PROBE_DIR/cookies.txt"
export TEST_PROBE_DIR
(umask 077; : >"$TEST_PROBE_DIR/cookies.txt")
chmod 600 "$TEST_PROBE_DIR/cookies.txt"
for route in "${DEFAULT_ROUTES[@]}"; do
  result="$(PATH="$STUB_BIN:$PATH" probe_route "$TEST_PROBE_DIR" "$COOKIE_JAR" "http://127.0.0.1:5000" "$route")" || die "probe_route failed for $route"
  [[ "${result%% *}" == 200 ]] || die "probe_route did not retain final HTTP 200 for $route: $result"
  if [[ "$route" == "${DEFAULT_ROUTES[0]}" ]]; then
    [[ "$result" == "200 http://127.0.0.1:5000/ops/mail?tenant_id=northstar" ]] || die "login redirect final URL was not the expected same-origin return_to: $result"
  else
    [[ "$result" == "200 http://127.0.0.1:5000$route" ]] || die "protected route final URL was not retained: $result"
  fi
done
[[ "$(wc -l <"$CURL_LOG" | tr -d ' ')" == "$(( ${#DEFAULT_ROUTES[@]} + 1 ))" ]] || die "same-origin login redirect did not result in exactly one additional request"
[[ "$(head -n 1 "$CURL_LOG")" == "http://127.0.0.1:5000${DEFAULT_ROUTES[0]}" ]] || die "login bootstrap was not the first curl request"
[[ "$(sed -n '2p' "$CURL_LOG")" == "http://127.0.0.1:5000/ops/mail?tenant_id=northstar" ]] || die "same-origin login redirect was not followed by the expected second request"
[[ "$(stat -f '%Lp' "$TEST_PROBE_DIR/cookies.txt" 2>/dev/null || stat -c '%a' "$TEST_PROBE_DIR/cookies.txt")" == 600 ]] || die "cookie jar permissions changed during route probes"

: >"$CURL_LOG"
for unsafe_route in /redirect-cross-origin /redirect-alternate-port; do
  result="$(PATH="$STUB_BIN:$PATH" probe_route "$TEST_PROBE_DIR" "$COOKIE_JAR" "http://127.0.0.1:5000" "$unsafe_route")" || die "probe_route failed while rejecting $unsafe_route"
  [[ "${result%% *}" == redirect_rejected ]] || die "probe_route accepted unsafe redirect for $unsafe_route: $result"
  [[ "$(wc -l <"$CURL_LOG" | tr -d ' ')" == 1 ]] || die "probe_route made a second request after rejecting $unsafe_route"
  [[ "$(cat "$CURL_LOG")" == "http://127.0.0.1:5000$unsafe_route" ]] || die "probe_route contacted a URL beyond the unsafe redirect response"
  : >"$CURL_LOG"
done

for invalid_route in \
  '@127.0.0.1:5001/collect' \
  'http://user:pass@127.0.0.1:5001/collect' \
  '//127.0.0.1:5001/collect' \
  '/\\@127.0.0.1:5001/collect' \
  $'/dev/mail\n/redirect'; do
  : >"$CURL_LOG"
  result="$(PATH="$STUB_BIN:$PATH" probe_route "$TEST_PROBE_DIR" "$COOKIE_JAR" "http://127.0.0.1:5000" "$invalid_route")" ||
    die "probe_route errored instead of refusing invalid route input"
  [[ "${result%% *}" == route_rejected ]] || die "probe_route accepted unsafe route input: $result"
  [[ ! -s "$CURL_LOG" ]] || die "probe_route made a request for unsafe route input '$invalid_route'"
done
ok custom-route-input-refusal-precedes-request

for probe_path in "/dev/mail" "/dev/mail/css-$HASH32"; do
  if [[ "$probe_path" == /dev/mail ]]; then response_path="$TEST_PROBE_DIR/probe.html"; else response_path="$TEST_PROBE_DIR/probe.css"; fi
  for target in 'https://outside.example/collect' 'http://127.0.0.1:5001/collect'; do
    : >"$CURL_LOG"
    request_url="http://127.0.0.1:5000$probe_path"
    result="$(CURL_REDIRECT_URL="$request_url" CURL_REDIRECT_LOCATION="$target" PATH="$STUB_BIN:$PATH" \
      probe_route "$TEST_PROBE_DIR" "$COOKIE_JAR" "http://127.0.0.1:5000" "$probe_path" "$response_path")" ||
      die "probe_route failed for HTML/CSS identity probe $probe_path"
    [[ "${result%% *}" == redirect_rejected ]] || die "HTML/CSS identity probe accepted unsafe redirect $target: $result"
    [[ "$(wc -l <"$CURL_LOG" | tr -d ' ')" == 1 ]] || die "HTML/CSS identity probe made a request after unsafe redirect $target"
    [[ "$(cat "$CURL_LOG")" == "$request_url" ]] || die "HTML/CSS identity probe contacted a URL beyond its redirect response"
  done
done
ok route-html-css-probes-share-origin-boundaries-and-cookie-jar

# --- ci_contexts_status ----------------------------------------------------
check_runs() { # check_runs <CI Green conclusion|none> <Guard conclusion|none> [status]
  local green="$1" guard="$2" status="${3:-completed}"
  node -e '
const [green, guard, status] = process.argv.slice(1);
const runs = [];
if (green !== "none") runs.push({ id: 11, name: "CI Green", status, conclusion: status === "completed" ? green : null });
if (guard !== "none") runs.push({ id: 12, name: "Guard Release Trigger", status: "completed", conclusion: guard });
runs.push({ id: 13, name: "Dependabot", status: "completed", conclusion: "failure" });
process.stdout.write(JSON.stringify({ total_count: runs.length, check_runs: runs }));
' "$green" "$guard" "$status"
}
check_runs success success >"$TEST_DIR/cr-pass.json"
verdict="$(ci_contexts_status "$TEST_DIR/cr-pass.json" 2>/dev/null)" || die "ci_contexts_status should pass when both contexts succeeded"
[[ "$verdict" == *'"status":"pass"'* ]] || die "ci_contexts_status pass payload: $verdict"
check_runs failure success >"$TEST_DIR/cr-fail.json"
err="$(ci_contexts_status "$TEST_DIR/cr-fail.json" 2>&1 >/dev/null)" && die "ci_contexts_status accepted a failed CI Green"
[[ "$err" == *"CI Green=failure"* ]] || die "ci_contexts_status did not name CI Green: $err"
check_runs success none >"$TEST_DIR/cr-missing.json"
err="$(ci_contexts_status "$TEST_DIR/cr-missing.json" 2>&1 >/dev/null)" && die "ci_contexts_status accepted a missing Guard Release Trigger"
[[ "$err" == *"Guard Release Trigger=missing"* ]] || die "ci_contexts_status did not name the missing context: $err"
check_runs success success in_progress >"$TEST_DIR/cr-running.json"
err="$(ci_contexts_status "$TEST_DIR/cr-running.json" 2>&1 >/dev/null)" && die "ci_contexts_status accepted an in-progress CI Green"
[[ "$err" == *"CI Green=in_progress"* ]] || die "ci_contexts_status did not name the in-progress context: $err"
# Two concatenated pages (what gh --paginate prints); a rerun supersedes the older failure.
{
  printf '{"total_count":2,"check_runs":[{"id":5,"name":"CI Green","status":"completed","conclusion":"failure"}]}'
  printf '{"total_count":2,"check_runs":[{"id":9,"name":"CI Green","status":"completed","conclusion":"success"},{"id":10,"name":"Guard Release Trigger","status":"completed","conclusion":"success"}]}'
} >"$TEST_DIR/cr-pages.json"
ci_contexts_status "$TEST_DIR/cr-pages.json" >/dev/null 2>&1 || die "ci_contexts_status should read concatenated pages and take the latest run"
ci_contexts_status - <"$TEST_DIR/cr-pass.json" >/dev/null 2>&1 || die "ci_contexts_status should read stdin"
ok ci_contexts_status

# --- launcher refusals happen before any docker call ------------------------
: >"$STUB_LOG"
for bad_sha in "not-a-sha" "ABCDEF0123456789ABCDEF0123456789ABCDEF01" "abc123" "$(printf '0%.0s' {1..40})"; do
  if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --sha "$bad_sha" >/dev/null 2>&1; then die "launcher accepted --sha '$bad_sha'"; fi
done
if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" >/dev/null 2>&1; then die "launcher accepted a missing --sha"; fi
if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --sha "$(git -C "$ROOT_DIR" rev-parse HEAD)" --bogus >/dev/null 2>&1; then die "launcher accepted an unknown option"; fi
if grep -Eq '^(docker|gh) ' "$STUB_LOG"; then die "docker/gh were invoked before the SHA refusals: $(cat "$STUB_LOG")"; fi
ok invalid-sha-refused-before-docker

# --- teardown refuses records that do not belong to this launcher ------------
write_record() { # write_record <file> <project> <run_parent>
  node -e '
const [file, project, runParent] = process.argv.slice(1);
require("node:fs").writeFileSync(file, JSON.stringify({
  compose_project: project, run_parent: runParent, worktree: `${runParent}/candidate`, source_sha: "0".repeat(40)
}));
' "$1" "$2" "$3"
}
write_record "$TEST_DIR/owner.json" mailglass-storybook-review-demo /tmp/mailglass-phase178.AAAAAAAA
write_record "$TEST_DIR/prefix.json" mailglass-phase178-reviewX /tmp/mailglass-phase178.AAAAAAAA
write_record "$TEST_DIR/parent.json" mailglass-phase178-review-abcd1234-x "$HOME"
write_record "$TEST_DIR/empty.json" "" /tmp/mailglass-phase178.AAAAAAAA
: >"$STUB_LOG"
for rec in owner prefix parent empty; do
  if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --teardown "$TEST_DIR/$rec.json" >/dev/null 2>&1; then die "teardown accepted the $rec record"; fi
done
if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --teardown "$TEST_DIR/missing.json" >/dev/null 2>&1; then die "teardown accepted a missing record"; fi
[[ ! -s "$STUB_LOG" ]] || die "Docker/Git was invoked while refusing unsafe teardown records: $(cat "$STUB_LOG")"
ok teardown-refuses-foreign-projects-and-paths

# --- private ownership marker binds all cleanup identity fields -------------
write_owned_record() { # write_owned_record <record> <project> <run_parent> <sha> <run_id>
  node -e '
const fs = require("node:fs");
const path = require("node:path");
const [file, project, runParent, sha, runId] = process.argv.slice(1);
const worktree = path.join(runParent, "candidate");
const markerPath = path.join(runParent, ".phase178-owner.json");
const binding = { schema_version: "phase178-owner.v1", compose_project: project, source_sha: sha, run_id: runId, run_parent: runParent, worktree };
fs.writeFileSync(markerPath, JSON.stringify(binding, null, 2) + "\n", { mode: 0o600 });
fs.chmodSync(markerPath, 0o600);
const record = { ...binding, schema_version: "phase178-candidate.v1", ownership_marker: markerPath };
fs.writeFileSync(file, JSON.stringify(record, null, 2) + "\n");
' "$1" "$2" "$3" "$4" "$5"
  printf 'offline recovery config\n' >"$3/compose.demo.yml"
}
TAMPER_PARENT="$(mktemp -d /tmp/mailglass-phase178.XXXXXXXX)"
TEST_RECOVERY_DIRS+=("$TAMPER_PARENT")
chmod 700 "$TAMPER_PARENT"
TAMPER_PROJECT="mailglass-phase178-review-abcd1234-run01"
write_owned_record "$TEST_DIR/tampered.json" "$TAMPER_PROJECT" "$TAMPER_PARENT" "0000000000000000000000000000000000000000" run01
node -e '
const fs = require("node:fs");
const file = process.argv[1];
const record = JSON.parse(fs.readFileSync(file, "utf8"));
record.compose_project = "mailglass-phase178-review-other-run02";
fs.writeFileSync(file, JSON.stringify(record, null, 2) + "\n");
' "$TEST_DIR/tampered.json"
: >"$STUB_LOG"
if PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --teardown "$TEST_DIR/tampered.json" >/dev/null 2>&1; then die "teardown accepted a record whose project differs from its ownership marker"; fi
[[ ! -s "$STUB_LOG" ]] || die "Docker/Git ran before the tampered ownership record was refused: $(cat "$STUB_LOG")"
[[ -f "$TAMPER_PARENT/.phase178-owner.json" && -f "$TAMPER_PARENT/compose.demo.yml" ]] || die "tampered-record refusal changed recovery files"
ok teardown-validates-private-run-ownership-before-mutation

# --- Docker failures remain visible and retain recovery files ---------------
for mode in query-failure remove-failure; do
  run_parent="$(mktemp -d /tmp/mailglass-phase178.XXXXXXXX)"
  TEST_RECOVERY_DIRS+=("$run_parent")
  chmod 700 "$run_parent"
  project="mailglass-phase178-review-abcd1234-$mode"
  record="$TEST_DIR/$mode.json"
  write_owned_record "$record" "$project" "$run_parent" "0000000000000000000000000000000000000000" "$mode"
  : >"$STUB_LOG"
  if DOCKER_TEST_MODE="$mode" PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --teardown "$record" >"$TEST_DIR/$mode.out" 2>&1; then
    die "teardown reported success after Docker $mode"
  fi
  [[ -d "$run_parent" && -f "$run_parent/.phase178-owner.json" && -f "$run_parent/compose.demo.yml" ]] || die "Docker $mode discarded recovery files"
  grep -q 'retained recovery files' "$TEST_DIR/$mode.out" || die "Docker $mode did not explain that recovery files were retained: $(cat "$TEST_DIR/$mode.out")"
  if [[ "$mode" == remove-failure ]]; then
    grep -q 'docker rm -f container-123' "$STUB_LOG" || die "Docker removal failure was not exercised"
  else
    grep -q 'docker ps -aq --filter' "$STUB_LOG" || die "Docker query failure was not exercised"
  fi
done
ok teardown-docker-failures-nonzero-and-retain-recovery

# --- complete teardown verifies absence before discarding recovery directory -
success_parent="$(mktemp -d /tmp/mailglass-phase178.XXXXXXXX)"
TEST_RECOVERY_DIRS+=("$success_parent")
chmod 700 "$success_parent"
success_record="$TEST_DIR/success.json"
write_owned_record "$success_record" "mailglass-phase178-review-abcd1234-success" "$success_parent" \
  "0000000000000000000000000000000000000000" success
: >"$STUB_LOG"
if ! PATH="$STUB_BIN:$PATH" bash "$LAUNCHER" --teardown "$success_record" >"$TEST_DIR/success.out" 2>&1; then
  die "clean teardown failed despite empty project resources: $(cat "$TEST_DIR/success.out")"
fi
[[ ! -e "$success_parent" ]] || die "verified-clean teardown retained the run directory"
for resource in 'ps -aq --filter' 'volume ls -q --filter' 'network ls -q --filter'; do
  grep -q "docker $resource" "$STUB_LOG" || die "clean teardown skipped project-resource verification for: $resource"
done
node -e '
const record = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
const verified = new Set(record.teardown.dispositions.filter((item) => item.status === "verified").map((item) => item.name));
for (const name of ["containers_verification", "volumes_verification", "networks_verification"]) {
  if (!verified.has(name)) throw new Error(`missing verified disposition ${name}`);
}
' "$success_record" || die "clean teardown record omitted an absence verification"
ok teardown-success-requires-empty-project-resources

# --- static guarantees ------------------------------------------------------
for file in "$LAUNCHER" "$COST_TOOL"; do
  name="${file#"$ROOT_DIR"/}"
  if [[ ! -f "$file" ]]; then
    ok "no-github-write-commands $name (absent: re-run after the file exists)"
    continue
  fi
  count="$(grep -c -e 'gh pr create' -e 'gh workflow run' -e 'gh run rerun' -e 'gh pr merge' -e 'git push' "$file" || true)"
  [[ "$count" == 0 ]] || die "$name contains $count GitHub-write or push command(s)"
  ok "no-github-write-commands $name"
done
count="$(grep -c -e 'make demo-down' -e 'demo-down' "$LAUNCHER" || true)"
[[ "$count" == 0 ]] || die "launcher references the shared demo teardown target"
loose="$(grep -E 'docker compose' "$LAUNCHER" | grep -vE '^[[:space:]]*#' | grep -v -e ' -p ' || true)"
[[ -z "$loose" ]] || die "docker compose is used without -p: $loose"
ok every-docker-compose-call-is-project-scoped
if grep -q 'worktree prune' "$LAUNCHER"; then die "launcher contains repository-wide git worktree prune"; fi
ok no-repository-wide-worktree-prune
if grep -q -- '--location' "$LAUNCHER"; then die "launcher contains automatic curl redirect following"; fi
ok no-automatic-curl-redirect-following

# --- defaults ---------------------------------------------------------------
for route in '/dev/mail"' '/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin' '/dev/storybook/preview_authoring' \
  '/dev/storybook/preview_chrome' '/dev/storybook/primitives/stat_card' '/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar'; do
  grep -qF -- "$route" "$LAUNCHER" || die "default route missing from launcher: $route"
done
mode="$(git -C "$ROOT_DIR" ls-files -s scripts/check_phase178_candidate.sh | awk '{print $1}')"
[[ -z "$mode" || "$mode" == 100755 ]] || die "launcher is tracked with mode $mode, expected 100755"
ok default-routes-and-mode

printf 'PASS %d\n' "$PASSED"
