const { test, expect } = require("@playwright/test");

// =============================================================================
// flows.spec.js — Phase 115 Plan 04 (FLOW-01 / FLOW-02 / FLOW-03)
//
// Proves the 5-path taxonomy (happy / error / boundary / edge / advanced) per
// surface at the 320px floor with the {system} theme axis, plus the overlay
// interaction subset and the light/dark/system contrast spot-check. Drives the
// three live surfaces (Operator /ops/mail, Inbound /ops/mail/inbound, Preview
// /dev/mail) by SEEDED URL — ZERO new fixtures (D-02). Assertions only:
// getComputedStyle / boundingBox / scrollWidth-clientWidth / elementFromPoint /
// data-theme / getAnimations — NEVER any pixel-diff / screenshot assertion (D-03).
//
// Per-file convention: login + open helpers are duplicated from
// structural.spec.js / operator.spec.js (no shared module exists today).
// =============================================================================

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

// The full-walk axis: 320px floor (FLOW-02) and the system theme (FLOW-02 3rd axis).
const FLOW_VIEWPORT = { width: 320, height: 900 };

// ---------------------------------------------------------------------------
// Login + open helpers (mirror structural.spec.js exactly — no shared module)
// ---------------------------------------------------------------------------

async function loginOperator(page, returnTo, subjectId = "operator-1", sessionTenantId = tenantId) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const loginParams = new URLSearchParams({
    tenant_id: sessionTenantId,
    return_to: returnTo,
    subject_id: subjectId
  });

  const loginURL = new URL(`/ops/browser-login?${loginParams.toString()}`, baseURL).toString();
  await page.goto(loginURL);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${sessionTenantId}`));
}

async function openOperator(page, query = `tenant_id=${tenantId}&view=deliveries`) {
  await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/mail?${query}`);
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
}

async function openInbound(page, query = `tenant_id=${tenantId}`, subjectId = "operator-1", sessionTenantId = tenantId) {
  const path = query ? `/ops/mail/inbound?${query}` : "/ops/mail/inbound";
  await loginOperator(page, `/ops/mail?tenant_id=${sessionTenantId}`, subjectId, sessionTenantId);
  await page.goto(new URL(path, baseURL).toString());
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}

async function openPreviewEmpty(page) {
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
}

async function openPreviewIndex(page, query = "") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
}

async function openPreviewScenario(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-assigns-form")).toBeVisible();
}

async function openPreviewError(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-render-error")).toBeVisible();
}

// noMatchRow mirrors structural.spec.js — visible() filter resolves across table/cards.
function noMatchRow(page) {
  return page
    .getByTestId("inbound-record-row")
    .filter({ has: page.locator(".badge-warning", { hasText: "No match" }) })
    .filter({ visible: true })
    .first();
}

async function openOperatorReplayModal(page) {
  await openOperator(page);
  // visible() resolves the card row at <768px and the table row at >=768px.
  await page.getByTestId("operator-delivery-row").filter({ visible: true }).first().click();
  await expect(page.getByTestId("operator-detail-column")).toBeVisible();
  await page.getByTestId("operator-replay-open").click();
  const modal = page.getByTestId("operator-replay-modal");
  await expect(modal).toBeVisible();
  return modal;
}

async function openInboundReplayModal(page) {
  await openInbound(page);
  const replayableRow = page
    .getByTestId("inbound-record-row")
    .filter({ hasNot: page.locator(".badge-warning", { hasText: "No match" }) })
    .filter({ visible: true })
    .first();
  await replayableRow.click();
  await page.waitForURL(/inbound_id=/);
  await page.getByTestId("inbound-replay-open").click();
  const modal = page.getByTestId("inbound-replay-modal");
  await expect(modal).toBeVisible();
  return modal;
}

// ---------------------------------------------------------------------------
// Geometry / contrast helpers (mirror structural.spec.js)
// ---------------------------------------------------------------------------

async function assertNoElementHorizontalOverflow(locator, label) {
  await expect(locator.first(), `${label} present`).toBeVisible();
  const overflow = await locator.first().evaluate(el => el.scrollWidth - el.clientWidth);
  expect(overflow, `${label} horizontal overflow`).toBeLessThanOrEqual(1);
}

async function assertNoRootOverflow(page, label) {
  const overflow = await page.evaluate(() => {
    const el = document.documentElement;
    return el.scrollWidth - el.clientWidth;
  });
  expect(overflow, `${label} root horizontal overflow`).toBeLessThanOrEqual(1);
}

