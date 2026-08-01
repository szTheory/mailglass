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
| Commit SHA | pending |
| Core tag | pending |
| Admin tag | pending |
| GitHub release URL | pending |

## Pre-publication Evidence

| Proof | Canonical command | Commit SHA | Exit status | Observed outcome |
| --- | --- | --- | --- | --- |
| PROOF-02 webhook-to-suppression scope | `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs --warnings-as-errors` | pending | pending | pending |
| PROOF-02 pre-send transactional suppression | `mix test test/mailglass/suppression_test.exs --warnings-as-errors` | pending | pending | pending |
| PROOF-03 B2C examples and HexDocs/package registration | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | pending | pending | pending |
| Phase 147 tenant-scoped LiveView refresh and foreign-tenant rejection | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | pending | pending | pending |
| Linked-release workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors` | pending | pending | pending |
| Path-mode fresh-consumer smoke | `DEP_MODE=path MAILGLASS_PATH="$PWD" WORK_DIR="${TMPDIR:-/tmp}" bash scripts/consumer_install_smoke.sh` | pending | pending | pending |

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

## Scope Boundaries

External B2C launch gates remain separate production-adoption blockers for
Sigra, Chimeway, Parapet, Accrue, and host recovery. They are not evidence that
the Mailglass release is complete. Crosswake is excluded: this phase adds no
Crosswake behavior and no `crosswake_mailglass` package.
