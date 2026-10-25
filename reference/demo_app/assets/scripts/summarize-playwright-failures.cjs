#!/usr/bin/env node
// Print each non-passing test from a Playwright JSON report so a failed CI run
// names what broke. The evidence artifact is only uploaded on success.
const fs = require("node:fs");

const reportPath = process.argv[2];
let report;
try {
  report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
} catch (error) {
  console.error(`Playwright report unreadable (${reportPath}): ${error.message}`);
  process.exit(0);
}

const stripAnsi = (text) => text.replace(/\u001b\[[0-9;]*m/g, "");
const failures = [];

function walk(suite, file) {
  for (const spec of suite.specs || []) {
    for (const test of spec.tests || []) {
      const results = test.results || [];
      const last = results[results.length - 1] || {};
      if (last.status === "passed" || last.status === "skipped") continue;
      const message = stripAnsi((last.error && last.error.message) || "").split("\n").slice(0, 6).join("\n    ");
      failures.push(`${file}:${spec.line} › ${spec.title} [${last.status || "unknown"}]\n    ${message}`);
    }
  }
  for (const child of suite.suites || []) walk(child, file);
}

for (const suite of report.suites || []) walk(suite, suite.file || suite.title);
for (const error of report.errors || []) failures.push(`(global) ${stripAnsi(error.message || "").split("\n")[0]}`);

console.error(failures.length === 0 ? "Playwright report lists no failing tests." : `Playwright failures (${failures.length}):\n${failures.join("\n")}`);
