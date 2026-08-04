---
phase: 153-generated-host-proof-docs-and-release-gate
verified: 2026-08-04T17:03:10Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "Exact published Hex versions repeat the complete generated-host journey before the release is accepted."
  gaps_remaining: []
  regressions: []
---

# Phase 153: Generated-Host Proof, Docs, and Release Gate — Verification Report

**Phase Goal:** A clean, production-shaped Phoenix host proves the published first-adopter journey end to end and prevents release on contract or configuration drift.
**Verified:** 2026-08-04T17:03:10Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A disposable stock Phoenix/Ecto/Postgres host consumes package-shaped artifacts through public APIs, migrates a unique non-public schema, and boots. | ✓ VERIFIED | `generated_host_proof.sh` creates a stock host, uses package artifacts, and invokes the generated public `Mailglass.Migration.up/0` wrapper. Protected prepublication run `30922262406` passed its local package-shaped journey. |
| 2 | Checkpoint evidence is bounded, deterministic, PII-free, and fails closed on incomplete stages or identity drift. | ✓ VERIFIED | `Checkpoint.encode/1` and `check_generated_host_proof.sh` implement the allowlist/validation contract; focused Phase 153 test run passed. |
| 3 | Unstamped default-tenant sync and normal `mailglass_outbound` async delivery have equivalent provider input and durable settlement scrubs private content. | ✓ VERIFIED | Journey calls normal `deliver_later/1`, polls persisted job/capture state, compares normalized inputs, and asserts scrubbed payload state without worker-perform/drain/manual/inline shortcuts. Focused contracts passed. |
| 4 | Queue/schema/input negative controls fail before false durable or provider success. | ✓ VERIFIED | `Journey.negative_controls!` snapshots qualified DB/job/capture/render/task state around controls; focused negative-control contracts passed. |
| 5 | Signed feedback and replayed one-click HTTP POSTs create durable facts, converge suppression, block matching future send, and preserve controls. | ✓ VERIFIED | Generated router mounts signed Postmark/one-click paths; journey performs HTTP requests and asserts outcomes. Focused HTTP contracts passed. |
| 6 | Callable production preflight and an authenticated, production-shaped operator route work independently of ordinary boot. | ✓ VERIFIED | `ProductionPreflight.run/1`, preflight task, and generated authenticated `MailglassAdmin.Router` mount are substantive and covered by focused readiness/preflight tests. |
| 7 | Primary adopter/production documentation states and checks the current public 2.x contract. | ✓ VERIFIED | README navigation, guides, and `docs_contract_test.exs` cover default tenancy, queue, preflight, feedback/suppression, and authenticated operator access; contracts passed. |
| 8 | The resolver derives the exact changed core/admin/inbound package set and enforces target agreement and linked-release policy. | ✓ VERIFIED | Resolver/target/workflow source is wired and resolver/concurrency tests passed; published target is exactly core `2.4.1`, admin `2.4.1`, inbound `2.1.2`. |
| 9 | Protected publication is gated by the candidate-specific journey, CI, package checks, target agreement, environment, and approval. | ✓ VERIFIED | `publish-hex` run `30922262406` succeeded on candidate `587c9d1…`, with all prepublication/publish jobs and retained Phase 153 artifact present. |
| 10 | The published tag remains the immutable intended candidate despite later proof fixes. | ✓ VERIFIED | Local and GitHub tag dereference `mailglass-v2.4.1` to `587c9d1a09944de02220b3fa121ce937677a8c3a`; the corrective workflow commit `cca6b061…` and ledger commit `6c3fdd8c…` did not move it. |
| 11 | Exact released artifacts match the selected versions, checksums, docs, and non-retraction state. | ✓ VERIFIED | Live Hex API/tarball SHA-256 checks match ledger values for all three packages; exact HexDocs pages resolve and run `30927455604` completed its not-retracted job. |
| 12 | Stored complete-release proof rejects workflow/candidate/package/version/checksum/approval/deployment/artifact/Hex drift. | ✓ VERIFIED | Live `mix run scripts/verify_release_proof.exs -- --ledger …/153-RELEASE-PROOF.md --stage complete` exited 0; its five fixture tests also passed. |
| 13 | Exact published Hex versions repeat the full generated-host journey, then complete published trust and retraction checks. | ✓ VERIFIED | Corrected `post-publish-smoke` run `30927455604` succeeded. Job `92053541965` successfully ran the exact resolver-selected generated-host journey; trust job `92056645363` succeeded with unexpired artifact `8900195536`; unretracted job `92056645569` succeeded. |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Generated host runner, migration task, host template, journey, checkpoint, validator | Public-boundary clean-host proof | ✓ VERIFIED | Substantive source and focused contracts; both protected local and published Hex executions are evidenced. |
| Generated-host / preflight / documentation tests | Behavioral and drift contracts | ✓ VERIFIED | Prior focused Phase-153 suite: 100 tests, 0 failures, 1 skipped; re-verification fixture subset: 5 tests, 0 failures. |
| Resolver, target, publication and post-publication workflows, proof verifier | Release-drift gate | ✓ VERIFIED | Live protected publication and candidate-bound post-publish execution satisfy the complete release chain. |
| `153-RELEASE-PROOF.md`, `153-REVIEW.md`, `153-REVIEW-FIX.md` | Auditable persisted evidence | ✓ VERIFIED | Ledger now includes the successful post-publication run. Review is clean and its documented fix remains included without altering the published tag. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Generated runner | Host journey | Fresh `phx.new` then generated host modules | ✓ WIRED | Direct runner copy/invocation plus successful local and Hex workflow runs. |
| Generated migration | Public migration facade | `Mailglass.Migration.up/0` / `down/0` | ✓ WIRED | Direct delegation in generated migration source. |
| `deliver_later/1` | Supervised `mailglass_outbound` producer | Persisted job and polling | ✓ WIRED | Host config/journey/test evidence confirms normal-mode flow. |
| Generated HTTP router | Webhook and one-click public routes | Router scopes, signatures, requests | ✓ WIRED | Source and focused HTTP contracts. |
| Preflight | Migration, Oban, host config | Public migration/readiness/config calls | ✓ WIRED | Direct source and focused preflight tests. |
| Resolver/target | Protected publication | Publish workflow preflight | ✓ WIRED | Exact candidate publish run succeeded. |
| Published Hex artifacts | Exact-Hex journey and trust/retraction checks | Candidate-bound post-publish workflow | ✓ WIRED | Run `30927455604` and all required downstream jobs passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated host journey | Job, delivery, event, payload, capture observations | Host Repo/catalog/capture adapter | Yes | ✓ FLOWING |
| Checkpoint | Stage facts and hashes | Journey proof map | Yes; validated fail-closed | ✓ FLOWING |
| Release proof | Candidate, workflow, approvals, artifact, Hex releases | GitHub/Hex live APIs | Yes; complete proof verifier passed | ✓ FLOWING |
| Published consumer/trust proof | Exact Hex dependencies and published checkpoint | Run `30927455604` | Yes; exact-Hex, trust-artifact, and unretracted jobs passed | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command / Evidence | Result | Status |
| --- | --- | --- | --- |
| Phase 153 focused contracts | Prior focused test matrix | 100 tests, 0 failures, 1 skipped | ✓ PASS |
| Complete live release proof | `mix run scripts/verify_release_proof.exs -- --ledger …/153-RELEASE-PROOF.md --stage complete` | `release proof verified for mailglass-v2.4.1` | ✓ PASS |
| Release-proof mutation fixtures | `mix test test/scripts/release_proof_verifier_test.exs --warnings-as-errors` | 5 tests, 0 failures | ✓ PASS |
| Exact published journey | GitHub run `30927455604` | Workflow and required consumer/trust/retraction jobs successful | ✓ PASS |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probe is declared for this phase. The release-proof verifier and live post-publish workflow are the applicable probes and both passed.

