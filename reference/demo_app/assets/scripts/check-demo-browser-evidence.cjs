#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const evidenceDir = path.resolve(__dirname, "../../tmp/demo_browser_evidence");
const reportPath = path.join(evidenceDir, "playwright-report.json");
const manifestPath = path.join(evidenceDir, "phase173-captures.json");
const checkpointPath = path.join(evidenceDir, "checkpoint.json");
const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const REQUIRED_TESTS = [
  "dashboard links to preview and operator surfaces",
  "outbound operator opens with seeded delivery evidence",
  "inbound operator opens with seeded support mailbox evidence",
  "empty account stays isolated and explains the absence of deliveries",
  "recipient browser shows a truthful expired unsubscribe state"
];
const SHA256_PATTERN = /^[0-9a-f]{64}$/;
const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const MAX_PNG_BYTES = 8 * 1024 * 1024;
const BASELINE_SOURCE_REVISION = "7e3720237f51f2907b77c7dcb03042f2dd379d53";
const EXPECTED_BASELINES = Object.freeze([
  ["dashboard", "baseline-dashboard-7e372023-375-light", "baseline-dashboard-7e372023-375-light.png", "54f7f188fba06483302e72a96340487217e700880a5389de6e71e22eec45b9a4", "375x1613"],
  ["preview", "baseline-preview-7e372023-375-light", "baseline-preview-7e372023-375-light.png", "263e69bac41292128583b2accb5f6f7c43d5a5c1a9aa86b09fe758d032d85206", "375x1847"],
  ["outbound-primary", "baseline-outbound-7e372023-1440-light", "baseline-outbound-7e372023-1440-light.png", "7984796b17ceb0b04f9d465925aae0c9356b1bd26732d28c8a5b448a2d749791", "1440x2002"],
  ["inbound-primary", "baseline-inbound-7e372023-1440-dark", "baseline-inbound-7e372023-1440-dark.png", "e5b263b3dba88cebe5636b1f27e868457045d9841ce070bb873fc0aaa97e3b6c", "1440x1431"],
  ["empty-account-adverse", "baseline-empty-account-7e372023-375-dark", "baseline-empty-account-7e372023-375-dark.png", "8809d1c8094f5698cbd7e55f1bcdc34e198947bd8cf2cbe59202b3522f95c9b7", "375x1013"],
  ["recipient-expired-adverse", "baseline-recipient-expired-7e372023-375-light", "baseline-recipient-expired-7e372023-375-light.png", "bf9013f075e08143128675efb4436f8e3f52b091201e4ab06f9930bb8182d560", "375x900"]
].map(([captureId, id, path, sha256, dimensions]) => Object.freeze({ captureId, id, path, sha256, dimensions })));
const EXPECTED_TITLES = Object.freeze({
  dashboard: "dashboard links to preview and operator surfaces",
  preview: "dashboard links to preview and operator surfaces",
  "outbound-primary": "outbound operator opens with seeded delivery evidence",
  "inbound-primary": "inbound operator opens with seeded support mailbox evidence",
  "empty-account-adverse": "empty account stays isolated and explains the absence of deliveries",
  "recipient-expired-adverse": "recipient browser shows a truthful expired unsubscribe state"
});

function requireString(value, label) {
  if (typeof value !== "string" || value.length === 0) throw new Error(`${label} is missing`);
}

function requireSha256(value, label) {
  if (typeof value !== "string" || !SHA256_PATTERN.test(value)) {
    throw new Error(`${label} must be a full SHA-256 digest`);
  }
}

