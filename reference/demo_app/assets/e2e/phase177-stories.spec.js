const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_MANIFEST = path.resolve(__dirname, "../../../persona_spec/quick_view_scenarios.json");

// path -> {owner, picker, root testids that must render inside every variation}
const STORIES = {
  "/dev/storybook/health_overview": {
    owner: "health-overview-story",
    picker: "health-overview-review-theme",
    story: "health-overview-story",
    roots: ["operator-health-layout", "operator-health-status"]
  },
  "/dev/storybook/account_scope": {
    owner: "account-scope-story",
    picker: "account-scope-review-theme",
    story: "account-scope-story",
    roots: ["operator-account-context", "surface-nav-scope-group"]
  },
  "/dev/storybook/preview_chrome": {
    owner: "preview-chrome-story",
    picker: "preview-chrome-review-theme",
    story: "preview-chrome-story",
    roots: ["surface-nav-sidebar", "preview-scope-label"]
  }
};

const RETAINED_IDS = [
  "health-overview-northstar-normal",
  "health-overview-helios-empty",
  "health-overview-stale",
  "health-overview-unavailable",
  "health-overview-fjordline-long-unicode",
  "account-scope-none",
  "account-scope-one",
  "account-scope-many",
  "account-scope-long-label",
  "preview-chrome-valid-return",
  "preview-chrome-direct-entry"
];

test("Phase 177 retained Health and Account stories inventory and composition", async ({ page }) => {
  const manifest = JSON.parse(fs.readFileSync(SCENARIO_MANIFEST, "utf8"));
  const scenarios = manifest.scenarios.filter(scenario =>
    /^(health-overview-|account-scope-|preview-chrome-)/.test(scenario.id)
  );
  expect(scenarios.map(scenario => scenario.id).sort()).toEqual([...RETAINED_IDS].sort());
  expect(new Set(scenarios.map(scenario => scenario.id)).size).toBe(11);

  for (const scenario of scenarios) {
    const story = STORIES[scenario.story_path];
    expect(story, `${scenario.id} story path is a known Phase 177 story`).toBeTruthy();
    expect(scenario.theme_owner).toBe(story.owner);
    expect(scenario.theme_picker_testid).toBe(story.picker);
    expect(scenario.variation_id).toBeTruthy();
    expect(scenario.role_job).toBeTruthy();
    expect(scenario.source.length).toBeGreaterThan(0);
    expect(scenario.state).toBeTruthy();
    expect(scenario.reason).toBeTruthy();
    expect(scenario.owning_requirements.length).toBeGreaterThan(0);
    expect(scenario.proof_boundary).toBe("story-render-only");
  }

  // Stories prove rendering only; the Storybook axe sweep pins its selection at 20 entries.
  expect(manifest.axe_selection.length).toBe(20);
  expect(
    manifest.axe_selection.filter(entry =>
      /^(health-overview-|account-scope-|preview-chrome-)/.test(entry.scenario_id)
    )
  ).toEqual([]);

  for (const [storyPath, story] of Object.entries(STORIES)) {
    const response = await page.goto(storyPath);
    expect(response?.status(), `${storyPath} loads`).toBe(200);

    const expected = scenarios.filter(entry => entry.story_path === storyPath).length;
    await expect
      .poll(() => page.locator("iframe[id]").count(), {
        message: `${storyPath} renders one iframe per retained variation`
      })
      .toBeGreaterThanOrEqual(expected);

    for (const scenario of scenarios.filter(entry => entry.story_path === storyPath)) {
      // Storybook re-renders iframe ids after hydration (a theme suffix is appended), so resolve
      // each frame by the stable `iframe-storybook_<story>-variation-<id>` prefix at use time.
      // `variation-one` cannot match `variation-none`, the prefix includes the full variation id.
      const prefix = `iframe-storybook_${storyPath.split("/").pop()}-variation-${scenario.variation_id}`;
      const locator = page.locator(`iframe[id^="${prefix}"]`);
      await expect(locator, `${scenario.id} has exactly one story iframe`).toHaveCount(1);

      const frame = page.frameLocator(`iframe[id^="${prefix}"]`);
      const root = frame.getByTestId(story.story);
      await expect(root, `${scenario.id} current-source story variation is present`).toHaveAttribute(
        "data-scenario-id",
        scenario.id
      );
      await expect(root).toHaveAttribute("data-state", scenario.state);
      await expect(frame.getByTestId(story.picker)).toBeVisible();
      for (const testid of story.roots) {
        await expect(root.getByTestId(testid).first(), `${scenario.id} renders ${testid}`).toBeVisible();
      }
    }
  }
});
