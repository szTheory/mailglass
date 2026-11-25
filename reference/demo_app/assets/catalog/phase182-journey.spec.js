// phase182-journey.spec.js: the capture producer for the Phase 182 "after" catalog (BRADM-07)
// and the advisory browser journey for BRADM-01 (D-20, D-21).
//
// This is an EVIDENCE PRODUCER, not a test of the product and not a pixel-diff baseline. It is run
// only by `catalog/capture-before-catalog.cjs --mode after`, which owns the order
//   restart -> reset -> CatalogSeed + JourneySeed -> this spec -> validate -> promote.
// This spec NEVER calls the destructive reset endpoint. It lives in `./catalog`, outside `./e2e`,
// so the advisory `demo_browser_evidence` lane and `make demo-e2e` never run it.
//
// Two kinds of test live here, split by the `@advisory` title tag:
//   * capture tests (no tag): the determinism self-test, the served-identity check, one test per
//     scenario id and one per injected-defect calibration id. Their failure aborts the capture.
//   * advisory tests (`@advisory`): the journey at 375 and 1440, light and dark, and the
//     localized-time check in two time zones. The driver runs them in a second Playwright
//     invocation and reports the result; they are never the required proof of BRADM-01 (the
//     required proof is `phase182_journey_test.exs`, 180 D-04/D-13) and they never block evidence.
//
// Environment (all set by the driver; no defaults, so a hand run fails loudly):
//   DEMO_BASE_URL            the running evidence demo, for example http://127.0.0.1:4015/
//   CATALOG_STAGING_DIR      absolute path of the git-ignored staging directory to write into
//   CATALOG_CASES_FILE       cases.json written by the driver: { catalog: <CatalogSeed>, journey: <JourneySeed> }
//   CATALOG_ONLY             optional: comma-separated capture ids
//   DEMO_CANDIDATE_REVISION  optional: the source revision (else `git rev-parse HEAD`)
//
// Every capture (D-19, D-20): the theme cookie `mailglass_admin_theme_v2` plus a matching
// `emulateMedia` colour scheme and reduced motion, set BEFORE navigation; wait for the connected
// LiveView (never `networkidle`, never a fixed sleep); wait for the body face to be loaded; wait for
// every `time[data-local-time]` to be localized; screenshot with `animations: "disabled"` and
// `caret: "hide"` at device scale factor 1, timezone UTC and locale en-US (the config sets the
// context options). The STOP_LINE probe is a hard failure on every page.

const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { AFTER_SCENARIO_IDS, AFTER_CALIBRATION_CAPTURE_IDS } = require("./capture-before-catalog.cjs");

const REPO_ROOT = path.resolve(__dirname, "../../../..");
const THEME_COOKIE = "mailglass_admin_theme_v2";
const VIEWPORT_HEIGHT = 900;
const RELATIVE_TIME = /\bago\b|just now/i;
const STOP_LINE = /next try at|will retry/i;
const ZONE_TOKEN = /(UTC|[A-Z]{2,5}|GMT[+-]\d{1,2}(?::\d{2})?|[+-]\d{4})$/;
const BODY_FACE = '400 16px "Atkinson Hyperlegible Next"';
const CSS_PATH = "mailglass_admin/priv/static/app.css";
const HOOKS_PATH = "mailglass_admin/priv/static/hooks.js";
const MIN_TARGET = 44;

