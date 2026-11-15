const { test, expect } = require("@playwright/test");
const { openInTheme } = require("./support/theme.cjs");

// =============================================================================
// theme-ownership.spec.js — Phase 180 Plan 03, browser layer of BRPIPE-02.
//
// LANE: ADVISORY. This spec runs in the `operator_browser_gate` lane
// (config/quality/ci_policy.exs), which does not block merges. It is NOT the
// required proof of BRPIPE-02. The required, merge-blocking proof is
// `test/mailglass_admin/root_theme_ownership_contract_test.exs` in the
// `support_contract_admin` lane (document-level `data-theme` counts per surface
// and mode, a static scan of lib/, and mutation-proven detectors).
//
// What this spec adds on top: the computed result in a real browser. `<html>`
// is the only theme owner (D-11), so for every surface and every cookie x OS
// combination:
//
//   - `[...document.querySelectorAll("[data-theme]")]` is exactly [<html>] for an
//     explicit light/dark cookie and empty for System (no cookie);
//   - `--color-base-100` and `color-scheme` computed on the shell, the visible
//     Preview pane and the root-layout toast equal the values on <html>;
//   - base-100 luminance is high in the resolved-light theme and low in the
//     resolved-dark theme, compared against <html>'s own value (never a hex
//     literal), so a token swap in Phase 181 does not edit this file.
//
// Theme is a cookie (`mailglass_admin_theme_v2`) plus a full-page redirect, and
// System follows the emulated OS `prefers-color-scheme`. `emulateMedia` runs
// before navigation (see support/theme.cjs).
// =============================================================================

const PREVIEW_SHOW = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default";

const COOKIES = ["light", "dark", null];
const OS_SCHEMES = ["light", "dark"];

function cookieLabel(cookie) {
  return cookie === null ? "none" : cookie;
}

// The theme the page must resolve to: an explicit cookie wins, otherwise System
// follows the emulated OS preference.
function resolvedTheme(cookie, os) {
  return cookie === null ? os : cookie;
}

// Reads, in the page, everything the ownership contract talks about. Each target
// is a CSS selector; a target that does not match is reported as `null` so the
// assertion can name it instead of throwing inside evaluate().
async function probeTheme(page, targets) {
  return page.evaluate(selectors => {
    const css = (el, prop) => getComputedStyle(el).getPropertyValue(prop).trim();
    const html = document.documentElement;

    // Normalise whatever colour syntax the token resolves to (hex, rgb, oklch,
    // color()) through a 1x1 canvas, so luminance never depends on the token
    // format. No hex literal is asserted anywhere.
    const toRgb = value => {
      const canvas = document.createElement("canvas");
      canvas.width = 1;
      canvas.height = 1;
      const ctx = canvas.getContext("2d", { willReadFrequently: true });
      ctx.clearRect(0, 0, 1, 1);
      ctx.fillStyle = "#000000";
      ctx.fillStyle = value;
      ctx.fillRect(0, 0, 1, 1);
      const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
      return { r, g, b, a };
    };
    const channel = v => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    };
    const luminance = ({ r, g, b }) =>
      0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);

    const read = el =>
      el === null
        ? null
        : { base100: css(el, "--color-base-100"), colorScheme: getComputedStyle(el).colorScheme };

    const htmlBase100 = css(html, "--color-base-100");
    const out = {
      themed: [...document.querySelectorAll("[data-theme]")].map(el => el.tagName.toLowerCase()),
      htmlAttribute: html.getAttribute("data-theme"),
      html: read(html),
      htmlLuminance: htmlBase100 === "" ? null : luminance(toRgb(htmlBase100)),
      targets: {}
    };
    for (const [name, selector] of Object.entries(selectors)) {
      out.targets[name] = read(document.querySelector(selector));
    }
    return out;
  }, targets);
}

// The ownership contract, asserted on one probe result.
function expectRootOwnsTheme(probe, { cookie, os }, label) {
  const resolved = resolvedTheme(cookie, os);

  expect(
    probe.themed,
    `${label}: elements carrying [data-theme] (explicit cookies leave exactly <html>, System leaves none)`
  ).toEqual(cookie === null ? [] : ["html"]);

  if (cookie === null) {
    expect(probe.htmlAttribute, `${label}: <html> has no data-theme in System mode`).toBeNull();
  } else {
    expect(probe.htmlAttribute, `${label}: <html> data-theme`).toBe(`mailglass-${cookie}`);
  }

  expect(probe.html.base100, `${label}: <html> resolves --color-base-100`).not.toBe("");
  expect(probe.htmlLuminance, `${label}: <html> base-100 luminance`).not.toBeNull();
  if (resolved === "light") {
    expect(probe.htmlLuminance, `${label}: resolved-light base-100 is light`).toBeGreaterThan(0.8);
  } else {
    expect(probe.htmlLuminance, `${label}: resolved-dark base-100 is dark`).toBeLessThan(0.2);
  }

  for (const [name, value] of Object.entries(probe.targets)) {
    expect(value, `${label}: ${name} is present in the document`).not.toBeNull();
    expect(value.base100, `${label}: ${name} --color-base-100 equals <html>`).toBe(probe.html.base100);
    expect(value.colorScheme, `${label}: ${name} color-scheme equals <html>`).toBe(probe.html.colorScheme);
  }
}

const PREVIEW_TARGETS = {
  "preview-shell": '[data-testid="preview-shell"]',
  "preview-pane": '[data-testid="preview-pane"]:not([hidden])',
  "#mg-copy-toast": "#mg-copy-toast"
};

test.describe("theme ownership: Preview show", () => {
  for (const cookie of COOKIES) {
    for (const os of OS_SCHEMES) {
      test(`preview show cookie=${cookieLabel(cookie)} os=${os}`, async ({ page }) => {
        await page.setViewportSize({ width: 1280, height: 900 });
        await openInTheme(page, PREVIEW_SHOW, { cookie, os });
        await expect(page.getByTestId("preview-shell")).toBeVisible();
        await expect(page.locator('[data-testid="preview-pane"]:not([hidden])')).toBeVisible();

        const probe = await probeTheme(page, PREVIEW_TARGETS);
        expectRootOwnsTheme(probe, { cookie, os }, `preview show cookie=${cookieLabel(cookie)} os=${os}`);
      });
    }
  }
});
