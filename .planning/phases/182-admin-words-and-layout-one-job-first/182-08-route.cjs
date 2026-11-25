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
const ROUTE = "/private/tmp/mailglass-v211-phase182-08";
const PREFLIGHT = "/private/tmp/mailglass-v211-phase182-08-preflight";
const SOURCE = path.join(ROUTE, "source");
const ROOT_MARKER = ".route-owner.json";
const EVIDENCE = path.join(__dirname, "182-08-EVIDENCE.json");
const PLAN = path.join(__dirname, "182-08-PLAN.md");
const PATCH = path.join(__dirname, "184-07-CANDIDATE.patch");
const PATCH_HASH = "b2c7c557cd21d1c5a82633a94e081005f68bd70412f4f3e3e145d02525206907";
const BASE = "a295e9a950e14d7ce3ec9456f31fbda864933580";
const TREE = "55274beccd045fff361aead1732b14e5e00d587f";
const REMOTE = "https://github.com/szTheory/mailglass.git";
const REPOSITORY = "szTheory/mailglass";
const BASE_REF = "refs/heads/gsd/v2.11-phase182-admin-evidence";
const BRANCH = "gsd/v2.11-phase182-08-evidence";
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
function controllerSeal() {
  const source = bytes(__filename).toString("utf8");
  const start = "// BEGIN 182-08 sealed registry comparator.";
  const end = "// END 182-08 sealed registry comparator";
  const registryRowsStart = source.indexOf("function registryRows(proof)");
  const first = source.indexOf(start, registryRowsStart), last = source.indexOf(end, first + start.length);
  need(registryRowsStart >= 0 && first >= 0 && last > first && source.indexOf(start, first + start.length) < 0 &&
    source.indexOf(end, last + end.length) < 0, "sealed registry comparator boundary is missing or duplicated");
  return { sha256: sha(source), registrySectionSha256: sha(source.slice(first, last + end.length)) };
}
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
function load() {
  const e = JSON.parse(bytes(EVIDENCE));
  need(e.schema === "phase182-08-evidence.v1" && e.root === ROUTE, "invalid route evidence identity");
  return e;
}
function patchCheck() {
  const raw = bytes(PATCH);
  need(sha(raw) === PATCH_HASH, "retained patch checksum mismatch");
  const entries = [...raw.toString().matchAll(/^diff --git a\/(\S+) b\/(\S+)$/gm)];
  need(entries.every((match) => match[1] === match[2]), "unexpected renamed patch entry");
  assert.deepEqual(sorted(entries.map((match) => match[2])), sorted([...PATCH_SELECTION, ...PATCH_EXCLUSIONS]));
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
  // Reuse the compatible Hex 2.6.0 codec source, never its previous route output.
  const helper = path.join(__dirname, "184-07-deps-prep.exs");
  const result = success(path.join(ELIXIR_BIN, "elixir"), ["-pa", HEX_EBIN, helper, command, HEX_EBIN], {
    cwd, input: JSON.stringify(input),
    env: { PATH: `${OTP_BIN}:/usr/bin:/bin`, LANG: "C", LC_ALL: "C", HEX_OFFLINE: "1", ERL_FLAGS: "+S 2:2 +A 1" },
    timeout: 45000,
  });
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
      dependencies: dependencies.join(";") };
    need(/^[a-f0-9]{64}$/.test(row.inner) && /^[a-f0-9]{64}$/.test(row.outer),
      `non-canonical lock checksum: ${key}`);
    if (rows.has(key)) need(equal(rows.get(key), row), `lock metadata disagrees across workspaces: ${key}`);
    else rows.set(key, row);
  }
  return [...rows.values()].sort((a, b) => `${a.name}@${a.version}`.localeCompare(`${b.name}@${b.version}`));
}
// BEGIN 182-08 sealed registry comparator. This is shared by fixtures and the pinned Hex path.
const REGISTRY_SCRIPT = String.raw`
defmodule Phase182RegistryProbe do
  def need(true, _), do: :ok
  def need(false, message), do: raise(ArgumentError, message)
  def decode_dependencies(""), do: []
  def decode_dependencies(encoded) do
    encoded |> String.split(";", trim: true) |> Enum.map(fn row ->
      [repo, package, app, requirement, optional] = row |> String.split(",") |> Enum.map(&Base.decode64!/1)
      {repo, package, app, requirement, optional == "true"}
    end) |> Enum.sort()
  end
  def lock_checksum!(value, label, package, version) do
    need(is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value),
      "invalid canonical lock #{label} checksum #{package}@#{version}: expected lowercase-hex-64")
    Base.decode16!(value, case: :lower)
  end
  def checksum!(tid, key, expected, label, package, version) do
    entries = :ets.lookup(tid, key)
    values = Enum.map(entries, fn {_key, value} -> value end)
    observed = case values do
      [value] when is_binary(value) and byte_size(value) == 32 -> Base.encode16(value, case: :lower)
      [value] when is_binary(value) and byte_size(value) == 64 ->
        if Regex.match?(~r/\A[0-9A-Fa-f]{64}\z/, value), do: "ascii-hex-value-length-64", else: "binary-value-length-64"
      [value] when is_binary(value) -> "binary-value-length-#{byte_size(value)}"
      [value] -> "#{inspect(value)}"
      [] -> "missing"
      _ -> "duplicate-entry-count-#{length(values)}"
    end
    expected_hex = Base.encode16(expected, case: :lower)
    need(length(values) == 1 and is_binary(hd(values)) and byte_size(hd(values)) == 32 and observed == expected_hex,
      "#{label} checksum mismatch #{package}@#{version}: expected=#{expected_hex} observed=#{observed} entries=#{length(values)}")
    observed
  end
  def one_value!(tid, key, label, package, version) do
    case :ets.lookup(tid, key) do
      [{^key, value}] -> value
      [] -> raise ArgumentError, "missing #{label} entry #{package}@#{version}"
      entries -> raise ArgumentError, "duplicate #{label} entries #{package}@#{version}: count=#{length(entries)}"
    end
  end
  def verify(tid, records, expected_url) do
    need(one_value!(tid, :version, "registry schema", "registry", "") == 5, "registry schema is not 5")
    need(one_value!(tid, {:repo, "hexpm"}, "repo URL", "registry", "") == expected_url,
      "cached repo URL mismatch: expected=#{expected_url}")
    Enum.map(records, fn record ->
      [package, version, inner_hex, outer_hex, dependencies] = String.split(record, "|", parts: 5)
      inner = lock_checksum!(inner_hex, "inner", package, version)
      outer = lock_checksum!(outer_hex, "outer", package, version)
      versions = one_value!(tid, {:versions, "hexpm", package}, "version list", package, version)
      need(is_list(versions) and version in versions, "missing release version #{package}@#{version}")
      observed_inner = checksum!(tid, {:inner_checksum, "hexpm", package, version}, inner,
        "inner", package, version)
      observed_outer = checksum!(tid, {:outer_checksum, "hexpm", package, version}, outer,
        "outer", package, version)
      actual = one_value!(tid, {:deps, "hexpm", package, version}, "dependency metadata", package, version)
        |> Enum.sort()
      expected = decode_dependencies(dependencies)
      need(actual == expected,
        "dependency metadata mismatch #{package}@#{version}: expected_count=#{length(expected)} observed_count=#{length(actual)}")
      encoded_actual = actual |> Enum.map(fn {repo, name, app, requirement, optional} ->
        [repo, name, app, requirement, to_string(optional)] |> Enum.map(&Base.encode64/1) |> Enum.join(",")
      end) |> Enum.sort() |> Enum.join(";")
      %{name: package, version: version, inner: observed_inner, outer: observed_outer, dependencies: encoded_actual}
    end)
  end
  def fixture_table(scenario, records) do
    tid = :ets.new(:phase182_fixture, [:bag, :public])
    schema = if scenario == "schema3", do: 3, else: 5
    repo = if scenario == "repo_mismatch", do: "https://wrong.invalid", else: "https://repo.hex.pm"
    :ets.insert(tid, {:version, schema})
    :ets.insert(tid, {{:repo, "hexpm"}, repo})
    Enum.each(records, fn record ->
      [package, version, inner, outer, dependencies] = String.split(record, "|", parts: 5)
      unless scenario == "missing_version" do
        :ets.insert(tid, {{:versions, "hexpm", package}, [version]})
      end
      Enum.each([{:inner_checksum, inner}, {:outer_checksum, outer}], fn {kind, hex} ->
        key = {kind, "hexpm", package, version}
        cond do
          scenario == "missing_#{kind}" -> :ok
          scenario == "duplicate_#{kind}" ->
            seed = if scenario == "invalid_lock_inner" and kind == :inner_checksum, do: String.duplicate("a", 64), else: hex
            raw = Base.decode16!(seed, case: :lower)
            :ets.insert(tid, {key, raw})
            :ets.insert(tid, {key, <<(:erlang.bxor(:binary.at(raw, 0), 1)), binary_part(raw, 1, 31)::binary>>})
          scenario == "ascii_#{kind}" ->
            seed = if scenario == "invalid_lock_inner" and kind == :inner_checksum, do: String.duplicate("a", 64), else: hex
            :ets.insert(tid, {key, seed})
          scenario == "short_#{kind}" ->
            seed = if scenario == "invalid_lock_inner" and kind == :inner_checksum, do: String.duplicate("a", 64), else: hex
            :ets.insert(tid, {key, binary_part(Base.decode16!(seed, case: :lower), 0, 31)})
          scenario == "mutate_#{kind}" ->
            seed = if scenario == "invalid_lock_inner" and kind == :inner_checksum, do: String.duplicate("a", 64), else: hex
            raw = Base.decode16!(seed, case: :lower)
            <<first, rest::binary>> = raw
            :ets.insert(tid, {key, <<(:erlang.bxor(first, 1)), rest::binary>>})
          true ->
            seed = if scenario == "invalid_lock_inner" and kind == :inner_checksum, do: String.duplicate("a", 64), else: hex
            :ets.insert(tid, {key, Base.decode16!(seed, case: :lower)})
        end
      end)
      unless scenario == "missing_deps" do
        deps = decode_dependencies(dependencies)
        altered = if scenario == "wrong_dependencies" do
          [{"hexpm", "different", "different", "~> 0", false}]
        else
          deps
        end
        :ets.insert(tid, {{:deps, "hexpm", package, version}, altered})
      end
    end)
    tid
  end
  def main do
    [mode, cache_path, expected_url, scenario | encoded] = System.argv()
    records = Enum.map(encoded, fn row ->
      [package, version, inner, outer, dependencies] = String.split(row, "|", parts: 5)
      Enum.join([package, version, inner, outer, dependencies], "|")
    end)
    try do
      tid = case mode do
        "inspect" ->
          {:ok, table} = Hex.Registry.Server.read_cache(cache_path)
          table
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
          state.ets
        "fixture" -> fixture_table(scenario, records)
        other -> raise ArgumentError, "unsupported registry probe mode #{other}"
      end
      checked = verify(tid, records, expected_url)
      schema = one_value!(tid, :version, "registry schema", "registry", "")
      repo = one_value!(tid, {:repo, "hexpm"}, "repo URL", "registry", "")
      IO.puts(["META", to_string(schema), Base.encode64(repo), Integer.to_string(length(records))] |> Enum.join("\t"))
      Enum.each(checked, fn row -> IO.puts(["REC", row.name, row.version, row.inner, row.outer, row.dependencies] |> Enum.join("\t")) end)
      IO.puts("PASS")
    rescue
      error ->
        IO.puts(["FAIL", Base.encode64(Exception.message(error))] |> Enum.join("\t"))
    end
  end
end
Phase182RegistryProbe.main()
`;
function runRegistry(mode, cachePath, rows, timeout = 60000, scenario = "none") {
  const encodedRows = rows.map((row) => [row.name, row.version, row.inner, row.outer, row.dependencies].join("|"));
  const argv = ["-pa", HEX_EBIN, "-e", REGISTRY_SCRIPT, "--", mode, cachePath,
    "https://repo.hex.pm", scenario, ...encodedRows];
  const env = { PATH: `${ELIXIR_BIN}:${OTP_BIN}:/usr/bin:/bin`, HOME: os.homedir(), MIX_HOME,
    HEX_HOME: path.dirname(cachePath), HEX_OFFLINE: "1", ASDF_ELIXIR_VERSION: "1.18.4-otp-27",
    ASDF_ERLANG_VERSION: "27.3.4.13", ERL_FLAGS: "+S 2:2 +A 1", LANG: "C", LC_ALL: "C" };
  const result = processCommand(path.join(ELIXIR_BIN, "elixir"), argv, { cwd: OWNER, env, timeout });
  need(result.status === 0 && !result.error,
    `Hex ${mode} process failed (${result.error ?? result.status}): ${sanitize(result.stderr).slice(0, 512)}`);
  const lines = result.stdout.toString("utf8").trim().split("\n");
  const failed = lines.find((line) => line.startsWith("FAIL\t"));
  if (failed) return { ok: false, mode, failure: Buffer.from(failed.split("\t")[1], "base64").toString("utf8"),
    stdoutSha256: sha(result.stdout), stderrSha256: sha(result.stderr) };
  const meta = lines.find((line) => line.startsWith("META\t"));
  need(meta && lines.at(-1) === "PASS", `Hex ${mode} returned no complete record receipt`);
  const [, schema, repo64, count] = meta.split("\t");
  return { ok: true, schema: Number(schema), repoUrl: Buffer.from(repo64, "base64").toString("utf8"),
    recordsChecked: Number(count), records: lines.filter((line) => line.startsWith("REC\t")).map((line) => {
      const [, name, version, inner, outer, dependencies] = line.split("\t");
      return { name, version, inner, outer, dependencies };
    }), mode, stdoutSha256: sha(result.stdout), stderrSha256: sha(result.stderr) };
}
function validateRegistryMeta(meta, expectedCount) {
  need(meta?.ok !== false, `Hex registry comparator rejected cache: ${meta?.failure ?? "unknown failure"}`);
  need(meta.schema === 5, "registry schema must be 5");
  need(meta.repoUrl === "https://repo.hex.pm", "registry repo URL is not the effective candidate URL");
  need(meta.recordsChecked === expectedCount, "registry record count differs from the five lock graphs");
  return true;
}
function validateRegistryReceipt(meta, expectedRows) {
  validateRegistryMeta(meta, expectedRows.length);
  need(equal(meta.records, expectedRows.map(({ name, version, inner, outer, dependencies }) =>
    ({ name, version, inner, outer, dependencies }))), "registry record/checksum/dependency receipt differs from lock graph");
  return true;
}
function validateCacheCopy({ sourceBefore, sourceAfter, destination, sourceIdentity, destinationIdentity }) {
  need(sourceBefore === sourceAfter, "owner cache drifted while the destination copy was made");
  need(destination === sourceBefore, "destination cache bytes differ from the authenticated source");
  need(sourceIdentity.dev !== destinationIdentity.dev || sourceIdentity.ino !== destinationIdentity.ino,
    "destination cache shares the owner cache inode");
  return true;
}

