const { defineConfig } = require("@playwright/test");

const port = process.env.PORT || "4015";
const baseURL = process.env.DEMO_BASE_URL || `http://127.0.0.1:${port}`;
const externalServer = Boolean(process.env.DEMO_BASE_URL);

module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["list"]] : "list",
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
