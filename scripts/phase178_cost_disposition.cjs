#!/usr/bin/env node
"use strict";

// Deterministic hosted-cost derivation (Phase 178, UIQ-07, D-12).
//
// Phase 174 enriched its hosted receipts by hand. This tool derives the same
// records from raw GitHub REST responses so the final hosted plans are
// mechanical. It is pure file I/O: GitHub is only ever read by the caller's own
// shell steps (`gh api`), never from here, and nothing here writes to GitHub.
//
// Subcommands:
//   ci-job       --run <raw> --jobs <raw> --job-name <name> [--log <saved job log>] --out <path>
//   enrich-cost  --downloaded <cost.json> --ci-job <ci-job.json> --baseline-run <raw> --baseline-jobs <raw> --out <path>
//   counts       --operator-log <saved log> --demo-cost <cost.json> --expected <json> --out <path>
//   disposition  --baseline-run <raw> --baseline-jobs <raw>
//                [--dispatch-run <raw> --dispatch-jobs <raw>] [--pr-run <raw> --pr-jobs <raw>]
//                [--pilot-cost <cost.json> --pilot-source-event workflow_dispatch|pull_request --identity-bound true|false]
//                --sha <candidate> --counts <file|'{}'> [--input <path>]... --out <path>

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const CI_JOB_SCHEMA = "phase174-ci-job.v1";
const DISPOSITION_SCHEMA = "phase178-cost-disposition.v1";
const ADDED_WALL_MINUTES = 5;
const ADDED_RUNNER_MINUTES = 10;
const WALL_BUDGET_MS = ADDED_WALL_MINUTES * 60000;
const CI_GREEN = "CI Green";
const DEMO_JOB = "Demo Browser Evidence (Docker Compose / Chromium)";
// GitHub appends the matrix value to a matrix job name.
const OPERATOR_JOB = "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)";
const SUPPORT_JOB = "Support Contract Admin (Elixir 1.18 / OTP 27)";
const MEASURED_JOBS = [DEMO_JOB, OPERATOR_JOB, SUPPORT_JOB];
const RUN_KEYS = { dispatch: "workflow_dispatch", pr: "pull_request" };

const RUNNER_PLATFORM_SOURCE =
  "https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories";

// GitHub's published standard-runner mapping, label -> platform. The runner
// platform is not in the raw jobs API, so it is derived from the job's label
// (as Phase 174 recorded in ci-job.json provenance.runner_platform). An
// unmapped label is an error unless a saved job log names the platform.
const RUNNER_LABEL_TABLE = Object.freeze({
  "ubuntu-latest": { os: "Linux", arch: "X64" },
  "ubuntu-24.04": { os: "Linux", arch: "X64" },
  "ubuntu-22.04": { os: "Linux", arch: "X64" },
  "ubuntu-24.04-arm": { os: "Linux", arch: "ARM64" },
  "ubuntu-22.04-arm": { os: "Linux", arch: "ARM64" },
  "windows-latest": { os: "Windows", arch: "X64" },
  "windows-2022": { os: "Windows", arch: "X64" },
  "windows-2025": { os: "Windows", arch: "X64" },
  "macos-latest": { os: "macOS", arch: "ARM64" },
  "macos-14": { os: "macOS", arch: "ARM64" },
  "macos-15": { os: "macOS", arch: "ARM64" }
});

const COST_LIMITATION =
  "Total pilot cost is distinct from added cost. This observed job delta does not establish causal added PR cost or overall workflow latency.";
const COST_RECOMMENDATION =
  "Retain every acceptance case in both conditions and the existing advisory lane/required gates. Re-measure variance, then optimize shared setup or demonstrate equivalent coverage before reducing duplicated baseline execution.";

function fail(message) {
  throw new Error(message);
}

function sha256File(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function readJson(file, label) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    return fail(`${label || file} is not readable JSON: ${error.message}`);
  }
}

function jobList(jobs) {
  const list = Array.isArray(jobs) ? jobs : jobs && jobs.jobs;
  if (!Array.isArray(list)) fail("raw jobs input has no jobs array");
  return list;
}

