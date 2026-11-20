"use strict";

const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const {
  APPROVED_PATCH_RELATIVE,
  APPROVED_PATCH_SHA256,
  OWNER,
  checksumObservedHex,
  resolveApprovedPatch,
  validateRegistryReceipt,
} = require("./184-11-route.cjs");

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
    dependencies: ["dep-a", "dep-b"],
    innerRaw: Buffer.from("01".repeat(32), "hex"),
    outerRaw: Buffer.from("02".repeat(32), "hex"),
    ...overrides,
  };
}

function receipt(records = [row()], overrides = {}) {
  return {
    schema: 5,
    repoUrl: "https://repo.hex.pm",
    effectiveRepoUrl: "https://repo.hex.pm",
    effectiveCachePath: "/disposable/hex/cache.bin",
    offline: true,
    records,
    ...overrides,
  };
}

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
  const resolveAt = (io) => resolveApprovedPatch({ canonicalRoot: root, io });

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
  assert.throws(() => checksumObservedHex(inner, Buffer.from(inner, "ascii")), /32 bytes/i);
  assert.throws(() => checksumObservedHex(inner, Buffer.alloc(31)), /32 bytes/i);
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
  const wrongDependencies = row({ dependencies: ["dep-c"] });
  const asciiBytes = row({ innerRaw: Buffer.from(expected.inner, "ascii") });
  const badLength = row({ outerRaw: Buffer.alloc(31) });
  for (const actual of [wrongVersion, wrongInner, wrongOuter, wrongDependencies, asciiBytes, badLength]) {
    assert.throws(() => validateRegistryReceipt(receipt([actual]), [expected], "/disposable/hex/cache.bin"));
  }
});
