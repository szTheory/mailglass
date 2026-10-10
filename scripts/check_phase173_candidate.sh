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

if [[ "${PHASE173_CANDIDATE_MODE:-false}" != "true" ]]; then
  cd "$REPO_ROOT"
  ORIGIN_SHA="$(git rev-parse HEAD)"
  ORIGIN_META="$EVIDENCE_DIR/origin-dirty-paths.json"
  mkdir -p "$EVIDENCE_DIR"
  git check-ignore -q -- "$ORIGIN_META" || fail "$ORIGIN_META must be ignored by git"

  git status --porcelain=v1 -z --untracked-files=all |
    node -e '
const fs = require("node:fs");
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const records = input.split("\0").filter(Boolean);
  const files = [];
  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    const status = record.slice(0, 2);
    const path = record.slice(3);
    files.push({ status, path });
    if (status.includes("R") || status.includes("C")) {
      const previousPath = records[++index];
      if (previousPath) files[files.length - 1].previousPath = previousPath;
    }
  }
  fs.writeFileSync(process.argv[1], JSON.stringify({
    schemaVersion: 1,
    capturedAt: new Date().toISOString(),
    originSha: process.argv[2],
    workspace: process.argv[3],
    files
  }, null, 2) + "\n");
});
' "$ORIGIN_META" "$ORIGIN_SHA" "$REPO_ROOT"

  RUN_PARENT="$(mktemp -d /tmp/mailglass-phase173.XXXXXXXX)"
  CANDIDATE_WORKTREE="$RUN_PARENT/candidate"
  git worktree add --detach "$CANDIDATE_WORKTREE" "$ORIGIN_SHA"
  [[ "$(git -C "$CANDIDATE_WORKTREE" rev-parse HEAD)" == "$ORIGIN_SHA" ]] ||
    fail "detached worktree HEAD differs from captured candidate SHA"
  [[ -z "$(git -C "$CANDIDATE_WORKTREE" status --porcelain=v1 --untracked-files=all)" ]] ||
    fail "new candidate worktree is not clean"

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
  printf 'phase173 original dirty path/status record: %s\n' "$ORIGIN_META"
  exit "$STATUS"
fi

SHA="${PHASE173_CANDIDATE_SHA:-}"
WORKTREE="${PHASE173_CANDIDATE_WORKTREE:-}"
ORIGIN_META="${PHASE173_ORIGIN_DIRTY_METADATA:-}"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || fail "candidate SHA must be a full 40-character commit"
[[ -n "$WORKTREE" && -n "$ORIGIN_META" ]] || fail "candidate mode needs worktree and dirty metadata paths"
[[ -d "$WORKTREE" ]] || fail "candidate worktree does not exist: $WORKTREE"
[[ -f "$ORIGIN_META" ]] || fail "original dirty path/status record is missing"
WORKTREE="$(cd "$WORKTREE" && pwd -P)"

cd "$WORKTREE"
ROOT_DIR="$(git rev-parse --show-toplevel)"
[[ "$ROOT_DIR" == "$WORKTREE" ]] || fail "candidate worktree path does not match its Git root (reported=$ROOT_DIR expected=$WORKTREE)"
[[ "$(git rev-parse HEAD)" == "$SHA" ]] || fail "candidate HEAD does not match requested SHA"
[[ -z "$(git status --porcelain=v1 --untracked-files=all)" ]] ||
  fail "candidate worktree is dirty before runtime evidence"

ORIGIN_META_REL="$EVIDENCE_REL/origin-dirty-paths.json"
DELIVERY_JSON="$ROOT_DIR/$EVIDENCE_REL/delivery-candidate.json"
git check-ignore -q -- "$DELIVERY_JSON" || fail "$DELIVERY_JSON must be ignored by git"
rg -q -e "\"originSha\"[[:space:]]*:[[:space:]]*\"$SHA\"" "$ORIGIN_META" ||
  fail "original dirty metadata does not identify the candidate SHA"
mkdir -p "$(dirname "$DELIVERY_JSON")"

declare -a FAILURES=()
declare -a OWNER_GAPS=()
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
for plan_file in "$PHASE_173_DIR/173-01-PLAN.md" "$PHASE_173_DIR/173-02-PLAN.md" "$PHASE_173_DIR/173-03-PLAN.md"; do
  git cat-file -e "$SHA:$plan_file" || fail "candidate is missing plan $plan_file"
  listed_files="$(sed -nE 's#^[[:space:]]*<files>(.*)</files>.*#\1#p' "$plan_file" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  while IFS= read -r listed_path; do
    [[ -n "$listed_path" ]] || continue
    [[ "$listed_path" == *"/tmp/demo_browser_evidence/"* ]] && continue
    git cat-file -e "$SHA:$listed_path" || fail "candidate is missing Phase 173 deliverable $listed_path"
  done <<< "$listed_files"
done

