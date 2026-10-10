#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_REL="reference/demo_app/tmp/demo_browser_evidence"
EVIDENCE_DIR="$REPO_ROOT/$EVIDENCE_REL"

fail() {
  printf 'phase173 candidate gate: %s\n' "$*" >&2
  exit 1
}

assert_candidate_clean() {
  local dirty
  dirty="$(git status --porcelain=v1 --untracked-files=all -- . \
    ':(exclude)reference/demo_app/README.md' \
    ':(exclude)reference/demo_app/assets/e2e/demo.spec.js')"
  [[ -z "$dirty" ]] || fail "candidate worktree has tracked or untracked changes outside the protected exclusions: $dirty"
}

restore_candidate_demo_lock() {
  local lock_path="reference/demo_app/mix.lock"
  local expected actual
  expected="$(git rev-parse "$SHA:$lock_path")" || fail "candidate demo lockfile is missing at the captured SHA"
  if ! git diff --quiet -- "$lock_path"; then
    git restore --worktree -- "$lock_path" || fail "could not restore candidate-generated demo lockfile changes"
  fi
  actual="$(git hash-object "$lock_path")" || fail "could not verify candidate demo lockfile"
  [[ "$actual" == "$expected" ]] || fail "candidate demo lockfile differs from its captured SHA after restore"
}

if [[ "${PHASE173_CANDIDATE_MODE:-false}" != "true" ]]; then
  cd "$REPO_ROOT"
  ORIGIN_SHA="$(git rev-parse HEAD)"
  ORIGIN_META="$EVIDENCE_DIR/origin-dirty-paths.json"
  mkdir -p "$EVIDENCE_DIR"
  git check-ignore -q -- "$ORIGIN_META" || fail "$ORIGIN_META must be ignored by git"
  node - "$ORIGIN_META" "$ORIGIN_SHA" "$REPO_ROOT" "$SCRIPT_DIR/phase173_json_output.cjs" <<'NODE'
