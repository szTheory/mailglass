# Phase 148 Release Proof Ledger

This credential-free, PII-free ledger records the completed Mailglass-owned
evidence for the linked `mailglass` and `mailglass_admin` 2.4.0 release.
`mailglass_inbound` remains independently published at 2.1.1.

## Final Verdict

**PASS.** Core and admin 2.4.0 are public, inbound remains at 2.1.1, the
protected publish graph passed without an override, and a clean Phoenix host
installed and exercised the exact public package set. ASVS L1 unresolved
high-severity findings: **0**.

## Release Identity

| Field | Value |
| --- | --- |
| Release commit | `80986b95a2c98d4be12859eb69af5b6b9b3e6762` |
| Core | `mailglass` 2.4.0 — [GitHub release](https://github.com/szTheory/mailglass/releases/tag/mailglass-v2.4.0), [Hex](https://hex.pm/packages/mailglass/2.4.0) |
| Admin | `mailglass_admin` 2.4.0 — [GitHub release](https://github.com/szTheory/mailglass/releases/tag/mailglass_admin-v2.4.0), [Hex](https://hex.pm/packages/mailglass_admin/2.4.0) |
| Inbound | `mailglass_inbound` 2.1.1 — [Hex](https://hex.pm/packages/mailglass_inbound/2.1.1); consumed, not republished |
| Release Please run | [30727814826](https://github.com/szTheory/mailglass/actions/runs/30727814826) — success |
| Protected publish runs | [core tag: 30727822863](https://github.com/szTheory/mailglass/actions/runs/30727822863); [admin tag: 30727823211](https://github.com/szTheory/mailglass/actions/runs/30727823211) — success |
| Release-event consumer smoke | [30727822861](https://github.com/szTheory/mailglass/actions/runs/30727822861) — success |

Both GitHub releases are non-draft, non-prerelease releases published on
2026-08-02 and target the exact release commit above. Exact negative queries
confirmed that neither a GitHub release/tag nor a Hex release exists for
`mailglass_inbound` 2.4.0.

## Pre-publication Evidence

The release commit passed the repository's full local `mix ci` gate and the
protected workflow's tag-bound checks. The protected prepublish job reran the
Phase 148 proof bundle and recorded all four commands as passed:

| Proof | Canonical surface | Outcome |
| --- | --- | --- |
| Stream/address suppression | `test/mailglass/webhook/ingest_auto_suppress_test.exs` | Passed: unsubscribe remains stream-scoped; complaint and hard bounce remain address-wide. |
| Transactional suppression | `test/mailglass/suppression_test.exs` | Passed: complaint and hard-bounce suppression blocks transactional delivery. |
| B2C docs/package contract | `test/mailglass/docs_contract_test.exs` | Passed: examples parse and the B2C guide is packaged. |
| Tenant-scoped operator refresh | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | Passed: current-tenant refresh works and foreign-tenant broadcasts are rejected. |

The protected proof artifact is
`phase-148-release-proof-30727823211` (artifact ID `8827141331`). Its
`phase-148.json` SHA-256 is
`16fb0acf40b2c0136315c5f9b9ef8c0fd2e97fe24d39dd3f22b959053cd3885f`.
It binds the exact 2.4.0/2.4.0/2.1.1 package set to the release commit without
containing credentials or customer data.

## Protected Publication

Runs [30727822863](https://github.com/szTheory/mailglass/actions/runs/30727822863)
and [30727823211](https://github.com/szTheory/mailglass/actions/runs/30727823211)
were triggered by the core and admin release events respectively. Each
completed with:

| Job | Conclusion |
| --- | --- |
| `prepublish-summary` | success |
| `gate-ci-green` | success |
| `publish-core` | success |
| `publish-admin` | success |
| `publish-inbound` | skipped |

The gate evaluated exact-SHA CI and the dual-schema advisory matrix. Branch
protection was verified using the encrypted repository secret; no release gate
was bypassed or weakened. A release-fanout concurrency deadlock discovered
during the first attempt was fixed in PR
[#180](https://github.com/szTheory/mailglass/pull/180) by separating publish
and smoke concurrency groups.

## Post-publication Evidence

The canonical core release event ran the linked consumer proof. Run
[30727822861](https://github.com/szTheory/mailglass/actions/runs/30727822861)
completed successfully against the exact `mailglass-v2.4.0` release event and
release SHA. A separate fallback-dispatch rehearsal also passed in run
[30729042943](https://github.com/szTheory/mailglass/actions/runs/30729042943).

| Proof | Exact input / result | Outcome |
| --- | --- | --- |
| Registry readiness | core/admin 2.4.0; inbound 2.1.1 | Hex and HexDocs checks passed. |
| Fresh consumer | `DEP_MODE=hex`, `VERSION=2.4.0`, `VERSION_INBOUND=2.1.1`, `INCLUDE_INBOUND=true` | Fresh Hex resolution and compilation passed for all three packages. |
| Generated host | Phoenix installer plus Mailglass installer | `OPS-01 guard passed`; generated host compiled and booted. |
| HTTP runtime | `GET /dev/mail/` | HTTP 200; endpoint smoke passed. |
| Published trust journey | install, preview, send, signed webhook ingest, operator no-match diagnosis | Five checkpoints passed. |
| Registry integrity | package retraction checks | Passed. |

The canonical release-event trust artifact is
`trust-runner-published-30727822861` (artifact ID `8827594852`). Its
`checkpoint.json` SHA-256 is
`24858ca83da8ba49e7c2a2b500bc4c5aae676134f408b7e2928ea0bf95b2e29a`;
the checkpoint payload's deterministic content hash is
`4daaf66d42dccbe5401899de23ba0e455b1c6b74a7c9efab6b56682c76f6d281`.
The workflow automatically closed failure tracker issue
[#179](https://github.com/szTheory/mailglass/issues/179) after the successful
consumer and trust jobs.

## Historical Blockers Resolved

Earlier evidence was correctly recorded as no-go because it came from a dirty
workspace, core/admin still declared 2.3.0, package checks were incomplete, and
release-SHA CI was unavailable. Those were historical preconditions, not
waivers. PRs [#165](https://github.com/szTheory/mailglass/pull/165),
[#167](https://github.com/szTheory/mailglass/pull/167),
[#168](https://github.com/szTheory/mailglass/pull/168), and
[#178](https://github.com/szTheory/mailglass/pull/178) resolved them before the
release PR [#169](https://github.com/szTheory/mailglass/pull/169) merged.

## Scope Boundaries

This proves the Mailglass package release and adopter-install boundary only.
External B2C Alpha launch gates for Sigra, Chimeway, Parapet, Accrue, and host
recovery remain separate production-adoption work. Crosswake remains excluded:
no Crosswake behavior or `crosswake_mailglass` package was added.
