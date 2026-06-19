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

const PRIMITIVE_VIEWPORTS = [
  { width: 320, height: 900 },
  { width: 768, height: 900 },
  { width: 1280, height: 900 }
];

const PRIMITIVE_STATES = {
  nav_link: ["active", "inactive", "hover-ready", "focus-visible", "disabled", "long-label"],
  nav_pill: ["active", "inactive", "hover-ready", "focus-visible", "disabled", "long-label"],
  tenant_chip: ["with-tenant", "no-tenant", "long-tenant", "non-ascii-tenant"],
  theme_picker: ["system-selected", "light-selected", "dark-selected", "hover-ready", "focus-visible", "disabled"],
  stat_card: [
    "neutral",
    "info",
    "success",
    "warning",
    "error",
    "empty",
    "loading",
    "unavailable",
    "long-label",
    "long-value"
  ]
};

const LOADING_NOT_APPLICABLE_PRIMITIVES = ["nav_link", "nav_pill", "tenant_chip", "theme_picker"];

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

  const srgb = String(value).trim().match(/^color\(srgb\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)(?:\s*\/\s*([0-9.]+))?\)$/i);
  if (srgb) {
    return {
      r: Number.parseFloat(srgb[1]),
      g: Number.parseFloat(srgb[2]),
      b: Number.parseFloat(srgb[3]),
      a: srgb[4] ? Number.parseFloat(srgb[4]) : 1
    };
  }

  const match = String(value).match(/rgba?\(([^)]+)\)/);
  if (!match) return null;
  const parts = match[1]
    .replace(/\//g, " ")
    .split(/[,\s]+/)
    .filter(Boolean)
    .map(part => part.trim().endsWith("%")
      ? (Number.parseFloat(part) / 100) * 255
      : Number.parseFloat(part));
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
      const parts = match[1]
        .replace(/\//g, " ")
        .split(/[,\s]+/)
        .filter(Boolean)
        .map(part => Number.parseFloat(part.trim()));
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
  let background = parseRgbColor(colors.backgroundColor);

  if (!background) {
    const parentBackground = await locator.first().evaluate(el => {
      const parent = el.parentElement;
      return parent ? getComputedStyle(parent).backgroundColor : "rgb(255, 255, 255)";
    });
    background = parseRgbColor(parentBackground);
  }

  expect(stroke, `${label} non-text color parses`).not.toBeNull();
  expect(background, `${label} background color parses`).not.toBeNull();
  expect(contrastRatio(stroke, background), `${label} non-text contrast`).toBeGreaterThanOrEqual(3);
}

async function assertTouchTarget(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const box = await locator.first().boundingBox();
  expect(box, `${label} target-size box`).not.toBeNull();
  // Chromium can report 44px CSS floors as 43.89px after subpixel layout.
  // Round to the rendered pixel for the structural target-size assertion.
  expect(Math.round(box.width), `${label} target-size width`).toBeGreaterThanOrEqual(44);
  expect(Math.round(box.height), `${label} target-size height`).toBeGreaterThanOrEqual(44);
}

async function assertFocusAppearanceAndNotObscured(page, locator, label) {
  const target = locator.first();
  await expect(target, label).toBeVisible();
  await target.focus();

  const focusState = await target.evaluate(el => {
    const style = getComputedStyle(el);
    const rect = el.getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const hit = document.elementFromPoint(x, y);

    return {
      outlineWidth: Number.parseFloat(style.outlineWidth),
      outlineStyle: style.outlineStyle,
      notObscured: hit === el || el.contains(hit)
    };
  });

  expect(focusState.outlineWidth, `${label} focus indicator width`).toBeGreaterThanOrEqual(2);
  expect(focusState.outlineStyle, `${label} focus indicator style`).not.toBe("none");
  expect(focusState.notObscured, `${label} Focus Not Obscured`).toBeTruthy();

  await assertNonTextContrastAA(target, label);
}

async function expectNoDataTheme(locator, label) {
  expect(await locator.first().getAttribute("data-theme"), label).toBeNull();
}

function primitiveCell(page, component, state) {
  return page.getByTestId(`gallery-${component}-${state}`);
}

function primitiveWrapper(page, component, state, theme) {
  const cell = primitiveCell(page, component, state);
  if (theme === "system") return page.getByTestId(`gallery-${component}-${state}-system`);
  return cell.locator(`[data-theme="mailglass-${theme}"]`).first();
}

async function assertPrimitiveThemeWrappers(page, component, state) {
  const light = primitiveWrapper(page, component, state, "light");
  const dark = primitiveWrapper(page, component, state, "dark");
  const system = primitiveWrapper(page, component, state, "system");

  await expect(light, `${component}/${state} light wrapper`).toBeVisible();
  await expect(dark, `${component}/${state} dark wrapper`).toBeVisible();
  await expect(system, `${component}/${state} system wrapper`).toBeVisible();
  await expectNoDataTheme(system, `${component}/${state} system wrapper`);
}

function primitiveTarget(wrapper, component) {
  switch (component) {
    case "nav_link":
    case "nav_pill":
      return wrapper.locator("a, [role='link']").first();
    case "tenant_chip":
      return wrapper.locator("span[title]").first();
    case "theme_picker":
      return wrapper.locator("fieldset").first();
    case "stat_card":
      return wrapper.locator("article").first();
    default:
      return wrapper;
  }
}

function themeOptionLabels(wrapper) {
  return wrapper.locator("fieldset label");
}

async function assertThemePickerSemantics(wrapper, selectedValue, label) {
  const radios = wrapper.locator('input[type="radio"]');
  await expect(radios, `${label} radio count`).toHaveCount(3);

  for (const text of ["System", "Light", "Dark"]) {
    await expect(wrapper.getByText(text, { exact: true }), `${label} ${text} label`).toBeVisible();
  }

  await expect(wrapper.locator(`input[type="radio"][value="${selectedValue}"]`), `${label} checked option`).toBeChecked();
  await expect(wrapper.locator("[aria-pressed]"), `${label} no pressed-button semantics`).toHaveCount(0);
  await expect(wrapper.getByRole("button"), `${label} no button-mode options`).toHaveCount(0);
}

async function assertHoverReady(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  await locator.first().hover();
  const cursor = await locator.first().evaluate(el => getComputedStyle(el).cursor);
  expect(["pointer", "auto"].includes(cursor), `${label} hover cursor`).toBeTruthy();
}

async function assertProgrammaticDisabled(locator, enabledLocator, label) {
  await expect(locator.first(), label).toBeVisible();

  const disabledState = await locator.first().evaluate(el => {
    const style = getComputedStyle(el);
    return {
      tag: el.tagName,
      disabled: el.disabled === true,
      ariaDisabled: el.getAttribute("aria-disabled"),
      href: el.getAttribute("href"),
      tabIndex: el.getAttribute("tabindex"),
      color: style.color,
      backgroundColor: style.backgroundColor,
      cursor: style.cursor,
      opacity: Number.parseFloat(style.opacity),
      pointerEvents: style.pointerEvents
    };
  });
  const enabledState = await enabledLocator.first().evaluate(el => {
    const style = getComputedStyle(el);
    return {
      color: style.color,
      backgroundColor: style.backgroundColor,
      cursor: style.cursor,
      opacity: Number.parseFloat(style.opacity),
      pointerEvents: style.pointerEvents
    };
  });

  expect(
    disabledState.disabled ||
      disabledState.ariaDisabled === "true" ||
      disabledState.tabIndex === "-1",
    `${label} programmatic disabled evidence`
  ).toBeTruthy();
  expect(disabledState.href, `${label} removes navigation href`).toBeNull();
  expect(
    disabledState.color !== enabledState.color ||
      disabledState.backgroundColor !== enabledState.backgroundColor ||
      disabledState.cursor !== enabledState.cursor ||
      disabledState.opacity !== enabledState.opacity ||
      disabledState.pointerEvents !== enabledState.pointerEvents,
    `${label} visually distinct from enabled state`
  ).toBeTruthy();
}

async function assertNoElementHorizontalOverflow(locator, label) {
  const overflow = await locator.first().evaluate(el => {
    return el.scrollWidth - el.clientWidth;
  });
  expect(overflow, `${label} horizontal overflow`).toBeLessThanOrEqual(1);
}

async function assertStatCardShape(wrapper, label) {
  const card = wrapper.locator("article").first();
  await expect(card, label).toBeVisible();

  const labelEl = card.locator("p").first();
  const valueEl = card.locator("p").nth(1);
  const severityEl = card.locator("p").nth(2);

  await expect(labelEl, `${label} label`).toHaveAttribute("title", /.+/);
  await expect(valueEl, `${label} value`).toHaveText(/.+/);
  await expect(severityEl.locator('[class*="hero-"]'), `${label} severity icon`).toBeVisible();
  await expect(severityEl.locator("span").last(), `${label} severity text`).toHaveText(/.+/);

  const valueStyle = await valueEl.evaluate(el => {
    const style = getComputedStyle(el);
    return {
      whiteSpace: style.whiteSpace,
      fontVariantNumeric: style.fontVariantNumeric,
      overflowWrap: style.overflowWrap
    };
  });
  expect(valueStyle.whiteSpace, `${label} value nowrap`).toBe("nowrap");
  expect(valueStyle.fontVariantNumeric, `${label} tabular numeric treatment`).toContain("tabular-nums");
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
      hitTag: hit ? hit.tagName : null,
      hitTestId: nearestTestId ? nearestTestId.getAttribute("data-testid") : null
    };
  });

  expect(
    hitTest.ok,
    `${label} panel is above scrim at centroid; hit=${hitTest.hitTestId || hitTest.hitTag}`
  ).toBeTruthy();
}

