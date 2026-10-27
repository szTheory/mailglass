#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const { execFileSync } = require("node:child_process");
const { selectedCases, validateReport, compareFindings } = require("../mailglass_admin/e2e/support/storybook-axe.cjs");
const { collectTests } = require("../reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs");

const ROOT = path.resolve(__dirname, "..");
const PHASE_DIR = path.join(ROOT, "reference/demo_app/tmp/demo_browser_evidence/phase174");
const MANIFEST_PATH = path.join(ROOT, "reference/persona_spec/quick_view_scenarios.json");
const APPROVED_PATH = path.join(ROOT, "mailglass_admin/docs/storybook-axe-approved.json");
const SHA1 = /^[0-9a-f]{40}$/;
const SHA256 = /^[0-9a-f]{64}$/;
const MD5 = /^[0-9a-f]{32}$/;
const CI_JOB_NAME = "Demo Browser Evidence (Docker Compose / Chromium)";
const CI_JOB_ID = "demo_browser_evidence";
const REQUIRED_PHASE173_TESTS = [
  "dashboard links to preview and operator surfaces",
  "outbound operator opens with seeded delivery evidence",
  "inbound operator opens with seeded support mailbox evidence",
  "empty account stays isolated and explains the absence of deliveries",
  "recipient browser shows a truthful expired unsubscribe state"
];
const REQUIRED_PHASE174_TESTS = [
  "Storybook owns its iframe hook and both pinned Demo surfaces complete real cycles",
  "delivery story owns Light, Dark, and live System review themes",
  "inbound story owns Light, Dark, and live System review themes",
  "delivery loads production CSS, all font bytes, and computed roles",
  "inbound loads production CSS, all font bytes, and computed roles",
  "delivery normal and boundary quick views fit bounded responsive widths",
  "inbound normal and boundary quick views fit bounded responsive widths"
];
const HOOK_CASE_IDS = [
  "storybook:mounted-preview",
  "delivery:escape-focus-return",
  "delivery:close-focus-return",
  "delivery:reconnect-focus-return",
  "inbound:close-focus-return",
  "inbound:escape-focus-return"
];
const FONT_FILES = [
  "inter-400.woff2",
  "inter-700.woff2",
  "inter-tight-400.woff2",
  "inter-tight-700.woff2",
  "ibm-plex-mono-400.woff2",
  "ibm-plex-mono-700.woff2"
];
const WORKFLOW_STEPS = [
  "Checkout",
  "Audit demo browser lockfile",
  "Test pinned baseline provisioning",
  "Run demo browser evidence"
];
const SOURCE_REQUIRED = [
  ".github/workflows/ci.yml",
  "compose.demo.yml",
  "scripts/run_demo_browser_evidence.sh",
  "scripts/check_phase174_evidence.cjs",
  "scripts/check_phase174_evidence.test.cjs",
  "scripts/gsd-regression-gate.sh",
  "scripts/ci_green_policy.sh",
  "scripts/prepare_phase173_baselines.cjs",
  "reference/demo_app/Dockerfile",
  "reference/demo_app/mix.lock",
  "reference/demo_app/assets/package.json",
  "reference/demo_app/assets/package-lock.json",
  "reference/demo_app/assets/playwright.config.cjs",
  "reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs",
  "reference/demo_app/assets/scripts/check-demo-browser-deps.cjs",
  "reference/demo_app/assets/scripts/evidence-output-path.cjs",
  "reference/demo_app/dev/mailglass_demo_web/storybook.ex",
  "reference/demo_app/lib/mailglass_demo_web/router.ex",
  "reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex",
  "reference/demo_app/assets/scripts/check-persona-reset-target.cjs",
  "reference/demo_app/storybook/primitives/theme_picker.story.exs",
  "reference/demo_app/storybook/quick_views/delivery.story.exs",
  "reference/demo_app/storybook/quick_views/inbound.story.exs",
  "mailglass_admin/mix.lock",
  "mailglass_admin/package.json",
  "mailglass_admin/package-lock.json",
  "mailglass_admin/playwright.storybook.config.cjs",
  "mailglass_admin/playwright.config.cjs",
  "mailglass_admin/e2e/flows.spec.js",
  "mailglass_admin/e2e/storybook-axe.spec.js",
  "mailglass_admin/e2e/support/storybook-axe.cjs",
  "mailglass_admin/docs/storybook-axe-approved.json",
  "mailglass_admin/assets/css/app.css",
  "mailglass_admin/priv/static/app.css",
  "mailglass_admin/priv/static/hooks.js",
  "mailglass_admin/lib/mailglass_admin/operator/quick_view.ex",
  "mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex",
  "mailglass_admin/lib/mailglass_admin/inbound_live.ex",
  "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex",
  "mailglass_admin/lib/mailglass_admin/controllers/assets.ex",
  "reference/persona_spec/quick_view_scenarios.ex",
  "reference/persona_spec/quick_view_scenarios.json"
];

function fail(message) {
  throw new Error(message);
}

