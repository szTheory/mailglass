# Phase 184: Close Admin and docs browser evidence gaps - Context

**Gathered:** 2026-11-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the observed v2.11 candidate gate failures and the remaining current Admin journey/reviewer and generated-doc browser evidence gaps. Phase 184 gets one closure plan and one new exact-SHA hosted candidate route based on `a295e9a950e14d7ce3ec9456f31fbda864933580`. It does not change the product scope or the prior Phase 182-07 stop.

</domain>

<decisions>
## Implementation Decisions

### Candidate and approval boundary
- **D-01:** Keep Phase 182-07 blocked and unchanged. Phase 184 owns any new repair or candidate attempt.
- **D-02:** Use the isolated candidate checkout at exact base SHA `a295e9a950e14d7ce3ec9456f31fbda864933580`; keep owner changes in the main checkout untouched.
- **D-03:** One candidate branch push and one hosted `workflow_dispatch` are authorized. No retries, reruns, third candidate preview, PR, main push, merge, release, deploy, tag, milestone archive, or additional plan expansion.
- **D-04:** Before dispatch, require cheap local consistency checks and targeted preflights to pass. The hosted route must produce a matching formal cost receipt, all required checks green, the exact expected test count, no more than +5 minutes wall time and +10 minutes runner time against the approved baseline. Any missing receipt, count mismatch, failed gate, or limit breach stops the phase before preview.

### Browser and evidence handling
- **D-05:** Keep existing Playwright and browser-image versions; add no dependency, install, image pull, or retry. Use the already available Playwright 1.65.1 image for the Admin and docs browser work.
- **D-06:** Repair the Demo Admin runtime mismatch with a supported Node runtime and an explicit inexpensive version preflight; preserve the Phase 174 Node 18 / Playwright 1.60 contract.
- **D-07:** Diagnose the preview Axe `Target.createTarget` timeouts in one bounded, zero-retry local browser cell. Do not mask them by extending timeouts or weakening Axe assertions.
- **D-08:** Run docs browser assertions against the same generated output directories produced by the docs build, using the existing pinned browser image. Preserve generated-output and package contracts.
- **D-09:** Only after passing exact-SHA hosted and cost gates, run the one authorized candidate-owned isolated Admin preview and current 375px light/dark journey, then collect two independent reviews. Clean only resources created for this route and confirm owner-demo resources remain unchanged.

### Protected inputs and discretion
- **D-10:** Preserve the stop against favicon recapture while its source-hash mismatch remains unresolved. Do not alias a different producer or alter protected source bytes to force a pass.
- **D-11:** No new product behavior, data capture, backend capability, dependency, or broad workflow redesign is in this phase.

### The agent's Discretion
Choose the smallest implementation that satisfies these boundaries, follows existing repository patterns, and preserves provenance. Keep source edits and execution in the isolated checkout; planning/evidence updates must be scoped to Phase 184 and related v2.11 audit artifacts.

</decisions>

<canonical_refs>
## Canonical References

### Milestone scope and constraints
- `.planning/ROADMAP.md` — v2.11 requirements, phase 184 scope, plan cap, and phase success criteria.
- `.planning/REQUIREMENTS.md` — BRADM and BRDOC acceptance requirements and traceability.
- `.planning/AUTONOMOUS-PLAYBOOK.md` — candidate, verification, cost, privacy, and cleanup gates.
- `.planning/research/brand-v2-adoption/BRPOL-04-PIN-DECISION.md` — milestone plan-cap authorization and limits of the closure expansion.

### Prior exact-candidate evidence
- `.planning/phases/182-admin-words-and-layout-one-job-first/182-07-CHECK.md` — Phase 182 stop, exact candidate boundary, and prior route outcomes.
- `.planning/phases/183-docs-packaging-and-launch-prep/183-VERIFICATION.md` — docs phase status and open browser evidence.
- `.planning/research/brand-v2-adoption/admin-current-evidence/current-a295e9a-20261118T074427Z/hosted-run-report.md` — candidate run 44261984013 results and artifact references.
- `.planning/research/brand-v2-adoption/INTEGRATION-v2.11-20261118.md` — cross-phase evidence and remaining closure gaps.

### Existing implementation paths
- `scripts/run_demo_browser_evidence.sh` — Demo browser evidence and cost-record generation.
- `scripts/gsd-regression-gate.sh` — existing pinned Docker browser runner and resource limits.
- `scripts/verify_brand_docs.sh` — docs build/output and browser-contract flow.
- `mailglass_admin/e2e/docs-theme-contract.cjs` — same-output browser assertions.
- `mailglass_admin/playwright.config.cjs` and `mailglass_admin/e2e/axe-baseline.spec.js` — Admin preview test configuration and Axe checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has a Playwright 1.65.1 Docker browser path with zero retries and strict resource limits.
- `scripts/run_demo_browser_evidence.sh` writes phase cost and browser evidence records; the prior failed run omitted the required Phase 174 cost file.
- `scripts/verify_brand_docs.sh` already builds all three docs packages and checks their outputs before running browser assertions.

### Established Patterns
- Candidate evidence is bound to a source SHA and digest; preserve those bindings through the single route.
- Browser launch failures on macOS use the existing pinned Docker path, not a new browser installation.
- Keep the Phase 174 Node 18 / Playwright 1.60 suite separate from Phase 175 Admin Playwright 1.65.1 runtime requirements.

### Integration Points
- Candidate source changes are made in the isolated checkout and flow through one branch push and exact-SHA GitHub workflow dispatch.
- Phase 182 current Admin evidence, Phase 183 docs browser evidence, cost disposition, and the milestone audit consume the resulting same-candidate artifacts.

</code_context>

<specifics>
## Specific Ideas

Use cheap formatter, fixture, Credo, runtime-version, selector/readiness, and local browser preflights before the long hosted workflow. Diagnose the browser target-creation seam first; do not rerun full suites or hosted jobs merely to inspect timing. Base all later claims on the exact one-run artifacts.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the owner-approved closure scope.

</deferred>

---

*Phase: 184-Close Admin and docs browser evidence gaps*
*Context gathered: 2026-11-18*
