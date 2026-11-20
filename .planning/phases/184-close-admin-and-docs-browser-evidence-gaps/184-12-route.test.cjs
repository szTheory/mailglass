"use strict";

const assert = require("node:assert/strict");
const { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const path = require("node:path");
const { createHash, randomUUID } = require("node:crypto");
const test = require("node:test");
const {
  APPROVED_PATCH_RELATIVE,
  APPROVED_PATCH_SHA256,
  OWNER,
  checksumObservedHex,
  normalizeRequirementTerms,
  validateRetainedRegistryReceipt,
  validateTerminalCustody,
  terminalizeBlockedEvidence,
  markRoot,
  removeOwned,
  resolvePatchAtRoot,
  resolveApprovedPatch,
  assertStageAllowed,
  testedCommands,
  validateRegistryReceipt,
  compareRegistryRequirementsFixture,
} = require("./184-12-route.cjs");

function fakeFs({ target, raw, kind = "file", realPath = target } = {}) {
  return {
    lstatSync(actual) {
      if (actual !== target || kind === "missing") {
        const error = new Error("missing fixture path");
        error.code = "ENOENT";
        throw error;
      }
      return {
        isFile: () => kind === "file",
        isSymbolicLink: () => kind === "symlink",
        nlink: 1,
      };
    },
    realpathSync(actual) {
      if (actual !== target || kind === "missing") throw new Error("missing fixture path");
      return realPath;
    },
    readFileSync(actual) {
      if (actual !== target || !raw) throw new Error("fixture read was not the selected path");
      return raw;
    },
  };
}

function row(overrides = {}) {
  return {
    name: "fixture_pkg",
    version: "1.2.3",
    inner: "01".repeat(32),
    outer: "02".repeat(32),
    dependencies: [],
    innerRaw: Buffer.from("01".repeat(32), "hex"),
    outerRaw: Buffer.from("02".repeat(32), "hex"),
    ...overrides,
  };
}

function receipt(records = [row()], overrides = {}) {
  return {
    mode: "probe",
    schema: 5,
    repoUrl: "https://repo.hex.pm",
    effectiveRepoUrl: "https://repo.hex.pm",
    effectiveCachePath: "/disposable/hex/cache.bin",
    offline: true,
    records,
    ...overrides,
  };
}
function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}
function dependency({ repo = "hexpm", packageName = "elixir_make", app = "elixir_make",
  requirement, optional = false }) {
  return [repo, packageName, app, requirement, String(optional)]
    .map((value) => Buffer.from(value, "utf8").toString("base64")).join(",");
}

