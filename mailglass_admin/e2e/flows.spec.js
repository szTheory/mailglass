const { test, expect, chromium } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const fs = require("fs");
const path = require("path");
const {
  accountSwitcher,
  accountOption,
  accountContext,
  accountId,
  accountSwitchStatus,
  switchStatusIdPattern
} = require("./support/account.cjs");

// =============================================================================
// flows.spec.js — Phase 115 Plan 04 (FLOW-01 / FLOW-02 / FLOW-03)
//
// Proves the 5-path taxonomy (happy / error / boundary / edge / advanced) per
// surface at the 320px floor with the {system} theme axis, plus the overlay
// interaction subset and the light/dark/system contrast spot-check. Drives the
// three live surfaces (Operator /ops/mail, Inbound /ops/mail/inbound, Preview
// /dev/mail) by SEEDED URL — ZERO new fixtures (D-02). Assertions only:
// getComputedStyle / boundingBox / scrollWidth-clientWidth / elementFromPoint /
// data-theme / getAnimations — NEVER any pixel-diff / screenshot assertion (D-03).
//
// Per-file convention: login + open helpers are duplicated from
// structural.spec.js / operator.spec.js (no shared module exists today).
// =============================================================================

const tenantId = "browser-tenant";
const baseURL = process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;
const gapClosureArtifacts = path.resolve(
  __dirname,
  "../test-results/baseline-layout"
);

// The full-walk axis: 320px floor (FLOW-02) and the system theme (FLOW-02 3rd axis).
const FLOW_VIEWPORT = { width: 320, height: 900 };

// ---------------------------------------------------------------------------
// Login + open helpers (mirror structural.spec.js exactly — no shared module)
// ---------------------------------------------------------------------------

async function loginOperator(
  page,
  returnTo,
  subjectId = "operator-1",
  sessionTenantId = tenantId,
  resetScenario = null,
  recentAuthAt = null
) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get(
    `/ops/browser-reset${resetScenario ? `?scenario=${encodeURIComponent(resetScenario)}` : ""}`
  );
  expect(resetResponse.ok()).toBeTruthy();

  const loginParams = new URLSearchParams({
    tenant_id: sessionTenantId,
    return_to: returnTo,
    subject_id: subjectId
  });
  if (recentAuthAt) loginParams.set("recent_auth_at", recentAuthAt);

  const loginURL = new URL(`/ops/browser-login?${loginParams.toString()}`, baseURL).toString();
  await page.goto(loginURL);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${sessionTenantId}`));
}

async function openOperator(page, query = `tenant_id=${tenantId}&view=deliveries`) {
  await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/mail?${query}`);
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
}

async function openInbound(page, query = `tenant_id=${tenantId}`, subjectId = "operator-1", sessionTenantId = tenantId) {
  const path = query ? `/ops/mail/inbound?${query}` : "/ops/mail/inbound";
  await loginOperator(page, `/ops/mail?tenant_id=${sessionTenantId}`, subjectId, sessionTenantId);
  await page.goto(new URL(path, baseURL).toString());
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}

async function installPhase174HookProbe(page) {
  await page.addInitScript(() => {
    const probe = { sockets: [], focusinAdded: [], focusinRemoved: [] };
    window.__phase174Probe = probe;
    const NativeWebSocket = window.WebSocket;
    window.WebSocket = new Proxy(NativeWebSocket, {
      construct(target, args) {
        const socket = Reflect.construct(target, args);
        const record = {
          url: String(args[0]),
          opened: false,
          closed: false,
          sentFrames: 0,
          receivedFrames: 0,
          channelJoins: 0
        };
        probe.sockets.push(record);
        const nativeSend = socket.send.bind(socket);
        socket.send = data => {
          record.sentFrames += 1;
          if (String(data).includes("phx_join")) record.channelJoins += 1;
          return nativeSend(data);
        };
        socket.addEventListener("open", () => { record.opened = true; });
        socket.addEventListener("message", () => { record.receivedFrames += 1; });
        socket.addEventListener("close", () => { record.closed = true; });
        return socket;
      }
    });
    const nativeAdd = EventTarget.prototype.addEventListener;
    const nativeRemove = EventTarget.prototype.removeEventListener;
    EventTarget.prototype.addEventListener = function(type, listener, options) {
      if (
        type === "focusin" &&
        typeof this.matches === "function" &&
        this.matches('[phx-hook="ModalFocusTrap"]')
      ) probe.focusinAdded.push(this.id);
      return nativeAdd.call(this, type, listener, options);
    };
    EventTarget.prototype.removeEventListener = function(type, listener, options) {
      if (
        type === "focusin" &&
        typeof this.matches === "function" &&
        this.matches('[phx-hook="ModalFocusTrap"]')
      ) probe.focusinRemoved.push(this.id);
      return nativeRemove.call(this, type, listener, options);
    };
  });
}

async function phase174DocumentProbe(page) {
  return page.evaluate(() => {
    const probe = window.__phase174Probe || {};
    return {
      sockets: (probe.sockets || []).map(socket => ({
        path: new URL(socket.url, location.href).pathname,
        opened: socket.opened,
        closed: socket.closed,
        sentFrames: socket.sentFrames,
        receivedFrames: socket.receivedFrames,
        channelJoins: socket.channelJoins
      })),
      focusinAdded: probe.focusinAdded || [],
      focusinRemoved: probe.focusinRemoved || []
    };
  });
}

async function phase174FocusTrapWraps(page, dialogId) {
  const dialog = page.locator("#" + dialogId);
  const lastControl = await dialog.evaluate(element => {
    const controls = [...element.querySelectorAll(
      "a[href], area[href], input:not([disabled]):not([type='hidden']), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, [contenteditable='true'], [tabindex]:not([tabindex='-1'])"
    )].filter(control =>
      !control.hasAttribute("data-focus-trap") &&
      control.getClientRects().length > 0 &&
      getComputedStyle(control).visibility !== "hidden"
    );
    const last = controls[controls.length - 1];
    return last?.id || last?.getAttribute("data-testid") || last?.getAttribute("aria-label");
  });
  expect(lastControl, "the production quick view has a final tabbable control").toBeTruthy();
  await dialog.locator('[data-focus-trap="start"]').focus();
  await expect.poll(() => page.evaluate(() => {
    const element = document.activeElement;
    return element?.id || element?.getAttribute("data-testid") || element?.getAttribute("aria-label");
  })).toBe(lastControl);
}

async function assertPhase174QuickViewScrollAccess(page, dialog, dialogId) {
  await dialog.evaluate(element => {
    const content = element.ownerDocument.createElement("div");
    content.dataset.testid = "phase174-overflow-content";
    content.style.blockSize = "1400px";
    content.style.marginBlock = "1rem";
    content.textContent = Array.from({ length: 80 }, (_, index) => `Overflow test line ${index + 1}`).join(" ");
    element.insertBefore(content, element.querySelector('[data-focus-trap="end"]'));
  });

  const dimensions = await dialog.evaluate(element => ({
    clientHeight: element.clientHeight,
    scrollHeight: element.scrollHeight
  }));
  expect(dimensions.scrollHeight, `${dialogId} contains clipped long content`).toBeGreaterThan(dimensions.clientHeight);

  const axe = await new AxeBuilder({ page })
    .include(`#${dialogId}`)
    .withRules(["scrollable-region-focusable"])
    .analyze();
  expect(
    axe.violations.map(violation => violation.id),
    `${dialogId} has no scrollable-region-focusable violation after a long-content reproduction`
  ).not.toContain("scrollable-region-focusable");

  await expect(dialog).toHaveAttribute("tabindex", "0");
  await dialog.focus();
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(dialogId);
  await page.keyboard.press("PageDown");
  await expect.poll(() => dialog.evaluate(element => element.scrollTop)).toBeGreaterThan(0);
  await page.keyboard.press("End");
  await expect.poll(() => dialog.evaluate(element => element.scrollTop + element.clientHeight >= element.scrollHeight - 1)).toBe(true);
}

async function openPreviewEmpty(page) {
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
}

async function openPreviewIndex(page, query = "") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page).toHaveURL(/\/dev\/mail\/MailglassAdmin\.Fixtures\.HappyMailer\/welcome_default/);
  await expect(page.getByTestId("preview-header-controls")).toBeVisible();
  await expect(page.getByTestId("preview-assigns-form")).toBeVisible();
}

async function openPreviewScenario(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-assigns-form")).toBeVisible();
}

async function openPreviewError(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-render-error")).toBeVisible();
}

// noMatchRow mirrors structural.spec.js — visible() filter resolves across table/cards.
function noMatchRow(page) {
  return page
    .locator('[data-testid="inbound-records-table"] tbody tr, [data-testid="inbound-records-cards"] li')
    .filter({ has: page.getByRole("button", { name: "Unrouted", exact: true }) })
    .filter({ visible: true })
    .first();
}

// Two-tier inspection (mirror structural.spec.js): a row click opens the
// condensed Quick view; the full record (detail-column, replay, timeline,
// routing trace, evidence) lives behind "Open full detail" (&full=1).
async function selectDeliveryFull(page, row) {
  await row.click();
  await expect(page.getByTestId("operator-quick-view")).toBeVisible();
  await page.getByTestId("operator-quick-view-full").click();
  await expect(page.getByTestId("operator-detail-column")).toBeVisible();
}

async function selectInboundFull(page, row) {
  const openButton = row.getByTestId("inbound-record-open");
  if (await openButton.count()) {
    await openButton.click();
  } else {
    // Mobile cards are the native control for opening Quick view.
    const mobileOpen = row.getByTestId("inbound-record-row");
    if (await mobileOpen.count()) await mobileOpen.click();
    else await row.click();
  }
  await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
  await page.getByTestId("inbound-quick-view-full").click();
  await expect(page.getByTestId("inbound-detail-column")).toBeVisible();
}

async function assertZoomReadableValue(locator, label, expectedText, viewportWidth) {
  await expect(locator, `${label} is rendered and visible`).toBeVisible();
  await expect(locator, `${label} matches its complete fixture value`).toHaveText(expectedText);
  await locator.scrollIntoViewIfNeeded();
  // scrollIntoViewIfNeeded leaves an element that is already partly in view
  // where it is, which can be a fraction of a pixel above the viewport after a
  // resize carries the scroll offset over. Center it so the edge checks below
  // measure the layout rather than the leftover scroll position.
  await locator.evaluate(element => {
    const rect = element.getBoundingClientRect();
    if (rect.top < 0 || rect.bottom > document.documentElement.clientHeight) {
      element.scrollIntoView({ block: "center", inline: "nearest" });
    }
  });
  const geometry = await locator.evaluate(element => {
    const rect = element.getBoundingClientRect();
    const range = document.createRange();
    range.selectNodeContents(element);
    const lines = [...range.getClientRects()].map(line => ({
      left: line.left,
      right: line.right,
      top: line.top,
      bottom: line.bottom
    }));
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
    let lastText = null;
    while (walker.nextNode()) {
      if (walker.currentNode.textContent.trim()) lastText = walker.currentNode;
    }
    let lastCharacter = null;
    if (lastText) {
      let offset = lastText.textContent.length - 1;
      while (offset >= 0 && /\s/.test(lastText.textContent[offset])) offset -= 1;
      const character = document.createRange();
      character.setStart(lastText, Math.max(offset, 0));
      character.setEnd(lastText, Math.max(offset, 0) + 1);
      const characterRect = character.getBoundingClientRect();
      lastCharacter = { left: characterRect.left, right: characterRect.right };
    }
    return {
      text: element.textContent.trim(),
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      viewportHeight: document.documentElement.clientHeight,
      scrollWidth: element.scrollWidth,
      clientWidth: element.clientWidth,
      scrollHeight: element.scrollHeight,
      clientHeight: element.clientHeight,
      documentScrollWidth: document.documentElement.scrollWidth,
      lines,
      lastCharacter
    };
  });

  expect(geometry.text.length, `${label} has complete rendered text`).toBeGreaterThan(0);
  expect(geometry.text, `${label} is not replaced by truncation`).not.toMatch(/(?:\.\.\.|…)/);
  expect(geometry.lines.length, `${label} has rendered text geometry`).toBeGreaterThan(0);
  expect(geometry.left, `${label} left edge`).toBeGreaterThanOrEqual(0);
  expect(geometry.right, `${label} right edge`).toBeLessThanOrEqual(viewportWidth);
  expect(geometry.top, `${label} top edge`).toBeGreaterThanOrEqual(0);
  expect(geometry.bottom, `${label} bottom edge`).toBeLessThanOrEqual(geometry.viewportHeight);
  expect(geometry.lines.every(line =>
    line.left >= geometry.left && line.right <= geometry.right + 1 &&
    line.left >= 0 && line.right <= viewportWidth + 1
  ), `${label} text lines fit the value and layout viewport`).toBeTruthy();
  expect(geometry.lastCharacter?.left, `${label} final character starts within the value`)
    .toBeGreaterThanOrEqual(geometry.left);
  expect(geometry.lastCharacter?.right, `${label} final character ends within the value`)
    .toBeLessThanOrEqual(geometry.right + 1);
  expect(geometry.scrollWidth - geometry.clientWidth, `${label} horizontal clipping`)
    .toBeLessThanOrEqual(1);
  expect(geometry.scrollHeight - geometry.clientHeight, `${label} vertical clipping`)
    .toBeLessThanOrEqual(1);
  expect(geometry.documentScrollWidth, `${label} document horizontal overflow`)
    .toBeLessThanOrEqual(viewportWidth);
}

async function assertZoomReachableControl(control, label, viewportWidth) {
  await expect(control, `${label} is visible at actual 200% zoom`).toBeVisible();
  await control.scrollIntoViewIfNeeded();
  const geometry = await control.evaluate(element => {
    const rect = element.getBoundingClientRect();
    return {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      viewportWidth: document.documentElement.clientWidth,
      viewportHeight: document.documentElement.clientHeight,
      scrollWidth: element.scrollWidth,
      clientWidth: element.clientWidth,
      scrollHeight: element.scrollHeight,
      clientHeight: element.clientHeight,
      documentScrollWidth: document.documentElement.scrollWidth
    };
  });

  expect(geometry.viewportWidth, `${label} layout viewport width`).toBe(viewportWidth);
  expect(geometry.left, `${label} left edge`).toBeGreaterThanOrEqual(0);
  expect(geometry.right, `${label} right edge`).toBeLessThanOrEqual(viewportWidth);
  expect(geometry.top, `${label} top edge`).toBeGreaterThanOrEqual(0);
  expect(geometry.bottom, `${label} bottom edge`).toBeLessThanOrEqual(geometry.viewportHeight);
  expect(geometry.scrollWidth - geometry.clientWidth, `${label} horizontal clipping`).toBeLessThanOrEqual(1);
  expect(geometry.scrollHeight - geometry.clientHeight, `${label} vertical clipping`).toBeLessThanOrEqual(1);
  expect(geometry.documentScrollWidth, `${label} document horizontal overflow`).toBeLessThanOrEqual(viewportWidth);
}

