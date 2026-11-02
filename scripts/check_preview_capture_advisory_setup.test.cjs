const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const workflow = fs.readFileSync(
  path.join(__dirname, "..", ".github", "workflows", "ci.yml"),
  "utf8"
);
const watcherInstall = "sudo apt-get install --yes --no-install-recommends inotify-tools";

function jobBlock(name) {
  const start = workflow.search(new RegExp(`^  ${name}:\\s*$`, "m"));
  assert.notEqual(start, -1, `missing workflow job: ${name}`);

  const rest = workflow.slice(start + 1);
  const nextJob = rest.search(/^  [a-zA-Z0-9_-]+:\s*$/m);
  return workflow.slice(start, nextJob === -1 ? undefined : start + 1 + nextJob);
}

test("Preview Capture Advisory installs its Linux watcher before server startup", () => {
  const advisory = jobBlock("preview_capture_advisory");
  const playwright = advisory.indexOf("      - name: Install Playwright browser");
  const install = advisory.indexOf(`        run: ${watcherInstall}`);
  const server = advisory.indexOf("      - name: Start deterministic preview capture server");

  assert.notEqual(playwright, -1, "missing Playwright dependency setup");
  assert.notEqual(install, -1, "missing job-scoped inotify-tools installation");
  assert.notEqual(server, -1, "missing deterministic preview server startup");
  assert.ok(playwright < install && install < server, "watcher install must precede server startup");
  assert.equal(workflow.split(watcherInstall).length - 1, 1, "watcher install must remain scoped to one job");
});

test("Demo Browser Evidence runs the advisory setup contract", () => {
  const demo = jobBlock("demo_browser_evidence");
  assert.ok(demo.includes("scripts/check_preview_capture_advisory_setup.test.cjs"));
});
