---
phase: 64
slug: contract-verification-hardening
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-31
---

# Phase 64 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| source annotations -> compiled docs | Stable runtime modules and entrypoints cross from source comments into executable contract proof via `Code.fetch_docs/1`. | Runtime module and function metadata. |
| error/task source metadata -> compiled docs | Stable error and operator task metadata become part of the package's executable public contract. | Structured-error metadata and Mix task module metadata. |
| testing helper source metadata -> compiled docs | Adopter-facing testing helpers ship in `lib/` and therefore cross into the public package contract if metadata is wrong. | Testing helper module, function, and macro metadata. |
| canonical docs -> contract proof | The canonical inbound inventory and adoption docs feed directly into the fail-closed `docs_contract_test.exs` lane. | Public documentation claims and closed type-set inventories. |
| package-local proof -> root aggregate gate | The inbound package's contract proof becomes part of the root `mix verify.stability_contract` gate via alias delegation. | Package-local support-contract verification results. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-64-01 | Tampering | stable runtime metadata | mitigate | Runtime modules and direct entrypoints carry the expected `0.1.0` / `0.2.0` since metadata; `cd mailglass_inbound && mix compile --warnings-as-errors` passed. Evidence: `mailglass_inbound/lib/mailglass_inbound.ex:2`, `mailglass_inbound/lib/mailglass_inbound/router.ex:40`, `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex:2`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:35`. | closed |
| T-64-02 | Repudiation | version-history truth for public seams | mitigate | Stale runtime tags are corrected to package-history versions and enforced by the compiled-doc contract test. Evidence: `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex:119`, `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex:32`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:60`. | closed |
| T-64-03 | Tampering | stable structured-error metadata | mitigate | `MIMEError`, `SignatureError`, and `S3FetchError` carry `@moduledoc since: "0.2.0"` and `__types__/0` since metadata; targeted error tests passed. Evidence: `mailglass_inbound/lib/mailglass_inbound/mime_error.ex:2`, `mailglass_inbound/lib/mailglass_inbound/signature_error.ex:2`, `mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex:2`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:76`. | closed |
| T-64-04 | Elevation of privilege | operator task API boundary | mitigate | Operator task modules have module-level metadata only; `run/*` functions remain without direct `@doc since:` guarantees and are explicitly excluded by the contract test. Evidence: `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex:14`, `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex:40`, `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex:42`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:121`. | closed |
| T-64-05 | Tampering | testing helper metadata | mitigate | Adopter-facing testing helper modules and direct helper functions/macros are pinned to `0.2.0`. Evidence: `mailglass_inbound/lib/mailglass_inbound/fixtures.ex:2`, `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:2`, `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:2`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:82`. | closed |
| T-64-06 | Elevation of privilege | testing/runtime boundary | mitigate | Only D-04 testing-bucket helpers receive since metadata; internal helpers stay `@doc false`; required helper test lanes passed. Evidence: `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:158`, `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:261`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:121`. | closed |
| T-64-07 | Tampering | inbound contract docs | mitigate | Docs contract performs exact closed-set checks for MIME, Signature, and S3 `__types__/0`; docs/error test lane passed. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:478`, `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:76`. | closed |
| T-64-08 | Repudiation | release-line and install truth | mitigate | Inbound install pins and changelog release posture are refreshed to `~> 0.3`, `~> 1.3`, and current `0.3.0` truth; docs-contract lane passed. Evidence: `mailglass_inbound/README.md:69`, `mailglass_inbound/README.md:70`, `mailglass_inbound/CHANGELOG.md:94`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:460`. | closed |
| T-64-09 | Elevation of privilege | stable/deferred boundary | mitigate | Section-scoped forbidden-claim checks reject stable/adoption over-claims while allowing clearly deferred references; docs-contract lane passed. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:260`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:271`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:412`. | closed |
| T-64-10 | Repudiation | compiled-doc stability proof ownership | mitigate | `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` is the authoritative inbound compiled-doc proof and its targeted lane passed. Evidence: `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs:1`, `mailglass_inbound/mix.exs:49`. | closed |
| T-64-11 | Elevation of privilege | root verification alias wiring | mitigate | Root `verify.stability_contract` delegates to `cmd --cd mailglass_inbound mix verify.support_contract.inbound`; root test pins that string; both package and root aggregate gates passed. Evidence: `mix.exs:276`, `mix.exs:279`, `test/mailglass/stability_contract_test.exs:55`, `test/mailglass/stability_contract_test.exs:59`. | closed |
| T-64-12 | Tampering | docs-only lane meaning | mitigate | `verify.docs.contract.inbound` remains docs-only, while `verify.support_contract.inbound` separately adds compiled-doc proof coverage. Evidence: `mailglass_inbound/mix.exs:46`, `mailglass_inbound/mix.exs:49`, `mix.exs:286`. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-31 | 12 | 12 | 0 | Codex |

---

## Verification Evidence

Executed successfully on 2026-05-31:

| Command | Result |
|---------|--------|
| `cd mailglass_inbound && mix compile --warnings-as-errors` | passed |
| `cd mailglass_inbound && mix test test/mailglass_inbound/mime_error_test.exs test/mailglass_inbound/signature_error_test.exs test/mailglass_inbound/s3_fetch_error_test.exs --warnings-as-errors` | passed, 20 tests |
| `cd mailglass_inbound && mix test test/mailglass_inbound/fixtures_test.exs test/mailglass_inbound/test/ingress_test.exs --warnings-as-errors` | passed |
| `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs test/mailglass_inbound/mailbox_case_test.exs --warnings-as-errors` | passed, 20 tests |
| `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/mime_error_test.exs test/mailglass_inbound/signature_error_test.exs test/mailglass_inbound/s3_fetch_error_test.exs --warnings-as-errors` | passed, 37 tests |
| `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | passed, 17 tests |
| `cd mailglass_inbound && mix test test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` | passed, 7 tests |
| `cd mailglass_inbound && mix verify.support_contract.inbound` | passed, 24 tests |
| `mix verify.stability_contract` | passed: core lane 1 property, 75 tests, 1 skipped; admin/inbound/docs lanes passed |

No `## Threat Flags` sections were present in the phase summaries.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-31
