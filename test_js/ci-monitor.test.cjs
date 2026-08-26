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
    "databaseId,workflowName,headBranch,headSha,event,status,conclusion,url,createdAt"
  ]);

  assert.deepEqual(buildCommand(["inspect", "4242"]), [
    "run",
    "view",
    "4242",
    "--json",
    "databaseId,workflowName,headBranch,headSha,event,status,conclusion,url,jobs"
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
  assert.throws(() => buildCommand(["runs", "--limit", "500"]), /unknown argument/);
  assert.throws(() => buildCommand(["dispatch"]), /unknown command/);
});
