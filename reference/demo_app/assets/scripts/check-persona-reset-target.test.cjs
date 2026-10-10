const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const { resetDisposableEvidence } = require("./check-persona-reset-target.cjs");
const ROOT = path.resolve(__dirname, "../..");
const RUN_ID = "mailglass-evidence-20261010093046-123-456";

function requestFixture({ healthStatus = 200, marker = RUN_ID } = {}) {
  const calls = [];
  return {
    calls,
    request: {
      async get(url, options) {
        calls.push({ method: "GET", url, options });
        return {
          status: () => healthStatus,
          headers: () => ({ "x-mailglass-evidence-project-id": marker })
        };
      },
      async post(url, options) {
        calls.push({ method: "POST", url, options });
        return { ok: () => true, status: () => 200 };
      }
    }
  };
}

test("reset checks health identity then posts to the same explicit local origin", async () => {
  const { calls, request } = requestFixture();
  const response = await resetDisposableEvidence(request, {
    DEMO_BASE_URL: "http://127.0.0.1:4015",
    DEMO_EVIDENCE_RUN_ID: RUN_ID,
    DEMO_EVIDENCE_RESET_TOKEN: "secret-token"
  });

  assert.equal(response.status(), 200);
  assert.deepEqual(calls.map(({ method }) => method), ["GET", "POST"]);
  assert.equal(calls[0].url, "http://127.0.0.1:4015/health");
  assert.equal(calls[0].options.maxRedirects, 0);
  assert.equal(calls[1].url, "http://127.0.0.1:4015/demo/evidence/reset");
  assert.equal(calls[1].options.headers["x-mailglass-demo-reset-token"], "secret-token");
});

for (const [name, env, healthOptions] of [
  ["missing base URL", { DEMO_EVIDENCE_RUN_ID: RUN_ID, DEMO_EVIDENCE_RESET_TOKEN: "token" }, {}],
  ["remote base URL", { DEMO_BASE_URL: "https://example.com", DEMO_EVIDENCE_RUN_ID: RUN_ID, DEMO_EVIDENCE_RESET_TOKEN: "token" }, {}],
  ["missing run ID", { DEMO_BASE_URL: "http://demo:4015", DEMO_EVIDENCE_RESET_TOKEN: "token" }, {}],
  ["missing reset token", { DEMO_BASE_URL: "http://demo:4015", DEMO_EVIDENCE_RUN_ID: RUN_ID }, {}],
  ["missing health marker", { DEMO_BASE_URL: "http://demo:4015", DEMO_EVIDENCE_RUN_ID: RUN_ID, DEMO_EVIDENCE_RESET_TOKEN: "token" }, { marker: null }],
  ["mismatched health marker", { DEMO_BASE_URL: "http://demo:4015", DEMO_EVIDENCE_RUN_ID: RUN_ID, DEMO_EVIDENCE_RESET_TOKEN: "token" }, { marker: "mailglass-evidence-20261010093046-123-999" }],
  ["redirected health response", { DEMO_BASE_URL: "http://demo:4015", DEMO_EVIDENCE_RUN_ID: RUN_ID, DEMO_EVIDENCE_RESET_TOKEN: "token" }, { healthStatus: 302 }]
]) {
  test(`rejects ${name} before reset POST`, async () => {
    const { calls, request } = requestFixture(healthOptions);
    await assert.rejects(resetDisposableEvidence(request, env));
    assert.equal(calls.some(({ method }) => method === "POST"), false);
  });
}

function assertProducerUsesGuardedReset(source, label) {
  assert.match(source, /require\(["']\.\.\/scripts\/check-persona-reset-target\.cjs["']\)/, `${label}: helper import`);
  assert.match(source, /test\.beforeEach\s*\(\s*async\s*\(\s*\{\s*request\s*\}\s*\)\s*=>\s*\{[\s\S]*?resetDisposableEvidence\s*\(\s*request/, `${label}: guarded beforeEach call`);
  assert.doesNotMatch(source, /request\.post\s*\(\s*["']\/demo\/evidence\/reset/, `${label}: direct reset POST`);
}

test("both browser evidence producers use the shared guarded reset before each test", () => {
  for (const filename of ["persona-screenshots.spec.js", "phase173-evidence.spec.js"]) {
    const source = fs.readFileSync(path.join(ROOT, "assets/e2e", filename), "utf8");
    assertProducerUsesGuardedReset(source, filename);
  }
});

test("producer source contract rejects missing helper import", () => {
  const source = fs.readFileSync(path.join(ROOT, "assets/e2e/phase173-evidence.spec.js"), "utf8");
  const mutated = source.replace(/const \{ resetDisposableEvidence \} = require\([^\n]+\);\n/, "");
  assert.throws(() => assertProducerUsesGuardedReset(mutated, "mutated spec"));
});

test("producer source contract rejects missing beforeEach guard", () => {
  const source = fs.readFileSync(path.join(ROOT, "assets/e2e/phase173-evidence.spec.js"), "utf8");
  const mutated = source.replace(/test\.beforeEach\([\s\S]*?\n\}\);\n/, "");
  assert.throws(() => assertProducerUsesGuardedReset(mutated, "mutated spec"));
});

test("producer source contract rejects a direct reset POST", () => {
  const source = fs.readFileSync(path.join(ROOT, "assets/e2e/phase173-evidence.spec.js"), "utf8");
  const mutated = source.replace(
    "await resetDisposableEvidence(request);",
    'await request.post("/demo/evidence/reset", {});'
  );
  assert.throws(() => assertProducerUsesGuardedReset(mutated, "mutated spec"));
});
