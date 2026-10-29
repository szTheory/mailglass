const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";

async function openHealth(page, { scenario = "phase177-health-all", theme } = {}) {
  await page.context().clearCookies();
  const reset = await page.request.get(`/ops/browser-reset?scenario=${scenario}`);
  expect(reset.ok()).toBeTruthy();
  const themeParam = theme ? `&theme=${theme}` : "";
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}${themeParam}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
  await expect(page.getByTestId("operator-overview-health")).toBeVisible();
}

// Geometry gates that are measured inside the page. The list grows with the
// retained suite; each part returns plain data so a failure names its numbers.
async function healthGates(page) {
  return page.evaluate(() => {
    const root = document.querySelector('[data-testid="operator-overview-health"]');
    const overflow = document.documentElement.scrollWidth - document.documentElement.clientWidth;

    // G4: every link and button in the Health region is at least 44px tall; a
    // field_help trigger (.mg-field-help button) is the one exception, at least 24x24.
    const smallTargets = [];
    for (const el of root.querySelectorAll("a, button")) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) continue;
      const isHelp = el.matches(".mg-field-help, .mg-field-help *") || !!el.closest(".mg-field-help");
      const label = el.getAttribute("data-testid") || el.id || el.textContent.trim().slice(0, 40);
      if (isHelp) {
        if (rect.width < 24 || rect.height < 24) {
          smallTargets.push({ label, help: true, width: rect.width, height: rect.height });
        }
      } else if (rect.height < 44) {
        smallTargets.push({ label, help: false, width: rect.width, height: rect.height });
      }
    }

    return { overflow, smallTargets };
  });
}

test.describe("Phase 177 Health", () => {
  test("Phase 177 tracer: all-eight Health stays in bounds and links land", async ({ page }) => {
    await openHealth(page);

    // The scenario seeds every issue category: eight rows.
    const rows = page
      .getByTestId("operator-overview-health")
      .locator('li[data-testid^="operator-health-"], li[data-testid^="operator-overview-health-"]');
    await expect(rows).toHaveCount(8);

    for (const width of [320, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      const gates = await healthGates(page);
      expect(gates.overflow, `document overflow at ${width}px`).toBeLessThanOrEqual(1);
      expect(gates.smallTargets, `small targets at ${width}px`).toEqual([]);
    }

    // One deep link, end to end: Failed deliveries lands on the failed filter
    // with exactly the one failed Delivery the scenario seeded.
    await page.getByTestId("operator-health-deliveries-failed-link").click();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true })).toHaveCount(1);
  });
});
