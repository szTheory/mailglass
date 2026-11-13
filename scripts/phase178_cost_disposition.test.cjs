"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const tool = require("./phase178_cost_disposition.cjs");

const REPO_ROOT = path.resolve(__dirname, "..");
const RETAINED_174 = path.join(REPO_ROOT, "reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1");

const DEMO = "Demo Browser Evidence (Docker Compose / Chromium)";
const OPERATOR = "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)";
const SUPPORT = "Support Contract Admin (Elixir 1.18 / OTP 27)";
const SHA_A = "a".repeat(40);
const SHA_B = "b".repeat(40);

function iso(base, offsetSeconds) {
  return new Date(Date.parse(base) + offsetSeconds * 1000).toISOString().replace(".000Z", "Z");
}

function job(id, name, startOffset, durationSeconds, base, extra = {}) {
  return {
    id,
    run_id: 1,
    name,
    status: "completed",
    conclusion: "success",
    started_at: iso(base, startOffset),
    completed_at: iso(base, startOffset + durationSeconds),
    labels: ["ubuntu-latest"],
    runner_name: `GitHub Actions ${id}`,
    steps: [{ name: "Set up job", status: "completed", conclusion: "success", number: 1 }],
    ...extra
  };
}

function run(id, sha, base, event = "workflow_dispatch", updatedOffset = 600) {
  return {
    id,
    run_attempt: 1,
    head_sha: sha,
    event,
    status: "completed",
    conclusion: "success",
    html_url: `https://github.com/szTheory/mailglass/actions/runs/${id}`,
    run_started_at: base,
    updated_at: iso(base, updatedOffset),
    repository: { full_name: "szTheory/mailglass" }
  };
}

const BASE_T = "2026-10-01T10:00:00Z";
const CAND_T = "2026-10-29T10:00:00Z";

// Baseline: Demo 200 s, Operator 600 s, Support 240 s, CI Green ends 700 s after run start.
const baselineRun = run(100, SHA_B, BASE_T, "push", 700);
const baselineJobs = {
  jobs: [
    job(1, DEMO, 10, 200, BASE_T),
    job(2, OPERATOR, 10, 600, BASE_T),
    job(3, SUPPORT, 10, 240, BASE_T),
    job(4, "CI Green", 680, 20, BASE_T)
  ]
};
// Candidate dispatch: Demo +400 s (delta 400 s: over), Operator +100 s, Support +10 s.
const dispatchRun = run(200, SHA_A, CAND_T, "workflow_dispatch", 1000);
const dispatchJobs = {
  jobs: [
    job(11, DEMO, 10, 600, CAND_T),
    job(12, OPERATOR, 10, 700, CAND_T),
    job(13, SUPPORT, 10, 250, CAND_T),
    job(14, "CI Green", 980, 20, CAND_T)
  ]
};
const prRun = run(300, SHA_A, CAND_T, "pull_request", 800);
const prJobs = {
  jobs: [
    job(21, DEMO, 10, 220, CAND_T),
    job(22, OPERATOR, 10, 610, CAND_T),
    job(23, SUPPORT, 10, 245, CAND_T),
    job(24, "CI Green", 780, 20, CAND_T)
  ]
};

function pilotCost() {
  return {
    schema_version: "phase174-cost.v1",
    conditions: [
      { condition: "cold", job_id: "demo_browser_evidence", setup_ms: 100000, execution_ms: 150000, wall_ms: 260000, runner_minutes: 4.3333,
        executed_counts: { demo: 98, hooks: 6, fidelity: 26, axe: 18, total: 148 } },
      { condition: "warm", job_id: "demo_browser_evidence", setup_ms: 3000, execution_ms: 150000, wall_ms: 320000, runner_minutes: 10.5,
        executed_counts: { demo: 98, hooks: 6, fidelity: 26, axe: 18, total: 148 } }
    ]
  };
}

function expectedCounts(operator = { passed: 310, skipped: 1, failed: 0, flaky: 0 }, demo = {
  demo: 98, hooks: 6, fidelity: 26, axe: 18, total: 148
}) {
  return { operator, demo };
}

function countInputs(operatorLog = "310 passed\n1 skipped", demoCost = pilotCost(), expected = expectedCounts()) {
  return {
    operatorLog,
    demoCost,
    expected
  };
}