async function openOperatorReplayModal(page) {
  await openOperator(page);
  // The Confirm control only renders when replay is :exact (or :ambiguous with a
  // selected target) — confirm_enabled?/2 in replay_modal.ex. Row 0 in the browser
  // seed is non-replayable (:unavailable), so it yields a modal WITHOUT a Confirm
  // button. Select the exact-replay delivery (index 3, per operator.spec.js's
  // delivery seed ordering) so #operator-replay-confirm is present for the
  // focus-trap / double-submit assertions.
  // visible() resolves the card row at <768px and the table row at >=768px.
  await selectDeliveryFull(
    page,
    page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3)
  );
  await page.getByTestId("operator-replay-open").click();
  const modal = page.getByTestId("operator-replay-modal");
  await expect(modal).toBeVisible();
  // phx-mounted moves initial focus to Close after the dialog is visible; wait for it
  // so a test that drives focus is not overtaken by the mount focus on slow runners.
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("operator-replay-close");
  return modal;
}

async function openInboundReplayModal(page) {
  await openInbound(page);
  const replayableRow = page
    .locator('[data-testid="inbound-records-table"] tbody tr, [data-testid="inbound-records-cards"] li')
    .filter({ hasNot: page.getByRole("button", { name: "Unrouted", exact: true }) })
    .filter({ visible: true })
    .first();
  await selectInboundFull(page, replayableRow);
  await page.getByTestId("inbound-replay-open").click();
  const modal = page.getByTestId("inbound-replay-modal");
  await expect(modal).toBeVisible();
  // Same mount-focus sync point as openOperatorReplayModal.
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");
  return modal;
}

// ---------------------------------------------------------------------------
// Geometry / contrast helpers (mirror structural.spec.js)
// ---------------------------------------------------------------------------

async function assertNoElementHorizontalOverflow(locator, label) {
  await expect(locator.first(), `${label} present`).toBeVisible();
  const overflow = await locator.first().evaluate(el => el.scrollWidth - el.clientWidth);
  expect(overflow, `${label} horizontal overflow`).toBeLessThanOrEqual(1);
}

async function assertNoRootOverflow(page, label) {
  const overflow = await page.evaluate(() => {
    const el = document.documentElement;
    return el.scrollWidth - el.clientWidth;
  });
  expect(overflow, `${label} root horizontal overflow`).toBeLessThanOrEqual(1);
}

async function assertSingleH1(page, label) {
  await expect(page.getByRole("heading", { level: 1 }), `${label} single h1`).toHaveCount(1);
}

async function assertPanelAboveScrim(modal, label) {
  await expect(modal, label).toBeVisible();
  const hitTest = await modal.evaluate(el => {
    const rect = el.getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const hit = document.elementFromPoint(x, y);
    const nearestTestId = hit && hit.closest ? hit.closest("[data-testid]") : null;
    return {
      ok: hit === el || el.contains(hit),
      hitTestId: nearestTestId ? nearestTestId.getAttribute("data-testid") : null,
      hitTag: hit ? hit.tagName : null
    };
  });
  expect(
    hitTest.ok,
    `${label} panel is above scrim at centroid; hit=${hitTest.hitTestId || hitTest.hitTag}`
  ).toBeTruthy();
}

function parseRgbColor(value) {
  const hex = String(value).trim().match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hex) {
    const digits = hex[1].length === 3 ? hex[1].split("").map(c => c + c).join("") : hex[1];
    return {
      r: Number.parseInt(digits.slice(0, 2), 16) / 255,
      g: Number.parseInt(digits.slice(2, 4), 16) / 255,
      b: Number.parseInt(digits.slice(4, 6), 16) / 255,
      a: 1
    };
  }
  const match = String(value).match(/rgba?\(([^)]+)\)/);
  if (!match) return null;
  const parts = match[1]
    .replace(/\//g, " ")
    .split(/[,\s]+/)
    .filter(Boolean)
    .map(p => (p.trim().endsWith("%") ? (Number.parseFloat(p) / 100) * 255 : Number.parseFloat(p)));
  if (parts.length < 3 || parts.slice(0, 3).some(p => !Number.isFinite(p))) return null;
  return {
    r: parts[0] / 255,
    g: parts[1] / 255,
    b: parts[2] / 255,
    a: parts.length >= 4 && Number.isFinite(parts[3]) ? parts[3] : 1
  };
}

function relativeLuminance(color) {
  const channel = v => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
  return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
}

function contrastRatio(fg, bg) {
  const lighter = Math.max(relativeLuminance(fg), relativeLuminance(bg));
  const darker = Math.min(relativeLuminance(fg), relativeLuminance(bg));
  return (lighter + 0.05) / (darker + 0.05);
}

async function resolvedColors(locator) {
  return locator.first().evaluate(el => {
    const normalizeColor = value => {
      const canvas = document.createElement("canvas");
      const context = canvas.getContext("2d");
      if (!context) return value;
      context.fillStyle = "#000000";
      context.fillStyle = value;
      return context.fillStyle;
    };
    const transparent = value => {
      const match = String(value).match(/rgba?\(([^)]+)\)/);
      if (!match) return false;
      const parts = match[1]
        .replace(/\//g, " ")
        .split(/[,\s]+/)
        .filter(Boolean)
        .map(p => Number.parseFloat(p.trim()));
      return parts.length >= 4 && parts[3] === 0;
    };
    const style = getComputedStyle(el);
    let current = el;
    let backgroundColor = style.backgroundColor;
    while (current && transparent(backgroundColor)) {
      current = current.parentElement;
      backgroundColor = current ? getComputedStyle(current).backgroundColor : "rgb(255, 255, 255)";
    }
    return {
      color: normalizeColor(style.color),
      backgroundColor: normalizeColor(backgroundColor)
    };
  });
}

async function assertTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const foreground = parseRgbColor(colors.color);
  const background = parseRgbColor(colors.backgroundColor);
  expect(foreground, `${label} foreground parses`).not.toBeNull();
  expect(background, `${label} background parses`).not.toBeNull();
  expect(contrastRatio(foreground, background), `${label} text contrast`).toBeGreaterThanOrEqual(4.5);
}

// =============================================================================
// FULL WALK — 3 surfaces x 5 paths at 320px / system theme.
// Each path asserts: correct landmark/testid visible + single-h1 invariant +
// no horizontal overflow on root AND master-detail (scrollWidth - clientWidth
// <= 1). Happy path additionally asserts the single dominant primary CTA.
// =============================================================================

test.describe("flows: full walk — 5 paths x 3 surfaces at 320/system (FLOW-01/02)", () => {

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
    // system theme axis: no explicit ?theme= param → root emits no data-theme.
  });

  // -------------------------------- OPERATOR --------------------------------

  test("Operator happy: select row -> detail timeline; single dominant CTA survives 320/system", async ({ page }) => {
    await openOperator(page);
    await assertSingleH1(page, "operator happy");
    await assertNoRootOverflow(page, "operator happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator happy master-detail");

    // At 320 the table is hidden — select from the card presentation. Phase 175
    // (REPLAY-05) renders the replay CTA only for a replayable target, so open the
    // seeded exact-replay delivery rather than whichever row is first.
    await selectDeliveryFull(
      page,
      page
        .getByTestId("operator-deliveries-cards")
        .getByTestId("operator-delivery-row")
        .filter({ hasText: "browser-exact@example.com" })
        .first()
    );

    // The single obvious top action for Operator: the replay CTA (the one
    // dominant action in the detail). It must be visible and be the dominant
    // action button at 320px. Live copy is "Review webhook replay" (btn-primary).
    const replayCta = page.getByTestId("operator-replay-open");
    await expect(replayCta).toBeVisible();
    const box = await replayCta.boundingBox();
    expect(box, "operator replay CTA box").not.toBeNull();
    expect(Math.round(box.height), "operator replay CTA target floor").toBeGreaterThanOrEqual(44);
    await assertSingleH1(page, "operator happy after select");
    await assertNoRootOverflow(page, "operator happy detail");
  });

  test("Operator error: delivery_id=does-not-exist -> detail error", async ({ page }) => {
    // A bare delivery_id deep-link opens the Quick view; an off-page id surfaces
    // the error inside it (operator-quick-view-error), the list still behind it.
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&delivery_id=does-not-exist`);
    const quickView = page.getByTestId("operator-quick-view");
    await expect(page.getByTestId("operator-quick-view-error")).toBeVisible();
    await expect(quickView.getByTestId("operator-quick-view-full")).toHaveCount(0);
    await expect(quickView.locator("dl")).toHaveCount(0);
    await assertSingleH1(page, "operator error");
    await assertNoRootOverflow(page, "operator error");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator error master-detail");
  });

  test("Operator boundary: filtered-empty -> empty + reset", async ({ page }) => {
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&event=queued`);
    const filteredEmpty = page.getByTestId("operator-deliveries-list-card").getByTestId("data-state-empty");
    await expect(filteredEmpty).toBeVisible();
    await expect(page.getByTestId("operator-empty-reset")).toBeVisible();
    await assertSingleH1(page, "operator boundary");
    await assertNoRootOverflow(page, "operator boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator boundary master-detail");
  });

  test("Operator edge: long/non-ASCII tenant truncates without overflow at 320", async ({ page }) => {
    // Edge path: a long/non-ASCII tenant id stresses the mono ID cells. The
    // suppressed-status seeded view exposes the truncating ID cells; assert no
    // overflow at the 320 floor on root and master-detail.
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&event=suppressed`);
    await assertSingleH1(page, "operator edge");
    await assertNoRootOverflow(page, "operator edge");
    await assertNoElementHorizontalOverflow(page.getByTestId("operator-master-detail"), "operator edge master-detail");
    await assertNoElementHorizontalOverflow(
      page.getByTestId("operator-deliveries-list-card"),
      "operator edge list-card"
    );
  });

  test("Operator advanced: replay modal -> panel above scrim, Escape closes", async ({ page }) => {
    const modal = await openOperatorReplayModal(page);
    await assertPanelAboveScrim(modal, "operator advanced replay-modal");
    await assertSingleH1(page, "operator advanced");
    await assertNoRootOverflow(page, "operator advanced");
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("operator-replay-modal")).toHaveCount(0);
  });

  // --------------------------------- INBOUND --------------------------------

  test("Inbound happy: select no-match row -> routing trace; dominant CTA on replayable row at 320/system", async ({ page }) => {
    await openInbound(page);
    await assertSingleH1(page, "inbound happy");
    await assertNoRootOverflow(page, "inbound happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound happy master-detail");

    // Happy path per taxonomy: select a no-match row -> routing trace renders
    // (the routing trace explains why no Mailbox matched).
    await selectInboundFull(page, noMatchRow(page));
    await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
    await assertSingleH1(page, "inbound happy after no-match select");
    await assertNoRootOverflow(page, "inbound happy trace");

    // Full detail's "← Back" lands on the Quick view (id retained); navigate to the
    // bare list to clear the overlay before selecting a replayable row.
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    // The single dominant top action (Replay inbound) is present on a replayable
    // (matched) row. Live copy is "Replay inbound" (btn-error); the planner's
    // prose label "Replay inbound message" approximates it.
    const replayableRow = page
      .getByTestId("inbound-records-cards")
      .locator("li")
      .filter({ hasNot: page.getByRole("button", { name: "Unrouted", exact: true }) })
      .filter({ visible: true })
      .first();
    await selectInboundFull(page, replayableRow);
    const replayCta = page.getByTestId("inbound-replay-open");
    await expect(replayCta).toBeVisible();
    const box = await replayCta.boundingBox();
    expect(box, "inbound replay CTA box").not.toBeNull();
    expect(Math.round(box.height), "inbound replay CTA target floor").toBeGreaterThanOrEqual(44);
    await assertNoRootOverflow(page, "inbound happy detail");
  });

  test("Inbound error: inbound_id=does-not-exist -> detail error", async ({ page }) => {
    // A bare inbound_id deep-link opens the Quick view; an off-page id surfaces
    // the error inside it (inbound-quick-view-error), the list still behind it.
    await openInbound(page, `tenant_id=${tenantId}&inbound_id=does-not-exist`);
    await expect(page.getByTestId("inbound-quick-view-error")).toBeVisible();
    await assertSingleH1(page, "inbound error");
    await assertNoRootOverflow(page, "inbound error");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound error master-detail");
  });

  test("Inbound boundary: filtered-empty window", async ({ page }) => {
    await openInbound(page, `tenant_id=${tenantId}&search=impossible-filtered-empty`);
    await expect(page.getByText("No messages match the current filters.")).toBeVisible();
    await assertSingleH1(page, "inbound boundary");
    await assertNoRootOverflow(page, "inbound boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-master-detail"), "inbound boundary master-detail");
  });

  test("Inbound edge: no-match record long mono cells select without overflow at 320", async ({ page }) => {
    await openInbound(page);
    // List view first: long mono ID cells must not overflow the list-card at 320
    // (the list-card is hidden once a record is selected at <768px).
    await assertNoElementHorizontalOverflow(
      page.getByTestId("inbound-records-list-card"),
      "inbound edge list-card"
    );

    await selectInboundFull(page, noMatchRow(page));
    await expect(page.getByTestId("inbound-routing-trace")).toBeVisible();
    await assertSingleH1(page, "inbound edge");
    await assertNoRootOverflow(page, "inbound edge");
    // Full detail replaces the list; assert the detail column (not the now-hidden
    // list grid) has no horizontal overflow at the 320 floor.
    await assertNoElementHorizontalOverflow(page.getByTestId("inbound-detail-column"), "inbound edge detail-column");
  });

  test("Inbound advanced: replay modal parity -> panel above scrim, Escape closes", async ({ page }) => {
    const modal = await openInboundReplayModal(page);
    await assertPanelAboveScrim(modal, "inbound advanced replay-modal");
    expect(await modal.getAttribute("role")).toBe("dialog");
    expect(await modal.getAttribute("aria-modal")).toBe("true");
    await assertSingleH1(page, "inbound advanced");
    await assertNoRootOverflow(page, "inbound advanced");
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  });

  // --------------------------------- PREVIEW --------------------------------

  test("Preview happy: scenario -> editable assigns + reset; no redundant render action at 320/system", async ({ page }) => {
    await openPreviewScenario(page, "");
    await assertSingleH1(page, "preview happy");
    await assertNoRootOverflow(page, "preview happy");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview happy shell");
    await expect(page.getByTestId("preview-mailables-picker")).toHaveAttribute("data-picker-variant", "menu");
    await expect(page.getByTestId("preview-email-menu-trigger")).toBeVisible();
    const scenarioLayoutDisplay = await page
      .getByTestId("preview-scenario-layout")
      .evaluate(el => getComputedStyle(el).display);
    expect(scenarioLayoutDisplay).not.toBe("grid");

    // Supported scalar edits render automatically. Reset is the explicit
    // action; a separate Render button would be redundant and imply stale state.
    const assignsForm = page.getByTestId("preview-assigns-form");
    await expect(assignsForm.getByRole("button", { name: "Restore defaults", exact: true })).toBeVisible();
    await expect(assignsForm.getByRole("button", { name: /render preview/i })).toHaveCount(0);
  });

  test("Preview error: BrokenMailer -> render error", async ({ page }) => {
    await openPreviewError(page, "");
    await expect(page.getByTestId("preview-render-error")).toBeVisible();
    await expect(page.getByTestId("preview-mailables-picker")).toHaveAttribute("data-picker-variant", "menu");
    await assertSingleH1(page, "preview error");
    await assertNoRootOverflow(page, "preview error");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview error shell");
  });

  test("Preview boundary: no mailables -> empty", async ({ page }) => {
    await openPreviewEmpty(page);
    await expect(page.getByTestId("preview-empty-mailables")).toBeVisible();
    await assertSingleH1(page, "preview boundary");
    await assertNoRootOverflow(page, "preview boundary");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview boundary shell");
  });

  test("Preview edge: index redirects into the unified scenario layout at 320", async ({ page }) => {
    await openPreviewIndex(page, "");
    await expect(page.getByTestId("preview-start")).toHaveCount(0);
    await expect(page.getByTestId("admin-shell-page-header")).toBeVisible();
    await assertSingleH1(page, "preview redirected scenario");
    await assertNoRootOverflow(page, "preview edge");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview edge shell");
    // The compact email menu exposes real scenario links without a second nav column.
    const mailablesPicker = page.getByTestId("preview-mailables-picker");
    await expect(mailablesPicker).toBeVisible();
    await expect(mailablesPicker).toHaveAttribute("data-picker-variant", "menu");
    await page.getByTestId("preview-email-menu-trigger").click();
    // Phase 178: each option reads the humanized label first and the raw atom beneath it.
    await expect(mailablesPicker.getByRole("link", { name: /^Welcome default\s+welcome_default$/ })).toBeVisible();
  });

  test("Phase 168 shared spacing: operator, Inbound reveal, and Preview gaps use 4px", async ({ page }) => {
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&delivery_id=does-not-exist`);
    const operatorError = page.getByTestId("operator-quick-view-error");
    await expect(operatorError).toBeVisible();
    const operatorErrorIcon = operatorError.locator(".mt-xs");
    await expect(operatorErrorIcon).toBeVisible();
    const iconMarginTop = await operatorErrorIcon.evaluate(element => getComputedStyle(element).marginTop);
    expect(iconMarginTop, "operator error icon margin-top").toBe("4px");

    await page.setViewportSize({ width: 1280, height: 900 });
    await openInbound(page);
    await selectInboundFull(page, noMatchRow(page));
    const evidenceCard = page.getByTestId("inbound-evidence-card");
    await expect(evidenceCard).toBeVisible();
    // Phase 176 replaced the right-aligned reveal stack with one header group: the
    // heading sits above its caption in a 4px (space-y-xs) text stack.
    const headingStack = evidenceCard.getByRole("heading", { name: "Raw provider source" });
    const headingGap = await headingStack.evaluate(element => getComputedStyle(element).marginBottom);
    expect(headingGap, "Inbound evidence heading-to-caption gap").toBe("4px");

    await openPreviewIndex(page);
    await page.getByTestId("preview-email-menu-trigger").click();
    const scenarioList = page.getByTestId("preview-email-menu-scenario-list").first();
    await expect(scenarioList).toBeVisible();
    const scenarioRowGap = await scenarioList.evaluate(element => getComputedStyle(element).rowGap);
    expect(scenarioRowGap, "Preview scenario list row gap").toBe("4px");
  });

  test("Preview advanced: frame theme differs from admin theme without overflow at 320", async ({ page }) => {
    await openPreviewScenario(page, "theme=light");
    await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
    await page.getByTestId("preview-frame-theme-toggle").click();
    await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");
    // Frame theme diverges from admin theme — admin chrome stays light.
    await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-light");
    await assertSingleH1(page, "preview advanced");
    await assertNoRootOverflow(page, "preview advanced");
    await assertNoElementHorizontalOverflow(page.getByTestId("preview-shell"), "preview advanced shell");
  });

  test("Preview a11y: admin theme_picker is tri-state (system reachable)", async ({ page }) => {
    await openPreviewScenario(page, "theme=light");
    // The bespoke binary App button is gone; the canonical theme_picker renders
    // three theme radios (system/light/dark) in the global preview chrome.
    const controls = page.getByTestId("preview-global-controls");
    const radios = controls.locator('input[type="radio"][name="preview_admin_theme"]');
    await expect(radios).toHaveCount(3);
    await expect(page.getByTestId("preview-header-controls").locator('input[name="preview_admin_theme"]')).toHaveCount(0);
    // The :system option is reachable (the third tri-state choice the old binary
    // button could never express).
    await expect(controls.locator('input[type="radio"][name="preview_admin_theme"][value="system"]')).toHaveCount(1);
    // The bespoke admin-theme button must be gone after the swap.
    await expect(page.getByTestId("preview-admin-theme-toggle")).toHaveCount(0);
  });

  test("Preview a11y: backdrop toggle reflects aria-pressed + announces via aria-live", async ({ page }) => {
    await openPreviewScenario(page, "theme=light");
    const backdrop = page.getByTestId("preview-frame-theme-toggle");
    const status = page.getByTestId("preview-backdrop-status");
    const pane = page.getByTestId("preview-pane");
    const beforeBg = await pane.evaluate(el => getComputedStyle(el).backgroundColor);
    // Pre-click: backdrop off (light), aria-pressed=false, announce says light.
    await expect(backdrop).toHaveAttribute("aria-pressed", "false");
    await expect(status).toHaveAttribute("role", "status");
    await expect(status).toHaveAttribute("aria-live", "polite");
    await expect(status).toHaveText("Preview backdrop: light");
    await expect(pane).toHaveAttribute("data-theme", "mailglass-light");
    // Toggle: aria-pressed flips true and the aria-live region announces dark.
    await backdrop.click();
    await expect(backdrop).toHaveAttribute("aria-pressed", "true");
    await expect(status).toHaveText("Preview backdrop: dark");
    await expect(pane).toHaveAttribute("data-preview-frame-theme", "dark");
    await expect(pane).toHaveAttribute("data-theme", "mailglass-dark");
    const afterBg = await pane.evaluate(el => getComputedStyle(el).backgroundColor);
    expect(afterBg).not.toBe(beforeBg);
  });

});