test("Hex 2.6.0 registry and retained readback accept the recorded equivalent lock requirement", () => {
  const expectedText = "~> 0.7";
  const observedText = "~> 0.7 or ~> 0.8 or ~> 0.9";
  const expectedDependency = dependency({ requirement: expectedText });
  const observedDependency = dependency({ requirement: observedText });
  const expected = row({ name: "cc_precompiler", version: "0.1.11", dependencies: [expectedDependency] });
  const observed = { ...expected, dependencies: [observedDependency] };
  const productionComparatorAccepted = compareRegistryRequirementsFixture([expectedDependency], [observedDependency]);
  let retainedReadbackAccepted = false;
  let retainedComparison;
  try {
    const cachePath = "/disposable/hex/cache.bin";
    const b64 = (value) => Buffer.from(value).toString("base64");
    const stdout = Buffer.from([
      ["META", "5", b64("https://repo.hex.pm"), b64("https://repo.hex.pm"), b64(cachePath), "true", "1"].join("\t"),
      ["REC", observed.name, observed.version, observed.innerRaw.toString("base64"),
        observed.outerRaw.toString("base64"), observedDependency].join("\t"),
      "PASS",
      "",
    ].join("\n"));
    const normalizedTerms = normalizeRequirementTerms([expectedText, observedText]);
    const requirementComparisons = [{
      repo: "hexpm", package: "elixir_make", app: "elixir_make", optional: false,
      expected: [expectedText], observed: [observedText], normalizedTermsBase64: [normalizedTerms[0]],
    }];
    const checkedRecord = { name: observed.name, version: observed.version, inner: observed.inner,
      outer: observed.outer, dependencies: [observedDependency], requirementComparisons };
    const retained = {
      schema: "phase184-12-registry-receipt.v1",
      recordsChecked: 1,
      recordsSha256: sha256(JSON.stringify([checkedRecord])),
      receipt: {
        mode: "probe", cachePath, stdoutBase64: stdout.toString("base64"), stdoutSha256: sha256(stdout),
        dependencyRequirementPairs: [{ name: observed.name, version: observed.version,
          comparisons: requirementComparisons }],
      },
    };
    const replay = validateRetainedRegistryReceipt(retained, [expected], cachePath);
    retainedComparison = replay.checked.records[0].requirementComparisons[0];
    retainedReadbackAccepted = replay.checked.recordsChecked === 1;
  } catch (_) {}
  assert.deepEqual({ productionComparatorAccepted, retainedReadbackAccepted }, {
    productionComparatorAccepted: true,
    retainedReadbackAccepted: true,
  });
  assert.deepEqual({ expected: retainedComparison.expected, observed: retainedComparison.observed }, {
    expected: [expectedText], observed: [observedText],
  });
});

test("Hex requirement equality rejects valid non-equivalent, broader, malformed, and tuple drift", () => {
  const expected = dependency({ requirement: "~> 0.7" });
  const equivalent = dependency({ requirement: "~> 0.7 or ~> 0.8 or ~> 0.9" });
  const wrongRange = dependency({ requirement: "~> 0.8" });
  const broaderRange = dependency({ requirement: ">= 0.7" });
  const wrongPackage = dependency({ packageName: "other_pkg", requirement: "~> 0.7" });
  const wrongApp = dependency({ app: "other_app", requirement: "~> 0.7" });
  const optional = dependency({ requirement: "~> 0.7", optional: true });
  assert.equal(compareRegistryRequirementsFixture([expected], [equivalent]), true);
  for (const actual of [wrongRange, broaderRange, wrongPackage, wrongApp, optional]) {
    assert.equal(compareRegistryRequirementsFixture([expected], [actual]), false);
  }
  assert.throws(() => compareRegistryRequirementsFixture([expected], [dependency({ requirement: "not a version range" })]),
    /semantic comparator fixture failed/i);
  assert.throws(() => validateRegistryReceipt(receipt([{ ...row(), dependencies: [equivalent] }]),
    [{ ...row(), dependencies: [expected] }], "/disposable/hex/cache.bin"), /requirement|tuple/i);
  assert.throws(() => validateRegistryReceipt(receipt([{ ...row(), dependencies: [equivalent, equivalent] }]),
    [{ ...row(), dependencies: [expected] }], "/disposable/hex/cache.bin"), /multiplicity/i);
});

test("resolves only the approved patch from the canonical checkout when cwd is foreign", () => {
  const selected = resolveApprovedPatch({ cwd: "/foreign/phase-182" });
  const expected = path.join(OWNER, APPROVED_PATCH_RELATIVE);
  assert.equal(selected.path, expected);
  assert.equal(selected.sha256, APPROVED_PATCH_SHA256);
  assert.equal(selected.bytes.toString("base64"), readFileSync(expected).toString("base64"));
});

test("rejects missing, symlinked, alternate-root, and changed patch inputs", () => {
  const root = "/fixture/canonical-repo";
  const target = path.join(root, APPROVED_PATCH_RELATIVE);
  const raw = Buffer.from("synthetic bytes at the selected read boundary");
  const resolveAt = (io) => resolvePatchAtRoot(root, io);

  assert.throws(() => resolveAt(fakeFs({ target, raw, kind: "missing" })), /missing/i);
  assert.throws(() => resolveAt(fakeFs({ target, raw, kind: "symlink", realPath: "/fixture/elsewhere/patch" })), /symlink|regular/i);
  assert.throws(() => resolveAt(fakeFs({ target, raw })), /checksum/i);
  assert.throws(() => resolveApprovedPatch({ canonicalRoot: "/fixture/alternate-repo", cwd: "/foreign" }), /canonical|root/i);
});

