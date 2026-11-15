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
//     Preview pane, the open Quick view dialog and the root-layout toast equal
//     the values on <html>;
//   - base-100 luminance is high in the resolved-light theme and low in the
//     resolved-dark theme, compared against <html>'s own value (never a hex
//     literal), so a token swap in Phase 181 does not edit this file.
//
// Theme is a cookie (`mailglass_admin_theme_v2`) plus a full-page redirect, and
// System follows the emulated OS `prefers-color-scheme`. `emulateMedia` runs
// before navigation (see support/theme.cjs).
//
// Beyond the matrix: the real theme picker round trip, a push_patch and the
// Preview frame control, the no-JavaScript first response, iframe isolation,
// forced colours, a back-navigation probe, and a pixel check of the Preview
// frame backdrop. Tests tagged @smoke180 are the per-task subset.
// =============================================================================

const TENANT = "browser-tenant";
const PREVIEW_INDEX = "/dev/mail";
const PREVIEW_SHOW = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default";
const OPERATOR_LIST = `/ops/mail?tenant_id=${TENANT}&view=deliveries`;
const GALLERY = "/dev/mail/gallery";
const THEME_COOKIE_NAME = "mailglass_admin_theme_v2";

const COOKIES = ["light", "dark", null];
const OS_SCHEMES = ["light", "dark"];
const SMOKE = { tag: "@smoke180" };

function cookieLabel(cookie) {
  return cookie === null ? "none" : cookie;
}

function modeLabel({ cookie, os }) {
  return `cookie=${cookieLabel(cookie)} os=${os}`;
}

// The theme the page must resolve to: an explicit cookie wins, otherwise System
// follows the emulated OS preference.
function resolvedTheme(cookie, os) {
  return cookie === null ? os : cookie;
}