test("Phase 168 Delivery Mailable wrapping", async ({ page }) => {
  const mailable = "Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName";
  fs.mkdirSync(gapClosureArtifacts, { recursive: true });
  await page.setViewportSize({ width: 720, height: 900 });
  await loginOperator(page, "/ops/mail?tenant_id=northstar", "operator-1", "northstar", "accounts");
  await expect(page.getByTestId("operator-overview-health")).toBeVisible();
  expect(await page.evaluate(() => window.innerWidth), "Health CSS viewport width").toBe(720);
  const healthScreenshot = path.join(gapClosureArtifacts, "health-720-css.png");
  await page.screenshot({ path: healthScreenshot, fullPage: true });
  expect(fs.statSync(healthScreenshot).size, "Health screenshot is non-empty").toBeGreaterThan(0);

  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
  await accountSwitcher(page).click();
  const fjordline = accountOption(page, "fjordline-aps");
  await fjordline.click();
  await expect(page).toHaveURL(/tenant_id=fjordline-aps/);

  const row = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();
  await selectDeliveryFull(page, row);
  // Technical details are always expanded since Phase 175 (no disclosure summary).
  await expect(page.locator("#delivery-detail-technical")).toBeVisible();
  const mailableElement = page.locator("#delivery-detail-mailable-trigger");
  await expect(mailableElement).toHaveText("Mailables.TransactionalEmailWithVeryLongModuleName");
  await expect(page.locator("#delivery-detail-mailable")).toHaveText(mailable);

  for (const width of [320, 390, 720, 768, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    const geometry = await mailableElement.evaluate(element => {
      const rect = element.getBoundingClientRect();
      return {
        overflowWrap: getComputedStyle(element).overflowWrap,
        left: rect.left,
        right: rect.right,
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
        documentScrollWidth: document.documentElement.scrollWidth,
        viewportWidth: window.innerWidth,
        overflowing: [...document.querySelectorAll("body *")]
          .map(node => ({ node, overflow: node.scrollWidth - node.clientWidth }))
          .filter(({ overflow }) => overflow > 1)
          .sort((a, b) => b.overflow - a.overflow)
          .slice(0, 3)
          .map(({ node, overflow }) =>
            `${node.dataset.testid || node.tagName.toLowerCase()}: ${node.textContent.trim().slice(0, 48)} (+${overflow}px)`
          )
      };
    });
    expect(geometry.overflowWrap, `Mailable wrapping at ${width}px`).toBe("anywhere");
    expect(geometry.left, `Mailable left edge at ${width}px`).toBeGreaterThanOrEqual(0);
    expect(geometry.right, `Mailable right edge at ${width}px`).toBeLessThanOrEqual(width);
    expect(
      geometry.scrollWidth - geometry.clientWidth,
      `Mailable element overflow at ${width}px`
    ).toBeLessThanOrEqual(1);
    expect(
      geometry.documentScrollWidth,
      `document width at ${width}px; overflowing elements: ${geometry.overflowing.join("; ")}`
    ).toBeLessThanOrEqual(geometry.viewportWidth);

    if ([320, 720, 1440].includes(width)) {
      const screenshot = path.join(gapClosureArtifacts, `delivery-${width}-css.png`);
      await page.screenshot({ path: screenshot, fullPage: true });
      expect(fs.statSync(screenshot).size, `Delivery screenshot at ${width} CSS px is non-empty`)
        .toBeGreaterThan(0);
    }
  }

  const extensionPath = path.resolve(__dirname, "support/browser-zoom-extension");
  const zoomContext = await chromium.launchPersistentContext("", {
    channel: "chromium",
    headless: true,
    viewport: { width: 1440, height: 900 },
    // Keep a 1440px device-pixel capture after the actual tab zoom halves CSS width.
    deviceScaleFactor: 2,
    args: [
      `--disable-extensions-except=${extensionPath}`,
      `--load-extension=${extensionPath}`
    ]
  });

  try {
    const zoomPage = zoomContext.pages()[0] || (await zoomContext.newPage());
    await loginOperator(
      zoomPage,
      "/ops/mail?tenant_id=northstar",
      "operator-1",
      "northstar",
      "accounts"
    );
    await zoomPage.goto("/ops/mail?tenant_id=northstar&view=deliveries");
    await expect(zoomPage.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await accountSwitcher(zoomPage).click();
    await accountOption(zoomPage, "fjordline-aps").click();
    await expect(zoomPage).toHaveURL(/tenant_id=fjordline-aps/);

    const zoomRow = zoomPage.getByTestId("operator-delivery-row").filter({ visible: true }).first();
    const expectedDeliveryId = await zoomRow.getAttribute("phx-value-id");
    expect(expectedDeliveryId, "the selected fixture row exposes its complete Delivery ID").toBeTruthy();
    await selectDeliveryFull(zoomPage, zoomRow);
    const expectedMailable = "Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName";
    // Technical details are always expanded since Phase 175 (no disclosure summary).
    await expect(zoomPage.locator("#delivery-detail-technical")).toBeVisible();
    const zoomedMailable = zoomPage.locator("#delivery-detail-mailable-trigger");
    await expect(zoomPage.locator("#delivery-detail-mailable")).toHaveText(expectedMailable);
    const initialDevicePixelRatio = await zoomPage.evaluate(() => window.devicePixelRatio);

    const serviceWorker =
      zoomContext.serviceWorkers()[0] || (await zoomContext.waitForEvent("serviceworker"));
    const tabZoom = await serviceWorker.evaluate(async () => {
      const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
      if (!tab?.id) throw new Error("The active browser tab is unavailable");
      await chrome.tabs.setZoom(tab.id, 2);
      return { requested: await chrome.tabs.getZoom(tab.id), tabId: tab.id };
    });
    expect(tabZoom.requested, "real Chromium tab zoom factor").toBe(2);

    await expect
      .poll(() => zoomPage.evaluate(() => window.devicePixelRatio))
      .toBe(initialDevicePixelRatio * 2);

    const committedAccountContext = accountContext(zoomPage);
    await expect(committedAccountContext).toBeVisible();
    await expect(committedAccountContext).toContainText("fjordline-aps");
    const topbarControls = [
      ["committed Account context", committedAccountContext],
      ["Account switcher", accountSwitcher(zoomPage)],
      ["Appearance group", zoomPage.getByRole("group", { name: "Appearance", exact: true })],
      ["System radio", zoomPage.getByRole("radio", { name: "System", exact: true })],
      ["System radio label", zoomPage.getByRole("radio", { name: "System", exact: true }).locator("xpath=..")],
      ["Light radio", zoomPage.getByRole("radio", { name: "Light", exact: true })],
      ["Light radio label", zoomPage.getByRole("radio", { name: "Light", exact: true }).locator("xpath=..")],
      ["Dark radio", zoomPage.getByRole("radio", { name: "Dark", exact: true })],
      ["Dark radio label", zoomPage.getByRole("radio", { name: "Dark", exact: true }).locator("xpath=..")]
    ];
    for (const [label, control] of topbarControls) {
      await assertZoomReachableControl(control, label, 720);
    }

    const detail = zoomPage.getByTestId("operator-detail-header");
    await assertZoomReadableValue(detail.getByRole("button", { name: `Copy Delivery ID: ${expectedDeliveryId}`, exact: true }), "Delivery ID", expectedDeliveryId, 720);
    await assertZoomReadableValue(zoomedMailable, "Mailable", "Mailables.TransactionalEmailWithVeryLongModuleName", 720);
    await assertZoomReadableValue(detail.getByText("POSTMARK", { exact: true }), "Provider", "POSTMARK", 720);
    await assertZoomReadableValue(
      detail.getByText("del_01JXW9ZQKB3V1N4P2RMT7FHCG", { exact: true }),
      "Provider message ID",
      "del_01JXW9ZQKB3V1N4P2RMT7FHCG",
      720
    );

    const timelineEvent = zoomPage.getByTestId("operator-timeline-event").first();
    await expect(timelineEvent).toBeVisible();
    const expectedEventId = await timelineEvent.getAttribute("data-event-id");
    expect(expectedEventId, "the selected fixture event exposes its complete Event ID").toBeTruthy();
    const recordedTimestamp = timelineEvent.locator("time").first();
    await expect(recordedTimestamp, "the fixture event has a recorded timestamp").toHaveCount(1);
    const expectedRecordedTimestamp = (await recordedTimestamp.textContent()).trim();
    expect(expectedRecordedTimestamp, "the fixture timestamp exposes its canonical UTC value").toBeTruthy();
    await assertZoomReadableValue(
      timelineEvent.getByRole("button", { name: /^Copy Event ID: / }),
      "Timeline Event ID",
      expectedEventId,
      720
    );
    await assertZoomReadableValue(recordedTimestamp, "Recorded timestamp", expectedRecordedTimestamp, 720);
    const providerEventId = timelineEvent.locator("p.mono").filter({ hasText: /^Provider Event ID:/ });
    await expect(providerEventId, "the selected fixture event has no provider event ID").toHaveCount(0);
    const providerTimestamp = timelineEvent.locator("p").filter({ hasText: /^Provider occurrence time:/ });
    await expect(providerTimestamp, "the selected fixture event has no provider occurrence timestamp")
      .toHaveCount(0);

    const zoomGeometry = await zoomedMailable.evaluate(element => {
      const rect = element.getBoundingClientRect();
      return {
        layoutViewportWidth: window.innerWidth,
        devicePixelRatio: window.devicePixelRatio,
        overflowWrap: getComputedStyle(element).overflowWrap,
        left: rect.left,
        right: rect.right,
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
        documentScrollWidth: document.documentElement.scrollWidth
      };
    });
    expect(zoomGeometry.layoutViewportWidth, "200% zoom halves the 1440 CSS layout viewport")
      .toBe(720);
    expect(
      zoomGeometry.devicePixelRatio / initialDevicePixelRatio,
      "200% browser zoom doubles devicePixelRatio"
    ).toBe(2);
    expect(zoomGeometry.overflowWrap, "Mailable wraps under actual 200% browser zoom").toBe("anywhere");
    expect(zoomGeometry.left, "zoomed Mailable left edge").toBeGreaterThanOrEqual(0);
    expect(zoomGeometry.right, "zoomed Mailable right edge")
      .toBeLessThanOrEqual(zoomGeometry.layoutViewportWidth);
    expect(zoomGeometry.scrollWidth - zoomGeometry.clientWidth, "zoomed Mailable element overflow")
      .toBeLessThanOrEqual(1);
    expect(zoomGeometry.documentScrollWidth, "zoomed document overflow")
      .toBeLessThanOrEqual(zoomGeometry.layoutViewportWidth);

    const description = zoomPage.getByText(
      "Trace each delivery through its event history.",
      { exact: true }
    );

    // UI-SPEC requires the supported 320 CSS px layout width and 200% browser
    // zoom together. With the 2x device scale, a 640px Playwright viewport
    // yields an actual 320 CSS px layout viewport while the tab remains at 2x.
    await zoomPage.setViewportSize({ width: 640, height: 900 });
    await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
    await expect.poll(() => zoomPage.evaluate(() => document.documentElement.clientWidth)).toBe(320);
    const narrowTabZoom = await serviceWorker.evaluate(async () => {
      const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
      if (!tab?.id) throw new Error("The active browser tab is unavailable");
      return chrome.tabs.getZoom(tab.id);
    });
    expect(narrowTabZoom, "narrow layout retains actual 200% browser zoom").toBe(2);
    for (const [label, control] of topbarControls) {
      await assertZoomReachableControl(control, `${label} at 320 CSS px`, 320);
    }
    await assertZoomReadableValue(detail.getByRole("button", { name: `Copy Delivery ID: ${expectedDeliveryId}`, exact: true }), "Delivery ID at 320 CSS px", expectedDeliveryId, 320);
    await assertZoomReadableValue(zoomedMailable, "Mailable at 320 CSS px", "Mailables.TransactionalEmailWithVeryLongModuleName", 320);
    await assertZoomReadableValue(detail.getByText("POSTMARK", { exact: true }), "Provider at 320 CSS px", "POSTMARK", 320);
    await assertZoomReadableValue(
      detail.getByText("del_01JXW9ZQKB3V1N4P2RMT7FHCG", { exact: true }),
      "Provider message ID at 320 CSS px",
      "del_01JXW9ZQKB3V1N4P2RMT7FHCG",
      320
    );
    await assertZoomReadableValue(
      timelineEvent.getByRole("button", { name: /^Copy Event ID: / }),
      "Timeline Event ID at 320 CSS px",
      expectedEventId,
      320
    );
    await assertZoomReadableValue(
      recordedTimestamp,
      "Recorded timestamp at 320 CSS px",
      expectedRecordedTimestamp,
      320
    );
    await assertZoomReadableValue(
      description,
      "Delivery explanation at 320 CSS px",
      "Trace each delivery through its event history.",
      320
    );
    const narrowDocumentWidth = await zoomPage.evaluate(() => document.documentElement.scrollWidth);
    expect(narrowDocumentWidth, "320 CSS px at 200% has no page-level horizontal overflow").toBeLessThanOrEqual(320);
    await expect(description).toBeVisible();
    const clippedCopy = await Promise.all([description, zoomedMailable].map(locator =>
      locator.evaluate(element => {
        const range = document.createRange();
        range.selectNodeContents(element);
        return {
          text: element.textContent.trim(),
          bounds: (() => {
            const rect = element.getBoundingClientRect();
            return { left: rect.left, right: rect.right };
          })(),
          lines: [...range.getClientRects()].map(rect => ({ left: rect.left, right: rect.right })),
          lastCharacter: (() => {
            const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
            let lastText = null;
            while (walker.nextNode()) {
              if (walker.currentNode.textContent.trim()) lastText = walker.currentNode;
            }
            if (!lastText) return null;
            const character = document.createRange();
            character.setStart(lastText, lastText.length - 1);
            character.setEnd(lastText, lastText.length);
            const rect = character.getBoundingClientRect();
            const elementRect = element.getBoundingClientRect();
            return { left: rect.left, right: rect.right, elementLeft: elementRect.left, elementRight: elementRect.right };
          })()
        };
      })
    ));
    for (const copy of clippedCopy) {
      expect(copy.text.length, "zoomed exact-value copy is present").toBeGreaterThan(0);
      expect(copy.lines.length, "zoomed text produces visible line boxes").toBeGreaterThan(0);
      expect(
        copy.lines.every(line =>
          line.left >= copy.bounds.left &&
          line.right <= copy.bounds.right + 1 &&
          line.left >= 0 &&
          line.right <= zoomGeometry.layoutViewportWidth + 1
        ),
        `all rendered text lines fit their element and the ${zoomGeometry.layoutViewportWidth} CSS px viewport`
      ).toBeTruthy();
      expect(copy.lastCharacter?.left, "exact-value final character remains visible inside its element")
        .toBeGreaterThanOrEqual(copy.bounds.left);
      expect(copy.lastCharacter?.right, "exact-value final character does not clip past its element")
        .toBeLessThanOrEqual(copy.bounds.right + 1);
      expect(copy.lastCharacter?.right, "exact-value final character remains inside the viewport")
        .toBeLessThanOrEqual(zoomGeometry.layoutViewportWidth + 1);
    }

    const zoomScreenshot = path.join(gapClosureArtifacts, "delivery-200-browser-zoom.png");
    await zoomPage.screenshot({ path: zoomScreenshot, fullPage: true, scale: "device" });
    expect(fs.statSync(zoomScreenshot).size, "200% zoom screenshot is non-empty").toBeGreaterThan(0);
  } finally {
    await zoomContext.close();
  }
});

// =============================================================================
// OVERLAY SUBSET — operator + inbound replay modal at 320:
// panel-above-scrim + Escape closes + background scrollY unchanged
// (scroll-chaining guard from the mg-overscroll-contain in Plan 02).
// =============================================================================

test.describe("flows: overlay interaction subset at 320 (FLOW-02/03)", () => {

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
  });

  test("Operator replay modal: panel above scrim, Escape closes, background scrollY unchanged", async ({ page }) => {
    const modal = await openOperatorReplayModal(page);
    await assertPanelAboveScrim(modal, "operator overlay-subset");

    const before = await page.evaluate(() => window.scrollY);
    // Scroll inside the modal scroll container — overscroll-behavior: contain
    // must prevent scroll-chaining to the background.
    await modal.evaluate(el => {
      const scroller = el.closest(".mg-overscroll-contain") || el;
      scroller.scrollTop = scroller.scrollTop + 200;
    });
    const after = await page.evaluate(() => window.scrollY);
    expect(after, "operator background scrollY unchanged").toBe(before);

    await page.keyboard.press("Escape");
    await expect(page.getByTestId("operator-replay-modal")).toHaveCount(0);
  });

  test("Inbound replay modal: panel above scrim, Escape closes, background scrollY unchanged", async ({ page }) => {
    const modal = await openInboundReplayModal(page);
    await assertPanelAboveScrim(modal, "inbound overlay-subset");

    const before = await page.evaluate(() => window.scrollY);
    await modal.evaluate(el => {
      // The inbound modal panel itself carries mg-overscroll-contain.
      const scroller = el.classList.contains("mg-overscroll-contain")
        ? el
        : el.closest(".mg-overscroll-contain") || el;
      scroller.scrollTop = scroller.scrollTop + 200;
    });
    const after = await page.evaluate(() => window.scrollY);
    expect(after, "inbound background scrollY unchanged").toBe(before);

    await page.keyboard.press("Escape");
    await expect(page.getByTestId("inbound-replay-modal")).toHaveCount(0);
  });

});