function findJob(jobs, name) {
  const matches = jobList(jobs).filter((job) => job.name === name);
  if (matches.length === 0) fail(`job not found in raw jobs input: ${name}`);
  if (matches.length > 1) fail(`job name is ambiguous in raw jobs input: ${name}`);
  return matches[0];
}

function jobDurationMs(job) {
  const started = Date.parse(job.started_at);
  const completed = Date.parse(job.completed_at);
  if (!Number.isFinite(started) || !Number.isFinite(completed)) fail(`job ${job.name} has no started_at/completed_at`);
  if (completed < started) fail(`job ${job.name} completed before it started`);
  return completed - started;
}

function requireSuccessfulJob(job, label) {
  if (job.status !== "completed" || job.conclusion !== "success") {
    fail(`${label} job ${job.name} did not complete successfully (${job.status}/${job.conclusion})`);
  }
}

// ---------------------------------------------------------------------------
// ci-job
// ---------------------------------------------------------------------------

function platformFromLog(log) {
  const text = String(log)
    .split(/\r?\n/)
    .map((line) => line.replace(/\u001b\[[0-9;]*m/g, "").replace(/^\d{4}-\d{2}-\d{2}T[\d:.]+Z\s?/, "").trim());
  let runnerOs = null;
  for (let i = 0; i < text.length; i += 1) {
    if (/^(?:##\[group\])?Operating System$/i.test(text[i])) {
      const next = text.slice(i + 1).find((line) => line.length > 0 && !/^##\[/.test(line)) || "";
      if (/ubuntu|linux|debian/i.test(next)) runnerOs = "Linux";
      else if (/windows/i.test(next)) runnerOs = "Windows";
      else if (/mac/i.test(next)) runnerOs = "macOS";
      break;
    }
  }
  if (!runnerOs) {
    const image = text.map((line) => line.match(/^Image:\s*(\S+)/i)).find(Boolean);
    if (image) {
      if (/^ubuntu/i.test(image[1])) runnerOs = "Linux";
      else if (/^windows/i.test(image[1])) runnerOs = "Windows";
      else if (/^macos/i.test(image[1])) runnerOs = "macOS";
    }
  }
  let runnerArch = null;
  for (const line of text) {
    const match = line.match(/^(?:Runner\s+Arch(?:itecture)?|Architecture|RUNNER_ARCH)\s*[:=]\s*(X64|X86|ARM64|ARM)\b/i);
    if (match) {
      runnerArch = match[1].toUpperCase();
      break;
    }
  }
  return { os: runnerOs, arch: runnerArch };
}

function resolvePlatform(job, log) {
  const labels = Array.isArray(job.labels) ? job.labels : [];
  const mapped = labels.map((label) => RUNNER_LABEL_TABLE[label]).find(Boolean);
  if (log !== undefined && log !== null) {
    const fromLog = platformFromLog(log);
    if (!fromLog.os) fail(`saved job log has no runner Operating System header for job ${job.name}`);
    let arch = fromLog.arch;
    let archSource = "job log";
    if (!arch) {
      // The standard runner header names the OS image but not the CPU
      // architecture; accept the label mapping's architecture only when its
      // OS agrees with the log.
      if (mapped && mapped.os === fromLog.os) {
        arch = mapped.arch;
        archSource = `label ${labels.join(",")} (OS confirmed by job log)`;
      } else {
        fail(`saved job log has no runner architecture for job ${job.name} and no agreeing label mapping`);
      }
    }
    if (mapped && mapped.os !== fromLog.os) {
      fail(`runner OS from job log (${fromLog.os}) disagrees with label mapping (${mapped.os}) for job ${job.name}`);
    }
    return {
      os: fromLog.os,
      arch,
      text: `Derived from the saved job log runner header (OS: ${fromLog.os}); architecture from ${archSource}; not from the execution receipt.`,
      derivation: "job-log"
    };
  }
  if (!mapped) {
    return fail(`unmapped runner label(s) [${labels.join(", ")}] for job ${job.name}; pass --log with a saved job log naming the runner platform`);
  }
  return {
    os: mapped.os,
    arch: mapped.arch,
    text: `Derived from actual job label ${labels.find((label) => RUNNER_LABEL_TABLE[label])} and GitHub's published standard-runner mapping; not from the execution receipt.`,
    derivation: "runner-label"
  };
}

function deriveCiJob(run, jobs, jobName, options = {}) {
  if (!run || typeof run !== "object") fail("raw run input is missing");
  const job = findJob(jobs, jobName);
  if (job.status !== "completed") fail(`job ${jobName} is not completed (${job.status})`);
  const platform = resolvePlatform(job, options.log);
  const durationMs = jobDurationMs(job);
  return {
    schema_version: CI_JOB_SCHEMA,
    repository: run.repository && run.repository.full_name,
    run_id: String(run.id),
    run_attempt: String(run.run_attempt),
    head_sha: run.head_sha,
    status: run.status,
    conclusion: run.conclusion,
    url: run.html_url,
    run_started_at: run.run_started_at,
    run_completed_at: run.updated_at,
    duration_ms: durationMs,
    job: { ...job, runner_os: platform.os, runner_arch: platform.arch },
    provenance: {
      raw_run: options.rawRunName || "github-run.raw.json",
      raw_jobs: options.rawJobsName || "github-jobs.raw.json",
      runner_platform: platform.text,
      runner_platform_derivation: platform.derivation,
      runner_platform_source: RUNNER_PLATFORM_SOURCE,
      workflow_completion_source: "GitHub REST run updated_at after status=completed"
    }
  };
}

// ---------------------------------------------------------------------------
// enrich-cost
// ---------------------------------------------------------------------------

function enrichCost(downloaded, ciJob, baselineRun, baselineJobs) {
  if (!downloaded || !Array.isArray(downloaded.conditions) || downloaded.conditions.length === 0) {
    fail("downloaded cost receipt has no conditions");
  }
  if (!ciJob || ciJob.schema_version !== CI_JOB_SCHEMA || !ciJob.job) fail("ci-job input is missing or has an unsupported schema");
  const cost = JSON.parse(JSON.stringify(downloaded));
  const jobIds = [...new Set(cost.conditions.map((condition) => condition.job_id))];
  if (jobIds.length !== 1 || !jobIds[0]) fail("downloaded cost conditions do not agree on one job_id");

  const job = ciJob.job;
  const durationMs = ciJob.duration_ms;
  const baselineJob = findJob(baselineJobs, job.name);
  requireSuccessfulJob(baselineJob, "baseline");
  if (JSON.stringify(baselineJob.labels) !== JSON.stringify(job.labels)) {
    fail(`baseline job labels ${JSON.stringify(baselineJob.labels)} differ from the candidate's ${JSON.stringify(job.labels)}; not the same profile`);
  }
  const baselineMs = jobDurationMs(baselineJob);
  const deltaMs = durationMs - baselineMs;
  const exceedanceMs = Math.max(0, deltaMs - WALL_BUDGET_MS);
  const deltaMinutes = deltaMs / 60000;
  const runnerWithin = deltaMinutes <= ADDED_RUNNER_MINUTES;
  const wallWithin = deltaMs <= WALL_BUDGET_MS;
  const profile = (job.labels || []).join(", ");

  cost.hosted_job = {
    run_id: ciJob.run_id,
    run_attempt: ciJob.run_attempt,
    repository: ciJob.repository,
    head_sha: ciJob.head_sha,
    job_id: jobIds[0],
    job_database_id: job.id,
    job_name: job.name,
    runner_name: job.runner_name,
    runner_os: job.runner_os,
    runner_arch: job.runner_arch,
    started_at: job.started_at,
    completed_at: job.completed_at,
    duration_ms: durationMs,
    runner_count: 1,
    runner_minutes: durationMs / 60000,
    provenance: "ci-job.json and preserved raw GitHub REST responses; original artifact cost is cost.downloaded.json"
  };
  cost.added_cost = {
    status: "measured",
    reason: `Observed same-lane single-job comparison on the same ${profile} runner label (the job name and labels match in both raw jobs inputs). One sample; runner/setup variance is included. Toolchain and lock-pin identity between the two SHAs is not derived here. This is not a causal incremental-PR or critical-path estimate.`,
    measurement: "observed-same-profile-job-delta",
    baseline: {
      run_id: String(baselineRun.id),
      job_database_id: baselineJob.id,
      head_sha: baselineRun.head_sha,
      url: baselineRun.html_url,
      job_name: baselineJob.name,
      runner_labels: baselineJob.labels,
      runner_name: baselineJob.runner_name,
      runner_count: 1,
      started_at: baselineJob.started_at,
      completed_at: baselineJob.completed_at,
      duration_ms: baselineMs,
      runner_minutes: baselineMs / 60000,
      raw_run: "baseline-run.raw.json",
      raw_jobs: "baseline-jobs.raw.json"
    },
    candidate: {
      run_id: ciJob.run_id,
      job_database_id: job.id,
      head_sha: ciJob.head_sha,
      duration_ms: durationMs,
      runner_count: 1,
      runner_minutes: durationMs / 60000,
      raw_run: "github-run.raw.json",
      raw_jobs: "github-jobs.raw.json"
    },
    wall_ms: deltaMs,
    wall_minutes: deltaMinutes,
    runner_minutes: deltaMinutes,
    limitation: COST_LIMITATION
  };
  cost.budget = {
    added_wall_minutes: ADDED_WALL_MINUTES,
    added_runner_minutes: ADDED_RUNNER_MINUTES,
    disposition: `${wallWithin ? "observed-wall-budget-within-limit" : `observed-wall-budget-exceeded-by-${exceedanceMs / 1000}-seconds`}; ${runnerWithin ? "observed-runner-budget-within-limit" : "observed-runner-budget-exceeded"}`,
    comparison: "observed-same-profile-job-delta",
    observed_added_wall_minutes: deltaMinutes,
    observed_added_runner_minutes: deltaMinutes,
    wall_within_budget: wallWithin,
    wall_exceedance_ms: exceedanceMs,
    runner_within_budget: runnerWithin,
    recommendation: COST_RECOMMENDATION
  };
  return cost;
}

// ---------------------------------------------------------------------------
// counts
// ---------------------------------------------------------------------------

const SUMMARY_KEYS = { passed: "passed", skipped: "skipped", failed: "failed", flaky: "flaky" };

function parsePlaywrightSummary(log) {
  const executed = { passed: 0, skipped: 0, failed: 0, flaky: 0 };
  let lines = 0;
  for (const raw of String(log).split(/\r?\n/)) {
    const line = raw.replace(/\u001b\[[0-9;]*m/g, "").replace(/^\d{4}-\d{2}-\d{2}T[\d:.]+Z\s?/, "");
    const match = line.match(/^\s*(\d+)\s+(passed|skipped|failed|flaky)(?:\s+\([^)]*\))?\s*$/);
    if (match) {
      executed[SUMMARY_KEYS[match[2]]] += Number(match[1]);
      lines += 1;
    }
  }
  if (lines === 0) fail("operator log has no Playwright summary line (N passed / skipped / failed / flaky)");
  return { executed, summary_lines: lines };
}

function compareCounts(expected, executed, shorthandKey) {
  if (expected === undefined || expected === null) return [];
  const wanted = typeof expected === "number" ? { [shorthandKey]: expected } : expected;
  const mismatches = [];
  for (const key of Object.keys(wanted)) {
    const value = executed[key];
    if (value !== wanted[key]) mismatches.push({ key, expected: wanted[key], executed: value === undefined ? null : value });
  }
  return mismatches;
}

function deriveCounts({ operatorLog, demoCost, expected }) {
  const want = expected || {};
  const operator = parsePlaywrightSummary(operatorLog);
  const operatorMismatches = compareCounts(want.operator, operator.executed, "passed");
  if (!demoCost || !Array.isArray(demoCost.conditions)) fail("demo cost receipt has no conditions");
  const demo = {};
  const demoMismatches = [];
  for (const condition of demoCost.conditions) {
    if (!condition.executed_counts) fail(`demo cost condition ${condition.condition} has no executed_counts`);
    demo[condition.condition] = { executed: condition.executed_counts, expected_in_receipt: condition.expected_counts || null };
    for (const mismatch of compareCounts(want.demo, condition.executed_counts, "total")) {
      demoMismatches.push({ condition: condition.condition, ...mismatch });
    }
  }
  return {
    operator: {
      executed: operator.executed,
      summary_lines: operator.summary_lines,
      expected: want.operator === undefined ? null : want.operator,
      mismatch: operatorMismatches.length > 0,
      mismatches: operatorMismatches
    },
    demo: {
      ...demo,
      expected: want.demo === undefined ? null : want.demo,
      mismatch: demoMismatches.length > 0,
      mismatches: demoMismatches
    }
  };
}

// ---------------------------------------------------------------------------
// disposition
// ---------------------------------------------------------------------------

function wallToCiGreen(run, jobs) {
  const green = findJob(jobs, CI_GREEN);
  requireSuccessfulJob(green, "run");
  const started = Date.parse(run.run_started_at);
  if (!Number.isFinite(started)) fail(`run ${run.id} has no run_started_at`);
  const completed = Date.parse(green.completed_at);
  if (!Number.isFinite(completed)) fail(`run ${run.id} ${CI_GREEN} has no completed_at`);
  return completed - started;
}

function totalRunnerMs(jobs) {
  return jobList(jobs).reduce((sum, job) => (
    Number.isFinite(Date.parse(job.started_at)) && Number.isFinite(Date.parse(job.completed_at)) ? sum + jobDurationMs(job) : sum
  ), 0);
}

function deriveRun(baseline, candidate, sha, label) {
  const { run, jobs } = candidate;
  if (!run || !jobs) fail(`${label} run and jobs inputs must both be provided`);
  if (run.head_sha !== sha) {
    fail(`${label} run ${run.id} head_sha ${run.head_sha} is not the candidate ${sha}; refusing to measure another SHA`);
  }
  const jobEntries = {};
  for (const name of MEASURED_JOBS) {
    const base = findJob(baseline.jobs, name);
    const cand = findJob(jobs, name);
    requireSuccessfulJob(base, "baseline");
    requireSuccessfulJob(cand, label);
    const baseMs = jobDurationMs(base);
    const candMs = jobDurationMs(cand);
    const deltaMs = candMs - baseMs;
    const runnerDelta = deltaMs / 60000;
    jobEntries[name] = {
      baseline_seconds: baseMs / 1000,
      candidate_seconds: candMs / 1000,
      delta_seconds: deltaMs / 1000,
      runner_minutes_delta: runnerDelta,
      wall_within_budget: deltaMs <= WALL_BUDGET_MS,
      runner_within_budget: runnerDelta <= ADDED_RUNNER_MINUTES,
      wall_exceedance_ms: Math.max(0, deltaMs - WALL_BUDGET_MS)
    };
  }
  const baseWall = wallToCiGreen(baseline.run, baseline.jobs);
  const candWall = wallToCiGreen(run, jobs);
  const wallDelta = candWall - baseWall;
  const baseRunner = totalRunnerMs(baseline.jobs) / 60000;
  const candRunner = totalRunnerMs(jobs) / 60000;
  const runnerDelta = candRunner - baseRunner;
  return {
    run_id: String(run.id),
    head_sha: run.head_sha,
    jobs: jobEntries,
    wall_to_ci_green: { baseline_seconds: baseWall / 1000, candidate_seconds: candWall / 1000, delta_seconds: wallDelta / 1000 },
    runner_minutes: { baseline: baseRunner, candidate: candRunner, delta: runnerDelta },
    budget: {
      added_wall_minutes: ADDED_WALL_MINUTES,
      added_runner_minutes: ADDED_RUNNER_MINUTES,
      wall_within_budget: wallDelta <= WALL_BUDGET_MS,
      runner_within_budget: runnerDelta <= ADDED_RUNNER_MINUTES,
      wall_exceedance_ms: Math.max(0, wallDelta - WALL_BUDGET_MS),
      runner_exceedance_minutes: Math.max(0, runnerDelta - ADDED_RUNNER_MINUTES)
    }
  };
}

function derivePilotConditions(pilotCost, sourceEvent, identityBound) {
  if (!["workflow_dispatch", "pull_request"].includes(sourceEvent)) {
    fail("--pilot-source-event must be workflow_dispatch or pull_request when --pilot-cost is given");
  }
  if (typeof identityBound !== "boolean") fail("--identity-bound must be true or false when --pilot-cost is given");
  const result = { source_event: sourceEvent, identity_bound: identityBound };
  for (const name of ["cold", "warm"]) {
    const condition = (pilotCost.conditions || []).find((item) => item.condition === name);
    if (!condition) fail(`pilot cost receipt has no ${name} condition`);
    for (const field of ["setup_ms", "execution_ms", "wall_ms", "runner_minutes"]) {
      if (!Number.isFinite(condition[field])) fail(`pilot ${name} condition has no numeric ${field}`);
    }
    result[name] = {
      setup_ms: condition.setup_ms,
      execution_ms: condition.execution_ms,
      wall_ms: condition.wall_ms,
      runner_minutes: condition.runner_minutes,
      wall_within_budget: condition.wall_ms <= WALL_BUDGET_MS,
      runner_within_budget: condition.runner_minutes <= ADDED_RUNNER_MINUTES
    };
  }
  return result;
}

function sortedObject(object) {
  return Object.fromEntries(Object.keys(object).sort().map((key) => [key, object[key]]));
}

function deriveDisposition(options) {
  const { baselineRun, baselineJobs, dispatch, pr, sha, counts } = options;
  if (!baselineRun || !baselineJobs) fail("baseline run and jobs inputs are required");
  if (!dispatch && !pr) fail("disposition needs at least one measured run (dispatch or pull_request)");
  if (!/^[0-9a-f]{40}$/.test(String(sha))) fail("--sha must be a full 40-character lowercase hex candidate SHA");
  const baseline = { run: baselineRun, jobs: baselineJobs };
  const runs = {};
  if (dispatch) runs[RUN_KEYS.dispatch] = deriveRun(baseline, dispatch, sha, RUN_KEYS.dispatch);
  if (pr) runs[RUN_KEYS.pr] = deriveRun(baseline, pr, sha, RUN_KEYS.pr);
  const pilot = options.pilotCost
    ? derivePilotConditions(options.pilotCost, options.pilotSourceEvent, options.identityBound)
    : null;
  return {
    schema_version: DISPOSITION_SCHEMA,
    source_revision: sha,
    baseline_run_id: String(baselineRun.id),
    runs,
    pilot_conditions: pilot,
    counts: counts === undefined ? {} : counts,
    input_hashes: sortedObject(options.inputHashes || {})
  };
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const REPEATABLE_FLAGS = new Set(["--input"]);

function parseFlags(argv) {
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const flag = argv[i];
    if (!flag.startsWith("--")) fail(`unexpected argument ${flag}`);
    const value = argv[i + 1];
    if (value === undefined || (value.startsWith("--") && value !== "--")) fail(`${flag} needs a value`);
    i += 1;
    if (REPEATABLE_FLAGS.has(flag)) {
      (flags[flag] = flags[flag] || []).push(value);
    } else {
      if (flag in flags) fail(`duplicate option ${flag}`);
      flags[flag] = value;
    }
  }
  return flags;
}

function need(flags, name) {
  if (flags[name] === undefined) fail(`required option ${name} is missing`);
  return flags[name];
}

function writeOutput(flags, inputFlags, value) {
  const out = path.resolve(need(flags, "--out"));
  for (const name of inputFlags) {
    const given = [].concat(flags[name] === undefined ? [] : flags[name]);
    for (const file of given) {
      if (path.resolve(file) === out) fail(`--out must not overwrite its own input (${name} ${file})`);
    }
  }
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, `${JSON.stringify(value, null, 2)}\n`);
  return out;
}

function parseBoolean(value, flag) {
  if (value === "true") return true;
  if (value === "false") return false;
  return fail(`${flag} must be true or false`);
}

function cli(argv = process.argv.slice(2)) {
  const [command, ...rest] = argv;
  const flags = parseFlags(rest);
  if (command === "ci-job") {
    const runFile = need(flags, "--run");
    const jobsFile = need(flags, "--jobs");
    const log = flags["--log"] === undefined ? undefined : fs.readFileSync(flags["--log"], "utf8");
    const ciJob = deriveCiJob(readJson(runFile), readJson(jobsFile), need(flags, "--job-name"), {
      log,
      rawRunName: path.basename(runFile),
      rawJobsName: path.basename(jobsFile)
    });
    return writeOutput(flags, ["--run", "--jobs", "--log"], ciJob);
  }
  if (command === "enrich-cost") {
    const cost = enrichCost(
      readJson(need(flags, "--downloaded")),
      readJson(need(flags, "--ci-job")),
      readJson(need(flags, "--baseline-run")),
      readJson(need(flags, "--baseline-jobs"))
    );
    return writeOutput(flags, ["--downloaded", "--ci-job", "--baseline-run", "--baseline-jobs"], cost);
  }
  if (command === "counts") {
    const counts = deriveCounts({
      operatorLog: fs.readFileSync(need(flags, "--operator-log"), "utf8"),
      demoCost: readJson(need(flags, "--demo-cost")),
      expected: readJson(need(flags, "--expected"))
    });
    return writeOutput(flags, ["--operator-log", "--demo-cost", "--expected"], counts);
  }
  if (command === "disposition") {
    const hashes = {};
    const hashed = (role, file) => { hashes[role] = sha256File(file); return file; };
    const pair = (runFlag, jobsFlag, role) => {
      if (flags[runFlag] === undefined && flags[jobsFlag] === undefined) return null;
      return {
        run: readJson(hashed(`${role}_run`, need(flags, runFlag))),
        jobs: readJson(hashed(`${role}_jobs`, need(flags, jobsFlag)))
      };
    };
    const baselineRun = readJson(hashed("baseline_run", need(flags, "--baseline-run")));
    const baselineJobs = readJson(hashed("baseline_jobs", need(flags, "--baseline-jobs")));
    const dispatch = pair("--dispatch-run", "--dispatch-jobs", "dispatch");
    const pr = pair("--pr-run", "--pr-jobs", "pr");
    let pilotCost = null;
    if (flags["--pilot-cost"] !== undefined) pilotCost = readJson(hashed("pilot_cost", flags["--pilot-cost"]));
    let counts;
    const countsArg = need(flags, "--counts");
    if (countsArg === "{}") counts = {};
    else counts = readJson(hashed("counts", countsArg));
    for (const file of flags["--input"] || []) {
      const key = `input:${path.basename(file)}`;
      if (key in hashes) fail(`duplicate --input name ${path.basename(file)}`);
      hashes[key] = sha256File(file);
    }
    const disposition = deriveDisposition({
      baselineRun, baselineJobs, dispatch, pr,
      sha: need(flags, "--sha"),
      counts,
      pilotCost,
      pilotSourceEvent: flags["--pilot-source-event"],
      identityBound: flags["--identity-bound"] === undefined ? undefined : parseBoolean(flags["--identity-bound"], "--identity-bound"),
      inputHashes: hashes
    });
    return writeOutput(flags, [
      "--baseline-run", "--baseline-jobs", "--dispatch-run", "--dispatch-jobs", "--pr-run", "--pr-jobs",
      "--pilot-cost", "--counts", "--input"
    ], disposition);
  }
  return fail(`unknown subcommand '${command || ""}'; expected ci-job, enrich-cost, counts or disposition`);
}

if (require.main === module) {
  try {
    const out = cli();
    process.stdout.write(`${out}\n`);
  } catch (error) {
    process.stderr.write(`ERROR: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = {
  deriveCiJob,
  enrichCost,
  deriveCounts,
  deriveDisposition,
  sha256File,
  cli,
  constants: { DEMO_JOB, OPERATOR_JOB, SUPPORT_JOB, CI_GREEN, RUNNER_LABEL_TABLE }
};
