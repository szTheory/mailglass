const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync, spawnSync } = require("node:child_process");
const test = require("node:test");

const ROOT = path.resolve(__dirname, "..");
const MANIFEST = JSON.parse(fs.readFileSync(path.join(ROOT, "reference/persona_spec/quick_view_scenarios.json"), "utf8"));
const APPROVED = JSON.parse(fs.readFileSync(path.join(ROOT, "mailglass_admin/docs/storybook-axe-approved.json"), "utf8"));
const { selectedCases } = require(path.join(ROOT, "mailglass_admin/e2e/support/storybook-axe.cjs"));
const CHECKER = path.join(__dirname, "check_phase174_evidence.cjs");
const HASH = value => crypto.createHash("sha256").update(value).digest("hex");
const RUN_ID = "local-phase174-complete";
const REVISION = execFileSync("git", ["rev-parse", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim();
const STAMP = "2026-10-27T00:00:00.000Z";
const AXE = selectedCases(MANIFEST);
const AXE_CASES = AXE.cases.map(({ case_id, scenario_id, state, theme }) => ({ case_id, scenario_id, state, theme }));
const HOOK_CASE_IDS = [
  "storybook:mounted-preview",
  "delivery:escape-focus-return",
  "delivery:close-focus-return",
  "delivery:reconnect-focus-return",
  "inbound:close-focus-return",
  "inbound:escape-focus-return"
];

function fidelityCaseIds() {
  const ids = [
    "theme:delivery:northstar_normal",
    "theme:inbound:northstar_normal",
    "fonts:delivery:northstar_normal",
    "fonts:inbound:northstar_normal",
    "widths:delivery:responsive-matrix",
    "widths:inbound:responsive-matrix"
  ];
  for (const area of ["delivery", "inbound"]) {
    for (const [index, width] of [320, 375, 768, 1280, 1440].entries()) {
      for (const theme of ["light", "dark"]) {
        const boundary = (index + (theme === "dark" ? 1 : 0)) % 2 === 1;
        const variant = boundary ? "northstar_first" : "northstar_normal";
        ids.push(`width:${area}:${variant}:${width}:${theme}`);
      }
    }
  }
  return ids;
}

const FIDELITY_CASE_IDS = fidelityCaseIds();
const PHASE173_TITLES = [
  "dashboard links to preview and operator surfaces",
  "outbound operator opens with seeded delivery evidence",
  "inbound operator opens with seeded support mailbox evidence",
  "empty account stays isolated and explains the absence of deliveries",
  "recipient browser shows a truthful expired unsubscribe state"
];
const PHASE174_DEMO_TITLES = [
  "Storybook owns its iframe hook and both pinned Demo surfaces complete real cycles",
  "delivery story owns Light, Dark, and live System review themes",
  "inbound story owns Light, Dark, and live System review themes",
  "delivery loads production CSS, all font bytes, and computed roles",
  "inbound loads production CSS, all font bytes, and computed roles",
  "delivery normal and boundary quick views fit bounded responsive widths",
  "inbound normal and boundary quick views fit bounded responsive widths"
];
const DEMO_TITLES = [...PHASE173_TITLES, ...PHASE174_DEMO_TITLES];
const DEMO_CASE_IDS = testReport().suites.flatMap(suite => suite.specs.map(spec => `${spec.file}:${spec.line}:${spec.title}`));

function localSource() {
  const files = [{ path: "scripts/run_demo_browser_evidence.sh", bytes: 14, sha256: HASH("wrapper-source") }];
  const body = files.map(file => `${file.path}\0${file.bytes}\0${file.sha256}\n`).join("");
  return {
    hash_method: "sha256(sorted(path\\0byte_length\\0file_sha256\\n))",
    input_paths: files.map(file => file.path),
    files,
    source_revision: REVISION,
    source_digest: HASH(body)
  };
}

function testReport() {
  const byTitle = (title, file, line) => ({ title, file, line, tests: [{ outcome: "expected", results: [{ status: "passed" }] }] });
  return {
    suites: [
      { title: "phase173-evidence.spec.js", specs: PHASE173_TITLES.map((title, index) => byTitle(title, "phase173-evidence.spec.js", 200 + index)) },
      { title: "storybook-hooks.spec.js", specs: [byTitle(PHASE174_DEMO_TITLES[0], "storybook-hooks.spec.js", 100)] },
      { title: "storybook-fidelity.spec.js", specs: PHASE174_DEMO_TITLES.slice(1).map((title, index) => byTitle(title, "storybook-fidelity.spec.js", 300 + index)) }
    ]
  };
}

function addSameTitleDifferentFileCase(evidenceDir) {
  const phaseDir = path.join(evidenceDir, "phase174");
  const duplicate = {
    title: PHASE173_TITLES[0],
    file: "demo.spec.js",
    line: 113,
    tests: [{ outcome: "expected", results: [{ status: "passed" }] }]
  };
  for (const conditionName of ["cold", "warm"]) {
    const conditionDir = path.join(phaseDir, conditionName);
    const reportPath = path.join(conditionDir, "demo-playwright-report.json");
    const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
    report.suites.push({ title: "demo.spec.js", specs: [duplicate] });
    fs.writeFileSync(reportPath, JSON.stringify(report));
  }
  const executionPath = path.join(phaseDir, "execution.json");
  const execution = JSON.parse(fs.readFileSync(executionPath, "utf8"));
  for (const condition of execution.conditions) {
    condition.demo_case_ids.push("demo.spec.js:113:dashboard links to preview and operator surfaces");
    condition.expected_counts.demo += 1;
    condition.expected_counts.total += 1;
    condition.executed_counts.demo += 1;
    condition.executed_counts.total += 1;
  }
  fs.writeFileSync(executionPath, JSON.stringify(execution));
  const costPath = path.join(phaseDir, "cost.json");
  const cost = JSON.parse(fs.readFileSync(costPath, "utf8"));
  for (const condition of cost.conditions) {
    condition.expected_counts.demo += 1;
    condition.expected_counts.total += 1;
    condition.executed_counts.demo += 1;
    condition.executed_counts.total += 1;
  }
  fs.writeFileSync(costPath, JSON.stringify(cost));
}

function setStorybookDocumentOwnership(evidenceDir) {
  const phaseDir = path.join(evidenceDir, "phase174");
  for (const conditionName of ["cold", "warm"]) {
    const hookPath = path.join(phaseDir, conditionName, "hooks.json");
    const receipt = JSON.parse(fs.readFileSync(hookPath, "utf8"));
    receipt.storybook.documents = [
      { url: "/dev/storybook/quick_views/delivery", admin_bootstrap_present: false },
      { url: "/dev/storybook/iframe/quick_views/delivery", admin_bootstrap_present: false }
    ];
    receipt.final_documents[0].admin_bootstrap_present = true;
    fs.writeFileSync(hookPath, JSON.stringify(receipt));
  }
}

function hooksReceipt(runId, condition, identity) {
  return {
    schema_version: "phase174-storybook-hooks.v1",
    run_identity: { run_id: runId, condition, ...identity },
    proof_boundary: { reset: "authenticated reset endpoint used" },
    source: { path: "mailglass_admin/priv/static/hooks.js", md5: "a".repeat(32) },
    locked_versions: {
      demo_live_view: "1.1.33",
      admin_live_view: "1.2.13",
      phoenix_storybook: "1.2.0",
      demo_playwright: "1.60.0",
      admin_playwright: "1.59.1"
    },
    storybook: {
      hook_asset_responses: [{ status: 200, hasStorybookRegistration: true, hasSocketConstructor: false }],
      documents: [
        { url: "/dev/storybook/quick_views/delivery", admin_bootstrap_present: false },
        { url: "/dev/storybook/iframe/quick_views/delivery", admin_bootstrap_present: false }
      ],
      preview: { mounted: true, removed: { iframe_detached: true, browsing_context_receipts: [{}] }, remounted_listener_count: 1 }
    },
    browser_websockets: [{ path: "/live/websocket", sentFrames: 2, receivedFrames: 2 }],
    demo_route_cases: [
      ...Array.from({ length: 3 }, (_, index) => ({ surface: "delivery", opened: `d${index}`, navigatedTo: `d${index + 1}`, focusReturnedTo: `delivery-opener-${index}`, focusinAdded: 1, focusinRemoved: 1, reducedMotion: true })),
      ...Array.from({ length: 2 }, (_, index) => ({ surface: "inbound", opened: `i${index}`, navigatedTo: `i${index + 1}`, focusReturnedTo: `inbound-opener-${index}`, focusinAdded: 1, focusinRemoved: 1, reducedMotion: true }))
    ],
    final_documents: [{ url: "/ops/mail/inbound", admin_bootstrap_present: true }]
  };
}

function fidelityReceipt(runId, condition, identity) {
  const theme = area => ({
    caseId: `theme:${area}:northstar_normal`,
    owner: "quick-view-story",
    systemLight: { resolvedScheme: "light", dataTheme: "mailglass-light" },
    systemDark: { resolvedScheme: "dark", dataTheme: "mailglass-dark" },
    explicitThemeStability: true,
    selectionPreserved: true,
    hostPreferencePersisted: false
  });
  const stylesheet = area => ({
    caseId: `fonts:${area}:northstar_normal`,
    source: { path: "mailglass_admin/assets/css/app.css", sha256: "a".repeat(64) },
    built: { path: "mailglass_admin/priv/static/app.css", sha256: "b".repeat(64), bytes: 12 },
    served: { sha256: "b".repeat(64), bytes: 12, matchesBuilt: true }
  });
  const fonts = area => ({
    caseId: `fonts:${area}:northstar_normal`,
    assets: ["inter-400.woff2", "inter-700.woff2", "inter-tight-400.woff2", "inter-tight-700.woff2", "ibm-plex-mono-400.woff2", "ibm-plex-mono-700.woff2"].map(file => ({ path: file, status: 200, bytes: 12, loadedFace: "loaded" }))
  });
  const widthCases = area => [320, 375, 768, 1280, 1440].flatMap((width, index) => ["light", "dark"].map(themeName => {
    const boundary = (index + (themeName === "dark" ? 1 : 0)) % 2 === 1;
    return {
      caseId: `width:${area}:${boundary ? "northstar_first" : "northstar_normal"}:${width}:${themeName}`,
      viewportWidth: width,
      theme: themeName,
      closeWithinPane: true,
      technicalWrapping: { width: 100, scrollWidth: 100, overflowWrap: "anywhere" }
    };
  }));
  return {
    run_identity: { run_id: runId, condition, ...identity },
    source: { revision: identity.source_revision, dirty: false, dirtyStatusSha256: "c".repeat(64) },
    selectedCaseIds: FIDELITY_CASE_IDS,
    executedCaseIds: FIDELITY_CASE_IDS,
    themes: [theme("delivery"), theme("inbound")],
    stylesheets: [stylesheet("delivery"), stylesheet("inbound")],
    fonts: [fonts("delivery"), fonts("inbound")],
    computedRoles: [{ caseId: "fonts:delivery:northstar_normal" }, { caseId: "fonts:inbound:northstar_normal" }],
    widths: ["delivery", "inbound"].map(area => ({ caseId: `widths:${area}:responsive-matrix`, cases: widthCases(area) })),
    evidenceLimits: ["Browser zoom reconciliation is owned by Phase 178."]
  };
}

function axeReceipt(runId, condition, identity) {
  const executionId = `${runId}-${condition}`;
  return {
    schema_version: 1,
    run_id: executionId,
    producer_execution_token: `token-${executionId}`,
    source_revision: identity.source_revision,
    source_digest: identity.source_digest,
    started_at: STAMP,
    completed_at: STAMP,
    expected: AXE_CASES,
    excluded: AXE.emptyRouteOnly.map(({ scenario_id, state, proof_boundary, reason }) => ({ scenario_id, state, proof_boundary, reason })),
    executed: AXE_CASES.map(item => ({ ...item, status: "passed", completed_at: STAMP })),
    violations: [],
    incomplete: []
  };
}

function conditionCounts() {
  return {
    demo: DEMO_CASE_IDS.length,
    hooks: HOOK_CASE_IDS.length,
    fidelity: FIDELITY_CASE_IDS.length,
    axe: AXE_CASES.length,
    total: DEMO_CASE_IDS.length + HOOK_CASE_IDS.length + FIDELITY_CASE_IDS.length + AXE_CASES.length
  };
}

function browserReceipt(type, condition, identity) {
  const admin = type === "admin";
  return {
    schema_version: `phase174-${type}-browser.v1`,
    run_identity: { run_id: `${RUN_ID}-${condition}`, condition, ...identity },
    ...(admin ? { cli: "/workspace/mailglass_admin/node_modules/.bin/playwright", install_exit_code: 0 } : {}),
    version: admin ? "1.59.1" : "1.60.0",
    chromium_revision: admin ? "1234" : "5678",
    cache_directory: "/cache/playwright",
    cache_state: condition === "cold" ? "miss" : "hit",
    installer_ms: admin ? 15 : 10
  };
}

function createFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase174-evidence-"));
  const phaseDir = path.join(root, "phase174");
  fs.mkdirSync(phaseDir, { recursive: true });
  const source = localSource();
  const identity = { source_revision: REVISION, source_digest: source.source_digest };
  const counts = conditionCounts();
  const conditions = [];
  for (const condition of ["cold", "warm"]) {
    const runId = `${RUN_ID}-${condition}`;
    const conditionDir = path.join(phaseDir, condition);
    fs.mkdirSync(conditionDir, { recursive: true });
    fs.writeFileSync(path.join(conditionDir, "demo-playwright-report.json"), JSON.stringify(testReport()));
    fs.writeFileSync(path.join(conditionDir, "hooks.json"), JSON.stringify(hooksReceipt(runId, condition, identity)));
    fs.writeFileSync(path.join(conditionDir, "fidelity.json"), JSON.stringify(fidelityReceipt(runId, condition, identity)));
    fs.writeFileSync(path.join(conditionDir, "axe.json"), JSON.stringify(axeReceipt(RUN_ID, condition, identity)));
    fs.writeFileSync(path.join(conditionDir, "admin-browser.json"), JSON.stringify(browserReceipt("admin", condition, identity)));
    fs.writeFileSync(path.join(conditionDir, "demo-browser.json"), JSON.stringify(browserReceipt("demo", condition, identity)));
    const timings = {
      service_start: 100,
      demo_lock_audit: 1,
      demo_npm_ci: 20,
      demo_browser_install: 10,
      demo_scan: 40,
      admin_npm_ci: 20,
      admin_browser_install: 15,
      admin_axe_scan: 80,
      comparison: 14
    };
    const caseRecord = {
      condition,
      run_id: runId,
      job_id: "local",
      source_revision: REVISION,
      source_digest: source.source_digest,
      status: "passed",
      started_at: STAMP,
      completed_at: "2026-10-27T00:00:00.300Z",
      timings_ms: timings,
      expected_counts: counts,
      executed_counts: counts,
      setup_ms: 166,
      execution_ms: 134,
      wall_ms: 300,
      demo_case_ids: DEMO_CASE_IDS,
      hook_case_ids: HOOK_CASE_IDS,
      fidelity_case_ids: FIDELITY_CASE_IDS,
      axe_case_ids: AXE_CASES.map(item => item.case_id)
    };
    caseRecord.admin_browser = browserReceipt("admin", condition, identity);
    caseRecord.demo_browser = browserReceipt("demo", condition, identity);
    conditions.push(caseRecord);
  }

  fs.writeFileSync(path.join(phaseDir, "execution.json"), JSON.stringify({
    schema_version: "phase174-execution.v1",
    phase: 174,
    run_id: RUN_ID,
    mode: "local",
    pilot: true,
    source_revision: REVISION,
    source_digest: source.source_digest,
    source,
    github: {
      actions: false,
      run_id: "",
      run_attempt: "",
      job: "",
      sha: "",
      repository: "",
      runner_name: "",
      runner_os: "",
      runner_arch: ""
    },
    conditions
  }, null, 2));
  fs.writeFileSync(path.join(phaseDir, "cost.json"), JSON.stringify({
    schema_version: "phase174-cost.v1",
    run_id: RUN_ID,
    source_revision: REVISION,
    source_digest: source.source_digest,
    pilot: true,
    conditions: conditions.map(({ condition, run_id, setup_ms, execution_ms, wall_ms, expected_counts, executed_counts }) => ({
      condition,
      run_id,
      job_id: "local",
      source_revision: REVISION,
      source_digest: source.source_digest,
      timings_ms: conditions.find(item => item.condition === condition).timings_ms,
      setup_ms,
      execution_ms,
      teardown_ms: condition === "warm" ? 10 : 0,
      wall_ms,
      runner_count: 1,
      runner_minutes: null,
      runner_minutes_status: "awaiting-hosted-job",
      expected_counts,
      executed_counts,
      admin_browser: conditions.find(item => item.condition === condition).admin_browser,
      demo_browser: conditions.find(item => item.condition === condition).demo_browser
    })),
    pilot_wall_ms: 750,
    teardown_completed_at: "2026-10-27T00:00:00.750Z",
    added_cost: { status: "unmeasured", reason: "No same-profile existing-lane baseline is available in this local fixture." },
    budget: { added_wall_minutes: 5, added_runner_minutes: 10, disposition: "awaiting-hosted-job" }
  }, null, 2));
  return root;
}

function runChecker(evidenceDir, args = []) {
  return spawnSync(process.execPath, [CHECKER, "--evidence-dir", evidenceDir, "--pilot", ...args], {
    cwd: ROOT,
    encoding: "utf8"
  });
}

function addCiJob(evidenceDir, overrides = {}) {
  const phaseDir = path.join(evidenceDir, "phase174");
  const executionPath = path.join(phaseDir, "execution.json");
  const costPath = path.join(phaseDir, "cost.json");
  const execution = JSON.parse(fs.readFileSync(executionPath, "utf8"));
  const cost = JSON.parse(fs.readFileSync(costPath, "utf8"));
  const github = {
    actions: true,
    run_id: "9000",
    run_attempt: "1",
    job: "demo_browser_evidence",
    sha: execution.source_revision,
    repository: "szTheory/mailglass",
    runner_name: "runner-linux-01",
    runner_os: "Linux",
    runner_arch: "X64"
  };
  execution.github = { ...github, ...(overrides.github || {}) };
  for (const condition of cost.conditions) {
    condition.job_id = execution.github.job;
    condition.runner_minutes = condition.wall_ms / 60000;
    condition.runner_minutes_status = "wrapper-condition-elapsed";
  }
  const startedAt = "2026-10-27T00:00:00.000Z";
  const completedAt = "2026-10-27T00:01:00.000Z";
  const job = {
    id: 321,
    name: "Demo Browser Evidence (Docker Compose / Chromium)",
    status: "completed",
    conclusion: "success",
    runner_name: github.runner_name,
    runner_os: github.runner_os,
    runner_arch: github.runner_arch,
    started_at: startedAt,
    completed_at: completedAt,
    steps: [
      "Checkout",
      "Audit demo browser lockfile",
      "Test pinned baseline provisioning",
      "Run demo browser evidence"
    ].map(name => ({ name, status: "completed", conclusion: "success" }))
  };
  const ciJob = {
    schema_version: "phase174-ci-job.v1",
    repository: github.repository,
    run_id: github.run_id,
    run_attempt: github.run_attempt,
    head_sha: execution.source_revision,
    status: "completed",
    conclusion: "success",
    url: "https://github.com/szTheory/mailglass/actions/runs/9000",
    run_started_at: startedAt,
    run_completed_at: completedAt,
    duration_ms: 60000,
    job
  };
  cost.hosted_job = {
    run_id: github.run_id,
    run_attempt: github.run_attempt,
    repository: github.repository,
    head_sha: execution.source_revision,
    job_id: github.job,
    job_database_id: job.id,
    job_name: job.name,
    runner_name: github.runner_name,
    runner_os: github.runner_os,
    runner_arch: github.runner_arch,
    started_at: startedAt,
    completed_at: completedAt,
    duration_ms: 60000,
    runner_count: 1,
    runner_minutes: 1
  };
  if (overrides.ciJob) Object.assign(ciJob, overrides.ciJob);
  if (overrides.job) Object.assign(ciJob.job, overrides.job);
  fs.writeFileSync(executionPath, JSON.stringify(execution, null, 2));
  fs.writeFileSync(costPath, JSON.stringify(cost, null, 2));
  fs.writeFileSync(path.join(evidenceDir, "ci-job.json"), JSON.stringify(ciJob, null, 2));
  return { ciJob, execution, cost };
}

test("checker accepts complete independent local cold/warm evidence", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const result = runChecker(evidenceDir);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const summary = JSON.parse(result.stdout.trim());
  assert.equal(summary.valid, true);
  assert.equal(summary.conditions.cold.axe.successful, AXE_CASES.length);
  assert.equal(summary.conditions.warm.axe.successful, AXE_CASES.length);
});