function requireThat(condition, message) {
  if (!condition) fail(message);
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function nonempty(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function loadJson(filename, label) {
  let stat;
  try {
    stat = fs.lstatSync(filename);
  } catch {
    fail(`${label} is missing: ${filename}`);
  }
  requireThat(stat.isFile() && !stat.isSymbolicLink(), `${label} must be a regular file: ${filename}`);
  try {
    return JSON.parse(fs.readFileSync(filename, "utf8"));
  } catch (error) {
    fail(`${label} is not valid JSON: ${error.message}`);
  }
}

function exactStringSet(actual, expected, label) {
  requireThat(Array.isArray(actual), `${label} must be an array`);
  requireThat(new Set(actual).size === actual.length, `${label} contains duplicate entries`);
  const left = [...actual].sort();
  const right = [...expected].sort();
  requireThat(JSON.stringify(left) === JSON.stringify(right), `${label} is missing, extra, or stale`);
}

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
        ids.push(`width:${area}:${boundary ? "northstar_first" : "northstar_normal"}:${width}:${theme}`);
      }
    }
  }
  return ids;
}

function selectedSourcePaths(root = ROOT) {
  const tracked = execFileSync("git", ["ls-files", "-z"], { cwd: root, encoding: "buffer" })
    .toString("utf8")
    .split("\0")
    .filter(Boolean);
  const trackedSet = new Set(tracked);
  const missing = SOURCE_REQUIRED.filter(item => !trackedSet.has(item));
  requireThat(missing.length === 0, `selected source input is not tracked: ${missing.join(", ")}`);
  const selected = new Set(SOURCE_REQUIRED);
  for (const item of tracked) {
    if (
      (item.startsWith("reference/demo_app/assets/e2e/") && item.endsWith(".spec.js")) ||
      (item.startsWith("reference/demo_app/storybook/quick_views/") && /\.(exs?|heex)$/.test(item)) ||
      (item.startsWith("mailglass_admin/priv/static/fonts/") && item.endsWith(".woff2")) ||
      (item.startsWith("mailglass_admin/e2e/storybook-axe") && /\.(js|cjs)$/.test(item)) ||
      (item.startsWith("mailglass_admin/e2e/support/storybook-axe") && /\.(js|cjs)$/.test(item))
    ) selected.add(item);
  }
  return [...selected].sort((left, right) => left.localeCompare(right));
}

function computeSourceIdentity(root = ROOT, sourceRevision) {
  const revision = sourceRevision || execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
  requireThat(SHA1.test(revision), "candidate source revision must be a full Git object ID");
  const files = selectedSourcePaths(root).map(relativePath => {
    const contents = fs.readFileSync(path.join(root, relativePath));
    return {
      path: relativePath,
      bytes: contents.byteLength,
      sha256: crypto.createHash("sha256").update(contents).digest("hex")
    };
  });
  const digestInput = files.map(item => `${item.path}\0${item.bytes}\0${item.sha256}\n`).join("");
  const sourceDigest = crypto.createHash("sha256").update(digestInput).digest("hex");
  return {
    hash_method: "sha256(sorted(path\\0byte_length\\0file_sha256\\n))",
    input_paths: files.map(item => item.path),
    files,
    source_revision: revision,
    source_digest: sourceDigest
  };
}

const EXPECTED_FIDELITY_CASE_IDS = fidelityCaseIds();

function validateSource(source, sourceRevision, sourceDigest) {
  requireThat(isRecord(source), "source input manifest is missing");
  requireThat(source.hash_method === "sha256(sorted(path\\0byte_length\\0file_sha256\\n))", "source hash method is missing or unsupported");
  requireThat(Array.isArray(source.files) && source.files.length > 0, "source input file list is empty");
  const filePaths = [];
  const seen = new Set();
  for (const item of source.files) {
    requireThat(isRecord(item), "source input entry is invalid");
    requireThat(nonempty(item.path) && !path.isAbsolute(item.path) && !item.path.split(/[\\/]/).includes(".."), "source input path is unsafe");
    requireThat(!seen.has(item.path), `source input path is duplicated: ${item.path}`);
    seen.add(item.path);
    requireThat(Number.isSafeInteger(item.bytes) && item.bytes >= 0, `source input byte count is invalid: ${item.path}`);
    requireThat(SHA256.test(item.sha256), `source input digest is invalid: ${item.path}`);
    filePaths.push(item.path);
  }
  exactStringSet(source.input_paths, filePaths, "source.input_paths");
  const ordered = [...source.files].sort((left, right) => left.path.localeCompare(right.path));
  const digestInput = ordered.map(item => `${item.path}\0${item.bytes}\0${item.sha256}\n`).join("");
  const digest = crypto.createHash("sha256").update(digestInput).digest("hex");
  requireThat(source.source_revision === sourceRevision, "source manifest revision does not match execution revision");
  requireThat(source.source_digest === sourceDigest && digest === sourceDigest, "source manifest digest does not match selected source inputs");
}