function validCounts() {
  return tool.deriveCounts(countInputs());
}

function tmpDir(label) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `phase178-cost-test-${label}-`));
}

function withConclusion(jobs, name, conclusion) {
  return { ...jobs, jobs: jobs.jobs.map((candidate) => candidate.name === name
    ? { ...candidate, conclusion }
    : candidate) };
}

function advisoryRed(runId, jobName = OPERATOR, overrides = {}) {
  return {
    run: String(runId), job: jobName, title: "Flaky preview assertion", key: "preview assertion",
    matched: ".planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md",
    log_sha256: "c".repeat(64), ...overrides
  };
}

function advisoryRedLine(entry) {
  return `rerun_advisory_red: run=${entry.run} | job=${entry.job} | title=${entry.title} | key=${entry.key} | log=operator-gate.log | log_sha256=${entry.log_sha256} | matched=${entry.matched}`;
}

test("deriveCiJob derives the schema, duration and Linux/X64 from the ubuntu-latest label", () => {
  const ci = tool.deriveCiJob(dispatchRun, dispatchJobs, DEMO);
  assert.equal(ci.schema_version, "phase174-ci-job.v1");
  assert.equal(ci.run_id, "200");
  assert.equal(ci.run_attempt, "1");
  assert.equal(ci.repository, "szTheory/mailglass");
  assert.equal(ci.head_sha, SHA_A);
  assert.equal(ci.duration_ms, 600000);
  assert.equal(ci.job.runner_os, "Linux");
  assert.equal(ci.job.runner_arch, "X64");
  assert.match(ci.provenance.runner_platform, /ubuntu-latest/);
  assert.equal(ci.run_completed_at, dispatchRun.updated_at);
});

test("deriveCiJob throws naming a missing job", () => {
  assert.throws(() => tool.deriveCiJob(dispatchRun, dispatchJobs, "No Such Job"), /No Such Job/);
});

test("deriveCiJob rejects an unmapped runner label and prefers a saved log header when given", () => {
  const selfHosted = { jobs: [job(31, DEMO, 0, 100, CAND_T, { labels: ["self-hosted-x"] })] };
  assert.throws(() => tool.deriveCiJob(dispatchRun, selfHosted, DEMO), /self-hosted-x/);
  const log = [
    "2026-10-29T10:00:01.0000000Z Current runner version: '2.329.0'",
    "2026-10-29T10:00:01.0000001Z ##[group]Operating System",
    "2026-10-29T10:00:01.0000002Z Ubuntu",
    "2026-10-29T10:00:01.0000003Z 24.04.3",
    "2026-10-29T10:00:01.0000004Z ##[endgroup]",
    "2026-10-29T10:00:01.0000005Z Runner Architecture: X64"
  ].join("\n");
  const ci = tool.deriveCiJob(dispatchRun, selfHosted, DEMO, { log });
  assert.equal(ci.job.runner_os, "Linux");
  assert.equal(ci.job.runner_arch, "X64");
  assert.match(ci.provenance.runner_platform, /job log/i);
  assert.throws(() => tool.deriveCiJob(dispatchRun, selfHosted, DEMO, { log: "no runner header here" }), /runner/i);
});

test("enrichCost adds hosted_job matching validateCiJob and does not mutate its input", () => {
  const downloaded = pilotCost();
  const frozen = JSON.stringify(downloaded);
  const ci = tool.deriveCiJob(dispatchRun, dispatchJobs, DEMO);
  const cost = tool.enrichCost(downloaded, ci, baselineRun, baselineJobs);
  assert.equal(JSON.stringify(downloaded), frozen);
  const hosted = cost.hosted_job;
  assert.deepEqual(Object.keys(hosted).slice(0, 14), [
    "run_id", "run_attempt", "repository", "head_sha", "job_id", "job_database_id", "job_name",
    "runner_name", "runner_os", "runner_arch", "started_at", "completed_at", "duration_ms", "runner_count"
  ]);
  assert.equal(hosted.job_id, "demo_browser_evidence");
  assert.equal(hosted.job_database_id, 11);
  assert.equal(hosted.job_name, DEMO);
  assert.equal(hosted.duration_ms, 600000);
  assert.equal(hosted.runner_count, 1);
  assert.equal(hosted.runner_minutes, 10);
  assert.equal(cost.added_cost.status, "measured");
  assert.equal(cost.added_cost.wall_ms, 400000);
  assert.equal(cost.budget.wall_within_budget, false);
  assert.equal(cost.budget.wall_exceedance_ms, 100000);
  assert.equal(cost.budget.runner_within_budget, true);
});

