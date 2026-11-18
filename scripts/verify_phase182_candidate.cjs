#!/usr/bin/env node
"use strict";

// Fail-closed, dependency-free verification of the Phase 182 exact-SHA gates.
// This runs after the manual CI dispatch and before any preview or browser work.

const fs = require("node:fs");
const crypto = require("node:crypto");
const path = require("node:path");
const os = require("node:os");
const { execFileSync, spawnSync } = require("node:child_process");

const BASE_SHA = "c94fcdda32c73c93628b840f0b6b9feafe43cb17";
const ROUTE_PARENT_SHA = "4bd52b6fc4e432f473d85f60477d05268cc0f459";
const BRANCH = "gsd/v2.11-phase182-admin-evidence";
const REPOSITORY = "szTheory/mailglass";
const BASELINE_RUN = "40414024714";
const COST_SCHEMA = "phase178-cost-disposition.v1";
const PHASE178_COST_PATH = ".planning/milestones/v2.10-phases/178-preview-authoring-and-milestone-review/178-COST-DISPOSITION.json";
const BASELINE_RUN_SHA256 = "4bbf8e5e941cd9447634c1e3e8cac22a3fcb0dcde2fd7057331b138ce428b2ef";
const BASELINE_JOBS_SHA256 = "70c30ead8f33d7503b79230a16aaf6f11e7a3bbc4da05f782312b131c6b0afb0";
const EXPECTED_COUNTS_SHA256 = "ec2bfcc87676d223f5c3cf6881ce753cdafcb1001ea0f9b501a630faaa221852";
const PREFLIGHT_PATH = ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-EVIDENCE.json";
const EVIDENCE_PREFIX = ".planning/research/brand-v2-adoption/admin-current-evidence/";
const CANDIDATE_INDEX_PATH = ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-CANDIDATE.json";
const COST_DISPOSITION_PATH = ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-COST-DISPOSITION.json";
const CHECK_PATH = ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-CHECK.md";
const EXPECTED_LEGACY_DECISION_FAILURES = [
  "e037ceecabbf9d28261a6fc2bcfc8d02f6a32af7",
  "4db125d2eb7d1703fb3c2c26ab2d368701e197dc",
  "9697bb59195d36621a3dfa7e1d9cfb1c62389348",
  "2d443e1f3e4e5cead07b7a6975ee35c8aa24434e"
].sort();
const EXPECTED_GITLEAKS_FALSE_POSITIVE = {
  rule_id: "generic-api-key",
  file: ".planning/phases/182-admin-words-and-layout-one-job-first/182-CONTEXT.md",
  start_line: 87,
  end_line: 87,
  commit: "a700f9b0c5be7e804f16f1c01a510959caca6538"
};
const ROUTE_COMMITS = [
  {
    subject: "chore(deps): refresh resolver locks for Plug security fix",
    files: ["mix.lock", "mailglass_admin/mix.lock", "mailglass_inbound/mix.lock", "reference/demo_app/mix.lock", "reference/host_app/mix.lock"]
  },
  {
    subject: "chore(v2.11): add exact-SHA candidate gate verifier",
    files: ["scripts/verify_phase182_candidate.cjs"]
  },
  {
    subject: "docs(v2.11): authorize scoped Phase 182 candidate gates",
    files: [
      ".planning/phases/182-admin-words-and-layout-one-job-first/182-07-PLAN.md",
      ".planning/STATE.md",
      ".planning/ROADMAP.md",
      ".planning/v2.11-MILESTONE-AUDIT.md"
    ]
  }
];
const COST_JOBS = [
  "Demo Browser Evidence (Docker Compose / Chromium)",
  "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)",
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
];
const REQUIRED_HOSTED_JOBS = ["CI Green", ...COST_JOBS];
const LOCK_CHECKS = {
  root: "mix deps.get --check-locked",
  admin: "mix deps.get --check-locked",
  inbound: "mix deps.get --check-locked",
  demo: "mix deps.get --check-locked",
  reference_host: "mix deps.get --check-locked",
  hex_audit: "mix mailglass.audit --kind hex"
};
const LOCK_PATHS = [
  "mix.lock",
  "mailglass_admin/mix.lock",
  "mailglass_inbound/mix.lock",
  "reference/demo_app/mix.lock",
  "reference/host_app/mix.lock"
];
const COST_INPUT_ROLES = [
  "baseline_run",
  "baseline_jobs",
  "dispatch_run",
  "dispatch_jobs",
  "count_operator_log",
  "count_demo_cost",
  "count_expected"
];

function fail(message) {
  throw new Error(message);
}

function readJson(file, label) {
  let stat;
  try {
    stat = fs.lstatSync(file);
  } catch (error) {
    fail(`${label} is not readable JSON: ${error.message}`);
  }
  if (!stat.isFile() || stat.isSymbolicLink()) fail(`${label} must be a regular file`);
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    fail(`${label} is not readable JSON: ${error.message}`);
  }
}