function collectFidelityCases(receipt, identity) {
  requireThat(isRecord(receipt), "fidelity receipt is missing");
  requireIdentity(receipt.run_identity, identity, "fidelity");
  requireThat(receipt.source?.revision === identity.source_revision, "fidelity source revision is stale");
  requireThat(typeof receipt.source?.dirty === "boolean" && SHA256.test(receipt.source?.dirtyStatusSha256), "fidelity source dirtiness receipt is incomplete");
  exactStringSet(receipt.selectedCaseIds, EXPECTED_FIDELITY_CASE_IDS, "fidelity selectedCaseIds");
  exactStringSet(receipt.executedCaseIds, EXPECTED_FIDELITY_CASE_IDS, "fidelity executedCaseIds");

  const themes = Array.isArray(receipt.themes) ? receipt.themes : [];
  requireThat(themes.length === 2, "fidelity theme receipts must cover Delivery and Inbound");
  for (const area of ["delivery", "inbound"]) {
    const theme = themes.find(item => item.caseId === `theme:${area}:northstar_normal`);
    requireThat(theme?.owner === "quick-view-story", `fidelity ${area} theme owner is missing`);
    requireThat(theme.systemLight?.resolvedScheme === "light" && theme.systemDark?.resolvedScheme === "dark", `fidelity ${area} live System theme cases are incomplete`);
    requireThat(theme.systemLight?.dataTheme === "mailglass-light" && theme.systemDark?.dataTheme === "mailglass-dark", `fidelity ${area} production theme tokens are wrong`);
    requireThat(theme.explicitThemeStability === true && theme.selectionPreserved === true && theme.hostPreferencePersisted === false, `fidelity ${area} story-local theme boundary is invalid`);
  }

  requireThat(Array.isArray(receipt.stylesheets) && receipt.stylesheets.length === 2, "fidelity production CSS receipts must cover both stories");
  for (const area of ["delivery", "inbound"]) {
    const stylesheet = receipt.stylesheets.find(item => item.caseId === `fonts:${area}:northstar_normal`);
    requireThat(SHA256.test(stylesheet?.source?.sha256) && SHA256.test(stylesheet?.built?.sha256) && SHA256.test(stylesheet?.served?.sha256), `fidelity ${area} CSS source/build/served digest is incomplete`);
    requireThat(stylesheet.built.sha256 === stylesheet.served.sha256 && stylesheet.served.matchesBuilt === true, `fidelity ${area} production CSS does not match the built asset`);
  }

  requireThat(Array.isArray(receipt.fonts) && receipt.fonts.length === 2, "fidelity font receipts must cover both stories");
  for (const area of ["delivery", "inbound"]) {
    const fontReceipt = receipt.fonts.find(item => item.caseId === `fonts:${area}:northstar_normal`);
    requireThat(Array.isArray(fontReceipt?.assets) && fontReceipt.assets.length === FONT_FILES.length, `fidelity ${area} font bytes are incomplete`);
    exactStringSet(fontReceipt.assets.map(item => item.path), FONT_FILES, `fidelity ${area} font paths`);
    requireThat(fontReceipt.assets.every(item => item.status === 200 && Number.isInteger(item.bytes) && item.bytes > 0 && item.loadedFace === "loaded"), `fidelity ${area} font response or face loading failed`);
  }

  requireThat(Array.isArray(receipt.widths) && receipt.widths.length === 2, "fidelity width receipts must cover both stories");
  for (const area of ["delivery", "inbound"]) {
    const widthReceipt = receipt.widths.find(item => item.caseId === `widths:${area}:responsive-matrix`);
    requireThat(Array.isArray(widthReceipt?.cases) && widthReceipt.cases.length === 10, `fidelity ${area} responsive cases are incomplete`);
    const expectedArea = EXPECTED_FIDELITY_CASE_IDS.filter(id => id.startsWith(`width:${area}:`));
    exactStringSet(widthReceipt.cases.map(item => item.caseId), expectedArea, `fidelity ${area} responsive case IDs`);
    requireThat(widthReceipt.cases.every(item => item.closeWithinPane === true && item.technicalWrapping?.scrollWidth <= item.technicalWrapping?.width && item.technicalWrapping?.overflowWrap === "anywhere"), `fidelity ${area} width containment or technical wrapping failed`);
    requireThat(widthReceipt.cases.every(item => [320, 375, 768, 1280, 1440].includes(item.viewportWidth) && ["light", "dark"].includes(item.theme)), `fidelity ${area} viewport/theme coverage is invalid`);
  }
  requireThat(Array.isArray(receipt.evidenceLimits) && receipt.evidenceLimits.some(item => /Phase 178/i.test(item)), "fidelity evidence limits must retain the real-zoom Phase 178 boundary");
  return EXPECTED_FIDELITY_CASE_IDS;
}

function requireIdentity(identity, expected, label) {
  requireThat(isRecord(identity), `${label} receipt run identity is missing`);
  requireThat(identity.run_id === expected.run_id && identity.condition === expected.condition, `${label} receipt run identity is stale`);
  requireThat(identity.source_revision === expected.source_revision && identity.source_digest === expected.source_digest, `${label} receipt source identity is stale`);
}

