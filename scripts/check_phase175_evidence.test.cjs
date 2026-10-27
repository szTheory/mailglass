const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const zlib = require("node:zlib");
const { execFileSync } = require("node:child_process");
const test = require("node:test");
const checker174 = require("./check_phase174_evidence.cjs");
const { selectedCases } = require("../mailglass_admin/e2e/support/storybook-axe.cjs");
const checker = require("./check_phase175_evidence.cjs");

const ROOT = path.resolve(__dirname, "..");
const REVISION = execFileSync("git", ["rev-parse", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim();
const hash = (bytes, algorithm = "sha256") => crypto.createHash(algorithm).update(bytes).digest("hex");
const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const FIDELITY_SCREENSHOTS = [
  "delivery-investigation-320-dark.png",
  "delivery-investigation-1440-dark.png",
  "delivery-investigation-200-browser-zoom.png"
];
const FIDELITY_CAPTURE_GEOMETRIES = [
  { filename: FIDELITY_SCREENSHOTS[0], width: 320, height: 2153, viewportWidth: 320, viewportHeight: 900, devicePixelRatio: 1, screenshotScale: 1 },
  { filename: FIDELITY_SCREENSHOTS[1], width: 1440, height: 1363, viewportWidth: 1440, viewportHeight: 900, devicePixelRatio: 1, screenshotScale: 1 },
  { filename: FIDELITY_SCREENSHOTS[2], width: 640, height: 4316, viewportWidth: 320, viewportHeight: 2324, devicePixelRatio: 4, screenshotScale: 2 }
];

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = crc & 1 ? 0xedb88320 ^ (crc >>> 1) : crc >>> 1;
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function fixturePng(width, height) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8;
  header[9] = 2;
  const chunk = (type, data) => {
    const typeBytes = Buffer.from(type, "ascii");
    const value = Buffer.alloc(12 + data.length);
    value.writeUInt32BE(data.length, 0);
    typeBytes.copy(value, 4);
    data.copy(value, 8);
    value.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 8 + data.length);
    return value;
  };
  return Buffer.concat([
    PNG_SIGNATURE,
    chunk("IHDR", header),
    chunk("IDAT", zlib.deflateSync(Buffer.alloc(height * (width * 3 + 1)))),
    chunk("IEND", Buffer.alloc(0))
  ]);
}

function corruptPngImageData(png) {
  const chunks = [];
  let offset = PNG_SIGNATURE.length;
  while (offset < png.length) {
    const length = png.readUInt32BE(offset);
    const type = png.toString("ascii", offset + 4, offset + 8);
    const data = type === "IDAT" ? Buffer.from("not-zlib") : png.subarray(offset + 8, offset + 8 + length);
    const typeBytes = Buffer.from(type, "ascii");
    const chunk = Buffer.alloc(12 + data.length);
    chunk.writeUInt32BE(data.length, 0);
    typeBytes.copy(chunk, 4);
    data.copy(chunk, 8);
    chunk.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 8 + data.length);
    chunks.push(chunk);
    offset += length + 12;
  }
  return Buffer.concat([PNG_SIGNATURE, ...chunks]);
}

function workspaceTemp() {
  return fs.mkdtempSync(path.join(ROOT, ".phase175-checker-test-"));
}

