const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const { visibleByTestId } = require("./support/account.cjs");

const tenantId = "browser-tenant";
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const INCLUDE = '[data-testid="operator-overview-health"]';
// The REQUIREMENTS landmark set (320/375/768/1280/1440) plus 390 and 1024.
const WIDTHS = [320, 375, 390, 768, 1024, 1280, 1440];
const COLUMN_CAP_PX = 42 * 16 + 1;

async function openHealth(page, { scenario = "phase177-health-all", theme = "light" } = {}) {
  await page.context().clearCookies();
  await page.emulateMedia({ colorScheme: theme });
  const reset = await page.request.get(
    `/ops/browser-reset${scenario === "default" ? "" : `?scenario=${scenario}`}`
  );
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}&theme=${theme}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
  await expect(page.getByTestId("operator-overview-health")).toBeVisible();
}

async function armFault(page, operation) {
  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const fault = await page.evaluate(
    async ({ csrfToken, operation }) => {
      const response = await fetch(
        `/ops/browser-mutate?action=arm-known-read-failure&operation=${operation}`,
        { method: "POST", headers: { "x-csrf-token": csrfToken }, redirect: "manual" }
      );
      return { status: response.status, body: await response.text() };
    },
    { csrfToken, operation }
  );
  expect(fault.status, fault.body).toBe(200);
}

// A stale panel: one reader fails on Refresh after an earlier success.
async function openStaleHealth(page) {
  await openHealth(page, { scenario: "phase169-health-partial" });
  await armFault(page, "orphan_backlog");
  await page.getByRole("button", { name: "Refresh health" }).click();
  await expect(page.getByTestId("operator-health-stale-orphan_backlog")).toBeVisible();
}

// An unavailable panel: the first Health read of a LiveView fails. Health reads
// are dropped on Deliveries, so the one-shot fault is consumed when Health is
// reopened from the Account scope nav.
async function openUnavailableHealth(page) {
  await openHealth(page, { scenario: "default" });
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
  await armFault(page, "failed_ingest");
  await visibleByTestId(page, "surface-nav-scope-items").getByRole("link", { name: "Health" }).click();
  await expect(page.getByTestId("operator-health-unavailable-failed_ingest")).toBeVisible();
}

