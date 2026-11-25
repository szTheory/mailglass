// Playwright config for the before-catalog capture spec (Phase 180, BRPIPE-03).
//
// Why a second config: the demo config's `testDir: "./e2e"` is what the advisory
// `demo_browser_evidence` lane and `make demo-e2e` run, so a capture spec placed in
// `./e2e` would run there. The catalog producer lives in `./catalog` and is run only by
// `catalog/capture-before-catalog.cjs`, never by CI.
//
// The catalog always targets an explicit, already running demo (the driver restarts it,
// resets it and seeds it first), so there is no `webServer` block and `DEMO_BASE_URL`
// is required.
const { defineConfig } = require("@playwright/test");

const baseURL = process.env.DEMO_BASE_URL;
if (typeof baseURL !== "string" || baseURL.length === 0) {
  throw new Error(
    "DEMO_BASE_URL must name the running evidence demo (for example http://127.0.0.1:4015/): " +
      "the before-catalog never starts a server."
  );
}

module.exports = defineConfig({
  testDir: "./catalog",
  timeout: 60_000,
  expect: { timeout: 5_000 },
  retries: 0,
  // Serial on purpose, as in the demo config: the driver resets and seeds ONE shared demo
  // database before the spec runs, and the captures read rows by id from that state. A
  // second worker would only add contention against the same server. This spec never
  // calls the destructive reset endpoint itself; the driver owns reset -> seed -> capture.
  workers: 1,
  reporter: "list",
  use: {
    baseURL,
    timezoneId: "UTC",
    locale: "en-US",
    deviceScaleFactor: 1,
    reducedMotion: "reduce"
  }
});