### Requirements Coverage

| Requirement | Source plan(s) | Status | Evidence |
| --- | --- | --- | --- |
| ADOPT-01 | 153-01 | ✓ SATISFIED | Public migration wrapper and package-shaped host proof. |
| ADOPT-02 | 153-02 | ✓ SATISFIED | Normal Oban sync/async parity and lifecycle evidence. |
| ADOPT-03 | 153-03 | ✓ SATISFIED | Negative controls with zero-effect observations. |
| ADOPT-04 | 153-04 | ✓ SATISFIED | Signed feedback and replay-safe one-click HTTP proof. |
| ADOPT-05 | 153-05 | ✓ SATISFIED | Production preflight and authenticated operator mount. |
| ADOPT-06 | 153-06 | ✓ SATISFIED | Executable current-contract documentation. |
| REL-17 | 153-07, 153-08 | ✓ SATISFIED | Exact selection, protected publication, immutable Hex artifacts, and a successful published-package journey. |

All requirement IDs declared across Phase 153 Plan frontmatter are accounted for. No Phase-153 artifact has an unresolved debt-marker blocker, and no later phase is required to close this phase’s contract.

### Re-verification Closure

The previous blocker was a real failed initial post-publish run (`30927069342`). It is now closed by an independently checked replacement run (`30927455604`) whose workflow implementation is at follow-up SHA `cca6b061…` but which explicitly checks out immutable release ref `mailglass-v2.4.1` at `587c9d1…`. This preserves the published candidate while proving its exact artifacts.

### Gaps Summary

No gaps found. Phase goal achieved.

---

_Verified: 2026-08-04T17:03:10Z_
_Verifier: the agent (gsd-verifier)_