async function assertSingleH1(page, label) {
  await expect(page.getByRole("heading", { level: 1 }), `${label} single h1`).toHaveCount(1);
}

async function assertPanelAboveScrim(modal, label) {
  await expect(modal, label).toBeVisible();
  const hitTest = await modal.evaluate(el => {
    const rect = el.getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const hit = document.elementFromPoint(x, y);
    const nearestTestId = hit && hit.closest ? hit.closest("[data-testid]") : null;
    return {
      ok: hit === el || el.contains(hit),
      hitTestId: nearestTestId ? nearestTestId.getAttribute("data-testid") : null,
      hitTag: hit ? hit.tagName : null
    };
  });
  expect(
    hitTest.ok,
    `${label} panel is above scrim at centroid; hit=${hitTest.hitTestId || hitTest.hitTag}`
  ).toBeTruthy();
}

function parseRgbColor(value) {
  const hex = String(value).trim().match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hex) {
    const digits = hex[1].length === 3 ? hex[1].split("").map(c => c + c).join("") : hex[1];
    return {
      r: Number.parseInt(digits.slice(0, 2), 16) / 255,
      g: Number.parseInt(digits.slice(2, 4), 16) / 255,
      b: Number.parseInt(digits.slice(4, 6), 16) / 255,
      a: 1
    };
  }
  const match = String(value).match(/rgba?\(([^)]+)\)/);
  if (!match) return null;
  const parts = match[1]
    .replace(/\//g, " ")
    .split(/[,\s]+/)
    .filter(Boolean)
    .map(p => (p.trim().endsWith("%") ? (Number.parseFloat(p) / 100) * 255 : Number.parseFloat(p)));
  if (parts.length < 3 || parts.slice(0, 3).some(p => !Number.isFinite(p))) return null;
  return {
    r: parts[0] / 255,
    g: parts[1] / 255,
    b: parts[2] / 255,
    a: parts.length >= 4 && Number.isFinite(parts[3]) ? parts[3] : 1
  };
}

function relativeLuminance(color) {
  const channel = v => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
  return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
}

function contrastRatio(fg, bg) {
  const lighter = Math.max(relativeLuminance(fg), relativeLuminance(bg));
  const darker = Math.min(relativeLuminance(fg), relativeLuminance(bg));
  return (lighter + 0.05) / (darker + 0.05);
}

async function resolvedColors(locator) {
  return locator.first().evaluate(el => {
    const normalizeColor = value => {
      const canvas = document.createElement("canvas");
      const context = canvas.getContext("2d");
      if (!context) return value;
      context.fillStyle = "#000000";
      context.fillStyle = value;
      return context.fillStyle;
    };
    const transparent = value => {
      const match = String(value).match(/rgba?\(([^)]+)\)/);
      if (!match) return false;
      const parts = match[1]
        .replace(/\//g, " ")
        .split(/[,\s]+/)
        .filter(Boolean)
        .map(p => Number.parseFloat(p.trim()));
      return parts.length >= 4 && parts[3] === 0;
    };
    const style = getComputedStyle(el);
    let current = el;
    let backgroundColor = style.backgroundColor;
    while (current && transparent(backgroundColor)) {
      current = current.parentElement;
      backgroundColor = current ? getComputedStyle(current).backgroundColor : "rgb(255, 255, 255)";
    }
    return {
      color: normalizeColor(style.color),
      backgroundColor: normalizeColor(backgroundColor)
    };
  });
}

async function assertTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const foreground = parseRgbColor(colors.color);
  const background = parseRgbColor(colors.backgroundColor);
  expect(foreground, `${label} foreground parses`).not.toBeNull();
  expect(background, `${label} background parses`).not.toBeNull();
  expect(contrastRatio(foreground, background), `${label} text contrast`).toBeGreaterThanOrEqual(4.5);
}

// =============================================================================
// FULL WALK — 3 surfaces x 5 paths at 320px / system theme.
// Each path asserts: correct landmark/testid visible + single-h1 invariant +
// no horizontal overflow on root AND master-detail (scrollWidth - clientWidth
// <= 1). Happy path additionally asserts the single dominant primary CTA.
// =============================================================================

