const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_MANIFEST = path.resolve(__dirname, "../../../persona_spec/quick_view_scenarios.json");

async function loginTo(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

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

test("Phase174 delivery keyboard navigation preserves selection context and focus return", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  const listPath = "/ops/mail?tenant_id=northstar&view=deliveries&provider=postmark&window_hours=168";
  await loginTo(page, listPath);

  const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
  await expect(rows.nth(2)).toBeVisible();
  const startingRow = rows.nth(1);
  const selectedId = await startingRow.getAttribute("phx-value-id");
  const focusReturnId = await startingRow.getByRole("button", { name: /Open delivery/ }).getAttribute("id");
  await startingRow.getByRole("button", { name: /Open delivery/ }).click();

  const quickView = page.getByTestId("operator-quick-view");
  await expect(quickView).toBeVisible();
  await expect(quickView.locator('[aria-live="polite"]')).toHaveText(/2 of \d+/);
  await expect(page).toHaveURL(url => {
    const query = url.searchParams;
    return query.get("delivery_id") === selectedId &&
      query.get("tenant_id") === "northstar" &&
      query.get("provider") === "postmark" &&
      query.get("window_hours") === "168";
  });
  await expect(page.evaluate(() => document.activeElement?.id)).resolves.toBe("operator-quick-view-close");

  const previous = quickView.getByRole("link", { name: "Previous delivery" });
  const next = quickView.getByRole("link", { name: "Next delivery" });
  const idleBackground = await next.evaluate(element => getComputedStyle(element).backgroundColor);
  await next.hover();
  const hoverBackground = await next.evaluate(element => getComputedStyle(element).backgroundColor);
  expect(hoverBackground, "ghost navigation has a visible hover state").not.toBe(idleBackground);
  await next.focus();
  await page.keyboard.press("Shift+Tab");
  await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute("aria-label")))
    .toBe("Previous delivery");
  const focusVisible = await previous.evaluate(element => element.matches(":focus-visible"));
  expect(focusVisible, "keyboard navigation exposes its focus indicator").toBe(true);
  await page.keyboard.press("Tab");
  await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute("aria-label")))
    .toBe("Next delivery");

  const nextId = new URL(await next.getAttribute("href"), page.url()).searchParams.get("delivery_id");
  expect(nextId).toBeTruthy();
  await page.keyboard.press("Enter");
  await expect.poll(() => new URL(page.url()).searchParams.get("delivery_id")).toBe(nextId);
  await expect(page).toHaveURL(url =>
    url.searchParams.get("tenant_id") === "northstar" &&
    url.searchParams.get("provider") === "postmark" &&
    url.searchParams.get("window_hours") === "168"
  );

  await page.keyboard.press("Escape");
  await expect(quickView).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe(focusReturnId);
});