test("deriveDisposition reports per-job deltas, run wall and runner-minutes for both runs", () => {
  const out = tool.deriveDisposition({
    baselineRun, baselineJobs,
    dispatch: { run: dispatchRun, jobs: dispatchJobs },
    pr: { run: prRun, jobs: prJobs },
    sha: SHA_A,
    ...countInputs()
  });
  assert.equal(out.schema_version, "phase178-cost-disposition.v1");
  assert.equal(out.source_revision, SHA_A);
  assert.equal(out.baseline_run_id, "100");
  assert.deepEqual(Object.keys(out.runs), ["workflow_dispatch", "pull_request"]);
  const d = out.runs.workflow_dispatch;
  assert.equal(d.run_id, "200");
  assert.deepEqual(d.jobs[DEMO], {
    baseline_seconds: 200, candidate_seconds: 600, delta_seconds: 400,
    runner_minutes_delta: 400 / 60, wall_within_budget: false, runner_within_budget: true, wall_exceedance_ms: 100000
  });
  assert.equal(d.jobs[OPERATOR].delta_seconds, 100);
  assert.equal(d.jobs[OPERATOR].wall_within_budget, true);
  assert.equal(d.jobs[SUPPORT].wall_exceedance_ms, 0);
  assert.deepEqual(d.wall_to_ci_green, { baseline_seconds: 700, candidate_seconds: 1000, delta_seconds: 300 });
  // runner minutes: baseline (200+600+240+20)/60, candidate (600+700+250+20)/60
  assert.equal(d.runner_minutes.baseline, 1060 / 60);
  assert.equal(d.runner_minutes.candidate, 1570 / 60);
  assert.equal(d.runner_minutes.delta, 510 / 60);
  assert.equal(d.budget.added_wall_minutes, 5);
  assert.equal(d.budget.added_runner_minutes, 10);
  assert.equal(d.budget.wall_within_budget, true);
  assert.equal(d.budget.wall_exceedance_ms, 0);
  assert.equal(d.budget.runner_within_budget, true);
  assert.equal(out.runs.pull_request.jobs[DEMO].delta_seconds, 20);
  assert.equal(out.pilot_conditions, null);
});

test("deriveDisposition never omits a requested job and needs at least one run", () => {
  const missing = { jobs: dispatchJobs.jobs.filter((j) => j.name !== SUPPORT) };
  assert.throws(() => tool.deriveDisposition({
    baselineRun, baselineJobs, dispatch: { run: dispatchRun, jobs: missing }, sha: SHA_A, ...countInputs()
  }), new RegExp(SUPPORT.replace(/[()/]/g, "\\$&")));
  assert.throws(() => tool.deriveDisposition({ baselineRun, baselineJobs, sha: SHA_A }), /at least one/i);
  assert.throws(() => tool.deriveDisposition({
    baselineRun, baselineJobs, dispatch: { run: dispatchRun, jobs: dispatchJobs }, sha: SHA_B, ...countInputs()
  }), /head_sha|identity|candidate/i);
});

test("disposition measures an Operator advisory red only when a recorded advisory red matches it", () => {
  const failedPr = { run: prRun, jobs: withConclusion(prJobs, OPERATOR, "failure") };
  const entry = advisoryRed("300");
  const out = tool.deriveDisposition({
    baselineRun, baselineJobs, pr: failedPr, sha: SHA_A, ...countInputs(), advisoryReds: [entry]
  });
  const measured = out.runs.pull_request.jobs[OPERATOR];
  assert.equal(measured.candidate_seconds, 610);
  assert.equal(measured.delta_seconds, 10);
  assert.equal(measured.conclusion, "failure");
  assert.deepEqual(measured.advisory_reds, [{
    title: entry.title, key: entry.key, matched: entry.matched, log_sha256: entry.log_sha256
  }]);
  const successful = tool.deriveDisposition({
    baselineRun, baselineJobs, pr: { run: prRun, jobs: prJobs }, sha: SHA_A, ...countInputs()
  });
  assert.deepEqual(out.runs.pull_request.jobs[DEMO], successful.runs.pull_request.jobs[DEMO]);
  assert.deepEqual(out.runs.pull_request.jobs[SUPPORT], successful.runs.pull_request.jobs[SUPPORT]);
  assert.equal("conclusion" in out.runs.pull_request.jobs[DEMO], false);
  assert.equal("conclusion" in out.runs.pull_request.jobs[SUPPORT], false);
});

