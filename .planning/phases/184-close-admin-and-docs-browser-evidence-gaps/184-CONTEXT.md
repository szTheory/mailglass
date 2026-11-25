# Phase 184: Close Admin and docs browser evidence gaps - Context

**Gathered:** 2026-11-18
**Status:** Recovery scope authorized; ready for planning

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

### Recovery scope after the Phase 184-01 preflight stop
- **D-12:** The owner authorizes exactly one additional gap-closure plan, `184-02`, raising the v2.11 plan cap from 25 to 26. No further plan expansion is authorized.
- **D-13:** Plan 184-01 stays blocked and immutable; do not retry its failed command or switch its execution boundary. Plan 184-02 may prepare one fresh exact-SHA candidate route from `a295e9a950e14d7ce3ec9456f31fbda864933580`, with at most one branch push, one matching `workflow_dispatch`, and one conditional preview only after every hosted/count/cost gate passes. No retries, reruns, second route, over-budget CI, or third-party publication.
- **D-14:** Before any source edit or Mix/browser action in plan 184-02, implement and fixture-test a Node-built-in-only evidence helper and capture complete pre-edit owner/protected per-path baselines plus separately hashed report-target preimages. The helper must fail closed on missing/tampered inputs, re-compute hashes from retained manifests, and bind source identity to retained Git content. The 184-01 digest-only assertions remain historical claims; do not retrofit them into a successful `verify-all` result.
- **D-15:** Use an isolated candidate clone and candidate-owned dependency snapshots for all four Mix projects. The existing owner dependency trees total about 133 MiB and are on the same APFS volume as `/private/tmp`; `cp -c` is a candidate snapshot option, not yet validated. Before Mix, verify byte-identical locks, exact file/mode/content inventories, no symlink or hard-link escape into owner trees, candidate-root containment, and read-only candidate dependency snapshots. Set the approved Elixir/OTP versions explicitly and keep every build path candidate-owned. Do not run `mix deps.get`, install packages, pull/build images, use shared owner deps after startup, or escalate permissions. If snapshot creation, read-only enforcement, inventory, or path checks fail, stop before Mix and all hosted work.
- **D-16:** Distinguish `CI Green`'s policy-required jobs from the separate advisory Demo Browser Evidence and Operator Browser Gate workflows; Phase 184-02 still requires both browser workflows to pass independently. Freeze the 356-case Operator inventory (355 pass, one named guarded skip, zero failures/flaky) and the Demo 169-case cold and warm counts (111 demo, 6 hooks, 26 fidelity, 26 Axe). Require the formal `phase178-cost-disposition.v1` receipt with seven input hashes, baseline run `40414024714`, wall time at most 1,541 seconds and runner time at most 110.68333333333334 minutes; both budget flags must pass and count-mismatch flags must be false. Missing or failing gates stop before preview.
- **D-17:** Keep the Phase 182-07 stop, favicon source-hash/capture stop, owner WIP, and owner-demo services unchanged throughout plan 184-02.
- **D-18:** On 2026-11-18 the owner authorizes exactly one additional Phase 184 plan, `184-03`, raising the v2.11 plan cap from 26 to 27. Its scope is limited to fixing and verifying the candidate-absent `verify-all` defect using isolated synthetic fixtures and the retained 184-02 helper. This does not authorize a real dependency snapshot, Mix, product/source repair, browser/container launch, branch push, workflow dispatch, preview, or another candidate route. Plan 184-02 remains consumed; preserve its failure evidence and the 184-01/182-07/favicon stops. No further plan expansion is authorized.

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
