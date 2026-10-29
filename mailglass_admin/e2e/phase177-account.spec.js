const { test, expect } = require("@playwright/test");
const { visibleByTestId, accountSwitcher, accountLabel } = require("./support/account.cjs");

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
});
