# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** — Phases 39-44 (shipped 2026-05-06) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** — Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) — see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** — Phases 52, 57-62 (shipped 2026-05-31) — see [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- ◆ **v1.4 Inbound Stability Lock** — Phases 63-66 (planning) — lock `mailglass_inbound` contract posture and make the release-position decision.

## Phases

<details>
<summary>✅ v1.1 Inbound Core Slice (Phases 39-44) — SHIPPED 2026-05-06</summary>

- [x] Phase 39: Inbound Package Foundation (3/3 plans) — completed 2026-05-06
- [x] Phase 40: Postmark Ingress And Replayable Persistence (3/3 plans) — completed 2026-05-06
- [x] Phase 41: SendGrid Ingress And Mailbox Routing (3/3 plans) — completed 2026-05-06
- [x] Phase 42: Async Execution And Adopter Proof (3/3 plans) — completed 2026-05-06
- [x] Phase 43: Execution Verification Recovery (3/3 plans) — completed 2026-05-06
- [x] Phase 44: Async Adoption Closeout Reconciliation (2/2 plans) — completed 2026-05-06

Audit re-passed 2026-05-07 after Phase 43 + 44 closeout. Full archive at [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md).

</details>

<details open>
<summary>◆ v1.4 Inbound Stability Lock (Phases 63-66) — PLANNING</summary>

- [x] Phase 63: Inbound Contract Inventory Reconciliation — canonical stable/testing/internal/deferred inventory (completed 2026-05-31)
- [x] Phase 64: Contract Verification Hardening — compiled-doc, docs-contract, and root stability proof gates (completed 2026-05-31)
- [x] Phase 65: Compatibility, Docs, and DX Lock — adoption path, operator wording, testing docs, and compatibility/deprecation posture (completed 2026-06-01)
- [x] Phase 66: Release Position Decision — evidence-backed `1.0.0` decision recorded with release notes and final candidate-version proof (completed 2026-06-01)

**Goal:** Lock `mailglass_inbound` into a stable adopter contract by defining its public API, compatibility policy, docs guarantees, and executable stability checks without expanding feature scope.

**Requirements:** LOCK-01..03, PROOF-01..03, DX-01..04, REL-01..03

**Non-goals:** No matcher expansion, lifecycle callbacks, public replay API, provider extension API, worker/queue contract, synthetic inbound dev UI, ecosystem integrations, or `gen_smtp` listener work.

### Phase Details

#### Phase 63: Inbound Contract Inventory Reconciliation

**Goal:** Reconcile `mailglass_inbound/docs/api_stability.md` against shipped behavior so adopters can tell stable semantics from reachable implementation details.

**Requirements:** LOCK-01, LOCK-02, LOCK-03

**Success criteria:**
1. `mailglass_inbound/docs/api_stability.md` names stable runtime, testing, operator, telemetry, and error-contract seams without promoting internal modules.
2. Existing provider support is documented through `MailglassInbound.Ingress.Plug` behavior/options, not as public provider module APIs.
3. Internal and deferred lists explicitly include replay internals, worker/queue details, route structs, provider modules, matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations.
4. The inventory aligns with core/admin language: stable means semantic contract, not ExDoc visibility or module reachability.

**Plans:** 1/1 plans complete

Plans:
- [x] `63-01-PLAN.md` — Reconcile the canonical inbound stability inventory and tighten the package-local docs-contract test around stable, internal, and deferred semantics.

#### Phase 64: Contract Verification Hardening

**Goal:** Make the inbound stability contract executable through compiled-doc metadata, docs drift checks, and root verification wiring.

**Requirements:** PROOF-01, PROOF-02, PROOF-03

**Success criteria:**
1. A package-local inbound stability contract test asserts `@moduledoc since:` / `@doc since:` metadata for stable modules and public functions/macros/callbacks.
2. Closed inbound atom/type sets remain locked to docs through explicit tests.
3. Inbound docs-contract tests fail on public replay API claims, stable worker/queue claims, provider-module extension claims, replay-as-fresh wording, and stale release-line claims.
4. Root `mix verify.stability_contract` includes the inbound contract lane and fails closed on drift.

**Plans:** 5/5 plans complete

Plans:
- [x] `64-01-PLAN.md` — Correct package-line `since` metadata on the stable inbound runtime seams.
- [x] `64-02-PLAN.md` — Correct package-line `since` metadata on the stable structured-error and operator task modules.
- [x] `64-03-PLAN.md` — Correct package-line `since` metadata on the adopter-facing inbound testing helpers.
- [x] `64-04-PLAN.md` — Tighten the inbound docs-contract lane around closed error sets, release pins, and over-claim drift.
- [x] `64-05-PLAN.md` — Create the package-local inbound compiled-doc proof and delegate root stability verification to it.

#### Phase 65: Compatibility, Docs, and DX Lock

**Goal:** Give adopters one coherent inbound adoption, compatibility, testing, and operator-trust story.

**Requirements:** DX-01, DX-02, DX-03, DX-04

**Success criteria:**
1. `mailglass_inbound/README.md` is the canonical adoption path and stays consistent with the install/provider/operator guides.
2. Compatibility/deprecation guidance states stable inbound surfaces require deprecation bridge or major-version change, while internal/deferred surfaces may change without deprecation.
3. Operator docs explain doctor/replay/prune commands, exit semantics, tenant guards, destructive confirmations, and replay-over-stored-truth semantics.
4. Testing docs make `MailboxCase`, `Test.Ingress`, process-local assertions, and one-assertion-per-drive behavior clear.
5. Admin/operator trust docs do not imply replay as fresh receive, silent reroute, UI contract, or stable DOM/component APIs.