function requireEnv(name) {
  const value = process.env[name];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${name} is required: run this spec through catalog/capture-before-catalog.cjs --mode after`);
  }
  return value;
}

const BASE_URL = requireEnv("DEMO_BASE_URL");
const STAGING = path.resolve(requireEnv("CATALOG_STAGING_DIR"));
const CASES_FILE = requireEnv("CATALOG_CASES_FILE");

const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const md5 = (bytes) => crypto.createHash("md5").update(bytes).digest("hex");

const CASES_DOCUMENT = JSON.parse(fs.readFileSync(CASES_FILE, "utf8"));
const CATALOG_CASES = CASES_DOCUMENT.catalog.cases;
const JOURNEY_CASES = CASES_DOCUMENT.journey.cases;

// ---------------------------------------------------------------------------------------
// Capture matrix
// ---------------------------------------------------------------------------------------

const SELF_TEST_ID = "deliveries__northstar__default__1440__light";
const NORTHSTAR_ACTIVITY = "/ops/mail?tenant_id=northstar&view=deliveries";
const JOURNEY_SEARCH = "pw-typo-bounce@northstar.example";

// `<screen>__<fixture-or-case>__<state>__<width>__<theme>`; the slug is the file name.
function make({ tier, screen, fixture = "any", caseSlug = null, state = "default", viewport, theme, prepare, inject = null, fullPage = true }) {
  const second = caseSlug || fixture;
  return { id: `${screen}__${second}__${state}__${viewport}__${theme}`, tier, screen, fixture, case: caseSlug, state, viewport, theme, fullPage, prepare, inject };
}

function journeyDeliveryId(slug) {
  const entry = JOURNEY_CASES[slug];
  if (!entry || typeof entry.delivery_id !== "string") {
    throw new Error(`cases.json has no journey delivery_id for "${slug}"; was JourneySeed run after the reset?`);
  }
  return entry.delivery_id;
}

function catalogDeliveryId(slug) {
  const entry = CATALOG_CASES[slug];
  if (!entry || typeof entry.delivery_id !== "string") {
    throw new Error(`cases.json has no catalog delivery_id for "${slug}"; was CatalogSeed run after the reset?`);
  }
  return entry.delivery_id;
}

const detailOf = (deliveryId) => (page) =>
  openOperator(page, `${NORTHSTAR_ACTIVITY}&delivery_id=${deliveryId}&full=1`);

// Injected defects for the reviewer calibration (D-21): each removes ONE thing from a real page after it
// has settled, so a reviewer that cannot reject the result cannot be trusted to reject anything.
async function injectNoZone(page) {
  await page.evaluate(() => {
    document.querySelectorAll("[data-time-zone]").forEach((element) => element.remove());
    document.querySelectorAll("[data-timestamp-copy]").forEach((button) => {
      const text = button.querySelector("time")?.textContent.replace(/\s+/g, " ").trim() || "";
      button.setAttribute("aria-label", `Copy ${text}`);
    });
  });
}

async function injectNoStatusWord(page) {
  const removed = await page.evaluate(() => {
    let count = 0;
    document.querySelectorAll(".badge").forEach((badge) => {
      // Keep the drawn mark, drop every other visible piece of text (the word) and its accessible name.
      const walker = document.createTreeWalker(badge, NodeFilter.SHOW_TEXT);
      const texts = [];
      while (walker.nextNode()) if (walker.currentNode.textContent.trim() !== "") texts.push(walker.currentNode);
      texts.forEach((node) => {
        node.textContent = "";
        count += 1;
      });
      badge.removeAttribute("aria-label");
      badge.removeAttribute("title");
    });
    // The verdict heading repeats the class word beside its mark, and the sentence under it opens with the
    // same word ("Failed: the email ..."); without removing both the word would still be on the page and
    // the defect would be arguable rather than plain.
    document.querySelectorAll("[data-verdict-class] h3").forEach((heading) => {
      heading.textContent = "";
      count += 1;
    });
    document.querySelectorAll("[data-verdict-class] p").forEach((paragraph) => {
      const node = paragraph.firstChild;
      if (!node || node.nodeType !== Node.TEXT_NODE) return;
      // The text node opens with template whitespace, so the pattern allows leading space.
      const stripped = node.textContent.replace(/^\s*(Sent|Delivered|Delayed|Failed|Not sent|Queued)(:|\b)\s*/, "");
      if (stripped === node.textContent) return;
      node.textContent = stripped.charAt(0).toUpperCase() + stripped.slice(1);
      count += 1;
    });
    return count;
  });
  expect(removed, "the status-word defect must remove at least one badge word").toBeGreaterThan(0);
}

function buildMatrix() {
  const defs = [];
  const pw = (slug) => `pw-${slug}`;

  // The password-reset journey: search by the customer's address, then the delivery's full detail.
  for (const [viewport, theme] of [
    [375, "light"],
    [375, "dark"],
    [1440, "light"]
  ]) {
    defs.push(
      make({
        tier: "J",
        screen: "deliveries",
        fixture: "northstar",
        state: "reset-search",
        viewport,
        theme,
        prepare: async (page) => {
          await openOperator(page, `${NORTHSTAR_ACTIVITY}&search=${encodeURIComponent(JOURNEY_SEARCH)}`);
          await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }), "the search must narrow the list to the one reset row").toHaveCount(1);
        }
      }),
      make({
        tier: "J",
        screen: "delivery-detail",
        caseSlug: "reset-typo-bounce",
        viewport,
        theme,
        prepare: (page) => detailOf(journeyDeliveryId(pw("typo-bounce")))(page)
      })
    );
  }

  for (const slug of ["nil-reason-bounce", "deferred", "suppressed", "sent-no-report", "bounce-then-open"]) {
    defs.push(
      make({
        tier: "J",
        screen: "delivery-detail",
        caseSlug: `reset-${slug}`,
        viewport: 375,
        theme: "light",
        prepare: (page) => detailOf(journeyDeliveryId(pw(slug)))(page)
      })
    );
  }

  defs.push(
    make({
      tier: "J",
      screen: "deliveries",
      fixture: "northstar",
      state: "empty-search",
      viewport: 375,
      theme: "light",
      prepare: async (page) => {
        await openOperator(page, `${NORTHSTAR_ACTIVITY}&search=${encodeURIComponent("nobody@northstar.example")}`);
        // `operator-empty-filtered` is a hidden marker node; the visible filtered empty state ends in the reset control.
        await expect(page.getByTestId("operator-empty-reset"), "an address with no email must show the filtered empty state").toBeVisible();
      }
    }),
    make({ tier: "J", screen: "deliveries", fixture: "northstar", viewport: 1440, theme: "light", prepare: (page) => openOperator(page, NORTHSTAR_ACTIVITY) }),
    // Same row and same data as the Phase 180 capture of this id (the CatalogSeed invite row).
    make({
      tier: "J",
      screen: "delivery-detail",
      caseSlug: "typo-bounce",
      viewport: 375,
      theme: "light",
      prepare: (page) => detailOf(catalogDeliveryId("typo-bounce"))(page)
    })
  );

  // Injected-defect calibration shots, drawn from the real reset-typo-bounce detail at 375 light.
  const typoBounceDetail = (page) => detailOf(journeyDeliveryId(pw("typo-bounce")))(page);
  defs.push(
    make({ tier: "X", screen: "calib-defect-no-zone", caseSlug: "reset-typo-bounce", viewport: 375, theme: "light", prepare: typoBounceDetail, inject: injectNoZone }),
    make({ tier: "X", screen: "calib-defect-no-status-word", caseSlug: "reset-typo-bounce", viewport: 375, theme: "light", prepare: typoBounceDetail, inject: injectNoStatusWord })
  );

  const ids = defs.map((candidate) => candidate.id);
  if (new Set(ids).size !== ids.length) throw new Error("the capture matrix repeats a capture id");
  const expected = [...AFTER_SCENARIO_IDS, ...AFTER_CALIBRATION_CAPTURE_IDS].sort();
  if (JSON.stringify([...ids].sort()) !== JSON.stringify(expected)) {
    throw new Error(`the capture matrix and the driver's id lists disagree:\n  matrix:   ${[...ids].sort().join(", ")}\n  expected: ${expected.join(", ")}`);
  }
  return defs;
}

