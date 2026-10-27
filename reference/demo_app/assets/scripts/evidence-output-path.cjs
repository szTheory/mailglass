"use strict";

const path = require("node:path");

const EVIDENCE_ROOT = path.resolve(__dirname, "../../tmp/demo_browser_evidence");

function resolveEvidenceOutputPath(candidate) {
  const resolved = candidate ? path.resolve(candidate) : EVIDENCE_ROOT;
  if (resolved !== EVIDENCE_ROOT && !resolved.startsWith(`${EVIDENCE_ROOT}${path.sep}`)) {
    throw new Error(`Demo browser evidence output must stay under ${EVIDENCE_ROOT}`);
  }
  return resolved;
}

module.exports = { resolveEvidenceOutputPath };
