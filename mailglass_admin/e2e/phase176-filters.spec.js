const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");

const tenantId = "browser-tenant";
const denyRevealTenantId = "deny-reveal";
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

async function openBrowserTenant(page, { scenario, subject, tenant = tenantId, returnPath } = {}) {
  await page.context().clearCookies();
  const reset = await page.request.get(
    `/ops/browser-reset${scenario ? `?scenario=${scenario}` : ""}`
  );
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(returnPath || `/ops/mail?tenant_id=${tenant}`);
  const subjectParam = subject ? `&subject_id=${subject}` : "";
  await page.goto(`/ops/browser-login?tenant_id=${tenant}&return_to=${returnTo}${subjectParam}`);
  if (returnPath) {
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
  } else {
    await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  }
}

test.describe("Phase 176 direct filters", () => {
  test("Phase 176 tracer: Deliveries select applies without Apply", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.locator("#operator-filters")).toBeVisible();

    // D-01: the form has no Apply control at all.
    await expect(page.getByRole("button", { name: /apply/i })).toHaveCount(0);

    const initialUrl = page.url();
    const historyBefore = await page.evaluate(() => window.history.length);

    await page.locator("#filters_event").selectOption("failed");
    await page.waitForURL(url => {
      const params = new URL(url).searchParams;
      return params.get("event") === "failed" && !params.has("page") && !params.has("delivery_id");
    });
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
    await expect(page.locator("#filters_event")).toHaveValue("failed");

    // FILTER-03: one select intent is exactly one history entry.
    const historyAfter = await page.evaluate(() => window.history.length);
    expect(historyAfter - historyBefore).toBe(1);

    await page.goBack();
    await page.waitForURL(url => new URL(url).searchParams.get("event") !== "failed");
    expect(page.url()).toBe(initialUrl);
    await expect(page.locator("#filters_event")).toHaveValue("");

    await page.goForward();
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await expect(page.locator("#filters_event")).toHaveValue("failed");
  });
  test("Phase 176 search: one history entry per search edit and Enter commits immediately", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const search = page.locator("#filters_search");
    await expect(search).toHaveAttribute("phx-debounce", "300");
    await expect(search).toHaveAttribute("autocomplete", "off");
    await expect(search).toHaveAttribute("enterkeyhint", "search");
    await expect(page.locator("#filters_event")).not.toHaveAttribute("phx-debounce", /.*/);

    const searchParam = () => new URL(page.url()).searchParams.get("search");
    const historyBefore = await page.evaluate(() => window.history.length);

    // One edit: type, let the debounce commit, type more, let it commit again.
    await search.click();
    await search.pressSequentially("ab", { delay: 30 });
    await page.waitForURL(() => searchParam() === "ab");
    await search.pressSequentially("c", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abc");

    // Focus and caret survive the commits; the input is never disabled or re-keyed.
    await expect(search).toBeFocused();
    await expect(search).toBeEnabled();
    await expect(search).toHaveValue("abc");
    expect(await page.evaluate(() => window.history.length) - historyBefore).toBe(1);

    // Enter commits without waiting for the 300 ms debounce.
    await search.pressSequentially("d", { delay: 10 });
    const startedAt = Date.now();
    await search.press("Enter");
    await page.waitForURL(() => searchParam() === "abcd", { timeout: 250 });
    expect(Date.now() - startedAt).toBeLessThan(250);
    await expect(search).toBeFocused();
    expect(await page.evaluate(() => window.history.length) - historyBefore).toBe(1);
  });
  test("Phase 176 spike: focused search restores on Back (LV 1.2.13)", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

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

  test("Phase 176 spike: typing after an empty Back is kept (LV 1.2.13)", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

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
  test("Phase 176 Inbound select applies without Apply", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
    await expect(page.locator("#inbound-filters")).toBeVisible();

    // D-01: the Inbound form has no Apply or submit control either.
    await expect(page.getByRole("button", { name: /apply/i })).toHaveCount(0);
    await expect(page.locator("#inbound-filters [type=submit]")).toHaveCount(0);

    const initialUrl = page.url();
    const historyBefore = await page.evaluate(() => window.history.length);

    await page.locator("#filters_outcome").selectOption("accept");
    await page.waitForURL(url => {
      const params = new URL(url).searchParams;
      return params.get("outcome") === "accept" && !params.has("page") && !params.has("inbound_id");
    });
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
    await expect(page.locator("#filters_outcome")).toHaveValue("accept");
    expect(new URL(page.url()).searchParams.get("tenant_id")).toBe(tenantId);

    // FILTER-03: one select intent is exactly one history entry.
    expect((await page.evaluate(() => window.history.length)) - historyBefore).toBe(1);

    await page.goBack();
    await page.waitForURL(url => new URL(url).searchParams.get("outcome") !== "accept");
    expect(page.url()).toBe(initialUrl);
    await expect(page.locator("#filters_outcome")).toHaveValue("");

    await page.goForward();
    await page.waitForURL(url => new URL(url).searchParams.get("outcome") === "accept");
    await expect(page.locator("#filters_outcome")).toHaveValue("accept");
  });

  test("Phase 176 Inbound search: one history entry per edit and Enter commits", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const search = page.locator("#filters_search");
    await expect(search).toHaveAttribute("phx-debounce", "300");
    await expect(search).toHaveAttribute("autocomplete", "off");
    await expect(search).toHaveAttribute("enterkeyhint", "search");
    await expect(page.locator("#filters_outcome")).not.toHaveAttribute("phx-debounce", /.*/);
    await expect(page.locator("#filters_window_hours")).not.toHaveAttribute("phx-debounce", /.*/);

    const searchParam = () => new URL(page.url()).searchParams.get("search");
    const historyBefore = await page.evaluate(() => window.history.length);

    await search.click();
    await search.pressSequentially("ab", { delay: 30 });
    await page.waitForURL(() => searchParam() === "ab");
    await search.pressSequentially("c", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abc");

    await expect(search).toBeFocused();
    await expect(search).toBeEnabled();
    await expect(search).toHaveValue("abc");
    expect((await page.evaluate(() => window.history.length)) - historyBefore).toBe(1);

    // Enter commits without waiting for the 300 ms debounce.
    await search.pressSequentially("d", { delay: 10 });
    const startedAt = Date.now();
    await search.press("Enter");
    await page.waitForURL(() => searchParam() === "abcd", { timeout: 250 });
    expect(Date.now() - startedAt).toBeLessThan(250);
    await expect(search).toBeFocused();
    expect((await page.evaluate(() => window.history.length)) - historyBefore).toBe(1);
  });

  test("Phase 176 Inbound search restores on Back with focus", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
    await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();

    const search = page.locator("#filters_search");
    const searchParam = () => new URL(page.url()).searchParams.get("search");

    await search.click();
    await search.pressSequentially("abc", { delay: 30 });
    await page.waitForURL(() => searchParam() === "abc");
    await page.locator("#filters_outcome").selectOption("accept");
    await page.waitForURL((url) => new URL(url).searchParams.get("outcome") === "accept");

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

  test("Phase 176 Deliveries failed read shows error and Retry", async ({ page }) => {
    await openBrowserTenant(page);
    await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
    await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();

    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
    const armed = await page.evaluate(async ({ csrfToken }) => {
      const response = await fetch("/ops/browser-mutate?action=arm-known-read-failure&operation=deliveries", {
        method: "POST",
        headers: { "x-csrf-token": csrfToken },
        body: undefined,
        redirect: "manual"
      });
      return { status: response.status, body: await response.text() };
    }, { csrfToken });
    expect(armed.status, armed.body).toBe(200);

    await page.locator("#filters_event").selectOption("suppressed");
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "suppressed");

    const card = page.getByTestId("operator-deliveries-list-card");
    await expect(card).toContainText("Couldn't load deliveries for these filters");
    await expect(card).toContainText("The read failed. Your filters are unchanged. Retry, or change a filter.");
    await expect(page.getByTestId("operator-result-count")).toHaveCount(0);
    await expect(page.getByTestId("operator-empty-filtered")).toHaveCount(0);
    await expect(page.getByTestId("operator-empty-truly")).toHaveCount(0);
    await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);
    await expect(page.locator("#filters_event")).toHaveValue("suppressed");

    const historyBefore = await page.evaluate(() => window.history.length);
    const urlBefore = page.url();
    await page.getByTestId("operator-retry-deliveries").click();

    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }).first()).toBeVisible();
    await expect(page.getByTestId("operator-retry-deliveries")).toHaveCount(0);
    await expect(page.getByTestId("operator-result-count")).toBeVisible();
    expect(await page.evaluate(() => window.history.length)).toBe(historyBefore);
    expect(page.url()).toBe(urlBefore);
  });
});

