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
    timeout: 120_000,
    reuseExistingServer: !process.env.CI
  }
});
