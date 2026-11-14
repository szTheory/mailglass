"use strict";

const path = require("node:path");
const fs = require("node:fs");

const EVIDENCE_ROOT = path.resolve(__dirname, "../../tmp/demo_browser_evidence");

function resolveEvidenceOutputPath(candidate) {
  const resolved = candidate ? path.resolve(candidate) : EVIDENCE_ROOT;
  if (resolved !== EVIDENCE_ROOT && !resolved.startsWith(`${EVIDENCE_ROOT}${path.sep}`)) {
    throw new Error(`Demo browser evidence output must stay under ${EVIDENCE_ROOT}`);
  }
  // A lexical prefix alone permits a directory inside the root to redirect
  // writes (or retained-evidence replacement) to an unrelated directory.
  let current = path.parse(resolved).root;
  for (const part of resolved.slice(current.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    try {
      if (fs.lstatSync(current).isSymbolicLink()) {
        throw new Error(`Demo browser evidence path contains a symlink: ${current}`);
      }
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
  return resolved;
}

module.exports = { resolveEvidenceOutputPath };