function collectHookCases(receipt, identity) {
  requireThat(isRecord(receipt) && receipt.schema_version === "phase174-storybook-hooks.v1", "hook receipt is missing or has an unsupported schema");
  requireIdentity(receipt.run_identity, identity, "hook");
  requireThat(receipt.proof_boundary?.reset === "authenticated reset endpoint used", "hook receipt did not use this run's authenticated Demo reset");
  requireThat(receipt.source?.path === "mailglass_admin/priv/static/hooks.js" && MD5.test(receipt.source?.md5), "hook source asset identity is missing");
  requireThat(receipt.locked_versions?.demo_live_view === "1.1.33" && receipt.locked_versions?.admin_live_view === "1.2.13" && receipt.locked_versions?.phoenix_storybook === "1.2.0", "hook receipt has stale locked LiveView or Storybook versions");
  requireThat(receipt.locked_versions?.demo_playwright === "1.60.0" && receipt.locked_versions?.admin_playwright === "1.59.1", "hook receipt does not identify both independently locked Playwright clients");
  const responses = receipt.storybook?.hook_asset_responses;
  requireThat(Array.isArray(responses) && responses.length > 0, "Storybook hook asset responses are missing");
  requireThat(responses.every(item => item.status === 200 && item.hasStorybookRegistration === true && item.hasSocketConstructor === false), "Storybook hook registration response failed");
  const preview = receipt.storybook?.preview;
  requireThat(preview?.mounted === true && preview.remounted_listener_count >= 1, "Storybook preview mount/remount hook evidence is incomplete");
  requireThat(preview.removed?.iframe_detached === true && Array.isArray(preview.removed?.browsing_context_receipts) && preview.removed.browsing_context_receipts.length > 0, "Storybook preview removal evidence is incomplete");
  requireThat(Array.isArray(receipt.browser_websockets) && receipt.browser_websockets.some(item => item.path === "/live/websocket" && item.sentFrames > 0 && item.receivedFrames > 0), "connected Storybook LiveView websocket evidence is missing");
  requireThat(Array.isArray(receipt.demo_route_cases) && receipt.demo_route_cases.length === 5, "real Delivery and Inbound route cycles are incomplete");
  requireThat(receipt.demo_route_cases.filter(item => item.surface === "delivery").length === 3 && receipt.demo_route_cases.filter(item => item.surface === "inbound").length === 2, "real route cycle counts do not match selected cases");
  requireThat(receipt.demo_route_cases.every(item => nonempty(item.opened) && nonempty(item.navigatedTo) && item.opened !== item.navigatedTo && nonempty(item.focusReturnedTo) && item.focusinAdded > 0 && item.focusinAdded === item.focusinRemoved && item.reducedMotion === true), "real route focus, navigation, or reduced-motion receipt failed");
  const storybookDocuments = receipt.storybook?.documents;
  requireThat(Array.isArray(storybookDocuments) && storybookDocuments.length >= 2 && storybookDocuments.every(item => typeof item.url === "string" && item.url.startsWith("/dev/storybook") && item.admin_bootstrap_present === false), "Admin client isolation from Demo Storybook documents failed");
  requireThat(Array.isArray(receipt.final_documents) && receipt.final_documents.length > 0 && receipt.final_documents.every(item => typeof item.url === "string" && item.url.startsWith("/ops/") && item.admin_bootstrap_present === true), "production operator route Admin bootstrap evidence is incomplete");
  return HOOK_CASE_IDS;
}

function validateDemoReport(report) {
  requireThat(isRecord(report) && Array.isArray(report.suites), "Demo Playwright JSON report is missing suites");
  const tests = collectTests(report.suites);
  requireThat(tests.length > 0, "Demo browser execution discovered zero tests");
  requireThat(tests.every(item => item.outcome === "expected" || item.outcome === "passed"), "Demo browser execution contains failed, skipped, flaky, or unfinished cases");
  const titles = tests.map(item => item.title);
  const caseIds = tests.map(item => item.case_id);
  requireThat(caseIds.every(nonempty), "Demo Playwright case identity is missing source file or line metadata");
  exactStringSet(caseIds, [...new Set(caseIds)], "Demo Playwright test case identities");
  for (const title of [...REQUIRED_PHASE173_TESTS, ...REQUIRED_PHASE174_TESTS]) {
    requireThat(titles.includes(title), `required Demo browser case did not execute: ${title}`);
  }
  return { tests, titles, caseIds };
}

function validateBrowserInstall(receipt, type, condition, identity) {
  requireThat(isRecord(receipt), `${type} browser install receipt is missing`);
  requireThat(receipt.schema_version === `phase174-${type}-browser.v1`, `${type} browser receipt has an unsupported schema`);
  requireIdentity(receipt.run_identity, identity, `${type} browser`);
  requireThat(receipt.version === (type === "admin" ? "1.59.1" : "1.60.0"), `${type} browser CLI version does not match its locked client`);
  requireThat(/^\d+$/.test(String(receipt.chromium_revision)), `${type} required Chromium revision is missing`);
  requireThat(receipt.cache_directory === "/cache/playwright", `${type} browser cache directory is not the run-owned shared cache`);
  requireThat(["hit", "miss"].includes(receipt.cache_state), `${type} browser cache hit/miss state is missing`);
  requireThat(Number.isFinite(receipt.installer_ms) && receipt.installer_ms > 0, `${type} Chromium installer elapsed time is missing`);
  if (type === "admin") {
    requireThat(receipt.cli === "/workspace/mailglass_admin/node_modules/.bin/playwright", "Admin browser install did not use Admin's locked Playwright CLI");
    requireThat(receipt.install_exit_code === 0, "Admin-owned Chromium installer failed");
  }
  if (condition === "cold") requireThat(receipt.cache_state === "miss", `${type} cold condition did not use an empty run-owned browser cache`);
  if (condition === "warm") requireThat(receipt.cache_state === "hit", `${type} warm condition did not reuse this run's browser cache`);
  return receipt;
}

