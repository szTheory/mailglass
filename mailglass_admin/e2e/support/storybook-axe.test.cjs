const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { normalizeTarget, selectedCases, validateReport, compareFindings } = require("./storybook-axe.cjs");

const manifest = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, "../../../reference/persona_spec/quick_view_scenarios.json"),
    "utf8"
  )
);

const cases = manifest.axe_selection
  .filter(selection => selection.selected)
  .flatMap(selection =>
    selection.themes.map(theme => ({
      case_id: `${selection.scenario_id}::${selection.state}::${theme}`,
      scenario_id: selection.scenario_id,
      state: selection.state,
      theme
    }))
  );
const excluded = manifest.axe_selection
  .filter(selection => selection.selected === false)
  .map(selection => ({
    scenario_id: selection.scenario_id,
    state: selection.state,
    proof_boundary: selection.proof_boundary,
    reason: selection.reason
  }));
const firstCase = cases.find(item => item.case_id === "qv-delivery-normal::normal::light");
const context = {
  manifest,
  runId: "storybook-run-current",
  revision: "revision-current",
  sourceDigest: "digest-current"
};
const stamp = "2026-10-27T04:00:00.000Z";

test("Phase 175 selected Axe inventory executes 13 rendered variants in 26 theme cases", () => {
  let selected;
  try {
    selected = selectedCases(manifest);
  } catch (error) {
    assert.fail(`current selected Axe inventory is accepted: ${error.message}`);
  }
  assert.equal(selected.cases.length, 26);
  assert.equal(new Set(selected.cases.map(item => item.case_id)).size, 26);
  assert.equal(selected.emptyRouteOnly.length, 2);
});

function validReport(overrides = {}) {
  return {
    schema_version: 1,
    run_id: context.runId,
    source_revision: context.revision,
    source_digest: context.sourceDigest,
    started_at: stamp,
    completed_at: stamp,
    expected: structuredClone(cases),
    excluded: structuredClone(excluded),
    executed: cases.map(item => ({ ...item, status: "passed", completed_at: stamp })),
    violations: [],
    incomplete: [],
    ...overrides
  };
}

function finding(overrides = {}) {
  return {
    rule_id: "color-contrast",
    target: [[".badge"], ["#quick-view-normal-light"]],
    scenario_id: firstCase.scenario_id,
    state: firstCase.state,
    theme: firstCase.theme,
    impact: "serious",
    count: 1,
    ...overrides
  };
}

function supplement() {
  const bounds = (left, top, width, height) => ({ left, top, right: left + width, bottom: top + height, width, height });
  return cases.map(item => ({ case_id: item.case_id,
    chrome: { picker: bounds(8, 8, 240, 76), dialog: bounds(0, 96, 320, 504), viewport: 320,
      targets: [bounds(12, 32, 64, 44), bounds(80, 32, 64, 44), bounds(148, 32, 80, 44)] },
    focus_wrap: { forward: true, backward: true, controls: 3 }, contrasts: []
  }));
}

test("supplemental proof rejects missing coverage, overlap, clipped controls and broken focus", () => {
  const report = validReport({ supplemental: supplement() });
  assert.equal(validateReport(report, { ...context, approval: approvalFor() }).valid, true);
  for (const change of [
    report => report.supplemental.pop(),
    report => report.supplemental[0].chrome.picker.bottom = 120,
    report => report.supplemental[0].chrome.targets[0].width = 12,
    report => report.supplemental[0].focus_wrap.forward = false,
    report => report.supplemental[1].case_id = report.supplemental[0].case_id
  ]) {
    const bad = structuredClone(report);
    change(bad);
    assertInvalidValidation(bad, context, /supplemental/);
  }
});

test("supplemental contrast cannot omit a retained target or relax its threshold", () => {
  const prior = finding({ target: [[".badge"]], reason: "Unresolved by axe", disposition: "retained-incomplete", evidence: "storybook-run-prior" });
  const approval = approvalFor([], [prior]);
  const report = validReport({ supplemental: supplement() });
  assertInvalidValidation(report, context, /contrast targets/, approval);
  report.supplemental[0].contrasts = [{ target: ".badge", ratio: 4.6, minimum: 4.5, font_size: 14, font_weight: 400 }];
  assert.equal(validateReport(report, { ...context, approval }).valid, true);
  report.supplemental[0].contrasts[0].ratio = 4.499;
  assertInvalidValidation(report, context, /contrast is insufficient/, approval);
  report.supplemental[0].contrasts[0].minimum = 3;
  assertInvalidValidation(report, context, /contrast is insufficient/, approval);
});