test("an unmatched Operator advisory red still fails the disposition", () => {
  const failedPr = { run: prRun, jobs: withConclusion(prJobs, OPERATOR, "failure") };
  const derive = ({ dispatch, ...options } = {}) => tool.deriveDisposition({
    baselineRun, baselineJobs, dispatch, pr: failedPr, sha: SHA_A, ...countInputs(), ...options
  });
  assert.throws(() => derive(), /did not complete successfully.*failure/);
  assert.throws(() => derive({ dispatch: { run: dispatchRun, jobs: dispatchJobs }, advisoryReds: [advisoryRed("200")] }), /job succeeded/);
  assert.throws(() => derive({ advisoryReds: [advisoryRed("999")] }), /unmeasured run/);
  assert.throws(() => derive({ advisoryReds: [advisoryRed("300", "Preview Capture Advisory")] }), /did not complete successfully.*failure/);
});

test("Demo, Support, CI Green and non-failure Operator conclusions reject an advisory red exception", () => {
  const failedPr = { run: prRun, jobs: withConclusion(prJobs, OPERATOR, "failure") };
  const validRed = advisoryRed("300");
  const derive = (candidate = failedPr.jobs, advisoryReds = [validRed]) => tool.deriveDisposition({
    baselineRun, baselineJobs, pr: { run: prRun, jobs: candidate }, sha: SHA_A, ...countInputs(), advisoryReds
  });
  assert.throws(() => derive(
    withConclusion(prJobs, DEMO, "failure"), [advisoryRed("300", DEMO)]
  ), /advisory red recorded for a job that must succeed/);
  assert.throws(() => derive(withConclusion(prJobs, SUPPORT, "failure"), []), /did not complete successfully.*failure/);
  assert.throws(() => derive(withConclusion(failedPr.jobs, "CI Green", "failure")), /job CI Green.*did not complete successfully/);
  for (const conclusion of ["timed_out", "cancelled"]) {
    assert.throws(() => derive(withConclusion(prJobs, OPERATOR, conclusion)), new RegExp(`completed/${conclusion}`));
  }
});

