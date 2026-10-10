---
phase: 173-consistency-and-delivery-evidence
verified: 2026-10-10T13:58:01Z
status: gaps_found
score: 24/27 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/173-consistency-and-delivery-evidence/173-01-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-01-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-02-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-02-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-03-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-03-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-04-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-04-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-05-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-05-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-06-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-06-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-07-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-07-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-08-PLAN.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-08-SUMMARY.md
  - .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md
  - Makefile
  - compose.demo.yml
  - guides/run-the-demo.md
  - mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex
  - mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex
  - mailglass_admin/docs/design-system.md
  - mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs
  - reference/demo_app/Dockerfile
  - reference/demo_app/assets/e2e/persona-screenshots.spec.js
  - reference/demo_app/assets/e2e/phase173-evidence.spec.js
  - reference/demo_app/assets/scripts/check-demo-browser-deps.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-deps.test.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.cjs
  - reference/demo_app/assets/scripts/check-persona-reset-target.test.cjs
  - reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs
  - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
  - reference/demo_app/mix.exs
  - reference/demo_app/storybook/primitives/theme_picker.story.exs
  - reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs
  - reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
  - scripts/check_phase173_candidate.sh
  - scripts/phase173_json_output.cjs
  - scripts/phase173_json_output.py
  - scripts/run_demo_browser_evidence.sh
  - scripts/test_check_phase173_candidate.sh
  - scripts/test_run_demo_browser_evidence.sh
covered_digest: "v3:sha256:b46d3260fc8a5e6ca99e3cad461e80bcb69a2d98cd5aa8717c9dd0b0b8b49325"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 24/27
  gaps_closed: []
  gaps_remaining:
    - "Roadmap SC3/UIQ-03 remains incomplete: the full gate was skipped for current code SHA 4994442105315afdaa71beba73f6ab85e40f8533; exact-SHA required CI and owner acceptance are outstanding."
  regressions: []
gaps:
  - truth: "Roadmap SC3: The owner can review the completed milestone from a documented working candidate with required CI, committed acceptance inputs, current assets, and explicit resource disposition."
    status: failed
    reason: "Current code SHA 4994442105315afdaa71beba73f6ab85e40f8533 has no full candidate-gate result. The last locally green gate was for older SHA a7fd4843d17c2bf201fb1366c588d65af0f22c3d. Exact-SHA required CI and authorized owner acceptance are unavailable; historical checks do not establish this candidate's delivery readiness."
    artifacts:
      - path: reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
        issue: "status is incomplete; ci.runs is empty; ownerAcceptance.status is unverified; fullDeliveryGate.status is not-run."
      - path: scripts/check_phase173_candidate.sh
        issue: "The full candidate gate and regression gate were skipped for current code SHA 4994442105315afdaa71beba73f6ab85e40f8533 because the allowed hard fence did not establish that the gate's Docker/test-discovery scope avoids protected inputs."
      - path: reference/demo_app/README.md
        issue: "Protected owner acceptance remains unverified under the hard fence; no claim is made."
    missing:
      - "A successful required CI Green result whose headSha is exactly 4994442105315afdaa71beba73f6ab85e40f8533."
      - "Authorized owner acceptance and a full delivery-gate result for the current candidate from a demonstrably protected-path-safe context."
  - truth: "UIQ-03/D-08: Required CI Green passes for the exact final committed delivery candidate, separately from advisory browser/capture jobs."
    status: failed
    reason: "Exact-SHA CI Green is unavailable for current code SHA 4994442105315afdaa71beba73f6ab85e40f8533; the prior CI check was tied to an older candidate."
    artifacts:
      - path: reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
        issue: "The required job is named, but ci.runs is empty and ci.status is not-found."
    missing:
      - "A successful required CI Green run with headSha 4994442105315afdaa71beba73f6ab85e40f8533."
  - truth: "UIQ-03/D-05/D-10: The live full candidate delivery gate passes its required local, evidence, owner-acceptance, and exact-SHA CI predicates."
    status: failed
    reason: "The full candidate gate and regression gate were skipped for the current code SHA because the workflow may discover or consume a protected path. The older gate result at a7fd4843d17c2bf201fb1366c588d65af0f22c3d is historical evidence only."
    artifacts:
      - path: reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
        issue: "localChecks.fullDeliveryGate.status is not-run; localChecks.status is partial."
    missing:
      - "A full delivery-gate result for the current SHA from a demonstrably protected-path-safe execution context."