// ---------------------------------------------------------------------------------------
// Navigation helpers (copied from before-catalog.spec.js; the two specs share no code)
// ---------------------------------------------------------------------------------------

async function connected(page) {
  await page.locator("[data-phx-main].phx-connected").waitFor({ state: "visible" });
}

// Operator surfaces need a session: the human /demo/login entry, then the exact target.
// `return_to` is encoded so the nested query survives the redirect.
async function openOperator(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.goto(target);
  await connected(page);
}

// Rows render twice (desktop table and mobile list); only the visible one is the real row. The row's
// open control is the visible button that selects it: the table cell's "Open delivery for ..." button
// on desktop, the whole card (which is itself the `operator-delivery-row` button) on a phone.
function rowOpenControl(page) {
  return page.locator('button[phx-click="select_delivery"]').filter({ visible: true }).first();
}

async function openFirstDeliveryRow(page) {
  await expect(rowOpenControl(page)).toBeVisible();
  await rowOpenControl(page).click();
  await expect(page.getByTestId("operator-quick-view")).toBeVisible();
  await expect(page).toHaveURL(/delivery_id=/);
}

// ---------------------------------------------------------------------------------------
// Readiness and probes
// ---------------------------------------------------------------------------------------

async function settle(page) {
  await connected(page);
  // `font-display: swap` means `document.fonts.ready` alone can resolve before the face is in use,
  // so request it explicitly and then assert that it is loaded.
  await page.evaluate(async (face) => {
    await document.fonts.load(face);
    await document.fonts.ready;
  }, BODY_FACE);
  expect(await page.evaluate((face) => document.fonts.check(face), BODY_FACE), "the body face (400) must be loaded before a capture").toBe(true);
  // Timestamps render the UTC value until the local-time script marks them localized.
  await page.waitForFunction(() => !document.querySelector("time[data-local-time]:not([data-localized])"));
  await page.evaluate(() => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve))));
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
        nested_theme_attr_count: [...document.querySelectorAll("[data-theme]")].filter((element) => element !== root).length,
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