test("advisory red input is validated, hashed and unmatched CLI reds exit non-zero", () => {
  const dir = tmpDir("advisory-reds");
  const write = (name, value) => {
    const file = path.join(dir, name);
    fs.writeFileSync(file, typeof value === "string" ? value : JSON.stringify(value));
    return file;
  };
  const failedPrJobs = withConclusion(prJobs, OPERATOR, "failure");
  const files = {
    baselineRun: write("baseline-run.json", baselineRun),
    baselineJobs: write("baseline-jobs.json", baselineJobs),
    prRun: write("pr-run.json", prRun),
    prJobs: write("pr-jobs.json", failedPrJobs),
    successfulPrJobs: write("successful-pr-jobs.json", prJobs),
    operatorLog: write("operator-gate.log", "310 passed\n1 skipped"),
    demoCost: write("demo-cost.json", pilotCost()),
    expected: write("expected.json", expectedCounts())
  };
  const validEntry = advisoryRed("300");
  const validFile = write("advisory-reds.txt", `${advisoryRedLine(validEntry)}\n`);
  const baseArgs = ["disposition", "--baseline-run", files.baselineRun, "--baseline-jobs", files.baselineJobs,
    "--pr-run", files.prRun, "--pr-jobs", files.prJobs, "--sha", SHA_A,
    "--operator-log", files.operatorLog, "--demo-cost", files.demoCost, "--expected", files.expected];
  const out1 = path.join(dir, "out1.json");
  const out2 = path.join(dir, "out2.json");
  tool.cli([...baseArgs, "--advisory-reds", validFile, "--out", out1]);
  tool.cli([...baseArgs, "--advisory-reds", validFile, "--out", out2]);
  assert.equal(fs.readFileSync(out1, "utf8"), fs.readFileSync(out2, "utf8"));
  const result = JSON.parse(fs.readFileSync(out1, "utf8"));
  assert.equal(result.input_hashes.advisory_reds, tool.sha256File(validFile));
  assert.equal(result.input_hashes.count_operator_log, tool.sha256File(files.operatorLog));
  assert.equal(result.input_hashes.count_demo_cost, tool.sha256File(files.demoCost));
  assert.equal(result.input_hashes.count_expected, tool.sha256File(files.expected));

  const emptyFile = write("empty-advisory-reds.txt", "");
  const emptyOut = path.join(dir, "empty-out.json");
  tool.cli(["disposition", "--baseline-run", files.baselineRun, "--baseline-jobs", files.baselineJobs,
    "--pr-run", files.prRun, "--pr-jobs", files.successfulPrJobs, "--sha", SHA_A,
    "--operator-log", files.operatorLog, "--demo-cost", files.demoCost, "--expected", files.expected,
    "--advisory-reds", emptyFile, "--out", emptyOut]);
  assert.equal(JSON.parse(fs.readFileSync(emptyOut, "utf8")).input_hashes.advisory_reds, tool.sha256File(emptyFile));

  const malformedFile = write("malformed-advisory-reds.txt", "not an advisory line\n");
  assert.throws(() => tool.cli([...baseArgs, "--advisory-reds", malformedFile, "--out", path.join(dir, "bad.json")]), /line 1/);
  const incompleteFile = write("incomplete-advisory-reds.txt", "rerun_advisory_red: run=300 | job=Operator\n");
  assert.throws(() => tool.cli([...baseArgs, "--advisory-reds", incompleteFile, "--out", path.join(dir, "bad-fields.json")]), /line 1/);

  const unmatchedFile = write("unmatched-advisory-reds.txt", `${advisoryRedLine(advisoryRed("300", "Preview Capture Advisory"))}\n`);
  const child = spawnSync(process.execPath, [path.join(__dirname, "phase178_cost_disposition.cjs"), ...baseArgs.slice(1),
    "--advisory-reds", unmatchedFile, "--out", path.join(dir, "unmatched.json")], { encoding: "utf8" });
  assert.equal(child.status, 1);
  assert.match(child.stderr, /^ERROR:/);
});

test("pilot_conditions copies cold and warm measurements and flags the budgets", () => {
  const out = tool.deriveDisposition({
    baselineRun, baselineJobs, dispatch: { run: dispatchRun, jobs: dispatchJobs }, sha: SHA_A, ...countInputs(),
    pilotCost: pilotCost(), pilotSourceEvent: "workflow_dispatch", identityBound: true
  });
  assert.equal(out.pilot_conditions.source_event, "workflow_dispatch");
  assert.equal(out.pilot_conditions.identity_bound, true);
  assert.deepEqual(out.pilot_conditions.cold, {
    setup_ms: 100000, execution_ms: 150000, wall_ms: 260000, runner_minutes: 4.3333,
    wall_within_budget: true, runner_within_budget: true
  });
  assert.equal(out.pilot_conditions.warm.wall_ms, 320000);
  assert.equal(out.pilot_conditions.warm.wall_within_budget, false);
  assert.equal(out.pilot_conditions.warm.runner_within_budget, false);
  const noWarm = pilotCost();
  noWarm.conditions = noWarm.conditions.filter((c) => c.condition !== "warm");
  assert.throws(() => tool.deriveDisposition({
    baselineRun, baselineJobs, dispatch: { run: dispatchRun, jobs: dispatchJobs }, sha: SHA_A, ...countInputs(),
    pilotCost: noWarm, pilotSourceEvent: "workflow_dispatch", identityBound: true
  }), /warm/);
});

