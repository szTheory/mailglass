const { test, expect } = require("@playwright/test");
const { visibleByTestId, accountSwitcher, accountLabel } = require("./support/account.cjs");

// "accounts" browser scenario seeds northstar and fjordline-aps; the session
// tenant is northstar and the URL selects the Account under test.
const accountId = "fjordline-aps";
const sessionTenantId = "northstar";

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
});
