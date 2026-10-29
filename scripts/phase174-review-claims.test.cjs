const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");
const subject = process.env.GSD_PROHIB_SUBJECT
  ? path.resolve(process.env.GSD_PROHIB_SUBJECT)
  : path.join(__dirname, "phase174-review-claims.cjs");
const { reviewEvidence } = require(subject);
const counts = { demo: 98, hooks: 6, fidelity: 26, axe: 18, total: 148 };
const evidence = () => ({ valid: true, conditions: {
  cold: { expected: counts, executed: counts, axe: { valid: true } },
  warm: { expected: counts, executed: counts, axe: { valid: true } }
}, hosted_job: null });

test("executed advisory evidence never claims required CI or owner approval", () => {
  for (const hosted of [null, { run_id: "123", job_id: "456" }]) {
    assert.deepEqual(reviewEvidence({ ...evidence(), hosted_job: hosted }), {
      execution: "passed", environment: hosted ? "hosted" : "local",
      job: "demo_browser_evidence", tier: "advisory",
      required_ci_proof: false, owner_approval: false
    });
  }
});

test("unexecuted, failed, zero-case and partial evidence cannot produce a passing review", () => {
  for (const candidate of [null, {}, { ...evidence(), valid: false },
    { ...evidence(), conditions: {} },
    { ...evidence(), conditions: { cold: { expected: { ...counts, axe: 0 }, executed: counts, axe: { valid: true } } } },
    { ...evidence(), conditions: { cold: { expected: counts, executed: { ...counts, axe: 17 }, axe: { valid: true } } } },
    { ...evidence(), conditions: { cold: { expected: counts, executed: counts, axe: { valid: false } } } }
  ]) assert.throws(() => reviewEvidence(candidate), /complete successful execution/);
});