// The first screenshot of a freshly loaded page can differ from the next by one colour level in a few
// anti-aliased edge pixels; every later screenshot of the same state is byte-identical. A discarded
// warm-up shot puts every real capture, and both halves of the determinism self-test, on the stable path.
async function shoot(page, file, { fullPage }) {
  const options = { fullPage, animations: "disabled", caret: "hide" };
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-after-warmup-"));
  try {
    await page.screenshot({ path: path.join(scratch, "warm-up.png"), ...options });
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
  await page.screenshot({ path: file, ...options });
}

// ---------------------------------------------------------------------------------------
// Source identity (the demo server runs on the host-visible repository via a bind mount)
// ---------------------------------------------------------------------------------------

function sourceRevision() {
  return process.env.DEMO_CANDIDATE_REVISION || execFileSync("git", ["rev-parse", "HEAD"], { cwd: REPO_ROOT, encoding: "utf8" }).trim();
}

function gitBlob(revision, repoPath) {
  const sha = execFileSync("git", ["rev-parse", `${revision}:${repoPath}`], { cwd: REPO_ROOT, encoding: "utf8" }).trim();
  const bytes = execFileSync("git", ["show", `${revision}:${repoPath}`], { cwd: REPO_ROOT, encoding: null, maxBuffer: 64 * 1024 * 1024 });
  return { sha, bytes };
}

// ---------------------------------------------------------------------------------------
// Capture tests
// ---------------------------------------------------------------------------------------

const MATRIX = buildMatrix();

function selectedMatrix() {
  const only = (process.env.CATALOG_ONLY || "").trim();
  if (only === "") return MATRIX;
  const ids = only
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);
  const known = new Set(MATRIX.map((def) => def.id));
  const unknown = ids.filter((id) => !known.has(id));
  if (unknown.length > 0) throw new Error(`CATALOG_ONLY names unknown capture ids: ${unknown.join(", ")}`);
  return MATRIX.filter((def) => ids.includes(def.id));
}