function validateAxeReport(report, identity, manifest, approved) {
  const reportRunId = `${identity.run_id}`;
  requireThat(isRecord(report) && report.run_id === reportRunId, "Axe report run identity is stale");
  requireThat(report.source_revision === identity.source_revision && report.source_digest === identity.source_digest, "Axe report source identity is stale");
  const validation = validateReport(report, {
    manifest,
    runId: reportRunId,
    revision: identity.source_revision,
    sourceDigest: identity.source_digest,
    approval: approved
  });
  const comparison = compareFindings(report, approved);
  const errors = [...validation.errors, ...comparison.errors];
  requireThat(validation.valid && comparison.valid, `Axe comparison rejected: ${errors.join("; ")}`);
  requireThat(validation.metrics.expected === 18 && validation.metrics.executed === 18 && validation.metrics.successful === 18 && validation.metrics.failed === 0 && validation.metrics.missing === 0, "Axe selected-case count is empty, partial, or failed");
  return {
    expected: validation.metrics.expected,
    executed: validation.metrics.executed,
    successful: validation.metrics.successful,
    violations: comparison.metrics.violations,
    unapproved: comparison.metrics.unapproved,
    incomplete: comparison.metrics.incomplete,
    untriaged: comparison.metrics.untriaged,
    valid: true
  };
}

function validateCondition(condition, execution, manifest, approved, phaseDir) {
  requireThat(isRecord(condition), "execution condition entry is invalid");
  const name = condition.condition;
  requireThat(["cold", "warm", "single"].includes(name), `unsupported execution condition: ${name}`);
  const identity = {
    run_id: condition.run_id,
    condition: name,
    source_revision: execution.source_revision,
    source_digest: execution.source_digest
  };
  requireThat(condition.run_id === `${execution.run_id}-${name}`, `${name} condition run ID is stale`);
  requireThat(condition.source_revision === execution.source_revision && condition.source_digest === execution.source_digest, `${name} condition source identity is stale`);
  requireThat(condition.status === "passed", `${name} execution status is not passed`);
  requireThat(Number.isFinite(Date.parse(condition.started_at)) && Number.isFinite(Date.parse(condition.completed_at)) && Date.parse(condition.completed_at) > Date.parse(condition.started_at), `${name} execution timing bounds are missing or invalid`);
  requireThat(isRecord(condition.timings_ms), `${name} setup/scan/comparison timing boundaries are missing`);
  const timingFields = ["service_start", "demo_lock_audit", "demo_npm_ci", "demo_browser_install", "demo_scan", "admin_npm_ci", "admin_browser_install", "admin_axe_scan", "comparison"];
  for (const field of timingFields) requireThat(Number.isFinite(condition.timings_ms[field]) && condition.timings_ms[field] >= 0, `${name} timing boundary is missing or invalid: ${field}`);
  requireThat(condition.timings_ms.admin_browser_install > 0 && condition.timings_ms.admin_axe_scan > 0 && condition.timings_ms.comparison > 0, `${name} Admin browser setup, scan, or comparison was not measured`);

  const conditionDir = path.join(phaseDir, name);
  const demoReport = loadJson(path.join(conditionDir, "demo-playwright-report.json"), `${name} Demo Playwright report`);
  const demo = validateDemoReport(demoReport);
  const hookReceipt = loadJson(path.join(conditionDir, "hooks.json"), `${name} hook receipt`);
  const hooks = collectHookCases(hookReceipt, identity);
  const fidelityReceipt = loadJson(path.join(conditionDir, "fidelity.json"), `${name} fidelity receipt`);
  const fidelity = collectFidelityCases(fidelityReceipt, identity);
  const axeReport = loadJson(path.join(conditionDir, "axe.json"), `${name} Axe receipt`);
  const axe = validateAxeReport(axeReport, { ...identity, run_id: `${execution.run_id}-${name}` }, manifest, approved);
  const adminBrowser = validateBrowserInstall(loadJson(path.join(conditionDir, "admin-browser.json"), `${name} Admin browser install receipt`), "admin", name, identity);
  const demoBrowser = validateBrowserInstall(loadJson(path.join(conditionDir, "demo-browser.json"), `${name} Demo browser install receipt`), "demo", name, identity);
  requireThat(hookReceipt.locked_versions.admin_playwright === adminBrowser.version && hookReceipt.locked_versions.demo_playwright === demoBrowser.version, `${name} browser CLI versions do not match hook receipt versions`);
  requireThat(adminBrowser.installer_ms === condition.timings_ms.admin_browser_install && demoBrowser.installer_ms === condition.timings_ms.demo_browser_install, `${name} browser install timings do not match install receipts`);
  requireThat(isRecord(condition.admin_browser) && JSON.stringify(condition.admin_browser) === JSON.stringify(adminBrowser), `${name} execution receipt is missing Admin CLI/cache details`);
  requireThat(isRecord(condition.demo_browser) && JSON.stringify(condition.demo_browser) === JSON.stringify(demoBrowser), `${name} execution receipt is missing Demo CLI/cache details`);

  const expectedCounts = {
    demo: demo.tests.length,
    hooks: hooks.length,
    fidelity: fidelity.length,
    axe: axe.expected,
    total: demo.tests.length + hooks.length + fidelity.length + axe.expected
  };
  const executedCounts = {
    demo: demo.tests.length,
    hooks: hooks.length,
    fidelity: fidelity.length,
    axe: axe.executed,
    total: demo.tests.length + hooks.length + fidelity.length + axe.executed
  };
  requireThat(JSON.stringify(condition.expected_counts) === JSON.stringify(expectedCounts), `${name} expected case counts do not match receipts`);
  requireThat(JSON.stringify(condition.executed_counts) === JSON.stringify(executedCounts), `${name} executed case counts do not match receipts`);
  exactStringSet(condition.demo_case_ids, demo.caseIds, `${name} Demo case IDs`);
  exactStringSet(condition.hook_case_ids, hooks, `${name} hook case IDs`);
  exactStringSet(condition.fidelity_case_ids, fidelity, `${name} fidelity case IDs`);
  exactStringSet(condition.axe_case_ids, axeReport.expected.map(item => item.case_id), `${name} Axe case IDs`);
  for (const [field, label] of [["setup_ms", "setup"], ["execution_ms", "execution"], ["wall_ms", "wall"]]) {
    requireThat(Number.isFinite(condition[field]) && condition[field] > 0, `${name} ${label} duration is missing or invalid`);
  }
  requireThat(condition.wall_ms >= condition.setup_ms + condition.execution_ms, `${name} wall duration omits setup or execution`);
  requireThat(nonempty(condition.job_id), `${name} job identity is missing`);
  return { expected: expectedCounts, executed: executedCounts, axe };
}