// Geometry and text gates measured inside the page. Each part returns plain
// data so a failure names its numbers.
async function healthGates(page) {
  return page.evaluate(() => {
    const q = id => document.querySelector(`[data-testid="${id}"]`);
    const rect = el => el.getBoundingClientRect();
    const root = q("operator-overview-health");
    const layout = q("operator-health-layout");
    const column = q("operator-health-column");
    const obs = q("operator-health-observation");
    const status = q("operator-health-status");
    const activity = q("operator-health-activity");
    const verdict = status.firstElementChild;
    const verdictText = verdict.querySelector("h2").textContent.trim();
    const items = [...status.querySelectorAll("ul > li")];
    const notices = [
      ...status.querySelectorAll(
        'p[data-testid^="operator-health-stale-"], p[data-testid^="operator-health-unavailable-"]'
      )
    ];

    // G1: no horizontal overflow on the document.
    const overflow = document.documentElement.scrollWidth - document.documentElement.clientWidth;

    // G2: DOM order equals visual order. Each element follows its predecessor in
    // the DOM and starts below it (or in a later column).
    const seq = [obs, verdict, ...items, ...notices, activity];
    const orderFailures = [];
    for (let i = 0; i < seq.length - 1; i++) {
      const a = seq[i];
      const b = seq[i + 1];
      const follows = !!(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING);
      const ra = rect(a);
      const rb = rect(b);
      const placed = rb.top >= ra.bottom - 1 || rb.left >= ra.right - 1;
      if (!follows || !placed) orderFailures.push(`${i}->${i + 1} follows=${follows} placed=${placed}`);
    }

    // G3: period, timestamp and Refresh share one [role=group] ancestor.
    const ts = q("operator-health-last-checked");
    const btn = document.getElementById("operator-health-refresh");
    const win = q("operator-health-window");
    const grouped =
      obs.getAttribute("role") === "group" && obs.contains(win) && obs.contains(ts) && obs.contains(btn);
    const rt = rect(ts);
    const rb = rect(btn);
    const sameLine = rt.top < rb.bottom && rb.top < rt.bottom;
    const gap = sameLine ? rb.left - rt.right : Math.max(rb.top - rt.bottom, rt.top - rb.bottom);
    const cohesion = { grouped, sameLine, gap, ok: grouped && (sameLine ? gap <= 16 : gap <= 8) };

    // G4: every link and button is >= 44px tall; a field_help trigger is >= 24x24.
    const smallTargets = [];
    let targets = 0;
    let helpTargets = 0;
    for (const el of root.querySelectorAll("a, button")) {
      const r = rect(el);
      if (r.width === 0 && r.height === 0) continue;
      const label = el.getAttribute("data-testid") || el.id || el.textContent.trim().slice(0, 40);
      if (el.closest(".mg-field-help")) {
        helpTargets++;
        if (r.width < 24 || r.height < 24) smallTargets.push({ label, help: true, w: r.width, h: r.height });
      } else {
        targets++;
        if (r.height < 44) smallTargets.push({ label, help: false, w: r.width, h: r.height });
      }
    }

    // G6: verdict and stale cues are present as text (never colour alone).
    const staleNotices = notices.filter(n => n.getAttribute("data-testid").startsWith("operator-health-stale-"));
    const stalePanels = staleNotices.map(n => n.getAttribute("data-testid").replace("operator-health-stale-", ""));
    const staleRowPrefix = {
      failed_ingest: id => id === "operator-overview-health-failures",
      orphan_backlog: id => id === "operator-overview-health-orphans",
      delivery_activity: id => id.startsWith("operator-health-deliveries-"),
      inbound_activity: id => id.startsWith("operator-health-inbound-")
    };
    const staleRowsMissingCue = items
      .filter(li => stalePanels.some(p => staleRowPrefix[p](li.getAttribute("data-testid"))))
      .filter(li => !li.textContent.includes("Not refreshed"))
      .map(li => li.getAttribute("data-testid"));
    const staleNoticeText = staleNotices.every(n => /refreshed/.test(n.textContent));
    const textCues = {
      verdictText,
      stalePanels,
      staleRowsMissingCue,
      ok: verdictText.length > 0 && staleRowsMissingCue.length === 0 && staleNoticeText
    };

    return {
      viewport: window.innerWidth,
      containerWidth: rect(layout).width,
      columnWidth: rect(column).width,
      overflow,
      orderFailures,
      cohesion,
      smallTargets,
      targets,
      helpTargets,
      textCues
    };
  });
}

function expectGates(gates, label) {
  expect(gates.overflow, `${label}: document overflow`).toBeLessThanOrEqual(1);
  expect(gates.orderFailures, `${label}: DOM order equals visual order`).toEqual([]);
  expect(gates.cohesion, `${label}: period, timestamp and Refresh stay together`).toMatchObject({ ok: true });
  expect(gates.smallTargets, `${label}: target sizes`).toEqual([]);
  expect(gates.targets, `${label}: G4 saw link/button targets`).toBeGreaterThan(0);
  expect(gates.textCues, `${label}: text cues`).toMatchObject({ ok: true });
  expect(gates.columnWidth, `${label}: reading column cap`).toBeLessThanOrEqual(COLUMN_CAP_PX);
}

