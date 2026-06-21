const { test, expect } = require("@playwright/test");

test.describe("mailglass demo evidence", () => {
  test.beforeEach(async ({ request }) => {
    const response = await request.post("/demo/evidence/reset", {
      headers: {
        "x-mailglass-demo-reset-token": process.env.DEMO_EVIDENCE_RESET_TOKEN || "",
      },
    });
    expect(response.ok()).toBeTruthy();
  });

  test("dashboard links to preview and operator surfaces", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Northstar Ops", exact: true })).toBeVisible();
    await expect(page.getByText("Deliveries", { exact: true })).toBeVisible();

    await page.getByRole("link", { name: /preview mailables/i }).click();
    await expect(page).toHaveURL(/\/dev\/mail/);
    // The responsive preview renders the mailable list in both a desktop sidebar
    // and a mobile list (both in the DOM), so a bare getByText is a strict-mode
    // violation. Scope to the desktop sidebar — the visible container at the
    // default Playwright viewport (1280px).
    await expect(
      page.getByTestId("preview-sidebar-desktop").getByText("AccountMailer"),
    ).toBeVisible();
  });

  test("outbound operator opens with seeded delivery evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /outbound operator/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
    // Navigate to Deliveries view to assert the list
    await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
    // Phase 113 (DATA-01) made operator-deliveries-list the mobile-only (md:hidden)
    // <ul>; assert the viewport-agnostic operator-deliveries-list-card <aside> wrapper.
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const deliveryId = await page.getByTestId("operator-delivery-row").first().getAttribute("phx-value-id");
    await page.goto(`/demo/login?return_to=/ops/mail?tenant_id=northstar%26delivery_id=${deliveryId}`);

    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-timeline")).toBeVisible();
  });

  test("inbound operator opens with seeded support mailbox evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /inbound operator/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\/inbound\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Inbound records", exact: true })).toBeVisible();
    // Phase 113 (DATA-01): inbound-records-list is the mobile-only <ul>; assert the
    // viewport-agnostic inbound-records-list-card <aside> wrapper instead.
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const inboundId = await page.getByTestId("inbound-record-row").first().getAttribute("phx-value-id");
    await page.goto(`/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar%26inbound_id=${inboundId}`);
    await expect(page.getByTestId("inbound-detail-header")).toBeVisible();
  });
});
