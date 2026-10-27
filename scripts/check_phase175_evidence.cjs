#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const phase174 = require("./check_phase174_evidence.cjs");
const { selectedCases, compareFindings } = require("../mailglass_admin/e2e/support/storybook-axe.cjs");

const ROOT = path.resolve(__dirname, "..");
const PHASE_DIR_NAME = "phase175";
const HASH_METHOD = "sha256(sorted(path\\0byte_length\\0file_sha256\\n))";
const SHA1 = /^[0-9a-f]{40}$/;
const SHA256 = /^[0-9a-f]{64}$/;
const MD5 = /^[0-9a-f]{32}$/;
const PHASE175_EXTRA_SOURCE = [
  "scripts/check_phase175_evidence.cjs",
  "scripts/check_phase175_evidence.test.cjs",
  "mailglass_admin/e2e/phase175-inbound.spec.js",
  "mailglass_admin/test/support/admin_bootstrap.ex",
  "mailglass_admin/test/support/operator_browser_server.ex",
  "mailglass_admin/test/support/operator_fixtures.ex"
];
const FIDELITY_SOURCE_FILES = [
  "reference/persona_spec/quick_view_scenarios.ex",
  "reference/persona_spec/quick_view_scenarios.json",
  "reference/demo_app/storybook/delivery_investigation.story.exs",
  "reference/demo_app/assets/e2e/delivery-investigation.spec.js",
  "reference/demo_app/assets/e2e/storybook-fidelity.spec.js",
  "mailglass_admin/e2e/storybook-axe.spec.js",
  "mailglass_admin/e2e/support/storybook-axe.cjs",
  "mailglass_admin/e2e/support/storybook-axe-supplement.cjs",
  "mailglass_admin/e2e/flows.spec.js",
  "mailglass_admin/e2e/phase175-inbound.spec.js",
  "mailglass_admin/assets/css/app.css",
  "mailglass_admin/priv/static/app.css",
  "mailglass_admin/priv/static/hooks.js",
  "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex",
  "mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex",
  "mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex",
  "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex",
  ...[
    "inter-400.woff2", "inter-700.woff2", "inter-tight-400.woff2",
    "inter-tight-700.woff2", "ibm-plex-mono-400.woff2", "ibm-plex-mono-700.woff2"
  ].map(file => `mailglass_admin/priv/static/fonts/${file}`)
];
const FIDELITY_CASE_IDS = [
  "story:delivery-investigation-fjordline-long-unicode",
  "theme:delivery-investigation:system-light-dark-and-explicit-stability",
  ...[320, 375, 768, 1280, 1440].map((width, index) =>
    `fidelity:delivery-investigation:${width}:${index % 2 === 0 ? "dark" : "light"}`),
  "assets:storybook-css-and-six-font-faces",
  "fidelity:delivery-investigation:real-200-percent-zoom",
  "hook:storybook-host-connected-and-production-quick-view-focus-return"
];
const DEMO_CASES = [
  ["delivery-investigation.spec.js", "Phase 175 retained Delivery scenario inventory and production composition"],
  ["delivery-investigation.spec.js", "Phase 175 connected Delivery empty states use exact headings, guidance, and actions"],
  ["storybook-fidelity.spec.js", "Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom"],
  ["outbound-replay.spec.js", "outbound replay from the demo completes and records a durable no-change outcome"]
];
const ADMIN_CASES = [
  ["flows.spec.js", "Phase 175 Delivery tracer"],
  ["flows.spec.js", "Phase 175 Delivery recovery"],
  ["flows.spec.js", "Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible"],
  ["flows.spec.js", "Phase 175 Delivery layout U1/U2/U3/U5/U6: technical wrapping, reachable replay review and real zoom"],
  ["flows.spec.js", "Phase 175 suppression refresh"],
  ["flows.spec.js", "Phase 175 suppression policy"],
  ["phase175-inbound.spec.js", "Phase 175 Inbound full: confirm reports recorded Mailbox outcome and refreshes evidence"],
  ["phase175-inbound.spec.js", "Phase 175 Inbound full: Escape closes review and returns focus to its detail trigger"],
  ["phase175-inbound.spec.js", "Phase 175 Inbound quick: review preserves Account, filters, selection and keyboard context"],
  ["phase175-inbound.spec.js", "Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom"]
];
const WIDTHS = [320, 375, 768, 1280, 1440];

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

