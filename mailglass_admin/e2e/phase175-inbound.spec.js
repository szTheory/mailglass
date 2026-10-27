const { test, expect } = require("@playwright/test");

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
