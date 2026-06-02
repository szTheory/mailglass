---
phase: 71-inbound-release-truth-preflight
status: passed
verified_at: 2026-06-02
requirements:
  - REL-01
  - PROOF-01
---

# Phase 71 Verification: Inbound Release Truth Preflight

## Result

Phase 71 passed. The release-truth preflight now proves current
`mailglass_inbound` `1.0.0` source/package truth through the existing
repo-native lane and separates required proof from advisory checks.

## Command Evidence

| Command | Result | Evidence |
|---------|--------|----------|
| `mix mailglass.publish.check --package mailglass_inbound` | PASS | Pre-publish check completed with `conflict=0`; `.planning/publish/mailglass_inbound-publish-summary.json` remains the canonical generated evidence. |
| `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` | PASS | 6 tests, 0 failures. |
| `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | PASS | 24 tests, 0 failures, 1 skipped pre-existing skipped test. |

## Phase 71 Blockers Resolved

| Item | Disposition | Rationale |
|------|-------------|-----------|
| Root `README.md` described `mailglass_inbound` as `v0.5+`. | Phase 71 blocker resolved. | This contradicted current source/package truth for inbound `1.0.0`. The README now states inbound has its own stable `1.0` contract and independent package release line. |
| Root `README.md` said `mailglass_inbound` was outside the `v1.x` stability promise for the milestone. | Phase 71 blocker resolved. | The stale wording blurred the Phase 66 release-position decision. The README now routes inbound stability truth to `mailglass_inbound/docs/api_stability.md`. |
| `MAINTAINING.md` smoke-install example used `{:mailglass_inbound, "~> 0.3"}`. | Phase 71 blocker resolved. | The runbook now uses `{:mailglass_inbound, "~> 1.0"}` for the inbound `1.0.0` smoke lane. |
| `MAINTAINING.md` fallback example implied a core-only `mailglass-v1.0.0` tag for recovery. | Phase 71 blocker resolved. | The fallback path now names package-specific recovery and the inbound-only `mailglass_inbound-v1.0.0` tag shape. |
| Required release proof versus provider-live proof could drift in runbook wording. | Phase 71 blocker resolved. | `MAINTAINING.md` now states required inbound release proof is deterministic repo/package/workflow evidence and provider-live/ecosystem canaries remain advisory unless a specific release claim depends on them. |

## Deferred Stale Claims

| Item | Deferred To | Rationale |
|------|-------------|-----------|
| `reference/host_app/mix.exs` published-Hex mode still pins `mailglass_inbound` `~> 0.3`. | Phase 73 | Inbound `1.0.0` is not yet published, so updating published-Hex smoke pins before the publish ceremony can make the reference app resolve an unavailable version. Phase 73 owns post-publish smoke/install pin truth. |
| `reference/demo_app/mix.exs` published-Hex mode still pins `mailglass_inbound` `~> 0.3.0`. | Phase 73 | Same as the host app: this is post-publish Hex truth, not a Phase 71 source/package preflight blocker. |
| `guides/compatibility-and-deprecations.md` still contains broad `mailglass_inbound 0.x` compatibility wording. | Phase 72 | Phase 72 owns public contract wording and stale-claim guard expansion. The stale guide wording does not invalidate REL-01/PROOF-01 because Phase 71 now guards root release truth and runbook release proof boundaries. |

## Verification Notes

- `mix mailglass.publish.check --package mailglass_inbound` remains the single canonical preflight; no duplicate tarball/package verifier was added.
- Exact Phase 71 release truth is now asserted in `test/mailglass/stability_contract_test.exs` across manifest, source version, changelog, package README install pin, root README status, publish pin, and publish-summary output.
- Root docs/runbook blocker fixes are guarded in `test/mailglass/docs_contract_test.exs`.
