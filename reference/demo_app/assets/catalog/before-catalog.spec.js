// before-catalog.spec.js: the capture producer for the Phase 180 "before" catalog (BRPIPE-03).
//
// This is an EVIDENCE PRODUCER, not a test of the product and not a pixel-diff baseline
// (D-18). It is run only by `catalog/capture-before-catalog.cjs`, which owns the order
// restart -> reset -> catalog seed -> this spec -> validate -> promote. This spec NEVER
// calls the destructive reset endpoint. It lives outside `./e2e` on purpose (F9): anything
// in `./e2e` runs in the advisory `demo_browser_evidence` lane and `make demo-e2e`.
//
// Environment (all set by the driver; no defaults, so a hand run fails loudly):
//   DEMO_BASE_URL        the running evidence demo, for example http://127.0.0.1:4015/
//   CATALOG_STAGING_DIR  absolute path of the git-ignored staging directory to write into
//   CATALOG_CASES_FILE   cases.json written by the driver from `CatalogSeed.seed!/0`
//   CATALOG_ONLY         optional: comma-separated capture ids, or `smoke`
//   DEMO_CANDIDATE_REVISION  optional: the source revision (else `git rev-parse HEAD`)
//
// Every capture (D-19): the theme cookie `mailglass_admin_theme_v2` plus a matching
// `emulateMedia` colour scheme and reduced motion, set BEFORE navigation; wait for the
// connected LiveView (never `networkidle`); wait for the Inter face to be loaded
// (`document.fonts.check`, since the admin CSS uses `font-display: swap`); screenshot with
// `animations: "disabled"` and `caret: "hide"` at device scale factor 1, timezone UTC and
// locale en-US (the config sets the context options). The resolved `<html data-theme>` is
// recorded per capture, with the number of `[data-theme]` elements other than the root.

const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const REPO_ROOT = path.resolve(__dirname, "../../../..");
const THEME_COOKIE = "mailglass_admin_theme_v2";
const VIEWPORT_HEIGHT = 900;
const RELATIVE_TIME = /\bago\b|just now/i;
const STOP_LINE = /next try at|will retry/i;
const CSS_PATH = "mailglass_admin/priv/static/app.css";
const HOOKS_PATH = "mailglass_admin/priv/static/hooks.js";

