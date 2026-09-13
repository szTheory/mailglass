#!/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node

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
const TRUSTED_TOOL_SPECS = Object.freeze({
  NODE: Object.freeze({
    path: "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node",
    sha256: "27db838bb204ef7c21df2931f5656e4c8fb32e6e947f363a402b49714d32b5b1",
    version: "v24.19.0",
    versionArgs: Object.freeze(["--version"]),
  }),
  GIT: Object.freeze({
    path: "/opt/homebrew/Cellar/git/2.41.0/bin/git",
    sha256: "8a685463cdb7b0bd80507a3978bd1720a97475c9326c186916b228d55242b450",
    version: "git version 2.41.0",
    versionArgs: Object.freeze(["--version"]),
  }),
  BASH: Object.freeze({
    path: "/opt/homebrew/Cellar/bash/5.2.37/bin/bash",
    sha256: "956cc46a1c898cdcbf1f41ba129bfc4e992df6ea112ea7082d227c5a3cc05bab",
    version: "GNU bash, version 5.2.37(1)-release (aarch64-apple-darwin24.2.0)",
    versionArgs: Object.freeze(["--version"]),
  }),
  GH: Object.freeze({
    path: "/opt/homebrew/Cellar/gh/2.95.0/bin/gh",
    sha256: "798882434e7f6ae5846194191263ecc59d56bc201f13f016270f44cb4f34499e",
    version: "gh version 2.95.0 (2026-06-17)",
    versionArgs: Object.freeze(["--version"]),
  }),
  JQ: Object.freeze({
    path: "/usr/bin/jq",
    sha256: "b16bc93b2f3c69ce3134f20b796bb72aa3410b10166566ac2ca1bee5e4153ed5",
    version: "jq-1.7.1-apple",
    versionArgs: Object.freeze(["--version"]),
  }),
});
const TRUSTED_TOOLS = Object.freeze(
  Object.fromEntries(Object.entries(TRUSTED_TOOL_SPECS).map(([name, spec]) => [name, spec.path])),
);
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
    const expected = TRUSTED_TOOL_SPECS[name];
    if (
      typeof path !== "string" ||
      path !== expected.path ||
      !isAbsolute(path) ||
      path.includes("/.asdf/shims/")
    ) {
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
    if (sha256(readFileSync(path)) !== expected.sha256) {
      fail(`trusted ${name} executable digest drifted`);
    }
    const version = run(path, expected.versionArgs, {
      encoding: "utf8",
      label: `trusted ${name} version probe`,
    }).stdout.split("\n")[0].trim();
    if (version !== expected.version) fail(`trusted ${name} executable version drifted`);
  }
  return tools;
}

export function trustedToolClosure(tools = TRUSTED_TOOLS) {
  validateTrustedToolchain(tools);
  return REQUIRED_TOOL_NAMES.map((name) => ({
    name,
    path: tools[name],
    sha256: TRUSTED_TOOL_SPECS[name].sha256,
    version: TRUSTED_TOOL_SPECS[name].version,
  }));
}

export function buildChildEnvironment(tools = TRUSTED_TOOLS) {
  const env = {};
  for (const key of ["HOME", "TMPDIR", "LANG", "LC_ALL", "USER", "LOGNAME", "SSH_AUTH_SOCK", "GH_TOKEN", "GITHUB_TOKEN"]) {
    if (process.env[key]) env[key] = process.env[key];
  }
  for (const [name, path] of Object.entries(tools)) env[`MAILGLASS_${name}`] = path;
  env.GH_HOST = "github.com";
  // The staged Bash script uses only system utilities by bare name. Keeping
  // user-owned tool directories out of PATH prevents grep/mktemp/etc. shadowing;
  // non-system tools are invoked through their MAILGLASS_* absolute paths.
  env.PATH = "/usr/bin:/bin";
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
  if (output === "") return [];
  if (!output.endsWith("\0")) fail(`${root} tree output is not NUL terminated`);
  return output.split("\0").slice(0, -1);
}