function exactStringSet(actual, expected, label) {
  requireThat(Array.isArray(actual), `${label} must be an array`);
  requireThat(actual.every(nonempty), `${label} contains an empty identity`);
  requireThat(new Set(actual).size === actual.length, `${label} contains duplicate entries`);
  requireThat(JSON.stringify([...actual].sort()) === JSON.stringify([...expected].sort()), `${label} is missing, extra, or stale`);
}

function validateCaseReceipts(expectedIds, executions, label = "case") {
  requireThat(Array.isArray(expectedIds) && expectedIds.length > 0, `${label} expected case set is empty`);
  requireThat(expectedIds.every(nonempty), `${label} expected case identity is invalid`);
  requireThat(new Set(expectedIds).size === expectedIds.length, `${label} expected case set contains duplicates`);
  requireThat(Array.isArray(executions) && executions.length > 0, `${label} executed case set is empty`);
  const seen = new Set();
  for (const execution of executions) {
    requireThat(isRecord(execution) && nonempty(execution.id), `${label} execution identity is missing`);
    requireThat(!seen.has(execution.id), `${label} duplicate executed case ${execution.id}`);
    seen.add(execution.id);
    requireThat(expectedIds.includes(execution.id), `${label} unexpected executed case ${execution.id}`);
    requireThat(execution.status === "passed", `${label} execution ${execution.id} is ${String(execution.status)}`);
  }
  for (const id of expectedIds) requireThat(seen.has(id), `${label} missing executed case ${id}`);
  return [...seen].sort();
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
    fail(`${label} is malformed JSON: ${error.message}`);
  }
}

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function md5(bytes) {
  return crypto.createHash("md5").update(bytes).digest("hex");
}

function selectedSourcePaths(root = ROOT) {
  return [...new Set([
    ...phase174.selectedSourcePaths(root),
    ...PHASE175_EXTRA_SOURCE
  ])].sort((left, right) => left.localeCompare(right));
}

function sourceIdentity(root = ROOT, sourceRevision) {
  const revision = sourceRevision || execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
  requireThat(SHA1.test(revision), "candidate source revision must be a full Git object ID");
  const files = selectedSourcePaths(root).map(relativePath => {
    const bytes = fs.readFileSync(path.join(root, relativePath));
    return { path: relativePath, bytes: bytes.byteLength, sha256: sha256(bytes) };
  });
  const digestInput = files.map(item => `${item.path}\0${item.bytes}\0${item.sha256}\n`).join("");
  return {
    hash_method: HASH_METHOD,
    input_paths: files.map(item => item.path),
    files,
    source_revision: revision,
    source_digest: sha256(Buffer.from(digestInput))
  };
}

function validateSource(source, root, revision, expectedDigest) {
  requireThat(isRecord(source) && source.hash_method === HASH_METHOD, "Phase 175 source manifest is missing or unsupported");
  requireThat(source.source_revision === revision && SHA1.test(revision), "Phase 175 source revision is stale or malformed");
  const current = sourceIdentity(root, revision);
  requireThat(source.source_digest === expectedDigest && current.source_digest === expectedDigest, "Phase 175 selected-source digest is stale");
  exactStringSet(source.input_paths, current.input_paths, "Phase 175 selected source paths");
  requireThat(JSON.stringify(source.files) === JSON.stringify(current.files), "Phase 175 selected-source file hashes do not match the current workspace");
  return current;
}