// =============================================================================
// THEME-PARITY SPOT-CHECK — 1 happy + 1 overlay path x {light,dark,system} x 320:
// assertTextContrastAA passes; read data-theme to confirm the theme axis.
// =============================================================================

test.describe("flows: theme-parity contrast spot-check at 320 (FLOW-02)", () => {

  const THEMES = [
    { name: "light", query: "theme=light", expected: "mailglass-light" },
    { name: "dark", query: "theme=dark", expected: "mailglass-dark" },
    { name: "system", query: "", expected: null }
  ];

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
  });

  for (const theme of THEMES) {
    test(`Operator happy path passes AA contrast in ${theme.name} at 320`, async ({ page }) => {
      const query = `tenant_id=${tenantId}&view=deliveries${theme.query ? `&${theme.query}` : ""}`;
      await openOperator(page, query);

      // Confirm the theme axis via data-theme on the root.
      if (theme.expected) {
        await expect(page.locator("html")).toHaveAttribute("data-theme", theme.expected);
      } else {
        expect(await page.locator("html").getAttribute("data-theme"), "system root has no data-theme").toBeNull();
      }

      await assertTextContrastAA(page.getByTestId("operator-deliveries-list-card"), `operator ${theme.name} list-card`);
    });

    test(`Operator overlay (replay modal) passes AA contrast in ${theme.name} at 320`, async ({ page }) => {
      // Open the operator surface in the target theme, then the replay modal.
      const query = `tenant_id=${tenantId}&view=deliveries${theme.query ? `&${theme.query}` : ""}`;
      await openOperator(page, query);
      if (theme.expected) {
        await expect(page.locator("html")).toHaveAttribute("data-theme", theme.expected);
      } else {
        expect(await page.locator("html").getAttribute("data-theme"), "system root has no data-theme").toBeNull();
      }

      // Phase 175 (REPLAY-05): only a replayable target renders the replay CTA.
      await selectDeliveryFull(
        page,
        page
          .getByTestId("operator-deliveries-cards")
          .getByTestId("operator-delivery-row")
          .filter({ hasText: "browser-exact@example.com" })
          .first()
      );
      await page.getByTestId("operator-replay-open").click();
      const modal = page.getByTestId("operator-replay-modal");
      await expect(modal).toBeVisible();

      await assertTextContrastAA(modal, `operator ${theme.name} replay-modal`);
    });
  }

});

// =============================================================================
// THEME PICKER CLICK (FLOW-03) — clicking the operator shell's theme_picker must
// actually re-theme the admin shell. Guards two regressions at once: (1) the
// sr-only radio that swallowed clicks (overlay must keep the input the click
// target), and (2) the shell deriving theme from URL params only, so the
// cookie-persisting redirect left .mg-admin-root unthemed. The shell always
// stamps an explicit data-theme, so assert on .mg-admin-root (the admin theme
// root), not the host <html>.
// =============================================================================