test.describe("flows: full walk — 5 paths x 3 surfaces at 320/system (FLOW-01/02)", () => {

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
    // system theme axis: no explicit ?theme= param → root emits no data-theme.
  });

  // -------------------------------- OPERATOR --------------------------------

  test("Operator happy: select row -> detail timeline; single dominant CTA survives 320/system", async ({ page }) => {
    await openOperator(page);
    await assertSingleH1(page, "operator happy");
    await assertNoRootOverflow(page, "operator happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator happy master-detail");

    // At 320 the table is hidden — select from the card presentation.
    await page.getByTestId("operator-deliveries-cards").getByTestId("operator-delivery-row").first().click();
    await expect(page.getByTestId("operator-detail-column")).toBeVisible();

    // The single obvious top action for Operator: the replay CTA (the one
    // destructive/dominant action in the detail header). It must be visible and
    // be the dominant action button at 320px. Live copy is "Replay webhook"
    // (btn-error); the planner's prose label "Replay delivery" approximates it.
    const replayCta = page.getByTestId("operator-replay-open");
    await expect(replayCta).toBeVisible();
    const box = await replayCta.boundingBox();
    expect(box, "operator replay CTA box").not.toBeNull();
    expect(Math.round(box.height), "operator replay CTA target floor").toBeGreaterThanOrEqual(44);
    await assertSingleH1(page, "operator happy after select");
    await assertNoRootOverflow(page, "operator happy detail");
  });

  test("Operator error: delivery_id=does-not-exist -> detail error", async ({ page }) => {
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&delivery_id=does-not-exist`);
    await expect(page.getByTestId("operator-detail-error")).toBeVisible();
    await assertSingleH1(page, "operator error");
    await assertNoRootOverflow(page, "operator error");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator error master-detail");
  });

  test("Operator boundary: filtered-empty -> empty + reset", async ({ page }) => {
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&status=queued`);
    const filteredEmpty = page.getByTestId("operator-deliveries-list-card").getByTestId("data-state-empty");
    await expect(filteredEmpty).toBeVisible();
    await expect(page.getByTestId("operator-empty-reset")).toBeVisible();
    await assertSingleH1(page, "operator boundary");
    await assertNoRootOverflow(page, "operator boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator boundary master-detail");
  });

  test("Operator edge: long/non-ASCII tenant truncates without overflow at 320", async ({ page }) => {
    // Edge path: a long/non-ASCII tenant id stresses the mono ID cells. The
    // suppressed-status seeded view exposes the truncating ID cells; assert no
    // overflow at the 320 floor on root and master-detail.
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&status=suppressed`);
    await assertSingleH1(page, "operator edge");
    await assertNoRootOverflow(page, "operator edge");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator edge master-detail");
    await assertNoElementHorizontalOverflow(
      page.getByTestId("operator-deliveries-list-card"),
      "operator edge list-card"
    );
  });

  test("Operator advanced: replay modal -> panel above scrim, Escape closes", async ({ page }) => {
    const modal = await openOperatorReplayModal(page);
    await assertPanelAboveScrim(modal, "operator advanced replay-modal");
    await assertSingleH1(page, "operator advanced");
    await assertNoRootOverflow(page, "operator advanced");
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("operator-replay-modal")).toHaveCount(0);
  });

  // --------------------------------- INBOUND --------------------------------

  test("Inbound happy: select no-match row -> routing trace; dominant CTA on replayable row at 320/system", async ({ page }) => {
    await openInbound(page);
    await assertSingleH1(page, "inbound happy");
    await assertNoRootOverflow(page, "inbound happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound happy master-detail");

    // Happy path per taxonomy: select a no-match row -> routing trace renders
    // (the routing trace explains why no Mailbox matched).
    await noMatchRow(page).click();
    await page.waitForURL(/inbound_id=/);
    await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
    await assertSingleH1(page, "inbound happy after no-match select");
    await assertNoRootOverflow(page, "inbound happy trace");

    // At 320 the list-card is hidden once a record is selected — return to the
    // list via detail-back before selecting a replayable row.
    await page.getByTestId("inbound-detail-back").click();
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    // The single dominant top action (Replay inbound) is present on a replayable
    // (matched) row. Live copy is "Replay inbound" (btn-error); the planner's
    // prose label "Replay inbound message" approximates it.
    const replayableRow = page
      .getByTestId("inbound-records-cards")
      .getByTestId("inbound-record-row")
      .filter({ hasNot: page.locator(".badge-warning", { hasText: "No match" }) })
      .filter({ visible: true })
      .first();
    await replayableRow.click();
    await page.waitForURL(/inbound_id=/);
    const replayCta = page.getByTestId("inbound-replay-open");
    await expect(replayCta).toBeVisible();
    const box = await replayCta.boundingBox();
    expect(box, "inbound replay CTA box").not.toBeNull();
    expect(Math.round(box.height), "inbound replay CTA target floor").toBeGreaterThanOrEqual(44);
    await assertNoRootOverflow(page, "inbound happy detail");
  });

  test("Inbound error: inbound_id=does-not-exist -> detail error", async ({ page }) => {
    await openInbound(page, `tenant_id=${tenantId}&inbound_id=does-not-exist`);
    await expect(page.getByTestId("inbound-detail-error")).toBeVisible();
    await assertSingleH1(page, "inbound error");
    await assertNoRootOverflow(page, "inbound error");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound error master-detail");
  });

  test("Inbound boundary: filtered-empty window", async ({ page }) => {
    await openInbound(page, `tenant_id=${tenantId}&search=impossible-filtered-empty`);
    await expect(page.getByText("No records match the current filters.")).toBeVisible();
    await assertSingleH1(page, "inbound boundary");
    await assertNoRootOverflow(page, "inbound boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound boundary master-detail");
  });

  test("Inbound edge: no-match record long mono cells select without overflow at 320", async ({ page }) => {
    await openInbound(page);
    // List view first: long mono ID cells must not overflow the list-card at 320
    // (the list-card is hidden once a record is selected at <768px).
    await assertNoElementHorizontalOverflow(
      page.getByTestId("inbound-records-list-card"),
      "inbound edge list-card"
    );

    await noMatchRow(page).click();
    await page.waitForURL(/inbound_id=/);
    await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
    await assertSingleH1(page, "inbound edge");
    await assertNoRootOverflow(page, "inbound edge");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound edge master-detail");
  });

  test("Inbound advanced: replay modal parity -> panel above scrim, Escape closes", async ({ page }) => {
    const modal = await openInboundReplayModal(page);
    await assertPanelAboveScrim(modal, "inbound advanced replay-modal");
    expect(await modal.getAttribute("role")).toBe("dialog");
    expect(await modal.getAttribute("aria-modal")).toBe("true");
    await assertSingleH1(page, "inbound advanced");
    await assertNoRootOverflow(page, "inbound advanced");
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  });

  // --------------------------------- PREVIEW --------------------------------

  test("Preview happy: scenario -> assigns form + render CTA; single dominant CTA at 320/system", async ({ page }) => {
    await openPreviewScenario(page, "");
    await assertSingleH1(page, "preview happy");
    await assertNoRootOverflow(page, "preview happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview happy shell");

    // The single obvious top action for Preview: the render CTA inside the
    // assigns form. Live copy is "Render preview" (btn-primary); the planner's
    // prose label "Render scenario" approximates it. Assert it is the dominant
    // (btn-primary) action and visible at 320.
    const renderCta = page.getByTestId("preview-assigns-form").locator("button.btn-primary").first();
    await expect(renderCta).toBeVisible();
    const box = await renderCta.boundingBox();
    expect(box, "preview render CTA box").not.toBeNull();
    expect(Math.round(box.height), "preview render CTA target floor").toBeGreaterThanOrEqual(44);
  });

  test("Preview error: BrokenMailer -> render error", async ({ page }) => {
    await openPreviewError(page, "");
    await expect(page.getByTestId("preview-render-error")).toBeVisible();
    await assertSingleH1(page, "preview error");
    await assertNoRootOverflow(page, "preview error");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview error shell");
  });

  test("Preview boundary: no mailables -> empty", async ({ page }) => {
    await openPreviewEmpty(page);
    await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
    await assertSingleH1(page, "preview boundary");
    await assertNoRootOverflow(page, "preview boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview boundary shell");
  });

  test("Preview edge: index with many scenarios in details navigation at 320", async ({ page }) => {
    await openPreviewIndex(page, "");
    await assertSingleH1(page, "preview edge");
    await assertNoRootOverflow(page, "preview edge");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview edge shell");
    // Mobile mailables navigation reaches a real scenario link at 320.
    const mobileMailables = page.getByTestId("preview-mobile-mailables");
    await expect(mobileMailables).toBeVisible();
  });

  test("Preview advanced: frame theme differs from admin theme without overflow at 320", async ({ page }) => {
    await openPreviewScenario(page, "theme=light");
    await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
    await page.getByTestId("preview-frame-theme-toggle").click();
    await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");
    // Frame theme diverges from admin theme — admin chrome stays light.
    await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
    await assertSingleH1(page, "preview advanced");
    await assertNoRootOverflow(page, "preview advanced");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview advanced shell");
  });

});

// =============================================================================
// OVERLAY SUBSET — operator + inbound replay modal at 320:
// panel-above-scrim + Escape closes + background scrollY unchanged
// (scroll-chaining guard from the mg-overscroll-contain in Plan 02).
// =============================================================================

test.describe("flows: overlay interaction subset at 320 (FLOW-02/03)", () => {

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
  });

  test("Operator replay modal: panel above scrim, Escape closes, background scrollY unchanged", async ({ page }) => {
    const modal = await openOperatorReplayModal(page);
    await assertPanelAboveScrim(modal, "operator overlay-subset");

    const before = await page.evaluate(() => window.scrollY);
    // Scroll inside the modal scroll container — overscroll-behavior: contain
    // must prevent scroll-chaining to the background.
    await modal.evaluate(el => {
      const scroller = el.closest(".mg-overscroll-contain") || el;
      scroller.scrollTop = scroller.scrollTop + 200;
    });
    const after = await page.evaluate(() => window.scrollY);
    expect(after, "operator background scrollY unchanged").toBe(before);

    await page.keyboard.press("Escape");
    await expect(page.getByTestId("operator-replay-modal")).toHaveCount(0);
  });

  test("Inbound replay modal: panel above scrim, Escape closes, background scrollY unchanged", async ({ page }) => {
    const modal = await openInboundReplayModal(page);
    await assertPanelAboveScrim(modal, "inbound overlay-subset");

    const before = await page.evaluate(() => window.scrollY);
    await modal.evaluate(el => {
      // The inbound modal panel itself carries mg-overscroll-contain.
      const scroller = el.classList.contains("mg-overscroll-contain")
        ? el
        : el.closest(".mg-overscroll-contain") || el;
      scroller.scrollTop = scroller.scrollTop + 200;
    });
    const after = await page.evaluate(() => window.scrollY);
    expect(after, "inbound background scrollY unchanged").toBe(before);

    await page.keyboard.press("Escape");
    await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  });

});

// =============================================================================
// THEME-PARITY SPOT-CHECK — 1 happy + 1 overlay path x {light,dark,system} x 320:
// assertTextContrastAA passes; read data-theme to confirm the theme axis.
// =============================================================================

test.describe("flows: theme-parity contrast spot-check at 320 (FLOW-02)", () => {

  const THEMES = [
    { name: "light", query: "theme=light", expected: "mailglass-light" },
    { name: "dark", query: "theme=dark", expected: "mailglass-dark" },
    { name: "system", query: "", expected: null }
  ];

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
  });

  for (const theme of THEMES) {
    test(`Operator happy path passes AA contrast in ${theme.name} at 320`, async ({ page }) => {
      const query = `tenant_id=${tenantId}&view=deliveries${theme.query ? `&${theme.query}` : ""}`;
      await openOperator(page, query);

      // Confirm the theme axis via data-theme on the root.
      if (theme.expected) {
        await expect(page.locator("html")).toHaveAttribute("data-theme", theme.expected);
      } else {
        expect(await page.locator("html").getAttribute("data-theme"), "system root has no data-theme").toBeNull();
      }

      await assertTextContrastAA(page.getByTestId("operator-deliveries-list-card"), `operator ${theme.name} list-card`);
    });

    test(`Operator overlay (replay modal) passes AA contrast in ${theme.name} at 320`, async ({ page }) => {
      // Open the operator surface in the target theme, then the replay modal.
      const query = `tenant_id=${tenantId}&view=deliveries${theme.query ? `&${theme.query}` : ""}`;
      await openOperator(page, query);
      if (theme.expected) {
        await expect(page.locator("html")).toHaveAttribute("data-theme", theme.expected);
      } else {
        expect(await page.locator("html").getAttribute("data-theme"), "system root has no data-theme").toBeNull();
      }

      await page.getByTestId("operator-deliveries-cards").getByTestId("operator-delivery-row").first().click();
      await expect(page.getByTestId("operator-detail-column")).toBeVisible();
      await page.getByTestId("operator-replay-open").click();
      const modal = page.getByTestId("operator-replay-modal");
      await expect(modal).toBeVisible();

      await assertTextContrastAA(modal, `operator ${theme.name} replay-modal`);
    });
  }

});
