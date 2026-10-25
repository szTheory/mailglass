"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { test } = require("node:test");
const { prepareBaselines } = require("../scripts/prepare_phase173_baselines.cjs");
const { EXPECTED_BASELINES, validatePinnedBaselines } = require("../reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs");

const committed = path.resolve(__dirname, "../reference/demo_app/assets/baselines/phase173");

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase173-baselines-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, "source");
  const output = path.join(root, "output");
  fs.mkdirSync(source);
  for (const baseline of EXPECTED_BASELINES) {
    fs.copyFileSync(path.join(committed, baseline.path), path.join(source, baseline.path));
  }
  return { root, source, output };
}

test("a fresh checkout prepares only six exact pinned PNGs and safely reuses identical files", (t) => {
  const { root, source, output } = fixture(t);
  assert.equal(prepareBaselines(source, output, root), 6);
  assert.equal(prepareBaselines(source, output, root), 6);
  assert.deepEqual(fs.readdirSync(output).sort(), EXPECTED_BASELINES.map((b) => b.path).sort());
  assert.equal(validatePinnedBaselines(output).length, 6);
});

test("missing or changed source baseline fails before evidence capture", (t) => {
  const { root, source, output } = fixture(t);
  const filename = path.join(source, EXPECTED_BASELINES[0].path);
  fs.writeFileSync(filename, "changed baseline");
  assert.throws(() => prepareBaselines(source, output, root));
  fs.unlinkSync(filename);
  assert.throws(() => prepareBaselines(source, output, root));
  assert.equal(fs.existsSync(output), false);
});

test("different existing baseline bytes are rejected and never overwritten", (t) => {
  const { root, source, output } = fixture(t);
  fs.mkdirSync(output);
  const filename = path.join(output, EXPECTED_BASELINES[0].path);
  fs.writeFileSync(filename, "owner bytes");
  assert.throws(() => prepareBaselines(source, output, root), /refusing overwrite/);
  assert.equal(fs.readFileSync(filename, "utf8"), "owner bytes");
});

test("symlinked output directory and destination files are rejected without changing their targets", (t) => {
  const { root, source, output } = fixture(t);
  const target = path.join(root, "target");
  fs.mkdirSync(target);
  fs.symlinkSync(target, output);
  assert.throws(() => prepareBaselines(source, output, root));
  assert.deepEqual(fs.readdirSync(target), []);
  fs.unlinkSync(output);
  fs.mkdirSync(output);
  const targetFile = path.join(target, "owner.txt");
  fs.writeFileSync(targetFile, "owner bytes");
  fs.symlinkSync(targetFile, path.join(output, EXPECTED_BASELINES[0].path));
  assert.throws(() => prepareBaselines(source, output, root));
  assert.equal(fs.readFileSync(targetFile, "utf8"), "owner bytes");
});