const fs = require("node:fs");
const [output, originSha, workspace, writerPath] = process.argv.slice(2);
const { writeJson } = require(writerPath);
writeJson(output, {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  originSha,
  workspace,
  dirtyInventory: { status: "not-collected", reason: "protected-path fence" }
}, workspace);
NODE

  RUN_PARENT="$(mktemp -d /tmp/mailglass-phase173.XXXXXXXX)"
  CANDIDATE_WORKTREE="$RUN_PARENT/candidate"
  git worktree add --detach --no-checkout "$CANDIDATE_WORKTREE" "$ORIGIN_SHA"
  printf '%s\n' '/*' '!/reference/demo_app/README.md' '!/reference/demo_app/assets/e2e/demo.spec.js' |
    git -C "$CANDIDATE_WORKTREE" sparse-checkout set --no-cone --no-sparse-index --stdin ||
    fail "could not establish protected-path sparse exclusions"
  [[ "$(git -C "$CANDIDATE_WORKTREE" rev-parse HEAD)" == "$ORIGIN_SHA" ]] ||
    fail "no-checkout worktree HEAD differs from captured candidate SHA"
  git -C "$CANDIDATE_WORKTREE" checkout --detach "$ORIGIN_SHA" ||
    fail "could not materialize exact-SHA candidate after sparse exclusions"
  [[ "$(git -C "$CANDIDATE_WORKTREE" rev-parse HEAD)" == "$ORIGIN_SHA" ]] ||
    fail "detached worktree HEAD differs from captured candidate SHA"
  [[ -z "$(git -C "$CANDIDATE_WORKTREE" status --porcelain=v1 --untracked-files=all -- . \
    ':(exclude)reference/demo_app/README.md' \
    ':(exclude)reference/demo_app/assets/e2e/demo.spec.js')" ]] ||
    fail "new candidate worktree is not clean"

  # Validate the exact pinned baseline set before transferring any bytes into
  # the isolated candidate. Only validated PNG buffers are copied; no evidence
  # directory, source, manifest, README, or owner workspace content is cloned.
  if ! node - "$EVIDENCE_DIR" "$CANDIDATE_WORKTREE/$EVIDENCE_REL" "$ORIGIN_SHA" "$SCRIPT_DIR/phase173_json_output.cjs" <<'NODE'
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const [sourceRoot, candidateRoot, candidateSha, writerPath] = process.argv.slice(2);
const { writeJson } = require(writerPath);
const validator = require(path.resolve(sourceRoot, "../../assets/scripts/check-demo-browser-evidence.cjs"));
const outputPath = path.join(sourceRoot, "delivery-candidate.json");
try {
  const pinned = validator.validatePinnedBaselines(sourceRoot);
  const resolvedSource = fs.realpathSync(sourceRoot);
  const resolvedCandidateParent = path.dirname(candidateRoot);
  const candidateRootResolved = path.resolve(candidateRoot);
  if (!candidateRootResolved.startsWith(`${resolvedCandidateParent}${path.sep}`)) {
    throw new Error("candidate evidence destination escapes its detached worktree");
  }
  fs.mkdirSync(candidateRoot, { recursive: true });
  const targetRoot = fs.lstatSync(candidateRoot);
  if (!targetRoot.isDirectory() || targetRoot.isSymbolicLink()) {
    throw new Error("candidate evidence destination is not a regular directory");
  }
  for (const expected of pinned) {
    const sourcePath = path.resolve(resolvedSource, expected.path);
    if (!sourcePath.startsWith(`${resolvedSource}${path.sep}`)) throw new Error(`baseline path escapes evidence directory: ${expected.path}`);
    const sourceStat = fs.lstatSync(sourcePath);
    if (!sourceStat.isFile() || sourceStat.isSymbolicLink()) throw new Error(`baseline is not a regular file: ${expected.path}`);
    const bytes = fs.readFileSync(sourcePath);
    const digest = crypto.createHash("sha256").update(bytes).digest("hex");
    if (digest !== expected.sha256) throw new Error(`baseline changed after validation: ${expected.path}`);
    const destination = path.join(candidateRoot, expected.path);
    if (!destination.startsWith(`${candidateRootResolved}${path.sep}`)) throw new Error(`candidate baseline escapes evidence directory: ${expected.path}`);
    let destinationExists = false;
    try {
      fs.lstatSync(destination);
      destinationExists = true;
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
    if (destinationExists || fs.lstatSync(path.dirname(destination)).isSymbolicLink()) {
      throw new Error(`candidate baseline destination already exists or traverses a symlink: ${expected.path}`);
    }
    fs.writeFileSync(destination, bytes, { flag: "wx" });
  }
} catch (error) {
  writeJson(outputPath, {
    schemaVersion: 1,
    status: "incomplete",
    candidateSha,
    baselineValidation: "failed",
    failures: [error.message],
    artifactDirectory: "reference/demo_app/tmp/demo_browser_evidence/"
  }, path.resolve(sourceRoot, "../../../.."));
  console.error(error.message);
  process.exitCode = 1;
}
NODE
  then
    fail "pinned baseline validation or transfer failed; see $EVIDENCE_DIR/delivery-candidate.json"
  fi

  set +e
  (
    cd "$CANDIDATE_WORKTREE"
    PHASE173_CANDIDATE_MODE=true \
      PHASE173_CANDIDATE_SHA="$ORIGIN_SHA" \
      PHASE173_CANDIDATE_WORKTREE="$CANDIDATE_WORKTREE" \
      PHASE173_ORIGIN_DIRTY_METADATA="$ORIGIN_META" \
      bash scripts/check_phase173_candidate.sh
  )
  STATUS=$?
  set -e
  printf 'phase173 candidate worktree: %s\n' "$CANDIDATE_WORKTREE"
  printf 'phase173 original SHA-only metadata record: %s\n' "$ORIGIN_META"
  exit "$STATUS"
fi

SHA="${PHASE173_CANDIDATE_SHA:-}"
WORKTREE="${PHASE173_CANDIDATE_WORKTREE:-}"
ORIGIN_META="${PHASE173_ORIGIN_DIRTY_METADATA:-}"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || fail "candidate SHA must be a full 40-character commit"
[[ -n "$WORKTREE" && -n "$ORIGIN_META" ]] || fail "candidate mode needs worktree and dirty metadata paths"
[[ -d "$WORKTREE" ]] || fail "candidate worktree does not exist: $WORKTREE"
[[ -f "$ORIGIN_META" ]] || fail "original SHA metadata record is missing"
WORKTREE="$(cd "$WORKTREE" && pwd -P)"

cd "$WORKTREE"
ROOT_DIR="$(git rev-parse --show-toplevel)"
[[ "$ROOT_DIR" == "$WORKTREE" ]] || fail "candidate worktree path does not match its Git root (reported=$ROOT_DIR expected=$WORKTREE)"
[[ "$(git rev-parse HEAD)" == "$SHA" ]] || fail "candidate HEAD does not match requested SHA"
assert_candidate_clean

ORIGIN_META_REL="$EVIDENCE_REL/origin-dirty-paths.json"
DELIVERY_JSON="$ROOT_DIR/$EVIDENCE_REL/delivery-candidate.json"
git check-ignore -q -- "$DELIVERY_JSON" || fail "$DELIVERY_JSON must be ignored by git"
rg -q -e "\"originSha\"[[:space:]]*:[[:space:]]*\"$SHA\"" "$ORIGIN_META" ||
  fail "original dirty metadata does not identify the candidate SHA"
mkdir -p "$(dirname "$DELIVERY_JSON")"

declare -a FAILURES=()
declare -a PRIOR_SUMMARIES=()
declare -a ADVISORY_JOBS=()
declare -a CI_JOBS=()
REGRESSION_STATUS="not-run"
ASSET_STATUS="not-needed"
PREVIEW_STATUS="not-started"
CI_STATUS="missing"
CI_URL=""
CI_RUN_ID=""
REVIEW_PROJECT=""
EVIDENCE_STATUS="not-run"
HTTP_PORT=""
DB_PORT=""
PREVIEW_URL=""
SOURCE_CSS_SHA256=""
BUILT_CSS_SHA256=""
SERVED_CSS_SHA256=""
SERVED_CSS_PATH=""

for mapping in 168:10 169:5 170:8 171:4 172:3; do
  phase="${mapping%%:*}"
  expected="${mapping##*:}"
  summaries="$(git ls-tree -r --name-only "$SHA" .planning/phases | rg "^\.planning/phases/${phase}-[^/]+/${phase}-[^/]+-SUMMARY\.md$" || true)"
  count="$(printf '%s\n' "$summaries" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" == "$expected" ]] || fail "Phase $phase has $count committed summaries at $SHA; expected $expected"

  while IFS= read -r summary_path; do
    [[ -n "$summary_path" ]] || continue
    PRIOR_SUMMARIES+=("$summary_path")
    summary="$(git show "$SHA:$summary_path")" || fail "cannot read committed summary $summary_path"
    task_section="$(printf '%s\n' "$summary" | awk '/^## Task Commits/{inside=1; next} /^## /{inside=0} inside')"
    task_commits="$(printf '%s\n' "$task_section" | grep -oE '(^|[^[:alnum:]])[0-9a-f]{7,40}([^[:alnum:]]|$)' | tr -cd '0-9a-f\n' || true)"
    if [[ -z "$task_commits" ]]; then
      task_commits="$(printf '%s\n' "$summary" | grep -oE '(^|[^[:alnum:]])[0-9a-f]{7,40}([^[:alnum:]]|$)' | tr -cd '0-9a-f\n' || true)"
    fi
    [[ -n "$task_commits" ]] || fail "committed summary has no verifiable commit references: $summary_path"
    while IFS= read -r task_sha; do
      [[ -n "$task_sha" ]] || continue
      git merge-base --is-ancestor "$task_sha" "$SHA" ||
        fail "Phase task commit $task_sha from $summary_path is missing from candidate ancestry"
    done <<< "$task_commits"
  done <<< "$summaries"
