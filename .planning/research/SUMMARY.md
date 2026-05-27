# v1.3 Research Summary - Adopter Trust Proof

**Project:** mailglass  
**Milestone focus:** v1.3 Adopter Trust Proof  
**Intent:** prove adopter confidence in a real Phoenix host integration without expanding product scope

## 1) Recommended stack additions/changes

Keep the shipped core stack unchanged (`Elixir ~> 1.18`, `OTP 27+`, Phoenix/LiveView/Plug, Ecto/Postgres, Swoosh, optional-deps gateway policy). v1.3 is an integration-proof milestone, not a runtime re-foundation.

Add only the thin proof layer needed for trust evidence:

- One maintained Phoenix reference host app artifact.
- One deterministic trust-journey runner command used by both humans and CI.
- One required CI trust lane using real Postgres and fixture-driven flows.
- One clean-baseline lane that proves fresh-host adoption path behavior.
- One published-version proof pass in release ceremony to validate Hex-first adopter reality.

Do not add new foundational runtime dependencies, transport classes, provider-matrix breadth, or product-like UI scope.

## 2) Feature table stakes for v1.3

The milestone must prove one canonical journey end to end:

1. install (`mix mailglass.install` path),
2. preview boot,
3. send evidence persisted,
4. webhook ingest through verify-first path,
5. operator troubleshooting from deterministic evidence.

Table-stakes deliverables:

- Maintained reference host app that is runnable and intentionally thin.
- Deterministic trust fixtures (stable IDs, stable payloads, stable assertions).
- One scripted troubleshooting scenario (including one non-happy-path signal).
- Clean-baseline CI lane that continuously re-validates the same journey.
- Clear docs boundary: reference app is usage/operations proof, not API contract truth.

Anything outside this trust claim is out of scope for v1.3.

## 3) Architecture integration approach

Integrate by composition through existing public seams only:

- installer entrypoint,
- mailable/delivery API,
- webhook route mount,
- admin route mount and existing operator read surfaces.

Architecture shape:

- Keep the reference host app separate from installer snapshot fixtures.
- Keep one shared trust runner as the source of execution truth for docs and CI.
- Run ingress proof through real request-shape verification and normalization flow (no internal bypass).
- Keep trust claims Hex-first; local path overrides may exist for development but are non-proof paths.
- Reuse existing append-only ledger and operator evidence surfaces; do not duplicate core internals in host code.

This preserves existing package boundaries while adding an adopter-visible proof harness.

## 4) Highest-risk pitfalls and prevention

1. **Reference app scope creep into second product**  
   Prevention: enforce strict proof-scope allowlist; require each change to map to trust-journey requirement.

2. **Path dependency coupling hides real install failures**  
   Prevention: enforce Hex-first defaults in proof lanes; fail CI if path deps leak into trust inputs.

3. **"Clean baseline" CI not truly clean**  
   Prevention: require from-scratch setup order with deterministic fixtures; avoid warm-state shortcuts.

4. **Webhook proof bypasses verify-first ingress behavior**  
   Prevention: use signed request-shape fixtures through mounted routes, plus one signature-failure assertion.

5. **Operator troubleshooting flow is ambiguous or non-deterministic**  
   Prevention: seed stable evidence IDs and codify one machine-checkable diagnosis path.

6. **Sibling package version skew breaks trust story**  
   Prevention: make published-version trust run part of release evidence; maintain one version-source strategy.

7. **Reference app becomes accidental API contract**  
   Prevention: explicit docs language that contract truth lives in stability docs and contract tests.

8. **Trust artifacts rot after launch**  
   Prevention: define maintenance cadence and require green trust-proof evidence in release gating.

## 5) Suggested sequencing constraints

Use this order to minimize rework and prevent false confidence:

1. **Scope lock + reference host baseline first**  
   Set non-goals, ownership boundaries, and Hex-first proof defaults before adding journey logic.

2. **Happy-path trust journey wiring second**  
   Wire install -> preview -> send with deterministic checkpoints.

3. **Webhook + operator troubleshooting proof third**  
   Add signed ingress fixtures and one deterministic non-happy-path troubleshooting path.

4. **Shared trust runner extraction fourth**  
   Ensure the same command powers local verification, CI, and release evidence.

5. **CI lane hardening fifth**  
   Add required trust lane, clean-baseline lane, and published-version release proof.

6. **Docs boundary and maintenance cadence last (before milestone exit)**  
   Finalize usage-proof vs contract-truth wording and lock recurring upkeep expectations.

Non-negotiable sequencing rules:

- Do not broaden providers/transports before canonical journey is deterministic.
- Do not claim trust proof until clean-baseline and published-version lanes are green.
- Do not treat reference-app internals as public API at any point in v1.3.
