const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_MANIFEST = path.resolve(__dirname, "../../../persona_spec/quick_view_scenarios.json");

const STORY = {
  path: "/dev/storybook/preview_authoring",
  leaf: "preview_authoring",
  owner: "preview-authoring-story",
  picker: "preview-authoring-review-theme",
  story: "preview-authoring-story",
  // Production roots that must render inside every variation.
  roots: ["preview-assigns-form", "preview-email-menu-trigger"]
};

test("Phase 178 retained Preview authoring stories render through production components", async ({ page }) => {
  const manifest = JSON.parse(fs.readFileSync(SCENARIO_MANIFEST, "utf8"));
  const scenarios = manifest.scenarios.filter(scenario => scenario.id.startsWith("preview-authoring-"));

  // The ExUnit manifest test pins the exact set; the browser proves every manifest row has a frame.
  expect(scenarios.length, "manifest carries retained Preview authoring rows").toBeGreaterThan(0);
  expect(new Set(scenarios.map(scenario => scenario.id)).size).toBe(scenarios.length);
  expect(new Set(scenarios.map(scenario => scenario.variation_id)).size).toBe(scenarios.length);

  for (const scenario of scenarios) {
    expect(scenario.story_path).toBe(STORY.path);
    expect(scenario.theme_owner).toBe(STORY.owner);
    expect(scenario.theme_picker_testid).toBe(STORY.picker);
    expect(scenario.variation_id).toBeTruthy();
    expect(scenario.role_job).toBeTruthy();
    expect(scenario.source.length).toBeGreaterThan(0);
    expect(scenario.state).toBeTruthy();
    expect(scenario.reason).toBeTruthy();
    expect(scenario.owning_requirements).toContain("STORY-07");
    expect(scenario.proof_boundary).toBe("story-render-only");
  }

  // Stories prove rendering only; the Storybook axe sweep pins its selection at 20 entries.
  expect(manifest.axe_selection.length).toBe(20);
  expect(manifest.axe_selection.filter(entry => /^preview-authoring-/.test(entry.scenario_id))).toEqual([]);

  const response = await page.goto(STORY.path);
  expect(response?.status(), `${STORY.path} loads`).toBe(200);

  // One iframe per manifest row, no more: a story variation without a manifest row fails here too.
  await expect
    .poll(() => page.locator(`iframe[id^="iframe-storybook_${STORY.leaf}-variation-"]`).count(), {
      message: `${STORY.path} renders exactly one iframe per retained variation`
    })
    .toBe(scenarios.length);

  for (const scenario of scenarios) {
    // Storybook re-renders iframe ids after hydration (a theme suffix is appended), so resolve
    // each frame by the stable `iframe-storybook_<story>-variation-<id>` prefix at use time.
    const prefix = `iframe-storybook_${STORY.leaf}-variation-${scenario.variation_id}`;
    await expect(page.locator(`iframe[id^="${prefix}"]`), `${scenario.id} has exactly one story iframe`).toHaveCount(1);

    const frame = page.frameLocator(`iframe[id^="${prefix}"]`);
    const root = frame.getByTestId(STORY.story);
    await expect(root, `${scenario.id} current-source story variation is present`).toHaveAttribute(
      "data-scenario-id",
      scenario.id
    );
    await expect(root).toHaveAttribute("data-state", scenario.state);
    await expect(frame.locator(`[data-theme-owner="${STORY.owner}"]`)).toHaveCount(1);
    await expect(frame.getByTestId(STORY.picker)).toBeVisible();
    for (const testid of STORY.roots) {
      await expect(root.getByTestId(testid).first(), `${scenario.id} renders ${testid}`).toBeVisible();
    }
  }
});