test("Phase174 delivery first, last, single, empty, and nil-position states remain truthful", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  const northstarPath = "/ops/mail?tenant_id=northstar&view=deliveries&provider=postmark&window_hours=168";
  await loginTo(page, northstarPath);

  const rows = page.getByTestId("operator-delivery-row").filter({ visible: true });
  const total = await rows.count();
  expect(total).toBeGreaterThan(1);

  const firstRow = rows.first();
  const northstarId = await firstRow.getAttribute("phx-value-id");
  await firstRow.getByRole("button", { name: /Open delivery/ }).click();
  const quickView = page.getByTestId("operator-quick-view");
  await expect(quickView.locator('[aria-live="polite"]')).toHaveText(/1 of \d+/);
  const firstUnavailable = quickView.locator('span[aria-disabled="true"][aria-label="Previous delivery"]');
  await expect(firstUnavailable).toBeVisible();
  expect(await firstUnavailable.evaluate(element => element.tagName)).toBe("SPAN");
  await expect(quickView.getByRole("link", { name: "Previous delivery" })).toHaveCount(0);
  await expect(quickView.getByRole("link", { name: "Next delivery" })).toBeVisible();
  await quickView.getByRole("link", { name: "Close quick view" }).click();
  await expect(quickView).toHaveCount(0);

  const lastRow = rows.last();
  await lastRow.getByRole("button", { name: /Open delivery/ }).click();
  await expect(quickView.locator('[aria-live="polite"]')).toHaveText(new RegExp(`${total} of ${total}`));
  await expect(quickView.locator('span[aria-disabled="true"][aria-label="Next delivery"]')).toBeVisible();
  await expect(quickView.getByRole("link", { name: "Next delivery" })).toHaveCount(0);
  await quickView.getByRole("link", { name: "Close quick view" }).click();
  await expect(quickView).toHaveCount(0);

  const fjordlinePath = "/ops/mail?tenant_id=fjordline-aps&view=deliveries&provider=postmark&window_hours=168";
  await page.goto(fjordlinePath);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  const singleRow = page.getByTestId("operator-delivery-row").filter({ visible: true });
  await expect(singleRow).toHaveCount(1);
  await singleRow.first().getByRole("button", { name: /Open delivery/ }).click();
  await expect(quickView.locator('[aria-live="polite"]')).toHaveText(/1 of 1/);
  await expect(quickView).toContainText("Fjordline A/S");
  await expect(quickView.locator('span[aria-disabled="true"][aria-label="Previous delivery"]')).toBeVisible();
  await expect(quickView.locator('span[aria-disabled="true"][aria-label="Next delivery"]')).toBeVisible();
  await expect(quickView.getByRole("link", { name: "Previous delivery" })).toHaveCount(0);
  await expect(quickView.getByRole("link", { name: "Next delivery" })).toHaveCount(0);

  await page.goto(`/ops/mail?tenant_id=northstar&provider=sendgrid&window_hours=168&delivery_id=${northstarId}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  const outsideFilterView = page.getByTestId("operator-quick-view");
  await expect(outsideFilterView).toBeVisible();
  await expect(outsideFilterView.locator('[aria-live="polite"]')).toHaveCount(0);
  await expect(outsideFilterView).toContainText("Northstar Logistics");
  await expect(page.locator("body")).not.toContainText("Internal Server Error");

  const heliosPath = "/ops/mail?tenant_id=helios-void&view=deliveries&window_hours=168";
  await page.goto(`/demo/login?return_to=${encodeURIComponent(heliosPath)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await expect(page.getByRole("heading", { name: "No deliveries in this time window", exact: true })).toBeVisible();
  await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);
  await expect(page.getByTestId("operator-quick-view")).toHaveCount(0);
  expect(new URL(page.url()).searchParams.has("delivery_id")).toBe(false);
});

