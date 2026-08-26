const fs = require("node:fs");
const path = require("node:path");

class TimeoutEvidenceReporter {
  constructor(options = {}) {
    this.outputFile =
      options.outputFile || path.join("test-results", "operator-browser-evidence.json");
    this.tests = [];
  }

  onTestEnd(test, result) {
    this.tests.push({
      title: test.titlePath().filter(Boolean).join(" > "),
      status: result.status,
      retry: result.retry,
      duration_ms: result.duration,
      stages: (result.stdout || [])
        .map(entry => entry.toString().trim())
        .filter(
          line =>
            line.startsWith("[gallery-matrix]") ||
            line.startsWith("[operator-browser-server]")
        ),
      attachments: (result.attachments || [])
        .filter(attachment => attachment.path)
        .map(attachment => ({
          name: attachment.name,
          file: path.basename(attachment.path),
          content_type: attachment.contentType
        }))
    });
  }

  async onEnd(result) {
    const evidence = {
      schema_version: 1,
      kind: "manifest",
      lane: "browser",
      run_id: process.env.GITHUB_RUN_ID || null,
      job: process.env.GITHUB_JOB || null,
      head_sha: process.env.GITHUB_SHA || null,
      event_name: process.env.GITHUB_EVENT_NAME || null,
      command:
        process.env.MAILGLASS_BROWSER_EVIDENCE_COMMAND || "npm run test:operator-browser",
      toolchain: {
        node: process.version,
        playwright: playwrightVersion()
      },
      captured_at: new Date().toISOString(),
      status: result.status,
      coverage: {
        widths: [320, 390, 768, 1440],
        themes: ["light", "dark", "system"],
        workers: 1
      },
      tests: this.tests
    };

    fs.mkdirSync(path.dirname(this.outputFile), { recursive: true });
    fs.writeFileSync(this.outputFile, `${JSON.stringify(evidence, null, 2)}\n`);
  }
}

function playwrightVersion() {
  try {
    return require("@playwright/test/package.json").version;
  } catch (_error) {
    return null;
  }
}

module.exports = TimeoutEvidenceReporter;