// WCAG relative-luminance contrast of an element's colour against the nearest
// opaque ancestor background. Colours go through a canvas pixel, so oklch() and
// color-mix() values are normalised to sRGB first.
async function contrastOf(locator) {
  return locator.evaluate(el => {
    const ctx = document.createElement("canvas").getContext("2d", { willReadFrequently: true });
    const px = color => {
      ctx.clearRect(0, 0, 1, 1);
      ctx.fillStyle = "#000";
      ctx.fillStyle = color;
      ctx.fillRect(0, 0, 1, 1);
      const d = ctx.getImageData(0, 0, 1, 1).data;
      return [d[0], d[1], d[2], d[3] / 255];
    };
    const lum = ([r, g, b]) => {
      const f = v => {
        v /= 255;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      };
      return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
    };
    const stack = [];
    for (let n = el.parentElement; n; n = n.parentElement) {
      const c = px(getComputedStyle(n).backgroundColor);
      if (c[3] > 0) stack.push(c);
      if (c[3] === 1) break;
    }
    let bg = [255, 255, 255];
    for (const c of stack.reverse()) bg = bg.map((v, i) => c[i] * c[3] + v * (1 - c[3]));
    const fg = px(getComputedStyle(el).color);
    const l1 = lum(fg);
    const l2 = lum(bg);
    return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
  });
}

