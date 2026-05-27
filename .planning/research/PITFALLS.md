# Domain Pitfalls

**Domain:** `mailglass` v1.3 Adopter Trust Proof (maintained Phoenix reference host app + trust-proof CI lane)  
**Researched:** 2026-05-27  
**Confidence:** HIGH (project artifacts + Elixir/Phoenix/Hex OSS failure-pattern convergence)

## Likely Implementation Sequence (for phase mapping)

1. **Phase 1 - Reference App Baseline:** create one maintained host app skeleton, strict scope, deterministic seed data, and ownership boundaries.
2. **Phase 2 - Golden Journey Wiring:** prove install -> preview -> send -> webhook ingest -> operator troubleshooting in one runnable flow.
3. **Phase 3 - Clean-Baseline CI Lane:** exercise the reference app from a clean host-app baseline (no local shortcuts, no path-dep cheats).
4. **Phase 4 - Docs and Contract Positioning:** clearly separate usage proof artifacts from API contract truth.
5. **Phase 5 - Drift Prevention and Release Cadence:** enforce update cadence and breakage triage so proof stays trustworthy after release.

## Critical Pitfalls

### Pitfall 1: Reference app scope creep turns "proof host" into a second product
**What goes wrong:** the reference app accumulates custom UI, extra auth modes, provider breadth, and app-specific abstractions that are not required for trust proof. Maintainers end up supporting two products: library + demo app.
**Why it happens:** "just one more realism tweak" feels harmless each week; no explicit "proof-only" boundary.
**Consequences:** maintenance drag, slow library releases, stale reference app, and trust erosion when examples stop matching current APIs.
**Warning signs:**
- reference app PRs are mostly app-feature work, not proof-flow maintenance
- app introduces its own domain language instead of Mailglass nouns
- unresolved TODOs around the core trust journey while peripheral polish grows
**Prevention:**
- maintain a written "proof scope allowlist" (the exact journey and only supporting pages/tooling)
- require each reference-app change to map to one trust-proof requirement
- reject features that do not increase confidence in install/send/webhook/operator flow
**Phase to address:** Phase 1 (set boundary), enforce in Phases 2-5.

### Pitfall 2: Path-dependency coupling hides real Hex install failures
**What goes wrong:** reference app is wired to local path deps or umbrella-local assumptions, so install success in-repo does not represent adopter reality from Hex.
**Why it happens:** path deps are faster during development and accidentally leak into committed config/scripts.
**Consequences:** adopters hit first-day breakage while maintainers see green locally; confidence claim is invalid.
**Warning signs:**
- `{:mailglass, path: ...}` or equivalent local coupling remains in committed files
- setup scripts assume monorepo sibling layout
- CI never resolves published package versions in a clean environment
**Prevention:**
- lock reference-app default to Hex package resolution for proof lanes
- keep local-dev override scripts separate and explicitly non-proof
- add CI assertions that fail on path deps in trust-proof lane inputs
**Phase to address:** Phase 1 baseline and Phase 3 CI hardening.

### Pitfall 3: "Clean baseline" CI is not actually clean
**What goes wrong:** CI reuses cached artifacts, prewarmed database state, or in-tree assumptions that mask migration/install/order-of-operations issues.
**Why it happens:** speed optimizations are added before invariants are pinned.
**Consequences:** false positives, flaky trust proof, high-maintainer triage burden.
**Warning signs:**
- lane only passes with warm cache or re-run
- failures reproduce only on first run or on fresh machines
- setup steps depend on undocumented environment assumptions
**Prevention:**
- enforce fresh app bootstrapping in lane (create/setup/migrate/seed/verify flow)
- keep a deterministic fixture path for webhook and operator evidence
- split fast feedback vs trust-proof lane; trust-proof lane stays strict even if slower
**Phase to address:** Phase 3 (primary), with deterministic artifacts prepared in Phase 2.

### Pitfall 4: Webhook proof bypasses real verify-first behavior
**What goes wrong:** tests inject events directly into internals, skipping Plug-level signature verification and normalization boundaries.
**Why it happens:** direct function calls are easier than full request-shape fixtures.
**Consequences:** milestone claims webhook confidence, but forged/bad signature paths and provider-shape regressions are unproven.
**Warning signs:**
- reference flow never exercises provider request parsing/signature checks
- no coverage for signature-failure/operator-debug surfaces
- webhook fixtures omit headers/timestamps required by verifiers
**Prevention:**
- route proof through ingress Plug path with realistic signed payload fixtures
- keep one explicit negative-path assertion for signature failure semantics
- verify normalized events and downstream operator visibility from that same ingress path
**Phase to address:** Phase 2 journey wiring; regression-protect in Phase 3 lane.