test("same test title from different source locations remains separately countable", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  addSameTitleDifferentFileCase(evidenceDir);
  const result = runChecker(evidenceDir);
  assert.equal(result.status, 0, result.stderr || result.stdout);
});

test("Admin bootstrap is isolated from Storybook documents and present on production routes", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  setStorybookDocumentOwnership(evidenceDir);
  const result = runChecker(evidenceDir);
  assert.equal(result.status, 0, result.stderr || result.stdout);
});

test("checker rejects missing, empty, partial, and stale reports", t => {
  const missingDir = createFixture();
  t.after(() => fs.rmSync(missingDir, { recursive: true, force: true }));
  fs.rmSync(path.join(missingDir, "phase174/cold/hooks.json"));
  assert.notEqual(runChecker(missingDir).status, 0, "missing hook receipt must fail");

  const emptyDir = createFixture();
  t.after(() => fs.rmSync(emptyDir, { recursive: true, force: true }));
  const axePath = path.join(emptyDir, "phase174/cold/axe.json");
  const emptyAxe = JSON.parse(fs.readFileSync(axePath, "utf8"));
  emptyAxe.executed = [];
  fs.writeFileSync(axePath, JSON.stringify(emptyAxe));
  assert.notEqual(runChecker(emptyDir).status, 0, "zero executed axe cases must fail");

  const partialDir = createFixture();
  t.after(() => fs.rmSync(partialDir, { recursive: true, force: true }));
  const partialAxePath = path.join(partialDir, "phase174/warm/axe.json");
  const partialAxe = JSON.parse(fs.readFileSync(partialAxePath, "utf8"));
  partialAxe.executed.pop();
  fs.writeFileSync(partialAxePath, JSON.stringify(partialAxe));
  assert.notEqual(runChecker(partialDir).status, 0, "partial axe execution must fail");

  const staleDir = createFixture();
  t.after(() => fs.rmSync(staleDir, { recursive: true, force: true }));
  const stalePath = path.join(staleDir, "phase174/cold/axe.json");
  const stale = JSON.parse(fs.readFileSync(stalePath, "utf8"));
  stale.source_revision = "f".repeat(40);
  fs.writeFileSync(stalePath, JSON.stringify(stale));
  assert.notEqual(runChecker(staleDir).status, 0, "stale source identity must fail");
});