function sha256File(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function evidenceFilePath(relativePath, evidenceDir, label) {
  if (typeof relativePath !== "string" || !relativePath.startsWith(`${evidenceDir}/`)
      || path.isAbsolute(relativePath) || relativePath.split(/[\\/]/).includes("..")) {
    fail(`${label} path must be inside the owned Phase 182 evidence tree`);
  }
  const absolutePath = path.resolve(process.cwd(), relativePath);
  const evidenceRoot = fs.realpathSync(path.resolve(process.cwd(), EVIDENCE_PREFIX));
  const runDirectory = path.resolve(process.cwd(), evidenceDir);
  if (fs.realpathSync(runDirectory) !== runDirectory) fail("candidate evidence directory must not be a symlink");
  const realPath = fs.realpathSync(absolutePath);
  if (!realPath.startsWith(`${evidenceRoot}${path.sep}`)) fail(`${label} path escapes the owned evidence tree`);
  const stat = fs.lstatSync(absolutePath);
  if (!stat.isFile() || stat.isSymbolicLink()) {
    fail(`${label} must be a regular evidence file, not a symlink`);
  }
  return absolutePath;
}

function readEvidenceFile(relativePath, expectedSha, evidenceDir, label) {
  const file = evidenceFilePath(relativePath, evidenceDir, label);
  if (sha256File(file) !== expectedSha) fail(`${label} SHA-256 does not match the recorded digest`);
  return file;
}

function readEvidenceJson(relativePath, expectedSha, evidenceDir, label) {
  return readJson(readEvidenceFile(relativePath, expectedSha, evidenceDir, label), label);
}

function requireValue(value, expected, label) {
  if (value !== expected) fail(`${label} must be ${JSON.stringify(expected)}, got ${JSON.stringify(value)}`);
}

function requireSuccessJob(jobs, name) {
  const job = jobs && jobs[name];
  if (!job) fail(`hosted receipt is missing job ${name}`);
  requireValue(job.status, "completed", `${name}.status`);
  requireValue(job.conclusion, "success", `${name}.conclusion`);
}

function verifyLockPreflight(index) {
  const preflight = index.lock_preflight;
  if (!preflight || typeof preflight !== "object") fail("candidate is missing local lock-preflight evidence");
  for (const [name, command] of Object.entries(LOCK_CHECKS)) {
    const check = preflight.checks && preflight.checks[name];
    if (!check) fail(`lock preflight is missing ${name} check`);
    requireValue(check.command, command, `${name} command`);
    requireValue(check.exit_status, 0, `${name} exit_status`);
  }

  const recordedLocks = preflight.locks;
  if (!recordedLocks || typeof recordedLocks !== "object") fail("lock preflight is missing lock hashes");
  const recordedPaths = Object.keys(recordedLocks).sort();
  const expectedPaths = [...LOCK_PATHS].sort();
  if (JSON.stringify(recordedPaths) !== JSON.stringify(expectedPaths)) fail("lock preflight must contain exactly the five candidate lockfiles");

  for (const lockPath of LOCK_PATHS) {
    const lock = recordedLocks[lockPath];
    const gitBlob = execFileSync("git", ["rev-parse", `${index.candidate_sha}:${lockPath}`], { encoding: "utf8" }).trim();
    requireValue(lock.candidate_blob_oid, gitBlob, `${lockPath} candidate blob OID`);
    if (!/^[0-9a-f]{64}$/.test(lock.candidate_blob_sha256 || "")) fail(`${lockPath} candidate SHA-256 is invalid`);
    const candidateBlob = execFileSync("git", ["show", `${index.candidate_sha}:${lockPath}`]);
    requireValue(crypto.createHash("sha256").update(candidateBlob).digest("hex"), lock.candidate_blob_sha256, `${lockPath} candidate blob SHA-256`);
    requireValue(lock.before_check_sha256, lock.candidate_blob_sha256, `${lockPath} pre-check SHA-256`);
    requireValue(lock.after_check_sha256, lock.candidate_blob_sha256, `${lockPath} post-check SHA-256`);
    requireValue(sha256File(lockPath), lock.candidate_blob_sha256, `${lockPath} current SHA-256`);
  }
}

function readPorcelainInventory() {
  const bytes = execFileSync("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], { encoding: "buffer" });
  const inventory = new Map();
  for (const entry of bytes.toString("utf8").split("\0")) {
    if (!entry) continue;
    const status = entry.slice(0, 2);
    const relativePath = entry.slice(3);
    if (status.includes("R") || status.includes("C")) fail("owner-WIP inventory contains a rename/copy that the baseline format cannot safely compare");
    const absolutePath = path.resolve(process.cwd(), relativePath);
    let digest = null;
    try {
      const stat = fs.lstatSync(absolutePath);
      if (stat.isFile() && !stat.isSymbolicLink()) digest = sha256File(absolutePath);
      else if (stat.isSymbolicLink()) digest = crypto.createHash("sha256").update(fs.readlinkSync(absolutePath)).digest("hex");
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
    if (inventory.has(relativePath)) fail(`owner-WIP inventory contains duplicate path ${relativePath}`);
    inventory.set(relativePath, { status, sha256: digest });
  }
  return inventory;
}

function verifyOwnerWip(index, args) {
  const committedPreflight = execFileSync("git", ["show", `${index.candidate_sha}:${PREFLIGHT_PATH}`], { encoding: "buffer" });
  const currentPreflight = fs.readFileSync(PREFLIGHT_PATH);
  if (!currentPreflight.equals(committedPreflight)) fail("recorded owner-WIP baseline differs from the candidate Git blob");
  const baseline = readJson(PREFLIGHT_PATH, "recorded owner-WIP baseline").candidate.owner_worktree_inventory;
  const receipt = index.owner_wip;
  requireValue(receipt && receipt.matches_baseline, true, "owner_wip.matches_baseline");
  requireValue(receipt && receipt.baseline_inventory_sha256, baseline.sha256, "owner-WIP baseline inventory digest");
  requireValue(receipt && receipt.path_count, baseline.path_count, "owner-WIP baseline path_count");

  const current = readPorcelainInventory();
  const baselinePaths = new Map(baseline.paths.map((entry) => [entry.path, { status: entry.status, sha256: entry.sha256 }]));
  for (const [relativePath, expected] of baselinePaths) {
    const actual = current.get(relativePath);
    if (!actual) fail(`recorded owner-WIP path is missing: ${relativePath}`);
    requireValue(actual.status, expected.status, `${relativePath} owner-WIP status`);
    requireValue(actual.sha256, expected.sha256, `${relativePath} owner-WIP SHA-256`);
  }

  const evidenceDir = index.evidence_dir;
  if (typeof evidenceDir !== "string" || !evidenceDir.startsWith(EVIDENCE_PREFIX)
      || path.isAbsolute(evidenceDir) || evidenceDir.split(/[\\/]/).includes("..")) {
    fail("candidate evidence_dir must be a unique path inside the Phase 182 evidence tree");
  }
  const allowedExtras = new Set([
    args["--index"], args["--cost"], CHECK_PATH
  ]);
  const evidencePaths = new Set([
    index.hosted && index.hosted.raw_run_path,
    index.hosted && index.hosted.raw_jobs_path,
    index.privacy && index.privacy.trufflehog && index.privacy.trufflehog.report_path,
    index.privacy && index.privacy.gitleaks && index.privacy.gitleaks.report_path,
    index.demo_artifact && index.demo_artifact.raw_artifacts_path,
    ...Object.values(index.cost_inputs || {}).map((entry) => entry && entry.path)
  ].filter(Boolean));
  for (const relativePath of current.keys()) {
    if (baselinePaths.has(relativePath) || allowedExtras.has(relativePath)) continue;
    if (relativePath.startsWith(`${evidenceDir}/`)) {
      if (!evidencePaths.has(relativePath)) fail(`unreferenced file in candidate evidence directory: ${relativePath}`);
      continue;
    }
    fail(`unexpected dirty path outside the owner-WIP baseline and candidate evidence: ${relativePath}`);
  }
  for (const relativePath of evidencePaths) {
    if (!relativePath.startsWith(`${evidenceDir}/`) || !current.has(relativePath)) fail(`candidate evidence file is missing or outside its run directory: ${relativePath}`);
  }
}

function verifyPrivacy(index) {
  const range = `${BASE_SHA}..${index.candidate_sha}`;
  requireValue(execFileSync("git", ["rev-parse", `refs/heads/${BRANCH}`], { encoding: "utf8" }).trim(), index.candidate_sha, "local review ref SHA");
  const trufflehog = runTrufflehog(index.candidate_sha);
  const gitleaks = runGitleaks(index.candidate_sha);
  for (const [name, scan] of Object.entries({
    trufflehog: index.privacy && index.privacy.trufflehog,
    gitleaks: index.privacy && index.privacy.gitleaks
  })) {
    if (!scan) fail(`candidate is missing ${name} privacy scan receipt`);
    requireValue(scan.status, "passed", `${name} status`);
    requireValue(scan.range, range, `${name} candidate range`);
    const actual = name === "trufflehog" ? trufflehog : gitleaks;
    requireValue(scan.tool_version, actual.version, `${name} version`);
    requireValue(scan.raw_report_sha256, actual.raw_report_sha256, `${name} raw-report digest`);
    const summary = readEvidenceJson(scan.report_path, scan.report_sha256, index.evidence_dir, `${name} summary`);
    requireValue(summary.schema_version, "phase182-privacy-scan-summary.v1", `${name} summary schema`);
    requireValue(summary.tool, name, `${name} summary tool`);
    requireValue(summary.status, "passed", `${name} summary status`);
    requireValue(summary.range, range, `${name} summary range`);
    requireValue(summary.tool_version, actual.version, `${name} summary version`);
    requireValue(summary.raw_report_sha256, scan.raw_report_sha256, `${name} raw-report digest binding`);
    requireValue(summary.unclassified_findings, 0, `${name} unclassified findings`);
    requireValue(summary.findings, actual.findings, `${name} findings count`);
    if (name === "trufflehog") requireValue(summary.findings, 0, "TruffleHog findings");
    if (name === "gitleaks") {
      if (JSON.stringify(canonical(summary.classified_false_positive)) !== JSON.stringify(canonical(EXPECTED_GITLEAKS_FALSE_POSITIVE))) {
        fail("Gitleaks classified finding does not match the reviewed Phase 182 context false positive");
      }
      requireValue(scan.false_positive_classified, true, "Gitleaks false-positive receipt");
    }
  }
}

function scannerVersion(command, args) {
  return execFileSync(command, args, { encoding: "utf8" }).trim();
}

function runTrufflehog(candidateSha) {
  const version = scannerVersion("trufflehog", ["--version"]);
  const result = spawnSync("trufflehog", [
    "git", "file://.", `--since-commit=${BASE_SHA}`, `--branch=${BRANCH}`,
    "--json", "--no-verification", "--no-update", "--fail", "--fail-on-scan-errors"
  ], { maxBuffer: 32 * 1024 * 1024 });
  if (result.error) fail(`TruffleHog could not run: ${result.error.message}`);
  if (result.signal || result.status !== 0) fail("TruffleHog exact-range scan failed or found a secret; candidate is blocked");
  const raw = result.stdout || Buffer.alloc(0);
  const lines = raw.toString("utf8").split(/\r?\n/).filter((line) => line.trim());
  const findings = lines.map((line) => {
    try { return JSON.parse(line); } catch (_error) { return fail("TruffleHog emitted an invalid JSON result"); }
  });
  if (findings.length !== 0) fail("TruffleHog exact-range scan returned findings; candidate is blocked");
  return { version, findings: findings.length, raw_report_sha256: crypto.createHash("sha256").update(raw).digest("hex") };
}

function runGitleaks(candidateSha) {
  const version = scannerVersion("gitleaks", ["version"]);
  const result = spawnSync("gitleaks", [
    "git", `--log-opts=${BASE_SHA}..${candidateSha}`, "--report-format=json",
    "--report-path=-", "--redact=100", "--no-banner", "."
  ], { maxBuffer: 32 * 1024 * 1024 });
  if (result.error) fail(`Gitleaks could not run: ${result.error.message}`);
  if (result.signal) fail("Gitleaks exact-range scan was terminated; candidate is blocked");
  const raw = result.stdout || Buffer.alloc(0);
  let findings;
  try { findings = JSON.parse(raw.toString("utf8")); } catch (error) { return fail(`Gitleaks emitted invalid JSON: ${error.message}`); }
  if (!Array.isArray(findings)) fail("Gitleaks JSON result is not an array");
  if (findings.length === 1) {
    const known = findings[0];
    const exactKnownFalsePositive = known.RuleID === "generic-api-key"
      && known.File === ".planning/phases/182-admin-words-and-layout-one-job-first/182-CONTEXT.md"
      && known.StartLine === 87 && known.EndLine === 87
      && known.Commit === "a700f9b0c5be7e804f16f1c01a510959caca6538";
    if (!exactKnownFalsePositive || result.status !== 1) fail("Gitleaks exact-range scan found an unexpected finding; candidate is blocked");
  } else if (findings.length === 0) {
    if (result.status !== 0) fail("Gitleaks exited unsuccessfully without a classified finding");
  } else {
    fail("Gitleaks exact-range scan found unexpected findings; candidate is blocked");
  }
  return { version, findings: findings.length, raw_report_sha256: crypto.createHash("sha256").update(raw).digest("hex") };
}

function commitSubject(sha) {
  return execFileSync("git", ["show", "-s", "--format=%s", sha], { encoding: "utf8" }).replace(/\n$/, "");
}

function commitFiles(sha) {
  const output = execFileSync("git", ["diff-tree", "--no-commit-id", "--name-only", "-r", "-z", sha], { encoding: "buffer" });
  const files = output.toString("utf8").split("\0").filter(Boolean).sort();
  if (files.some((file) => file.includes("\n"))) fail(`commit ${sha} contains a newline path that the release guard cannot represent`);
  return files;
}

function guardPass(mode, subject, files = "") {
  try {
    return execFileSync("bash", ["scripts/guard_release_trigger.sh", mode, subject, ...(mode === "decision" ? [files] : [])], { encoding: "utf8" }).trim() === "PASS";
  } catch (_error) {
    return false;
  }
}

function verifyReleaseHygiene(index) {
  const receipt = index.release_hygiene;
  const range = `${BASE_SHA}..${index.candidate_sha}`;
  requireValue(receipt && receipt.range, range, "release hygiene range");
  requireValue(receipt && receipt.status, "passed", "release subject hygiene status");
  requireValue(receipt && receipt.decision_status, "review_only", "local release decision status");
  const commits = execFileSync("git", ["rev-list", "--reverse", range], { encoding: "utf8" }).trim().split("\n").filter(Boolean);
  requireValue(receipt.commit_count, commits.length, "release hygiene commit_count");

  const actualDecisionFailures = [];
  for (const sha of commits) {
    const subject = commitSubject(sha);
    const files = commitFiles(sha);
    if (!guardPass("hygiene", subject)) fail(`release subject hygiene failed for ${sha}`);
    if (!guardPass("decision", subject, files.join("\n"))) actualDecisionFailures.push(sha);
  }
  actualDecisionFailures.sort();
  const recordedFailures = [...(receipt.decision_failures || [])].sort();
  if (JSON.stringify(actualDecisionFailures) !== JSON.stringify(EXPECTED_LEGACY_DECISION_FAILURES)) {
    fail(`candidate range has unexpected local release-decision failures: ${JSON.stringify(actualDecisionFailures)}`);
  }
  if (JSON.stringify(recordedFailures) !== JSON.stringify(actualDecisionFailures)) fail("recorded local release-decision findings do not match the candidate range");

  const routeCommits = execFileSync("git", ["rev-list", "--reverse", `${ROUTE_PARENT_SHA}..${index.candidate_sha}`], { encoding: "utf8" }).trim().split("\n").filter(Boolean);
  requireValue(routeCommits.length, ROUTE_COMMITS.length, "scoped candidate commit count");
  for (let i = 0; i < ROUTE_COMMITS.length; i += 1) {
    const sha = routeCommits[i];
    const expected = ROUTE_COMMITS[i];
    requireValue(commitSubject(sha), expected.subject, `scoped commit ${i + 1} subject`);
    if (JSON.stringify(commitFiles(sha)) !== JSON.stringify([...expected.files].sort())) fail(`scoped commit ${sha} changed an unexpected path set`);
    if (!guardPass("decision", expected.subject, [...expected.files].sort().join("\n"))) fail(`scoped commit ${sha} fails the local release decision`);
  }
}

function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]));
  }
  return value;
}

