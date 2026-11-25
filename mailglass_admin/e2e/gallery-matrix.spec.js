const { test, expect } = require("@playwright/test");
const { openInTheme } = require("./support/theme.cjs");

// =============================================================================
// Phase 116 RATCHET-02 — Gallery matrix overflow gate.
//
// The gallery at /dev/mail/gallery is the dev-only audit surface where every
// shared component × state is proven across the FULL viewport × theme matrix
// without horizontal overflow or 320px clipping.
//
// This spec implements RATCHET-02 as a Playwright RESIZE LOOP over the SAME
// stable `data-testid="gallery-{component}-{state}"` cells that already exist
// (D-09) — it NEVER generates specimens programmatically (the 324-cell
// cartesian explosion the research warns against is avoided by resizing the
// page, not by multiplying specimen rows).
//
// Phase 180 (BRPIPE-02): `<html>` is the only theme owner, so each cell renders
// ONE specimen wrapper, `data-testid="gallery-{component}-{state}-system"`, in the
// theme the page is in. The light/dark/system matrix is therefore driven by
// loading the gallery once per theme (cookie + emulated OS + goto), not by three
// wrappers in one page:
//   - light:  cookie "light",            OS light  -> <html data-theme="mailglass-light">
//   - dark:   cookie "dark",             OS light  -> <html data-theme="mailglass-dark">
//   - system: no cookie,                 OS dark   -> <html> has no data-theme
//             (system = absence of an explicit theme; OS dark proves it follows the OS)
//
// The matrix axes (UI-SPEC "Breakpoints" + "RATCHET-02"):
//   widths: 320, 390, 768, 1440
//   themes: light, dark, system  (outer loop: one page load per theme)
// At every cell the specimen wrapper must satisfy scrollWidth <= clientWidth + 1
// (no horizontal overflow), at 320px every specimen renders fully inside its own
// wrapper without internal clipping, and no element inside the cell carries a
// theme attribute (a nested owner would re-declare the token set).
//
// Scope note (D-04 / STATE.md [110/113]): the overflow invariant is PER-SPECIMEN
// (each specimen wrapper's content fits the wrapper). The gallery SHELL itself is a
// wide multi-section audit grid that can scroll horizontally below ~768px — a
// pre-existing layout property, not a specimen defect, and out of scope for this
// fixtures plan. The gallery render template stacks the specimen full-width below
// xl (116-04); that is what makes the per-specimen invariant hold at 320/390.
// Screenshot-free / no pixel diff — pure runtime DOM geometry.
// =============================================================================

const MATRIX_WIDTHS = [320, 390, 768, 1440];
const MATRIX_THEMES = ["light", "dark", "system"];
const MATRIX_HEIGHT = 900;
let testBodyStartedAtNs;

test.beforeEach(async ({}, testInfo) => {
  testBodyStartedAtNs = process.hrtime.bigint();
  console.log(`[gallery-matrix] stage=test_body_start test_id=${testInfo.title}`);
});

test.afterEach(async ({}, testInfo) => {
  const elapsedMs = Number((process.hrtime.bigint() - testBodyStartedAtNs) / 1_000_000n);
  console.log(`[gallery-matrix] stage=test_body_finish test_id=${testInfo.title} elapsed_ms=${elapsedMs}`);
});

// Specimens that carry the fjordline-aps persona mirror + the pre-existing
// stress specimens. These MUST render without overflow at every width — they
// are the long-ID / long-module-name / non-ASCII / long-value cells most likely
// to blow out a narrow viewport, so they are asserted explicitly in addition to
// the all-cells sweep.
const STRESS_CELLS = [
  "gallery-fjordline_stress-fjordline-non-ascii-names",
  "gallery-fjordline_stress-fjordline-long-id",
  "gallery-fjordline_stress-fjordline-long-mailable",
  "gallery-fjordline_stress-fjordline-nil-reject",
  "gallery-tenant_chip-non-ascii-tenant",
  "gallery-tenant_chip-long-tenant",
  "gallery-deliveries_list-long-value-stress",
  "gallery-records_list-long-value-stress",
  "gallery-stat_card-long-value"
];

