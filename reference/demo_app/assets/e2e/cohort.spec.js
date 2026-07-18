// cohort.spec.js — RATCHET-04 "≥1 Playwright run against rich demo_app data".
//
// Extends the existing demo evidence harness (demo.spec.js): the same
// beforeEach POST /demo/evidence/reset (x-mailglass-demo-reset-token) re-runs
// DemoData.reset! -> MailglassDemo.Personas.seed!, so this suite runs against
// the rich multi-account persona cohort (northstar / fjordline-aps / helios-void).
// No new harness, OperatorBrowserServer is NOT bent (D-10).
//
// This is the RATCHET-04 demo-data run: structural assertions (account picker
// visibility, edge-value render, empty-state), NOT an axe baseline (axe stays
// admin-only per RESEARCH). Kept serial via the shared playwright.config.cjs
// (the destructive /demo/evidence/reset races a shared DB across parallel
// workers — do NOT set fullyParallel:true).
//
// Render-surface notes (what the demo operator surface DOES vs does NOT show):
//   * The long delivery id (provider_message_id) renders in the detail header
//     "Provider message" field; the 64-char long mailable name renders there too.
//   * The recipient renders verbatim in the detail header <h2> (unmasked there;
//     the list masks it).
//   * The non-ASCII from[].name display names live in Delivery.metadata["from"],
//     which the operator surface does NOT render — their verbatim render is
//     covered by the gallery fjordline specimens (plan 116-04), not here.
//   * The fjordline event is :delivered with reject_reason: nil, so the timeline
//     shows NO "Reason:" line (the legitimate null branch).

const { test, expect } = require("@playwright/test");

// Canonical persona stress literals (MailglassDemo.Personas.specimen_literals/0).
const LONG_DELIVERY_ID = "del_01JXW9ZQKB3V1N4P2RMT7FHCG";
const LONG_MAILABLE = "Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName";
const FJORDLINE_RECIPIENT = "bjorn.hansen@fjordline-aps.example";

// Asserts the PAGE does not develop horizontal overflow — the long-ID /
// long-mailable / long-recipient truncation contract. We check at the document
// level (not on the table wrapper, which is intentionally `overflow-x-auto`):
// the contract is "no page-level horizontal scrollbar / layout break", and a
// contained scroll region is by design. 1px tolerance for sub-pixel rounding.
async function expectNoPageHorizontalOverflow(page) {
  const overflows = await page.evaluate(
    () => document.documentElement.scrollWidth - window.innerWidth > 1
  );
  expect(overflows, "page overflows the viewport horizontally").toBe(false);
}