// -----------------------------------------------------------------------------
// Phase 176 connected cases (plan 176-10, D-29). Client-only behaviors that an
// ExUnit LiveView test cannot see: history.length, caret, focus, reconnect.
// -----------------------------------------------------------------------------

const collections = {
  deliveries: {
    name: "Deliveries",
    path: `/ops/mail?tenant_id=${tenantId}&view=deliveries`,
    form: "operator-filters",
    card: "operator-deliveries-list-card",
    select: "#filters_event",
    selectParam: "event",
    selectValue: "delivered",
    status: "operator-results-status",
    toggle: "operator-filters-toggle"
  },
  inbound: {
    name: "Inbound",
    path: `/ops/mail/inbound?tenant_id=${tenantId}`,
    form: "inbound-filters",
    card: "inbound-records-list-card",
    select: "#filters_outcome",
    selectParam: "outcome",
    selectValue: "accept",
    status: "inbound-results-status",
    toggle: "inbound-filters-toggle"
  }
};

const historyLength = page => page.evaluate(() => window.history.length);
const searchParamOf = page => new URL(page.url()).searchParams.get("search");

async function openCollection(page, key, { query = "", scenario, subject, tenant } = {}) {
  await openBrowserTenant(page, { scenario, subject, tenant });
  const base = collections[key];
  const path = tenant && tenant !== tenantId ? base.path.replace(tenantId, tenant) : base.path;
  await page.goto(`${path}${query}`);
  await expect(page.getByTestId(base.card)).toBeVisible();
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
}

