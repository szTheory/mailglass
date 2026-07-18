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
    await expect(
      page.getByRole("heading", { name: "Explore Mailglass in a working app", exact: true }),
    ).toBeVisible();
    await expect(page.getByText("AtlasDesk", { exact: false }).first()).toBeVisible();
    await expect(page.getByText("Email deliveries", { exact: true })).toBeVisible();

    const headingBox = await page
      .getByRole("heading", { name: "Explore Mailglass in a working app", exact: true })
      .boundingBox();
    const introBox = await page.getByTestId("dashboard-intro").boundingBox();
    const statsBox = await page.locator('[aria-label="Seeded demo data"]').boundingBox();

    expect(headingBox).not.toBeNull();
    expect(introBox).not.toBeNull();
    expect(statsBox).not.toBeNull();
    expect(introBox.y).toBeGreaterThan(headingBox.y + headingBox.height - 1);
    expect(statsBox.y).toBeGreaterThan(introBox.y + introBox.height - 1);

    await page.getByRole("link", { name: /preview emails/i }).click();
    await expect(page).toHaveURL(/\/dev\/mail\/MailglassDemoWeb\.Mailers\.AccountMailer\/invite_admin/);
    await expect(page.getByTestId("admin-shell-page-header")).toBeVisible();
    await expect(page.getByTestId("preview-email-menu-trigger")).toBeVisible();
    await expect(page.getByTestId("preview-email-menu-trigger")).toContainText("AccountMailer");
  });

  test("outbound operator opens with seeded delivery evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /trace a sent email/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
    // Navigate to Deliveries view to assert the list
    await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
    // Phase 113 (DATA-01) made operator-deliveries-list the mobile-only (md:hidden)
    // <ul>; assert the viewport-agnostic operator-deliveries-list-card <aside> wrapper.
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const deliveryId = await page.getByTestId("operator-delivery-row").first().getAttribute("phx-value-id");
    // Full detail (`full=1`) is where the detail header + timeline render; a bare
    // `delivery_id=` opens the Quick view peek (two-tier redesign, PR #128).
    await page.goto(`/demo/login?return_to=/ops/mail?tenant_id=northstar%26delivery_id=${deliveryId}%26full=1`);

    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-timeline")).toBeVisible();
  });

  test("inbound operator opens with seeded support mailbox evidence", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: /follow an inbound message/i }).click();
    await expect(page).toHaveURL(/\/ops\/mail\/inbound\?tenant_id=northstar/);
    await expect(page.getByRole("heading", { name: "Inbound records", exact: true })).toBeVisible();
    // Phase 113 (DATA-01): inbound-records-list is the mobile-only <ul>; assert the
    // viewport-agnostic inbound-records-list-card <aside> wrapper instead.
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const inboundId = await page.getByTestId("inbound-record-row").first().getAttribute("phx-value-id");
    // full=1 opens Full detail (where the detail header renders); a bare
    // inbound_id opens the Quick view peek (two-tier redesign, PR #128).
    await page.goto(`/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar%26inbound_id=${inboundId}%26full=1`);
    await expect(page.getByTestId("inbound-detail-header")).toBeVisible();
  });
});
