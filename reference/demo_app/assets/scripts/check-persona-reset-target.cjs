const SAFE_HOSTS = new Set(["127.0.0.1", "localhost", "demo"]);
const PROJECT_ID = /^mailglass-evidence-[0-9]{14}-[0-9]+-[0-9]+$/;

function evidenceOrigin(env) {
  const raw = env.DEMO_BASE_URL;
  if (typeof raw !== "string" || raw.length === 0) {
    throw new Error("DEMO_BASE_URL must explicitly identify the local evidence demo");
  }

  let url;
  try {
    url = new URL(raw);
  } catch {
    throw new Error("DEMO_BASE_URL is not a valid local origin");
  }

  if (
    url.protocol !== "http:" ||
    !SAFE_HOSTS.has(url.hostname) ||
    url.username !== "" ||
    url.password !== "" ||
    url.pathname !== "/" ||
    url.search !== "" ||
    url.hash !== ""
  ) {
    throw new Error("DEMO_BASE_URL must be a plain local or container demo origin");
  }

  return url.origin;
}

async function resetDisposableEvidence(request, env = process.env) {
  const origin = evidenceOrigin(env);
  const runId = env.DEMO_EVIDENCE_RUN_ID;
  const token = env.DEMO_EVIDENCE_RESET_TOKEN;
  if (typeof runId !== "string" || !PROJECT_ID.test(runId)) {
    throw new Error("DEMO_EVIDENCE_RUN_ID is missing or unsafe");
  }
  if (typeof token !== "string" || token.length === 0) {
    throw new Error("DEMO_EVIDENCE_RESET_TOKEN is missing");
  }

  const health = await request.get(`${origin}/health`, { maxRedirects: 0 });
  const healthUrl = new URL(`${origin}/health`);
  if (health.status() !== 200 || new URL(healthUrl).origin !== origin) {
    throw new Error(`evidence demo health preflight failed (${health.status()})`);
  }

  const marker = health.headers()["x-mailglass-evidence-project-id"];
  if (marker !== runId) {
    throw new Error("evidence demo project identity does not match this run");
  }

  const response = await request.post(`${origin}/demo/evidence/reset`, {
    headers: { "x-mailglass-demo-reset-token": token },
    maxRedirects: 0
  });
  if (!response.ok()) {
    throw new Error(`demo reset failed (${response.status()}) after identity preflight`);
  }
  return response;
}

module.exports = { resetDisposableEvidence };
