const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

async function openInbound(page) {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent("/ops/mail/inbound?tenant_id=browser-tenant");
  await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}

for (const width of [1440, 1024, 390, 320]) {
  test(`inbound compact filters and accessible help at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await openInbound(page);
    const filters = page.getByTestId("inbound-filters");
    const summary = page.getByTestId("inbound-overview");
    const list = page.getByTestId("inbound-records-list-card");
    const filterBox = await filters.boundingBox();
    const summaryBox = await summary.boundingBox();
    const listBox = await list.boundingBox();
    expect(filterBox.y + filterBox.height).toBeLessThanOrEqual(summaryBox.y);
    expect(summaryBox.y + summaryBox.height).toBeLessThanOrEqual(listBox.y);
    // The mobile account/theme header occupies more space; the collection
    // heading and first record still start within the initial 900px viewport.
    expect(listBox.y).toBeLessThan(width >= 1280 ? 500 : 750);
    expect(filterBox.height).toBeLessThan(width >= 1280 ? 100 : width >= 768 ? 240 : 70);
    await expect(summary.getByRole("button")).toHaveCount(1);
    await expect(summary.getByRole("link")).toHaveCount(0);
    await expect(page.getByTestId("inbound-summary-scope")).toContainText("All outcomes · Last 7 days · Any provider");
    const collectionHeader = page.getByTestId("inbound-collection-header");
    await expect(collectionHeader.getByRole("heading", { name: "Received messages", exact: true })).toBeVisible();
    await expect(collectionHeader.getByTestId("inbound-result-count")).toBeVisible();
    if (width >= 768) {
      // Full UTC values and the separately labelled local times stay inside
      // their cell, including at the intermediate tablet/desktop width.
      const receivedCells = page.getByTestId("inbound-records-table").locator("td.mg-inbound-received");
      expect(await receivedCells.evaluateAll(cells => cells.every(cell => cell.scrollWidth <= cell.clientWidth))).toBe(true);
      expect(await receivedCells.locator("time").evaluateAll(times => times.every(time => time.textContent.endsWith(" UTC")))).toBe(true);
      const mailboxColumn = page.getByRole("columnheader", { name: "Mailbox", exact: true });
      expect((await mailboxColumn.boundingBox()).width).toBeGreaterThan(100);
    }
    if (process.env.INBOUND_LAYOUT_CAPTURE_PREFIX) {
      await page.screenshot({ path: `${process.env.INBOUND_LAYOUT_CAPTURE_PREFIX}-${width}.png` });
    }

    if (width < 768) {
      const toggle = page.getByTestId("inbound-filters-toggle");
      await expect(page.locator("#inbound-filter-panel")).toBeHidden();
      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "true");
    }
    await expect(page.locator("#inbound-filter-panel")).toBeVisible();
    for (const field of ["provider", "outcome", "window_hours", "search"]) {
      const help = page.locator(`#filters_${field}-help-trigger`);
      const tooltip = page.locator(`#filters_${field}-help-tooltip`);
      await expect(page.locator(`#filters_${field}`)).toHaveAttribute("aria-describedby", `filters_${field}-help`);
      await expect(tooltip).toBeHidden();
      await help.hover();
      await expect(tooltip).toBeVisible();
      const bounds = await tooltip.boundingBox();
      expect(bounds.x).toBeGreaterThanOrEqual(0);
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(width);
      expect(await tooltip.evaluate(element => {
        const rect = element.getBoundingClientRect();
        return document.elementFromPoint(rect.left + 12, rect.bottom - 12) === element;
      })).toBe(true);

      // Keyboard focus reveals help; Escape dismisses it without losing focus.
      await page.mouse.move(0, 0);
      await help.focus();
      await page.keyboard.press("Tab");
      await page.keyboard.press("Shift+Tab");
      await expect(help).toBeFocused();
      await expect(tooltip).toBeVisible();
      await page.keyboard.press("Escape");
      await expect(tooltip).toBeHidden();
      await expect(help).toBeFocused();

      // Tap/click pins help until it is dismissed or another control is used.
      await help.click();
      await expect(help).toHaveAttribute("aria-expanded", "true");
      await expect(tooltip).toBeVisible();
      await page.getByRole("heading", { name: "Inbound records", exact: true }).click();
      await expect(help).toHaveAttribute("aria-expanded", "false");
      await expect(tooltip).toBeHidden();
    }
    const summaryHelp = page.getByRole("button", { name: "Help for summary counts", exact: true });
    await summaryHelp.hover();
    const summaryTooltip = page.locator("#inbound-summary-help-tooltip");
    await expect(summaryTooltip).toBeVisible();
    const summaryHelpBox = await summaryTooltip.boundingBox();
    expect(summaryHelpBox.x).toBeGreaterThanOrEqual(0);
    expect(summaryHelpBox.x + summaryHelpBox.width).toBeLessThanOrEqual(width);
    await page.mouse.move(0, 0);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    const accessibility = await new AxeBuilder({ page })
      .include("#inbound-filter-panel")
      .include('[data-testid="inbound-overview"]')
      .analyze();
    expect(accessibility.violations).toEqual([]);
    if (width < 768) {
      await page.getByTestId("inbound-filters-toggle").click();
      await expect(page.locator("#inbound-filter-panel")).toBeHidden();
      await page.setViewportSize({ width: 1440, height: 900 });
      await expect(page.locator("#inbound-filter-panel")).toBeVisible();
      await page.setViewportSize({ width, height: 900 });
      await expect(page.locator("#inbound-filter-panel")).toBeHidden();
    }
  });
}

test("inbound summary scope follows applied filters and explains the outcome distinction", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await openInbound(page);
  const total = page.getByTestId("inbound-overview-total").locator("p").nth(1);
  const before = await total.innerText();
  await page.getByLabel("Mailbox outcome", { exact: true }).selectOption("accept");
  await page.getByRole("button", { name: "Apply filters", exact: true }).click();
  await expect(page).toHaveURL(/outcome=accept/);
  await expect(total).toHaveText(before);
  await expect(page.getByTestId("inbound-summary-outcome-scope")).toHaveText("List filtered to Accepted");
  await page.getByLabel("Time window", { exact: true }).selectOption("24");
  await expect(page.getByTestId("inbound-summary-scope")).toContainText("Last 7 days");
  await page.getByRole("button", { name: "Apply filters", exact: true }).click();
  await expect(page.getByTestId("inbound-summary-scope")).toContainText("Last 24 hours");
  await page.getByRole("button", { name: "Clear filters", exact: true }).click();
  await expect(page.getByTestId("inbound-summary-outcome-scope")).toHaveCount(0);
  await expect(page.getByTestId("inbound-summary-scope")).toContainText("Last 7 days");
  await expect(page).toHaveURL(/tenant_id=browser-tenant/);
});