function validateAssetIdentity(assets, captureTitle) {
  if (!assets || !["admin-css", "compiled-template"].includes(assets.kind)) {
    throw new Error(`source/build/served asset identity is missing: ${captureTitle}`);
  }
  for (const key of ["source", "built"]) {
    requireString(assets[key]?.path, `${key} asset path`);
    requireSha256(assets[key]?.sha256, `${key} asset digest`);
  }
  requireString(assets.served?.url, "served asset URL");
  if (assets.kind === "admin-css") {
    requireSha256(assets.served.sha256, "served CSS digest");
    if (assets.built_served_match !== true || assets.built.sha256 !== assets.served.sha256) {
      throw new Error(`built/served CSS identity mismatch: ${captureTitle}`);
    }
  } else {
    requireSha256(assets.served?.html_sha256, "served HTML digest");
    requireSha256(assets.served?.inline_css_sha256, "served inline CSS digest");
    if (assets.built_served_match !== null) {
      throw new Error(`compiled-template asset comparison must be explicitly scoped: ${captureTitle}`);
    }
  }
}

function collectTests(suites, acc = []) {
  for (const suite of suites || []) {
    for (const spec of suite.specs || []) {
      for (const test of spec.tests || []) {
        acc.push({
          title: spec.title,
          outcomes: (test.results || []).map((result) => result.status),
          outcome: test.outcome || test.status
        });
      }
    }
    collectTests(suite.suites, acc);
  }
  return acc;
}

function safeCapturePath(root, relativePath) {
  if (typeof relativePath !== "string" || relativePath.length === 0) {
    throw new Error("capture path is missing");
  }
  if (path.isAbsolute(relativePath) || relativePath.split(/[\\/]/).includes("..")) {
    throw new Error(`capture path must be relative and traversal-free: ${relativePath}`);
  }

  const resolvedRoot = path.resolve(root);
  const capturePath = path.resolve(resolvedRoot, relativePath);
  if (capturePath === resolvedRoot || !capturePath.startsWith(`${resolvedRoot}${path.sep}`)) {
    throw new Error(`capture path is outside the owned evidence directory: ${relativePath}`);
  }

  let realRoot;
  let realCapture;
  let stat;
  try {
    stat = fs.lstatSync(capturePath);
  } catch {
    throw new Error(`missing or invalid PNG: ${relativePath}`);
  }
  if (stat.isSymbolicLink()) throw new Error(`capture path is outside the owned evidence directory: ${relativePath}`);
  if (!stat.isFile()) throw new Error(`capture is not a regular file: ${relativePath}`);
  try {
    realRoot = fs.realpathSync(resolvedRoot);
    realCapture = fs.realpathSync(capturePath);
  } catch {
    throw new Error(`missing or invalid PNG: ${relativePath}`);
  }
  if (!realCapture.startsWith(`${realRoot}${path.sep}`)) {
    throw new Error(`capture path is outside the owned evidence directory: ${relativePath}`);
  }
  return { absolutePath: realCapture, relativePath };
}

