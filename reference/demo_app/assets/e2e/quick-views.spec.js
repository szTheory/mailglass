const { test, expect } = require("@playwright/test");

test("Phase174 tracer opens a real Delivery and its retained production story", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(
    `/demo/login?return_to=${encodeURIComponent("/ops/mail?tenant_id=northstar&view=deliveries")}`
  );
  await page.locator("[data-phx-main].phx-connected").waitFor();

  const row = page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(1);
  await expect(row).toBeVisible();
  await row.getByRole("button", { name: "Open delivery", exact: false }).click();

  const quickView = page.getByTestId("operator-quick-view");
  await expect(quickView).toBeVisible();
  await expect(quickView.locator('[aria-live="polite"]')).toHaveText(/\d+ of \d+/);
  await expect(quickView.getByRole("link", { name: "Close quick view" })).toBeVisible();

  const controls = [
    quickView.getByRole("link", { name: "Previous delivery" }),
    quickView.getByRole("link", { name: "Next delivery" }),
    quickView.getByRole("link", { name: "Close quick view" })
  ];
  for (const control of controls) {
    const box = await control.boundingBox();
    expect(box, "quick-view controls have measurable boxes").toBeTruthy();
    expect(box.width, "quick-view control width").toBeGreaterThanOrEqual(44);
    expect(box.height, "quick-view control height").toBeGreaterThanOrEqual(44);
  }

  for (const direction of ["Previous", "Next"]) {
    const arrow = quickView.getByRole("link", { name: `${direction} delivery` });
    const classes = await arrow.getAttribute("class");
    expect(classes).toContain("btn-ghost");
    expect(classes).toContain("mg-focus-ring");
    expect(classes).not.toMatch(/\bborder(?:-[^ ]+)?\b/);
  }

  const responses = [];
  page.on("response", response => {
    if (response.url().includes("/dev/storybook")) {
      responses.push({ url: new URL(response.url()).pathname, status: response.status() });
    }
  });

  const root = await page.goto("/dev/storybook");
  expect(root.status(), "Storybook root loads").toBe(200);
  await expect.poll(async () => page.locator("[data-phx-main]").getAttribute("class")).toContain("phx-connected");
  const foundations = page.getByRole("link", { name: "Foundations", exact: true });
  await expect(foundations).toBeVisible();
  const primitivesFolder = page.locator('#psb-sidebar div[phx-value-path="/dev/storybook/primitives"]');
  await primitivesFolder.click();
  await expect(primitivesFolder).toHaveAttribute("phx-click", "close-folder");
  const picker = page.locator('#psb-sidebar-container a[href="/dev/storybook/primitives/theme_picker"]');
  await expect(picker).toBeVisible();
  await expect(picker).toHaveAttribute("href", "/dev/storybook/primitives/theme_picker");
  await picker.click();
  await expect(page).toHaveURL(/\/dev\/storybook\/primitives\/theme_picker/);
  expect(page.url()).toContain("/dev/storybook/");

  const story = await page.goto("/dev/storybook/quick_views/delivery");
  expect(story.status(), "retained Delivery story loads directly").toBe(200);
  const storyFrame = page.frameLocator('iframe[id*="northstar_normal"]');
  await expect(storyFrame.getByRole("dialog")).toBeVisible();
  await expect(storyFrame.getByRole("dialog")).toContainText("Northstar Logistics");

  expect(
    responses.some(response => response.url.startsWith("/dev/storybook/assets/") && response.status === 200),
    `Storybook assets load below the mount prefix: ${JSON.stringify(responses)}`
  ).toBeTruthy();
});