done

# Every tracked deliverable listed in the Phase 173 plans must exist at this SHA.
PHASE_173_DIR=".planning/phases/173-consistency-and-delivery-evidence"
for plan_file in "$PHASE_173_DIR/173-01-PLAN.md" "$PHASE_173_DIR/173-02-PLAN.md" "$PHASE_173_DIR/173-03-PLAN.md" "$PHASE_173_DIR/173-04-PLAN.md" "$PHASE_173_DIR/173-05-PLAN.md" "$PHASE_173_DIR/173-06-PLAN.md"; do
  git cat-file -e "$SHA:$plan_file" || fail "candidate is missing plan $plan_file"
  listed_files="$(sed -nE 's#^[[:space:]]*<files>(.*)</files>.*#\1#p' "$plan_file" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  while IFS= read -r listed_path; do
    [[ -n "$listed_path" ]] || continue
    [[ "$listed_path" == "reference/demo_app/README.md" ]] && continue
    [[ "$listed_path" == "reference/demo_app/assets/e2e/demo.spec.js" ]] && continue
    [[ "$listed_path" == *"/tmp/demo_browser_evidence/"* ]] && continue
    git cat-file -e "$SHA:$listed_path" || fail "candidate is missing Phase 173 deliverable $listed_path"
  done <<< "$listed_files"
