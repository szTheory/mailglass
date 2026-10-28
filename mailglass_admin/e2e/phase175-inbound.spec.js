const { test, expect, chromium } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

async function openInbound(page) {
  await page.context().clearCookies();
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await page.goto(new URL(`/ops/mail/inbound?tenant_id=${tenantId}`, baseURL).toString());
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}

async function openInboundFullReplay(page) {
  const row = page
    .locator('[data-testid="inbound-records-table"] tbody tr, [data-testid="inbound-records-cards"] li')
    .filter({ hasNot: page.getByRole("button", { name: "Unrouted", exact: true }) })
    .filter({ visible: true })
    .first();

  await row.getByTestId("inbound-record-open").click();
  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  await page.getByTestId("inbound-quick-view-full").click();
  await expect(page.getByTestId("inbound-detail-column")).toBeVisible();

  const recordId = new URL(page.url()).searchParams.get("inbound_id");
  expect(recordId, "selected Inbound record remains in the URL").toBeTruthy();
  await page.getByTestId("inbound-replay-open").click();
  const modal = page.getByTestId("inbound-replay-modal");
  await expect(modal).toBeVisible();
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");
  return { modal, recordId };
}

async function openInboundQuickReplay(page) {
  const row = page
    .locator('[data-testid="inbound-records-table"] tbody tr, [data-testid="inbound-records-cards"] li')
    .filter({ visible: true })
    .first();
  const opener = row.getByTestId("inbound-record-open");
  if (await opener.count()) await opener.click();
  else await row.getByTestId("inbound-record-row").click();

  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  const recordId = new URL(page.url()).searchParams.get("inbound_id");
  expect(recordId, "quick-view selection remains in the URL").toBeTruthy();
  await page.getByTestId("inbound-quick-replay-open").click();
  const modal = page.getByTestId("inbound-replay-modal");
  await expect(modal).toBeVisible();
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");
  return { modal, recordId, trigger: page.getByTestId("inbound-quick-replay-open") };
}

test("Phase 175 Inbound full: confirm reports recorded Mailbox outcome and refreshes evidence", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });

  let holdNextReply = false;
  let heldReply = null;
  let resolveHeldReply;
  let liveSocket = null;

  await page.routeWebSocket(/\/live\/websocket/, socket => {
    liveSocket = socket;
    const server = socket.connectToServer();
    socket.onMessage(message => {
      if (String(message).includes("confirm_replay")) holdNextReply = true;
      server.send(message);
    });
    server.onMessage(message => {
      if (holdNextReply) {
        holdNextReply = false;
        heldReply = message;
        resolveHeldReply?.();
      } else {
        socket.send(message);
      }
    });
  });

  await openInbound(page);
  const { modal, recordId } = await openInboundFullReplay(page);
  expect(new URL(page.url()).searchParams.get("inbound_id")).toBe(recordId);
  expect(new URL(page.url()).searchParams.get("full")).toBe("1");
  await expect(modal).toContainText(tenantId);
  await expect(modal).toContainText(recordId);
  await expect(modal).toContainText("Recorded Mailbox: Elixir.MailglassAdmin.TestSupport.InboundTestMailbox");
  await expect(modal).toContainText("does not evaluate current router rules or redeliver through the provider");

  const priorRuns = await page.getByTestId("inbound-timeline-run").count();
  const pendingReply = new Promise(resolve => { resolveHeldReply = resolve; });
  await page.getByTestId("inbound-replay-confirm").click();
  await pendingReply;
  await expect.poll(() => Boolean(heldReply), { message: "the Inbound replay response is held" }).toBe(true);

  await expect(modal).toBeVisible();
  await expect(modal).toContainText(recordId);
  await expect(page.getByTestId("inbound-replay-confirm")).toBeDisabled();
  await expect(page.getByTestId("inbound-replay-confirm")).toContainText("Replaying…");
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");

  liveSocket.send(heldReply);
  heldReply = null;

  await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  const toast = page.getByTestId("copy-toast");
  await expect(toast).toBeVisible();
  await expect(toast).toContainText("Replay run recorded. Mailbox outcome: Accepted.");
  await expect(page.getByTestId("inbound-timeline-run")).toHaveCount(priorRuns + 1);
  await expect(page.getByTestId("inbound-timeline")).toContainText("Replay");
  expect(new URL(page.url()).searchParams.get("inbound_id")).toBe(recordId);
  expect(new URL(page.url()).searchParams.get("full")).toBe("1");
  await expect(toast).not.toContainText(/delivered|sent/i);
});

