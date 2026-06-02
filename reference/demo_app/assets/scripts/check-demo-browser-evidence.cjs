const fs = require("fs");
const path = require("path");

const evidenceDir = path.join(__dirname, "..", "..", "tmp", "demo_browser_evidence");
const reportPath = path.join(evidenceDir, "playwright-report.json");
const checkpointPath = path.join(evidenceDir, "checkpoint.json");

const requiredTests = [
  "dashboard links to preview and operator surfaces",
  "outbound operator opens with seeded delivery evidence",
  "inbound operator opens with seeded support mailbox evidence"
];

const coveredRoutes = [
  "/",
  "/dev/mail",
  "/ops/mail?tenant_id=northstar",
  "/ops/mail/inbound?tenant_id=northstar"
];

function collectTests(suite, acc = []) {
  for (const spec of suite.specs || []) {
    for (const test of spec.tests || []) {
      acc.push({
        title: spec.title,
        status: test.outcome || test.status,
        expectedStatus: test.expectedStatus,
        ok: (test.outcome || test.status) === "expected"
      });
    }
  }

  for (const child of suite.suites || []) {
    collectTests(child, acc);
  }

  return acc;
}

if (!fs.existsSync(reportPath)) {
  throw new Error(`Missing Playwright JSON report: ${reportPath}`);
}

const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
const tests = (report.suites || []).flatMap((suite) => collectTests(suite));
const byTitle = new Map(tests.map((test) => [test.title, test]));
const missing = requiredTests.filter((title) => !byTitle.has(title));
const failed = requiredTests
  .map((title) => byTitle.get(title))
  .filter((test) => test && !test.ok);

const status = missing.length === 0 && failed.length === 0 ? "passed" : "failed";
const checkpoint = {
  schema_version: "demo_browser_evidence.v1",
  generated_at: new Date().toISOString(),
  status,
  base_url: process.env.DEMO_BASE_URL || "http://127.0.0.1:4015",
  reset_token_present: Boolean(process.env.DEMO_EVIDENCE_RESET_TOKEN),
  routes_covered: coveredRoutes,
  tests: requiredTests.map((title) => ({
    title,
    status: byTitle.get(title)?.status || "missing"
  })),
  failures: {
    missing,
    failed: failed.map((test) => test.title)
  }
};

fs.mkdirSync(evidenceDir, { recursive: true });
fs.writeFileSync(checkpointPath, `${JSON.stringify(checkpoint, null, 2)}\n`);

if (status !== "passed") {
  console.error(`Demo browser evidence failed. Checkpoint: ${checkpointPath}`);
  process.exit(1);
}

console.log(`Demo browser evidence passed. Checkpoint: ${checkpointPath}`);