function ghApiJson(endpoint, label) {
  const result = spawnSync("gh", ["api", endpoint], { maxBuffer: 64 * 1024 * 1024 });
  if (result.error || result.signal || result.status !== 0) fail(`${label} could not be fetched from GitHub`);
  try {
    return JSON.parse((result.stdout || Buffer.alloc(0)).toString("utf8"));
  } catch (_error) {
    fail(`${label} returned invalid JSON`);
  }
}

function ghCommandBytes(args, label) {
  const cacheDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-phase182-gh-cache-"));
  try {
    const result = spawnSync("gh", args, {
      maxBuffer: 128 * 1024 * 1024,
      env: { ...process.env, XDG_CACHE_HOME: cacheDir, GH_PAGER: "cat" }
    });
    if (result.error || result.signal || result.status !== 0) fail(`${label} failed; candidate is blocked`);
    return result.stdout || Buffer.alloc(0);
  } finally {
    fs.rmSync(cacheDir, { recursive: true, force: true });
  }
}

function verifyRemoteMain() {
  const remote = execFileSync("git", ["remote", "get-url", "origin"], { encoding: "utf8" }).trim().replace(/\.git$/, "");
  requireValue(remote, "https://github.com/szTheory/mailglass", "canonical origin URL");
  const rows = execFileSync("git", ["ls-remote", "origin", "refs/heads/main"], { encoding: "utf8" }).trim().split(/\r?\n/).filter(Boolean);
  if (rows.length !== 1) fail("remote main could not be read unambiguously");
  requireValue(rows[0].split(/\s+/)[0], BASE_SHA, "live origin/main SHA");
}

