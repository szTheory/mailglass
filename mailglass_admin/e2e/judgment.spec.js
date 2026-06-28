const { test, expect } = require("@playwright/test");

// ---------------------------------------------------------------------------
// Judgment-level regression gates (Phase 118, METHOD-02 / D-11 / D-12).
//
// These two gates catch the headline IA defects that structural greps cannot:
// active navigation state is a RENDERED property of the DOM, so a literal grep
// for a hardcoded `active={...}` assignment can never evaluate whether the right
// nav item is highlighted on the right route. Only a rendered-DOM assertion can.
//
// Both gates are live `test(...)` and ARMED: they flipped green in Phase 119
// (when the shell stopped hardcoding the Deliveries-active sidebar on the Overview
// route and the redundant in-page Navigate card block was removed), and were armed
// into the documented ratchet floor in Phase 123. They run in the REQUIRED
// operator_browser_gate CI lane — playwright.config.cjs testDir "./e2e" globs this
// spec into `npm run test:operator-browser`, so a regression here blocks the PR.
//
// Pitfall reference (118-RESEARCH.md): the no-nav-duplication gate targets the
// same data-testid the existing operator.spec.js VERIF-02 test currently asserts
// IS visible. That is a deliberate, flagged contradiction — operator.spec.js is
// the opposing test that Phase 119 updates; this plan only FLAGS it and must not
// modify it. The shell/nav primitive itself is correct (Pitfall 3); only the
// caller's hardcoded active literal and the redundant in-page card block are the
// defects, both fixed in Phase 119.
// ---------------------------------------------------------------------------

// Mirrors operator.spec.js / structural.spec.js tenantId exactly.
const tenantId = "browser-tenant";
const baseURL =
  process.env.OPERATOR_BASE_URL ||
  `http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}`;

// Reaches the Overview view: the default operator route with NO `&view=deliveries`.
// (Mirrors the openOperator login dance from operator.spec.js — browser-reset +
// browser-login — but lands on Overview, where openOperator navigates onward to
// the Deliveries view.)
async function openOverview(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(
    new URL(
      `/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`,
      baseURL
    ).toString()
  );
  // The Overview landing renders this h1; reaching it confirms we are authenticated
  // and on the Overview route, not the Deliveries view.
  await expect(
    page.getByRole("heading", { name: "Operator overview", exact: true })
  ).toBeVisible();
  // Stay on / return to the Overview route (no view=deliveries query).
  await page.goto(
    new URL(`/ops/mail?tenant_id=${tenantId}`, baseURL).toString()
  );
  await expect(
    page.getByRole("heading", { name: "Operator overview", exact: true })
  ).toBeVisible();
  await expect(page.getByTestId("operator-overview")).toBeVisible();
}

test.describe("judgment gates (armed in Phase 119)", () => {
  // GATE: nav-active-correctness
  //
  // Correct end-state: on the Overview route the Deliveries sidebar nav link does
  // NOT carry aria-current="page", AND an Overview nav item exists that DOES carry
  // aria-current="page". Phase 119 (SHELL-01) gave Overview its own nav identity and
  // fixed the false-active bug (operator_live.ex active={@view} replaces literal
  // active={:deliveries}). The accent-allowlist Playwright seam keys off
  // [aria-current='page'] (structural.spec.js:11-17), so a correct active item is
  // also what keeps the Glass accent legitimate on this route.
  // NOTE: This gate is armed and runs in the required operator_browser_gate lane
  // (playwright.config.cjs testDir "./e2e" glob).
  test("nav-active-correctness: Overview route highlights Overview, not Deliveries", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOverview(page);

    const sidebar = page.getByRole("navigation", { name: "Operator sections" }).first();

    // Deliveries must NOT be the active (aria-current=page) item on the Overview route.
    // nav_link emits aria-current={@active && "page"}: when inactive, Phoenix OMITS the
    // attribute entirely (boolean false → no attribute). Assert absence of the attribute.
    const deliveriesLink = sidebar.getByRole("link", { name: "Deliveries", exact: true });
    await expect(deliveriesLink).not.toHaveAttribute("aria-current", "page");

    // An Overview nav item must exist and BE the active (aria-current=page) item.
    const overviewLink = sidebar.getByRole("link", { name: "Overview", exact: true });
    await expect(overviewLink).toHaveAttribute("aria-current", "page");
  });

  // GATE: no-nav-duplication
  //
  // Correct end-state: the populated Overview renders ZERO
  // data-testid="operator-overview-nav" elements — the in-page "Navigate" card block
  // was removed in Phase 119 (SHELL-02). The operator.spec.js VERIF-02 test previously
  // asserted this same testid IS visible (the flagged Pitfall-2 contradiction); that
  // opposing test was updated in Phase 119 (119-02 Task 1).
  // NOTE: This gate is armed and runs in the required operator_browser_gate lane
  // (playwright.config.cjs testDir "./e2e" glob).
  test("no-nav-duplication: populated Overview renders no in-page Navigate card block", async ({
    page
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await openOverview(page);

    // The populated Overview (tenant scoped, health cards present) must not duplicate
    // the sidebar with an in-page navigation card block.
    await expect(page.getByTestId("operator-overview-health")).toBeVisible();
    await expect(page.getByTestId("operator-overview-nav")).toHaveCount(0);
  });
});
