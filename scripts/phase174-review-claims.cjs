const fs = require("node:fs");
const path = require("node:path");

// This is the public review summary boundary, used by the evidence checker.
// Execution success cannot grant CI authority or an owner's approval.
function reviewEvidence(evidence) {
  const conditions = Object.values(evidence?.conditions || {});
  const keys = ["demo", "hooks", "fidelity", "axe", "total"];
  if (evidence?.valid !== true || conditions.length === 0 || conditions.some(item =>
    keys.some(key => !Number.isInteger(item.expected?.[key]) || item.expected[key] <= 0 ||
      item.executed?.[key] !== item.expected[key]) || item.axe?.valid !== true
  )) throw new Error("Review claims require complete successful execution");

  const root = path.resolve(__dirname, "..");
  const policy = fs.readFileSync(path.join(root, "config/quality/ci_policy.exs"), "utf8");
  const workflow = fs.readFileSync(path.join(root, ".github/workflows/ci.yml"), "utf8");
  const advisory = policy.match(/advisory:\s*\[([\s\S]*?)\]/)?.[1] || "";
  const required = policy.match(/active_required:\s*\[([\s\S]*?)\]/)?.[1] || "";
  const aggregate = workflow.match(/^  ci_green:\n([\s\S]*?)(?=^  [a-z_]+:|$(?![\s\S]))/m)?.[1] || "";
  if (!advisory.includes('"demo_browser_evidence"') || required.includes('"demo_browser_evidence"') ||
      /^\s+- demo_browser_evidence\s*$/m.test(aggregate)) {
    throw new Error("Demo evidence CI placement changed; reconcile the review contract");
  }
  return {
    execution: "passed",
    environment: evidence.hosted_job ? "hosted" : "local",
    job: "demo_browser_evidence",
    tier: "advisory",
    required_ci_proof: false,
    owner_approval: false
  };
}

module.exports = { reviewEvidence };