done

# Run the phase regression gate from the clean candidate only.
if [[ "${PHASE173_SKIP_LOCAL_CHECKS:-false}" != "true" ]]; then
  # A fresh detached worktree has no ignored Mix/npm install directories. Restore
  # the existing exact-lock dependencies needed by the regression suites; this
  # does not add or update dependencies.
  if ! (
    ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix deps.get --check-locked &&
    (cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix deps.get --check-locked) &&
    (cd mailglass_inbound && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix deps.get --check-locked) &&
    (cd mailglass_admin && npm ci --no-audit --no-fund)
  ); then
    REGRESSION_STATUS="failed"
    FAILURES+=("exact-lock candidate dependency setup failed")
  elif bash scripts/gsd-regression-gate.sh; then
    REGRESSION_STATUS="passed"
  else
    REGRESSION_STATUS="failed"
    FAILURES+=("candidate regression gate failed")
  fi

  # Run the pinned preview asset check only when this phase changed Admin
  # source or generated assets. The phase summary records a stable comparison
  # point for clean detached candidate worktrees.
  PHASE_BASE_SHA="$(git show "$SHA:$PHASE_173_DIR/173-01-SUMMARY.md" | sed -nE 's/^plan_head_before:[[:space:]]*([0-9a-f]{40})$/\1/p' | head -n 1)"
  [[ "$PHASE_BASE_SHA" =~ ^[0-9a-f]{40}$ ]] ||
    fail "Phase 173 starting SHA is missing from 173-01-SUMMARY.md"
  git merge-base --is-ancestor "$PHASE_BASE_SHA" "$SHA" ||
    fail "Phase 173 starting SHA is not an ancestor of the candidate"
  ADMIN_ASSET_CHANGES="$(git diff --name-only "$PHASE_BASE_SHA" "$SHA" -- mailglass_admin/assets mailglass_admin/priv/static)"
  if [[ -n "$ADMIN_ASSET_CHANGES" ]]; then
    if (cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix verify.preview); then
      ASSET_STATUS="passed"
    else
      ASSET_STATUS="failed"
      FAILURES+=("pinned-toolchain mix verify.preview failed")
    fi
  else
    ASSET_STATUS="not-run-unchanged"
  fi
else
  REGRESSION_STATUS="skipped-test-mode"
  ASSET_STATUS="skipped-test-mode"
fi

if ! command -v docker >/dev/null 2>&1; then
  PREVIEW_STATUS="unavailable"
  FAILURES+=("Docker CLI is unavailable")
