const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { pathToFileURL } = require("node:url");
const { chromium } = require("playwright");

const repoRoot = path.resolve(__dirname, "../..");
const assetCommit = "7781b4b1ceeca940e5f892530b1cf05430b54d7c";
const packageDirs = {
  core: { root: repoRoot, docs: path.join(repoRoot, "doc") },
  admin: {
    root: path.join(repoRoot, "mailglass_admin"),
    docs: path.join(repoRoot, "mailglass_admin/doc"),
  },
  inbound: {
    root: path.join(repoRoot, "mailglass_inbound"),
    docs: path.join(repoRoot, "mailglass_inbound/doc"),
  },
};

function pinnedLockups() {
  const pin = JSON.parse(fs.readFileSync(path.join(repoRoot, "brandbook/brand.pin.json"), "utf8"));
  const assets = new Map();

  for (const [assetPath, fragment] of [
    ["brandbook/v2/mailglass-lockup-light.svg", "#gh-light-mode-only"],
    ["brandbook/v2/mailglass-lockup-dark.svg", "#gh-dark-mode-only"],
  ]) {
    const entry = pin.shipped.find(({ to }) => to === assetPath);
    assert.ok(entry, `missing shipped pin row for ${assetPath}`);
    const bytes = execFileSync("git", ["show", `${assetCommit}:${assetPath}`], {
      cwd: repoRoot,
      encoding: "buffer",
    });
    const sha256 = require("node:crypto").createHash("sha256").update(bytes).digest("hex");
    assert.equal(bytes.byteLength, entry.bytes, `${assetPath} byte count differs from the pin`);
    assert.equal(sha256, entry.sha256, `${assetPath} digest differs from the pin`);
    assert.deepEqual(bytes, fs.readFileSync(path.join(repoRoot, assetPath)));

    const fullUrl = `https://raw.githubusercontent.com/szTheory/mailglass/${assetCommit}/${assetPath}${fragment}`;
    // HTTP requests do not transmit URL fragments; use only the exact immutable origin/path.
    const requestUrl = new URL(fullUrl);
    requestUrl.hash = "";
    assets.set(requestUrl.href, { bytes, fullUrl });
  }

  return assets;
}

