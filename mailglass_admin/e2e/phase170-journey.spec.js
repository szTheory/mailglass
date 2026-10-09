const { test, expect, chromium } = require("@playwright/test");
const { createHash } = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

async function resetAndOpenInbound(page, route = `/ops/mail/inbound?tenant_id=${tenantId}`) {
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(route);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Inbound records", exact: true })).toBeVisible();
}

async function overflowState(page) {
  return page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    offenders: [...document.querySelectorAll("body *")]
      .filter(element => {
        const rect = element.getBoundingClientRect();
        return rect.width > 0 && (rect.left < -1 || rect.right > document.documentElement.clientWidth + 1);
      })
      .slice(0, 8)
      .map(element => {
        const style = getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return `${element.tagName.toLowerCase()}${element.id ? `#${element.id}` : ""}.${String(element.className || "").split(" ").slice(0, 2).join(".")} width=${Math.round(rect.width)} right=${Math.round(rect.right)} wrap=${style.overflowWrap} min=${style.minWidth}`;
      })
  }));
}

test.describe("Phase 170 connected", () => {
  test("Account, exact record, evidence, replay review, history refresh, and return stay connected", async ({ page }) => {
    test.setTimeout(120_000);
    await page.setViewportSize({ width: 1440, height: 1000 });
    await resetAndOpenInbound(page);

    const accepted = page.getByTestId("inbound-record-row")
      .filter({ has: page.locator('[data-testid^="inbound-outcome-accept"]') })
      .first();
    const recordOpen = accepted.getByTestId("inbound-record-open");
    const recordId = await recordOpen.getAttribute("phx-value-id");
    expect(recordId).toMatch(/^[0-9a-f-]{36}$/i);
    await recordOpen.click();
    await expect(page).toHaveURL(new RegExp(`inbound_id=${recordId}`));
    await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
    await expect(page.getByTestId("inbound-quick-view")).toContainText("browser-tenant");
    await page.getByTestId("inbound-quick-view-full").click();

    const detail = page.getByTestId("inbound-detail-header");
    await expect(detail).toContainText(recordId);
    await expect(detail).toContainText("browser-tenant");
    await expect(page.getByTestId("inbound-timeline-run").first()).toContainText("Fresh");
    await expect(page.getByTestId("inbound-evidence-redacted")).toBeVisible();
    await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
    const reveal = page.getByTestId("inbound-evidence-reveal");
    await expect(reveal).toHaveAttribute("aria-expanded", "false");
    await reveal.focus();
    await page.keyboard.press("Enter");
    await expect(reveal).toHaveAttribute("aria-expanded", "true");
    await expect(page.getByTestId("inbound-evidence-raw")).toBeVisible();
    await page.getByTestId("inbound-evidence-re-redact").click();
    await expect(reveal).toHaveAttribute("aria-expanded", "false");

    const snapshot = page.getByTestId("inbound-timeline-snapshot");
    await expect(snapshot).toContainText("History snapshot through");
    await expect(snapshot.locator("time")).toHaveAttribute("datetime", /Z$/);
    const beforeRuns = await page.getByTestId("inbound-timeline-run").count();
    await page.getByTestId("inbound-replay-open").click();
    const modal = page.getByTestId("inbound-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("browser-tenant");
    await expect(modal).toContainText(recordId);
    await expect(modal).toContainText("Recorded Mailbox:");
    await expect(modal.getByRole("button", { name: "Close replay review" })).toBeFocused();
    await modal.getByTestId("inbound-replay-confirm").click();
    const feedback = page.getByTestId("inbound-replay-feedback");
    await expect(feedback).toContainText(/Replay run recorded|Replay failed|Replay was already submitted/);
    await expect(modal).toHaveCount(0);
    await expect(page.getByTestId("inbound-timeline-snapshot")).toContainText("History snapshot through");
    await expect(page.getByTestId("inbound-timeline-run")).toHaveCount(beforeRuns);
    await page.getByRole("button", { name: "Refresh history" }).click();
    await expect(page.getByTestId("inbound-timeline-snapshot")).toContainText("History snapshot through");
    await expect(page.getByTestId("inbound-timeline-run")).toHaveCount(beforeRuns + 1);
    await expect(page.getByTestId("inbound-timeline-run").last()).toContainText("Replay");

    // The same-Account exact record remains selectable when current list filters
    // yield no results and the requested page is outside the result range.
    const returnPath = `/ops/mail/inbound?tenant_id=${tenantId}&provider=ses&outcome=accept&page=2&inbound_id=${recordId}`;
    await page.goto(returnPath);
    await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
    await expect(page.getByTestId("inbound-selection-outside-results")).toBeVisible();
    await page.getByTestId("inbound-quick-view-full").click();
    await expect(page.getByTestId("inbound-detail-header")).toContainText(recordId);
    await page.getByTestId("inbound-detail-back").click();
    await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
    await expect(page).not.toHaveURL(/full=1/);
    await page.getByTestId("inbound-detail-back").click();
    await expect(page).not.toHaveURL(/inbound_id=/);
    const returnedURL = new URL(page.url());
    expect(returnedURL.searchParams.get("tenant_id")).toBe(tenantId);
    expect(returnedURL.searchParams.get("provider")).toBe("ses");
    expect(returnedURL.searchParams.get("outcome")).toBe("accept");
    expect(returnedURL.searchParams.get("page")).toBe("2");
    expect(returnedURL.searchParams.has("inbound_id")).toBe(false);
    await expect(page.getByTestId("inbound-empty-filtered")).toHaveCount(1);

    // Current rules are explicitly labeled as simulation; recorded execution is
    // shown separately as a historical run. The native disclosure owns its state.
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    const noMatchOpen = page.getByTestId("inbound-record-row")
      .filter({ has: page.locator('[data-testid^="inbound-outcome-no_match"]') })
      .first()
      .getByTestId("inbound-record-open");
    const noMatchId = await noMatchOpen.getAttribute("phx-value-id");
    await noMatchOpen.click();
    await page.getByTestId("inbound-quick-view-full").click();
    await expect(page.getByTestId("inbound-timeline-run").first()).toContainText("Fresh");
    const simulation = page.getByTestId("inbound-routing-disclosure");
    await expect(simulation).toContainText("Current router simulation");
    await simulation.locator("summary").focus();
    await page.keyboard.press("Enter");
    await expect(simulation).toHaveAttribute("open", "");
    await expect(simulation).toContainText("does not prove which route was selected when the message arrived");
    await expect(page.locator("body")).not.toContainText("fixture execution failure");
    await page.screenshot({ path: "test-results/phase170-connected-detail.png", fullPage: true });
    expect(noMatchId).toMatch(/^[0-9a-f-]{36}$/i);
  });

  test("foreign IDs, empty, filtered-empty, and out-of-range stay distinct", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await resetAndOpenInbound(page);

    const foreignId = "11111111-1111-4111-8111-111111111111";
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&inbound_id=${foreignId}`);
    await expect(page.getByTestId("inbound-quick-view-error")).toBeVisible();
    await expect(page.getByTestId("inbound-quick-view-error")).toContainText(
      "could not be loaded in the selected Account"
    );
    await expect(page.locator("body")).not.toContainText(foreignId);

    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&provider=ses`);
    await expect(page.getByTestId("inbound-empty-filtered")).toHaveCount(1);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}&page=99`);
    await expect(page.getByTestId("inbound-empty-out-of-range")).toHaveCount(1);
    await expect(page.getByTestId("inbound-page-reset")).toBeVisible();

    const emptyTenant = "browser-empty-tenant";
    const emptyPath = `/ops/mail/inbound?tenant_id=${emptyTenant}`;
    await page.goto(`/ops/browser-login?tenant_id=${emptyTenant}&return_to=${encodeURIComponent(emptyPath)}`);
    await expect(page.getByTestId("inbound-empty-truly")).toHaveCount(1);

    const packageReset = await page.request.get("/ops/browser-reset?scenario=phase170-package-unavailable");
    expect(packageReset.ok()).toBeTruthy();
    const packagePath = `/ops/mail/inbound?tenant_id=${tenantId}`;
    await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(packagePath)}`);
    await expect(page.getByTestId("inbound-package-unavailable")).toBeVisible();
    await expect(page.locator("body")).not.toContainText("browser-scenario.example");

    await page.screenshot({ path: "test-results/phase170-out-of-range.png", fullPage: true });
  });
});

