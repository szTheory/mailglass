const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";

async function loginOperator(page, query = `tenant_id=${tenantId}`) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await page.goto(`/ops/mail?${query}`);
  await expect(page.getByTestId("operator-shell")).toBeVisible();
}

async function surfaceBackground(page, testId) {
  return page.getByTestId(testId).evaluate(element => getComputedStyle(element).backgroundColor);
}

test.describe("Plan 168-03 rendered acceptance", () => {
  test("System follows emulated OS changes while remaining selected across navigation and reload", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.emulateMedia({ colorScheme: "light" });
    await loginOperator(page);

    const operatorShell = page.getByTestId("operator-shell");
    const systemChoice = page.getByRole("radio", { name: "System", exact: true });
    await expect(systemChoice).toBeChecked();
    await expect(operatorShell).not.toHaveAttribute("data-theme", /mailglass-/);
    const lightBackground = await surfaceBackground(page, "operator-shell");

    await page.emulateMedia({ colorScheme: "dark" });
    await expect.poll(() => surfaceBackground(page, "operator-shell")).not.toBe(lightBackground);
    const darkBackground = await surfaceBackground(page, "operator-shell");
    await expect(systemChoice).toBeChecked();
    await expect(operatorShell).not.toHaveAttribute("data-theme", /mailglass-/);

    await page.getByRole("radio", { name: "Dark", exact: true }).click();
    await expect(operatorShell).toHaveAttribute("data-theme", "mailglass-dark");
    const explicitDarkBackground = await surfaceBackground(page, "operator-shell");
    await page.emulateMedia({ colorScheme: "light" });
    await expect.poll(() => surfaceBackground(page, "operator-shell")).toBe(explicitDarkBackground);

    await page.getByRole("radio", { name: "Light", exact: true }).click();
    await expect(operatorShell).toHaveAttribute("data-theme", "mailglass-light");
    const explicitLightBackground = await surfaceBackground(page, "operator-shell");
    await page.emulateMedia({ colorScheme: "dark" });
    await expect.poll(() => surfaceBackground(page, "operator-shell")).toBe(explicitLightBackground);
    console.log(
      `[plan168-03] palette system-light=${lightBackground} system-dark=${darkBackground} explicit-dark=${explicitDarkBackground} explicit-light=${explicitLightBackground}`
    );

    await page.getByRole("radio", { name: "System", exact: true }).click();
    await expect(operatorShell).not.toHaveAttribute("data-theme", /mailglass-/);
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
    await expect.poll(() => surfaceBackground(page, "operator-shell")).toBe(darkBackground);

    await page.getByTestId("surface-nav-sidebar").getByRole("link", { name: "Preview", exact: true }).click();
    const previewShell = page.getByTestId("preview-shell");
    await expect(previewShell).toBeVisible();
    await expect(previewShell).not.toHaveAttribute("data-theme", /mailglass-/);
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
    await page.reload();
    await expect(page.getByTestId("preview-shell")).toBeVisible();
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
    await expect.poll(() => surfaceBackground(page, "preview-shell")).toBe(darkBackground);
  });

  test("gallery feedback, missing time, long-copy, fonts, icons, and reduced motion remain understandable", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await page.emulateMedia({ reducedMotion: "reduce" });
    const failedFontRequests = [];
    page.on("requestfailed", request => {
      if (/\.woff2?(?:\?|$)/.test(request.url())) failedFontRequests.push(request.url());
    });
    await page.route("**/*.woff2", route => route.abort());
    await page.route("**/*.woff", route => route.abort());
    await page.goto("/dev/mail/gallery");
    await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();

    const errorCell = page.getByTestId("gallery-flash-long-error-copy-system");
    const error = errorCell.getByRole("alert");
    await expect(error).toContainText("Delivery status could not be refreshed");
    await expect(error).toHaveAttribute("aria-live", "assertive");
    const longMessage = error.locator("span.flex-1");
    await expect(longMessage).toContainText("unbroken-recovery-evidence-");
    const longCopyGeometry = await longMessage.evaluate(element => ({
      clientWidth: element.clientWidth,
      scrollWidth: element.scrollWidth,
      rect: element.getBoundingClientRect().toJSON()
    }));
    expect(longCopyGeometry.clientWidth).toBeGreaterThan(0);
    expect(longCopyGeometry.scrollWidth).toBeLessThanOrEqual(longCopyGeometry.clientWidth + 1);
    expect(longCopyGeometry.rect.right).toBeLessThanOrEqual(320);

    const dismiss = error.getByRole("button", { name: "Dismiss error message", exact: true });
    const dismissBox = await dismiss.boundingBox();
    expect(dismissBox.width).toBeGreaterThanOrEqual(44);
    expect(dismissBox.height).toBeGreaterThanOrEqual(44);
    await dismiss.focus();
    await expect(dismiss).toBeFocused();

    const unavailableCell = page.getByTestId("gallery-timestamp-unavailable-system");
    await expect(unavailableCell).toContainText("Unavailable");
    const recordedCell = page.getByTestId("gallery-timestamp-recorded-system");
    await expect(recordedCell.locator("time")).toHaveAttribute(
      "aria-label",
      "Recorded at 2026-10-07 20:06:18 UTC"
    );

    const loadingCell = page.getByTestId("gallery-stat_card-loading-system");
    await expect(loadingCell).toContainText("Loading");
    const staleCell = page.getByTestId("gallery-data_state-stale-system");
    await expect(staleCell).toContainText("This view may be out of date.");
    await expect(staleCell).toContainText("Refresh to check for updates.");
    await expect(staleCell).not.toContainText("14:32");
    const errorAnimation = await error.locator(".motion-reveal").evaluate(element =>
      getComputedStyle(element).animationDuration
    );
    expect(Number.parseFloat(errorAnimation)).toBeLessThanOrEqual(0.00001);

    // Simulate unavailable decorative icon styling and local font assets without
    // changing DOM content: operator-facing copy, labels, and dismissal stay visible.
    await page.evaluate(() => document.fonts.ready);
    expect(failedFontRequests.length).toBeGreaterThan(0);
    await page.addStyleTag({ content: "svg[aria-hidden='true'] { display: none !important; }" });
    await expect(error).toContainText("Delivery status could not be refreshed");
    await expect(dismiss).toBeVisible();
    await expect(page.getByTestId("gallery-logo-rest").getByRole("img", { name: "mailglass" }).first()).toBeVisible();
    await expect(page.getByTestId("gallery-theme_picker-system-selected-system")).toContainText("System");
    console.log(
      `[plan168-03] gallery long-copy=${longCopyGeometry.clientWidth}px scroll=${longCopyGeometry.scrollWidth}px fontRequestsBlocked=${failedFontRequests.length} reducedAnimation=${errorAnimation}`
    );
  });

  test("routine filter patches retain the feedback node and do not replay its entrance animation", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await loginOperator(page, `tenant_id=${tenantId}&view=deliveries&support_focus=failed_ingest`);
    const detail = page.getByTestId("operator-support-focus-detail");
    await expect(detail).toBeVisible();
    await expect.poll(() => detail.evaluate(element =>
      element.getAnimations().every(animation => animation.playState === "finished")
    )).toBeTruthy();

    await page.evaluate(() => {
      window.__plan168FeedbackNode = document.querySelector("#operator-support-focus-detail");
      window.__plan168FeedbackAnimationStarts = 0;
      document.addEventListener("animationstart", event => {
        if (event.target && event.target.id === "operator-support-focus-detail") {
          window.__plan168FeedbackAnimationStarts += 1;
        }
      }, true);
    });

    // The live-validation event patches filter-form state while the support
    // feedback remains unchanged and on screen.
    await page.evaluate(() => {
      window.__plan168PatchCount = 0;
      new MutationObserver(() => window.__plan168PatchCount += 1).observe(document.body, {
        childList: true,
        characterData: true,
        attributes: true,
        subtree: true
      });
    });
    await page.locator('select[name="filters[provider]"]').selectOption("postmark");
    await expect(page.getByTestId("operator-support-focus-detail")).toBeVisible();
    await expect.poll(() => page.evaluate(() => window.__plan168PatchCount)).toBeGreaterThan(0);
    const stableNode = await page.evaluate(() =>
      document.querySelector("#operator-support-focus-detail") === window.__plan168FeedbackNode
    );
    expect(stableNode).toBeTruthy();
    const animationStarts = await page.evaluate(() => window.__plan168FeedbackAnimationStarts);
    expect(animationStarts).toBe(0);
    await expect(page.getByTestId("operator-flash-error")).toHaveCount(0);
    console.log(`[plan168-03] filter-patch stableFeedbackNode=${stableNode} animationStarts=${animationStarts}`);
  });

  test("a repeated LiveView refresh leaves identical success feedback and detail animation unchanged", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await loginOperator(page, `tenant_id=${tenantId}&view=deliveries`);
    const noopRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(1);
    await noopRow.click();
    await expect(page.getByTestId("operator-quick-view")).toBeVisible();
    await page.getByTestId("operator-quick-view-full").click();
    await expect(page).toHaveURL(/full=1/);
    await page.getByTestId("operator-replay-open").click();
    await page.getByTestId("operator-replay-confirm").click();

    const status = page.locator("#operator-flash-info");
    await expect(status).toContainText("Replay command completed with no newly normalized Events.");
    await expect(status).toHaveAttribute("role", "status");
    await expect(status).toHaveAttribute("aria-live", "polite");
    await page.evaluate(() => {
      window.__plan168StatusNode = document.querySelector("#operator-flash-info");
      window.__plan168StatusText = window.__plan168StatusNode.innerText;
      window.__plan168StatusMutations = 0;
      new MutationObserver(() => window.__plan168StatusMutations += 1).observe(
        window.__plan168StatusNode,
        { childList: true, characterData: true, subtree: true }
      );
      const id = new URL(location.href).searchParams.get("delivery_id");
      window.__plan168DetailNode = document.querySelector(`#delivery-detail-${id}`);
      window.__plan168AnimationStarts = 0;
      document.addEventListener("animationstart", event => {
        if (event.target === window.__plan168DetailNode) window.__plan168AnimationStarts += 1;
      }, true);
    });

    await page.getByTestId("operator-replay-open").click();
    await page.getByTestId("operator-replay-confirm").click();
    await expect(status).toContainText("Replay command completed with no newly normalized Events.");
    const unchangedStatus = await page.evaluate(() => ({
      sameNode: document.querySelector("#operator-flash-info") === window.__plan168StatusNode,
      sameText: document.querySelector("#operator-flash-info").innerText === window.__plan168StatusText,
      statusMutations: window.__plan168StatusMutations,
      sameDetail: document.querySelector(`#delivery-detail-${new URL(location.href).searchParams.get("delivery_id")}`) === window.__plan168DetailNode,
      animationStarts: window.__plan168AnimationStarts
    }));
    expect(unchangedStatus).toEqual({
      sameNode: true,
      sameText: true,
      statusMutations: 0,
      sameDetail: true,
      animationStarts: 0
    });
    console.log(`[plan168-03] repeated-replay ${JSON.stringify(unchangedStatus)}`);
  });
});