// A click cannot produce an invalid window draft (RESEARCH Pitfall 6), so inject
// an unlisted option and dispatch the same bubbling change event a user's browser
// would (precedent: storybook-axe.spec.js). LiveView sends validate_filters.
async function injectInvalidWindowDraft(page, formId) {
  const before = page.url();
  await page.evaluate(id => {
    const select = document.querySelector(`#${id} [name='filters[window_hours]']`);
    const option = document.createElement("option");
    option.value = "-5";
    option.textContent = "-5";
    select.appendChild(option);
    select.value = "-5";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }, formId);

  await expect(page.locator("#filters_window_hours-error")).toBeVisible();
  await expect(page.locator(`#${formId} [name='filters[window_hours]'] option:checked`)).toHaveText(
    "Custom period (-5 hours)"
  );
  expect(page.url(), "an invalid draft is not committed to the URL").toBe(before);
}

// Record ids are per-run UUIDs; collapse them so a baseline taken on the neutral
// page compares equal to the same markup in a later state.
const normalizeAxeTarget = target =>
  target.replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g, "*");

async function collectAxeFindings(page) {
  const results = await new AxeBuilder({ page }).withTags(WCAG_TAGS).analyze();
  return results.violations.flatMap(violation =>
    violation.nodes.map(node => `${violation.id} @ ${normalizeAxeTarget(node.target.join(" "))}`)
  );
}

// "No new violations": the neutral page of the same collection and theme sets the
// baseline (it carries the pre-existing Phase 113 aria-selected-on-button defect on
// the Deliveries row buttons, logged in deferred-items.md); every state must add
// nothing to it.
async function expectNoNewAxeViolations(page, label, baseline) {
  const findings = await collectAxeFindings(page);
  const added = [...new Set(findings)].filter(finding => !baseline.has(finding));
  expect(added, `${label}: axe WCAG 2.2 AA violations beyond the neutral baseline`).toEqual([]);
}

async function expectTheme(page, theme) {
  await expect(page.locator(`[data-theme="mailglass-${theme}"]`).first()).toBeVisible();
}

async function armKnownReadFailure(page, operation) {
  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const armed = await page.evaluate(
    async ({ csrfToken, operation }) => {
      const response = await fetch(
        `/ops/browser-mutate?action=arm-known-read-failure&operation=${operation}`,
        { method: "POST", headers: { "x-csrf-token": csrfToken }, redirect: "manual" }
      );
      return { status: response.status, body: await response.text() };
    },
    { csrfToken, operation }
  );
  expect(armed.status, armed.body).toBe(200);
}

