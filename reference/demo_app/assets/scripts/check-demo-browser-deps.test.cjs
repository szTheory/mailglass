const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const { validatePackageManifest } = require("./check-demo-browser-deps.cjs");
const root = path.resolve(__dirname, "../../../../");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const packageJson = JSON.parse(read("reference/demo_app/assets/package.json"));
const lock = JSON.parse(read("reference/demo_app/assets/package-lock.json"));
const clone = (value) => JSON.parse(JSON.stringify(value));

test("accepts the checked-in package manifest and exact lock", () => {
  assert.equal(validatePackageManifest(packageJson, lock), true);
});

for (const [name, mutate] of [
  ["extra package", (pkg, currentLock) => { currentLock.packages["node_modules/extra"] = {}; }],
  ["missing package", (_pkg, currentLock) => { delete currentLock.packages["node_modules/fsevents"]; }],
  ["root spec", (pkg) => { pkg.devDependencies["@playwright/test"] = "^1.60.0"; }],
  ["root install dependency", (pkg) => { pkg.dependencies = { "surprise-package": "*" }; }],
  ["version", (_pkg, currentLock) => { currentLock.packages["node_modules/playwright"].version = "1.59.1"; }],
  ["tarball URL", (_pkg, currentLock) => { currentLock.packages["node_modules/playwright-core"].resolved = "https://example.invalid/playwright-core.tgz"; }],
  ["SRI", (_pkg, currentLock) => { currentLock.packages["node_modules/@playwright/test"].integrity = "sha512-invalid"; }],
  ["dependency edge", (_pkg, currentLock) => { currentLock.packages["node_modules/playwright"].optionalDependencies.fsevents = "2.3.3"; }],
  ["install metadata", (_pkg, currentLock) => { currentLock.packages["node_modules/fsevents"].hasInstallScript = false; }],
  ["unexpected metadata", (_pkg, currentLock) => { currentLock.packages["node_modules/playwright"].funding = { url: "https://example.invalid" }; }]
]) {
  test(`rejects ${name} drift`, () => {
    const pkg = clone(packageJson);
    const currentLock = clone(lock);
    mutate(pkg, currentLock);
    assert.throws(() => validatePackageManifest(pkg, currentLock));
  });
}

test("all four demo browser npm ci sites run the same gate immediately first", () => {
  const dockerfile = read("reference/demo_app/Dockerfile");
  assert.match(dockerfile, /COPY reference\/demo_app\/assets\/scripts\/check-demo-browser-deps\.cjs \/tmp\/mailglass-demo-assets\/scripts\//);
  assert.match(dockerfile, /node \/tmp\/mailglass-demo-assets\/scripts\/check-demo-browser-deps\.cjs --lock-only \\\n\s+&& npm --prefix \/tmp\/mailglass-demo-assets ci/);

  const compose = read("compose.demo.yml");
  assert.match(compose, /node assets\/scripts\/check-demo-browser-deps\.cjs --lock-only\s+&& npm --prefix assets ci/);

  const wrapper = read("scripts/run_demo_browser_evidence.sh");
  assert.match(wrapper, /node assets\/scripts\/check-demo-browser-deps\.cjs --lock-only && npm --prefix assets ci/);

  const mix = read("reference/demo_app/mix.exs");
  assert.match(mix, /setup: \[\s*"deps\.get",\s*"ecto\.setup",\s*"cmd node assets\/scripts\/check-demo-browser-deps\.cjs --lock-only",\s*"cmd npm --prefix assets ci/);
});

test("existing advisory job audits the exact lock before browser evidence run", () => {
  const workflow = read(".github/workflows/ci.yml");
  const start = workflow.indexOf("  demo_browser_evidence:");
  const end = workflow.indexOf("\n  preview_capture_advisory:", start);
  assert.notEqual(start, -1);
  const job = workflow.slice(start, end);
  const audit = job.indexOf("npm --prefix reference/demo_app/assets audit --package-lock-only --audit-level=high");
  const run = job.indexOf("bash scripts/run_demo_browser_evidence.sh");
  assert.ok(audit >= 0 && run > audit, "lock audit must precede browser evidence run");
});
