const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const repoRoot = path.resolve(__dirname, "../..");
const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");
const { parseCliArgs, outputPathsFor, validateOutputPaths } = require("./docs-theme-contract.cjs");

test("explicit output root maps all three packages without falling back to checkout docs", () => {
  const outputRoot = path.join(os.tmpdir(), "mailglass-generated-docs");
  const options = parseCliArgs(["--all", "--output-root", outputRoot]);
  const outputs = outputPathsFor(options.packages, options.outputRoot);

  assert.deepEqual(options.packages, ["core", "admin", "inbound"]);
  assert.equal(options.outputRoot, path.resolve(outputRoot));
  for (const packageName of options.packages) {
    assert.equal(outputs[packageName].docs, path.join(path.resolve(outputRoot), packageName));
    assert.equal(outputs[packageName].readmePath, path.join(path.resolve(outputRoot), packageName, "README.html"));
  }
});

test("missing package output is rejected with its name and README path", (t) => {
  const outputRoot = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-docs-contract-"));
  t.after(() => fs.rmSync(outputRoot, { recursive: true, force: true }));
  fs.mkdirSync(path.join(outputRoot, "core"), { recursive: true });
  fs.writeFileSync(path.join(outputRoot, "core", "README.html"), "<html></html>");

  const options = parseCliArgs(["--all", "--output-root", outputRoot]);
  const outputs = outputPathsFor(options.packages, options.outputRoot);

  assert.throws(() => validateOutputPaths(outputs), /admin docs output is missing README\.html/);
});

test("CLI rejects a missing README before attempting to launch Chromium", (t) => {
  const outputRoot = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-docs-cli-"));
  t.after(() => fs.rmSync(outputRoot, { recursive: true, force: true }));
  const contractPath = path.join(__dirname, "docs-theme-contract.cjs");
  const result = spawnSync(process.execPath, [contractPath, "--all", "--output-root", outputRoot], {
    cwd: repoRoot,
    encoding: "utf8",
  });

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /core docs output is missing README\.html/);
  assert.doesNotMatch(result.stderr, /browserType\.launch|chrome-headless/);
});

test("CLI rejects missing output-root path and preserves legacy package selection", () => {
  assert.throws(() => parseCliArgs(["--all", "--output-root"]), /--output-root requires a path/);
  assert.deepEqual(parseCliArgs(["--package", "admin"]).packages, ["admin"]);
  assert.equal(outputPathsFor(["core"], null).core.docs, path.join(repoRoot, "doc"));
});

test("core README uses one lowercase heading, immutable theme lockups, and a separate tagline", () => {
  const header = readme.split(/^## /m, 1)[0];
  const headings = [...header.matchAll(/^# .*$/gm)].map(([heading]) => heading);
  const imageUrls = [...header.matchAll(/<img\b[^>]*\bsrc=["']([^"']+)["'][^>]*>/gi)].map(
    ([, src]) => src,
  );

  assert.deepEqual(headings, ["# mailglass"]);
  assert.deepEqual(imageUrls, [
    "https://raw.githubusercontent.com/szTheory/mailglass/7781b4b1ceeca940e5f892530b1cf05430b54d7c/brandbook/v2/mailglass-lockup-light.svg#gh-light-mode-only",
    "https://raw.githubusercontent.com/szTheory/mailglass/7781b4b1ceeca940e5f892530b1cf05430b54d7c/brandbook/v2/mailglass-lockup-dark.svg#gh-dark-mode-only",
  ]);
  assert.match(header, /alt=["']mailglass["']/);
  assert.match(header, /See your email before it ships\. Trace it after\./);
});
