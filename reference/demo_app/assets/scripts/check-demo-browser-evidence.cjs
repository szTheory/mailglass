#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const evidenceDir = path.resolve(__dirname, "../../tmp/demo_browser_evidence");
const reportPath = path.join(evidenceDir, "playwright-report.json");
const manifestPath = path.join(evidenceDir, "phase173-captures.json");
const checkpointPath = path.join(evidenceDir, "checkpoint.json");
const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

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

function createCheckpoint({ report, manifest, evidenceDir: root, candidateRevision }) {
  if (!report || !Array.isArray(report.suites)) {
    throw new Error("Playwright JSON report is missing suites");
  }
  if (!manifest || !Array.isArray(manifest.captures) || manifest.captures.length === 0) {
    throw new Error("report must contain exactly one current capture for the tracer (zero found)");
  }
  if (typeof candidateRevision !== "string" || candidateRevision.length === 0) {
    throw new Error("candidate revision is missing");
  }

  const tests = collectTests(report.suites);
  const outcomes = new Map(tests.map((test) => [test.title, test]));
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

    const safePath = safeCapturePath(root, capture.path);
    const bytes = fs.readFileSync(safePath.absolutePath);
    if (bytes.length < PNG_SIGNATURE.length || !bytes.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE)) {
      throw new Error(`missing or invalid PNG: ${capture.path}`);
    }

    return {
      ...capture,
      path: safePath.relativePath,
      sha256: crypto.createHash("sha256").update(bytes).digest("hex")
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