const STAGE_PRECONDITIONS = {
  preallocation: [], local: ["preallocation"], hosted: ["local"], cost: ["hosted"],
  preview: ["hosted", "cost"], review: ["preview"], terminal: [],
};
function reserveEffectMarker(evidence, label) {
  need(evidence && Array.isArray(evidence.attempts), "effect ledger is missing");
  need(!evidence.attempts.some((attempt) => attempt.label === label), `effect marker already exists: ${label}`);
  const marker = { label, reservedAt: now(), count: evidence.attempts.length + 1 };
  evidence.attempts.push(marker);
  return marker;
}
function selectStage(evidence, stage, transport = (selection) => ({ ...selection, status: "passed",
  receiptSha256: sha(JSON.stringify(selection)) })) {
  need(Object.hasOwn(STAGE_PRECONDITIONS, stage), `unknown stage selector: ${stage}`);
  need(evidence?.schema === "phase182-08-evidence.v1" && evidence.plan === "182-08" &&
    evidence.source?.commit === BASE && evidence.source?.tree === TREE && evidence.branch === BRANCH,
  "stage evidence identity differs from the approved plan, branch, or source tree");
  const receipts = evidence.stageReceipts || {};
  if (stage !== "preallocation" && stage !== "terminal") {
    for (const required of STAGE_PRECONDITIONS[stage]) {
      const receipt = receipts[required];
      need(receipt?.status === "passed" && receipt.stage === required && receipt.plan === "182-08" &&
        receipt.sourceTree === TREE && /^[a-f0-9]{64}$/.test(receipt.receiptSha256 || ""),
      `stage ${stage} lacks an authenticated ${required} receipt`);
    }
  }
  if (stage === "preview") need(evidence.cost?.status === "passed" &&
    evidence.cost?.candidateSha === evidence.candidate?.sha && /^[a-f0-9]{64}$/.test(evidence.cost?.receiptSha256 || ""),
  "preview requires passing formal cost evidence for the exact candidate");
  const selection = { stage, plan: "182-08", sourceTree: TREE, candidateSha: evidence.candidate?.sha || null };
  const receipt = transport(selection);
  need(receipt && receipt.stage === stage && receipt.plan === "182-08" && receipt.sourceTree === TREE &&
    receipt.status === "passed" && /^[a-f0-9]{64}$/.test(receipt.receiptSha256 || ""),
  `transport returned an unauthenticated ${stage} receipt`);
  return receipt;
}
// END 182-08 sealed registry comparator
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
  path.relative(OWNER, path.join(__dirname, "184-09-SUMMARY.md")),
  path.relative(OWNER, PLAN), path.relative(OWNER, path.join(__dirname, "182-08-route.cjs")),
  path.relative(OWNER, EVIDENCE), path.relative(OWNER, path.join(__dirname, "182-08-SUMMARY.md")),
];
const MUTABLE = new Set([...REPORTS, path.relative(OWNER, EVIDENCE)]);
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
  const index = gitText(["rev-parse", "--git-path", "index"]);
  const rows = fileManifestNames().filter((name) => !MUTABLE.has(name)).map(pathState);
  const porcelain = git(["status", "--porcelain=v2", "-z", "--untracked-files=all"]);
  return {
    head: gitText(["rev-parse", "HEAD"]), index: digest(path.resolve(OWNER, index)),
    worktrees: sha(git(["worktree", "list", "--porcelain"])), porcelain: sha(porcelain),
    indexDiff: sha(git(["diff", "--no-ext-diff", "--cached", "--binary"])),
    worktreeDiff: sha(git(["diff", "--no-ext-diff", "--binary", "--", ".", ...REPORTS.map((file) => `:(exclude)${file}`)])),
    workInProgress: rows, protected: sorted(protectedNames).map(pathState),
    reportPreimages: REPORTS.map(pathState), toolchain: sha(JSON.stringify(inventory(MIX_HOME))),
  };
}
function verifyOwner(before) {
  const after = ownerBaseline();
  for (const field of ["head", "index", "worktrees", "indexDiff", "worktreeDiff", "workInProgress", "protected", "toolchain"])
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
  edit("test/scripts/phase182_07_runtime_contract.test.cjs", (input) => input
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
  schema: "phase182-08-docs-compile-view.v1", workspace: path.basename(input),
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
      "const record={schema:'phase182-07-docs-browser-runtime.v1',candidate,sourceFingerprint",
      "const stagedTree=execFileSync('git',['-C',root,'write-tree'],{encoding:'utf8'}).trim();\nif(stagedTree!==process.env.MAILGLASS_DOCS_STAGED_TREE)throw new Error('staged candidate tree drift');\nconst record={schema:'phase182-08-docs-browser-runtime.v1',candidate,stagedTree,sourceFingerprint");
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
  stage(e, "runtime-contracts", "node", ["--test", "test/scripts/phase182_07_runtime_contract.test.cjs",
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
  const label = `phase182-08-${e.nonce}`;
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
  need(receipt.schema === "phase182-08-docs-browser-runtime.v1" && receipt.candidate === BASE &&
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
    !e.allocated && !exists(ROUTE) && !exists(PREFLIGHT), "cache preflight receipt is not current and passing");
  validateRegistryMeta(e.cachePreflight, 124);
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
  const seal = controllerSeal();
  assert.match(seal.sha256, /^[a-f0-9]{64}$/);
  assert.match(seal.registrySectionSha256, /^[a-f0-9]{64}$/);
  assert.notEqual(seal.sha256, seal.registrySectionSha256);
  const root = fs.mkdtempSync("/private/tmp/mailglass-phase182-08-fixture-");
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
    assert.throws(() => validateCacheCopy({ sourceBefore: "a", sourceAfter: "b", destination: "a",
      sourceIdentity: { dev: 1, ino: 1 }, destinationIdentity: { dev: 2, ino: 2 } }), /cache drifted/);
    assert.throws(() => validateCacheCopy({ sourceBefore: "a", sourceAfter: "a", destination: "b",
      sourceIdentity: { dev: 1, ino: 1 }, destinationIdentity: { dev: 2, ino: 2 } }), /destination cache bytes/);
    assert.throws(() => validateCacheCopy({ sourceBefore: "a", sourceAfter: "a", destination: "a",
      sourceIdentity: { dev: 1, ino: 1 }, destinationIdentity: { dev: 1, ino: 1 } }), /shares the owner cache inode/);
    assert.equal(validateCacheCopy({ sourceBefore: "a", sourceAfter: "a", destination: "a",
      sourceIdentity: { dev: 1, ino: 1 }, destinationIdentity: { dev: 2, ino: 2 } }), true);
    const registryFixture = { name: "alpha", version: "1.0.0", inner: "a".repeat(64),
      outer: "b".repeat(64), dependencies: "" };
    const registryPass = runRegistry("fixture", "fixture-cache", [registryFixture], 60000, "valid");
    assert.equal(validateRegistryReceipt(registryPass, [registryFixture]), true);
    for (const scenario of ["mutate_inner_checksum", "mutate_outer_checksum", "missing_inner_checksum",
      "missing_outer_checksum", "duplicate_inner_checksum", "duplicate_outer_checksum", "ascii_inner_checksum",
      "ascii_outer_checksum", "short_inner_checksum", "short_outer_checksum", "missing_version",
      "missing_deps", "wrong_dependencies", "schema3", "repo_mismatch", "invalid_lock_inner"]) {
      const invalidRow = scenario === "invalid_lock_inner" ? { ...registryFixture, inner: "A".repeat(64) } : registryFixture;
      const invalid = runRegistry("fixture", "fixture-cache", [invalidRow], 60000, scenario);
      assert.equal(invalid.ok, false, `registry fixture ${scenario} was incorrectly accepted`);
      assert(invalid.failure.length > 0, `registry fixture ${scenario} did not retain a failure reason`);
    }
    const mutatedInner = runRegistry("fixture", "fixture-cache", [registryFixture], 60000, "mutate_inner_checksum");
    assert.match(mutatedInner.failure, /expected=[a-f0-9]{64} observed=[a-f0-9]{64}/);
    const asciiHex = runRegistry("fixture", "fixture-cache", [registryFixture], 60000, "ascii_inner_checksum");
    assert.match(asciiHex.failure, /observed=ascii-hex-value-length-64/);
    assert.throws(() => validateRegistryReceipt({ ...registryPass, recordsChecked: 2,
      records: [...registryPass.records, { ...registryFixture, name: "extra" }] }, [registryFixture]), /record count/);
    assert.throws(() => validateRegistryReceipt({ ...registryPass, records: [] }, [registryFixture]), /record\/checksum\/dependency/);
    const baseStageEvidence = {
      schema: "phase182-08-evidence.v1", plan: "182-08", branch: BRANCH,
      source: { commit: BASE, tree: TREE }, candidate: { sha: "c".repeat(40) }, attempts: [],
      stageReceipts: Object.fromEntries(["preallocation", "local", "hosted", "cost", "preview"].map((stage) =>
        [stage, { stage, status: "passed", plan: "182-08", sourceTree: TREE, receiptSha256: "d".repeat(64) }])),
      cost: { status: "passed", candidateSha: "c".repeat(40), receiptSha256: "e".repeat(64) },
    };
    for (const stage of ["preallocation", "local", "hosted", "cost", "preview", "review", "terminal"]) {
      assert.equal(selectStage(baseStageEvidence, stage).stage, stage);
    }
    assert.throws(() => selectStage({ ...baseStageEvidence, branch: "wrong" }, "local"), /identity differs/);
    assert.throws(() => selectStage({ ...baseStageEvidence, source: { commit: BASE, tree: "f".repeat(40) } }, "local"), /identity differs/);
    assert.throws(() => selectStage({ ...baseStageEvidence,
      stageReceipts: { ...baseStageEvidence.stageReceipts, local: undefined } }, "hosted"), /lacks an authenticated local/);
    assert.throws(() => selectStage(baseStageEvidence, "review", () => ({ stage: "review", plan: "182-08",
      sourceTree: TREE, status: "passed" })), /unauthenticated review receipt/);
    const marked = { attempts: [] };
    reserveEffectMarker(marked, "dispatch");
    assert.throws(() => reserveEffectMarker(marked, "dispatch"), /already exists/);
    assert.equal(marked.attempts.length, 1);
    const command = testedCommands();
    assert.deepEqual(command.resolve, ["mix", "deps.get", "--check-locked"]);
    assert(command.browserContainer.includes("--pull=never") && command.browserContainer.includes("--network=none"));
    assert(command.dispatch.includes(BRANCH) && command.dispatch.includes(WORKFLOW));
    const validMeta = { schema: 5, repoUrl: "https://repo.hex.pm", recordsChecked: 2 };
    assert.equal(validateRegistryMeta(validMeta, 2), true);
    assert.throws(() => validateRegistryMeta({ ...validMeta, schema: 3 }, 2), /schema/);
    assert.throws(() => validateRegistryMeta({ ...validMeta, repoUrl: "https://wrong.invalid" }, 2), /repo URL/);
    assert.throws(() => validateRegistryMeta({ ...validMeta, recordsChecked: 1 }, 2), /record count/);
    const receiptRows = [
      { name: "alpha", version: "1.0.0", inner: "a".repeat(64), outer: "b".repeat(64), dependencies: "" },
      { name: "beta", version: "2.0.0", inner: "c".repeat(64), outer: "d".repeat(64), dependencies: "dep" },
    ];
    assert.equal(validateRegistryReceipt({ ...validMeta, records: receiptRows }, receiptRows), true);
    assert.throws(() => validateRegistryReceipt({ ...validMeta, recordsChecked: 1, records: receiptRows.slice(1) }, receiptRows), /record count/);
    assert.throws(() => validateRegistryReceipt({ ...validMeta, records: receiptRows.map((row) =>
      row.name === "alpha" ? { ...row, outer: "e".repeat(64) } : row) }, receiptRows), /checksum\/dependency/);
    assert.throws(() => validateRegistryReceipt({ ...validMeta, records: receiptRows.map((row) =>
      row.name === "beta" ? { ...row, dependencies: "wrong" } : row) }, receiptRows), /checksum\/dependency/);
    return { status: "passed", candidateRootAbsent: !exists(ROUTE), writableLeexFixture: true,
      archiveTamperRejected: true, lockScopeEnforced: true, injectedExit: abort.status, markerLast: true,
      cacheSchemaAndRepoFailClosed: true, rawChecksumFixtures: 17, recordAndChecksumMismatchRejected: true,
      copyDriftRejected: true, stageSelectors: 7, duplicateEffectMarkersRejected: true, routesExecuted: 0 };
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
  need(!exists(PREFLIGHT) && e.cleanup?.preflightRootAbsent === true, "preflight scratch cleanup is not proven");
  verifyOwner(e.owner);
  return { status: "verified", disposition: "blocked", routeRootAbsent: true, attempts: e.attempts.length };
}
async function captureCachePreflight() {
  need(!exists(ROUTE) && !exists(PREFLIGHT) && !exists(EVIDENCE), "preallocation paths are occupied");
  const before = ownerBaseline();
  let gate = "lock-and-archive-proof", proof, rows, cacheSource, inspect, advisories, probe;
  let cacheFailure = null, controller;
  let scratchNonce = null, scratchRemoved = false;
  try {
    const plan = bytes(PLAN);
    controller = controllerSeal();
    patchCheck();
    proof = lockProof();
    rows = registryRows(proof);
    need(rows.length === 124 && proof.archives.size === 124 &&
      proof.final.reduce((sum, workspace) => sum + workspace.packages.length, 0) === 282,
    "exact five-lock cache record inventory changed");
    const cacheStat = fs.lstatSync(REGISTRY_CACHE);
    need(cacheStat.isFile() && cacheStat.nlink === 1 && fs.realpathSync(REGISTRY_CACHE) === REGISTRY_CACHE,
      "owner cache.bin is not a local single-link regular file");
    cacheSource = { path: ".hex/cache.bin", size: cacheStat.size, sha256: digest(REGISTRY_CACHE), mode: cacheStat.mode & 0o777 };
    gate = "registry-schema-record-and-checksum-proof";
    inspect = runRegistry("inspect", REGISTRY_CACHE, rows);
    try { validateRegistryReceipt(inspect, rows); }
    catch (error) {
      cacheFailure = { phase: "owner-cache-records", reason: sanitize(error.message).slice(0, 1000),
        normalizedComparatorResult: inspect.failure || null, receiptSha256: inspect.stdoutSha256 || null };
      throw error;
    }
    advisories = await advisoryProof(proof);
    gate = "real-offline-cache-prefetch";
    scratchNonce = randomUUID();
    markRoot(PREFLIGHT, scratchNonce);
    const hexHome = path.join(PREFLIGHT, "cache", "hex");
    fs.mkdirSync(hexHome, { recursive: true, mode: 0o700 });
    const scratchCache = path.join(hexHome, "cache.bin");
    const sourceBefore = digest(REGISTRY_CACHE);
    const sourceIdentity = fs.lstatSync(REGISTRY_CACHE);
    fs.copyFileSync(REGISTRY_CACHE, scratchCache, fs.constants.COPYFILE_EXCL);
    fs.chmodSync(scratchCache, 0o400);
    const copiedStat = fs.lstatSync(scratchCache);
    validateCacheCopy({ sourceBefore, sourceAfter: digest(REGISTRY_CACHE), destination: digest(scratchCache),
      sourceIdentity, destinationIdentity: copiedStat });
    probe = runRegistry("probe", scratchCache, rows);
    validateRegistryReceipt(probe, rows);
    need(digest(scratchCache) === cacheSource.sha256 && digest(REGISTRY_CACHE) === cacheSource.sha256,
      "offline prefetch changed source or scratch cache bytes");
    const removed = removeOwned(PREFLIGHT, scratchNonce);
    scratchRemoved = !exists(PREFLIGHT) && removed.at(-1) === ROOT_MARKER;
    need(scratchRemoved, "cache preflight scratch cleanup was not marker-last");
    verifyOwner(before);
    const lockRows = proof.cases.map(({ file, originalOid, originalHash, finalHash }) => ({ file, originalOid, originalHash, finalHash }));
    const evidence = {
      schema: "phase182-08-evidence.v1", root: ROUTE, plan: "182-08", branch: BRANCH,
      status: "preallocation-review", allocated: false, attempts: [],
      createdAt: now(), source: { commit: BASE, tree: TREE, patchHash: PATCH_HASH }, planSha256: sha(plan),
      controller,
      proposedGraph: { packageChanges: UPDATES, archives: proof.archives.size,
        lockManifests: proof.final.reduce((sum, workspace) => sum + workspace.packages.length, 0), locks: lockRows },
      advisories, owner: before,
      cachePreflight: { status: "passed", source: cacheSource, schema: inspect.schema, repoUrl: inspect.repoUrl,
        requiredRecords: rows.length, recordsChecked: probe.recordsChecked, requiredRecordsSha256: sha(JSON.stringify(rows)),
        lockArchiveRecords: proof.archives.size, sourceLockManifests: 282,
        offline: true, effectiveRepoUrl: probe.repoUrl, probeCacheHome: path.dirname(scratchCache),
        inspectReceiptSha256: inspect.stdoutSha256, offlinePrefetchReceiptSha256: probe.stdoutSha256,
        sourceUnchanged: true, scratchRemoved, scratchMarkerLast: true },
      stageReceipts: { preallocation: { stage: "preallocation", status: "passed", plan: "182-08",
        sourceTree: TREE, receiptSha256: sha(JSON.stringify({ inspect: inspect.stdoutSha256, probe: probe.stdoutSha256,
          controller: controller.registrySectionSha256, plan: sha(plan) })) } },
      cleanup: { routeRootAbsent: true, preflightRootAbsent: !exists(PREFLIGHT), allocatedResources: [],
        removedResources: [PREFLIGHT], retainedResources: [] },
    };
    save(evidence, EVIDENCE, true);
    verifyOwner(evidence.owner);
    return { status: "passed", written: path.basename(EVIDENCE), schema: inspect.schema, repoUrl: inspect.repoUrl,
      requiredRecords: rows.length, prefetchRecords: probe.recordsChecked, candidateRootAbsent: !exists(ROUTE),
      preflightRootAbsent: !exists(PREFLIGHT), ownerUnchanged: true };
  } catch (error) {
    let cleanupError = null;
    if (scratchNonce && exists(PREFLIGHT)) {
      try { removeOwned(PREFLIGHT, scratchNonce); scratchRemoved = !exists(PREFLIGHT); }
      catch (cleanup) { cleanupError = sanitize(cleanup.message); }
    }
    const ownerEqual = (() => { try { verifyOwner(before); return true; } catch (_) { return false; } })();
    const evidence = {
      schema: "phase182-08-evidence.v1", root: ROUTE, plan: "182-08", branch: BRANCH,
      status: "blocked", allocated: false, attempts: [],
      createdAt: now(), source: { commit: BASE, tree: TREE, patchHash: PATCH_HASH }, planSha256: exists(PLAN) ? digest(PLAN) : null,
      controller: controller || (exists(__filename) ? controllerSeal() : null),
      firstStop: { gate, reason: sanitize(error.message).slice(0, 1000), at: now() },
      cachePreflight: { status: "blocked", source: cacheSource || null, schema: inspect?.schema ?? null,
        repoUrl: inspect?.repoUrl ?? null, requiredRecords: rows?.length ?? null,
        offlinePrefetchReceiptSha256: probe?.stdoutSha256 ?? null, registryFailure: cacheFailure ||
          (inspect?.failure ? { phase: "owner-cache-records", reason: inspect.failure } : null) },
      owner: before, cleanup: { routeRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT),
        preflightScratchRemoved: scratchRemoved, preflightCleanupError: cleanupError, ownerEqual },
    };
    save(evidence, EVIDENCE, true);
    return { status: "blocked", written: path.basename(EVIDENCE), firstStop: evidence.firstStop,
      candidateRootAbsent: !exists(ROUTE), preflightRootAbsent: !exists(PREFLIGHT), ownerUnchanged: ownerEqual };
  }
}
async function readOnlyCheck() {
  const proof = lockProof();
  const fixtures = selftest();
  const before = ownerBaseline();
  const advisories = await advisoryProof(proof);
  verifyOwner(before);
  return { proof, fixtures, before, advisories };
}
async function cli(argv) {
  const [name, stageName] = argv;
  if (name === "selftest" && (argv.length === 1 || (argv.length === 2 && stageName === "--cache"))) return selftest();
  if (name === "cache-preflight" && argv.length === 1) return captureCachePreflight();
  if (name === "start-local" && argv.length === 1) return startLocal();
  if (name === "verify-stage" && stageName === "terminal" && argv.length === 2) return verifyTerminal();
  if (name === "verify-stage" && stageName === "preallocation" && argv.length === 2) {
    const e = load();
    if (e.status === "blocked") return verifyTerminal(e);
    need(e.status === "preallocation-review" && !e.allocated && e.attempts.length === 0 &&
      !exists(ROUTE) && !exists(PREFLIGHT) && e.cleanup?.routeRootAbsent && e.cleanup?.preflightRootAbsent,
    "candidate-free cache preflight receipt is incomplete");
    need(e.plan === "182-08" && e.branch === BRANCH && e.planSha256 === digest(PLAN),
      "plan or route branch identity changed after cache preflight");
    const currentController = controllerSeal();
    need(e.controller?.registrySectionSha256 === currentController.registrySectionSha256,
      "sealed registry comparator changed after cache preflight");
    validateRegistryMeta(e.cachePreflight, 124);
    verifyOwner(e.owner);
    return { status: "verified", stage: "preallocation", schema: e.cachePreflight.schema,
      repoUrl: e.cachePreflight.repoUrl, records: e.cachePreflight.recordsChecked,
      candidateRootAbsent: true, preflightRootAbsent: true };
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
  throw new Error("usage: 182-08-route.cjs selftest|cache-preflight|start-local|verify-stage preallocation|dependency|local|terminal");
}
if (require.main === module) {
  cli(process.argv.slice(2)).then((result) => console.log(JSON.stringify(result))).catch((error) => {
    console.error(sanitize(error.message));
    process.exitCode = 1;
  });
}

module.exports = { parseLock, refreshLock, verifyLockDelta, patchCheck, makeBuildView, markRoot, removeOwned, lockProof, advisoryProof };