else
  read -r HTTP_PORT DB_PORT < <(python3 - <<'PY'
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
  [[ "$HTTP_PORT" =~ ^[0-9]+$ && "$DB_PORT" =~ ^[0-9]+$ && "$HTTP_PORT" != "$DB_PORT" ]] || fail "could not allocate unique review ports"
  [[ "$HTTP_PORT" != 4015 && "$HTTP_PORT" != 5415 && "$DB_PORT" != 4015 && "$DB_PORT" != 5415 ]] ||
    fail "review port selection collided with a demo default"
  RUN_SUFFIX="$(date -u +%Y%m%d%H%M%S)-$$-$RANDOM"
  REVIEW_PROJECT="mailglass-phase173-review-${SHA:0:8}-$RUN_SUFFIX"
  PREVIEW_URL="http://127.0.0.1:$HTTP_PORT"
  compose() {
    MAILGLASS_DEMO_HTTP_PORT="$HTTP_PORT" MAILGLASS_DEMO_DB_PORT="$DB_PORT" \
      docker compose -p "$REVIEW_PROJECT" -f "$ROOT_DIR/compose.demo.yml" "$@"
  }
  if compose up --build --detach --wait --wait-timeout 600 demo; then
    restore_candidate_demo_lock
    TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-phase173-probe.XXXXXX")"
    route_failure=false
    for route in / /health /dev/mail /dev/mail/gallery /dev/storybook/primitives/nav_link?variation_id=long_label; do
      status="$(curl --silent --show-error --location --output "$TMP_DIR/route.html" --write-out '%{http_code}' --max-time 30 "$PREVIEW_URL$route" 2>/dev/null || true)"
      if [[ "$status" != 200 ]]; then
        route_failure=true
        FAILURES+=("HTTP route $route returned ${status:-no-response}")
      fi
    done
    if [[ "$route_failure" == false ]]; then
      curl --silent --show-error --location --fail --output "$TMP_DIR/preview.html" --max-time 30 "$PREVIEW_URL/dev/mail" || {
        route_failure=true
        FAILURES+=("preview HTML could not be fetched")
      }
    fi
    if [[ "$route_failure" == false ]]; then
      SERVED_CSS_PATH="$(node - "$TMP_DIR/preview.html" <<'NODE'
const fs = require("node:fs");
const html = fs.readFileSync(process.argv[2], "utf8");
const match = html.match(/href=["']([^"']*\/dev\/mail\/css-[a-f0-9]{32})["']/);
if (match) process.stdout.write(match[1]);
NODE
      )"
      [[ "$SERVED_CSS_PATH" == /dev/mail/css-* ]] || {
        route_failure=true
        FAILURES+=("preview HTML has no versioned mount-rooted Admin CSS link")
      }
    fi
    if [[ "$route_failure" == false ]]; then
      curl --silent --show-error --location --fail --output "$TMP_DIR/served.css" --max-time 30 "$PREVIEW_URL$SERVED_CSS_PATH" || {
        route_failure=true
        FAILURES+=("versioned Admin CSS route could not be fetched")
      }
    fi
    if [[ "$route_failure" == false ]]; then
      read -r SOURCE_CSS_SHA256 BUILT_CSS_SHA256 SERVED_CSS_SHA256 < <(node - "$ROOT_DIR" "$TMP_DIR/served.css" <<'NODE'
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const served = process.argv[3];
const hash = (data) => crypto.createHash("sha256").update(data).digest("hex");
process.stdout.write([
  hash(fs.readFileSync(path.join(root, "mailglass_admin/assets/css/app.css"))),
  hash(fs.readFileSync(path.join(root, "mailglass_admin/priv/static/app.css"))),
  hash(fs.readFileSync(served))
].join(" ") + "\n");
NODE
      )
      if [[ "$BUILT_CSS_SHA256" != "$SERVED_CSS_SHA256" ]]; then
        route_failure=true
        FAILURES+=("served Admin CSS bytes differ from the candidate bundle")
      fi
    fi
    rm -rf "$TMP_DIR"
    if [[ "$route_failure" == false ]]; then PREVIEW_STATUS="passed"; else PREVIEW_STATUS="failed"; fi
  else
    PREVIEW_STATUS="failed"
    FAILURES+=("isolated review Compose project did not become healthy")
  fi
fi

# Read-only exact-SHA GitHub query. Browser/capture jobs remain advisory.
if command -v gh >/dev/null 2>&1; then
  if run_json="$(gh run list --commit "$SHA" --workflow CI --limit 100 --json databaseId,headSha,status,conclusion,workflowName,url,event 2>/dev/null)"; then
    CI_RUN_ID="$(printf '%s' "$run_json" | node -e '
