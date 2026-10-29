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

    // The synthetic test endpoint has no Plug.Parsers, so the disconnected render sees
    // no query params and mints a bare Preview href. A real endpoint parses them. Wait
    // for the connected render before reading the minted link.
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();

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

  // Backstop for the P2 prohibition (phase177_prohibition_contract_test.exs): in a
  // real browser the opaque return id may sit in href values and nowhere else.
  test("Phase 177 privacy canary: Preview shows the return id only inside hrefs", async ({
    page
  }) => {
    const canary = "zz-canary-7f3";
    for (const width of [320, 1280]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(`/dev/mail?return_surface=overview&return_tenant_id=${canary}`);
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();

      // Non-vacuous: the Back link carries the id in its href.
      const back = page.getByTestId("preview-return-link").first();
      await expect(back).toHaveAttribute("href", new RegExp(canary));

      const stripped = (await page.content()).replace(/href="[^"]*"/g, 'href=""');
      expect(stripped, `no canary outside href values at ${width}`).not.toContain(canary);
      expect(await page.locator("body").innerText(), `no canary in visible text at ${width}`).not.toContain(
        canary
      );
      expect(await page.title(), "no canary in the title").not.toContain(canary);
    }
  });
});