function phase175FidelityReceipt(evidenceDir, runRevision = REVISION) {
  const files = checker.fidelitySourcePaths().map(relativePath => {
    const bytes = fs.readFileSync(path.join(ROOT, relativePath));
    return { path: relativePath, bytes: bytes.byteLength, sha256: hash(bytes) };
  });
  const sourceDigest = hash(files.map(item => `${item.path}\0${item.bytes}\0${item.sha256}\n`).join(""));
  const source = { hash_method: "sha256(sorted(path\\0byte_length\\0file_sha256\\n))", revision: runRevision, files, digest: sourceDigest };
  const origin = "http://demo:4015";
  const cssPath = "mailglass_admin/priv/static/app.css";
  const css = fs.readFileSync(path.join(ROOT, cssPath));
  const cssMd5 = hash(css, "md5");
  const fontPaths = files.map(item => item.path).filter(item => item.startsWith("mailglass_admin/priv/static/fonts/"));
  const fonts = fontPaths.map(relativePath => {
    const bytes = fs.readFileSync(path.join(ROOT, relativePath));
    const name = path.basename(relativePath);
    return { path: name, url: `${origin}/dev/mail/fonts/${name}`, status: 200, contentType: "font/woff2", bytes: bytes.byteLength, sha256: hash(bytes) };
  });
  const screenshotDir = path.relative(ROOT, evidenceDir);
  const screenshotPaths = FIDELITY_SCREENSHOTS.map(filename => `${screenshotDir}/${filename}`);
  for (const capture of FIDELITY_CAPTURE_GEOMETRIES) {
    fs.writeFileSync(path.join(evidenceDir, capture.filename), fixturePng(capture.width, capture.height));
  }
  const executedCaseIds = checker.FIDELITY_CASE_IDS;
  const detail = {
    caseId: "fidelity:delivery-investigation:long-unicode",
    expectedCaseCount: 10,
    completedCaseCount: 10,
    executedCaseIds,
    urls: {
      storyUrl: `${origin}/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode`,
      storyIframeUrl: "about:srcdoc",
      storyIframeDocumentOrigin: "null",
      storyIframeOwnerOrigin: origin,
      storyIframeParentOrigin: origin,
      storyIframeMode: "srcdoc",
      storyIframeHasSrcAttribute: false,
      storyIframeSrcdocBytes: Buffer.byteLength("<html></html>\n"),
      storyIframeSrcdocSha256: hash(Buffer.from("<html></html>\n")),
      connectedUrl: `${origin}/ops/mail/deliveries?tenant_id=browser-tenant`
    },
    assets: {
      stylesheet: { url: `${origin}/dev/mail/css-${cssMd5}`, status: 200, bytes: css.byteLength, sha256: hash(css), md5: cssMd5, matchesBuilt: true },
      fonts,
      loadedFaces: fonts.map((item, index) => ({ family: ["Inter", "Inter", "Inter Tight", "Inter Tight", "IBM Plex Mono", "IBM Plex Mono"][index], weight: [400, 700, 400, 700, 400, 700][index], status: "loaded" }))
    },
    hooks: { storyHostConnected: true, quickViewClosed: true, exactFocusReturnId: "delivery-opener" },
    widths: FIDELITY_CAPTURE_GEOMETRIES.slice(0, 2).map((capture, index) => ({
      viewportWidth: capture.viewportWidth,
      screenshot: screenshotPaths[index],
      geometry: {
        viewportWidth: capture.viewportWidth,
        viewportHeight: capture.viewportHeight,
        documentWidth: capture.viewportWidth,
        devicePixelRatio: capture.devicePixelRatio
      },
      captureGeometry: {
        viewportWidth: capture.viewportWidth,
        viewportHeight: capture.viewportHeight,
        documentWidth: capture.viewportWidth,
        contentHeight: capture.height,
        devicePixelRatio: capture.devicePixelRatio,
        screenshotScale: capture.screenshotScale
      }
    })),
    zoom: {
      tabZoom: { factor: 2 },
      initial: { viewportWidth: 1440, viewportHeight: 900, devicePixelRatio: 2 },
      effective: { viewportWidth: 320, viewportHeight: 2324, documentWidth: 320, devicePixelRatio: 4 },
      captureGeometry: {
        viewportWidth: 320,
        viewportHeight: 2324,
        documentWidth: 320,
        contentHeight: 2158,
        devicePixelRatio: 4,
        screenshotScale: 2
      },
      screenshot: `${screenshotDir}/${FIDELITY_SCREENSHOTS[2]}`
    },
    screenshots: screenshotPaths
  };
  return { source, selectedCaseIds: executedCaseIds, executedCaseIds, cases: [detail] };
}

function playwrightReport(declarations, prefix) {
  return {
    suites: [{
      file: `${prefix}/${declarations[0][0]}`,
      specs: declarations.map(([file, title], index) => ({
        file: `${prefix}/${file}`,
        line: 100 + index,
        title,
        tests: [{ status: "expected", results: [{ status: "passed" }] }]
      }))
    }]
  };
}