test("determinism self-test: the same screen captured twice is byte-identical", async ({ page }) => {
  const def = MATRIX.find((candidate) => candidate.id === SELF_TEST_ID);
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-after-selftest-"));
  const hashes = [];
  try {
    for (const attempt of [0, 1]) {
      await prepareContext(page, def);
      await def.prepare(page);
      await settle(page);
      const file = path.join(scratch, `attempt-${attempt}.png`);
      await shoot(page, file, { fullPage: true });
      hashes.push(sha256(fs.readFileSync(file)));
    }
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
  writeStaged("determinism.json", JSON.stringify({ self_test_id: SELF_TEST_ID, sha256: hashes, identical: hashes[0] === hashes[1] }, null, 2));
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
  expect(md5(servedCss), "served css bytes must match the md5 in their own route").toBe(cssHref.match(/css-([a-f0-9]{32})$/)[1]);
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
  // Plug.CSRFProtection answers a plain GET for a JavaScript body with 403 (cross-origin script
  // inclusion guard); the XHR marker is the documented way to read it as data.
  const jsResponse = await page.request.get(jsPath, { headers: { "x-requested-with": "XMLHttpRequest" } });
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
      // hooks.js is not served on its own; it is embedded in the js bundle, so the bundle must contain
      // the committed bytes.
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
    await def.prepare(page);
    await settle(page);
    if (def.inject) await def.inject(page);

    const found = await probe(page);
    expect(found.root_theme_attr, `${def.id}: <html data-theme> must follow the theme cookie`).toBe(`mailglass-${def.theme}`);
    expect(found.stop_line_hits, `${def.id}: the page must not promise a retry or a retry time (the milestone stop line)`).toEqual([]);

    const file = `${def.id}.png`;
    await shoot(page, stagePath(file), { fullPage: def.fullPage !== false });
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

// ---------------------------------------------------------------------------------------
// Advisory journey (BRADM-01, D-20): never the required proof, never blocks the evidence
// ---------------------------------------------------------------------------------------

async function noHorizontalScroll(page, step) {
  const overflow = await page.evaluate(() => ({ scroll: document.documentElement.scrollWidth, inner: window.innerWidth }));
  expect(overflow.scroll, `${step}: scrollWidth (${overflow.scroll}) must not exceed innerWidth (${overflow.inner})`).toBeLessThanOrEqual(overflow.inner);
}

async function minTarget(locator, label) {
  const box = await locator.boundingBox();
  expect(box, `${label} must be on screen`).not.toBeNull();
  expect(box.height, `${label} must be at least ${MIN_TARGET} px tall (is ${box && box.height})`).toBeGreaterThanOrEqual(MIN_TARGET);
}

test.describe("advisory: password-reset journey @advisory", () => {
  for (const [viewport, theme] of [
    [375, "light"],
    [375, "dark"],
    [1440, "light"],
    [1440, "dark"]
  ]) {
    test(`journey at ${viewport} ${theme}: search, open the row, open full detail @advisory`, async ({ page }) => {
      await prepareContext(page, { viewport, theme });
      await openOperator(page, NORTHSTAR_ACTIVITY);
      await settle(page);
      await noHorizontalScroll(page, "Activity list");

      const search = page.locator("#filters_search");
      await expect(search).toBeVisible();
      await minTarget(search, "the search input");

      await search.fill(JOURNEY_SEARCH);
      await page.waitForURL((url) => new URL(url).searchParams.get("search") === JOURNEY_SEARCH);
      await connected(page);
      const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
      await expect(rows).toHaveCount(1);
      await minTarget(rowOpenControl(page), "the row's open control");
      await noHorizontalScroll(page, "searched list");

      await openFirstDeliveryRow(page);
      await connected(page);
      await noHorizontalScroll(page, "Quick view");

      await page.getByTestId("operator-quick-view-full").click();
      await expect(page).toHaveURL(/full=1/);
      await connected(page);
      await expect(page.getByTestId("operator-detail-header")).toBeVisible();
      await settle(page);
      await noHorizontalScroll(page, "full detail");

      const verdict = page.locator("#delivery-detail-verdict");
      await expect(verdict, "the verdict must be on the full detail").toBeVisible();
      if (viewport === 375) {
        const box = await verdict.boundingBox();
        expect(box.y, `the verdict's top (${box.y}) must be inside the first viewport (${VIEWPORT_HEIGHT})`).toBeLessThan(VIEWPORT_HEIGHT);
      }
      const link = verdict.locator("a");
      if ((await link.count()) > 0) await minTarget(link.first(), "the next-step link");
      expect(await page.evaluate((face) => document.fonts.check(face), BODY_FACE), "the body face must be loaded").toBe(true);
    });
  }

  test("a suppressed email's next-step link is a 44 px target @advisory", async ({ page }) => {
    await prepareContext(page, { viewport: 375, theme: "light" });
    await detailOf(journeyDeliveryId("pw-suppressed"))(page);
    await settle(page);
    const link = page.locator("#delivery-detail-verdict a");
    await expect(link, "a Not sent verdict links to the suppression card").toHaveCount(1);
    await minTarget(link, "the next-step link");
  });
});

for (const [timezoneId, expected] of [
  ["America/New_York", /^(EST|EDT)$/],
  ["Pacific/Auckland", /^(NZDT|NZST|GMT\+1[23])$/]
]) {
  test.describe(`advisory: localized time in ${timezoneId} @advisory`, () => {
    test.use({ timezoneId });

    test(`every localized time ends in a zone token (${timezoneId}) @advisory`, async ({ page }) => {
      await prepareContext(page, { viewport: 1440, theme: "light" });
      await detailOf(journeyDeliveryId("pw-typo-bounce"))(page);
      await settle(page);

      const texts = await page.evaluate(() =>
        [...document.querySelectorAll("time[data-local-time]")].map((element) => ({
          localized: element.dataset.localized === "1",
          text: element.textContent.replace(/\s+/g, " ").trim()
        }))
      );
      expect(texts.length, "the detail must show at least one time").toBeGreaterThan(0);
      for (const { localized, text } of texts) {
        expect(localized, `"${text}" must be localized by the browser`).toBe(true);
        expect(text, `"${text}" must end in a zone token`).toMatch(ZONE_TOKEN);
        expect(text.split(" ").at(-1), `"${text}" must carry the ${timezoneId} zone, not UTC`).toMatch(expected);
      }
    });
  });
}
