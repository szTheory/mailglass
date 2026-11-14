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

const connectedCollections = [
  {
    name: "Deliveries",
    target: "/ops/mail?tenant_id=northstar&view=deliveries",
    select: "#filters_event",
    value: "failed",
    param: "event"
  },
  {
    name: "Inbound",
    target: "/ops/mail/inbound?tenant_id=northstar",
    select: "#filters_outcome",
    value: "accept",
    param: "outcome"
  }
];

test.describe("Phase 176 connected on the demo client (LV 1.1.33)", () => {
  for (const c of connectedCollections) {
    test(`Phase 176 connected (LV 1.1.33): ${c.name} search history, Enter and focused Back`, async ({ page }) => {
      await loginTo(page, c.target);
      const search = page.locator("#filters_search");
      await expect(search).toBeVisible();
      const searchParam = () => new URL(page.url()).searchParams.get("search");
      const historyLength = () => page.evaluate(() => window.history.length);
      const before = await historyLength();

      // One edit is one history entry, however many debounced commits it spans.
      await search.click();
      await search.pressSequentially("ab", { delay: 30 });
      await page.waitForURL(() => searchParam() === "ab");
      await search.pressSequentially("c", { delay: 30 });
      await page.waitForURL(() => searchParam() === "abc");
      expect((await historyLength()) - before).toBe(1);

      // A select commit starts a new entry; the next Search edit starts another.
      await page.locator(c.select).selectOption(c.value);
      await page.waitForURL(url => new URL(url).searchParams.get(c.param) === c.value);
      expect((await historyLength()) - before).toBe(2);

      await search.click();
      await search.pressSequentially("d", { delay: 10 });
      const startedAt = Date.now();
      await search.press("Enter");
      await page.waitForURL(() => searchParam() === "abcd", { timeout: 250 });
      expect(Date.now() - startedAt, "Enter commits before the 300 ms debounce").toBeLessThan(250);
      await page.waitForTimeout(500);
      expect((await historyLength()) - before, "Enter adds one entry and no extra later").toBe(3);
      await expect(search).toBeFocused();

      // Focused Back restores the committed text with focus kept.
      await page.goBack();
      await page.waitForURL(() => searchParam() === "abc");
      await expect(search).toBeFocused();
      await expect(search).toHaveValue("abc");
    });
  }
});