function flattenPlaywrightTests(suites, inheritedFile = "", acc = []) {
  for (const suite of suites || []) {
    const suiteFile = suite.file || inheritedFile;
    for (const spec of suite.specs || []) {
      const file = spec.file || suiteFile;
      for (const attempt of spec.tests || []) {
        acc.push({
          title: spec.title,
          file,
          line: spec.line,
          id: Number.isSafeInteger(spec.line) && nonempty(file) ? `${file}:${spec.line}:${spec.title}` : null,
          status: attempt.status || attempt.outcome,
          resultStatuses: (attempt.results || []).map(result => result.status)
        });
      }
    }
    flattenPlaywrightTests(suite.suites, suiteFile, acc);
  }
  return acc;
}

function selectExpectedTests(report, declarations, label, { exactReport = false } = {}) {
  requireThat(isRecord(report) && Array.isArray(report.suites), `${label} Playwright report is missing suites`);
  const all = flattenPlaywrightTests(report.suites);
  requireThat(all.length > 0, `${label} Playwright report executed zero cases`);
  const selected = [];
  for (const [suffix, title] of declarations) {
    const matches = all.filter(item => item.title === title && typeof item.file === "string" && item.file.endsWith(suffix));
    requireThat(matches.length === 1, `${label} expected case is missing or duplicated: ${suffix} :: ${title}`);
    const item = matches[0];
    requireThat(nonempty(item.id), `${label} case lacks source file/line identity: ${title}`);
    requireThat(item.status === "expected" || item.status === "passed", `${label} case did not pass: ${title} (${String(item.status)})`);
    requireThat(item.resultStatuses.length === 1 && item.resultStatuses[0] === "passed", `${label} case is skipped, retried, or failed: ${title}`);
    selected.push(item);
  }
  exactStringSet(selected.map(item => item.id), selected.map(item => item.id), `${label} selected case identities`);
  if (exactReport) requireThat(all.length === declarations.length, `${label} report contains unexpected or missing selected cases`);
  return selected.map(item => ({ id: item.id, status: "passed", title: item.title, file: item.file, line: item.line }));
}

function fidelitySourcePaths() {
  return [...FIDELITY_SOURCE_FILES].sort((left, right) => left.localeCompare(right));
}

function validateFidelitySource(source, root, revision) {
  requireThat(isRecord(source) && source.hash_method === HASH_METHOD, "fidelity source manifest is missing or unsupported");
  requireThat(source.revision === revision, "fidelity source revision is stale");
  const expectedPaths = fidelitySourcePaths();
  exactStringSet(source.files?.map(item => item.path), expectedPaths, "fidelity source input paths");
  const currentFiles = expectedPaths.map(relativePath => {
    const bytes = fs.readFileSync(path.join(root, relativePath));
    return { path: relativePath, bytes: bytes.byteLength, sha256: sha256(bytes) };
  });
  requireThat(JSON.stringify(source.files) === JSON.stringify(currentFiles), "fidelity source asset/input bytes are stale");
  const digestInput = currentFiles.map(item => `${item.path}\0${item.bytes}\0${item.sha256}\n`).join("");
  requireThat(source.digest === sha256(Buffer.from(digestInput)), "fidelity source digest is invalid");
  return currentFiles;
}

function safeWorkspaceFile(root, relativePath, label) {
  requireThat(nonempty(relativePath) && !path.isAbsolute(relativePath) && !relativePath.split(/[\\/]/).includes(".."), `${label} path is unsafe`);
  const resolved = path.resolve(root, relativePath);
  requireThat(resolved.startsWith(`${path.resolve(root)}${path.sep}`), `${label} path escapes workspace`);
  const stat = fs.lstatSync(resolved);
  requireThat(stat.isFile() && !stat.isSymbolicLink() && stat.size > 0, `${label} artifact is missing or empty`);
  return resolved;
}

