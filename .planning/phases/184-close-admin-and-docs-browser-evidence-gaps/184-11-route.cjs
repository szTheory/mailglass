#!/usr/bin/env node
"use strict";

const path = require("node:path");

const OWNER = path.resolve(__dirname, "../../..");
const APPROVED_PATCH_RELATIVE = ".planning/phases/184-close-admin-and-docs-browser-evidence-gaps/184-07-CANDIDATE.patch";
const APPROVED_PATCH_SHA256 = "b2c7c557cd21d1c5a82633a94e081005f68bd70412f4f3e3e145d02525206907";

function resolveApprovedPatch() {
  return { path: null, sha256: null, bytes: null };
}

function checksumObservedHex(expectedHex, observedRaw) {
  return null;
}

function validateRegistryReceipt(receipt, expectedRows, expectedCachePath) {
  return { schema: null, repoUrl: null, recordsChecked: 0, records: [] };
}

if (require.main === module) {
  console.error("route controller is not implemented");
  process.exitCode = 2;
}

module.exports = {
  APPROVED_PATCH_RELATIVE,
  APPROVED_PATCH_SHA256,
  OWNER,
  checksumObservedHex,
  resolveApprovedPatch,
  validateRegistryReceipt,
};