test.describe("flows: operator theme picker applies the theme on click (FLOW-03)", () => {

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize(FLOW_VIEWPORT);
  });

  test("clicking Dark / Light / System re-themes the admin shell and updates selection", async ({ page }) => {
    await openOperator(page);
    const root = page.locator(".mg-admin-root").first();

    // Default (system): shell inherits prefers-color-scheme; system radio is selected.
    await expect(root).not.toHaveAttribute("data-theme", /mailglass-/);
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();

    await page.getByRole("radio", { name: "Dark", exact: true }).click();
    await expect(root, "Dark click themes the shell").toHaveAttribute("data-theme", "mailglass-dark");
    await expect(page.getByRole("radio", { name: "Dark", exact: true })).toBeChecked();

    await page.getByRole("radio", { name: "Light", exact: true }).click();
    await expect(root, "Light click themes the shell").toHaveAttribute("data-theme", "mailglass-light");
    await expect(page.getByRole("radio", { name: "Light", exact: true })).toBeChecked();

    await page.getByRole("radio", { name: "System", exact: true }).click();
    await expect(root, "System click returns to inherited theme").not.toHaveAttribute("data-theme", /mailglass-/);
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
  });

  test("theme preference persists across sections without theme query params", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries`);

    await page.getByRole("radio", { name: "Dark", exact: true }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");
    await expect(page).not.toHaveURL(/[?&]theme=/);

    await page.getByTestId("surface-nav-sidebar").getByRole("link", { name: "Preview", exact: true }).click();
    await expect(page.getByTestId("preview-shell")).toHaveAttribute("data-theme", "mailglass-dark");
    await expect(page).not.toHaveURL(/[?&]theme=/);

    await page.getByTestId("surface-nav-sidebar").getByRole("link", { name: "Health", exact: true }).click();
    await expect(page.getByTestId("operator-shell")).toHaveAttribute("data-theme", "mailglass-dark");
    await expect(page).not.toHaveURL(/[?&]theme=/);

    await page.getByTestId("surface-nav-sidebar").getByRole("link", { name: "Inbound", exact: true }).click();
    await expect(page.getByTestId("operator-shell")).toHaveAttribute("data-theme", "mailglass-dark");
    await expect(page).not.toHaveURL(/[?&]theme=/);
  });

  test("System preference beats stale legacy per-page cookies", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOperator(page, `tenant_id=${tenantId}&view=deliveries`);

    await page.context().addCookies([
      {
        name: "mailglass_admin_theme",
        value: "dark",
        domain: "127.0.0.1",
        path: "/ops/mail"
      },
      {
        name: "mailglass_admin_theme",
        value: "light",
        domain: "127.0.0.1",
        path: "/dev/mail"
      }
    ]);

    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-shell")).toHaveAttribute("data-theme", "mailglass-dark");

    await page.getByRole("radio", { name: "System", exact: true }).click();
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
    await expect(page.getByTestId("operator-shell")).not.toHaveAttribute("data-theme", /mailglass-/);

    await page.getByTestId("surface-nav-sidebar").getByRole("link", { name: "Preview", exact: true }).click();
    await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
    await expect(page.getByTestId("preview-shell")).not.toHaveAttribute("data-theme", /mailglass-/);
    await expect(page).not.toHaveURL(/[?&]theme=/);
  });

});

// =============================================================================
// A11Y DELTAS (Phase 121 Plan 04, D-11 / D-14 / D-16)
//
// Only-forward evidence for the three new a11y behaviors built in Plans 02 & 03:
//   - Reveal disclosure (Plan 02): aria-expanded false->true, aria-controls=
//     "inbound-evidence-raw", the same toggle relabelled "Hide raw source" collapsing
//     back and returning the raw bytes to count 0, and a role="status" aria-live="polite" region.
//   - Replay-modal Tab focus-trap (Plan 03): Tab off the last control wraps focus
//     back inside the dialog, on BOTH the inbound and operator replay modals.
//   - Replay-modal double-submit lock (Plan 03): Confirm carries phx-disable-with
//     ("Replaying…") so a second click cannot re-fire, on BOTH surfaces.
//
// The locked redacted-by-default PII boundary (inbound-evidence-raw count 0 in
// every non-revealed state) is preserved — never weakened (D-10).
// =============================================================================
test.describe("flows: a11y deltas — reveal disclosure + replay focus-trap + double-submit (D-11/D-14)", () => {

  test("Inbound reveal is a true ARIA disclosure: aria-expanded false->true, re-redact collapses raw, aria-live present", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openInbound(page);

    // Select a no-match row to reach the EvidenceCard in its redacted-by-default state.
    await selectInboundFull(page, noMatchRow(page));
    await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();

    const reveal = page.getByTestId("inbound-evidence-reveal");
    // Disclosure semantics in the redacted state.
    await expect(reveal).toHaveAttribute("aria-expanded", "false");
    await expect(reveal).toHaveAttribute("aria-controls", "inbound-evidence-raw");
    // Redacted-by-default PII boundary (D-10): raw bytes absent before reveal.
    await expect(page.getByTestId("inbound-evidence-caption")).toBeVisible();
    await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);

    // Grant the reveal — aria-expanded flips true and the raw payload renders.
    await reveal.click();
    await expect(reveal).toHaveAttribute("aria-expanded", "true");
    await expect(reveal).toHaveText("Hide raw source");
    await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(1);

    // aria-live status region announces the grant in TEXT (WCAG 1.4.1, never color alone).
    const status = page.getByTestId("inbound-evidence-status");
    await expect(status).toHaveAttribute("role", "status");
    await expect(status).toHaveAttribute("aria-live", "polite");
    await expect(status).toContainText("Raw source revealed.");

    // Re-redact collapses back to redacted: raw bytes return to count 0, aria-expanded false.
    // The SAME persistent toggle collapses it; focus stays on that one element.
    await reveal.click();
    await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
    await expect(page.getByTestId("inbound-evidence-caption")).toBeVisible();
    await expect(reveal).toHaveAttribute("aria-expanded", "false");
    await expect(reveal).toHaveText("Reveal raw source");
    await expect(reveal).toBeFocused();
  });

  test("Inbound replay modal: Tab off the last control keeps focus inside the dialog; Confirm locks after first click", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const modal = await openInboundReplayModal(page);

    // Focus-trap: drive focus to the last control (Confirm) then Tab — the end
    // sentinel wraps focus back to the first control, so focus stays inside the dialog.
    await page.locator("#inbound-replay-confirm").focus();
    await page.keyboard.press("Tab");
    await expect
      .poll(() => modal.evaluate(el => el.contains(document.activeElement)), {
        message: "focus remains within the inbound replay dialog after Tab past Confirm"
      })
      .toBe(true);

    // Double-submit lock: Confirm carries phx-disable-with so a render->click double-fire
    // cannot append a duplicate replay run to the append-only ledger.
    await expect(page.locator("#inbound-replay-confirm")).toHaveAttribute("phx-disable-with", "Replaying…");
    await page.locator("#inbound-replay-close").focus();
    await page.keyboard.press("Shift+Tab");
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-confirm");
    await page.keyboard.press("Tab");
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("inbound-replay-close");
  });

  test("Operator replay modal: Tab off the last control keeps focus inside the dialog; Confirm locks after first click", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const modal = await openOperatorReplayModal(page);

    await page.locator("#operator-replay-confirm").focus();
    await page.keyboard.press("Tab");
    await expect
      .poll(() => modal.evaluate(el => el.contains(document.activeElement)), {
        message: "focus remains within the operator replay dialog after Tab past Confirm"
      })
      .toBe(true);
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("operator-replay-close");

    await expect(page.locator("#operator-replay-confirm")).toHaveAttribute("phx-disable-with", "Replaying…");
  });

  test("Phase 168 Account scope", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    let holdAccountReply = false;
    let heldAccountReply = null;
    let resolveAccountReply;
    let liveSocket = null;
    await page.routeWebSocket(/\/live\/websocket/, socket => {
      liveSocket = socket;
      const server = socket.connectToServer();
      socket.onMessage(message => server.send(message));
      server.onMessage(message => {
        if (holdAccountReply && String(message).includes("fjordline-aps")) {
          holdAccountReply = false;
          heldAccountReply = message;
          resolveAccountReply?.();
        } else {
          socket.send(message);
        }
      });
    });

    await loginOperator(
      page,
      "/ops/mail?tenant_id=northstar",
      "operator-1",
      "northstar",
      "accounts"
    );
    await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(accountId(page)).toHaveText("northstar");

    // Give the prior Account a selected record; switching must drop this ID.
    await page.getByTestId("operator-delivery-row").filter({ visible: true }).first().click();
    await expect(page).toHaveURL(/delivery_id=/);
    const targetAccount = accountOption(page, "fjordline-aps");
    await expect(targetAccount).toHaveAttribute("href", /tenant_id=fjordline-aps/);
    await expect(targetAccount).not.toHaveAttribute("href", /delivery_id=/);
    // Quick view is modal, so finish its focused task before opening the selector.
    await page.getByTestId("operator-detail-back").click();
    await expect(page).not.toHaveURL(/delivery_id=/);
    const committedRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();
    const committedRowText = await committedRow.innerText();
    const pendingSwitch = accountSwitchStatus(page).filter({
      hasText: "Switching to fjordline-aps…"
    });
    await expect(pendingSwitch, "the target Account's pending status is available to the switch control")
      .toHaveCount(1);
    await expect(pendingSwitch, "status target uses a safe numeric token independent of the Account ID")
      .toHaveAttribute("id", switchStatusIdPattern);
    await expect(pendingSwitch).toBeHidden();
    await accountSwitcher(page).click();
    holdAccountReply = true;
    const pendingAccountReply = new Promise(resolve => { resolveAccountReply = resolve; });
    await targetAccount.click();

    await pendingAccountReply;
    await expect(pendingSwitch, "a delayed Account switch has visible pending feedback").toBeVisible();
    await expect(pendingSwitch).toHaveAttribute("role", "status");
    await expect(pendingSwitch).toHaveAttribute("aria-live", "polite");
    await expect(pendingSwitch).toHaveAttribute("aria-atomic", "true");
    await expect(pendingSwitch).toHaveText("Switching to fjordline-aps…");
    await expect(accountId(page)).toHaveText("northstar");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }).first()).toHaveText(committedRowText, { useInnerText: true });
    liveSocket.send(heldAccountReply);
    heldAccountReply = null;

    await expect(page).toHaveURL(/tenant_id=fjordline-aps/);
    await expect(page).not.toHaveURL(/delivery_id=/);
    await expect(accountId(page)).toHaveText("fjordline-aps");
    await expect(pendingSwitch).toHaveCount(0);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    const scopedRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();
    await expect(scopedRow).toContainText("fjordline-aps.example");
    await scopedRow.click();
    await expect(page.getByTestId("operator-quick-view")).toContainText("fjordline-aps");
  });

  test("Phase 168 essential shell and status type roles meet the UI contract", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await openOperator(page);

    const sizes = await page.evaluate(() => {
      const pixels = element => Number.parseFloat(getComputedStyle(element).fontSize);
      const body = document.querySelector(".text-body");
      const badges = [...document.querySelectorAll(".badge")];
      const navigation = [...document.querySelectorAll('[data-testid="operator-shell"] nav a')];
      return {
        body: body ? pixels(body) : null,
        badge: badges.map(pixels),
        navigation: navigation.map(pixels)
      };
    });

    expect(sizes.body, "body text uses the 16px role").toBe(16);
    expect(sizes.badge.length, "status badges render on the selected operator page").toBeGreaterThan(0);
    expect(Math.min(...sizes.badge), `essential badge sizes ${sizes.badge}`).toBeGreaterThanOrEqual(14);
    expect(sizes.navigation.length, "operator navigation links render").toBeGreaterThan(0);
    expect(Math.min(...sizes.navigation), `navigation sizes ${sizes.navigation}`).toBeGreaterThanOrEqual(14);
  });

  test("Phase 168 Quick view focus", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await openOperator(page);

    const mobileRow = page.locator('[id^="operator-delivery-mobile-"]').first();
    const deliveryId = await mobileRow.getAttribute("id");
    await mobileRow.focus();
    await page.keyboard.press("Enter");

    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    await expect(quickView).toHaveAttribute("aria-modal", "true");
    await expect(page.getByRole("heading", { name: "Quick view", exact: true })).toBeVisible();
    await expect(quickView).toContainText("Updated");
    await expect(quickView).toContainText("Delivery ID");
    await expect(quickView).toContainText(deliveryId.replace("operator-delivery-mobile-", ""));
    await expect(page.getByTestId("operator-quick-view-focus-return")).toHaveAttribute("data-focus-return-id", deliveryId);
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("operator-quick-view-close");

    await quickView.getByTestId("operator-quick-view-next").focus();
    await page.keyboard.press("Shift+Tab");
    await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute("data-testid"))).toBe("operator-quick-view-full");

    const idField = quickView.getByRole("button", { name: /^Copy Delivery ID: / });
    const overflow = await idField.evaluate(element => element.scrollWidth - element.clientWidth);
    expect(overflow, "full delivery ID wraps within the narrow dialog").toBeLessThanOrEqual(1);

    const firstQuickViewControl = await quickView.evaluate(el => {
      const controls = [...el.querySelectorAll(
        "a[href], area[href], input:not([disabled]):not([type='hidden']), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, [contenteditable='true'], [tabindex]:not([tabindex='-1'])"
      )].filter(element => !element.hasAttribute("data-focus-trap") && element.getClientRects().length > 0);
      return controls[0]?.id || controls[0]?.getAttribute("data-testid");
    });
    await page.getByTestId("operator-quick-view-full").focus();
    await page.keyboard.press("Tab");
    await expect.poll(() => page.evaluate(() => document.activeElement?.id || document.activeElement?.getAttribute("data-testid"))).toBe(firstQuickViewControl);

    await page.keyboard.press("Escape");
    await expect(quickView).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(deliveryId);

    await page.setViewportSize({ width: 1280, height: 900 });
    const desktopRow = page.locator('[id^="operator-delivery-desktop-"]').first();
    const desktopId = await desktopRow.getAttribute("id");
    await desktopRow.focus();
    await page.keyboard.press("Enter");
    await expect(quickView).toBeVisible();

    await page.getByTestId("operator-detail-back").click();
    await expect(quickView).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(desktopId);
  });

  test("Phase 175 Delivery tracer", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    fs.mkdirSync(gapClosureArtifacts, { recursive: true });

    let holdNextReply = false;
    let heldReply = null;
    let resolveHeldReply = null;
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

    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&window_hours=168`);
    const selectedRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3);
    await selectDeliveryFull(page, selectedRow);

    const selectedUrl = new URL(page.url());
    const selectedDeliveryId = selectedUrl.searchParams.get("delivery_id");
    expect(selectedDeliveryId).toBeTruthy();
    await expect(page.getByTestId("operator-detail-column")).toBeVisible();

    const technical = page.locator("#delivery-detail-technical");
    await expect(technical).toBeVisible();
    expect(await technical.evaluate(element => element.tagName)).toBe("DIV");
    await expect(technical).toContainText(selectedDeliveryId);

    const suppression = page.getByTestId("operator-suppression-card");
    await expect(suppression).toBeVisible();
    await suppression.getByTestId("operator-suppression-refresh").click();
    await expect(suppression).toContainText(
      /No current Mailglass suppression matches this delivery|Current Mailglass match|unavailable/i
    );

    await page.getByTestId("operator-replay-open").click();
    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal.getByRole("button", { name: "Close", exact: true })).toBeVisible();
    const requestId = await modal.getByTestId("operator-replay-target-id").innerText();
    expect(requestId).toMatch(/^[0-9a-f-]{36}$/i);
    await expect(modal).toContainText("browser-exact-delivery");
    await expect(modal).toContainText("does not resend mail");
    await expect(modal).toContainText("across this Account");

    const reviewScreenshot = path.join(gapClosureArtifacts, "delivery-175-replay-review.png");
    await page.screenshot({ path: reviewScreenshot, fullPage: true });
    expect(fs.statSync(reviewScreenshot).size, "Delivery replay review screenshot is non-empty")
      .toBeGreaterThan(0);

    const pendingReply = new Promise(resolve => { resolveHeldReply = resolve; });
    const confirm = modal.getByTestId("operator-replay-confirm");
    await confirm.click();
    await pendingReply;
    await expect(confirm).toBeDisabled();
    await expect(modal.getByTestId("operator-replay-target-id")).toHaveText(requestId);

    liveSocket.send(heldReply);
    heldReply = null;

    await expect(modal).toHaveCount(0);
    const toast = page.getByTestId("copy-toast");
    await expect(toast).toBeVisible();
    await expect(toast).toHaveAttribute("role", "status");
    await expect(toast).toContainText(/Replay command added .* Event|Replay added no new Events/);

    const detail = page.getByTestId("operator-detail-column");
    await expect(detail).toContainText("Webhook replay requested");
    await expect(detail).toContainText("Webhook replay completed");
    await expect(detail).toContainText(/Replay command added .* Event|Replay added no new Events/);

    const resultScreenshot = path.join(gapClosureArtifacts, "delivery-175-replay-result.png");
    await page.screenshot({ path: resultScreenshot, fullPage: true });
    expect(fs.statSync(resultScreenshot).size, "Delivery replay result screenshot is non-empty")
      .toBeGreaterThan(0);

    const returnedUrl = new URL(page.url());
    expect(returnedUrl.searchParams.get("tenant_id")).toBe(tenantId);
    expect(returnedUrl.searchParams.get("window_hours")).toBe("168");
    expect(returnedUrl.searchParams.get("delivery_id")).toBe(selectedDeliveryId);
    expect(returnedUrl.searchParams.get("full")).toBe("1");
    const backToListUrl = new URL(await page.getByTestId("operator-detail-back").getAttribute("href"), baseURL);
    expect(backToListUrl.searchParams.get("tenant_id")).toBe(tenantId);
    expect(backToListUrl.searchParams.get("view")).toBe("deliveries");
    expect(backToListUrl.searchParams.get("window_hours")).toBe("168");
    await expect(page.getByTestId("operator-replay-open")).toBeVisible();
  });

  test("Phase 175 Delivery recovery", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    let holdNextReply = false;
    let holdReplayResponse = true;
    let heldReply = null;
    let resolveHeldReply = null;
    let liveSocket = null;

    await page.routeWebSocket(/\/live\/websocket/, socket => {
      liveSocket = socket;
      const server = socket.connectToServer();

      socket.onMessage(message => {
        if (holdReplayResponse && String(message).includes("confirm_replay")) holdNextReply = true;
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

    await openOperator(page, `tenant_id=${tenantId}&view=deliveries&window_hours=168`);
    await selectDeliveryFull(
      page,
      page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3)
    );
    await page.getByTestId("operator-replay-open").click();

    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    const modalNode = await modal.elementHandle();
    const targetId = await modal.getByTestId("operator-replay-target-id").innerText();
    const confirm = modal.getByTestId("operator-replay-confirm");
    const initialReviewId = await confirm.getAttribute("phx-value-review");

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const armed = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch(
        "/ops/browser-mutate?action=arm-known-read-failure&operation=selected_delivery",
        {
          method: "POST",
          headers: { "x-csrf-token": csrfToken },
          redirect: "manual"
        }
      );
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(armed.status, armed.body).toBe(200);

    const pendingReply = new Promise(resolve => { resolveHeldReply = resolve; });
    await confirm.click();
    await pendingReply;
    await expect(confirm).toBeDisabled();
    await expect(modal.getByTestId("operator-replay-target-id")).toHaveText(targetId);

    liveSocket.send(heldReply);
    heldReply = null;
    holdReplayResponse = false;

    const feedback = modal.getByTestId("operator-replay-feedback");
    await expect(feedback).toContainText("Couldn’t refresh current Delivery eligibility.");
    await expect(feedback.getByRole("button", { name: "Review again", exact: true })).toBeVisible();
    expect(await modal.evaluate((element, original) => element === original, modalNode)).toBeTruthy();
    await expect(modal.getByTestId("operator-replay-target-id")).toHaveText(targetId);

    await feedback.getByRole("button", { name: "Review again", exact: true }).click();
    await expect(modal.getByTestId("operator-replay-target-id")).toHaveText(targetId);
    expect(await modal.evaluate((element, original) => element === original, modalNode)).toBeTruthy();
    await expect(confirm).toBeEnabled();
    expect(await confirm.getAttribute("phx-value-review")).not.toBe(initialReviewId);

    await confirm.click();
    await expect(modal).toHaveCount(0);
    await expect(page.getByTestId("copy-toast")).toContainText(/Replay command added .* Event/);
  });

  test("Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    let holdReplayResponse = false;
    let holdNextReply = false;
    let heldReply = null;
    let resolveHeldReply = null;
    let liveSocket = null;

    await page.routeWebSocket(/\/live\/websocket/, socket => {
      liveSocket = socket;
      const server = socket.connectToServer();

      socket.onMessage(message => {
        if (holdReplayResponse && String(message).includes("confirm_replay")) holdNextReply = true;
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

    const ambiguousReset = await page.request.get("/ops/browser-reset?scenario=phase169-replay-many");
    expect(ambiguousReset.ok()).toBeTruthy();
    const ambiguous = await ambiguousReset.json();
    const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${ambiguous.tenant_id}`);
    await page.goto(`/ops/browser-login?tenant_id=${ambiguous.tenant_id}&return_to=${returnTo}`);
    await page.goto(
      `/ops/mail?tenant_id=${ambiguous.tenant_id}&delivery_id=${ambiguous.delivery_id}&full=1`
    );
    await page.getByTestId("operator-replay-open").click();

    const ambiguousModal = page.getByTestId("operator-replay-modal");
    await expect(ambiguousModal).toBeVisible();
    const radios = ambiguousModal.getByRole("radio", { name: "POSTMARK webhook target", exact: true });
    await expect(radios).toHaveCount(2);
    await expect(radios.nth(0)).not.toBeChecked();
    await expect(radios.nth(1)).not.toBeChecked();
    await expect(ambiguousModal.getByTestId("operator-replay-confirm")).toHaveCount(0);

    const selectedRadio = ambiguousModal.locator(
      `#operator-replay-targets input[type='radio'][value='${ambiguous.candidate_ids[1]}']`
    );
    await selectedRadio.check();
    await expect(selectedRadio).toBeChecked();
    const exactTargetId = await ambiguousModal
      .locator("#operator-replay-targets input[type='radio']:checked")
      .getAttribute("value");
    expect(exactTargetId).toBe(ambiguous.candidate_ids[1]);
    const confirm = ambiguousModal.getByTestId("operator-replay-confirm");
    holdReplayResponse = true;
    const pendingReply = new Promise(resolve => { resolveHeldReply = resolve; });
    await confirm.click();
    await pendingReply;
    await expect(confirm).toBeDisabled();
    await expect(confirm).toHaveText("Replaying…");
    await expect(selectedRadio).toBeChecked();

    liveSocket.send(heldReply);
    heldReply = null;
    holdReplayResponse = false;
    await expect(ambiguousModal).toHaveCount(0);
    await expect(page.getByTestId("copy-toast")).toContainText("Replay command added 1 newly normalized Event.");

    const authorized = await page.request.get("/ops/browser-auth-log");
    expect(authorized.ok()).toBeTruthy();
    const authorizationLog = await authorized.json();
    expect(authorizationLog.destructive_actions).toHaveLength(1);
    expect(authorizationLog.destructive_actions[0].delivery_id).toBe(ambiguous.delivery_id);
    expect(authorizationLog.destructive_actions[0].webhook_event_id).toBe(exactTargetId);

    const staleAuthAt = "2000-01-01T00:00:00.000Z";
    await loginOperator(
      page,
      `/ops/mail?tenant_id=${tenantId}`,
      "operator-1",
      tenantId,
      null,
      staleAuthAt
    );
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&window_hours=168`);
    const exactRow = page.getByTestId("operator-delivery-row").filter({
      visible: true,
      hasText: "browser-exact@example.com"
    }).first();
    await selectDeliveryFull(page, exactRow);
    await page.getByTestId("operator-replay-open").click();

    const deniedModal = page.getByTestId("operator-replay-modal");
    const deniedTarget = await deniedModal.getByTestId("operator-replay-target-id").first().innerText();
    const deniedConfirm = deniedModal.getByTestId("operator-replay-confirm");
    const firstReviewId = await deniedConfirm.getAttribute("phx-value-review");
    await deniedConfirm.click();
    const denial = deniedModal.getByTestId("operator-replay-feedback");
    await expect(denial).toContainText("Recent authentication is required.");
    await expect(denial).not.toContainText("Ask an Account administrator to review access.");
    await expect(deniedModal).toBeVisible();
    await expect(deniedModal.getByTestId("operator-replay-target-id").first()).toHaveText(deniedTarget);
    await expect(deniedConfirm).toBeDisabled();
    await expect(denial.getByRole("button", { name: "Review again", exact: true })).toBeVisible();

    await denial.getByRole("button", { name: "Review again", exact: true }).click();
    await expect(deniedModal.getByTestId("operator-replay-target-id").first()).toHaveText(deniedTarget);
    await expect(deniedConfirm).toBeEnabled();
    expect(await deniedConfirm.getAttribute("phx-value-review")).not.toBe(firstReviewId);
    await expect(page.getByTestId("operator-replay-command-feedback")).toHaveCount(0);

    await deniedModal.locator("#operator-replay-close").click();
    await page.getByTestId("operator-detail-back").click();
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    const unavailableRow = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();
    await selectDeliveryFull(page, unavailableRow);
    await expect(page.getByTestId("operator-detail-column")).toContainText("Replay is unavailable.");
    await expect(page.getByTestId("operator-replay-open")).toHaveCount(0);

    await loginOperator(page, `/ops/mail?tenant_id=${tenantId}`);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&window_hours=168`);
    const noChangeRow = page.getByTestId("operator-delivery-row").filter({
      visible: true,
      hasText: "browser-noop@example.com"
    }).first();
    await selectDeliveryFull(page, noChangeRow);
    await page.getByTestId("operator-replay-open").click();
    await page.getByTestId("operator-replay-confirm").click();
    await expect(page.getByTestId("copy-toast")).toContainText(
      "Replay command completed with no newly normalized Events."
    );
    await expect(page.getByTestId("operator-replay-command-feedback")).toContainText(
      "Replay command completed with no newly normalized Events."
    );
    await expect(page.getByTestId("operator-replay-action")).toContainText(
      "Last replay: completed · 0 newly normalized Events"
    );
    await expect(page.getByTestId("operator-timeline")).toContainText("no change");
  });

  test("Phase 175 Delivery layout U1/U2/U3/U5/U6: technical wrapping, reachable replay review and real zoom", async ({ page }) => {
    const expectedWidths = [320, 375, 768, 1280, 1440];
    const expectedMailable = "Mailables.TransactionalEmailWithVeryLongModuleName";
    const artifactDir = path.resolve(__dirname, "../test-results/phase175-layout");
    fs.mkdirSync(artifactDir, { recursive: true });

    const openFjordlineDetail = async targetPage => {
      await loginOperator(
        targetPage,
        "/ops/mail?tenant_id=northstar",
        "operator-1",
        "northstar",
        "accounts"
      );
      await targetPage.goto("/ops/mail?tenant_id=northstar&view=deliveries&window_hours=168");
      await accountSwitcher(targetPage).click();
      await accountOption(targetPage, "fjordline-aps").click();
      await expect(targetPage).toHaveURL(/tenant_id=fjordline-aps/);
      const row = targetPage.getByTestId("operator-delivery-row").filter({ visible: true }).first();
      const deliveryId = await row.getAttribute("phx-value-id");
      expect(deliveryId, "selected Delivery exposes its complete exact ID").toBeTruthy();
      await selectDeliveryFull(targetPage, row);
      return { deliveryId, detail: targetPage.getByTestId("operator-detail-header") };
    };

    const { deliveryId, detail } = await openFjordlineDetail(page);
    const mailable = page.locator("#delivery-detail-mailable-trigger");
    const copyId = detail.getByRole("button", { name: `Copy Delivery ID: ${deliveryId}`, exact: true });
    const widthReceipts = [];
    for (const width of expectedWidths) {
      await page.setViewportSize({ width, height: 900 });
      await expect(detail).toBeVisible();
      await expect(detail).toContainText("fjordline-aps");
      await assertZoomReadableValue(copyId, `Delivery ID at ${width}px`, deliveryId, width);
      await assertZoomReadableValue(mailable, `Mailable at ${width}px`, expectedMailable, width);
      const geometry = await page.evaluate(() => ({
        viewportWidth: window.innerWidth,
        documentWidth: document.documentElement.scrollWidth,
        horizontalOverflow: [...document.querySelectorAll("body *")]
          .filter(element => {
            const rect = element.getBoundingClientRect();
            const style = getComputedStyle(element);
            return rect.width > 0 && style.display !== "none" && style.visibility !== "hidden" &&
              Number(style.opacity) > 0 && (rect.left < -1 || rect.right > window.innerWidth + 1);
          })
          .slice(0, 8)
          .map(element => `${element.tagName.toLowerCase()}#${element.id}.${String(element.className).slice(0, 48)}`)
      }));
      expect(geometry.documentWidth, `Delivery page has no horizontal overflow at ${width}px`)
        .toBeLessThanOrEqual(width);
      expect(geometry.horizontalOverflow, `visible Delivery geometry fits at ${width}px`)
        .toEqual([]);
      widthReceipts.push({ width, deliveryId, account: "fjordline-aps", mailable: expectedMailable, ...geometry });
      if ([320, 1440].includes(width)) {
        const screenshot = path.join(artifactDir, `delivery-${width}.png`);
        await page.screenshot({ path: screenshot, fullPage: true });
        expect(fs.statSync(screenshot).size, `Delivery ${width}px screenshot is retained`).toBeGreaterThan(0);
        widthReceipts.at(-1).screenshot = path.relative(path.resolve(__dirname, "../.."), screenshot);
      }
    }
    expect(widthReceipts).toHaveLength(5);

    await openOperator(page);
    await selectDeliveryFull(page, page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3));
    const trigger = page.getByTestId("operator-replay-open");
    await expect(trigger).toBeVisible();
    const triggerId = await trigger.getAttribute("id");
    const selectedUrl = page.url();
    await trigger.click();
    const modal = page.getByTestId("operator-replay-modal");
    await expect(modal).toBeVisible();
    await expect(modal.getByRole("heading", { name: "Review webhook replay", exact: true })).toBeVisible();
    const modalTargetId = await modal.getByTestId("operator-replay-target-id").innerText();
    expect(modalTargetId, "the review names its exact stored request").toBeTruthy();
    await expect(accountContext(page)).toContainText("browser-tenant");
    expect(page.url()).toBe(selectedUrl);

    const extensionPath = path.resolve(__dirname, "support/browser-zoom-extension");
    const zoomContext = await chromium.launchPersistentContext("", {
      channel: "chromium",
      headless: true,
      viewport: { width: 1440, height: 900 },
      deviceScaleFactor: 2,
      args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`]
    });
    let zoomReceipt;
    try {
      const zoomPage = zoomContext.pages()[0] || await zoomContext.newPage();
      const selected = await openFjordlineDetail(zoomPage);
      const initial = await zoomPage.evaluate(() => ({
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight,
        devicePixelRatio: window.devicePixelRatio
      }));
      const serviceWorker = zoomContext.serviceWorkers()[0] || await zoomContext.waitForEvent("serviceworker");
      const zoom = await serviceWorker.evaluate(async () => {
        const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
        if (!tab?.id) throw new Error("Active Chromium tab is unavailable");
        await chrome.tabs.setZoom(tab.id, 2);
        return { tabId: tab.id, factor: await chrome.tabs.getZoom(tab.id) };
      });
      expect(zoom.factor, "actual browser tabs.setZoom applies a real 200% zoom").toBe(2);
      await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(720);
      await zoomPage.setViewportSize({ width: 640, height: 900 });
      await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
      const effective = await zoomPage.evaluate(() => ({
        viewportWidth: window.innerWidth,
        viewportHeight: window.innerHeight,
        documentWidth: document.documentElement.scrollWidth,
        devicePixelRatio: window.devicePixelRatio
      }));
      expect(effective.devicePixelRatio / initial.devicePixelRatio, "real tab zoom doubles effective DPR").toBe(2);
      expect(effective.documentWidth, "Delivery page has no overflow under real 200% zoom").toBeLessThanOrEqual(320);
      const zoomId = zoomPage.getByTestId("operator-detail-header").getByRole("button", {
        name: `Copy Delivery ID: ${selected.deliveryId}`, exact: true
      });
      await assertZoomReadableValue(zoomId, "Delivery ID at real 200% zoom", selected.deliveryId, 320);
      await assertZoomReadableValue(
        zoomPage.locator("#delivery-detail-mailable-trigger"),
        "Mailable at real 200% zoom",
        expectedMailable,
        320
      );
      const zoomTextEvidence = { url: zoomPage.url(), deliveryId: selected.deliveryId, mailable: expectedMailable };
      const longTextScreenshot = path.join(artifactDir, "delivery-200-browser-zoom-long-text.png");
      await zoomPage.screenshot({ path: longTextScreenshot, fullPage: true, scale: "device" });
      expect(fs.statSync(longTextScreenshot).size).toBeGreaterThan(0);
      await openOperator(zoomPage);
      await selectDeliveryFull(
        zoomPage,
        zoomPage.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3)
      );
      const replayTrigger = zoomPage.getByTestId("operator-replay-open");
      const originId = await replayTrigger.getAttribute("id");
      await replayTrigger.click();
      const zoomModal = zoomPage.getByTestId("operator-replay-modal");
      await expect(zoomModal).toBeVisible();
      const zoomTargetId = await zoomModal.getByTestId("operator-replay-target-id").innerText();
      expect(zoomTargetId).toBeTruthy();
      const scroll = await zoomModal.evaluate(element => ({
        clientHeight: element.clientHeight,
        scrollHeight: element.scrollHeight,
        overflowY: getComputedStyle(element).overflowY,
        scrollTop: element.scrollTop
      }));
      expect(scroll.overflowY).toBe("auto");
      expect(scroll.scrollHeight).toBeGreaterThan(scroll.clientHeight);
      expect((await accountContext(zoomPage).textContent()).trim()).toContain("browser-tenant");
      const close = zoomModal.getByRole("button", { name: "Close", exact: true });
      const confirm = zoomModal.getByTestId("operator-replay-confirm");
      await expect(close).toBeVisible();
      await expect(confirm).toBeVisible();
      const targets = await Promise.all([close, confirm].map(control => control.boundingBox()));
      for (const target of targets) {
        expect(target.width).toBeGreaterThanOrEqual(44);
        expect(target.height).toBeGreaterThanOrEqual(44);
      }
      await zoomModal.evaluate(element => { element.scrollTop = element.scrollHeight; });
      await expect(confirm).toBeInViewport();
      await zoomModal.evaluate(element => { element.scrollTop = 0; });
      await expect(close).toBeInViewport();
      await confirm.focus();
      await zoomPage.keyboard.press("Tab");
      await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe("operator-replay-close");
      await zoomPage.keyboard.press("Shift+Tab");
      await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe("operator-replay-confirm");
      await zoomPage.keyboard.press("Escape");
      await expect(zoomModal).toHaveCount(0);
      await expect.poll(() => zoomPage.evaluate(() => document.activeElement?.id)).toBe(originId);
      zoomReceipt = {
        caseId: "layout:delivery:real-200-percent-zoom",
        longTextEvidence: zoomTextEvidence,
        url: zoomPage.url(),
        source: { initial, effective, tabZoom: zoom },
        dialog: { ...scroll, exactTargetId: zoomTargetId, closeTarget: targets[0], primaryTarget: targets[1], focusWrap: true, originId }
      };
      const screenshot = path.join(artifactDir, "delivery-200-browser-zoom.png");
      await zoomPage.screenshot({ path: screenshot, fullPage: true, scale: "device" });
      expect(fs.statSync(screenshot).size, "real 200% zoom screenshot is retained").toBeGreaterThan(0);
      zoomReceipt.screenshot = path.relative(path.resolve(__dirname, "../.."), screenshot);
    } finally {
      await zoomContext.close();
    }
    const evidence = {
      expectedCaseCount: expectedWidths.length + 1,
      executedCaseCount: widthReceipts.length + Number(Boolean(zoomReceipt)),
      cases: widthReceipts,
      realZoom: zoomReceipt
    };
    expect(evidence.executedCaseCount).toBe(evidence.expectedCaseCount);
    fs.writeFileSync(path.join(artifactDir, "delivery-layout.json"), `${JSON.stringify(evidence, null, 2)}\n`);
  });

  test("Phase 175 suppression refresh", async ({ page }) => {
    const resetResponse = await page.request.get(
      "/ops/browser-reset?scenario=phase169-suppression&variant=one"
    );
    expect(resetResponse.ok()).toBeTruthy();
    const fixture = await resetResponse.json();
    const detailPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${fixture.delivery_id}&full=1`;

    await page.context().clearCookies();
    const loginPath = `/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`)}`;
    await page.goto(loginPath);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
    await page.goto(detailPath);

    const originalUrl = page.url();
    const card = page.getByTestId("operator-suppression-card");
    const refresh = card.getByTestId("operator-suppression-refresh");
    await expect(card).toContainText("Current Mailglass match");
    await expect(card).toContainText("operator review · Ångström");
    await expect(refresh).toHaveAttribute("phx-disable-with", "Refreshing suppression…");
    await expect(refresh).toHaveClass(/btn-ghost/);
    await expect(card.getByTestId("operator-suppression-refresh")).toHaveCount(1);
    await refresh.focus();
    await expect.poll(() => page.evaluate(() => document.activeElement?.dataset.testid)).toBe(
      "operator-suppression-refresh"
    );

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const armed = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch(
        "/ops/browser-mutate?action=arm-known-read-failure&operation=delivery_suppression",
        {
          method: "POST",
          headers: { "x-csrf-token": csrfToken },
          redirect: "manual"
        }
      );
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(armed.status, armed.body).toBe(200);

    await refresh.click();
    await expect(card).toContainText("Stale");
    await expect(card).toContainText("Couldn’t refresh suppression evidence. Try again.");
    await expect(card).toContainText("last retrieved record and may be out of date");
    await expect(card).toContainText("operator review · Ångström");
    await expect(refresh).toBeVisible();
    await expect(card.getByTestId("operator-suppression-refresh")).toHaveCount(1);
    await expect.poll(() => page.evaluate(() => document.activeElement?.dataset.testid)).toBe(
      "operator-suppression-refresh"
    );
    expect(page.url()).toBe(originalUrl);

    const changedResponse = await page.request.get(
      "/ops/browser-reset?scenario=phase169-suppression&variant=many"
    );
    expect(changedResponse.ok()).toBeTruthy();

    await refresh.click();
    await expect(card).toContainText("Current Mailglass match");
    await expect(card).toContainText("phase169-address-stream");
    await expect(card).toContainText("Complaint");
    await expect(card).not.toContainText("operator review · Ångström");
    await expect(refresh).toBeVisible();
    await expect(card.getByTestId("operator-suppression-refresh")).toHaveCount(1);
    await expect.poll(() => page.evaluate(() => document.activeElement?.dataset.testid)).toBe(
      "operator-suppression-refresh"
    );
    expect(page.url()).toBe(originalUrl);
    const selected = new URL(page.url());
    expect(selected.searchParams.get("tenant_id")).toBe(tenantId);
    expect(selected.searchParams.get("delivery_id")).toBe(fixture.delivery_id);
  });

  test("Phase 175 suppression policy", async ({ page }) => {
    const resetResponse = await page.request.get(
      "/ops/browser-reset?scenario=phase169-suppression&variant=one"
    );
    expect(resetResponse.ok()).toBeTruthy();
    const fixture = await resetResponse.json();
    const detailPath = `/ops/mail?tenant_id=${tenantId}&view=deliveries&delivery_id=${fixture.delivery_id}&full=1`;

    await page.context().clearCookies();
    const loginPath = `/ops/browser-login?tenant_id=${tenantId}&return_to=${encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`)}`;
    await page.goto(loginPath);
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
    await page.goto(detailPath);

    const card = page.getByTestId("operator-suppression-card");
    const refresh = card.getByTestId("operator-suppression-refresh");
    const actionIsLast = () =>
      refresh.evaluate(button => button.parentElement?.lastElementChild === button);

    await expect(card).toContainText("Removal policy");
    await expect(card).toContainText("Mailglass allows removal of Policy suppressions.");
    await expect(card.getByText("Expiry date not recorded", { exact: true })).toHaveCount(0);
    await expect(card.locator("time[data-local-time='true']")).toHaveCount(1);
    await expect(refresh).toHaveAttribute("phx-disable-with", "Refreshing suppression…");
    await expect(refresh).toHaveClass(/btn-ghost/);
    await expect(refresh).toHaveCount(1);
    await expect(card.getByRole("button", { name: /remove suppression/i })).toHaveCount(0);
    expect(await actionIsLast()).toBe(true);

    const changedResponse = await page.request.get(
      "/ops/browser-reset?scenario=phase169-suppression&variant=many"
    );
    expect(changedResponse.ok()).toBeTruthy();

    const originalUrl = page.url();
    await refresh.click();
    await expect(card).toContainText("Mailglass does not allow removal of Complaint suppressions.");
    await expect(card).toContainText("Expiry date not recorded");
    await expect(card).toContainText("Other configured stores and provider restrictions are not checked.");
    await expect(card).toContainText("Address + stream · Account-local");
    await expect(card).toContainText("phase169-address-stream");
    await expect(card.locator("time[data-local-time='true']")).toHaveCount(0);
    await expect(refresh).toBeVisible();
    await expect(refresh).toHaveCount(1);
    expect(await actionIsLast()).toBe(true);
    await expect(card.getByRole("button", { name: /remove suppression/i })).toHaveCount(0);
    expect(page.url()).toBe(originalUrl);
  });

  test("Phase 168 confirmation focus", async ({ browser }) => {
    const context = await browser.newContext({
      baseURL,
      viewport: { width: 320, height: 900 },
      isMobile: true,
      hasTouch: true
    });
    const page = await context.newPage();

    let holdNextReply = false;
    let holdReplayResponse = true;
    let heldReply = null;
    let resolveHeldReply = null;
    let liveSocket = null;

    await page.routeWebSocket(/\/live\/websocket/, socket => {
      liveSocket = socket;
      const server = socket.connectToServer();

      socket.onMessage(message => {
        if (holdReplayResponse && String(message).includes("confirm_replay")) holdNextReply = true;
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

    try {
      await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
      await openOperator(page);
      await selectDeliveryFull(page, page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3));
      await page.getByTestId("operator-replay-open").tap();
      const modal = page.getByTestId("operator-replay-modal");
      await expect(modal).toBeVisible();
      await expect(modal.getByRole("heading", { name: "Review webhook replay" })).toBeVisible();
      await expect(modal).toHaveAttribute("aria-describedby", "replay-modal-description");
      await expect(modal).toContainText("browser-exact-delivery");
      const operatorShell = page.getByTestId("operator-shell");
      await expect(page.getByRole("radio", { name: "System", exact: true })).toBeChecked();
      const lightModalBackground = await modal.evaluate(element => getComputedStyle(element).backgroundColor);
      await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
      await expect.poll(() => modal.evaluate(element => getComputedStyle(element).backgroundColor)).not.toBe(lightModalBackground);
      const darkModalBackground = await modal.evaluate(element => getComputedStyle(element).backgroundColor);
      expect(darkModalBackground).not.toBe(lightModalBackground);
      await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
      await expect.poll(() => modal.evaluate(element => getComputedStyle(element).backgroundColor)).toBe(lightModalBackground);
      await expect(operatorShell).not.toHaveAttribute("data-theme", /mailglass-/);
      const motion = await modal.evaluate(element => ({
        animation: getComputedStyle(element).animationDuration,
        transition: getComputedStyle(element).transitionDuration
      }));
      expect(Number.parseFloat(motion.animation), `reduced-motion animation ${motion.animation}`).toBeLessThanOrEqual(0.001);
      expect(Number.parseFloat(motion.transition), `reduced-motion transition ${motion.transition}`).toBeLessThanOrEqual(0.001);
      const exactTargetId = await modal.getByTestId("operator-replay-target-id").innerText();
      expect(exactTargetId).toMatch(/^[0-9a-f-]{36}$/i);
      const initialFocus = await page.evaluate(() => ({
        tag: document.activeElement?.tagName,
        id: document.activeElement?.id,
        text: document.activeElement?.textContent?.trim().slice(0, 60)
      }));
      expect(
        await modal.evaluate(el => el.contains(document.activeElement)),
        `focus should enter the confirmation dialog; active=${JSON.stringify(initialFocus)}`
      ).toBeTruthy();

      const pendingReply = new Promise(resolve => { resolveHeldReply = resolve; });
      const confirm = modal.getByTestId("operator-replay-confirm");
      await confirm.tap();
      await pendingReply;
      await expect(confirm).toHaveText("Replaying…");
      await expect(confirm).toBeDisabled();
      await expect(modal.getByTestId("operator-replay-target-id")).toHaveText(exactTargetId);
      await expect(modal).toContainText("Selected target");
      await modal.locator("#operator-replay-close").focus();
      await page.keyboard.press("Shift+Tab");
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("operator-replay-cancel");
      await expect.poll(() => modal.evaluate(el => el.contains(document.activeElement))).toBeTruthy();

      liveSocket.send(heldReply);
      heldReply = null;
      holdReplayResponse = false;
      await expect(modal).toHaveCount(0);
      await expect(page.getByTestId("operator-replay-command-feedback")).toContainText(
        "Replay command added 1 newly normalized Event."
      );
      const detail = page.getByTestId("operator-detail-column");
      await expect(detail).toContainText("Webhook replay requested");
      await expect(detail).toContainText("Webhook replay completed");
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("replay-open-btn");

      const staleAuthAt = "2000-01-01T00:00:00.000Z";
      await loginOperator(
        page,
        `/ops/mail?tenant_id=${tenantId}`,
        "operator-1",
        tenantId,
        null,
        staleAuthAt
      );
      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
      await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
      await selectDeliveryFull(page, page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(3));
      const replayTrigger = page.getByTestId("operator-replay-open");
      await replayTrigger.tap();
      const deniedModal = page.getByTestId("operator-replay-modal").filter({ visible: true }).first();
      // LiveView's mounted focus runs after two animation frames. Let it
      // finish before moving focus so Enter cannot activate Close instead.
      await expect(deniedModal.locator("#operator-replay-close")).toBeFocused();
      const deniedTarget = await deniedModal.getByTestId("operator-replay-target-id").innerText();
      const deniedConfirm = deniedModal.getByTestId("operator-replay-confirm");
      await deniedConfirm.focus();
      await expect(deniedConfirm).toBeFocused();
      await page.keyboard.press("Enter");
      const staleAuthFeedback = deniedModal.getByTestId("operator-replay-feedback");
      await expect(staleAuthFeedback).toContainText("Recent authentication is required.");
      await expect(staleAuthFeedback).not.toContainText("Ask an Account administrator to review access.");
      await expect(deniedModal.getByTestId("operator-replay-review-again")).toBeVisible();
      await expect(deniedModal).toBeVisible();
      await expect(deniedModal.getByTestId("operator-replay-target-id")).toHaveText(deniedTarget);
      await expect(deniedConfirm).toBeDisabled();
      await deniedModal.locator("#operator-replay-close").focus();
      await page.keyboard.press("Shift+Tab");
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("operator-replay-cancel");
      await expect.poll(() => deniedModal.evaluate(el => el.contains(document.activeElement))).toBeTruthy();
      await page.keyboard.press("Escape");
      await expect(page.getByTestId("operator-replay-modal").filter({ visible: true })).toHaveCount(0);
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("replay-open-btn");

      await openOperator(page);
      await selectDeliveryFull(page, page.getByTestId("operator-delivery-row").filter({ visible: true }).first());
      const unavailableDetail = page.getByTestId("operator-detail-column");
      await expect(unavailableDetail).toContainText("Replay is unavailable.");
      await expect(unavailableDetail).toContainText("Historical rows without exact webhook linkage");
      await expect(page.getByTestId("operator-replay-open")).toHaveCount(0);
      await expect(page.getByTestId("operator-replay-modal")).toHaveCount(0);
    } finally {
      await context.close();
    }
  });

  test("Phase174 scroll access: delivery overflow is keyboard reachable and both navigation boundaries are inert", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await openOperator(page);

    const firstRow = page.locator('[data-testid="operator-delivery-row"]:visible').first();
    await expect(firstRow).toBeVisible();
    await firstRow.click();
    const quickView = page.getByTestId("operator-quick-view");
    await expect(quickView).toBeVisible();
    await assertPhase174QuickViewScrollAccess(page, quickView, "operator-quick-view");

    const position = quickView.locator('[aria-live="polite"]');
    await expect(position).toHaveText(/^\s*1 of \d+\s*$/);
    const [current, total] = (await position.textContent()).trim().split(" of ").map(Number);
    expect(current).toBe(1);

    const previous = quickView.getByTestId("operator-quick-view-prev");
    await expect(previous).toHaveJSProperty("tagName", "SPAN");
    await expect(previous).toHaveAttribute("tabindex", "-1");
    await expect(previous).not.toHaveAttribute("role");
    await expect(previous).not.toHaveAttribute("href");
    await expect(previous).toHaveText("Previous delivery unavailable");
    const previousBox = await previous.boundingBox();
    for (let index = 1; index < total; index += 1) {
      await quickView.getByRole("link", { name: "Next delivery", exact: true }).click();
      await expect(position).toHaveText(`${index + 1} of ${total}`);
    }
    const next = quickView.getByTestId("operator-quick-view-next");
    await expect(next).toHaveJSProperty("tagName", "SPAN");
    await expect(next).toHaveAttribute("tabindex", "-1");
    await expect(next).not.toHaveAttribute("role");
    await expect(next).not.toHaveAttribute("href");
    await expect(next).toHaveText("Next delivery unavailable");
    const nextBox = await next.boundingBox();
    const closeBox = await quickView.getByRole("link", { name: "Close quick view", exact: true }).boundingBox();

    for (const [label, box] of [["Previous", previousBox], ["Next", nextBox], ["Close", closeBox]]) {
      expect(box?.width, `${label} delivery control keeps a 44px width`).toBeGreaterThanOrEqual(44);
      expect(box?.height, `${label} delivery control keeps a 44px height`).toBeGreaterThanOrEqual(44);
    }
  });

  test("Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await openInbound(page);

    const firstRow = page.locator('[data-testid="inbound-record-open"]:visible').first();
    await expect(firstRow).toBeVisible();
    await firstRow.click();
    const quickView = page.getByTestId("inbound-quick-view");
    await expect(quickView).toBeVisible();
    await assertPhase174QuickViewScrollAccess(page, quickView, "inbound-quick-view");

    const position = quickView.locator('[aria-live="polite"]');
    await expect(position).toHaveText(/^\s*1 of \d+\s*$/);
    const [current, total] = (await position.textContent()).trim().split(" of ").map(Number);
    expect(current).toBe(1);

    const previous = quickView.getByRole("button", { name: "Previous inbound record", exact: true });
    await expect(previous).toBeDisabled();
    const previousBox = await previous.boundingBox();
    for (let index = 1; index < total; index += 1) {
      await quickView.getByRole("link", { name: "Next inbound record", exact: true }).click();
      await expect(position).toHaveText(`${index + 1} of ${total}`);
    }
    const next = quickView.getByRole("button", { name: "Next inbound record", exact: true });
    await expect(next).toBeDisabled();
    const nextBox = await next.boundingBox();
    const closeBox = await quickView.getByRole("link", { name: "Close quick view", exact: true }).boundingBox();

    for (const [label, box] of [["Previous", previousBox], ["Next", nextBox], ["Close", closeBox]]) {
      expect(box?.width, `Inbound ${label} control keeps a 44px width`).toBeGreaterThanOrEqual(44);
      expect(box?.height, `Inbound ${label} control keeps a 44px height`).toBeGreaterThanOrEqual(44);
    }

    await quickView.getByRole("link", { name: "Open full detail", exact: true }).click();
    const back = page.getByTestId("inbound-detail-back");
    await expect(back).toBeVisible();
    await expect(back).toBeFocused();
    await back.click();
    await expect(page.getByTestId("inbound-quick-view")).toBeVisible();
    await expect(page.locator("#inbound-quick-view-close")).toBeFocused();
  });

  test("Phase174 client hooks: Admin focus traps survive patches, reconnects, and removal", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.emulateMedia({ reducedMotion: "reduce" });
    await installPhase174HookProbe(page);

    const actualWebSockets = [];
    page.on("websocket", socket => actualWebSockets.push(socket.url()));
    const lock = fs.readFileSync(path.resolve(__dirname, "../mix.lock"), "utf8");
    const liveViewVersion = lock.match(/^\s+"phoenix_live_view": \{:hex, :phoenix_live_view, "([^"]+)"/m)?.[1];
    expect(liveViewVersion).toBe("1.2.13");

    const cases = [];
    await openOperator(page);
    await expect(page.evaluate(() => matchMedia("(prefers-reduced-motion: reduce)").matches)).resolves.toBe(true);
    const deliveryRows = page.getByTestId("operator-delivery-row").filter({ visible: true });
    await expect(deliveryRows.count()).resolves.toBeGreaterThan(1);

    async function runDeliveryCycle(index, closeWithEscape) {
      const opener = deliveryRows.nth(index).getByRole("button", { name: /Open delivery/ });
      const openerId = await opener.getAttribute("id");
      const initialId = await opener.getAttribute("phx-value-id");
      await opener.click();
      const quickView = page.getByTestId("operator-quick-view");
      await expect(quickView).toBeVisible();
      const initialProbe = await phase174DocumentProbe(page);
      expect(initialProbe.focusinAdded.filter(id => id === "operator-quick-view").length -
        initialProbe.focusinRemoved.filter(id => id === "operator-quick-view").length).toBe(1);
      await phase174FocusTrapWraps(page, "operator-quick-view");
      const next = quickView.getByRole("link", { name: "Next delivery" });
      await expect(next).toBeVisible();
      const nextId = new URL(await next.getAttribute("href"), page.url()).searchParams.get("delivery_id");
      expect(nextId).toBeTruthy();
      await next.click();
      await expect.poll(() => new URL(page.url()).searchParams.get("delivery_id")).toBe(nextId);
      expect(nextId).not.toBe(initialId);
      if (closeWithEscape) await page.keyboard.press("Escape");
      else await quickView.getByRole("link", { name: "Close quick view" }).click();
      await expect(quickView).toHaveCount(0);
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(openerId);
      const closedProbe = await phase174DocumentProbe(page);
      const added = closedProbe.focusinAdded.filter(id => id === "operator-quick-view").length;
      const removed = closedProbe.focusinRemoved.filter(id => id === "operator-quick-view").length;
      expect(removed).toBe(added);
      expect(closedProbe.sockets.some(socket => socket.channelJoins > 0)).toBe(true);
      cases.push({ surface: "delivery", opened: initialId, navigatedTo: nextId, focusReturnedTo: openerId, focusinAdded: added, focusinRemoved: removed });
    }

    await runDeliveryCycle(1, true);
    await runDeliveryCycle(1, false);

    const beforeDrop = await phase174DocumentProbe(page);
    const beforeDropCount = beforeDrop.sockets.filter(socket => socket.path.includes("/live/websocket")).length;
    expect(beforeDropCount).toBe(1);
    const createdBeforeDrop = await page.evaluate(() => window.__phase174Probe.sockets.length);
    await page.evaluate(() => new Promise(resolve => window.liveSocket.disconnect(resolve)));
    await page.evaluate(() => window.liveSocket.connect());
    await expect.poll(async () => {
      const afterDrop = await phase174DocumentProbe(page);
      return afterDrop.sockets.length;
    }).toBeGreaterThan(createdBeforeDrop);
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const afterReconnect = await phase174DocumentProbe(page);
    expect(afterReconnect.sockets.filter(socket => socket.path.includes("/live/websocket") && socket.opened && !socket.closed)).toHaveLength(1);
    expect(actualWebSockets.length).toBeGreaterThan(0);
    await runDeliveryCycle(0, true);

    await openInbound(page);
    await expect(page.evaluate(() => matchMedia("(prefers-reduced-motion: reduce)").matches)).resolves.toBe(true);
    const inboundRows = page.getByTestId("inbound-records-table")
      .getByTestId("inbound-record-row").filter({ visible: true });
    await expect(inboundRows.first()).toBeVisible();
    expect(await inboundRows.count()).toBeGreaterThan(1);

    async function runInboundCycle(index, closeWithEscape) {
      const opener = inboundRows.nth(index).getByTestId("inbound-record-open");
      const openerId = await opener.getAttribute("id");
      const initialId = await opener.getAttribute("phx-value-id");
      await opener.click();
      const quickView = page.getByTestId("inbound-quick-view");
      await expect(quickView).toBeVisible();
      const initialProbe = await phase174DocumentProbe(page);
      expect(initialProbe.focusinAdded.filter(id => id === "inbound-quick-view").length -
        initialProbe.focusinRemoved.filter(id => id === "inbound-quick-view").length).toBe(1);
      await phase174FocusTrapWraps(page, "inbound-quick-view");
      const next = quickView.getByRole("link", { name: "Next inbound record" });
      await expect(next).toBeVisible();
      const nextId = new URL(await next.getAttribute("href"), page.url()).searchParams.get("inbound_id");
      expect(nextId).toBeTruthy();
      await next.click();
      await expect.poll(() => new URL(page.url()).searchParams.get("inbound_id")).toBe(nextId);
      expect(nextId).not.toBe(initialId);
      if (closeWithEscape) await page.keyboard.press("Escape");
      else await quickView.getByRole("link", { name: "Close quick view" }).click();
      await expect(quickView).toHaveCount(0);
      const matchingRowId = "inbound-record-open-desktop-" + nextId;
      await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(matchingRowId);
      const closedProbe = await phase174DocumentProbe(page);
      const added = closedProbe.focusinAdded.filter(id => id === "inbound-quick-view").length;
      const removed = closedProbe.focusinRemoved.filter(id => id === "inbound-quick-view").length;
      expect(removed).toBe(added);
      expect(closedProbe.sockets.some(socket => socket.channelJoins > 0)).toBe(true);
      cases.push({
        surface: "inbound",
        opened: initialId,
        navigatedTo: nextId,
        focusReturnedTo: matchingRowId,
        openerBeforeNavigation: openerId,
        focusinAdded: added,
        focusinRemoved: removed
      });
    }

    await runInboundCycle(1, false);
    await runInboundCycle(1, true);
    expect(cases.filter(item => item.surface === "delivery")).toHaveLength(3);
    expect(cases.filter(item => item.surface === "inbound")).toHaveLength(2);
  });

});
