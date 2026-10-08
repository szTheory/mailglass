const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;
const beforeDir = path.resolve(process.cwd(), "../.planning/phases/169-outbound-investigation-and-recovery/artifacts/before");

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

async function openBrowserTenant(page) {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
}

test.describe("Phase 169 connected journey", () => {
  test("Health keeps unaffected Account facts visible after one read becomes unavailable", async ({ page }) => {
    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-health-partial");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    expect(fixture.failed_webhook_event_id).toBeTruthy();
    expect(fixture.unmatched_event_id).toBeTruthy();

    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`)}`);
    const failures = page.getByTestId("operator-overview-health-failures");
    const unmatched = page.getByTestId("operator-overview-health-orphans");
    await expect(failures).toContainText("1");
    await expect(unmatched).toContainText("1");

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const fault = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch("/ops/browser-mutate?action=arm-known-read-failure&operation=orphan_backlog", {
        method: "POST",
        headers: { "x-csrf-token": csrfToken },
        body: undefined,
        redirect: "manual"
      });
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(fault.status, fault.body).toBe(200);

    await page.getByRole("button", { name: "Retry observations" }).click();
    await expect(page.getByTestId("operator-health-stale-orphan_backlog")).toBeVisible();
    await expect(unmatched).toContainText("1");
    await expect(unmatched).toContainText("Last retrieved");
    await expect(failures).toContainText("1");
    await expect(page.getByTestId("operator-health-partial")).toBeVisible();
    await expect(page.getByTestId("operator-overview-health-replay")).toBeVisible();
    await expect(page.locator("body")).not.toContainText("synthetic transient operator read failure");
    await page.screenshot({ path: "test-results/phase169-health-partial.png", fullPage: true });
  });

  test("Account support keeps exact IDs with no matching Deliveries and opens only proven linkage", async ({ page }) => {
    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-support-empty");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();

    const emptyPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&event=opened&support_focus=failed_ingest&support_webhook_event_id=${fixture.older_webhook_event_id}`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(emptyPath)}`);
    await expect(page.getByTestId("data-state-empty")).toBeVisible();
    const exactWebhook = page.getByTestId("operator-support-exact-evidence");
    await expect(exactWebhook).toContainText(fixture.older_webhook_event_id);
    await expect(exactWebhook).not.toContainText(fixture.newer_webhook_event_id);

    const exactEventPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&event=opened&support_focus=orphan_backlog&support_event_id=${fixture.newer_unlinked_event_id}`;
    await page.goto(exactEventPath);
    const exactEvent = page.getByTestId("operator-support-exact-evidence");
    await expect(exactEvent).toContainText(fixture.newer_unlinked_event_id);
    await expect(exactEvent).toContainText("No Delivery linkage is recorded for this Event.");
    await expect(exactEvent).toContainText("phase169-long-safe-reference-");
    await expect(exactEvent.getByTestId("operator-support-linked-delivery")).toHaveCount(0);

    const linkedEventPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&event=opened&support_focus=orphan_backlog&support_event_id=${fixture.linked_event_id}`;
    await page.goto(linkedEventPath);
    const linkedEvent = page.getByTestId("operator-support-exact-evidence");
    await expect(linkedEvent).toContainText(`Linked Delivery: ${fixture.other_delivery_id}`);
    await linkedEvent.getByTestId("operator-support-linked-delivery").click();
    await page.waitForURL(url => new URL(url).searchParams.get("delivery_id") === fixture.other_delivery_id);
    const linkedURL = new URL(page.url());
    expect(linkedURL.searchParams.get("support_event_id")).toBe(fixture.linked_event_id);
    await expect(page.getByTestId("operator-detail-header")).toContainText(fixture.other_delivery_id);
    await expect(page.getByTestId("operator-support-exact-evidence")).toContainText(fixture.linked_event_id);
    await page.waitForTimeout(350);
    await page.screenshot({ path: "test-results/phase169-support-exact.png", fullPage: true });
  });

  test("Phase 169 timeline keeps the oldest 100 and the exact selected 101st Event", async ({ page }) => {
    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-timeline-101");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    expect(fixture.delivery_id).toBeTruthy();
    expect(fixture.selected_event_id).toBeTruthy();

    const detailPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${fixture.delivery_id}&support_focus=orphan_backlog&support_event_id=${fixture.selected_event_id}&full=1`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(detailPath)}`);
    await expect(page.getByTestId("operator-detail-header")).toBeVisible();

    const visibleEvents = page.getByTestId("operator-timeline-event");
    await expect(visibleEvents).toHaveCount(100);
    await expect(page.getByTestId("operator-timeline-overflow")).toContainText(
      "At least one additional Event is not shown in this timeline. The full history is not available in this view.",
    );
    await expect(page.getByTestId("operator-timeline-selected-event")).toContainText(fixture.selected_event_id);
    await expect(page.getByTestId("operator-timeline-selected-event")).toContainText(
      "This exact Event is outside the displayed timeline.",
    );
    await expect(page.getByTestId("operator-timeline-selected-event")).toContainText("Recorded time");

    const ordinaryWebhook = page.locator(`[data-event-id="${fixture.ordinary_linked_event_id}"]`);
    await expect(ordinaryWebhook).toContainText("Delivered");
    await expect(ordinaryWebhook).not.toContainText("Webhook replay");
    await expect(page.locator(`[data-event-id="${fixture.unknown_event_id}"]`)).toContainText("Unknown event");
    await expect(page.getByTestId("operator-timeline-selected-event")).toContainText("evt-東京-Ångström-");
    await expect(page.locator("body")).not.toContainText("never render");
    await page.screenshot({ path: "test-results/phase169-timeline-101.png", fullPage: true });
  });

  test("Phase 169 exact copy keeps values visible and reports clipboard success and failure", async ({ page, context, browser }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-timeline-101");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    const detailPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${fixture.delivery_id}&support_focus=orphan_backlog&support_event_id=${fixture.selected_event_id}&full=1`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(detailPath)}`);

    const selected = page.getByTestId("operator-timeline-selected-event");
    const eventId = selected.getByRole("button", { name: "Copy event ID" });
    await expect(selected).toContainText("evt-東京-Ångström-");
    await eventId.focus();
    await page.keyboard.press("Enter");
    await expect(eventId.locator("xpath=following-sibling::*[@data-copy-status]")).toHaveText("Copied.");
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(fixture.selected_event_id);
    await expect(selected).toContainText(fixture.selected_event_id);

    const visibleEvent = page.getByTestId("operator-timeline-event").first();
    const time = visibleEvent.locator("time[data-local-time]");
    const originalUtc = await time.innerText();
    const copyTime = visibleEvent.getByRole("button", { name: "Copy recorded time" });
    await copyTime.click();
    await expect(copyTime.locator("xpath=following-sibling::*[@data-copy-status]")).toHaveText("Copied.");
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(originalUtc);
    await expect(time).toHaveText(originalUtc);

    await page.evaluate(() => {
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: () => Promise.reject(new Error("denied")) }
      });
    });
    await eventId.click();
    await expect(eventId.locator("xpath=following-sibling::*[@data-copy-status]")).toHaveText(
      "Clipboard unavailable. Select and copy the visible value manually."
    );
    await expect(selected).toContainText(fixture.selected_event_id);

    await page.evaluate(() => {
      window.liveSocket.disconnect();
      window.liveSocket.connect();
    });
    await expect(eventId).toBeVisible();
    await eventId.click();
    await expect(eventId.locator("xpath=following-sibling::*[@data-copy-status]")).toHaveText(
      "Clipboard unavailable. Select and copy the visible value manually."
    );
    await expect(selected).toContainText(fixture.selected_event_id);

    const touchContext = await browser.newContext({ hasTouch: true, permissions: ["clipboard-read", "clipboard-write"] });
    try {
      const touchPage = await touchContext.newPage();
      await touchPage.setViewportSize({ width: 390, height: 844 });
      await touchPage.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(detailPath)}`);
      const touchCopy = touchPage.getByTestId("operator-timeline-event").first()
        .getByRole("button", { name: "Copy recorded time" });
      await touchCopy.tap();
      await expect(touchCopy.locator("xpath=following-sibling::*[@data-copy-status]")).toHaveText("Copied.");
    } finally {
      await touchContext.close();
    }
    await page.screenshot({ path: "test-results/phase169-copy-status.png", fullPage: true });
  });

  for (const width of [390, 1440]) {
    test(`Phase 169 pre-edit baseline at ${width}px`, async ({ page }) => {
    fs.mkdirSync(beforeDir, { recursive: true });
    const cssResponses = [];
    page.on("response", async response => {
      if (/\/css-[0-9a-f]+(?:\.css)?(?:\?|$)/i.test(response.url())) {
        cssResponses.push({ url: response.url(), body: await response.body() });
      }
    });

    await page.setViewportSize({ width, height: 1000 });
    await openBrowserTenant(page);
    await expect(page.getByTestId("operator-overview")).toBeVisible();
    await page.screenshot({ path: path.join(beforeDir, `health-${width}.png`) });
    const routes = [new URL(page.url()).pathname + new URL(page.url()).search];

    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await page.screenshot({ path: path.join(beforeDir, `deliveries-${width}.png`) });
    routes.push(new URL(page.url()).pathname + new URL(page.url()).search);

    const exactRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3);
    if (width >= 768) {
      await exactRow.locator("td").first().click();
    } else {
      await exactRow.click();
    }
    await expect(page.getByTestId("operator-quick-view")).toBeVisible();
    await page.screenshot({ path: path.join(beforeDir, `quick-view-${width}.png`) });
    const selectedDeliveryId = new URL(page.url()).searchParams.get("delivery_id");
    routes.push(new URL(page.url()).pathname + new URL(page.url()).search);

    await page.getByTestId("operator-quick-view-full").click();
    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await page.screenshot({ path: path.join(beforeDir, `detail-${width}.png`) });
    routes.push(new URL(page.url()).pathname + new URL(page.url()).search);

    await page.getByTestId("operator-replay-open").click();
    const review = page.getByTestId("operator-replay-modal");
    await expect(review).toBeVisible();
    await page.screenshot({ path: path.join(beforeDir, `replay-review-${width}.png`) });
    await review.locator("#operator-replay-close").click();

    expect(cssResponses.length, "served versioned stylesheet response").toBeGreaterThan(0);
    const served = cssResponses[0];
    const builtAsset = fs.readFileSync(path.resolve(process.cwd(), "priv/static/app.css"));
    const sourceAsset = fs.readFileSync(path.resolve(process.cwd(), "assets/css/app.css"));
    expect(served.body, "served CSS bytes match the checked-in built asset").toEqual(builtAsset);
    const evidence = {
      servedCssUrl: served.url,
      servedCssSha256: sha256(served.body),
      builtCssSha256: sha256(builtAsset),
      sourceCssSha256: sha256(sourceAsset),
      userAgent: await page.evaluate(() => navigator.userAgent),
      platform: await page.evaluate(() => navigator.platform),
      browserPlatform: process.platform,
      viewportCssPixels: width,
      zoom: 1,
      deviceScaleFactor: await page.evaluate(() => window.devicePixelRatio),
      theme: "System",
      fixture: "seed_browser_scenario!/0 (browser-tenant)",
      routes,
      selectedDeliveryId,
      interactionStates: ["Health", "Deliveries", "Quick view", "full detail", "replay review"],
      screenshotPaths: [
        `artifacts/before/health-${width}.png`,
        `artifacts/before/deliveries-${width}.png`,
        `artifacts/before/quick-view-${width}.png`,
        `artifacts/before/detail-${width}.png`,
        `artifacts/before/replay-review-${width}.png`
      ]
    };
    console.log(`PHASE169_BASELINE ${JSON.stringify(evidence)}`);
    });
  }

  test("Phase 169 baseline and exact replay tracer", async ({ page }) => {
    const unknownScenario = await page.request.get("/ops/browser-reset?scenario=unlisted");
    expect(unknownScenario.status()).toBe(400);

    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-exact");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    expect(fixture.delivery_id).toBeTruthy();
    expect(fixture.webhook_event_id).toBeTruthy();

    const listPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&provider=postmark&event=delivered&window_hours=168&page=2`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(listPath)}`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const detailPath = `${listPath}&delivery_id=${fixture.delivery_id}&full=1`;
    await page.goto(detailPath);
    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(fixture.delivery_id);
    await page.getByTestId("operator-replay-open").click();
    const review = page.getByTestId("operator-replay-modal");
    await expect(review).toBeVisible();
    await expect(review.getByTestId("operator-replay-target-id")).toHaveText(fixture.webhook_event_id);
    await page.getByTestId("operator-replay-confirm").click();
    await expect(page.getByText(/Replay completed with/)).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText("Last replay:");

    const authResponse = await page.request.get("/ops/browser-auth-log");
    expect(authResponse.ok()).toBeTruthy();
    const authLog = await authResponse.json();
    expect(authLog.destructive_actions).toHaveLength(1);
    expect(authLog.destructive_actions[0].delivery_id).toBe(fixture.delivery_id);
    expect(authLog.destructive_actions[0].webhook_event_id).toBe(fixture.webhook_event_id);

    await page.getByTestId("operator-detail-back").click();
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    const returned = new URL(page.url());
    expect(returned.searchParams.get("tenant_id")).toBe(tenantId);
    expect(returned.searchParams.get("view")).toBe("deliveries");
    expect(returned.searchParams.get("provider")).toBe("postmark");
    expect(returned.searchParams.get("event")).toBe("delivered");
    expect(returned.searchParams.get("window_hours")).toBe("168");
    expect(returned.searchParams.get("page")).toBe("2");
    expect(returned.searchParams.has("delivery_id")).toBe(false);
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
  });

  test("Phase 169 filter history restores committed URL state", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    await page.locator("#filters_event").selectOption("failed");
    await expect(page).not.toHaveURL(/event=failed/);
    await page.getByRole("button", { name: "Apply filters" }).click();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");

    await page.goBack();
    await page.waitForURL(url => new URL(url).searchParams.get("event") !== "failed");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);

    await page.goForward();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
    await expect(page.locator("#filters_event")).toHaveValue("failed");
  });
});