test("Phase 175 Inbound full: Escape closes review and returns focus to its detail trigger", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openInbound(page);
  const { modal } = await openInboundFullReplay(page);

  await expect(modal.getByRole("button", { name: "Close", exact: true })).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-open-btn");
});

test("Phase 175 Inbound quick: review preserves Account, filters, selection and keyboard context", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openInbound(page);
  await page.getByLabel("Mailbox outcome", { exact: true }).selectOption("accept");
  await page.getByLabel("Time window", { exact: true }).selectOption("24");
  await expect(page).toHaveURL(/outcome=accept/);
  await expect(page).toHaveURL(/window_hours=24/);
  const routeContext = new URL(page.url());
  expect(routeContext.searchParams.get("tenant_id")).toBe(tenantId);
  expect(routeContext.searchParams.get("outcome"), page.url()).toBe("accept");
  expect(routeContext.searchParams.get("window_hours")).toBe("24");

  const { modal, recordId, trigger } = await openInboundQuickReplay(page);
  const initialUrl = new URL(page.url());
  expect(initialUrl.searchParams.get("tenant_id")).toBe(tenantId);
  expect(initialUrl.searchParams.get("outcome"), page.url()).toBe("accept");
  expect(initialUrl.searchParams.get("window_hours")).toBe("24");
  expect(initialUrl.searchParams.get("inbound_id")).toBe(recordId);
  await expect(modal).toContainText(recordId);
  await expect(modal).toContainText("Recorded Mailbox:");

  await page.keyboard.press("ArrowDown");
  expect(new URL(page.url()).searchParams.get("inbound_id")).toBe(recordId);

  await page.locator("#inbound-replay-close").focus();
  await page.keyboard.press("Shift+Tab");
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-confirm");
  await page.keyboard.press("Tab");
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");

  await page.keyboard.press("Escape");
  await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-quick-replay-open-btn");
  expect(new URL(page.url()).searchParams.toString()).toBe(initialUrl.searchParams.toString());

  await trigger.click();
  await expect(page.getByTestId("inbound-replay-modal")).toBeVisible();
  await page.locator("#inbound-replay-cancel").click();
  await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-quick-replay-open-btn");
  expect(new URL(page.url()).searchParams.get("inbound_id")).toBe(recordId);
});