export function expectedArchivedManifest(repo, authorityOid, gitPath = TRUSTED_TOOLS.GIT) {
  const milestonePaths = treePaths(repo, authorityOid, ARCHIVE_ROOT, gitPath);
  const unexpectedV27 = milestonePaths.filter(
    (path) =>
      path.startsWith(`${ARCHIVE_ROOT}/v2.7`) &&
      !path.startsWith(`${ARCHIVED_PHASE_ROOT}/`) &&
      ![
        `${ARCHIVE_ROOT}/v2.7-ROADMAP.md`,
        `${ARCHIVE_ROOT}/v2.7-REQUIREMENTS.md`,
        `${ARCHIVE_ROOT}/v2.7-MILESTONE-AUDIT.md`,
      ].includes(path),
  );
  if (unexpectedV27.length > 0) fail("legacy quick-task or unknown v2.7 archive content is present");

  const livePhasePaths = treePaths(repo, authorityOid, ".planning/phases", gitPath).filter((path) =>
    EXPECTED_PHASES.some((phase) => path.startsWith(`.planning/phases/${phase}-`)),
  );
  if (livePhasePaths.length > 0) fail("live/archive lifecycle disagreement");
  if (treePaths(repo, authorityOid, ".planning/REQUIREMENTS.md", gitPath).length > 0) {
    fail("live REQUIREMENTS.md remains after milestone archive");
  }

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
    ".planning/ROADMAP.md",
    ".planning/RETROSPECTIVE.md",
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

function requirePhysicalParentChain(destination, label) {
  if (!isAbsolute(destination) || resolve(destination) !== destination) {
    fail(`${label} is not one normalized absolute path`);
  }
  const parents = [];
  let current = dirname(destination);
  while (true) {
    parents.push(current);
    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }
  for (const parent of parents.reverse()) {
    let entry;
    let physical;
    try {
      entry = lstatSync(parent);
      physical = realpathSync(parent);
    } catch {
      fail(`${label} parent is missing`);
    }
    if (!entry.isDirectory() || entry.isSymbolicLink() || physical !== parent) {
      fail(`${label} parent is not one physical directory`);
    }
  }
  return dirname(destination);
}

function safePredecessor(destination) {
  requirePhysicalParentChain(destination, "installation destination");
  let entry;
  try {
    entry = lstatSync(destination);
  } catch (error) {
    if (error?.code === "ENOENT") return { disposition: "create" };
    fail("could not inspect installation predecessor");
  }
  const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
  if (!entry.isFile() || entry.isSymbolicLink()) fail("installation predecessor has unsafe predecessor kind");
  if (!allowedOwners.has(entry.uid)) fail("installation predecessor has unsafe ownership");
  if ((entry.mode & 0o022) !== 0) fail("installation predecessor has unsafe mode");
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
  const runtimeClosure = trustedToolClosure(tools);
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
    runtime_closure: runtimeClosure,
    predecessor,
    rollback:
      predecessor.disposition === "create"
        ? { action: "remove_created", destination }
        : { action: "restore_backup", destination, backup: predecessor.backup, sha256: predecessor.sha256 },
  };
  // Re-lstat at the emission boundary. Any replacement invalidates the proposal.
  const rechecked = safePredecessor(destination);
  if (JSON.stringify(rechecked) !== JSON.stringify(predecessor)) fail("installation predecessor changed before proposal emission");
  if (JSON.stringify(trustedToolClosure(tools)) !== JSON.stringify(runtimeClosure)) {
    fail("trusted runtime closure changed before proposal emission");
  }
  return proposal;
}

export function terminalReceiptPath(repo, authorityOid) {
  if (!FULL_OID.test(authorityOid)) fail("terminal receipt authority OID is invalid");
  return resolve(repo, `tmp/mailglass-finalize-v2.7-${authorityOid}/report.json`);
}