function validateFidelityReceipt(receipt, { root = ROOT, revision }) {
  requireThat(isRecord(receipt), "Phase 175 fidelity receipt is missing");
  const sourceFiles = validateFidelitySource(receipt.source, root, revision);
  exactStringSet(receipt.selectedCaseIds, FIDELITY_CASE_IDS, "fidelity selected case IDs");
  exactStringSet(receipt.executedCaseIds, FIDELITY_CASE_IDS, "fidelity executed case IDs");
  requireThat(Array.isArray(receipt.cases) && receipt.cases.length > 0, "fidelity case receipts are empty");
  const detail = [...receipt.cases].reverse().find(item => item?.caseId === "fidelity:delivery-investigation:long-unicode");
  requireThat(isRecord(detail), "fidelity run detail receipt is missing");
  exactStringSet(detail.executedCaseIds, FIDELITY_CASE_IDS, "fidelity detail executed case IDs");
  requireThat(detail.expectedCaseCount === FIDELITY_CASE_IDS.length && detail.completedCaseCount === FIDELITY_CASE_IDS.length, "fidelity expected/executed counts are incomplete");

  const storyUrl = new URL(detail.urls?.storyUrl || "");
  const iframeUrl = new URL(detail.urls?.storyIframeUrl || "");
  const connectedUrl = new URL(detail.urls?.connectedUrl || "");
  requireThat(storyUrl.pathname === "/dev/storybook/delivery_investigation" && storyUrl.searchParams.get("variation_id") === "fjordline_long_unicode", "fidelity story URL is missing or stale");
  const inlineStoryIframe = detail.urls?.storyIframeMode === "srcdoc" && iframeUrl.href === "about:srcdoc";
  const routedStoryIframe = detail.urls?.storyIframeMode === "url" && iframeUrl.origin === storyUrl.origin && iframeUrl.pathname.startsWith("/dev/storybook/iframe/");
  requireThat(inlineStoryIframe || routedStoryIframe, "fidelity iframe URL is missing or from the wrong source");
  requireThat(detail.urls?.storyIframeOwnerOrigin === storyUrl.origin && detail.urls?.storyIframeParentOrigin === storyUrl.origin, "fidelity iframe parent access is missing or from the wrong source");
  if (inlineStoryIframe) {
    requireThat(detail.urls.storyIframeDocumentOrigin === "null" && typeof detail.urls.storyIframeHasSrcAttribute === "boolean" && Number.isInteger(detail.urls.storyIframeSrcdocBytes) && detail.urls.storyIframeSrcdocBytes > 0 && SHA256.test(detail.urls.storyIframeSrcdocSha256 || ""), "fidelity inline iframe source proof is incomplete");
  } else {
    requireThat(detail.urls?.storyIframeDocumentOrigin === storyUrl.origin && detail.urls?.storyIframeHasSrcAttribute === true, "fidelity routed iframe source proof is incomplete");
  }
  requireThat(connectedUrl.origin === storyUrl.origin && connectedUrl.pathname.startsWith("/ops/"), "fidelity connected-route URL is missing or from the wrong source");
  requireThat([storyUrl, connectedUrl].every(url => url.protocol === "http:" && !url.username && !url.password), "fidelity URLs contain an unsupported origin or credentials");

  const sourceByPath = new Map(sourceFiles.map(item => [item.path, item]));
  const cssFile = sourceByPath.get("mailglass_admin/priv/static/app.css");
  const stylesheet = detail.assets?.stylesheet;
  requireThat(isRecord(stylesheet) && stylesheet.status === 200 && stylesheet.matchesBuilt === true, "fidelity production stylesheet receipt failed");
  const stylesheetUrl = new URL(stylesheet.url || "");
  requireThat(stylesheetUrl.origin === storyUrl.origin && /^\/(dev|ops)\/mail\/css-[0-9a-f]{32}$/.test(stylesheetUrl.pathname), "fidelity stylesheet URL is missing, stale, or wrong-source");
  const cssBytes = fs.readFileSync(path.join(root, cssFile.path));
  requireThat(stylesheet.bytes === cssBytes.byteLength && stylesheet.sha256 === sha256(cssBytes) && stylesheet.md5 === md5(cssBytes) && stylesheetUrl.pathname.endsWith(stylesheet.md5), "served stylesheet bytes or version URL do not match current production CSS");

  const expectedFonts = FIDELITY_SOURCE_FILES.filter(item => item.startsWith("mailglass_admin/priv/static/fonts/")).map(item => path.basename(item)).sort();
  requireThat(Array.isArray(detail.assets.fonts) && detail.assets.fonts.length === expectedFonts.length, "fidelity font asset receipt is incomplete");
  exactStringSet(detail.assets.fonts.map(item => item.path), expectedFonts, "fidelity font asset paths");
  for (const font of detail.assets.fonts) {
    const relativePath = `mailglass_admin/priv/static/fonts/${font.path}`;
    const expected = sourceByPath.get(relativePath);
    const bytes = fs.readFileSync(path.join(root, relativePath));
    const url = new URL(font.url || "");
    requireThat(font.status === 200 && String(font.contentType).includes("font/woff2"), `font response failed: ${font.path}`);
    requireThat(url.origin === storyUrl.origin && url.pathname.endsWith(`/fonts/${font.path}`), `font URL is missing or wrong-source: ${font.path}`);
    requireThat(font.bytes === expected.bytes && font.bytes === bytes.byteLength && font.sha256 === expected.sha256 && font.sha256 === sha256(bytes), `font bytes are stale: ${font.path}`);
  }
  requireThat(Array.isArray(detail.assets.loadedFaces) && detail.assets.loadedFaces.length === 6 && detail.assets.loadedFaces.every(item => item.status === "loaded"), "fidelity font face load receipt is incomplete");
  requireThat(detail.hooks?.storyHostConnected === true && detail.hooks.quickViewClosed === true && nonempty(detail.hooks.exactFocusReturnId), "fidelity connected hook/focus receipt is incomplete");
  requireThat(detail.zoom?.tabZoom?.factor === 2 && detail.zoom?.effective?.viewportWidth === 320 && detail.zoom.effective.documentWidth <= 320, "fidelity real 200-percent zoom receipt is incomplete");
  safeWorkspaceFile(root, detail.zoom?.screenshot, "fidelity zoom screenshot");
  for (const screenshot of detail.screenshots || []) safeWorkspaceFile(root, screenshot, "fidelity responsive screenshot");

  return {
    expected_case_ids: FIDELITY_CASE_IDS,
    executed_case_ids: [...receipt.executedCaseIds].sort(),
    story_url: storyUrl.href,
    iframe_url: iframeUrl.href,
    iframe_mode: detail.urls.storyIframeMode,
    iframe_document_origin: detail.urls.storyIframeDocumentOrigin,
    iframe_owner_origin: detail.urls.storyIframeOwnerOrigin,
    iframe_parent_access_origin: detail.urls.storyIframeParentOrigin,
    connected_url: connectedUrl.href,
    stylesheet_url: stylesheetUrl.href,
    stylesheet_sha256: stylesheet.sha256,
    font_urls: detail.assets.fonts.map(item => item.url).sort(),
    font_sha256: Object.fromEntries(detail.assets.fonts.map(item => [item.path, item.sha256]))
  };
}