function verifySingleDispatch(index, hosted) {
  const endpoint = `repos/${REPOSITORY}/actions/workflows/ci.yml/runs?branch=${encodeURIComponent(BRANCH)}&event=workflow_dispatch&head_sha=${index.candidate_sha}&per_page=100`;
  const response = ghApiJson(endpoint, "candidate workflow-dispatch list");
  if (!Array.isArray(response.workflow_runs)) fail("workflow-dispatch list has no workflow_runs array");
  requireValue(response.total_count, response.workflow_runs.length, "workflow-dispatch list pagination completeness");
  const matching = response.workflow_runs.filter((run) => run.event === "workflow_dispatch"
    && run.head_branch === BRANCH && run.head_sha === index.candidate_sha);
  requireValue(matching.length, 1, "workflow-dispatch count for exact candidate SHA");
  requireValue(String(matching[0].id), String(hosted.run_id), "unique workflow-dispatch run ID");
  requireValue(Number(matching[0].run_attempt), 1, "unique workflow-dispatch attempt");
}

// Match the established Phase 178 normalizer: read only timestamped final
// Operator summary rows, reject conflicting totals, and keep latest/category.
function summaryLinesFromOperatorLog(log) {
  const found = new Map();
  for (const line of String(log).split(/\r?\n/)) {
    const withoutAnsi = line.replace(/\u001b\[[0-9;]*m/g, "");
    const columns = withoutAnsi.split("\t");
    const timestampIndex = columns.findIndex((column) => /^\d{4}-\d\d-\d\dT[\d:.]+Z(?:\s+.*)?$/.test(column));
    let timestamp;
    let message;
    if (timestampIndex >= 0) {
      const timestampAndMessage = columns[timestampIndex].match(/^(\d{4}-\d\d-\d\dT[\d:.]+Z)(?:\s+(.*))?$/);
      timestamp = timestampAndMessage[1];
      const step = columns.length >= 3 ? columns[1].trim() : null;
      const job = columns.length >= 3 ? columns[0].trim() : null;
      if (job && job !== COST_JOBS[1]) continue;
      if (step && step !== "UNKNOWN STEP" && !/^Run operator browser gate$/i.test(step)) continue;
      message = [timestampAndMessage[2], ...columns.slice(timestampIndex + 1)].filter(Boolean).join(" ").trim();
    } else {
      const match = withoutAnsi.match(/^(\d{4}-\d\d-\d\dT[\d:.]+Z)\s+(.*)$/);
      if (!match) continue;
      [, timestamp, message] = match;
      message = message.trim();
    }

    const notice = message.replace(/^##\[notice\]\s*/, "");
    const summary = notice.match(/^(\d+)\s+passed(?:\s+\((\d+)\s+skipped\))?(?:\s+\([^)]*\))?\s*$/);
    const single = notice.match(/^(\d+)\s+(skipped|failed|flaky)\s*(?:\([^)]*\))?\s*$/);
    const pairs = [];
    if (summary) {
      pairs.push(["passed", Number(summary[1])]);
      if (summary[2] !== undefined) pairs.push(["skipped", Number(summary[2])]);
    } else if (single) {
      pairs.push([single[2], Number(single[1])]);
    }
    for (const [category, count] of pairs) {
      const values = found.get(category) || [];
      values.push({ timestamp, count });
      found.set(category, values);
    }
  }
  const final = [];
  for (const [category, values] of found) {
    const counts = [...new Set(values.map((value) => value.count))];
    if (counts.length !== 1) fail(`live Operator Browser Gate log has conflicting ${category} totals`);
    values.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
    final.push({ timestamp: values.at(-1).timestamp, count: counts[0], category });
  }
  if (!final.some((entry) => entry.category === "passed")) fail("live Operator Browser Gate log has no final passed total");
  final.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  return `${final.map(({ timestamp, count, category }) => `${timestamp} ${count} ${category}`).join("\n")}\n`;
}