test("checker rejects absent cost fields and forged local CI labels", t => {
  const missingCostDir = createFixture();
  t.after(() => fs.rmSync(missingCostDir, { recursive: true, force: true }));
  const costPath = path.join(missingCostDir, "phase174/cost.json");
  const cost = JSON.parse(fs.readFileSync(costPath, "utf8"));
  delete cost.conditions[0].setup_ms;
  fs.writeFileSync(costPath, JSON.stringify(cost));
  assert.notEqual(runChecker(missingCostDir).status, 0, "missing setup cost must fail");

  const teardownDir = createFixture();
  t.after(() => fs.rmSync(teardownDir, { recursive: true, force: true }));
  const teardownPath = path.join(teardownDir, "phase174/cost.json");
  const teardown = JSON.parse(fs.readFileSync(teardownPath, "utf8"));
  teardown.conditions[1].teardown_ms = 0;
  fs.writeFileSync(teardownPath, JSON.stringify(teardown));
  assert.notEqual(runChecker(teardownDir).status, 0, "unmeasured final teardown must fail");

  const forgedDir = createFixture();
  t.after(() => fs.rmSync(forgedDir, { recursive: true, force: true }));
  const executionPath = path.join(forgedDir, "phase174/execution.json");
  const execution = JSON.parse(fs.readFileSync(executionPath, "utf8"));
  execution.github = {
    actions: true,
    run_id: "9000",
    run_attempt: "1",
    job: "demo_browser_evidence",
    sha: execution.source_revision,
    repository: "szTheory/mailglass",
    runner_name: "caller-says-runner",
    runner_os: "Linux",
    runner_arch: "X64"
  };
  fs.writeFileSync(executionPath, JSON.stringify(execution));
  assert.notEqual(runChecker(forgedDir, ["--require-ci"]).status, 0, "local labels without independently fetched job evidence must fail");
});

