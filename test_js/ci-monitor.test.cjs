const assert = require("node:assert/strict");
const test = require("node:test");

const { buildCommand } = require("../scripts/ci_monitor.cjs");

test("builds observable run-list and exact-run inspection commands", () => {
  assert.deepEqual(buildCommand(["runs", "--branch", "phase-163"]), [
    "run",
    "list",
    "--limit",
    "20",
    "--branch",
    "phase-163",
    "--json",
    "databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,url,createdAt"
  ]);

  assert.deepEqual(buildCommand(["inspect", "4242"]), [
    "run",
    "view",
    "4242",
    "--json",
    "databaseId,workflowName,headBranch,headSha,event,attempt,status,conclusion,url,jobs"
  ]);

  assert.deepEqual(buildCommand(["workflows"]), [
    "workflow",
    "list",
    "--all",
    "--json",
    "id,name,path,state"
  ]);
});

test("keeps watch fail-fast and failed-log operations exact-run scoped", () => {
  assert.deepEqual(buildCommand(["watch", "4242"]), [
    "run",
    "watch",
    "4242",
    "--exit-status",
    "--interval",
    "10"
  ]);

  assert.deepEqual(buildCommand(["log-failed", "4242"]), [
    "run",
    "view",
    "4242",
    "--log-failed"
  ]);

  assert.deepEqual(buildCommand(["job-log", "98259840268"]), [
    "run",
    "view",
    "--job",
    "98259840268",
    "--log"
  ]);

  assert.deepEqual(buildCommand(["artifacts", "4242"]), [
    "api",
    "repos/{owner}/{repo}/actions/runs/4242/artifacts?per_page=100"
  ]);

  assert.deepEqual(
    buildCommand([
      "artifact-download",
      "4242",
      "operator-browser-timeout-evidence-4242-node-22",
      "/tmp/phase-163-artifact"
    ]),
    [
      "run",
      "download",
      "4242",
      "--name",
      "operator-browser-timeout-evidence-4242-node-22",
      "--dir",
      "/tmp/phase-163-artifact"
    ]
  );
});

test("inspects exact PR identity and check rollup without mutating it", () => {
  assert.deepEqual(buildCommand(["pr-inspect", "228"]), [
    "pr",
    "view",
    "228",
    "--json",
    "number,state,isDraft,headRefName,headRefOid,baseRefName,url,statusCheckRollup"
  ]);

  assert.deepEqual(
    buildCommand(["pr-set-title", "228", "ci(163): automate timeout proof"]),
    ["pr", "edit", "228", "--title", "ci(163): automate timeout proof"]
  );
});

test("builds a bounded PR creation command without an inline body", () => {
  assert.deepEqual(
    buildCommand([
      "pr-create",
      "--base",
      "main",
      "--head",
      "phase-163",
      "--title",
      "Phase 163 timeout repairs",
      "--body-file",
      "/tmp/phase-163-pr.md"
    ]),
    [
      "pr",
      "create",
      "--base",
      "main",
      "--head",
      "phase-163",
      "--title",
      "Phase 163 timeout repairs",
      "--body-file",
      "/tmp/phase-163-pr.md"
    ]
  );
});

test("rejects unknown commands and malformed identifiers", () => {
  assert.throws(() => buildCommand(["inspect", "not-a-run"]), /positive integer/);
  assert.throws(() => buildCommand(["pr-inspect", "0"]), /positive integer/);
  assert.throws(() => buildCommand(["runs", "--limit", "500"]), /unknown argument/);
  assert.throws(() => buildCommand(["dispatch"]), /unknown command/);
});