function validateAxeReceipt(report, {
  runId,
  revision,
  sourceDigest,
  manifestPath = path.join(ROOT, "reference/persona_spec/quick_view_scenarios.json"),
  approvalPath = path.join(ROOT, "mailglass_admin/docs/storybook-axe-approved.json"),
  approval: suppliedApproval
}) {
  requireThat(isRecord(report), "Axe report is missing");
  const manifest = loadJson(manifestPath, "current quick-view manifest");
  const expectedRows = selectedCases(manifest).cases;
  const expectedIds = expectedRows.map(item => item.case_id);
  requireThat(report.run_id === runId, "Axe report run identity is stale");
  requireThat(report.source_revision === revision && report.source_digest === sourceDigest, "Axe report source identity is stale or wrong-source");
  exactStringSet(report.expected?.map(item => item.case_id), expectedIds, "Axe expected case IDs");
  const executed = (report.executed || []).map(item => ({ id: item.case_id, status: item.status }));
  const executedIds = validateCaseReceipts(expectedIds, executed, "Axe");
  requireThat(Array.isArray(report.violations), "Axe violation accounting is missing");
  requireThat(Array.isArray(report.incomplete), "Axe incomplete finding accounting is missing");
  const expectedIdSet = new Set(expectedIds);
  for (const finding of [...report.violations, ...report.incomplete]) {
    const caseId = isRecord(finding) && nonempty(finding.scenario_id) && nonempty(finding.state) &&
      ["light", "dark"].includes(finding.theme)
      ? `${finding.scenario_id}::${finding.state}::${finding.theme}`
      : null;
    requireThat(caseId !== null && expectedIdSet.has(caseId), "Axe finding has missing or unexpected case identity");
  }
  const approval = suppliedApproval ?? loadJson(approvalPath, "approved Axe findings and incomplete triage");
  const comparison = compareFindings(report, approval);
  requireThat(comparison.valid, `Axe findings are not fully accounted for: ${comparison.errors.join("; ")}`);
  return {
    expected_case_ids: expectedIds,
    executed_case_ids: executedIds,
    expected_count: expectedIds.length,
    executed_count: executedIds.length,
    violation_count: report.violations.length,
    incomplete_count: report.incomplete.length,
    unapproved_violation_count: comparison.metrics.unapproved,
    untriaged_incomplete_count: comparison.metrics.untriaged,
    incomplete_disposition: "retained and independently triaged; never counted as violations or as a clean pass"
  };
}

