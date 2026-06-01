# Phase 66 Release Position

## Active Decision

Promote `mailglass_inbound` to `1.0.0`.

This is the single active path for Phase 66 because the required release-blocking evidence is green at the final candidate-version gate and no release blocker was found.

## Evidence Basis

1. Phase 63 (`63-CONTEXT.md`) reconciled the canonical inbound stable/testing/internal/deferred inventory.
2. Phase 64 (`64-CONTEXT.md`) hardened executable contract proof lanes (compiled-doc + docs-contract + root stability wiring).
3. Phase 65 verification is passed (`.planning/phases/65-compatibility-docs-and-dx-lock/65-VERIFICATION.md`, score `7/7`).
4. The pre-edit truth was `0.3.0`, and the final candidate truth is now coherent at `1.0.0` in `mailglass_inbound/mix.exs`, `.release-please-manifest.json`, `mailglass_inbound/README.md`, and `.planning/publish/mailglass_inbound-publish-summary.json`.
5. Final Phase 66 release gates are green:
`mix verify.stability_contract` and `mix mailglass.publish.check --package mailglass_inbound` (both exit code `0` in `.planning/phases/66-release-position-decision/66-VERIFICATION.md`).

## Why `1.0.0` Is Justified

Promotion is justified because the contract is explicit, narrow, documented, and verified:
- explicit canonical inventory in `mailglass_inbound/docs/api_stability.md`
- compatibility/deprecation posture routed through `guides/compatibility-and-deprecations.md`
- executable contract proof and release-gate evidence are green in Phases 64-66

## Blocker Status

No blocker is currently active.

If a release blocker appears during release ceremony execution, fallback posture is:
final explicit `0.4.0` confidence release with the framing `next is 1.0`.

## Compatibility Source of Truth

This artifact does not define a second contract inventory.
Compatibility and surface guarantees remain canonical in:
- `mailglass_inbound/docs/api_stability.md`
- `guides/compatibility-and-deprecations.md`

## Scope Guard

This decision does not reopen feature scope and does not propose:
matcher expansion, lifecycle callbacks, public replay/provider extension APIs,
public worker/queue contracts, synthetic UI, `gen_smtp`, or ecosystem integrations.