function createCheckpoint({
  report,
  manifest,
  evidenceDir: root,
  candidateRevision,
  requiredTestTitles = REQUIRED_TESTS
}) {
  if (!report || !Array.isArray(report.suites)) {
    throw new Error("Playwright JSON report is missing suites");
  }
  if (!manifest || manifest.schema_version !== "phase173-captures.v2" || !Array.isArray(manifest.captures) || manifest.captures.length === 0) {
    throw new Error("report must contain exactly one current capture for the tracer (zero found)");
  }
  if (typeof candidateRevision !== "string" || !/^[0-9a-f]{40}$/.test(candidateRevision)) {
    throw new Error("candidate revision must be a full Git object ID");
  }
  if (!Array.isArray(requiredTestTitles) || requiredTestTitles.length === 0) {
    throw new Error("required browser test titles are missing");
  }

  const phaseSuitePresent = report.suites.some((suite) =>
    typeof suite.title === "string" && suite.title.includes("phase173-evidence.spec.js")
  );
  if (!phaseSuitePresent) throw new Error("Playwright report does not come from phase173-evidence.spec.js");

  const tests = collectTests(report.suites);
  const outcomes = new Map(tests.map((test) => [test.title, test]));
  const captureTitles = new Set(manifest.captures.map((capture) => capture?.test_title));
  for (const title of requiredTestTitles) {
    const matchingTest = outcomes.get(title);
    if (!matchingTest || (matchingTest.outcome !== "expected" && matchingTest.outcome !== "passed")) {
      throw new Error(`required browser test did not pass: ${title}`);
    }
    if (!captureTitles.has(title)) throw new Error(`required browser test has no current capture: ${title}`);
  }

  const seenCaptureIds = new Set();
  const captures = manifest.captures.map((capture) => {
    if (!capture || typeof capture !== "object" || typeof capture.test_title !== "string") {
      throw new Error("capture test title is missing");
    }
    const matchingTest = outcomes.get(capture.test_title);
    if (!matchingTest || (matchingTest.outcome !== "expected" && matchingTest.outcome !== "passed")) {
      throw new Error(`capture test did not pass: ${capture.test_title}`);
    }
    if (capture.candidate_revision !== candidateRevision) {
      throw new Error(`capture candidate revision does not match: ${capture.test_title}`);
    }
    if (typeof capture.candidate_dirty !== "boolean") throw new Error("candidate dirty-tree state is missing");
    if (seenCaptureIds.has(capture.id)) throw new Error(`duplicate capture ID: ${capture.id}`);
    seenCaptureIds.add(capture.id);
    requireString(capture.id, "capture ID");
    if (typeof capture.route !== "string" || !capture.route.startsWith("/")) {
      throw new Error(`capture route is missing or invalid: ${capture.test_title}`);
    }
    for (const field of ["fixture", "theme", "viewport", "interaction_state", "browser", "rendering_scope"]) {
      requireString(capture[field], `capture ${field}`);
    }
    if (!["light", "dark", "system"].includes(capture.theme)) throw new Error(`capture theme is invalid: ${capture.test_title}`);
    const dimensions = /^(\d+)x(\d+)$/.exec(capture.viewport);
    if (!dimensions) throw new Error(`capture viewport is invalid: ${capture.test_title}`);
    if (!capture.before_after || typeof capture.before_after !== "object") {
      throw new Error(`before/after relation is missing: ${capture.test_title}`);
    }
    requireString(capture.before_after.baseline_id, "baseline ID");
    const baselinePath = safeCapturePath(root, capture.before_after.baseline_path);
    requireSha256(capture.before_after.baseline_sha256, "baseline PNG digest");
    if (!/^[0-9a-f]{40}$/.test(capture.before_after.baseline_source_revision || "")) {
      throw new Error("baseline source revision must be a full Git object ID");
    }
    if (typeof capture.before_after.baseline_dirty !== "boolean") {
      throw new Error("baseline dirty-tree state is missing");
    }
    for (const field of [
      "baseline_route",
      "baseline_fixture",
      "baseline_theme",
      "baseline_viewport",
      "baseline_capture_dimensions",
      "baseline_interaction_state",
      "baseline_browser",
      "relation"
    ]) {
      requireString(capture.before_after[field], `before/after ${field}`);
    }
    if (!["light", "dark", "system"].includes(capture.before_after.baseline_theme)) {
      throw new Error(`baseline theme is invalid: ${capture.test_title}`);
    }
    const baselineDimensions = /^(\d+)x(\d+)$/.exec(capture.before_after.baseline_viewport);
    if (!baselineDimensions) throw new Error(`baseline viewport is invalid: ${capture.test_title}`);
    const baselineCaptureDimensions = /^(\d+)x(\d+)$/.exec(capture.before_after.baseline_capture_dimensions);
    if (!baselineCaptureDimensions) throw new Error(`baseline capture dimensions are invalid: ${capture.test_title}`);
    const baselineBytes = fs.readFileSync(baselinePath.absolutePath);
    if (baselineBytes.length < PNG_SIGNATURE.length || !baselineBytes.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
      throw new Error(`missing or invalid baseline PNG: ${capture.before_after.baseline_path}`);
    }
    const baselineSha256 = crypto.createHash("sha256").update(baselineBytes).digest("hex");
    if (capture.before_after.baseline_sha256 !== baselineSha256) {
      throw new Error(`baseline PNG digest mismatch: ${capture.before_after.baseline_path}`);
    }
    if (
      baselineBytes.readUInt32BE(16) !== Number(baselineCaptureDimensions[1]) ||
      baselineBytes.readUInt32BE(20) !== Number(baselineCaptureDimensions[2]) ||
      Number(baselineCaptureDimensions[1]) !== Number(baselineDimensions[1]) ||
      Number(baselineCaptureDimensions[2]) < Number(baselineDimensions[2])
    ) {
      throw new Error(`baseline PNG dimensions do not match its viewport: ${capture.before_after.baseline_path}`);
    }
    if (!capture.rendering_scope.toLowerCase().includes("browser rendering only")) {
      throw new Error(`capture exceeds browser rendering evidence scope: ${capture.test_title}`);
    }
    validateAssetIdentity(capture.assets, capture.test_title);

    const safePath = safeCapturePath(root, capture.path);
    const bytes = fs.readFileSync(safePath.absolutePath);
    if (bytes.length > MAX_PNG_BYTES) throw new Error(`PNG exceeds size limit: ${capture.path}`);
    if (bytes.length < PNG_SIGNATURE.length || !bytes.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
      throw new Error(`missing or invalid PNG: ${capture.path}`);
    }
    requireSha256(capture.sha256, "capture PNG digest");
    const actualSha256 = crypto.createHash("sha256").update(bytes).digest("hex");
    if (capture.sha256 !== actualSha256) throw new Error(`capture PNG digest mismatch: ${capture.path}`);
    if (bytes.readUInt32BE(16) !== Number(dimensions[1]) || bytes.readUInt32BE(20) !== Number(dimensions[2])) {
      throw new Error(`capture PNG dimensions do not match its viewport: ${capture.path}`);
    }

    return {
      ...capture,
      before_after: {
        ...capture.before_after,
        baseline_capture_dimensions: `${baselineBytes.readUInt32BE(16)}x${baselineBytes.readUInt32BE(20)}`
      },
      path: safePath.relativePath,
      sha256: actualSha256
    };
  });

  if (requiredTestTitles === REQUIRED_TESTS) {
    if (captures.length !== EXPECTED_BASELINES.length) throw new Error("capture set does not match the six approved synthetic captures");
    const seen = new Set();
    for (const capture of captures) {
      const expected = EXPECTED_BASELINES.find((item) => item.captureId === capture.id);
      if (!expected || seen.has(capture.id)) throw new Error(`unknown or duplicate synthetic capture: ${capture.id}`);
      seen.add(capture.id);
      if (capture.test_title !== EXPECTED_TITLES[capture.id]) throw new Error(`unexpected test title for synthetic capture: ${capture.id}`);
      if (capture.before_after.baseline_id !== expected.id || capture.before_after.baseline_path !== expected.path ||
          capture.before_after.baseline_sha256 !== expected.sha256 || capture.before_after.baseline_source_revision !== BASELINE_SOURCE_REVISION ||
          capture.before_after.baseline_capture_dimensions !== expected.dimensions) {
        throw new Error(`baseline provenance does not match the approved synthetic record: ${capture.id}`);
      }
    }
    validatePinnedBaselines(root);
  }

  return {
    schema_version: "demo_browser_evidence.v2",
    generated_at: new Date().toISOString(),
    status: "passed",
    candidate_revision: candidateRevision,
    candidate_dirty: captures.every((capture) => capture.candidate_dirty),
    route: "synthetic demo browser routes",
    fixture: "synthetic fixtures only",
    theme: "per-capture pinned theme",
    viewport: "per-capture pinned viewport",
    interaction_state: "per-capture pinned interaction state",
    browser: "per-capture identified browser",
    before_after: "six pinned baseline pairs",
    source_build_served_identity: "validated per capture",
    captures: captures.map((capture) => ({
      id: capture.id,
      test_title: capture.test_title,
      route: capture.route,
      fixture: capture.fixture,
      theme: capture.theme,
      viewport: capture.viewport,
      interaction_state: capture.interaction_state,
      browser: capture.browser,
      rendering_scope: capture.rendering_scope,
      candidate_revision: capture.candidate_revision,
      candidate_dirty: capture.candidate_dirty,
      before_after: capture.before_after,
      assets: capture.assets,
      path: capture.path,
      sha256: capture.sha256
    }))
  };
}