async function verifyScenario(browser, packageName, colorScheme, theme) {
  const { docs } = packageDirs[packageName];
  const readmePath = path.join(docs, "README.html");
  assert.ok(fs.existsSync(readmePath), `${packageName} docs are missing README.html; build docs first`);
  const pinned = pinnedLockups();
  const context = await browser.newContext({
    colorScheme,
    viewport: { width: 1200, height: 900 },
  });
  const page = await context.newPage();
  const abortedNetwork = [];

  await page.route("**/*", async (route) => {
    const requestUrl = route.request().url();
    const asset = pinned.get(requestUrl);

    if (asset) {
      await route.fulfill({
        status: 200,
        contentType: "image/svg+xml",
        body: asset.bytes,
      });
      return;
    }

    if (requestUrl.startsWith("file:") || requestUrl.startsWith("data:")) {
      await route.continue();
      return;
    }

    abortedNetwork.push(requestUrl);
    await route.abort();
  });

  await page.goto(pathToFileURL(readmePath).href, { waitUntil: "domcontentloaded" });

  const headings = await page.locator(".content-inner h1").allTextContents();
  assert.deepEqual(headings.map((text) => text.trim()), ["mailglass"]);
  const lockups = page.locator('.content-inner img[src*="#gh-"]');
  assert.equal(await lockups.count(), 2, "README must contain both theme lockups");

  const sourceRefs = await lockups.evaluateAll((images) => images.map((image) => image.getAttribute("src")));
  assert.deepEqual(
    sourceRefs,
    [...pinned.values()].map(({ fullUrl }) => fullUrl),
    "generated README lockups must keep both exact immutable refs and renderer fragments",
  );

  await page.locator(".display-settings").click();
  const themeSelect = page.locator('#settings-modal-content select[name="theme"]');
  await themeSelect.waitFor({ state: "visible" });
  await themeSelect.selectOption(theme);
  await page.waitForFunction((expected) => document.body.classList.contains("dark") === (expected === "dark"), theme);

  const sidebarMark = page.locator(".sidebar-projectImage img");
  await sidebarMark.evaluate((image) => image.decode());
  const sidebarSrc = await sidebarMark.getAttribute("src");
  assert.ok(sidebarSrc.endsWith(`mailglass-mark-${theme}.svg`), `${packageName} sidebar mark did not follow the native ${theme} setting`);

  const visibleLockups = await lockups.evaluateAll((images) =>
    images
      .filter((image) => getComputedStyle(image).display !== "none")
      .map((image) => ({
        alt: image.getAttribute("alt"),
        width: image.getBoundingClientRect().width,
        height: image.getBoundingClientRect().height,
        naturalWidth: image.naturalWidth,
        naturalHeight: image.naturalHeight,
      })),
  );
  assert.equal(visibleLockups.length, 1, "only the theme-matched README lockup should be visible");
  assert.equal(visibleLockups[0].alt, "mailglass");
  assert.ok(visibleLockups[0].naturalWidth > 0 && visibleLockups[0].naturalHeight > 0, "README lockup did not decode");

  await page.setViewportSize({ width: 375, height: 812 });
  await page.waitForTimeout(50);
  const narrow = await page.evaluate(() => ({
    viewportWidth: window.innerWidth,
    documentWidth: document.documentElement.scrollWidth,
    image: [...document.querySelectorAll('.content-inner img[src*="#gh-"]')]
      .filter((image) => getComputedStyle(image).display !== "none")
      .map((image) => ({
        width: image.getBoundingClientRect().width,
        height: image.getBoundingClientRect().height,
        naturalWidth: image.naturalWidth,
        naturalHeight: image.naturalHeight,
      }))[0],
  }));
  assert.ok(narrow.image.width >= 96, "the visible lockup must remain at least 96 px wide");
  assert.ok(narrow.image.width <= narrow.viewportWidth, "the lockup must fit its narrow content width");
  assert.ok(narrow.documentWidth <= narrow.viewportWidth, "the README must not cause horizontal scrolling");
  const renderedRatio = narrow.image.width / narrow.image.height;
  const sourceRatio = narrow.image.naturalWidth / narrow.image.naturalHeight;
  assert.ok(Math.abs(renderedRatio - sourceRatio) < 0.02, "the README lockup was stretched or cropped");

  const tagline = await page.locator(".content-inner").innerText();
  assert.ok(tagline.includes("See your email before it ships. Trace it after."), "tagline must stay separate from the artwork");
  assert.ok(abortedNetwork.every((url) => /^https?:/.test(url)), "only non-local network requests may be aborted");
  await context.close();
}

async function verifyPackage(browser, packageName) {
  for (const [colorScheme, theme] of [
    ["dark", "light"],
    ["light", "dark"],
  ]) {
    await verifyScenario(browser, packageName, colorScheme, theme);
  }
}

async function main(args) {
  const all = args.includes("--all");
  const packageIndex = args.indexOf("--package");
  const packageName = packageIndex >= 0 ? args[packageIndex + 1] : null;
  const packages = all ? Object.keys(packageDirs) : packageName ? [packageName] : [];

  assert.ok(packages.length > 0, "usage: node mailglass_admin/e2e/docs-theme-contract.cjs --package core|admin|inbound|--all");
  for (const name of packages) assert.ok(packageDirs[name], `unknown package: ${name}`);

  const browser = await chromium.launch({ headless: true });
  try {
    for (const name of packages) {
      await verifyPackage(browser, name);
      process.stdout.write(`[docs-theme-contract] ${name}: both native themes, pinned images, and narrow layout pass\n`);
    }
  } finally {
    await browser.close();
  }
}

main(process.argv.slice(2)).catch((error) => {
  process.stderr.write(`${error.stack || error}\n`);
  process.exitCode = 1;
});
