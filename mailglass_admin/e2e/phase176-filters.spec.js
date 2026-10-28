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
  test("Phase 176 Deliveries failed read shows error and Retry", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const armed = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch("/ops/browser-mutate?action=arm-known-read-failure&operation=deliveries", {
        method: "POST",
        headers: { "x-csrf-token": csrfToken },
        body: undefined,
        redirect: "manual"
      });
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(armed.status, armed.body).toBe(200);

    await page.locator("#filters_event").selectOption("suppressed");
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "suppressed");

    const card = page.getByTestId("operator-deliveries-list-card");
    await expect(card).toContainText("Couldn't load deliveries for these filters");
    await expect(card).toContainText("The read failed. Your filters are unchanged. Retry, or change a filter.");
    await expect(page.getByTestId("operator-result-count")).toHaveCount(0);
    await expect(page.getByTestId("operator-empty-filtered")).toHaveCount(0);
    await expect(page.getByTestId("operator-empty-truly")).toHaveCount(0);
    await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);
    await expect(page.locator("#filters_event")).toHaveValue("suppressed");

    const historyBefore = await page.evaluate(() => window.history.length);
    const urlBefore = page.url();
    await page.getByTestId("operator-retry-deliveries").click();

    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }).first()).toBeVisible();
    await expect(page.getByTestId("operator-retry-deliveries")).toHaveCount(0);
    await expect(page.getByTestId("operator-result-count")).toBeVisible();
    expect(await page.evaluate(() => window.history.length)).toBe(historyBefore);
    expect(page.url()).toBe(urlBefore);
  });
});
