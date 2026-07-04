const path = require("path");
const { defineConfig } = require("@playwright/test");

const port = process.env.PORT || "4015";
const baseURL = process.env.DEMO_BASE_URL || `http://127.0.0.1:${port}`;
const externalServer = Boolean(process.env.DEMO_BASE_URL);
const evidenceDir = path.join(__dirname, "..", "tmp", "demo_browser_evidence");

module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  retries: process.env.CI ? 1 : 0,
  // Every spec file (demo / cohort / persona-screenshots) fires the DESTRUCTIVE
  // `POST /demo/evidence/reset` (TRUNCATE ... RESTART IDENTITY CASCADE + reseed)
  // in its beforeEach/beforeAll against the ONE shared demo DB. `fullyParallel`
  // is off, which serializes tests WITHIN a file — but Playwright still runs
  // separate FILES in parallel workers (CI has >1 core). A sibling file's reset
  // then wipes + reseeds inbound records (new UUIDs) in the window between
  // demo.spec.js capturing the first `inbound-record-row` id and navigating to
  // its detail — the captured UUID no longer resolves, so `Detail.fetch` returns
  // nil and `inbound-detail-header` never renders (observed as a "flaky" retry
  // pass). The advisory xact-lock only orders the reset transactions; it cannot
  // stop a reset from invalidating an id another test already read. Pin a single
  // worker so the destructive shared-DB seam is truly serial across files.
  workers: 1,
  reporter: process.env.CI
    ? [
        ["github"],
        ["list"],
        ["json", { outputFile: path.join(evidenceDir, "playwright-report.json") }]
      ]
    : "list",
  use: {
    baseURL,
    trace: "on-first-retry"
  },
  webServer: externalServer
    ? undefined
    : {
        command: "mix ecto.setup && mix phx.server",
        cwd: "..",
        env: {
          ...process.env,
          MIX_ENV: "dev",
          PORT: port
        },
        url: baseURL,
        timeout: 300_000,
        reuseExistingServer: !process.env.CI,
        stdout: "pipe",
        stderr: "pipe"
      }
});