test.describe("Phase 177 Health", () => {
  test("Phase 177 tracer: all-eight Health stays in bounds and links land", async ({ page }) => {
    await openHealth(page);

    // The scenario seeds every issue category: eight rows.
    const rows = page
      .getByTestId("operator-overview-health")
      .locator('li[data-testid^="operator-health-"], li[data-testid^="operator-overview-health-"]');
    await expect(rows).toHaveCount(8);

    for (const width of [320, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      const gates = await healthGates(page);
      expect(gates.overflow, `document overflow at ${width}px`).toBeLessThanOrEqual(1);
      expect(gates.smallTargets, `small targets at ${width}px`).toEqual([]);
    }

    // One deep link, end to end: Failed deliveries lands on the failed filter
    // with exactly the one failed Delivery the scenario seeded.
    await page.getByTestId("operator-health-deliveries-failed-link").click();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true })).toHaveCount(1);
  });

  test("Phase 177 Health gates hold at every width", async ({ page }) => {
    test.setTimeout(120_000);
    const states = [
      { label: "all-eight", open: () => openHealth(page) },
      { label: "default", open: () => openHealth(page, { scenario: "default" }) },
      { label: "phase169-health-partial", open: () => openHealth(page, { scenario: "phase169-health-partial" }) },
      { label: "stale orphan_backlog", open: () => openStaleHealth(page) },
      { label: "armed failed_ingest fault", open: () => openUnavailableHealth(page) }
    ];

    for (const state of states) {
      await page.setViewportSize({ width: 1280, height: 900 });
      await state.open();
      for (const width of WIDTHS) {
        await page.setViewportSize({ width, height: 900 });
        const gates = await healthGates(page);
        expect(gates.viewport).toBe(width);
        expectGates(gates, `${state.label} at ${width}px`);
      }
    }
  });

  test("Phase 177 Health axe", async ({ page }, testInfo) => {
    test.setTimeout(120_000);

    async function scan(label) {
      // G7 is non-vacuous: a zero-match include would scan nothing.
      const matched = await page.locator(INCLUDE).count();
      expect(matched, `${label}: include selector matched`).toBeGreaterThanOrEqual(1);
      const results = await new AxeBuilder({ page }).include(INCLUDE).withTags(WCAG_TAGS).analyze();
      const incompleteIds = results.incomplete.map(item => item.id);
      testInfo.annotations.push({
        type: `axe ${label}`,
        description: JSON.stringify({
          matched,
          violations: results.violations.length,
          incomplete: results.incomplete.length,
          incompleteIds
        })
      });
      expect(
        results.violations.map(v => `${v.id}: ${v.nodes.map(n => n.target.join(" ")).join(" | ")}`),
        `${label}: axe violations`
      ).toEqual([]);

      // Incomplete findings are triaged, never reported as a pass. The one known
      // item is axe being unable to resolve the daisyUI button background behind
      // the "Refresh health" label; it is resolved by a computed contrast check.
      for (const item of results.incomplete) {
        expect(item.id, `${label}: unexpected incomplete rule`).toBe("color-contrast");
        for (const node of item.nodes) {
          expect(node.target.join(" "), `${label}: unexpected incomplete node`).toContain("phx-click-loading");
        }
      }
      if (results.incomplete.length > 0) {
        const contrast = await contrastOf(
          page.locator("#operator-health-refresh").locator(":scope > span.grid > span").first()
        );
        testInfo.annotations.push({
          type: `axe ${label} triage`,
          description: `color-contrast incomplete on the Refresh label resolved by computed check: ${contrast.toFixed(2)}:1 (>= 4.5)`
        });
        expect(contrast, `${label}: Refresh label contrast`).toBeGreaterThanOrEqual(4.5);
      }
    }

    for (const theme of ["light", "dark"]) {
      await page.setViewportSize({ width: 1280, height: 900 });
      await openHealth(page, { theme });
      await scan(`all-eight ${theme}`);
    }

    await page.setViewportSize({ width: 1280, height: 900 });
    await openUnavailableHealth(page);
    await scan("armed failed_ingest fault");
  });

  test("Phase 177 every Health issue link lands on its count", async ({ page }) => {
    test.setTimeout(180_000);
    await page.setViewportSize({ width: 1280, height: 900 });

    // testid -> where its link lands and how that destination shows a count.
    const rows = [
      { testid: "operator-health-deliveries-failed", kind: "deliveries" },
      { testid: "operator-health-deliveries-bounced", kind: "deliveries" },
      { testid: "operator-health-deliveries-rejected", kind: "deliveries" },
      { testid: "operator-health-deliveries-deferred", kind: "deliveries" },
      { testid: "operator-health-inbound-failed", kind: "inbound" },
      { testid: "operator-health-inbound-no_match", kind: "inbound" },
      { testid: "operator-overview-health-failures", kind: "card", card: "support-card-failed-ingest-tier1" },
      { testid: "operator-overview-health-orphans", kind: "card", card: "support-card-orphan-backlog-tier1" }
    ];

    for (const [index, row] of rows.entries()) {
      await openHealth(page);
      const count = Number((await page.getByTestId(`${row.testid}-count`).innerText()).trim());
      // The scenario seeds counts 1..8 in this fixed order, all below the page size.
      expect(count, `${row.testid} count`).toBe(index + 1);

      await page.getByTestId(`${row.testid}-link`).click();
      if (row.kind === "deliveries") {
        await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
        await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }), row.testid).toHaveCount(count);
      } else if (row.kind === "inbound") {
        await expect(page.getByRole("heading", { name: "Inbound records", level: 1 })).toBeVisible();
        await expect(page.getByTestId("inbound-record-row").filter({ visible: true }), row.testid).toHaveCount(count);
      } else {
        const card = page.getByTestId(row.card);
        await expect(card, row.testid).toBeVisible();
        expect(Number((await card.innerText()).match(/\d+/)[0]), `${row.testid} destination count`).toBe(count);
      }
    }
  });

  test("Phase 177 Refresh keeps focus and width", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openHealth(page);

    const button = page.locator("#operator-health-refresh");
    const checkedStamp = () =>
      page.getByTestId("operator-health-last-checked").getByRole("button").getAttribute("aria-label");
    const idleWidth = (await button.boundingBox()).width;

    // LiveView puts phx-click-loading on the clicked element while the event is in
    // flight; apply it by hand to measure the "Refreshing…" label deterministically.
    const loadingWidth = await button.evaluate(el => {
      el.classList.add("phx-click-loading");
      const width = el.getBoundingClientRect().width;
      el.classList.remove("phx-click-loading");
      return width;
    });
    expect(Math.abs(loadingWidth - idleWidth), "Refresh width while loading").toBeLessThanOrEqual(1);

    const before = await checkedStamp();
    await button.click();
    // The retry patch re-renders the timestamp; focus must survive it.
    await expect.poll(checkedStamp).not.toBe(before);
    expect(await page.evaluate(() => document.activeElement && document.activeElement.id)).toBe(
      "operator-health-refresh"
    );
    const afterWidth = (await button.boundingBox()).width;
    expect(Math.abs(afterWidth - idleWidth), "Refresh width after the patch").toBeLessThanOrEqual(1);
  });

  test("Phase 177 Health real-width parity", async ({ page }, testInfo) => {
    await page.setViewportSize({ width: 768, height: 900 });
    await openHealth(page);

    const gates = await healthGates(page);
    // The container width is measured on the real route (sidebar and padding
    // included), never compared with a predicted value.
    expect(Number.isFinite(gates.containerWidth)).toBe(true);
    expect(gates.containerWidth).toBeGreaterThan(0);
    testInfo.annotations.push({
      type: "health container width at viewport 768",
      description: String(gates.containerWidth)
    });
    expect(gates.viewport).toBe(768);
    expectGates(gates, `real width ${gates.containerWidth}px`);
  });

  test("Phase 177 Health long counts widen only their own cell", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await openHealth(page);

    const counts = page.locator('[data-testid="operator-overview-health"] [data-testid$="-count"]');
    await expect(counts).toHaveCount(8);
    const widths = () => counts.evaluateAll(els => els.map(el => el.getBoundingClientRect().width));
    const before = await widths();

    const widened = 2;
    await counts.nth(widened).evaluate(el => {
      el.textContent = "123,456";
    });
    const after = await widths();
    after.forEach((width, index) => {
      if (index === widened) expect(width, "widened count cell").toBeGreaterThan(before[index]);
      else expect(Math.abs(width - before[index]), `count cell ${index}`).toBeLessThanOrEqual(0.5);
    });
    const gates = await healthGates(page);
    expect(gates.overflow, "document overflow with a six-digit count at 320px").toBeLessThanOrEqual(1);
  });

  test("Phase 177 Health per-issue help is visually subordinate", async ({ page }) => {
    test.setTimeout(90_000);
    for (const theme of ["light", "dark"]) {
      await page.setViewportSize({ width: 1280, height: 900 });
      await openHealth(page, { theme });

      const rows = page.locator('[data-testid="operator-health-status"] ul > li');
      await expect(rows).toHaveCount(8);

      for (let index = 0; index < 8; index++) {
        const row = rows.nth(index);
        // Exactly one help trigger per issue row.
        await expect(row.locator(".mg-field-help button"), `row ${index} help triggers (${theme})`).toHaveCount(1);

        const facts = await row.evaluate(li => {
          const link = li.querySelector("a");
          const button = li.querySelector(".mg-field-help button");
          const glyph = button.firstElementChild;
          const linkStyle = getComputedStyle(link);
          const glyphStyle = getComputedStyle(glyph);
          const linkRect = link.getBoundingClientRect();
          const glyphRect = glyph.getBoundingClientRect();
          return {
            glyphHeight: glyphRect.height,
            glyphWidth: glyphRect.width,
            linkWidth: linkRect.width,
            helpColor: getComputedStyle(button).color,
            linkColor: linkStyle.color,
            glyphDecoration: glyphStyle.textDecorationLine,
            linkDecoration: linkStyle.textDecorationLine
          };
        });
        const where = `row ${index} (${theme})`;
        expect(facts.glyphHeight, `${where}: glyph height`).toBeLessThanOrEqual(16);
        expect(facts.glyphWidth, `${where}: glyph narrower than the label link`).toBeLessThan(facts.linkWidth);
        expect(facts.helpColor, `${where}: help colour differs from the link`).not.toBe(facts.linkColor);
        expect(facts.glyphDecoration, `${where}: glyph underline`).toBe("none");
        expect(facts.linkDecoration, `${where}: link underline`).toContain("underline");

        // WCAG 1.4.11: tertiary never means invisible.
        const contrast = await contrastOf(row.locator(".mg-field-help button").first().locator(":scope > *").first());
        expect(contrast, `${where}: help glyph contrast`).toBeGreaterThanOrEqual(3);
      }
    }
  });
});
