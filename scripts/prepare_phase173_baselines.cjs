"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { validatePinnedBaselines } = require("../reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs");
const { writePinnedFile } = require("./phase173_json_output.cjs");

const workspaceRoot = path.resolve(__dirname, "..");
const sourceRoot = path.join(workspaceRoot, "reference/demo_app/assets/baselines/phase173");
const outputRoot = path.join(workspaceRoot, "reference/demo_app/tmp/demo_browser_evidence");

function prepareBaselines(source, output, trustedRoot) {
  const baselines = validatePinnedBaselines(source);
  for (const baseline of baselines) {
    const bytes = fs.readFileSync(path.join(source, baseline.path));
    const digest = crypto.createHash("sha256").update(bytes).digest("hex");
    if (digest !== baseline.sha256) throw new Error(`Pinned baseline changed: ${baseline.path}`);
    writePinnedFile(path.join(output, baseline.path), bytes, trustedRoot);
  }
  validatePinnedBaselines(output);
  return baselines.length;
}

if (require.main === module) {
  try {
    console.log(`Prepared ${prepareBaselines(sourceRoot, outputRoot, workspaceRoot)} exact pinned Phase 173 baselines.`);
  } catch (error) {
    console.error(`Phase 173 baseline preparation failed: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { prepareBaselines };
