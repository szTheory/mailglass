const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const fs = require("node:fs");
const path = require("node:path");

const SCENARIO_PATH = path.resolve(
  __dirname,
  "../../reference/persona_spec/quick_view_scenarios.json"
);
const REPORT_PATH = process.env.STORYBOOK_AXE_REPORT
  ? path.isAbsolute(process.env.STORYBOOK_AXE_REPORT)
    ? process.env.STORYBOOK_AXE_REPORT
    : path.resolve(__dirname, "..", process.env.STORYBOOK_AXE_REPORT)
  : path.resolve(__dirname, "..", "test-results", "phase174-storybook-axe.json");
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const EXECUTION_TOKEN = process.env.STORYBOOK_AXE_EXECUTION_TOKEN || null;
const MANIFEST = JSON.parse(fs.readFileSync(SCENARIO_PATH, "utf8"));
const SCENARIOS = new Map((MANIFEST.scenarios || []).map(scenario => [scenario.id, scenario]));
const SELECTION = MANIFEST.axe_selection || [];

function selectedCases() {
  const selectedVariants = SELECTION.filter(entry => entry.selected === true);
  const emptyRouteOnly = SELECTION.filter(
    entry => entry.selected === false && entry.proof_boundary === "connected-real-route-only"
  );

  if (selectedVariants.length !== 9) {
    throw new Error(`Expected 9 selected rendered variants, received ${selectedVariants.length}`);
  }
  if (emptyRouteOnly.length !== 2 || emptyRouteOnly.some(entry => !entry.reason)) {
    throw new Error("Both unselected empty cases must retain their connected-real-route-only proof boundary and reason");
  }
  if (
    emptyRouteOnly.some(entry => {
      const scenario = SCENARIOS.get(entry.scenario_id);
      return (
        entry.state !== "empty" ||
        !scenario ||
        scenario.state !== "empty" ||
        scenario.rendered !== false ||
        scenario.story_path !== null ||
        scenario.variation_id !== null
      );
    })
  ) {
    throw new Error("The two excluded empty cases must remain unrendered real-route-only scenarios");
  }

  const cases = selectedVariants.flatMap(selection => {
    const scenario = SCENARIOS.get(selection.scenario_id);
    if (
      !scenario ||
      scenario.rendered !== true ||
      scenario.state !== selection.state ||
      !scenario.story_path ||
      !scenario.variation_id ||
      !Array.isArray(selection.themes) ||
      selection.themes.length !== 2 ||
      selection.themes.some(theme => !["light", "dark"].includes(theme)) ||
      selection.root_selector !== ".mg-admin-root"
    ) {
      throw new Error(`Invalid selected Storybook execution identity: ${selection.scenario_id}`);
    }
    return selection.themes.map(theme => ({
      case_id: `${selection.scenario_id}::${selection.state}::${theme}`,
      scenario_id: selection.scenario_id,
      state: selection.state,
      theme,
      story_path: scenario.story_path,
      variation_id: scenario.variation_id,
      root_selector: selection.root_selector
    }));
  });

  if (cases.length !== 18 || new Set(cases.map(item => item.case_id)).size !== 18) {
    throw new Error(`Expected 18 unique selected Storybook cases, received ${cases.length}`);
  }
  return { cases, emptyRouteOnly };
}

const { cases: EXPECTED_CASES, emptyRouteOnly: EXCLUDED_CASES } = selectedCases();
const freshReport = {
  schema_version: 1,
  run_id: process.env.STORYBOOK_AXE_RUN_ID || null,
  producer_execution_token: EXECUTION_TOKEN,
  source_revision: process.env.STORYBOOK_SOURCE_REVISION || null,
  source_digest: process.env.STORYBOOK_SOURCE_DIGEST || null,
  started_at: new Date().toISOString(),
  completed_at: null,
  expected: EXPECTED_CASES.map(({ case_id, scenario_id, state, theme }) => ({
    case_id,
    scenario_id,
    state,
    theme
  })),
  excluded: EXCLUDED_CASES.map(({ scenario_id, state, proof_boundary, reason }) => ({
    scenario_id,
    state,
    proof_boundary,
    reason
  })),
  executed: [],
  violations: [],
  incomplete: []
};

function readMatchingProgress() {
  if (!fs.existsSync(REPORT_PATH)) return null;
  try {
    const previous = JSON.parse(fs.readFileSync(REPORT_PATH, "utf8"));
    const sameExecution =
      previous.schema_version === freshReport.schema_version &&
      previous.run_id === freshReport.run_id &&
      previous.producer_execution_token === freshReport.producer_execution_token &&
      previous.source_revision === freshReport.source_revision &&
      previous.source_digest === freshReport.source_digest &&
      previous.completed_at === null &&
      JSON.stringify(previous.expected) === JSON.stringify(freshReport.expected) &&
      JSON.stringify(previous.excluded) === JSON.stringify(freshReport.excluded);
    return sameExecution ? previous : null;
  } catch (_error) {
    return null;
  }
}

const report = readMatchingProgress() || freshReport;

function normalizeTarget(target) {
  const candidates = Array.isArray(target) ? target : [target];
  return candidates
    .map(candidate =>
      (Array.isArray(candidate) ? candidate : [candidate])
        .map(selector => String(selector).trim())
        .filter(Boolean)
    )
    .filter(candidate => candidate.length > 0)
    .sort((left, right) => JSON.stringify(left).localeCompare(JSON.stringify(right)));
}

