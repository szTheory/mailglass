const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";

async function openBrowserTenant(page) {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
}

test.describe("Phase 176 direct filters", () => {
  test("Phase 176 tracer: Deliveries select applies without Apply", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.locator("#operator-filters")).toBeVisible();

    // D-01: the form has no Apply control at all.
    await expect(page.getByRole("button", { name: /apply/i })).toHaveCount(0);

    const initialUrl = page.url();
    const historyBefore = await page.evaluate(() => window.history.length);

    await page.locator("#filters_event").selectOption("failed");
    await page.waitForURL(url => {
      const params = new URL(url).searchParams;
      return params.get("event") === "failed" && !params.has("page") && !params.has("delivery_id");
    });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.locator("#filters_event")).toHaveValue("failed");

    // FILTER-03: one select intent is exactly one history entry.
    const historyAfter = await page.evaluate(() => window.history.length);
    expect(historyAfter - historyBefore).toBe(1);

    await page.goBack();
    await page.waitForURL(url => new URL(url).searchParams.get("event") !== "failed");
    expect(page.url()).toBe(initialUrl);
    await expect(page.locator("#filters_event")).toHaveValue("");

    await page.goForward();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await expect(page.locator("#filters_event")).toHaveValue("failed");
  });
});