async function noHorizontalOverflow(page) {
  return page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth
  }));
}

test.describe("Phase 176 connected", () => {
  for (const key of ["deliveries", "inbound"]) {
    const c = collections[key];

    test(`Phase 176 connected: ${c.name} search edit adds one history entry and Enter adds none extra`, async ({ page }) => {
      await openCollection(page, key);
      const search = page.locator("#filters_search");
      const before = await historyLength(page);

      await search.click();
      await search.pressSequentially("ab", { delay: 30 });
      await page.waitForURL(() => searchParamOf(page) === "ab");
      await search.pressSequentially("c", { delay: 30 });
      await page.waitForURL(() => searchParamOf(page) === "abc");
      expect((await historyLength(page)) - before).toBe(1);

      // Enter during a pending debounce: one entry, immediate URL, no extra entry later.
      await search.pressSequentially("d", { delay: 10 });
      const startedAt = Date.now();
      await search.press("Enter");
      await page.waitForURL(() => searchParamOf(page) === "abcd", { timeout: 250 });
      expect(Date.now() - startedAt).toBeLessThan(250);
      await page.waitForTimeout(500);
      expect((await historyLength(page)) - before).toBe(1);
      await expect(search).toBeFocused();
    });

    test(`Phase 176 connected: ${c.name} Clear during a pending debounce ends cleared`, async ({ page }) => {
      await openCollection(page, key);
      const rows = page.getByTestId(key === "deliveries" ? "operator-delivery-row" : "inbound-record-row");
      const unfiltered = await rows.filter({ visible: true }).count();
      expect(unfiltered).toBeGreaterThan(0);

      await openCollection(page, key, { query: `&search=${key === "deliveries" ? "browser-selected" : "support"}` });
      const search = page.locator("#filters_search");
      await expect(search).toHaveValue(key === "deliveries" ? "browser-selected" : "support");

      // Pending debounce: the typed suffix has not reached the server yet. The end
      // state is asserted, not the intermediate history delta (Pitfall 1, A2).
      await search.click();
      await search.pressSequentially("-zz", { delay: 10 });
      await page.getByRole("button", { name: "Clear filters" }).filter({ visible: true }).click();

      await page.waitForURL(() => searchParamOf(page) === null);
      await page.waitForTimeout(700);
      expect(searchParamOf(page), "the pending edit must not resurrect the search").toBeNull();
      await expect(search).toHaveValue("");
      await expect(rows.filter({ visible: true })).toHaveCount(unfiltered);
    });

    test(`Phase 176 connected: ${c.name} Back and Forward restore the search with it focused`, async ({ page }) => {
      await openCollection(page, key);
      const search = page.locator("#filters_search");

      await search.click();
      await search.pressSequentially("abc", { delay: 30 });
      await page.waitForURL(() => searchParamOf(page) === "abc");
      await page.locator(c.select).selectOption(c.selectValue);
      await page.waitForURL(url => new URL(url).searchParams.get(c.selectParam) === c.selectValue);

      await search.click();
      await search.pressSequentially("d", { delay: 30 });
      await page.waitForURL(() => searchParamOf(page) === "abcd");

      await page.goBack();
      await page.waitForURL(() => searchParamOf(page) === "abc");
      await expect(search).toBeFocused();
      await expect(search).toHaveValue("abc");

      await page.goForward();
      await page.waitForURL(() => searchParamOf(page) === "abcd");
      await expect(search).toHaveValue("abcd");
    });

    test(`Phase 176 connected: ${c.name} reconnect recovery updates the URL without a history entry`, async ({ page }) => {
      await openCollection(page, key);
      const before = await historyLength(page);

      await page.evaluate(() => window.liveSocket.disconnect());
      await page.locator(c.select).selectOption(c.selectValue);
      await page.evaluate(() => window.liveSocket.connect());

      await page.waitForURL(url => new URL(url).searchParams.get(c.selectParam) === c.selectValue);
      await expect(page.locator(c.select)).toHaveValue(c.selectValue);
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      expect(await historyLength(page), "recovery uses replace").toBe(before);
    });

    test(`Phase 176 connected: ${c.name} status region settles to a count, an empty or an error text`, async ({ page }) => {
      await openCollection(page, key);
      const status = page.getByTestId(c.status);
      const noun = key === "deliveries" ? "deliver(y|ies)" : "message(s)?";
      await expect(status).toHaveAttribute("role", "status");
      await expect(status).toHaveText(new RegExp(`^\\s*\\d+ ${noun} (matches|match)\\s*$`));

      await openCollection(page, key, { query: "&search=zzzz-no-such-row" });
      await expect(page.getByTestId(c.status)).toHaveText(
        key === "deliveries"
          ? "No deliveries match the current filters"
          : "No messages match the current filters"
      );
    });

    test(`Phase 176 connected: ${c.name} filter form has exactly one implicit-submission-blocking field and Enter commits`, async ({ page }) => {
      await openCollection(page, key);
      const blocking = await page.evaluate(id => {
        const types = ["text", "search", "email", "url", "tel", "password", "number", "date", "month", "week", "time", "datetime-local"];
        return [...document.querySelectorAll(`#${id} input`)]
          .filter(input => types.includes((input.getAttribute("type") || "text").toLowerCase()))
          .map(input => input.id || input.name);
      }, c.form);
      expect(blocking, "D-03: a second blocking field would need a submit control").toEqual(["filters_search"]);
      await expect(page.locator(`#${c.form} [type=submit]`)).toHaveCount(0);

      const search = page.locator("#filters_search");
      await search.click();
      await search.pressSequentially("enter-me", { delay: 5 });
      await search.press("Enter");
      await page.waitForURL(() => searchParamOf(page) === "enter-me", { timeout: 250 });
    });

    test(`Phase 176 connected: ${c.name} focus and caret survive a debounced commit`, async ({ page }) => {
      await openCollection(page, key);
      const search = page.locator("#filters_search");

      await search.click();
      await search.pressSequentially("abcdef", { delay: 10 });
      for (let i = 0; i < 3; i += 1) await page.keyboard.press("ArrowLeft");
      await page.waitForURL(() => searchParamOf(page) === "abcdef");

      await expect(search).toBeFocused();
      expect(await search.evaluate(input => input.selectionStart)).toBe(3);
      await page.keyboard.type("X", { delay: 10 });
      await page.waitForURL(() => searchParamOf(page) === "abcXdef");
      await expect(search).toHaveValue("abcXdef");
      await expect(search).toBeFocused();
    });
  }

  test("Phase 176 connected: rapid select, search and Enter end at the sorted canonical URL", async ({ page }) => {
    await openCollection(page, "deliveries");
    const search = page.locator("#filters_search");
    const before = await historyLength(page);

    await page.locator("#filters_event").selectOption("delivered");
    await search.click();
    await search.pressSequentially("browser", { delay: 10 });
    await search.press("Enter");

    await page.waitForURL(url => {
      const params = new URL(url).searchParams;
      return params.get("event") === "delivered" && params.get("search") === "browser";
    });
    await page.waitForTimeout(700);

    const params = new URL(page.url()).searchParams;
    const keys = [...params.keys()];
    expect(keys, "canonical URL keys are sorted").toEqual([...keys].sort());
    expect(params.has("page")).toBe(false);
    expect(params.get("event")).toBe("delivered");
    expect(params.get("search")).toBe("browser");
    await expect(page.locator("#filters_event")).toHaveValue("delivered");
    await expect(search).toHaveValue("browser");
    expect((await historyLength(page)) - before, "one select entry plus one search entry").toBe(2);
  });

  test("Phase 176 connected: a commit from page 2 lands on page 1 on Deliveries", async ({ page }) => {
    await openCollection(page, "deliveries", { scenario: "phase169-exact", query: "&page=2" });
    await expect(page.getByTestId("operator-pagination")).toContainText("Page 2 of");

    await page.locator("#filters_event").selectOption("delivered");
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "delivered");
    expect(new URL(page.url()).searchParams.has("page")).toBe(false);
    await expect(page.getByTestId("operator-pagination")).toContainText("Page 1 of");
    await expect(page.getByTestId("operator-delivery-row").filter({ visible: true }).first()).toBeVisible();
  });

  test("Phase 176 connected: a commit from a stale page lands on page 1 on Inbound", async ({ page }) => {
    // The browser seed holds fewer than one page of Inbound records, so page=2 is
    // an out-of-range URL: the commit must still drop it and show page 1 rows.
    await openCollection(page, "inbound", { query: "&page=2" });

    await page.locator("#filters_outcome").selectOption("accept");
    await page.waitForURL(url => new URL(url).searchParams.get("outcome") === "accept");
    expect(new URL(page.url()).searchParams.has("page")).toBe(false);
    await expect(page.getByTestId("inbound-record-row").filter({ visible: true }).first()).toBeVisible();
    await expect(page.getByText("No messages on this page")).toHaveCount(0);
  });

  test("Phase 176 connected: a commit adds no animation to the results container", async ({ page }) => {
    for (const key of ["deliveries", "inbound"]) {
      const c = collections[key];
      await openCollection(page, key);
      await page.locator(c.select).selectOption(c.selectValue);
      await page.waitForURL(url => new URL(url).searchParams.get(c.selectParam) === c.selectValue);
      const running = await page.getByTestId(c.card).evaluate(node =>
        node.getAnimations({ subtree: true }).filter(animation => animation.playState === "running").length
      );
      expect(running, `${c.name}: no running animation on the results container`).toBe(0);
    }
  });

  test("Phase 176 connected: a 500-character query overflows nothing at 360px and under CSS zoom 2x", async ({ page }) => {
    const longQuery = "a".repeat(250) + "東京-é-".repeat(40) + "z".repeat(20);
    for (const key of ["deliveries", "inbound"]) {
      for (const view of [
        { width: 360, height: 800, zoom: null },
        { width: 720, height: 800, zoom: "2" }
      ]) {
        await page.setViewportSize({ width: view.width, height: view.height });
        await openCollection(page, key, { query: `&search=${encodeURIComponent(longQuery)}` });
        if (view.zoom) await page.evaluate(zoom => { document.documentElement.style.zoom = zoom; }, view.zoom);
        const { scrollWidth, clientWidth } = await noHorizontalOverflow(page);
        expect(scrollWidth, `${key} at ${view.width}px CSS zoom ${view.zoom || 1}`).toBeLessThanOrEqual(clientWidth);
      }
    }
  });

  test("Phase 176 connected: the mobile Filters toggle reaches 44px and does not clip under CSS zoom 2x", async ({ page }) => {
    for (const key of ["deliveries", "inbound"]) {
      const c = collections[key];
      for (const view of [
        { width: 360, height: 800, zoom: null },
        { width: 720, height: 800, zoom: "2" }
      ]) {
        await page.setViewportSize({ width: view.width, height: view.height });
        await openCollection(page, key);
        if (view.zoom) await page.evaluate(zoom => { document.documentElement.style.zoom = zoom; }, view.zoom);

        const toggle = page.getByTestId(c.toggle);
        await expect(toggle).toBeVisible();
        await expect(toggle).toHaveAttribute("aria-expanded", "false");
        const box = await toggle.boundingBox();
        expect(box.height, `${key} toggle height`).toBeGreaterThanOrEqual(43.5);

        // Everything is reachable behind the toggle.
        await toggle.click();
        await expect(toggle).toHaveAttribute("aria-expanded", "true");
        const controls = page.locator(
          `#${c.form} select, #${c.form} input#filters_search, #${c.form} button[phx-click="clear_filters"]`
        );
        const count = await controls.count();
        expect(count).toBeGreaterThanOrEqual(4);
        for (let i = 0; i < count; i += 1) {
          const control = controls.nth(i);
          await expect(control).toBeVisible();
          const controlBox = await control.boundingBox();
          expect(controlBox.height, `${key} control ${i} height`).toBeGreaterThanOrEqual(43.5);
        }

        // "Filters (N applied)" is not clipped.
        await page.locator(c.select).selectOption(c.selectValue);
        await page.waitForURL(url => new URL(url).searchParams.get(c.selectParam) === c.selectValue);
        await expect(toggle).toContainText("(1 applied)");
        const clipped = await toggle.evaluate(node => node.scrollWidth > node.clientWidth + 1);
        expect(clipped, `${key} toggle label clipped at ${view.width}px CSS zoom ${view.zoom || 1}`).toBe(false);
        const { scrollWidth, clientWidth } = await noHorizontalOverflow(page);
        expect(scrollWidth).toBeLessThanOrEqual(clientWidth);
      }
    }
  });
});