test("compares canonical lowercase lock hex to the raw 32-byte registry value", () => {
  const expected = "a7".repeat(32);
  const observed = Buffer.from(expected, "hex");
  assert.equal(checksumObservedHex(expected, observed), expected);
});

test("rejects mutations, ASCII hex, bad lengths, and noncanonical lock encodings", () => {
  const inner = "1a".repeat(32);
  const outer = "ef".repeat(32);
  const innerMutation = Buffer.from(inner, "hex");
  const outerMutation = Buffer.from(outer, "hex");
  innerMutation[0] ^= 1;
  outerMutation[31] ^= 1;
  assert.throws(() => checksumObservedHex(inner, innerMutation), /checksum/i);
  assert.throws(() => checksumObservedHex(outer, outerMutation), /checksum/i);
  assert.throws(() => checksumObservedHex(inner, Buffer.from(inner, "ascii")), /32 raw bytes/i);
  assert.throws(() => checksumObservedHex(inner, Buffer.alloc(31)), /32 raw bytes/i);
  assert.throws(() => checksumObservedHex(inner.toUpperCase(), Buffer.from(inner, "hex")), /canonical/i);
  assert.throws(() => checksumObservedHex("gg".repeat(32), Buffer.alloc(32)), /canonical/i);
});

test("accepts exactly the schema-5 offline record set and effective Hex URL", () => {
  const expected = row();
  const checked = validateRegistryReceipt(receipt([expected]), [expected], "/disposable/hex/cache.bin");
  assert.deepEqual(checked, {
    schema: 5,
    repoUrl: "https://repo.hex.pm",
    recordsChecked: 1,
    records: [{
      name: expected.name,
      version: expected.version,
      inner: expected.inner,
      outer: expected.outer,
      dependencies: expected.dependencies,
    }],
  });
});

test("rejects schema, effective URL, cache path, offline, count, duplicate, and missing-record drift", () => {
  const expected = row();
  const expectedRows = [expected];
  for (const bad of [
    receipt([expected], { schema: 3 }),
    receipt([expected], { repoUrl: "https://mirror.invalid", effectiveRepoUrl: "https://mirror.invalid" }),
    receipt([expected], { effectiveRepoUrl: "https://mirror.invalid" }),
    receipt([expected], { effectiveCachePath: "/owner/.hex/cache.bin" }),
    receipt([expected], { offline: false }),
    receipt([]),
    receipt([expected, expected]),
  ]) {
    assert.throws(() => validateRegistryReceipt(bad, expectedRows, "/disposable/hex/cache.bin"));
  }
});

test("rejects release, checksum, dependency, and checksum-shape mismatches", () => {
  const expected = row();
  const wrongVersion = row({ version: "9.9.9" });
  const wrongInner = row({ innerRaw: Buffer.from("03".repeat(32), "hex") });
  const wrongOuter = row({ outerRaw: Buffer.from("04".repeat(32), "hex") });
  const wrongDependencies = row({ dependencies: [dependency({ packageName: "dep-c", requirement: "~> 1.0" })] });
  const asciiBytes = row({ innerRaw: Buffer.from(expected.inner, "ascii") });
  const badLength = row({ outerRaw: Buffer.alloc(31) });
  for (const actual of [wrongVersion, wrongInner, wrongOuter, wrongDependencies, asciiBytes, badLength]) {
    assert.throws(() => validateRegistryReceipt(receipt([actual]), [expected], "/disposable/hex/cache.bin"));
  }
});