must_haves:
  truths:
    - "Roadmap SC1: A maintainer can find delivered shared patterns and applicable states in the existing gallery/Storybook and current design-system guidance, with clear token ownership and no obsolete rule competing with the shipped pattern."
    - "Roadmap SC2: A maintainer can repeat focused existing checks and inspect source-identified before/after renders of changed primary flows and adverse states, with browser, email-client, and historical-score evidence clearly distinguished."
    - "Roadmap SC3: The owner can open a documented working preview of the completed milestone and review a concise task-based walkthrough; the delivery candidate has passing required CI, current generated assets, committed task-owned changes, and disposed or explicitly retained temporary artifacts/services."
    - "UIQ-02/D-04/D-05: One current candidate can be driven through a synthetic demo route, semantic and geometry assertions, a bounded screenshot, and a fail-closed provenance checkpoint."
    - "UIQ-02/D-06: Each current browser capture states its route, scenario, theme, viewport, interaction state, browser, before/after relation, actual PNG digest, candidate revision and source/build/served asset identity; browser claims do not imply email-client behavior."
    - "UIQ-03/D-07/D-09: The evidence run starts and cleans only its own uniquely named Compose project with its own host ports, leaving the retained demo and unrelated services intact."
    - "UIQ-01/D-01: Current design guidance accurately describes the shipped Admin CSS and brand token ownership, with no obsolete color/size/visual-score rule competing."
    - "UIQ-01/D-02/D-03: The comprehensive Admin Gallery and curated demo Storybook are discoverable, use overlapping examples and themes consistently, and still load the committed Admin CSS without a second catalog or stylesheet."
    - "UIQ-02/D-05/D-06: Admin preview manifests distinguish deterministic dry-run identity from actual screenshot-byte proof, reject incomplete current evidence, and state the browser/email-client limit."
    - "UIQ-03/D-07: The owner can open the retained final-candidate preview and a task-based walkthrough while the older feedback preview remains intact."
    - "UIQ-03/D-08: Required CI Green passes for the exact final delivery candidate, separately from advisory jobs, with no branch-protection change."
    - "UIQ-03/D-09: Source and generated assets are current; task-owned changes are committed; temporary evidence resources are disposed or explicitly retained with their disposition."
    - "UIQ-03/D-09: The candidate worktree is detached, clean, exact, contains committed phase work, and excludes recorded owner dirt without copying it."
    - "D-10/D-11: Machine-observable readiness, candidate identity, CI status, and cleanup are checked automatically; no merge or publication occurs."
    - "UIQ-02/D-04/D-05/D-06/D-09/D-10: Successful browser evidence retains only a validated synthetic checkpoint and allowlisted PNG pairs; failed runs leave no uploadable directory, while raw Playwright output stays ephemeral."
    - "UIQ-02/D-05/D-10: Both Admin actual-capture writer paths reject build/served CSS digest mismatch."
    - "UIQ-02/D-06/D-10: CI Admin capture requires exactly the synthetic HappyMailer module; local discovery and explicit-module behavior remain supported."
    - "UIQ-02/UIQ-03/D-08/D-10/D-11: The offline exact-lock package legitimacy gate runs before every demo browser npm ci, and the existing advisory CI job audits that lock."
    - "UIQ-02/D-06/D-07/D-09/D-10: The evidence reset rejects token-only requests on the retained demo and both capture producers verify the disposable target before POST."
    - "UIQ-02/UIQ-03/D-05/D-06/D-08/D-10: The outer gate validates and transfers only six pinned synthetic baselines, then rechecks the sanitized checkpoint and allowlisted PNG pairs."
    - "UIQ-03/D-07/D-08/D-09/D-10/D-11: The walkthrough and candidate-gate contracts identify the review URL, exact candidate, served CSS, CI, advisory evidence, and scoped cleanup; missing prerequisites leave delivery incomplete."
    - "UIQ-03/D-05/D-08/D-09/D-10/D-11: The committed live gate evaluates one exact clean candidate SHA, current assets and evidence, and required CI without remote writes."
    - "UIQ-03/D-07/D-08/D-09: The retained review project and clean candidate worktree survive with recorded URL, ports, project, SHA, and scoped cleanup."
    - "UIQ-03/D-05/D-08/D-10: A passed delivery record requires exact-SHA required CI, committed acceptance inputs, and successful local checks; otherwise it records incomplete reasons."
    - "UIQ-02/D-04/D-05/D-06: A focused synthetic browser run from a clean detached worktree produces six current/baseline PNG pairs and a checkpoint bound to its exact SHA, clean flag, capture metadata, asset identity, and actual PNG hashes."
    - "D-07/D-09/D-10: A new retained review URL serves the exact clean candidate from an isolated Compose project; required routes answer 200 and served Admin CSS bytes equal the candidate bundle."
    - "D-08/D-09/D-11: The local disposition records current evidence separately from protected README acceptance and exact-SHA CI prerequisites, without claiming UIQ-03 or phase completion."
  artifacts:
    - path: mailglass_admin/docs/design-system.md
      provides: Current brand/CSS ownership, scales, review surfaces, and evidence limits
    - path: reference/demo_app/assets/e2e/phase173-evidence.spec.js
      provides: Synthetic primary/adverse browser captures with source and asset provenance
    - path: reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
      provides: Fail-closed capture and retained-evidence validation
    - path: scripts/check_phase173_candidate.sh
      provides: Detached candidate, CI, owner-dirt, readiness, asset, and evidence gate
    - path: .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md
      provides: Candidate walkthrough and scoped resource disposition
    - path: reference/demo_app/README.md
      provides: Working-preview entry point; protected owner acceptance remains unverified
    - path: reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
      provides: Current candidate, local regression, preview, CI, acceptance, and resource disposition evidence
    - path: reference/demo_app/tmp/demo_browser_evidence/retained/checkpoint.json
      provides: Current synthetic capture metadata and PNG byte digest checkpoint in the candidate worktree
  key_links:
    - from: brandbook/tokens.css
      to: mailglass_admin/docs/design-system.md
      via: Admin CSS mapping and token parity assertions
    - from: mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex
      to: mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex
      via: Actual source/build/served metadata and screenshot bytes
    - from: reference/demo_app/assets/e2e/phase173-evidence.spec.js
      to: reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
      via: Focused Playwright report and PNG-byte checkpoint validation
    - from: scripts/check_phase173_candidate.sh
      to: .github/workflows/ci.yml
      via: Exact-SHA read-only required CI query
    - from: reference/demo_app/README.md
      to: .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md
      via: Working-preview entry point and owner walkthrough link; protected source remains unverified
    - from: scripts/run_demo_browser_evidence.sh
      to: current detached candidate checkpoint
      via: Focused producer, fail-closed validator, exact SHA, and six current/baseline PNG pairs
    - from: current retained Compose project
      to: current candidate Admin CSS bundle
      via: Five live routes and served CSS SHA-256 equality
  roadmap_requirements:
    UIQ-01: satisfied
    UIQ-02: satisfied
    UIQ-03: unmet