function axeReport(runId, runRevision, sourceDigest) {
  const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, "reference/persona_spec/quick_view_scenarios.json"), "utf8"));
  const expected = selectedCases(manifest).cases;
  const approval = JSON.parse(fs.readFileSync(path.join(ROOT, "mailglass_admin/docs/storybook-axe-approved.json"), "utf8"));
  return {
    run_id: runId,
    source_revision: runRevision,
    source_digest: sourceDigest,
    expected,
    executed: expected.map(item => ({ ...item, status: "passed", completed_at: "2026-10-27T00:00:00.000Z" })),
    violations: [],
    incomplete: approval.incomplete_triage.slice(-2).map(item => ({ ...item }))
  };
}

function layoutReceipt(label) {
  return {
    expectedCaseCount: 6,
    executedCaseCount: 6,
    cases: [320, 375, 768, 1280, 1440].map(width => ({ width, [label]: true })),
    realZoom: { source: { tabZoom: { factor: 2 }, effective: { viewportWidth: 320 } }, dialog: { focusWrap: true } }
  };
}

function cleanEvidence() {
  const root = workspaceTemp();
  const evidenceRoot = path.join(root, "evidence");
  const phase175 = path.join(evidenceRoot, "phase175");
  const conditionDir = path.join(phase175, "single");
  const runId = "mailglass-evidence-test-01-1";
  const source = checker.sourceIdentity(ROOT, REVISION);
  const phase174Source = checker174.computeSourceIdentity(ROOT, REVISION);
  fs.mkdirSync(conditionDir, { recursive: true });
  fs.mkdirSync(path.join(evidenceRoot, "phase174", "single"), { recursive: true });
  const run = {
    schema_version: "phase175-run.v1", phase: 175, run_id: runId, compose_project: runId,
    mode: "local", pilot: false, source_revision: REVISION, source_digest: source.source_digest,
    source, phase174_source_digest: phase174Source.source_digest, serial: true,
    conditions: ["single"], checker_ms: 10,
    cleanup: { completed: true, compose_project: runId },
    condition_runtime: [{ condition: "single", source_revision: REVISION, source_digest: source.source_digest, compose_project: runId, admin_operator_ms: 500, admin_operator_exit_code: 0, timings_ms: { admin_operator: 500 } }]
  };
  const files = {
    "demo-playwright-report.json": playwrightReport(checker.DEMO_CASES, "assets/e2e"),
    "admin-playwright-report.json": playwrightReport(checker.ADMIN_CASES, "e2e"),
    "fidelity.json": phase175FidelityReceipt(conditionDir),
    "axe.json": axeReport(`${runId}-single`, REVISION, phase174Source.source_digest),
    "runtime.json": { condition: "single", source_revision: REVISION, source_digest: source.source_digest, admin_operator_ms: 500, admin_operator_exit_code: 0, compose_project: runId, timings_ms: { admin_operator: 500 } },
    "delivery-layout.json": layoutReceipt("delivery"),
    "inbound-layout.json": layoutReceipt("inbound")
  };
  for (const [name, contents] of Object.entries(files)) fs.writeFileSync(path.join(conditionDir, name), `${JSON.stringify(contents, null, 2)}\n`);
  fs.writeFileSync(path.join(phase175, "run.json"), `${JSON.stringify(run, null, 2)}\n`);
  fs.writeFileSync(path.join(evidenceRoot, "phase174", "single", "execution-condition.json"), "{}\n");
  return { root, evidenceRoot, phase175, conditionDir };
}

test("Phase 175 case receipts reject empty, missing, duplicate, unexpected, failed, and skipped execution", () => {
  const expected = ["demo:delivery-tracer", "admin:inbound-confirm"];
  assert.doesNotThrow(() => checker.validateCaseReceipts(expected, expected.map(id => ({ id, status: "passed" })), "clean"));
  assert.throws(() => checker.validateCaseReceipts([], [], "empty expected"), /expected case set is empty/);
  assert.throws(() => checker.validateCaseReceipts(expected, [], "zero execution"), /executed case set is empty/);
  assert.throws(() => checker.validateCaseReceipts(expected, [{ id: expected[0], status: "passed" }], "missing"), /missing executed case/);
  assert.throws(() => checker.validateCaseReceipts(expected, [...expected.map(id => ({ id, status: "passed" })), { id: expected[0], status: "passed" }], "duplicate"), /duplicate executed case/);
  assert.throws(() => checker.validateCaseReceipts(expected, [...expected.map(id => ({ id, status: "passed" })), { id: "extra", status: "passed" }], "unexpected"), /unexpected executed case/);
  assert.throws(() => checker.validateCaseReceipts(expected, [{ id: expected[0], status: "failed" }, { id: expected[1], status: "passed" }], "failed"), /execution .* failed/);
  assert.throws(() => checker.validateCaseReceipts(expected, [{ id: expected[0], status: "skipped" }, { id: expected[1], status: "passed" }], "skipped"), /execution .* skipped/);
});