# Compare path/status-only owner metadata against prior accepted files and the
# Phase 173 plan inputs. Never read original dirty file contents.
ACCEPTANCE_PATHS=""
for summary_path in "${PRIOR_SUMMARIES[@]}"; do
  summary="$(git show "$SHA:$summary_path")"
  summary_paths="$(printf '%s\n' "$summary" | awk '
    /^key-files:/ { in_keys=1; next }
    in_keys && /^[^[:space:]]/ { exit }
    in_keys && /^[[:space:]]+- / { sub(/^[[:space:]]+- /, ""); print }
  ')"
  ACCEPTANCE_PATHS+="$summary_paths"$'\n'
done
for plan_file in "$PHASE_173_DIR/173-01-PLAN.md" "$PHASE_173_DIR/173-02-PLAN.md" "$PHASE_173_DIR/173-03-PLAN.md"; do
  ACCEPTANCE_PATHS+="$(sed -nE 's#^[[:space:]]*<files>(.*)</files>.*#\1#p' "$plan_file" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"$'\n'
done
while IFS=$'\t' read -r dirty_status dirty_path; do
  [[ -n "$dirty_path" ]] || continue
  if printf '%s\n' "$ACCEPTANCE_PATHS" | rg -F -x -q -- "$dirty_path"; then
    OWNER_GAPS+=("$dirty_status $dirty_path")
  fi
done < <(node - "$ORIGIN_META" <<'NODE'
const fs = require("node:fs");
const metadata = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
for (const file of metadata.files || []) {
  console.log(`${file.status}\t${file.path}`);
}
NODE
)

# Run the phase regression gate from the clean candidate only.
if [[ "${PHASE173_SKIP_LOCAL_CHECKS:-false}" != "true" ]]; then
  if bash scripts/gsd-regression-gate.sh; then
    REGRESSION_STATUS="passed"
  else
    REGRESSION_STATUS="failed"
    FAILURES+=("candidate regression gate failed")
  fi

  if (cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix verify.preview); then
    ASSET_STATUS="passed"
  else
    ASSET_STATUS="failed"
    FAILURES+=("pinned-toolchain mix verify.preview failed")
  fi
else
  REGRESSION_STATUS="skipped-test-mode"
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

[[ -n "${ADVISORY_JSON:-}" ]] || ADVISORY_JSON='[]'
if ((${#OWNER_GAPS[@]} > 0)); then
  for owner_gap in "${OWNER_GAPS[@]}"; do FAILURES+=("required acceptance input remains owner-dirty: $owner_gap"); done
fi

FINAL_STATUS="incomplete"
if [[ "$PREVIEW_STATUS" == passed && "$CI_STATUS" == passed && "$REGRESSION_STATUS" == passed && "$ASSET_STATUS" != failed && ${#OWNER_GAPS[@]} -eq 0 && ${#FAILURES[@]} -eq 0 ]]; then
  FINAL_STATUS="passed"
fi

node - "$DELIVERY_JSON" "$FINAL_STATUS" "$SHA" "$WORKTREE" "$REVIEW_PROJECT" "$HTTP_PORT" "$DB_PORT" "$PREVIEW_URL" "$PREVIEW_STATUS" "$CI_STATUS" "$CI_RUN_ID" "$CI_URL" "$REGRESSION_STATUS" "$ASSET_STATUS" "$SERVED_CSS_PATH" "$SOURCE_CSS_SHA256" "$BUILT_CSS_SHA256" "$SERVED_CSS_SHA256" "$ORIGIN_META" "$ADVISORY_JSON" "$(printf '%s\n' "${OWNER_GAPS[@]:-}")" "$(printf '%s\n' "${FAILURES[@]:-}")" <<'NODE'
const fs = require("node:fs");
const [output, status, candidateSha, worktree, reviewProject, httpPort, dbPort, previewUrl,
  previewStatus, ciStatus, ciRunId, ciUrl, regressionStatus, assetStatus, servedCssPath,
  sourceCssSha256, builtCssSha256, servedCssSha256, originMetadata, advisoryJson,
  ownerGapsRaw, failuresRaw] = process.argv.slice(2);
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
  advisoryJobs: JSON.parse(advisoryJson || "[]"),
  localChecks: { regression: regressionStatus, previewAssets: assetStatus },
  originalWorkspace: { sha: original.originSha, excludedDirtyPaths: original.files || [] },
  requiredOwnerDirtyPaths: (ownerGapsRaw || "").split("\n").filter(Boolean),
  failures: (failuresRaw || "").split("\n").filter(Boolean),
  cleanup: {
    compose: `docker compose -p "${reviewProject}" -f "${worktree}/compose.demo.yml" down`,
    worktree: `git worktree remove "${worktree}"`,
    parent: `rmdir "${require("node:path").dirname(worktree)}"`
  },
  artifactDirectory: "reference/demo_app/tmp/demo_browser_evidence/",
  artifactRetention: "14 days advisory",
  capturedAt: new Date().toISOString()
};
fs.writeFileSync(output, JSON.stringify(record, null, 2) + "\n");
console.log(JSON.stringify({ status, candidateSha, previewUrl: record.previewUrl, ci: record.requiredCi, reviewProject, candidateWorktree: worktree, failures: record.failures }));
NODE

if [[ "$FINAL_STATUS" != passed ]]; then exit 1; fi
