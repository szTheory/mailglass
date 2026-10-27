#!/usr/bin/env node

const fs = require("node:fs");

const REPORT_SCHEMA_VERSION = 1;
const APPROVAL_SCHEMA_VERSION = 1;
const SELECTED_VARIANTS = 9;
const SELECTED_CASES = 18;
const EMPTY_ROUTE_ONLY_CASES = 2;

const CASE_KEYS = ["case_id", "scenario_id", "state", "theme"];
const EXCLUDED_KEYS = ["scenario_id", "state", "proof_boundary", "reason"];
const FINDING_KEYS = ["rule_id", "target", "scenario_id", "state", "theme", "impact", "count"];

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isTimestamp(value) {
  return typeof value === "string" && Number.isFinite(Date.parse(value));
}

function nonempty(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function exactKeys(value, keys) {
  return isRecord(value) && Object.keys(value).sort().join("\0") === [...keys].sort().join("\0");
}

function caseId(item) {
  return `${item.scenario_id}::${item.state}::${item.theme}`;
}

function normalizeTarget(target) {
  const candidates = Array.isArray(target) ? target : [target];
  const normalized = candidates
    .map(candidate =>
      (Array.isArray(candidate) ? candidate : [candidate])
        .map(selector => String(selector).trim())
        .filter(Boolean)
    )
    .filter(candidate => candidate.length > 0)
    // Storybook's host-generated iframe id can gain or lose a theme suffix
    // across equivalent mounts. The report already carries scenario/state/theme
    // identity, so retain the stable selector inside the story document.
    .filter(candidate => !candidate.every(selector => /^#iframe-storybook_quick_views_/.test(selector)))
    .sort((left, right) => JSON.stringify(left).localeCompare(JSON.stringify(right)));
  return normalized.length > 0 ? normalized : candidates.map(candidate => (Array.isArray(candidate) ? candidate : [candidate]));
}

function selectedCases(manifest) {
  if (!isRecord(manifest) || !Array.isArray(manifest.scenarios) || !Array.isArray(manifest.axe_selection)) {
    throw new Error("manifest must contain scenario and axe_selection arrays");
  }

  const scenarios = new Map();
  for (const scenario of manifest.scenarios) {
    if (!isRecord(scenario) || !nonempty(scenario.id) || scenarios.has(scenario.id)) {
      throw new Error("manifest scenarios must have unique nonempty ids");
    }
    scenarios.set(scenario.id, scenario);
  }

  const selected = manifest.axe_selection.filter(entry => entry?.selected === true);
  const emptyRouteOnly = manifest.axe_selection.filter(
    entry => entry?.selected === false && entry?.proof_boundary === "connected-real-route-only"
  );
  if (selected.length !== SELECTED_VARIANTS) {
    throw new Error(`expected ${SELECTED_VARIANTS} selected rendered variants, received ${selected.length}`);
  }
  if (
    emptyRouteOnly.length !== EMPTY_ROUTE_ONLY_CASES ||
    emptyRouteOnly.some(entry => !nonempty(entry.reason))
  ) {
    throw new Error("both empty route-only cases must retain a proof boundary and reason");
  }
  for (const entry of emptyRouteOnly) {
    const scenario = scenarios.get(entry.scenario_id);
    if (
      entry.state !== "empty" ||
      !scenario ||
      scenario.state !== "empty" ||
      scenario.rendered !== false ||
      scenario.story_path !== null ||
      scenario.variation_id !== null
    ) {
      throw new Error(`invalid empty route-only manifest case ${entry.scenario_id}`);
    }
  }

  const cases = selected.flatMap(entry => {
    const scenario = scenarios.get(entry.scenario_id);
    if (
      !scenario ||
      scenario.rendered !== true ||
      scenario.state !== entry.state ||
      !nonempty(scenario.story_path) ||
      !nonempty(scenario.variation_id) ||
      !Array.isArray(entry.themes) ||
      entry.themes.length !== 2 ||
      new Set(entry.themes).size !== 2 ||
      entry.themes.some(theme => theme !== "light" && theme !== "dark") ||
      entry.root_selector !== ".mg-admin-root"
    ) {
      throw new Error(`invalid selected Storybook execution identity ${entry.scenario_id}`);
    }
    return entry.themes.map(theme => ({
      case_id: `${entry.scenario_id}::${entry.state}::${theme}`,
      scenario_id: entry.scenario_id,
      state: entry.state,
      theme,
      story_path: scenario.story_path,
      variation_id: scenario.variation_id,
      root_selector: entry.root_selector
    }));
  });

  const ids = cases.map(item => item.case_id);
  if (cases.length !== SELECTED_CASES || new Set(ids).size !== SELECTED_CASES) {
    throw new Error(`expected ${SELECTED_CASES} unique selected cases, received ${cases.length}`);
  }
  return { cases, emptyRouteOnly };
}

function asExpectedCase(item) {
  return {
    case_id: item.case_id,
    scenario_id: item.scenario_id,
    state: item.state,
    theme: item.theme
  };
}

function asExcludedCase(item) {
  return {
    scenario_id: item.scenario_id,
    state: item.state,
    proof_boundary: item.proof_boundary,
    reason: item.reason
  };
}

function fingerprint(item) {
  return JSON.stringify({
    rule_id: item.rule_id,
    target: item.target,
    scenario_id: item.scenario_id,
    state: item.state,
    theme: item.theme
  });
}

function findingShape(item, collection, errors, expectedIds) {
  const allowedKeys = collection === "incomplete" ? [...FINDING_KEYS, "reason", "disposition", "evidence"] : FINDING_KEYS;
  if (!exactKeys(item, allowedKeys)) {
    errors.push(`${collection} finding has an invalid or unsafe field set`);
    return;
  }
  if (!nonempty(item.rule_id) || !nonempty(item.scenario_id) || !nonempty(item.state) || !["light", "dark"].includes(item.theme)) {
    errors.push(`${collection} finding is missing rule or case identity`);
  }
  if (expectedIds && !expectedIds.has(caseId(item))) {
    errors.push(`${collection} finding refers to an unexpected case ${caseId(item)}`);
  }
  if (
    !Array.isArray(item.target) ||
    item.target.length === 0 ||
    item.target.some(chain => !Array.isArray(chain) || chain.length === 0 || chain.some(selector => !nonempty(selector)))
  ) {
    errors.push(`${collection} finding has an invalid stable selector target`);
  }
  if (!Number.isInteger(item.count) || item.count < 1) errors.push(`${collection} finding count must be a positive integer`);
  if (item.impact !== null && !nonempty(item.impact)) errors.push(`${collection} finding impact must be a string or null`);
  if (collection === "incomplete" && (!nonempty(item.reason) || !nonempty(item.disposition) || !nonempty(item.evidence))) {
    errors.push("incomplete finding must preserve its reason, disposition and evidence");
  }
}

function validateReport(report, options = {}) {
  const errors = [];
  const metrics = {
    expected: Array.isArray(report?.expected) ? report.expected.length : 0,
    executed: Array.isArray(report?.executed) ? report.executed.length : 0,
    successful: Array.isArray(report?.executed) ? report.executed.filter(item => item?.status === "passed").length : 0,
    failed: Array.isArray(report?.executed) ? report.executed.filter(item => item?.status !== "passed").length : 0,
    missing: 0,
    incomplete: Array.isArray(report?.incomplete) ? report.incomplete.length : 0
  };

  if (!isRecord(report)) {
    return { valid: false, errors: ["report is missing or is not an object"], metrics };
  }
  if (report.schema_version !== REPORT_SCHEMA_VERSION) errors.push(`unsupported report schema_version ${String(report.schema_version)}`);
  if (!nonempty(options.runId) || !nonempty(options.revision) || !nonempty(options.sourceDigest)) {
    errors.push("independent caller run id, revision and source digest are required");
  }
  if (report.run_id !== options.runId) errors.push("report run_id does not match caller run id");
  if (report.source_revision !== options.revision) errors.push("report source_revision does not match caller revision");
  if (report.source_digest !== options.sourceDigest) errors.push("report source_digest does not match caller digest");
  if (!isTimestamp(report.started_at)) errors.push("report start timestamp is missing or invalid");
  if (!isTimestamp(report.completed_at)) errors.push("report completion timestamp is missing or invalid");

  let manifestCases = [];
  let exclusions = [];
  try {
    const selected = selectedCases(options.manifest);
    manifestCases = selected.cases.map(asExpectedCase);
    exclusions = selected.emptyRouteOnly.map(asExcludedCase);
  } catch (error) {
    errors.push(`manifest invalid: ${error.message}`);
  }

  const expectedIds = new Set(manifestCases.map(item => item.case_id));
  const expectedRows = Array.isArray(report.expected) ? report.expected : [];
  if (expectedRows.length === 0) errors.push("report expected set is empty");
  const expectedSeen = new Set();
  for (const row of expectedRows) {
    if (!exactKeys(row, CASE_KEYS)) {
      errors.push("expected case has an invalid schema");
      continue;
    }
    if (expectedSeen.has(row.case_id)) errors.push(`duplicate expected case ${row.case_id}`);
    expectedSeen.add(row.case_id);
    const declared = manifestCases.find(item => item.case_id === row.case_id);
    if (!declared) errors.push(`extra expected case ${row.case_id}`);
    else if (JSON.stringify(row) !== JSON.stringify(declared)) errors.push(`expected identity changed for ${row.case_id}`);
  }
  for (const row of manifestCases) if (!expectedSeen.has(row.case_id)) errors.push(`missing expected case ${row.case_id}`);

  if (!Array.isArray(report.excluded) || JSON.stringify(report.excluded) !== JSON.stringify(exclusions)) {
    errors.push("excluded route-only cases do not match the manifest proof boundaries");
  }

  const executions = Array.isArray(report.executed) ? report.executed : [];
  if (executions.length === 0) errors.push("report executed set is empty");
  const executedSeen = new Set();
  for (const execution of executions) {
    const allowed = ["case_id", "scenario_id", "state", "theme", "status", "completed_at"];
    if (execution?.status !== "passed") allowed.push("failure_stage", "error");
    if (!exactKeys(execution, allowed)) {
      errors.push("execution record has an invalid schema");
      continue;
    }
    if (executedSeen.has(execution.case_id)) errors.push(`duplicate executed case ${execution.case_id}`);
    executedSeen.add(execution.case_id);
    if (!expectedIds.has(execution.case_id)) errors.push(`extra executed case ${execution.case_id}`);
    const declared = manifestCases.find(item => item.case_id === execution.case_id);
    if (declared && CASE_KEYS.some(key => execution[key] !== declared[key])) errors.push(`execution identity changed for ${execution.case_id}`);
    if (execution.status !== "passed") errors.push(`execution ${execution.case_id} is ${String(execution.status)}`);
    if (!isTimestamp(execution.completed_at)) errors.push(`execution ${execution.case_id} is unfinished`);
  }
  for (const row of manifestCases) if (!executedSeen.has(row.case_id)) errors.push(`missing executed case ${row.case_id}`);
  metrics.missing = manifestCases.filter(row => !executedSeen.has(row.case_id)).length;

  const knownIds = new Set(manifestCases.map(item => item.case_id));
  for (const collection of ["violations", "incomplete"]) {
    const rows = report[collection];
    if (!Array.isArray(rows)) {
      errors.push(`${collection} must be an array`);
      continue;
    }
    const seen = new Set();
    for (const item of rows) {
      findingShape(item, collection, errors, knownIds);
      if (isRecord(item)) {
        const id = fingerprint(item);
        if (seen.has(id)) errors.push(`${collection} contains duplicate finding fingerprint`);
        seen.add(id);
      }
    }
  }

  if (options.approval?.review_basis?.run_id === report.run_id) {
    errors.push("report and approved findings use the same evidence run (self-comparison)");
  }
  return { valid: errors.length === 0, errors: [...new Set(errors)], metrics };
}

function validateApproval(approval) {
  const errors = [];
  if (!isRecord(approval)) return ["approved findings file is missing or is not an object"];
  if (approval.schema_version !== APPROVAL_SCHEMA_VERSION) errors.push("unsupported approved findings schema_version");
  if (
    !isRecord(approval.review_basis) ||
    !nonempty(approval.review_basis.run_id) ||
    !nonempty(approval.review_basis.source_revision) ||
    !nonempty(approval.review_basis.source_digest)
  ) {
    errors.push("approved findings need independent review_basis run, revision and digest");
  }
  if (!Array.isArray(approval.approved_fingerprints)) errors.push("approved_fingerprints must be an array");
  if (!Array.isArray(approval.incomplete_triage)) errors.push("incomplete_triage must be an array");

  const approvalSeen = new Set();
  for (const item of Array.isArray(approval.approved_fingerprints) ? approval.approved_fingerprints : []) {
    if (!isRecord(item) || !exactKeys(item, [...FINDING_KEYS, "approval"])) {
      errors.push("approved fingerprint has an invalid schema");
      continue;
    }
    const { approval: provenance, ...fingerprintData } = item;
    findingShape({ ...fingerprintData, impact: fingerprintData.impact ?? null }, "violations", errors);
    const id = fingerprint(item);
    if (approvalSeen.has(id)) errors.push("approved fingerprints contain a duplicate");
    approvalSeen.add(id);
    if (
      !isRecord(provenance) ||
      !nonempty(provenance.source) ||
      !nonempty(provenance.reviewer) ||
      !nonempty(provenance.reason) ||
      !isTimestamp(provenance.approved_at)
    ) {
      errors.push("each approved fingerprint needs source, reviewer, reason and approval date");
    }
  }

  const triageSeen = new Set();
  for (const item of Array.isArray(approval.incomplete_triage) ? approval.incomplete_triage : []) {
    const { reason, disposition, evidence, ...fingerprintData } = item || {};
    if (!isRecord(item) || !exactKeys(item, [...FINDING_KEYS, "reason", "disposition", "evidence"])) {
      errors.push("incomplete triage record has an invalid schema");
      continue;
    }
    findingShape({ ...fingerprintData }, "violations", errors);
    const id = fingerprint(item);
    if (triageSeen.has(id)) errors.push("incomplete triage contains a duplicate fingerprint");
    triageSeen.add(id);
    if (!nonempty(reason) || !nonempty(disposition) || disposition === "untriaged" || !nonempty(evidence)) {
      errors.push("incomplete triage needs a reason, reviewed disposition and evidence");
    }
    if (approval.review_basis?.run_id && evidence !== approval.review_basis.run_id) {
      errors.push("incomplete triage evidence must name the independent review_basis run");
    }
  }
  return [...new Set(errors)];
}

function compareFindings(report, approval) {
  const errors = validateApproval(approval);
  if (!isRecord(report)) return { valid: false, errors: [...errors, "report is missing or is not an object"], metrics: { violations: 0, unapproved: 0, incomplete: 0, untriaged: 0 } };
  if (approval?.review_basis?.run_id === report.run_id) errors.push("report and approved findings use the same evidence run (self-comparison)");

  const approved = new Map(
    (Array.isArray(approval?.approved_fingerprints) ? approval.approved_fingerprints : []).map(item => [fingerprint(item), item])
  );
  let unapproved = 0;
  for (const item of Array.isArray(report.violations) ? report.violations : []) {
    const id = fingerprint(item);
    const match = approved.get(id);
    if (!match) {
      unapproved += 1;
      errors.push(`unapproved finding fingerprint ${id}`);
    } else if (Number.isInteger(match.count) && item.count > match.count) {
      errors.push(`finding count exceeds approved count for ${id}`);
    }
  }

  const triaged = new Map(
    (Array.isArray(approval?.incomplete_triage) ? approval.incomplete_triage : []).map(item => [fingerprint(item), item])
  );
  let untriaged = 0;
  for (const item of Array.isArray(report.incomplete) ? report.incomplete : []) {
    const match = triaged.get(fingerprint(item));
    if (!match || !nonempty(match.reason) || !nonempty(match.disposition) || match.disposition === "untriaged" || !nonempty(match.evidence)) {
      untriaged += 1;
      errors.push(`untriaged incomplete finding fingerprint ${fingerprint(item)}`);
    }
  }

  const violations = Array.isArray(report.violations) ? report.violations.length : 0;
  const incomplete = Array.isArray(report.incomplete) ? report.incomplete.length : 0;
  const uniqueErrors = [...new Set(errors)];
  return {
    valid: uniqueErrors.length === 0,
    errors: uniqueErrors,
    metrics: { violations, unapproved, incomplete, untriaged }
  };
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (!flag.startsWith("--") || !argv[index + 1] || argv[index + 1].startsWith("--")) {
      throw new Error(`expected --name value, received ${flag}`);
    }
    const name = flag.slice(2);
    if (!["report", "approved", "manifest", "run-id", "revision", "source-digest"].includes(name)) {
      throw new Error(`unknown option ${flag}`);
    }
    if (Object.hasOwn(result, name)) throw new Error(`duplicate option ${flag}`);
    result[name] = argv[++index];
  }
  for (const name of ["report", "approved", "manifest", "run-id", "revision", "source-digest"]) {
    if (!nonempty(result[name])) throw new Error(`required option --${name} is missing`);
  }
  return result;
}

function readJson(filename, label) {
  try {
    return JSON.parse(fs.readFileSync(filename, "utf8"));
  } catch (error) {
    throw new Error(`${label} could not be read: ${error.message}`);
  }
}

function cli(argv = process.argv.slice(2)) {
  try {
    const args = parseArgs(argv);
    const report = readJson(args.report, "report");
    const approval = readJson(args.approved, "approved findings");
    const manifest = readJson(args.manifest, "manifest");
    const validation = validateReport(report, {
      manifest,
      runId: args["run-id"],
      revision: args.revision,
      sourceDigest: args["source-digest"],
      approval
    });
    const comparison = compareFindings(report, approval);
    const metrics = validation.metrics;
    const summary = {
      expected: metrics.expected,
      executed: metrics.executed,
      successful: metrics.successful,
      failed: metrics.failed,
      missing: metrics.missing,
      incomplete: metrics.incomplete,
      violations: comparison.metrics.violations,
      unapproved: comparison.metrics.unapproved,
      untriaged: comparison.metrics.untriaged,
      valid: validation.valid && comparison.valid
    };
    process.stdout.write(`${JSON.stringify(summary)}\n`);
    if (!validation.valid || !comparison.valid) {
      for (const error of [...validation.errors, ...comparison.errors]) process.stderr.write(`ERROR: ${error}\n`);
      process.exitCode = 1;
    }
  } catch (error) {
    process.stderr.write(`ERROR: ${error.message}\n`);
    process.exitCode = 1;
  }
}

if (require.main === module) cli();

module.exports = { selectedCases, normalizeTarget, validateReport, compareFindings };