function approvalFor(findings = [], incomplete = []) {
  return {
    schema_version: 1,
    review_basis: {
      run_id: "storybook-run-prior",
      source_revision: "revision-prior",
      source_digest: "digest-prior"
    },
    approved_fingerprints: findings.map(item => ({
      ...item,
      approval: {
        source: "independent reviewed decision",
        reviewer: "accessibility-review",
        reason: "Exact retained fingerprint for the test control.",
        approved_at: stamp
      }
    })),
    incomplete_triage: incomplete
  };
}

function assertInvalidValidation(report, opts = context, match, approval = approvalFor()) {
  const result = validateReport(report, { ...opts, approval });
  assert.equal(result.valid, false, `expected invalid report; errors were ${JSON.stringify(result.errors)}`);
  if (match) assert.match(result.errors.join("\n"), match);
}

function assertInvalidComparison(report, approval, match) {
  const result = compareFindings(report, approval);
  assert.equal(result.valid, false, `expected comparison failure; errors were ${JSON.stringify(result.errors)}`);
  if (match) assert.match(result.errors.join("\n"), match);
}

test("validateReport rejects a missing report before comparison", () => {
  assertInvalidValidation(null, context, /report/i);
});

test("validateReport rejects unsupported report schema", () => {
  assertInvalidValidation(validReport({ schema_version: 99 }), context, /schema/i);
});

test("validateReport rejects empty expected and executed sets", () => {
  assertInvalidValidation(validReport({ expected: [] }), context, /expected/i);
  assertInvalidValidation(validReport({ executed: [] }), context, /executed/i);
});

test("validateReport requires the exact nonempty manifest case set", () => {
  assertInvalidValidation(validReport({ expected: cases.slice(1) }), context, /missing/i);
  assertInvalidValidation(validReport({ expected: [...cases, { ...cases[0], case_id: "extra::case" }] }), context, /extra/i);
  assertInvalidValidation(validReport({ expected: [...cases, { ...cases[0] }] }), context, /duplicate/i);
});

test("validateReport requires one successful execution for every expected case", () => {
  const missing = validReport();
  missing.executed.pop();
  assertInvalidValidation(missing, context, /missing/i);

  const extra = validReport();
  extra.executed.push({ ...extra.executed[0], case_id: "extra::case" });
  assertInvalidValidation(extra, context, /extra/i);

  const duplicate = validReport();
  duplicate.executed.push({ ...duplicate.executed[0] });
  assertInvalidValidation(duplicate, context, /duplicate/i);
});

test("validateReport rejects failed, skipped and unfinished executions", () => {
  for (const status of ["failed", "skipped", "running"]) {
    const report = validReport();
    report.executed[0].status = status;
    report.executed[0].failure_stage = "axe analysis";
    report.executed[0].error = "Error";
    assertInvalidValidation(report, context, new RegExp(status));
  }
  const unfinished = validReport();
  unfinished.executed[0].completed_at = null;
  assertInvalidValidation(unfinished, context, /unfinished|completion/i);
});

test("validateReport rejects stale caller run, revision and digest identities", () => {
  assertInvalidValidation(validReport({ run_id: "stale-run" }), context, /run/i);
  assertInvalidValidation(validReport({ source_revision: "stale-revision" }), context, /revision/i);
  assertInvalidValidation(validReport({ source_digest: "stale-digest" }), context, /digest/i);
});

test("validateReport requires a completed report timestamp", () => {
  assertInvalidValidation(validReport({ completed_at: null }), context, /completion/i);
});

test("validateReport rejects the same evidence run on both sides of a comparison", () => {
  const report = validReport();
  const approval = approvalFor();
  approval.review_basis.run_id = report.run_id;
  assertInvalidValidation(report, context, /self|same.*run/i, approval);
});