test.describe("Phase 176 connected axe states", () => {
  for (const theme of ["light", "dark"]) {
    test(`Phase 176 connected: Deliveries invalid draft, invalid URL and failed read pass axe (${theme})`, async ({ page }) => {
      test.setTimeout(90_000);

      await openCollection(page, "deliveries", { query: `&theme=${theme}` });
      await expectTheme(page, theme);
      const baseline = new Set(await collectAxeFindings(page));
      await injectInvalidWindowDraft(page, "operator-filters");
      await expect(page.getByTestId("filters-draft-pending-note")).toBeVisible();
      await expectNoNewAxeViolations(page, `Deliveries invalid draft (${theme})`, baseline);

      await openCollection(page, "deliveries", { query: `&event=bogus&theme=${theme}` });
      await expectTheme(page, theme);
      await expect(page.getByTestId("filters-url-invalid-note")).toContainText(
        "Showing results without the Latest recorded event filter."
      );
      await expectNoNewAxeViolations(page, `Deliveries invalid URL (${theme})`, baseline);

      await openCollection(page, "deliveries", { query: `&theme=${theme}` });
      await armKnownReadFailure(page, "deliveries");
      await page.locator("#filters_event").selectOption("suppressed");
      await page.waitForURL(url => new URL(url).searchParams.get("event") === "suppressed");
      await expect(page.getByTestId("operator-retry-deliveries")).toBeVisible();
      await expectTheme(page, theme);
      await expectNoNewAxeViolations(page, `Deliveries failed read (${theme})`, baseline);
    });

    test(`Phase 176 connected: Inbound invalid draft, invalid URL and failed read pass axe (${theme})`, async ({ page }) => {
      test.setTimeout(90_000);

      await openCollection(page, "inbound", { query: `&theme=${theme}` });
      await expectTheme(page, theme);
      const baseline = new Set(await collectAxeFindings(page));
      await injectInvalidWindowDraft(page, "inbound-filters");
      await expect(page.getByTestId("filters-draft-pending-note")).toBeVisible();
      await expectNoNewAxeViolations(page, `Inbound invalid draft (${theme})`, baseline);

      await openCollection(page, "inbound", { query: `&outcome=not-real&theme=${theme}` });
      await expectTheme(page, theme);
      await expect(page.getByTestId("filters-url-invalid-note")).toBeVisible();
      await expectNoNewAxeViolations(page, `Inbound invalid URL (${theme})`, baseline);

      await openBrowserTenant(page, {
        scenario: "phase170-read-unavailable",
        returnPath: `${collections.inbound.path}&theme=${theme}`
      });
      await expect(page.getByTestId("inbound-read-unavailable")).toBeVisible();
      await expectTheme(page, theme);
      await expectNoNewAxeViolations(page, `Inbound failed read (${theme})`, baseline);
    });

    test(`Phase 176 connected: Inbound revealed and denied raw source pass axe (${theme})`, async ({ page }) => {
      test.setTimeout(90_000);

      await openCollection(page, "inbound", { query: `&theme=${theme}` });
      const accepted = page
        .getByTestId("inbound-record-row")
        .filter({ has: page.locator('[data-testid^="inbound-outcome-accept"]') })
        .first();
      const recordId = await accepted.getByTestId("inbound-record-open").getAttribute("phx-value-id");
      expect(recordId).toBeTruthy();
      await page.goto(`${collections.inbound.path}&inbound_id=${recordId}&full=1&theme=${theme}`);
      await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      const redactedBaseline = new Set(await collectAxeFindings(page));
      await page.getByTestId("inbound-evidence-reveal").click();
      await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(1);
      await expectTheme(page, theme);
      await expectNoNewAxeViolations(page, `Inbound revealed raw source (${theme})`, redactedBaseline);

      await openBrowserTenant(page, { subject: "deny-reveal", tenant: denyRevealTenantId });
      await page.goto(`/ops/mail/inbound?tenant_id=${denyRevealTenantId}&theme=${theme}`);
      const denied = page.getByTestId("inbound-record-row").filter({ visible: true }).first();
      const deniedId = await denied.getByTestId("inbound-record-open").getAttribute("phx-value-id");
      expect(deniedId).toBeTruthy();
      await page.goto(`/ops/mail/inbound?tenant_id=${denyRevealTenantId}&inbound_id=${deniedId}&full=1&theme=${theme}`);
      await expect(page.getByTestId("inbound-evidence-card")).toBeVisible();
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      const deniedBaseline = new Set(await collectAxeFindings(page));
      await page.getByTestId("inbound-evidence-reveal").click();
      await expect(page.getByTestId("inbound-evidence-denied")).toBeVisible();
      await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
      await expectTheme(page, theme);
      await expectNoNewAxeViolations(page, `Inbound denied raw source (${theme})`, deniedBaseline);
    });
  }
});