function prepareTerminalReceipt(repo, authorityOid, gitPath) {
  const tmpRoot = resolve(repo, "tmp");
  if (!inside(repo, tmpRoot)) fail("terminal report root escapes repository");
  requirePhysicalParentChain(resolve(tmpRoot, "receipt"), "terminal report root");
  let tmpEntry;
  try {
    tmpEntry = lstatSync(tmpRoot);
  } catch {
    fail("terminal report root is missing");
  }
  if (!tmpEntry.isDirectory() || tmpEntry.isSymbolicLink() || realpathSync(tmpRoot) !== tmpRoot) {
    fail("terminal report root is not a physical repository directory");
  }
  const reportPath = terminalReceiptPath(repo, authorityOid);
  const reportDir = dirname(reportPath);
  const relativePath = relative(repo, reportPath);
  const tracked = git(repo, ["--literal-pathspecs", "ls-files", "--error-unmatch", "--", relativePath], {
    gitPath,
    allowFailure: true,
  });
  if (tracked.status === 0) fail("terminal report target is tracked");
  git(repo, ["check-ignore", "-q", "--", relativePath], {
    gitPath,
    label: "terminal report ignore check",
  });
  try {
    mkdirSync(reportDir, { recursive: false, mode: 0o700 });
  } catch (error) {
    if (error?.code === "EEXIST") fail("terminal invocation receipt already exists for milestone and authority OID");
    fail("could not create terminal invocation receipt");
  }
  const reportDirEntry = lstatSync(reportDir);
  if (!reportDirEntry.isDirectory() || reportDirEntry.isSymbolicLink() || realpathSync(reportDir) !== reportDir) {
    fail("terminal invocation receipt is not one physical directory");
  }
  return reportPath;
}