test("deriveCounts parses Playwright summary lines behind GitHub timestamps and flags mismatches", () => {
  const ts = "2026-10-29T12:00:00.0000000Z ";
  const log = [
    `${ts}Running 128 tests using 1 worker`,
    `${ts}  1 failed`,
    `${ts}    [chromium] › a.spec.js:1:1 › broken ───`,
    `${ts}  2 flaky`,
    `${ts}  1 skipped`,
    `${ts}  123 passed (4.5m)`,
    `${ts}##[endgroup]`
  ].join("\n");
  const counts = tool.deriveCounts({
    operatorLog: log,
    demoCost: pilotCost(),
    expected: expectedCounts(
      { passed: 123, skipped: 1, failed: 0, flaky: 2 },
      { demo: 98, hooks: 6, fidelity: 26, axe: 18, total: 149 }
    )
  });
  assert.deepEqual(counts.operator.executed, { passed: 123, skipped: 1, failed: 1, flaky: 2 });
  assert.equal(counts.operator.mismatch, true);
  assert.deepEqual(counts.operator.mismatches, [{ key: "failed", expected: 0, executed: 1 }]);
  assert.equal(counts.demo.cold.executed.demo, 98);
  assert.equal(counts.demo.mismatch, true);
  assert.deepEqual(counts.demo.mismatches.map((m) => [m.condition, m.key, m.expected, m.executed]), [
    ["cold", "total", 149, 148], ["warm", "total", 149, 148]
  ]);
  assert.throws(() => tool.deriveCounts({ operatorLog: `${ts}nothing useful`, demoCost: pilotCost(), expected: expectedCounts() }), /summary/i);
});

test("deriveCounts ignores GitHub notice continuation lines in timestamped logs", () => {
  const ts = "2026-10-29T12:00:00.0000000Z ";
  const log = [
    `${ts}##[notice]  1 failed`,
    "    [chromium] › a.spec.js:1:1 › broken ───",
    "  1 skipped",
    "  309 passed (15.0m)",
    `${ts}  1 failed`,
    `${ts}  1 skipped`,
    `${ts}  309 passed (15.0m)`
  ].join("\n");
  const counts = tool.deriveCounts({ operatorLog: log, demoCost: pilotCost(), expected: expectedCounts(
    { passed: 309, skipped: 1, failed: 1, flaky: 0 }
  ) });
  assert.deepEqual(counts.operator.executed, { passed: 309, skipped: 1, failed: 1, flaky: 0 });
  assert.equal(counts.operator.summary_lines, 3);
});

test("deriveCounts continues to parse untimestamped Playwright summaries", () => {
  const log = "  310 passed (6.3m)\n  1 skipped";
  const counts = tool.deriveCounts({ operatorLog: log, demoCost: pilotCost(), expected: expectedCounts(
    { passed: 310, skipped: 1, failed: 0, flaky: 0 }
  ) });
  assert.deepEqual(counts.operator.executed, { passed: 310, skipped: 1, failed: 0, flaky: 0 });
  assert.equal(counts.operator.summary_lines, 2);
});

test("deriveCounts rejects missing, empty, partial or invalid expected count input", () => {
  const base = { operatorLog: "310 passed\n1 skipped", demoCost: pilotCost() };
  assert.throws(() => tool.deriveCounts({ ...base }), /expected counts/);
  assert.throws(() => tool.deriveCounts({ ...base, expected: {} }), /must not be empty/);
  assert.throws(() => tool.deriveCounts({ ...base, expected: { operator: { passed: 310 }, demo: expectedCounts().demo } }), /expected\.operator.*missing.*skipped/);
  assert.throws(() => tool.deriveCounts({ ...base, expected: { operator: expectedCounts().operator, demo: { total: 148 } } }), /expected\.demo.*missing.*demo/);
  assert.throws(() => tool.deriveCounts({ ...base, expected: expectedCounts({ passed: -1, skipped: 1, failed: 0, flaky: 0 }) }), /nonnegative integer/);
  assert.throws(() => tool.deriveCounts({ ...base, expected: expectedCounts({ passed: 310.5, skipped: 1, failed: 0, flaky: 0 }) }), /nonnegative integer/);
});