test("Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom", async ({ page }) => {
  const subject = "Browser support — résumé routing diagnostics across multiple accounts";
  const mailbox = "Elixir.MailglassAdmin.TestSupport.InboundTestMailbox";
  const widths = [320, 375, 768, 1280, 1440];
  const artifacts = path.resolve(__dirname, "../test-results/phase175-layout");
  fs.mkdirSync(artifacts, { recursive: true });

  const openUnicodeDetail = async targetPage => {
    await targetPage.setViewportSize({ width: 1280, height: 900 });
    await openInbound(targetPage);
    const row = targetPage
      .locator('[data-testid="inbound-records-table"] tbody tr, [data-testid="inbound-records-cards"] li')
      .filter({ hasText: subject })
      .filter({ visible: true })
      .first();
    await expect(row, "the retained Unicode subject belongs to a current inbound row").toBeVisible();
    await row.getByTestId("inbound-record-open").click();
    await expect(targetPage.getByTestId("inbound-quick-view")).toBeVisible();
    const recordId = new URL(targetPage.url()).searchParams.get("inbound_id");
    expect(recordId, "selected Inbound record ID remains in the route").toBeTruthy();
    await targetPage.getByTestId("inbound-quick-view-full").click();
    const detail = targetPage.getByTestId("inbound-detail-column");
    await expect(detail).toBeVisible();
    return { detail, recordId };
  };

  const { detail, recordId } = await openUnicodeDetail(page);
  const detailHeader = page.getByTestId("inbound-detail-header");
  const subjectText = detailHeader.getByText(subject, { exact: true });
  const recordIdControl = detailHeader.getByRole("button", { name: /^Copy Record ID: / });
  const mailboxIdentity = detailHeader.locator("#inbound-detail-mailbox");
  await expect(mailboxIdentity).toContainText("InboundTestMailbox");
  await expect(recordIdControl).toContainText(recordId);
  const widthCases = [];
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    await expect(subjectText).toBeVisible();
    await expect(subjectText).toHaveText(subject);
    await expect(mailboxIdentity).toBeVisible();
    const geometry = await page.evaluate(() => ({
      viewportWidth: window.innerWidth,
      documentWidth: document.documentElement.scrollWidth,
      overflow: [...document.querySelectorAll("body *")]
        .filter(element => {
          const rect = element.getBoundingClientRect();
          return rect.width > 0 && (rect.left < -1 || rect.right > window.innerWidth + 1);
        })
        .slice(0, 8)
        .map(element => `${element.tagName.toLowerCase()}#${element.id}.${String(element.className).slice(0, 48)}`)
    }));
    expect(geometry.documentWidth, `Inbound page has no horizontal overflow at ${width}px`)
      .toBeLessThanOrEqual(width);
    expect(geometry.overflow, `visible Inbound geometry fits at ${width}px`).toEqual([]);
    widthCases.push({
      width,
      recordId,
      subject,
      mailbox,
      ...geometry
    });
    if ([320, 1440].includes(width)) {
      const screenshot = path.join(artifacts, `inbound-${width}.png`);
      await page.screenshot({ path: screenshot, fullPage: true });
      expect(fs.statSync(screenshot).size, `Inbound ${width}px screenshot is retained`).toBeGreaterThan(0);
      widthCases.at(-1).screenshot = path.relative(path.resolve(__dirname, "../.."), screenshot);
    }
  }
  expect(widthCases).toHaveLength(5);

  const extensionPath = path.resolve(__dirname, "support/browser-zoom-extension");
  const zoomContext = await chromium.launchPersistentContext("", {
    channel: "chromium",
    headless: true,
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 2,
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`]
  });
  let zoomEvidence;
  try {
    const zoomPage = zoomContext.pages()[0] || await zoomContext.newPage();
    const selected = await openUnicodeDetail(zoomPage);
    const initial = await zoomPage.evaluate(() => ({
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      devicePixelRatio: window.devicePixelRatio
    }));
    const serviceWorker = zoomContext.serviceWorkers()[0] || await zoomContext.waitForEvent("serviceworker");
    const tabZoom = await serviceWorker.evaluate(async () => {
      const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
      if (!tab?.id) throw new Error("Active Chromium tab is unavailable");
      await chrome.tabs.setZoom(tab.id, 2);
      return { tabId: tab.id, factor: await chrome.tabs.getZoom(tab.id) };
    });
    expect(tabZoom.factor, "the browser applies real 200% tab zoom").toBe(2);
    await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(640);
    await zoomPage.setViewportSize({ width: 640, height: 760 });
    await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
    const effective = await zoomPage.evaluate(() => ({
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      documentWidth: document.documentElement.scrollWidth,
      devicePixelRatio: window.devicePixelRatio
    }));
    expect(effective.devicePixelRatio / initial.devicePixelRatio, "actual zoom doubles effective DPR").toBe(2);
    expect(effective.documentWidth, "Inbound page has no overflow at 320 CSS px and 200% zoom")
      .toBeLessThanOrEqual(320);
    const zoomHeader = zoomPage.getByTestId("inbound-detail-header");
    await expect(zoomHeader.getByText(subject, { exact: true })).toBeVisible();
    await expect(zoomHeader.getByRole("button", { name: /^Copy Record ID: / }))
      .toContainText(selected.recordId);
    await expect(zoomHeader.locator("#inbound-detail-mailbox")).toContainText("InboundTestMailbox");
    const trigger = zoomPage.getByTestId("inbound-replay-open");
    const originId = await trigger.getAttribute("id");
    await trigger.click();
    const modal = zoomPage.getByTestId("inbound-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText(selected.recordId);
    await expect(modal).toContainText(`Recorded Mailbox: ${mailbox}`);
    const scroll = await modal.evaluate(element => ({
      clientHeight: element.clientHeight,
      scrollHeight: element.scrollHeight,
      overflowY: getComputedStyle(element).overflowY,
      account: document.querySelector('[data-testid="operator-account-context"]')?.textContent.trim()
    }));
    expect(scroll.overflowY).toBe("auto");
    expect(scroll.scrollHeight).toBeGreaterThan(scroll.clientHeight);
    expect(scroll.account).toContain(tenantId);
    const close = modal.getByRole("button", { name: "Close", exact: true });
    const confirm = modal.getByTestId("inbound-replay-confirm");
    await expect(close).toBeVisible();
    await expect(confirm).toBeVisible();
    const targets = await Promise.all([close, confirm].map(control => control.evaluate(element => {
      const rect = element.getBoundingClientRect();
      return { width: rect.width, height: rect.height, layoutWidth: element.offsetWidth, layoutHeight: element.offsetHeight };
    })));
    for (const target of targets) {
      expect(target.layoutWidth).toBeGreaterThanOrEqual(44);
      expect(target.layoutHeight).toBeGreaterThanOrEqual(44);
      expect(target.width).toBeGreaterThanOrEqual(43.5);
      expect(target.height).toBeGreaterThanOrEqual(43.5);
    }
    await modal.evaluate(element => { element.scrollTop = element.scrollHeight; });
    await expect(confirm).toBeInViewport();
    await modal.evaluate(element => { element.scrollTop = 0; });
    await expect(close).toBeInViewport();
    await confirm.focus();
    await zoomPage.keyboard.press("Tab");
    await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");
    await zoomPage.keyboard.press("Shift+Tab");
    await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-confirm");
    await zoomPage.keyboard.press("Escape");
    await expect(modal).toHaveCount(0);
    await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe(originId);
    zoomEvidence = {
      caseId: "layout:inbound:real-200-percent-zoom",
      url: zoomPage.url(),
      recordId: selected.recordId,
      source: { initial, effective, tabZoom },
      dialog: { ...scroll, closeTarget: targets[0], primaryTarget: targets[1], focusWrap: true, originId }
    };
    const screenshot = path.join(artifacts, "inbound-200-browser-zoom.png");
    await zoomPage.screenshot({ path: screenshot, fullPage: true, scale: "device" });
    expect(fs.statSync(screenshot).size, "real 200% Inbound screenshot is retained").toBeGreaterThan(0);
    zoomEvidence.screenshot = path.relative(path.resolve(__dirname, "../.."), screenshot);
  } finally {
    await zoomContext.close();
  }

  const evidence = {
    expectedCaseCount: widths.length + 1,
    executedCaseCount: widthCases.length + Number(Boolean(zoomEvidence)),
    cases: widthCases,
    realZoom: zoomEvidence
  };
  expect(evidence.executedCaseCount).toBe(evidence.expectedCaseCount);
  fs.writeFileSync(path.join(artifacts, "inbound-layout.json"), `${JSON.stringify(evidence, null, 2)}\n`);
});
