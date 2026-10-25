const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const { createCheckpoint } = require("./check-demo-browser-evidence.cjs");
const workflowPath = path.resolve(__dirname, "../../../../.github/workflows/ci.yml");
const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lN8AAAAASUVORK5CYII=",
  "base64"
);
const CANDIDATE = "1f84f510fcf6e80799fa99027bd1a33b186f47fa";

function fixture(evidenceDir, attachmentPath) {
  const capturePath = path.join(evidenceDir, "preview.png");
  fs.writeFileSync(capturePath, png);
  fs.writeFileSync(path.join(evidenceDir, "baseline.png"), png);
  const pngSha = crypto.createHash("sha256").update(png).digest("hex");
  const report = {
    suites: [
      {
        title: "phase173-evidence.spec.js",
        specs: [
          {
            title: "current preview route",
            tests: [
              {
                outcome: "expected",
                results: [
                  {
                    attachments: [
                      {
                        name: "screenshot",
                        contentType: "image/png",
                        path: attachmentPath || capturePath
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  };
  const capture = {
    id: "current-preview-capture",
    test_title: "current preview route",
    route: "/dev/mail?theme=light",
    fixture: "synthetic preview fixture",
    theme: "light",
    viewport: "1x1",
    interaction_state: "initial route",
    browser: "Chromium test fixture",
    before_after: {
      baseline_id: "baseline-preview",
      baseline_path: "baseline.png",
      baseline_sha256: pngSha,
      baseline_source_revision: CANDIDATE,
      baseline_dirty: true,
      baseline_route: "/dev/mail?theme=light",
      baseline_fixture: "synthetic preview fixture",
      baseline_theme: "light",
      baseline_viewport: "1x1",
      baseline_capture_dimensions: "1x1",
      baseline_interaction_state: "initial route",
      baseline_browser: "Chromium test fixture",
      relation: "paired current and baseline captures"
    },
    candidate_revision: CANDIDATE,
    candidate_dirty: true,
    path: attachmentPath ? path.relative(evidenceDir, attachmentPath) : "preview.png",
    sha256: pngSha,
    assets: {
      kind: "admin-css",
      source: { path: "source.css", sha256: "1".repeat(64) },
      built: { path: "built.css", sha256: "2".repeat(64) },
      served: { url: "/dev/mail/css-test", sha256: "2".repeat(64) },
      built_served_match: true
    },
    rendering_scope: "Browser rendering only; no email client behavior is certified."
  };
  return {
    report,
    manifest: { schema_version: "phase173-captures.v2", captures: [capture] }
  };
}

function checkpointArgs(evidenceDir, report, manifest) {
  return {
    report,
    manifest,
    evidenceDir,
    candidateRevision: CANDIDATE,
    requiredTestTitles: ["current preview route"]
  };
}

test("accepts one current capture and hashes its PNG bytes", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  const checkpoint = createCheckpoint(checkpointArgs(evidenceDir, report, manifest));

  assert.equal(checkpoint.status, "passed");
  assert.equal(checkpoint.candidate_dirty, true);
  assert.equal(checkpoint.captures.length, 1);
  assert.equal(checkpoint.captures[0].sha256, crypto.createHash("sha256").update(png).digest("hex"));
});

test("records a clean candidate when every capture is clean", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  manifest.captures[0].candidate_dirty = false;
  const checkpoint = createCheckpoint(checkpointArgs(evidenceDir, report, manifest));

  assert.equal(checkpoint.candidate_dirty, false);
  assert.equal(checkpoint.captures[0].candidate_dirty, false);
});

test("rejects captures with inconsistent candidate dirty-tree state", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  fs.copyFileSync(path.join(evidenceDir, "preview.png"), path.join(evidenceDir, "second.png"));
  manifest.captures.push({ ...manifest.captures[0], id: "second-capture", path: "second.png", candidate_dirty: false });

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)),
    /candidate dirty-tree state is inconsistent/
  );
});

test("rejects a report with zero current captures", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, { suites: [] }, { schema_version: "phase173-captures.v2", captures: [] })),
    /exactly one current capture/
  );
});

test("rejects a missing PNG", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const missingPath = path.join(evidenceDir, "missing.png");
  const { report, manifest } = fixture(evidenceDir, missingPath);

  assert.throws(() => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)), /missing or invalid PNG/);
});

test("rejects symlinks that escape the run-owned evidence directory", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  const outsideDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-outside-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  t.after(() => fs.rmSync(outsideDir, { recursive: true, force: true }));
  const outsidePath = path.join(outsideDir, "outside.png");
  fs.writeFileSync(outsidePath, png);
  const aliasPath = path.join(evidenceDir, "external.png");
  fs.symlinkSync(outsidePath, aliasPath);
  const { report, manifest } = fixture(evidenceDir, aliasPath);

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)),
    /outside the owned evidence directory/
  );
});

