#!/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node

import { createHash, randomBytes } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const LOADER_IDENTITY = "mailglass-finalize-milestone-loader 1";
const SOURCE_PATH = "scripts/mailglass_finalize_milestone_loader.mjs";
const FINALIZER_PATH = "scripts/finalize_milestone_v2_7.sh";
const SUPPORTED_MILESTONE = "v2.7";
const CANONICAL_REPOSITORY = "/Users/jon/projects/mailglass";
const EXPECTED_REPOSITORY = "szTheory/mailglass";
const INSTALLATION_DESTINATION = "/Users/jon/.local/bin/mailglass-finalize-milestone";
const ARCHIVE_ROOT = ".planning/milestones";
const ARCHIVED_PHASE_ROOT = `${ARCHIVE_ROOT}/v2.7-phases`;
const MAX_OUTPUT_BYTES = 16_000;
const FULL_OID = /^[0-9a-f]{40}$/;
const EXPECTED_PHASES = Object.freeze(["161", "162", "163", "164", "165"]);
const EXPECTED_SCHEDULES = Object.freeze(["Post Publish", "Release Please", "Repository Hygiene"]);
const TRUSTED_TOOLS = Object.freeze({
  NODE: "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node",
  GIT: "/opt/homebrew/Cellar/git/2.41.0/bin/git",
  BASH: "/opt/homebrew/Cellar/bash/5.2.37/bin/bash",
  GH: "/opt/homebrew/Cellar/gh/2.95.0/bin/gh",
  JQ: "/usr/bin/jq",
  MIX: "/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin/mix",
  ELIXIR: "/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin/elixir",
  ERL: "/Users/jon/.asdf/installs/erlang/28.4.1/bin/erl",
});
const REQUIRED_TOOL_NAMES = Object.freeze(Object.keys(TRUSTED_TOOLS));

function fail(message) {
  throw new Error(`finalize-milestone v2.7: ${message}`);
}

function bounded(message) {
  return String(message).slice(-MAX_OUTPUT_BYTES);
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
    timeout: options.timeout ?? 30_000,
    maxBuffer: options.maxBuffer ?? 16 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    if (options.allowFailure) return result;
    const detail = bounded(result.stderr?.toString() || result.stdout?.toString() || result.error?.message);
    fail(`${options.label ?? "subprocess"} failed: ${detail || "no diagnostic"}`);
  }
  return result;
}

