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

// Two-tier inspection: a row click opens the condensed Quick view (peek); the full
// record (header, timeline, suppression, replay) lives one tier deeper behind
// "Open full detail" (&full=1). These helpers drive a row straight to Full detail.
async function openDeliveryFull(page, row) {
  await row.click();
  await expect(page.getByTestId("operator-quick-view")).toBeVisible();
  await page.getByTestId("operator-quick-view-full").click();
  await expect(page).toHaveURL(/full=1/);
}

async function openInboundFull(page, row) {
  await row.click();
  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  await page.getByTestId("inbound-quick-view-full").click();
  await expect(page).toHaveURL(/full=1/);
}

async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  // Navigate to Deliveries view before delivery-centric assertions.
  // Target the page h1 (level 1) explicitly. The orientation strip is now
  // empty-pane-only (Phase 120 / D-08): on a POPULATED Deliveries view the strip
  // — and its second <h2>Deliveries</h2> section heading (the D-LABEL-TRIPLING
  // third heading) — is no longer rendered, so the historical heading ambiguity is
  // gone here. The `level: 1` qualifier is retained anyway: it is harmless, still
  // correct, and keeps the query unambiguous on the genuine-no-data view where the
  // strip (and its <h2>) does render.
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
  test("desktop: a row opens the Quick view over the list; Open full detail shows the full record", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const deliveriesCard = page.getByTestId("operator-deliveries-list-card");
    await expect(deliveriesCard).toBeVisible();

    // No selection → no overlay and no full detail; the list stands alone (full width).
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
    await expect(page.getByTestId("operator-detail-header")).toHaveCount(0);

    const selectedRow = deliveryRow(page, 0);
    await selectedRow.click();

    // Quick view (peek) slides in; the list stays in the DOM behind it, row highlighted.
    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    await expect(deliveriesCard).toBeVisible();
    await expect(selectedRow).toHaveAttribute("aria-selected", "true");
    await expect(selectedRow).toHaveAttribute("data-selected", "true");
    await expect(page).toHaveURL(/\/ops\/mail\?/);
    await expect(page).toHaveURL(/delivery_id=/);
    await expect(page).not.toHaveURL(/full=1/);
    // The peek is condensed: the full timeline / suppression / replay are deferred.
    await expect(page.getByTestId("operator-timeline")).toHaveCount(0);
    await expect(page.getByTestId("operator-replay-open")).toHaveCount(0);

    // Open full detail → the complete record, full width, list replaced.
    await page.getByTestId("operator-quick-view-full").click();
    await expect(page).toHaveURL(/full=1/);
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);

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

    // Full detail leads with the event timeline (above suppression).
    const timelineBox = await page.getByTestId("operator-timeline").boundingBox();
    const suppressionBox = await page.getByTestId("operator-suppression-card").boundingBox();
    expect(timelineBox.y).toBeLessThan(suppressionBox.y);
  });

  test("mobile: row opens the Quick view bottom sheet; full detail preserves section order", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openOperator(page);

    // Phase 120 / D-08: the orientation strip is empty-pane-only. On a POPULATED
    // Deliveries view it is NOT rendered.
    const deliveriesCard = page.getByTestId("operator-deliveries-list-card");
    await expect(deliveriesCard).toBeVisible();
    await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);

    await deliveryRow(page, 0).click();

    // The Quick view opens as a bottom sheet; the list stays mounted behind it.
    await expect(page.getByTestId("operator-quick-view")).toBeVisible();

    // Open full detail → full-screen record with a Back control.
    await page.getByTestId("operator-quick-view-full").click();
    await expect(page).toHaveURL(/full=1/);
    await expect(page.getByTestId("operator-detail-back")).toBeVisible();

    // Detail-section order (header → timeline → suppression) is a stable contract.
    const headerBox = await page.getByTestId("operator-detail-header").boundingBox();
    const timelineBox = await page.getByTestId("operator-timeline").boundingBox();
    const suppressionBox = await page.getByTestId("operator-suppression-card").boundingBox();

    expect(headerBox).not.toBeNull();
    expect(timelineBox).not.toBeNull();
    expect(suppressionBox).not.toBeNull();
    expect(headerBox.y).toBeLessThan(timelineBox.y);
    expect(timelineBox.y).toBeLessThan(suppressionBox.y);

    // Re-confirm strip absence on the populated &view=deliveries route at 390px.
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);
  });

  test("failed SendGrid row remains index-pinned for failure audit", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    const failedRow = deliveryRow(page, 4);

    await expect(failedRow).toContainText("Failed");
    await openDeliveryFull(page, failedRow);

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

    await openDeliveryFull(page, exactRow);
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

    await openDeliveryFull(page, ambiguousRow);
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

    await openDeliveryFull(page, noopRow);
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

    // The record-keyed id (#delivery-detail-<uuid>) now lives in Full detail.
    await openDeliveryFull(page, deliveryRow(page, 0));
    const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId).toBeTruthy();
    await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();

    // Flip to the next record via the Quick view (all push_patch, no full reload) and
    // re-enter Full detail — the id must change (element replaced, not patched in place).
    await page.getByTestId("operator-detail-back").click();
    await expect(page.getByTestId("operator-quick-view")).toBeVisible();
    await page.getByTestId("operator-quick-view-next").click();
    await page.waitForURL((url) => {
      const id = new URL(url).searchParams.get("delivery_id");
      return Boolean(id) && id !== deliveryId;
    });
    await page.getByTestId("operator-quick-view-full").click();
    await expect(page).toHaveURL(/full=1/);
    const deliveryId2 = new URL(page.url()).searchParams.get("delivery_id");
    expect(deliveryId2).not.toEqual(deliveryId);

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

    await openDeliveryFull(page, deliveryRow(page, 0));
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

    // The record-keyed id (#inbound-detail-<uuid>) now lives in Full detail.
    await openInboundFull(page, page.getByTestId("inbound-record-row").nth(0));
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
    await openInboundFull(page, noMatchRow);

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

    // Row click opens the Quick view bottom sheet; the list stays mounted behind it.
    await expect(page).toHaveURL(/inbound_id=/);
    await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
    await expect(page.getByTestId("inbound-detail-back")).toBeVisible();

    // The ✕ dismisses the overlay back to the records list.
    await page.getByTestId("inbound-detail-back").click();
    await expect(page).not.toHaveURL(/inbound_id=/);
    await expect(recordsCard).toBeVisible();
    await expect(page.getByTestId("inbound-quick-view")).toHaveCount(0);
  });

  // VERIF-02: structural coverage for Operator Overview landing (D-05 / GAP-register sev-4 closeout)
  // Asserts the health-count cards container and drill-through links are visible
  // when the tenant is scoped. Uses getByTestId for structural assertions (not pixel-based).
  // Note: operator-overview-nav (Navigate block) was removed in Phase 119 (SHELL-02).
  test("operator overview landing has health cards and drill-through links", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Navigate back to the Overview landing (openOperator navigates to Deliveries view)
    await page.goto(`/ops/mail?tenant_id=${tenantId}`);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();

    // Overview container
    await expect(page.getByTestId("operator-overview")).toBeVisible();

    // Health-count cards container (all four sub-cards always render; colors vary by seed state)
    await expect(page.getByTestId("operator-overview-health")).toBeVisible();

    // SHELL-02: failures stat card is wrapped in a drill-through link to failed Deliveries
    const failuresLink = page.getByTestId("operator-overview-health-failures-link");
    await expect(failuresLink).toBeVisible();
    await expect(failuresLink).toHaveAttribute("href", /event=failed/);

    // SHELL-02: suppressions stat card is wrapped in a drill-through link to suppressed Deliveries
    const suppressionsLink = page.getByTestId("operator-overview-health-suppressions-link");
    await expect(suppressionsLink).toBeVisible();
    await expect(suppressionsLink).toHaveAttribute("href", /event=suppressed/);
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
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();

    // In the browser-tenant with seed data present, the Overview is in attention state.
    // The orientation strip should be absent (suppressed — health needs attention).
    // NOTE: this assertion goes RED until Task 2 gates the strip on the all-clear predicate.
    await expect(page.getByTestId("operator-overview-orientation")).toHaveCount(0);
  });

  // D-10 (Phase 120): Deliveries empty-pane-only judgment gate.
  // Modeled on the Overview empty-pane-only gate above, this locks the single-calm-pane
  // contract for the Deliveries surface into the operator browser ratchet:
  //   - POPULATED  → orientation strip ABSENT (count 0) + filters toolbar PRESENT.
  //   - NO-DATA    → orientation strip PRESENT (count 1) + filters toolbar WITHHELD
  //                  (count 0, locks D-02/D-04: the toolbar is the only scope-widening
  //                  vector, so its absence is the security boundary) + master-detail
  //                  grid WITHHELD (count 0, locks the single-calm-pane contract D-03 —
  //                  which is also why no "Select a delivery…" helper renders) +
  //                  operator-empty-truly visible.
  //   - NO-MATCH   → filters toolbar PRESENT (Clear-filters escape kept) + orientation
  //                  strip ABSENT (count 0; the strip is genuine-no-data only).
  // T-120-04 security boundary: the no-data `operator-filters` count 0 assertion arms
  // the regression gate — any future change re-introducing the toolbar (scope-widening
  // vector) in genuine no-data fails this browser gate.
  test("deliveries orientation strip is empty-pane-only; filters toolbar withheld on no-data, kept on no-match", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // --- POPULATED Deliveries view (browser-tenant has seed rows) ---
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    // Strip absent on populated; toolbar present.
    await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);
    await expect(page.getByTestId("operator-filters")).toBeVisible();
    // The Status column reflects the message's real lifecycle state: a delivered
    // message (status :sent + last_event :delivered in the seed) now badges "Delivered",
    // not a perpetual "Sent".
    await expect(page.getByTestId("operator-deliveries-list-card")).toContainText("Delivered");

    // --- GENUINE NO-DATA Deliveries view ---
    // Log in to a tenant with zero seeded deliveries (only browser-tenant is seeded by
    // browser-reset). A fresh tenant id yields @deliveries == [] with no active filters
    // and no filter errors → the genuine-no-data single-calm-pane branch.
    const emptyTenant = "browser-empty-tenant";
    const emptyReturnTo = encodeURIComponent(`/ops/mail?tenant_id=${emptyTenant}&view=deliveries`);
    await page.goto(`/ops/browser-login?tenant_id=${emptyTenant}&return_to=${emptyReturnTo}`);

    // Single calm pane: empty-truly + orientation strip only.
    // `operator-empty-truly` is a presence-marker div (style="display:none" in
    // deliveries_list.ex), so assert its presence by count — matching the Plan 01
    // ExUnit `assert html =~ "operator-empty-truly"` contract — not CSS visibility.
    await expect(page.getByTestId("operator-empty-truly")).toHaveCount(1);
    await expect(page.getByTestId("deliveries-orientation")).toHaveCount(1);
    // Toolbar WITHHELD (D-02/D-04 — the only scope-widening vector is absent).
    await expect(page.getByTestId("operator-filters")).toHaveCount(0);
    // Master-detail grid WITHHELD (D-03 single-calm-pane; no "Select a delivery…" helper).
    await expect(page.getByTestId("operator-master-detail")).toHaveCount(0);

    // --- NO-MATCH Deliveries view ---
    // Active filter that matches zero browser-tenant rows: event=queued is a valid
    // lifecycle status with no seeded delivery whose latest event is :queued →
    // @deliveries == [] AND filters_active?/1 true → no-match (toolbar kept, strip absent).
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&event=queued`);
    await expect(page.getByTestId("operator-filters")).toBeVisible();
    await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);
  });

  // D-16 (Phase 121): Inbound empty-pane-only judgment gate.
  // Modeled VERBATIM on the Deliveries empty-pane-only gate above, this locks the
  // single-calm-pane contract for the Inbound surface into the operator browser
  // ratchet (armed into the permanent floor in Phase 123):
  //   - POPULATED  → orientation strip ABSENT (count 0) + filters toolbar PRESENT.
  //   - NO-DATA    → orientation strip PRESENT (count 1) + filters toolbar WITHHELD
  //                  (count 0, locks D-02/D-05: the toolbar is the only scope-widening
  //                  vector, so its absence is the security boundary) + master-detail
  //                  grid WITHHELD (count 0, the single-calm-pane contract) +
  //                  inbound-empty-truly present (count 1).
  //   - NO-MATCH   → filters toolbar PRESENT (Clear-filters escape kept) + orientation
  //                  strip ABSENT (count 0; the strip is genuine-no-data only).
  // T-121-10 security boundary: the no-data `inbound-filters` count 0 assertion arms
  // the regression gate — any future change re-introducing the tenant-scope-widening
  // toolbar in genuine no-data fails this browser gate.
  // Markers are style="display:none" divs (records_list.ex:100) — assert by COUNT,
  // never pixel/CSS visibility.
  test("inbound orientation strip is empty-pane-only; filters toolbar withheld on no-data, kept on no-match", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // --- POPULATED Inbound view (browser-tenant has seed rows) ---
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
    // Strip absent on populated; toolbar present.
    await expect(page.getByTestId("inbound-orientation")).toHaveCount(0);
    await expect(page.getByTestId("inbound-filters")).toBeVisible();

    // --- GENUINE NO-DATA Inbound view ---
    // Log in to a tenant with zero seeded InboundMessages (only browser-tenant is
    // seeded by browser-reset). A fresh tenant id yields @records == [] with no active
    // filters and no filter errors → the genuine-no-data single-calm-pane branch.
    const emptyTenant = "browser-empty-tenant";
    const emptyReturnTo = encodeURIComponent(`/ops/mail/inbound?tenant_id=${emptyTenant}`);
    await page.goto(`/ops/browser-login?tenant_id=${emptyTenant}&return_to=${emptyReturnTo}`);

    // Single calm pane: inbound-empty-truly + orientation strip only.
    await expect(page.getByTestId("inbound-empty-truly")).toHaveCount(1);
    await expect(page.getByTestId("inbound-orientation")).toHaveCount(1);
    // Toolbar WITHHELD (D-02/D-05 — the only scope-widening vector is absent).
    await expect(page.getByTestId("inbound-filters")).toHaveCount(0);
    // Master-detail grid WITHHELD (single-calm-pane; no "Select an InboundMessage…" helper).
    await expect(page.getByTestId("inbound-master-detail")).toHaveCount(0);

    // --- NO-MATCH Inbound view ---
    // Active filter that matches zero browser-tenant rows: provider=no-such-provider
    // → @records == [] AND filters_active?/1 true → no-match (toolbar kept, strip absent).
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&provider=no-such-provider`);
    await expect(page.getByTestId("inbound-filters")).toBeVisible();
    await expect(page.getByTestId("inbound-orientation")).toHaveCount(0);
  });

  // VERIF-02 (split for D-15/D-16, Phase 121): the inbound orientation strip is now
  // empty-pane-only (asserted by the judgment gate above), so this paired test keeps
  // ONLY the preview-orientation assertion — the previous populated-inbound assertion
  // (inbound-orientation toBeVisible on /ops/mail/inbound?tenant_id=…) is removed
  // because the strip no longer renders below a populated table (D-04).
  test("preview surface renders its orientation strip", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page);

    // Preview surface orientation strip (renders when @mailables == []).
    // Navigate via /ops/browser-preview-empty which sets mailables=[] in the session
    // before redirecting to /dev/mail/ — the test router is configured with explicit
    // mailables so a direct goto would show the landing card instead of the strip.
    await page.goto("/ops/browser-preview-empty");
    await expect(page.getByTestId("preview-orientation")).toBeVisible();
  });

  // Timestamps render server-side as UTC, then the local-time script rewrites the
  // visible text to the viewer's timezone (keeping UTC in the title) and copies UTC
  // on click. Node/Chromium here runs in UTC, so the localized text still reads UTC-
  // equivalent — assert the mechanism (machine-readable <time>, title, clipboard),
  // not a specific offset.
  test("Deliveries timestamps are <time> elements localized client-side and copy UTC on click", async ({
    page,
    context
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await openOperator(page);

    const ts = page.locator("time[data-local-time]").first();
    await expect(ts).toBeVisible();

    // Machine-readable ISO8601 (Z) drives the client conversion; UTC stays in the tooltip.
    await expect(ts).toHaveAttribute("datetime", /Z$/);
    await expect(ts).toHaveAttribute("title", /UTC$/);
    await expect(ts).toHaveAttribute("data-utc", /UTC$/);

    // The script marks nodes it has localized.
    await expect(ts).toHaveAttribute("data-localized", "1");

    // js-enabled marker is set (scopes the skeleton), and the skeleton CSS is delivered:
    // an unlocalized <time data-local-time> paints a muted bar with transparent text.
    const skeleton = await page.evaluate(() => {
      const hasJs = document.documentElement.classList.contains("mg-js");
      const t = document.createElement("time");
      t.setAttribute("data-local-time", "true");
      document.body.appendChild(t);
      const cs = getComputedStyle(t);
      const out = { hasJs, color: cs.color, background: cs.backgroundColor };
      t.remove();
      return out;
    });
    expect(skeleton.hasJs).toBe(true);
    expect(skeleton.color).toBe("rgba(0, 0, 0, 0)"); // transparent text
    expect(skeleton.background).not.toBe("rgba(0, 0, 0, 0)"); // muted bar present

    // Clicking copies the canonical UTC string to the clipboard...
    const utc = await ts.getAttribute("data-utc");
    await ts.click();
    const clip = await page.evaluate(() => navigator.clipboard.readText());
    expect(clip).toBe(utc);
    expect(clip).toContain("UTC");

    // ...and does NOT navigate: the click must not bubble to the row's select_delivery
    // phx-click (the bug this guards).
    await expect(page).not.toHaveURL(/delivery_id=/);
  });
});