**Plans:** 4/4 plans complete

Plans:
- [x] `65-01-PLAN.md` — Keep the inbound README as the canonical adoption lane and route compatibility posture through the active guide topology.
- [x] `65-02-PLAN.md` — Tighten operator, testing, and admin trust docs around shipped semantics and explicit non-contract boundaries.
- [ ] `65-03-PLAN.md` — Extend inbound docs-contract and Tier 1 docs checks to lock the adoption and compatibility story.
- [ ] `65-04-PLAN.md` — Extend inbound docs-contract and Tier 1 docs checks to lock operator, testing, and admin trust wording.

#### Phase 66: Release Position Decision

**Goal:** Decide and document whether `mailglass_inbound` is ready for `1.0.0` or needs one final explicit `0.x` confidence release.

**Requirements:** REL-01, REL-02, REL-03

**Success criteria:**
1. Full stability and release-blocking verification evidence exists for the inbound lock.
2. The release decision is explicit: promote `mailglass_inbound` to `1.0.0` if the lock is real, otherwise cut one final `0.x` confidence release with "next is 1.0" framing.
3. Changelog/release notes include adopter action required, verification commands, behavior changes, operator-impacting changes, and docs/stability posture.
4. Project planning state records that broad feature-growth work remains blocked until the release-position decision is complete.

**Plans:** 2 plans

Plans:
- [x] `66-01-PLAN.md` — Capture fresh Phase 66 release evidence and write the canonical binary release-position record.
- [x] `66-02-PLAN.md` — Apply the chosen release truth, release notes, final publish proof, and feature-growth gate updates.

</details>

<details>
<summary>✅ v1.2 Inbound Production Confidence (Phases 44.5, 45-50, 50.5, 50.7, 51) — SHIPPED 2026-05-26</summary>

- [x] Phase 44.5: v1.0/1.1 Release Ceremony (5/5 plans) — completed 2026-05-07
- [x] Phase 45: Inbound Telemetry + Idempotency Foundation (12/12 plans) — completed 2026-05-23
- [x] Phase 46: Mailgun + SES Inbound Ingress (3/3 plans) — completed 2026-05-23
- [x] Phase 47: Inbound Test Helpers + Generators (4/4 plans) — completed 2026-05-24
- [x] Phase 48: Inbound Admin LiveView (3/3 plans) — completed 2026-05-24
- [x] Phase 49: Inbound Runtime Operator Tooling (3/3 plans) — completed 2026-05-25
- [x] Phase 50: Inbound Documentation Pass (3/3 plans) — completed 2026-05-25
- [x] Phase 50.5: v1.2 Release Ceremony (3/3 plans) — completed 2026-05-26
- [x] Phase 50.7: v1.2 Repo Hygiene Pass (1/1 plan) — completed 2026-05-26
- [x] Phase 51: Stability Closeout (4/4 plans) — completed 2026-05-26

Audit passed 2026-05-26 after Phase 51 closeout. Full archive at [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md).

</details>

<details>
<summary>✅ v1.3 Adopter Trust Proof (Phases 52, 57-62) — SHIPPED 2026-05-31</summary>

- [x] Phase 52: Trust Scope Lock + Reference Host Baseline (3/3 plans) — completed 2026-05-27
- [x] Phase 57: Deterministic Trust Runner + Fixtures (2/2 plans) — completed 2026-05-27
- [x] Phase 58: Verify-First Webhook + Operator Path (2/2 plans) — completed 2026-05-27
- [x] Phase 59: CI Trust Lanes + Checkpoint Evidence (2/2 plans) — completed 2026-05-28
- [x] Phase 60: Release Trust Gate + Drift Prevention (5/5 plans) — completed 2026-05-31
- [x] Phase 61: Docs Contract Boundary Enforcement (3/3 plans) — completed 2026-05-31
- [x] Phase 62: Close gap: EVID-02/EVID-03 — current-release trust proof (1/1 plan) — completed 2026-05-31

Audit passed 2026-05-31 after Phase 62 closeout. Full archive at [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md).

</details>

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup (BACKLOG)

**Goal:** Reduce distracting internal planning references such as `D-20`, phase-plan IDs, and similar GSD artifacting in source comments so the code reads cleanly for humans while preserving the intent behind important architectural notes
**Requirements:** TBD
**Plans:** 3/3 plans complete

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow (BACKLOG)

**Goal:** Make it easy at any time to see realistic rendered example emails across themes and mobile/responsive layouts, ideally through an idiomatic low-friction workflow such as a mix task, preview pipeline, or CI-generated screenshots
**Requirements:** TBD
**Plans:** 3/3 plans complete

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

## Notes

**Release-cadence rule (added 2026-05-06):** Each milestone closes with a release ceremony (Phase X.5 by convention). Don't start the next milestone implementation while previous-milestone work is unreleased. The 4-milestone-deep gap between v0.3.2 and 1.0.0 is the failure mode this rule prevents.

**v1.4 convergence rule:** After inbound stability lock, default future planning to release ceremony, maintenance, release hygiene, docs truth, and narrow adopter-pull work. Broad feature-growth remains blocked until the release-position decision is complete (now satisfied by Phase 66 artifacts).
