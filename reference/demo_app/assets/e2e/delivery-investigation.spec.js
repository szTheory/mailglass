const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_MANIFEST = path.resolve(__dirname, "../../../persona_spec/quick_view_scenarios.json");
const RETAINED_IDS = [
  "delivery-investigation-northstar-normal",
  "delivery-investigation-fjordline-long-unicode",
  "delivery-investigation-suppression-stale",
  "delivery-investigation-suppression-unavailable",
  "delivery-investigation-unknown-expiry",
  "delivery-investigation-replay-ambiguous",
  "delivery-investigation-replay-unavailable",
  "delivery-investigation-replay-denied",
  "delivery-investigation-replay-failed"
];

async function loginTo(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
}

test("Phase 175 retained Delivery scenario inventory and production composition", async ({ page }) => {
  const manifest = JSON.parse(fs.readFileSync(SCENARIO_MANIFEST, "utf8"));
  const scenarios = manifest.scenarios.filter(scenario =>
    scenario.id.startsWith("delivery-investigation-")
  );
  expect(scenarios.map(scenario => scenario.id).sort()).toEqual([...RETAINED_IDS].sort());
  expect(new Set(scenarios.map(scenario => scenario.id)).size).toBe(9);

  for (const scenario of scenarios) {
    expect(scenario.story_path).toBe("/dev/storybook/delivery_investigation");
    expect(scenario.variation_id).toBeTruthy();
    expect(scenario.role_job).toBeTruthy();
    expect(scenario.source.length).toBeGreaterThan(0);
    expect(scenario.state).toBeTruthy();
    expect(scenario.reason).toBeTruthy();
    expect(scenario.owning_requirements.length).toBeGreaterThan(0);
    expect(scenario.proof_boundary).toMatch(/story-render/);
  }

  const selectedAxeCases = manifest.axe_selection
    .filter(entry => entry.scenario_id.startsWith("delivery-investigation-") && entry.selected)
    .reduce((count, entry) => count + entry.themes.length, 0);
  expect(selectedAxeCases).toBe(8);

  const response = await page.goto("/dev/storybook/delivery_investigation");
  expect(response?.status(), "retained Delivery investigation story loads").toBe(200);

  for (const scenario of scenarios.filter(entry => entry.rendered)) {
    const frame = page.frameLocator(`iframe[id*="${scenario.variation_id}"]`);
    const story = frame.getByTestId("delivery-investigation-story");
    await expect(story, `${scenario.id} current-source story variation is present`).toHaveAttribute(
      "data-scenario-id",
      scenario.id
    );
    await expect(story.getByTestId("operator-detail-header")).toBeVisible();
    await expect(story.getByTestId("operator-suppression-card")).toBeVisible();
    await expect(story.getByTestId("operator-replay-action")).toBeVisible();
  }

  const normal = page.frameLocator('iframe[id*="northstar_complete"]');
  await expect(normal.getByTestId("operator-replay-modal")).toBeVisible();
  await expect(normal.getByTestId("operator-replay-reviewed-target")).toContainText(
    "wh_evt_story_delivery_01"
  );

  const long = page.frameLocator('iframe[id*="fjordline_long_unicode"]');
  await expect(long.getByTestId("operator-detail-header")).toContainText(
    "TransactionalEmailWithVeryLongModuleName"
  );
  await expect(long.getByTestId("operator-replay-reviewed-target")).toContainText(
    "wh_evt_fjordline_01JXW9ZQKB3V1N4P2RMT7FHCG"
  );

  const stale = page.frameLocator('iframe[id*="suppression_stale"]');
  await expect(stale.getByTestId("operator-suppression-card")).toContainText("Stale");
  await expect(stale.getByTestId("operator-suppression-unavailable")).toContainText(
    "last retrieved record and may be out of date"
  );
  await expect(stale.getByRole("button", { name: "Retry suppression read" })).toBeVisible();

  const unavailable = page.frameLocator('iframe[id*="suppression_unavailable"]');
  await expect(unavailable.getByTestId("operator-suppression-card")).toContainText("Unavailable");
  await expect(unavailable.getByTestId("operator-suppression-card")).not.toContainText(
    "Address or domain"
  );

  const unknownExpiry = page.frameLocator('iframe[id*="unknown_expiry"]');
  await expect(unknownExpiry.getByTestId("operator-suppression-card")).toContainText(
    "Expiry date not recorded"
  );
  await expect(unknownExpiry.getByTestId("operator-suppression-card")).toContainText(
    "Mailglass does not allow removal"
  );
  await expect(unknownExpiry.getByTestId("operator-suppression-card")).not.toContainText(
    "Never expires"
  );

  const ambiguous = page.frameLocator('iframe[id*="replay_ambiguous"]');
  await expect(ambiguous.getByTestId("operator-replay-modal")).toContainText(
    "No request is selected for you"
  );
  await expect(ambiguous.locator("#operator-replay-targets").getByRole("radio")).toHaveCount(2);
  await expect(ambiguous.getByTestId("operator-replay-confirm")).toHaveCount(0);

  const replayUnavailable = page.frameLocator('iframe[id*="replay_unavailable"]');
  await expect(replayUnavailable.getByTestId("operator-replay-modal")).toContainText(
    "Historical rows without exact webhook linkage cannot be replayed safely."
  );
  await expect(replayUnavailable.getByTestId("operator-replay-confirm")).toHaveCount(0);

  const denied = page.frameLocator('iframe[id*="replay_denied"]');
  await expect(denied.getByTestId("operator-replay-feedback")).toContainText(
    "Ask an Account administrator to review access."
  );
  await expect(denied.getByTestId("operator-replay-confirm")).toBeDisabled();
  await expect(denied.getByTestId("operator-replay-review-again")).toBeVisible();

  const failed = page.frameLocator('iframe[id*="replay_failed"]');
  await expect(failed.getByTestId("operator-replay-feedback")).toContainText(
    "Review current eligibility before trying again."
  );
  await expect(failed.getByTestId("operator-replay-confirm")).toBeDisabled();
  await expect(failed.getByTestId("operator-replay-review-again")).toBeVisible();
});

