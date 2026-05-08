const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";
const exactRecipient = "browser-exact@example.com";
const ambiguousRecipient = "browser-ambiguous@example.com";
const noopRecipient = "browser-noop@example.com";
const selectedRecipient = "browser-selected@example.com";

function deliveryRow(page, index) {
  return page.getByTestId("operator-delivery-row").nth(index);
}

async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Operator deliveries" })).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}

test.describe("operator browser gate", () => {
  test("desktop keeps list/detail in two panes and preserves read-only selection flow", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const deliveriesCard = page.getByTestId("operator-deliveries-list-card");
    const detailColumn = page.getByTestId("operator-detail-column");
    const emptyDetail = page.getByTestId("operator-empty-detail");

    await expect(emptyDetail).toBeVisible();

    const deliveriesBox = await deliveriesCard.boundingBox();
    const detailBox = await detailColumn.boundingBox();

    expect(deliveriesBox).not.toBeNull();
    expect(detailBox).not.toBeNull();
    expect(deliveriesBox.y).toBeLessThanOrEqual(detailBox.y);

    const selectedRow = deliveryRow(page, 0);

    await selectedRow.click();

    await expect(selectedRow).toHaveAttribute("aria-selected", "true");
    await expect(selectedRow).toHaveAttribute("data-selected", "true");
    await expect(page).toHaveURL(/\/ops\/mail\?/);
    await expect(page).toHaveURL(/delivery_id=/);

    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(selectedRecipient);
    await expect(page.getByTestId("operator-detail-header")).toContainText(
      "Replay is unavailable."
    );
    await expect(page.getByTestId("operator-timeline")).toBeVisible();
    await expect(page.getByTestId("operator-suppression-card")).toBeVisible();
    await expect(page.getByTestId("operator-suppression-card")).toContainText("ops:review");
    await expect(page.getByTestId("operator-replay-open")).toBeVisible();
    await expect(page.getByRole("button", { name: /remove suppression/i })).toHaveCount(0);
  });

  test("mobile stacks list before detail and preserves detail section order", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openOperator(page);

    const deliveriesCard = page.getByTestId("operator-deliveries-list-card");
    const detailColumn = page.getByTestId("operator-detail-column");

    const deliveriesBox = await deliveriesCard.boundingBox();
    const detailBox = await detailColumn.boundingBox();

    expect(deliveriesBox).not.toBeNull();
    expect(detailBox).not.toBeNull();
    expect(deliveriesBox.y).toBeLessThan(detailBox.y);

    await deliveryRow(page, 0).click();

    const headerBox = await page.getByTestId("operator-detail-header").boundingBox();
    const timelineBox = await page.getByTestId("operator-timeline").boundingBox();
    const suppressionBox = await page.getByTestId("operator-suppression-card").boundingBox();

    expect(headerBox).not.toBeNull();
    expect(timelineBox).not.toBeNull();
    expect(suppressionBox).not.toBeNull();
    expect(headerBox.y).toBeLessThan(timelineBox.y);
    expect(timelineBox.y).toBeLessThan(suppressionBox.y);
  });

  test("exact replay flow shows ready copy and records a new-work outcome", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const exactRow = deliveryRow(page, 3);

    await exactRow.click();
    await expect(page.getByTestId("operator-detail-header")).toContainText(exactRecipient);
    await expect(page.getByTestId("operator-detail-header")).toContainText("Replay is ready.");

    await page.getByTestId("operator-replay-open").click();

    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Replay is ready.");
    await expect(modal).toContainText("Confirm to replay that stored request.");
    await expect(modal).toContainText("browser-exact-delivery");

    await page.getByTestId("operator-replay-confirm").click();

    await expect(page.getByText("Replay completed with new work.")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(
      "Last replay: completed · new work"
    );
    await expect(page.getByTestId("operator-timeline")).toContainText("Replay audit");
    await expect(page.getByTestId("operator-timeline")).toContainText("completed");
    await expect(page.getByTestId("operator-timeline")).toContainText("new work");
  });

  test("ambiguous replay flow requires an explicit choice before confirm is available", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const ambiguousRow = deliveryRow(page, 2);

    await ambiguousRow.click();
    await expect(page.getByTestId("operator-detail-header")).toContainText(ambiguousRecipient);
    await expect(page.getByTestId("operator-detail-header")).toContainText(
      "Replay is choice required."
    );

    await page.getByTestId("operator-replay-open").click();

    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Replay is choice required.");
    await expect(modal).toContainText(
      "The operator UI will not guess across multiple replayable webhook rows."
    );
    await expect(modal).toContainText("browser-ambiguous-delivery-1");
    await expect(modal).toContainText("browser-ambiguous-delivery-2");
    await expect(page.getByTestId("operator-replay-confirm")).toHaveCount(0);

    await page.getByRole("radio", { name: /browser-ambiguous-delivery-2/i }).check();
    await expect(page.getByTestId("operator-replay-confirm")).toBeVisible();
  });

  test("noop replay flow keeps no-change wording visible in the browser", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const noopRow = deliveryRow(page, 1);

    await noopRow.click();
    await expect(page.getByTestId("operator-detail-header")).toContainText(noopRecipient);
    await expect(page.getByTestId("operator-detail-header")).toContainText("Replay is ready.");

    await page.getByTestId("operator-replay-open").click();
    await page.getByTestId("operator-replay-confirm").click();

    await expect(page.getByText("Replay completed with no change.")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(
      "Last replay: completed · no change"
    );
    await expect(page.getByTestId("operator-timeline")).toContainText("completed");
    await expect(page.getByTestId("operator-timeline")).toContainText("no change");
  });
});
