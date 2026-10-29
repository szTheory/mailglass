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
PASSED=0

cleanup() {
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
for tool in docker gh; do
  cat >"$STUB_BIN/$tool" <<STUB
#!/usr/bin/env bash
printf '%s %s\n' "$tool" "\$*" >>"$STUB_LOG"
exit 0
STUB
  chmod +x "$STUB_BIN/$tool"
done

# shellcheck source=scripts/check_phase178_candidate.sh
PHASE178_CANDIDATE_LIB_ONLY=1 source "$LAUNCHER" || die "could not source the launcher in library mode"
set +e # the launcher enables errexit; this harness asserts return codes itself

# --- extract_css_href ------------------------------------------------------
HASH32="0123456789abcdef0123456789abcdef"
printf '<html><link rel="stylesheet" href="/dev/mail/css-%s"></html>' "$HASH32" >"$TEST_DIR/with.html"
printf '<html><link rel="stylesheet" href="/assets/app.css"></html>' >"$TEST_DIR/without.html"
got="$(extract_css_href "$TEST_DIR/with.html")"
[[ "$got" == "/dev/mail/css-$HASH32" ]] || die "extract_css_href returned '$got'"
none="$(extract_css_href "$TEST_DIR/without.html")"
rc=$?
[[ $rc -ne 0 && -z "$none" ]] || die "extract_css_href must fail silently without a versioned link (rc=$rc out='$none')"
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
[[ ! -s "$STUB_LOG" ]] || die "docker/gh were invoked before the SHA refusals: $(cat "$STUB_LOG")"
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
[[ ! -s "$STUB_LOG" ]] || die "docker was invoked while refusing unsafe teardown records: $(cat "$STUB_LOG")"
ok teardown-refuses-foreign-projects-and-paths

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

# --- defaults ---------------------------------------------------------------
for route in '/dev/mail"' '/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin' '/dev/storybook/preview_authoring' \
  '/dev/storybook/preview_chrome' '/dev/storybook/primitives/stat_card' '/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar'; do
  grep -qF -- "$route" "$LAUNCHER" || die "default route missing from launcher: $route"
done
mode="$(git -C "$ROOT_DIR" ls-files -s scripts/check_phase178_candidate.sh | awk '{print $1}')"
[[ -z "$mode" || "$mode" == 100755 ]] || die "launcher is tracked with mode $mode, expected 100755"
ok default-routes-and-mode

printf 'PASS %d\n' "$PASSED"