function validateCost(cost, execution, results, pilot, requireCi) {
  requireThat(isRecord(cost) && cost.schema_version === "phase174-cost.v1", "cost receipt is missing or has an unsupported schema");
  requireThat(cost.run_id === execution.run_id && cost.source_revision === execution.source_revision && cost.source_digest === execution.source_digest, "cost receipt source/run identity is stale");
  requireThat(cost.pilot === pilot, "cost receipt pilot flag does not match requested evidence mode");
  const expectedConditions = pilot ? ["cold", "warm"] : ["single"];
  requireThat(Array.isArray(cost.conditions) && cost.conditions.length === expectedConditions.length, "cost receipt is missing cold/warm condition entries");
  for (const conditionName of expectedConditions) {
    const receipt = cost.conditions.find(item => item.condition === conditionName);
    const result = results[conditionName];
    requireThat(isRecord(receipt) && result, `cost entry is missing for ${conditionName}`);
    requireThat(receipt.run_id === `${execution.run_id}-${conditionName}` && receipt.source_revision === execution.source_revision && receipt.source_digest === execution.source_digest, `${conditionName} cost source/run identity is stale`);
    requireThat(nonempty(receipt.job_id), `${conditionName} cost job ID is missing`);
    for (const [field, label] of [["setup_ms", "setup"], ["execution_ms", "execution"], ["teardown_ms", "teardown"], ["wall_ms", "wall"]]) {
      requireThat(Number.isFinite(receipt[field]) && receipt[field] >= 0, `${conditionName} cost ${label} duration is missing or invalid`);
    }
    requireThat(receipt.wall_ms >= receipt.setup_ms + receipt.execution_ms, `${conditionName} cost wall duration omits setup or execution`);
    requireThat(isRecord(receipt.timings_ms), `${conditionName} cost timing boundaries are missing`);
    for (const field of ["service_start", "demo_lock_audit", "demo_npm_ci", "demo_browser_install", "demo_scan", "admin_npm_ci", "admin_browser_install", "admin_axe_scan", "comparison"]) requireThat(Number.isFinite(receipt.timings_ms[field]) && receipt.timings_ms[field] >= 0, `${conditionName} cost timing boundary is missing: ${field}`);
    requireThat(Number.isFinite(receipt.teardown_ms), `${conditionName} teardown timing was not measured`);
    requireThat(JSON.stringify(receipt.expected_counts) === JSON.stringify(result.expected) && JSON.stringify(receipt.executed_counts) === JSON.stringify(result.executed), `${conditionName} cost case counts do not match executed receipts`);
    const executionCondition = execution.conditions.find(item => item.condition === conditionName);
    requireThat(JSON.stringify(receipt.admin_browser) === JSON.stringify(executionCondition.admin_browser) && JSON.stringify(receipt.demo_browser) === JSON.stringify(executionCondition.demo_browser), `${conditionName} cost browser install details do not match execution receipts`);
    requireThat(receipt.runner_count === 1, `${conditionName} runner count must identify the single actual executor`);
    // The producer runs before GitHub can expose completed job metadata.
    // Validate its condition timings here; only --require-ci establishes hosted proof.
    if (requireCi || execution.github?.actions === true) {
      requireThat(Number.isFinite(receipt.runner_minutes) && receipt.runner_minutes > 0 && receipt.runner_minutes_status === "wrapper-condition-elapsed", `${conditionName} hosted runner time is missing`);
      requireThat(Math.abs(receipt.runner_minutes - receipt.wall_ms / 60000) < 0.001, `${conditionName} hosted runner minutes do not match measured condition wall time`);
    } else {
      requireThat(receipt.runner_minutes === null && receipt.runner_minutes_status === "awaiting-hosted-job", `${conditionName} local elapsed time is mislabeled as hosted runner cost`);
    }
  }
  requireThat(Number.isFinite(cost.pilot_wall_ms) && cost.pilot_wall_ms > 0, "pilot total wall duration is missing");
  const finalCondition = cost.conditions[cost.conditions.length - 1];
  requireThat(finalCondition.teardown_ms > 0, "run-owned Compose teardown was not measured");
  requireThat(Number.isFinite(Date.parse(cost.teardown_completed_at)), "run-owned teardown completion timestamp is missing");
  const accountedWallMs = cost.conditions.reduce((sum, item) => sum + item.wall_ms, 0) + finalCondition.teardown_ms;
  requireThat(cost.pilot_wall_ms >= accountedWallMs, "pilot total wall duration omits condition work or run-owned teardown");
  requireThat(isRecord(cost.added_cost) && ["measured", "unmeasured"].includes(cost.added_cost.status) && nonempty(cost.added_cost.reason), "added PR cost needs a measured or explicit unmeasured disposition");
  requireThat(isRecord(cost.budget) && cost.budget.added_wall_minutes === 5 && cost.budget.added_runner_minutes === 10 && nonempty(cost.budget.disposition), "provisional wall/runner budget disposition is missing");
  if (requireCi) validateHostedCost(cost, execution);
}

