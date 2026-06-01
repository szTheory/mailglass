---
phase: 65
slug: compatibility-docs-and-dx-lock
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 65 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| README/guide prose -> adopter setup behavior | Adopters copy setup steps and compatibility rules directly from inbound docs. | Public setup and compatibility guidance |
| CLI/operator docs -> tenant-affecting operator actions | Operators follow documented replay, prune, and doctor semantics for tenant-scoped stored inbound data. | Tenant-scoped operational actions |
| testing/admin docs -> adopter expectations | Adopters build tests and admin workflows around surfaces the docs imply are stable. | Public testing harness and admin trust-boundary guidance |
| executable docs checks -> release-blocking verification | Docs-contract tests and Tier 1 docs checks decide whether release docs remain acceptable. | Release-blocking verification signal |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-65-01 | Repudiation | `mailglass_inbound/README.md` + `mailglass_inbound/docs/inbound-install.md` | mitigate | README remains the canonical adoption lane, install guide is subordinate, and docs-contract assertions verify routing. Evidence: `mailglass_inbound/README.md:4`, `mailglass_inbound/README.md:198`, `mailglass_inbound/docs/inbound-install.md:261`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:475`. | closed |
| T-65-02 | Tampering | `guides/compatibility-and-deprecations.md` | mitigate | Compatibility guidance routes to `mailglass_inbound/docs/api_stability.md`, preserves stable-vs-internal/deferred semantics, and includes a deprecation-DX inventory. Evidence: `guides/compatibility-and-deprecations.md:200`, `guides/compatibility-and-deprecations.md:209`, `guides/compatibility-and-deprecations.md:213`. | closed |
| T-65-03 | Spoofing | repo docs topology | mitigate | `guides/compatibility-and-deprecations.md` remains the only repo-root compatibility authority; `docs/compatibility-and-deprecations.md` is absent and forbidden-token assertions protect against rerouting. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:514`. | closed |
| T-65-04 | Elevation of Privilege | replay/prune operator docs | mitigate | Operator docs preserve tenant guards, confirmation tiers, exit semantics, and destructive behavior. Evidence: `mailglass_inbound/docs/inbound-operator.md:46`, `mailglass_inbound/docs/inbound-operator.md:113`, `mailglass_inbound/docs/inbound-operator.md:144`, `mailglass_inbound/docs/inbound-operator.md:190`. | closed |
| T-65-05 | Tampering | prune/replay semantics | mitigate | Replay is documented as stored-truth recovery, prune remains explicitly destructive, and routing-debug guidance routes command semantics to the canonical operator guide. Evidence: `mailglass_inbound/docs/inbound-operator.md:156`, `mailglass_inbound/docs/inbound-operator.md:190`, `mailglass_inbound/docs/inbound-routing-debug.md:301`. | closed |
| T-65-06 | Repudiation | testing/admin trust docs | mitigate | Testing docs require `async: false`, process-local capture, and one-assertion-per-drive semantics; admin trust docs keep UI/DOM/component surfaces non-contractual. Evidence: `mailglass_inbound/docs/inbound-testing.md:17`, `mailglass_inbound/docs/inbound-testing.md:68`, `mailglass_inbound/docs/inbound-testing.md:125`, `mailglass_admin/docs/operator-trust.md:100`. | closed |
| T-65-07 | Repudiation | inbound docs-contract test | mitigate | Docs-contract assertions lock canonical README/install/compatibility routing. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:475`. | closed |
| T-65-08 | Tampering | Tier 1 docs checker | mitigate | `mix mailglass.docs.check` encodes required/forbidden tokens for adoption, compatibility, operator, testing, and admin trust docs. Evidence: `lib/mix/tasks/mailglass.docs.check.ex:251`, `lib/mix/tasks/mailglass.docs.check.ex:347`, `lib/mix/tasks/mailglass.docs.check.ex:380`, `lib/mix/tasks/mailglass.docs.check.ex:417`. | closed |
| T-65-09 | Spoofing | compatibility topology | mitigate | Repo-root compatibility story stays anchored to `guides/compatibility-and-deprecations.md`; no second repo-root compatibility doc exists. Evidence: `guides/compatibility-and-deprecations.md:198`. | closed |
| T-65-10 | Elevation of Privilege | operator docs contract | mitigate | Docs-contract assertions require tenant guards, exit semantics, dry-run/confirmation behavior, and stored-truth replay framing. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:294`. | closed |
| T-65-11 | Spoofing | replay/admin trust wording | mitigate | Docs-contract and Tier 1 checks require negative-boundary replay phrasing and reject fresh-receive, silent-reroute, and stable-UI overclaims. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:309`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:348`, `lib/mix/tasks/mailglass.docs.check.ex:392`. | closed |
| T-65-12 | Repudiation | testing harness docs | mitigate | Testing guide is locked to `MailglassInbound.MailboxCase`, `Test.Ingress`, `async: false`, process-local capture, and one-assertion-per-drive behavior. Evidence: `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:319`, `mailglass_inbound/docs/inbound-testing.md:17`, `mailglass_inbound/docs/inbound-testing.md:125`. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 12 | 12 | 0 | Codex / gsd-security-auditor |

## Security Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Threats found | 12 |
| Closed | 12 |
| Open | 0 |

Verification:

- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` - passed (`22 tests, 0 failures`)
- `mix mailglass.docs.check` - passed (`OK - Tier 1 docs match the stability contract.`)
- `mix verify.stability_contract` - passed (`1 property, 75 tests, 0 failures, 1 skipped`; downstream suites `35 tests, 0 failures` and `29 tests, 0 failures`; non-failing warnings emitted)

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-01
