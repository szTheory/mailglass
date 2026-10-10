---
phase: "173"
slug: "consistency-and-delivery-evidence"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 173 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Demo app and browser evidence runner | Resets are restricted to a disposable run-owned Compose project; the retained review preview is isolated. | Synthetic fixture state, run identity, reset token, screenshots |
| Capture process and retained artifacts | Manifests must describe actual owned PNG bytes and source/build/served asset identity. | PNG bytes, hashes, source and asset metadata |
| Original workspace and detached candidate | Candidate evidence is derived from an exact committed SHA; owner-dirty paths stay excluded. | Commit SHA, path/status metadata, pinned baseline bytes |
| Candidate and CI result | Only a successful required CI conclusion for the exact candidate SHA supports delivery completion. | Candidate SHA, workflow conclusion, run URL |
| Admin capture and CI discovery | CI capture uses only the named synthetic fixture, and actual writes enforce CSS identity. | Synthetic mail preview and CSS hashes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-173-01 | Denial of Service | Evidence runner cleanup | high | mitigate | Run-owned Compose project, unique ports, and scoped cleanup (`scripts/run_demo_browser_evidence.sh:7,25,47-59`). | closed |
| T-173-02 | Information Disclosure | Browser screenshots and JSON | high | mitigate | Fixed synthetic captures and allowlisted retention (`reference/demo_app/assets/e2e/phase173-evidence.spec.js:240-259`; `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:262-276,330-344`). | closed |
| T-173-03 | Tampering | Capture paths and SHA-256 | high | mitigate | Owned-path validation, candidate identity, and PNG byte hashes (`reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:89-122,170-173,238-246`). | closed |
| T-173-04 | Repudiation | Current versus historical render claims | medium | mitigate | Pinned baseline source and byte identity prevent historical output from being labeled current (`reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:22-30,189-223,270-276`). | closed |
| T-173-05 | Tampering | Admin capture manifest | high | mitigate | Owned relative paths and actual PNG/source/build/served byte checks (`mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex:146-165,189-208`). | closed |
| T-173-06 | Information Disclosure | Admin preview fixtures | high | mitigate | CI discovery is restricted to synthetic `HappyMailer` before discovery (`mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex:55-64,79-85`). | closed |
| T-173-07 | Denial of Service | Browser evidence reset | high | mitigate | Disposable-project identity and reset-token checks guard reset (`reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:174-189,212-241`). | closed |
| T-173-08 | Repudiation | Token and review guidance | medium | mitigate | Current guide/source token parity is tested (`mailglass_admin/docs/design-system.md:4-9,146`; `mailglass_admin/test/mailglass_admin/token_parity_test.exs:197-214`). | closed |
| T-173-09 | Repudiation | Exact-candidate CI assertion | high | mitigate | Exact SHA and required `CI Green` are mandatory for a passed delivery result (`scripts/check_phase173_candidate.sh:371-407,526-529`). | closed |
| T-173-10 | Tampering | Candidate checkout and generated assets | high | mitigate | Dirty-path snapshot, clean detached checkout, ancestry, and served CSS checks (`scripts/check_phase173_candidate.sh:21-56,148-151,181-215,344-360`). | closed |
| T-173-11 | Denial of Service | Owner preview during delivery review | high | mitigate | Separate review project and ports; scoped cleanup preserves retained projects (`scripts/check_phase173_candidate.sh:298-308`; `scripts/run_demo_browser_evidence.sh:47-59`). | closed |
| T-173-12 | Information Disclosure | Retained handoff artifacts | medium | mitigate | Delivery record emits scoped paths, hashes, statuses, and run URLs without message or token data (`scripts/check_phase173_candidate.sh:537-566`). | closed |
| T-173-13 | Information Disclosure | Demo artifact retention | high | mitigate | Only six fixed synthetic PNG pairs and sanitized checkpoint are staged for success-only upload (`reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:262-276,330-344`; `.github/workflows/ci.yml:1046-1053`). | closed |
| T-173-14 | Tampering | Admin actual manifest writers | high | mitigate | Both actual writer paths reject built/served CSS hash divergence (`mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex:73-75,103-112,146-165`). | closed |
| T-173-15 | Information Disclosure | CI Admin discovery | high | mitigate | CI allowlist precedes discovery and selects the synthetic fixture (`mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex:55-64,79-85`; `.github/workflows/ci.yml:1153-1163`). | closed |
| T-173-16 | Denial of Service | Demo evidence reset | high | mitigate | Shared read-only preflight verifies the run-owned app marker before reset; both screenshot producers call it (`reference/demo_app/assets/scripts/check-persona-reset-target.cjs:32-60`; `reference/demo_app/assets/e2e/phase173-evidence.spec.js:239-240`; `reference/demo_app/assets/e2e/persona-screenshots.spec.js:151`). | closed |
| T-173-SC | Tampering | Package supply chain | high | mitigate | Exact package-lock gate runs before all four demo browser install paths (`reference/demo_app/assets/scripts/check-demo-browser-deps.cjs:59-82`; `scripts/run_demo_browser_evidence.sh:88`; `compose.demo.yml:91-94`; `reference/demo_app/Dockerfile:11-12`; `reference/demo_app/mix.exs:83-84`). | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*Severity: critical > high > medium > low — only open threats at or above the configured high threshold count toward `threats_open`.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-10 | 17 | 17 | 0 | gsd-security-auditor (ASVS Level 1) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-10

The security gate is clear. The separate exact-candidate delivery gate remains incomplete; UIQ-03 is still Pending until its required delivery evidence passes.
