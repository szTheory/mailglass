const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");

const REPO_ROOT = path.resolve(__dirname, "../../../../");
const EVIDENCE_DIR = path.resolve(__dirname, "../../tmp/demo_browser_evidence");
const CAPTURE_DIR = path.join(EVIDENCE_DIR, "captures");
const MANIFEST_PATH = path.join(EVIDENCE_DIR, "phase173-captures.json");
const RESET_TOKEN = process.env.DEMO_EVIDENCE_RESET_TOKEN || "";
const RUN_ID = process.env.DEMO_EVIDENCE_RUN_ID || "";
const CANDIDATE_REVISION = process.env.DEMO_CANDIDATE_REVISION || "";
const CANDIDATE_DIRTY = process.env.DEMO_CANDIDATE_DIRTY === "true";
const PAGE_CONTROLLER_BEAM_SHA256 = process.env.DEMO_PAGE_CONTROLLER_BEAM_SHA256 || "";
const UNSUBSCRIBE_HTML_BEAM_SHA256 = process.env.DEMO_UNSUBSCRIBE_HTML_BEAM_SHA256 || "";
const BASELINES = {
  dashboard: {
    id: "baseline-dashboard-7e372023-375-light",
    path: "baseline-dashboard-7e372023-375-light.png",
    sha256: "54f7f188fba06483302e72a96340487217e700880a5389de6e71e22eec45b9a4",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/",
    fixture: "synthetic seeded AtlasDesk dashboard summary",
    theme: "light",
    viewport: "375x900",
    interactionState: "initial dashboard route before selecting a review surface",
    browser: "Chromium 148.0.7778.0",
    relation: "same route and initial dashboard state"
  },
  preview: {
    id: "baseline-preview-7e372023-375-light",
    path: "baseline-preview-7e372023-375-light.png",
    sha256: "263e69bac41292128583b2accb5f6f7c43d5a5c1a9aa86b09fe758d032d85206",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/dev/mail?theme=light",
    fixture: "synthetic seeded AtlasDesk Mailable preview root",
    theme: "light",
    viewport: "375x900",
    interactionState: "initial preview route before selecting a Mailable scenario",
    browser: "Chromium 148.0.7778.0",
    relation: "same preview surface; current capture selects the default scenario"
  },
  outbound: {
    id: "baseline-outbound-7e372023-1440-light",
    path: "baseline-outbound-7e372023-1440-light.png",
    sha256: "7984796b17ceb0b04f9d465925aae0c9356b1bd26732d28c8a5b448a2d749791",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/ops/mail?tenant_id=northstar&view=deliveries",
    fixture: "synthetic seeded northstar deliveries",
    theme: "light",
    viewport: "1440x900",
    interactionState: "delivery list before selecting a row",
    browser: "Chromium 148.0.7778.0",
    relation: "same list surface; current capture follows opening the first delivery quick view"
  },
  inbound: {
    id: "baseline-inbound-7e372023-1440-dark",
    path: "baseline-inbound-7e372023-1440-dark.png",
    sha256: "e5b263b3dba88cebe5636b1f27e868457045d9841ce070bb873fc0aaa97e3b6c",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/ops/mail/inbound?tenant_id=northstar",
    fixture: "synthetic seeded northstar support mailbox records",
    theme: "dark",
    viewport: "1440x900",
    interactionState: "inbound record list before selection",
    browser: "Chromium 148.0.7778.0",
    relation: "same mailbox surface; current capture follows opening the first record quick view"
  },
  empty: {
    id: "baseline-empty-account-7e372023-375-dark",
    path: "baseline-empty-account-7e372023-375-dark.png",
    sha256: "8809d1c8094f5698cbd7e55f1bcdc34e198947bd8cf2cbe59202b3522f95c9b7",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/ops/mail?tenant_id=helios-void&view=deliveries",
    fixture: "synthetic helios-void account with zero delivery rows",
    theme: "dark",
    viewport: "375x900",
    interactionState: "direct route to the empty account deliveries state",
    browser: "Chromium 148.0.7778.0",
    relation: "same route, fixture, theme, viewport, and empty state"
  },
  recipient: {
    id: "baseline-recipient-expired-7e372023-375-light",
    path: "baseline-recipient-expired-7e372023-375-light.png",
    sha256: "bf9013f075e08143128675efb4436f8e3f52b091201e4ab06f9930bb8182d560",
    sourceRevision: "7e3720237f51f2907b77c7dcb03042f2dd379d53",
    dirty: true,
    route: "/dev/unsubscribe/expired",
    fixture: "fixed synthetic expired unsubscribe route state",
    theme: "light",
    viewport: "375x900",
    interactionState: "initial expired recipient link state",
    browser: "Chromium 148.0.7778.0",
    relation: "same route, fixture, theme, viewport, and expired state"
  }
};

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

