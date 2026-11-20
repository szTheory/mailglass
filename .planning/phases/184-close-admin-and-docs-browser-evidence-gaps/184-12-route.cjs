#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const { createHash, randomUUID } = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { gunzipSync } = require("node:zlib");

const OWNER = path.resolve(__dirname, "../../..");
const ROUTE = "/private/tmp/mailglass-v211-phase184-12";
const PREFLIGHT = "/private/tmp/mailglass-v211-phase184-12-preflight";
const SCRATCH = "/private/tmp/mailglass-v211-phase184-12-scratch";
const SOURCE = path.join(ROUTE, "source");
const ROOT_MARKER = ".route-owner.json";
const EVIDENCE = path.join(__dirname, "184-12-EVIDENCE.json");
const RETAINED = path.join(__dirname, "184-12-retained");
const CUSTODY = path.join(RETAINED, "custody.jsonl");
const TDD_RECORD = path.join(RETAINED, "tdd-red-evidence.json");
const PLAN = path.join(__dirname, "184-12-PLAN.md");
const PATCH_RELATIVE = ".planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-07-CANDIDATE.patch";
const PATCH = path.join(OWNER, PATCH_RELATIVE);
const PATCH_HASH = "b2c7c557cd21d1c5a82633a94e081005f68bd70412f4f3e3e145d02525206907";
const HEX_HELPER = path.join(__dirname, "184-07-deps-prep.exs");
const HEX_HELPER_HASH = "9a8ee9b59e8c27dbb0aac68b2f1bef3a4f91a9c0844418d91568cdd6e66fd456";
const BASE = "a295e9a950e14d7ce3ec9456f31fbda864933580";
const TREE = "55274beccd045fff361aead1732b14e5e00d587f";
const REMOTE = "https://github.com/szTheory/mailglass.git";
const REPOSITORY = "szTheory/mailglass";
const BASE_REF = "refs/heads/gsd/v2.11-phase182-admin-evidence";
const BRANCH = "gsd/v2.11-phase184-12-evidence";
const WORKFLOW = "265569665";
const MIX_HOME = path.join(os.homedir(), ".mix");
const ROUTE_MIX_HOME = path.join(ROUTE, "cache", "mix");
const HEX_CACHE = path.join(os.homedir(), ".hex");
const REGISTRY_CACHE = path.join(HEX_CACHE, "cache.bin");
const ELIXIR_BIN = path.join(os.homedir(), ".asdf/installs/elixir/1.18.4-otp-27/bin");
const OTP_BIN = path.join(os.homedir(), ".asdf/installs/erlang/27.3.4.13/bin");
const HEX_EBIN = path.join(MIX_HOME, "archives/hex-2.6.0/hex-2.6.0/ebin");
const REBAR3 = path.join(MIX_HOME, "elixir/1-18-otp-27/rebar3");
const IMAGE = "mcr.microsoft.com/playwright:v1.65.1-noble";
const PLAYWRIGHT_PACKAGE = path.join(OWNER, "mailglass_admin/node_modules/playwright/package.json");
const PLAYWRIGHT_CORE_PACKAGE = path.join(OWNER, "mailglass_admin/node_modules/playwright-core/package.json");
const LOCKS = ["mix.lock", "mailglass_admin/mix.lock", "mailglass_inbound/mix.lock",
  "reference/demo_app/mix.lock", "reference/host_app/mix.lock"];
const WORKSPACES = ["core", "admin", "inbound", "demo", "host"];
const PATCH_SELECTION = [
  ".github/workflows/ci.yml", "scripts/run_demo_browser_evidence.sh",
  "scripts/prepare_docs_compile_snapshot.cjs", "scripts/verify_brand_docs.sh",
  "mailglass_admin/e2e/docs-theme-contract.cjs", "mailglass_admin/e2e/phase177-account.spec.js",
  "scripts/check_phase174_evidence.cjs", "scripts/check_phase174_evidence.test.cjs",
  "test/scripts/phase184_07_runtime_contract.test.cjs",
];
const PATCH_EXCLUSIONS = [
  "mailglass_admin/e2e/docs-theme-contract.test.cjs", "mailglass_admin/lib/mailglass_admin/surface_nav.ex",
  "mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs",
  "scripts/demo_admin_node_runtime.cjs", "scripts/prepare_docs_compile_snapshot.test.cjs",
];
const FORMAT_PATHS = ["test/mailglass/docs_migration_smoke_test.exs",
  "test/mailglass/publish/brand_asset_allowlist_test.exs"];
const CAUSE_TEST = "mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs";
const IDNA_TEST = "ci/contracts/idna_compatibility_test.exs";
const APPROVED_PATHS = [...PATCH_SELECTION, ...LOCKS, ...FORMAT_PATHS, CAUSE_TEST, IDNA_TEST];
const UPDATES = {
  idna: { version: "8.0.0", inner: "bb8795a18aadce07dce6a3928c4fcae74ac66eaf95186b46ea11598bccc719f9",
    outer: "e0c5ce7846f14515af66142a55b8097d5f46d10df9235e781f168bef5622bcf9" },
  swoosh: { version: "1.30.0", inner: "a0904169dce7777d4decb80fb01b51eb317e6d140e9f6f00a8e2562426ae06e8",
    outer: "d1b553f5264ae39fb299e0da12e01e33aaba49c2509757065ca3aef06e659b0c" },
};

