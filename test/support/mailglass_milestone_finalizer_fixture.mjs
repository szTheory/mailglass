import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

import {
  authenticateClosedManifest,
  buildChildEnvironment,
  captureAuthorityCommit,
  selectExactAttemptOneCi,
  selectNaturalSchedules,
  trustedToolClosure,
  validateTrustedToolchain,
} from "../../scripts/mailglass_finalize_milestone_loader.mjs";

const FINALIZER_PATH = "scripts/finalize_milestone_v2_7.sh";
const MAX_OUTPUT_BYTES = 16_000;

function fail(message) {
  throw new Error(`finalize-milestone fixture: ${message}`);
}

function inside(root, candidate) {
  const fromRoot = relative(root, candidate);
  return fromRoot === "" || (fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`));
}

function run(path, args, options = {}) {
  const result = spawnSync(path, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: options.encoding ?? null,
    timeout: 30_000,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    if (options.allowFailure) return result;
    const detail = String(result.stderr?.toString() || result.stdout?.toString() || result.error?.message).slice(
      -MAX_OUTPUT_BYTES,
    );
    fail(`${options.label ?? "subprocess"} failed: ${detail || "no diagnostic"}`);
  }
  return result;
}

function assertPhysicalDirectory(path, label) {
  let entry;
  let physical;
  try {
    entry = lstatSync(path);
    physical = realpathSync(path);
  } catch {
    fail(`${label} is missing`);
  }
  if (!entry.isDirectory() || entry.isSymbolicLink() || physical !== path) {
    fail(`${label} is not one physical directory`);
  }
}

function materialize(root, entry) {
  const destination = resolve(root, entry.path);
  if (!inside(root, destination)) fail("authenticated fixture path escaped private root");
  mkdirSync(dirname(destination), { recursive: true, mode: 0o700 });
  const mode = entry.executable ? 0o500 : 0o400;
  writeFileSync(destination, entry.contents, { flag: "wx", mode });
  chmodSync(destination, mode);
}

function prepareReportPath(repo, relativePath) {
  if (!/^tmp\/[^/]+\/report\.json$/.test(relativePath)) {
    fail("terminal report path is outside fixture capture storage");
  }
  const tmpRoot = resolve(repo, "tmp");
  if (!inside(repo, tmpRoot)) fail("fixture report root escaped repository");
  try {
    mkdirSync(tmpRoot, { recursive: false, mode: 0o700 });
  } catch (error) {
    if (error?.code !== "EEXIST") throw error;
  }
  assertPhysicalDirectory(tmpRoot, "fixture report root");

  const reportPath = resolve(repo, relativePath);
  const reportDir = dirname(reportPath);
  try {
    mkdirSync(reportDir, { recursive: false, mode: 0o700 });
  } catch (error) {
    if (error?.code !== "EEXIST") throw error;
  }
  assertPhysicalDirectory(reportDir, "fixture report parent");
  return reportPath;
}

function fixtureGitWrapper(privateRoot, gitPath) {
  const wrapper = resolve(privateRoot, "fixture-git");
  writeFileSync(
    wrapper,
    `#!/bin/bash
set -eu
if [ "\${1:-}" = -C ] && [ "\${3:-}" = remote ] && [ "\${4:-}" = get-url ] && [ "\${5:-}" = origin ]; then
  printf '%s\\n' 'git@github.com:szTheory/mailglass.git'
  exit 0
fi
if [ "\${1:-}" = -C ] && [ "\${3:-}" = fetch ] && [ "\${4:-}" = origin ] && [ "\${5:-}" = main ]; then
  exit 0
fi
exec ${JSON.stringify(gitPath)} "$@"
`,
    { flag: "wx", mode: 0o500 },
  );
  chmodSync(wrapper, 0o500);
  return wrapper;
}

export function runFixtureFinalization(options) {
  const allowedKeys = new Set([
    "repo",
    "authorityOid",
    "reportRelative",
    "ciRuns",
    "scheduleRuns",
    "expectedScheduleNames",
    "fixtureMutation",
    "transientQueryMarker",
  ]);
  const unexpected = Object.keys(options).filter((key) => !allowedKeys.has(key));
  if (unexpected.length > 0) fail(`caller-selected or unsupported fixture input: ${unexpected.join(",")}`);

  const tools = validateTrustedToolchain();
  const runtimeClosure = trustedToolClosure(tools);
  const repo = realpathSync(options.repo);
  assertPhysicalDirectory(repo, "fixture repository");
  const authorityOid = options.authorityOid ?? captureAuthorityCommit(repo, tools.GIT);
  const porcelain = run(tools.GIT, ["-C", repo, "status", "--porcelain=v1", "--untracked-files=all"], {
    encoding: "utf8",
    label: "fixture clean check",
  }).stdout;
  if (porcelain !== "") fail("repository is not clean");

  const authenticated = authenticateClosedManifest(repo, authorityOid, tools.GIT);
  if (options.transientQueryMarker) {
    const marker = resolve(options.transientQueryMarker);
    if (!inside(dirname(repo), marker)) fail("transient query marker escaped fixture root");
    try {
      writeFileSync(marker, "failed once\n", { flag: "wx", mode: 0o600 });
      fail("transient read-only evidence query failed");
    } catch (error) {
      if (!String(error?.message).includes("transient read-only evidence query failed") && error?.code !== "EEXIST") {
        throw error;
      }
      if (String(error?.message).includes("transient read-only evidence query failed")) throw error;
    }
  }
  const ciRun = selectExactAttemptOneCi(options.ciRuns, authorityOid);
  const schedules = selectNaturalSchedules(options.scheduleRuns, authorityOid, options.expectedScheduleNames);
  const reportPath = prepareReportPath(
    repo,
    options.reportRelative ?? "tmp/phase-165-finalize.fixture/report.json",
  );
  const privateRoot = mkdtempSync(resolve(tmpdir(), "mailglass-finalize-v2-7-fixture-"));

  try {
    chmodSync(privateRoot, 0o700);
    for (const entry of authenticated) materialize(privateRoot, entry);
    const inputsPath = resolve(privateRoot, "terminal-inputs.json");
    const loaderPath = fileURLToPath(new URL("../../scripts/mailglass_finalize_milestone_loader.mjs", import.meta.url));
    const loaderBytes = readFileSync(loaderPath);
    const executable = {
      path: loaderPath,
      sha256: createHash("sha256").update(loaderBytes).digest("hex"),
      source_oid: authorityOid,
      mode: "0500",
      uid: process.getuid?.() ?? 0,
      gid: process.getgid?.() ?? 0,
    };
    writeFileSync(
      inputsPath,
      `${JSON.stringify({ ci: ciRun, schedules, executable, runtime_closure: runtimeClosure }, null, 2)}\n`,
      { flag: "wx", mode: 0o400 },
    );
    chmodSync(inputsPath, 0o400);

    if (options.fixtureMutation === "move-before-dispatch") {
      writeFileSync(resolve(repo, ".phase-165-head-move"), "move\n", { flag: "wx" });
      run(tools.GIT, ["-C", repo, "add", "--", ".phase-165-head-move"]);
      run(tools.GIT, ["-C", repo, "commit", "-q", "-m", "fixture head move before dispatch"]);
    }
    if (captureAuthorityCommit(repo, tools.GIT) !== authorityOid) {
      fail("authority commit changed before Bash dispatch");
    }

    run(tools.GIT, ["-C", repo, "update-ref", "refs/remotes/origin/main", authorityOid]);
    const childEnv = buildChildEnvironment(tools);
    childEnv.MAILGLASS_GIT = fixtureGitWrapper(privateRoot, tools.GIT);
    childEnv.MAILGLASS_MILESTONE_FIXTURE = "1";
    if (options.fixtureMutation === "move-after-report") {
      childEnv.MAILGLASS_MILESTONE_MUTATE_AFTER_REPORT = "move-head";
    } else if (options.fixtureMutation === "dirty-after-report") {
      childEnv.MAILGLASS_MILESTONE_MUTATE_AFTER_REPORT = "dirty-worktree";
    }

    const finalizer = resolve(privateRoot, FINALIZER_PATH);
    const result = run(tools.BASH, [finalizer, repo, privateRoot, authorityOid, reportPath, inputsPath], {
      cwd: repo,
      env: childEnv,
      encoding: "utf8",
      label: "staged fixture finalizer",
    });
    const report = JSON.parse(readFileSync(reportPath, "utf8"));
    if (report.schema !== "mailglass-finalize-milestone-fixture-v1" || report.status === "pass") {
      fail("fixture orchestration emitted production-shaped terminal evidence");
    }
    return { output: String(result.stdout).slice(-MAX_OUTPUT_BYTES), report };
  } finally {
    rmSync(privateRoot, { recursive: true, force: true });
  }
}
