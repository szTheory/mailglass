const { test, expect } = require("@playwright/test");
const {
  launchRealZoomContext,
  applyRealZoom,
  measureEffective,
  recordReceipt,
  undersizedTargets,
  TARGET_CSS_WIDTH
} = require("./support/real-zoom.cjs");

// Phase 178 (UIQ-06 / D-10): actual 200% Chromium tab zoom on the connected
// Operator routes the milestone left to this phase. One persistent context is
// shared by the serial cases because tab zoom is per origin and survives
// same-origin navigation, so the extension is loaded and zoom applied once.
// Every case re-measures its own receipt: the document width depends on the
// route, not on the zoom that was applied in beforeAll.

const tenantId = "browser-tenant";

let context;
let page;
let baseReceipt;

async function openTenant({ scenario, returnPath } = {}) {
  await context.clearCookies();
  const reset = await page.request.get(`/ops/browser-reset${scenario ? `?scenario=${scenario}` : ""}`);
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(returnPath || `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
}

// The shared receipt with this route's own effective measurement.
async function receiptFor() {
  return { ...baseReceipt, effective: await measureEffective(page) };
}

function insideViewport(box, label) {
  expect(box, `${label} has a rendered box`).not.toBeNull();
  expect(box.x, `${label} starts inside the viewport`).toBeGreaterThanOrEqual(-0.5);
  expect(box.x + box.width, `${label} ends inside ${TARGET_CSS_WIDTH} CSS px`).toBeLessThanOrEqual(
    TARGET_CSS_WIDTH + 0.5
  );
}

test.describe.serial("Phase 178 real zoom", () => {
  test.beforeAll(async () => {
    test.setTimeout(90_000);
    context = await launchRealZoomContext();
    page = context.pages()[0] || (await context.newPage());
    await openTenant();
    baseReceipt = await applyRealZoom(context, page);
  });

  test.afterAll(async () => {
    await context?.close();
  });

  test("Phase 178 real zoom: Delivery quick view keeps position, arrows and Close usable at 320 CSS px", async ({}, testInfo) => {
    await openTenant({ returnPath: `/ops/mail?tenant_id=${tenantId}&view=deliveries` });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    // At 320 CSS px the card list is shown and each card is itself the opener.
    const opener = page.locator('button[id^="operator-delivery-mobile-"]').filter({ visible: true }).first();
    const openerId = await opener.getAttribute("id");
    expect(openerId, "the Delivery opener carries the id Quick view returns focus to").toBeTruthy();
    await opener.click();

    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    const receipt = await receiptFor();
    recordReceipt(testInfo, receipt, "Delivery quick view");

    const position = quickView.locator('[aria-live="polite"]');
    await expect(position).toHaveText(/^\s*1 of \d+\s*$/);
    const total = Number((await position.textContent()).trim().split(" of ")[1]);
    expect(total, "the seeded Deliveries list has more than one row").toBeGreaterThan(1);

    expect(await undersizedTargets(page, '[data-testid="operator-quick-view"]'), "Quick view targets stay 44x44").toEqual(
      []
    );
    for (const name of ["Close quick view", "Next delivery", "Open full detail"]) {
      const control = quickView.getByRole("link", { name, exact: true });
      await expect(control, `${name} is visible`).toBeVisible();
      insideViewport(await control.boundingBox(), name);
    }
    insideViewport(await position.boundingBox(), "position counter");

    // The next arrow navigates; the previous arrow goes back.
    const firstId = new URL(page.url()).searchParams.get("delivery_id");
    await quickView.getByRole("link", { name: "Next delivery", exact: true }).click();
    await expect(position).toHaveText(`2 of ${total}`);
    await expect.poll(() => new URL(page.url()).searchParams.get("delivery_id")).not.toBe(firstId);
    await quickView.getByRole("link", { name: "Previous delivery", exact: true }).click();
    await expect(position).toHaveText(`1 of ${total}`);

    // Close returns focus to the control that opened the Quick view.
    await quickView.getByRole("link", { name: "Close quick view", exact: true }).click();
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
    await expect(page.locator(`#${openerId}`)).toBeFocused();
  });
});