test.describe("Phase 170 rendered", () => {
  test("responsive themes, touch, focus, reduced motion, and current evidence at each viewport", async ({ page, browser }) => {
    test.setTimeout(120_000);
    await resetAndOpenInbound(page);
    const rows = page.getByTestId("inbound-record-row");
    const accepted = rows.filter({ has: page.locator('[data-testid^="inbound-outcome-accept"]') }).first();
    const recordId = await accepted.getByTestId("inbound-record-open").getAttribute("phx-value-id");
    const detailPath = `/ops/mail/inbound?tenant_id=${tenantId}&inbound_id=${recordId}&full=1`;
    const sizes = [320, 390, 768, 1440];
    const captures = [];

    for (const width of sizes) {
      await page.setViewportSize({ width, height: 900 });
      for (const theme of ["light", "dark", "system"]) {
        await page.emulateMedia({ colorScheme: theme === "light" ? "light" : "dark", reducedMotion: "reduce" });
        await page.goto(`${detailPath}&theme=${theme}`);
        await expect(page.getByTestId("inbound-detail-header")).toBeVisible();
        await expect(page.getByTestId("inbound-timeline")).toBeVisible();
        await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();
        const geometry = await overflowState(page);
        const shot = `test-results/phase170-${width}-${theme}.png`;
        await page.screenshot({ path: shot, fullPage: true });
        expect(geometry.document, `${width}px ${theme} page should not scroll horizontally: ${geometry.offenders}`).toBeLessThanOrEqual(width);
        const targetSizes = await page.locator("button, a").evaluateAll(elements => elements
          .filter(element => {
            const rect = element.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0 && getComputedStyle(element).visibility !== "hidden";
          })
          .map(element => {
            const rect = element.getBoundingClientRect();
            return { label: element.innerText.trim(), width: rect.width, height: rect.height };
          }));
        expect(targetSizes.every(({ width: w, height: h }) => w >= 44 && h >= 44), `${width}px ${theme} interactive targets must be at least 44×44`).toBeTruthy();
        captures.push({ width, theme, screenshot: shot, bytes: fs.statSync(shot).size, ...geometry });
      }
    }

    // System mode follows a live OS color-scheme change without changing the
    // operator's selected theme.
    await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
    await page.goto(`${detailPath}&theme=system`);
    const systemBackground = () => page.locator("html").evaluate(element => getComputedStyle(element).getPropertyValue("--mg-color-background").trim());
    const darkSystemBackground = await systemBackground();
    await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
    const lightSystemBackground = await systemBackground();
    expect(lightSystemBackground).not.toBe(darkSystemBackground);

    await page.goto(`${detailPath}&theme=light`);
    const reveal = page.getByTestId("inbound-evidence-reveal");
    for (let step = 0; step < 40 && !(await reveal.evaluate(element => document.activeElement === element)); step += 1) {
      await page.keyboard.press("Tab");
    }
    await expect(reveal).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(reveal).toHaveAttribute("aria-expanded", "true");
    await expect(page.locator("[data-testid=\"inbound-evidence-status\"]")).toContainText("Raw source revealed");
    await page.getByTestId("inbound-evidence-re-redact").focus();
    await page.keyboard.press("Enter");
    await expect(reveal).toBeFocused();

    const savedSession = await page.context().storageState();
    const touchContext = await browser.newContext({ storageState: savedSession, hasTouch: true, viewport: { width: 390, height: 844 }, reducedMotion: "reduce" });
    try {
      const touchPage = await touchContext.newPage();
      await touchPage.goto(`${baseURL}${detailPath}&theme=system`);
      const back = touchPage.getByTestId("inbound-detail-back");
      await expect(back).toBeVisible();
      const box = await back.boundingBox();
      expect(box.height).toBeGreaterThanOrEqual(44);
      await back.tap();
      await expect(touchPage.getByTestId("inbound-records-list")).toBeVisible();
    } finally {
      await touchContext.close();
    }

    const extensionPath = path.resolve(__dirname, "support/browser-zoom-extension");
    const zoomContext = await chromium.launchPersistentContext("", {
      channel: "chromium",
      headless: true,
      viewport: { width: 1440, height: 900 },
      storageState: savedSession,
      args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`]
    });
    try {
      const zoomPage = zoomContext.pages()[0] || await zoomContext.newPage();
      await zoomPage.goto(`${baseURL}/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(`${detailPath}&theme=dark`)}`);
      await expect(zoomPage.getByTestId("inbound-detail-header")).toBeVisible();
      const initialDpr = await zoomPage.evaluate(() => window.devicePixelRatio);
      const serviceWorker = zoomContext.serviceWorkers()[0] || await zoomContext.waitForEvent("serviceworker");
      const zoom = await serviceWorker.evaluate(async () => {
        const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
        await chrome.tabs.setZoom(tab.id, 2);
        return chrome.tabs.getZoom(tab.id);
      });
      expect(zoom).toBe(2);
      await expect.poll(() => zoomPage.evaluate(() => window.devicePixelRatio)).toBe(initialDpr * 2);
      await expect(zoomPage.getByTestId("inbound-evidence-reveal")).toBeVisible();
      const geometry = await overflowState(zoomPage);
      expect(geometry.viewport).toBe(720);
      expect(geometry.document, `actual 200% zoom should not scroll horizontally: ${geometry.offenders}`).toBeLessThanOrEqual(720);
      const zoomTargets = await zoomPage.locator("button, a").evaluateAll(elements => elements
        .filter(element => {
          const rect = element.getBoundingClientRect();
          return rect.width > 0 && rect.height > 0 && getComputedStyle(element).visibility !== "hidden";
        })
        .map(element => {
          const rect = element.getBoundingClientRect();
          return { label: element.innerText.trim(), width: rect.width, height: rect.height };
        }));
      const undersizedZoomTargets = zoomTargets.filter(({ width, height }) => width < 44 || height < 44);
      expect(undersizedZoomTargets, `200% zoom interactive targets must remain at least 44×44: ${JSON.stringify(undersizedZoomTargets)}`).toEqual([]);
      const shot = "test-results/phase170-200pct-dark.png";
      await zoomPage.screenshot({ path: shot, fullPage: true });
      captures.push({ width: "1440 device / 720 CSS at actual 200% zoom", theme: "dark", screenshot: shot, bytes: fs.statSync(shot).size, ...geometry });
    } finally {
      await zoomContext.close();
    }

    const digest = bytes => createHash("sha256").update(bytes).digest("hex");
    const cssPath = path.resolve(__dirname, "../assets/css/app.css");
    const builtCssPath = path.resolve(__dirname, "../priv/static/app.css");
    const cssLinks = await page.locator('link[rel="stylesheet"]').evaluateAll(links => links.map(link => link.href));
    const servedCss = [];
    for (const url of cssLinks) {
      const response = await page.request.get(url);
      if (response.ok()) {
        servedCss.push({ url, sha256: digest(await response.body()) });
      }
    }
    const scriptUrls = await page.locator("script[src]").evaluateAll(scripts => scripts.map(script => script.src));
    const servedJs = [];
    for (const url of scriptUrls) {
      const response = await page.request.get(url);
      if (response.ok() && new URL(url).pathname.endsWith(".js")) {
        servedJs.push({ url, sha256: digest(await response.body()) });
      }
    }
    const inlineJs = await page.locator("script:not([src])").evaluateAll(scripts => scripts.map(script => script.textContent));
    const builtCssSha256 = digest(fs.readFileSync(builtCssPath));
    expect(servedCss.some(asset => asset.sha256 === builtCssSha256), `served stylesheet must match generated Admin CSS (${JSON.stringify({ cssLinks, servedCss, builtCssSha256 })})`).toBeTruthy();
    const provenance = {
      revision: require("node:child_process").execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim(),
      sourceCssSha256: digest(fs.readFileSync(cssPath)),
      builtCssSha256,
      servedCss,
      servedJs,
      inlineJsSha256: inlineJs.filter(text => text.trim().length > 0).map(text => digest(text)),
      captures
    };
    fs.writeFileSync(path.resolve(__dirname, "../test-results/phase170-rendered-provenance.json"), `${JSON.stringify(provenance, null, 2)}\n`);
    test.info().annotations.push({
      type: "rendered-captures",
      description: JSON.stringify(provenance)
    });
  });
});
