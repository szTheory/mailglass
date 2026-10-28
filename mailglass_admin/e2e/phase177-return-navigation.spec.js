const { test, expect } = require("@playwright/test");

// Account seeded by the "accounts" browser scenario that is NOT the one the
// test router hard-codes in the Preview navigation (browser-tenant).
const accountId = "fjordline-aps";
const sessionTenantId = "northstar";

async function openAccount(page, tenant) {
  await page.context().clearCookies();
  const reset = await page.request.get("/ops/browser-reset?scenario=accounts");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenant}`);
  await page.goto(
    `/ops/browser-login?tenant_id=${sessionTenantId}&return_to=${returnTo}&subject_id=operator-1`
  );
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${tenant}`));
}

test.describe("Phase 177 return navigation", () => {
  test("Phase 177 tracer: Preview returns to the originating Account", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openAccount(page, accountId);

    const operatorUrl = new RegExp(`/ops/mail\\?tenant_id=${accountId}$`);
    await expect(page).toHaveURL(operatorUrl);

    // Cross-live_session plain-href navigation to Preview carrying the context.
    await page
      .getByTestId("surface-nav-sidebar")
      .getByRole("link", { name: "Preview", exact: true })
      .filter({ visible: true })
      .click();
    await expect(page).toHaveURL(/\/dev\/mail\/[^?]+\?.*return_surface=overview/);
    await expect(page).toHaveURL(new RegExp(`return_tenant_id=${accountId}`));
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();

    const back = page.getByTestId("preview-return-link").filter({ visible: true });
    await expect(back).toHaveText("Back to Health");
    await expect(page.getByTestId("preview-return-link").first()).not.toContainText(accountId);

    await back.click();
    await expect(page).toHaveURL(operatorUrl);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();

    // Browser Back from the operator page returns to Preview.
    await page.goBack();
    await expect(page).toHaveURL(/\/dev\/mail\/[^?]+\?.*return_surface=overview/);
    await expect(page).toHaveURL(new RegExp(`return_tenant_id=${accountId}`));
  });
});