test("rejects absolute and traversal capture paths", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  manifest.captures[0].path = path.join(evidenceDir, "preview.png");
  assert.throws(() => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)), /relative and traversal-free/);

  manifest.captures[0].path = "../outside.png";
  assert.throws(() => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)), /relative and traversal-free/);
});

test("accepts multiple captures and preserves long route and revision text exactly", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  const longRoute = `/dev/mail/${"preview-scenario-".repeat(24)}?candidate=${"a".repeat(80)}`;
  fs.writeFileSync(path.join(evidenceDir, "second.png"), png);
  manifest.captures.push({
    ...manifest.captures[0],
    id: "long-route-current-capture",
    route: longRoute,
    path: "second.png"
  });

  const checkpoint = createCheckpoint(checkpointArgs(evidenceDir, report, manifest));
  assert.equal(checkpoint.captures.length, 2);
  assert.equal(checkpoint.captures[1].route, longRoute);
  assert.equal(checkpoint.captures[1].candidate_revision, CANDIDATE);
});

test("rejects an actual built/served CSS mismatch", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  manifest.captures[0].assets.served.sha256 = "3".repeat(64);

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)),
    /built\/served CSS identity mismatch/
  );
});

test("rejects incomplete capture provenance", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  delete manifest.captures[0].before_after.baseline_interaction_state;

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)),
    /before\/after baseline_interaction_state is missing/
  );
});

test("rejects baseline PNG dimensions that do not match declared capture dimensions", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  manifest.captures[0].before_after.baseline_capture_dimensions = "2x2";

  assert.throws(
    () => createCheckpoint(checkpointArgs(evidenceDir, report, manifest)),
    /baseline PNG dimensions do not match its viewport/
  );
});

function assertUploadContract(text) {
  const jobStart = text.indexOf("  demo_browser_evidence:");
  if (jobStart < 0) throw new Error("demo browser job is missing");
  const nextJob = text.indexOf("\n  [a-zA-Z0-9_-]+:\n", jobStart);
  const job = text.slice(jobStart, nextJob < 0 ? undefined : nextJob);
  const runStart = job.indexOf("      - name: Run demo browser evidence");
  const uploadStart = job.indexOf("      - name: Upload demo browser evidence artifact");
  if (runStart < 0 || uploadStart < runStart) throw new Error("evidence run/upload steps are missing or out of order");
  const runStep = job.slice(runStart, uploadStart);
  const uploadEnd = job.indexOf("\n      - name:", uploadStart + 1);
  const uploadStep = job.slice(uploadStart, uploadEnd < 0 ? undefined : uploadEnd);
  if (!/^        id: evidence$/m.test(runStep)) throw new Error("evidence run step needs an ID");
  if (!/^        if: steps\.evidence\.outcome == 'success'$/m.test(uploadStep)) throw new Error("upload must require successful evidence");
  if (!/^          if-no-files-found: error$/m.test(uploadStep)) throw new Error("upload must fail when retained files are missing");
  if (!/^          retention-days: 14$/m.test(uploadStep)) throw new Error("upload retention must remain 14 days");
  if (!/^          path: reference\/demo_app\/tmp\/demo_browser_evidence\/retained\/$/m.test(uploadStep)) {
    throw new Error("upload must select only the retained evidence directory");
  }
  if (/playwright-report|test-results|phase173-captures/.test(uploadStep)) throw new Error("raw browser output cannot be uploaded");
}

test("workflow uploads only retained evidence after successful evidence run", () => {
  const workflow = fs.readFileSync(workflowPath, "utf8");
  assert.doesNotThrow(() => assertUploadContract(workflow));
  const jobStart = workflow.indexOf("  demo_browser_evidence:");
  const nextJob = workflow.indexOf("\n  preview_capture_advisory:", jobStart);
  const job = workflow.slice(jobStart, nextJob);
  const mutations = [
    job.replace("if: steps.evidence.outcome == 'success'", "if: always()"),
    job.replace("if-no-files-found: error", "if-no-files-found: warn"),
    job.replace("retention-days: 14", "retention-days: 90"),
    job.replace("path: reference/demo_app/tmp/demo_browser_evidence/retained/", "path: reference/demo_app/tmp/demo_browser_evidence/playwright-report.json")
  ];
  for (const mutatedJob of mutations) {
    const mutatedWorkflow = workflow.slice(0, jobStart) + mutatedJob + workflow.slice(nextJob);
    assert.throws(() => assertUploadContract(mutatedWorkflow));
  }
});
