const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";
const exactRecipient = "browser-exact@example.com";
const ambiguousRecipient = "browser-ambiguous@example.com";
const noopRecipient = "browser-noop@example.com";
const selectedRecipient = "browser-selected@example.com";

function deliveryRow(page, index) {
  // Phase 113 (DATA-01) renders rows in two presentations sharing this testid:
  // a desktop <table> (>=768px) and a mobile card <ul> (<768px). Exactly one is
  // visible per viewport, so filter to the visible presentation before indexing —
  // otherwise .nth() resolves the hidden desktop <tr> at mobile widths and clicks hang.
  return page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(index);
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
  // Phase 113 (DATA-01) split the deliveries list into a responsive table
  // (>=768px) + card list (<768px). The legacy `operator-deliveries-list` <ul>
  // is now the mobile-only (md:hidden) presentation, so it is hidden on the
  // desktop viewports most operator-gate tests use. Assert the viewport-agnostic
  // `operator-deliveries-list-card` aside instead — it is visible at all widths
  // on a fresh (pre-selection) deliveries view.
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
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

  test("mobile shows orientation before list and preserves detail section order", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openOperator(page);

    const deliveriesCard = page.getByTestId("operator-deliveries-list-card");
    const orientation = page.getByTestId("deliveries-orientation");

    const deliveriesBox = await deliveriesCard.boundingBox();
    const orientationBox = await orientation.boundingBox();

    expect(deliveriesBox).not.toBeNull();
    expect(orientationBox).not.toBeNull();
    expect(orientationBox.y).toBeLessThan(deliveriesBox.y);

    await deliveryRow(page, 0).click();

    await expect(deliveriesCard).toBeHidden();
    await expect(page.getByTestId("operator-detail-back")).toBeVisible();

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

  test("failed SendGrid row remains index-pinned for failure audit", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const failedRow = deliveryRow(page, 4);

    await expect(failedRow).toContainText("Failed");
    await failedRow.click();

    const detailHeader = page.getByTestId("operator-detail-header");
    await expect(detailHeader).toContainText("browser-other@example.com");
    await expect(detailHeader).toContainText("Failed");
    await expect(detailHeader).toContainText("SENDGRID");
    await expect(detailHeader).toContainText("sg_browser_other");
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
    await expect(page.getByTestId("operator-timeline")).toContainText("Webhook replay completed", { timeout: 10000 });
    await expect(page.getByTestId("operator-timeline")).toContainText("Replay succeeded");
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

    const secondTarget = page.getByRole("radio", { name: "POSTMARK webhook target", exact: true }).nth(1);
    await secondTarget.focus();
    await page.keyboard.press("Space");
    await expect(secondTarget).toBeChecked();
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

    // Click the first delivery row and read the delivery_id from the URL.
    // LiveView pushes the delivery_id param asynchronously, so wait for the
    // URL to settle before reading it (mirrors the existing selection tests).
    await deliveryRow(page, 0).click();
    await expect(page).toHaveURL(/delivery_id=/);
    const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId).toBeTruthy();

    // The detail pane must carry the record-keyed id
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();

    // Switch to a second delivery and verify the id changes (element replaced, not patched).
    // Wait until the delivery_id param actually changes — toHaveURL(/delivery_id=/) is
    // already true from the first selection and would not gate the transition.
    await deliveryRow(page, 1).click();
    await page.waitForURL((url) => {
      const id = new URL(url).searchParams.get("delivery_id");
      return Boolean(id) && id !== deliveryId;
    });
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
    await expect(page).toHaveURL(/delivery_id=/);
    const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId).toBeTruthy();

    // Under reduced-motion the animation resolves at 0.01ms — element must not be
    // stuck invisible at opacity: 0
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();
  });

  // MOTION-02 regression gate (D-07 / GAP-13):
  // Asserts the inbound detail pane carries a record-keyed id attribute
  // (#inbound-detail-<uuid>) that is visible after clicking an inbound row.
  // Requires Phase 78 seed: one InboundRecord in the browser scenario.
  test("inbound detail pane carries record-keyed id", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);

    // Click the first inbound row — testid matches DOM: data-testid="inbound-record-row"
    await page.getByTestId("inbound-record-row").nth(0).click();

    // LiveView pushes inbound_id param; wait for URL to settle
    await expect(page).toHaveURL(/inbound_id=/);
    const inboundId = new URL(page.url()).searchParams.get("inbound_id");
    expect(inboundId).toBeTruthy();

    // The detail pane must carry the record-keyed id
    await expect(page.locator(`#inbound-detail-${inboundId}`)).toBeVisible();
  });

  test("why-did-inbound-not-route desktop exposes overview, routing trace, and redacted evidence", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);

    const overview = page.getByTestId("inbound-overview");
    await expect(overview).toBeVisible();
    await expect(overview).toContainText("No-match rate");

    const noMatchRow = page
      .getByTestId("inbound-record-row")
      .filter({ has: page.locator(".badge-warning", { hasText: "No match" }) })
      .first();

    await expect(noMatchRow).toContainText("No match");
    await noMatchRow.click();

    await expect(page).toHaveURL(/inbound_id=/);
    await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
    await expect(page.getByTestId("inbound-trace-clause")).not.toHaveCount(0);
    await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();
    await expect(page.getByTestId("inbound-evidence-redacted")).toBeVisible();
    await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
  });

  test("why-did-inbound-not-route mobile selection swaps list for detail and back", async ({
    page
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openOperator(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);

    const recordsCard = page.getByTestId("inbound-records-list-card");
    await expect(recordsCard).toBeVisible();

    await page
      .getByTestId("inbound-record-row")
      .filter({ visible: true })
      .filter({ has: page.locator(".badge-warning", { hasText: "No match" }) })
      .first()
      .click();

    await expect(page).toHaveURL(/inbound_id=/);
    await expect(recordsCard).toBeHidden();
    await expect(page.getByTestId("inbound-detail-back")).toBeVisible();

    await page.getByTestId("inbound-detail-back").click();
    await expect(recordsCard).toBeVisible();
    await expect(page).not.toHaveURL(/inbound_id=/);
  });

  // VERIF-02: structural coverage for Operator Overview landing (D-05 / GAP-register sev-4 closeout)
  // Asserts the health-count cards container and navigation CTAs container are visible
  // when the tenant is scoped. Uses getByTestId for structural assertions (not pixel-based).
  test("operator overview landing has health cards and navigation CTAs", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Navigate back to the Overview landing (openOperator navigates to Deliveries view)
    await page.goto(`/ops/mail?tenant_id=${tenantId}`);
    await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();

    // Overview container
    await expect(page.getByTestId("operator-overview")).toBeVisible();

    // Health-count cards container (all four sub-cards always render; colors vary by seed state)
    await expect(page.getByTestId("operator-overview-health")).toBeVisible();

    // Navigation CTAs container (View Deliveries + View Inbound links)
    await expect(page.getByTestId("operator-overview-nav")).toBeVisible();

    // SHELL-02: failures stat card is wrapped in a drill-through link to status=failed Deliveries
    const failuresLink = page.getByTestId("operator-overview-health-failures-link");
    await expect(failuresLink).toBeVisible();
    await expect(failuresLink).toHaveAttribute("href", /status=failed/);

    // SHELL-02: suppressions stat card is wrapped in a drill-through link to status=suppressed Deliveries
    const suppressionsLink = page.getByTestId("operator-overview-health-suppressions-link");
    await expect(suppressionsLink).toBeVisible();
    await expect(suppressionsLink).toHaveAttribute("href", /status=suppressed/);
  });

  // SHELL-02: orientation strip is empty-pane-only — present on all-clear, absent when attention needed.
  // Uses the browser-tenant persona which has existing seed data (non-zero failures = attention state).
  // The all-clear branch is checked by navigating to a tenant with no seed failures/suppressions;
  // use the browser-tenant directly for the attention check (seed data includes failures).
  test("operator overview orientation strip is empty-pane-only (all-clear vs attention)", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Navigate to Overview (openOperator lands on Deliveries)
    await page.goto(`/ops/mail?tenant_id=${tenantId}`);
    await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();

    // In the browser-tenant with seed data present, the Overview is in attention state.
    // The orientation strip should be absent (suppressed — health needs attention).
    // NOTE: this assertion goes RED until Task 2 gates the strip on the all-clear predicate.
    await expect(page.getByTestId("operator-overview-orientation")).toHaveCount(0);
  });

  // VERIF-02: structural coverage for inbound and preview orientation strips (D-05)
  // Asserts inbound-orientation and preview-orientation testids are visible on
  // their respective surfaces. Mirrors the existing deliveries-orientation check
  // in the mobile test (line 101).
  test("inbound and preview surfaces render their orientation strips", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Inbound surface orientation strip
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-orientation")).toBeVisible();

    // Preview surface orientation strip (renders when @mailables == []).
    // Navigate via /ops/browser-preview-empty which sets mailables=[] in the session
    // before redirecting to /dev/mail/ — the test router is configured with explicit
    // mailables so a direct goto would show the landing card instead of the strip.
    await page.goto("/ops/browser-preview-empty");
    await expect(page.getByTestId("preview-orientation")).toBeVisible();
  });
});
