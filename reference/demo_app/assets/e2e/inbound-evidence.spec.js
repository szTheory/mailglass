const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_MANIFEST = path.resolve(__dirname, "../../../persona_spec/quick_view_scenarios.json");
const RETAINED_IDS = [
  "inbound-evidence-normal-contacts",
  "inbound-evidence-long-local-part",
  "inbound-evidence-unicode",
  "inbound-evidence-spoofed-display-name",
  "inbound-evidence-many-recipients",
  "inbound-evidence-missing-headers",
  "inbound-evidence-unparseable",
  "inbound-evidence-evidence-unknown",
  "inbound-evidence-evidence-empty-revealed",
  "inbound-evidence-evidence-large-revealed",
  "inbound-evidence-evidence-denied"
];

test("Phase 176 retained Inbound evidence inventory and production composition", async ({ page }) => {
  const manifest = JSON.parse(fs.readFileSync(SCENARIO_MANIFEST, "utf8"));
  const scenarios = manifest.scenarios.filter(scenario =>
    scenario.id.startsWith("inbound-evidence-")
  );
  expect(scenarios.map(scenario => scenario.id).sort()).toEqual([...RETAINED_IDS].sort());
  expect(new Set(scenarios.map(scenario => scenario.id)).size).toBe(11);

  for (const scenario of scenarios) {
    expect(scenario.story_path).toBe("/dev/storybook/inbound_evidence");
    expect(scenario.theme_owner).toBe("inbound-evidence-story");
    expect(scenario.theme_picker_testid).toBe("inbound-evidence-review-theme");
    expect(scenario.variation_id).toBeTruthy();
    expect(scenario.role_job).toBeTruthy();
    expect(scenario.source.length).toBeGreaterThan(0);
    expect(scenario.state).toBeTruthy();
    expect(scenario.reason).toBeTruthy();
    expect(scenario.owning_requirements.length).toBeGreaterThan(0);
    expect(scenario.proof_boundary).toBe("story-render-only");
  }

  // Stories prove composition only; the Storybook axe sweep pins SELECTED_VARIANTS,
  // so none of these scenarios belongs in axe_selection (connected routes carry axe).
  expect(
    manifest.axe_selection.filter(entry => entry.scenario_id.startsWith("inbound-evidence-"))
  ).toEqual([]);

  const response = await page.goto("/dev/storybook/inbound_evidence");
  expect(response?.status(), "retained Inbound evidence story loads").toBe(200);

  for (const scenario of scenarios.filter(entry => entry.rendered)) {
    const frame = page.frameLocator(`iframe[id*="${scenario.variation_id}"]`);
    const story = frame.getByTestId("inbound-evidence-story");
    await expect(story, `${scenario.id} current-source story variation is present`).toHaveAttribute(
      "data-scenario-id",
      scenario.id
    );
    await expect(story.getByTestId("inbound-detail-header")).toBeVisible();
    await expect(story.getByTestId("inbound-evidence-card")).toBeVisible();
  }
});