test("Phase174 delivery retained variants preserve exact scenario facts and bounded theme captures", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto("/dev/storybook/quick_views/delivery");
  await expect(page.getByRole("heading", { name: /Delivery/i }).first()).toBeVisible();

  const normal = page.frameLocator('iframe[id*="northstar_normal"]');
  const first = page.frameLocator('iframe[id*="northstar_first"]');
  const last = page.frameLocator('iframe[id*="northstar_last"]');
  const single = page.frameLocator('iframe[id*="fjordline_single_unicode"]');
  const normalFrame = page.locator('iframe[id*="northstar_normal"]');
  await expect.poll(() => normalFrame.evaluate(frame => frame.clientHeight))
    .toBeGreaterThanOrEqual(600);
  await expect(normal.getByRole("dialog")).toBeVisible();
  await expect(normal.getByRole("dialog").locator('[aria-live="polite"]')).toHaveText(/2 of \d+/);
  await expect(first.getByRole("dialog").locator('[aria-live="polite"]')).toHaveText(/1 of \d+/);
  await expect(first.getByRole("dialog").locator('span[aria-disabled="true"][aria-label="Previous delivery"]')).toBeVisible();
  await expect(last.getByRole("dialog").locator('[aria-live="polite"]')).toHaveText(/\d+ of \d+/);
  await expect(last.getByRole("dialog").locator('span[aria-disabled="true"][aria-label="Next delivery"]')).toBeVisible();
  await expect(single.getByRole("dialog").locator('[aria-live="polite"]')).toHaveText(/1 of 1/);
  await expect(single.getByRole("dialog")).toContainText("Fjordline A/S");
  await expect(single.getByRole("heading", { name: "Welcome to Fjordline A/S — Bjørn Hansen / 山田太郎" }))
    .toBeVisible();
  await expect(single.getByRole("button", { name: "Copy Delivery ID" }))
    .toHaveAttribute("data-copy-value", "del_01JXW9ZQKB3V1N4P2RMT7FHCG");

  const captureDir = path.resolve(__dirname, "../../tmp/demo_browser_evidence/phase174");
  fs.mkdirSync(captureDir, { recursive: true });
  const lightPanelBackground = await normal.locator("#operator-quick-view")
    .evaluate(panel => getComputedStyle(panel).backgroundColor);
  await page.locator('iframe[id*="northstar_normal"]').evaluate(frame => {
    frame.contentDocument.documentElement.dataset.theme = "mailglass-dark";
    frame.contentDocument.querySelector("#psb-iframe-container > .mg-admin-root").dataset.theme = "mailglass-dark";
  });
  const darkPanelBackground = await normal.locator("#operator-quick-view")
    .evaluate(panel => getComputedStyle(panel).backgroundColor);
  expect(darkPanelBackground, "dark capture uses the dark production theme").not.toBe(lightPanelBackground);
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await normalFrame.screenshot({ path: path.join(captureDir, "delivery-dark.png") });
  await page.locator('iframe[id*="northstar_normal"]').evaluate(frame => {
    frame.contentDocument.documentElement.dataset.theme = "mailglass-light";
    frame.contentDocument.querySelector("#psb-iframe-container > .mg-admin-root").dataset.theme = "mailglass-light";
  });
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await normalFrame.screenshot({ path: path.join(captureDir, "delivery-light.png") });
});

test("Phase174 delivery scenario manifest accounts for rendered and real-route-only cases", async () => {
  const manifest = JSON.parse(fs.readFileSync(SCENARIO_MANIFEST, "utf8"));
  expect(manifest.schema_version).toBeTruthy();

  const delivery = manifest.scenarios.filter(scenario => scenario.id.startsWith("qv-delivery-"));
  expect(delivery.map(scenario => scenario.id).sort()).toEqual([
    "qv-delivery-empty",
    "qv-delivery-first",
    "qv-delivery-last",
    "qv-delivery-normal",
    "qv-delivery-single-unicode"
  ]);
  expect(new Set(delivery.map(scenario => scenario.id)).size).toBe(5);

  const rendered = delivery.filter(scenario => scenario.story_path !== null && scenario.variation_id !== null);
  expect(rendered).toHaveLength(4);
  const axeSelection = manifest.axe_selection.filter(entry => entry.scenario_id.startsWith("qv-delivery-"));
  expect(axeSelection).toHaveLength(5);
  const selectedCases = axeSelection
    .filter(entry => entry.selected)
    .reduce((count, entry) => count + entry.themes.length, 0);
  expect(selectedCases).toBe(8);
  expect(axeSelection.find(entry => entry.scenario_id === "qv-delivery-empty")).toMatchObject({
    selected: false,
    proof_boundary: "connected-real-route-only"
  });
  expect(axeSelection.filter(entry => entry.selected).every(entry => entry.root_selector === ".mg-admin-root"))
    .toBe(true);

  expect(manifest.feedback).toHaveLength(12);
  for (const feedback of manifest.feedback) {
    expect(feedback.source_path).toBeTruthy();
    expect(feedback.current_sources.length).toBeGreaterThan(0);
    expect(feedback.owner_requirements.length).toBeGreaterThan(0);
    expect(feedback.owner_phase).toBeTruthy();
    expect(feedback.disposition).toBeTruthy();
    expect(feedback.evidence_pointer).toBeTruthy();
  }
  expect(manifest.feedback.filter(feedback => ["175", "176", "177", "178"].includes(feedback.owner_phase))
    .every(feedback => feedback.status === "pending")).toBe(true);
});
