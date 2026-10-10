#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_BIN_DIR="$(dirname "$(node -p 'process.execPath')")"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/phase173-candidate-contract.XXXXXX")"
FAKE_BIN="$TEST_DIR/bin"
FAKE_ROOT="$TEST_DIR/candidate"
FIXTURES="$TEST_DIR/fixtures"
SPARSE_REPO="$TEST_DIR/sparse-origin"
SPARSE_WORKTREE="$TEST_DIR/sparse-worktree"
LOG="$TEST_DIR/cli.log"
SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
CSS_TEXT=".candidate { color: #123456; }"
CSS_MD5="$(printf '%s' "$CSS_TEXT" | md5 -q 2>/dev/null || printf '%s' "$CSS_TEXT" | md5sum | cut -d ' ' -f1)"

cleanup() {
  if [[ -d "$SPARSE_REPO/.git" ]]; then
    git -C "$SPARSE_REPO" worktree remove --force "$SPARSE_WORKTREE" >/dev/null 2>&1 || true
  fi
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT
mkdir -p "$FAKE_BIN" "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence" "$FAKE_ROOT/scripts" \
  "$FAKE_ROOT/mailglass_admin/assets/css" "$FAKE_ROOT/mailglass_admin/priv/static" \
  "$FAKE_ROOT/mailglass_inbound" \
  "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence" \
  "$FAKE_ROOT/reference/demo_app/assets/scripts" "$FIXTURES"
cp "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs" \
  "$FAKE_ROOT/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"
cp "$ROOT_DIR/scripts/phase173_json_output.cjs" "$FAKE_ROOT/scripts/phase173_json_output.cjs"
cp "$ROOT_DIR/scripts/phase173_json_output.py" "$FAKE_ROOT/scripts/phase173_json_output.py"
node - "$ROOT_DIR" "$FAKE_ROOT" "$FIXTURES" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const [sourceRoot, fakeRoot, fixtures] = process.argv.slice(2);
const checker = require(path.join(sourceRoot, "reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"));
const sourceEvidence = path.join(sourceRoot, "reference/demo_app/tmp/demo_browser_evidence");
const fakeEvidence = path.join(fakeRoot, "reference/demo_app/tmp/demo_browser_evidence");
for (const baseline of checker.validatePinnedBaselines(sourceEvidence)) {
  fs.copyFileSync(path.join(sourceEvidence, baseline.path), path.join(fakeEvidence, baseline.path));
  fs.copyFileSync(path.join(sourceEvidence, baseline.path), path.join(fixtures, baseline.path));
}
NODE
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
<task><files>tracked/phase173-03.ex, reference/demo_app/README.md, reference/demo_app/assets/e2e/demo.spec.js</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-04-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-04.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-05-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-05.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-06-PLAN.md" <<'PLAN'
<task><files>tracked/phase173-06.ex</files></task>
PLAN
cat > "$FAKE_ROOT/.planning/phases/173-consistency-and-delivery-evidence/173-01-SUMMARY.md" <<'SUMMARY'
plan_head_before: 1111111111111111111111111111111111111111
SUMMARY
for path in tracked/phase173-01.ex tracked/phase173-02.ex tracked/phase173-03.ex tracked/phase173-04.ex tracked/phase173-05.ex tracked/phase173-06.ex; do
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

# Exercise the actual Git sparse-checkout behavior in a disposable repository.
# The protected path strings below are created only inside TEST_DIR.
mkdir -p "$SPARSE_REPO/reference/demo_app/assets/e2e"
git -C "$SPARSE_REPO" init -q
git -C "$SPARSE_REPO" config user.name "Phase 173 Contract"
git -C "$SPARSE_REPO" config user.email "phase173-contract@example.invalid"
printf 'harmless synthetic README sentinel\n' > "$SPARSE_REPO/reference/demo_app/README.md"
printf 'harmless synthetic E2E sentinel\n' > "$SPARSE_REPO/reference/demo_app/assets/e2e/demo.spec.js"
printf 'visible synthetic file\n' > "$SPARSE_REPO/visible.txt"
git -C "$SPARSE_REPO" add .
git -C "$SPARSE_REPO" commit -qm 'synthetic sparse checkout fixture'
git -C "$SPARSE_REPO" worktree add --detach --no-checkout "$SPARSE_WORKTREE" HEAD
printf '%s\n' '/*' '!/reference/demo_app/README.md' '!/reference/demo_app/assets/e2e/demo.spec.js' |
  git -C "$SPARSE_WORKTREE" sparse-checkout set --no-cone --no-sparse-index --stdin
git -C "$SPARSE_WORKTREE" checkout --detach HEAD
[[ -f "$SPARSE_WORKTREE/visible.txt" ]] || { printf 'FAIL: sparse checkout omitted visible sentinel\n' >&2; exit 1; }
[[ ! -e "$SPARSE_WORKTREE/reference/demo_app/README.md" ]] || { printf 'FAIL: sparse checkout materialized synthetic README sentinel\n' >&2; exit 1; }
[[ ! -e "$SPARSE_WORKTREE/reference/demo_app/assets/e2e/demo.spec.js" ]] || { printf 'FAIL: sparse checkout materialized synthetic E2E sentinel\n' >&2; exit 1; }
git -C "$SPARSE_REPO" worktree remove --force "$SPARSE_WORKTREE"
printf 'real Git sparse checkout left both synthetic protected sentinels unmaterialized\n'

# The shared JSON evidence writer must reject a destination symlink without
# changing the target bytes. Both the link and target live under TEST_DIR.
node - "$ROOT_DIR/scripts/phase173_json_output.cjs" "$TEST_DIR" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const { writeJson, writeFileExclusive } = require(process.argv[2]);
const testDir = process.argv[3];
const target = path.join(testDir, "symlink-target.json");
const link = path.join(testDir, "symlink-output.json");
const original = Buffer.from("target bytes must remain unchanged\n");
fs.writeFileSync(target, original);
fs.symlinkSync(target, link);
let rejected = false;
try { writeJson(link, { should: "not be written" }, testDir); } catch (error) {
  rejected = /not a regular file/.test(error.message);
}
if (!rejected) throw new Error("JSON evidence writer accepted a symlink destination");
if (!fs.readFileSync(target).equals(original)) throw new Error("symlink target bytes changed");
if (!fs.lstatSync(link).isSymbolicLink()) throw new Error("rejected symlink destination was replaced");

const realParent = path.join(testDir, "real-parent");
const linkedParent = path.join(testDir, "linked-parent");
fs.mkdirSync(realParent);
fs.symlinkSync(realParent, linkedParent, "dir");
let parentRejected = false;
try { writeJson(path.join(linkedParent, "parent-output.json"), { should: "not be written" }, testDir); }
catch { parentRejected = true; }
if (!parentRejected) throw new Error("JSON evidence writer followed a symlinked parent directory");
if (fs.existsSync(path.join(realParent, "parent-output.json"))) throw new Error("symlinked parent received JSON output");

const trustedRoot = path.join(testDir, "trusted-root");
const nestedOutput = path.join(trustedRoot, "missing", "nested", "output.bin");
fs.mkdirSync(trustedRoot);
writeFileExclusive(nestedOutput, Buffer.from("nested output"), trustedRoot);
if (fs.readFileSync(nestedOutput, "utf8") !== "nested output") throw new Error("secure writer failed to create a missing nested parent");

const externalTarget = path.join(testDir, "external-target");
const externalLink = path.join(trustedRoot, "linked-parent");
fs.mkdirSync(externalTarget);
fs.symlinkSync(externalTarget, externalLink, "dir");
let externalRejected = false;
try {
  writeFileExclusive(path.join(externalLink, "new-child", "output.bin"), Buffer.from("must not escape"), trustedRoot);
} catch { externalRejected = true; }
if (!externalRejected) throw new Error("secure writer followed a symlinked parent outside its trusted root");
if (fs.existsSync(path.join(externalTarget, "new-child"))) throw new Error("symlink target received a created directory");
NODE

node - "$ROOT_DIR" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const launcherPath = path.join(root, "scripts/check_phase173_candidate.sh");
const dockerPath = path.join(root, ".dockerignore");
const composePath = path.join(root, "compose.demo.yml");
const runnerPath = path.join(root, "scripts/run_demo_browser_evidence.sh");
const protectedPaths = ["reference/demo_app/README.md", "reference/demo_app/assets/e2e/demo.spec.js"];
const sparseRules = ["/*", ...protectedPaths.map((item) => `!/${item}`)];
const activeDockerRules = (text) => text.replace(/\r\n?/g, "\n").split("\n").map((line) => line.trim())
  .filter((line) => line && !line.startsWith("#"));
function assertContract(launcher, dockerignore, compose, runner) {
  const outerStart = launcher.indexOf('if [[ "${PHASE173_CANDIDATE_MODE:-false}" != "true" ]]');
  const candidateStart = launcher.indexOf("\nSHA=", outerStart);
  if (!(outerStart >= 0 && candidateStart > outerStart)) throw new Error("launcher outer/candidate mode boundary is missing");
  const outer = launcher.slice(outerStart, candidateStart);
  if (outer.includes('mkdir -p "$EVIDENCE_DIR"')) throw new Error("outer launcher creates output parents by pathname");
  if (launcher.includes('mkdir -p "$(dirname "$DELIVERY_JSON")"')) throw new Error("candidate launcher creates output parents by pathname");
  if (launcher.includes('fs.mkdirSync(candidateRoot, { recursive: true })')) throw new Error("baseline transfer creates destination by pathname");
  if (!launcher.includes("writeFileExclusive(destination, bytes,")) throw new Error("baseline transfer does not use the secure exclusive writer");
  if (/git\s+(status|diff|ls-files|cat-file)\b/.test(outer)) throw new Error("outer launcher inventories origin paths");
  const add = outer.indexOf("git worktree add --detach --no-checkout");
  const sparse = outer.indexOf("sparse-checkout set --no-cone --no-sparse-index --stdin");
  const checkout = outer.indexOf("checkout --detach");
  const transfer = outer.indexOf("validatePinnedBaselines");
  const candidate = outer.indexOf("PHASE173_CANDIDATE_MODE=true");
  if (!(add >= 0 && sparse > add && checkout > sparse && transfer > checkout && candidate > transfer)) {
    throw new Error("candidate checkout or materialization precedes sparse exclusion setup");
  }
  for (const rule of sparseRules) if (!outer.includes(rule)) throw new Error(`sparse exclusion missing: ${rule}`);
  if (!outer.includes('status --porcelain=v1 --untracked-files=all -- . \\\n    \':(exclude)reference/demo_app/README.md\' \\\n    \':(exclude)reference/demo_app/assets/e2e/demo.spec.js\'')) {
    throw new Error("initial candidate cleanliness check does not exclude protected paths");
  }
  const loop = launcher.slice(launcher.indexOf("while IFS= read -r listed_path"), launcher.indexOf("# Run the phase regression gate"));
  let cursor = -1;
  for (const item of protectedPaths) {
    const skip = loop.indexOf(`listed_path\" == \"${item}\"`);
    const probe = loop.indexOf("git cat-file -e");
    if (!(skip >= 0 && probe > skip)) throw new Error(`protected path is not skipped before git cat-file: ${item}`);
    if (skip <= cursor) throw new Error("protected skips are not in deterministic order");
    cursor = skip;
  }
  if (!launcher.includes('ownerAcceptance: { status: ownerAcceptanceStatus }') ||
      !launcher.includes('OWNER_ACCEPTANCE_STATUS="unverified"') || !launcher.includes('dirtyInventory: original.dirtyInventory')) {
    throw new Error("owner acceptance or SHA-only inventory is not explicit");
  }
  const lockedMixPrep = "ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix deps.get --check-locked";
  if (launcher.split(lockedMixPrep).length - 1 !== 3 ||
      !launcher.includes("npm ci --no-audit --no-fund")) {
    throw new Error("candidate regression dependencies are not restored from existing lockfiles");
  }
  const previewStartup = launcher.indexOf("if compose up --build --detach --wait --wait-timeout 600 demo; then");
  const previewRestore = launcher.indexOf("restore_candidate_demo_lock", previewStartup);
  const evidenceRun = launcher.indexOf('if DEMO_CANDIDATE_REVISION="$SHA" bash scripts/run_demo_browser_evidence.sh; then');
  const evidenceRestore = launcher.indexOf("restore_candidate_demo_lock", evidenceRun);
  if (!(previewStartup >= 0 && previewRestore > previewStartup && evidenceRun > previewRestore && evidenceRestore > evidenceRun)) {
    throw new Error("candidate-generated demo lockfile is not restored around both evidence startups");
  }
  if (!launcher.includes("assert_candidate_clean") ||
      !launcher.includes("':(exclude)reference/demo_app/README.md'") ||
      !launcher.includes("':(exclude)reference/demo_app/assets/e2e/demo.spec.js'")) {
    throw new Error("candidate cleanliness check lacks explicit protected-path exclusions");
  }
  if (launcher.includes("ACCEPTANCE_PATHS") || launcher.includes("OWNER_GAPS") || launcher.includes("excludedDirtyPaths")) {
    throw new Error("owner acceptance is inferred from a dirty-path inventory");
  }
  const dockerRules = activeDockerRules(dockerignore);
  if (JSON.stringify(dockerRules.slice(-2)) !== JSON.stringify(protectedPaths)) throw new Error("Docker protected exclusions are not final active rules");
  if (dockerRules.some((line) => line.startsWith("!") && protectedPaths.includes(line.slice(1)))) throw new Error("Docker exclusions are re-included");
  if ((compose.match(/context:\s*\./g) || []).length !== 2) throw new Error("both demo builds must use repository-root context");
  if (fs.existsSync(path.join(root, "Dockerfile.dockerignore")) || fs.existsSync(path.join(root, "reference/demo_app/Dockerfile.dockerignore"))) {
    throw new Error("Dockerfile-specific ignore override bypasses the root exclusions");
  }
  if (!runner.includes("test:e2e -- phase173-evidence.spec.js --reporter=json")) throw new Error("focused Phase 173 browser selector changed");
}
const initial = [fs.readFileSync(launcherPath, "utf8"), fs.readFileSync(dockerPath, "utf8"),
  fs.readFileSync(composePath, "utf8"), fs.readFileSync(runnerPath, "utf8")];
assertContract(...initial);
const cases = [
  [0, (x) => x.replace('ORIGIN_META="$EVIDENCE_DIR/origin-dirty-paths.json"', 'git status --porcelain=v1\n  ORIGIN_META="$EVIDENCE_DIR/origin-dirty-paths.json"')],
  [0, (x) => x.replace('git -C "$CANDIDATE_WORKTREE" sparse-checkout set --no-cone --no-sparse-index --stdin', 'git -C "$CANDIDATE_WORKTREE" checkout --detach "$ORIGIN_SHA"')],
  [0, (x) => x.replace("!/reference/demo_app/README.md", "")],
  [0, (x) => x.replace('[[ "$listed_path" == "reference/demo_app/README.md" ]] && continue', "# skip removed")],
  [1, (x) => x.replace("reference/demo_app/README.md\n", "")],
  [1, (x) => `${x}\n!reference/demo_app/README.md\n`],
  [3, (x) => x.replace("phase173-evidence.spec.js", "*.spec.js")],
  [0, (x) => x.replaceAll("ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix deps.get --check-locked", "asdf exec mix deps.get")],
  [0, (x) => x.replace("restore_candidate_demo_lock\n    TMP_DIR", "TMP_DIR")]
];
for (const [caseIndex, [sourceIndex, mutation]] of cases.entries()) {
  const candidate = initial.slice();
  candidate[sourceIndex] = mutation(candidate[sourceIndex]);
  let rejected = false;
  try { assertContract(...candidate); } catch { rejected = true; }
  if (!rejected) throw new Error(`contract mutation ${caseIndex + 1} was accepted`);
}
const secondDockerMutation = initial.slice();
secondDockerMutation[1] = secondDockerMutation[1].replace("reference/demo_app/assets/e2e/demo.spec.js\n", "");
try { assertContract(...secondDockerMutation); throw new Error("Docker second-rule mutation was accepted"); } catch (error) {
  if (error.message === "Docker second-rule mutation was accepted") throw error;
}
const secondSparseMutation = initial.slice();
secondSparseMutation[0] = secondSparseMutation[0].replace("!/reference/demo_app/assets/e2e/demo.spec.js", "");
try { assertContract(...secondSparseMutation); throw new Error("sparse second-rule mutation was accepted"); } catch (error) {
  if (error.message === "sparse second-rule mutation was accepted") throw error;
}
const secondSkipMutation = initial.slice();
secondSkipMutation[0] = secondSkipMutation[0].replace('[[ "$listed_path" == "reference/demo_app/assets/e2e/demo.spec.js" ]] && continue', "# skip removed");
try { assertContract(...secondSkipMutation); throw new Error("scan second-skip mutation was accepted"); } catch (error) {
  if (error.message === "scan second-skip mutation was accepted") throw error;
}
console.log("protected-path source contract passed all positive and negative mutations");
NODE

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
  hash-object)
    printf '%s\n' "${FAKE_GIT_HEAD:-$SHA}"
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
    [[ "$path" != "reference/demo_app/README.md" && "$path" != "reference/demo_app/assets/e2e/demo.spec.js" ]] || {
      printf 'PROTECTED PATH PROBED: %s\n' "$path" >&2
      exit 92
    }
    [[ "${FAKE_MISSING_PATH:-}" != "$path" ]]
    ;;
  sparse-checkout)
    if [[ "${1:-}" == set ]]; then
      cat > "$FIXTURES/sparse-rules"
      touch "$FIXTURES/sparse-set"
    fi
    ;;
  checkout)
    [[ -f "$FIXTURES/sparse-set" ]] || { printf 'checkout before sparse setup\n' >&2; exit 93; }
    cp -R "$FAKE_ORIGIN_DIR/." "$PWD/"
    rm -rf "$PWD/reference/demo_app/tmp/demo_browser_evidence"
    touch "$FIXTURES/checkout-done"
    ;;
  worktree)
    if [[ "${1:-}" == add ]]; then
      destination="${4:-}"
      mkdir -p "$destination"
      touch "$FIXTURES/worktree-added"
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
cat > "$FAKE_BIN/npm" <<'NPM'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$LOG"
exit 0
NPM
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