function noMatchRow(page) {
  return page
    .getByTestId("inbound-record-row")
    .filter({ has: page.locator(".badge-warning", { hasText: "No match" }) })
    .first();
}

async function openOperatorReplayModal(page) {
  await openOperator(page);
  await page.getByTestId("operator-delivery-row").first().click();
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
    .first();
  await replayableRow.click();
  await page.waitForURL(/inbound_id=/);
  await page.getByTestId("inbound-replay-open").click();

  const modal = page.getByTestId("inbound-replay-modal");
  await expect(modal).toBeVisible();
  return modal;
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
      await assertTouchTarget(filterToggle, "operator filter toggle");

      await page.getByTestId("operator-delivery-row").first().click();
      const back = page.getByTestId("operator-detail-back");
      await assertTouchTarget(back, "operator detail back");
    });

    test("Inbound: first nav link height >= 44px at 390px viewport", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openInbound(page);

      const navLink = page.getByRole("navigation").getByRole("link").first();
      await assertTouchTarget(navLink, "inbound first nav link");
    });

    test("Operator replay modal, nav, preview theme controls, and preview summary controls meet target-size floor", async ({
      page
    }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openOperator(page);
      await assertTouchTarget(page.getByRole("navigation").getByRole("link").first(), "operator nav link");

      const operatorModal = await openOperatorReplayModal(page);
      await assertTouchTarget(
        operatorModal.getByRole("button", { name: "Cancel", exact: true }),
        "operator replay modal cancel"
      );

      const inboundModal = await openInboundReplayModal(page);
      await assertTouchTarget(
        inboundModal.getByRole("button", { name: "Cancel", exact: true }),
        "inbound replay modal cancel"
      );
      await assertTouchTarget(page.getByTestId("inbound-replay-confirm"), "inbound replay modal confirm");

      await page.setViewportSize({ width: 390, height: 844 });
      await openPreviewScenario(page, "theme=light");
      await assertTouchTarget(page.getByTestId("preview-admin-theme-toggle"), "preview admin theme control");
      await assertTouchTarget(page.getByTestId("preview-frame-theme-toggle"), "preview frame theme control");
      await assertTouchTarget(
        page.getByTestId("preview-mobile-mailables").locator("summary").first(),
        "preview sidebar summary control"
      );
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

    test("Inbound: replay modal has focus-management parity with the operator modal (role/aria + Escape-to-close)", async ({ page }) => {
      await openInbound(page);

      // Select a replayable (non-no-match) row — the matched :accept row has an enabled replay button
      const replayableRow = page
        .getByTestId("inbound-record-row")
        .filter({ hasNot: page.locator(".badge-warning", { hasText: "No match" }) })
        .first();
      await replayableRow.click();
      await page.waitForURL(/inbound_id=/);

      // Open the replay modal via the trigger button
      await page.getByTestId("inbound-replay-open").click();

      // Assert DOM contract matches operator modal parity: role, aria-modal, Escape wiring
      const modal = page.getByTestId("inbound-replay-modal");
      await expect(modal).toBeVisible();
      expect(await modal.getAttribute("role")).toBe("dialog");
      expect(await modal.getAttribute("aria-modal")).toBe("true");
      expect(await modal.getAttribute("phx-window-keydown")).toBe("close_replay");
      expect(await modal.getAttribute("phx-key")).toBe("Escape");

      // Assert Escape-to-close closes the modal (routes to existing close_replay handler)
      await page.keyboard.press("Escape");
      await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
    });

  });

  test.describe("replay modal overlay stacking", () => {

    test("Operator and Inbound replay modal panels are top hit-test targets above their scrims", async ({
      page
    }) => {
      const operatorModal = await openOperatorReplayModal(page);
      await assertPanelAboveScrim(operatorModal, "operator-replay-modal");

      const inboundModal = await openInboundReplayModal(page);
      await assertPanelAboveScrim(inboundModal, "inbound-replay-modal");
    });

  });

  test.describe("preview state coverage, responsive theme matrix, and contrast", () => {

    test("Preview: explicit light and dark index and scenario themes apply to shell", async ({ page }) => {
      await openPreviewIndex(page, "theme=light");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-light");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");

      await openPreviewIndex(page, "theme=dark");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");

      await openPreviewScenario(page, "theme=light");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-light");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");

      await openPreviewScenario(page, "theme=dark");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");
      await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");
    });

    test("Preview: system/default root emits no explicit data-theme under light and dark OS schemes", async ({ page }) => {
      for (const colorScheme of ["light", "dark"]) {
        await page.emulateMedia({ colorScheme });

        await openPreviewIndex(page);
        await expectNoDataTheme(page.locator("html"), `${colorScheme} system root html`);
        await expectNoDataTheme(page.getByTestId("preview-shell"), `${colorScheme} system preview shell`);

        await page.emulateMedia({ colorScheme });
        await openPreviewScenario(page, "theme=system");
        await expectNoDataTheme(page.locator("html"), `${colorScheme} explicit system root html`);
        await expectNoDataTheme(page.getByTestId("preview-shell"), `${colorScheme} explicit system preview shell`);
      }
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

    test("Operator: first link has visible >=2px focus indicator and non-text contrast", async ({ page }) => {
      await openOperator(page);

      const link = page.getByRole("link").first();
      await assertFocusAppearanceAndNotObscured(page, link, "operator first link focus");
    });

    test("Inbound: first link has visible >=2px focus indicator and non-text contrast", async ({ page }) => {
      await openInbound(page);

      const link = page.getByRole("link").first();
      await assertFocusAppearanceAndNotObscured(page, link, "inbound first link focus");
    });

    test("Preview: theme and frame controls have visible >=2px focus indicators and non-text contrast", async ({
      page
    }) => {
      await openPreviewScenario(page, "theme=light");

      await assertFocusAppearanceAndNotObscured(
        page,
        page.getByTestId("preview-admin-theme-toggle"),
        "preview admin theme focus"
      );
      await assertFocusAppearanceAndNotObscured(
        page,
        page.getByTestId("preview-frame-theme-toggle"),
        "preview frame theme focus"
      );
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

    test("Operator: detail pane carries phx-remove exit attribute (MOTION-LD-13)", async ({ page }) => {
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

  // =========================================================================
  // APP SHELL — Phase 112
  // Integrated tenant, theme, navigation, and pagination proof.
  // =========================================================================
  test.describe("app shell structural proof — Phase 112", () => {

    test("sole tenant canonicalizes, explicit theme paints root, active nav has structural cues, and pagination boundaries are honest", async ({
      page
    }) => {
      await page.setViewportSize({ width: 1280, height: 900 });
      await page.context().clearCookies();
      const resetResponse = await page.request.get("/ops/browser-reset?scenario=sole");
      expect(resetResponse.ok()).toBeTruthy();

      await page.goto(
        `/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent("/ops/mail")}`
      );
      await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();

      await expect(page).toHaveURL(/\/ops\/mail\?/);
      await expect(page).toHaveURL(new RegExp(`tenant_id=${tenantId}`));
      await expect(page.getByTestId("tenant-selector")).toHaveCount(0);

      await page.context().addCookies([
        {
          name: "mailglass_admin_theme",
          value: "dark",
          domain: "127.0.0.1",
          path: "/ops/mail"
        }
      ]);

      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&page=1`);
      await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");

      const activeDesktop = page
        .locator('a[aria-current="page"]')
        .filter({ hasText: "Deliveries" })
        .first();
      await expect(activeDesktop).toBeVisible();
      await expect(activeDesktop).toHaveClass(/border-l-2/);
      await expect(activeDesktop).toHaveClass(/border-primary/);

      await expect(page.getByTestId("operator-result-count")).toContainText("6 results");
      await expect(page.getByTestId("operator-pagination")).toBeVisible();
      await expect(page.getByTestId("operator-pagination-prev-disabled")).toHaveAttribute("aria-disabled", "true");
      await expect(page.getByTestId("operator-pagination-next")).toHaveAttribute("href", /tenant_id=browser-tenant/);
      await expect(page.getByTestId("operator-pagination-next")).toHaveAttribute("href", /page=2/);

      await page.getByTestId("operator-pagination-next").click();
      await expect(page).toHaveURL(/tenant_id=browser-tenant/);
      await expect(page).toHaveURL(/page=2/);
      await expect(page.getByTestId("operator-pagination-prev")).toBeVisible();
      await expect(page.getByTestId("operator-pagination-next-disabled")).toHaveAttribute("aria-disabled", "true");

      await page.context().clearCookies();
      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
      await expect(page.locator("html")).not.toHaveAttribute("data-theme", "system");
    });

    test("multi-tenant selector preserves surface state and inbound pagination uses real boundaries", async ({
      page
    }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await page.context().clearCookies();
      const resetResponse = await page.request.get("/ops/browser-reset");
      expect(resetResponse.ok()).toBeTruthy();

      await page.goto(
        `/ops/browser-login?tenant_id=&return_to=${encodeURIComponent("/ops/mail/inbound?page=1")}`
      );

      await expect(page.getByTestId("tenant-selector")).toBeVisible();
      await expect(page.getByText("browser-tenant", { exact: true })).toBeVisible();
      await expect(page.getByText("deny-reveal", { exact: true })).toBeVisible();

      await page.getByRole("link", { name: /browser-tenant/ }).click();
      await expect(page).toHaveURL(/\/ops\/mail\/inbound\?/);
      await expect(page).toHaveURL(/tenant_id=browser-tenant/);

      const activeMobile = page.locator('a[aria-current="page"][href*="/ops/mail/inbound"]').last();
      await expect(activeMobile).toBeVisible();
      await expect(activeMobile).toHaveClass(/border-b-2/);
      await expect(activeMobile).toHaveClass(/border-primary/);

      await expect(page.getByTestId("inbound-result-count")).toContainText("9 results");
      await expect(page.getByTestId("inbound-pagination")).toBeVisible();
      await expect(page.getByTestId("inbound-pagination-prev-disabled")).toHaveAttribute("aria-disabled", "true");
      await expect(page.getByTestId("inbound-pagination-next")).toHaveAttribute("href", /tenant_id=browser-tenant/);
      await expect(page.getByTestId("inbound-pagination-next")).toHaveAttribute("href", /page=2/);
    });

  });

  // =========================================================================
  // PRIMITIVE STRUCTURAL MATRIX — Phase 110
  // Named primitives are proved against rendered, compiled CSS output across
  // exact 320/768/1280 widths and light/dark/system gallery wrappers.
  // =========================================================================
  test.describe("primitive gallery structural proof — Phase 110", () => {

    test("primitive cells render every planned state in light, dark, and system wrappers", async ({
      page
    }) => {
      await openGallery(page);

      const source = require("fs").readFileSync("lib/mailglass_admin/gallery_live.ex", "utf8");

      for (const viewport of PRIMITIVE_VIEWPORTS) {
        await page.setViewportSize(viewport);

        for (const [component, states] of Object.entries(PRIMITIVE_STATES)) {
          for (const state of states) {
            const cell = primitiveCell(page, component, state);
            await expect(cell, `${component}/${state} cell at ${viewport.width}`).toBeVisible();
            await assertPrimitiveThemeWrappers(page, component, state);

            for (const theme of ["light", "dark", "system"]) {
              const wrapper = primitiveWrapper(page, component, state, theme);
              await assertTextContrastAA(
                wrapper,
                `${theme} ${viewport.width} ${component}/${state}`
              );
            }
          }
        }

        await expect(primitiveCell(page, "stat_card", "loading"), `stat_card loading ${viewport.width}`).toBeVisible();

        for (const component of LOADING_NOT_APPLICABLE_PRIMITIVES) {
          await expect(
            primitiveCell(page, component, "loading"),
            `${component} loading intentionally absent at ${viewport.width}`
          ).toHaveCount(0);
          expect(source, `${component} source records loading non-applicability`).toContain(
            `loading not applicable: ${component}`
          );
        }
      }
    });

    test("theme_picker keeps native three-radio semantics without pressed-button state", async ({
      page
    }) => {
      await openGallery(page);

      const selectedStates = [
        ["system-selected", "system"],
        ["light-selected", "light"],
        ["dark-selected", "dark"]
      ];

      for (const viewport of PRIMITIVE_VIEWPORTS) {
        await page.setViewportSize(viewport);

        for (const [state, selected] of selectedStates) {
          for (const theme of ["light", "dark", "system"]) {
            const wrapper = primitiveWrapper(page, "theme_picker", state, theme);
            await assertThemePickerSemantics(
              wrapper,
              selected,
              `${theme} ${viewport.width} theme_picker/${state}`
            );
            await assertNonTextContrastAA(
              wrapper.locator(`label:has(input[value="${selected}"])`).first(),
              `${theme} ${viewport.width} theme_picker/${state} selected cue`
            );
          }
        }
      }
    });

    test("interactive primitive hover, focus, disabled, and target-size contracts hold", async ({
      page
    }) => {
      await openGallery(page);

      for (const viewport of PRIMITIVE_VIEWPORTS) {
        await page.setViewportSize(viewport);

        for (const theme of ["light", "dark", "system"]) {
          const navLinkActive = primitiveWrapper(page, "nav_link", "active", theme).locator("a").first();
          const navPillActive = primitiveWrapper(page, "nav_pill", "active", theme).locator("a").first();
          await assertTouchTarget(navLinkActive, `${theme} ${viewport.width} nav_link target`);
          await assertTouchTarget(navPillActive, `${theme} ${viewport.width} nav_pill target`);
          await assertNonTextContrastAA(navLinkActive, `${theme} ${viewport.width} nav_link active cue`);

          for (const option of await themeOptionLabels(primitiveWrapper(page, "theme_picker", "system-selected", theme)).all()) {
            await assertTouchTarget(option, `${theme} ${viewport.width} theme_picker option target`);
          }

          await assertHoverReady(
            primitiveWrapper(page, "nav_link", "hover-ready", theme).locator("a"),
            `${theme} ${viewport.width} nav_link hover`
          );
          await assertHoverReady(
            primitiveWrapper(page, "nav_pill", "hover-ready", theme).locator("a"),
            `${theme} ${viewport.width} nav_pill hover`
          );
          await assertHoverReady(
            themeOptionLabels(primitiveWrapper(page, "theme_picker", "hover-ready", theme)).first(),
            `${theme} ${viewport.width} theme_picker hover`
          );

          await assertFocusAppearanceAndNotObscured(
            page,
            primitiveWrapper(page, "nav_link", "focus-visible", theme).locator("a"),
            `${theme} ${viewport.width} nav_link focus ring`
          );
          await assertFocusAppearanceAndNotObscured(
            page,
            primitiveWrapper(page, "nav_pill", "focus-visible", theme).locator("a"),
            `${theme} ${viewport.width} nav_pill focus ring`
          );
          await assertFocusAppearanceAndNotObscured(
            page,
            primitiveWrapper(page, "theme_picker", "focus-visible", theme).locator('input[type="radio"]').first(),
            `${theme} ${viewport.width} theme_picker focus ring`
          );

          await assertProgrammaticDisabled(
            primitiveWrapper(page, "nav_link", "disabled", theme).locator("[role='link']"),
            navLinkActive,
            `${theme} ${viewport.width} nav_link disabled`
          );
          await assertProgrammaticDisabled(
            primitiveWrapper(page, "nav_pill", "disabled", theme).locator("[role='link']"),
            navPillActive,
            `${theme} ${viewport.width} nav_pill disabled`
          );

          const disabledPicker = primitiveWrapper(page, "theme_picker", "disabled", theme);
          await expect(disabledPicker.locator("fieldset")).toHaveAttribute("disabled", "");
          await expect(disabledPicker.locator('input[type="radio"]').first()).toBeDisabled();
        }
      }
    });

    test("stat_card shape, icon meaning, and overflow contracts hold at primitive widths", async ({
      page
    }) => {
      await openGallery(page);

      for (const viewport of PRIMITIVE_VIEWPORTS) {
        await page.setViewportSize(viewport);

        for (const theme of ["light", "dark", "system"]) {
          for (const state of ["neutral", "info", "success", "warning", "error", "empty", "loading", "unavailable", "long-label", "long-value"]) {
            const wrapper = primitiveWrapper(page, "stat_card", state, theme);
            await assertStatCardShape(wrapper, `${theme} ${viewport.width} stat_card/${state}`);
            await assertTextContrastAA(wrapper.locator("article"), `${theme} ${viewport.width} stat_card/${state}`);
          }

          const loadingCard = primitiveWrapper(page, "stat_card", "loading", theme).locator("article");
          await expect(loadingCard, `${theme} ${viewport.width} loading aria-busy`).toHaveAttribute("aria-busy", "true");
          await expect(loadingCard.getByText("Loading", { exact: true })).toBeVisible();

          const longLabel = primitiveWrapper(page, "stat_card", "long-label", theme).locator("article p").first();
          await expect(longLabel).toHaveAttribute("title", /Deliveries requiring operator review/);

          const longValue = primitiveWrapper(page, "stat_card", "long-value", theme).locator("article p").nth(1);
          await expect(longValue).toHaveAttribute("title", /trace_01JXWIDEVALUE/);
        }

        await assertNoElementHorizontalOverflow(
          primitiveCell(page, "stat_card", "long-value"),
          `gallery stat_card ${viewport.width}`
        );
      }
    });

    test("meaningful primitive icons have adjacent visible text or accessible names", async ({
      page
    }) => {
      await openGallery(page);

      for (const viewport of PRIMITIVE_VIEWPORTS) {
        await page.setViewportSize(viewport);

        for (const theme of ["light", "dark", "system"]) {
          await expect(
            primitiveWrapper(page, "nav_link", "active", theme).locator('[class*="hero-"]')
          ).toBeVisible();
          await expect(
            primitiveWrapper(page, "nav_link", "active", theme).getByText("Deliveries", { exact: true })
          ).toBeVisible();

          await expect(
            primitiveWrapper(page, "tenant_chip", "with-tenant", theme).locator('[class*="hero-"]')
          ).toBeVisible();
          await expect(
            primitiveWrapper(page, "tenant_chip", "with-tenant", theme).getByText("acme-corp", { exact: true })
          ).toBeVisible();

          await expect(
            primitiveWrapper(page, "stat_card", "warning", theme).locator('[class*="hero-"]')
          ).toBeVisible();
          await expect(
            primitiveWrapper(page, "stat_card", "warning", theme)
              .locator("article p")
              .nth(2)
              .getByText("Needs attention", { exact: true })
          ).toBeVisible();
        }
      }
    });

  });

});