function verifyBaselineInputs(files, manifest, expectedCounts) {
  const trustedDisposition = JSON.parse(execFileSync("git", ["show", `${BASE_SHA}:${PHASE178_COST_PATH}`], { encoding: "utf8" }));
  requireValue(String(trustedDisposition.baseline_run_id), BASELINE_RUN, "base-pinned Phase 178 baseline run ID");
  requireValue(trustedDisposition.input_hashes && trustedDisposition.input_hashes.baseline_run, BASELINE_RUN_SHA256, "base-pinned baseline run input hash");
  requireValue(trustedDisposition.input_hashes && trustedDisposition.input_hashes.baseline_jobs, BASELINE_JOBS_SHA256, "base-pinned baseline jobs input hash");
  requireValue(trustedDisposition.input_hashes && trustedDisposition.input_hashes["input:expected.json"], EXPECTED_COUNTS_SHA256, "base-pinned expected-count input hash");
  requireValue(manifest.baseline_run.sha256, BASELINE_RUN_SHA256, "retained baseline run input hash");
  requireValue(manifest.baseline_jobs.sha256, BASELINE_JOBS_SHA256, "retained baseline jobs input hash");
  requireValue(manifest.count_expected.sha256, EXPECTED_COUNTS_SHA256, "retained expected-count input hash");
  if (JSON.stringify(canonical(expectedCounts)) !== JSON.stringify(canonical(trustedDisposition.counts.expected_input.expected))) {
    fail("expected counts differ from the base-pinned Phase 178 source");
  }

  const baselineRun = readJson(files.baseline_run, "baseline run input");
  const baselineJobs = readJson(files.baseline_jobs, "baseline jobs input");
  requireValue(String(baselineRun.id), BASELINE_RUN, "baseline run input ID");
  const liveRun = ghApiJson(`repos/${REPOSITORY}/actions/runs/${BASELINE_RUN}`, "pinned baseline run");
  const liveJobs = ghApiJson(`repos/${REPOSITORY}/actions/runs/${BASELINE_RUN}/jobs?per_page=100`, "pinned baseline jobs");
  if (JSON.stringify(canonical(liveRun)) !== JSON.stringify(canonical(baselineRun))) fail("retained baseline run differs from the live GitHub API receipt");
  if (JSON.stringify(canonical(liveJobs)) !== JSON.stringify(canonical(baselineJobs))) fail("retained baseline jobs differ from the live GitHub API receipt");
  const baselineJobList = Array.isArray(baselineJobs) ? baselineJobs : baselineJobs && baselineJobs.jobs;
  if (!Array.isArray(baselineJobList)) fail("retained baseline jobs have no jobs array");
  requireValue(baselineJobs.total_count, baselineJobList.length, "baseline jobs pagination completeness");
  requireValue(liveRun.repository && liveRun.repository.full_name, REPOSITORY, "baseline repository");
  for (const job of baselineJobList) {
    requireValue(String(job.run_id), BASELINE_RUN, `${job.name} baseline run_id`);
    requireValue(job.head_sha, baselineRun.head_sha, `${job.name} baseline head_sha`);
    requireValue(job.head_branch, baselineRun.head_branch, `${job.name} baseline head_branch`);
  }
  return { baselineRun, baselineJobs };
}