function git(repo, args, options = {}) {
  return run(options.gitPath ?? TRUSTED_TOOLS.GIT, args, {
    ...options,
    cwd: repo,
    label: options.label ?? "Git operation",
  });
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function normalizedRepository(url) {
  const match = String(url).trim().match(
    /^(?:git@github\.com:|https:\/\/github\.com\/|ssh:\/\/git@github\.com\/)([^/]+\/[^/]+?)(?:\.git)?$/,
  );
  return match?.[1] ?? "";
}

export function validateTrustedToolchain(tools = TRUSTED_TOOLS) {
  const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
  for (const name of REQUIRED_TOOL_NAMES) {
    const path = tools[name];
    if (typeof path !== "string" || !isAbsolute(path) || path.includes("/.asdf/shims/")) {
      fail(`trusted ${name} executable is not one physical absolute path`);
    }
    let entry;
    let physical;
    try {
      entry = lstatSync(path);
      physical = realpathSync(path);
    } catch {
      fail(`trusted ${name} executable is missing`);
    }
    if (!entry.isFile() || entry.isSymbolicLink() || physical !== path) {
      fail(`trusted ${name} executable is not one physical regular file`);
    }
    if (!allowedOwners.has(entry.uid) || (entry.mode & 0o022) !== 0) {
      fail(`trusted ${name} executable has unsafe ownership or mode`);
    }
  }
  return tools;
}

export function buildChildEnvironment(tools = TRUSTED_TOOLS) {
  const env = {};
  for (const key of ["HOME", "TMPDIR", "LANG", "LC_ALL", "USER", "LOGNAME", "SSH_AUTH_SOCK", "GH_TOKEN", "GITHUB_TOKEN"]) {
    if (process.env[key]) env[key] = process.env[key];
  }
  for (const [name, path] of Object.entries(tools)) env[`MAILGLASS_${name}`] = path;
  env.GH_HOST = "github.com";
  env.PATH = [...new Set(Object.values(tools).map(dirname).concat(["/usr/bin", "/bin"]))].join(":");
  return env;
}

export function captureAuthorityCommit(repo, gitPath = TRUSTED_TOOLS.GIT) {
  const oid = git(repo, ["rev-parse", "--verify", "HEAD^{commit}"], {
    gitPath,
    encoding: "utf8",
    label: "authority commit capture",
  }).stdout.trim();
  if (!FULL_OID.test(oid)) fail("authority commit is not a full lowercase OID");
  return oid;
}

function assertCleanRepository(repo, gitPath = TRUSTED_TOOLS.GIT) {
  const porcelain = git(repo, ["status", "--porcelain=v1", "--untracked-files=all"], {
    gitPath,
    encoding: "utf8",
    label: "clean repository check",
  }).stdout;
  if (porcelain !== "") fail("repository is not clean");
}

function exactIndexRecord(repo, repositoryPath, gitPath) {
  const output = git(repo, ["--literal-pathspecs", "ls-files", "--stage", "-z", "--", repositoryPath], {
    gitPath,
    label: `index authentication for ${repositoryPath}`,
  }).stdout.toString("utf8");
  if (!output.endsWith("\0")) fail(`${repositoryPath} index output is not NUL terminated`);
  const records = output.split("\0").slice(0, -1);
  if (records.length !== 1) fail(`${repositoryPath} does not have exactly one index record`);
  const match = records[0].match(/^(100644|100755) [0-9a-f]{40} 0\t(.+)$/s);
  if (!match || match[2] !== repositoryPath) fail(`${repositoryPath} is not one exact stage-0 regular path`);
}

export function authenticateCommitFile(repo, authorityOid, repositoryPath, gitPath = TRUSTED_TOOLS.GIT) {
  if (!FULL_OID.test(authorityOid)) fail("authentication OID is invalid");
  const lexical = resolve(repo, repositoryPath);
  if (!inside(repo, lexical)) fail(`${repositoryPath} escapes the repository`);
  let entry;
  try {
    entry = lstatSync(lexical);
  } catch {
    fail(`${repositoryPath} is missing from the worktree`);
  }
  if (!entry.isFile() || entry.isSymbolicLink()) fail(`${repositoryPath} is not a regular file`);
  const type = git(repo, ["cat-file", "-t", `${authorityOid}:${repositoryPath}`], {
    gitPath,
    encoding: "utf8",
    label: `object authentication for ${repositoryPath}`,
  }).stdout.trim();
  if (type !== "blob") fail(`${repositoryPath} is not a blob at the authority commit`);
  exactIndexRecord(repo, repositoryPath, gitPath);
  const staged = git(repo, ["--literal-pathspecs", "diff", "--cached", "--quiet", authorityOid, "--", repositoryPath], {
    gitPath,
    allowFailure: true,
  });
  const working = git(repo, ["--literal-pathspecs", "diff", "--quiet", "--", repositoryPath], {
    gitPath,
    allowFailure: true,
  });
  if (staged.status !== 0 || working.status !== 0) fail(`${repositoryPath} differs from authority`);
  return git(repo, ["show", `${authorityOid}:${repositoryPath}`], {
    gitPath,
    label: `blob read for ${repositoryPath}`,
  }).stdout;
}

function treePaths(repo, authorityOid, root, gitPath) {
  const output = git(repo, ["ls-tree", "-r", "--name-only", "-z", authorityOid, "--", root], {
    gitPath,
    label: `tree enumeration for ${root}`,
  }).stdout.toString("utf8");
  if (!output.endsWith("\0")) fail(`${root} tree output is not NUL terminated`);
  return output.split("\0").slice(0, -1);
}

export function expectedArchivedManifest(repo, authorityOid, gitPath = TRUSTED_TOOLS.GIT) {
  const archivePaths = treePaths(repo, authorityOid, ARCHIVED_PHASE_ROOT, gitPath);
  const phaseDirs = [...new Set(archivePaths.map((path) => path.split("/").slice(0, 4).join("/")))];
  const phaseNumbers = phaseDirs.map((path) => path.split("/").at(-1)?.match(/^(\d+)-/)?.[1] ?? "");
  if (
    phaseDirs.length !== EXPECTED_PHASES.length ||
    phaseNumbers.some((phase, index) => phase !== EXPECTED_PHASES[index])
  ) {
    fail("archived phase layout is not exactly phases 161-165");
  }
  const fixed = [
    SOURCE_PATH,
    FINALIZER_PATH,
    `${ARCHIVE_ROOT}/v2.7-ROADMAP.md`,
    `${ARCHIVE_ROOT}/v2.7-REQUIREMENTS.md`,
    `${ARCHIVE_ROOT}/v2.7-MILESTONE-AUDIT.md`,
    ".planning/MILESTONES.md",
    ".planning/PROJECT.md",
    ".planning/STATE.md",
    ".planning/state.json",
    ".gitignore",
  ];
  const paths = [...fixed, ...archivePaths];
  if (paths.length !== new Set(paths).size) fail("closed manifest contains duplicate paths");
  return paths.map((path) => ({ path, executable: path === SOURCE_PATH || path === FINALIZER_PATH }));
}

export function authenticateClosedManifest(repo, authorityOid, gitPath = TRUSTED_TOOLS.GIT) {
  const manifest = expectedArchivedManifest(repo, authorityOid, gitPath);
  return manifest.map((entry) => ({
    ...entry,
    contents: authenticateCommitFile(repo, authorityOid, entry.path, gitPath),
  }));
}

function materialize(root, entry) {
  const destination = resolve(root, entry.path);
  if (!inside(root, destination)) fail("manifest path escaped private authority root");
  mkdirSync(dirname(destination), { recursive: true, mode: 0o700 });
  const mode = entry.executable ? 0o500 : 0o400;
  writeFileSync(destination, entry.contents, { flag: "wx", mode });
  chmodSync(destination, mode);
}

function exactRecord(record, expected) {
  return record && typeof record === "object" && Object.entries(expected).every(([key, value]) => record[key] === value);
}

export function selectExactAttemptOneCi(runs, authorityOid) {
  if (!Array.isArray(runs) || !FULL_OID.test(authorityOid)) fail("CI evidence input is invalid");
  const matches = runs.filter((run) =>
    exactRecord(run, {
      workflowName: "CI",
      event: "push",
      attempt: 1,
      headBranch: "main",
      headSha: authorityOid,
      status: "completed",
      conclusion: "success",
    }) && Number.isInteger(run.databaseId) && run.databaseId > 0,
  );
  if (matches.length !== 1) fail("expected one exact attempt-1 normal push CI record for authority OID");
  return matches[0];
}

export function selectNaturalSchedules(runs, authorityOid, expectedNames = EXPECTED_SCHEDULES) {
  if (!Array.isArray(runs) || !Array.isArray(expectedNames) || !FULL_OID.test(authorityOid)) {
    fail("scheduled evidence input is invalid");
  }
  const selected = expectedNames.map((workflowName) => {
    const matches = runs.filter((run) =>
      exactRecord(run, {
        workflowName,
        event: "schedule",
        attempt: 1,
        headBranch: "main",
        headSha: authorityOid,
        status: "completed",
        conclusion: "success",
      }) && Number.isInteger(run.databaseId) && run.databaseId > 0,
    );
    if (matches.length !== 1) fail(`expected one natural attempt-1 ${workflowName} schedule for authority OID`);
    return matches[0];
  });
  if (selected.length !== new Set(selected.map((run) => run.databaseId)).size) {
    fail("scheduled evidence reuses one run across controls");
  }
  return selected;
}

function safePredecessor(destination) {
  let entry;
  try {
    entry = lstatSync(destination);
  } catch (error) {
    if (error?.code === "ENOENT") return { disposition: "create" };
    fail("could not inspect installation predecessor");
  }
  const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
  if (!entry.isFile() || entry.isSymbolicLink() || !allowedOwners.has(entry.uid) || (entry.mode & 0o022) !== 0) {
    fail("installation predecessor is not a safe regular non-symlink file");
  }
  const digest = sha256(readFileSync(destination));
  return {
    disposition: "backup_replace",
    sha256: digest,
    mode: (entry.mode & 0o777).toString(8).padStart(4, "0"),
    uid: entry.uid,
    gid: entry.gid,
    backup: `${destination}.backup-${digest.slice(0, 16)}`,
  };
}

export function buildInstallationProposal(options = {}) {
  const repo = options.repo ?? CANONICAL_REPOSITORY;
  const destination = options.destination ?? INSTALLATION_DESTINATION;
  const tools = validateTrustedToolchain(options.tools ?? TRUSTED_TOOLS);
  const gitPath = tools.GIT;
  const authorityOid = options.authorityOid ?? captureAuthorityCommit(repo, gitPath);
  const source = authenticateCommitFile(repo, authorityOid, SOURCE_PATH, gitPath);
  const predecessor = safePredecessor(destination);
  const proposal = {
    proposal_schema: "mailglass-finalize-milestone-install-proposal-v1",
    milestone: SUPPORTED_MILESTONE,
    source_oid: authorityOid,
    source_sha256: sha256(source),
    destination,
    mode: "0500",
    runtime_closure: Object.entries(tools).map(([name, path]) => ({ name, path })),
    predecessor,
    rollback:
      predecessor.disposition === "create"
        ? { action: "remove_created", destination }
        : { action: "restore_backup", destination, backup: predecessor.backup, sha256: predecessor.sha256 },
  };
  // Re-lstat at the emission boundary. Any replacement invalidates the proposal.
  const rechecked = safePredecessor(destination);
  if (JSON.stringify(rechecked) !== JSON.stringify(predecessor)) fail("installation predecessor changed before proposal emission");
  return proposal;
}

export function writeTerminalReport(repo, reportPath, report, gitPath = TRUSTED_TOOLS.GIT) {
  const absolute = resolve(reportPath);
  if (!inside(repo, absolute)) fail("terminal report escapes repository");
  const relativePath = relative(repo, absolute);
  const tracked = git(repo, ["--literal-pathspecs", "ls-files", "--error-unmatch", "--", relativePath], {
    gitPath,
    allowFailure: true,
  });
  if (tracked.status === 0) fail("terminal report target is tracked");
  git(repo, ["check-ignore", "-q", "--", relativePath], {
    gitPath,
    label: "terminal report ignore check",
  });
  const temporary = `${absolute}.tmp-${randomBytes(8).toString("hex")}`;
  writeFileSync(temporary, `${JSON.stringify(report, null, 2)}\n`, { flag: "wx", mode: 0o600 });
  renameSync(temporary, absolute);
  return absolute;
}

function stageAndDispatch({ repo, authorityOid, authenticated, ciRun, schedules, reportPath, tools, fixture }) {
  const privateRoot = mkdtempSync(resolve(tmpdir(), "mailglass-finalize-v2-7-"));
  try {
    chmodSync(privateRoot, 0o700);
    for (const entry of authenticated) materialize(privateRoot, entry);
    const inputsPath = resolve(privateRoot, "terminal-inputs.json");
    writeFileSync(inputsPath, `${JSON.stringify({ ci: ciRun, schedules }, null, 2)}\n`, {
      flag: "wx",
      mode: 0o400,
    });
    chmodSync(inputsPath, 0o400);
    if (captureAuthorityCommit(repo, tools.GIT) !== authorityOid) {
      fail("authority commit changed before Bash dispatch");
    }
    const childEnv = buildChildEnvironment(tools);
    if (fixture) childEnv.MAILGLASS_MILESTONE_FIXTURE = "1";
    const finalizer = resolve(privateRoot, FINALIZER_PATH);
    const result = run(tools.BASH, [finalizer, repo, privateRoot, authorityOid, reportPath, inputsPath], {
      cwd: repo,
      env: childEnv,
      encoding: "utf8",
      label: "staged milestone finalizer",
    });
    return { output: bounded(result.stdout), report: JSON.parse(readFileSync(reportPath, "utf8")) };
  } finally {
    rmSync(privateRoot, { recursive: true, force: true });
  }
}

export function runFixtureFinalization(options) {
  const tools = options.tools ?? TRUSTED_TOOLS;
  const repo = realpathSync(options.repo);
  const authorityOid = options.authorityOid ?? captureAuthorityCommit(repo, tools.GIT);
  assertCleanRepository(repo, tools.GIT);
  const authenticated = authenticateClosedManifest(repo, authorityOid, tools.GIT);
  const ciRun = selectExactAttemptOneCi(options.ciRuns, authorityOid);
  const schedules = selectNaturalSchedules(options.scheduleRuns, authorityOid, options.expectedScheduleNames);
  const reportPath = resolve(repo, options.reportRelative ?? "tmp/phase-165-finalize.fixture/report.json");
  mkdirSync(dirname(reportPath), { recursive: true, mode: 0o700 });
  return stageAndDispatch({ repo, authorityOid, authenticated, ciRun, schedules, reportPath, tools, fixture: true });
}

function validateCanonicalRepository(gitPath) {
  let lexical;
  let repo;
  try {
    lexical = lstatSync(CANONICAL_REPOSITORY);
    repo = realpathSync(CANONICAL_REPOSITORY);
  } catch {
    fail("canonical repository is missing");
  }
  if (!lexical.isDirectory() || lexical.isSymbolicLink() || repo !== CANONICAL_REPOSITORY) {
    fail("canonical repository path is not the compiled physical checkout");
  }
  const origin = git(repo, ["remote", "get-url", "origin"], { gitPath, encoding: "utf8" }).stdout.trim();
  if (normalizedRepository(origin) !== EXPECTED_REPOSITORY) fail("canonical repository origin is not szTheory/mailglass");
  return repo;
}

function ghJson(tools, args, childEnv) {
  const result = run(tools.GH, args, { encoding: "utf8", env: childEnv, label: "read-only GitHub evidence query" });
  try {
    const parsed = JSON.parse(result.stdout);
    if (!Array.isArray(parsed)) fail("GitHub evidence response is not an array");
    return parsed;
  } catch (error) {
    fail(`GitHub evidence response is invalid JSON: ${bounded(error.message)}`);
  }
}

function finalizeMilestone() {
  const tools = validateTrustedToolchain();
  const repo = validateCanonicalRepository(tools.GIT);
  assertCleanRepository(repo, tools.GIT);
  const authorityOid = captureAuthorityCommit(repo, tools.GIT);
  const authenticated = authenticateClosedManifest(repo, authorityOid, tools.GIT);
  const childEnv = buildChildEnvironment(tools);
  const fields = "databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,createdAt";
  const ciRuns = ghJson(tools, ["run", "list", "--repo", EXPECTED_REPOSITORY, "--workflow", "CI", "--branch", "main", "--event", "push", "--status", "completed", "--limit", "100", "--json", fields], childEnv);
  const scheduleRuns = ghJson(tools, ["run", "list", "--repo", EXPECTED_REPOSITORY, "--branch", "main", "--event", "schedule", "--status", "completed", "--limit", "100", "--json", fields], childEnv);
  const ciRun = selectExactAttemptOneCi(ciRuns, authorityOid);
  const schedules = selectNaturalSchedules(scheduleRuns, authorityOid);
  const reportDir = resolve(repo, `tmp/phase-165-finalize.${randomBytes(4).toString("hex")}`);
  mkdirSync(reportDir, { recursive: false, mode: 0o700 });
  const result = stageAndDispatch({
    repo,
    authorityOid,
    authenticated,
    ciRun,
    schedules,
    reportPath: resolve(reportDir, "report.json"),
    tools,
    fixture: false,
  });
  if (captureAuthorityCommit(repo, tools.GIT) !== authorityOid) fail("authority commit changed after report write");
  assertCleanRepository(repo, tools.GIT);
  console.log(result.output.trim());
}

export function main(args = process.argv.slice(2)) {
  if (args.length === 1 && args[0] === "--version") {
    console.log(LOADER_IDENTITY);
    return;
  }
  if (args.length === 3 && args[0] === "--installation-proposal" && args[1] === "--destination") {
    if (args[2] !== INSTALLATION_DESTINATION) fail("installation proposal destination is not canonical");
    console.log(JSON.stringify(buildInstallationProposal({ destination: args[2] })));
    return;
  }
  if (args.length !== 1 || args[0] !== SUPPORTED_MILESTONE) fail("expected exact milestone token v2.7");
  finalizeMilestone();
}

const invokedPath = process.argv[1] ? realpathSync(process.argv[1]) : "";
if (invokedPath === realpathSync(fileURLToPath(import.meta.url))) {
  try {
    main();
  } catch (error) {
    console.error(bounded(error instanceof Error ? error.message : error));
    process.exitCode = 1;
  }
}