function validateLayoutReceipt(receipt, label) {
  requireThat(isRecord(receipt), `${label} layout receipt is missing`);
  requireThat(receipt.expectedCaseCount === 6 && receipt.executedCaseCount === 6, `${label} layout expected/executed count is incomplete`);
  requireThat(Array.isArray(receipt.cases) && receipt.cases.length === 5, `${label} responsive width matrix is incomplete`);
  exactStringSet(receipt.cases.map(item => String(item.width)), WIDTHS.map(String), `${label} layout widths`);
  requireThat(receipt.realZoom?.source?.tabZoom?.factor === 2 && receipt.realZoom.source.effective.viewportWidth === 320, `${label} actual 200-percent zoom evidence is incomplete`);
  requireThat(receipt.realZoom.dialog?.focusWrap === true, `${label} replay modal focus evidence is incomplete`);
  return { expected_count: 6, executed_count: 6, widths: WIDTHS, zoom_factor: receipt.realZoom.source.tabZoom.factor };
}

function validateCondition(evidenceRoot, condition, run) {
  const conditionDir = path.join(evidenceRoot, PHASE_DIR_NAME, condition);
  const phase174Dir = path.join(evidenceRoot, "phase174", condition);
  const demoReport = loadJson(path.join(conditionDir, "demo-playwright-report.json"), `${condition} Phase 175 Demo Playwright report`);
  const adminReport = loadJson(path.join(conditionDir, "admin-playwright-report.json"), `${condition} connected Admin Playwright report`);
  const fidelityReceipt = loadJson(path.join(conditionDir, "fidelity.json"), `${condition} fidelity receipt`);
  const axeReport = loadJson(path.join(conditionDir, "axe.json"), `${condition} Axe report`);
  const runtime = loadJson(path.join(conditionDir, "runtime.json"), `${condition} runtime receipt`);
  const demo = selectExpectedTests(demoReport, DEMO_CASES, `${condition} Demo`);
  const admin = selectExpectedTests(adminReport, ADMIN_CASES, `${condition} Admin`, { exactReport: true });
  const fidelity = validateFidelityReceipt(fidelityReceipt, { root: ROOT, revision: run.source_revision });
  const axe = validateAxeReceipt(axeReport, {
    runId: `${run.run_id}-${condition}`,
    revision: run.source_revision,
    sourceDigest: run.phase174_source_digest
  });
  const deliveryLayout = validateLayoutReceipt(loadJson(path.join(conditionDir, "delivery-layout.json"), `${condition} Delivery layout receipt`), `${condition} Delivery`);
  const inboundLayout = validateLayoutReceipt(loadJson(path.join(conditionDir, "inbound-layout.json"), `${condition} Inbound layout receipt`), `${condition} Inbound`);
  const expectedGroups = {
    demo: demo.map(item => item.id).sort(),
    admin: admin.map(item => item.id).sort(),
    fidelity: fidelity.expected_case_ids,
    axe: axe.expected_case_ids
  };
  const executedGroups = {
    demo: demo.map(item => item.id).sort(),
    admin: admin.map(item => item.id).sort(),
    fidelity: fidelity.executed_case_ids,
    axe: axe.executed_case_ids
  };
  for (const group of Object.keys(expectedGroups)) {
    validateCaseReceipts(expectedGroups[group], executedGroups[group].map(id => ({ id, status: "passed" })), `${condition} ${group}`);
  }
  requireThat(runtime.condition === condition && runtime.source_revision === run.source_revision && runtime.source_digest === run.source_digest, `${condition} runtime source identity is stale`);
  requireThat(Number.isSafeInteger(runtime.admin_operator_ms) && runtime.admin_operator_ms > 0, `${condition} Admin operator runtime is missing`);
  requireThat(runtime.admin_operator_exit_code === 0, `${condition} Admin operator suite failed`);
  requireThat(runtime.compose_project === run.compose_project, `${condition} runtime used another Compose project`);
  for (const [label, file] of [["demo report", "demo-playwright-report.json"], ["admin report", "admin-playwright-report.json"], ["fidelity", "fidelity.json"], ["axe", "axe.json"]]) {
    const stat = fs.lstatSync(path.join(conditionDir, file));
    requireThat(stat.isFile() && !stat.isSymbolicLink() && stat.size > 0, `${condition} ${label} receipt is empty or unsafe`);
  }
  requireThat(fs.existsSync(path.join(phase174Dir, "execution-condition.json")), `${condition} Phase 174 execution condition is missing`);
  return {
    condition,
    run_id: `${run.run_id}-${condition}`,
    source_revision: run.source_revision,
    source_digest: run.source_digest,
    expected_case_ids: expectedGroups,
    executed_case_ids: executedGroups,
    counts: Object.fromEntries(Object.entries(executedGroups).map(([key, ids]) => [key, ids.length])),
    axe: { expected: axe.expected_count, executed: axe.executed_count, violations: axe.violation_count, incomplete: axe.incomplete_count, incomplete_disposition: axe.incomplete_disposition },
    fidelity: { story_url: fidelity.story_url, iframe_url: fidelity.iframe_url, connected_url: fidelity.connected_url, stylesheet_url: fidelity.stylesheet_url, stylesheet_sha256: fidelity.stylesheet_sha256, font_urls: fidelity.font_urls, font_sha256: fidelity.font_sha256 },
    layout: { delivery: deliveryLayout, inbound: inboundLayout },
    timings_ms: runtime.timings_ms || {},
    added_cost_ms: runtime.admin_operator_ms
  };
}