test("deriveCounts requires exactly one complete cold and warm Demo condition", () => {
  const expected = expectedCounts();
  const base = { operatorLog: "310 passed\n1 skipped", expected };
  const empty = pilotCost();
  empty.conditions = [];
  assert.throws(() => tool.deriveCounts({ ...base, demoCost: empty }), /exactly one cold and one warm/);

  const missingWarm = pilotCost();
  missingWarm.conditions = missingWarm.conditions.filter((condition) => condition.condition !== "warm");
  assert.throws(() => tool.deriveCounts({ ...base, demoCost: missingWarm }), /exactly one cold and one warm/);

  const duplicateCold = pilotCost();
  duplicateCold.conditions[1] = { ...duplicateCold.conditions[1], condition: "cold" };
  assert.throws(() => tool.deriveCounts({ ...base, demoCost: duplicateCold }), /duplicate cold/);

  const partialCounts = pilotCost();
  delete partialCounts.conditions[1].executed_counts.axe;
  assert.throws(() => tool.deriveCounts({ ...base, demoCost: partialCounts }), /warm\.executed_counts.*missing.*axe/);
});

test("disposition recomputes counts from raw inputs and rejects self-consistent forged counts", () => {
  const base = {
    baselineRun, baselineJobs, dispatch: { run: dispatchRun, jobs: dispatchJobs }, sha: SHA_A
  };
  assert.throws(() => tool.deriveDisposition({ ...base }), /operator log input is required/);

  const forged = tool.deriveCounts({
    operatorLog: "999 passed\n1 skipped",
    demoCost: pilotCost(),
    expected: expectedCounts({ passed: 999, skipped: 1, failed: 0, flaky: 0 })
  });
  assert.equal(forged.operator.mismatch, false);

  const rawInputs = countInputs(
    "310 passed\n1 skipped",
    pilotCost(),
    expectedCounts({ passed: 999, skipped: 1, failed: 0, flaky: 0 })
  );
  const disposition = tool.deriveDisposition({ ...base, ...rawInputs });
  assert.equal(disposition.counts.operator.mismatch, true);
  assert.deepEqual(disposition.counts.operator.mismatches, [
    { key: "passed", expected: 999, executed: 310 }
  ]);
  assert.throws(() => tool.deriveDisposition({ ...base, ...rawInputs, counts: forged }), /precomputed counts are not accepted/);
  assert.throws(() => tool.deriveDisposition({ ...base, counts: forged }), /precomputed counts are not accepted/);
});

test("disposition CLI records a SHA-256 for every input file and is byte-reproducible", () => {
  const dir = tmpDir("cli");
  const w = (name, value) => { const p = path.join(dir, name); fs.writeFileSync(p, typeof value === "string" ? value : JSON.stringify(value)); return p; };
  const files = {
    br: w("baseline-run.json", baselineRun), bj: w("baseline-jobs.json", baselineJobs),
    dr: w("dispatch-run.json", dispatchRun), dj: w("dispatch-jobs.json", dispatchJobs),
    cost: w("cost.json", pilotCost()),
    operatorLog: w("operator-gate.log", "310 passed\n1 skipped"),
    demoCost: w("demo-cost.json", pilotCost()),
    expected: w("expected.json", expectedCounts()),
    extra: w("extra-input.txt", "evidence")
  };
  const argv = (out) => ["disposition", "--baseline-run", files.br, "--baseline-jobs", files.bj,
    "--dispatch-run", files.dr, "--dispatch-jobs", files.dj, "--pilot-cost", files.cost,
    "--pilot-source-event", "workflow_dispatch", "--identity-bound", "true", "--sha", SHA_A,
    "--operator-log", files.operatorLog, "--demo-cost", files.demoCost, "--expected", files.expected,
    "--input", files.extra, "--out", out];
  const out1 = path.join(dir, "out1.json");
  const out2 = path.join(dir, "out2.json");
  tool.cli(argv(out1));
  tool.cli(argv(out2));
  assert.equal(fs.readFileSync(out1, "utf8"), fs.readFileSync(out2, "utf8"));
  const result = JSON.parse(fs.readFileSync(out1, "utf8"));
  for (const [key, file] of [
    ["pilot_cost", files.cost],
    ["count_operator_log", files.operatorLog],
    ["count_demo_cost", files.demoCost],
    ["count_expected", files.expected],
    ["input:extra-input.txt", files.extra]
  ]) {
    assert.equal(result.input_hashes[key], tool.sha256File(file), key);
  }
  assert.deepEqual(result.counts, validCounts());
  assert.throws(() => tool.cli([...argv(path.join(dir, "old-counts.json")), "--counts", "{}"]), /--counts is no longer accepted/);
  assert.throws(() => tool.cli(["ci-job", "--run", files.dr, "--jobs", files.dj, "--job-name", DEMO, "--out", files.dr]), /input/i);
  fs.rmSync(dir, { recursive: true, force: true });
});

