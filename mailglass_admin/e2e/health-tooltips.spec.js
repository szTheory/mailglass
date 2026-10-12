const { test, expect } = require("@playwright/test");

for (const width of [1440, 390]) {
  for (const interaction of ["hover", "keyboard"]) {
    test(`health uses one anchored tooltip pattern: ${interaction} at ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 1100 });
      const reset = await page.request.get("/ops/browser-reset");
      expect(reset.ok()).toBeTruthy();
      const returnTo = encodeURIComponent("/ops/mail?tenant_id=browser-tenant");
      await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
      await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();

      await expect(page.getByTestId("operator-health-status")).toContainText("Needs attention");
      await expect(page.getByText("Additional records", { exact: true })).toHaveCount(0);
      await expect(page.locator(".mg-stat-card-tooltip")).toHaveCount(0);
      const triggers = page.locator('[data-testid="operator-overview-health"] .mg-field-help button');
      expect(await triggers.count()).toBeGreaterThan(3);
      for (let index = 0; index < await triggers.count(); index++) {
        const trigger = triggers.nth(index);
        const tooltip = trigger.locator("xpath=..").locator(".mg-field-help-tooltip");
        await trigger.evaluate(element => element.scrollIntoView({ block: "center" }));
        if (interaction === "hover") {
          await trigger.hover();
        } else {
          await page.mouse.move(0, 0);
          await trigger.focus();
          await page.keyboard.press("Tab");
          await page.keyboard.press("Shift+Tab");
          await expect(trigger).toBeFocused();
        }
        await expect(tooltip).toHaveCSS("opacity", "1");
        await expect.poll(() => tooltip.evaluate(element => {
          const panel = element.getBoundingClientRect();
          const top = document.elementFromPoint(panel.left + 12, panel.top + 12);
          return top === element && panel.left >= 11 && panel.right <= window.innerWidth - 11 &&
            panel.top >= 11 && panel.bottom <= window.innerHeight - 11;
        })).toBeTruthy();
        const anchor = await trigger.boundingBox();
        const panel = await tooltip.boundingBox();
        const placement = await tooltip.getAttribute("data-placement");
        expect(Math.abs(placement === "bottom" ? panel.y - (anchor.y + anchor.height + 8) : anchor.y - (panel.y + panel.height + 8))).toBeLessThanOrEqual(1);
        await page.keyboard.press("Escape");
        await expect(tooltip).toHaveCSS("visibility", "hidden");
      }
    });
  }
}

test("health refresh retains its icon after repeated requests", async ({ page }) => {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent("/ops/mail?tenant_id=browser-tenant");
  await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
  const refresh = page.getByRole("button", { name: "Refresh health", exact: true });
  for (let attempt = 0; attempt < 2; attempt++) {
    await refresh.click();
    await expect(page.getByTestId("copy-toast")).toBeVisible();
    await expect(page.getByTestId("copy-toast")).toContainText("Email health refreshed.");
    await expect(refresh).toBeEnabled();
    await expect(refresh.locator(".hero-arrow-path")).toBeVisible();
  }
});

for (const width of [1440, 390]) {
  test(`shared help keeps its anchor after a LiveView style reset at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    const reset = await page.request.get("/ops/browser-reset");
    expect(reset.ok()).toBeTruthy();
    const returnTo = encodeURIComponent("/ops/mail?tenant_id=browser-tenant");
    await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
    const trigger = page.locator("#operator-health-window-help-trigger");
    const tooltip = page.locator("#operator-health-window-help-tooltip");
    await trigger.click();
    const anchored = async () => {
      const button = await trigger.boundingBox();
      const panel = await tooltip.boundingBox();
      return panel && button && panel.x >= 12 && panel.x + panel.width <= width - 11 &&
        Math.abs(panel.y - (button.y + button.height + 8)) <= 1;
    };
    await expect.poll(anchored).toBeTruthy();
    await expect(tooltip).toHaveCSS("opacity", "1");
    // Morphdom can discard client-owned inline styles when replacing attributes.
    await tooltip.evaluate(element => element.removeAttribute("style"));
    await expect.poll(anchored).toBeTruthy();
    await expect(tooltip).toHaveCSS("opacity", "1");
    await page.setViewportSize({ width, height: 420 });
    await expect.poll(async () => {
      const panel = await tooltip.boundingBox();
      return panel && panel.y >= 12 && panel.y + panel.height <= 409;
    }).toBeTruthy();
    await page.keyboard.press("Escape");
    await expect(tooltip).toHaveCSS("visibility", "hidden");
  });
}


test("timestamp UTC tooltip uses shared placement and retains copying feedback", async ({ page, context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.request.get("/ops/browser-reset");
  const returnTo = encodeURIComponent("/ops/mail?tenant_id=browser-tenant");
  await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
  const timestamp = page.locator("[data-testid='operator-health-last-checked'] [data-timestamp-copy]");
  const tooltip = timestamp.locator("xpath=..").locator(".mg-field-help-tooltip");
  await timestamp.hover();
  await expect(tooltip).toHaveCSS("visibility", "visible");
  await expect(tooltip).toContainText(await timestamp.getAttribute("data-copy-value"));
  await timestamp.click();
  await expect(page.getByTestId("copy-toast")).toContainText("Timestamp copied as UTC.");
});
