const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { validateReport, compareFindings } = require("./storybook-axe.cjs");

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
