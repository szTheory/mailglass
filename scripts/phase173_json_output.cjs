"use strict";

const { spawnSync } = require("node:child_process");
const path = require("node:path");

function writeJson(outputPath, value, trustedRoot = process.cwd()) {
  const helper = path.join(__dirname, "phase173_json_output.py");
  const result = spawnSync("python3", [helper, trustedRoot, outputPath], {
    input: `${JSON.stringify(value, null, 2)}\n`,
    encoding: "utf8",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const detail = (result.stderr || "").trim();
    throw new Error(detail || `Secure JSON output failed with status ${result.status}`);
  }
}

function writeFileExclusive(outputPath, bytes, trustedRoot = process.cwd()) {
  const helper = path.join(__dirname, "phase173_json_output.py");
  const result = spawnSync("python3", [helper, trustedRoot, outputPath, "--exclusive-file"], {
    input: bytes,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const detail = (result.stderr || Buffer.alloc(0)).toString("utf8").trim();
    throw new Error(detail || `Secure file output failed with status ${result.status}`);
  }
}

function writePinnedFile(outputPath, bytes, trustedRoot = process.cwd()) {
  const helper = path.join(__dirname, "phase173_json_output.py");
  const result = spawnSync("python3", [helper, trustedRoot, outputPath, "--pinned-file"], {
    input: bytes,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const detail = (result.stderr || Buffer.alloc(0)).toString("utf8").trim();
    throw new Error(detail || `Pinned file output failed with status ${result.status}`);
  }
}

module.exports = { writeJson, writeFileExclusive, writePinnedFile };