test("normalizeTarget removes only a volatile Storybook host iframe selector", () => {
  assert.deepEqual(
    normalizeTarget([
      ["span[data-focus-trap=\"start\"]"],
      ["#iframe-storybook_quick_views_delivery-variation-northstar_normal-dark"]
    ]),
    [["span[data-focus-trap=\"start\"]"]]
  );
  assert.deepEqual(normalizeTarget([[".badge"]]), [[".badge"]]);
});

test("compareFindings rejects changed rules at a flat finding count", () => {
  const approved = finding();
  const report = validReport({ violations: [finding({ rule_id: "aria-prohibited-attr" })] });
  assertInvalidComparison(report, approvalFor([approved]), /unapproved|fingerprint/i);
});

test("compareFindings rejects changed targets at a flat finding count", () => {
  const approved = finding();
  const report = validReport({ violations: [finding({ target: [[".different-target"], ["#quick-view-normal-light"]] })] });
  assertInvalidComparison(report, approvalFor([approved]), /unapproved|fingerprint/i);
});

test("compareFindings rejects changed states at a flat finding count", () => {
  const approved = finding();
  const report = validReport({ violations: [finding({ state: "first" })] });
  assertInvalidComparison(report, approvalFor([approved]), /unapproved|fingerprint|expected/i);
});

test("compareFindings requires exact triage for every incomplete fingerprint", () => {
  const incomplete = finding({ rule_id: "color-contrast" });
  const report = validReport({ incomplete: [{ ...incomplete, reason: "Axe could not decide.", disposition: "untriaged", evidence: context.runId }] });
  assertInvalidComparison(report, approvalFor(), /untriaged|triage/i);

  const triage = {
    ...incomplete,
    reason: "Axe returned incomplete and no contrast pass is inferred.",
    disposition: "reviewed-incomplete-no-verdict",
    evidence: "storybook-run-prior"
  };
  assert.equal(compareFindings(report, approvalFor([], [triage])).valid, true);
  assertInvalidComparison(report, approvalFor([], [{ ...triage, evidence: "unrelated-run" }]), /review_basis/i);
});

test("compareFindings rejects a report used as its own approval evidence", () => {
  const report = validReport();
  const approval = approvalFor();
  approval.review_basis.run_id = report.run_id;
  assertInvalidComparison(report, approval, /self|same.*run/i);
});

test("compareFindings passes an unchanged exact independently approved fingerprint", () => {
  const unchanged = finding();
  const report = validReport({ violations: [unchanged] });
  assert.equal(compareFindings(report, approvalFor([unchanged])).valid, true);
});

test("compareFindings passes an improved report with no findings", () => {
  assert.equal(compareFindings(validReport(), approvalFor([finding()])).valid, true);
});

test("CLI prints execution counts and rejects a missing report file", () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "phase174-axe-cli-"));
  try {
    const reportPath = path.join(tempDir, "report.json");
    const approvalPath = path.join(tempDir, "approved.json");
    const manifestPath = path.join(tempDir, "manifest.json");
    fs.writeFileSync(reportPath, JSON.stringify(validReport()));
    fs.writeFileSync(approvalPath, JSON.stringify(approvalFor()));
    fs.writeFileSync(manifestPath, JSON.stringify(manifest));
    const cliPath = path.resolve(__dirname, "storybook-axe.cjs");
    const args = [
      cliPath,
      "--report", reportPath,
      "--approved", approvalPath,
      "--manifest", manifestPath,
      "--run-id", context.runId,
      "--revision", context.revision,
      "--source-digest", context.sourceDigest
    ];
    const success = spawnSync(process.execPath, args, { encoding: "utf8" });
    assert.equal(success.status, 0, success.stderr);
    assert.deepEqual(JSON.parse(success.stdout), {
      expected: 18,
      executed: 18,
      successful: 18,
      failed: 0,
      missing: 0,
      incomplete: 0,
      violations: 0,
      unapproved: 0,
      untriaged: 0,
      valid: true
    });

    const missing = spawnSync(process.execPath, [
      ...args.slice(0, 2),
      path.join(tempDir, "missing.json"),
      ...args.slice(3)
    ], { encoding: "utf8" });
    assert.notEqual(missing.status, 0);
    assert.match(missing.stderr, /report could not be read/i);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