cat > "$FAKE_ROOT/scripts/run_demo_browser_evidence.sh" <<'EVIDENCE'
#!/usr/bin/env bash
set -euo pipefail
EVIDENCE_DIR="reference/demo_app/tmp/demo_browser_evidence"
printf 'focused evidence wrapper invoked\n' >>"$LOG"
rm -rf "$EVIDENCE_DIR/retained"
mkdir -p "$EVIDENCE_DIR/captures" "$EVIDENCE_DIR/retained"
node - "$EVIDENCE_DIR" "${FAKE_EVIDENCE_MODE:-valid}" "${DEMO_CANDIDATE_REVISION:-}" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const [evidenceDir, mode, revision] = process.argv.slice(2);
const checker = require(path.resolve("reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs"));
const captures = [];
for (const baseline of checker.EXPECTED_BASELINES) {
  const bytes = fs.readFileSync(path.join(evidenceDir, baseline.path));
  const relative = `captures/fixture-${baseline.captureId}.png`;
  fs.writeFileSync(path.join(evidenceDir, relative), bytes);
  captures.push({
    id: baseline.captureId,
    path: relative,
    sha256: baseline.sha256,
    candidate_revision: revision,
    candidate_dirty: mode === "mixed-dirty" && baseline.captureId === "dashboard",
    before_after: { baseline_path: baseline.path, baseline_sha256: baseline.sha256 }
  });
  fs.copyFileSync(path.join(evidenceDir, baseline.path), path.join(evidenceDir, "retained", `${baseline.captureId}-baseline.png`));
  if (!(mode === "missing" && baseline.captureId === "dashboard")) {
    fs.copyFileSync(path.join(evidenceDir, relative), path.join(evidenceDir, "retained", `${baseline.captureId}-current.png`));
  }
}
const checkpoint = {
  schema_version: "demo_browser_evidence.v2",
  status: mode === "failed" ? "failed" : "passed",
  candidate_revision: mode === "stale" ? "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" : revision,
  candidate_dirty: false,
  captures
};
if (mode !== "missing-checkpoint") fs.writeFileSync(path.join(evidenceDir, "retained/checkpoint.json"), `${JSON.stringify(checkpoint, null, 2)}\n`);
if (mode === "changed" && fs.existsSync(path.join(evidenceDir, "retained/dashboard-current.png"))) {
  fs.appendFileSync(path.join(evidenceDir, "retained/dashboard-current.png"), Buffer.from([0]));
}
NODE
if [[ "${FAKE_EVIDENCE_MODE:-valid}" == failed ]]; then exit 23; fi
EVIDENCE
chmod +x "$FAKE_ROOT/scripts/run_demo_browser_evidence.sh"