### Pitfall 5: Operator troubleshooting story is non-deterministic or under-specified
**What goes wrong:** preview/send succeed, but operator steps depend on timing races, manual clicking, or ambiguous "look around in admin until you find it" instructions.
**Why it happens:** operator journey is treated as documentation garnish instead of a testable contract.
**Consequences:** support burden rises; adopters cannot reproduce incidents; trust proof fails at the exact "when things go wrong" moment.
**Warning signs:**
- operator evidence is not tied to stable IDs/event keys
- replay/debug outcomes differ across runs
- docs rely on screenshots without deterministic state setup
**Prevention:**
- seed deterministic deliveries/events with known identifiers
- codify one scripted troubleshooting path (symptom -> evidence -> diagnosis -> action)
- keep operator checks machine-verifiable where possible, doc-verifiable otherwise
**Phase to address:** Phase 2 (design deterministic path), finalized in Phase 4 docs.

### Pitfall 6: Sibling package version skew breaks the reference proof silently
**What goes wrong:** `mailglass`, `mailglass_admin`, and `mailglass_inbound` versions drift or publish timing changes, but reference app constraints and CI matrix are not updated in lockstep.
**Why it happens:** linked-version intent exists, but trust-proof lane wiring is maintained separately and lags releases.
**Consequences:** intermittent install failures, broken demos after release day, and high-cost emergency patching.
**Warning signs:**
- reference app pins versions differently than sibling package release policy
- release ceremony completes without rerunning trust-proof lane against published versions
- admin depends on features unavailable in resolved core/inbound versions
**Prevention:**
- treat trust-proof lane as release-gating evidence, not post-release smoke
- maintain a single version-source strategy and update checklist per release
- add explicit "published-version" run in ceremony artifacts
**Phase to address:** Phase 3 CI composition and Phase 5 release cadence.

### Pitfall 7: Reference-app docs become accidental API contract truth
**What goes wrong:** adopters copy behavior from reference app internals and treat it as stable API, conflicting with core `api_stability` docs and contract tests.
**Why it happens:** runnable apps are more persuasive than prose; without explicit boundaries, examples look canonical.
**Consequences:** future refactors become semver landmines, and maintainer must support accidental surface area.
**Warning signs:**
- issues cite reference-app private modules as "documented behavior"
- core docs and reference docs drift on what is supported vs illustrative
- sample code uses internals without "example-only" guardrails
**Prevention:**
- label reference app as "usage proof, not contract surface"
- link every reference step to canonical contract docs/tests
- avoid exposing internal-only modules in guide copy unless explicitly marked non-contractual
**Phase to address:** Phase 4 docs/positioning.

### Pitfall 8: No explicit maintenance owner or freshness SLO for trust artifacts
**What goes wrong:** reference app and trust lane launch strong, then rot because nobody owns monthly drift checks, dependency bumps, or fixture refresh.
**Why it happens:** milestone ends after buildout, not after operationalizing upkeep.
**Consequences:** stale proof, broken newcomer experience, repeated firefights, maintainer burnout.
**Warning signs:**
- trust lane red for multiple days with no triage SLA
- setup docs lag current release/version floor
- fixture/provider payloads stop matching current normalized shapes
**Prevention:**
- define maintenance owner and cadence in-repo (for one-person maintainer, explicit recurring checklist)
- require trust-lane green before release ceremony completion
- add lightweight recurring drift audit: setup success, webhook fixture validity, operator path reproducibility
**Phase to address:** Phase 5 drift-prevention operations (designed in Phase 1).

## Smallest Useful Guardrail Set (v1.3)

1. One reference app with strict scope and explicit non-goals.
2. Trust-proof CI lane that installs from Hex versions on a clean baseline.
3. Ingress proof through real verify-first webhook path (including one negative signature case).
4. Deterministic operator troubleshooting path with stable evidence IDs.
5. Docs boundary that keeps API contract truth in core contract docs/tests.
6. Ongoing maintenance cadence with owner, checklist, and release-gating enforcement.

## Phase-by-Phase Risk Focus

| Phase | Main risk to kill early | Concrete prevention gate |
|-------|--------------------------|---------------------------|
| Phase 1 - Reference App Baseline | scope creep + path-dep coupling | scope allowlist; fail if path deps appear in trust lane |
| Phase 2 - Golden Journey Wiring | fake webhook/operator proof | signed ingress fixtures + deterministic troubleshooting script |
| Phase 3 - Clean-Baseline CI Lane | false green from non-clean runs | from-scratch lane with strict setup and no local shortcuts |
| Phase 4 - Docs/Contract Positioning | accidental API expansion via examples | explicit usage-proof vs contract-truth language in docs |
| Phase 5 - Drift Prevention/Cadence | post-launch artifact rot | owner + recurring checklist + release gate tied to trust lane |

## Sources

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/research/milestone-candidates/06-adopter-trust-proof.md`
- `.planning/research/milestone-candidates/SYNTHESIS.md`
