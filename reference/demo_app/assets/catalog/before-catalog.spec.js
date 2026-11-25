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

const FJORDLINE = "fjordline-aps";
const WIDTHS = [375, 1440];
const THEMES = ["light", "dark"];
const PREVIEW_SHOW_PATH = "/dev/mail/MailglassDemoWeb.Mailers.BillingMailer/payment_failed";

// The ten delivery cases on the full-detail screen (Tier C): four seeded by CatalogSeed and
// six DemoData rows. Slugs match cases.json.
const DELIVERY_CASES = [
  "typo-bounce",
  "send-failed",
  "sent-no-report",
  "unicode-recipient",
  "nil-reason-bounce",
  "deferred-no-retry",
  "delivered-no-open",
  "long-recipient",
  "complained",
  "manual-suppressed"
];
const CASE_WIDTH_THEMES = [
  [375, "light"],
  [375, "dark"],
  [1440, "light"]
];

// `<screen>__<fixture-or-case>__<state>__<width>__<theme>`; the slug is the file name.
function make({ tier, screen, fixture = "any", caseSlug = null, state = "default", viewport, theme, prepare, fullPage = true }) {
  const second = caseSlug || fixture;
  return {
    id: `${screen}__${second}__${state}__${viewport}__${theme}`,
    tier,
    screen,
    fixture,
    case: caseSlug,
    state,
    viewport,
    theme,
    fullPage,
    prepare
  };
}

const operatorAt = (target) => (page) => openOperator(page, target);
const previewAt = (target) => async (page) => {
  await openPage(page, target);
  await emailFrameReady(page);
};

