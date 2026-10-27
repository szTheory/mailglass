const { expect } = require("@playwright/test");

// Runs in the rendered story document. Unsupported paint must fail closed;
// this is a bounded solid-color check, not a replacement for the axe scan.
function renderedContrast(element) {
  const doc = element.ownerDocument;
  const view = doc.defaultView;
  const canvas = doc.createElement("canvas");
  canvas.width = canvas.height = 1;
  const context = canvas.getContext("2d", { willReadFrequently: true });
  const rgba = color => {
    context.clearRect(0, 0, 1, 1);
    context.fillStyle = color;
    context.fillRect(0, 0, 1, 1);
    const [r, g, b, a] = context.getImageData(0, 0, 1, 1).data;
    return [r / 255, g / 255, b / 255, a / 255];
  };
  const over = (front, back) => {
    const alpha = front[3] + back[3] * (1 - front[3]);
    return alpha === 0 ? [0, 0, 0, 0] : [
      ...front.slice(0, 3).map((value, i) =>
        (value * front[3] + back[i] * back[3] * (1 - front[3])) / alpha),
      alpha
    ];
  };
  let background = [0, 0, 0, 0];
  for (let node = element; node; node = node.parentElement) {
    const style = view.getComputedStyle(node);
    // daisyUI retains its noise URL even with the brand's --noise: 0.
    // The second image layer has zero size and paints no pixels.
    const unpaintedNoise = style.backgroundImage.startsWith("none, url(") &&
      style.backgroundSize === "auto, 0%";
    if ((style.backgroundImage !== "none" && !unpaintedNoise) || Number(style.opacity) !== 1 ||
        style.filter !== "none" || style.mixBlendMode !== "normal") {
      throw new Error("Supplemental contrast cannot decide complex paint");
    }
    background = over(background, rgba(style.backgroundColor));
    if (background[3] === 1) break;
  }
  if (background[3] !== 1) throw new Error("No opaque rendered background");
  const style = view.getComputedStyle(element);
  const foreground = over(rgba(style.color), background);
  const luminance = color => color.slice(0, 3).map(value =>
    value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
  ).reduce((sum, value, i) => sum + value * [0.2126, 0.7152, 0.0722][i], 0);
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  const size = parseFloat(style.fontSize);
  const large = size >= 24 || (size >= 56 / 3 && Number(style.fontWeight) >= 700);
  return { ratio: (values[0] + 0.05) / (values[1] + 0.05), minimum: large ? 3 : 4.5,
    font_size: size, font_weight: Number(style.fontWeight) };
}

async function verifyStoryAccessibility(page, frameSelector, findings) {
  const frame = page.frameLocator(frameSelector);
  const root = frame.locator('[data-theme-owner="quick-view-story"]');
  const dialog = root.locator('[role="dialog"]');
  await expect.poll(() => dialog.evaluate(element =>
    element.getAnimations().every(animation => animation.playState === "finished")
  )).toBe(true);
  const chrome = await root.evaluate(root => {
    const bounds = element => {
      const r = element.getBoundingClientRect();
      return { left: r.left, right: r.right, top: r.top, bottom: r.bottom, width: r.width, height: r.height };
    };
    const picker = root.querySelector('[data-testid="quick-view-review-theme"]');
    return {
      picker: bounds(picker), dialog: bounds(root.querySelector('[role="dialog"]')),
      viewport: root.ownerDocument.defaultView.innerWidth,
      targets: [...picker.querySelectorAll("label")].map(bounds)
    };
  });
  expect(chrome.picker.bottom, "review chrome does not obscure quick-view content").toBeLessThanOrEqual(chrome.dialog.top);
  expect(chrome.picker.left).toBeGreaterThanOrEqual(0);
  expect(chrome.picker.right).toBeLessThanOrEqual(chrome.viewport);
  for (const target of chrome.targets) {
    expect(target.width).toBeGreaterThanOrEqual(44);
    expect(target.height).toBeGreaterThanOrEqual(44);
    expect(target.left).toBeGreaterThanOrEqual(chrome.picker.left);
    expect(target.right).toBeLessThanOrEqual(chrome.picker.right);
  }

  const contrasts = [];
  for (const finding of findings.filter(item => item.rule_id === "color-contrast")) {
    for (const chain of finding.target) {
      if (chain.length !== 1) throw new Error("Unsupported contrast selector chain");
      const target = dialog.locator(chain[0]);
      await expect(target).toHaveCount(1);
      await target.scrollIntoViewIfNeeded();
      const contrast = await target.evaluate(renderedContrast);
      expect(contrast.ratio, `${chain[0]} rendered text contrast`).toBeGreaterThanOrEqual(contrast.minimum);
      contrasts.push({ target: chain[0], ...contrast });
    }
  }

  const controls = "a[href], button:not([disabled]), [tabindex]:not([tabindex='-1']):not([data-focus-trap])";
  const ends = await dialog.locator(controls).evaluateAll(elements => {
    const visible = elements.filter(element => element.getClientRects().length > 0 &&
      getComputedStyle(element).visibility !== "hidden");
    visible[0].focus();
    return { count: visible.length };
  });
  expect(ends.count).toBeGreaterThan(0);
  await page.keyboard.press("Shift+Tab");
  await expect.poll(() => dialog.locator(controls).evaluateAll(elements => {
    const visible = elements.filter(element => element.getClientRects().length > 0 &&
      getComputedStyle(element).visibility !== "hidden");
    return visible.at(-1) === document.activeElement;
  })).toBe(true);
  await page.keyboard.press("Tab");
  await expect.poll(() => dialog.locator(controls).evaluateAll(elements => {
    const visible = elements.filter(element => element.getClientRects().length > 0 &&
      getComputedStyle(element).visibility !== "hidden");
    return visible[0] === document.activeElement;
  })).toBe(true);
  return { chrome, contrasts, focus_wrap: { forward: true, backward: true, controls: ends.count } };
}

module.exports = { renderedContrast, verifyStoryAccessibility };