test("Phase 175 report selection requires named Demo and connected Admin cases to pass exactly once", () => {
  assert.equal(checker.selectExpectedTests(playwrightReport(checker.DEMO_CASES, "assets/e2e"), checker.DEMO_CASES, "Demo").length, 4);
  assert.equal(checker.selectExpectedTests(playwrightReport(checker.ADMIN_CASES, "e2e"), checker.ADMIN_CASES, "Admin", { exactReport: true }).length, 10);
  const missing = playwrightReport(checker.DEMO_CASES.slice(1), "assets/e2e");
  assert.throws(() => checker.selectExpectedTests(missing, checker.DEMO_CASES, "Demo"), /missing or duplicated/);
  const skipped = playwrightReport(checker.ADMIN_CASES, "e2e");
  skipped.suites[0].specs[0].tests[0].results[0].status = "skipped";
  assert.throws(() => checker.selectExpectedTests(skipped, checker.ADMIN_CASES, "Admin", { exactReport: true }), /skipped, retried, or failed/);
});

test("Phase 175 fidelity rejects stale source and wrong CSS/font URLs or bytes", () => {
  const temp = workspaceTemp();
  try {
    assert.ok(checker.fidelitySourcePaths().includes("mailglass_admin/priv/static/hooks.js"));
    const valid = phase175FidelityReceipt(temp);
    assert.equal(checker.validateFidelityReceipt(valid, { root: ROOT, revision: REVISION, evidenceDir: temp }).executed_case_ids.length, 10);
    const wrongFrameOrigin = structuredClone(valid);
    wrongFrameOrigin.cases[0].urls.storyIframeParentOrigin = "null";
    assert.throws(() => checker.validateFidelityReceipt(wrongFrameOrigin, { root: ROOT, revision: REVISION, evidenceDir: temp }), /iframe parent access/);
    const missingInlineSource = structuredClone(valid);
    delete missingInlineSource.cases[0].urls.storyIframeSrcdocSha256;
    assert.throws(() => checker.validateFidelityReceipt(missingInlineSource, { root: ROOT, revision: REVISION, evidenceDir: temp }), /inline iframe source proof/);
    const stale = structuredClone(valid);
    stale.source.revision = "0".repeat(40);
    assert.throws(() => checker.validateFidelityReceipt(stale, { root: ROOT, revision: REVISION, evidenceDir: temp }), /revision is stale/);
    const wrongCss = structuredClone(valid);
    wrongCss.cases[0].assets.stylesheet.url = "http://demo:4015/dev/mail/css-00000000000000000000000000000000";
    assert.throws(() => checker.validateFidelityReceipt(wrongCss, { root: ROOT, revision: REVISION, evidenceDir: temp }), /bytes or version URL/);
    const wrongFont = structuredClone(valid);
    wrongFont.cases[0].assets.fonts[0].url = "http://other:4015/dev/mail/fonts/inter-400.woff2";
    assert.throws(() => checker.validateFidelityReceipt(wrongFont, { root: ROOT, revision: REVISION, evidenceDir: temp }), /wrong-source/);
    const wrongResponsiveDpr = structuredClone(valid);
    wrongResponsiveDpr.cases[0].widths[0].geometry.devicePixelRatio = 2;
    assert.throws(() => checker.validateFidelityReceipt(wrongResponsiveDpr, { root: ROOT, revision: REVISION, evidenceDir: temp }), /DPR does not match/);
    const wrongZoomDpr = structuredClone(valid);
    wrongZoomDpr.cases[0].zoom.effective.devicePixelRatio = 2;
    assert.throws(() => checker.validateFidelityReceipt(wrongZoomDpr, { root: ROOT, revision: REVISION, evidenceDir: temp }), /effective DPR does not match/);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test("Phase 175 fidelity requires decoded responsive and zoom PNGs inside the current run directory", () => {
  const temp = workspaceTemp();
  try {
    const evidenceDir = path.join(temp, "run-one", "phase175", "single");
    fs.mkdirSync(evidenceDir, { recursive: true });
    const valid = phase175FidelityReceipt(evidenceDir);
    const options = { root: ROOT, revision: REVISION, evidenceDir };
    assert.doesNotThrow(() => checker.validateFidelityReceipt(valid, options));

    for (const capture of FIDELITY_CAPTURE_GEOMETRIES) {
      const screenshotPath = path.join(evidenceDir, capture.filename);
      const validBytes = fs.readFileSync(screenshotPath);
      const wrongDimensions = [
        { bytes: fixturePng(capture.width - 1, capture.height), error: /PNG width/ },
        { bytes: fixturePng(1, 1), error: /PNG width/ },
        { bytes: fixturePng(capture.width, capture.height - 1), error: /PNG height/ }
      ];
      for (const negative of wrongDimensions) {
        fs.writeFileSync(screenshotPath, negative.bytes);
        assert.throws(() => checker.validateFidelityReceipt(valid, options), negative.error, capture.filename);
      }
      fs.writeFileSync(screenshotPath, validBytes);
    }

    const missingInventory = structuredClone(valid);
    missingInventory.cases[0].screenshots = missingInventory.cases[0].screenshots.filter(item => !item.endsWith("delivery-investigation-1440-dark.png"));
    assert.throws(() => checker.validateFidelityReceipt(missingInventory, options), /screenshot inventory/);

    const otherRunDir = path.join(temp, "run-two", "phase175", "single");
    fs.mkdirSync(otherRunDir, { recursive: true });
    for (const filename of FIDELITY_SCREENSHOTS) {
      fs.copyFileSync(path.join(evidenceDir, filename), path.join(otherRunDir, filename));
    }
    const wrongRun = structuredClone(valid);
    wrongRun.cases[0].screenshots = FIDELITY_SCREENSHOTS.map(filename => `${path.relative(ROOT, otherRunDir)}/${filename}`);
    wrongRun.cases[0].zoom.screenshot = wrongRun.cases[0].screenshots[2];
    assert.throws(() => checker.validateFidelityReceipt(wrongRun, options), /screenshot inventory/);

    const responsivePng = path.join(evidenceDir, FIDELITY_SCREENSHOTS[0]);
    const pngBytes = fs.readFileSync(responsivePng);
    fs.writeFileSync(responsivePng, "arbitrary nonempty file");
    assert.throws(() => checker.validateFidelityReceipt(valid, options), /PNG signature/);
    fs.writeFileSync(responsivePng, corruptPngImageData(fixturePng(320, 2153)));
    assert.throws(() => checker.validateFidelityReceipt(valid, options), /cannot be decoded/);
    fs.writeFileSync(responsivePng, pngBytes);

    const missingCapture = path.join(evidenceDir, FIDELITY_SCREENSHOTS[1]);
    fs.unlinkSync(missingCapture);
    assert.throws(() => checker.validateFidelityReceipt(valid, options), /artifact is missing/);
    fs.writeFileSync(missingCapture, pngBytes);

    const leafTarget = path.join(temp, "leaf-target.png");
    fs.writeFileSync(leafTarget, fixturePng(320, 2153));
    fs.unlinkSync(responsivePng);
    fs.symlinkSync(leafTarget, responsivePng);
    assert.throws(() => checker.validateFidelityReceipt(valid, options), /symlink/);
    fs.unlinkSync(responsivePng);
    fs.writeFileSync(responsivePng, pngBytes);

    const physicalRoot = path.join(temp, "physical-run");
    const symlinkRoot = path.join(temp, "run-alias");
    const aliasedEvidenceDir = path.join(symlinkRoot, "phase175", "single");
    fs.mkdirSync(path.join(physicalRoot, "phase175", "single"), { recursive: true });
    fs.symlinkSync(physicalRoot, symlinkRoot, "dir");
    const aliased = phase175FidelityReceipt(aliasedEvidenceDir);
    assert.throws(
      () => checker.validateFidelityReceipt(aliased, { root: ROOT, revision: REVISION, evidenceDir: aliasedEvidenceDir }),
      /symlink/
    );
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test("Phase 175 Axe receipt accounts for expected, executed, violation, and separately triaged incomplete rows", () => {
  const report = axeReport("fixture-cold", REVISION, "a".repeat(64));
  const summary = checker.validateAxeReceipt(report, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64) });
  assert.equal(summary.expected_count, 26);
  assert.equal(summary.executed_count, 26);
  assert.equal(summary.violation_count, 0);
  assert.equal(summary.incomplete_count, 2);
  assert.match(summary.incomplete_disposition, /independently triaged/);
  const missing = structuredClone(report);
  delete missing.incomplete;
  assert.throws(() => checker.validateAxeReceipt(missing, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64) }), /incomplete finding accounting/);
  const wrongSource = structuredClone(report);
  wrongSource.source_digest = "b".repeat(64);
  assert.throws(() => checker.validateAxeReceipt(wrongSource, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64) }), /source identity/);

  const untriaged = structuredClone(report);
  untriaged.incomplete.push({
    rule_id: "color-contrast",
    target: [[".not-in-approved-triage"]],
    scenario_id: "delivery-investigation-northstar-normal",
    state: "normal-permitted-review",
    theme: "light",
    impact: "serious",
    count: 1
  });
  assert.throws(() => checker.validateAxeReceipt(untriaged, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64) }), /untriaged incomplete/);
  const wrongFindingIdentity = structuredClone(report);
  wrongFindingIdentity.incomplete[0].state = "not-in-manifest";
  assert.throws(() => checker.validateAxeReceipt(wrongFindingIdentity, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64) }), /missing or unexpected case identity/);

  const approved = JSON.parse(fs.readFileSync(path.join(ROOT, "mailglass_admin/docs/storybook-axe-approved.json"), "utf8"));
  const missingEvidenceRun = structuredClone(approved);
  missingEvidenceRun.evidence_runs = missingEvidenceRun.evidence_runs.filter(run => !report.incomplete.some(item => item.evidence === run.run_id));
  assert.throws(() => checker.validateAxeReceipt(report, { runId: "fixture-cold", revision: REVISION, sourceDigest: "a".repeat(64), approval: missingEvidenceRun }), /independent reviewed run/);
});

