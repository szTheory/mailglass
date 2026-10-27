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

function localSource() {
  const files = [{ path: "scripts/run_demo_browser_evidence.sh", bytes: 14, sha256: HASH("wrapper-source") }];
  const body = files.map(file => `${file.path}\0${file.bytes}\0${file.sha256}\n`).join("");
  return {
    hash_method: "sha256(sorted(path\\0byte_length\\0file_sha256\\n))",
    input_paths: files.map(file => file.path),
    files,
    source_digest: HASH(body)
  };
}

function testReport() {
  const byTitle = title => ({ title, tests: [{ outcome: "expected", results: [{ status: "passed" }] }] });
  return {
    suites: [
      { title: "phase173-evidence.spec.js", specs: PHASE173_TITLES.map(byTitle) },
      { title: "storybook-hooks.spec.js", specs: [byTitle(PHASE174_DEMO_TITLES[0])] },
      { title: "storybook-fidelity.spec.js", specs: PHASE174_DEMO_TITLES.slice(1).map(byTitle) }
    ]
  };
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
      preview: { mounted: true, removed: { iframe_detached: true, browsing_context_receipts: [{}] }, remounted_listener_count: 1 }
    },
    browser_websockets: [{ path: "/live/websocket", sentFrames: 2, receivedFrames: 2 }],
    demo_route_cases: [
      ...Array.from({ length: 3 }, (_, index) => ({ surface: "delivery", opened: `d${index}`, navigatedTo: `d${index + 1}`, focusReturnedTo: `delivery-opener-${index}`, focusinAdded: 1, focusinRemoved: 1, reducedMotion: true })),
      ...Array.from({ length: 2 }, (_, index) => ({ surface: "inbound", opened: `i${index}`, navigatedTo: `i${index + 1}`, focusReturnedTo: `inbound-opener-${index}`, focusinAdded: 1, focusinRemoved: 1, reducedMotion: true }))
    ],
    final_documents: [{ admin_bootstrap_present: false }]
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
    demo: DEMO_TITLES.length,
    hooks: HOOK_CASE_IDS.length,
    fidelity: FIDELITY_CASE_IDS.length,
    axe: AXE_CASES.length,
    total: DEMO_TITLES.length + HOOK_CASE_IDS.length + FIDELITY_CASE_IDS.length + AXE_CASES.length
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
    const caseRecord = {
      condition,
      run_id: runId,
      source_revision: REVISION,
      source_digest: source.source_digest,
      status: "passed",
      expected_counts: counts,
      executed_counts: counts,
      setup_ms: 100,
      execution_ms: 200,
      wall_ms: 300,
      demo_case_ids: DEMO_TITLES,
      hook_case_ids: HOOK_CASE_IDS,
      fidelity_case_ids: FIDELITY_CASE_IDS,
      axe_case_ids: AXE_CASES.map(item => item.case_id)
    };
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
      source_revision: REVISION,
      source_digest: source.source_digest,
      setup_ms,
      execution_ms,
      teardown_ms: 0,
      wall_ms,
      runner_count: 1,
      runner_minutes: null,
      runner_minutes_status: "awaiting-hosted-job",
      expected_counts,
      executed_counts
    })),
    pilot_wall_ms: 600,
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

test("checker accepts complete independent local cold/warm evidence", t => {
  const evidenceDir = createFixture();
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const result = runChecker(evidenceDir);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const summary = JSON.parse(result.stdout.trim());
  assert.equal(summary.valid, true);
  assert.equal(summary.conditions.cold.axe.successful, 18);
  assert.equal(summary.conditions.warm.axe.successful, 18);
});