// Login clears every cookie, so the theme cookie is always set after it
// (openInTheme does that). Mirrors loginOperator in flows.spec.js.
async function loginOperator(page, returnTo = `/ops/mail?tenant_id=${TENANT}`) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  const params = new URLSearchParams({
    tenant_id: TENANT,
    return_to: returnTo,
    subject_id: "operator-1"
  });
  await page.goto(`/ops/browser-login?${params.toString()}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
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

const TOAST = { "#mg-copy-toast": "#mg-copy-toast" };

const PREVIEW_TARGETS = {
  "preview-shell": '[data-testid="preview-shell"]',
  "preview-pane": '[data-testid="preview-pane"]:not([hidden])',
  ...TOAST
};

// -----------------------------------------------------------------------------
// The cookie x OS matrix, one entry per surface. `smoke` names the single
// iteration that carries @smoke180 (a surface's other iterations run in the full
// file at the phase gate).
// -----------------------------------------------------------------------------

const SURFACES = [
  {
    name: "preview show",
    targets: PREVIEW_TARGETS,
    async open(page, mode) {
      await openInTheme(page, PREVIEW_SHOW, mode);
      await expect(page.getByTestId("preview-shell")).toBeVisible();
      await expect(page.locator('[data-testid="preview-pane"]:not([hidden])')).toBeVisible();
    }
  },
  {
    name: "preview index",
    smoke: { cookie: "dark", os: "dark" },
    targets: PREVIEW_TARGETS,
    async open(page, mode) {
      await openInTheme(page, PREVIEW_INDEX, mode);
      // The index redirects into the unified scenario layout.
      await expect(page).toHaveURL(/\/dev\/mail\/MailglassAdmin\.Fixtures\.HappyMailer\/welcome_default/);
      await expect(page.getByTestId("preview-shell")).toBeVisible();
      await expect(page.locator('[data-testid="preview-pane"]:not([hidden])')).toBeVisible();
    }
  },
  {
    name: "operator list",
    targets: { "operator-shell": '[data-testid="operator-shell"]', ...TOAST },
    async open(page, mode) {
      await loginOperator(page);
      await openInTheme(page, OPERATOR_LIST, mode);
      await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    }
  },
  {
    name: "operator detail with quick view",
    smoke: { cookie: "light", os: "light" },
    targets: {
      "operator-shell": '[data-testid="operator-shell"]',
      "operator-quick-view": '[data-testid="operator-quick-view"]',
      ...TOAST
    },
    async open(page, mode) {
      await loginOperator(page);
      await openInTheme(page, OPERATOR_LIST, mode);
      await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
      await page.getByTestId("operator-delivery-row").filter({ visible: true }).first().click();
      await expect(page.getByTestId("operator-quick-view")).toBeVisible();
    }
  },
  {
    name: "gallery",
    smoke: { cookie: null, os: "dark" },
    targets: { "gallery specimen": '[data-testid="gallery-stat_card-neutral-system"]', ...TOAST },
    async open(page, mode) {
      await openInTheme(page, GALLERY, mode);
      await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
      await expect(page.getByTestId("gallery-stat_card-neutral-system")).toBeVisible();
    }
  }
];

for (const surface of SURFACES) {
  test.describe(`theme ownership: ${surface.name}`, () => {
    for (const cookie of COOKIES) {
      for (const os of OS_SCHEMES) {
        const mode = { cookie, os };
        const title = `${surface.name} ${modeLabel(mode)}`;
        const isSmoke =
          surface.smoke !== undefined && surface.smoke.cookie === cookie && surface.smoke.os === os;

        test(title, isSmoke ? SMOKE : {}, async ({ page }) => {
          await page.setViewportSize({ width: 1280, height: 900 });
          await surface.open(page, mode);
          const probe = await probeTheme(page, surface.targets);
          expectRootOwnsTheme(probe, mode, title);
        });
      }
    }
  });
}

// -----------------------------------------------------------------------------
// Controls: the real theme picker, push_patch, and the Preview frame control.
// -----------------------------------------------------------------------------

test.describe("theme ownership: controls", () => {
  test("theme picker round trip light -> dark -> system keeps <html> the only owner", SMOKE, async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const os = "light";
    await loginOperator(page);
    await openInTheme(page, OPERATOR_LIST, { cookie: null, os });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const operatorTargets = { "operator-shell": '[data-testid="operator-shell"]', ...TOAST };
    expectRootOwnsTheme(await probeTheme(page, operatorTargets), { cookie: null, os }, "picker start (System)");

    // Each radio click is a full redirect round trip through /theme/<segment>.
    const steps = [
      { radio: "Light", cookie: "light" },
      { radio: "Dark", cookie: "dark" },
      { radio: "System", cookie: null }
    ];
    for (const step of steps) {
      await page.getByRole("radio", { name: step.radio, exact: true }).click();
      if (step.cookie === null) {
        await expect(page.locator("html")).not.toHaveAttribute("data-theme", /mailglass-/);
      } else {
        await expect(page.locator("html")).toHaveAttribute("data-theme", `mailglass-${step.cookie}`);
      }
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      await expect(page.getByRole("radio", { name: step.radio, exact: true })).toBeChecked();
      expectRootOwnsTheme(
        await probeTheme(page, operatorTargets),
        { cookie: step.cookie, os },
        `picker after ${step.radio}`
      );
    }
  });

  test("preview push_patch and the frame backdrop control leave the single owner intact", SMOKE, async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const mode = { cookie: "dark", os: "light" };
    await openInTheme(page, PREVIEW_SHOW, mode);
    await expect(page.getByTestId("preview-shell")).toBeVisible();
    expectRootOwnsTheme(await probeTheme(page, PREVIEW_TARGETS), mode, "preview before push_patch");

    // push_patch: a scenario link patches the LiveView without a page load.
    await page.evaluate(() => {
      window.__themeOwnershipSameDocument = true;
    });
    await page.getByTestId("preview-email-menu-trigger").filter({ visible: true }).first().click();
    await page
      .getByTestId("preview-email-menu-option")
      .filter({ hasText: "welcome_enterprise", visible: true })
      .first()
      .click();
    await expect(page).toHaveURL(/welcome_enterprise/);
    await expect(page.locator('[data-testid="preview-pane"]:not([hidden])')).toBeVisible();
    expect(
      await page.evaluate(() => window.__themeOwnershipSameDocument === true),
      "the scenario switch was a push_patch (same document), not a page load"
    ).toBe(true);
    const afterPatch = await probeTheme(page, PREVIEW_TARGETS);
    expectRootOwnsTheme(afterPatch, mode, "preview after push_patch");

    // The frame backdrop control changes only preview-frame-backdrop.
    const backdropScheme = () =>
      page
        .getByTestId("preview-frame-backdrop")
        .evaluate(el => getComputedStyle(el).colorScheme);
    const before = await backdropScheme();
    await page.getByTestId("preview-frame-theme-toggle").click();
    await expect(page.getByTestId("preview-frame-theme-toggle")).toHaveAttribute("aria-pressed", "true");
    await expect.poll(backdropScheme, { message: "the backdrop wrapper color-scheme flips" }).not.toBe(before);
    const afterToggle = await probeTheme(page, PREVIEW_TARGETS);
    expectRootOwnsTheme(afterToggle, mode, "preview after frame toggle");
    expect(afterToggle.html, "frame control leaves <html> tokens unchanged").toEqual(afterPatch.html);
    expect(afterToggle.targets["preview-shell"], "frame control leaves the shell unchanged").toEqual(
      afterPatch.targets["preview-shell"]
    );
    expect(afterToggle.targets["preview-pane"], "frame control leaves the pane unchanged").toEqual(
      afterPatch.targets["preview-pane"]
    );
  });

  test("forced colours keep a visible outline on a focused theme picker control", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.emulateMedia({ forcedColors: "active" });
    await loginOperator(page);
    await openInTheme(page, OPERATOR_LIST, { cookie: null, os: "light" });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    // Reach the checked radio from the keyboard so :focus-visible applies.
    const radio = page.getByRole("radio", { name: "System", exact: true });
    await radio.focus();
    await page.keyboard.press("Shift+Tab");
    await page.keyboard.press("Tab");
    await expect(radio).toBeFocused();

    const outline = await radio.evaluate(input => {
      const wrapper = input.parentElement;
      return {
        forced: window.matchMedia("(forced-colors: active)").matches,
        wrapper: getComputedStyle(wrapper).outlineStyle,
        wrapperWidth: getComputedStyle(wrapper).outlineWidth,
        input: getComputedStyle(input).outlineStyle
      };
    });
    console.log(`[theme-ownership] forced-colors picker outline=${JSON.stringify(outline)}`);
    expect(outline.forced, "forced-colors emulation is active").toBe(true);
    // The ring is drawn as an outline on the segment (never box-shadow), which
    // forced-colors mode keeps.
    expect(outline.wrapper, "focused picker segment keeps an outline in forced colours").not.toBe("none");
    expect(Number.parseFloat(outline.wrapperWidth)).toBeGreaterThan(0);
  });

  // D-14 bfcache probe. Playwright launches Chromium with
  // --disable-back-forward-cache, so this exercises HTTP-cache restoration of
  // the old document on back-navigation, not the real bfcache.
  test("back navigation shows the cookie's theme, not the previous document's", SMOKE, async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await loginOperator(page);
    await openInTheme(page, OPERATOR_LIST, { cookie: "light", os: "light" });
    await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-light");

    await page.getByRole("radio", { name: "Dark", exact: true }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");

    await page.goto(PREVIEW_INDEX);
    await expect(page.getByTestId("preview-shell")).toBeVisible();
    await page.goBack();
    await expect(page.getByTestId("operator-shell")).toBeVisible();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "mailglass-dark");
  });
});

// -----------------------------------------------------------------------------
// First response and iframe isolation.
// -----------------------------------------------------------------------------

test.describe("theme ownership: first response and iframe", () => {
  test("without JavaScript the first response already carries the right <html> attribute", SMOKE, async ({
    browser,
    baseURL
  }) => {
    for (const cookie of ["dark", "light", null]) {
      const context = await browser.newContext({ baseURL, javaScriptEnabled: false });
      try {
        if (cookie !== null) {
          await context.addCookies([{ name: THEME_COOKIE_NAME, value: cookie, url: baseURL }]);
        }
        const page = await context.newPage();

        // Raw first response: the attribute is in the markup, written by the server.
        const raw = await page.request.get(PREVIEW_SHOW);
        expect(raw.ok(), `first response for cookie=${cookieLabel(cookie)}`).toBeTruthy();
        const htmlTag = (await raw.text()).match(/<html\b[^>]*>/i)?.[0] ?? "";
        expect(htmlTag, "the first response contains an <html> tag").not.toBe("");
        if (cookie === null) {
          expect(htmlTag, "System: no data-theme in the first response").not.toMatch(/\sdata-theme=/);
        } else {
          expect(htmlTag, `cookie=${cookie}: first response carries the attribute`).toContain(
            `data-theme="mailglass-${cookie}"`
          );
        }

        // Same answer from a document loaded with scripting disabled.
        await page.goto(PREVIEW_SHOW);
        // Scripting is really off: the LiveView never connects.
        await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(0);
        const attribute = await page.locator("html").getAttribute("data-theme");
        expect(attribute, `loaded document, cookie=${cookieLabel(cookie)}`).toBe(
          cookie === null ? null : `mailglass-${cookie}`
        );
        expect(
          await page.evaluate(() => [...document.querySelectorAll("[data-theme]")].map(el => el.tagName.toLowerCase()))
        ).toEqual(cookie === null ? [] : ["html"]);
      } finally {
        await context.close();
      }
    }
  });

  test("the email iframe document has no theme owner and does not inherit admin tokens", SMOKE, async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openInTheme(page, PREVIEW_SHOW, { cookie: "dark", os: "dark" });
    await expect(page.getByTestId("preview-frame-backdrop")).toBeVisible();

    const iframe = page.locator('iframe[title^="Email HTML preview"]');
    await expect(iframe).toBeVisible();
    // Isolation only: canvas colour is deliberately not asserted (Chrome and
    // Firefox propagate color-scheme into the frame, Safari does not).
    const inside = await iframe.contentFrame().locator("html").evaluate(root => ({
      location: root.ownerDocument.location.href,
      themed: root.ownerDocument.querySelectorAll("[data-theme]").length,
      rootAttribute: root.getAttribute("data-theme"),
      base100: getComputedStyle(root).getPropertyValue("--color-base-100")
    }));
    expect(inside.location, "the probe ran inside the srcdoc document, not the admin page").toBe("about:srcdoc");
    expect(inside.themed, "no [data-theme] element inside the iframe document").toBe(0);
    expect(inside.rootAttribute, "the iframe root carries no theme attribute").toBeNull();
    expect(inside.base100, "admin --color-base-100 does not cross into the iframe").toBe("");
  });
});

// -----------------------------------------------------------------------------
// Preview frame backdrop pixels (closes 180-02 deliverable D5 with a machine
// observation): the toggle paints Canvas under a color-scheme wrapper, and the
// result does not depend on the admin theme.
// -----------------------------------------------------------------------------

async function samplePadding(locator) {
  const png = await locator.screenshot({ animations: "disabled" });
  return locator.page().evaluate(async base64 => {
    const image = new Image();
    image.src = `data:image/png;base64,${base64}`;
    await image.decode();
    const canvas = document.createElement("canvas");
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    const ctx = canvas.getContext("2d", { willReadFrequently: true });
    ctx.drawImage(image, 0, 0);
    // Top edge, horizontally centred: inside the wrapper's p-sm padding and clear
    // of the rounded corners and the iframe.
    const [r, g, b] = ctx.getImageData(Math.floor(image.naturalWidth / 2), 2, 1, 1).data;
    const channel = v => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    };
    return { r, g, b, luminance: 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b) };
  }, png.toString("base64"));
}

test.describe("theme ownership: Preview frame backdrop pixels", () => {
  test("frame light paints a light stage and frame dark a dark stage, under either admin theme", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const observed = {};

    for (const adminTheme of ["light", "dark"]) {
      await openInTheme(page, PREVIEW_SHOW, { cookie: adminTheme, os: "light" });
      const backdrop = page.getByTestId("preview-frame-backdrop");
      await expect(backdrop).toBeVisible();
      await backdrop.scrollIntoViewIfNeeded();

      observed[`${adminTheme}/frame-light`] = await samplePadding(backdrop);

      await page.getByTestId("preview-frame-theme-toggle").click();
      await expect(page.getByTestId("preview-frame-theme-toggle")).toHaveAttribute("aria-pressed", "true");
      await expect(page.getByTestId("preview-pane")).toHaveAttribute("data-preview-frame-theme", "dark");
      await expect
        .poll(() => backdrop.evaluate(el => getComputedStyle(el).colorScheme))
        .toBe("dark");
      observed[`${adminTheme}/frame-dark`] = await samplePadding(backdrop);
    }
    console.log(`[theme-ownership] frame backdrop samples=${JSON.stringify(observed)}`);

    for (const adminTheme of ["light", "dark"]) {
      expect(
        observed[`${adminTheme}/frame-light`].luminance,
        `frame light stage is light under admin ${adminTheme}`
      ).toBeGreaterThan(0.9);
      expect(
        observed[`${adminTheme}/frame-dark`].luminance,
        `frame dark stage is dark under admin ${adminTheme}`
      ).toBeLessThan(0.05);
    }
    // Independent of the admin theme: identical pixels under admin light and admin dark.
    expect(observed["dark/frame-light"], "frame light is the same under either admin theme").toEqual(
      observed["light/frame-light"]
    );
    expect(observed["dark/frame-dark"], "frame dark is the same under either admin theme").toEqual(
      observed["light/frame-dark"]
    );
  });
});