test.describe("persona cohort — RATCHET-04 rich demo_app run", () => {
  test.beforeEach(async ({ request }) => {
    // Same seam as demo.spec.js: re-seed the cohort (DemoData.reset! ->
    // Personas.seed!) before each test so northstar + fjordline-aps + the
    // helios-void no-data edge are present.
    const response = await request.post("/demo/evidence/reset", {
      headers: {
        "x-mailglass-demo-reset-token": process.env.DEMO_EVIDENCE_RESET_TOKEN || "",
      },
    });
    expect(response.ok()).toBeTruthy();
  });

  test("account picker lists the two deliveries-bearing personas; helios-void absent", async ({
    page,
  }) => {
    // No tenant_id => operator surface renders the >=2-account picker
    // (tenant_state :select_required). safe_return_to allows "/ops/mail".
    await page.goto("/demo/login?return_to=/ops/mail");
    await expect(page).toHaveURL(/\/ops\/mail$/);

    const picker = page.getByTestId("tenant-selector");
    await expect(picker).toBeVisible();

    // northstar + fjordline-aps both bear deliveries -> both selectable.
    // The picker shows account labels while URLs still carry tenant_id.
    await expect(
      picker.getByRole("link", { name: /Northstar Logistics/ })
    ).toBeVisible();
    await expect(
      picker.getByRole("link", { name: /Fjordline A\/S/ })
    ).toBeVisible();

    // helios-void is realized by ABSENCE (zero Delivery rows) -> NOT selectable.
    await expect(picker.getByText("Helios Trial", { exact: true })).toHaveCount(0);
  });

  test("fjordline-aps edge values render: long-ID + long-mailable truncated, recipient verbatim, nil reject_reason no reason line", async ({
    page,
  }) => {
    await page.goto("/demo/login?return_to=/ops/mail?tenant_id=fjordline-aps");
    await page.goto("/ops/mail?tenant_id=fjordline-aps&view=deliveries");

    // Desktop table is the visible container at the 1280px default viewport
    // (the mobile <ul> operator-deliveries-list is md:hidden).
    const table = page.getByTestId("operator-deliveries-table");
    await expect(table).toBeVisible();
    await expectNoPageHorizontalOverflow(page);

    // Open the single fjordline-aps delivery's FULL detail. Navigate via the
    // delivery_id + full=1 URL params (the demo.spec.js pattern) rather than a
    // phx-click, which is robust to LiveView connection timing. `full=1` is
    // required post-#128: a bare delivery_id opens the Quick view peek, and the
    // detail header lives one step deeper in Full detail.
    const row = table.getByTestId("operator-delivery-row").first();
    await expect(row).toBeVisible();
    const deliveryId = await row.getAttribute("phx-value-id");
    expect(deliveryId).toBeTruthy();
    await page.goto(
      `/ops/mail?tenant_id=fjordline-aps&delivery_id=${deliveryId}&full=1`
    );

    const detail = page.getByTestId("operator-detail-header");
    await expect(detail).toBeVisible();
    // The page must not overflow horizontally despite the long
    // provider_message_id and 64-char mailable name (truncation contract).
    await expectNoPageHorizontalOverflow(page);

    // The long delivery id (provider_message_id) renders verbatim in the
    // "Provider message" field (truncated by CSS, not the string).
    await expect(detail.getByText(LONG_DELIVERY_ID)).toBeVisible();
    // The 64-char long mailable module name renders verbatim.
    await expect(detail.getByText(LONG_MAILABLE)).toBeVisible();
    // The recipient renders verbatim (unmasked) in the detail header.
    await expect(detail.getByText(FJORDLINE_RECIPIENT)).toBeVisible();

    // The single event is :delivered with reject_reason: nil -> the timeline
    // shows NO "Reason:" line (the legitimate null branch, not an error).
    const timeline = page.getByTestId("operator-timeline");
    await expect(timeline).toBeVisible();
    await expect(timeline.getByText(/^Reason:/)).toHaveCount(0);
  });

  test("northstar high-count lifecycle renders without horizontal overflow", async ({ page }) => {
    await page.goto("/demo/login?return_to=/ops/mail?tenant_id=northstar");
    await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");

    const table = page.getByTestId("operator-deliveries-table");
    await expect(table).toBeVisible();

    // northstar carries the many/high-count/error lifecycle (incl the >=80-char
    // truncation-stress recipient). The page must not overflow / collapse.
    await expectNoPageHorizontalOverflow(page);

    // Multiple delivery rows present (high-count edge), confirming the rich seed.
    const rowCount = await table.getByTestId("operator-delivery-row").count();
    expect(rowCount).toBeGreaterThan(1);
  });

  test("helios-void direct URL renders the empty state, not a crash", async ({ page }) => {
    await page.goto("/demo/login?return_to=/ops/mail?tenant_id=helios-void");
    // Direct navigation to the zero-delivery account renders the scoped surface.
    await page.goto("/ops/mail?tenant_id=helios-void&view=deliveries");

    // A crash would surface a Phoenix/Plug error page, not the operator shell.
    await expect(page.getByTestId("admin-shell-sidebar")).toContainText("Deliveries");

    // The deliveries surface for a zero-delivery account shows the empty state
    // ("No deliveries" heading), never another tenant's rows.
    await expect(
      page.getByRole("heading", { name: "No deliveries", exact: true })
    ).toBeVisible();
    await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);

    // No server-error page.
    await expect(page.locator("body")).not.toContainText("Internal Server Error");
  });
});
