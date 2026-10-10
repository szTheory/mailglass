const { test, expect } = require("@playwright/test");

for (const width of [1440, 390]) {
  for (const interaction of ["hover", "keyboard"]) {
    test(`health tooltips paint above later cards: ${interaction} at ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 1100 });
      const reset = await page.request.get("/ops/browser-reset");
      expect(reset.ok()).toBeTruthy();
      const returnTo = encodeURIComponent("/ops/mail?tenant_id=browser-tenant");
      await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${returnTo}`);
      await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();

      const links = page.locator('[data-testid="operator-overview-health"] a:has(.mg-stat-card-tooltip)');
      await expect(links).toHaveCount(5);
      for (let index = 0; index < await links.count(); index++) {
        const link = links.nth(index);
        const tooltip = link.locator(".mg-stat-card-tooltip");
        await link.evaluate(element => element.scrollIntoView({ block: "center" }));
        if (interaction === "hover") {
          await link.hover();
        } else {
          await page.mouse.move(0, 0);
          // Shift+Tab reaches the card through real keyboard navigation and
          // exercises :focus-visible without following its drill-through link.
          await link.focus();
          await page.keyboard.press("Tab");
          await page.keyboard.press("Shift+Tab");
          await expect(link).toBeFocused();
        }
        await expect(tooltip).toHaveCSS("opacity", "1");
        await expect.poll(() => tooltip.evaluate(element => {
          const bounds = element.getBoundingClientRect();
          // The hint normally lets clicks pass through. Enable hit testing
          // only while sampling its painted layer, then restore that behavior.
          element.style.pointerEvents = "auto";
          try {
            const x = bounds.left + 12;
            const y = Math.min(bounds.bottom - 12, window.innerHeight - 12);
            const top = document.elementFromPoint(x, y);
            return {
              inFront: top === element,
              card: element.parentElement.dataset.testid,
              top: top?.dataset.testid || top?.tagName,
              sampleInTooltip: y > bounds.top,
            };
          } finally {
            element.style.removeProperty("pointer-events");
          }
        })).toMatchObject({ inFront: true, sampleInTooltip: true });
        await expect(tooltip).toHaveCSS("pointer-events", "none");
      }
    });
  }
}