function verifyDemoArtifact(index, hosted, rawRun, rawJobs, costFile, costSha256) {
  const receipt = index.demo_artifact;
  if (!receipt || typeof receipt !== "object") fail("candidate is missing the exact-run Demo artifact receipt");
  const retained = readEvidenceJson(receipt.raw_artifacts_path, receipt.raw_artifacts_sha256, index.evidence_dir, "raw Demo artifact list");
  const live = ghApiJson(`repos/${REPOSITORY}/actions/runs/${hosted.run_id}/artifacts?per_page=100`, "candidate Demo artifacts");
  if (JSON.stringify(canonical(live)) !== JSON.stringify(canonical(retained))) fail("retained Demo artifact list differs from live GitHub metadata");
  if (!Array.isArray(live.artifacts)) fail("candidate artifact response has no artifacts array");
  requireValue(live.total_count, live.artifacts.length, "candidate artifact pagination completeness");
  const expectedName = `demo-browser-evidence-${hosted.run_id}-1`;
  const matches = live.artifacts.filter((artifact) => artifact.name === expectedName);
  requireValue(matches.length, 1, "unique exact-attempt Demo evidence artifact");
  const artifact = matches[0];
  requireValue(artifact.expired, false, "Demo evidence artifact expired");
  requireValue(String(artifact.id), String(receipt.id), "Demo evidence artifact ID");
  requireValue(Number(receipt.run_attempt), 1, "candidate Demo artifact attempt receipt");
  requireValue(artifact.name, receipt.name, "Demo evidence artifact name");
  requireValue(artifact.digest, receipt.digest, "Demo evidence artifact digest");
  requireValue(artifact.size_in_bytes, receipt.size_in_bytes, "Demo evidence artifact size");
  requireValue(artifact.digest && /^sha256:[0-9a-f]{64}$/.test(artifact.digest), true, "Demo evidence artifact digest format");
  const workflowRun = artifact.workflow_run || {};
  requireValue(String(workflowRun.id), String(hosted.run_id), "Demo artifact workflow_run ID");
  requireValue(workflowRun.head_sha, index.candidate_sha, "Demo artifact workflow_run SHA");
  requireValue(workflowRun.head_branch, BRANCH, "Demo artifact workflow_run branch");
  requireValue(String(workflowRun.repository_id), String(rawRun.repository && rawRun.repository.id), "Demo artifact repository ID");
  requireValue(String(workflowRun.head_repository_id), String(rawRun.head_repository && rawRun.head_repository.id), "Demo artifact head repository ID");
  requireValue(receipt.workflow_run_id, String(hosted.run_id), "candidate Demo artifact run ID receipt");
  requireValue(String(receipt.repository_id), String(rawRun.repository && rawRun.repository.id), "candidate Demo artifact repository receipt");
  requireValue(String(receipt.head_repository_id), String(rawRun.head_repository && rawRun.head_repository.id), "candidate Demo artifact head repository receipt");
  requireValue(receipt.head_sha, index.candidate_sha, "candidate Demo artifact SHA receipt");
  requireValue(receipt.head_branch, BRANCH, "candidate Demo artifact branch receipt");

  const demoJob = (Array.isArray(rawJobs) ? rawJobs : rawJobs.jobs).find((job) => job.name === COST_JOBS[0]);
  if (!demoJob) fail("candidate jobs are missing the Demo Browser Evidence job");
  requireValue(String(demoJob.run_id), String(hosted.run_id), "Demo job run_id");
  requireValue(demoJob.head_sha, index.candidate_sha, "Demo job head_sha");
  requireValue(demoJob.head_branch, BRANCH, "Demo job head_branch");

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-phase182-demo-artifact-"));
  try {
    ghCommandBytes(["run", "download", String(hosted.run_id), "--repo", REPOSITORY, "--name", expectedName, "--dir", tempDir], "exact-run Demo artifact download");
    const liveAfterDownload = ghApiJson(`repos/${REPOSITORY}/actions/runs/${hosted.run_id}/artifacts?per_page=100`, "candidate Demo artifact list after download");
    if (JSON.stringify(canonical(liveAfterDownload)) !== JSON.stringify(canonical(live))) {
      fail("Demo artifact identity changed while the exact-run artifact was downloaded");
    }
    const downloadedCost = path.join(tempDir, "phase174", "cost.json");
    const downloadedBytes = fs.readFileSync(downloadedCost);
    if (!downloadedBytes.equals(fs.readFileSync(costFile))) fail("retained Demo cost input does not match the exact-run artifact member");
    requireValue(crypto.createHash("sha256").update(downloadedBytes).digest("hex"), costSha256, "exact-run Demo cost SHA-256");
    const demoCost = JSON.parse(downloadedBytes.toString("utf8"));
    requireValue(demoCost.source_revision, index.candidate_sha, "Demo cost source revision");
    requireValue(demoCost.run_id, `mailglass-evidence-${hosted.run_id}-1`, "Demo cost run identity");
    for (const condition of demoCost.conditions || []) {
      requireValue(condition.run_id, `mailglass-evidence-${hosted.run_id}-1`, `${condition.condition} Demo cost run identity`);
      requireValue(condition.source_revision, index.candidate_sha, `${condition.condition} Demo cost source revision`);
    }
  } catch (_error) {
    fail("exact-run Demo artifact contents could not be verified");
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

function verifyCostReproduction(index, cost, hosted, rawRun, rawJobs) {
  const manifest = index.cost_inputs;
  if (!manifest || typeof manifest !== "object") fail("candidate is missing the cost input manifest");
  if (JSON.stringify(Object.keys(manifest).sort()) !== JSON.stringify([...COST_INPUT_ROLES].sort())) {
    fail("cost input manifest must contain exactly the seven disposition source roles");
  }
  const files = {};
  const expectedHashes = {};
  for (const role of COST_INPUT_ROLES) {
    const entry = manifest[role];
    if (!entry || !/^[0-9a-f]{64}$/.test(entry.sha256 || "")) fail(`cost input ${role} has an invalid SHA-256`);
    files[role] = readEvidenceFile(entry.path, entry.sha256, index.evidence_dir, `cost input ${role}`);
    expectedHashes[role] = entry.sha256;
  }
  requireValue(manifest.dispatch_run.path, hosted.raw_run_path, "cost dispatch run path");
  requireValue(manifest.dispatch_run.sha256, hosted.raw_run_sha256, "cost dispatch run digest");
  requireValue(manifest.dispatch_jobs.path, hosted.raw_jobs_path, "cost dispatch jobs path");
  requireValue(manifest.dispatch_jobs.sha256, hosted.raw_jobs_sha256, "cost dispatch jobs digest");

  const costHashes = cost.input_hashes;
  if (!costHashes || typeof costHashes !== "object" || Array.isArray(costHashes)
      || JSON.stringify(Object.keys(costHashes).sort()) !== JSON.stringify([...COST_INPUT_ROLES].sort())) {
    fail("cost disposition input hashes do not contain the exact seven source roles");
  }
  for (const role of COST_INPUT_ROLES) requireValue(costHashes[role], expectedHashes[role], `cost input hash ${role}`);

  const dispatchRun = readJson(files.dispatch_run, "dispatch run input");
  const dispatchJobs = readJson(files.dispatch_jobs, "dispatch jobs input");
  requireValue(String(dispatchRun.id), String(hosted.run_id), "dispatch run input id");
  requireValue(dispatchRun.head_sha, index.candidate_sha, "dispatch run input SHA");
  requireValue(String(rawRun.id), String(dispatchRun.id), "raw run/cost run identity");
  requireValue(JSON.stringify(rawJobs), JSON.stringify(dispatchJobs), "raw jobs/cost jobs identity");

  const expectedCounts = readJson(files.count_expected, "expected test counts");
  const baseline = verifyBaselineInputs(files, manifest, expectedCounts);
  const operatorJob = (Array.isArray(rawJobs) ? rawJobs : rawJobs.jobs).find((job) => job.name === COST_JOBS[1]);
  if (!operatorJob) fail("candidate jobs are missing the Operator Browser Gate job");
  const liveOperatorLog = ghCommandBytes([
    "run", "view", String(hosted.run_id), "--repo", REPOSITORY, "--attempt", "1",
    "--log", "--job", String(operatorJob.id)
  ], "exact-run Operator Browser Gate log retrieval");
  const sanitizedOperatorLog = Buffer.from(summaryLinesFromOperatorLog(liveOperatorLog.toString("utf8")), "utf8");
  if (!sanitizedOperatorLog.equals(fs.readFileSync(files.count_operator_log))) {
    fail("retained Operator count summary does not match the exact-run live job log");
  }
  const demoCost = readJson(files.count_demo_cost, "Demo cost input");
  const operatorLog = fs.readFileSync(files.count_operator_log, "utf8");
  verifyDemoArtifact(index, hosted, rawRun, rawJobs, files.count_demo_cost, manifest.count_demo_cost.sha256);
  const derived = require("./phase178_cost_disposition.cjs").deriveDisposition({
    baselineRun: baseline.baselineRun,
    baselineJobs: baseline.baselineJobs,
    dispatch: { run: dispatchRun, jobs: dispatchJobs },
    sha: index.candidate_sha,
    operatorLog,
    demoCost,
    expected: expectedCounts,
    inputHashes: expectedHashes
  });
  if (JSON.stringify(canonical(cost)) !== JSON.stringify(canonical(derived))) fail("cost disposition does not reproduce from its retained exact-SHA source inputs");
}

function verify(index, cost, args) {
  requireValue(index.schema_version, "phase182-candidate-gate.v1", "candidate schema_version");
  requireValue(index.status, "passed", "candidate status");
  if (!/^[0-9a-f]{40}$/.test(index.candidate_sha || "")) fail("candidate_sha must be a full lowercase Git SHA");
  requireValue(index.base_sha, BASE_SHA, "candidate base_sha");
  requireValue(index.branch, BRANCH, "candidate branch");
  requireValue(execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim(), index.candidate_sha, "checked-out candidate HEAD");
  verifyRemoteMain();
  verifyOwnerWip(index, args);
  verifyLockPreflight(index);
  verifyPrivacy(index);
  verifyReleaseHygiene(index);

  const hosted = index.hosted;
  if (!hosted || typeof hosted !== "object") fail("candidate is missing hosted receipt");
  requireValue(hosted.workflow, ".github/workflows/ci.yml", "hosted workflow");
  requireValue(hosted.event, "workflow_dispatch", "hosted event");
  requireValue(hosted.repository, REPOSITORY, "hosted repository");
  requireValue(hosted.head_repository, REPOSITORY, "hosted head_repository");
  requireValue(Number(hosted.run_attempt), 1, "hosted run_attempt");
  requireValue(hosted.ref, `refs/heads/${BRANCH}`, "hosted ref");
  requireValue(hosted.status, "completed", "hosted status");
  requireValue(hosted.conclusion, "success", "hosted conclusion");
  requireValue(hosted.head_sha, index.candidate_sha, "hosted head_sha");
  if (!/^\d+$/.test(String(hosted.run_id || ""))) fail("hosted receipt is missing a numeric run_id");
  verifySingleDispatch(index, hosted);

  const rawRun = readEvidenceJson(hosted.raw_run_path, hosted.raw_run_sha256, index.evidence_dir, "raw workflow run");
  const rawJobs = readEvidenceJson(hosted.raw_jobs_path, hosted.raw_jobs_sha256, index.evidence_dir, "raw workflow jobs");
  const liveRun = JSON.parse(execFileSync("gh", ["api", `repos/${REPOSITORY}/actions/runs/${hosted.run_id}`], { encoding: "utf8" }));
  const liveJobs = JSON.parse(execFileSync("gh", ["api", `repos/${REPOSITORY}/actions/runs/${hosted.run_id}/jobs?per_page=100`], { encoding: "utf8" }));
  if (JSON.stringify(canonical(liveRun)) !== JSON.stringify(canonical(rawRun))) fail("retained workflow run JSON differs from the live GitHub API receipt");
  if (JSON.stringify(canonical(liveJobs)) !== JSON.stringify(canonical(rawJobs))) fail("retained workflow jobs JSON differs from the live GitHub API receipt");
  requireValue(String(rawRun.id), String(hosted.run_id), "raw run id");
  requireValue(rawRun.event, "workflow_dispatch", "raw run event");
  requireValue(String(rawRun.path || "").split("@")[0], ".github/workflows/ci.yml", "raw workflow path");
  requireValue(rawRun.repository && rawRun.repository.full_name, REPOSITORY, "raw run repository");
  requireValue(rawRun.head_repository && rawRun.head_repository.full_name, REPOSITORY, "raw run head_repository");
  requireValue(Number(rawRun.run_attempt), 1, "raw run run_attempt");
  requireValue(rawRun.head_branch, BRANCH, "raw run branch");
  requireValue(rawRun.head_sha, index.candidate_sha, "raw run head_sha");
  requireValue(rawRun.status, "completed", "raw run status");
  requireValue(rawRun.conclusion, "success", "raw run conclusion");

  const rawJobList = Array.isArray(rawJobs) ? rawJobs : rawJobs && rawJobs.jobs;
  if (!Array.isArray(rawJobList)) fail("raw workflow jobs receipt has no jobs array");
  requireValue(rawJobs.total_count, rawJobList.length, "workflow jobs pagination completeness");
  const rawJobsByName = new Map();
  for (const job of rawJobList) {
    if (!job || typeof job.name !== "string") fail("raw workflow jobs receipt contains an invalid job");
    requireValue(String(job.run_id), String(rawRun.id), `${job.name} run_id`);
    requireValue(job.head_sha, index.candidate_sha, `${job.name} head_sha`);
    requireValue(job.head_branch, BRANCH, `${job.name} head_branch`);
    if (rawJobsByName.has(job.name)) fail(`raw workflow jobs receipt has duplicate job ${job.name}`);
    rawJobsByName.set(job.name, job);
  }
  for (const name of REQUIRED_HOSTED_JOBS) requireSuccessJob(hosted.jobs, name);
  for (const name of REQUIRED_HOSTED_JOBS) {
    const rawJob = rawJobsByName.get(name);
    if (!rawJob) fail(`raw workflow jobs receipt is missing ${name}`);
    requireValue(rawJob.status, "completed", `raw ${name}.status`);
    requireValue(rawJob.conclusion, "success", `raw ${name}.conclusion`);
    requireValue(hosted.jobs[name].status, rawJob.status, `${name}.status receipt match`);
    requireValue(hosted.jobs[name].conclusion, rawJob.conclusion, `${name}.conclusion receipt match`);
  }

  requireValue(cost.schema_version, COST_SCHEMA, "cost schema_version");
  requireValue(cost.source_revision, index.candidate_sha, "cost source_revision");
  requireValue(String(cost.baseline_run_id), BASELINE_RUN, "cost baseline_run_id");
  const measured = cost.runs && cost.runs.workflow_dispatch;
  if (!measured) fail("cost disposition is missing workflow_dispatch run");
  requireValue(String(measured.run_id), String(hosted.run_id), "cost dispatch run_id");
  requireValue(measured.head_sha, index.candidate_sha, "cost dispatch head_sha");
  if (sha256File(args["--cost"]) !== index.cost_disposition_sha256) {
    fail("candidate receipt does not bind the exact cost disposition bytes");
  }
  verifyCostReproduction(index, cost, hosted, rawRun, rawJobs);

  const budget = measured.budget;
  requireValue(budget && budget.added_wall_minutes, 5, "added wall budget");
  requireValue(budget && budget.added_runner_minutes, 10, "added runner budget");
  requireValue(budget.wall_within_budget, true, "wall budget result");
  requireValue(budget.runner_within_budget, true, "runner budget result");
  if (!measured.wall_to_ci_green || !Number.isFinite(measured.wall_to_ci_green.delta_seconds)
      || measured.wall_to_ci_green.delta_seconds > 300) fail("added wall time exceeds the 5-minute limit");
  if (!measured.runner_minutes || !Number.isFinite(measured.runner_minutes.delta)
      || measured.runner_minutes.delta > 10) fail("added runner time exceeds the 10-minute limit");

  for (const name of COST_JOBS) {
    if (!measured.jobs || !measured.jobs[name]) fail(`cost disposition is missing measured job ${name}`);
    if (measured.jobs[name].conclusion && measured.jobs[name].conclusion !== "success") {
      fail(`cost measured job ${name} did not succeed`);
    }
  }
  for (const kind of ["operator", "demo"]) {
    const counts = cost.counts && cost.counts[kind];
    requireValue(counts && counts.mismatch, false, `${kind} count mismatch`);
    if (!Array.isArray(counts.mismatches) || counts.mismatches.length !== 0) {
      fail(`${kind} expected/executed counts differ`);
    }
  }
}

function parseArgs(argv) {
  const values = {};
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (!["--index", "--cost"].includes(key)) fail(`unexpected argument ${key}`);
    if (values[key] || !argv[i + 1] || argv[i + 1].startsWith("--")) fail(`${key} needs one value`);
    values[key] = argv[++i];
  }
  for (const key of ["--index", "--cost"]) if (!values[key]) fail(`${key} is required`);
  requireValue(values["--index"], CANDIDATE_INDEX_PATH, "candidate index path");
  requireValue(values["--cost"], COST_DISPOSITION_PATH, "cost disposition path");
  return values;
}

try {
  const args = parseArgs(process.argv.slice(2));
  verify(readJson(args["--index"], "candidate index"), readJson(args["--cost"], "cost disposition"), args);
  process.stdout.write("Phase 182 exact-SHA hosted and cost gates verified.\n");
} catch (error) {
  process.stderr.write(`Phase 182 candidate gate blocked: ${error.message}\n`);
  process.exitCode = 1;
}