test("require-ci rejects mismatched job identity and missing completed-job metadata", t => {
  const mismatchDir = createFixture();
  t.after(() => fs.rmSync(mismatchDir, { recursive: true, force: true }));
  addCiJob(mismatchDir, { ciJob: { head_sha: "e".repeat(40) } });
  const mismatch = runChecker(mismatchDir, ["--require-ci"]);
  assert.notEqual(mismatch.status, 0, "mismatched CI head SHA must fail");

  const incompleteDir = createFixture();
  t.after(() => fs.rmSync(incompleteDir, { recursive: true, force: true }));
  addCiJob(incompleteDir, { job: { conclusion: "failure" } });
  const incomplete = runChecker(incompleteDir, ["--require-ci"]);
  assert.notEqual(incomplete.status, 0, "uncompleted/failed CI job metadata must fail");
});

test("require-ci accepts matching completed job and derives full runner duration", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  addCiJob(evidenceDir);
  const result = runChecker(evidenceDir, ["--require-ci"]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const summary = JSON.parse(result.stdout.trim());
  assert.equal(summary.hosted_job.duration_ms, 60000);
  assert.equal(summary.hosted_job.runner_minutes, 1);
});

test("CI producer validates condition timings before completed job metadata exists", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { cost } = addCiJob(evidenceDir);
  delete cost.hosted_job;
  fs.writeFileSync(path.join(evidenceDir, "phase174/cost.json"), JSON.stringify(cost));
  fs.rmSync(path.join(evidenceDir, "ci-job.json"));

  const preflight = runChecker(evidenceDir);
  assert.equal(preflight.status, 0, preflight.stderr || preflight.stdout);
  assert.equal(JSON.parse(preflight.stdout).hosted_job, null,
    "producer preflight must not claim independent hosted proof");
  assert.notEqual(runChecker(evidenceDir, ["--require-ci"]).status, 0,
    "the final gate must still require completed independent job metadata");
});