// -----------------------------------------------------------------------------
// Phase 176 gap closure (plan 176-13). The mobile Filters toggle must switch a
// class, never write an inline display style: after a close at a narrow width the
// panel has to be visible again once the viewport reaches the md breakpoint.
// One test per collection so a Deliveries failure never hides the Inbound control.
// -----------------------------------------------------------------------------

test.describe("Phase 176 gap closure", () => {
  const panelIds = { deliveries: "operator-filter-panel", inbound: "inbound-filter-panel" };

  for (const key of ["deliveries", "inbound"]) {
    const c = collections[key];

    test(`Phase 176 gap: ${key} filter panel is visible at desktop width after a mobile close`, async ({ page }) => {
      await page.setViewportSize({ width: 360, height: 800 });
      await openCollection(page, key);

      const toggle = page.getByTestId(c.toggle);
      const panel = page.locator(`#${panelIds[key]}`);
      await expect(toggle).toHaveAttribute("aria-expanded", "false");

      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "true");
      await expect(page.locator(c.select)).toBeVisible();

      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "false");
      await expect(panel).toBeHidden();

      await page.setViewportSize({ width: 1280, height: 800 });
      await expect(panel).toBeVisible();
      await expect(page.locator(c.select)).toBeVisible();
      await expect(toggle).toBeHidden();
    });
  }
});

