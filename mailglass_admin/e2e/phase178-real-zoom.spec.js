const { test, expect } = require("@playwright/test");
const {
  launchRealZoomContext,
  applyRealZoom,
  measureEffective,
  recordReceipt,
  undersizedTargets,
  TARGET_CSS_WIDTH
} = require("./support/real-zoom.cjs");
const { accountSwitcher, visibleByTestId } = require("./support/account.cjs");

// Phase 178 (UIQ-06 / D-10): actual 200% Chromium tab zoom on the connected
// Operator routes the milestone left to this phase. One persistent context is
// shared by the serial cases because tab zoom is per origin and survives
// same-origin navigation, so the extension is loaded and zoom applied once.
// Every case re-measures its own receipt: the document width depends on the
// route, not on the zoom that was applied in beforeAll.

const tenantId = "browser-tenant";

let context;
let page;
let baseReceipt;

async function openTenant({ scenario, returnPath } = {}) {
  await context.clearCookies();
  const reset = await page.request.get(`/ops/browser-reset${scenario ? `?scenario=${scenario}` : ""}`);
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(returnPath || `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
}

// The shared receipt with this route's own effective measurement.
async function receiptFor() {
  return { ...baseReceipt, effective: await measureEffective(page) };
}

function insideViewport(box, label) {
  expect(box, `${label} has a rendered box`).not.toBeNull();
  expect(box.x, `${label} starts inside the viewport`).toBeGreaterThanOrEqual(-0.5);
  expect(box.x + box.width, `${label} ends inside ${TARGET_CSS_WIDTH} CSS px`).toBeLessThanOrEqual(
    TARGET_CSS_WIDTH + 0.5
  );
}


// Presses Tab until `matches` (evaluated in the page) is true for the focused
// element; fails with the step count so a lost tab order names itself.
async function tabTo(description, matches, max = 60) {
  await page.evaluate(() => {
    document.activeElement?.blur();
    window.scrollTo(0, 0);
  });
  for (let step = 0; step < max; step += 1) {
    await page.keyboard.press("Tab");
    if (await page.evaluate(matches)) return step + 1;
  }
  throw new Error(`Tab never reached ${description} within ${max} presses`);
}

async function focusIsVisible() {
  return page.evaluate(() => {
    const style = getComputedStyle(document.activeElement);
    const outline = style.outlineStyle !== "none" && Number.parseFloat(style.outlineWidth) > 0;
    return { outline, boxShadow: style.boxShadow, ok: outline || style.boxShadow !== "none" };
  });
}

// Shared Quick view body for the Delivery and Inbound cases.
async function inboundOpener() {
  return page.locator('button[id^="inbound-record-open-mobile-"]').filter({ visible: true }).first();
}

test.describe.serial("Phase 178 real zoom", () => {
  test.beforeAll(async () => {
    test.setTimeout(90_000);
    context = await launchRealZoomContext();
    page = context.pages()[0] || (await context.newPage());
    await openTenant();
    baseReceipt = await applyRealZoom(context, page);
  });

  test.afterAll(async () => {
    await context?.close();
  });

  test("Phase 178 real zoom: Delivery quick view keeps position, arrows and Close usable at 320 CSS px", async ({}, testInfo) => {
    await openTenant({ returnPath: `/ops/mail?tenant_id=${tenantId}&view=deliveries` });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    // At 320 CSS px the card list is shown and each card is itself the opener.
    const opener = page.locator('button[id^="operator-delivery-mobile-"]').filter({ visible: true }).first();
    const openerId = await opener.getAttribute("id");
    expect(openerId, "the Delivery opener carries the id Quick view returns focus to").toBeTruthy();
    await opener.click();

    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    const receipt = await receiptFor();
    recordReceipt(testInfo, receipt, "Delivery quick view");

    const position = quickView.locator('[aria-live="polite"]');
    await expect(position).toHaveText(/^\s*1 of \d+\s*$/);
    const total = Number((await position.textContent()).trim().split(" of ")[1]);
    expect(total, "the seeded Deliveries list has more than one row").toBeGreaterThan(1);

    expect(await undersizedTargets(page, '[data-testid="operator-quick-view"]'), "Quick view targets stay 44x44").toEqual(
      []
    );
    for (const name of ["Close quick view", "Next delivery", "Open full detail"]) {
      const control = quickView.getByRole("link", { name, exact: true });
      await expect(control, `${name} is visible`).toBeVisible();
      insideViewport(await control.boundingBox(), name);
    }
    insideViewport(await position.boundingBox(), "position counter");

    // The next arrow navigates; the previous arrow goes back.
    const firstId = new URL(page.url()).searchParams.get("delivery_id");
    await quickView.getByRole("link", { name: "Next delivery", exact: true }).click();
    await expect(position).toHaveText(`2 of ${total}`);
    await expect.poll(() => new URL(page.url()).searchParams.get("delivery_id")).not.toBe(firstId);
    await quickView.getByRole("link", { name: "Previous delivery", exact: true }).click();
    await expect(position).toHaveText(`1 of ${total}`);

    // Close returns focus to the control that opened the Quick view.
    await quickView.getByRole("link", { name: "Close quick view", exact: true }).click();
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
    await expect(page.locator(`#${openerId}`)).toBeFocused();
  });
  test("Phase 178 real zoom: Inbound quick view keeps position, arrows and Close usable at 320 CSS px", async ({}, testInfo) => {
    await openTenant({ returnPath: `/ops/mail/inbound?tenant_id=${tenantId}` });
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const opener = await inboundOpener();
    const openerId = await opener.getAttribute("id");
    expect(openerId, "the Inbound opener carries the id Quick view returns focus to").toBeTruthy();
    await opener.click();

    const quickView = page.getByTestId("inbound-quick-view");
    await expect(quickView).toBeVisible();
    recordReceipt(testInfo, await receiptFor(), "Inbound quick view");

    const position = quickView.locator('[aria-live="polite"]');
    await expect(position).toHaveText(/^\s*1 of \d+\s*$/);
    const total = Number((await position.textContent()).trim().split(" of ")[1]);
    expect(total, "the seeded Inbound list has more than one record").toBeGreaterThan(1);

    expect(await undersizedTargets(page, '[data-testid="inbound-quick-view"]'), "Quick view targets stay 44x44").toEqual(
      []
    );

    // Position 1: the previous arrow is natively disabled, and still 44x44 inside the viewport.
    const previous = quickView.getByRole("button", { name: "Previous inbound record", exact: true });
    await expect(previous).toBeDisabled();
    insideViewport(await previous.boundingBox(), "disabled previous arrow");
    for (const name of ["Close quick view", "Next inbound record", "Open full detail"]) {
      const control = quickView.getByRole("link", { name, exact: true });
      await expect(control, `${name} is visible`).toBeVisible();
      insideViewport(await control.boundingBox(), name);
    }
    insideViewport(await position.boundingBox(), "position counter");

    const firstId = new URL(page.url()).searchParams.get("inbound_id");
    await quickView.getByRole("link", { name: "Next inbound record", exact: true }).click();
    await expect(position).toHaveText(`2 of ${total}`);
    await expect.poll(() => new URL(page.url()).searchParams.get("inbound_id")).not.toBe(firstId);
    // Off the boundary the arrow becomes a link, so the disabled button is gone.
    await expect(previous).toHaveCount(0);
    await quickView.getByRole("link", { name: "Previous inbound record", exact: true }).click();
    await expect(position).toHaveText(`1 of ${total}`);

    await quickView.getByRole("link", { name: "Close quick view", exact: true }).click();
    await expect(page.getByTestId("inbound-quick-view")).toHaveCount(0);
    await expect(page.locator(`#${openerId}`)).toBeFocused();
  });

  test("Phase 178 real zoom: Health overview keeps the verdict, issue rows and Refresh readable at 320 CSS px", async ({}, testInfo) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    try {
      await openTenant({ scenario: "phase177-health-all" });
      const health = page.getByTestId("operator-overview-health");
      await expect(health).toBeVisible();
      recordReceipt(testInfo, await receiptFor(), "Health overview");

      const status = page.getByTestId("operator-health-status");
      await expect(status.locator("h2").first(), "the verdict is a visible heading").toBeVisible();
      expect((await status.locator("h2").first().textContent()).trim().length, "the verdict has text").toBeGreaterThan(0);
      const rows = status.locator("ul > li");
      expect(await rows.count(), "the all-issues scenario lists issue rows").toBeGreaterThan(0);
      for (let i = 0; i < (await rows.count()); i += 1) {
        const row = rows.nth(i);
        await expect(row, `issue row ${i} is visible`).toBeVisible();
        insideViewport(await row.boundingBox(), `issue row ${i}`);
        const link = row.locator("a, button").first();
        if (await link.count()) {
          expect((await link.boundingBox()).height, `issue row ${i} target height`).toBeGreaterThanOrEqual(43.5);
        }
      }

      expect(
        await undersizedTargets(page, '[data-testid="operator-overview-health"]', { exempt: ".mg-field-help" }),
        "Health targets stay 44px (field help is held to 24px)"
      ).toEqual([]);
      const smallHelp = await health.locator(".mg-field-help button, .mg-field-help a, .mg-field-help [role=button]").evaluateAll(els =>
        els
          .map(el => el.getBoundingClientRect())
          .filter(r => r.width > 0 && r.height > 0 && (r.width < 24 || r.height < 24))
      );
      expect(smallHelp, "field-help triggers stay 24x24").toEqual([]);

      // Refresh is reachable with Tab, shows focus, and is operable.
      const refresh = page.locator("#operator-health-refresh");
      await expect(refresh).toBeVisible();
      insideViewport(await refresh.boundingBox(), "Refresh health");
      await tabTo("Refresh health", () => document.activeElement?.id === "operator-health-refresh");
      await expect(refresh).toBeFocused();
      const focus = await focusIsVisible();
      expect(focus.ok, `Refresh health shows visible focus: ${JSON.stringify(focus)}`).toBe(true);
      const checked = page.getByTestId("operator-health-last-checked");
      const before = (await checked.textContent()).trim();
      await page.keyboard.press("Enter");
      await expect(health, "Health stays rendered after Refresh").toBeVisible();
      await expect(checked).toBeVisible();
      expect((await checked.textContent()).trim().length, `last-checked text (was "${before}")`).toBeGreaterThan(0);
    } finally {
      await page.emulateMedia({ reducedMotion: null });
    }
  });

  test("Phase 178 real zoom: Account control opens and lists Accounts at 320 CSS px", async ({}, testInfo) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    try {
      await context.clearCookies();
      const reset = await page.request.get("/ops/browser-reset?scenario=accounts");
      expect(reset.ok()).toBeTruthy();
      const returnTo = encodeURIComponent("/ops/mail?tenant_id=fjordline-aps");
      await page.goto(`/ops/browser-login?tenant_id=northstar&return_to=${returnTo}&subject_id=operator-1`);
      await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      recordReceipt(testInfo, await receiptFor(), "Account control");

      const switcher = accountSwitcher(page);
      await expect(switcher).toHaveCount(1);
      const switcherBox = await switcher.boundingBox();
      insideViewport(switcherBox, "Account switcher");
      expect(switcherBox.height, "Account switcher height").toBeGreaterThanOrEqual(43.5);

      // Reach the switcher with Tab, open it from the keyboard.
      await tabTo(
        "the Account switcher",
        () => document.activeElement?.dataset?.testid === "operator-account-switcher"
      );
      const focus = await focusIsVisible();
      expect(focus.ok, `Account switcher shows visible focus: ${JSON.stringify(focus)}`).toBe(true);
      await page.keyboard.press("Enter");

      const group = visibleByTestId(page, "surface-nav-scope-group");
      const list = group.locator('ul[aria-label="Available Accounts"]');
      await expect(list).toBeVisible();
      const options = group.getByTestId("operator-account-option");
      expect(await options.count(), "both Accounts are listed").toBeGreaterThanOrEqual(2);
      for (let i = 0; i < (await options.count()); i += 1) {
        const option = options.nth(i);
        await expect(option, `Account option ${i} is visible`).toBeVisible();
        const box = await option.boundingBox();
        insideViewport(box, `Account option ${i}`);
        expect(box.height, `Account option ${i} height`).toBeGreaterThanOrEqual(43.5);
      }
      const overflow = await measureEffective(page);
      expect(overflow.documentWidth, "open Account list adds no page overflow").toBeLessThanOrEqual(TARGET_CSS_WIDTH);
    } finally {
      await page.emulateMedia({ reducedMotion: null });
    }
  });

  test("Phase 178 real zoom: filters on Deliveries and Inbound apply without overflow at 320 CSS px", async ({}, testInfo) => {
    const collections = {
      Deliveries: {
        path: `/ops/mail?tenant_id=${tenantId}&view=deliveries`,
        form: "operator-filters",
        card: "operator-deliveries-list-card",
        select: "#filters_event",
        param: "event",
        value: "delivered",
        toggle: "operator-filters-toggle"
      },
      Inbound: {
        path: `/ops/mail/inbound?tenant_id=${tenantId}`,
        form: "inbound-filters",
        card: "inbound-records-list-card",
        select: "#filters_outcome",
        param: "outcome",
        value: "accept",
        toggle: "inbound-filters-toggle"
      }
    };
    const longQuery = "a".repeat(250) + "東京-é-".repeat(40) + "z".repeat(20);

    for (const [name, c] of Object.entries(collections)) {
      await openTenant({ returnPath: c.path });
      await expect(page.getByTestId(c.card)).toBeVisible();
      recordReceipt(testInfo, await receiptFor(), `${name} filters`);

      const toggle = page.getByTestId(c.toggle);
      await expect(toggle, `${name} Filters toggle is visible`).toBeVisible();
      await expect(toggle).toHaveAttribute("aria-expanded", "false");
      const toggleBox = await toggle.boundingBox();
      insideViewport(toggleBox, `${name} Filters toggle`);
      expect(toggleBox.height, `${name} Filters toggle height`).toBeGreaterThanOrEqual(43.5);
      expect(toggleBox.width, `${name} Filters toggle width`).toBeGreaterThanOrEqual(43.5);

      // Opening it reveals every control, each at 44px and inside the viewport.
      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "true");
      const controls = page.locator(
        `#${c.form} select, #${c.form} input#filters_search, #${c.form} button[phx-click="clear_filters"]`
      );
      const count = await controls.count();
      expect(count, `${name} filter controls`).toBeGreaterThanOrEqual(4);
      for (let i = 0; i < count; i += 1) {
        const control = controls.nth(i);
        await expect(control, `${name} control ${i} is visible`).toBeVisible();
        const box = await control.boundingBox();
        insideViewport(box, `${name} control ${i}`);
        expect(box.height, `${name} control ${i} height`).toBeGreaterThanOrEqual(43.5);
        expect(box.width, `${name} control ${i} width`).toBeGreaterThanOrEqual(43.5);
      }

      // A select applies straight to the URL, and the toggle label is not clipped.
      await page.locator(c.select).selectOption(c.value);
      await page.waitForURL(url => new URL(url).searchParams.get(c.param) === c.value);
      await expect(toggle).toContainText("(1 applied)");
      expect(
        await toggle.evaluate(node => node.scrollWidth > node.clientWidth + 1),
        `${name} toggle label is not clipped`
      ).toBe(false);
      expect((await measureEffective(page)).documentWidth, `${name} filtered page overflow`).toBeLessThanOrEqual(
        TARGET_CSS_WIDTH
      );

      // The 500-character query from the Phase 176 case causes no page overflow.
      await openTenant({ returnPath: `${c.path}&search=${encodeURIComponent(longQuery)}` });
      await expect(page.getByTestId(c.card)).toBeVisible();
      expect(
        (await measureEffective(page)).documentWidth,
        `${name} 500-character query overflow`
      ).toBeLessThanOrEqual(TARGET_CSS_WIDTH);
    }
  });
});
