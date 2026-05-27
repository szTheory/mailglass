# Feature Landscape

**Domain:** v1.3 Adopter Trust Proof (reference host app)  
**Project:** mailglass  
**Researched:** 2026-05-27  
**Overall confidence:** HIGH

## Scope Principle

This milestone is a **trust-proof wedge**, not a capability wedge.

The new work should prove that a real adopter can run one maintained Phoenix host app through:

1. install,
2. preview,
3. send,
4. webhook ingest,
5. operator troubleshooting.

Anything that does not strengthen that proof should be deferred.

## New Work Only (Delta From Shipped v1.2)

Shipped capability is already broad (outbound, preview/admin, inbound ingest/runtime, telemetry, operator tooling, docs). The v1.3 delta is:

- one maintained reference host app as the canonical adoption proof artifact;
- one clean-baseline CI lane that continuously validates that artifact;
- one explicit docs posture that keeps API-contract truth in core docs/tests (not in the reference app).

## Table Stakes (Must-Have To Prove Trust)

| Feature | Expected Behavior In v1.3 | Complexity | Depends On Shipped Capability | Why It Is Table Stakes |
|---|---|---|---|---|
| **Maintained reference Phoenix host app** | Fresh clone + setup runs successfully; app boots with Mailglass integrated and configured on a realistic Phoenix baseline. | Med | `mix mailglass.install`, Phoenix mount patterns, existing schema/migrations | Without a runnable host, trust remains fragmented across docs/tests. |
| **Single canonical trust journey** | One documented flow proves install -> preview -> send -> webhook ingest -> operator troubleshoot, with clear checkpoints and expected outcomes. | Med | Preview LiveView, outbound pipeline, inbound ingress, admin/operator surfaces | Trust requires an end-to-end story, not isolated subsystem proofs. |
| **Webhook + operator troubleshooting proof path** | The host app demonstrates diagnosis from evidence (event/history/timeline), including at least one non-happy-path troubleshooting case. | Med | append-only event ledger, normalized events, replay/evidence tooling, inbound admin pages | Operators must be able to answer "what happened and why" in one place. |
| **Clean-baseline CI lane for reference app** | CI creates/uses a clean host-app baseline and verifies the trust journey deterministically; failures block drift. | High | existing CI discipline, contract tests, fixture/test helpers | Proof must be continuously re-validated, not manually claimed. |
| **Contract-boundary docs positioning** | Docs explicitly state: reference app is usage/operations proof; contract truth remains in `api_stability.md`, requirements, and contract tests. | Low | existing stability docs + docs contract tests | Prevents accidental "example app behavior == guaranteed public API" drift. |

## Differentiators (Nice-To-Have Follow-On, Not Required For v1.3 Exit)

| Feature | Value | Complexity | Suggested Timing |
|---|---|---|---|
| **Multi-provider trust matrix in host app** | Stronger evaluator confidence across provider permutations. | High | After v1.3 (inbound stability lock or focused provider follow-on) |
| **Hosted demo instance of reference app** | Faster evaluator onboarding, easier demos. | Med-High | After v1.3; only if maintenance budget supports ops burden |
| **Synthetic inbound generation UI in host app** | Better local troubleshooting ergonomics. | Med | After trust-proof baseline; keep dev-only and security-scoped |
| **Cross-version upgrade proof matrix** | Better long-horizon trust for adopters upgrading over time. | Med-High | After inbound stability lock clarifies broader contract posture |
| **Expanded failure-playbook scenarios** | Richer operator readiness and support docs. | Med | Incremental follow-on once baseline journey is stable |

## Anti-Features / Exclusions (Do Not Bundle Into v1.3)

| Anti-Feature | Why It Weakens This Milestone | Keep Out Of Scope For v1.3 |
|---|---|---|
| **Transport-class expansion (`gen_smtp` listener)** | Different architecture, ops risk, and threat surface; not needed for trust-proof baseline. | Yes |
| **Ecosystem grab-bag integrations** | Dilutes milestone focus and complicates verification. | Yes |
| **Broad provider matrix expansion** | Increases combinatorial test burden without improving the core trust claim. | Yes |
| **New product surface (marketing/multi-channel)** | Violates locked project boundary and distracts from adopter proof objective. | Yes |
| **Core API redesign during trust-proof milestone** | Destabilizes the very contract the milestone is trying to prove trustworthy. | Yes |
| **Treating reference-app internals as API contract** | Creates accidental public guarantees and long-term maintenance drag. | Yes |

## Expected Milestone Behavior (Done-Enough Signal)

At milestone exit, adopters should reasonably expect:

- a maintained reference host app they can run locally on a clean Phoenix baseline;
- a deterministic walkthrough that reaches preview, send, webhook ingest, and operator diagnosis;
- CI evidence that the walkthrough still works from a clean starting point;
- documentation that cleanly separates "usage proof" from "public API contract";
- no surprise scope creep into new transports/providers/product surfaces.

## Dependency Notes (What Reuses Shipped Capability)

v1.3 should reuse, not re-implement, these shipped foundations:

- **Install + setup primitives:** existing install/generator flow and baseline project wiring;
- **Preview + send path:** shipped preview/admin and outbound delivery foundations;
- **Webhook/inbound path:** normalized ingress, replay-safe persistence, and event taxonomy already in place;
- **Operator troubleshooting:** existing admin evidence/timeline/replay tooling;
- **Contract truth and docs checks:** existing stability docs and docs-contract verification lanes.

## Complexity Notes

| Workstream | Complexity | Primary Risk | Mitigation |
|---|---|---|---|
| Reference app design (thin but realistic) | Med | Becoming a second product app | Keep one representative journey only |
| Deterministic trust fixtures/scenarios | Med | Flaky or ambiguous proof outputs | Use stable fixtures + explicit expected checkpoints |
| Clean-baseline CI lane | High | Environment drift and long feedback loops | Keep lane narrow and purpose-built for trust journey |
| Docs boundary language | Low | Contract confusion between app and library | Explicitly separate proof artifact vs API contract source |
| Ongoing maintenance posture | Med | Reference app silently rotting between releases | Tie upkeep to release/CI gates and milestone rituals |

## Out Of Scope For This Milestone

- Cloudflare Email Routing support
- `gen_smtp` listener/relay transport work
- broad ecosystem integrations (`SEED-003` auto-promotion)
- schedule-send convenience work
- inbound auto-suppression policy expansion without fresh adopter signal

These remain viable follow-on wedges, but they are not required to prove v1.3 trust.