async function applyTheme(page, theme) {
  await page.emulateMedia({ colorScheme: theme });
}

async function expectNoPageHorizontalOverflow(page) {
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth - window.innerWidth
  );
  expect(overflow, "page-level content must not clip or scroll horizontally").toBeLessThanOrEqual(1);
}

function sourceAndBuiltCss() {
  const sourcePath = path.join(REPO_ROOT, "mailglass_admin/assets/css/app.css");
  const builtPath = path.join(REPO_ROOT, "mailglass_admin/priv/static/app.css");
  return {
    source: { path: "mailglass_admin/assets/css/app.css", sha256: sha256(fs.readFileSync(sourcePath)) },
    built: { path: "mailglass_admin/priv/static/app.css", sha256: sha256(fs.readFileSync(builtPath)) }
  };
}

async function adminCssIdentity(page) {
  const hrefs = await page.locator('link[rel="stylesheet"]').evaluateAll((links) =>
    links.map((link) => link.href)
  );
  const href = hrefs.find((item) => new URL(item).pathname.includes("/css-"));
  if (!href) throw new Error(`No mount-rooted Admin stylesheet found for ${page.url()}`);

  const response = await page.request.get(href);
  if (!response.ok()) throw new Error(`Served Admin stylesheet returned ${response.status()}: ${href}`);
  const servedBytes = await response.body();
  const { source, built } = sourceAndBuiltCss();
  const servedSha256 = sha256(servedBytes);
  if (built.sha256 !== servedSha256) {
    throw new Error(`Built and served Admin CSS differ for ${page.url()}`);
  }

  return {
    kind: "admin-css",
    source,
    built,
    served: { url: new URL(href).pathname, sha256: servedSha256 },
    built_served_match: true
  };
}

async function inlineTemplateIdentity(page, sourceRelativePath, beamRelativePath, beamSha256) {
  const sourcePath = path.join(REPO_ROOT, sourceRelativePath);
  if (!/^[0-9a-f]{64}$/.test(beamSha256)) throw new Error(`Compiled template identity is missing: ${beamRelativePath}`);
  const css = await page.locator("style").first().textContent();
  if (!css) throw new Error(`Inline stylesheet is missing for ${page.url()}`);
  const response = await page.request.get(page.url());
  if (!response.ok()) throw new Error(`Current route returned ${response.status()}: ${page.url()}`);
  return {
    kind: "compiled-template",
    source: { path: sourceRelativePath, sha256: sha256(fs.readFileSync(sourcePath)) },
    built: { path: beamRelativePath, sha256: beamSha256 },
    served: {
      url: new URL(page.url()).pathname,
      html_sha256: sha256(await response.body()),
      inline_css_sha256: sha256(Buffer.from(css))
    },
    built_served_match: null
  };
}