function stageAndDispatch({
  repo,
  authorityOid,
  authenticated,
  ciRun,
  schedules,
  reportPath,
  tools,
  executable,
  runtimeClosure,
}) {
  const privateRoot = mkdtempSync(resolve(tmpdir(), "mailglass-finalize-v2-7-"));
  try {
    chmodSync(privateRoot, 0o700);
    for (const entry of authenticated) materialize(privateRoot, entry);
    const inputsPath = resolve(privateRoot, "terminal-inputs.json");
    const revalidatedClosure = trustedToolClosure(tools);
    if (JSON.stringify(revalidatedClosure) !== JSON.stringify(runtimeClosure)) {
      fail("trusted runtime closure changed before staged dispatch");
    }
    writeFileSync(inputsPath, `${JSON.stringify({ ci: ciRun, schedules, executable, runtime_closure: runtimeClosure }, null, 2)}\n`, {
      flag: "wx",
      mode: 0o400,
    });
    chmodSync(inputsPath, 0o400);
    if (captureAuthorityCommit(repo, tools.GIT) !== authorityOid) {
      fail("authority commit changed before Bash dispatch");
    }
    const childEnv = buildChildEnvironment(tools);
    if (JSON.stringify(trustedToolClosure(tools)) !== JSON.stringify(runtimeClosure)) {
      fail("trusted runtime closure changed before finalizer invocation");
    }
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

function parseSelfCheck(args) {
  if (
    args.length !== 5 ||
    args[0] !== "--self-check" ||
    args[1] !== "--repo" ||
    args[3] !== "--expected-source-oid"
  ) {
    fail("expected --self-check --repo ABSOLUTE --expected-source-oid FULL_OID");
  }
  return { repoArgument: args[2], expectedSourceOid: args[4] };
}

export function verifyInstalledExecutable(options) {
  const tools = validateTrustedToolchain(options.tools ?? TRUSTED_TOOLS);
  const repo = realpathSync(options.repo);
  const expectedSourceOid = options.expectedSourceOid;
  const executableLexical = resolve(options.executable);
  if (!FULL_OID.test(expectedSourceOid)) fail("installed executable authority OID is invalid");
  if (inside(repo, executableLexical)) fail("installed executable must be external to the repository");
  requirePhysicalParentChain(executableLexical, "installed executable");
  let executableEntry;
  let executable;
  try {
    executableEntry = lstatSync(executableLexical);
    executable = realpathSync(executableLexical);
  } catch {
    fail("installed executable is missing");
  }
  const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
  if (!executableEntry.isFile() || executableEntry.isSymbolicLink() || executable !== executableLexical) {
    fail("installed executable is not one physical regular file");
  }
  if (!allowedOwners.has(executableEntry.uid)) fail("installed executable has unsafe ownership");
  if ((executableEntry.mode & 0o777) !== 0o500) fail("installed executable mode is not 0500");
  const installedBytes = readFileSync(executable);
  const approvedBytes = authenticateCommitFile(repo, expectedSourceOid, SOURCE_PATH, tools.GIT);
  if (!installedBytes.equals(approvedBytes)) fail("installed-byte mismatch");
  return {
    path: executable,
    sha256: sha256(installedBytes),
    source_oid: expectedSourceOid,
    mode: "0500",
    uid: executableEntry.uid,
    gid: executableEntry.gid,
  };
}

function selfCheck(args) {
  const tools = validateTrustedToolchain();
  const { repoArgument, expectedSourceOid } = parseSelfCheck(args);
  if (!isAbsolute(repoArgument) || !FULL_OID.test(expectedSourceOid)) fail("self-check input is invalid");
  const repo = realpathSync(repoArgument);
  const executableLexical = fileURLToPath(import.meta.url);
  const evidence = verifyInstalledExecutable({ repo, expectedSourceOid, executable: executableLexical, tools });
  const currentOid = captureAuthorityCommit(repo, tools.GIT);
  const ancestry = git(repo, ["merge-base", "--is-ancestor", expectedSourceOid, currentOid], {
    gitPath: tools.GIT,
    allowFailure: true,
  });
  if (ancestry.status !== 0) fail("installation OID is not an ancestor of current authority");
  trustedToolClosure(tools);
  console.log(`installation_oid=${expectedSourceOid}`);
  console.log(`current_oid=${currentOid}`);
  console.log(`loader_sha256=${evidence.sha256}`);
  console.log(`executable=${evidence.path}`);
  console.log("mode=0500");
}

function authenticateRunningInstallation(repo, authorityOid, tools, runtimeClosure) {
  const invoked = process.argv[1] ? resolve(process.argv[1]) : "";
  const modulePath = fileURLToPath(import.meta.url);
  if (invoked !== INSTALLATION_DESTINATION || modulePath !== INSTALLATION_DESTINATION) {
    fail("terminal executable is not the approved installation destination");
  }
  if (realpathSync(process.execPath) !== tools.NODE) {
    fail("terminal executable is not running under the approved Node runtime");
  }
  const evidence = verifyInstalledExecutable({
    repo,
    expectedSourceOid: authorityOid,
    executable: modulePath,
    tools,
  });
  if (JSON.stringify(trustedToolClosure(tools)) !== JSON.stringify(runtimeClosure)) {
    fail("trusted runtime closure changed at installed boundary");
  }
  return evidence;
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

function ghJson(tools, runtimeClosure, args, childEnv) {
  if (JSON.stringify(trustedToolClosure(tools)) !== JSON.stringify(runtimeClosure)) {
    fail("trusted runtime closure changed before GitHub evidence query");
  }
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
  const runtimeClosure = trustedToolClosure(tools);
  const repo = validateCanonicalRepository(tools.GIT);
  assertCleanRepository(repo, tools.GIT);
  const authorityOid = captureAuthorityCommit(repo, tools.GIT);
  const authenticated = authenticateClosedManifest(repo, authorityOid, tools.GIT);
  const executable = authenticateRunningInstallation(repo, authorityOid, tools, runtimeClosure);
  const reportPath = prepareTerminalReceipt(repo, authorityOid, tools.GIT);
  const childEnv = buildChildEnvironment(tools);
  const fields = "databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,createdAt";
  const ciRuns = ghJson(tools, runtimeClosure, ["run", "list", "--repo", EXPECTED_REPOSITORY, "--workflow", "CI", "--branch", "main", "--event", "push", "--status", "completed", "--limit", "100", "--json", fields], childEnv);
  const scheduleRuns = ghJson(tools, runtimeClosure, ["run", "list", "--repo", EXPECTED_REPOSITORY, "--branch", "main", "--event", "schedule", "--status", "completed", "--limit", "100", "--json", fields], childEnv);
  const ciRun = selectExactAttemptOneCi(ciRuns, authorityOid);
  const schedules = selectNaturalSchedules(scheduleRuns, authorityOid);
  const result = stageAndDispatch({
    repo,
    authorityOid,
    authenticated,
    ciRun,
    schedules,
    reportPath,
    tools,
    executable,
    runtimeClosure,
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
  if (args[0] === "--self-check") return selfCheck(args);
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