test("Phase 175 clean current-source evidence passes while missing and malformed reports fail", () => {
  const fixture = cleanEvidence();
  try {
    const summary = checker.checkEvidence(fixture.evidenceRoot, { pilot: false });
    assert.equal(summary.valid, true);
    assert.equal(summary.conditions[0].counts.admin, 10);
    assert.equal(summary.conditions[0].counts.demo, 4);
    assert.equal(summary.conditions[0].axe.incomplete, 2);
    assert.equal(summary.conditions[0].fidelity.font_urls.length, 6);

    const admin = path.join(fixture.conditionDir, "admin-playwright-report.json");
    const content = fs.readFileSync(admin, "utf8");
    fs.unlinkSync(admin);
    assert.throws(() => checker.checkEvidence(fixture.evidenceRoot, { pilot: false }), /Admin Playwright report is missing/);
    fs.writeFileSync(admin, "{");
    assert.throws(() => checker.checkEvidence(fixture.evidenceRoot, { pilot: false }), /malformed JSON/);
    fs.writeFileSync(admin, content);

    const runPath = path.join(fixture.phase175, "run.json");
    const run = JSON.parse(fs.readFileSync(runPath, "utf8"));
    run.source_digest = "f".repeat(64);
    fs.writeFileSync(runPath, JSON.stringify(run));
    assert.throws(() => checker.checkEvidence(fixture.evidenceRoot, { pilot: false }), /selected-source digest is stale/);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("Phase 175 selected source identity binds the Demo Mix dependency manifest", () => {
  assert.ok(checker.selectedSourcePaths(ROOT).includes("reference/demo_app/mix.exs"));
  assert.ok(checker.sourceIdentity(ROOT, REVISION).input_paths.includes("reference/demo_app/mix.exs"));
});