async function recordCapture({ page, browser, testInfo, id, fixture, theme, interactionState, baseline, assets }) {
  await expectNoPageHorizontalOverflow(page);
  await fs.promises.mkdir(CAPTURE_DIR, { recursive: true });
  const relativePath = `captures/${RUN_ID}-${id}.png`;
  const absolutePath = path.join(EVIDENCE_DIR, relativePath);
  const bytes = await page.screenshot({ path: absolutePath, animations: "disabled" });
  const route = new URL(page.url()).pathname + new URL(page.url()).search;
  const capture = {
    id,
    test_title: testInfo.title,
    route,
    fixture,
    theme,
    viewport: await page.evaluate(() => `${window.innerWidth}x${window.innerHeight}`),
    interaction_state: interactionState,
    browser: `Chromium ${browser.version()}`,
    before_after: {
      baseline_id: baseline.id,
      baseline_path: baseline.path,
      baseline_sha256: baseline.sha256,
      baseline_source_revision: baseline.sourceRevision,
      baseline_dirty: baseline.dirty,
      baseline_route: baseline.route,
      baseline_fixture: baseline.fixture,
      baseline_theme: baseline.theme,
      baseline_viewport: baseline.viewport,
      baseline_interaction_state: baseline.interactionState,
      baseline_browser: baseline.browser,
      relation: baseline.relation
    },
    candidate_revision: CANDIDATE_REVISION,
    candidate_dirty: CANDIDATE_DIRTY,
    path: relativePath,
    sha256: sha256(bytes),
    assets,
    rendering_scope: "Browser rendering only; no delivered-email client behavior is certified."
  };

  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, "utf8"));
  manifest.captures.push(capture);
  fs.writeFileSync(MANIFEST_PATH, `${JSON.stringify(manifest, null, 2)}\n`);
}

test.beforeAll(() => {
  if (!/^mailglass-evidence-[a-zA-Z0-9-]+$/.test(RUN_ID)) {
    throw new Error("Evidence run ID is missing or unsafe");
  }
  if (!/^[0-9a-f]{40}$/.test(CANDIDATE_REVISION)) {
    throw new Error("Candidate revision must be a full Git object ID");
  }
  if (!/^[0-9a-f]{64}$/.test(PAGE_CONTROLLER_BEAM_SHA256) || !/^[0-9a-f]{64}$/.test(UNSUBSCRIBE_HTML_BEAM_SHA256)) {
    throw new Error("Compiled route-template identities are missing");
  }
  fs.mkdirSync(CAPTURE_DIR, { recursive: true });
  fs.writeFileSync(
    MANIFEST_PATH,
    `${JSON.stringify({ schema_version: "phase173-captures.v2", captures: [] }, null, 2)}\n`
  );
});

test.beforeEach(async ({ request }) => {
  const response = await request.post("/demo/evidence/reset", {
    headers: { "x-mailglass-demo-reset-token": RESET_TOKEN }
  });
  expect(response.ok(), "synthetic demo fixture reset must succeed").toBeTruthy();
});

test("dashboard links to preview and operator surfaces", async ({ page, browser }, testInfo) => {
  const theme = "light";
  await page.setViewportSize({ width: 375, height: 900 });
  await applyTheme(page, theme);
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Explore Mailglass in a working app" })).toBeVisible();
  await expect(page.locator('a[href="/dev/mail"]')).toBeVisible();
  await expect(page.locator('a[href*="/ops/mail?tenant_id=northstar"]')).toBeVisible();
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "dashboard",
    fixture: "synthetic AtlasDesk dashboard summary",
    theme,
    interactionState: "primary navigation links visible before selection",
    baseline: BASELINES.dashboard,
    assets: await inlineTemplateIdentity(
      page,
      "reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex",
      "/workspace/reference/demo_app/_build/dev/lib/mailglass_demo/ebin/Elixir.MailglassDemoWeb.PageController.beam",
      PAGE_CONTROLLER_BEAM_SHA256
    )
  });

  await page.locator('a[href="/dev/mail"]').click();
  await expect(page).toHaveURL(/\/dev\/mail\/MailglassDemoWeb\.Mailers\.[^?]+\?width=768$/);
  await page.goto("/dev/mail?theme=light");
  await expect(page.getByRole("heading", { name: "Preview", exact: true })).toBeVisible();
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "preview",
    fixture: "synthetic AtlasDesk Mailable preview scenario",
    theme,
    interactionState: "opened Preview from dashboard and selected the light theme",
    baseline: BASELINES.preview,
    assets: await adminCssIdentity(page)
  });
});

