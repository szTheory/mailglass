const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;
const beforeDir = path.resolve(process.cwd(), "../.planning/phases/169-outbound-investigation-and-recovery/artifacts/before");
const afterDir = path.resolve(process.cwd(), "../.planning/phases/169-outbound-investigation-and-recovery/artifacts/after");

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

  test("Phase 169 current suppression stays distinct from history, totals, and an unavailable refresh", async ({ page }) => {
    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-suppression&variant=one");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    const detailPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${fixture.delivery_id}&full=1`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(detailPath)}`);

    const current = page.getByTestId("operator-suppression-card");
    await expect(current).toContainText("Current Mailglass match");
    await expect(current).toContainText(fixture.recipient);
    await expect(current).toContainText("Address · Account-local");
    await expect(current).toContainText("Policy");
    await expect(current).toContainText("operator review · Ångström");
    await expect(current).toContainText("Expires at");
    await expect(page.getByTestId("operator-timeline")).toContainText("Suppressed");
    await expect(page.getByTestId("operator-support-cards")).toContainText("Active suppressions: 1");
    await page.goto(`/ops/mail?tenant_id=${tenantId}`);
    await expect(page.getByRole("link", { name: "View historical suppressed Delivery Events in Deliveries" })).toBeVisible();
    await page.goto(detailPath);

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const armed = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch("/ops/browser-mutate?action=arm-known-read-failure&operation=delivery_suppression", {
        method: "POST",
        headers: { "x-csrf-token": csrfToken },
        body: undefined,
        redirect: "manual"
      });
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(armed.status, armed.body).toBe(200);

    await page.getByTestId("operator-suppression-refresh").click();
    await expect(page.getByTestId("operator-suppression-unavailable")).toBeVisible();
    await expect(current).toContainText("last retrieved record and may be out of date");
    await expect(current).toContainText("The public Mailglass removal command permits Policy records.");
    await expect(page.getByTestId("operator-timeline")).toContainText(fixture.historical_event_id);
    await expect(page.locator("body")).not.toContainText("never render");

    for (const variant of ["empty", "many"]) {
      const next = await page.request.get(`/ops/browser-reset?scenario=phase169-suppression&variant=${variant}`);
      expect(next.ok()).toBeTruthy();
      const nextFixture = await next.json();
      const path = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${nextFixture.delivery_id}&full=1`;
      await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(path)}`);
      const card = page.getByTestId("operator-suppression-card");

      if (variant === "empty") {
        await expect(card).toContainText("No current matching suppression recorded in Mailglass was found");
        await expect(card).toContainText("does not establish absence of configured-store or provider restrictions");
      } else {
        await expect(card).toContainText("Address + stream · Account-local");
        await expect(card).toContainText("Complaint");
        await expect(card).toContainText("The public Mailglass removal command blocks Complaint records.");
        await expect(card).toContainText(nextFixture.recipient);
      }
    }
    await page.screenshot({ path: "test-results/phase169-current-suppression.png", fullPage: true });
  });

  test("Phase 169 rendered before evidence remains immutable", async () => {
    const expected = {
      "deliveries-1440.png": "3f496a8c88fd8b3dd9a3f538debf6b07f6d4b516e23d7424240cfccca9c2091b",
      "deliveries-390.png": "8dcf2f4d2e1bc88143458964bbd4cf421385149fc4e4d35e28f89d5cadfe1f64",
      "detail-1440.png": "21157c8b37fb9b4ff1d16850124f00127f7cd3313a567effc2bc3ecc3866ed58",
      "detail-390.png": "1d939c4010fe61668a9a294864347eefaeffe32b90dff05fb8ecf08da33ff846",
      "health-1440.png": "8d20abe41ebea2354ba44d46750c0e19efa29ebe2f3722898458bd408f92b33e",
      "health-390.png": "d0e76d2baf7baa28499781b7a91636149fdf657e5375d70fdd2f6a49567560ba",
      "quick-view-1440.png": "fb2ae4bf11e6192281b9d3e2ae8a15658d4d9f887c18da20f98de77149918250",
      "quick-view-390.png": "3e5e35b70b5eace02bb2f8c586290c4bb9ef6d0f80698d05052e29be8f403dc6",
      "replay-review-1440.png": "581e4e9dcaf36d93c2e2d85e6ed049ea7d5d5a539f8798ccea90373aa7f433a8",
      "replay-review-390.png": "fee62c72368b1f239d0dadb8d9af376d0150b714a27932cbf78c2d963ff6e2a9"
    };

    for (const [file, digest] of Object.entries(expected)) {
      expect(fs.existsSync(path.join(beforeDir, file)), `before capture ${file} exists`).toBeTruthy();
      expect(sha256(fs.readFileSync(path.join(beforeDir, file))), `before capture ${file} is unchanged`).toBe(digest);
    }
  });

  test("Phase 169 rendered route matrix stays readable across widths and missing media", async ({ page }) => {
    fs.mkdirSync(afterDir, { recursive: true });
    const cssResponses = [];
    const externalRequests = [];
    page.on("request", request => {
      if (new URL(request.url()).origin !== baseURL) externalRequests.push(request.url());
    });
    page.on("response", async response => {
      if (/\/css-[0-9a-f]+(?:\.css)?(?:\?|$)/i.test(response.url())) {
        cssResponses.push({ url: response.url(), body: await response.body() });
      }
    });

    // The wordmark is inline; a missing optional logo route must not remove it.
    await page.route("**/logo.svg?phase169-missing", route => route.abort());
    const routes = [];
    const geometryByWidth = [];
    const widths = [320, 390, 768, 1440];

    for (const width of widths) {
      await page.setViewportSize({ width, height: 1000 });
      const reset = await page.request.get("/ops/browser-reset");
      expect(reset.ok()).toBeTruthy();
      await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`)}`);
      await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
      await expect(page.getByRole("img", { name: "mailglass" })).toBeVisible();
      await expect(page.getByTestId("operator-overview-health")).toBeVisible();
      await page.evaluate(() => {
        const probe = document.createElement("img");
        probe.alt = "";
        probe.src = "/ops/mail/logo.svg?phase169-missing";
        document.body.append(probe);
      });
      await expect.poll(() => page.locator('img[src*="phase169-missing"]').evaluate(image => image.complete && image.naturalWidth === 0)).toBeTruthy();
      await expect(page.getByRole("img", { name: "mailglass" })).toBeVisible();
      await expect(page.getByTestId("operator-overview-health")).toBeVisible();
      const healthGeometry = await page.evaluate(() => ({
        viewport: window.innerWidth,
        overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
        bodyFont: Number.parseFloat(getComputedStyle(document.querySelector(".text-body")).fontSize),
        labels: [...document.querySelectorAll(".text-label")].map(el => Number.parseFloat(getComputedStyle(el).fontSize)),
        decorativeIcons: document.querySelectorAll('span[aria-hidden="true"][class*="hero-"]').length
      }));
      expect(healthGeometry.viewport).toBe(width);
      expect(healthGeometry.overflow, `Health page overflow at ${width}px`).toBeLessThanOrEqual(1);
      expect(healthGeometry.bodyFont).toBe(16);
      expect(healthGeometry.labels.length).toBeGreaterThan(0);
      expect(Math.min(...healthGeometry.labels)).toBe(14);
      expect(healthGeometry.decorativeIcons).toBeGreaterThan(0);
      geometryByWidth.push({ width, ...healthGeometry });
      await page.locator('img[src*="phase169-missing"]').evaluate(image => image.remove());
      await page.screenshot({ path: path.join(afterDir, `health-${width}.png`), fullPage: true });
      routes.push({ width, state: "Health", url: new URL(page.url()).pathname + new URL(page.url()).search });

      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
      await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
      const contentWidth = await page.locator("main").first().evaluate(el => el.getBoundingClientRect().width);
      if (contentWidth >= 768) {
        await expect(page.getByTestId("operator-deliveries-table")).toBeVisible();
        await expect(page.getByTestId("operator-deliveries-cards")).toBeHidden();
      } else {
        await expect(page.getByTestId("operator-deliveries-cards")).toBeVisible();
        await expect(page.getByTestId("operator-deliveries-table")).toBeHidden();
      }
      const listGeometry = await page.evaluate(() => ({
        overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
        mainWidth: document.querySelector("main")?.getBoundingClientRect().width,
        focusTargets: [...document.querySelectorAll('[data-testid="operator-deliveries-list-card"] button')]
          .filter(el => el.getClientRects().length > 0)
          .map(el => el.getBoundingClientRect().height)
      }));
      expect(listGeometry.overflow, `Deliveries page overflow at ${width}px`).toBeLessThanOrEqual(1);
      expect(listGeometry.mainWidth).toBe(contentWidth);
      expect(listGeometry.focusTargets.length).toBeGreaterThan(0);
      expect(Math.min(...listGeometry.focusTargets), `Open action target at ${width}px`).toBeGreaterThanOrEqual(44);
      await page.screenshot({ path: path.join(afterDir, `deliveries-${width}.png`), fullPage: true });
      routes.push({ width, contentWidth, state: "Deliveries", url: new URL(page.url()).pathname + new URL(page.url()).search });

      await page.getByRole("button", { name: "Open delivery" }).nth(3).click();
      const quickView = page.getByTestId("operator-quick-view");
      await expect(quickView).toBeVisible();
      await expect(quickView).toHaveAttribute("aria-modal", "true");
      await expect(quickView).toContainText("Latest recorded event:");
      await expect(quickView).toContainText("Delivery ID");
      await expect(page.locator("body")).not.toContainText("browser-exact@example.com");
      // Overlays are fixed to the viewport; fullPage screenshots resize the capture
      // surface and place the sheet at the artificial bottom of a very tall image.
      await page.screenshot({ path: path.join(afterDir, `quick-view-${width}.png`), animations: "disabled" });
      routes.push({ width, state: "Quick view", url: new URL(page.url()).pathname + new URL(page.url()).search });

      await page.getByTestId("operator-quick-view-full").click();
      await expect(page.getByTestId("operator-detail-header")).toBeVisible();
      await expect(page.getByTestId("operator-detail-header")).toContainText("browser-exact@example.com");
      await expect(page.getByTestId("operator-timeline")).toBeVisible();
      await page.screenshot({ path: path.join(afterDir, `detail-${width}.png`), fullPage: true });
      routes.push({ width, state: "Full detail", url: new URL(page.url()).pathname + new URL(page.url()).search });

      await page.getByTestId("operator-replay-open").click();
      const review = page.getByTestId("operator-replay-modal");
      await expect(review).toBeVisible();
      await expect(review).toHaveAttribute("aria-modal", "true");
      await expect(review).toContainText("does not resend outbound mail or prove provider receipt");
      expect(await review.evaluate(el => el.contains(document.activeElement)), `Replay focus remains inside at ${width}px`).toBeTruthy();
      await page.screenshot({ path: path.join(afterDir, `replay-review-${width}.png`), animations: "disabled" });
      routes.push({ width, state: "Replay review", url: new URL(page.url()).pathname + new URL(page.url()).search });
      await page.keyboard.press("Escape");
      await expect(review).toHaveCount(0);
    }

    expect(externalRequests, "all browser requests remain local").toEqual([]);
    expect(cssResponses.length, "served versioned stylesheet response").toBeGreaterThan(0);
    const served = cssResponses[0];
    const builtAsset = fs.readFileSync(path.resolve(process.cwd(), "priv/static/app.css"));
    const sourceAsset = fs.readFileSync(path.resolve(process.cwd(), "assets/css/app.css"));
    expect(served.body, "served CSS bytes match the built asset").toEqual(builtAsset);
    console.log(`PHASE169_RENDERED ${JSON.stringify({
      revision: require("node:child_process").execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim(),
      fixture: "seed_browser_scenario!/0 (browser-tenant)",
      theme: "System",
      zoom: "100% Playwright viewport; actual 200% Chrome separately inspected",
      sourceCssSha256: sha256(sourceAsset),
      builtCssSha256: sha256(builtAsset),
      servedCssSha256: sha256(served.body),
      servedCssUrl: served.url,
      routes,
      screenshots: widths.flatMap(width => ["health", "deliveries", "quick-view", "detail", "replay-review"].map(state => `artifacts/after/${state}-${width}.png`)),
      geometryByWidth
    })}`);
  });

  test("Phase 169 connected Health, exact support, aged-out Delivery, replay, and return", async ({ page }) => {
    const unknownScenario = await page.request.get("/ops/browser-reset?scenario=unlisted");
    expect(unknownScenario.status()).toBe(400);

    const reset = await page.request.get("/ops/browser-reset?scenario=phase169-exact");
    expect(reset.ok()).toBeTruthy();
    const fixture = await reset.json();
    expect(fixture.delivery_id).toBeTruthy();
    expect(fixture.webhook_event_id).toBeTruthy();

    const filterPath = `/ops/mail?tenant_id=${tenantId}&provider=postmark&event=delivered&window_hours=168&page=2`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(filterPath)}`);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
    await expect(page.getByTestId("operator-overview-health-failures")).toContainText("1");
    await page.getByTestId("operator-overview-health-failures-link").click();
    await page.waitForURL(url => new URL(url).searchParams.get("support_focus") === "failed_ingest");
    const supportURL = new URL(page.url());
    expect(supportURL.searchParams.get("support_webhook_event_id")).toBe(fixture.webhook_event_id);
    expect(supportURL.searchParams.get("provider")).toBe("postmark");
    expect(supportURL.searchParams.get("event")).toBe("delivered");
    expect(supportURL.searchParams.get("window_hours")).toBe("168");
    expect(supportURL.searchParams.get("page")).toBe("2");
    const exactSupport = page.getByTestId("operator-support-exact-evidence");
    await expect(exactSupport).toContainText(fixture.webhook_event_id);
    await expect(exactSupport).toContainText("A unique linked Delivery is recorded.");
    await exactSupport.getByTestId("operator-support-linked-delivery").click();
    await page.waitForURL(url => new URL(url).searchParams.get("delivery_id") === fixture.delivery_id);
    await expect(page.getByTestId("operator-detail-header")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(fixture.delivery_id);
    await expect(page.getByTestId("operator-support-exact-evidence")).toContainText(fixture.webhook_event_id);
    const linkedDetailURL = new URL(page.url());
    expect(linkedDetailURL.searchParams.get("support_webhook_event_id")).toBe(fixture.webhook_event_id);
    expect(linkedDetailURL.searchParams.get("window_hours")).toBe("168");
    expect(fixture.listed_delivery_ids).not.toContain(fixture.delivery_id);

    await page.getByTestId("operator-detail-back").click();
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true })).not.toContainText(fixture.delivery_id);
    const quickViewPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&provider=postmark&event=delivered&window_hours=168&page=2&delivery_id=${fixture.delivery_id}&support_focus=failed_ingest&support_webhook_event_id=${fixture.webhook_event_id}`;
    await page.goto(quickViewPath);
    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    await expect(quickView).toContainText(fixture.delivery_id);
    await expect(quickView).not.toContainText("phase169-exact@example.com");
    await page.getByTestId("operator-quick-view-full").click();
    await expect(page.getByTestId("operator-detail-header")).toContainText(fixture.delivery_id);
    await page.getByTestId("operator-replay-open").click();
    const review = page.getByTestId("operator-replay-modal");
    await expect(review).toBeVisible();
    await expect(review.getByTestId("operator-replay-target-id")).toHaveText(fixture.webhook_event_id);
    await page.getByTestId("operator-replay-confirm").click();
    await expect(page.getByTestId("operator-replay-command-feedback")).toBeVisible();
    await expect(page.getByTestId("operator-detail-header")).toContainText(
      "Last retrieved replay evidence:"
    );

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
    expect(returned.searchParams.has("support_focus")).toBe(false);
    expect(returned.searchParams.has("support_webhook_event_id")).toBe(false);
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