test("Phase 175 connected Delivery empty states use exact headings, guidance, and actions", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });

  const helios = "/ops/mail?tenant_id=helios-void&view=deliveries&window_hours=168";
  await loginTo(page, helios);
  await expect(page.getByRole("heading", { name: "No deliveries in this time window", exact: true }))
    .toBeVisible();
  await expect(page.getByText(
    "No deliveries have been recorded for this Account during the selected time window.",
    { exact: true }
  )).toBeVisible();
  await expect(page.getByTestId("operator-delivery-row")).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Clear filters", exact: true })).toHaveCount(0);

  const filtered = "/ops/mail?tenant_id=northstar&view=deliveries&search=phase175-no-match&window_hours=168";
  await page.goto(`/demo/login?return_to=${encodeURIComponent(filtered)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await expect(page.getByRole("heading", { name: "No deliveries", exact: true })).toBeVisible();
  await expect(page.getByText("No deliveries match the current filters.", { exact: true }))
    .toBeVisible();
  await expect(page.getByTestId("operator-empty-reset")).toBeVisible();

  const requestedPage = "/ops/mail?tenant_id=fjordline-aps&view=deliveries&page=2&window_hours=168";
  await page.goto(`/demo/login?return_to=${encodeURIComponent(requestedPage)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await expect(page.getByRole("heading", { name: "No deliveries on this page", exact: true }))
    .toBeVisible();
  await expect(page.getByText("Move to an available page to inspect the current results.", { exact: true }))
    .toBeVisible();
  const previousPage = page.getByTestId("operator-pagination").getByTestId("operator-pagination-prev");
  await expect(previousPage).toHaveAttribute("href", /tenant_id=fjordline-aps/);
  await expect(previousPage).not.toHaveAttribute("href", /page=2/);
  await expect(page.getByText("Requested page 2 is beyond the last available page (1).", { exact: true }))
    .toBeVisible();
  await expect(page.getByTestId("operator-empty-reset")).toHaveCount(0);
});
