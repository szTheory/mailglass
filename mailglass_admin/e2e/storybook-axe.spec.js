const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const { selectedCases, normalizeTarget, validateReport, compareFindings } = require("./support/storybook-axe.cjs");
const { verifyStoryAccessibility } = require("./support/storybook-axe-supplement.cjs");
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
  : path.resolve(__dirname, "..", "test-results", "phase175-storybook-axe.json");
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const EXECUTION_TOKEN = process.env.STORYBOOK_AXE_EXECUTION_TOKEN || null;
const MANIFEST = JSON.parse(fs.readFileSync(SCENARIO_PATH, "utf8"));
const SCENARIOS = new Map((MANIFEST.scenarios || []).map(scenario => [scenario.id, scenario]));
const APPROVED_PATH = path.resolve(__dirname, "..", "docs", "storybook-axe-approved.json");
const APPROVED = JSON.parse(fs.readFileSync(APPROVED_PATH, "utf8"));
const { cases: EXPECTED_CASES, emptyRouteOnly: EXCLUDED_CASES } = selectedCases(MANIFEST);
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
  incomplete: [],
  supplemental: []
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

async function waitForSelectedStory(page, args) {
  const ready = await page.waitForFunction(({ frameSelector, rootSelector, theme, expectedPosition,
    errorSelector, expectedUnavailable, owner, pickerTestId, dialogTitle, dialogRequired }) => {
    const frames = document.querySelectorAll(frameSelector);
    if (frames.length !== 1) return false;
    const iframe = frames[0];
    // Scroll within the same parent-document readiness poll so a LiveView
    // remount cannot leave a stale element handle between wait and action.
    iframe.scrollIntoView({ block: "center" });
    const frameDocument = iframe?.contentDocument;
    const root = frameDocument?.querySelector(rootSelector);
    if (!iframe || !frameDocument || frameDocument.readyState !== "complete" || !root) {
      window.__phase174StableStoryFrame = null;
      return false;
    }

    const themeGroup = root.querySelector(`[data-testid="${pickerTestId}"]`);
    const radio = [...(themeGroup?.querySelectorAll('input[type="radio"]') || [])]
      .find(input => input.value === theme);
    if (!radio) return false;
    if (
      !radio.checked ||
      root.dataset.themePreference !== theme ||
      root.dataset.theme !== `mailglass-${theme}`
    ) {
      radio.checked = true;
      radio.dispatchEvent(new frameDocument.defaultView.Event("change", { bubbles: true }));
      window.__phase174StableStoryFrame = null;
      return false;
    }

    const dialog = root.querySelector('[role="dialog"]');
    const titleId = dialog?.getAttribute("aria-labelledby");
    const title = titleId && frameDocument.getElementById(titleId);
    const style = dialog && frameDocument.defaultView.getComputedStyle(dialog);
    const visible = Boolean(
      dialog &&
      title?.textContent.trim() === dialogTitle &&
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      dialog.getBoundingClientRect().width > 0 &&
      dialog.getBoundingClientRect().height > 0
    );
    if (dialogRequired ? !visible : visible) return false;
    if (!dialogRequired && !root.querySelector("main")) return false;
    if (dialogRequired && dialog.getAnimations().some(animation => animation.playState !== "finished")) return false;

    if (expectedPosition) {
      if (dialog.querySelector("[aria-live='polite']")?.textContent.trim() !== expectedPosition) return false;
    } else if (expectedUnavailable && !dialog.querySelector(errorSelector)) {
      return false;
    }

    if (frameDocument.fonts && frameDocument.fonts.status !== "loaded") return false;
    const currentFrames = document.querySelectorAll(frameSelector);
    if (currentFrames.length !== 1 || currentFrames[0] !== iframe || iframe.contentDocument !== frameDocument) {
      window.__phase174StableStoryFrame = null;
      return false;
    }
    const previous = window.__phase174StableStoryFrame;
    if (previous?.iframe !== iframe || previous?.frameDocument !== frameDocument) {
      window.__phase174StableStoryFrame = { iframe, frameDocument };
      return false;
    }

    return {
      owner: root.dataset.themeOwner,
      themePreference: root.dataset.themePreference,
      theme: root.dataset.theme,
      runtimeErrorCount: frameDocument.defaultView.__phase174RuntimeErrorCount || 0
    };
  }, args, { timeout: 30_000 });
  return ready.jsonValue();
}

