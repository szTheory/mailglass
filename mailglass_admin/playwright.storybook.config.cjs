const { defineConfig } = require("@playwright/test");
const crypto = require("node:crypto");

process.env.STORYBOOK_AXE_EXECUTION_TOKEN ||= crypto.randomUUID();

const baseURL = process.env.STORYBOOK_BASE_URL;

if (!baseURL) {
  throw new Error("STORYBOOK_BASE_URL must point at the isolated Demo service");
}

module.exports = defineConfig({
  testDir: "./e2e",
  testMatch: "storybook-axe.spec.js",
  timeout: 90_000,
  expect: { timeout: 10_000 },
  workers: 1,
  reporter: "list",
  use: {
    baseURL,
    viewport: { width: 1280, height: 900 },
    trace: "retain-on-failure"
  }
});