const now = () => new Date().toISOString();
const sha = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sorted = (entries) => [...entries].sort();
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function need(condition, message) { if (!condition) throw new Error(message); }
function resolvePatchAtRoot(canonicalRoot, io = fs) {
  const root = path.resolve(canonicalRoot);
  const expectedPath = path.resolve(root, PATCH_RELATIVE);
  const relative = path.relative(root, expectedPath);
  need(relative && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative),
    "approved patch path escaped the canonical root");
  const stat = io.lstatSync(expectedPath);
  need(stat.isFile() && !stat.isSymbolicLink?.() && stat.nlink === 1,
    "approved patch must be a regular independent file, not a symlink");
  need(io.realpathSync(expectedPath) === expectedPath, "approved patch path resolves through a symlink");
  const raw = Buffer.from(io.readFileSync(expectedPath));
  const hash = sha(raw);
  need(hash === PATCH_HASH, `approved patch checksum mismatch: ${hash}`);
  return { path: expectedPath, sha256: hash, bytes: raw };
}
function resolveApprovedPatch({ cwd = process.cwd(), canonicalRoot = OWNER, io } = {}) {
  void cwd;
  const root = path.resolve(canonicalRoot);
  need(root === OWNER || io, "patch root must be the canonical checkout root");
  if (root === OWNER) need(fs.realpathSync(OWNER) === OWNER, "checkout root is not canonical");
  return resolvePatchAtRoot(root, io || fs);
}
function checksumObservedHex(expectedHex, observedRaw) {
  need(typeof expectedHex === "string" && /^[a-f0-9]{64}$/.test(expectedHex),
    "lock checksum is not canonical lowercase 64-character hex");
  need(Buffer.isBuffer(observedRaw) && observedRaw.length === 32,
    "registry checksum must be exactly 32 raw bytes");
  const observedHex = observedRaw.toString("hex");
  need(observedHex === expectedHex,
    `registry checksum mismatch: expected ${expectedHex}, observed ${observedHex}`);
  return observedHex;
}
function normalizeDependencies(value) {
  need(Array.isArray(value) && value.every((item) => typeof item === "string"),
    "registry dependency metadata has an invalid shape");
  return sorted(value);
}
function decodeDependency(value) {
  const fields = value.split(",");
  need(fields.length === 5, "registry dependency tuple has an invalid shape");
  const decoded = fields.map((field) => {
    const raw = Buffer.from(field, "base64");
    need(raw.toString("base64") === field, "registry dependency tuple has invalid base64");
    return raw.toString("utf8");
  });
  const [repo, packageName, app, requirement, optional] = decoded;
  need(repo.length > 0 && packageName.length > 0 && app.length > 0 && requirement.length > 0,
    "registry dependency tuple has an empty field");
  need(optional === "true" || optional === "false", "registry dependency optional field is invalid");
  return { repo, packageName, app, requirement, optional };
}
const REQUIREMENT_TERM_SCRIPT = String.raw`
defmodule Phase184RequirementTerms do
  def main do
    if Hex.version() != "2.6.0", do: raise(ArgumentError, "installed Hex version is not 2.6.0")
    IO.read(:stdio, :all)
    |> String.split("\n", trim: true)
    |> Enum.each(fn encoded ->
      requirement = Base.decode64!(encoded)
      case Hex.Solver.Requirement.to_constraint(requirement) do
        {:ok, normalized_term} ->
          normalized_term |> :erlang.term_to_binary() |> Base.encode64() |> IO.puts()
        {:error, reason} -> raise ArgumentError, "invalid Hex requirement #{inspect(requirement)}: #{inspect(reason)}"
        other -> raise ArgumentError, "unexpected Hex requirement parser result: #{inspect(other)}"
      end
    end)
  end
end
Phase184RequirementTerms.main()
`;
function normalizeRequirementTerms(requirements, runtime = {}) {
  need(Array.isArray(requirements) && requirements.every((item) => typeof item === "string" && item.length > 0),
    "dependency requirement list is invalid");
  if (requirements.length === 0) return [];
  const input = `${requirements.map((item) => Buffer.from(item, "utf8").toString("base64")).join("\n")}\n`;
  const result = processCommand(path.join(ELIXIR_BIN, "elixir"), ["-pa", HEX_EBIN, "-e", REQUIREMENT_TERM_SCRIPT], {
    cwd: runtime.cwd || OWNER, input,
    env: { PATH: `${ELIXIR_BIN}:${OTP_BIN}:/usr/bin:/bin`, HOME: runtime.home || "/private/tmp",
      MIX_HOME: runtime.mixHome || "/private/tmp", HEX_OFFLINE: "1", ASDF_ELIXIR_VERSION: "1.18.4-otp-27",
      ASDF_ERLANG_VERSION: "27.3.4.13", ERL_FLAGS: "+S 2:2 +A 1", ERL_CRASH_DUMP: "/dev/null",
      TMPDIR: runtime.tmpdir || "/private/tmp", LANG: "C", LC_ALL: "C" },
    timeout: 30000,
  });
  need(result.status === 0 && !result.error,
    `Hex requirement parsing failed (${result.error ?? result.status}): ${sanitize(result.stderr).slice(0, 512)}`);
  const lines = result.stdout.toString("utf8").trimEnd().split("\n");
  need(lines.length === requirements.length && lines.every((line) => Buffer.from(line, "base64").toString("base64") === line),
    "Hex requirement parser returned an incomplete or malformed term list");
  return lines;
}
function compareDependencyRequirements(expectedDependencies, observedDependencies) {
  const decode = (items) => normalizeDependencies(items).map(decodeDependency);
  const expected = decode(expectedDependencies), observed = decode(observedDependencies);
  const group = (items) => {
    const result = new Map();
    for (const item of items) {
      const key = JSON.stringify([item.repo, item.packageName, item.app, item.optional]);
      if (!result.has(key)) result.set(key, { repo: item.repo, packageName: item.packageName,
        app: item.app, optional: item.optional, requirements: [] });
      result.get(key).requirements.push(item.requirement);
    }
    return result;
  };
  const expectedGroups = group(expected), observedGroups = group(observed);
  need(expectedGroups.size === observedGroups.size && [...expectedGroups.keys()].every((key) => observedGroups.has(key)),
    "registry dependency tuple metadata mismatch");
  const keys = sorted(expectedGroups.keys());
  for (const key of keys) need(expectedGroups.get(key).requirements.length === observedGroups.get(key).requirements.length,
    "registry dependency tuple multiplicity mismatch");
  const allRequirements = keys.flatMap((key) => [
    ...expectedGroups.get(key).requirements,
    ...observedGroups.get(key).requirements,
  ]);
  const normalized = normalizeRequirementTerms(allRequirements);
  let offset = 0;
  return keys.map((key) => {
    const expectedGroup = expectedGroups.get(key), observedGroup = observedGroups.get(key);
    const expectedTerms = normalized.slice(offset, offset + expectedGroup.requirements.length);
    offset += expectedGroup.requirements.length;
    const observedTerms = normalized.slice(offset, offset + observedGroup.requirements.length);
    offset += observedGroup.requirements.length;
    need(equal(sorted(expectedTerms), sorted(observedTerms)),
      `registry dependency requirement mismatch ${expectedGroup.packageName}`);
    return {
      repo: expectedGroup.repo, package: expectedGroup.packageName, app: expectedGroup.app,
      optional: expectedGroup.optional === "true",
      expected: expectedGroup.requirements,
      observed: observedGroup.requirements,
      normalizedTermsBase64: sorted(expectedTerms),
    };
  });
}
function validateRegistryReceipt(receipt, expectedRows, expectedCachePath) {
  need(receipt && receipt.schema === 5, "registry schema is not 5");
  need(receipt.repoUrl === "https://repo.hex.pm", "cached registry repo URL is not https://repo.hex.pm");
  if (receipt.mode === "inspect") {
    need(receipt.cachePath === expectedCachePath, "inspected registry cache path mismatch");
  } else {
    need(receipt.mode === "probe" && receipt.effectiveRepoUrl === "https://repo.hex.pm",
      "registry effective repo URL is not https://repo.hex.pm");
    need(receipt.effectiveCachePath === expectedCachePath, "effective registry cache path mismatch");
    need(receipt.offline === true, "Hex offline mode is not enabled");
  }
  need(Array.isArray(expectedRows) && Array.isArray(receipt.records) &&
    receipt.records.length === expectedRows.length, "registry record count mismatch");
  const keyOf = (row) => `${row.name}@${row.version}`;
  const expectedByKey = new Map(expectedRows.map((row) => [keyOf(row), row]));
  const actualByKey = new Map();
  need(expectedByKey.size === expectedRows.length, "duplicate expected lock record");
  for (const actual of receipt.records) {
    const key = keyOf(actual);
    need(!actualByKey.has(key), `duplicate registry release ${key}`);
    actualByKey.set(key, actual);
  }
  need(actualByKey.size === expectedByKey.size, "registry record set mismatch");
  const records = [...expectedByKey.keys()].sort().map((key) => {
    const expected = expectedByKey.get(key), actual = actualByKey.get(key);
    need(actual, `missing registry release ${key}`);
    const inner = checksumObservedHex(expected.inner, actual.innerRaw);
    const outer = checksumObservedHex(expected.outer, actual.outerRaw);
    const dependencies = normalizeDependencies(actual.dependencies);
    const requirementComparisons = compareDependencyRequirements(expected.dependencies, dependencies);
    return { name: actual.name, version: actual.version, inner, outer, dependencies, requirementComparisons };
  });
  return { schema: receipt.schema, repoUrl: receipt.repoUrl, recordsChecked: records.length, records };
}
function exists(file) {
  try { fs.lstatSync(file); return true; }
  catch (e) { if (e.code === "ENOENT") return false; throw e; }
}
function bytes(file) {
  const stat = fs.lstatSync(file);
  need(stat.isFile() && stat.nlink === 1, `expected a regular file with one link: ${path.basename(file)}`);
  return fs.readFileSync(file);
}
function digest(file) { return sha(bytes(file)); }
function sanitize(value) {
  return String(value)
    .replace(/(?:https?:\/\/)[^\s/]+:[^\s/]+@/g, "<REMOTE>")
    .replace(/\b[A-Z0-9_]*(?:TOKEN|PASSWORD|SECRET|CREDENTIAL|AUTH)[A-Z0-9_]*\s*[:=]\s*[^\s,;]+/gi, "<REDACTED>")
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "<EMAIL>")
    .replace(/(?:\/Users\/[^\s'"\x60]+|\/private\/tmp\/[^\s'"\x60]+)/g, "<PATH>");
}

function processCommand(executable, argv, { cwd = OWNER, env = process.env, input, timeout = 30000 } = {}) {
  const result = spawnSync(executable, argv, { cwd, env, input, timeout, maxBuffer: 64 * 1024 * 1024 });
  return { status: result.status ?? (result.signal === "SIGABRT" ? 134 : 1), signal: result.signal,
    error: result.error?.code ?? null, stdout: result.stdout ?? Buffer.alloc(0), stderr: result.stderr ?? Buffer.alloc(0) };
}
function success(executable, argv, options) {
  const result = processCommand(executable, argv, options);
  need(result.status === 0 && !result.error,
    `${path.basename(executable)} ${argv[0]} failed (${result.error ?? result.status}): ${sanitize(result.stderr).slice(0, 512)}`);
  return result.stdout;
}
function git(argv, cwd = OWNER) {
  return success("git", argv, { cwd, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" } });
}
function gitText(argv, cwd = OWNER) { return git(argv, cwd).toString("utf8").trim(); }
function stageOutput(raw) {
  return { bytes: raw.length, sha256: sha(raw), text: sanitize(raw.subarray(0, 32768)).slice(0, 32768) };
}
function save(evidence, target = EVIDENCE, exclusive = false) {
  const data = JSON.stringify(evidence, null, 2) + "\n";
  if (exclusive) fs.writeFileSync(target, data, { flag: "wx", mode: 0o600 });
  else {
    const swap = `${target}.${randomUUID()}.tmp`;
    fs.writeFileSync(swap, data, { flag: "wx", mode: 0o600 });
    fs.renameSync(swap, target);
  }
}
function custodyRows() {
  if (!exists(CUSTODY)) return [];
  const raw = bytes(CUSTODY).toString("utf8");
  need(raw.endsWith("\n"), "custody ledger is incomplete");
  const rows = raw.trimEnd().split("\n").map((line) => JSON.parse(line));
  need(rows.every((row, index) => row.sequence === index + 1 && row.plan === "184-12"),
    "custody ledger sequence or plan identity is invalid");
  return rows;
}
function appendCustody(row, exclusive = false) {
  const current = custodyRows();
  const record = { plan: "184-12", sequence: current.length + 1, at: now(), ...row };
  const fd = fs.openSync(CUSTODY, exclusive ? "wx" : "a", 0o600);
  try {
    fs.writeSync(fd, `${JSON.stringify(record)}\n`);
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  return record;
}
function claimEffect(label, nonce) {
  const rows = custodyRows();
  need(rows.some((row) => row.kind === "route" && row.status === "reserved" && row.nonce === nonce),
    "route custody reservation is missing");
  need(!rows.some((row) => row.kind === "effect" && row.label === label),
    `one-shot effect ${label} was already reserved`);
  return appendCustody({ kind: "effect", label, status: "reserved", nonce });
}
function finishEffect(label, nonce, status, details = {}) {
  const rows = custodyRows();
  need(rows.some((row) => row.kind === "effect" && row.label === label && row.status === "reserved" && row.nonce === nonce),
    `effect ${label} has no matching reservation`);
  need(!rows.some((row) => row.kind === "effect-result" && row.label === label),
    `effect ${label} already has a terminal result`);
  return appendCustody({ kind: "effect-result", label, status, nonce, details });
}
function writeRetained(name, value) {
  need(/^[a-z0-9][a-z0-9.-]*\.json$/.test(name), "invalid retained receipt name");
  fs.mkdirSync(RETAINED, { recursive: true, mode: 0o700 });
  fs.chmodSync(RETAINED, 0o700);
  const target = path.join(RETAINED, name);
  save(value, target, true);
  return { path: path.relative(OWNER, target), sha256: digest(target), bytes: fs.statSync(target).size };
}
function load() {
  const e = JSON.parse(bytes(EVIDENCE));
  need(e.schema === "phase184-12-evidence.v1" && e.root === ROUTE, "invalid route evidence identity");
  return e;
}
function patchCheck() {
  const selected = resolveApprovedPatch({ cwd: process.cwd() });
  need(selected.path === PATCH, "approved patch resolved to an unexpected path");
  const raw = selected.bytes;
  const entries = [...raw.toString().matchAll(/^diff --git a\/(\S+) b\/(\S+)$/gm)];
  need(entries.every((match) => match[1] === match[2]), "unexpected renamed patch entry");
  assert.deepEqual(sorted(entries.map((match) => match[2])), sorted([...PATCH_SELECTION, ...PATCH_EXCLUSIONS]));
  return { path: selected.path, sha256: selected.sha256, bytes: selected.bytes,
    selected: sorted(PATCH_SELECTION), excluded: sorted(PATCH_EXCLUSIONS) };
}
function parseLock(text) {
  const rows = new Map();
  for (const line of text.split("\n").slice(1, -1)) {
    if (line === "}") continue;
    const match = /^  "([a-z0-9_]+)": \{:hex, :([a-z0-9_]+), "([^"]+)", "([a-f0-9]{64})", (.*), "hexpm", "([a-f0-9]{64})"\},$/.exec(line);
    need(match && !rows.has(match[1]), "invalid or duplicate sealed lock tuple");
    rows.set(match[1], { line, name: match[2], version: match[3], inner: match[4], options: match[5], outer: match[6] });
  }
  need(rows.size > 0 && text.startsWith("%{\n") && text.endsWith("}\n"), "malformed Mix lock");
  return rows;
}
function refreshLock(text) {
  const rows = parseLock(text);
  for (const [name, update] of Object.entries(UPDATES)) {
    const old = rows.get(name);
    need(old?.name === name, `lock lacks ${name}`);
    const options = name === "swoosh"
      ? old.options.replace('{:idna, ">= 6.0.0 and < 8.0.0"', '{:idna, ">= 6.0.0 and < 9.0.0"')
      : old.options;
    if (name === "swoosh") need(options !== old.options, "sealed Swoosh constraint differs");
    const row = `  "${name}": {:hex, :${name}, "${update.version}", "${update.inner}", ${options}, "hexpm", "${update.outer}"},`;
    text = text.replace(old.line, row);
  }
  verifyLockDelta(rows, parseLock(text));
  return text;
}
function verifyLockDelta(before, after) {
  assert.deepEqual([...before.keys()], [...after.keys()]);
  for (const [name, row] of after) {
    const update = UPDATES[name];
    if (!update) need(row.line === before.get(name).line, `unapproved lock change: ${name}`);
    else {
      need(row.name === name && row.version === update.version &&
        row.inner === update.inner && row.outer === update.outer, `unexpected ${name} lock tuple`);
      const old = before.get(name).options;
      const expected = name === "swoosh" ? old.replace("< 8.0.0", "< 9.0.0") : old;
      need(row.options === expected, `unexpected dependency-graph change: ${name}`);
    }
  }
}
function archivePath(row, cache = HEX_CACHE) {
  return path.join(cache, "packages", "hexpm", `${row.name}-${row.version}.tar`);
}
function inventory(root) {
  const entries = [];
  function walk(full, relative) {
    const stat = fs.lstatSync(full);
    if (stat.isDirectory()) {
      entries.push({ path: relative, mode: stat.mode & 0o777, type: "directory" });
      for (const child of sorted(fs.readdirSync(full))) walk(path.join(full, child), path.join(relative, child));
    } else {
      const content = bytes(full);
      entries.push({ path: relative, mode: stat.mode & 0o777, type: "file", size: content.length, sha256: sha(content) });
    }
  }
  walk(root, ".");
  return entries;
}
function writeMode(file, mode) { fs.chmodSync(file, mode); }
function freeze(root) {
  for (const row of inventory(root).reverse()) writeMode(path.join(root, row.path), row.mode & ~0o222);
}
function makeBuildView(canonical, view) {
  need(!exists(view), "build view already exists");
  const before = inventory(canonical);
  need(before.every((row) => (row.mode & 0o222) === 0), "canonical packages permit writes");
  fs.mkdirSync(view, { mode: 0o700 });
  for (const name of fs.readdirSync(canonical)) {
    const from = path.join(canonical, name), to = path.join(view, name);
    need(fs.lstatSync(from).isDirectory(), "unexpected non-package dependency");
    if (name === "earmark_parser") {
      fs.cpSync(from, to, { recursive: true, errorOnExist: true, force: false });
      const copied = inventory(to);
      assert.deepEqual(copied, inventory(from));
      for (const row of copied) writeMode(path.join(to, row.path), row.mode | 0o200);
      for (const row of copied) {
        const orig = fs.lstatSync(path.join(from, row.path)), copy = fs.lstatSync(path.join(to, row.path));
        need(orig.dev !== copy.dev || orig.ino !== copy.ino, "compiler copy shares source inode");
      }
    } else fs.symlinkSync(from, to, "dir");
  }
  assert.deepEqual(inventory(canonical), before);
  return sha(JSON.stringify(before));
}
function authorizeRoot(root, nonce) {
  const st = fs.lstatSync(root);
  need(st.isDirectory() && st.uid === process.getuid() && fs.realpathSync(root) === root, "candidate root identity mismatch");
  const marker = JSON.parse(bytes(path.join(root, ROOT_MARKER)));
  need(marker.root === root && marker.nonce === nonce && marker.dev === st.dev && marker.ino === st.ino,
    "candidate root ownership record mismatch");
}
function removeOwned(root, nonce) {
  authorizeRoot(root, nonce);
  function remove(target) {
    const st = fs.lstatSync(target);
    need(st.uid === process.getuid(), "cleanup found an unowned child");
    if (st.isDirectory()) {
      writeMode(target, 0o700);
      for (const name of fs.readdirSync(target)) remove(path.join(target, name));
      fs.rmdirSync(target);
    } else if (st.isFile() || st.isSymbolicLink()) fs.unlinkSync(target);
    else throw new Error("cleanup found an unsupported file type");
  }
  const names = sorted(fs.readdirSync(root)).filter((name) => name !== ROOT_MARKER);
  for (const name of names) remove(path.join(root, name));
  fs.unlinkSync(path.join(root, ROOT_MARKER));
  fs.rmdirSync(root);
  return [...names, ROOT_MARKER];
}
function markRoot(root, nonce) {
  fs.mkdirSync(root, { mode: 0o700 });
  const { dev, ino } = fs.lstatSync(root);
  save({ root, nonce, dev, ino }, path.join(root, ROOT_MARKER), true);
}

function stage(e, label, executable, argv, options) {
  need(e.status === "running" && !e.attempts.some((attempt) => attempt.label === label),
    `stage ${label} already attempted or terminal`);
  const attempt = { label, startedAt: now(), argvSha256: sha(JSON.stringify([executable, ...argv])) };
  const file = path.join(ROUTE, "attempts", `${label}.json`);
  authorizeRoot(ROUTE, e.nonce);
  save(attempt, file, true);
  e.attempts.push(attempt);
  save(e);
  const result = processCommand(executable, argv, options);
  Object.assign(attempt, { status: result.status, error: result.error, signal: result.signal, finishedAt: now(),
    stdout: stageOutput(result.stdout), stderr: stageOutput(result.stderr) });
  save(e);
  need(attempt.status === 0 && !attempt.error, `stage ${label} failed with exit ${attempt.status}`);
  return result.stdout;
}

function tarOctal(field, cap, label, name) {
  let index = 0;
  while (field[index] === 0x20) index++;
  const start = index;
  let value = 0;
  while (field[index] >= 0x30 && field[index] <= 0x37) {
    const digit = field[index++] - 0x30;
    need(value <= Math.floor((cap - digit) / 8), `${label}: tar ${name} exceeds its cap`);
    value = value * 8 + digit;
  }
  need(index > start, `${label}: unsupported tar octal ${name} field`);
  for (; index < field.length; index++)
    need(field[index] === 0 || field[index] === 0x20, `${label}: unsupported tar octal ${name} padding`);
  return value;
}

function tarMembers(archive, label) {
  const MAX_MEMBERS = 30000;
  const members = new Map();
  const spellings = new Map();
  const zero = data => data.every(byte => byte === 0);
  const text = data => {
    const end = data.indexOf(0);
    const value = end === -1 ? data : data.subarray(0, end);
    need(end === -1 || zero(data.subarray(end)), `${label}: unrecognized tar field`);
    const decoded = value.toString('utf8');
    need(Buffer.from(decoded).equals(value), `${label}: noncanonical tar path encoding`);
    return decoded;
  };
  let offset = 0;
  while (offset + 512 <= archive.length) {
    const header = archive.subarray(offset, offset + 512);
    if (zero(header)) {
      need(archive.length - offset >= 1024 && zero(archive.subarray(offset)), `${label}: invalid tar terminator`);
      return members;
    }
    const checksum = header.reduce((sum, byte, index) => sum + (index >= 148 && index < 156 ? 32 : byte), 0);
    need(tarOctal(header.subarray(148, 156), 512 * 255, label, 'checksum') === checksum, `${label}: bad tar header checksum`);
    const magic = header.subarray(257, 263).toString('ascii');
    const version = header.subarray(263, 265).toString('ascii');
    need((magic === 'ustar\0' && version === '00' || magic === 'ustar ' && version === ' \0') &&
      zero(header.subarray(500, 512)) && zero(header.subarray(157, 257)),
    `${label}: unrecognized tar header or link metadata`);
    const kind = header[156] === 53 ? 'directory' : [0, 48].includes(header[156]) ? 'file' : null;
    need(kind && members.size < MAX_MEMBERS, `${label}: unsupported tar entry type or count`);
    const rawMode = tarOctal(header.subarray(100, 108), 0o177777, label, 'mode');
    const tag = rawMode & ~0o777;
    const expectedTag = kind === 'file' ? 0o100000 : 0o040000;
    need(tag === 0 || tag === expectedTag, `${label}: unsafe or mismatched tar mode`);
    const mode = rawMode & 0o777;
    const size = tarOctal(header.subarray(124, 136), 64 * 1024 * 1024, label, 'size');
    need(kind === 'file' || size === 0, `${label}: directory tar size must be zero`);
    const prefix = text(header.subarray(345, 500));
    const basename = text(header.subarray(0, 100));
    const rawName = prefix ? `${prefix}/${basename}` : basename;
    const name = kind === 'directory' ? rawName.replace(/\/$/, '') : rawName;
    const parts = name.split('/');
    need(parts.every(part => part && part !== '.' && part !== '..' && !/[\\\u0000-\u001f\u007f:]/.test(part)) &&
      !members.has(name), `${label}: unsafe or duplicate tar path`);
    for (const [index] of parts.entries()) {
      const ancestor = parts.slice(0, index + 1).join('/');
      const folded = ancestor.normalize('NFD').toLowerCase();
      need(!spellings.has(folded) || spellings.get(folded) === ancestor, `${label}: case-folded tar path collision`);
      spellings.set(folded, ancestor);
    }
    const dataStart = offset + 512;
    const dataEnd = dataStart + size;
    offset = dataStart + Math.ceil(size / 512) * 512;
    need(offset <= archive.length && zero(archive.subarray(dataEnd, offset)), `${label}: truncated or mispadded tar data`);
    members.set(name, {type: kind, mode, data: archive.subarray(dataStart, dataEnd)});
  }
  throw new Error(`${label}: missing tar terminator`);
}

function archiveEnvelope(data, row) {
  need(sha(data) === row.outer_checksum, `${row.name}: outer checksum does not match exact lock`);
  const envelope = tarMembers(data, `${row.name} envelope`);
  const names = ['CHECKSUM', 'VERSION', 'contents.tar.gz', 'metadata.config'];
  need(equal([...envelope.keys()].sort(), names) && [...envelope.values()].every(item => item.type === 'file'),
    `${row.name}: unexpected Hex envelope members`);
  const payload = key => envelope.get(key).data;
  need(payload('VERSION').equals(Buffer.from('3')), `${row.name}: unsupported Hex envelope version`);
  const checksum = payload('CHECKSUM').toString('ascii').toLowerCase();
  const inner = sha(Buffer.concat([payload('VERSION'), payload('metadata.config'), payload('contents.tar.gz')]));
  need(/^[a-f0-9]{64}$/.test(checksum) && checksum === inner && inner === row.inner_checksum,
    `${row.name}: inner checksum does not match exact lock`);
  const unpacked = gunzipSync(payload('contents.tar.gz'), {maxOutputLength: 128 * 1024 * 1024});
  const contents = tarMembers(unpacked, `${row.name} contents`);
  const expected = new Map();
  for (const [rel, member] of contents) {
    need(!['.hex', 'hex_metadata.config'].includes(rel.split('/')[0].normalize('NFD').toLowerCase()),
      `${row.name}: archive collides with checkout metadata`);
    const dirs = rel.split('/').slice(0, -1);
    for (const [index] of dirs.entries()) {
      const parent = dirs.slice(0, index + 1).join('/');
      need(!contents.has(parent) || contents.get(parent).type === 'directory', `${row.name}: non-directory ancestor`);
      expected.set(parent, {type: 'directory', mode: 0o555});
    }
    expected.set(rel, member.type === 'directory'
      ? {type: member.type, mode: 0o555}
      : {type: member.type, mode: member.mode & ~0o222, size: member.data.length, sha256: sha(member.data)});
  }
  return {inner, outer: row.outer_checksum, metadata: payload('metadata.config'), expected, contents};
}

function readArchive(row) {
  const file = archivePath(row);
  need(fs.realpathSync(file) === file, "archive path crosses a symbolic link");
  const raw = bytes(file);
  return archiveEnvelope(raw, { name: row.name, inner_checksum: row.inner, outer_checksum: row.outer });
}
function lockPayload(rows) {
  return rows.map(({ file, data }) => ({ path: file, bytes: Buffer.from(data).toString("base64") }));
}
function hexCommand(command, input, cwd = OWNER) {
  // Use the pinned Hex 2.6.0 codec source; no previous route receipt is read.
  need(digest(HEX_HELPER) === HEX_HELPER_HASH, "Hex helper source changed before invocation");
  const helper = HEX_HELPER;
  const result = success(path.join(ELIXIR_BIN, "elixir"), ["-pa", HEX_EBIN, helper, command, HEX_EBIN], {
    cwd, input: JSON.stringify(input),
    env: { PATH: `${OTP_BIN}:/usr/bin:/bin`, LANG: "C", LC_ALL: "C", HEX_OFFLINE: "1", ERL_FLAGS: "+S 2:2 +A 1" },
    timeout: 45000,
  });
  need(digest(HEX_HELPER) === HEX_HELPER_HASH, "Hex helper source changed during invocation");
  const decoded = JSON.parse(result);
  need(decoded.runtime?.version === "2.6.0" && decoded.runtime?.otp === "27.3.4.13" && decoded.runtime?.elixir === "1.18.4",
    "unexpected installed Hex compiler toolchain");
  return decoded.result;
}
function registryRows(proof) {
  const rows = new Map();
  for (const workspace of proof.final) for (const pkg of workspace.packages) {
    const key = `${pkg.name}@${pkg.version}`;
    const dependencies = pkg.dependencies.map((dep) => [dep.repo || "hexpm", dep.package, dep.name,
      dep.requirement, String(dep.optional)].map((value) => Buffer.from(value).toString("base64")).join(",")).sort();
    const row = { name: pkg.name, version: pkg.version, inner: pkg.inner_checksum, outer: pkg.outer_checksum,
      dependencies };
    if (rows.has(key)) need(equal(rows.get(key), row), `lock metadata disagrees across workspaces: ${key}`);
    else rows.set(key, row);
  }
  return [...rows.values()].sort((a, b) => `${a.name}@${a.version}`.localeCompare(`${b.name}@${b.version}`));
}
const REGISTRY_SCRIPT = String.raw`
defmodule Phase184RegistryProbe do
  def need(true, _), do: :ok
  def need(false, message), do: raise(ArgumentError, message)
  def decode_dependencies(""), do: []
  def decode_dependencies(encoded) do
    encoded |> String.split(";", trim: true) |> Enum.map(fn row ->
      [repo, package, app, requirement, optional] = row |> String.split(",") |> Enum.map(&Base.decode64!/1)
      need(optional in ["true", "false"], "dependency optional value is not canonical")
      need(repo != "" and package != "" and app != "" and requirement != "", "dependency tuple has an empty field")
      {repo, package, app, requirement, optional == "true"}
    end) |> Enum.sort()
  end
  def normalize_requirement(requirement) do
    case Hex.Solver.Requirement.to_constraint(requirement) do
      {:ok, normalized_term} -> normalized_term
      {:error, reason} -> raise ArgumentError, "invalid Hex dependency requirement #{inspect(requirement)}: #{inspect(reason)}"
      other -> raise ArgumentError, "unexpected Hex dependency parser result: #{inspect(other)}"
    end
  end
  def normalized_dependency_rows(rows) do
    rows
    |> Enum.group_by(fn {repo, package, app, _requirement, optional} -> {repo, package, app, optional} end,
      fn {_repo, _package, _app, requirement, _optional} -> normalize_requirement(requirement) end)
    |> Map.new(fn {metadata, requirements} -> {metadata, Enum.sort(requirements)} end)
  end
  def dependency_rows_equal?(actual, expected),
    do: normalized_dependency_rows(actual) === normalized_dependency_rows(expected)
  def raw_checksum(tid, kind, package, version, expected) do
    need(is_binary(expected) and Regex.match?(~r/\A[a-f0-9]{64}\z/, expected),
      "lock checksum is not canonical lowercase 64-character hex")
    expected_raw = Base.decode16!(expected, case: :lower)
    entries = :ets.lookup(tid, {kind, "hexpm", package, version})
    need(length(entries) == 1, "missing or duplicate #{kind} checksum #{package}@#{version}")
    {{^kind, "hexpm", ^package, ^version}, observed_raw} = hd(entries)
    need(is_binary(observed_raw) and byte_size(observed_raw) == 32,
      "#{kind} checksum has invalid raw-byte shape #{inspect(observed_raw)}")
    observed_hex = Base.encode16(observed_raw, case: :lower)
    need(observed_raw == expected_raw,
      "#{kind} checksum mismatch #{package}@#{version}: expected #{expected}, observed #{observed_hex}")
    {observed_hex, Base.encode64(observed_raw)}
  end
  def verify(tid, records, expected_url) do
    need(:ets.lookup(tid, :version) == [{:version, 5}], "registry schema is not 5")
    need(:ets.lookup(tid, {:repo, "hexpm"}) == [{{:repo, "hexpm"}, expected_url}], "cached repo URL mismatch")
    Enum.map(records, fn record ->
      [package, version, inner, outer, dependencies] = String.split(record, "|", parts: 5)
      versions = case :ets.lookup(tid, {:versions, "hexpm", package}) do [{_, value}] -> value; [] -> [] end
      need(version in versions, "missing release version #{package}@#{version}")
      {inner_hex, inner_raw64} = raw_checksum(tid, :inner_checksum, package, version, inner)
      {outer_hex, outer_raw64} = raw_checksum(tid, :outer_checksum, package, version, outer)
      actual = case :ets.lookup(tid, {:deps, "hexpm", package, version}) do [{_, value}] -> Enum.sort(value); [] -> :missing end
      need(actual != :missing, "missing dependency metadata #{package}@#{version}")
      need(dependency_rows_equal?(actual, decode_dependencies(dependencies)), "dependency metadata mismatch #{package}@#{version}")
      encoded_actual = actual |> Enum.map(fn {repo, name, app, requirement, optional} ->
        [repo, name, app, requirement, to_string(optional)] |> Enum.map(&Base.encode64/1) |> Enum.join(",")
      end) |> Enum.sort() |> Enum.join(";")
      %{name: package, version: version, inner: inner_hex, outer: outer_hex,
        inner_raw64: inner_raw64, outer_raw64: outer_raw64, dependencies: encoded_actual}
    end)
  end
  def main do
    case System.argv() do
      ["compare-fixture", expected64, observed64] ->
        decode_fixture = fn encoded ->
          encoded |> Base.decode64!() |> String.split("\n", trim: true) |> Enum.join(";") |> decode_dependencies()
        end
        expected = decode_fixture.(expected64)
        observed = decode_fixture.(observed64)
        IO.puts(if dependency_rows_equal?(observed, expected), do: "PASS", else: "FAIL")
      [mode, cache_path, expected_url | encoded] ->
        records = Enum.map(encoded, fn row ->
          [package, version, inner, outer, dependencies] = String.split(row, "|", parts: 5)
          Enum.join([package, version, inner, outer, dependencies], "|")
        end)
        {tid, effective_url, offline} = case mode do
          "inspect" ->
            {:ok, table} = Hex.Registry.Server.read_cache(cache_path)
            {table, expected_url, "not-probed"}
          "probe" ->
            {:ok, _} = Application.ensure_all_started(:ssl)
            Mix.start()
            {:ok, _} = Hex.Application.start(:normal, [])
            need(Hex.State.fetch!(:offline) == true, "effective Hex offline mode is not enabled")
            need(Path.expand(Hex.State.fetch!(:cache_home)) == Path.dirname(Path.expand(cache_path)), "effective Hex cache home differs")
            config = Hex.Repo.get_repo("hexpm")
            need(config.url == expected_url, "effective Hex repo URL differs")
            need(Path.expand(cache_path) == Path.join(Path.expand(Hex.State.fetch!(:cache_home)), "cache.bin"), "effective cache path differs")
            :ok = Hex.Registry.Server.open(check_version: false)
            :ok = Hex.Registry.Server.prefetch(Enum.map(records, fn row -> {"hexpm", hd(String.split(row, "|"))} end))
            state = :sys.get_state(Process.whereis(Hex.Registry.Server))
            {state.ets, config.url, "true"}
          other -> raise ArgumentError, "unsupported registry probe mode #{other}"
        end
        checked = verify(tid, records, expected_url)
        schema = :ets.lookup(tid, :version) |> hd() |> elem(1)
        repo = :ets.lookup(tid, {:repo, "hexpm"}) |> hd() |> elem(1)
        IO.puts(["META", to_string(schema), Base.encode64(repo), Base.encode64(effective_url),
          Base.encode64(Path.expand(cache_path)), offline, Integer.to_string(length(records))] |> Enum.join("\t"))
        Enum.each(checked, fn row -> IO.puts(["REC", row.name, row.version, row.inner_raw64,
          row.outer_raw64, row.dependencies] |> Enum.join("\t")) end)
        IO.puts("PASS")
      _ -> raise ArgumentError, "invalid registry comparator fixture"
    end
  end
end
Phase184RegistryProbe.main()
`;
function compareRegistryRequirementsFixture(expectedDependencies, observedDependencies, runtime = {}) {
  const encode = (rows) => Buffer.from(rows.join("\n"), "utf8").toString("base64");
  const result = processCommand(path.join(ELIXIR_BIN, "elixir"), ["-pa", HEX_EBIN, "-e", REGISTRY_SCRIPT,
    "--", "compare-fixture", encode(expectedDependencies), encode(observedDependencies)], {
    cwd: runtime.cwd || OWNER,
    env: { PATH: `${ELIXIR_BIN}:${OTP_BIN}:/usr/bin:/bin`, HOME: "/private/tmp", MIX_HOME: "/private/tmp",
      HEX_OFFLINE: "1", ASDF_ELIXIR_VERSION: "1.18.4-otp-27", ASDF_ERLANG_VERSION: "27.3.4.13",
      ERL_FLAGS: "+S 2:2 +A 1", ERL_CRASH_DUMP: "/dev/null", TMPDIR: "/private/tmp", LANG: "C", LC_ALL: "C" },
    timeout: 15000,
  });
  need(result.status === 0 && !result.error,
    `Hex semantic comparator fixture failed (${result.error ?? result.status}): ${sanitize(result.stderr).slice(0, 512)}`);
  return result.stdout.toString("utf8").trim() === "PASS";
}
function runRegistry(mode, cachePath, rows, timeout = 60000, runtime = {}) {
  const encodedRows = rows.map((row) => [row.name, row.version, row.inner, row.outer, row.dependencies.join(";")].join("|"));
  const argv = ["-pa", HEX_EBIN, "-e", REGISTRY_SCRIPT, "--", mode, cachePath, "https://repo.hex.pm", ...encodedRows];
  const env = { PATH: `${ELIXIR_BIN}:${OTP_BIN}:/usr/bin:/bin`, HOME: runtime.home || "/private/tmp",
    MIX_HOME: runtime.mixHome || "/private/tmp",
    HEX_HOME: path.dirname(cachePath), HEX_OFFLINE: "1", ASDF_ELIXIR_VERSION: "1.18.4-otp-27",
    ASDF_ERLANG_VERSION: "27.3.4.13", ERL_FLAGS: "+S 2:2 +A 1", ERL_CRASH_DUMP: "/dev/null",
    TMPDIR: runtime.tmpdir || "/private/tmp", LANG: "C", LC_ALL: "C" };
  const result = processCommand(path.join(ELIXIR_BIN, "elixir"), argv, {
    cwd: runtime.cwd || OWNER, env, timeout,
  });
  need(result.status === 0 && !result.error,
    `Hex ${mode} failed (${result.error ?? result.status}): ${sanitize(result.stderr).slice(0, 512)}`);
  const receipt = parseRegistryOutput(result.stdout, mode, cachePath);
  receipt.stderrSha256 = sha(result.stderr);
  return receipt;
}
function parseRegistryOutput(stdout, mode, cachePath) {
  const raw = Buffer.from(stdout);
  need(raw.length > 0 && raw.at(-1) === 0x0a && !raw.includes(0x0d), "Hex output is not canonical newline-delimited text");
  const lines = raw.toString("utf8").slice(0, -1).split("\n");
  const meta = lines.find((line) => line.startsWith("META\t"));
  need(meta && lines.at(-1) === "PASS", `Hex ${mode} returned no complete record receipt`);
  const [, schema, repo64, effectiveUrl64, effectiveCache64, offline, count] = meta.split("\t");
  const recordLines = lines.filter((line) => line.startsWith("REC\t"));
  need(recordLines.length === Number(count) && lines.length === Number(count) + 2,
    `Hex ${mode} returned an incomplete or ambiguous record list`);
  const receipt = { schema: Number(schema), repoUrl: Buffer.from(repo64, "base64").toString("utf8"),
    effectiveRepoUrl: Buffer.from(effectiveUrl64, "base64").toString("utf8"),
    effectiveCachePath: Buffer.from(effectiveCache64, "base64").toString("utf8"),
    cachePath: path.resolve(cachePath), offline: offline === "true", recordsChecked: Number(count),
    records: recordLines.map((line) => {
      const [, name, version, inner64, outer64, dependencies] = line.split("\t");
      return { name, version, innerRaw: Buffer.from(inner64, "base64"), outerRaw: Buffer.from(outer64, "base64"),
        dependencies: dependencies ? dependencies.split(";").sort() : [] };
    }), mode, stdoutSha256: sha(raw), stdoutBase64: raw.toString("base64") };
  need(receipt.records.every((row) => row.innerRaw.length === 32 && row.outerRaw.length === 32),
    "registry output contains a non-raw checksum shape");
  return receipt;
}
function validateRegistryMeta(meta, expectedCount, expectedCachePath) {
  need(meta.schema === 5, "registry schema must be 5");
  need(meta.repoUrl === "https://repo.hex.pm" && meta.effectiveRepoUrl === "https://repo.hex.pm",
    "registry repo URL is not the effective candidate URL");
  need(meta.offline === true && meta.effectiveCachePath === expectedCachePath,
    "effective Hex settings do not prove offline cache.bin selection");
  need(meta.recordsChecked === expectedCount, "registry record count differs from the five lock graphs");
  return true;
}
function retainedRegistryReceipt(receipt, checked) {
  return {
    mode: receipt.mode, cachePath: receipt.cachePath, stdoutBase64: receipt.stdoutBase64,
    stdoutSha256: receipt.stdoutSha256, stderrSha256: receipt.stderrSha256,
    dependencyRequirementPairs: checked.records.map((row) => ({ name: row.name, version: row.version,
      comparisons: row.requirementComparisons })),
  };
}
function validateRetainedRegistryReceipt(container, expectedRows, expectedCachePath) {
  need(container && container.schema === "phase184-12-registry-receipt.v1" && container.receipt,
    "retained registry receipt identity is absent");
  const raw = Buffer.from(container.receipt.stdoutBase64 || "", "base64");
  need(raw.toString("base64") === container.receipt.stdoutBase64 && sha(raw) === container.receipt.stdoutSha256,
    "retained registry stdout bytes or checksum are invalid");
  const receipt = parseRegistryOutput(raw, container.receipt.mode, container.receipt.cachePath);
  need(receipt.stdoutSha256 === container.receipt.stdoutSha256 && receipt.mode === container.receipt.mode &&
    receipt.cachePath === container.receipt.cachePath, "retained registry receipt metadata drifted");
  const checked = validateRegistryReceipt(receipt, expectedRows, expectedCachePath);
  need(container.recordsChecked === checked.recordsChecked && container.recordsSha256 === sha(JSON.stringify(checked.records)),
    "retained registry normalized record digest differs from raw receipt");
  need(equal(container.receipt.dependencyRequirementPairs, checked.records.map((row) => ({ name: row.name,
    version: row.version, comparisons: row.requirementComparisons }))),
  "retained raw requirement strings or recomputed Hex terms differ");
  return { receipt, checked };
}
function validateTerminalCustody(evidence, ledger) {
  need(evidence.status === "blocked" && evidence.terminal?.status === "blocked",
    "terminal blocked disposition is absent");
  const terminal = ledger.filter((row) => row.kind === "route-terminal");
  need(terminal.length === 1 && terminal[0].status === "blocked" &&
    terminal[0].nonce === evidence.route.nonce && terminal[0].preimageSha256 === evidence.terminal.preimageSha256,
  "append-only custody ledger lacks the unique matching terminal blocked disposition");
  return true;
}
function installedBrowserProof() {
  const images = JSON.parse(success("docker", ["image", "inspect", IMAGE]));
  need(images.length === 1, "pinned Playwright image lookup is ambiguous");
  const image = images[0];
  need(image.Id && image.RepoTags?.includes(IMAGE) && Array.isArray(image.RepoDigests) && image.RepoDigests.length > 0 &&
    image.RepoDigests.every((item) => /^mcr\.microsoft\.com\/playwright@sha256:[a-f0-9]{64}$/.test(item)) && image.Os === "linux" &&
    ["arm64", "amd64"].includes(image.Architecture), "pinned Playwright image identity is absent or mismatched");
  const playwright = JSON.parse(bytes(PLAYWRIGHT_PACKAGE));
  const core = JSON.parse(bytes(PLAYWRIGHT_CORE_PACKAGE));
  need(playwright.name === "playwright" && playwright.version === "1.65.1" &&
    core.name === "playwright-core" && core.version === "1.65.1", "Admin Playwright module version mismatch");
  return {
    image: { id: image.Id, repoTags: image.RepoTags, repoDigests: sorted(image.RepoDigests || []),
      platform: `${image.Os}/${image.Architecture}` },
    playwright: { version: playwright.version, packageSha256: digest(PLAYWRIGHT_PACKAGE),
      coreVersion: core.version, corePackageSha256: digest(PLAYWRIGHT_CORE_PACKAGE) },
  };
}
function toolchainProof() {
  const helper = bytes(HEX_HELPER);
  need(sha(helper) === HEX_HELPER_HASH, "installed Hex lock/archive helper source drifted");
  for (const executable of [path.join(ELIXIR_BIN, "elixir"), path.join(OTP_BIN, "erl")]) {
    const stat = fs.lstatSync(executable);
    need(stat.isFile() && !stat.isSymbolicLink() && stat.nlink === 1,
      `pinned runtime executable is not a regular file: ${path.basename(executable)}`);
  }
  need(exists(path.join(HEX_EBIN, "hex.app")), "installed Hex 2.6.0 application is absent");
  return { helperSha256: HEX_HELPER_HASH, hexAppSha256: digest(path.join(HEX_EBIN, "hex.app")),
    elixirPath: path.join(ELIXIR_BIN, "elixir"), otpPath: path.join(OTP_BIN, "erl"),
    hexPath: HEX_EBIN };
}
function assertStageAllowed(evidence, stageName) {
  const next = {
    fresh: "cache-preflight",
    "preallocation-review": "start-local",
    "local-passed": "run-hosted",
    "hosted-passed": "run-preview",
    "preview-passed": "finalize",
  };
  need(!["blocked", "terminal"].includes(evidence.status),
    "terminal or blocked route cannot reserve a downstream stage");
  need(next[evidence.status] === stageName, `stage ${stageName} is not selected from ${evidence.status}`);
  need(!evidence.attempts?.some((attempt) => attempt.label === stageName),
    `stage ${stageName} already has a one-shot attempt`);
  return true;
}
function lockProof() {
  need(gitText(["rev-parse", `${BASE}^{tree}`]) === TREE, "sealed base tree authentication failed");
  patchCheck();
  const cases = LOCKS.map((file, index) => {
    const data = git(["show", `${BASE}:${file}`]).toString();
    const refreshed = refreshLock(data);
    return { file, workspace: WORKSPACES[index], data, refreshed,
      originalOid: gitText(["rev-parse", `${BASE}:${file}`]), originalHash: sha(data), finalHash: sha(refreshed) };
  });
  const final = hexCommand("locks", { locks: lockPayload(cases.map((row) => ({ ...row, data: row.refreshed }))) });
  const archives = new Map();
  for (const [index, row] of cases.entries()) {
    need(final[index]?.path === row.file && final[index].lock_sha256 === row.finalHash,
      "Hex disagrees with final lock identity");
    const parsed = parseLock(row.refreshed);
    for (const pkg of final[index].packages) {
      const checked = parsed.get(pkg.destination);
      need(checked?.name === pkg.name && checked.version === pkg.version && checked.outer === pkg.outer_checksum &&
        checked.inner === pkg.inner_checksum && sha(Buffer.from(pkg.manifest, "base64")) === pkg.manifest_sha256,
        "Hex disagrees with lock tuple");
      const name = `${checked.name}-${checked.version}`;
      if (!archives.has(name)) archives.set(name, readArchive(checked));
      need(archives.get(name).outer === checked.outer, "archive identity varies between workspaces");
    }
    need(final[index].packages.length === parsed.size, "Hex lock parser changed package membership");
  }
  return { cases, final, archives };
}
function fileManifestNames() {
  const changed = new Set();
  for (const args of [["diff", "--name-only", "-z", "HEAD"], ["diff", "--cached", "--name-only", "-z"],
    ["ls-files", "--others", "--exclude-standard", "-z"]]) {
    for (const name of git(args).toString().split("\0").filter(Boolean)) changed.add(name);
  }
  return sorted(changed);
}
const REPORTS = [
  ".planning/STATE.md", ".planning/ROADMAP.md", ".planning/state.json", ".planning/v2.11-MILESTONE-AUDIT.md",
  ".planning/phases/182-admin-words-and-layout-one-job-first/182-VERIFICATION.md",
  ".planning/phases/183-docs-packaging-and-launch-prep/183-VERIFICATION.md",
  path.relative(OWNER, path.join(__dirname, "184-VERIFICATION.md")),
  path.relative(OWNER, PLAN), path.relative(OWNER, path.join(__dirname, "184-12-route.cjs")),
  path.relative(OWNER, path.join(__dirname, "184-12-route.test.cjs")), path.relative(OWNER, EVIDENCE),
  path.relative(OWNER, path.join(__dirname, "184-12-SUMMARY.md")),
];
const MUTABLE = new Set([...REPORTS, path.relative(OWNER, EVIDENCE), path.relative(OWNER, CUSTODY)]);
const PLAN_OWNED_FILES = new Set([
  path.relative(OWNER, path.join(__dirname, "184-12-route.cjs")),
  path.relative(OWNER, path.join(__dirname, "184-12-route.test.cjs")),
  path.relative(OWNER, path.join(__dirname, "184-12-review-gate.exs")),
  path.relative(OWNER, EVIDENCE),
  path.relative(OWNER, path.join(__dirname, "184-12-SUMMARY.md")),
  path.relative(OWNER, path.join(__dirname, "184-VERIFICATION.md")),
  path.relative(OWNER, path.join(__dirname, "182-admin-words-and-layout-one-job-first/182-VERIFICATION.md")),
  path.relative(OWNER, path.join(__dirname, "183-docs-packaging-and-launch-prep/183-VERIFICATION.md")),
  ".planning/v2.11-MILESTONE-AUDIT.md",
  ".planning/STATE.md", ".planning/ROADMAP.md", ".planning/state.json",
]);
function isPlanOwned(relative) {
  return PLAN_OWNED_FILES.has(relative) || relative.startsWith(`${path.relative(OWNER, RETAINED)}${path.sep}`);
}
function porcelainWithoutPlanArtifacts(raw) {
  const parts = raw.toString("utf8").split("\0").filter(Boolean);
  const kept = [];
  for (let index = 0; index < parts.length; index++) {
    const entry = parts[index];
    const pathName = entry.slice(3);
    if (!isPlanOwned(pathName)) kept.push(entry);
    if (entry.startsWith("2 ")) index++;
  }
  return sha(kept.join("\0"));
}
function indexWithoutPlanArtifacts() {
  const records = git(["ls-files", "--stage", "-z"]).toString("utf8").split("\0").filter(Boolean);
  const kept = records.filter((record) => !isPlanOwned(record.slice(record.indexOf("\t") + 1)));
  return sha(kept.join("\0"));
}
function pathState(relative) {
  const full = path.join(OWNER, relative);
  if (!exists(full)) return { path: relative, present: false };
  const st = fs.lstatSync(full);
  if (st.isSymbolicLink()) return { path: relative, mode: st.mode, symlinkHash: sha(fs.readlinkSync(full)) };
  if (st.isFile()) return { path: relative, mode: st.mode, size: st.size, sha256: sha(fs.readFileSync(full)) };
  return { path: relative, mode: st.mode };
}
function ownerBaseline() {
  const names = git(["ls-files", "--cached", "--others", "--exclude-standard", "-z"]).toString().split("\0").filter(Boolean);
  const protectedNames = new Set([path.relative(OWNER, PATCH)]);
  for (const name of names) {
    if (/favicon|182-07|^brandbook\/|184-(0[1-8])-(EVIDENCE|SUMMARY)|(?:seed|capture).*\.(?:c?js|exs|sh)$/.test(name) &&
      !MUTABLE.has(name)) protectedNames.add(name);
  }
  const rows = fileManifestNames().filter((name) => !MUTABLE.has(name) && !isPlanOwned(name)).map(pathState);
  const porcelain = git(["status", "--porcelain=v1", "-z", "--untracked-files=all"]);
  const worktrees = git(["worktree", "list", "--porcelain"]).toString("utf8").split("\n")
    .filter((line) => !line.startsWith("HEAD ")).join("\n");
  return {
    head: gitText(["rev-parse", "HEAD"]), index: indexWithoutPlanArtifacts(),
    worktrees: sha(worktrees), porcelain: porcelainWithoutPlanArtifacts(porcelain),
    indexDiff: sha(git(["diff", "--no-ext-diff", "--cached", "--binary"])),
    worktreeDiff: sha(git(["diff", "--no-ext-diff", "--binary", "--", ".", ...REPORTS.map((file) => `:(exclude)${file}`)])),
    workInProgress: rows, protected: sorted(protectedNames).map(pathState),
    reportPreimages: REPORTS.map(pathState), toolchain: sha(JSON.stringify(inventory(MIX_HOME))),
  };
}
function verifyOwner(before) {
  const after = ownerBaseline();
  if (before.head !== after.head) {
    const ancestry = processCommand("git", ["merge-base", "--is-ancestor", before.head, after.head], {
      cwd: OWNER, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" },
    });
    need(ancestry.status === 0, "owner HEAD changed outside the plan commit chain");
    const changed = git(["diff", "--name-only", "-z", `${before.head}..${after.head}`]).toString().split("\0").filter(Boolean);
    need(changed.length > 0 && changed.every((name) => isPlanOwned(name)),
      "owner HEAD contains a commit outside plan-owned files");
  }
  for (const field of ["index", "worktrees", "indexDiff", "worktreeDiff", "workInProgress", "protected", "toolchain"])
    need(equal(before[field], after[field]), `owner baseline changed: ${field}`);
  return true;
}
function materialize(e, proof) {
  authorizeRoot(ROUTE, e.nonce);
  const home = path.join(ROUTE, "cache", "hex");
  const targetArchives = path.join(home, "packages", "hexpm");
  fs.mkdirSync(targetArchives, { recursive: true });
  fs.mkdirSync(path.join(ROUTE_MIX_HOME, "archives"), { recursive: true });
  fs.mkdirSync(path.join(ROUTE_MIX_HOME, "elixir", "1-18-otp-27"), { recursive: true });
  fs.cpSync(path.join(MIX_HOME, "archives", "hex-2.6.0"), path.join(ROUTE_MIX_HOME, "archives", "hex-2.6.0"),
    { recursive: true, force: false, errorOnExist: true });
  const rebar = path.join(ROUTE_MIX_HOME, "elixir", "1-18-otp-27", "rebar3");
  fs.copyFileSync(REBAR3, rebar, fs.constants.COPYFILE_EXCL);
  need(digest(rebar) === digest(REBAR3), "copied Rebar toolchain changed bytes");
  freeze(ROUTE_MIX_HOME);
  const sourceCache = bytes(REGISTRY_CACHE);
  need(e.cachePreflight?.source?.sha256 === sha(sourceCache) && e.cachePreflight?.source?.size === sourceCache.length,
    "owner registry cache no longer matches the approved preflight bytes");
  const routeCache = path.join(home, "cache.bin");
  fs.copyFileSync(REGISTRY_CACHE, routeCache, fs.constants.COPYFILE_EXCL);
  fs.chmodSync(routeCache, 0o400);
  const cacheStat = fs.lstatSync(routeCache), ownerCacheStat = fs.lstatSync(REGISTRY_CACHE);
  need(digest(routeCache) === e.cachePreflight.source.sha256 &&
    (cacheStat.dev !== ownerCacheStat.dev || cacheStat.ino !== ownerCacheStat.ino),
  "route cache is not the exact independent preflight copy");
  for (const [name, packageArchive] of proof.archives) {
    const raw = bytes(path.join(HEX_CACHE, "packages", "hexpm", `${name}.tar`));
    need(sha(raw) === packageArchive.outer, "cached package changed before materialization");
    fs.writeFileSync(path.join(targetArchives, `${name}.tar`), raw, { flag: "wx", mode: 0o400 });
  }
  const verify = [];
  const inventories = {};
  for (const [index, workspace] of WORKSPACES.entries()) {
    const canonical = path.join(ROUTE, "deps", workspace);
    fs.mkdirSync(canonical, { recursive: true, mode: 0o700 });
    for (const row of proof.final[index].packages) {
      const { contents, expected, metadata } = proof.archives.get(`${row.name}-${row.version}`);
      const directory = path.join(canonical, row.destination);
      fs.mkdirSync(directory, { mode: 0o700 });
      for (const name of sorted(expected.keys())) {
        const entry = expected.get(name);
        const full = path.join(directory, name);
        need(full.startsWith(directory + path.sep), "archive member escaped dependency root");
        if (entry.type === "directory") fs.mkdirSync(full, { mode: 0o700 });
        else fs.writeFileSync(full, contents.get(name).data, { flag: "wx", mode: entry.mode });
      }
      fs.writeFileSync(path.join(directory, "hex_metadata.config"), metadata, { flag: "wx", mode: 0o400 });
      fs.writeFileSync(path.join(directory, ".hex"), Buffer.from(row.manifest, "base64"), { flag: "wx", mode: 0o400 });
      verify.push({ row, dest: directory, sha256: row.manifest_sha256 });
    }
    freeze(canonical);
    const rows = inventory(canonical);
    need(rows.every((row) => (row.mode & 0o222) === 0), "canonical package snapshot is writable");
    inventories[workspace] = { paths: rows.length, sha256: sha(JSON.stringify(rows)) };
  }
  const status = hexCommand("verify", { rows: verify }, SOURCE);
  need(status.length === verify.length && status.every((value) => value === "ok"), "installed Hex rejected a snapshot lock");
  return { inventories, checkouts: verify.length, archives: [...proof.archives].map(([name, row]) => ({ name, sha256: row.outer })) };
}
function mixEnv(workspace, changes = {}) {
  return {
    PATH: `${ELIXIR_BIN}:${OTP_BIN}:${process.env.PATH}`, HOME: os.homedir(),
    ASDF_ELIXIR_VERSION: "1.18.4-otp-27", ASDF_ERLANG_VERSION: "27.3.4.13",
    MIX_HOME: ROUTE_MIX_HOME, MIX_REBAR3: path.join(ROUTE_MIX_HOME, "elixir", "1-18-otp-27", "rebar3"),
    MIX_ENV: "dev", HEX_OFFLINE: "1", REBAR_OFFLINE: "1",
    HEX_HOME: path.join(ROUTE, "cache", "hex"), XDG_CACHE_HOME: path.join(ROUTE, "cache", "xdg"),
    REBAR_CACHE_DIR: path.join(ROUTE, "cache", "rebar"), TMPDIR: path.join(ROUTE, "outputs"),
    MIX_BUILD_PATH: path.join(ROUTE, "build", workspace), MIX_DEPS_PATH: path.join(ROUTE, "deps", workspace),
    ERL_FLAGS: "+S 4:4 +A 2", LANG: "en_US.UTF-8", ...changes,
  };
}
function candidateProof(e, proof) {
  const changed = () => sorted(new Set([
    ...git(["diff", "--name-only", "-z", "HEAD"], SOURCE).toString().split("\0").filter(Boolean),
    ...git(["ls-files", "--others", "--exclude-standard", "-z"], SOURCE).toString().split("\0").filter(Boolean),
  ]));
  stage(e, "acquire", "git", ["clone", "--no-tags", "--single-branch", "--branch",
    BASE_REF.replace("refs/heads/", ""), "--no-checkout", REMOTE, SOURCE], {
    env: { PATH: process.env.PATH, GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null" }, timeout: 120000,
  });
  git(["config", "core.hooksPath", "/dev/null"], SOURCE);
  git(["checkout", "-b", BRANCH, BASE], SOURCE);
  need(gitText(["rev-parse", "HEAD^{tree}"], SOURCE) === TREE &&
    gitText(["rev-parse", "--absolute-git-dir"], SOURCE) === path.join(SOURCE, ".git") &&
    !exists(path.join(SOURCE, ".git", "objects", "info", "alternates")), "candidate Git identity failed");
  for (const row of inventory(path.join(SOURCE, ".git", "objects"))) need(row.type === "file" || row.type === "directory", "candidate stores shared Git objects");
  git(["apply", "--whitespace=nowarn", ...PATCH_SELECTION.map((file) => `--include=${file}`), PATCH], SOURCE);
  assert.deepEqual(changed(), sorted(PATCH_SELECTION));
  for (const { file, data, refreshed } of proof.cases) {
    const full = path.join(SOURCE, file);
    need(bytes(full).equals(Buffer.from(data)), "candidate lock did not match sealed base");
    fs.writeFileSync(full, refreshed);
  }
  e.candidate = { base: BASE, tree: TREE, branch: BRANCH, patchHash: PATCH_HASH };
  save(e);
  e.snapshot = materialize(e, proof);
  save(e);
  for (const { file, workspace, finalHash } of proof.cases) {
    const cwd = path.dirname(path.join(SOURCE, file));
    stage(e, `resolve-${workspace}`, path.join(ELIXIR_BIN, "mix"), ["deps.get", "--check-locked"], {
      cwd, env: mixEnv(workspace), timeout: 90000,
    });
    need(digest(path.join(SOURCE, file)) === finalHash, `${workspace} lock changed during offline resolution`);
  }
  return changed;
}
function preflight() {
  need(!exists(ROUTE), "one-shot route path is occupied");
  const evidence = load();
  need(evidence.status === "preallocation-review" && evidence.attempts.length === 0 && !evidence.allocated,
    "only a candidate-free preflight can proceed");
  const remote = gitText(["ls-remote", "--refs", REMOTE, BASE_REF, `refs/heads/${BRANCH}`]);
  need(remote === `${BASE}\t${BASE_REF}`, "remote provenance drift or occupied route ref");
  const workflow = JSON.parse(success("gh", ["api", `repos/${REPOSITORY}/actions/workflows/${WORKFLOW}`]));
  need(String(workflow.id) === WORKFLOW && workflow.path === ".github/workflows/ci.yml" && workflow.state === "active",
    "pinned CI workflow is unavailable");
  const prs = readPulls();
  const image = JSON.parse(success("docker", ["image", "inspect", IMAGE]));
  need(image.length === 1 && image[0].Os === "linux" && image[0].RepoTags.includes(IMAGE), "pinned Playwright image is absent");
  return { workflow: { id: workflow.id, path: workflow.path }, prs, image: image[0].Id };
}
function readPulls() {
  const rows = JSON.parse(success("gh", ["pr", "list", "--repo", REPOSITORY, "--state", "open",
    "--json", "number,headRefOid,baseRefOid,state", "--limit", "3"]));
  need(rows.length === 1 && rows[0].number === 325 && rows[0].state === "OPEN", "open PR hold changed");
  return rows;
}

function edit(relative, update) {
  const file = path.join(SOURCE, relative);
  need(APPROVED_PATHS.includes(relative), "source edit is not in the candidate allowlist");
  const before = bytes(file).toString("utf8");
  const after = update(before);
  need(before !== after, `stale repair at ${relative}`);
  fs.writeFileSync(file, after);
}
function replaceExact(text, before, after) {
  need(text.split(before).length === 2, "repair source anchor is missing or ambiguous");
  return text.replace(before, after);
}
function createIDNAContract() {
  const source = String.raw`defmodule Mailglass.IDNACompatibilityContract do
  use ExUnit.Case, async: true

  alias Swoosh.Email.Render

  test "outbound serialization preserves ASCII, local parts, and root dots" do
    assert Render.render_recipient({nil, "Reader+mail@example.com"}) == "Reader+mail@example.com"

    assert Render.render_recipient([
             {"Reader \"A\"", "Reader+mail@bücher.example"},
             {nil, "other@example.com."}
           ]) == ~S("Reader \"A\"" <Reader+mail@xn--bcher-kva.example>, other@example.com.)
  end

  test "upgraded IDNA rejects malformed input and DNS length violations" do
    domains = [
      "xn--.example",
      "example..com",
      <<255, ".example">>,
      String.duplicate("a", 64) <> ".example",
      Enum.join(List.duplicate(String.duplicate("a", 63), 4), ".")
    ]

    for domain <- domains do
      result =
        try do
          {:ok, Render.render_recipient({nil, "reader@" <> domain})}
        catch
          kind, reason -> {:rejected, kind, reason}
        end

      assert {:rejected, _kind, _reason} = result
    end
  end
end
`;
  fs.writeFileSync(path.join(SOURCE, IDNA_TEST), source, { flag: "wx", mode: 0o644 });
}
function testConcurrentRender() {
  const test = `  test "overlapping delivery verdict renders keep their own cause and class" do
    parent = self()
    gate = make_ref()
    rejected = {:event, :rejected, :invalid}
    suppressed = {:suppression, :manual}

    render = fn cell ->
      Task.async(fn ->
        render_component(
          fn assigns ->
            send(parent, {gate, self()})

            receive do
              ^gate -> Components.delivery_verdict(assigns)
            after
              5_000 -> flunk("parallel verdict render never released")
            end
          end,
          verdict:
            Copy.delivery_verdict(row(cell), %{
              events: events(cell),
              suppression: if(cell == suppressed, do: %{reason: :manual}, else: :not_loaded)
            }),
          form: :full,
          id: "parallel-verdict"
        )
      end)
    end

    left = render.(rejected)
    right = render.(suppressed)
    left_pid = left.pid
    right_pid = right.pid
    assert_receive {^gate, ^left_pid}, 5_000
    assert_receive {^gate, ^right_pid}, 5_000
    send(left_pid, gate)
    send(right_pid, gate)

    assert cell_violations(expected(rejected), Task.await(left)) == []
    assert cell_violations(expected(suppressed), Task.await(right)) == []
  end

`;
  edit(CAUSE_TEST, (input) => replaceExact(input, '  describe "structure (D-04)" do', test + '  describe "structure (D-04)" do'));
}
function implementLocalSource() {
  const patch = bytes(PATCH).toString();
  const runtimeHelper = patch.split("diff --git a/scripts/demo_admin_node_runtime.cjs ")[1]?.split("\ndiff --git ")[0];
  need(runtimeHelper, "sealed patch lacks inline runtime source");
  const preload = runtimeHelper.split("\n").filter((line) => line.startsWith("+") && !line.startsWith("+++"))
    .map((line) => line.slice(1)).join("\n")
    .replace('const cli = process.argv[1] || "";', 'const cli = process.argv[1] ? require("node:fs").realpathSync(process.argv[1]) : "";');
  // The final source keeps the helper inside the existing Compose runner.
  const withRealPath = replaceExact(preload,
    "const argv = process.argv.slice(1);",
    "const argv = process.argv.slice(1);\nif (argv[0] && fs.existsSync(argv[0])) argv[0] = fs.realpathSync(argv[0]);");
  edit("scripts/run_demo_browser_evidence.sh", (input) => {
    input = replaceExact(input, 'NODE_OPTIONS="--require=/workspace/scripts/demo_admin_node_runtime.cjs"',
      'NODE_OPTIONS="--require=/tmp/mailglass-admin-node-runtime.cjs"');
    input = replaceExact(input, 'rm -f "$admin_runtime_proof_path"',
      `rm -f "$admin_runtime_proof_path"\ncat > /tmp/mailglass-admin-node-runtime.cjs <<'ADMIN_NODE_RUNTIME'\n${withRealPath}\nADMIN_NODE_RUNTIME`);
    input = input.replace(/^(\s*)(npm .*mailglass_admin.*(?:ci|run test:operator-browser).*)$/gm,
      '$1PATH="/opt/runner-node/bin:$PATH" $2');
    input = replaceExact(input, '      ./node_modules/.bin/playwright test --config=playwright.config.cjs --workers=1',
      '      PATH="/opt/runner-node/bin:$PATH" ./node_modules/.bin/playwright test --config=playwright.config.cjs --workers=1');
    return input;
  });
  edit("scripts/check_phase174_evidence.cjs", (input) =>
    replaceExact(input, '  "scripts/demo_admin_node_runtime.cjs",\n', ""));
  edit("mailglass_admin/e2e/phase177-account.spec.js", (input) =>
    replaceExact(input, 'aria-label="Mailglass sections"', 'aria-label="mailglass sections"'));
  edit("test/scripts/phase184_07_runtime_contract.test.cjs", (input) => input
    .replace(/assert\.match\(read\('scripts\/demo_admin_node_runtime\.cjs'\),/g, "assert.match(script,")
    .replace(/\/workspace\\\/scripts\\\/demo_admin_node_runtime/g, "/tmp\\/mailglass-admin-node-runtime"));
  testConcurrentRender();
}
function buildViews(e) {
  const buildViews = path.join(ROUTE, "local-deps");
  fs.mkdirSync(buildViews, { mode: 0o700 });
  for (const workspace of ["core", "admin", "inbound", "demo"]) {
    const hash = makeBuildView(path.join(ROUTE, "deps", workspace), path.join(buildViews, workspace));
    need(hash === e.snapshot.inventories[workspace].sha256, "writable view differs from canonical input proof");
  }
  return buildViews;
}
function implementDocs() {
  const helper = `#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHash } = require("node:crypto");
const assert = require("node:assert/strict");
const sha = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sorted = (entries) => [...entries].sort();
${need.toString()}
${exists.toString()}
${bytes.toString()}
${writeMode.toString()}
${inventory.toString()}
${makeBuildView.toString()}

const [input, output] = process.argv.slice(2);
assert.equal(fs.realpathSync(input), input);
const root = path.dirname(input);
assert(["core", "admin", "inbound"].includes(path.basename(input)));
assert.equal(output, path.join(root, "compile", path.basename(input)));
if (!exists(path.dirname(output))) fs.mkdirSync(path.dirname(output), { mode: 0o700 });
assert.equal(fs.realpathSync(path.dirname(output)), path.dirname(output));
const proof = makeBuildView(input, output);
console.log(JSON.stringify({
  schema: "phase184-12-docs-compile-view.v1", workspace: path.basename(input),
  sourceInventorySha256: proof, files: inventory(input).filter((row) => row.type === "file").length,
  sourceReadOnly: true, ownerHardlinks: false, contentMatches: true, writablePackage: "earmark_parser",
}));
`;
  edit("scripts/prepare_docs_compile_snapshot.cjs", () => helper);
  edit("scripts/verify_brand_docs.sh", (input) => {
    const trap = `set -Eeuo pipefail
readonly docs_stage_start="$(date -u +%FT%TZ)"
trap 'printf "[verify_brand_docs] failure line=%s status=%s start=%s\\n" "$LINENO" "$?" "$docs_stage_start" >&2' ERR`;
    input = replaceExact(input, "set -euo pipefail", trap);
    let n = 0;
    input = input.replace(/docker run --rm/g, () => {
      n += 1;
      return 'docker run --rm --label "com.mailglass.gsd.route=$MAILGLASS_DOCS_ROUTE_LABEL" --name "$MAILGLASS_DOCS_ROUTE_LABEL-' + n + '"';
    });
    need(n === 3, "unexpected docs browser container count");
    input = replaceExact(input,
      "const record={schema:'phase184-07-docs-browser-runtime.v1',candidate,sourceFingerprint",
      "const stagedTree=execFileSync('git',['-C',root,'write-tree'],{encoding:'utf8'}).trim();\nif(stagedTree!==process.env.MAILGLASS_DOCS_STAGED_TREE)throw new Error('staged candidate tree drift');\nconst record={schema:'phase184-12-docs-browser-runtime.v1',candidate,stagedTree,sourceFingerprint");
    return input;
  });
}
function verifyCanonical(e) {
  for (const [workspace, row] of Object.entries(e.snapshot.inventories)) {
    const current = inventory(path.join(ROUTE, "deps", workspace));
    need(current.length === row.paths && sha(JSON.stringify(current)) === row.sha256,
      `canonical snapshot changed: ${workspace}`);
  }
}
function runLocal(e, buildViews) {
  const coreEnv = mixEnv("core", { MIX_DEPS_PATH: path.join(buildViews, "core") });
  createIDNAContract();
  implementLocalSource();
  implementDocs();
  for (const file of ["scripts/verify_brand_docs.sh", "scripts/run_demo_browser_evidence.sh"])
    stage(e, `syntax-${path.basename(file, ".sh")}`, "bash", ["-n", file], { cwd: SOURCE });
  stage(e, "runtime-contracts", "node", ["--test", "test/scripts/phase184_07_runtime_contract.test.cjs",
    "scripts/check_phase174_evidence.test.cjs"], { cwd: SOURCE, timeout: 60000 });
  const parsedFormatting = FORMAT_PATHS.map((name) => {
    const expr = 'for f <- System.argv(), do: IO.puts(Base.encode64(:erlang.term_to_binary(Code.string_to_quoted!(File.read!(f)) |> Macro.prewalk(fn {a, m, b} when is_list(m) -> {a, Keyword.drop(m, [:line, :column]), b}; item -> item end))))';
    const argv = ["-e", expr, "--", name];
    return { name, argv, preimage: sha(success(path.join(ELIXIR_BIN, "elixir"), argv, { cwd: SOURCE, env: coreEnv })) };
  });
  stage(e, "scoped-format", path.join(ELIXIR_BIN, "mix"), ["format", ...FORMAT_PATHS], { cwd: SOURCE, env: coreEnv });
  for (const row of parsedFormatting) need(sha(success(path.join(ELIXIR_BIN, "elixir"), row.argv, { cwd: SOURCE, env: coreEnv })) === row.preimage,
    `formatting changed parsed code: ${row.name}`);
  stage(e, "format", path.join(ELIXIR_BIN, "mix"), ["format", "--check-formatted"], { cwd: SOURCE, env: coreEnv });
  const codec = `Application.load(:swoosh); Application.load(:idna); IO.inspect({Application.spec(:swoosh, :vsn), Application.spec(:idna, :vsn), :code.which(Swoosh.Email.Render), :code.which(:idna)}); ExUnit.start(); Code.require_file("${IDNA_TEST}")`;
  const compatibility = stage(e, "idna-compatibility", path.join(ELIXIR_BIN, "mix"), ["run", "--no-start", "-e", codec], {
    cwd: SOURCE, env: coreEnv, timeout: 180000,
  }).toString();
  need(compatibility.includes("2 tests, 0 failures") && compatibility.includes("'1.30.0'") &&
    compatibility.includes("'8.0.0'"), "compatibility contract did not prove both exact loaded versions and tests");
  verifyCanonical(e);
  stage(e, "docs-fixtures", path.join(ELIXIR_BIN, "mix"), ["run", "--no-start", "-r", "test/support/ci_yaml.ex", "-e",
    'ExUnit.start(); Code.require_file("test/scripts/brand_docs_contract_test.exs"); Code.require_file("test/scripts/brand_docs_ci_wiring_test.exs")'],
  { cwd: SOURCE, env: coreEnv, timeout: 90000 });
  stage(e, "credo", path.join(ELIXIR_BIN, "mix"), ["credo", "--strict"], { cwd: SOURCE, env: coreEnv, timeout: 90000 });
  verifyCanonical(e);
}

function dockerInventory() {
  const items = (args) => success("docker", args).toString().split("\n").filter(Boolean);
  const containers = items(["ps", "-aq", "--no-trunc"]).sort();
  const inspect = containers.length ? JSON.parse(success("docker", ["inspect", ...containers])) : [];
  return {
    containers: inspect.map((c) => ({ id: c.Id, name: c.Name, image: c.Image, state: c.State.Status,
      health: c.State.Health?.Status ?? null, startedAt: c.State.StartedAt,
      project: c.Config.Labels?.["com.docker.compose.project"] ?? null,
      route: c.Config.Labels?.["com.mailglass.gsd.route"] ?? null })),
    networks: items(["network", "ls", "--no-trunc", "--format", "{{.ID}} {{.Name}}"]).sort(),
    images: items(["image", "ls", "--no-trunc", "--digests", "--format", "{{.ID}} {{.Repository}} {{.Tag}} {{.Digest}} {{.Size}}"]).sort(),
    volumes: items(["volume", "ls", "--format", "{{.Name}} {{.Driver}}"]).sort(),
  };
}
function dockerCleanup(e) {
  if (!e.docker) return { created: [], removed: [], retained: [], mutated: false };
  const after = dockerInventory();
  const before = e.docker.before;
  const created = after.containers.filter((c) => !before.containers.some((b) => b.id === c.id));
  const unrelated = after.containers.filter((c) => c.route !== e.docker.label);
  need(equal(unrelated, before.containers) && equal(after.networks, before.networks) &&
    equal(after.images, before.images) && equal(after.volumes, before.volumes), "unrelated Docker inventory changed");
  need(created.every((c) => c.route === e.docker.label && c.name.startsWith("/" + e.docker.label + "-")),
    "candidate Docker container ownership mismatch");
  for (const c of created) success("docker", ["rm", "-f", c.id]);
  const final = dockerInventory();
  assert.deepEqual(final, before);
  return { mutated: true, created: created.map((c) => c.id), removed: created.map((c) => c.id),
    retained: [], postInventory: final };
}
function docsStage(e, changed) {
  const paths = changed();
  need(paths.every((file) => APPROVED_PATHS.includes(file)) &&
    [...LOCKS, ...PATCH_SELECTION, IDNA_TEST, CAUSE_TEST].every((file) => paths.includes(file)),
    "candidate source delta escaped the approved path set");
  git(["add", "--", ...paths], SOURCE);
  need(gitText(["diff", "--name-only"], SOURCE) === "" &&
    gitText(["ls-files", "--others", "--exclude-standard"], SOURCE) === "", "candidate remains unstaged");
  const tree = gitText(["write-tree"], SOURCE);
  e.candidate.stagedTree = tree;
  e.candidate.paths = paths;
  const outputs = path.join(ROUTE, "outputs");
  for (const name of ["output", "build", "cache"]) fs.mkdirSync(path.join(ROUTE, "deps", name), { recursive: true });
  const docsReceipt = path.join(outputs, "docs-browser.json");
  const label = `phase184-12-${e.nonce}`;
  const image = JSON.parse(success("docker", ["image", "inspect", IMAGE]))[0];
  need(image?.Id === e.verifiedBoundary.image, "loaded browser image identity drift");
  e.docker = { before: dockerInventory(), label };
  save(e);
  stage(e, "docs-browser", "bash", ["scripts/verify_brand_docs.sh", "--browser"], {
    cwd: SOURCE, timeout: 480000, env: mixEnv("core", {
      MAILGLASS_CANDIDATE_DEPS_ROOT: path.join(ROUTE, "deps"), MAILGLASS_READONLY_MIX_HOME: ROUTE_MIX_HOME,
      MAILGLASS_DOCS_BROWSER_EVIDENCE: docsReceipt, MAILGLASS_DOCS_STAGED_TREE: tree, MAILGLASS_DOCS_ROUTE_LABEL: label,
      GIT_CONFIG_COUNT: "1", GIT_CONFIG_KEY_0: "safe.directory", GIT_CONFIG_VALUE_0: "/work",
    }),
  });
  const receipt = JSON.parse(bytes(docsReceipt));
  need(receipt.schema === "phase184-12-docs-browser-runtime.v1" && receipt.candidate === BASE &&
    receipt.stagedTree === tree && receipt.image.id === image.Id && /^[a-f0-9]{64}$/.test(receipt.outputTreeSha256),
    "same-output docs receipt failed candidate identity checks");
  need(receipt.compileSnapshots.every((row) => row.sourceInventorySha256 === e.snapshot.inventories[row.workspace].sha256),
    "docs build view differs from sealed dependency input");
  verifyCanonical(e);
  e.docs = { sha256: digest(docsReceipt), value: receipt };
  save(e);
}
function recordBlocked(e, error, gate) {
  e.firstStop = { gate, reason: sanitize(error.message).slice(0, 1000), at: now() };
  e.status = "blocked";
  save(e);
  let docker;
  try {
    if (e.snapshot) verifyCanonical(e);
  } catch (err) { e.snapshotDrift = sanitize(err.message); }
  try { docker = dockerCleanup(e); }
  catch (err) { e.dockerCleanupIssue = sanitize(err.message); }
  try {
    const removed = e.allocated && exists(ROUTE) ? removeOwned(ROUTE, e.nonce) : [];
    e.cleanup = { routeRootAbsent: !exists(ROUTE), removed, docker };
  } catch (err) {
    e.cleanup = { routeRootAbsent: !exists(ROUTE), error: sanitize(err.message), docker };
  }
  try { e.cleanup.ownerEqual = verifyOwner(e.owner); }
  catch (err) { e.cleanup.ownerEqual = false; e.cleanup.ownerIssue = sanitize(err.message); }
  save(e);
  return { status: e.status, firstStop: e.firstStop, stageCount: e.attempts.length,
    routeRootAbsent: e.cleanup.routeRootAbsent, cleanupVerified: e.cleanup.ownerEqual && !e.dockerCleanupIssue };
}
function startLocal() {
  const e = load();
  need(e.status === "preallocation-review" && e.cachePreflight?.status === "passed" &&
    !e.allocated && !exists(ROUTE) && !exists(PREFLIGHT) && !exists(SCRATCH), "cache preflight receipt is not current and passing");
  validateRegistryMeta(e.cachePreflight, 124, path.join(PREFLIGHT, "cache", "hex", "cache.bin"));
  need(digest(REGISTRY_CACHE) === e.cachePreflight.source.sha256, "owner cache changed after preallocation proof");
  const boundary = preflight();
  const production = new Set(["core", "admin", "inbound"]);
  need(e.advisories.findings.every((finding) => !finding.workspaces.some((workspace) => production.has(workspace)) &&
    !Object.hasOwn(UPDATES, finding.name)), "production or newly introduced advisory blocks the route");
  const plan = bytes(PLAN);
  need(sha(plan) === e.planSha256, "approved plan bytes changed after preallocation");
  const proof = lockProof();
  assert.deepEqual(e.proposedGraph.locks, proof.cases.map(({ file, originalOid, originalHash, finalHash }) =>
    ({ file, originalOid, originalHash, finalHash })));
  e.preallocationOwner = e.owner;
  e.owner = ownerBaseline();
  e.verifiedBoundary = boundary;
  e.planSha256 = sha(plan);
  e.productionAdvisories = { workspaces: [...production], findings: 0, newFindings: 0,
    basis: "retained OSV metadata on exact production lock tuples; required hosted Hex Audit stays in force" };
  e.status = "running";
  e.nonce = randomUUID();
  save(e);
  let gate = "allocate";
  try {
    markRoot(ROUTE, e.nonce);
    e.allocated = true;
    fs.mkdirSync(path.join(ROUTE, "attempts"), { mode: 0o700 });
    fs.mkdirSync(path.join(ROUTE, "outputs"), { mode: 0o700 });
    save(e);
    gate = "candidate-five-lock-resolver";
    const changed = candidateProof(e, proof);
    gate = "read-only-compiler-and-local-contracts";
    runLocal(e, buildViews(e));
    gate = "same-output-docs-browser";
    docsStage(e, changed);
    verifyOwner(e.owner);
    e.status = "local-passed";
    save(e);
    return { status: e.status, stageCount: e.attempts.length, stagedTree: e.candidate.stagedTree };
  } catch (error) {
    return recordBlocked(e, error, gate);
  }
}

function testedCommands() {
  return {
    resolve: ["mix", "deps.get", "--check-locked"],
    docs: ["bash", "scripts/verify_brand_docs.sh", "--browser"],
    dispatch: ["gh", "workflow", "run", WORKFLOW, "--repo", REPOSITORY, "--ref", BRANCH],
    browserContainer: ["docker", "run", "--pull=never", "--network=none", "--read-only", IMAGE],
  };
}
function selftest() {
  need(!exists(ROUTE), "candidate-free controller fixture must run with route absent");
  const root = fs.mkdtempSync("/private/tmp/mailglass-phase184-12-fixture-");
  const nonce = randomUUID();
  const owned = path.join(root, "route");
  try {
    markRoot(owned, nonce);
    const canonical = path.join(owned, "canonical");
    fs.mkdirSync(path.join(canonical, "earmark_parser", "src"), { recursive: true });
    fs.mkdirSync(path.join(canonical, "other"));
    fs.writeFileSync(path.join(canonical, "earmark_parser", "src", "scanner.xrl"), "fixture source");
    fs.writeFileSync(path.join(canonical, "other", "mix.exs"), "fixture lock");
    freeze(canonical);
    const before = inventory(canonical);
    const view = path.join(owned, "view");
    const digestBefore = makeBuildView(canonical, view);
    assert.equal(digestBefore, sha(JSON.stringify(before)));
    assert.equal(fs.realpathSync(path.join(view, "other")), path.join(canonical, "other"));
    assert.throws(() => fs.openSync(path.join(view, "other", "mix.exs"), "r+"), { code: "EACCES" });
    fs.writeFileSync(path.join(view, "earmark_parser", "src", "scanner.erl"), "fixture output");
    const abort = processCommand("/bin/sh", ["-c", "exit 134"], { cwd: owned });
    assert.equal(abort.status, 134);
    assert.deepEqual(inventory(canonical), before);
    assert.throws(() => makeBuildView(canonical, view), /already exists/);
    assert.throws(() => removeOwned(owned, randomUUID()), /ownership record mismatch/);
    assert(exists(owned));
    assert.equal(removeOwned(owned, nonce).at(-1), ROOT_MARKER);
    assert(!exists(owned));
    const input = git(["show", `${BASE}:mix.lock`]).toString();
    const valid = refreshLock(input);
    assert.throws(() => verifyLockDelta(parseLock(input), parseLock(valid.replace('"1.20.4"', '"1.20.3"'))),
      /unapproved lock change/);
    assert.throws(() => archiveEnvelope(Buffer.alloc(1024), {
      name: "swoosh", outer_checksum: UPDATES.swoosh.outer, inner_checksum: UPDATES.swoosh.inner,
    }), /outer checksum/);
    const command = testedCommands();
    assert.deepEqual(command.resolve, ["mix", "deps.get", "--check-locked"]);
    assert(command.browserContainer.includes("--pull=never") && command.browserContainer.includes("--network=none"));
    assert(command.dispatch.includes(BRANCH) && command.dispatch.includes(WORKFLOW));
    assert.equal(assertStageAllowed({ status: "fresh", attempts: [] }, "cache-preflight"), true);
    assert.throws(() => assertStageAllowed({ status: "fresh", attempts: [] }, "start-local"), /not selected/);
    assert.equal(assertStageAllowed({ status: "preallocation-review", attempts: [] }, "start-local"), true);
    assert.equal(assertStageAllowed({ status: "local-passed", attempts: [] }, "run-hosted"), true);
    assert.equal(assertStageAllowed({ status: "hosted-passed", attempts: [] }, "run-preview"), true);
    for (const status of ["blocked", "terminal"]) {
      for (const stage of ["cache-preflight", "start-local", "run-hosted", "run-preview"]) {
        assert.throws(() => assertStageAllowed({ status, attempts: [] }, stage), /blocked route/);
      }
    }
    const receiptRows = [
      { name: "alpha", version: "1.0.0", inner: "a".repeat(64), outer: "b".repeat(64), dependencies: [] },
      { name: "beta", version: "2.0.0", inner: "c".repeat(64), outer: "d".repeat(64), dependencies: [] },
    ];
    const rawReceiptRows = receiptRows.map((row) => ({ ...row,
      innerRaw: Buffer.from(row.inner, "hex"), outerRaw: Buffer.from(row.outer, "hex") }));
    const validReceipt = { mode: "probe", schema: 5, repoUrl: "https://repo.hex.pm",
      effectiveRepoUrl: "https://repo.hex.pm", effectiveCachePath: "/fixture/hex/cache.bin",
      offline: true, records: rawReceiptRows };
    assert.equal(validateRegistryReceipt(validReceipt, receiptRows, "/fixture/hex/cache.bin").recordsChecked, 2);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, schema: 3 }, receiptRows, "/fixture/hex/cache.bin"), /schema/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, repoUrl: "https://wrong.invalid" }, receiptRows, "/fixture/hex/cache.bin"), /repo URL/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, effectiveRepoUrl: "https://wrong.invalid" }, receiptRows, "/fixture/hex/cache.bin"), /repo URL/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, effectiveCachePath: "/owner/.hex/cache.bin" }, receiptRows, "/fixture/hex/cache.bin"), /cache path/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, offline: false }, receiptRows, "/fixture/hex/cache.bin"), /offline/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, records: rawReceiptRows.slice(1) }, receiptRows, "/fixture/hex/cache.bin"), /record count/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, records: [...rawReceiptRows, rawReceiptRows[0]] }, receiptRows, "/fixture/hex/cache.bin"), /record count/);
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, records: rawReceiptRows.map((row) =>
      row.name === "alpha" ? { ...row, outerRaw: Buffer.from("ee".repeat(32), "hex") } : row) }, receiptRows, "/fixture/hex/cache.bin"), /checksum mismatch/);
    const wrongDependency = ["hexpm", "dep", "dep", "~> 1.0", "false"]
      .map((value) => Buffer.from(value).toString("base64")).join(",");
    assert.throws(() => validateRegistryReceipt({ ...validReceipt, records: rawReceiptRows.map((row) =>
      row.name === "beta" ? { ...row, dependencies: [wrongDependency] } : row) }, receiptRows, "/fixture/hex/cache.bin"), /dependency/);
    return { status: "passed", candidateRootAbsent: !exists(ROUTE), writableLeexFixture: true,
      archiveTamperRejected: true, lockScopeEnforced: true, injectedExit: abort.status, markerLast: true,
      cacheSchemaAndRepoFailClosed: true, recordAndChecksumMismatchRejected: true, routesExecuted: 0 };
  } finally {
    if (exists(owned)) removeOwned(owned, nonce);
    fs.rmdirSync(root);
  }
}
async function advisoryProof(proof) {
  const packages = new Map();
  for (const [index, { packages: rows }] of proof.final.entries()) {
    for (const row of rows) {
      const key = `${row.name}@${row.version}`;
      if (!packages.has(key)) packages.set(key, {
        query: { package: { ecosystem: "Hex", name: row.name }, version: row.version }, workspaces: [],
      });
      packages.get(key).workspaces.push(WORKSPACES[index]);
    }
  }
  const list = Array.from(packages.values());
  const request = JSON.stringify({ queries: list.map(({ query }) => query) });
  const endpoint = "https://api.osv.dev/v1/querybatch";
  const response = await fetch(endpoint, {
    method: "POST", headers: { "content-type": "application/json" }, body: request, signal: AbortSignal.timeout(20000),
  });
  need(response.ok, "advisory database read failed");
  const raw = Buffer.from(await response.arrayBuffer());
  const { results } = JSON.parse(raw);
  need(Array.isArray(results) && results.length === list.length && results.every((row) => row && !row.next_page_token),
    "advisory database response was incomplete");
  const findings = [];
  for (const [index, row] of results.entries()) {
    const { query, workspaces } = list[index];
    if (row.vulns?.length) {
      need(row.vulns.every(({ id }) => /^[A-Za-z0-9-]{1,100}$/.test(id)), "malformed advisory identifier");
      findings.push({ name: query.package.name, version: query.version, workspaces, ids: sorted(row.vulns.map(({ id }) => id)) });
    }
  }
  return { endpoint, checkedAt: now(), queryCount: list.length, requestSha256: sha(request), responseSha256: sha(raw),
    findings, findingIds: findings.reduce((sum, row) => sum + row.ids.length, 0) };
}
function verifyTerminal(e = load()) {
  need(e.status === "blocked" && e.firstStop?.gate, "blocked gate record is absent");
  need(!exists(ROUTE) && e.cleanup?.routeRootAbsent, "blocked route could not prove resource removal");
  need(e.attempts.length === new Set(e.attempts.map((row) => row.label)).size, "one-shot attempts were duplicated");
  if (e.allocated) need(e.cleanup.ownerEqual && !e.dockerCleanupIssue && e.cleanup.removed?.at(-1) === ROOT_MARKER,
    "cleanup or protected owner baseline could not be proved");
  else need(e.attempts.length === 0, "candidate-free stop recorded an effect");
  need(!exists(PREFLIGHT) && !exists(SCRATCH) && e.cleanup?.preflightRootAbsent === true &&
    e.cleanup?.scratchRootAbsent === true, "preflight and scratch cleanup is not proven");
  const ledger = custodyRows();
  validateTerminalCustody(e, ledger);
  need(e.custody?.sha256 === digest(CUSTODY), "terminal evidence does not bind the final custody ledger");
  const preimage = path.join(RETAINED, "terminal-preimage.json");
  need(exists(preimage) && digest(preimage) === e.terminal.preimageSha256,
    "terminal preimage is absent or changed");
  verifyOwner(e.owner);
  return { status: "verified", disposition: "blocked", routeRootAbsent: true, attempts: e.attempts.length };
}
function verifyPreallocation(e = load()) {
  need(["preallocation-review", "blocked"].includes(e.status) && e.allocated === false &&
    Array.isArray(e.attempts) && e.attempts.length === 0, "preallocation receipt has downstream activity");
  need(!exists(ROUTE) && !exists(PREFLIGHT) && !exists(SCRATCH) && e.cleanup?.routeRootAbsent === true &&
    e.cleanup?.preflightRootAbsent === true && e.cleanup?.scratchRootAbsent === true,
  "candidate-free preallocation roots are not absent");
  need(e.effectCounters?.candidateAllocation === 0 && e.effectCounters?.push === 0 &&
    e.effectCounters?.dispatch === 0 && e.effectCounters?.preview === 0,
  "preallocation receipt reserved a downstream effect");
  const ledger = custodyRows();
  const nonce = e.route?.nonce;
  need(typeof nonce === "string" && ledger.filter((row) => row.kind === "route" && row.label === "route-start" &&
    row.status === "reserved" && row.nonce === nonce).length === 1,
  "preallocation route reservation is absent or ambiguous");
  const routeResults = ledger.filter((row) => row.kind === "route" && row.label === "preallocation-result" && row.nonce === nonce);
  need(routeResults.length === 1 && routeResults[0].status === (e.status === "blocked" ? "blocked" : "passed"),
    "preallocation route result is absent or disagrees with the evidence");
  const reservations = ledger.filter((row) => row.kind === "effect" && row.label === "cache-preflight");
  const results = ledger.filter((row) => row.kind === "effect-result" && row.label === "cache-preflight");
  need(reservations.length === e.effectCounters.cachePreflight && results.length === reservations.length &&
    reservations.every((row) => row.nonce === nonce) && results.every((row) => row.nonce === nonce &&
      row.status === (e.status === "blocked" ? "blocked" : "passed")),
  "cache preflight effect counter or one-shot ledger differs");
  need(e.custody?.sha256 === digest(CUSTODY), "preallocation evidence does not bind the custody ledger");
  if (e.status === "blocked") {
    need(e.firstStop?.gate && e.firstStop.reason && e.cleanup?.ownerEqual === true,
      "blocked preallocation has no exact stop or owner reconciliation");
    need(e.cachePreflight?.status === "blocked" && e.effectCounters.cachePreflight <= 1,
      "blocked preallocation receipt is incomplete");
    need((!e.cleanup.preflightCreated || e.cleanup.preflightRemoved === true) &&
      (!e.cleanup.scratchCreated || e.cleanup.scratchRemoved === true),
    "blocked preallocation did not remove every created root marker-last");
    verifyOwner(e.owner);
    return { status: "verified", disposition: "blocked", stage: "preallocation", firstStop: e.firstStop,
      cachePreflightInvoked: e.effectCounters.cachePreflight === 1, candidateRootAbsent: true };
  }

  need(e.cachePreflight?.status === "passed" && e.source?.commit === BASE && e.source?.tree === TREE &&
    path.relative(OWNER, e.source.patchPath) === PATCH_RELATIVE && e.source.patchHash === PATCH_HASH,
  "preallocation source identity is incomplete");
  need(digest(PLAN) === e.planSha256 && digest(TDD_RECORD) === e.tddEvidenceSha256 &&
    digest(path.join(__dirname, "184-12-route.cjs")) === e.routeControllerSha256 &&
    digest(path.join(__dirname, "184-12-route.test.cjs")) === e.routeTestsSha256,
  "plan, fixture, or controller bytes changed after preallocation");
  need(equal(installedBrowserProof(), e.installedBrowser) && equal(toolchainProof(), e.toolchain),
    "installed image, Admin Playwright module, or toolchain identity drifted");

  const proof = lockProof();
  const rows = registryRows(proof);
  need(rows.length === 124 && proof.archives.size === 124 &&
    proof.final.reduce((sum, workspace) => sum + workspace.packages.length, 0) === 282 &&
    sha(JSON.stringify(rows)) === e.cachePreflight.requiredRecordsSha256,
  "sealed five-lock record inventory differs from the preflight evidence");
  const expectedLocks = proof.cases.map(({ file, originalOid, originalHash, finalHash }) => ({ file, originalOid, originalHash, finalHash }));
  need(equal(e.proposedGraph.locks, expectedLocks) && e.proposedGraph.archives === 124 &&
    e.proposedGraph.lockManifests === 282, "preallocation lock and archive receipts differ from the sealed source");

  const sourceStat = fs.lstatSync(REGISTRY_CACHE);
  need(sourceStat.isFile() && !sourceStat.isSymbolicLink() && sourceStat.nlink === 1 &&
    sourceStat.dev === e.cachePreflight.source.dev && sourceStat.ino === e.cachePreflight.source.ino &&
    sourceStat.mtimeMs === e.cachePreflight.source.mtimeMs &&
    (sourceStat.mode & 0o777) === e.cachePreflight.source.mode && digest(REGISTRY_CACHE) === e.cachePreflight.source.sha256,
  "owner schema-5 cache identity or bytes changed after prefetch");
  const retained = new Map(e.cachePreflight.retained.map((row) => [path.basename(row.path), row]));
  need(retained.size === 2 && retained.has("cache-inspection.json") && retained.has("cache-prefetch.json"),
    "both retained registry receipts are required");
  const inspectFile = retained.get("cache-inspection.json"), probeFile = retained.get("cache-prefetch.json");
  for (const item of [inspectFile, probeFile])
    need(digest(path.join(OWNER, item.path)) === item.sha256, `retained receipt hash mismatch: ${path.basename(item.path)}`);
  const inspection = JSON.parse(bytes(path.join(OWNER, inspectFile.path)));
  const prefetch = JSON.parse(bytes(path.join(OWNER, probeFile.path)));
  need(inspection.cache.sha256 === e.cachePreflight.source.sha256 && inspection.cache.size === e.cachePreflight.source.size &&
    inspection.cache.nlink === 1 && prefetch.sourceCacheSha256 === e.cachePreflight.source.sha256 &&
    prefetch.disposableCopySha256 === e.cachePreflight.source.sha256 && prefetch.offline === true &&
    prefetch.effectiveRepoUrl === "https://repo.hex.pm" &&
    prefetch.effectiveCachePath === path.join(PREFLIGHT, "cache", "hex", "cache.bin"),
  "retained cache or offline prefetch metadata differs from the owner baseline");
  const checkedInspection = validateRetainedRegistryReceipt(inspection, rows, REGISTRY_CACHE);
  const checkedPrefetch = validateRetainedRegistryReceipt(prefetch, rows, prefetch.effectiveCachePath);
  validateRegistryMeta({ ...checkedPrefetch.receipt, recordsChecked: checkedPrefetch.checked.recordsChecked }, 124,
    path.join(PREFLIGHT, "cache", "hex", "cache.bin"));
  need(checkedInspection.checked.recordsChecked === 124 && checkedPrefetch.checked.recordsChecked === 124 &&
    sha(JSON.stringify(checkedPrefetch.checked.records)) === e.cachePreflight.recordsSha256 &&
    e.cachePreflight.recordsChecked === 124 && e.cachePreflight.sourceUnchanged === true &&
    e.cachePreflight.disposableCopyByteIdenticalBeforeAndAfter === true &&
    e.cachePreflight.preflightRemoved === true && e.cachePreflight.scratchRemoved === true &&
    e.cachePreflight.preflightMarkerLast === true && e.cachePreflight.scratchMarkerLast === true,
  "preallocation did not prove exact records, byte identity, or marker-last cleanup");
  verifyOwner(e.owner);
  return { status: "verified", stage: "preallocation", schema: checkedInspection.receipt.schema,
    repoUrl: checkedInspection.receipt.repoUrl, records: checkedPrefetch.checked.recordsChecked,
    candidateRootAbsent: true, preflightRootAbsent: true, scratchRootAbsent: true };
}
function terminalizeBlockedEvidence(e, { preimagePath, saveEvidence, appendTerminal, ledgerDigest }) {
  need(e.status === "blocked" && !e.allocated && !e.terminal,
    "only a fresh blocked candidate-free route can be finalized");
  need(!exists(preimagePath), "terminal finalizer preimage already exists");
  save(e, preimagePath, true);
  const preimageSha256 = digest(preimagePath);
  e.terminal = { status: "blocked", finalizedAt: now(), preimagePath: path.relative(OWNER, preimagePath), preimageSha256 };
  saveEvidence(e);
  appendTerminal({ kind: "route-terminal", status: "blocked", nonce: e.route.nonce, preimageSha256 });
  e.custody.sha256 = ledgerDigest();
  saveEvidence(e);
  return e;
}
function finalizeBlocked() {
  const e = load();
  need(e.status === "blocked" && !e.allocated, "only a blocked candidate-free route can use this finalizer");
  verifyPreallocation(e);
  if (e.terminal?.status === "blocked") return verifyTerminal(e);
  need(!custodyRows().some((row) => row.kind === "route-terminal"), "terminal finalizer was already consumed");
  const preimage = path.join(RETAINED, "terminal-preimage.json");
  terminalizeBlockedEvidence(e, {
    preimagePath: preimage, saveEvidence: (next) => save(next),
    appendTerminal: (row) => appendCustody(row), ledgerDigest: () => digest(CUSTODY),
  });
  return verifyTerminal(e);
}
function recordCandidateFreeStop() {
  need(!exists(ROUTE) && !exists(PREFLIGHT) && !exists(SCRATCH) && !exists(EVIDENCE) && !exists(CUSTODY),
    "candidate-free stop cannot claim occupied route roots or markers");
  const owner = ownerBaseline();
  const nonce = randomUUID();
  const gate = "candidate-free-fixtures-and-selftest-report";
  const firstStop = {
    gate,
    reason: "The final candidate-free fixture/selftest command yielded only the TAP header at the 10-second tool boundary. Its final reporter result was not captured; read-only process reconciliation was unavailable, so the route stopped without rerunning it or invoking cache-preflight.",
    at: now(),
    command: "node --test --test-reporter=tap --test-name-pattern='Hex 2.6.0|Hex requirement equality' 184-12-route.test.cjs && node 184-12-route.cjs selftest",
    observedOutput: "TAP version 13; no final TAP plan or selftest receipt was captured.",
    reconciliation: [
      "No 184-12 cache-preflight or candidate command was invoked.",
      "The route, preflight, and scratch roots remain absent.",
      "ps was denied by the execution environment; pgrep reported that it could not get the process list.",
    ],
  };
  appendCustody({ kind: "route", label: "route-start", status: "reserved", nonce,
    approvedPatch: PATCH_RELATIVE, source: BASE }, true);
  const stopReceipt = writeRetained("preallocation-stop.json", {
    schema: "phase184-12-preallocation-stop.v1",
    firstStop,
    cachePreflightReserved: false,
    candidateRootAbsent: true,
    preflightRootAbsent: true,
    scratchRootAbsent: true,
    cacheRead: false,
    candidateAllocation: false,
    push: false,
    dispatch: false,
    preview: false,
  });
  const evidence = {
    schema: "phase184-12-evidence.v1", root: ROUTE, status: "blocked", allocated: false, attempts: [],
    createdAt: now(), route: { nonce, branch: BRANCH, candidateRoot: ROUTE, preflightRoot: PREFLIGHT, scratchRoot: SCRATCH },
    source: { commit: BASE, tree: TREE, patchPath: PATCH_RELATIVE, patchHash: PATCH_HASH },
    planSha256: digest(PLAN),
    routeControllerSha256: digest(path.join(__dirname, "184-12-route.cjs")),
    routeTestsSha256: digest(path.join(__dirname, "184-12-route.test.cjs")),
    tddEvidenceSha256: digest(TDD_RECORD),
    firstStop,
    effectCounters: { cachePreflight: 0, candidateAllocation: 0, push: 0, dispatch: 0, preview: 0 },
    cachePreflight: { status: "blocked", attempted: false, reason: "withheld before first invocation" },
    owner,
    retained: [stopReceipt],
    custody: { path: path.relative(OWNER, CUSTODY), sha256: null },
    cleanup: {
      routeRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT), scratchRootAbsent: !exists(SCRATCH),
      preflightCreated: false, scratchCreated: false, preflightRemoved: false, scratchRemoved: false,
      ownerEqual: true, dockerMutation: false, ownedProcessesCreated: [],
    },
  };
  appendCustody({ kind: "route", label: "preallocation-result", status: "blocked", nonce });
  evidence.custody.sha256 = digest(CUSTODY);
  save(evidence, EVIDENCE, true);
  return finalizeBlocked();
}
async function captureCachePreflight() {
  need(!exists(ROUTE) && !exists(PREFLIGHT) && !exists(SCRATCH) && !exists(EVIDENCE) && !exists(CUSTODY),
    "preallocation paths or one-shot markers are occupied");
  need(exists(TDD_RECORD), "fresh fixture RED evidence is absent");
  fs.mkdirSync(RETAINED, { recursive: true, mode: 0o700 });
  fs.chmodSync(RETAINED, 0o700);
  const before = ownerBaseline();
  const nonce = randomUUID();
  appendCustody({ kind: "route", label: "route-start", status: "reserved", nonce,
    approvedPatch: PATCH_RELATIVE, source: BASE }, true);
  let gate = "approved-plan-patch-and-runtime";
  let cacheReserved = false, proof, rows, cacheSource, sourceBytes, inspect, inspected, probe, verified;
  let preflightNonce = null, scratchNonce = null;
  let preflightRemoved = false, scratchRemoved = false;
  let preflightCreated = false, scratchCreated = false;
  try {
    const plan = bytes(PLAN);
    const patch = patchCheck();
    const tddEvidence = JSON.parse(bytes(TDD_RECORD));
    need(tddEvidence.exitCode === 1 && tddEvidence.targetTest && tddEvidence.semanticAssessment?.includes("intended RED"),
      "candidate-free RED evidence is incomplete");
    const browser = installedBrowserProof();
    const tools = toolchainProof();
    const routeControllerSha256 = digest(path.join(__dirname, "184-12-route.cjs"));
    const routeTestsSha256 = digest(path.join(__dirname, "184-12-route.test.cjs"));
    assertStageAllowed({ status: "fresh", attempts: [] }, "cache-preflight");
    claimEffect("cache-preflight", nonce);
    cacheReserved = true;
    gate = "sealed-source-five-lock-archive-proof";
    proof = lockProof();
    rows = registryRows(proof);
    need(rows.length === 124 && proof.archives.size === 124 &&
      proof.final.reduce((sum, workspace) => sum + workspace.packages.length, 0) === 282,
    "exact five-lock cache record inventory changed");
    const cacheStat = fs.lstatSync(REGISTRY_CACHE);
    need(cacheStat.isFile() && !cacheStat.isSymbolicLink() && cacheStat.nlink === 1 &&
      fs.realpathSync(REGISTRY_CACHE) === REGISTRY_CACHE,
      "owner cache.bin is not a local single-link regular file");
    sourceBytes = fs.readFileSync(REGISTRY_CACHE);
    cacheSource = { path: ".hex/cache.bin", size: sourceBytes.length, sha256: sha(sourceBytes),
      mode: cacheStat.mode & 0o777, dev: cacheStat.dev, ino: cacheStat.ino, nlink: cacheStat.nlink,
      mtimeMs: cacheStat.mtimeMs };
    gate = "registry-schema-record-and-checksum-proof";
    inspect = runRegistry("inspect", REGISTRY_CACHE, rows);
    inspected = validateRegistryReceipt(inspect, rows, REGISTRY_CACHE);
    need(inspected.recordsChecked === 124, "schema-5 cache did not return exactly 124 lock records");
    const cacheAfterInspection = fs.readFileSync(REGISTRY_CACHE);
    const statAfterInspection = fs.lstatSync(REGISTRY_CACHE);
    need(cacheAfterInspection.equals(sourceBytes) && statAfterInspection.dev === cacheSource.dev &&
      statAfterInspection.ino === cacheSource.ino && statAfterInspection.nlink === 1 &&
      (statAfterInspection.mode & 0o777) === cacheSource.mode && statAfterInspection.mtimeMs === cacheSource.mtimeMs,
    "owner cache changed during read-only schema-5 inspection");

    gate = "real-offline-cache-prefetch";
    preflightNonce = randomUUID();
    scratchNonce = randomUUID();
    markRoot(PREFLIGHT, preflightNonce);
    preflightCreated = true;
    markRoot(SCRATCH, scratchNonce);
    scratchCreated = true;
    const hexHome = path.join(PREFLIGHT, "cache", "hex");
    fs.mkdirSync(hexHome, { recursive: true, mode: 0o700 });
    const scratchCache = path.join(hexHome, "cache.bin");
    fs.writeFileSync(scratchCache, sourceBytes, { flag: "wx", mode: 0o400 });
    fs.chmodSync(scratchCache, 0o400);
    const copiedStat = fs.lstatSync(scratchCache), ownerStat = fs.lstatSync(REGISTRY_CACHE);
    need(copiedStat.isFile() && copiedStat.nlink === 1 && (copiedStat.mode & 0o777) === 0o400 &&
      fs.realpathSync(scratchCache) === scratchCache && fs.readFileSync(scratchCache).equals(sourceBytes) &&
      digest(scratchCache) === cacheSource.sha256 && (copiedStat.dev !== ownerStat.dev || copiedStat.ino !== ownerStat.ino),
    "preflight cache copy is not exact and independent");
    for (const dir of ["home", "mix", "tmp", "work"]) fs.mkdirSync(path.join(SCRATCH, dir), { mode: 0o700 });
    probe = runRegistry("probe", scratchCache, rows, 60000, {
      home: path.join(SCRATCH, "home"), mixHome: path.join(SCRATCH, "mix"),
      tmpdir: path.join(SCRATCH, "tmp"), cwd: path.join(SCRATCH, "work"),
    });
    verified = validateRegistryReceipt(probe, rows, scratchCache);
    need(verified.recordsChecked === 124 && probe.effectiveCachePath === scratchCache,
      "effective offline prefetch did not read back all 124 records from its disposable cache");
    const copyAfter = fs.readFileSync(scratchCache), ownerAfter = fs.readFileSync(REGISTRY_CACHE);
    const ownerStatAfter = fs.lstatSync(REGISTRY_CACHE);
    need(copyAfter.equals(sourceBytes) && ownerAfter.equals(sourceBytes) &&
      ownerStatAfter.dev === cacheSource.dev && ownerStatAfter.ino === cacheSource.ino &&
      ownerStatAfter.nlink === 1 && (ownerStatAfter.mode & 0o777) === cacheSource.mode &&
      ownerStatAfter.mtimeMs === cacheSource.mtimeMs,
    "offline prefetch changed cache-copy bytes or the owner cache");
    const inspectReceipt = writeRetained("cache-inspection.json", {
      schema: "phase184-12-cache-inspection.v1", cache: { path: cacheSource.path, size: cacheSource.size,
        sha256: cacheSource.sha256, mode: cacheSource.mode, nlink: cacheSource.nlink },
      recordsChecked: inspected.recordsChecked, recordsSha256: sha(JSON.stringify(inspected.records)),
      receipt: retainedRegistryReceipt(inspect, inspected),
    });
    const probeReceipt = writeRetained("cache-prefetch.json", {
      schema: "phase184-12-cache-prefetch.v1", sourceCacheSha256: cacheSource.sha256,
      disposableCopySha256: digest(scratchCache), effectiveRepoUrl: probe.effectiveRepoUrl,
      effectiveCachePath: probe.effectiveCachePath, offline: probe.offline,
      recordsChecked: verified.recordsChecked, recordsSha256: sha(JSON.stringify(verified.records)),
      receipt: retainedRegistryReceipt(probe, verified),
      networkGuard: "Hex 2.6.0 offline state was asserted inside Hex.Registry.Server before open/prefetch; no network-capable resolver or package fetch was invoked.",
    });
    const removedPreflight = removeOwned(PREFLIGHT, preflightNonce);
    preflightRemoved = !exists(PREFLIGHT) && removedPreflight.at(-1) === ROOT_MARKER;
    const removedScratch = removeOwned(SCRATCH, scratchNonce);
    scratchRemoved = !exists(SCRATCH) && removedScratch.at(-1) === ROOT_MARKER;
    need(preflightRemoved && scratchRemoved, "owned preflight and scratch roots were not removed marker-last");
    verifyOwner(before);
    const lockRows = proof.cases.map(({ file, originalOid, originalHash, finalHash }) => ({ file, originalOid, originalHash, finalHash }));
    const evidence = {
      schema: "phase184-12-evidence.v1", root: ROUTE, status: "preallocation-review", allocated: false, attempts: [],
      createdAt: now(), route: { nonce, branch: BRANCH, candidateRoot: ROUTE, preflightRoot: PREFLIGHT, scratchRoot: SCRATCH },
      source: { commit: BASE, tree: TREE, patchPath: patch.path, patchHash: patch.sha256 },
      routeControllerSha256, routeTestsSha256, tddEvidenceSha256: digest(TDD_RECORD),
      planSha256: sha(plan), installedBrowser: browser, toolchain: tools,
      effectCounters: { cachePreflight: 1, candidateAllocation: 0, push: 0, dispatch: 0, preview: 0 },
      proposedGraph: { packageChanges: UPDATES, archives: proof.archives.size,
        lockManifests: proof.final.reduce((sum, workspace) => sum + workspace.packages.length, 0), locks: lockRows },
      owner: before,
      cachePreflight: { status: "passed", source: cacheSource, schema: inspect.schema, repoUrl: inspect.repoUrl,
        requiredRecords: rows.length, recordsChecked: probe.recordsChecked, requiredRecordsSha256: sha(JSON.stringify(rows)),
        lockArchiveRecords: proof.archives.size, sourceLockManifests: 282,
        offline: probe.offline, effectiveRepoUrl: probe.effectiveRepoUrl, effectiveCachePath: probe.effectiveCachePath,
        probeCacheHome: path.dirname(scratchCache), recordsSha256: sha(JSON.stringify(verified.records)),
        inspectReceiptSha256: inspect.stdoutSha256, offlinePrefetchReceiptSha256: probe.stdoutSha256,
        sourceUnchanged: true, disposableCopyByteIdenticalBeforeAndAfter: true,
        retained: [inspectReceipt, probeReceipt], preflightRemoved, scratchRemoved,
        preflightMarkerLast: removedPreflight.at(-1) === ROOT_MARKER, scratchMarkerLast: removedScratch.at(-1) === ROOT_MARKER },
      custody: { path: path.relative(OWNER, CUSTODY), cachePreflightReserved: true,
        cachePreflightStatus: "passed", sha256: digest(CUSTODY) },
      cleanup: { routeRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT), scratchRootAbsent: !exists(SCRATCH),
        allocatedResources: [], removedResources: [PREFLIGHT, SCRATCH], retainedResources: [CUSTODY] },
    };
    finishEffect("cache-preflight", nonce, "passed", { records: 124, cacheSha256: cacheSource.sha256,
      disposableCopySha256: digest(scratchCache) });
    appendCustody({ kind: "route", label: "preallocation-result", status: "passed", nonce });
    evidence.custody.sha256 = digest(CUSTODY);
    save(evidence, EVIDENCE, true);
    verifyOwner(evidence.owner);
    return { status: "passed", written: path.basename(EVIDENCE), schema: inspect.schema, repoUrl: inspect.repoUrl,
      requiredRecords: rows.length, prefetchRecords: probe.recordsChecked, candidateRootAbsent: !exists(ROUTE),
      preflightRootAbsent: !exists(PREFLIGHT), scratchRootAbsent: !exists(SCRATCH), ownerUnchanged: true };
  } catch (error) {
    let cleanupError = null;
    try {
      if (preflightNonce && exists(PREFLIGHT)) {
        const removed = removeOwned(PREFLIGHT, preflightNonce);
        preflightRemoved = !exists(PREFLIGHT) && removed.at(-1) === ROOT_MARKER;
      }
    }
    catch (cleanup) { cleanupError = sanitize(cleanup.message); }
    try {
      if (scratchNonce && exists(SCRATCH)) {
        const removed = removeOwned(SCRATCH, scratchNonce);
        scratchRemoved = !exists(SCRATCH) && removed.at(-1) === ROOT_MARKER;
      }
    }
    catch (cleanup) { cleanupError = [cleanupError, sanitize(cleanup.message)].filter(Boolean).join("; "); }
    const ownerEqual = (() => { try { verifyOwner(before); return true; } catch (_) { return false; } })();
    const firstStop = { gate, reason: sanitize(error.message).slice(0, 1000), at: now() };
    if (cacheReserved) {
      const ledger = custodyRows();
      if (!ledger.some((row) => row.kind === "effect-result" && row.label === "cache-preflight")) {
        finishEffect("cache-preflight", nonce, "blocked", { gate, reason: firstStop.reason });
      }
    }
    const stopReceipt = writeRetained("preallocation-stop.json", {
      schema: "phase184-12-preallocation-stop.v1", firstStop, cachePreflightReserved: cacheReserved,
      candidateRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT), scratchRootAbsent: !exists(SCRATCH),
    });
    const evidence = {
      schema: "phase184-12-evidence.v1", root: ROUTE, status: "blocked", allocated: false, attempts: [],
      createdAt: now(), route: { nonce, branch: BRANCH, candidateRoot: ROUTE, preflightRoot: PREFLIGHT, scratchRoot: SCRATCH },
      source: { commit: BASE, tree: TREE, patchPath: PATCH_RELATIVE, patchHash: PATCH_HASH },
      planSha256: exists(PLAN) ? digest(PLAN) : null,
      firstStop, effectCounters: { cachePreflight: cacheReserved ? 1 : 0, candidateAllocation: 0, push: 0, dispatch: 0, preview: 0 },
      cachePreflight: { status: "blocked", source: cacheSource || null, schema: inspect?.schema ?? null,
        repoUrl: inspect?.repoUrl ?? null, recordsExpected: rows?.length ?? null,
        recordsObserved: inspected?.recordsChecked ?? probe?.recordsChecked ?? null,
        inspectionReceiptSha256: inspect?.stdoutSha256 ?? null,
        offlinePrefetchReceiptSha256: probe?.stdoutSha256 ?? null },
      owner: before, retained: [stopReceipt], custody: { path: path.relative(OWNER, CUSTODY), sha256: digest(CUSTODY) },
      cleanup: { routeRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT),
        scratchRootAbsent: !exists(SCRATCH), preflightCreated, scratchCreated, preflightRemoved, scratchRemoved,
        preflightCleanupError: cleanupError, ownerEqual },
    };
    appendCustody({ kind: "route", label: "preallocation-result", status: "blocked", nonce });
    evidence.custody.sha256 = digest(CUSTODY);
    save(evidence, EVIDENCE, true);
    return { status: "blocked", written: path.basename(EVIDENCE), firstStop: evidence.firstStop,
      candidateRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT),
      scratchRootAbsent: !exists(SCRATCH), ownerUnchanged: ownerEqual };
  }
}
async function cli(argv) {
  const [name, stageName] = argv;
  if (name === "selftest" && argv.length === 1) return selftest();
  if (name === "record-stop" && argv.length === 1) return recordCandidateFreeStop();
  if (name === "cache-preflight" && argv.length === 1) return captureCachePreflight();
  if (name === "start-local" && argv.length === 1) return startLocal();
  if (name === "finalize-blocked" && argv.length === 1) return finalizeBlocked();
  if (name === "verify-stage" && stageName === "terminal" && argv.length === 2) return verifyTerminal();
  if (name === "verify-stage" && stageName === "preallocation" && argv.length === 2) {
    return verifyPreallocation(load());
  }
  if (name === "verify-stage" && ["dependency", "local"].includes(stageName) && argv.length === 2) {
    const e = load();
    if (e.status === "blocked") return verifyTerminal(e);
    authorizeRoot(ROUTE, e.nonce);
    need(e.snapshot && e.productionAdvisories?.findings === 0 &&
      e.attempts.find((row) => row.label === "idna-compatibility")?.status === 0, "dependency stage evidence incomplete");
    verifyCanonical(e);
    if (stageName === "local") need(e.status === "local-passed" && e.docs?.value?.stagedTree === e.candidate.stagedTree,
      "same-output browser evidence is incomplete");
    return { status: "verified", stage: stageName };
  }
  throw new Error("usage: 184-12-route.cjs selftest|cache-preflight|start-local|finalize-blocked|verify-stage preallocation|dependency|local|terminal");
}
if (require.main === module) {
  cli(process.argv.slice(2)).then((result) => console.log(JSON.stringify(result))).catch((error) => {
    console.error(sanitize(error.message));
    process.exitCode = 1;
  });
}

module.exports = {
  APPROVED_PATCH_RELATIVE: PATCH_RELATIVE,
  APPROVED_PATCH_SHA256: PATCH_HASH,
  OWNER,
  checksumObservedHex,
  normalizeRequirementTerms,
  compareRegistryRequirementsFixture,
  resolveApprovedPatch,
  resolvePatchAtRoot,
  validateRegistryReceipt,
  validateRetainedRegistryReceipt,
  validateTerminalCustody,
  terminalizeBlockedEvidence,
  assertStageAllowed,
  parseLock,
  refreshLock,
  verifyLockDelta,
  patchCheck,
  testedCommands,
  makeBuildView,
  markRoot,
  removeOwned,
  lockProof,
  advisoryProof,
};
