const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const repoRoot = path.resolve(__dirname, "../..");
const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");

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