function buildMatrix() {
  const defs = [];

  // Tier A: Fjordline (the stress fixture), every operator screen at both widths and both themes.
  const fjordline = (screen, state, prepare, widths, themes) => {
    for (const viewport of widths)
      for (const theme of themes) defs.push(make({ tier: "A", screen, fixture: FJORDLINE, state, viewport, theme, prepare }));
  };
  fjordline("overview", "default", operatorAt(`/ops/mail?tenant_id=${FJORDLINE}`), WIDTHS, THEMES);
  fjordline("deliveries", "default", operatorAt(`/ops/mail?tenant_id=${FJORDLINE}&view=deliveries`), WIDTHS, THEMES);
  fjordline("delivery-quick-view", "open", openFjordlineQuickView, WIDTHS, THEMES);
  fjordline("delivery-detail", "default", openFjordlineDetail, WIDTHS, THEMES);
  fjordline("inbound", "default", operatorAt(`/ops/mail/inbound?tenant_id=${FJORDLINE}`), WIDTHS, THEMES);
  // 768 light only for the two list screens whose layout changes at that breakpoint.
  fjordline("overview", "default", operatorAt(`/ops/mail?tenant_id=${FJORDLINE}`), [768], ["light"]);
  fjordline("deliveries", "default", operatorAt(`/ops/mail?tenant_id=${FJORDLINE}&view=deliveries`), [768], ["light"]);

  // Tier E: Northstar inbound overlays (Northstar has inbound rows; Fjordline and Helios do not).
  defs.push(
    make({ tier: "E", screen: "inbound-quick-view", fixture: "northstar", state: "first-message", viewport: 1440, theme: "light", prepare: openNorthstarInboundQuickView }),
    make({ tier: "E", screen: "inbound-detail", fixture: "northstar", state: "first-message", viewport: 375, theme: "dark", prepare: openNorthstarInboundDetail })
  );

  // Tier D: persona-independent surfaces. The gallery is clipped to the viewport (its full page
  // is tens of thousands of pixels tall).
  for (const viewport of WIDTHS)
    for (const theme of THEMES) {
      defs.push(
        make({ tier: "D", screen: "preview-index", viewport, theme, prepare: previewAt("/dev/mail") }),
        make({ tier: "D", screen: "preview-show", state: "html", viewport, theme, prepare: previewAt(PREVIEW_SHOW_PATH) }),
        make({ tier: "D", screen: "gallery", viewport, theme, fullPage: false, prepare: (page) => openPage(page, "/dev/mail/gallery") })
      );
    }

  // Tier B: Northstar and Helios, list and empty-state screens only.
  for (const fixture of ["northstar", "helios-void"])
    for (const [viewport, theme] of [
      [1440, "light"],
      [375, "dark"]
    ]) {
      defs.push(
        make({ tier: "B", screen: "overview", fixture, viewport, theme, prepare: operatorAt(`/ops/mail?tenant_id=${fixture}`) }),
        make({ tier: "B", screen: "deliveries", fixture, viewport, theme, prepare: operatorAt(`/ops/mail?tenant_id=${fixture}&view=deliveries`) }),
        make({ tier: "B", screen: "inbound", fixture, viewport, theme, prepare: operatorAt(`/ops/mail/inbound?tenant_id=${fixture}`) })
      );
    }

  // Tier C: ten delivery cases on the full-detail screen, plus the two-subjects list.
  for (const slug of DELIVERY_CASES)
    for (const [viewport, theme] of CASE_WIDTH_THEMES)
      defs.push(
        make({
          tier: "C",
          screen: "delivery-detail",
          fixture: "northstar",
          caseSlug: slug,
          viewport,
          theme,
          prepare: (page, { cases }) =>
            openOperator(page, `/ops/mail?tenant_id=northstar&view=deliveries&delivery_id=${caseDeliveryId(cases, slug)}&full=1`)
        })
      );
  for (const [viewport, theme] of [
    [1440, "light"],
    [375, "dark"]
  ])
    defs.push(
      make({ tier: "C", screen: "deliveries", fixture: "northstar", caseSlug: "two-subjects-billing", viewport, theme, prepare: openTwoSubjectsList })
    );

  const ids = new Set(defs.map((candidate) => candidate.id));
  if (ids.size !== defs.length) throw new Error("the capture matrix repeats a capture id");
  return defs;
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

// The Preview pane renders the email in an `<iframe srcdoc>`; wait until its document exists.
async function emailFrameReady(page) {
  const frame = page.locator('iframe[title^="Email HTML preview"]');
  expect(await frame.count(), "the Preview pane must render the email iframe").toBeGreaterThan(0);
  await expect(page.frameLocator('iframe[title^="Email HTML preview"]').locator("body")).toBeVisible();
}

function caseDeliveryId(cases, slug) {
  const entry = cases[slug];
  if (!entry || typeof entry.delivery_id !== "string") {
    throw new Error(`cases.json has no delivery_id for case "${slug}"; was the catalog seed run after the reset?`);
  }
  return entry.delivery_id;
}

// Rows render twice (desktop table and mobile list); only the visible one is the real row.
async function openFirstDeliveryRow(page) {
  const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
  await expect(rows.first()).toBeVisible();
  const button = rows.first().getByRole("button", { name: /Open delivery/ });
  if ((await button.count()) > 0) await button.first().click();
  else await rows.first().click();
  await expect(page.getByTestId("operator-quick-view")).toBeVisible();
  await expect(page).toHaveURL(/delivery_id=/);
}

// Fjordline holds exactly one delivery: the long-module-name message.
async function openFjordlineQuickView(page) {
  await openOperator(page, `/ops/mail?tenant_id=${FJORDLINE}&view=deliveries`);
  const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
  await expect(rows, "Fjordline must show exactly its one long-module delivery row").toHaveCount(1);
  await openFirstDeliveryRow(page);
}

// The full-detail screen of the same delivery, reached through the quick view's own link.
async function openFjordlineDetail(page) {
  await openFjordlineQuickView(page);
  await page.getByTestId("operator-quick-view-full").click();
  await expect(page).toHaveURL(/full=1/);
  await expect(page.getByTestId("operator-detail-header")).toBeVisible();
}

async function openFirstInboundRow(page) {
  await openOperator(page, "/ops/mail/inbound?tenant_id=northstar");
  const open = page.locator('button[phx-click="select_inbound"]').filter({ visible: true });
  if ((await open.count()) === 0) {
    throw new Error("The Northstar inbound list has no message row, so the inbound overlays cannot be captured.");
  }
  await open.first().click();
  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  await expect(page).toHaveURL(/inbound_id=/);
}

async function openNorthstarInboundQuickView(page) {
  await openFirstInboundRow(page);
}

async function openNorthstarInboundDetail(page) {
  await openFirstInboundRow(page);
  await page.getByTestId("inbound-quick-view-full").click();
  await expect(page).toHaveURL(/full=1/);
  await expect(page.getByTestId("inbound-detail-header")).toBeVisible();
}

// Two messages to one customer with different subjects: the Northstar list filtered, through
// the operator's own `search` param, to the billing address that holds exactly two deliveries.
async function openTwoSubjectsList(page) {
  await openOperator(
    page,
    `/ops/mail?tenant_id=northstar&view=deliveries&search=${encodeURIComponent("billing@northstar.example")}`
  );
  const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
  await expect(rows, "billing@northstar.example must show exactly two deliveries").toHaveCount(2);
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

// The first screenshot of a freshly loaded page can differ from the next by one colour level
// in a few anti-aliased edge pixels (measured: 3 pixels, max channel delta 1, on /dev/mail);
// every later screenshot of the same state is byte-identical. A discarded warm-up shot puts
// every real capture, and both halves of the determinism self-test, on the stable path.
async function shoot(page, file, { fullPage }) {
  const options = { fullPage, animations: "disabled", caret: "hide" };
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-catalog-warmup-"));
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
      await shoot(page, file, { fullPage: true });
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
  // Plug.CSRFProtection answers a plain GET for a JavaScript body with 403 (cross-origin
  // script inclusion guard); the XHR marker is the documented way to read it as data.
  const jsResponse = await page.request.get(jsPath, {
    headers: { "x-requested-with": "XMLHttpRequest" }
  });
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
