const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

async function openInbound(page) {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent("/ops/mail/inbound?tenant_id=browser-tenant");
  await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}

test("timestamp itself copies exact UTC on click and keyboard activation", async ({ page, context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.setViewportSize({ width: 1024, height: 900 });
  await openInbound(page);

  const copyControl = page.locator("button[data-timestamp-copy]").first();
  const expectedUtc = await copyControl.getAttribute("data-copy-value");
  await expect(copyControl).toHaveAttribute("aria-label", /^Copy timestamp as UTC:/);
  await copyControl.click();
  const toast = page.getByTestId("copy-toast");
  await expect(toast).toBeVisible();
  await expect(toast).toContainText("Timestamp copied as UTC.");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(expectedUtc);

  await copyControl.focus();
  await page.keyboard.press("Enter");
  await expect(toast).toContainText("Timestamp copied as UTC.");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(expectedUtc);
});

test("mobile inbound timestamp copies without opening the message", async ({ page, context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.setViewportSize({ width: 390, height: 844 });
  await openInbound(page);

  const timestamp = page.locator("button[data-timestamp-copy]").filter({ visible: true }).first();
  const expectedUtc = await timestamp.getAttribute("data-copy-value");
  await timestamp.click();
  await expect(page.getByTestId("copy-toast")).toContainText("Timestamp copied as UTC.");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(expectedUtc);
  await expect(page).not.toHaveURL(/inbound_id=/);
});

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
    await expect(page.getByRole("group", { name: "Appearance" })).toBeVisible();
    await expect(page.getByText("Appearance", { exact: true })).toHaveCount(0);
    await expect(summary.getByRole("button")).toHaveCount(3);
    await expect(summary.getByRole("link")).toHaveCount(0);
    await expect(page.getByTestId("inbound-summary-scope")).toHaveCount(0);
    await expect(page.getByTestId("inbound-summary-outcome-scope")).toHaveCount(0);
    const collectionHeader = page.getByTestId("inbound-collection-header");
    await expect(collectionHeader.getByRole("heading", { name: "Received messages", exact: true })).toBeVisible();
    await expect(collectionHeader.getByTestId("inbound-result-count")).toBeVisible();
    for (const outcome of ["accepted", "no-match", "failed"]) {
      const stat = page.getByTestId(`inbound-overview-${outcome}`);
      const help = stat.getByRole("button");
      const tooltip = page.locator(`#inbound-overview-${outcome}-help-tooltip`);
      await expect(help).toHaveAttribute("aria-describedby", `inbound-overview-${outcome}-help`);
      await expect(tooltip).toBeHidden();
      await help.hover();
      await expect(tooltip).toBeVisible();
      const bounds = await tooltip.boundingBox();
      const helpBounds = await help.boundingBox();
      expect(bounds.x).toBeGreaterThanOrEqual(0);
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(width);
      expect(bounds.x).toBeLessThan(helpBounds.x + helpBounds.width);
      expect(bounds.x + bounds.width).toBeGreaterThan(helpBounds.x);
      expect(await tooltip.evaluate(element => {
        const rect = element.getBoundingClientRect();
        return document.elementFromPoint(rect.left + 12, rect.top + 12) === element;
      })).toBe(true);
      await page.mouse.move(0, 0);
    }
    if (width >= 768) {
      // Full UTC values and the separately labelled local times stay inside
      // their cell, including at the intermediate tablet/desktop width.
      const receivedCells = page.getByTestId("inbound-records-table").locator("td.mg-inbound-received");
      expect(await receivedCells.evaluateAll(cells => cells.every(cell => cell.scrollWidth <= cell.clientWidth))).toBe(true);
      expect(await receivedCells.locator("time").evaluateAll(times => times.every(time =>
        time.dataset.localized === "1" && time.textContent.trim() !== "" && !time.textContent.includes("Local:")
      ))).toBe(true);
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

test("outcome filters hide all-outcome stats and clearing restores them", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await openInbound(page);
  const summary = page.getByTestId("inbound-overview");
  const accepted = page.getByTestId("inbound-overview-accepted").locator("p").nth(1);
  const before = await accepted.innerText();

  await page.getByLabel("Mailbox outcome", { exact: true }).selectOption("accept");
  await expect(summary).toBeVisible();
  await page.getByRole("button", { name: "Apply filters", exact: true }).click();
  await expect(page).toHaveURL(/outcome=accept/);
  await expect(summary).toHaveCount(0);
  await expect(page.getByTestId("inbound-result-count")).toBeVisible();
  await expect(page.getByTestId("inbound-summary-outcome-scope")).toHaveCount(0);

  await page.getByLabel("Time window", { exact: true }).selectOption("24");
  await expect(summary).toHaveCount(0);
  await page.getByRole("button", { name: "Apply filters", exact: true }).click();
  await expect(page).toHaveURL(/window_hours=24/);
  await page.getByLabel("Search", { exact: true }).fill("no-matching-message-7f2a");
  await page.getByRole("button", { name: "Apply filters", exact: true }).click();
  await expect(page.getByTestId("inbound-empty-filtered")).toHaveCount(1);

  await page.getByTestId("inbound-filters").getByRole("button", { name: "Clear filters", exact: true }).click();
  await expect(summary).toBeVisible();
  await expect(accepted).toHaveText(before);
  await expect(page.getByLabel("Time window", { exact: true })).toHaveValue("168");
  await expect(page).toHaveURL(/tenant_id=browser-tenant/);
});


test("account menu closes when the operator clicks outside it", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await openInbound(page);
  const switcher = page.getByTestId("operator-account-switcher");
  const accounts = page.getByRole("list", { name: "Available Accounts" });
  await switcher.click();
  await expect(accounts).toBeVisible();
  await page.getByTestId("inbound-collection-header").click();
  await expect(accounts).toBeHidden();
});
