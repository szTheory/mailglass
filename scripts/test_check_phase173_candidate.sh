#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_BIN_DIR="$(dirname "$(node -p 'process.execPath')")"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/phase173-candidate-contract.XXXXXX")"
FAKE_BIN="$TEST_DIR/bin"
FAKE_ROOT="$TEST_DIR/candidate"
FIXTURES="$TEST_DIR/fixtures"
LOG="$TEST_DIR/cli.log"
SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
CSS_TEXT=".candidate { color: #123456; }"
CSS_MD5="$(printf '%s' "$CSS_TEXT" | md5 -q 2>/dev/null || printf '%s' "$CSS_TEXT" | md5sum | cut -d ' ' -f1)"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT
mkdir -p "$FAKE_BIN" "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence" "$FAKE_ROOT/scripts" \
  "$FAKE_ROOT/mailglass_admin/assets/css" "$FAKE_ROOT/mailglass_admin/priv/static" \
  "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence" "$FIXTURES"
printf '%s' "$CSS_TEXT" > "$FAKE_ROOT/mailglass_admin/assets/css/app.css"
cp "$FAKE_ROOT/mailglass_admin/assets/css/app.css" "$FAKE_ROOT/mailglass_admin/priv/static/app.css"
touch "$FAKE_ROOT/compose.demo.yml"
cat > "$FAKE_ROOT/scripts/gsd-regression-gate.sh" <<'SH'
#!/usr/bin/env bash
printf 'regression gate fake passed\n'
SH
chmod +x "$FAKE_ROOT/scripts/gsd-regression-gate.sh"
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-01-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-01.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-02-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-02.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-03-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-03.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-01-SUMMARY.md" <<'SUMMARY'
plan_head_before: 1111111111111111111111111111111111111111
SUMMARY
for path in tracked/phase173-01.ex tracked/phase173-02.ex tracked/phase173-03.ex; do
  mkdir -p "$FAKE_ROOT/$(dirname "$path")"
  touch "$FAKE_ROOT/$path"
done

SUMMARY_PATHS=""
for phase in 168 169 170 171 172; do
  case "$phase" in
    168) count=10 ;;
    169) count=5 ;;
    170) count=8 ;;
    171) count=4 ;;
    172) count=3 ;;
  esac
  mkdir -p "$FAKE_ROOT/.planning/phases/${phase}-fixture"
  for ((index = 1; index <= count; index++)); do
    summary=".planning/phases/${phase}-fixture/${phase}-$(printf '%02d' "$index")-SUMMARY.md"
    SUMMARY_PATHS+="$summary"$'\n'
    if [[ "$phase" == 172 && "${FAKE_REQUIRED_DIRTY:-false}" == true ]]; then
      accepted='reference/demo_app/assets/e2e/demo.spec.js'
    else
      accepted="lib/phase${phase}/task${index}.ex"
    fi
    printf '## Task Commits\n\n1. **Task 1** — `deadbeef` (`fix`)\n\nkey-files:\n  created:\n    - %s\n' "$accepted" > "$FAKE_ROOT/$summary"
  done
done
export SUMMARY_PATHS FAKE_ROOT FAKE_BIN FIXTURES LOG SHA CSS_MD5 CSS_TEXT ROOT_DIR