test("outbound operator opens with seeded delivery evidence", async ({ page, browser }, testInfo) => {
  const theme = "light";
  await page.setViewportSize({ width: 1440, height: 900 });
  await applyTheme(page, theme);
  await page.goto(`/demo/login?return_to=${encodeURIComponent("/ops/mail?tenant_id=northstar&view=deliveries")}`);
  await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
  const table = page.getByTestId("operator-deliveries-table");
  await expect(table).toBeVisible();
  await expect(table.getByTestId("operator-delivery-row").first()).toBeVisible();
  await page.waitForFunction(() => document.querySelector("[data-phx-main]")?.classList.contains("phx-connected"));
  await page.getByRole("button", { name: "Open delivery" }).first().click();
  await expect(page.getByTestId("operator-quick-view")).toBeVisible();
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "outbound-primary",
    fixture: "synthetic northstar delivery rows",
    theme,
    interactionState: "opened the first delivery quick view from the list",
    baseline: BASELINES.outbound,
    assets: await adminCssIdentity(page)
  });
});

test("inbound operator opens with seeded support mailbox evidence", async ({ page, browser }, testInfo) => {
  const theme = "dark";
  await page.setViewportSize({ width: 1440, height: 900 });
  await applyTheme(page, theme);
  await page.goto(`/demo/login?return_to=${encodeURIComponent("/ops/mail/inbound?tenant_id=northstar")}`);
  await page.goto("/ops/mail/inbound?tenant_id=northstar");
  const row = page.getByTestId("inbound-record-row").first();
  await expect(row).toBeVisible();
  await page.waitForFunction(() => document.querySelector("[data-phx-main]")?.classList.contains("phx-connected"));
  await page.getByTestId("inbound-record-open").first().click();
  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "inbound-primary",
    fixture: "synthetic northstar support mailbox records",
    theme,
    interactionState: "opened the first inbound record from the mailbox list",
    baseline: BASELINES.inbound,
    assets: await adminCssIdentity(page)
  });
});

test("empty account stays isolated and explains the absence of deliveries", async ({ page, browser }, testInfo) => {
  const theme = "dark";
  await page.setViewportSize({ width: 375, height: 900 });
  await applyTheme(page, theme);
  await page.goto(`/demo/login?return_to=${encodeURIComponent("/ops/mail?tenant_id=helios-void&view=deliveries")}`);
  await page.goto("/ops/mail?tenant_id=helios-void&view=deliveries");
  await expect(page.getByTestId("admin-shell-sidebar")).toContainText("Deliveries");
  await expect(page.getByRole("heading", { name: "No deliveries in this time window", exact: true })).toBeVisible();
  await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);
  await expect(page.locator("body")).not.toContainText("Internal Server Error");
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "empty-account-adverse",
    fixture: "synthetic helios-void account with zero delivery rows",
    theme,
    interactionState: "direct route to an account with no delivery data",
    baseline: BASELINES.empty,
    assets: await adminCssIdentity(page)
  });
});

test("recipient browser shows a truthful expired unsubscribe state", async ({ page, browser }, testInfo) => {
  const theme = "light";
  await page.setViewportSize({ width: 375, height: 900 });
  await applyTheme(page, theme);
  await page.goto("/dev/unsubscribe/expired");
  await expect(page.getByRole("heading", { name: "This unsubscribe link has expired." })).toBeVisible();
  await expect(page.getByText("You have not been unsubscribed.")).toHaveCount(0);
  await expectNoPageHorizontalOverflow(page);
  await recordCapture({
    page,
    browser,
    testInfo,
    id: "recipient-expired-adverse",
    fixture: "fixed synthetic expired unsubscribe route state",
    theme,
    interactionState: "opened a fixed expired recipient link without mutating subscription state",
    baseline: BASELINES.recipient,
    assets: await inlineTemplateIdentity(
      page,
      "lib/mailglass/compliance/unsubscribe_html/state.html.heex",
      "/workspace/reference/demo_app/_build/dev/lib/mailglass/ebin/Elixir.Mailglass.Compliance.UnsubscribeHTML.beam",
      UNSUBSCRIBE_HTML_BEAM_SHA256
    )
  });
});
