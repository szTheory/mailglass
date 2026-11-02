const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const {
  visibleByTestId,
  accountSwitcher,
  accountLabel,
  accountOption,
  accountSwitchStatus
} = require("./support/account.cjs");

const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

// "accounts" browser scenario seeds northstar and fjordline-aps; the session
// tenant is northstar and the URL selects the Account under test.
const accountId = "fjordline-aps";
const sessionTenantId = "northstar";
const widths = [320, 375, 768, 1280, 1440];

async function openHealth(page, tenant) {
  await page.context().clearCookies();
  const reset = await page.request.get("/ops/browser-reset?scenario=accounts");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenant}`);
  await page.goto(
    `/ops/browser-login?tenant_id=${sessionTenantId}&return_to=${returnTo}&subject_id=operator-1`
  );
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${tenant}`));
}

test.describe("Phase 177 Account scope", () => {
  test("Phase 177 tracer: Account header heads the scoped group", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openHealth(page, accountId);

    const group = visibleByTestId(page, "surface-nav-scope-group");
    await expect(group).toHaveCount(1);
    await expect(group).toHaveAttribute("data-account-scope", "");
    await expect(group).toHaveAttribute("role", "group");

    // The Account control is the group header and names the selected Account.
    await expect(group.getByTestId("operator-account-switcher")).toBeVisible();
    await expect(accountLabel(page)).toBeVisible();

    // The group's links are exactly Health, Deliveries and Inbound, in order.
    const scoped = group.getByTestId("surface-nav-scope-items").getByRole("link");
    await expect(scoped).toHaveText(["Health", "Deliveries", "Inbound"]);

    // Preview is outside the group, below it, with its caption.
    const preview = visibleByTestId(page, "surface-nav-preview-block");
    await expect(preview.getByRole("link", { name: "Preview", exact: true })).toBeVisible();
    await expect(visibleByTestId(page, "surface-nav-preview-caption")).toHaveText(
      "Not tied to an Account"
    );
    await expect(group.getByRole("link", { name: "Preview", exact: true })).toHaveCount(0);

    // The topbar carries only global controls.
    await expect(
      page.getByTestId("admin-shell-actions").locator('[data-testid^="operator-account"]')
    ).toHaveCount(0);

    // Order on the page: group above the Preview block.
    const groupBox = await group.boundingBox();
    const previewBox = await preview.boundingBox();
    expect(groupBox.y + groupBox.height).toBeLessThanOrEqual(previewBox.y + 1);

    await expect(accountSwitcher(page)).toHaveCount(1);
  });

  test("Phase 177 Account control stays visible at every width", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openHealth(page, accountId);

    for (const width of widths) {
      await page.setViewportSize({ width, height: 900 });

      const group = visibleByTestId(page, "surface-nav-scope-group");
      await expect(group, `one visible scope group at ${width}`).toHaveCount(1);

      const switcher = await accountSwitcher(page).boundingBox();
      expect(switcher, `Account switcher is rendered at ${width}`).not.toBeNull();
      expect(switcher.x, `left edge in viewport at ${width}`).toBeGreaterThanOrEqual(0);
      expect(switcher.x + switcher.width, `right edge in viewport at ${width}`).toBeLessThanOrEqual(
        width + 1
      );
      expect(switcher.y, `top in viewport at ${width}`).toBeGreaterThanOrEqual(0);
      expect(
        switcher.y + switcher.height,
        `Account header is above the fold at ${width}`
      ).toBeLessThanOrEqual(900);
      expect(switcher.height, `44px target at ${width}`).toBeGreaterThanOrEqual(43.99);

      // No horizontal page overflow from the chrome.
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth
      );
      expect(overflow, `horizontal overflow at ${width}`).toBeLessThanOrEqual(1);

      // Logo and the Appearance picker share one topbar row.
      const topbar = page.getByTestId("admin-shell-topbar");
      const logo = await topbar.locator('svg[aria-label="mailglass"]').boundingBox();
      const appearance = await topbar.getByRole("group", { name: "Appearance" }).boundingBox();
      // Compare vertical centers: the 24px logo and the 46px picker are
      // center-aligned, so their tops differ by half the height gap by design.
      expect(
        Math.abs(logo.y + logo.height / 2 - (appearance.y + appearance.height / 2)),
        `logo and Appearance picker share a row at ${width}`
      ).toBeLessThan(8);

      // Every scoped link and the Preview link is at least 44px tall.
      const links = group.getByTestId("surface-nav-scope-items").getByRole("link");
      await expect(links).toHaveCount(3);
      const preview = visibleByTestId(page, "surface-nav-preview-block").getByRole("link", {
        name: "Preview",
        exact: true
      });
      for (const link of [...(await links.all()), preview]) {
        const box = await link.boundingBox();
        expect(box.height, `link height at ${width}`).toBeGreaterThanOrEqual(43.99);
      }
    }

    // Preview keeps its Appearance picker in the topbar at 320 (Pitfall 10).
    await page.setViewportSize({ width: 320, height: 900 });
    await visibleByTestId(page, "surface-nav-preview-block")
      .getByRole("link", { name: "Preview", exact: true })
      .click();
    await expect(page).toHaveURL(/\/dev\/mail\//);
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const appearance = page
      .getByTestId("admin-shell-topbar")
      .getByRole("group", { name: "Appearance" });
    await expect(appearance).toBeVisible();
    const box = await appearance.boundingBox();
    expect(box.x + box.width).toBeLessThanOrEqual(321);
    await expect(page.locator('[data-testid^="operator-account"]').filter({ visible: true })).toHaveCount(0);
  });

  test("Phase 177 Account menu fits the band below md", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openHealth(page, accountId);

    for (const width of widths) {
      await page.setViewportSize({ width, height: 900 });

      const group = visibleByTestId(page, "surface-nav-scope-group");
      const switcher = accountSwitcher(page);
      await switcher.click();

      const menu = visibleByTestId(page, "surface-nav-scope-group").locator(
        'ul[aria-label="Available Accounts"]'
      );
      await expect(menu, `menu opens at ${width}`).toBeVisible();

      const menuBox = await menu.boundingBox();
      const groupBox = await group.boundingBox();
      const summaryBox = await switcher.boundingBox();

      expect(menuBox.x, `menu left edge in viewport at ${width}`).toBeGreaterThanOrEqual(-1);
      expect(menuBox.x + menuBox.width, `menu right edge in viewport at ${width}`).toBeLessThanOrEqual(
        width + 1
      );

      if (width < 768) {
        expect(
          Math.abs(menuBox.width - groupBox.width),
          `menu spans the group at ${width}`
        ).toBeLessThanOrEqual(2);
      } else {
        expect(
          Math.abs(menuBox.x - summaryBox.x),
          `menu aligns with the summary at ${width}`
        ).toBeLessThanOrEqual(2);
      }

      // Options are 44px targets and are not covered by anything else.
      const options = menu.getByTestId("operator-account-option");
      await expect(options).toHaveCount(2);
      for (const option of await options.all()) {
        const box = await option.boundingBox();
        expect(box.height, `option height at ${width}`).toBeGreaterThanOrEqual(43.99);
        const covered = await option.evaluate((el) => {
          const rect = el.getBoundingClientRect();
          const hit = document.elementFromPoint(rect.x + rect.width / 2, rect.y + rect.height / 2);
          return !hit || !el.contains(hit);
        });
        expect(covered, `option is not covered at ${width}`).toBe(false);
      }

      await switcher.click();
      await expect(menu).toBeHidden();
    }
  });

  // Opens Preview from Health with a valid return context (D-12) and waits for
  // the connected LiveView.
  async function openPreview(page, theme) {
    await openHealth(page, accountId);
    await visibleByTestId(page, "surface-nav-preview-block")
      .getByRole("link", { name: "Preview", exact: true })
      .click();
    await expect(page).toHaveURL(/\/dev\/mail\/[^?]+\?.*return_surface=overview/);
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    if (theme) {
      await page.goto(`${page.url()}&theme=${theme}`);
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    }
  }

  // Tab from the top of the document and describe every focus stop.
  async function tabStops(page, count) {
    await page.evaluate(() => {
      document.activeElement?.blur();
      window.scrollTo(0, 0);
    });
    const stops = [];
    for (let i = 0; i < count; i += 1) {
      await page.keyboard.press("Tab");
      stops.push(
        await page.evaluate(() => {
          const el = document.activeElement;
          const style = getComputedStyle(el);
          return {
            label: (el.getAttribute("aria-label") || el.textContent || "")
              .trim()
              .replace(/\s+/g, " "),
            testid: el.dataset.testid || null,
            inNav: Boolean(el.closest("nav")),
            inGroup: Boolean(el.closest("[data-account-scope]")),
            inTopbar: Boolean(el.closest('[data-testid="admin-shell-topbar"]')),
            outlineStyle: style.outlineStyle
          };
        })
      );
    }
    return stops;
  }

  test("Phase 177 scope group keyboard order", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openHealth(page, accountId);

    // Health, 2+ Accounts: the global Appearance control is first (topbar),
    // then the Account summary, the three scoped links and Preview, then page
    // content (D-13).
    const health = await tabStops(page, 8);
    expect(health[0].inTopbar, "the first stop is the global Appearance control").toBe(true);
    const healthNav = health.filter((stop) => stop.inNav);
    expect(healthNav.map((stop) => stop.testid || stop.label)).toEqual([
      "operator-account-switcher",
      "Health",
      "Deliveries",
      "Inbound",
      "Preview"
    ]);
    expect(healthNav[0].inGroup).toBe(true);
    expect(healthNav[4].inGroup, "Preview is outside the Account group").toBe(false);
    const previewIndex = health.findIndex((stop) => stop.inNav && stop.label === "Preview");
    expect(health[previewIndex + 1].inNav, "page content follows Preview").toBe(false);
    expect(health[previewIndex + 1].inTopbar).toBe(false);
    for (const stop of health) {
      expect(stop.outlineStyle, `${stop.label} shows a focus outline`).not.toBe("none");
    }

    // Preview with a valid context: Back link first, then the same group.
    await openPreview(page);
    const preview = await tabStops(page, 7);
    const previewNav = preview.filter((stop) => stop.inNav);
    expect(previewNav.map((stop) => stop.testid || stop.label)).toEqual([
      "preview-return-link",
      "Health",
      "Deliveries",
      "Inbound",
      "Preview"
    ]);
    const previewLast = preview.findIndex((stop) => stop.inNav && stop.label === "Preview");
    expect(preview[previewLast + 1].inNav, "page content follows Preview").toBe(false);
    for (const stop of preview) {
      expect(stop.outlineStyle, `${stop.label} shows a focus outline`).not.toBe("none");
    }
  });

  test("Phase 177 Preview shows no Account identity", async ({ page }) => {
    for (const width of [320, 1280]) {
      await page.setViewportSize({ width, height: 900 });
      await openPreview(page);

      await expect(
        page.locator('[data-testid^="operator-account"]').filter({ visible: true }),
        `no visible Account control at ${width}`
      ).toHaveCount(0);

      const label = visibleByTestId(page, "preview-scope-label");
      await expect(label).toHaveText("Scoped to an Account");
      expect(await label.getAttribute("tabindex"), "the scope label is not focusable").toBeNull();
      expect(await label.evaluate((el) => el.matches("a, button, summary, input, [tabindex]"))).toBe(
        false
      );
      await expect(visibleByTestId(page, "surface-nav-preview-caption")).toHaveText(
        "Not tied to an Account"
      );
      await expect(accountSwitcher(page)).toHaveCount(0);
    }
  });

  test("Phase 177 Account switch shows a polite status", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    let holdReply = false;
    let heldReply = null;
    let resolveHeld;
    let liveSocket = null;
    await page.routeWebSocket(/\/live\/websocket/, (socket) => {
      liveSocket = socket;
      const server = socket.connectToServer();
      socket.onMessage((message) => server.send(message));
      server.onMessage((message) => {
        if (holdReply && String(message).includes(accountId)) {
          holdReply = false;
          heldReply = message;
          resolveHeld?.();
        } else {
          socket.send(message);
        }
      });
    });

    await openHealth(page, sessionTenantId);
    await expect(accountLabel(page)).toHaveText(sessionTenantId);

    await accountSwitcher(page).click();
    holdReply = true;
    const reachedServer = new Promise((resolve) => {
      resolveHeld = resolve;
    });
    await accountOption(page, accountId).click();
    await reachedServer;

    // The status is visible, polite and names the target; it never claims success.
    const status = accountSwitchStatus(page).filter({ hasText: `Switching to ${accountId}…` });
    await expect(status).toBeVisible();
    await expect(status).toHaveAttribute("role", "status");
    await expect(status).toHaveAttribute("aria-live", "polite");
    await expect(page.getByText(/Switched/)).toHaveCount(0);
    await expect(accountLabel(page)).toHaveText(sessionTenantId);

    liveSocket.send(heldReply);
    heldReply = null;

    await expect(page).toHaveURL(new RegExp(`tenant_id=${accountId}`));
    await expect(accountLabel(page)).toHaveText(accountId);
    await expect(page.getByText(/Switched/)).toHaveCount(0);
    const menu = visibleByTestId(page, "surface-nav-scope-group").locator("details");
    await expect(menu).toHaveCount(1);
    await expect(menu).not.toHaveAttribute("open", /.*/);
  });

  test("Phase 177 scope group axe", async ({ page }, testInfo) => {
    // Both navigation copies are included on purpose: axe checks duplicate
    // ids across them, and it skips the copy CSS hides.
    const include = 'nav[aria-label="Mailglass sections"]';
    const receipts = [];

    async function scan(label) {
      const matched = await page.locator(include).count();
      // A renamed landmark must fail here instead of passing an empty scan.
      expect(matched, `${label}: include selector matched`).toBeGreaterThanOrEqual(1);
      const results = await new AxeBuilder({ page }).withTags(WCAG_TAGS).include(include).analyze();
      const receipt = {
        label,
        matched,
        violations: results.violations.length,
        incomplete: results.incomplete.length,
        incompleteRules: results.incomplete.map((rule) => rule.id)
      };
      receipts.push(receipt);
      testInfo.annotations.push({
        type: "axe-incomplete",
        description: `${label}: ${receipt.incomplete} incomplete (${receipt.incompleteRules.join(", ") || "none"}), ${receipt.violations} violations`
      });
      // Incomplete findings are triaged, not failed. This one was a real
      // defect (aria-label on a role-less div) that was fixed, so it stays out.
      expect(receipt.incompleteRules, `${label}: aria-prohibited-attr stays fixed`).not.toContain(
        "aria-prohibited-attr"
      );
      expect(
        results.violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(" ")).join(" | ")}`),
        `${label}: axe violations`
      ).toEqual([]);
    }

    for (const theme of ["light", "dark"]) {
      await page.emulateMedia({ colorScheme: theme });
      for (const width of [1280, 390]) {
        await page.setViewportSize({ width, height: 900 });
        await openHealth(page, accountId);
        await page.goto(`/ops/mail?tenant_id=${accountId}&theme=${theme}`);
        await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
        await scan(`health ${theme} ${width}`);

        await openPreview(page, theme);
        await scan(`preview ${theme} ${width}`);
      }
    }

    console.log(`PHASE177_AXE_RECEIPTS ${JSON.stringify(receipts)}`);
  });

  test("Phase 177 scope chrome honors reduced motion", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    const seconds = (value) =>
      Math.max(...String(value).split(",").map((part) => Number.parseFloat(part) || 0));
    const durations = (locator) =>
      locator.evaluateAll((elements) =>
        elements.map((el) => {
          const style = getComputedStyle(el);
          return {
            who: `${el.tagName.toLowerCase()}${el.dataset.testid ? `[${el.dataset.testid}]` : ""}${
              el.id ? `#${el.id}` : ""
            }`,
            transition: style.transitionDuration,
            animation: style.animationDuration
          };
        })
      );
    const expectInstant = async (label, locator, receipts) => {
      const measured = await durations(locator);
      expect(measured.length, `${label}: matched at least one element`).toBeGreaterThanOrEqual(1);
      for (const item of measured) {
        receipts.push(`${label} ${item.who} transition=${item.transition} animation=${item.animation}`);
        expect(seconds(item.transition), `${label} ${item.who} transition ${item.transition}`).toBeLessThanOrEqual(0.001);
        expect(seconds(item.animation), `${label} ${item.who} animation ${item.animation}`).toBeLessThanOrEqual(0.001);
      }
    };

    await openHealth(page, accountId);
    const chevron = accountSwitcher(page).locator('[class*="hero-chevron-down"]');

    // Teeth: without the reduce preference the chevron really does animate.
    await page.emulateMedia({ reducedMotion: "no-preference" });
    expect(
      seconds(await chevron.evaluate((el) => getComputedStyle(el).transitionDuration)),
      "chevron transition-duration under no-preference"
    ).toBeGreaterThan(0);

    await page.emulateMedia({ reducedMotion: "reduce" });
    const receipts = [];
    const group = visibleByTestId(page, "surface-nav-scope-group");
    await expectInstant("summary", accountSwitcher(page), receipts);
    await expectInstant("chevron closed", chevron, receipts);
    await expectInstant("group closed", group.locator("*"), receipts);
    await expectInstant("refresh", page.locator("#operator-health-refresh"), receipts);

    await accountSwitcher(page).click();
    await expect(group.locator('ul[aria-label="Available Accounts"]')).toBeVisible();
    await expectInstant("chevron open", chevron, receipts);
    await expectInstant("group open", group.locator("*"), receipts);

    await openPreview(page);
    await expectInstant(
      "preview return link",
      visibleByTestId(page, "preview-return-link"),
      receipts
    );
    await expectInstant(
      "preview group",
      visibleByTestId(page, "surface-nav-scope-group").locator("*"),
      receipts
    );
    console.log(`PHASE177_REDUCED_MOTION ${JSON.stringify(receipts)}`);
  });
});
