---
phase: 148
slug: release-and-adoption-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-01
---

# Phase 148 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit across the root and `mailglass_admin` Mix projects, plus GitHub Actions workflow-contract and published-consumer checks |
| **Config file** | `test/test_helper.exs`, `mailglass_admin/test/test_helper.exs`, `.github/workflows/ci.yml`, `.github/workflows/post-publish-smoke.yml` |
| **Quick run command** | `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs test/mailglass/suppression_test.exs test/mailglass/docs_contract_test.exs test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` |
| **Full suite command** | `mix ci` plus the protected package CI lanes required by `.github/workflows/publish-hex.yml` |
| **Estimated runtime** | Focused local proof under 2 minutes; full matrix and published-package proof are CI/release-bound |

---

## Sampling Rate

- **After every task commit:** Run the focused test command for the touched proof or workflow-contract surface.
- **After every plan wave:** Run the combined focused core proof and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors`; run `mix ci` after workflow changes.
- **Before `$gsd-verify-work`:** Full suite, protected publish gate, and published Hex-mode consumer smoke must be green.
- **Max feedback latency:** 120 seconds for local focused checks; release-only evidence is explicitly deferred to the publication checkpoint.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0/1 | REL-01 | T-148-01 | Release events cannot expose secrets or republish inbound; manual inbound-only dispatch remains explicit | workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` | ❌ W0 extension | ⬜ pending |
| TBD | TBD | 1 | PROOF-02 | N/A | Stream-scoped unsubscribe and address-wide complaint/bounce suppression retain their locked scopes | unit/integration | `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs test/mailglass/suppression_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | PROOF-03 | N/A | Published B2C examples use current APIs and the guide remains packaged | contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | PROOF-01 bundle | T-148-02 | Foreign-tenant events cannot refresh the selected tenant's operator UI | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | release | REL-01 | T-148-03 | Protected publication releases only intended packages and the fresh consumer resolves actual Hex artifacts | published E2E | `.github/workflows/post-publish-smoke.yml` runs `DEP_MODE=hex scripts/consumer_install_smoke.sh` after Hex and HexDocs readiness | ✅ workflow | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/scripts/linked_release_concurrency_test.exs` (or add a focused peer contract test) to assert release-event core/admin-only fan-out and preservation of the inbound-only manual path.
- [ ] Add a deterministic compatibility assertion for unchanged `mailglass_inbound` 2.1.1 against core 2.4.0 while retaining the live published resolver smoke as final proof.
- [ ] Define a credential-free, PII-free release-proof summary/artifact location.

---

## Protected External Verifications

| Behavior | Requirement | Why External | Automated Verification |
|----------|-------------|--------------|------------------------|
| Linked core/admin 2.4.0 packages are published while inbound remains 2.1.1 | REL-01 | Requires protected release events, Hex credentials, registry propagation, and real published artifacts | Release-target validation, protected publish jobs, GitHub/Hex API checks, and explicit absence of an inbound 2.4.0 release. |
| Clean consumer resolves and boots from published packages | REL-01 | Final evidence requires packages and HexDocs to exist on Hex | `post-publish-smoke.yml` retains successful `DEP_MODE=hex` consumer-smoke evidence after bounded readiness polling. |

No human verification or UAT is required. External checks are observed and evaluated by automation; any missing or red evidence fails closed.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Local feedback latency < 120 seconds
- [ ] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