function validatePinnedBaselines(root) {
  const resolvedRoot = path.resolve(root);
  return EXPECTED_BASELINES.map((expected) => {
    const fullPath = path.resolve(resolvedRoot, expected.path);
    if (!fullPath.startsWith(`${resolvedRoot}${path.sep}`)) throw new Error(`baseline path escapes evidence directory: ${expected.path}`);
    const stat = fs.lstatSync(fullPath);
    if (!stat.isFile() || stat.isSymbolicLink() || stat.size > MAX_PNG_BYTES) throw new Error(`baseline is not an owned regular PNG: ${expected.path}`);
    const bytes = fs.readFileSync(fullPath);
    const dimensions = expected.dimensions.split("x").map(Number);
    if (!bytes.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE) || sha256(bytes) !== expected.sha256 ||
        bytes.readUInt32BE(16) !== dimensions[0] || bytes.readUInt32BE(20) !== dimensions[1]) {
      throw new Error(`pinned baseline validation failed: ${expected.path}`);
    }
    return expected;
  });
}

function stageRetainedEvidence(root, checkpoint) {
  const target = path.join(path.resolve(root), "retained");
  const staging = path.join(path.resolve(root), `.retained-${process.pid}-${Date.now()}`);
  fs.rmSync(staging, { recursive: true, force: true });
  fs.mkdirSync(staging, { recursive: true });
  try {
    fs.writeFileSync(path.join(staging, "checkpoint.json"), `${JSON.stringify(checkpoint, null, 2)}\n`, { flag: "wx" });
    for (const capture of checkpoint.captures) {
      const baseline = EXPECTED_BASELINES.find((item) => item.captureId === capture.id);
      const currentPath = safeCapturePath(root, capture.path).absolutePath;
      fs.copyFileSync(currentPath, path.join(staging, `${capture.id}-current.png`), fs.constants.COPYFILE_EXCL);
      fs.copyFileSync(path.join(root, baseline.path), path.join(staging, `${capture.id}-baseline.png`), fs.constants.COPYFILE_EXCL);
    }
    fs.rmSync(target, { recursive: true, force: true });
    fs.renameSync(staging, target);
  } catch (error) {
    fs.rmSync(staging, { recursive: true, force: true });
    throw error;
  }
}