test('source identity includes dirty route and .story.exs bytes at the same revision', t => {
  const checker = require('./check_phase174_evidence.cjs');
  const required = [
    'reference/demo_app/lib/mailglass_demo_web/router.ex',
    'reference/demo_app/storybook/quick_views/delivery.story.exs',
    'reference/demo_app/storybook/quick_views/inbound.story.exs',
    'reference/demo_app/storybook/primitives/theme_picker.story.exs',
    'mailglass_admin/lib/mailglass_admin/inbound_live.ex',
    'mailglass_admin/lib/mailglass_admin/inbound/records_list.ex'
  ];
  const paths = checker.selectedSourcePaths(ROOT);
  for (const file of required) assert.ok(paths.includes(file), `missing exercised source: ${file}`);
  const copy = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'mailglass-source-')));
  t.after(() => fs.rmSync(copy, { recursive: true, force: true }));
  for (const file of paths) {
    fs.mkdirSync(path.dirname(path.join(copy, file)), { recursive: true });
    fs.copyFileSync(path.join(ROOT, file), path.join(copy, file));
  }
  execFileSync('git', ['init', '-q', copy]);
  execFileSync('git', ['add', '.'], { cwd: copy });
  const original = checker.computeSourceIdentity(copy, REVISION).source_digest;
  for (const file of required) {
    const full = path.join(copy, file), bytes = fs.readFileSync(full);
    fs.appendFileSync(full, '\n# dirty source proof\n');
    assert.notEqual(checker.computeSourceIdentity(copy, REVISION).source_digest, original, file);
    fs.writeFileSync(full, bytes);
  }
});
