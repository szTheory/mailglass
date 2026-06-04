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
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  // Navigate to Deliveries view before delivery-centric assertions.
  // Target the page h1 (level 1) explicitly: the Deliveries surface now also
  // renders the orientation strip's <h2>Deliveries</h2> section heading, so an
  // unqualified heading query is ambiguous under Playwright strict mode at the
  // viewports where the strip is visible.
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(
    page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
  ).toBeVisible();
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

    // Acceptance check for GAP-07 at 390px: orientation strip must be visible (deliveries-orientation)
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("deliveries-orientation")).toBeVisible();
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

  // MOTION-01 regression gate (D-07 / GAP-19):
  // Asserts the delivery detail pane carries a record-keyed id attribute
  // (#delivery-detail-<uuid>) that changes when a different delivery is selected.
  // LiveView's element-replace (rather than in-place patch) re-fires the mg-reveal
  // keyframe animation on each selection. ExUnit substring tests cannot catch a
  // missing or static id attribute — this Playwright DOM-layer test is the Nyquist gate.
  test("delivery detail pane carries record-keyed id for animation re-fire", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Click the first delivery row and read the delivery_id from the URL
    await deliveryRow(page, 0).click();
    const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId).toBeTruthy();

    // The detail pane must carry the record-keyed id
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();

    // Switch to a second delivery and verify the id changes (element replaced, not patched)
    await deliveryRow(page, 1).click();
    const deliveryId2 = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId2).not.toEqual(deliveryId);

    // New id visible; old id absent — confirms LiveView performed element replace
    await expect(page.locator(`#delivery-detail-${deliveryId2}`)).toBeVisible();
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toHaveCount(0);
  });

  // MOTION-02 regression gate (D-07 / GAP-19):
  // Asserts that the detail element remains visible (not stuck at opacity: 0)
  // under prefers-reduced-motion: reduce. The global app.css reduced-motion block
  // sets animation-duration: 0.01ms !important so the element is immediately visible.
  // Media emulation MUST precede page.goto (which happens inside openOperator).
  test("motion-reveal is suppressed under prefers-reduced-motion", async ({ page }) => {
    // Emulate reduced-motion BEFORE navigation so the media query is active on initial load
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    await deliveryRow(page, 0).click();
    const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId).toBeTruthy();

    // Under reduced-motion the animation resolves at 0.01ms — element must not be
    // stuck invisible at opacity: 0
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();
  });

  // SKIPPED: inbound id-presence assertion (seed dependency — Phase 78)
  //
  // The inbound detail pane HEEx fix (id={"inbound-detail-#{@detail.record.id}"}) ships in
  // Plan 01 (Phase 77). This e2e assertion is skipped because OperatorFixtures.seed_browser_scenario!()
  // seeds zero inbound records — there is no navigable inbound row in the browser scenario.
  //
  // To enable this test: Phase 78 must seed at least one InboundRecord in the browser scenario.
  // Once that seed is added, remove the skip wrapper and implement the assertion:
  //   1. Navigate to /ops/inbound?tenant_id=browser-tenant
  //   2. Click the first inbound row
  //   3. Read inbound_id from new URL(page.url()).searchParams.get("inbound_id")
  //   4. Assert page.locator(`#inbound-detail-${inboundId}`) toBeVisible()
  test.skip("inbound detail pane carries record-keyed id [SKIP: requires inbound seed in browser scenario]", async ({ page }) => {
    // Phase 78 seed expansion is the gate to enable this test.
    // See OperatorFixtures.seed_browser_scenario!() — zero inbound records are seeded.
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);
    await page.goto(`/ops/inbound?tenant_id=${tenantId}`);

    // Click the first inbound row (requires Phase 78 to seed at least one inbound record)
    await page.getByTestId("operator-inbound-row").nth(0).click();
    const inboundId = new URL(page.url()).searchParams.get("inbound_id");
    expect(inboundId).toBeTruthy();

    await expect(page.locator(`#inbound-detail-${inboundId}`)).toBeVisible();
  });
});
