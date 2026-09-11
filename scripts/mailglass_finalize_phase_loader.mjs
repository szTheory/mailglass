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
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const LOADER_IDENTITY = "mailglass-finalize-phase-loader 1";
const MAX_OUTPUT_BYTES = 16_000;
const SOURCE_PATH = "scripts/mailglass_finalize_phase_loader.mjs";
const SUPPORTED_PHASE = "164";
const CANONICAL_REPOSITORY = "/Users/jon/projects/mailglass";
const EXPECTED_REPOSITORY = "szTheory/mailglass";
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
const REQUIRED_TOOL_NAMES = Object.freeze([
  "NODE",
  "GIT",
  "BASH",
  "GH",
  "JQ",
  "MIX",
  "ELIXIR",
  "ERL",
]);
const EXPECTED_ELIXIR_VERSION = "1.19.5";
const EXPECTED_OTP_RELEASE = "28";
const TRUSTED_GIT = TRUSTED_TOOLS.GIT;
const TEST_ENV_KEYS = [];
const TERMINAL_FIRST_PLAN = 1;
const TERMINAL_LAST_PLAN = 39;
const PRE_VERIFICATION = "--pre-verification";
const FULL_OID = /^[0-9a-f]{40}$/;

const STATIC_DEPENDENCIES = [
  ["scripts/finalize_phase_164.sh", true],
  ["scripts/closeout_repository_truth.sh", true],
  ["scripts/verify_workspace_evidence.sh", true],
  ["scripts/validate_repository_truth.exs", true],
  ["scripts/ci_monitor.cjs", true],
  ["scripts/scheduled_control_evidence.sh", true],
  [".github/scheduled-controls.json", false],
  [
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md",
    false,
  ],
  [
    ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv",
    false,
  ],
  [".planning/ROADMAP.md", false],
  [".planning/REQUIREMENTS.md", false],
  [".gitignore", false],
  ["mailglass_admin/.gitignore", false],
  ["mailglass_inbound/.gitignore", false],
  ["reference/demo_app/.gitignore", false],
  ["reference/host_app/.gitignore", false],
  ["test/example/.gitignore", false],
  [".planning/release-target.json", false],
  [
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
    false,
  ],
  [
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md",
    false,
  ],
  [
    ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md",
    false,
  ],
  [".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md", false],
  [".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md", false],
].map(([path, executable]) => ({ path, executable }));

function fail(message) {
  throw new Error(`finalize-phase: ${message}`);
}

function bounded(message) {
  return String(message).slice(-MAX_OUTPUT_BYTES);
}

function inside(root, candidate) {
  const fromRoot = relative(root, candidate);
  return fromRoot === "" || (fromRoot !== ".." && !fromRoot.startsWith(`..${sep}`));
}

