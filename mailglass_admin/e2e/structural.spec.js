const { test, expect } = require("@playwright/test");

// Mirrors operator.spec.js tenantId exactly
const tenantId = "browser-tenant";
const denyRevealTenantId = "deny-reveal";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

// Glass #277B96 in RGB form — the accent color that must only appear on allowlisted elements
const ACCENT_LIGHT_RGB = "rgb(39, 123, 150)";

// Selectors whose elements are permitted to carry the accent color (design-system.md:112-121)
const ACCENT_ALLOWLIST = [
  "[aria-selected='true']",
  "[aria-current='page']",
  ".btn-primary",
  ":focus-visible"
];

// Mirrors openOperator from operator.spec.js exactly (browser-reset + browser-login)
async function openOperator(page) {
  await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(
    page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
  ).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}

async function loginOperator(page, returnTo, subjectId = "operator-1", sessionTenantId = tenantId) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const loginParams = new URLSearchParams({
    tenant_id: sessionTenantId,
    return_to: returnTo,
    subject_id: subjectId
  });

  const loginPath = `/ops/browser-login?${loginParams.toString()}`;
  const loginURL = new URL(loginPath, baseURL).toString();
  await page.goto(loginURL);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${sessionTenantId}`));
}

// Opens the Inbound surface (requires authenticated session from openOperator)
async function openInbound(
  page,
  query = `tenant_id=${tenantId}`,
  subjectId = "operator-1",
  sessionTenantId = tenantId
) {
  const path = query ? `/ops/mail/inbound?${query}` : "/ops/mail/inbound";
  await loginOperator(page, `/ops/mail?tenant_id=${sessionTenantId}`, subjectId, sessionTenantId);
  await page.goto(new URL(path, baseURL).toString());
  await expect(page.getByRole("heading", { name: "Inbound records", level: 1 })).toBeVisible();
}

// Opens the Preview surface via the test route that sets mailables=[] in the session
async function openPreviewEmpty(page) {
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-orientation")).toBeVisible();
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
  await expect(page.getByRole("heading", { name: "No Mailables discovered", exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Read preview setup", exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Preview the first Mailable", exact: true })).toHaveCount(0);
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
  await expect(page.getByTestId("preview-header-controls")).toBeVisible();
  await expect(page.getByTestId("preview-assigns-form")).toBeVisible();
  await expect(page.getByTestId("preview-tab-strip")).toBeVisible();
  await expect(page.getByTestId("preview-pane")).toBeVisible();
}

async function openPreviewError(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-render-error")).toBeVisible();
  await expect(page.getByRole("heading", { name: "preview_props/0 raised an error", exact: true })).toBeVisible();
  await expect(page.getByText("Fix the error in")).toBeVisible();
  await expect(
    page.getByTestId("preview-render-error").getByText("MailglassAdmin.Fixtures.BrokenMailer", { exact: true })
  ).toBeVisible();
  await expect(page.getByText("and save the file to reload.")).toBeVisible();
}

// Opens the Gallery surface (dev-only, no auth required)
async function openGallery(page) {
  await page.goto("/dev/mail/gallery");
  await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
}

// Returns true if any of the ACCENT_ALLOWLIST selectors match the element
async function isAccentAllowlisted(page, locator) {
  for (const selector of ACCENT_ALLOWLIST) {
    try {
      // evaluateHandle + matches() checks whether the element matches the CSS selector
      const matches = await locator.evaluate(
        (el, sel) => {
          // :focus-visible cannot be checked via matches() when not focused — skip it
          if (sel === ":focus-visible") return false;
          return el.matches(sel);
        },
        selector
      );
      if (matches) return true;
    } catch (_) {
      // Ignore errors from evaluate (e.g. element detached) — treat as not allowlisted
    }
  }
  return false;
}

function parseGridColumns(value) {
  return value
    .split(" ")
    .map(part => Number.parseFloat(part))
    .filter(Number.isFinite);
}

function expectRatio(columns, expected, tolerance = 0.05) {
  expect(columns.length).toBe(2);
  const total = columns[0] + columns[1];
  expect(total).toBeGreaterThan(0);
  expect(columns[0] / total).toBeGreaterThanOrEqual(expected - tolerance);
  expect(columns[0] / total).toBeLessThanOrEqual(expected + tolerance);
}

function parseRgbColor(value) {
  const hex = String(value).trim().match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hex) {
    const digits = hex[1].length === 3
      ? hex[1].split("").map(char => char + char).join("")
      : hex[1];

    return {
      r: Number.parseInt(digits.slice(0, 2), 16) / 255,
      g: Number.parseInt(digits.slice(2, 4), 16) / 255,
      b: Number.parseInt(digits.slice(4, 6), 16) / 255,
      a: 1
    };
  }

  const match = String(value).match(/rgba?\(([^)]+)\)/);
  if (!match) return null;
  const parts = match[1].split(",").map(part => Number.parseFloat(part.trim()));
  if (parts.length < 3 || parts.slice(0, 3).some(part => !Number.isFinite(part))) return null;
  return {
    r: parts[0] / 255,
    g: parts[1] / 255,
    b: parts[2] / 255,
    a: parts.length >= 4 && Number.isFinite(parts[3]) ? parts[3] : 1
  };
}

function relativeLuminance(color) {
  const channel = value => {
    if (value <= 0.03928) return value / 12.92;
    return ((value + 0.055) / 1.055) ** 2.4;
  };

  return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
}

function contrastRatio(foreground, background) {
  const lighter = Math.max(relativeLuminance(foreground), relativeLuminance(background));
  const darker = Math.min(relativeLuminance(foreground), relativeLuminance(background));
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
      const parts = match[1].split(",").map(part => Number.parseFloat(part.trim()));
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
      backgroundColor: normalizeColor(backgroundColor),
      borderColor: normalizeColor(style.borderTopColor),
      outlineColor: normalizeColor(style.outlineColor)
    };
  });
}

async function assertTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const foreground = parseRgbColor(colors.color);
  const background = parseRgbColor(colors.backgroundColor);
  expect(foreground, `${label} foreground color parses`).not.toBeNull();
  expect(background, `${label} background color parses`).not.toBeNull();
  expect(contrastRatio(foreground, background), `${label} text contrast`).toBeGreaterThanOrEqual(4.5);
}

async function assertNonTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const stroke = parseRgbColor(colors.outlineColor) || parseRgbColor(colors.borderColor);
  const background = parseRgbColor(colors.backgroundColor);
  expect(stroke, `${label} non-text color parses`).not.toBeNull();
  expect(background, `${label} background color parses`).not.toBeNull();
  expect(contrastRatio(stroke, background), `${label} non-text contrast`).toBeGreaterThanOrEqual(3);
}

function noMatchRow(page) {
  return page
    .getByTestId("inbound-record-row")
    .filter({ has: page.locator(".badge-warning", { hasText: "No match" }) })
    .first();
}

test.describe("structural assertions — 6 D-01 pillar facts", () => {

  // =========================================================================
  // FACT 1 — ARIA roles/states (Color/Elevation pillar context, correctness fact)
  // Gate: fail-on-any-violation (ARIA correctness is not aesthetic)
  // =========================================================================
  test.describe("ARIA roles/states", () => {

    test("Operator: selected delivery row has aria-selected=true, nav has aria-current=page", async ({ page }) => {
      await openOperator(page);

      // Click the first delivery row and assert aria-selected is set
      const firstRow = page.getByTestId("operator-delivery-row").first();
      await firstRow.click();
      await expect(firstRow).toHaveAttribute("aria-selected", "true");

      // Assert a nav link with aria-current="page" exists (getByRole with current:true)
      await expect(
        page.getByRole("navigation").getByRole("link", { current: "page" }).first()
      ).toBeVisible();
    });

    test("Inbound: page navigation landmark exists", async ({ page }) => {
      await openInbound(page);
      // Assert the page has a navigation landmark
      await expect(page.getByRole("navigation").first()).toBeVisible();
    });

    test("Preview: preview-orientation testId exists on browser-preview-empty route", async ({ page }) => {
      // openPreview already asserts preview-orientation is visible
      await openPreviewEmpty(page);
      await expect(page.getByTestId("preview-orientation")).toBeVisible();
    });

  });

  // =========================================================================
  // FACT 2 — Touch targets >= 44px (Spacing pillar)
  // Gate: fail-on-any-violation for primary interactive elements (nav links, CTA buttons)
  // Dense timeline rows are advisory only — not asserted here
  // =========================================================================
  test.describe("touch targets >= 44px", () => {

    test("Operator: primary CTA button (btn-primary) height >= 44px at 390px viewport", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openOperator(page);

      // Assert the primary CTA button (btn-primary class, min-h-11 in source) is >= 44px.
      // Uses CSS class selector to target only primary interactive elements — NOT dense-list
      // row controls (e.g., small replay/sort buttons) which are advisory-only touch-target
      // candidates (those are tracked as GAP rows in RATCHET-GAP-REGISTER.md, not as test
      // failures here — per the plan's gate-now vs record-as-GAP split).
      //
      // The primary filter CTA is inside the mobile disclosure; open it before measuring.
      await page.getByTestId("operator-filters-toggle").click();
      const primaryBtn = page.locator(".btn-primary:visible").first();
      await expect(primaryBtn).toBeVisible();
      const box = await primaryBtn.boundingBox();
      expect(box).not.toBeNull();
      expect(box.height).toBeGreaterThanOrEqual(44);
    });

    test("Operator: filter toggle and detail back controls meet touch target floor", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openOperator(page);

      const filterToggle = page.getByTestId("operator-filters-toggle");
      await expect(filterToggle).toBeVisible();
      const filterBox = await filterToggle.boundingBox();
      expect(filterBox).not.toBeNull();
      expect(filterBox.height).toBeGreaterThanOrEqual(44);

      await page.getByTestId("operator-delivery-row").first().click();
      const back = page.getByTestId("operator-detail-back");
      await expect(back).toBeVisible();
      const backBox = await back.boundingBox();
      expect(backBox).not.toBeNull();
      expect(backBox.height).toBeGreaterThanOrEqual(44);
    });

    test("Inbound: first nav link height >= 44px at 390px viewport", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openInbound(page);

      const navLink = page.getByRole("navigation").getByRole("link").first();
      const box = await navLink.boundingBox();
      expect(box).not.toBeNull();
      expect(box.height).toBeGreaterThanOrEqual(44);
    });

    test("Preview: any visible button or link >= 44px at 390px viewport", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      // openPreview navigates directly — no authenticated session needed
      await page.goto("/ops/browser-preview-empty");
      await expect(page.getByTestId("preview-orientation")).toBeVisible();

      // Check either a button or a nav link is >= 44px
      const buttons = page.getByRole("button");
      const links = page.getByRole("link");

      const buttonCount = await buttons.count();
      const linkCount = await links.count();

      if (buttonCount > 0) {
        const box = await buttons.first().boundingBox();
        if (box) {
          expect(box.height).toBeGreaterThanOrEqual(44);
          return;
        }
      }

      if (linkCount > 0) {
        const box = await links.first().boundingBox();
        if (box) {
          expect(box.height).toBeGreaterThanOrEqual(44);
        }
      }
    });

  });

  // =========================================================================
  // FACT 3 — font-weight in {400, 700} (Type pillar)
  // Gate: fail-on-any-violation (400 body, 700 bold — no intermediate weights)
  // Pitfall: do NOT assert on text-xl elements (known advisory TYPE violations per Phase 94)
  // Pitfall: do NOT assert 500/600 absent — font fallbacks may normalize intermediate weights
  // =========================================================================
  test.describe("font-weight in {400, 700}", () => {

    test("Operator: body text is 400, first h1 heading is 700", async ({ page }) => {
      await openOperator(page);

      const bodyWeight = await page.locator("body").evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(bodyWeight).toBe("400");

      const h1Weight = await page.getByRole("heading", { level: 1 }).first().evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(h1Weight).toBe("700");
    });

    test("Inbound: body text is 400, first heading is 700", async ({ page }) => {
      await openInbound(page);

      const bodyWeight = await page.locator("body").evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(bodyWeight).toBe("400");

      const headingWeight = await page.getByRole("heading").first().evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(headingWeight).toBe("700");
    });

    test("Preview: body text is 400", async ({ page }) => {
      await openPreviewEmpty(page);

      const bodyWeight = await page.locator("body").evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(bodyWeight).toBe("400");
    });

  });

  // =========================================================================
  // OPERATOR PHASE 98 — per-state, responsive-grid, and heading assertions
  // These assertions extend the structural layer without adding LLM baseline cells.
  // =========================================================================
  test.describe("operator state coverage and responsive grid", () => {

    test("Operator: deliveries page exposes exactly one h1", async ({ page }) => {
      await openOperator(page);
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
    });

    test("Operator: per-state delivery cells are reachable by URL", async ({ page }) => {
      await openOperator(page);

      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=does-not-exist`);
      await expect(page.getByTestId("operator-detail-error")).toBeVisible();

      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&status=queued`);
      const filteredEmpty = page.getByTestId("operator-empty-filtered");
      await expect(filteredEmpty).toBeVisible();
      await expect(filteredEmpty.getByRole("button", { name: "Clear filters" })).toBeVisible();

      await page.goto(`/ops/mail?tenant_id=browser-empty&view=deliveries`);
      const trulyEmpty = page.getByTestId("operator-empty-truly");
      await expect(trulyEmpty).toBeVisible();
      await expect(trulyEmpty.getByRole("button", { name: "Clear filters" })).toHaveCount(0);

      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&status=suppressed`);
      const suppressedRow = page.getByTestId("operator-delivery-row").first();
      await expect(suppressedRow).toContainText("Unknown");
      await expect(suppressedRow.locator(".badge-outline")).toContainText("Unknown");
    });

    test("Operator: master-detail grid follows 390/768/1440 responsive contract", async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 900 });
      await openOperator(page);
      let columns = parseGridColumns(
        await page.getByTestId("operator-master-detail").evaluate(
          el => getComputedStyle(el).getPropertyValue("grid-template-columns")
        )
      );
      expectRatio(columns, 0.4);

      await page.setViewportSize({ width: 1440, height: 900 });
      columns = parseGridColumns(
        await page.getByTestId("operator-master-detail").evaluate(
          el => getComputedStyle(el).getPropertyValue("grid-template-columns")
        )
      );
      expectRatio(columns, 0.33);

      await page.setViewportSize({ width: 390, height: 844 });
      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
      const gridBox = await page.getByTestId("operator-master-detail").boundingBox();
      const listBox = await page.getByTestId("operator-deliveries-list-card").boundingBox();
      expect(gridBox).not.toBeNull();
      expect(listBox).not.toBeNull();
      expect(listBox.width / gridBox.width).toBeGreaterThan(0.95);

      await page.getByTestId("operator-delivery-row").first().click();
      await expect(page.getByTestId("operator-deliveries-list-card")).toBeHidden();
      await expect(page.getByTestId("operator-detail-back")).toBeVisible();
    });

  });

  test.describe("inbound state coverage, responsive grid, and contrast", () => {

    test("Inbound: page exposes exactly one h1", async ({ page }) => {
      await openInbound(page);
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
    });

    test("Inbound: master-detail grid follows 390/768/1440 responsive contract", async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 900 });
      await openInbound(page);
      let columns = parseGridColumns(
        await page.getByTestId("inbound-master-detail").evaluate(
          el => getComputedStyle(el).getPropertyValue("grid-template-columns")
        )
      );
      expectRatio(columns, 0.4);

      await page.setViewportSize({ width: 1440, height: 1000 });
      await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
      columns = parseGridColumns(
        await page.getByTestId("inbound-master-detail").evaluate(
          el => getComputedStyle(el).getPropertyValue("grid-template-columns")
        )
      );
      expectRatio(columns, 0.33);

      await page.setViewportSize({ width: 390, height: 844 });
      await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
      const gridBox = await page.getByTestId("inbound-master-detail").boundingBox();
      const listBox = await page.getByTestId("inbound-records-list-card").boundingBox();
      expect(gridBox).not.toBeNull();
      expect(listBox).not.toBeNull();
      expect(listBox.width / gridBox.width).toBeGreaterThan(0.95);

      await noMatchRow(page).click();
      await expect(page.getByTestId("inbound-records-list-card")).toBeHidden();
      await expect(page.getByTestId("inbound-detail-back")).toBeVisible();

      const filterToggleBox = await page.getByTestId("inbound-filters-toggle").boundingBox();
      const backBox = await page.getByTestId("inbound-detail-back").boundingBox();
      expect(filterToggleBox).not.toBeNull();
      expect(backBox).not.toBeNull();
      expect(filterToggleBox.height).toBeGreaterThanOrEqual(44);
      expect(backBox.height).toBeGreaterThanOrEqual(44);
    });

    test("Inbound: no-tenant truly-empty filtered-empty detail-error loading contract and selected/detail flow are named", async ({
      page
    }) => {
      await openInbound(page, "");
      await expect(page.getByRole("heading", { name: "No tenant selected" })).toBeVisible();

      await page.goto(`/ops/mail/inbound?tenant_id=browser-empty`);
      await expect(page.getByText("No InboundMessages yet")).toBeVisible();

      await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&search=impossible-filtered-empty`);
      await expect(page.getByText("No InboundMessages match these filters")).toBeVisible();

      await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&inbound_id=does-not-exist`);
      await expect(page.getByTestId("inbound-detail-error")).toBeVisible();

      await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
      await noMatchRow(page).click();
      await expect(page).toHaveURL(/inbound_id=/);
      await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
      await expect(page.getByTestId("inbound-trace-clause")).not.toHaveCount(0);
      await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();
      await expect(page.getByTestId("inbound-evidence-redacted")).toBeVisible();
      await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
      await expect(noMatchRow(page)).toHaveAttribute("aria-selected", "true");

      const source = await page.request.get("/ops/mail/inbound?tenant_id=browser-tenant");
      expect(source.ok()).toBeTruthy();
    });

    test("Inbound: loading contract remains synchronous", async () => {
      // loading contract: D-10 permits no explicit loading UI when the LiveView stays synchronous.
      const source = require("fs").readFileSync("lib/mailglass_admin/inbound_live.ex", "utf8");
      expect(source).not.toContain("assign_async");
      expect(source).not.toContain('data-testid="inbound-loading"');
      expect(source).not.toContain("Loading InboundMessages...");
    });

    test("Inbound: WCAG AA contrast matrix covers light/dark themes at 390/768/1440", async ({
      page,
      browser
    }) => {
      const themes = [
        { name: "light", query: "", expectedTheme: "mailglass-light" },
        { name: "dark", query: "theme=dark", expectedTheme: "mailglass-dark" }
      ];
      const viewports = [
        { width: 390, height: 844 },
        { width: 768, height: 900 },
        { width: 1440, height: 1000 }
      ];

      for (const theme of themes) {
        for (const viewport of viewports) {
          await page.setViewportSize(viewport);
          const query = `tenant_id=${tenantId}${theme.query ? `&${theme.query}` : ""}`;
          await openInbound(page, query);
          await expect(page.locator(`[data-theme="${theme.expectedTheme}"]`).first()).toBeVisible();

          await assertTextContrastAA(page.getByTestId("inbound-overview"), `${theme.name} ${viewport.width} inbound-overview`);

          const row = noMatchRow(page);
          await row.click();
          await expect(page.getByTestId("inbound-detail-column")).toBeVisible();
          await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
          await assertTextContrastAA(page.getByTestId("inbound-routing-trace"), `${theme.name} ${viewport.width} inbound-routing-trace`);
          await assertTextContrastAA(page.getByTestId("inbound-route-card").first(), `${theme.name} ${viewport.width} inbound-route-card`);
          await assertTextContrastAA(page.getByTestId("inbound-trace-clause").first(), `${theme.name} ${viewport.width} inbound-trace-clause`);
          const selectedBoundary =
            viewport.width < 768 ? page.getByTestId("inbound-detail-back") : row;
          await selectedBoundary.focus();
          await assertNonTextContrastAA(selectedBoundary, `${theme.name} ${viewport.width} selected/detail flow`);

          await assertTextContrastAA(page.getByTestId("inbound-evidence-card"), `${theme.name} ${viewport.width} inbound-evidence-card`);
          await assertTextContrastAA(page.getByTestId("inbound-evidence-redacted"), `${theme.name} ${viewport.width} inbound-evidence-redacted`);
          await page.getByTestId("inbound-evidence-reveal").click();
          await assertTextContrastAA(page.getByTestId("inbound-evidence-raw"), `${theme.name} ${viewport.width} inbound-evidence-raw`);

          const deniedQuery = `tenant_id=${denyRevealTenantId}${theme.query ? `&${theme.query}` : ""}`;
          const deniedContext = await browser.newContext();
          const deniedPage = await deniedContext.newPage();

          try {
            await deniedPage.setViewportSize(viewport);
            await openInbound(deniedPage, deniedQuery, "deny-reveal", denyRevealTenantId);
            await noMatchRow(deniedPage).click();
            await deniedPage.getByTestId("inbound-evidence-reveal").click();
            await expect(deniedPage.getByTestId("inbound-evidence-denied")).toBeVisible();
            await expect(deniedPage.getByTestId("inbound-evidence-raw")).toHaveCount(0);
            await assertTextContrastAA(deniedPage.getByTestId("inbound-evidence-denied"), `${theme.name} ${viewport.width} inbound-evidence-denied`);
          } finally {
            await deniedContext.close();
          }

          await openInbound(page, theme.query, "operator-1");
          await assertTextContrastAA(page.getByRole("heading", { name: "No tenant selected" }), `${theme.name} ${viewport.width} no-tenant`);
          await openInbound(page, `tenant_id=browser-empty${theme.query ? `&${theme.query}` : ""}`, "operator-1");
          await assertTextContrastAA(page.getByText("No InboundMessages yet"), `${theme.name} ${viewport.width} truly-empty`);
          await openInbound(page, `tenant_id=${tenantId}&search=filtered-empty${theme.query ? `&${theme.query}` : ""}`, "operator-1");
          await assertTextContrastAA(page.getByText("No InboundMessages match these filters"), `${theme.name} ${viewport.width} filtered-empty`);
          await openInbound(page, `tenant_id=${tenantId}&inbound_id=does-not-exist${theme.query ? `&${theme.query}` : ""}`, "operator-1");
          await assertTextContrastAA(page.getByTestId("inbound-detail-error"), `${theme.name} ${viewport.width} detail-error`);
        }
      }
    });

  });

  test.describe("preview state coverage, responsive theme matrix, and contrast", () => {

    test("Preview: explicit light and dark index and scenario themes apply to shell", async ({ page }) => {
      await openPreviewIndex(page, "theme=light");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");

      await openPreviewIndex(page, "theme=dark");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");

      await openPreviewScenario(page, "theme=light");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");

      await openPreviewScenario(page, "theme=dark");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");
    });

    test("Preview: 390px mobile Mailables navigation reaches a real scenario link", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openPreviewIndex(page, "theme=dark");

      const mobileMailables = page.getByTestId("preview-mobile-mailables");
      await expect(mobileMailables).toBeVisible();
      await expect(mobileMailables.getByText("Mailables", { exact: true })).toBeVisible();
      await expect(
        mobileMailables.locator("a[href*='MailglassAdmin.Fixtures.HappyMailer/welcome_default']")
      ).toHaveAttribute("href", /theme=dark/);
    });

    test("Preview: no-Mailables empty branch exposes setup action only", async ({ page }) => {
      await openPreviewEmpty(page);
      await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
      await expect(page.getByRole("link", { name: "Read preview setup", exact: true })).toBeVisible();
      await expect(page.getByRole("link", { name: "Preview the first Mailable", exact: true })).toHaveCount(0);
    });

    test("Preview: BrokenMailer render-error branch names recovery target", async ({ page }) => {
      await openPreviewError(page);
      await expect(page.getByTestId("preview-render-error")).toBeVisible();
      await expect(page.getByText("Something went wrong")).toHaveCount(0);
    });

    test("Preview: start, empty, scenario, and render-error branches expose exactly one h1", async ({ page }) => {
      await openPreviewIndex(page, "theme=light");
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);

      await openPreviewEmpty(page);
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);

      await openPreviewScenario(page, "theme=light");
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);

      await openPreviewError(page, "theme=light");
      await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
    });

    test("Preview: admin chrome and preview frame toggles are independent", async ({ page }) => {
      await openPreviewScenario(page, "theme=light");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
      await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "light");

      await page.getByTestId("preview-frame-theme-toggle").click();
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
      await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");

      await page.getByTestId("preview-admin-theme-toggle").click();
      await expect(page).toHaveURL(/theme=dark/);
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");
      await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");
    });

    test("Preview: WCAG AA contrast matrix covers light/dark themes at 390/768/1440", async ({ page }) => {
      const themes = [
        { name: "light", query: "theme=light", expectedTheme: "mailglass-light" },
        { name: "dark", query: "theme=dark", expectedTheme: "mailglass-dark" }
      ];
      const viewports = [
        { width: 390, height: 844 },
        { width: 768, height: 900 },
        { width: 1440, height: 1000 }
      ];

      for (const theme of themes) {
        for (const viewport of viewports) {
          await page.setViewportSize(viewport);
          await openPreviewScenario(page, theme.query);
          await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", theme.expectedTheme);
          await assertTextContrastAA(page.getByTestId("preview-shell"), `${theme.name} ${viewport.width} preview-shell`);

          const nav =
            viewport.width < 768
              ? page.getByTestId("preview-mobile-mailables")
              : page.getByTestId("preview-sidebar-desktop");

          await assertTextContrastAA(nav, `${theme.name} ${viewport.width} preview-mailables`);
          await assertTextContrastAA(page.getByTestId("preview-header-controls"), `${theme.name} ${viewport.width} preview-header-controls`);
          await assertTextContrastAA(page.getByTestId("preview-assigns-form"), `${theme.name} ${viewport.width} preview-assigns-form`);
          await assertTextContrastAA(page.getByTestId("preview-tab-strip"), `${theme.name} ${viewport.width} preview-tab-strip`);
          await assertTextContrastAA(page.getByTestId("preview-pane"), `${theme.name} ${viewport.width} preview-pane`);

          const frameToggle = page.getByTestId("preview-frame-theme-toggle");
          await frameToggle.focus();
          await assertNonTextContrastAA(frameToggle, `${theme.name} ${viewport.width} preview-frame-toggle-focus`);
        }
      }
    });

  });

  // =========================================================================
  // FACT 4 — Reduced-motion suppresses animation (Motion+A11y pillar)
  // Gate: fail-on-any-violation (a11y requirement)
  // Pattern: emulateMedia BEFORE navigation (mirrors operator.spec.js:229)
  // =========================================================================
  test.describe("reduced-motion suppresses animation", () => {

    test("Operator: primary content area visible and stable under reduced-motion", async ({ page }) => {
      // emulateMedia MUST precede page navigation
      await page.emulateMedia({ reducedMotion: "reduce" });
      await openOperator(page);

      await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
    });

    test("Inbound: page heading visible under reduced-motion", async ({ page }) => {
      await page.emulateMedia({ reducedMotion: "reduce" });
      await openInbound(page);

      await expect(page.getByRole("heading").first()).toBeVisible();
    });

    test("Preview: preview-orientation visible under reduced-motion", async ({ page }) => {
      await page.emulateMedia({ reducedMotion: "reduce" });
      await page.goto("/ops/browser-preview-empty");
      await expect(page.getByTestId("preview-orientation")).toBeVisible();
    });

    // MOTION-02 structural proof: under prefers-reduced-motion, computed
    // animation-duration and transition-duration must collapse to effectively
    // zero. app.css:292-300 uses 0.01ms !important (not 0ms), so assert ≤ 0.05
    // (50ms) — never === 0. emulateMedia MUST precede navigation (done above
    // per the FACT 4 pattern — each test fixture runs emulateMedia first).
    test("Operator: motion-reveal computed duration effectively zero under reduced-motion", async ({ page }) => {
      // emulateMedia MUST precede page navigation
      await page.emulateMedia({ reducedMotion: "reduce" });
      await openOperator(page);

      // .motion-reveal on the detail pane is conditional (renders only after
      // delivery selection). Click the first row to bring it into the DOM.
      const firstRow = page.getByTestId("operator-deliveries-list").getByRole("button").first();
      await firstRow.click();

      // Wait for the detail pane to appear
      const el = page.locator(".motion-reveal").first();
      await expect(el).toBeVisible();

      // app.css:294 sets animation-duration: 0.01ms !important under reduce.
      // app.css:297 sets transition-duration: 0.01ms !important under reduce.
      // Assert ≤ 0.05s (50ms) — near-instant, never strict 0.
      const animDur = await el.evaluate(e => getComputedStyle(e).animationDuration);
      expect(parseFloat(animDur)).toBeLessThanOrEqual(0.05);

      const transDur = await el.evaluate(e => getComputedStyle(e).transitionDuration);
      expect(parseFloat(transDur)).toBeLessThanOrEqual(0.05);
    });

  });

  // =========================================================================
  // FACT 5 — Visible focus rings (Motion+A11y pillar)
  // Gate: fail-on-any-violation (a11y requirement)
  // Pitfall: assert outlineWidth specifically (not outline shorthand — serialization varies)
  // =========================================================================
  test.describe("visible focus rings", () => {

    test("Operator: first link has non-zero outlineWidth on focus", async ({ page }) => {
      await openOperator(page);

      const link = page.getByRole("link").first();
      await link.focus();
      const outlineWidth = await link.evaluate(
        el => getComputedStyle(el).outlineWidth
      );
      expect(parseFloat(outlineWidth)).toBeGreaterThan(0);
    });

    test("Inbound: first link has non-zero outlineWidth on focus", async ({ page }) => {
      await openInbound(page);

      const link = page.getByRole("link").first();
      await link.focus();
      const outlineWidth = await link.evaluate(
        el => getComputedStyle(el).outlineWidth
      );
      expect(parseFloat(outlineWidth)).toBeGreaterThan(0);
    });

    test("Preview: first link or button has non-zero outlineWidth on focus", async ({ page }) => {
      await openPreviewEmpty(page);

      const links = page.getByRole("link");
      const buttons = page.getByRole("button");

      const linkCount = await links.count();
      const buttonCount = await buttons.count();

      expect(linkCount + buttonCount).toBeGreaterThan(0);

      // Try a link first; fall back to a button if no links exist
      const focusable = linkCount > 0 ? links.first() : buttons.first();
      await focusable.focus({ timeout: 5000 });

      const outlineWidth = await focusable.evaluate(
        el => getComputedStyle(el).outlineWidth
      );
      expect(parseFloat(outlineWidth)).toBeGreaterThan(0);
    });

  });

  // =========================================================================
  // FACT 6 — Accent color only on allowlisted elements (Color pillar)
  // Gate: fail-on-any-violation
  // Post-Phase-94 this should be clean (accent confined by token re-baseline)
  // Pitfall: dark theme may have different accent surfaces — checked at RGB level
  // =========================================================================
  test.describe("accent color only on allowlisted elements", () => {

    test("Operator: non-allowlisted elements do not carry the accent color", async ({ page }) => {
      await openOperator(page);

      // Check a curated set of non-allowlisted structural elements
      // body, deliveries-list container, nav container background
      const elementLocators = [
        page.locator("body"),
        page.getByTestId("operator-deliveries-list"),
        page.getByRole("navigation").first()
      ];

      for (const locator of elementLocators) {
        const { bg, color } = await locator.evaluate(el => {
          const cs = getComputedStyle(el);
          return { bg: cs.backgroundColor, color: cs.color };
        });

        const allowlisted = await isAccentAllowlisted(page, locator);

        if (!allowlisted) {
          expect(bg).not.toBe(ACCENT_LIGHT_RGB);
          expect(color).not.toBe(ACCENT_LIGHT_RGB);
        }
      }
    });

    test("Inbound: non-allowlisted elements do not carry the accent color", async ({ page }) => {
      await openInbound(page);

      const elementLocators = [
        page.locator("body"),
        page.getByRole("navigation").first()
      ];

      for (const locator of elementLocators) {
        const { bg, color } = await locator.evaluate(el => {
          const cs = getComputedStyle(el);
          return { bg: cs.backgroundColor, color: cs.color };
        });

        const allowlisted = await isAccentAllowlisted(page, locator);

        if (!allowlisted) {
          expect(bg).not.toBe(ACCENT_LIGHT_RGB);
          expect(color).not.toBe(ACCENT_LIGHT_RGB);
        }
      }
    });

    test("Preview: non-allowlisted elements do not carry the accent color", async ({ page }) => {
      await openPreviewEmpty(page);

      const elementLocators = [
        page.locator("body"),
        page.getByTestId("preview-orientation")
      ];

      for (const locator of elementLocators) {
        const { bg, color } = await locator.evaluate(el => {
          const cs = getComputedStyle(el);
          return { bg: cs.backgroundColor, color: cs.color };
        });

        const allowlisted = await isAccentAllowlisted(page, locator);

        if (!allowlisted) {
          expect(bg).not.toBe(ACCENT_LIGHT_RGB);
          expect(color).not.toBe(ACCENT_LIGHT_RGB);
        }
      }
    });

  });

  // =========================================================================
  // FACT 7 — enter/exit asymmetry (Motion pillar, MOTION-LD-02/04/13)
  // Gate: fail-on-any-violation once un-skipped by Plan 102-03
  // Pattern: open operator surface, select delivery, assert phx-remove attribute
  //   or computed exit transitionDuration ≈ 0.15s on the detail pane element.
  //
  // This test is marked fixme pending Plan 102-03 (which adds phx-remove to the
  // detail pane — operator_live.ex:466). Un-skip in 102-03's closing task.
  // =========================================================================
  test.describe("enter/exit asymmetry", () => {

    // TODO(102-03): Un-skip this test once phx-remove is added to the
    // #delivery-detail-* element in operator_live.ex:466.
    test.fixme("Operator: detail pane carries phx-remove exit attribute (MOTION-LD-13)", async ({ page }) => {
      await openOperator(page);

      // Select the first delivery by clicking the first row button in the list
      const firstRow = page.getByTestId("operator-deliveries-list").getByRole("button").first();
      await firstRow.click();

      // The detail pane element ID is delivery-detail-{id}; locate by id prefix pattern
      const detailPane = page.locator('[id^="delivery-detail-"]').first();
      await expect(detailPane).toBeVisible();

      // Presence proof: phx-remove attribute must be non-null (set by Plan 102-03)
      const phxRemove = await detailPane.getAttribute("phx-remove");
      expect(phxRemove).not.toBeNull();
    });

  });

  // =========================================================================
  // GALLERY SURFACE — Phase 97
  // The gallery at /dev/mail/gallery is a dev-only LiveView with stable
  // data-testid="gallery-{component}-{state}" cells and twin data-theme wrappers.
  // GAP-05 closed by Phase 97 plan 08 (RATCHET-GAP-REGISTER.md).
  // =========================================================================
  test.describe("gallery surface — Phase 97", () => {

    test("gallery renders status_badge specimens for all 5 badge groups", async ({ page }) => {
      await openGallery(page);
      // badge-success group
      await expect(page.getByTestId("gallery-status_badge-delivered")).toBeVisible();
      // badge-primary group
      await expect(page.getByTestId("gallery-status_badge-dispatched")).toBeVisible();
      // badge-error group
      await expect(page.getByTestId("gallery-status_badge-bounced")).toBeVisible();
      // badge-warning group
      await expect(page.getByTestId("gallery-status_badge-deferred")).toBeVisible();
      // badge-outline group
      await expect(page.getByTestId("gallery-status_badge-autoresponded")).toBeVisible();
    });

    test("gallery renders nav_link active and inactive states", async ({ page }) => {
      await openGallery(page);
      await expect(page.getByTestId("gallery-nav_link-active")).toBeVisible();
      await expect(page.getByTestId("gallery-nav_link-inactive")).toBeVisible();
    });

    test("gallery renders flash states", async ({ page }) => {
      await openGallery(page);
      await expect(page.getByTestId("gallery-flash-error-kind")).toBeVisible();
      await expect(page.getByTestId("gallery-flash-success-kind")).toBeVisible();
    });

    test("gallery twin-theme wrappers present per cell", async ({ page }) => {
      await openGallery(page);
      const cell = page.getByTestId("gallery-status_badge-delivered");
      await expect(cell.locator('[data-theme="mailglass-light"]')).toBeVisible();
      await expect(cell.locator('[data-theme="mailglass-dark"]')).toBeVisible();
    });

    test("gallery renders routing_trace and evidence_card inbound specimens", async ({ page }) => {
      await openGallery(page);
      await expect(page.getByTestId("gallery-routing_trace-empty")).toBeVisible();
      await expect(page.getByTestId("gallery-evidence_card-redacted")).toBeVisible();
    });

  });

});