function safeFindings(results, item, collection) {
  const findings = [];
  for (const violation of results[collection] || []) {
    const targets = new Map();
    for (const node of violation.nodes || []) {
      const target = normalizeTarget(node.target);
      const fingerprint = JSON.stringify(target);
      const existing = targets.get(fingerprint);
      targets.set(fingerprint, {
        rule_id: violation.id,
        target,
        scenario_id: item.scenario_id,
        state: item.state,
        theme: item.theme,
        impact: node.impact || violation.impact || null,
        count: (existing?.count || 0) + 1
      });
    }
    findings.push(...targets.values());
  }
  return findings;
}

function persistReport(complete = false) {
  report.completed_at = complete ? new Date().toISOString() : null;
  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });
}

test.afterAll(() => {
  persistReport(report.executed.length === report.expected.length);
});

for (const item of EXPECTED_CASES) {
  test(`Phase174 selected axe / ${item.scenario_id} / ${item.theme}`, async ({ page }) => {
    const execution = {
      case_id: item.case_id,
      scenario_id: item.scenario_id,
      state: item.state,
      theme: item.theme,
      status: "failed",
      completed_at: null
    };
    report.executed.push(execution);
    let failureStage = "identity";

    try {
      if (!report.run_id || !report.source_revision || !report.source_digest) {
        throw new Error("STORYBOOK_AXE_RUN_ID, STORYBOOK_SOURCE_REVISION and STORYBOOK_SOURCE_DIGEST are required");
      }

      await page.addInitScript(() => {
        window.__phase174RuntimeErrorCount = 0;
        window.addEventListener("error", () => {
          window.__phase174RuntimeErrorCount += 1;
        });
        window.addEventListener("unhandledrejection", () => {
          window.__phase174RuntimeErrorCount += 1;
        });
      });
      await page.emulateMedia({ colorScheme: item.theme });
      const storyURL = new URL(item.story_path, process.env.STORYBOOK_BASE_URL);
      storyURL.searchParams.set("variation_id", item.variation_id);
      failureStage = "story route load";
      const response = await page.goto(storyURL.href, { waitUntil: "load" });
      expect(response?.ok(), "the selected Storybook story route responds successfully").toBe(true);

      const frameSelector = `iframe[id*="${item.variation_id}"]`;
      const productionRootSelector =
        `${item.root_selector}[data-theme-owner="quick-view-story"]`;
      failureStage = "selected iframe readiness";
      await page.waitForFunction(
        ({ selector, rootSelector }) => {
          const iframe = document.querySelector(selector);
          const frameDocument = iframe?.contentDocument;
          return Boolean(
            frameDocument?.readyState === "complete" &&
              frameDocument.querySelector(rootSelector)
          );
        },
        { selector: frameSelector, rootSelector: productionRootSelector }
      );
      const storyFrame = page.frameLocator(frameSelector);
      const root = storyFrame.locator(productionRootSelector);
      failureStage = "production root verification";
      await expect(root).toBeVisible();
      await expect(root).toHaveAttribute("data-theme-owner", "quick-view-story");
      await expect(root).toHaveAttribute("data-theme", `mailglass-${item.theme}`);
      const theme = storyFrame.getByRole("radio", { name: item.theme === "light" ? "Light" : "Dark", exact: true });
      failureStage = "story theme readiness";
      await expect.poll(
        () => theme.evaluate(input => {
          input.checked = true;
          input.dispatchEvent(new Event("change", { bubbles: true }));
          return input.closest('[data-theme-owner="quick-view-story"]')?.dataset.themePreference;
        }),
        { message: "the story-local theme owner handles the selected preference" }
      ).toBe(item.theme);
      await expect(root).toHaveAttribute("data-theme", `mailglass-${item.theme}`);
      const dialog = root.getByRole("dialog", { name: "Quick view" });
      failureStage = "quick-view state verification";
      await expect(dialog).toBeVisible();
      const position = SCENARIOS.get(item.scenario_id).projection?.position;
      if (position) {
        await expect(dialog.locator("[aria-live='polite']")).toHaveText(
          `${position.index} of ${position.total}`
        );
      } else {
        await expect(dialog.locator('[data-testid="inbound-quick-view-error"]')).toBeVisible();
      }
      await root.evaluate(async element => {
        await element.ownerDocument.fonts.ready;
      });
      failureStage = "selected iframe runtime check";
      const frameRuntimeErrorCount = await root.evaluate(
        element => element.ownerDocument.defaultView.__phase174RuntimeErrorCount || 0
      );
      expect(frameRuntimeErrorCount, "the selected story iframe has no runtime errors").toBe(0);

      failureStage = "axe analysis";
      const results = await new AxeBuilder({ page })
        .include([frameSelector, productionRootSelector])
        .withTags(WCAG_TAGS)
        .analyze();
      report.violations.push(...safeFindings(results, item, "violations"));
      report.incomplete.push(
        ...safeFindings(results, item, "incomplete").map(finding => ({
          ...finding,
          reason: "Axe returned an incomplete result requiring triage.",
          disposition: "untriaged",
          evidence: report.run_id
        }))
      );
      execution.status = "passed";
    } catch (error) {
      execution.failure_stage = failureStage;
      execution.error = error.name || "Error";
      throw error;
    } finally {
      execution.completed_at = new Date().toISOString();
      persistReport(report.executed.length === report.expected.length);
    }
  });
}
