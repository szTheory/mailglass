const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const TimeoutEvidenceReporter = require("../e2e/support/timeout-evidence-reporter.cjs");

test("writes a versioned, non-sensitive browser timeout report", async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-browser-evidence-"));
  const outputFile = path.join(root, "operator-browser-evidence.json");
  const previous = {
    GITHUB_RUN_ID: process.env.GITHUB_RUN_ID,
    GITHUB_JOB: process.env.GITHUB_JOB,
    GITHUB_SHA: process.env.GITHUB_SHA,
    GITHUB_EVENT_NAME: process.env.GITHUB_EVENT_NAME
  };

  process.env.GITHUB_RUN_ID = "5252";
  process.env.GITHUB_JOB = "operator_browser_gate";
  process.env.GITHUB_SHA = "b".repeat(40);
  process.env.GITHUB_EVENT_NAME = "pull_request";

  try {
    const reporter = new TimeoutEvidenceReporter({ outputFile });

    reporter.onTestEnd(
      { titlePath: () => ["gallery matrix", "every specimen renders"] },
      {
        status: "timedOut",
        retry: 0,
        duration: 30_300,
        stdout: [
          Buffer.from("[gallery-matrix] stage=matrix_discovered cells=87\n"),
          Buffer.from("recipient=private@example.test secret payload\n")
        ],
        attachments: [
          {
            name: "trace",
            path: "/tmp/test-results/gallery/trace.zip",
            contentType: "application/zip"
          }
        ],
        errors: [{ message: "recipient=private@example.test secret payload" }]
      }
    );

    await reporter.onEnd({ status: "failed" });

    const evidence = JSON.parse(fs.readFileSync(outputFile, "utf8"));

    assert.deepEqual(
      {
        schema_version: evidence.schema_version,
        kind: evidence.kind,
        lane: evidence.lane,
        run_id: evidence.run_id,
        job: evidence.job,
        head_sha: evidence.head_sha,
        event_name: evidence.event_name,
        status: evidence.status
      },
      {
        schema_version: 1,
        kind: "manifest",
        lane: "browser",
        run_id: "5252",
        job: "operator_browser_gate",
        head_sha: "b".repeat(40),
        event_name: "pull_request",
        status: "failed"
      }
    );

    assert.deepEqual(evidence.tests, [
      {
        title: "gallery matrix > every specimen renders",
        status: "timedOut",
        retry: 0,
        duration_ms: 30_300,
        stages: ["[gallery-matrix] stage=matrix_discovered cells=87"],
        attachments: [
          {
            name: "trace",
            file: "trace.zip",
            content_type: "application/zip"
          }
        ]
      }
    ]);

    assert.equal(JSON.stringify(evidence).includes("private@example.test"), false);
    assert.equal(JSON.stringify(evidence).includes("secret payload"), false);
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }

    fs.rmSync(root, { recursive: true, force: true });
  }
});