// -----------------------------------------------------------------------------
// Phase 176 gap closure (plan 176-15, WR-06 / D-12 / D-13). While the committed URL
// still carries an invalid filter value, the URL note stays on screen after a
// reconnect (phx-auto-recover re-posts the invalid value) and after a Search edit
// that never commits. The D-12 draft note shows beside it once a change event
// leaves the draft invalid. One test per collection, generated at describe level.
// -----------------------------------------------------------------------------

test.describe("Phase 176 URL-invalid labelling", () => {
  for (const key of ["deliveries", "inbound"]) {
    const c = collections[key];

    test(`Phase 176 URL-invalid labelling: ${key} keeps the URL note after reconnect and Search`, async ({ page }) => {
      await openCollection(page, key, { query: "&window_hours=abc" });

      const urlNote = page.getByTestId("filters-url-invalid-note");
      const draftNote = page.getByTestId("filters-draft-pending-note");
      const windowParam = () => new URL(page.url()).searchParams.get("window_hours");

      // First render: URL note only.
      await expect(urlNote).toBeVisible();
      await expect(urlNote).toContainText("Showing results for the default time window instead.");
      await expect(draftNote).toHaveCount(0);

      // Reconnect: phx-auto-recover re-posts window_hours=abc; no commit, both notes show.
      await page.evaluate(() => window.liveSocket.disconnect());
      await page.evaluate(() => window.liveSocket.connect());
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      await expect(urlNote).toBeVisible();
      await expect(urlNote).toContainText("Showing results for the default time window instead.");
      await expect(draftNote).toBeVisible();
      expect(windowParam()).toBe("abc");

      // Search edit: the invalid draft never commits; the URL note stays.
      await page.locator("#filters_search").fill("zz");
      await page.waitForTimeout(800);
      expect(searchParamOf(page)).toBeNull();
      expect(windowParam()).toBe("abc");
      await expect(urlNote).toBeVisible();
      await expect(draftNote).toBeVisible();
    });
  }
});
