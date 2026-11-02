// Known-bad subject for GSD's independent fail-first proof. Never imported by production.
module.exports.reviewEvidence = () => ({
  execution: "passed", environment: "hosted", job: "demo_browser_evidence",
  tier: "required", required_ci_proof: true, owner_approval: true
});
