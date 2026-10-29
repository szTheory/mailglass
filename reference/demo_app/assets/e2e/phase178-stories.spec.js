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

// UIQ-06 / D-07: the owner reported that the Storybook StatCard rendered in a serif face. The
// receipt compares computed font roles in the inline story block with the same component rendered
// by the production Admin gallery. Both pages are served by this demo from the same admin CSS
// bytes, so the comparison fails on any divergence, not only on a serif fallback.
const STATCARD = {
  path: "/dev/storybook/primitives/stat_card",
  gallery: "/dev/mail/gallery",
  galleryCell: "gallery-stat_card-neutral",
  cases: [
    { variation: "neutral_light", theme: "light" },
    { variation: "neutral_dark", theme: "dark" }
  ],
  productionFamilies: ["Inter", "Inter Tight", "IBM Plex Mono"],
  serifGenerics: ["serif", "georgia", "times", "times new roman", "cambria", "palatino"]
};

// Reads {family, weight} per role from the StatCard under `scope`, plus the faces in use.
async function readStatCardRoles(scope) {
  return scope.evaluate(async scope => {
    const view = scope.ownerDocument.defaultView;
    const document = scope.ownerDocument;
    const style = element => {
      const computed = view.getComputedStyle(element);
      return { family: computed.fontFamily, weight: computed.fontWeight };
    };
    const article = scope.querySelector("article");
    const label = article.querySelector("p span");
    const value = article.querySelector("p.mono");
    const roles = { ui: style(scope), label: style(label), value: style(value) };
    const firstFamily = family => family.split(",")[0].trim().replace(/^["']|["']$/g, "");
    const faces = [];
    for (const role of Object.keys(roles)) {
      const family = firstFamily(roles[role].family);
      const weight = roles[role].weight;
      await document.fonts.load(`${weight} 16px "${family}"`, "Mailglass 012345");
      const loaded = [...document.fonts].some(
        face =>
          face.family.replace(/["']/g, "") === family &&
          face.weight === String(weight) &&
          face.style === "normal" &&
          face.status === "loaded"
      );
      faces.push({
        role,
        family,
        weight,
        check: document.fonts.check(`${weight} 16px "${family}"`, "Mailglass 012345"),
        loaded
      });
    }
    return { roles, faces };
  });
}

test("Phase 178 StatCard story uses the production font roles", async ({ page }) => {
  const production = {};
  const galleryResponse = await page.goto(STATCARD.gallery);
  expect(galleryResponse?.status(), `${STATCARD.gallery} loads`).toBe(200);
  const cell = page.getByTestId(STATCARD.galleryCell);
  await expect(cell, "production gallery renders the neutral StatCard cell").toBeVisible();
  for (const { theme } of STATCARD.cases) {
    const wrapper = cell.locator(`[data-theme="mailglass-${theme}"]`).first();
    await expect(wrapper, `production ${theme} StatCard wrapper`).toBeVisible();
    production[theme] = await readStatCardRoles(await wrapper.elementHandle());
  }

  const response = await page.goto(STATCARD.path);
  expect(response?.status(), `${STATCARD.path} loads`).toBe(200);

  // The StatCard is a `:component` story without `container: :iframe`, so PhoenixStorybook renders
  // each variation inline in the explorer page, inside `.psb-sandbox` (the element the owner's
  // todo blames for the serif face). Resolve the variation block by its Storybook-generated id.
  const receipt = [];
  for (const { variation, theme } of STATCARD.cases) {
    const block = page.locator(`[id="${variation.replace(/_/g, "-")}-component"]`);
    await expect(block, `${variation} has exactly one inline story block`).toHaveCount(1);
    const wrapper = block.locator(`[data-theme="mailglass-${theme}"]`).first();
    await expect(wrapper.locator("article"), `${variation} renders the production StatCard`).toBeVisible();

    const story = await readStatCardRoles(await wrapper.elementHandle());
    const reference = production[theme];

    const sandboxFamily = await block.locator(".psb-sandbox").first().evaluate(node =>
      getComputedStyle(node).fontFamily.split(",")[0].trim().replace(/^["']|["']$/g, "")
    );
    expect(sandboxFamily, `${variation} .psb-sandbox first family is the production UI face`).toBe(
      reference.faces.find(face => face.role === "ui").family
    );

    for (const role of ["ui", "label", "value"]) {
      const storyFamily = story.roles[role].family.split(",")[0].trim().replace(/^["']|["']$/g, "");
      const productionFamily = reference.roles[role].family.split(",")[0].trim().replace(/^["']|["']$/g, "");
      expect(storyFamily, `${variation} ${role} first family matches production`).toBe(productionFamily);
      expect(story.roles[role].weight, `${variation} ${role} weight matches production`).toBe(
        reference.roles[role].weight
      );
      expect(
        STATCARD.productionFamilies,
        `${variation} ${role} resolves to a production face, not a fallback`
      ).toContain(storyFamily);
      expect(
        STATCARD.serifGenerics,
        `${variation} ${role} first family is not a serif`
      ).not.toContain(storyFamily.toLowerCase());
    }
    for (const face of [...story.faces, ...reference.faces]) {
      expect(face.check, `document.fonts.check ${face.role} ${face.weight} ${face.family}`).toBe(true);
      expect(face.loaded, `${face.role} ${face.weight} ${face.family} face is loaded`).toBe(true);
    }

    receipt.push({ variation, theme, story: story.roles, production: reference.roles });
  }

  test.info().annotations.push({ type: "statcard-font-roles", description: JSON.stringify(receipt) });
  console.log("PHASE178_STATCARD_RECEIPT " + JSON.stringify(receipt));
});
