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
});
