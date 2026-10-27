const { test, expect } = require("@playwright/test");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const evidencePath = path.resolve(__dirname, "../../tmp/demo_browser_evidence/phase174/hooks.json");
const hookSourcePath = path.resolve(__dirname, "../../../../mailglass_admin/priv/static/hooks.js");

function mixVersion(lockPath, dependency) {
  const lock = fs.readFileSync(lockPath, "utf8");
  const match = lock.match(new RegExp('^\\s+"' + dependency + '": \\{:hex, :' + dependency + ', "([^"]+)"', "m"));
  if (!match) throw new Error("Could not find " + dependency + " in " + lockPath);
  return match[1];
}

function npmVersion(lockPath, packageName) {
  const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
  const version = lock.packages["node_modules/" + packageName]?.version;
  if (!version) throw new Error("Could not find " + packageName + " in " + lockPath);
  return version;
}

async function loginTo(page, target) {
  await page.goto("/demo/login?return_to=" + encodeURIComponent(target));
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

async function installLifecycleProbe(page) {
  await page.addInitScript(() => {
    const probe = {
      sockets: [],
      focusinAdded: [],
      focusinRemoved: [],
      browsingContextReceipts: []
    };
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
          channelJoins: 0,
          events: {}
        };
        probe.sockets.push(record);
        const nativeSend = socket.send.bind(socket);
        socket.send = data => {
          const payload = String(data);
          record.sentFrames += 1;
          if (payload.includes("phx_join")) record.channelJoins += 1;
          for (const event of ["playground-toggle"]) {
            if (payload.includes(event)) record.events[event] = (record.events[event] || 0) + 1;
          }
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
      ) {
        probe.focusinAdded.push(this.id);
      }
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

    window.addEventListener("pagehide", () => {
      const active = probe.focusinAdded.length - probe.focusinRemoved.length;
      const receiptURL = new URL(location.href);
      receiptURL.searchParams.delete("playground_token");
      const receipt = { url: receiptURL.pathname + receiptURL.search, activeFocusinAtPagehide: active };
      probe.browsingContextReceipts.push(receipt);
      if (window.parent !== window) {
        try {
          window.parent.__phase174Probe?.browsingContextReceipts.push(receipt);
        } catch (_) {}
      }
    });
  });
}

function safeWebSocketPath(url) {
  try {
    return new URL(url).pathname;
  } catch (_) {
    return String(url).split("?")[0];
  }
}

async function documentProbe(frame) {
  return frame.evaluate(() => {
    const probe = window.__phase174Probe || {};
    const safeURL = new URL(location.href);
    safeURL.searchParams.delete("playground_token");
    const scripts = Array.from(document.scripts, script => script.src || "inline");
    const html = document.documentElement?.outerHTML || "";
    return {
      url: safeURL.pathname + safeURL.search,
      sockets: (probe.sockets || []).map(socket => ({
        path: new URL(socket.url, location.href).pathname,
        opened: socket.opened,
        closed: socket.closed,
        sentFrames: socket.sentFrames,
        receivedFrames: socket.receivedFrames,
        channelJoins: socket.channelJoins,
        events: socket.events
      })),
      focusinAdded: probe.focusinAdded || [],
      focusinRemoved: probe.focusinRemoved || [],
      scripts,
      adminBootstrapPresent: html.includes("positionActiveFieldHelpTooltips") ||
        scripts.some(script => /\/(?:dev\/mail|ops\/mail)\/js-[a-f0-9]{32}(?:$|\?)/.test(script))
    };
  });
}

async function focusTrapWrapsToLastControl(frame, dialogSelector) {
  const lastControl = await frame.locator(dialogSelector).evaluate(dialog => {
    const controls = Array.from(dialog.querySelectorAll(
      "a[href], area[href], input:not([disabled]):not([type='hidden']), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, [contenteditable='true'], [tabindex]:not([tabindex='-1'])"
    )).filter(element =>
      !element.hasAttribute("data-focus-trap") &&
      element.getClientRects().length > 0 &&
      getComputedStyle(element).visibility !== "hidden"
    );
    const element = controls[controls.length - 1];
    return element?.id || element?.getAttribute("data-testid") || element?.getAttribute("aria-label");
  });
  expect(lastControl, "the production quick view has a tabbable control").toBeTruthy();
  await frame.locator(dialogSelector + ' [data-focus-trap="start"]').focus();
  await expect.poll(() => frame.evaluate(() => {
    const element = document.activeElement;
    return element?.id || element?.getAttribute("data-testid") || element?.getAttribute("aria-label");
  })).toBe(lastControl);
}

