const { test, expect } = require("@playwright/test");

async function loginTo(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

test.describe("Phase 176 direct filters on the demo client", () => {
  test("Phase 176 spike: focused search restores on Back (LV 1.1.33)", async ({ page }) => {
    await loginTo(page, "/ops/mail?tenant_id=northstar&view=deliveries");
    await expect(page.locator("#filters_search")).toBeVisible();

    const search = page.locator("#filters_search");
    const searchParam = () => new URL(page.url()).searchParams.get("search");

    await search.click();
    await search.pressSequentially("abc", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abc");
    await page.locator("#filters_event").selectOption("failed");
    await page.waitForURL((url) => new URL(url).searchParams.get("event") === "failed");

    await search.click();
    await search.pressSequentially("d", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abcd");
    await expect(search).toBeFocused();
    await expect(search).toHaveValue("abcd");

    await page.goBack();
    await page.waitForURL(() => searchParam() === "abc");
    await expect(search).toBeFocused();
    await expect(search).toHaveValue("abc");
  });

  test("Phase 176 spike: typing after an empty Back is kept (LV 1.1.33)", async ({ page }) => {
    await loginTo(page, "/ops/mail?tenant_id=northstar&view=deliveries");
    await expect(page.locator("#filters_search")).toBeVisible();

    const search = page.locator("#filters_search");
    const searchParam = () => new URL(page.url()).searchParams.get("search");

    await search.click();
    await search.pressSequentially("abc", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abc");
    await page.locator("#filters_event").selectOption("failed");
    await page.waitForURL((url) => new URL(url).searchParams.get("event") === "failed");

    // Back changes the event filter only; the committed search stays "abc".
    await search.click();
    await page.goBack();
    await page.waitForURL((url) => !new URL(url).searchParams.has("event"));
    await expect(search).toHaveValue("abc");

    // Typing right after the Back must never be overwritten by a stale sync.
    await search.pressSequentially("x", { delay: 10 });
    await page.waitForURL(() => searchParam() === "abcx");
    await page.waitForTimeout(600);
    await expect(search).toHaveValue("abcx");
    await expect(search).toBeFocused();
  });
});
