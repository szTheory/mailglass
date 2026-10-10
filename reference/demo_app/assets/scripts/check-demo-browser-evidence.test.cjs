const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const { createCheckpoint } = require("./check-demo-browser-evidence.cjs");
const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lN8AAAAASUVORK5CYII=",
  "base64"
);

function fixture(evidenceDir, attachmentPath) {
  const capturePath = path.join(evidenceDir, "preview.png");
  fs.writeFileSync(capturePath, png);
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
  return {
    report,
    manifest: {
      captures: [
        {
          test_title: "current preview route",
          path: attachmentPath ? path.relative(evidenceDir, attachmentPath) : "preview.png",
          candidate_revision: "1f84f510fcf6e80799fa99027bd1a33b186f47fa"
        }
      ]
    }
  };
}

test("accepts one current capture and hashes its PNG bytes", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const { report, manifest } = fixture(evidenceDir);
  const checkpoint = createCheckpoint({
    report,
    manifest,
    evidenceDir,
    candidateRevision: "1f84f510fcf6e80799fa99027bd1a33b186f47fa"
  });

  assert.equal(checkpoint.status, "passed");
  assert.equal(checkpoint.captures.length, 1);
  assert.equal(
    checkpoint.captures[0].sha256,
    crypto.createHash("sha256").update(png).digest("hex")
  );
});

test("rejects a report with zero current captures", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const report = { suites: [] };
  const manifest = { captures: [] };

  assert.throws(
    () => createCheckpoint({ report, manifest, evidenceDir, candidateRevision: "1f84f510" }),
    /exactly one current capture/
  );
});

test("rejects a missing PNG", (t) => {
  const evidenceDir = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-evidence-"));
  t.after(() => fs.rmSync(evidenceDir, { recursive: true, force: true }));
  const missingPath = "missing.png";
  const { report, manifest } = fixture(evidenceDir, path.join(evidenceDir, missingPath));

  assert.throws(
    () =>
      createCheckpoint({
        report,
        manifest,
        evidenceDir,
        candidateRevision: "1f84f510fcf6e80799fa99027bd1a33b186f47fa"
      }),
    /missing or invalid PNG/
  );
});

test("rejects paths outside the run-owned evidence directory", (t) => {
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
    () =>
      createCheckpoint({
        report,
        manifest,
        evidenceDir,
        candidateRevision: "1f84f510fcf6e80799fa99027bd1a33b186f47fa"
      }),
    /outside the owned evidence directory/
  );
});