function requireEnv(name) {
  const value = process.env[name];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${name} is required: run this spec through catalog/capture-before-catalog.cjs`);
  }
  return value;
}

const BASE_URL = requireEnv("DEMO_BASE_URL");
const STAGING = path.resolve(requireEnv("CATALOG_STAGING_DIR"));
const CASES_FILE = requireEnv("CATALOG_CASES_FILE");

const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const md5 = (bytes) => crypto.createHash("md5").update(bytes).digest("hex");

// ---------------------------------------------------------------------------------------
// Capture matrix. `prepare(page, ctx)` navigates to the screen in its final visible state.
// ---------------------------------------------------------------------------------------

const SELF_TEST_ID = "preview-index__any__default__1440__light";

function buildMatrix() {
  return [
    {
      id: SELF_TEST_ID,
      tier: "D",
      screen: "preview-index",
      fixture: "any",
      case: null,
      state: "default",
      viewport: 1440,
      theme: "light",
      prepare: (page) => openPage(page, "/dev/mail")
    }
  ];
}

// ---------------------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------------------

async function connected(page) {
  await page.locator("[data-phx-main].phx-connected").waitFor({ state: "visible" });
}

// Dev-only review surfaces are not session gated.
async function openPage(page, target) {
  await page.goto(target);
  await connected(page);
}

// Operator surfaces need a session: the human /demo/login entry, then the exact target.
// `return_to` is encoded so the nested query survives the redirect.
async function openOperator(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.goto(target);
  await connected(page);
}

// ---------------------------------------------------------------------------------------
// Readiness and probes
// ---------------------------------------------------------------------------------------

async function settle(page) {
  await connected(page);
  // `font-display: swap` means `document.fonts.ready` alone can resolve before Inter is
  // in use, so request the face explicitly and then assert that it is loaded.
  await page.evaluate(async () => {
    await document.fonts.load("400 16px Inter");
    await document.fonts.ready;
  });
  expect(
    await page.evaluate(() => document.fonts.check("400 16px Inter")),
    "the Inter 400 face must be loaded before a capture"
  ).toBe(true);
  // Timestamps render a placeholder bar until the local-time script marks them localized.
  await page.waitForFunction(
    () => !document.querySelector("time[data-local-time]:not([data-localized])")
  );
  await page.evaluate(
    () => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
  );
}

async function probe(page) {
  return page.evaluate(
    ({ relative, stop }) => {
      const text = document.body.innerText;
      const hits = (source) => {
        const re = new RegExp(source.pattern, source.flags);
        const found = [];
        for (const line of text.split("\n")) if (re.test(line)) found.push(line.trim().slice(0, 120));
        return found;
      };
      const root = document.documentElement;
      return {
        root_theme_attr: root.getAttribute("data-theme"),
        nested_theme_attr_count: [...document.querySelectorAll("[data-theme]")].filter(
          (element) => element !== root
        ).length,
        relative_time_hits: hits(relative),
        stop_line_hits: hits(stop),
        fonts_loaded: [...document.fonts]
          .filter((face) => face.status === "loaded")
          .map((face) => `${face.family.replaceAll('"', "")} ${face.weight} ${face.style}`)
          .sort()
      };
    },
    {
      relative: { pattern: RELATIVE_TIME.source, flags: RELATIVE_TIME.flags },
      stop: { pattern: STOP_LINE.source, flags: STOP_LINE.flags }
    }
  );
}

async function prepareContext(page, def) {
  await page.setViewportSize({ width: def.viewport, height: VIEWPORT_HEIGHT });
  await page.emulateMedia({ colorScheme: def.theme, reducedMotion: "reduce" });
  await page.context().addCookies([{ name: THEME_COOKIE, value: def.theme, url: BASE_URL }]);
}

// ---------------------------------------------------------------------------------------
// Staging output
// ---------------------------------------------------------------------------------------

function stagePath(...parts) {
  const resolved = path.resolve(STAGING, ...parts);
  if (resolved !== STAGING && !resolved.startsWith(`${STAGING}${path.sep}`)) {
    throw new Error(`staging write escapes the staging directory: ${resolved}`);
  }
  return resolved;
}

function writeStaged(relative, contents) {
  const target = stagePath(relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, contents);
}

// ---------------------------------------------------------------------------------------
// Source identity (the demo server runs on the host-visible repository via a bind mount)
// ---------------------------------------------------------------------------------------

function sourceRevision() {
  return (
    process.env.DEMO_CANDIDATE_REVISION ||
    execFileSync("git", ["rev-parse", "HEAD"], { cwd: REPO_ROOT, encoding: "utf8" }).trim()
  );
}

function gitBlob(revision, repoPath) {
  const sha = execFileSync("git", ["rev-parse", `${revision}:${repoPath}`], {
    cwd: REPO_ROOT,
    encoding: "utf8"
  }).trim();
  const bytes = execFileSync("git", ["show", `${revision}:${repoPath}`], {
    cwd: REPO_ROOT,
    encoding: null,
    maxBuffer: 64 * 1024 * 1024
  });
  return { sha, bytes };
}

// ---------------------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------------------

const MATRIX = buildMatrix();

function selectedMatrix() {
  const only = (process.env.CATALOG_ONLY || "").trim();
  if (only === "") return MATRIX;
  const ids =
    only === "smoke"
      ? require("./capture-before-catalog.cjs").CATALOG_SMOKE_IDS
      : only
          .split(",")
          .map((id) => id.trim())
          .filter(Boolean);
  const known = new Set(MATRIX.map((def) => def.id));
  const unknown = ids.filter((id) => !known.has(id));
  if (unknown.length > 0) {
    throw new Error(`CATALOG_ONLY names unknown capture ids: ${unknown.join(", ")}`);
  }
  return MATRIX.filter((def) => ids.includes(def.id));
}

const CASES = JSON.parse(fs.readFileSync(CASES_FILE, "utf8")).cases;

test("determinism self-test: the same screen captured twice is byte-identical", async ({ page }) => {
  const def = MATRIX.find((candidate) => candidate.id === SELF_TEST_ID);
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-catalog-selftest-"));
  const hashes = [];
  try {
    for (const attempt of [0, 1]) {
      await prepareContext(page, def);
      await def.prepare(page, { cases: CASES });
      await settle(page);
      const file = path.join(scratch, `attempt-${attempt}.png`);
      await page.screenshot({ path: file, fullPage: true, animations: "disabled", caret: "hide" });
      hashes.push(sha256(fs.readFileSync(file)));
    }
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
  writeStaged(
    "determinism.json",
    JSON.stringify({ self_test_id: SELF_TEST_ID, sha256: hashes, identical: hashes[0] === hashes[1] }, null, 2)
  );
  expect(hashes[1], "a double capture of the self-test screen must be byte-identical").toBe(hashes[0]);
});

test("served identity: the running demo serves the committed admin assets", async ({ page }) => {
  const revision = sourceRevision();
  await page.goto("/dev/mail");
  await connected(page);

  const cssHref = await page.evaluate(() => {
    const link = [...document.querySelectorAll('link[rel="stylesheet"]')]
      .map((element) => element.href)
      .find((href) => new URL(href).pathname.startsWith("/dev/mail/css-"));
    return link ? new URL(link).pathname : null;
  });
  expect(cssHref, "the page must link the mounted admin css bundle").toMatch(/^\/dev\/mail\/css-[a-f0-9]{32}$/);

  const cssResponse = await page.request.get(cssHref);
  expect(cssResponse.status()).toBe(200);
  const servedCss = await cssResponse.body();
  expect(md5(servedCss), "served css bytes must match the md5 in their own route").toBe(
    cssHref.match(/css-([a-f0-9]{32})$/)[1]
  );
  const diskCss = fs.readFileSync(path.join(REPO_ROOT, CSS_PATH));
  const gitCss = gitBlob(revision, CSS_PATH);

  const inlineJs = await page.evaluate(
    () =>
      [...document.querySelectorAll("head script:not([src])")]
        .map((script) => script.textContent)
        .find((text) => text.includes("MailglassAdminHooks")) || null
  );
  expect(inlineJs, "the root layout must inline the admin hooks bundle").not.toBeNull();
  const jsPath = `/dev/mail/js-${md5(Buffer.from(inlineJs.trim()))}`;
  const jsResponse = await page.request.get(jsPath);
  expect(jsResponse.status()).toBe(200);
  const servedJs = await jsResponse.body();
  const diskHooks = fs.readFileSync(path.join(REPO_ROOT, HOOKS_PATH));
  const gitHooks = gitBlob(revision, HOOKS_PATH);

  const assets = [
    {
      url_path: cssHref,
      sha256: sha256(servedCss),
      bytes: servedCss.byteLength,
      matches_disk: sha256(servedCss) === sha256(diskCss),
      matches_git_blob: sha256(servedCss) === sha256(gitCss.bytes),
      git_blob_sha: gitCss.sha
    },
    {
      url_path: jsPath,
      sha256: sha256(servedJs),
      bytes: servedJs.byteLength,
      // F5: hooks.js is not served on its own; it is embedded in the js bundle, so the
      // bundle must contain the committed bytes.
      matches_disk: servedJs.includes(diskHooks),
      matches_git_blob: servedJs.includes(gitHooks.bytes),
      git_blob_sha: gitHooks.sha
    }
  ];
  writeStaged("served.json", JSON.stringify({ revision, assets }, null, 2));

  for (const asset of assets) {
    expect(asset.matches_disk, `${asset.url_path} must match the working tree bytes`).toBe(true);
    expect(asset.matches_git_blob, `${asset.url_path} must match the git blob at ${revision}`).toBe(true);
  }
  expect(inlineJs.includes(diskHooks.toString("utf8")), "the inline bundle must carry hooks.js").toBe(true);
});

for (const def of selectedMatrix()) {
  test(`capture ${def.id}`, async ({ page }) => {
    await prepareContext(page, def);
    await def.prepare(page, { cases: CASES });
    await settle(page);

    const found = await probe(page);
    expect(found.root_theme_attr, `${def.id}: <html data-theme> must follow the theme cookie`).toBe(
      `mailglass-${def.theme}`
    );

    const file = `${def.id}.png`;
    await page.screenshot({
      path: stagePath(file),
      fullPage: def.fullPage !== false,
      animations: "disabled",
      caret: "hide"
    });
    writeStaged(`aria/${def.id}.yml`, `${await page.locator("body").ariaSnapshot()}\n`);

    const url = new URL(page.url());
    writeStaged(
      `records/${def.id}.json`,
      JSON.stringify(
        {
          id: def.id,
          tier: def.tier,
          screen: def.screen,
          route: `${url.pathname}${url.search}`,
          fixture: def.fixture,
          case: def.case,
          state: def.state,
          viewport: def.viewport,
          theme: def.theme,
          full_page: def.fullPage !== false,
          ...found
        },
        null,
        2
      )
    );
  });
}