async function readDocumentSet(page) {
  const documents = [];
  for (const frame of page.frames()) documents.push(await documentProbe(frame));
  return documents;
}

test.describe("Phase174 hooks", () => {
  test.beforeEach(async ({ request }) => {
    if (!process.env.DEMO_EVIDENCE_RESET_TOKEN || !process.env.DEMO_EVIDENCE_PROJECT_ID) return;
    const response = await request.post("/demo/evidence/reset", {
      headers: {
        "x-mailglass-demo-reset-token": process.env.DEMO_EVIDENCE_RESET_TOKEN || ""
      }
    });
    expect(response.ok(), "the seeded Demo browser DB is ready").toBeTruthy();
  });

  test("Storybook owns its iframe hook and both pinned Demo surfaces complete real cycles", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.emulateMedia({ reducedMotion: "reduce" });
    await installLifecycleProbe(page);

    const networkWebSockets = [];
    const hookAssetResponses = [];
    page.on("websocket", socket => {
      const observation = {
        path: safeWebSocketPath(socket.url()),
        sentFrames: 0,
        receivedFrames: 0
      };
      networkWebSockets.push(observation);
      socket.on("framesent", () => { observation.sentFrames += 1; });
      socket.on("framereceived", () => { observation.receivedFrames += 1; });
    });
    page.on("response", async response => {
      const url = new URL(response.url());
      if (url.pathname.startsWith("/dev/storybook-hooks-")) {
        const body = await response.body();
        hookAssetResponses.push({
          url: url.pathname,
          status: response.status(),
          responseMd5: crypto.createHash("md5").update(body).digest("hex"),
          hasStorybookRegistration: body.includes("window.storybook.Hooks = window.MailglassAdminHooks"),
          hasSocketConstructor: body.includes("LiveSocket") || body.includes("Phoenix.Socket")
        });
      }
    });

    const storyUrl = "/dev/storybook/quick_views/delivery?tab=playground&variation_id=northstar_normal";
    const storyResponse = await page.goto(storyUrl);
    expect(storyResponse?.status(), "the retained production Delivery story loads").toBe(200);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

    const previewIframe = page.locator('iframe[id*="playground-preview"]');
    await expect(previewIframe).toHaveCount(1);
    await expect(previewIframe).toBeVisible();
    const previewFrame = page.frames().find(frame =>
      frame !== page.mainFrame() && frame.url().includes("playground")
    );
    expect(previewFrame, "the Playground preview is a real child document").toBeTruthy();
    await expect(previewFrame.locator("[data-phx-main].phx-connected")).toBeVisible();
    const dialog = previewFrame.locator("#operator-quick-view");
    await expect(dialog).toBeVisible();
    const hookIsRegistered = await previewFrame.evaluate(() =>
      typeof window.storybook?.Hooks?.ModalFocusTrap?.mounted === "function" &&
      document.querySelector('#operator-quick-view[phx-hook="ModalFocusTrap"]') !== null
    );
    expect(hookIsRegistered, "the isolated iframe registers the shared production hook").toBe(true);
    const initialPreviewUrl = previewFrame.url();
    await focusTrapWrapsToLastControl(previewFrame, "#operator-quick-view");
    let previewEvidence = await documentProbe(previewFrame);
    expect(previewEvidence.focusinAdded.filter(id => id === "operator-quick-view")).toHaveLength(1);
    expect(previewEvidence.focusinRemoved.filter(id => id === "operator-quick-view")).toHaveLength(0);
    expect(previewEvidence.sockets.filter(socket => socket.path.includes("/live/websocket"))).toHaveLength(1);
    expect(previewEvidence.sockets[0].channelJoins).toBeGreaterThan(0);

    const keyboardToggle = page.getByRole("switch");
    await expect(keyboardToggle).toHaveCount(1);
    const initialKeyboardEnabled = (await dialog.getAttribute("phx-window-keydown")) === "detail_key";
    await keyboardToggle.click();
    const firstToggleExpected = initialKeyboardEnabled ? null : "detail_key";
    await expect.poll(() => dialog.getAttribute("phx-window-keydown")).toBe(firstToggleExpected);
    expect(previewFrame.url(), "an assign update patches the existing connected production preview")
      .toBe(initialPreviewUrl);
    await focusTrapWrapsToLastControl(previewFrame, "#operator-quick-view");
    previewEvidence = await documentProbe(previewFrame);
    expect(previewEvidence.focusinAdded.filter(id => id === "operator-quick-view")).toHaveLength(1);
    expect(previewEvidence.focusinRemoved.filter(id => id === "operator-quick-view")).toHaveLength(0);
    await keyboardToggle.click();
    await expect.poll(() => dialog.getAttribute("phx-window-keydown"))
      .toBe(initialKeyboardEnabled ? "detail_key" : null);
    const mainDocumentProbe = await documentProbe(page.mainFrame());
    expect(mainDocumentProbe.sockets[0]?.events["playground-toggle"] || 0).toBeGreaterThan(0);

    const priorPreview = previewFrame;
    let previewDetached = false;
    page.on("framedetached", detached => {
      if (detached === priorPreview) previewDetached = true;
    });
    const primitivesFolder = page.locator('#psb-sidebar div[phx-value-path="/dev/storybook/primitives"]');
    const themePicker = page.locator('#psb-sidebar-container a[href="/dev/storybook/primitives/theme_picker"]');
    if (!(await themePicker.isVisible())) await primitivesFolder.click();
    await themePicker.click();
    await expect(page).toHaveURL(/\/dev\/storybook\/primitives\/theme_picker/);
    await expect(page.locator('iframe[id*="playground-preview"]')).toHaveCount(0);
    await expect.poll(() => previewDetached).toBe(true);
    const destructionReceipts = await page.evaluate(() =>
      window.__phase174Probe?.browsingContextReceipts || []
    );
    expect(
      destructionReceipts.some(receipt => receipt.activeFocusinAtPagehide <= 1),
      "removing the Storybook story destroys its dedicated preview browsing context"
    ).toBeTruthy();
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    const returnedStory = await page.goto(storyUrl);
    expect(returnedStory?.status()).toBe(200);
    const remountedIframe = page.locator('iframe[id*="playground-preview"]');
    await expect(remountedIframe).toHaveCount(1);
    const remountedFrame = page.frames().find(frame =>
      frame !== page.mainFrame() && frame.url().includes("playground")
    );
    expect(remountedFrame).toBeTruthy();
    await expect(remountedFrame.locator("[data-phx-main].phx-connected")).toBeVisible();
    await expect(remountedFrame.locator("#operator-quick-view")).toBeVisible();
    const remountedEvidence = await documentProbe(remountedFrame);
    expect(remountedEvidence.focusinAdded.filter(id => id === "operator-quick-view")).toHaveLength(1);
    expect(remountedEvidence.sockets.filter(socket => socket.path.includes("/live/websocket"))).toHaveLength(1);
    expect(remountedEvidence.sockets[0].channelJoins).toBeGreaterThan(0);

    const hooksSource = fs.readFileSync(hookSourcePath);
    const sourceMd5 = crypto.createHash("md5").update(hooksSource).digest("hex");
    expect(hookAssetResponses.length).toBeGreaterThan(0);
    expect(hookAssetResponses.every(response => response.status === 200)).toBe(true);
    expect(hookAssetResponses.every(response => response.url === "/dev/storybook-hooks-" + sourceMd5)).toBe(true);
    expect(hookAssetResponses.every(response => response.hasStorybookRegistration)).toBe(true);
    expect(hookAssetResponses.every(response => !response.hasSocketConstructor)).toBe(true);
    const documents = await readDocumentSet(page);
    expect(documents.every(document => !document.adminBootstrapPresent)).toBe(true);
    expect(networkWebSockets.filter(socket => socket.path.includes("/live/websocket")).length).toBeGreaterThanOrEqual(2);
    expect(documents.reduce((count, document) =>
      count + document.sockets.reduce((socketCount, socket) => socketCount + socket.channelJoins, 0), 0
    )).toBeGreaterThan(0);

    const demoLiveView = mixVersion(path.resolve(__dirname, "../../mix.lock"), "phoenix_live_view");
    const adminLiveView = mixVersion(path.resolve(__dirname, "../../../../mailglass_admin/mix.lock"), "phoenix_live_view");
    const storybookVersion = mixVersion(path.resolve(__dirname, "../../mix.lock"), "phoenix_storybook");
    const demoPlaywright = npmVersion(path.resolve(__dirname, "../package-lock.json"), "playwright");
    const adminPlaywright = npmVersion(path.resolve(__dirname, "../../../../mailglass_admin/package-lock.json"), "playwright");
    expect(demoLiveView).toBe("1.1.33");
    expect(adminLiveView).toBe("1.2.13");
    expect(storybookVersion).toBe("1.2.0");

    const demoCases = [];
    await loginTo(page, "/ops/mail?tenant_id=northstar&view=deliveries&provider=postmark&window_hours=168");
    await expect(page.evaluate(() => matchMedia("(prefers-reduced-motion: reduce)").matches)).resolves.toBe(true);
    const deliveryRows = page.getByTestId("operator-delivery-row").filter({ visible: true });
    await expect(deliveryRows.first()).toBeVisible();
    expect(await deliveryRows.count()).toBeGreaterThan(1);
    const openDeliveryAt = index => deliveryRows.nth(index).getByRole("button", { name: /Open delivery/ });
    const deliveryCloseCycles = [];

    async function runDeliveryCycle(index, closeWithEscape) {
      const opener = openDeliveryAt(index);
      const openerId = await opener.getAttribute("id");
      const initialId = await opener.getAttribute("phx-value-id");
      await opener.click();
      const quickView = page.getByTestId("operator-quick-view");
      await expect(quickView).toBeVisible();
      await expect(quickView).toHaveAttribute("aria-modal", "true");
      const openProbe = await documentProbe(page.mainFrame());
      expect(openProbe.focusinAdded.filter(id => id === "operator-quick-view").length -
        openProbe.focusinRemoved.filter(id => id === "operator-quick-view").length).toBe(1);
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
      const closedProbe = await documentProbe(page.mainFrame());
      const additions = closedProbe.focusinAdded.filter(id => id === "operator-quick-view").length;
      const removals = closedProbe.focusinRemoved.filter(id => id === "operator-quick-view").length;
      expect(removals).toBe(additions);
      demoCases.push({
        surface: "delivery",
        opened: initialId,
        navigatedTo: nextId,
        focusReturnedTo: openerId,
        focusinAdded: additions,
        focusinRemoved: removals,
        reducedMotion: true
      });
      deliveryCloseCycles.push(nextId);
    }

    await runDeliveryCycle(1, true);
    await runDeliveryCycle(1, false);
    const preReconnect = await documentProbe(page.mainFrame());
    const liveSocketCount = preReconnect.sockets.filter(socket => socket.path.includes("/live/websocket")).length;
    expect(liveSocketCount).toBe(1);
    const createdBeforeDrop = await page.evaluate(() => window.__phase174Probe.sockets.length);
    await page.evaluate(() => new Promise(resolve => window.liveSocket.disconnect(resolve)));
    await page.evaluate(() => window.liveSocket.connect());
    await expect.poll(async () => {
      const state = await documentProbe(page.mainFrame());
      return state.sockets.length;
    }).toBeGreaterThan(createdBeforeDrop);
    await expect.poll(async () => {
      const state = await documentProbe(page.mainFrame());
      return state.sockets.filter(socket =>
        socket.path.includes("/live/websocket") && socket.opened && !socket.closed
      ).length;
    }).toBe(1);
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    await runDeliveryCycle(0, true);

    await loginTo(page, "/ops/mail/inbound?tenant_id=northstar&provider=postmark&window_hours=168");
    const inboundRows = page.getByTestId("inbound-records-table").getByTestId("inbound-record-row").filter({ visible: true });
    await expect(inboundRows).toHaveCount(3);
    const inboundCloseCycles = [];

    async function runInboundCycle(index, closeWithEscape) {
      const row = inboundRows.nth(index);
      const opener = row.getByTestId("inbound-record-open");
      const openerId = await opener.getAttribute("id");
      const initialId = await opener.getAttribute("phx-value-id");
      await opener.click();
      const quickView = page.getByTestId("inbound-quick-view");
      await expect(quickView).toBeVisible();
      const openProbe = await documentProbe(page.mainFrame());
      expect(openProbe.focusinAdded.filter(id => id === "inbound-quick-view").length -
        openProbe.focusinRemoved.filter(id => id === "inbound-quick-view").length).toBe(1);
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
      const closedProbe = await documentProbe(page.mainFrame());
      const additions = closedProbe.focusinAdded.filter(id => id === "inbound-quick-view").length;
      const removals = closedProbe.focusinRemoved.filter(id => id === "inbound-quick-view").length;
      expect(removals).toBe(additions);
      demoCases.push({
        surface: "inbound",
        opened: initialId,
        navigatedTo: nextId,
        focusReturnedTo: matchingRowId,
        openerBeforeNavigation: openerId,
        focusinAdded: additions,
        focusinRemoved: removals,
        reducedMotion: true
      });
      inboundCloseCycles.push(nextId);
    }

    await runInboundCycle(1, false);
    await runInboundCycle(1, true);
    expect(deliveryCloseCycles).toHaveLength(3);
    expect(inboundCloseCycles).toHaveLength(2);

    const finalDocuments = await readDocumentSet(page);
    const evidence = {
      schema_version: "phase174-storybook-hooks.v1",
      proof_boundary: {
        static_story: "Storybook owns its preview iframe LiveView and proves shared hook registration, connected patch, trap wrap, and browsing-context removal.",
        real_routes: "Demo delivery and inbound routes own URL navigation, close, reduced-motion, and exact focus-return assertions.",
        admin_route_evidence: "The independently resolved Admin LiveView client is exercised by mailglass_admin/e2e/flows.spec.js.",
        reset: process.env.DEMO_EVIDENCE_RESET_TOKEN && process.env.DEMO_EVIDENCE_PROJECT_ID
          ? "authenticated reset endpoint used"
          : "reused the existing seeded local Demo host because its destructive reset token and run ID were not configured"
      },
      source: { path: "mailglass_admin/priv/static/hooks.js", md5: sourceMd5 },
      locked_versions: {
        demo_live_view: demoLiveView,
        admin_live_view: adminLiveView,
        phoenix_storybook: storybookVersion,
        demo_playwright: demoPlaywright,
        admin_playwright: adminPlaywright
      },
      storybook: {
        hook_asset_responses: hookAssetResponses,
        preview: {
          mounted: true,
          patched_assign: "keyboard? toggled twice through the native Playground switch from its scenario default",
          focus_trap_after_patch: "start sentinel moved focus to the final tabbable control",
          removed: { iframe_detached: previewDetached, browsing_context_receipts: destructionReceipts },
          remounted_listener_count: remountedEvidence.focusinAdded.filter(id => id === "operator-quick-view").length
        },
        documents: documents.map(document => ({
          url: document.url,
          socket_count: document.sockets.filter(socket => socket.path.includes("/live/websocket")).length,
          channel_join_count: document.sockets.reduce((sum, socket) => sum + socket.channelJoins, 0),
          admin_bootstrap_present: document.adminBootstrapPresent,
          script_urls: document.scripts
        }))
      },
      browser_websockets: networkWebSockets,
      demo_route_cases: demoCases,
      final_documents: finalDocuments.map(document => ({
        url: document.url,
        sockets: document.sockets,
        focusin_added: document.focusinAdded,
        focusin_removed: document.focusinRemoved,
        admin_bootstrap_present: document.adminBootstrapPresent,
        script_urls: document.scripts
      }))
    };
    fs.mkdirSync(path.dirname(evidencePath), { recursive: true });
    fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + "\n");
  });
});