function main() {
  try {
    const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    const checkpoint = createCheckpoint({
      report,
      manifest,
      evidenceDir,
      candidateRevision: process.env.DEMO_CANDIDATE_REVISION
    });
    fs.mkdirSync(evidenceDir, { recursive: true });
    fs.writeFileSync(checkpointPath, `${JSON.stringify(checkpoint, null, 2)}\n`);
    stageRetainedEvidence(evidenceDir, checkpoint);
    console.log(`Demo browser evidence passed. Checkpoint: ${checkpointPath}`);
  } catch (error) {
    const checkpoint = {
      schema_version: "demo_browser_evidence.v2",
      generated_at: new Date().toISOString(),
      status: "failed",
      candidate_revision: process.env.DEMO_CANDIDATE_REVISION || null,
      failure: error.message
    };
    fs.mkdirSync(evidenceDir, { recursive: true });
    fs.writeFileSync(checkpointPath, `${JSON.stringify(checkpoint, null, 2)}\n`);
    console.error(`Demo browser evidence failed: ${error.message}. Checkpoint: ${checkpointPath}`);
    process.exitCode = 1;
  }
}

if (require.main === module) main();

module.exports = { createCheckpoint, collectTests, safeCapturePath, validatePinnedBaselines, EXPECTED_BASELINES };