write_metadata() {
  cat > "$TEST_DIR/origin-dirty-paths.json" <<EOF
{"schemaVersion":1,"originSha":"$SHA","workspace":"synthetic-origin","dirtyInventory":{"status":"not-collected","reason":"protected-path fence"}}
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

run_locally_passed_candidate() {
  local output="$1"
  local exit_code=0
  if run_candidate > "$output" 2>&1; then exit_code=0; else exit_code=$?; fi
  if [[ "$exit_code" -ne 1 ]]; then
    cat "$output" >&2
    printf 'FAIL: candidate returned %s; expected only the explicit external-pending status\n' "$exit_code" >&2
    exit 1
  fi
}

assert_failure() {
  local label="$1"
  shift
  TEST_ENV=("$@")
  if run_candidate > "$TEST_DIR/$label.out" 2>&1; then
    cat "$TEST_DIR/$label.out" >&2
    printf 'FAIL: %s unexpectedly passed\n' "$label" >&2
    exit 1
  fi
}

TEST_ENV=()
run_locally_passed_candidate "$TEST_DIR/passed.out"
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" "$LOG" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const log = fs.readFileSync(process.argv[3], "utf8");
if (record.status !== "incomplete" || record.requiredCi.status !== "passed" || record.readiness.status !== "passed") {
  throw new Error("fake-green candidate did not remain incomplete pending owner acceptance");
}
if (record.ownerAcceptance.status !== "unverified" || record.originalWorkspace.dirtyInventory.status !== "not-collected" || "excludedDirtyPaths" in record.originalWorkspace || "requiredOwnerDirtyPaths" in record) {
  throw new Error("owner acceptance or origin dirty inventory was inferred");
}
if (record.browserEvidence.status !== "passed" || record.uploadableArtifactDirectory !== "reference/demo_app/tmp/demo_browser_evidence/retained/") {
  throw new Error("sanitized retained evidence was not required and recorded");
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
run_locally_passed_candidate "$TEST_DIR/changed_assets.out"
rg -q 'asdf exec mix verify.preview' "$LOG"
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (record.localChecks.previewAssets !== "passed") throw new Error("changed Admin assets did not record the preview asset check result");
NODE

for evidence_mode in failed missing missing-checkpoint stale changed mixed-dirty; do
  TEST_ENV=(FAKE_EVIDENCE_MODE="$evidence_mode")
  assert_failure "evidence_$evidence_mode" "FAKE_EVIDENCE_MODE=$evidence_mode"
  node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (record.status !== "incomplete" || record.browserEvidence.status !== "incomplete") {
  throw new Error("invalid retained evidence incorrectly passed the candidate gate");
}
NODE
done

assert_failure wrong_sha FAKE_GIT_HEAD=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
rg -q 'candidate HEAD does not match' "$TEST_DIR/wrong_sha.out"
assert_failure dirty_candidate FAKE_GIT_STATUS=' M lib/dirty.ex'
rg -q 'candidate worktree has tracked or untracked changes' "$TEST_DIR/dirty_candidate.out"
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
# Exercise the outer launcher with fake Git: it snapshots path/status metadata,
# creates a detached exact-SHA candidate, and invokes the committed candidate mode.
cp "$ROOT_DIR/scripts/check_phase173_candidate.sh" "$FAKE_ROOT/scripts/check_phase173_candidate.sh"
cp "$ROOT_DIR/scripts/phase173_json_output.cjs" "$FAKE_ROOT/scripts/phase173_json_output.cjs"
cp "$ROOT_DIR/scripts/phase173_json_output.py" "$FAKE_ROOT/scripts/phase173_json_output.py"
chmod +x "$FAKE_ROOT/scripts/check_phase173_candidate.sh"
write_metadata
: > "$LOG"
env PATH="$FAKE_BIN:$NODE_BIN_DIR:$PATH" \
  FAKE_ROOT="$FAKE_ROOT" FAKE_ORIGIN_DIR="$FAKE_ROOT" FAKE_ORIGIN_STATUS=' M reference/demo_app/assets/e2e/demo.spec.js' \
  FAKE_BIN="$FAKE_BIN" FIXTURES="$FIXTURES" LOG="$LOG" SHA="$SHA" CSS_MD5="$CSS_MD5" CSS_TEXT="$CSS_TEXT" \
  SUMMARY_PATHS="$SUMMARY_PATHS" \
  bash "$FAKE_ROOT/scripts/check_phase173_candidate.sh" > "$TEST_DIR/outer.out" || [[ "$?" -eq 1 ]]
rg -q 'phase173 candidate worktree: /tmp/mailglass-phase173\.' "$TEST_DIR/outer.out"
node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/origin-dirty-paths.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (record.dirtyInventory.status !== "not-collected" || record.dirtyInventory.reason !== "protected-path fence" || "files" in record) {
  throw new Error(`outer launcher collected or inferred a dirty path inventory: ${JSON.stringify(record)}`);
}
NODE
rg -q 'git worktree add --detach --no-checkout' "$LOG"
rg -q 'sparse-checkout set --no-cone --no-sparse-index --stdin' "$LOG"
rg -q 'checkout --detach' "$LOG"
node - "$FIXTURES/sparse-rules" "$LOG" <<'NODE'
const fs = require("node:fs");
const rules = fs.readFileSync(process.argv[2], "utf8").trim().split(/\r?\n/);
const log = fs.readFileSync(process.argv[3], "utf8");
const add = log.indexOf("git worktree add --detach --no-checkout");
const sparse = log.indexOf("sparse-checkout set --no-cone --no-sparse-index --stdin");
const checkout = log.indexOf("checkout --detach");
if (JSON.stringify(rules) !== JSON.stringify(["/*", "!/reference/demo_app/README.md", "!/reference/demo_app/assets/e2e/demo.spec.js"])) {
  throw new Error(`wrong sparse exclusions: ${JSON.stringify(rules)}`);
}
if (!(add >= 0 && sparse > add && checkout > sparse)) throw new Error("checkout/materialization did not follow sparse setup");
if (log.slice(0, add).includes("git status") || log.slice(0, add).includes("git diff") || log.slice(0, add).includes("git ls-files")) {
  throw new Error("origin inventory command ran before candidate isolation");
}
if (log.includes("git cat-file -e aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:reference/demo_app/README.md") ||
    log.includes("git cat-file -e aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:reference/demo_app/assets/e2e/demo.spec.js")) {
  throw new Error("protected deliverable path reached git cat-file");
}
NODE
if rg -q 'git (add |push |merge )|gh workflow run|docker compose.* down|worktree remove' "$LOG"; then
  printf 'FAIL: launcher attempted a prohibited GitHub write or retained-resource cleanup\n' >&2
  exit 1
fi

node - "$TEST_DIR/outer.out" "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence" "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const [outputPath, sourceEvidence, checkerPath] = process.argv.slice(2);
const output = fs.readFileSync(outputPath, "utf8");
const worktree = output.match(/phase173 candidate worktree: (.+)/)?.[1];
if (!worktree) throw new Error("outer launcher did not report its candidate worktree");
const checker = require(checkerPath);
const candidateEvidence = path.join(worktree, "reference/demo_app/tmp/demo_browser_evidence");
const transferred = fs.readdirSync(candidateEvidence).filter((name) => name.startsWith("baseline-") && name.endsWith(".png")).sort();
const expected = checker.EXPECTED_BASELINES.map((item) => item.path).sort();
if (JSON.stringify(transferred) !== JSON.stringify(expected)) throw new Error(`candidate received a non-allowlisted baseline set: ${transferred}`);
for (const baseline of checker.EXPECTED_BASELINES) {
  const source = fs.readFileSync(path.join(sourceEvidence, baseline.path));
  const candidate = fs.readFileSync(path.join(candidateEvidence, baseline.path));
  if (!source.equals(candidate)) throw new Error(`candidate baseline bytes differ: ${baseline.path}`);
}
NODE

run_outer() {
  local name="$1"
  : > "$LOG"
  env PATH="$FAKE_BIN:$NODE_BIN_DIR:$PATH" \
    FAKE_ROOT="$FAKE_ROOT" FAKE_ORIGIN_DIR="$FAKE_ROOT" FAKE_ORIGIN_STATUS=' M reference/demo_app/assets/e2e/demo.spec.js' \
    FAKE_BIN="$FAKE_BIN" FIXTURES="$FIXTURES" LOG="$LOG" SHA="$SHA" CSS_MD5="$CSS_MD5" CSS_TEXT="$CSS_TEXT" \
    SUMMARY_PATHS="$SUMMARY_PATHS" \
    bash "$FAKE_ROOT/scripts/check_phase173_candidate.sh" > "$TEST_DIR/$name.out" 2>&1
}

for baseline_mode in missing altered symlinked; do
  baseline_path="$(node - "$ROOT_DIR/reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs" <<'NODE'
const checker = require(process.argv[2]);
process.stdout.write(checker.EXPECTED_BASELINES[0].path);
NODE
)"
  original="$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/$baseline_path"
  saved="$FIXTURES/$baseline_path"
  case "$baseline_mode" in
    missing) rm "$original" ;;
    altered) printf 'altered' > "$original" ;;
    symlinked) rm "$original"; ln -s "$saved" "$original" ;;
  esac
  if run_outer "baseline_$baseline_mode"; then
    printf 'FAIL: outer launcher accepted %s baseline\n' "$baseline_mode" >&2
    exit 1
  fi
  rg -q 'baseline validation or transfer failed' "$TEST_DIR/baseline_$baseline_mode.out"
  node - "$FAKE_ROOT/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json" <<'NODE'
const fs = require("node:fs");
const record = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (record.status !== "incomplete" || record.baselineValidation !== "failed" || !record.failures[0].includes("baseline")) {
  throw new Error("invalid baseline did not leave a specific incomplete delivery record");
}
NODE
  if rg -q 'focused evidence wrapper invoked' "$LOG"; then
    printf 'FAIL: %s baseline reached focused capture\n' "$baseline_mode" >&2
    exit 1
  fi
  rm -f "$original"
  cp "$saved" "$original"
done

printf 'Phase 173 candidate fake-CLI contract passed (SHA, cleanliness, ancestry, owner dirt, HTTP/CSS, CI, retention, no remote writes).\n'