human_verification: []
advisory: []
---

# Phase 173: Consistency and Delivery Evidence Verification Report

**Phase Goal:** The delivered UI is coherent across slices and can be reviewed and reproduced from a working candidate.
**Verified:** 2026-10-10T12:22:44Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure Plan 07

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Roadmap SC1: Maintainers can find shared patterns and accurate current guidance with clear token ownership. | ✓ VERIFIED | The current design guide assigns brand/token ownership and semantic CSS roles, identifies the broad Gallery and curated Storybook, and states browser/email-client limits. The parity test ties the guide to token and CSS sources; the earlier verification confirmed the Gallery and Storybook use the shared versioned Admin bundle. |
| 2 | Roadmap SC2: Focused checks and source-identified before/after renders are repeatable and evidence limits are explicit. | ✓ VERIFIED | The phase-owned producer/checker and synthetic captures remain present and wired; the checkpoint identifies six browser-only captures with route, state, browser, baseline, asset and PNG metadata. The most recent full capture/regression evidence is from older candidate `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`, so it is not claimed as current-SHA gate proof. The task supplied that narrow synthetic contract checks passed after the follow-up code fix; they were not rerun here. |
| 3 | Roadmap SC3: The owner can review a documented working preview of the completed milestone with passing required CI, current assets, committed work, and explicit resource disposition. | ✗ FAILED | The last full candidate gate passed locally only for older SHA `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`. Full gate and regression checks were skipped on current code SHA `4994442105315afdaa71beba73f6ab85e40f8533`; exact-SHA CI and authorized owner acceptance remain unavailable. |
| 4 | Plan 01: A current candidate can run synthetic route assertions, bounded captures, and fail-closed provenance. | ✓ VERIFIED | Current source retains the phase-owned focused route assertions and fail-closed checkpoint; the synthetic contract checks after the follow-up code fix were reported passed. Older full capture/regression results are historical and are not used as current candidate gate proof. |
| 5 | Plan 01: Each capture records route, state, browser, before/after relation, actual PNG digest, candidate, and source/build/served identity without claiming email-client behavior. | ✓ VERIFIED | Retained checkpoint for the older candidate contains those fields per capture; all six use synthetic fixtures and browser-only wording. The byte-hash result remains historical evidence for that candidate. |
| 6 | Plan 01: Evidence lifecycle uses a unique Compose project and ports and scoped cleanup. | ✓ VERIFIED | The phase-owned wrapper and fake-Docker contract establish project-scoped cleanup. The retained review project is separately named `mailglass-phase173-review-3d6314ba-20261010115642-72946-14875` on ports 64514/64515. |
| 7 | Plan 02: Design guidance matches shipped CSS and token ownership without obsolete competing rules. | ✓ VERIFIED | Guide and parity assertions identify brandbook values, Admin semantic mapping, current scales, and historical visual scores as history. |
| 8 | Plan 02: Gallery and Storybook are complementary and share the committed Admin CSS. | ✓ VERIFIED | The current guide and phase-owned route checks document the broad Gallery, curated Storybook, shared examples/themes, and shared versioned stylesheet. The existing 320px Gallery overflow remains disclosed; no 320px pass is claimed. |
| 9 | Plan 02: Admin capture distinguishes dry-run identity from actual screenshot-byte proof and rejects incomplete evidence. | ✓ VERIFIED | Manifest and writer code validate actual PNG bytes and source/build/served identities; negative tests cover incomplete and mismatch cases. |
| 10 | Plan 03: The owner can open the retained current-candidate preview and follow a task-based walkthrough while the older feedback preview remains intact. | ✓ VERIFIED | The walkthrough and disposition record a retained working preview and scoped cleanup for older candidate `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`, not current code SHA `4994442105315afdaa71beba73f6ab85e40f8533`. This verifies the review surface exists, not current-candidate readiness or owner acceptance. |
| 11 | Plan 03: Required `CI Green` passes for the exact final candidate, separately from advisory jobs. | ✗ FAILED | Exact-SHA required CI Green is unavailable for current code SHA `4994442105315afdaa71beba73f6ab85e40f8533`; older-SHA CI evidence does not satisfy the criterion. |
| 12 | Plan 03: Source/generated assets are current, task-owned changes committed, and retained/disposed resources are explicit. | ✓ VERIFIED | Source/build ownership checks remain implemented; disposition/runbook describe retained resources. Asset, clean-worktree and regression measurements recorded for `a7fd4843d17c2bf201fb1366c588d65af0f22c3d` are historical, not a full verification of current code SHA. |
| 13 | Plan 03: Candidate is detached, clean, exact, includes committed phase work, and records owner dirt as excluded without copying it. | ✓ VERIFIED | The candidate-gate source and fake contract implement the detached/clean/exclusion checks; recorded clean-candidate evidence is for older SHA `a7fd4843d17c2bf201fb1366c588d65af0f22c3d`, not current SHA. |
| 14 | Plan 03: Machine checks cover readiness, identity, CI, and scoped cleanup without merge/publication. | ✓ VERIFIED | Current gate source and synthetic contract encode these boundaries. The live gate was not invoked for current SHA, so this is implementation/wiring evidence only. |
| 15 | Plan 04: Only validated synthetic checkpoint and allowlisted PNG pairs are retained. | ✓ VERIFIED | The six current/baseline pairs are present under the detached candidate's retained directory and their 12 byte hashes match the sanitized checkpoint/disposition. |
| 16 | Plan 04: Both Admin actual-capture write paths reject build/served CSS mismatch. | ✓ VERIFIED | The manifest implementation and focused negative tests encode the equality guard; no new source changes were reported after that verified plan. |
| 17 | Plan 04: CI Admin capture is restricted to synthetic HappyMailer while local selection behavior remains supported. | ✓ VERIFIED | The CI allowlist and separate local selection paths are implemented and covered by focused tests. |
| 18 | Plan 04: The same offline exact-lock gate precedes all demo browser installs and the advisory job audits the lock. | ✓ VERIFIED | Gate calls and ordering checks exist at all four install paths; the exact lock audit was recorded passing. |
| 19 | Plan 05: Evidence reset accepts only a run-owned synthetic project; both capture producers preflight before POST. | ✓ VERIFIED | Server-side marker/token guard and shared preflight wiring were inspected in the prior verification; focused controller/helper contracts and the isolated capture run passed. |
| 20 | Plan 05: Candidate gate transfers only six pinned baselines and validates the sanitized checkpoint and PNG bytes. | ✓ VERIFIED | Candidate gate and fake-CLI contracts cover allowlisted baseline transfer; all six current/baseline pairs in the new candidate were independently byte-hash checked. |
| 21 | Plan 05: Walkthrough and gate contracts identify URL, candidate, CSS, CI, evidence, and scoped cleanup; missing conditions remain incomplete. | ✓ VERIFIED | Runbook and contract sources are substantive. The current disposition records missing CI, protected acceptance, and unrun full-gate conditions as incomplete. |
| 22 | Plan 06: The live full gate evaluated one exact clean candidate, assets/evidence, and required CI without remote writes. | ✗ FAILED | The full gate and regression gate were skipped for current code SHA `4994442105315afdaa71beba73f6ab85e40f8533`. The older SHA `a7fd4843d17c2bf201fb1366c588d65af0f22c3d` locally passed previously, but cannot satisfy this current-SHA truth. |
| 23 | Plan 06: A retained review project and clean worktree survive with current URL, ports, SHA, and cleanup. | ✓ VERIFIED | A retained project/worktree and cleanup record exist for the older candidate; this does not establish current-candidate gate or CI results. |
| 24 | Plan 06: The gate only passes with exact-SHA CI and committed acceptance inputs; otherwise it records incomplete reasons. | ✓ VERIFIED | Current disposition is `incomplete` and records empty CI runs, protected owner acceptance as unverified, and the skipped full gate as explicit failures. |
| 25 | Plan 07: Six current/baseline synthetic PNG pairs and a validated checkpoint bind to the clean candidate SHA. | ✓ VERIFIED | The retained checkpoint records six synthetic current/baseline pairs with byte digests for an older candidate. That is evidence for the captured candidate only, not current code SHA gate proof. |
| 26 | Plan 07: A new retained review URL serves the exact candidate from an isolated Compose project with five successful routes and matching Admin CSS bytes. | ✓ VERIFIED | The disposition/runbook record an isolated review project, URL, routes and matching built/served CSS for the older candidate; no current-SHA full gate is claimed. |
| 27 | Plan 07: Local disposition separates current evidence from protected README acceptance and exact-SHA CI prerequisites without claiming completion. | ✓ VERIFIED | The disposition explicitly keeps delivery incomplete and separates local evidence, exact-SHA CI and owner acceptance. Its recorded candidate predates the current code SHA. |