function git(repo, args, options = {}) {
  const result = spawnSync(TRUSTED_GIT, args, {
    cwd: repo,
    encoding: options.encoding ?? null,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    if (options.allowFailure) return result;
    const detail = bounded(result.stderr?.toString() || result.error?.message || "git failed");
    fail(`${options.label ?? "Git operation"} failed: ${detail}`);
  }
  return result;
}

export function validateTrustedToolchain(tools = TRUSTED_TOOLS) {
  const allowedOwners = new Set([0, process.getuid?.()].filter(Number.isInteger));
  for (const name of REQUIRED_TOOL_NAMES) {
    const path = tools[name];
    if (typeof path !== "string" || path.length === 0) fail(`trusted ${name} executable is missing`);
    if (!isAbsolute(path)) fail(`trusted ${name} path is not absolute`);
    if (path.includes("/.asdf/shims/")) fail(`trusted ${name} executable must not be an asdf shim`);
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
  for (const name of [
    "HOME",
    "TMPDIR",
    "LANG",
    "LC_ALL",
    "USER",
    "LOGNAME",
    "SSH_AUTH_SOCK",
    "GH_TOKEN",
    "GITHUB_TOKEN",
    ...TEST_ENV_KEYS,
  ]) {
    if (process.env[name]) env[name] = process.env[name];
  }
  env.MAILGLASS_NODE = tools.NODE;
  env.MAILGLASS_GIT = tools.GIT;
  env.MAILGLASS_BASH = tools.BASH;
  env.MAILGLASS_GH = tools.GH;
  env.MAILGLASS_JQ = tools.JQ;
  env.MAILGLASS_MIX = tools.MIX;
  env.MAILGLASS_ELIXIR = tools.ELIXIR;
  env.MAILGLASS_ERL = tools.ERL;
  env.GH_HOST = "github.com";
  env.PATH = [...new Set(Object.values(tools).map(dirname).concat(["/usr/bin", "/bin"]))].join(":");
  return env;
}

function probeCommand(path, args, childEnv, label) {
  const result = spawnSync(path, args, {
    encoding: "utf8",
    env: childEnv,
    timeout: 10_000,
    maxBuffer: 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    const detail = bounded(result.stderr || result.stdout || result.error?.message || "probe failed");
    fail(`${label} probe failed: ${detail}`);
  }
  const output = String(result.stdout || "").trim();
  if (output.length === 0) fail(`${label} probe returned empty output`);
  return output;
}

export function probeTrustedRuntime(tools = TRUSTED_TOOLS, childEnv = buildChildEnvironment(tools)) {
  validateTrustedToolchain(tools);
  const expectedPath = [
    ...new Set(Object.values(tools).map(dirname).concat(["/usr/bin", "/bin"])),
  ].join(":");
  if (childEnv.PATH !== expectedPath) fail("trusted runtime PATH differs from authenticated tool closure");
  if (Object.keys(childEnv).some((name) => name.startsWith("ASDF_"))) {
    fail("trusted runtime environment contains ASDF selectors");
  }

  const mixOutput = probeCommand(tools.MIX, ["--version"], childEnv, "Mix");
  const elixirOutput = probeCommand(tools.ELIXIR, ["--version"], childEnv, "Elixir");
  const otpRelease = probeCommand(
    tools.ERL,
    ["-noshell", "-eval", 'io:format("~s", [erlang:system_info(otp_release)]), halt().'],
    childEnv,
    "Erlang",
  );
  const mixVersion = mixOutput.split("\n").find((line) => line.startsWith("Mix ")) || "";
  const elixirVersion = elixirOutput.split("\n").find((line) => line.startsWith("Elixir ")) || "";
  if (
    !mixVersion.startsWith(`Mix ${EXPECTED_ELIXIR_VERSION} `) ||
    !mixVersion.includes(`Erlang/OTP ${EXPECTED_OTP_RELEASE}`) ||
    !elixirVersion.startsWith(`Elixir ${EXPECTED_ELIXIR_VERSION} `) ||
    !elixirVersion.includes(`Erlang/OTP ${EXPECTED_OTP_RELEASE}`) ||
    otpRelease !== EXPECTED_OTP_RELEASE
  ) {
    fail("trusted runtime versions are incompatible with the approved BEAM closure");
  }
  const probe = {
    mix_version: mixVersion,
    elixir_version: elixirVersion,
    otp_release: otpRelease,
  };
  return {
    ...probe,
    digest: createHash("sha256").update(JSON.stringify(probe)).digest("hex"),
  };
}

function normalizedRepository(url) {
  const match = String(url).trim().match(
    /^(?:git@github\.com:|https:\/\/github\.com\/|ssh:\/\/git@github\.com\/)([^/]+\/[^/]+?)(?:\.git)?$/,
  );
  return match?.[1] ?? "";
}

export function validateCanonicalRepository() {
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
  const origin = git(repo, ["remote", "get-url", "origin"], {
    encoding: "utf8",
    label: "canonical origin authentication",
  }).stdout.trim();
  if (normalizedRepository(origin) !== EXPECTED_REPOSITORY) {
    fail("canonical repository origin is not szTheory/mailglass");
  }
  return repo;
}

export function captureAuthorityCommit(repo) {
  const oid = git(repo, ["rev-parse", "--verify", "HEAD^{commit}"], {
    encoding: "utf8",
    label: "authority commit capture",
  }).stdout.trim();
  if (!FULL_OID.test(oid)) fail("authority commit is not a full lowercase OID");
  return oid;
}

export function expectedPhaseArtifacts(phaseRelative) {
  const paths = [];
  for (let plan = TERMINAL_FIRST_PLAN; plan <= TERMINAL_LAST_PLAN; plan += 1) {
    const number = String(plan).padStart(2, "0");
    paths.push(`${phaseRelative}/164-${number}-PLAN.md`);
    paths.push(`${phaseRelative}/164-${number}-SUMMARY.md`);
  }
  return paths;
}

function exactIndexRecord(repo, repositoryPath) {
  const result = git(
    repo,
    ["--literal-pathspecs", "ls-files", "--stage", "-z", "--", repositoryPath],
    { label: `index authentication for ${repositoryPath}` },
  );
  const fields = result.stdout.toString("utf8").split("\0");
  if (fields.at(-1) !== "") fail(`${repositoryPath} index output is not NUL terminated`);
  const records = fields.slice(0, -1);
  if (records.length !== 1) fail(`${repositoryPath} does not have exactly one index record`);
  const match = records[0].match(/^\d{6} [0-9a-f]{40} 0\t(.+)$/s);
  if (!match || match[1] !== repositoryPath) fail(`${repositoryPath} is not one exact stage-0 path`);
}

export function authenticateCommitFile(repo, authorityOid, repositoryPath) {
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
    encoding: "utf8",
    label: `object authentication for ${repositoryPath}`,
  }).stdout.trim();
  if (type !== "blob") fail(`${repositoryPath} is not a blob at the authority commit`);
  exactIndexRecord(repo, repositoryPath);

  const staged = git(
    repo,
    ["--literal-pathspecs", "diff", "--cached", "--quiet", authorityOid, "--", repositoryPath],
    { allowFailure: true },
  );
  const working = git(repo, ["--literal-pathspecs", "diff", "--quiet", "--", repositoryPath], {
    allowFailure: true,
  });
  if (staged.status !== 0 || working.status !== 0) fail(`${repositoryPath} differs from authority`);

  return git(repo, ["show", `${authorityOid}:${repositoryPath}`], {
    label: `blob read for ${repositoryPath}`,
  }).stdout;
}

function capturedTreePaths(repo, authorityOid, treePath) {
  const output = git(repo, ["ls-tree", "-r", "--name-only", "-z", authorityOid, "--", treePath], {
    label: `tree enumeration for ${treePath}`,
  }).stdout.toString("utf8");
  if (!output.endsWith("\0")) fail(`${treePath} tree output is not NUL terminated`);
  const paths = output.split("\0").slice(0, -1);
  if (paths.length === 0 || new Set(paths).size !== paths.length) {
    fail(`${treePath} tree is empty or duplicated`);
  }
  return paths;
}

function phaseDirectoryAtCommit(repo, authorityOid) {
  const paths = capturedTreePaths(repo, authorityOid, ".planning/phases");
  const directories = new Set(
    paths
      .filter((path) => path.startsWith(".planning/phases/164-"))
      .map((path) => path.split("/").slice(0, 3).join("/")),
  );
  if (directories.size !== 1) fail("expected exactly one Phase 164 directory at authority commit");
  return [...directories][0];
}

function exactNumberedArtifacts(repo, authorityOid, phaseRelative) {
  const expected = expectedPhaseArtifacts(phaseRelative);
  const escaped = phaseRelative.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const numberedPattern = new RegExp(`^${escaped}/164-\\d{2}-(?:PLAN|SUMMARY)\\.md$`);
  const numberedLikePattern = new RegExp(
    `^${escaped}/164-\\d.*-(?:PLAN|SUMMARY)(?:\\.|$)`,
  );
  const phasePaths = capturedTreePaths(repo, authorityOid, phaseRelative);
  const actual = phasePaths.filter((path) => numberedPattern.test(path));
  const numberedLike = phasePaths.filter((path) => numberedLikePattern.test(path));
  if (
    numberedLike.length !== actual.length ||
    actual.length !== expected.length ||
    new Set(actual).size !== actual.length ||
    expected.some((path) => !actual.includes(path))
  ) {
    fail("authenticated Phase 164 numbered history is not the exact 01-39 PLAN/SUMMARY set");
  }
  return expected;
}

function dependencyManifest(repo, authorityOid, phaseRelative) {
  const phaseDependencies = [
    `${phaseRelative}/164-TRUTH-DISPOSITION.tsv`,
    `${phaseRelative}/164-VERIFICATION.md`,
    `${phaseRelative}/164-VALIDATION.md`,
    `${phaseRelative}/164-FINALIZATION.md`,
  ].map((path) => ({ path, executable: false }));
  const numbered = exactNumberedArtifacts(repo, authorityOid, phaseRelative).map((path) => ({
    path,
    executable: false,
  }));
  const publish = capturedTreePaths(repo, authorityOid, ".planning/publish").map((path) => ({
    path,
    executable: false,
  }));
  const dependencies = [...STATIC_DEPENDENCIES, ...phaseDependencies, ...numbered, ...publish];
  if (new Set(dependencies.map(({ path }) => path)).size !== dependencies.length) {
    fail("dependency manifest contains duplicate paths");
  }
  return dependencies;
}

function materialize(root, dependency, contents) {
  const destination = resolve(root, dependency.path);
  if (!inside(root, destination)) fail("dependency path escaped private authority root");
  mkdirSync(dirname(destination), { recursive: true, mode: 0o700 });
  const mode = dependency.executable ? 0o500 : 0o400;
  writeFileSync(destination, contents, { flag: "wx", mode });
  chmodSync(destination, mode);
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

function assertCleanRepository(repo) {
  const status = git(repo, ["status", "--porcelain=v1", "--untracked-files=all"], {
    encoding: "utf8",
    label: "clean repository check",
  }).stdout;
  if (status !== "") fail("repository is not clean");
}

function selfCheck(args) {
  const tools = validateTrustedToolchain();
  const childEnv = buildChildEnvironment(tools);
  const runtimeProbe = probeTrustedRuntime(tools, childEnv);
  const { repoArgument, expectedSourceOid } = parseSelfCheck(args);
  if (!isAbsolute(repoArgument) || !FULL_OID.test(expectedSourceOid)) {
    fail("self-check requires an absolute repository and full lowercase source OID");
  }
  const repo = realpathSync(repoArgument);
  if (resolve(repoArgument) !== repo) fail("repository path is not canonical");
  const executableLexical = fileURLToPath(import.meta.url);
  const executableStat = lstatSync(executableLexical);
  const executable = realpathSync(executableLexical);
  if (!executableStat.isFile() || executableStat.isSymbolicLink() || inside(repo, executable)) {
    fail("self-check executable must be a regular non-symlink outside the repository");
  }
  const mode = statSync(executable).mode & 0o777;
  if (mode !== 0o500) fail("self-check executable mode is not 0500");
  assertCleanRepository(repo);
  git(repo, ["cat-file", "-e", `${expectedSourceOid}^{commit}`], {
    label: "installation commit validation",
  });
  const installedBytes = readFileSync(executable);
  const installationBytes = authenticateCommitFile(repo, expectedSourceOid, SOURCE_PATH);
  if (!installedBytes.equals(installationBytes)) fail("installed bytes do not match installation OID");
  const currentOid = captureAuthorityCommit(repo);
  const currentBytes = authenticateCommitFile(repo, currentOid, SOURCE_PATH);
  if (!installedBytes.equals(currentBytes)) fail("current HEAD loader source differs from installed bytes");
  if (!installationOidIsAncestor(repo, expectedSourceOid, currentOid)) {
    fail("installation OID is not an ancestor of current authority OID");
  }
  if (TERMINAL_FIRST_PLAN !== 1 || TERMINAL_LAST_PLAN !== 39) fail("compiled terminal range is invalid");
  const digest = createHash("sha256").update(installedBytes).digest("hex");
  console.log(`installation_oid=${expectedSourceOid}`);
  console.log(`current_oid=${currentOid}`);
  console.log(`loader_sha256=${digest}`);
  console.log(`executable=${executable}`);
  console.log("mode=0500");
  console.log("terminal_range=01-39");
  console.log(`mix_version=${runtimeProbe.mix_version}`);
  console.log(`elixir_version=${runtimeProbe.elixir_version}`);
  console.log(`otp_release=${runtimeProbe.otp_release}`);
  console.log(`runtime_probe_sha256=${runtimeProbe.digest}`);
}

export function installationOidIsAncestor(repo, installationOid, currentOid) {
  const result = git(repo, ["merge-base", "--is-ancestor", installationOid, currentOid], {
    allowFailure: true,
  });
  return result.status === 0;
}

function finalize(args) {
  const valid = args.length === 1 || (args.length === 2 && args[1] === PRE_VERIFICATION);
  if (!valid || args[0] !== SUPPORTED_PHASE) {
    fail("expected phase 164 and optional --pre-verification");
  }
  const tools = validateTrustedToolchain();
  const childEnv = buildChildEnvironment(tools);
  probeTrustedRuntime(tools, childEnv);
  const repo = validateCanonicalRepository();
  const authorityOid = captureAuthorityCommit(repo);
  const phaseRelative = phaseDirectoryAtCommit(repo, authorityOid);
  const dependencies = dependencyManifest(repo, authorityOid, phaseRelative);
  const authenticated = dependencies.map((dependency) => ({
    dependency,
    contents: authenticateCommitFile(repo, authorityOid, dependency.path),
  }));
  const privateRoot = mkdtempSync(resolve(tmpdir(), "mailglass-finalize-164-"));
  try {
    chmodSync(privateRoot, 0o700);
    for (const item of authenticated) materialize(privateRoot, item.dependency, item.contents);
    const currentOid = captureAuthorityCommit(repo);
    if (currentOid !== authorityOid) fail("authority commit changed before Bash dispatch");
    const finalizer = resolve(privateRoot, "scripts/finalize_phase_164.sh");
    const modeArgs = args.length === 2 ? [PRE_VERIFICATION] : [];
    const result = spawnSync(
      tools.BASH,
      [finalizer, repo, privateRoot, authorityOid, ...modeArgs],
      {
        cwd: repo,
        encoding: "utf8",
        maxBuffer: 16 * 1024 * 1024,
        env: childEnv,
      },
    );
    const output = bounded([result.stdout?.trim(), result.stderr?.trim()].filter(Boolean).join("\n"));
    if (result.error || result.status !== 0) {
      fail(`finalizer exited with status ${result.status ?? 1}: ${output || "(no output)"}`);
    }
    if (output) console.log(output);
  } finally {
    rmSync(privateRoot, { recursive: true, force: true });
  }
}

export function main(args = process.argv.slice(2)) {
  if (args.length === 1 && args[0] === "--version") {
    console.log(LOADER_IDENTITY);
    return;
  }
  if (args[0] === "--self-check") return selfCheck(args);
  return finalize(args);
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