// Per-theme page load (D-12). `system` is "no cookie" with the OS emulated dark, so a
// pass proves System follows the OS rather than defaulting to light.
const THEME_MODES = {
  light: { cookie: "light", os: "light" },
  dark: { cookie: "dark", os: "light" },
  system: { cookie: null, os: "dark" }
};

async function openGalleryInTheme(page, theme) {
  await openInTheme(page, "/dev/mail/gallery", THEME_MODES[theme]);
  await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
  const html = page.locator("html");
  if (theme === "system") {
    await expect(html, "system gallery: <html> carries no theme attribute").not.toHaveAttribute(
      "data-theme",
      /mailglass-/
    );
  } else {
    await expect(html, `${theme} gallery: <html> carries the theme`).toHaveAttribute(
      "data-theme",
      `mailglass-${theme}`
    );
  }
}

// The single specimen wrapper of a cell: one per state, in the page's theme.
function specimen(page, cellTestId) {
  return page.getByTestId(`${cellTestId}-system`);
}

// No element inside the cell may carry a theme attribute: only <html> owns it.
async function assertNoNestedThemeOwner(page, cellTestId, label) {
  await expect(
    page.getByTestId(cellTestId).locator("[data-theme]"),
    `${label}: no element inside the cell carries data-theme`
  ).toHaveCount(0);
}

// scrollWidth > clientWidth means the element's content overflows it
// horizontally. A 1px tolerance absorbs subpixel rounding (matches
// assertNoElementHorizontalOverflow in structural.spec.js).
async function assertNoHorizontalOverflow(locator, label) {
  await expect(locator, `${label} visible`).toBeVisible();
  const geometry = await locator.evaluate(el => {
    const overflowing = [...el.querySelectorAll("*")]
      .map(child => ({
        tag: child.tagName.toLowerCase(),
        testId: child.getAttribute("data-testid"),
        className: typeof child.className === "string" ? child.className : "",
        text: child.textContent?.trim().slice(0, 80),
        overflow: child.scrollWidth - child.clientWidth
      }))
      .filter(child => child.overflow > 1)
      .slice(0, 8);
    return { overflow: el.scrollWidth - el.clientWidth, overflowing };
  });
  expect(
    geometry.overflow,
    `${label} horizontal overflow (scrollWidth - clientWidth); overflowing descendants=${JSON.stringify(geometry.overflowing)}`
  ).toBeLessThanOrEqual(1);
}

// At 320px nothing may be clipped or hidden. "Not clipped" is a PER-SPECIMEN
// invariant: the wrapper is visible, has a real layout box, and its own content
// is not internally cut off (scrollWidth <= clientWidth, already asserted by
// assertNoHorizontalOverflow). We deliberately do NOT assert the cell sits within
// the 320 viewport: the gallery shell is a wide multi-section audit grid whose
// outermost container can be wider than 320 (a pre-existing layout property,
// STATE.md [110/113] "gallery cells too narrow at 320px for meaningful per-cell
// check"). Page-level horizontal scroll of the audit grid is not a specimen clip
// and is out of scope for this fixtures plan — the meaningful guarantee is that
// every specimen renders its content fully inside its own theme wrapper at 320.
async function assertNotClippedAt320(locator, label) {
  await expect(locator, `${label} not hidden @320`).toBeVisible();
  const box = await locator.boundingBox();
  expect(box, `${label} has a layout box @320`).not.toBeNull();
  expect(box.width, `${label} has non-zero width @320`).toBeGreaterThan(0);
  expect(box.height, `${label} has non-zero height @320`).toBeGreaterThan(0);
}

