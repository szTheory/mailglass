const { test, expect } = require("@playwright/test");

const OWNER = '[data-theme-owner="quick-view-story"]';
const STORY_CASES = [
  {
    area: "delivery",
    path: "/dev/storybook/quick_views/delivery?variation_id=northstar_normal",
    variant: "northstar_normal"
  },
  {
    area: "inbound",
    path: "/dev/storybook/quick_views/inbound?variation_id=northstar_normal",
    variant: "northstar_normal"
  }
];

function quickViewFrame(page, variant) {
  return page.frameLocator(`iframe[id*="${variant}"]`);
}

async function themeState(frame) {
  return frame.locator(OWNER).evaluate(root => {
    const style = getComputedStyle(root);
    return {
      owner: root.dataset.themeOwner,
      preference: root.dataset.themePreference,
      resolved: root.dataset.themeResolved,
      osPreference: root.dataset.themeOs,
      dataTheme: root.dataset.theme,
      background: style.backgroundColor,
      text: style.color,
      base100: style.getPropertyValue("--color-base-100").trim(),
      baseContent: style.getPropertyValue("--color-base-content").trim()
    };
  });
}

async function setProductionTheme(page, theme) {
  const listPath = "/ops/mail?tenant_id=northstar&view=deliveries";
  await page.goto(`/demo/login?return_to=${encodeURIComponent(listPath)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await page.goto(
    `/ops/mail/theme/${theme}?return_to=${encodeURIComponent(listPath)}`
  );
  await page.locator("[data-phx-main].phx-connected").waitFor();

  return page.evaluate(() => {
    const root = document.documentElement;
    const style = getComputedStyle(root);
    return {
      dataTheme: root.dataset.theme,
      base100: style.getPropertyValue("--color-base-100").trim(),
      baseContent: style.getPropertyValue("--color-base-content").trim()
    };
  });
}

test.describe("Phase174 themes", () => {
  for (const story of STORY_CASES) {
    test(`${story.area} story owns Light, Dark, and live System review themes`, async ({
      page
    }) => {
      await page.setViewportSize({ width: 1280, height: 900 });
      await page.emulateMedia({ colorScheme: "light" });

      const storyResponse = await page.goto(story.path);
      expect(storyResponse?.ok(), `${story.area} Storybook story loads`).toBe(true);

      const frame = quickViewFrame(page, story.variant);
      const root = frame.locator(OWNER);
      const light = frame.getByRole("radio", { name: "Light", exact: true });
      const dark = frame.getByRole("radio", { name: "Dark", exact: true });
      const system = frame.getByRole("radio", { name: "System", exact: true });
      await expect(root).toBeVisible();
      await expect(light).toBeVisible();
      await expect(dark).toBeVisible();
      await expect(system).toBeVisible();

      const pageURL = page.url();
      const initialText = await frame.locator("body").innerText();
      const initial = await themeState(frame);
      expect(initial).toMatchObject({
        owner: "quick-view-story",
        preference: "system",
        resolved: "light",
        osPreference: "light",
        dataTheme: "mailglass-light"
      });
      expect(initial.background).not.toBe("rgba(0, 0, 0, 0)");
      expect(initial.text).not.toBe("");
      expect(initial.base100).not.toBe("");
      expect(initial.baseContent).not.toBe("");
      expect(await frame.locator("body").getAttribute("data-theme")).toBeNull();
      expect(await frame.locator("#psb-iframe-container").getAttribute("data-theme")).toBeNull();
      expect(await frame.locator("[data-theme]").count()).toBe(1);

      await expect(system).toBeChecked();
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-dark");
      const systemDark = await themeState(frame);
      expect(systemDark).toMatchObject({
        preference: "system",
        resolved: "dark",
        osPreference: "dark",
        dataTheme: "mailglass-dark"
      });
      expect(systemDark.background).not.toBe(initial.background);
      expect(systemDark.text).not.toBe(initial.text);

      await page.emulateMedia({ colorScheme: "light" });
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-light");
      await light.check();
      await expect(light).toBeChecked();
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(frame)).osPreference).toBe("dark");
      expect(await themeState(frame)).toMatchObject({
        preference: "light",
        resolved: "light",
        osPreference: "dark",
        dataTheme: "mailglass-light"
      });

      await dark.check();
      await expect(dark).toBeChecked();
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-dark");
      await page.emulateMedia({ colorScheme: "light" });
      await expect.poll(async () => (await themeState(frame)).osPreference).toBe("light");
      expect(await themeState(frame)).toMatchObject({
        preference: "dark",
        resolved: "dark",
        osPreference: "light",
        dataTheme: "mailglass-dark"
      });

      await system.check();
      await expect(system).toBeChecked();
      await expect.poll(async () => (await themeState(frame)).dataTheme).toBe("mailglass-light");
      const systemLight = await themeState(frame);
      expect(systemLight).toMatchObject({
        preference: "system",
        resolved: "light",
        osPreference: "light",
        dataTheme: "mailglass-light"
      });
      expect(await page.url()).toBe(pageURL);
      const selectedFrameId = await page.locator(`iframe[id*="${story.variant}"]`).getAttribute("id");
      expect(selectedFrameId).toContain(`variation-${story.variant}`);
      expect(await frame.locator("body").innerText()).toBe(initialText);

      const detachedTheme = await root.evaluate(node => {
        window.__phase174DetachedReviewRoot = node;
        const theme = node.dataset.theme;
        node.remove();
        return theme;
      });
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(() => frame.locator("body").evaluate(() =>
        window.__phase174DetachedReviewRoot?.dataset.theme
      )).toBe(detachedTheme);
      await frame.locator("body").evaluate(() => {
        const remounted = window.__phase174DetachedReviewRoot.cloneNode(true);
        document.body.append(remounted);
        window.__phase174RemountedReviewRoot = remounted;
      });
      await expect.poll(() => frame.locator("body").evaluate(() =>
        window.__phase174RemountedReviewRoot?.dataset.theme
      )).toBe("mailglass-dark");

      expect(
        (await page.context().cookies(new URL(page.url()).origin)).some(cookie =>
          cookie.name.includes("theme")
        ),
        "review selection does not persist a host preference"
      ).toBe(false);

      const productionLight = await setProductionTheme(page, "light");
      expect(productionLight.dataTheme).toBe("mailglass-light");
      expect(systemLight.base100).toBe(productionLight.base100);
      expect(systemLight.baseContent).toBe(productionLight.baseContent);

      await page.emulateMedia({ colorScheme: "light" });
      await page.goto(story.path);
      const restoredFrame = quickViewFrame(page, story.variant);
      await expect(restoredFrame.locator(OWNER)).toBeVisible();
      await expect.poll(async () => (await themeState(restoredFrame)).dataTheme).toBe("mailglass-light");
      await page.emulateMedia({ colorScheme: "dark" });
      await expect.poll(async () => (await themeState(restoredFrame)).dataTheme).toBe("mailglass-dark");
      const flippedSystemDark = await themeState(restoredFrame);

      const productionDark = await setProductionTheme(page, "dark");
      expect(productionDark.dataTheme).toBe("mailglass-dark");
      expect(flippedSystemDark.base100).toBe(productionDark.base100);
      expect(flippedSystemDark.baseContent).toBe(productionDark.baseContent);

      console.log(
        "PHASE174_THEME_RECEIPT " +
          JSON.stringify({
            story: story.area,
            caseId: `${story.area}:${story.variant}`,
            owner: initial.owner,
            systemLight: {
              selectedPreference: systemLight.preference,
              resolvedScheme: systemLight.resolved,
              osPreference: systemLight.osPreference,
              dataTheme: systemLight.dataTheme,
              background: systemLight.background,
              text: systemLight.text,
              base100: systemLight.base100,
              baseContent: systemLight.baseContent
            },
            systemDark: {
              selectedPreference: flippedSystemDark.preference,
              resolvedScheme: flippedSystemDark.resolved,
              osPreference: flippedSystemDark.osPreference,
              dataTheme: flippedSystemDark.dataTheme,
              background: flippedSystemDark.background,
              text: flippedSystemDark.text,
              base100: flippedSystemDark.base100,
              baseContent: flippedSystemDark.baseContent
            },
            production: { light: productionLight.dataTheme, dark: productionDark.dataTheme },
            explicitThemeStability: true,
            selectionPreserved: true,
            hostPreferencePersisted: false
          })
      );
    });
  }
});
