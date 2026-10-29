const { test, expect } = require("@playwright/test");

async function loginTo(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

function params(page) {
  return new URL(page.url()).searchParams;
}

test.describe("Phase 177 demo Preview return", () => {
  test("Phase 177 demo returns Preview to the originating Account", async ({ page }) => {
    await loginTo(page, "/ops/mail?tenant_id=fjordline-aps&view=deliveries");
    expect(params(page).get("tenant_id")).toBe("fjordline-aps");

    await page.getByRole("link", { name: "Preview", exact: true }).first().click();
    await page.waitForURL((url) => url.pathname.startsWith("/dev/mail"));
    await page.locator("[data-phx-main].phx-connected").waitFor();
    const previewUrl = page.url();

    await page.locator('[data-testid="preview-return-link"]:visible').first().click();
    await page.waitForURL((url) => url.pathname === "/ops/mail");
    await page.locator("[data-phx-main].phx-connected").waitFor();

    expect(params(page).get("tenant_id")).toBe("fjordline-aps");
    expect(params(page).get("view")).toBe("deliveries");
    await expect(page.locator('[data-testid="operator-account-label"]').first()).toContainText(
      "Fjordline",
    );

    await page.goBack();
    await page.waitForURL((url) => url.pathname.startsWith("/dev/mail"));
    expect(page.url()).toBe(previewUrl);
  });

  test("Phase 177 demo logged-out Preview return lands on the originating Account after login", async ({
    page,
    context,
  }) => {
    await context.clearCookies();
    await page.goto("/dev/mail?return_surface=deliveries&return_tenant_id=fjordline-aps");
    await page.locator("[data-phx-main].phx-connected").waitFor();

    await page.locator('[data-testid="preview-return-link"]:visible').first().click();
    await page.waitForURL((url) => url.pathname === "/ops/mail" && url.searchParams.has("view"));
    await page.locator("[data-phx-main].phx-connected").waitFor();

    expect(params(page).get("tenant_id")).toBe("fjordline-aps");
    expect(params(page).get("view")).toBe("deliveries");
  });
});