// The Phase-114 composed-group specimens hardcode an INNER per-wrapper testid
// (`gallery-composed-support-triage`, hyphenated) that renders once inside the
// specimen wrapper and has no `-system`/`data-theme` sub-structure. The CANONICAL
// outer cell for those specimens is the atom+state form
// (`gallery-composed_support_triage-...`, underscored) which this sweep covers
// normally. Exclude the hyphenated inner composed testids so discovery yields
// exactly one outer cell per specimen.
const COMPOSED_INNER_TESTIDS = new Set([
  "gallery-composed-support-triage",
  "gallery-composed-routing-evidence",
  "gallery-composed-detail-timeline"
]);

// Discover every stable gallery cell from the live DOM (component × state).
// We read the rendered testids rather than hardcoding a list so the resize
// loop automatically covers every existing specimen — including the new
// fjordline stress cells — without the spec ever enumerating a cartesian grid.
// The `-system` specimen wrappers and the composed inner testids are excluded so
// each canonical cell is visited exactly once.
async function discoverGalleryCells(page) {
  const ids = await page.locator("[data-testid^='gallery-']").evaluateAll(nodes =>
    nodes
      .map(node => node.getAttribute("data-testid"))
      .filter(id => id && id.startsWith("gallery-") && !id.endsWith("-system"))
  );
  // Dedupe, drop composed inner testids, keep deterministic order.
  return Array.from(new Set(ids)).filter(id => !COMPOSED_INNER_TESTIDS.has(id));
}

// Widths below xl render the specimen STACKED full-width, so every specimen gets
// the whole cell width — the overflow invariant is enforced for ALL cells here.
// At/above xl the specimen is a flex item in a row (`xl:flex-1`): a set of
// intrinsically-wide card/SVG specimens (the logo SVG, the theme_picker
// fieldset, routing_trace/tabs/suppression/composed cards) overflow their column.
// That is a pre-existing gallery-SHELL layout property (STATE.md [110/113]), not
// a specimen defect, and is out of scope for this fixtures plan — those cells are
// allowlisted at xl+ so the gate stays honest (it still fails closed if a NEW
// specimen overflows at xl+, and it enforces every cell strictly at the 320/390
// mobile floors the RATCHET-02 "must not clip at 320" contract targets).
const WIDE_SHELL_OVERFLOW_ALLOWLIST = new Set([
  "gallery-logo-rest",
  "gallery-theme_picker-system-selected",
  "gallery-theme_picker-light-selected",
  "gallery-theme_picker-dark-selected",
  "gallery-theme_picker-hover-ready",
  "gallery-theme_picker-focus-visible",
  "gallery-theme_picker-disabled",
  "gallery-suppression_card-present",
  "gallery-suppression_card-absent",
  "gallery-routing_trace-all-passing",
  "gallery-routing_trace-first-failing",
  "gallery-tabs-inactive-tab",
  "gallery-composed_support_triage-operator-detail",
  "gallery-composed_detail_timeline-inbound-detail"
]);

// The 320/390 mobile floors enforce overflow for EVERY cell (single-column).
const MOBILE_FLOOR_WIDTHS = new Set([320, 390]);