let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const sha = process.argv[1];
  const runs = JSON.parse(input);
  const matching = runs.find((run) => run.headSha === sha && run.workflowName === "CI");
  if (matching) process.stdout.write(String(matching.databaseId));
});
' "$SHA")"
    if [[ -n "$CI_RUN_ID" ]]; then
      view_json="$(gh run view "$CI_RUN_ID" --json databaseId,headSha,status,conclusion,url,workflowName,event,jobs 2>/dev/null || true)"
      if [[ -n "$view_json" ]]; then
        ci_result="$(printf '%s' "$view_json" | node -e '
let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const sha = process.argv[1];
  const run = JSON.parse(input);
  const required = (run.jobs || []).find((job) => job.name === "CI Green");
  const advisory = (run.jobs || []).filter((job) => /browser|capture/i.test(job.name));
  const result = {
    exact: run.headSha === sha,
    green: Boolean(required && required.conclusion === "success"),
    url: run.url || "",
    advisory
  };
  process.stdout.write(JSON.stringify(result));
});
' "$SHA")"
        CI_STATUS="$(node -e 'const x=JSON.parse(process.argv[1]); process.stdout.write(x.exact && x.green ? "passed" : "failed")' "$ci_result")"
        CI_URL="$(node -e 'const x=JSON.parse(process.argv[1]); process.stdout.write(x.url)' "$ci_result")"
        ADVISORY_JSON="$(node -e 'const x=JSON.parse(process.argv[1]); process.stdout.write(JSON.stringify(x.advisory))' "$ci_result")"
        if [[ "$CI_STATUS" != passed ]]; then FAILURES+=("required CI Green is not successful for the exact candidate SHA"); fi
      else
        CI_STATUS="missing"
        FAILURES+=("could not read exact-SHA CI run jobs")
      fi
    else
      CI_STATUS="missing"
      FAILURES+=("no successful CI workflow run exists for the exact candidate SHA")
    fi
  else
    CI_STATUS="unavailable"
    FAILURES+=("GitHub run read access is unavailable")
  fi
else
  CI_STATUS="unavailable"
  FAILURES+=("gh CLI is unavailable for read-only CI verification")
fi

# Capture fresh synthetic evidence in its own disposable Compose project, then
# independently validate the sanitized retained checkpoint and every PNG byte.
if DEMO_CANDIDATE_REVISION="$SHA" bash scripts/run_demo_browser_evidence.sh; then
  WRAPPER_STATUS="passed"
else
  WRAPPER_STATUS="failed"
  FAILURES+=("focused disposable browser evidence wrapper failed")
