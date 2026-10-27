const assert = require("node:assert/strict");
const test = require("node:test");
const { validateCaseReceipts } = require("./check_phase175_evidence.cjs");

test("Phase 175 case receipts reject empty, missing, duplicate, unexpected, failed, and skipped execution", () => {
  const expected = ["demo:delivery-tracer", "admin:inbound-confirm"];
  assert.doesNotThrow(() => validateCaseReceipts(expected, expected.map(id => ({ id, status: "passed" })), "clean"));
  assert.throws(() => validateCaseReceipts([], [], "empty expected"), /expected case set is empty/);
  assert.throws(() => validateCaseReceipts(expected, [], "zero execution"), /executed case set is empty/);
  assert.throws(() => validateCaseReceipts(expected, [{ id: expected[0], status: "passed" }], "missing"), /missing executed case/);
  assert.throws(() => validateCaseReceipts(expected, [...expected.map(id => ({ id, status: "passed" })), { id: expected[0], status: "passed" }], "duplicate"), /duplicate executed case/);
  assert.throws(() => validateCaseReceipts(expected, [...expected.map(id => ({ id, status: "passed" })), { id: "extra", status: "passed" }], "unexpected"), /unexpected executed case/);
  assert.throws(() => validateCaseReceipts(expected, [{ id: expected[0], status: "failed" }, { id: expected[1], status: "passed" }], "failed"), /execution .* failed/);
  assert.throws(() => validateCaseReceipts(expected, [{ id: expected[0], status: "skipped" }, { id: expected[1], status: "passed" }], "skipped"), /execution .* skipped/);
});
