#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

// Reviewed upstream repositories: microsoft/playwright (all Playwright packages),
// fsevents/fsevents (the optional Darwin-only package).
const EXPECTED_PACKAGES = Object.freeze({
  "node_modules/@playwright/test": Object.freeze({
    version: "1.60.0",
    resolved: "https://registry.npmjs.org/@playwright/test/-/test-1.60.0.tgz",
    integrity: "sha512-O71yZIbAh/PxDMNGns37GHBIfrVkEVyn+AXyIa5dOTfb4/xNvRWV+Vv/NMbNCtODB/pO7vLlF2OTmMVLhmr7Ag==",
    dev: true,
    license: "Apache-2.0",
    dependencies: { playwright: "1.60.0" },
    bin: { playwright: "cli.js" },
    engines: { node: ">=18" }
  }),
  "node_modules/playwright": Object.freeze({
    version: "1.60.0",
    resolved: "https://registry.npmjs.org/playwright/-/playwright-1.60.0.tgz",
    integrity: "sha512-hheHdokM8cdqCb0lcE3s+zT4t4W+vvjpGxsZlDnikarzx8tSzMebh3UiFtgqwFwnTnjYQcsyMF8ei2mCO/tpeA==",
    dev: true,
    license: "Apache-2.0",
    dependencies: { "playwright-core": "1.60.0" },
    bin: { playwright: "cli.js" },
    engines: { node: ">=18" },
    optionalDependencies: { fsevents: "2.3.2" }
  }),
  "node_modules/playwright-core": Object.freeze({
    version: "1.60.0",
    resolved: "https://registry.npmjs.org/playwright-core/-/playwright-core-1.60.0.tgz",
    integrity: "sha512-9bW6zvX/m0lEbgTKJ6YppOKx8H3VOPBMOCFh2irXFOT4BbHgrx5hPjwJYLT40Lu+4qtD36qKc/Hn56StUW57IA==",
    dev: true,
    license: "Apache-2.0",
    bin: { "playwright-core": "cli.js" },
    engines: { node: ">=18" }
  }),
  "node_modules/fsevents": Object.freeze({
    version: "2.3.2",
    resolved: "https://registry.npmjs.org/fsevents/-/fsevents-2.3.2.tgz",
    integrity: "sha512-xiqMQR4xAeHTuB9uWm+fFRcIOgKBMiOBP+eXiyT7jsgVCq1bkVygt00oASowB7EdtpOHaaPgKt812P9ab+DDKA==",
    dev: true,
    hasInstallScript: true,
    license: "MIT",
    optional: true,
    os: ["darwin"],
    engines: { node: "^8.16.0 || ^10.6.0 || >=11.0.0" }
  })
});

const ROOT_NAME = "mailglass-demo-browser-evidence";
const ROOT_SPEC = "^1.59.1";

function sameJson(actual, expected, label) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error(`${label} does not match the audited exact lock contract`);
}

function validatePackageManifest(packageJson, lock) {
  if (!packageJson || packageJson.name !== ROOT_NAME || packageJson.private !== true) {
    throw new Error("package.json root name/private metadata changed");
  }
  sameJson(Object.keys(packageJson).sort(), ["devDependencies", "name", "private", "scripts"], "package.json install metadata");
  sameJson(packageJson.devDependencies, { "@playwright/test": ROOT_SPEC }, "package.json devDependencies");
  sameJson(packageJson.scripts, {
    "test:e2e": "playwright test --config=playwright.config.cjs",
    "test:e2e:ci": "playwright test --config=playwright.config.cjs && node scripts/check-demo-browser-evidence.cjs"
  }, "package.json scripts");
  if (!lock || lock.lockfileVersion !== 3 || lock.name !== ROOT_NAME || !lock.packages || typeof lock.packages !== "object") {
    throw new Error("package-lock.json root metadata changed");
  }
  const root = lock.packages[""];
  if (!root || root.name !== ROOT_NAME) throw new Error("package-lock.json root name changed");
  sameJson(root.devDependencies, { "@playwright/test": ROOT_SPEC }, "package-lock root devDependencies");
  sameJson(Object.keys(lock.packages).sort(), ["", ...Object.keys(EXPECTED_PACKAGES)].sort(), "package inventory");
  for (const [packagePath, expected] of Object.entries(EXPECTED_PACKAGES)) {
    sameJson(lock.packages[packagePath], expected, packagePath);
  }
  sameJson(Object.keys(root).sort(), ["devDependencies", "name"], "package-lock root install metadata");
  sameJson(lock.requires, true, "package-lock requires flag");
  sameJson(Object.keys(lock).sort(), ["lockfileVersion", "name", "packages", "requires"], "package-lock top-level metadata");
  return true;
}

function main() {
  if (process.argv.length !== 3 || process.argv[2] !== "--lock-only") {
    throw new Error("usage: node check-demo-browser-deps.cjs --lock-only");
  }
  const assetsDir = path.resolve(__dirname, "..");
  const packageJson = JSON.parse(fs.readFileSync(path.join(assetsDir, "package.json"), "utf8"));
  const lock = JSON.parse(fs.readFileSync(path.join(assetsDir, "package-lock.json"), "utf8"));
  validatePackageManifest(packageJson, lock);
  console.log("Demo browser dependency lock matches the audited exact package set.");
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(`Demo browser dependency gate failed: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { EXPECTED_PACKAGES, validatePackageManifest };