function checkEvidence(evidenceRoot, { pilot = false, writeSummary = false } = {}) {
  const phaseDir = path.join(evidenceRoot, PHASE_DIR_NAME);
  const run = loadJson(path.join(phaseDir, "run.json"), "Phase 175 run receipt");
  requireThat(run.schema_version === "phase175-run.v1" && run.phase === 175, "Phase 175 run receipt has an unsupported schema/phase");
  requireThat(nonempty(run.run_id) && run.compose_project === run.run_id && SHA1.test(run.source_revision), "Phase 175 run identity is malformed");
  requireThat(run.pilot === pilot, "Phase 175 pilot flag does not match selected run");
  requireThat(run.serial === true, "Phase 175 cases were not declared serial");
  requireThat(run.cleanup?.completed === true && run.cleanup.compose_project === run.compose_project, "run-owned Compose cleanup is missing or belongs to another project");
  const source = validateSource(run.source, ROOT, run.source_revision, run.source_digest);
  requireThat(SHA256.test(run.phase174_source_digest), "Phase 174 source digest is missing for Axe receipts");
  const conditions = pilot ? ["cold", "warm"] : ["single"];
  exactStringSet(run.conditions, conditions, "Phase 175 conditions");
  requireThat(Array.isArray(run.condition_runtime) && run.condition_runtime.length === conditions.length, "Phase 175 runtime condition set is incomplete");
  const runtimeByCondition = new Map(run.condition_runtime.map(item => [item.condition, item]));
  const results = conditions.map(condition => validateCondition(evidenceRoot, condition, {
    ...run,
    ...runtimeByCondition.get(condition)
  }));
  const addedCostMs = results.reduce((sum, item) => sum + item.added_cost_ms, 0) + Number(run.checker_ms || 0);
  requireThat(Number.isSafeInteger(run.checker_ms) && run.checker_ms > 0, "Phase 175 receipt checker runtime is missing");
  const summary = {
    schema_version: "phase175-execution.v1",
    phase: 175,
    valid: true,
    run_id: run.run_id,
    mode: run.mode,
    pilot,
    source_revision: run.source_revision,
    source_digest: run.source_digest,
    source,
    phase174_source_digest: run.phase174_source_digest,
    serial: true,
    conditions: results,
    cost: {
      observed_phase175_added_ms: addedCostMs,
      observed_phase175_added_minutes: addedCostMs / 60000,
      per_condition_admin_operator_ms: Object.fromEntries(results.map(item => [item.condition, item.added_cost_ms])),
      provisional_pr_wall_minutes: 5,
      provisional_runner_minutes: 10,
      local_vs_hosted: run.mode === "ci" ? "GitHub job timing is recorded by the existing advisory lane" : "local elapsed time only; hosted runner minutes await the existing advisory job",
      budget_status: addedCostMs <= 300000 ? "within-provisional-five-minute-added-wall-budget" : "over-provisional-budget-review-required"
    },
    cleanup: run.cleanup
  };
  if (writeSummary) fs.writeFileSync(path.join(phaseDir, "execution.json"), `${JSON.stringify(summary, null, 2)}\n`);
  return summary;
}

function parseArgs(argv) {
  const args = { evidenceDir: null, pilot: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === "--evidence-dir") args.evidenceDir = argv[++index];
    else if (flag === "--pilot") args.pilot = true;
    else fail(`unknown option ${flag}`);
  }
  requireThat(nonempty(args.evidenceDir), "required option --evidence-dir is missing");
  return args;
}

function cli(argv = process.argv.slice(2)) {
  try {
    const args = parseArgs(argv);
    const summary = checkEvidence(path.resolve(args.evidenceDir), { pilot: args.pilot, writeSummary: true });
    process.stdout.write(`${JSON.stringify(summary)}\n`);
  } catch (error) {
    process.stderr.write(`ERROR: ${error.message}\n`);
    process.exitCode = 1;
  }
}

if (require.main === module) cli();

module.exports = {
  ADMIN_CASES,
  DEMO_CASES,
  FIDELITY_CASE_IDS,
  checkEvidence,
  exactStringSet,
  fidelitySourcePaths,
  parseArgs,
  selectedSourcePaths,
  selectExpectedTests,
  sourceIdentity,
  validateAxeReceipt,
  validateCaseReceipts,
  validateFidelityReceipt,
  validateFidelitySource,
  validateLayoutReceipt,
  validateSource
};