test("read-only verifier reparses a retained raw receipt for all 124 lock records", () => {
  const expectedRows = Array.from({ length: 124 }, (_, index) => ({
    name: `fixture_${String(index).padStart(3, "0")}`,
    version: "1.0.0",
    inner: sha256(`inner-${index}`),
    outer: sha256(`outer-${index}`),
    dependencies: [],
  }));
  const cachePath = "/private/tmp/phase184-12/cache/hex/cache.bin";
  const b64 = (value) => Buffer.from(value).toString("base64");
  const lines = [
    ["META", "5", b64("https://repo.hex.pm"), b64("https://repo.hex.pm"), b64(cachePath), "true", "124"].join("\t"),
    ...expectedRows.map((item) => ["REC", item.name, item.version, b64(Buffer.from(item.inner, "hex")),
      b64(Buffer.from(item.outer, "hex")), ""].join("\t")),
    "PASS",
  ];
  const stdout = Buffer.from(`${lines.join("\n")}\n`);
  const retained = {
    schema: "phase184-12-registry-receipt.v1",
    recordsChecked: expectedRows.length,
    recordsSha256: sha256(JSON.stringify(expectedRows)),
    receipt: { mode: "probe", cachePath, stdoutBase64: stdout.toString("base64"), stdoutSha256: sha256(stdout) },
  };
  const checked = validateRetainedRegistryReceipt(retained, expectedRows, cachePath);
  assert.equal(checked.checked.recordsChecked, 124);
  assert.equal(checked.receipt.offline, true);
  assert.throws(() => validateRetainedRegistryReceipt({ ...retained,
    receipt: { ...retained.receipt, stdoutSha256: "0".repeat(64) } }, expectedRows, cachePath), /checksum/i);
});

test("blocked terminal finalizer binds one custody marker to marker-last cleanup", (t) => {
  const root = mkdtempSync("/private/tmp/mailglass-184-12-terminal-fixture-");
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const ownedRoot = path.join(root, "owned-root");
  const ownerNonce = randomUUID();
  markRoot(ownedRoot, ownerNonce);
  writeFileSync(path.join(ownedRoot, "owned-output.json"), "owned fixture\n");
  const removed = removeOwned(ownedRoot, ownerNonce);
  assert.equal(removed.at(-1), ".route-owner.json");
  assert.equal(existsSync(ownedRoot), false);

  const preimagePath = path.join(root, "terminal-preimage.json");
  const evidencePath = path.join(root, "evidence.json");
  const ledger = [];
  const evidence = { status: "blocked", allocated: false, route: { nonce: randomUUID() }, custody: {} };
  const finalized = terminalizeBlockedEvidence(evidence, {
    preimagePath,
    saveEvidence(value) { writeFileSync(evidencePath, JSON.stringify(value)); },
    appendTerminal(row) { ledger.push({ sequence: ledger.length + 1, ...row }); },
    ledgerDigest() { return sha256(JSON.stringify(ledger)); },
  });
  assert.equal(finalized.terminal.status, "blocked");
  assert.equal(finalized.terminal.preimageSha256, sha256(readFileSync(preimagePath)));
  assert.equal(finalized.custody.sha256, sha256(JSON.stringify(ledger)));
  assert.equal(validateTerminalCustody(finalized, ledger), true);
  assert.throws(() => assertStageAllowed(finalized, "start-local"), /blocked route/i);
  assert.throws(() => validateTerminalCustody(finalized, []), /terminal blocked disposition/i);
  assert.throws(() => terminalizeBlockedEvidence(finalized, {
    preimagePath: path.join(root, "again.json"), saveEvidence() {}, appendTerminal() {}, ledgerDigest() { return ""; },
  }), /fresh blocked/i);
});

test("selects only the next route stage and blocks all downstream effects after a stop", () => {
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
  assert.deepEqual(testedCommands().browserContainer.slice(0, 5),
    ["docker", "run", "--pull=never", "--network=none", "--read-only"]);
});
