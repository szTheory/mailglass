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

  return {
    schema_version: "demo_browser_evidence.v2",
    generated_at: new Date().toISOString(),
    status: "passed",
    candidate_revision: candidateRevision,
    captures
  };
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

module.exports = { createCheckpoint, collectTests, safeCapturePath };