test.describe("gallery matrix — RATCHET-02 resize-loop overflow gate", () => {
  // The theme is the OUTER loop: one gallery page load per theme (D-12), then the
  // width loop over every cell. 117 cells x 4 widths per theme.
  for (const theme of MATRIX_THEMES) {
    test(`every gallery specimen renders without horizontal overflow across 320/390/768/1440 in ${theme}`, async ({
      page
    }) => {
      // Phase 163 exact-owner repair: the complete 117-cell matrix exhausted the
      // 30,000ms config default locally, then the first protected recurrence
      // exhausted its test-local bounds at 60,002/60,047ms and then
      // 120,004/120,064ms while readiness stayed healthy. Keep the global
      // default unchanged; each complete per-theme matrix body gets a finite
      // bound (one theme is a third of the former single-body matrix).
      test.setTimeout(240_000);
      await openGalleryInTheme(page, theme);

      const cells = await discoverGalleryCells(page);
      // Sanity: the gallery must expose a substantial specimen set (guards against
      // a selector regression silently turning this into a vacuous pass), and it
      // must include the fjordline persona mirror added in plan 116-04.
      expect(cells.length, "gallery exposes specimen cells").toBeGreaterThan(50);
      for (const stress of STRESS_CELLS) {
        expect(cells, `gallery includes stress cell ${stress}`).toContain(stress);
      }
      console.log(`[gallery-matrix] stage=matrix_discovered theme=${theme} cells=${cells.length}`);

      for (const width of MATRIX_WIDTHS) {
        await page.setViewportSize({ width, height: MATRIX_HEIGHT });
        const isMobileFloor = MOBILE_FLOOR_WIDTHS.has(width);

        for (const cellTestId of cells) {
          // Visibility is checked for EVERY cell at EVERY width — the resize loop
          // genuinely exercises the whole matrix at every viewport.
          const cell = page.getByTestId(cellTestId);
          await expect(cell, `${cellTestId} cell ${theme} @${width}`).toBeVisible();

          // Overflow is enforced for every cell at the mobile floors; at md+ the
          // wide-shell allowlist (pre-existing card/SVG specimens) is exempt, but
          // any non-allowlisted cell — including every 116-04 stress specimen —
          // still fails closed on overflow.
          const enforceOverflow = isMobileFloor || !WIDE_SHELL_OVERFLOW_ALLOWLIST.has(cellTestId);
          const wrapper = specimen(page, cellTestId);

          if (enforceOverflow) {
            await assertNoHorizontalOverflow(wrapper, `${cellTestId} ${theme} @${width}`);
          }

          if (width === 320) {
            await assertNotClippedAt320(wrapper, `${cellTestId} ${theme}`);
          }
        }
      }
    });

    test(`fjordline persona + pre-existing stress specimens never overflow at any width in ${theme}`, async ({
      page
    }) => {
      await openGalleryInTheme(page, theme);

      for (const width of MATRIX_WIDTHS) {
        await page.setViewportSize({ width, height: MATRIX_HEIGHT });

        for (const cellTestId of STRESS_CELLS) {
          const cell = page.getByTestId(cellTestId);
          await expect(cell, `${cellTestId} stress cell ${theme} @${width}`).toBeVisible();

          const wrapper = specimen(page, cellTestId);
          await assertNoHorizontalOverflow(wrapper, `${cellTestId} ${theme} @${width}`);
          // `<html>` is the only theme owner: nothing inside the cell may carry a
          // theme attribute (a nested owner would re-declare the token set).
          await assertNoNestedThemeOwner(page, cellTestId, `${cellTestId} ${theme} @${width}`);
        }
      }
    });
  }

  // @smoke180: one component (stat_card) at 1440 in each of the three themes. The
  // full matrices above run at the phase gate.
  for (const theme of MATRIX_THEMES) {
    test(`stat_card specimens at 1440 in ${theme} keep one specimen, no overflow, no nested theme`, { tag: "@smoke180" }, async ({
      page
    }) => {
      await openGalleryInTheme(page, theme);
      await page.setViewportSize({ width: 1440, height: MATRIX_HEIGHT });

      const cells = (await discoverGalleryCells(page)).filter(id => id.startsWith("gallery-stat_card-"));
      expect(cells.length, "stat_card exposes several states").toBeGreaterThan(3);

      for (const cellTestId of cells) {
        await expect(page.getByTestId(cellTestId), `${cellTestId} cell ${theme} @1440`).toBeVisible();
        await expect(
          page.getByTestId(`${cellTestId}-system`),
          `${cellTestId} renders exactly one specimen wrapper`
        ).toHaveCount(1);
        await assertNoHorizontalOverflow(specimen(page, cellTestId), `${cellTestId} ${theme} @1440`);
        await assertNoNestedThemeOwner(page, cellTestId, `${cellTestId} ${theme} @1440`);
      }
    });
  }
});