function parseTimestamp(value, label) {
  const ms = Date.parse(value);
  requireThat(Number.isFinite(ms), `${label} is not a valid timestamp`);
  return ms;
}

function validateHostedCost(cost, execution) {
  const hosted = cost.hosted_job;
  requireThat(isRecord(hosted), "cost receipt has no independently collected hosted job timing");
  requireThat(hosted.run_id === execution.github.run_id && hosted.run_attempt === execution.github.run_attempt, "cost hosted run identity is stale");
  requireThat(hosted.head_sha === execution.source_revision && hosted.repository === execution.github.repository, "cost hosted head/repository identity is stale");
  requireThat(hosted.job_id === CI_JOB_ID && hosted.job_name === CI_JOB_NAME, "cost hosted job identity is stale");
  requireThat(hosted.runner_name === execution.github.runner_name && hosted.runner_os === execution.github.runner_os && hosted.runner_arch === execution.github.runner_arch, "cost hosted runner identity is stale");
  const elapsedMs = parseTimestamp(hosted.completed_at, "hosted job completed_at") - parseTimestamp(hosted.started_at, "hosted job started_at");
  requireThat(elapsedMs > 0 && hosted.duration_ms === elapsedMs, "cost hosted duration does not match job timestamps");
  requireThat(hosted.runner_count === 1 && Number.isFinite(hosted.runner_minutes) && Math.abs(hosted.runner_minutes - elapsedMs / 60000) < 0.00001, "cost hosted runner minutes do not match full job duration");
}

function validateCiJob(evidenceRoot, execution, cost) {
  const ciJob = loadJson(path.join(evidenceRoot, "ci-job.json"), "independently fetched ci-job.json");
  requireThat(ciJob.schema_version === "phase174-ci-job.v1", "ci-job.json has an unsupported schema");
  const github = execution.github;
  requireThat(github.actions === true, "--require-ci rejects a local/caller-supplied GITHUB_ACTIONS label");
  for (const field of ["run_id", "run_attempt", "repository", "sha", "job", "runner_name", "runner_os", "runner_arch"]) {
    requireThat(nonempty(github[field]), `CI execution receipt is missing actual ${field}`);
  }
  requireThat(github.job === CI_JOB_ID, "CI execution GITHUB_JOB is not the advisory Demo evidence job");
  requireThat(ciJob.status === "completed" && ciJob.conclusion === "success", "actual CI run did not complete successfully");
  requireThat(ciJob.run_id === github.run_id && ciJob.run_attempt === github.run_attempt, "actual CI run ID/attempt does not match receipt");
  requireThat(ciJob.repository === github.repository && ciJob.head_sha === execution.source_revision && github.sha === execution.source_revision, "actual CI repository/head SHA does not match candidate source");
  requireThat(nonempty(ciJob.url), "actual CI run URL is missing");
  requireThat(isRecord(ciJob.job), "actual Demo CI job metadata is missing");
  const job = ciJob.job;
  requireThat(job.id !== undefined && String(job.id).length > 0 && job.name === CI_JOB_NAME, "actual Demo CI job identity is missing or wrong");
  requireThat(job.status === "completed" && job.conclusion === "success", "actual Demo CI job did not complete successfully");
  requireThat(job.runner_name === github.runner_name, "actual GitHub runner name does not match execution receipt");
  requireThat(job.runner_os === github.runner_os && job.runner_arch === github.runner_arch, "actual GitHub runner OS/architecture does not match execution receipt");
  requireThat(Array.isArray(job.steps), "actual CI job step metadata is missing");
  for (const stepName of WORKFLOW_STEPS) {
    const step = job.steps.find(item => item.name === stepName);
    requireThat(step?.status === "completed" && step.conclusion === "success", `actual CI step did not complete successfully: ${stepName}`);
  }
  const jobStarted = parseTimestamp(job.started_at, "CI job started_at");
  const jobCompleted = parseTimestamp(job.completed_at, "CI job completed_at");
  requireThat(jobCompleted > jobStarted, "actual CI job has a nonpositive duration");
  const durationMs = jobCompleted - jobStarted;
  requireThat(ciJob.duration_ms === durationMs, "ci-job.json derived duration does not match actual job timestamps");
  requireThat(ciJob.run_started_at && ciJob.run_completed_at && Date.parse(ciJob.run_completed_at) >= Date.parse(ciJob.run_started_at), "actual workflow run timestamps are incomplete");
  const hosted = cost.hosted_job;
  requireThat(isRecord(hosted), "cost receipt is missing hosted job identity and timing");
  requireThat(hosted.job_id === github.job && String(hosted.job_database_id) === String(job.id), "cost job ID does not match GITHUB_JOB and actual GitHub job ID");
  requireThat(hosted.job_name === job.name && hosted.runner_name === job.runner_name, "cost job/runner identity does not match GitHub job metadata");
  requireThat(hosted.duration_ms === durationMs && hosted.started_at === job.started_at && hosted.completed_at === job.completed_at, "cost full-runner duration does not match actual GitHub job timestamps");
  return {
    run_id: ciJob.run_id,
    run_attempt: ciJob.run_attempt,
    repository: ciJob.repository,
    head_sha: ciJob.head_sha,
    job_id: job.id,
    runner_name: job.runner_name,
    duration_ms: durationMs,
    runner_minutes: durationMs / 60000,
    url: ciJob.url
  };
}