function persistReport(complete = false) {
  report.completed_at = complete ? new Date().toISOString() : null;
  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  fs.writeFileSync(REPORT_PATH, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });
}

test.afterAll(() => {
  persistReport(report.executed.length === report.expected.length);
  const validation = validateReport(report, {
    manifest: MANIFEST,
    runId: process.env.STORYBOOK_AXE_RUN_ID,
    revision: process.env.STORYBOOK_SOURCE_REVISION,
    sourceDigest: process.env.STORYBOOK_SOURCE_DIGEST,
    approval: APPROVED
  });
  const comparison = compareFindings(report, APPROVED);
  const errors = [...validation.errors, ...comparison.errors];
  if (errors.length > 0) {
    throw new Error(
        `Phase 175 selected axe report rejected (${validation.metrics.expected} expected, ` +
        `${validation.metrics.successful} successful, ${comparison.metrics.unapproved} unapproved, ` +
        `${comparison.metrics.untriaged} untriaged): ${errors.join("; ")}`
    );
  }
});

for (const item of EXPECTED_CASES) {
  test(`Phase 175 selected Axe / ${item.scenario_id} / ${item.theme}`, async ({ page }) => {
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
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

      const storyArea = item.story_path.replace(/^\/dev\/storybook\//, "").split("/").join("_");
      const frameIdPrefix = `iframe-storybook_${storyArea}-variation-${item.variation_id}`;
      const frameSelector = `iframe[id^="${frameIdPrefix}"]`;
      const scenario = SCENARIOS.get(item.scenario_id);
      const owner = scenario.theme_owner || "quick-view-story";
      const pickerTestId = scenario.theme_picker_testid || "quick-view-review-theme";
      const dialogTitle = scenario.dialog_title || "Quick view";
      const dialogRequired = scenario.projection?.["modal_open?"] !== false;
      const productionRootSelector = `${item.root_selector}[data-theme-owner="${owner}"]`;
      failureStage = "selected iframe readiness";
      const position = owner === "quick-view-story" ? scenario.projection?.position : null;
      failureStage = "production root, theme and quick-view state verification";
      const storyState = await waitForSelectedStory(page, {
        frameSelector,
        rootSelector: productionRootSelector,
        theme: item.theme,
        expectedPosition: position ? `${position.index} of ${position.total}` : null,
        errorSelector: '[data-testid="inbound-quick-view-error"]',
        expectedUnavailable: owner === "quick-view-story" && !position,
        owner,
        pickerTestId,
        dialogTitle,
        dialogRequired
      });
      expect(storyState.owner, "the selected production root owns its local theme").toBe(owner);
      expect(storyState.themePreference, "the selected radio preference is applied locally").toBe(item.theme);
      expect(storyState.theme, "the selected production theme resolves correctly").toBe(`mailglass-${item.theme}`);
      failureStage = "selected iframe runtime check";
      expect(storyState.runtimeErrorCount, "the selected story iframe has no runtime errors").toBe(0);

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
      failureStage = "supplemental contrast, chrome and keyboard checks";
      const supplemental = await verifyStoryAccessibility(page, frameSelector,
        report.incomplete.filter(finding => finding.scenario_id === item.scenario_id && finding.theme === item.theme),
        { owner, pickerTestId, dialogTitle, dialogRequired });
      report.supplemental.push({ case_id: item.case_id, ...supplemental });
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
