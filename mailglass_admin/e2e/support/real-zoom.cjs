// Real browser zoom for Operator Browser Gate cases (Phase 178, UIQ-06 / D-10).
//
// "Real" means Chromium tab zoom: a persistent context loads the repository's
// two-file test extension (support/browser-zoom-extension) and its service
// worker sets the active tab to a 2x zoom factor. CSS zoom, transform scale and
// devicePixelRatio overrides never qualify, so nothing in this file uses them.
//
// Chromium tab zoom is per origin and survives same-origin navigation, so one
// context can log in, zoom once and then visit many routes at 320 CSS px.

const path = require("node:path");
const { chromium, expect } = require("@playwright/test");

const extensionPath = path.resolve(__dirname, "browser-zoom-extension");
const ZOOM_FACTOR = 2;
const TARGET_CSS_WIDTH = 320;

class RealZoomError extends Error {
  constructor(message) {
    super(message);
    this.name = "RealZoomError";
  }
}

const defaultBaseURL = () =>
  process.env.OPERATOR_BASE_URL || `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

// Headless Chromium with the zoom extension. The viewport is the pre-zoom
// window; applyRealZoom() narrows it so the effective width is 320 CSS px.
async function launchRealZoomContext({ viewport = { width: 1440, height: 900 }, baseURL } = {}) {
  return chromium.launchPersistentContext("", {
    channel: "chromium",
    headless: true,
    viewport,
    deviceScaleFactor: 2,
    baseURL: baseURL || defaultBaseURL(),
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`]
  });
}

async function measureEffective(page) {
  return page.evaluate(() => ({
    devicePixelRatio: window.devicePixelRatio,
    innerWidth: window.innerWidth,
    documentWidth: document.documentElement.scrollWidth
  }));
}

// Applies actual 200% tab zoom to the page's tab, then resizes the window so
// the page sees 320 CSS px. Returns the receipt
// { tabZoom, initial: { devicePixelRatio, innerWidth }, effective: { devicePixelRatio, innerWidth, documentWidth } }.
async function applyRealZoom(context, page) {
  const initial = await page.evaluate(() => ({
    devicePixelRatio: window.devicePixelRatio,
    innerWidth: window.innerWidth
  }));

  const serviceWorker =
    context.serviceWorkers()[0] ||
    (await context.waitForEvent("serviceworker", { timeout: 10_000 }).catch(() => null));
  if (!serviceWorker) {
    throw new RealZoomError("The browser zoom extension service worker is unavailable");
  }

  const tabZoom = await serviceWorker.evaluate(async factor => {
    const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
    if (!tab?.id) return { error: "The active Chromium tab is unavailable" };
    await chrome.tabs.setZoom(tab.id, factor);
    return { tabId: tab.id, factor: await chrome.tabs.getZoom(tab.id) };
  }, ZOOM_FACTOR);
  if (tabZoom.error) throw new RealZoomError(tabZoom.error);
  expect(tabZoom.factor, "the browser applies real 200% tab zoom").toBe(ZOOM_FACTOR);

  await expect
    .poll(() => page.evaluate(() => window.innerWidth), { message: "tab zoom halves the CSS viewport" })
    .toBe(initial.innerWidth / ZOOM_FACTOR);

  const height = page.viewportSize()?.height || 900;
  await page.setViewportSize({ width: TARGET_CSS_WIDTH * ZOOM_FACTOR, height });
  await expect
    .poll(() => page.evaluate(() => window.innerWidth), { message: "viewport reaches 320 CSS px" })
    .toBe(TARGET_CSS_WIDTH);

  const effective = await measureEffective(page);
  return { tabZoom: tabZoom.factor, initial, effective };
}

// Interactive targets inside rootSelector that render smaller than 44x44 CSS px.
// Visible means a non-empty box that is not visibility:hidden; a natively
// disabled button still counts because it is still a target a person sees.
// `exempt` is an optional selector for targets with a smaller documented
// minimum (the Health field-help trigger is held to 24x24 elsewhere).
async function undersizedTargets(page, rootSelector, { exempt } = {}) {
  return page.evaluate(({ selector, exempt }) => {
    const root = document.querySelector(selector);
    if (!root) return [{ testid: `missing root ${selector}`, width: 0, height: 0 }];
    return [...root.querySelectorAll("a[href], button, input:not([type=hidden]), select, textarea, summary, [role=button]")]
      .filter(element => {
        const rect = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        return (
          rect.width > 0 &&
          rect.height > 0 &&
          style.visibility !== "hidden" &&
          !element.closest("[hidden], .sr-only") &&
          !(exempt && element.closest(exempt))
        );
      })
      .map(element => {
        const rect = element.getBoundingClientRect();
        return {
          testid: element.dataset.testid || element.id || element.getAttribute("aria-label") || element.tagName.toLowerCase(),
          width: Math.round(rect.width * 10) / 10,
          height: Math.round(rect.height * 10) / 10
        };
      })
      .filter(({ width, height }) => width < 43.5 || height < 43.5);
  }, { selector: rootSelector, exempt });
}

// Asserts the receipt proves actual 200% zoom at 320 CSS px and records it as
// a "real-zoom" annotation on the running test.
function recordReceipt(testInfo, receipt, label) {
  expect(receipt.tabZoom, `${label}: tab zoom factor`).toBe(ZOOM_FACTOR);
  expect(
    receipt.effective.devicePixelRatio / receipt.initial.devicePixelRatio,
    `${label}: actual zoom doubles the effective devicePixelRatio`
  ).toBe(ZOOM_FACTOR);
  expect(receipt.effective.innerWidth, `${label}: CSS viewport width`).toBe(TARGET_CSS_WIDTH);
  expect(receipt.effective.documentWidth, `${label}: no page-level horizontal overflow`).toBeLessThanOrEqual(
    TARGET_CSS_WIDTH
  );
  testInfo.annotations.push({
    type: "real-zoom",
    description: JSON.stringify({ case: label, ...receipt })
  });
}

module.exports = {
  RealZoomError,
  ZOOM_FACTOR,
  TARGET_CSS_WIDTH,
  launchRealZoomContext,
  applyRealZoom,
  measureEffective,
  recordReceipt,
  undersizedTargets
};