function checkEvidence(evidenceRoot, { pilot = false, requireCi = false } = {}) {
  const phaseDir = path.join(evidenceRoot, "phase174");
  const execution = loadJson(path.join(phaseDir, "execution.json"), "Phase174 execution receipt");
  requireThat(execution.schema_version === "phase174-execution.v1" && execution.phase === 174, "execution receipt has an unsupported schema/phase");
  requireThat(nonempty(execution.run_id) && SHA1.test(execution.source_revision) && SHA256.test(execution.source_digest), "execution source/run identity is missing or malformed");
  validateSource(execution.source, execution.source_revision, execution.source_digest);
  requireThat(execution.pilot === pilot, "execution pilot flag does not match requested evidence mode");
  const names = pilot ? ["cold", "warm"] : ["single"];
  requireThat(Array.isArray(execution.conditions) && execution.conditions.length === names.length, "execution receipt does not contain the required condition set");
  exactStringSet(execution.conditions.map(item => item.condition), names, "execution condition names");
  const manifest = loadJson(MANIFEST_PATH, "current selected scenario manifest");
  const approved = loadJson(APPROVED_PATH, "independent Axe approval/triage record");
  const results = {};
  for (const condition of execution.conditions) {
    results[condition.condition] = validateCondition(condition, execution, manifest, approved, phaseDir);
  }
  if (pilot) {
    for (const type of ["admin_browser", "demo_browser"]) {
      requireThat(execution.conditions.find(item => item.condition === "cold")?.[type]?.cache_state === "miss", `${type} cold cache is not a miss`);
      requireThat(execution.conditions.find(item => item.condition === "warm")?.[type]?.cache_state === "hit", `${type} warm cache is not a hit`);
    }
  }
  const cost = loadJson(path.join(phaseDir, "cost.json"), "Phase174 cost receipt");
  validateCost(cost, execution, results, pilot, requireCi);
  let hosted = null;
  if (requireCi) hosted = validateCiJob(evidenceRoot, execution, cost);
  return {
    valid: true,
    run_id: execution.run_id,
    source_revision: execution.source_revision,
    source_digest: execution.source_digest,
    conditions: Object.fromEntries(Object.entries(results).map(([name, result]) => [name, {
      expected: result.expected,
      executed: result.executed,
      axe: result.axe
    }])),
    hosted_job: hosted
  };
}

function parseArgs(argv) {
  const result = { pilot: false, requireCi: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === "--pilot") {
      if (result.pilot) fail("duplicate option --pilot");
      result.pilot = true;
    } else if (flag === "--require-ci") {
      if (result.requireCi) fail("duplicate option --require-ci");
      result.requireCi = true;
    } else if (flag === "--evidence-dir") {
      if (result.evidenceDir || !argv[index + 1] || argv[index + 1].startsWith("--")) fail("--evidence-dir needs one path and may appear once");
      result.evidenceDir = path.resolve(argv[++index]);
    } else {
      fail(`unknown option ${flag}`);
    }
  }
  requireThat(result.evidenceDir, "required option --evidence-dir is missing");
  return result;
}

function cli(argv = process.argv.slice(2)) {
  try {
    const args = parseArgs(argv);
    const summary = checkEvidence(args.evidenceDir, { pilot: args.pilot, requireCi: args.requireCi });
    process.stdout.write(`${JSON.stringify(summary)}\n`);
  } catch (error) {
    process.stderr.write(`ERROR: ${error.message}\n`);
    process.exitCode = 1;
  }
}

if (require.main === module) cli();

module.exports = {
  checkEvidence,
  parseArgs,
  fidelityCaseIds,
  selectedSourcePaths,
  computeSourceIdentity,
  validateSource,
  validateCiJob,
  validateHostedCost,
  validateBrowserInstall
};