fi
restore_candidate_demo_lock
assert_candidate_clean
if EVIDENCE_ERROR="$(node - "$ROOT_DIR/$EVIDENCE_REL" "$SHA" 2>&1 <<'NODE'
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const [rootArg, candidateSha] = process.argv.slice(2);
const root = path.resolve(rootArg);
const checker = require(path.join(root, "../..", "assets/scripts/check-demo-browser-evidence.cjs"));
const hash = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
function regularOwnedFile(relative) {
  if (typeof relative !== "string" || !relative.startsWith("captures/")) throw new Error(`unsafe capture path: ${relative}`);
  const full = path.resolve(root, relative);
  if (!full.startsWith(`${root}${path.sep}`)) throw new Error(`capture path escapes evidence root: ${relative}`);
  let cursor = root;
  for (const part of relative.split("/")) {
    cursor = path.join(cursor, part);
    const stat = fs.lstatSync(cursor);
    if (stat.isSymbolicLink()) throw new Error(`symlinked evidence path: ${relative}`);
    if (cursor !== full && !stat.isDirectory()) throw new Error(`unsafe evidence path component: ${relative}`);
  }
  const stat = fs.lstatSync(full);
  if (!stat.isFile()) throw new Error(`evidence path is not a regular file: ${relative}`);
  return full;
}
try {
  const checkpointPath = path.join(root, "retained/checkpoint.json");
  const retainedRoot = fs.lstatSync(path.join(root, "retained"));
  if (!retainedRoot.isDirectory() || retainedRoot.isSymbolicLink()) throw new Error("retained evidence directory is missing or unsafe");
  const stat = fs.lstatSync(checkpointPath);
  if (!stat.isFile() || stat.isSymbolicLink()) throw new Error("retained checkpoint is missing or unsafe");
  const checkpoint = JSON.parse(fs.readFileSync(checkpointPath, "utf8"));
  if (checkpoint.status !== "passed") throw new Error(`retained checkpoint status is ${checkpoint.status || "missing"}`);
  if (checkpoint.candidate_revision !== candidateSha) throw new Error("retained checkpoint candidate SHA is stale");
  if (checkpoint.candidate_dirty !== false) throw new Error("retained checkpoint does not prove a clean candidate");
  if (!Array.isArray(checkpoint.captures) || checkpoint.captures.length !== checker.EXPECTED_BASELINES.length) {
    throw new Error("retained checkpoint does not contain all six synthetic captures");
  }
  if (checkpoint.captures.some((capture) => !capture || capture.candidate_dirty !== false)) {
    throw new Error("retained captures do not all prove a clean candidate");
  }
  checker.validatePinnedBaselines(root);
  const seen = new Set();
  const retainedExpected = new Set(["checkpoint.json"]);
  for (const capture of checkpoint.captures) {
    const baseline = checker.EXPECTED_BASELINES.find((item) => item.captureId === capture.id);
    if (!baseline || seen.has(capture.id)) throw new Error(`unknown or duplicate retained capture: ${capture.id}`);
    seen.add(capture.id);
    if (!capture.before_after || capture.before_after.baseline_path !== baseline.path || capture.before_after.baseline_sha256 !== baseline.sha256) {
      throw new Error(`retained capture has stale baseline provenance: ${capture.id}`);
    }
    const currentPath = regularOwnedFile(capture.path);
    const currentBytes = fs.readFileSync(currentPath);
    if (!currentBytes.subarray(0, signature.length).equals(signature) || hash(currentBytes) !== capture.sha256) {
      throw new Error(`current capture bytes do not match checkpoint: ${capture.id}`);
    }
    const currentRelative = `${capture.id}-current.png`;
    const baselineRelative = `${capture.id}-baseline.png`;
    retainedExpected.add(currentRelative);
    retainedExpected.add(baselineRelative);
    for (const relative of [currentRelative, baselineRelative]) {
      const full = path.join(root, "retained", relative);
      const entry = fs.lstatSync(full);
      if (!entry.isFile() || entry.isSymbolicLink()) throw new Error(`retained PNG is missing or unsafe: ${relative}`);
      const bytes = fs.readFileSync(full);
      if (!bytes.subarray(0, signature.length).equals(signature)) throw new Error(`retained file is not a PNG: ${relative}`);
      if (relative === currentRelative && (hash(bytes) !== capture.sha256 || !bytes.equals(currentBytes))) {
        throw new Error(`retained current PNG changed: ${relative}`);
      }
      if (relative === baselineRelative && (hash(bytes) !== baseline.sha256 || !bytes.equals(fs.readFileSync(path.join(root, baseline.path))))) {
        throw new Error(`retained baseline PNG changed: ${relative}`);
      }
    }
  }
  const actualNames = fs.readdirSync(path.join(root, "retained")).sort();
  const expectedNames = [...retainedExpected].sort();
  if (JSON.stringify(actualNames) !== JSON.stringify(expectedNames)) throw new Error("retained evidence contains missing or unallowlisted files");
  console.log("retained synthetic evidence passed exact SHA, clean state, six PNG pairs and byte hashes");
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
NODE
  )"; then
  [[ -n "$EVIDENCE_ERROR" ]] && printf '%s\n' "$EVIDENCE_ERROR"
  EVIDENCE_STATUS="passed"
else
  EVIDENCE_STATUS="incomplete"
  EVIDENCE_ERROR="${EVIDENCE_ERROR##*$'\n'}"
  FAILURES+=("retained evidence validation failed: ${EVIDENCE_ERROR:-no checkpoint output}")
fi

[[ -n "${ADVISORY_JSON:-}" ]] || ADVISORY_JSON='[]'
OWNER_ACCEPTANCE_STATUS="unverified"
FAILURES+=("protected owner acceptance remains unverified")