cat > "$FAKE_BIN/git" <<'GIT'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >> "$LOG"
if [[ "${1:-}" == -C ]]; then cd "$2"; shift 2; fi
command="$1"
shift || true
case "$command" in
  rev-parse)
    if [[ "${1:-}" == --show-toplevel ]]; then printf '%s\n' "$PWD"; else printf '%s\n' "${FAKE_GIT_HEAD:-$SHA}"; fi
    ;;
  status)
    if [[ ! -f "$FIXTURES/worktree-added" && -n "${FAKE_ORIGIN_STATUS:-}" ]]; then
      printf '%s\0' "$FAKE_ORIGIN_STATUS"
    else
      printf '%s' "${FAKE_GIT_STATUS:-}"
    fi
    ;;
  check-ignore)
    exit 0
    ;;
  ls-tree)
    if [[ "${*: -1}" == .planning/phases ]]; then printf '%s' "$SUMMARY_PATHS"; fi
    ;;
  show)
    spec="$1"
    path="${spec#*:}"
    if [[ "$path" == .planning/phases/173-consistency-and-delivery-evidence/173-01-SUMMARY.md ]]; then
      cat "$FAKE_ROOT/$path"
    elif [[ "${FAKE_REQUIRED_DIRTY:-false}" == true && "$path" == .planning/phases/172-fixture/* ]]; then
      printf '## Task Commits\n\n1. **Task 1** — `deadbeef` (`fix`)\n\nkey-files:\n  created:\n    - reference/demo_app/assets/e2e/demo.spec.js\n'
    else
      cat "$FAKE_ROOT/$path"
    fi
    ;;
  merge-base)
    [[ "${FAKE_MISSING_COMMIT:-}" != "${2:-}" ]]
    ;;
  diff)
    if [[ "$*" == *"mailglass_admin/assets"* || "$*" == *"mailglass_admin/priv/static"* ]]; then
      printf '%s' "${FAKE_ASSET_DIFF:-}"
    fi
    ;;
  cat-file)
    path="${2#*:}"
    [[ "${FAKE_MISSING_PATH:-}" != "$path" ]]
    ;;
  worktree)
    if [[ "${1:-}" == add ]]; then
      destination="${3:-}"
      mkdir -p "$destination"
      touch "$FIXTURES/worktree-added"
      cp -R "$FAKE_ORIGIN_DIR/." "$destination/"
      rm -rf "$destination/reference/demo_app/tmp/demo_browser_evidence"
    fi
    ;;
  *)
    exit 0
    ;;
esac
GIT
cat > "$FAKE_BIN/docker" <<'DOCKER'
#!/usr/bin/env bash
printf 'docker %s\n' "$*" >> "$LOG"
if [[ "${FAKE_DOCKER_UP:-true}" == false && "$*" == *" up "* ]]; then exit 1; fi
exit 0
DOCKER
cat > "$FAKE_BIN/asdf" <<'ASDF'
#!/usr/bin/env bash
printf 'asdf %s\n' "$*" >> "$LOG"
if [[ "${1:-}" == exec ]]; then shift; fi
if [[ "${1:-}" == mix ]]; then exit 0; fi
exec "$@"
ASDF
cat > "$FAKE_BIN/mix" <<'MIX'
#!/usr/bin/env bash
printf 'mix %s\n' "$*" >> "$LOG"
exit 0
MIX
cat > "$FAKE_BIN/gh" <<'GH'
#!/usr/bin/env bash
printf 'gh %s\n' "$*" >> "$LOG"
if [[ "$1" == run && "$2" == list ]]; then
  if [[ "${FAKE_NO_CI:-false}" == true ]]; then printf '[]\n'; else printf '[{"databaseId":123,"headSha":"%s","status":"completed","conclusion":"success","workflowName":"CI","url":"https://github.com/example/run/123","event":"push"}]\n' "${FAKE_CI_HEAD_SHA:-$SHA}"; fi
elif [[ "$1" == run && "$2" == view ]]; then
  printf '{"databaseId":123,"headSha":"%s","status":"completed","conclusion":"%s","url":"https://github.com/example/run/123","workflowName":"CI","event":"push","jobs":[{"name":"CI Green","conclusion":"%s"},{"name":"Demo browser","conclusion":"success"}]}' "${FAKE_CI_HEAD_SHA:-$SHA}" "${FAKE_CI_CONCLUSION:-success}" "${FAKE_CI_CONCLUSION:-success}"
else
  exit 2
fi
GH
cat > "$FAKE_BIN/curl" <<'CURL'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "$LOG"
output=""
format=""
url=""
fail_on_error=false
while (($#)); do
  case "$1" in
    --output|-o) output="$2"; shift 2 ;;
    --write-out|-w) format="$2"; shift 2 ;;
    --fail|-f) fail_on_error=true; shift ;;
    --silent|-s|--show-error|-S|--location|-L) shift ;;
    --max-time) shift 2 ;;
    *) url="$1"; shift ;;
  esac
done
path="${url#http://127.0.0.1:*/}"
code=200
body="<html><link rel=\"stylesheet\" href=\"/dev/mail/css-$CSS_MD5\"></html>"
if [[ "$url" == *"/css-"* ]]; then
  if [[ "${FAKE_BAD_CSS:-false}" == true ]]; then
    body=".different { color: red; }"
  else
    body="$(cat "$FAKE_ROOT/mailglass_admin/priv/static/app.css")"
  fi
elif [[ -n "${FAKE_HTTP_FAIL_ROUTE:-}" && "$url" == *"$FAKE_HTTP_FAIL_ROUTE"* ]]; then
  code=503
fi
if [[ -n "$output" ]]; then printf '%s' "$body" > "$output"; fi
if [[ "$format" == '%{http_code}' ]]; then printf '%s' "$code"; fi
if [[ "$fail_on_error" == true && "$code" -ge 400 ]]; then exit 22; fi
exit 0
CURL
chmod +x "$FAKE_BIN"/*

write_metadata() {
  cat > "$TEST_DIR/origin-dirty-paths.json" <<EOF
{"schemaVersion":1,"originSha":"$SHA","files":[{"status":" M","path":"reference/demo_app/assets/e2e/demo.spec.js"}]}
EOF
}

run_candidate() {
  : > "$LOG"
  write_metadata
  env PATH="$FAKE_BIN:$NODE_BIN_DIR:$PATH" \
    PHASE173_CANDIDATE_MODE=true \
    PHASE173_CANDIDATE_SHA="$SHA" \
    PHASE173_CANDIDATE_WORKTREE="$FAKE_ROOT" \
    PHASE173_ORIGIN_DIRTY_METADATA="$TEST_DIR/origin-dirty-paths.json" \
    PHASE173_SKIP_LOCAL_CHECKS=false \
    FAKE_ROOT="$FAKE_ROOT" FAKE_BIN="$FAKE_BIN" FIXTURES="$FIXTURES" LOG="$LOG" \
    SHA="$SHA" CSS_MD5="$CSS_MD5" CSS_TEXT="$CSS_TEXT" SUMMARY_PATHS="$SUMMARY_PATHS" \
    "${TEST_ENV[@]}" \
    bash "$ROOT_DIR/scripts/check_phase173_candidate.sh"
}

assert_failure() {
  local label="$1"
  shift
  TEST_ENV=("$@")
  if run_candidate > "$TEST_DIR/$label.out" 2>&1; then
    printf 'FAIL: %s unexpectedly passed\n' "$label" >&2
    exit 1
  fi
}

TEST_ENV=()
if ! run_candidate > "$TEST_DIR/passed.out" 2>&1; then cat "$TEST_DIR/passed.out" >&2; cat "$LOG" >&2; exit 1; fi
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" "$LOG" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const log = fs.readFileSync(process.argv[3], "utf8");
if (record.status !== "passed" || record.requiredCi.status !== "passed" || record.readiness.status !== "passed") {
  throw new Error("good candidate did not produce complete preview/CI evidence");
}
if (!record.originalWorkspace.excludedDirtyPaths.some((x) => x.path === "reference/demo_app/assets/e2e/demo.spec.js")) {
  throw new Error("owner dirty path/status was not recorded as excluded");
}
if ([4015, 5415].includes(record.ports.http) || [4015, 5415].includes(record.ports.database)) {
  throw new Error("candidate reused a default demo port");
}
if (!record.reviewProject.startsWith("mailglass-phase173-review-")) throw new Error("review project is not uniquely named");
if (log.includes("docker compose") && log.includes(" down ")) throw new Error("retained Compose project was stopped");
if (log.includes("worktree remove") || /git (add |push |merge )|gh workflow run/.test(log)) {
  throw new Error("gate attempted staging, push, merge, dispatch, or cleanup");
}
if (record.assets.built.sha256 !== record.assets.served.sha256) throw new Error("served CSS did not match bundle");
if (record.localChecks.previewAssets !== "not-run-unchanged") throw new Error("unchanged Admin assets should not run the preview asset check");
if (log.includes("verify.preview")) throw new Error("preview asset check ran without Admin asset changes");
NODE

TEST_ENV=(FAKE_ASSET_DIFF='mailglass_admin/assets/css/app.css')
if ! run_candidate > "$TEST_DIR/changed_assets.out" 2>&1; then cat "$TEST_DIR/changed_assets.out" >&2; cat "$LOG" >&2; exit 1; fi
rg -q 'asdf exec mix verify.preview' "$LOG"
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (record.localChecks.previewAssets !== "passed") throw new Error("changed Admin assets did not record the preview asset check result");
NODE

assert_failure wrong_sha FAKE_GIT_HEAD=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
rg -q 'candidate HEAD does not match' "$TEST_DIR/wrong_sha.out"
assert_failure dirty_candidate FAKE_GIT_STATUS=' M lib/dirty.ex'
rg -q 'candidate worktree is dirty' "$TEST_DIR/dirty_candidate.out"
assert_failure missing_ancestor FAKE_MISSING_COMMIT=deadbeef
rg -q 'missing from candidate ancestry' "$TEST_DIR/missing_ancestor.out"
assert_failure bad_http FAKE_HTTP_FAIL_ROUTE=/dev/mail/gallery
rg -q 'HTTP route /dev/mail/gallery returned 503' "$TEST_DIR/bad_http.out"
assert_failure bad_css FAKE_BAD_CSS=true
rg -q 'served Admin CSS bytes differ' "$TEST_DIR/bad_css.out"
assert_failure failed_ci FAKE_CI_CONCLUSION=failure
rg -q 'required CI Green is not successful' "$TEST_DIR/failed_ci.out"
assert_failure missing_ci FAKE_NO_CI=true
rg -q 'no successful CI workflow run exists' "$TEST_DIR/missing_ci.out"
assert_failure wrong_sha_ci FAKE_CI_HEAD_SHA=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
rg -q 'no successful CI workflow run exists' "$TEST_DIR/wrong_sha_ci.out"

TEST_ENV=(FAKE_REQUIRED_DIRTY=true)
assert_failure required_owner_dirty FAKE_REQUIRED_DIRTY=true
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (!record.requiredOwnerDirtyPaths.some((x) => x.includes("reference/demo_app/assets/e2e/demo.spec.js"))) {
  throw new Error("required owner path was not reported as path/status only");
}
NODE

# Exercise the outer launcher with fake Git: it snapshots path/status metadata,
# creates a detached exact-SHA candidate, and invokes the committed candidate mode.
cp "$ROOT_DIR/scripts/check_phase173_candidate.sh" "$FAKE_ROOT/scripts/check_phase173_candidate.sh"
chmod +x "$FAKE_ROOT/scripts/check_phase173_candidate.sh"
write_metadata
: > "$LOG"
env PATH="$FAKE_BIN:$NODE_BIN_DIR:$PATH" \
  FAKE_ROOT="$FAKE_ROOT" FAKE_ORIGIN_DIR="$FAKE_ROOT" FAKE_ORIGIN_STATUS=' M reference/demo_app/assets/e2e/demo.spec.js' \
  FAKE_BIN="$FAKE_BIN" FIXTURES="$FIXTURES" LOG="$LOG" SHA="$SHA" CSS_MD5="$CSS_MD5" CSS_TEXT="$CSS_TEXT" \
  SUMMARY_PATHS="$SUMMARY_PATHS" \
  bash "$FAKE_ROOT/scripts/check_phase173_candidate.sh" > "$TEST_DIR/outer.out"
rg -q 'phase173 candidate worktree: /tmp/mailglass-phase173\.' "$TEST_DIR/outer.out"
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const entry = record.files.find((item) => item.path === "reference/demo_app/assets/e2e/demo.spec.js");
if (!entry || entry.status !== " M") throw new Error(`outer launcher did not preserve owner path/status metadata: ${JSON.stringify(record)}`);
NODE
rg -q 'git worktree add --detach' "$LOG"
if rg -q 'git (add |push |merge )|gh workflow run|docker compose.* down|worktree remove' "$LOG"; then
  printf 'FAIL: launcher attempted a prohibited GitHub write or retained-resource cleanup\n' >&2
  exit 1
fi

printf 'Phase 173 candidate fake-CLI contract passed (SHA, cleanliness, ancestry, owner dirt, HTTP/CSS, CI, retention, no remote writes).\n'
