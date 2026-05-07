const { defineConfig } = require("@playwright/test");

const port = process.env.BROWSER_SERVER_PORT || "4101";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${port}`;
const browserLoginPath = `/ops/browser-login?tenant_id=browser-tenant&return_to=${encodeURIComponent(
  "/ops/mail?tenant_id=browser-tenant"
)}`;

module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: {
    timeout: 5_000
  },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["list"]] : "list",
  use: {
    baseURL,
    trace: "on-first-retry"
  },
  webServer: {
    command: 'MIX_ENV=test mix run --no-halt -e "MailglassAdmin.TestSupport.OperatorBrowserServer.run!()"',
    cwd: __dirname,
    env: {
      ...process.env,
      MIX_ENV: "test",
      BROWSER_SERVER_PORT: port
    },
    url: `${baseURL}${browserLoginPath}`,
    // CI-cold start runs `mix run` which compiles every transitive dep in
    // test env (incl. Phoenix, LiveView, mailglass core, mailglass_admin)
    // plus runs all 5 mailglass core migrations (citext extension, append-
    // only events trigger, suppression store, etc.) before the endpoint
    // binds to `port`. 120s was tight; 300s gives a comfortable margin
    // without masking real hangs. stdout/stderr from `mix run` is surfaced
    // by OperatorBrowserServer.run!/0 step-prints so any stall is visible.
    timeout: 300_000,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    stderr: "pipe"
  }
});