**Score:** 24/27 must-haves verified (0 present, behavior-unverified).

### Re-verification Summary

This verification preserves the independently inspectable UIQ-01/UIQ-02 source and evidence contracts. Current code SHA `4994442105315afdaa71beba73f6ab85e40f8533` has not received the full candidate gate; the previous full local gate at `a7fd4843d17c2bf201fb1366c588d65af0f22c3d` is historical. Required exact-SHA CI and authorized owner acceptance remain outstanding.

### Advisory (New Scope, Unevidenced)

No new-scope anti-pattern findings were raised in this re-verification. The full candidate gate was not rerun because its build context includes protected inputs; that remains an explicit failed must-have, not an advisory substitution.

| # | Finding | Category | Why Advisory |
|---|---|---|---|
| — | None | — | No new-scope concern was found that needed deterministic evidence. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_admin/docs/design-system.md` | Current token ownership, scales, review surfaces, and evidence limits | ✓ VERIFIED | Source-aligned and connected to parity assertions. |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | Guide/source drift guard | ✓ VERIFIED | Asserts ownership, mapping, scales, and review surfaces. |
| `reference/demo_app/assets/e2e/phase173-evidence.spec.js` | Bounded synthetic current/adverse capture producer | ✓ VERIFIED | Current output contains six source-identified captures; only the phase-owned spec is used. |
| `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs` | Provenance and retained capture validator | ✓ VERIFIED | Producer output is a sanitized checkpoint with actual-byte hashes and allowlisted files. |
| Retained `checkpoint.json` | Exact-SHA screenshot checkpoint | ✓ VERIFIED (historical) | `passed`, `candidate_dirty=false`, six captures for an older candidate. |
| `phase173-gap-disposition.json` | Candidate, preview, regression, CI, and acceptance record | ✓ VERIFIED (historical) | Records older-SHA local evidence and incomplete delivery reasons; does not prove current SHA. |
| `scripts/check_phase173_candidate.sh` | Full exact-candidate delivery gate | ⚠️ IMPLEMENTED, LIVE GATE NOT RUN | Gate source is substantive; full invocation was skipped for current SHA under the hard fence. |
| `173-DELIVERY.md` | Task-based preview walkthrough and scoped cleanup | ✓ VERIFIED | Runbook exists and describes the review path and scoped cleanup for the older candidate. |
| Protected owner acceptance input | Working-preview entry point and owner acceptance | ? UNVERIFIED | Not accessed under the hard fence. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `brandbook/tokens.css` | `mailglass_admin/docs/design-system.md` | CSS mapping and parity assertions | ✓ WIRED | Prior source audit confirmed the parity test reads tokens, CSS, and guide. |
| Admin capture task | `capture_manifest.ex` | Actual asset and PNG provenance | ✓ WIRED | Writer delegates actual capture validation; source was unchanged after the prior verification. |
| `phase173-evidence.spec.js` | evidence checker | Playwright report and PNG bytes | ✓ WIRED | Retained checkpoint/byte evidence exists for six captures on an older candidate. |
| evidence wrapper | detached candidate checkpoint | Focused producer and validator | ✓ WIRED | Source selects the phase-owned producer/checker; retained checkpoint is historical for current-SHA purposes. |
| retained Compose project | candidate Admin CSS bundle | HTTP routes and fetched CSS bytes | ✓ WIRED | Route and served-CSS probes were recorded for an older candidate. |
| candidate gate | GitHub `CI Green` | Exact-SHA read-only query | ✗ NOT SATISFIED | Exact-SHA CI Green unavailable for current SHA; no current query was run. |
| owner acceptance | `173-DELIVERY.md` | Protected acceptance input | ? UNVERIFIED | Not accessed under the hard fence; no claim is made. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Retained screenshots | `captures[].sha256` | PNG bytes from older candidate | Yes; prior byte-hash check recorded for that candidate | ✓ FLOWING (historical) |
| Candidate checkpoint | `candidate_revision`, capture metadata | Prior focused Playwright run | Yes; six capture records bound to older SHA | ✓ FLOWING (historical) |
| Admin stylesheet | `servedSha256` | Prior live HTTP response at the versioned CSS path | Yes; prior response hash matched older candidate bundle | ✓ FLOWING (historical) |
| Candidate delivery status | `ci.runs`, `ownerAcceptance`, `localChecks` | Prior disposition record | Yes; it records older-SHA local checks and unresolved external gates | ✓ FLOWING (historical) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Candidate revision and six-pair PNG byte provenance | Existing retained evidence, older SHA only | Six captures are recorded for an older candidate; no current-SHA claim | Historical evidence only |
| Retained preview behavior and asset delivery | Existing disposition, older SHA only | Preview and asset probes were recorded for an older candidate | Historical evidence only |
| Required exact-SHA CI | Not queried in this verification | Exact-SHA CI Green unavailable for `4994442105315afdaa71beba73f6ab85e40f8533` | ✗ OUTSTANDING |
| Full candidate gate and standard regression gate | Not run | Hard fence and candidate workflow discovery/build scope | ? SKIP — no full execute-phase verification is claimed |

### Probe Execution

Not applicable. This phase does not declare migration/tooling probe scripts as acceptance evidence.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| UIQ-01 | 173-02 | Find delivered patterns, states, ownership, and current design guidance | ✓ SATISFIED | Design guide, Gallery/Storybook wiring, and token parity source assertions. `.planning/REQUIREMENTS.md` still has its checkbox pending; it was not changed by verification. |
| UIQ-02 | 173-01, 173-02, 173-04, 173-05, 173-07 | Reproduce focused checks and inspect source-identified browser renders with explicit evidence limits | ✓ SATISFIED | Current producer/checker contracts and source-identified synthetic capture metadata are present; the task reports narrow contract checks passed after the fix. The older full candidate run is historical only. |
| UIQ-03 | 173-01, 173-03, 173-04, 173-05, 173-06, 173-07 | Review documented candidate with required CI, current assets, committed work, and retained/disposed resources | ✗ BLOCKED | Older candidate preview/local results do not prove current SHA; exact-SHA CI and authorized owner acceptance are outstanding, and current full gate was skipped. |

No orphaned Phase 173 requirement IDs were found; roadmap and phase plans map UIQ-01, UIQ-02, and UIQ-03.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None found in the safe source subset inspected | — | Current candidate gate source was inspected; no full-workspace anti-pattern scan was run under the hard fence. |

### Human Verification Required

None recorded. Visual UAT was out of scope. Protected README acceptance remains an explicit unresolved delivery prerequisite in the gaps above and is not assumed satisfied.

### Gaps Summary

UIQ-01 and UIQ-02 remain supported by current source inspection and the phase-owned evidence contracts, with older full runtime results labeled historical. Current code SHA `4994442105315afdaa71beba73f6ab85e40f8533` has not received the full candidate gate or regression gate: both were skipped because their discovery/build scope could include protected inputs under the hard fence. Exact-SHA required CI and authorized owner acceptance remain outstanding, so UIQ-03 and the phase goal are not complete.

---

_Verified: 2026-10-10T13:58:01Z_
_Verifier: the agent (gsd-verifier)_