FINAL_STATUS="incomplete"
if [[ "$PREVIEW_STATUS" == passed && "$CI_STATUS" == passed && "$REGRESSION_STATUS" == passed && "$ASSET_STATUS" != failed && "$EVIDENCE_STATUS" == passed && "$OWNER_ACCEPTANCE_STATUS" == accepted && ${#FAILURES[@]} -eq 0 ]]; then
  FINAL_STATUS="passed"
fi

node - "$DELIVERY_JSON" "$FINAL_STATUS" "$SHA" "$WORKTREE" "$REVIEW_PROJECT" "$HTTP_PORT" "$DB_PORT" "$PREVIEW_URL" "$PREVIEW_STATUS" "$CI_STATUS" "$CI_RUN_ID" "$CI_URL" "$REGRESSION_STATUS" "$ASSET_STATUS" "$EVIDENCE_STATUS" "$SERVED_CSS_PATH" "$SOURCE_CSS_SHA256" "$BUILT_CSS_SHA256" "$SERVED_CSS_SHA256" "$ORIGIN_META" "$ADVISORY_JSON" "$OWNER_ACCEPTANCE_STATUS" "$(printf '%s\n' "${FAILURES[@]:-}")" "$SCRIPT_DIR/phase173_json_output.cjs" <<'NODE'
const fs = require("node:fs");
const [output, status, candidateSha, worktree, reviewProject, httpPort, dbPort, previewUrl,
  previewStatus, ciStatus, ciRunId, ciUrl, regressionStatus, assetStatus, evidenceStatus, servedCssPath,
  sourceCssSha256, builtCssSha256, servedCssSha256, originMetadata, advisoryJson,
  ownerAcceptanceStatus, failuresRaw, writerPath] = process.argv.slice(2);
const { writeJson } = require(writerPath);
const original = JSON.parse(fs.readFileSync(originMetadata, "utf8"));
const record = {
  schemaVersion: 1,
  status,
  candidateSha,
  candidateWorktree: worktree,
  reviewProject,
  ports: { http: Number(httpPort) || null, database: Number(dbPort) || null },
  previewUrl: previewUrl ? `${previewUrl}/dev/mail` : null,
  readiness: { status: previewStatus, routes: ["/", "/health", "/dev/mail", "/dev/mail/gallery", "/dev/storybook/primitives/nav_link?variation_id=long_label"] },
  assets: {
    source: { path: "mailglass_admin/assets/css/app.css", sha256: sourceCssSha256 || null },
    built: { path: "mailglass_admin/priv/static/app.css", sha256: builtCssSha256 || null },
    served: { path: servedCssPath || null, sha256: servedCssSha256 || null }
  },
  requiredCi: { status: ciStatus, workflow: "CI", job: "CI Green", runId: ciRunId || null, url: ciUrl || null, headSha: candidateSha },
  ownerAcceptance: { status: ownerAcceptanceStatus },
  advisoryJobs: JSON.parse(advisoryJson || "[]"),
  localChecks: { regression: regressionStatus, previewAssets: assetStatus },
  browserEvidence: { status: evidenceStatus, sanitizedPath: `${"reference/demo_app/tmp/demo_browser_evidence"}/retained/` },
  originalWorkspace: { sha: original.originSha, dirtyInventory: original.dirtyInventory },
  failures: (failuresRaw || "").split("\n").filter(Boolean),
  cleanup: {
    compose: `docker compose -p "${reviewProject}" -f "${worktree}/compose.demo.yml" down`,
    worktree: `git worktree remove "${worktree}"`,
    parent: `rmdir "${require("node:path").dirname(worktree)}"`
  },
  artifactDirectory: "reference/demo_app/tmp/demo_browser_evidence/",
  uploadableArtifactDirectory: "reference/demo_app/tmp/demo_browser_evidence/retained/",
  artifactRetention: "14 days advisory",
  capturedAt: new Date().toISOString()
};
writeJson(output, record, process.cwd());
console.log(JSON.stringify({ status, candidateSha, previewUrl: record.previewUrl, ci: record.requiredCi, reviewProject, candidateWorktree: worktree, failures: record.failures }));
NODE

if [[ "$FINAL_STATUS" != passed ]]; then exit 1; fi