test("source stays pure file I/O and contains no GitHub write command", () => {
  const source = fs.readFileSync(path.join(__dirname, "phase178_cost_disposition.cjs"), "utf8");
  assert.doesNotMatch(source, /execSync|spawnSync|child_process/);
  for (const forbidden of ["gh pr create", "gh workflow run", "gh run rerun", "gh pr merge", "git push"]) {
    assert.equal(source.includes(forbidden), false, forbidden);
  }
});

// Normalization used for the 174 reproduction: sorted keys, provenance excluded.
function normalize(value) {
  const sort = (v) => Array.isArray(v) ? v.map(sort)
    : v && typeof v === "object" ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, sort(v[k])])) : v;
  const { provenance, ...rest } = value;
  return JSON.stringify(sort(rest));
}

const retainedPresent = fs.existsSync(path.join(RETAINED_174, "ci-job.json"));
if (!retainedPresent) console.log("skip: retained 174 inputs absent");

test("reproduces the retained Phase 174 ci-job, cost enrichment and disposition from raw inputs", { skip: retainedPresent ? false : "skip: retained 174 inputs absent" }, () => {
  const read = (rel) => JSON.parse(fs.readFileSync(path.join(RETAINED_174, rel), "utf8"));
  const rawRun = read("github-run.raw.json");
  const rawJobs = read("github-jobs.raw.json");
  const retainedCiJob = read("ci-job.json");
  const regenerated = tool.deriveCiJob(rawRun, rawJobs, DEMO);
  assert.equal(normalize(regenerated), normalize(retainedCiJob));
  assert.equal(regenerated.job.runner_os, retainedCiJob.job.runner_os);
  assert.equal(regenerated.job.runner_arch, retainedCiJob.job.runner_arch);

  const retainedCost = read("phase174/cost.json");
  const cost = tool.enrichCost(read("phase174/cost.downloaded.json"), regenerated, read("baseline-run.raw.json"), read("baseline-jobs.raw.json"));
  assert.deepEqual(cost.hosted_job, retainedCost.hosted_job);
  const strip = (c) => {
    const copy = JSON.parse(JSON.stringify(c));
    delete copy.added_cost.reason;
    return copy;
  };
  assert.deepEqual(strip(cost), strip(retainedCost));

  // Key link: the regenerated receipts satisfy the Phase 174 checker's hosted contract
  // (validateCiJob + validateHostedCost) without hand edits. The checker's full
  // --pilot --require-ci run also validates the CURRENT scenario manifest, which later
  // phases extended, so the full run is only valid from the 174 candidate checkout.
  const checker = require("./check_phase174_evidence.cjs");
  const execution = read("phase174/execution.json");
  const evidenceDir = tmpDir("evidence");
  fs.writeFileSync(path.join(evidenceDir, "ci-job.json"), `${JSON.stringify(regenerated, null, 2)}\n`);
  const hostedSummary = checker.validateCiJob(evidenceDir, execution, cost);
  checker.validateHostedCost(cost, execution);
  assert.equal(hostedSummary.duration_ms, 535000);
  assert.equal(hostedSummary.job_id, 122170444350);
  fs.rmSync(evidenceDir, { recursive: true, force: true });

  const disposition = tool.deriveDisposition({
    baselineRun: read("baseline-run.raw.json"), baselineJobs: read("baseline-jobs.raw.json"),
    dispatch: { run: rawRun, jobs: rawJobs }, sha: rawRun.head_sha, ...countInputs()
  });
  const demo = disposition.runs.workflow_dispatch.jobs[DEMO];
  assert.equal(demo.delta_seconds * 1000, 314000);
  assert.ok(Math.abs(demo.runner_minutes_delta - 5.2333) < 0.0001);
  assert.equal(demo.wall_exceedance_ms, 14000);
  assert.equal(demo.wall_within_budget, false);
});
