# Phase 148 Release Proof Ledger

This credential-free, PII-free ledger records the Mailglass-owned evidence for
the linked `mailglass` and `mailglass_admin` 2.4.0 release. `mailglass_inbound`
remains independently published at 2.1.1.

## Release Target

| Field | Value |
| --- | --- |
| Core package | `mailglass` 2.4.0 |
| Admin package | `mailglass_admin` 2.4.0 |
| Inbound package | `mailglass_inbound` 2.1.1 (consumed, not published) |
| Commit SHA | `d965fb0186c554b9280ca7414187bf73d85aae3e` (HEAD at evidence start; workspace was dirty) |
| Core tag | pending |
| Admin tag | pending |
| GitHub release URL | pending |

## Pre-publication Evidence

| Proof | Canonical command | Commit SHA | UTC timestamp | Exit status | Observed outcome |
| --- | --- | --- | --- | --- | --- |
| PROOF-02 webhook-to-suppression scope | `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:22:31Z | 0 | Included in the 52-test focused run (0 failures; 1 skipped): stream unsubscribe is `address_stream`; complaint and hard bounce are address-wide. |
| PROOF-02 pre-send transactional suppression | `mix test test/mailglass/suppression_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:22:31Z | 0 | Included in the 52-test focused run (0 failures; 1 skipped): complaint and hard-bounce address suppression blocks transactional delivery. |
| PROOF-03 B2C examples and HexDocs/package registration | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:22:31Z | 0 | Included in the 52-test focused run (0 failures; 1 skipped): B2C parse/package surface passed. |
| Phase 147 tenant-scoped LiveView refresh and foreign-tenant rejection | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:22:35Z | 0 | 79 tests, 0 failures: visible status refreshes only for the current tenant; foreign-tenant broadcast is rejected. |
| Linked-release workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:24:34Z | 0 | 21 tests, 0 failures: linked-release, recovery, and post-publish workflow contracts passed. |
| Path-mode fresh-consumer smoke | `proof_work_dir=$(mktemp -d) && DEP_MODE=path MAILGLASS_PATH="$PWD" WORK_DIR="$proof_work_dir" bash scripts/consumer_install_smoke.sh` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:22Z | inconclusive | Fresh work directory `/tmp/mailglass-148-03-path.dARLqI` was created; generated Phoenix host compiled, but execution transport truncated before a reliable script exit code could be retained. This is not green evidence. |

The four canonical behavioral test files are retained as the proof surface:
`test/mailglass/webhook/ingest_auto_suppress_test.exs`,
`test/mailglass/suppression_test.exs`, `test/mailglass/docs_contract_test.exs`,
and `mailglass_admin/test/mailglass_admin/operator_live_test.exs`. This ledger
does not replace or duplicate their tests.

## Protected Publication

| Field | Value |
| --- | --- |
| Protected workflow | `.github/workflows/publish-hex.yml` |
| Required environment | `hex-publish` |
| GitHub run URL | pending |
| Artifact name | pending |
| Core publish outcome | pending |
| Admin publish outcome | pending |
| Inbound publish outcome | pending — must remain unpublished for this release event |

The protected release event fans out only to core and admin after the gate and
core publish succeed. Inbound-only, admin-only, and `all` recovery remain
explicit `workflow_dispatch` paths. The static `mailglass-linked-release-fanout`
concurrency group does not cancel in-progress runs.

## Post-publication Evidence

| Proof | Command / workflow | Package versions | GitHub run URL | Artifact name | Exit status | Observed outcome |
| --- | --- | --- | --- | --- | --- | --- |
| Hex-mode fresh-consumer smoke | `.github/workflows/post-publish-smoke.yml` → `DEP_MODE=hex VERSION=2.4.0 VERSION_INBOUND=2.1.1 INCLUDE_INBOUND=true bash scripts/consumer_install_smoke.sh` | core/admin 2.4.0; inbound 2.1.1 | pending | pending | pending | pending |
| Hex and HexDocs readiness | `wait-for-index` and `wait-for-hexdocs` jobs | core/admin 2.4.0; inbound 2.1.1 | pending | pending | pending | pending |

`DEP_MODE=path` is shift-left evidence only. The eventual `DEP_MODE=hex` run is
the release completion proof because it resolves the packages adopters install;
it must fail closed if `mailglass_inbound` 2.1.1 is absent or lacks a recognized
compatible core constraint.

### Evidence provenance and current blockers

The commands above executed in a workspace with uncommitted Phase 147/B2C changes.
The recorded HEAD SHA identifies the base revision, not a clean release candidate;
therefore these local results cannot satisfy a commit-bound or published-artifact
claim. The path-mode result is additionally inconclusive and must be rerun to a
retained exit status before it can be a green shift-left input. Hex-mode proof
remains pending and is never inferred from path mode.

## Release-Workflow and Package Preflight Evidence

| Go/no-go input | Exact command / assertion | Commit SHA | UTC timestamp | Exit status | Observed outcome |
| --- | --- | --- | --- | --- | --- |
| Core/admin/inbound manifest target | `jq -c '{core: .["."], admin: .mailglass_admin, inbound: .mailglass_inbound}' .release-please-manifest.json` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:27Z | 0 | **BLOCKED:** manifest is core/admin `2.3.0`, inbound `2.1.1`; it is not the required core/admin `2.4.0` candidate set. |
| Linked release, recovery, and post-publish workflow contracts | `mix test test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:24:34Z | 0 | 21 tests, 0 failures. |
| Core package publish check | `mix mailglass.publish.check --package mailglass` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:26:16Z | 1 | **BLOCKED:** package allowlist rejects uncommitted `guides/b2c-first-adopter.md`; no allowlist or guide was changed by this plan. |
| Admin package publish check | `mix mailglass.publish.check --package mailglass_admin` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:26Z | inconclusive | The check reached isolated tarball compilation, but the execution transport did not retain a final exit status. This is not green evidence. |
| Workflow syntax lint | `actionlint .github/workflows/publish-hex.yml .github/workflows/release-please.yml .github/workflows/post-publish-smoke.yml` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:27:39Z | 0 | Passed. |
| Full repository gate | `mix ci` | `d965fb0186c554b9280ca7414187bf73d85aae3e` | 2026-08-01T23:27:35Z | 1 | **BLOCKED:** `--check-formatted` reports unformatted workflow-contract tests from prior work; they were not modified here. |

### ASVS L1 mitigation review

ASVS L1 unresolved high-severity findings: 3

1. **T-148-11 (evidence provenance):** the local focused results ran against a dirty workspace, so their HEAD SHA is not a clean release-candidate binding.
2. **T-148-12 (candidate package set):** the manifest is still core/admin `2.3.0`, and the core publish check rejects the uncommitted guide from its package allowlist.
3. **T-148-14 (release-SHA CI):** `mix ci` is red on existing formatting failures; a green release-SHA CI result is unavailable.

**T-148-13 (bounded evidence handling) is mitigated:** this ledger records only commands, SHA, timestamps, exit states, version values, and bounded outcomes; it contains no environment values, credentials, recipient data, or message content. Plan 04 must not offer `go` until the three findings are resolved and this count is recorded as zero.

## Scope Boundaries

External B2C launch gates remain separate production-adoption blockers for
Sigra, Chimeway, Parapet, Accrue, and host recovery. They are not evidence that
the Mailglass release is complete. Crosswake is excluded: this phase adds no
Crosswake behavior and no `crosswake_mailglass` package.
