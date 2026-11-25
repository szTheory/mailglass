---
phase: "180"
slug: reproducible-admin-bundle-and-before-catalog
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-17"
---

# Phase 180 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CSS inputs to generated Admin bundle | Tailwind scans source and produces the shipped CSS | Source text, executable, and CSS bytes |
| Admin preview route to browser | Preview tabs cross the operator surface boundary | Route parameters and theme values |
| Theme cookie to render | Client preference selects the page theme | Cookie value and closed theme set |
| Playwright to demo reset | Browser tests request disposable demo state | Local origin, run token, reset target |
| Demo producer to evidence catalog | Capture output becomes checked-in before-catalog evidence | PNGs, aria sidecars, manifests, and marker hashes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-180-01 | Tampering | Admin bundle check | high | mitigate | Rebuilds pinned Tailwind output to a temporary file and compares exact bytes against the committed bundle; positive and mismatch controls exist (`assets_check.ex`, `bundle_reproducibility_contract_test.exs`) | closed |
| T-180-02 | Tampering | Tailwind download | medium | accept | TLS peer verification is enabled; the downloaded executable remains a trust dependency without a per-run checksum pin. Byte comparison catches accidental bundle drift, but cannot prevent a malicious executable from copying the committed CSS | closed |
| T-180-03 | DoS / Repudiation | Asset check installer | high | mitigate | Installer and build failures propagate as errors rather than being converted into a pass; raising-installer contract test covers fail-closed behavior | closed |
| T-180-04 | Repudiation | Required Admin CI lane | high | mitigate | The support-contract alias starts with the bundle check and is required by CI Green; wiring and negative controls are asserted in the Admin contract lane | closed |
| T-180-05 | Tampering | Temporary bundle output | medium | mitigate | The check writes to a temporary output and replaces nothing under `priv/static`; tests assert protected-directory behavior | closed |
| T-180-06 | Tampering | Theme preference cookie | low | accept | The existing client-controlled cookie remains constrained to a closed theme set and fixed options; no phase-added inputs broaden the set | closed |
| T-180-07 | Elevation of privilege / Information Disclosure | Preview sandbox | high | mitigate | Preview iframe sandbox attributes are exact and contract-tested; only the intended sandbox appears in production | closed |
| T-180-08 | Tampering | Preview backdrop | low | mitigate | Backdrop theme interpolation uses a closed-value helper | closed |
| T-180-09 | Tampering | Theme ownership contract | medium | mitigate | Static and rendered checks cover surface counts, all library views, planted violations, and the single root theme owner | closed |
| T-180-10 | Repudiation | Theme ownership browser test | medium | mitigate | Browser evidence is explicitly advisory and distinguished from the required Admin lane | closed |
| T-180-11 | Tampering | Gallery and demo matrices | medium | mitigate | Required structural tests preserve the planned theme and viewport matrices; demo coverage retains its own explicit scope | closed |
| T-180-12 | DoS | Theme browser timing | low | accept | Connected-state waits, polling, and bounded retries reduce timing flakes; the advisory browser check can still be timing-sensitive | closed |
| T-180-13 | Tampering | Before-catalog producer | high | mitigate | Capture paths reject symlinks, traversal, unsafe slugs, and collisions; promotion is atomic and manifest tests cover path and file validation | closed |
| T-180-14 | Information Disclosure | Demo capture fixtures | high | mitigate | Fixtures use reserved synthetic addresses; driver and validator reject real addresses and reset tokens and enforce a closed privacy schema | closed |
| T-180-15 | Tampering / DoS | Demo reset endpoint | medium | mitigate | Reset calls use a local-origin, run-ID, token, and health-marker guard and reject redirects (`check-persona-reset-target.cjs`) | closed |
| T-180-16 | Repudiation | Capture identity and freshness | high | mitigate | Producer verifies source, served bytes, and run identity; manifest tests bind capture evidence to current source and reject stale markers | closed |
| T-180-17 | Tampering | Evidence staging | medium | mitigate | Staging is ignored, validated, and atomically promoted into the approved evidence location | closed |
| T-180-18 | DoS | Capture resource limits | medium | mitigate | The producer caps capture counts and byte budgets; the required validator enforces configured limits | closed |
| T-180-19 | Tampering | Manifest rewrite / post-merge inputs | medium | accept | Consistent manifest rewrites and changes to render inputs outside the checked bundle/root layout remain code-review responsibilities, as declared by Plan 180-04 | closed |
| T-180-SC | Tampering | Phase dependency scope | high | mitigate | Phase-only diff shows no package manifest or lockfile changes; the phase's `mix.exs` change is alias wiring and comments only | closed |

*Status: open · closed · open below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-180-01 | T-180-02 | The plans retain trust in the Tailwind download without a per-run executable checksum. TLS peer verification is enabled; the byte comparison detects accidental output drift but does not establish that a malicious executable cannot copy the committed CSS. | Plan 180-01 threat model | 2026-11-17 |
| AR-180-02 | T-180-06 | The existing theme cookie remains client-controlled but maps only to the closed supported theme set. | Plan 180-02 threat model | 2026-11-17 |
| AR-180-03 | T-180-12 | Advisory browser timing can still flake despite connected-state waits, polling, and bounded retries. | Plan 180-03 threat model | 2026-11-17 |
| AR-180-04 | T-180-19 | Consistent manifest rewrites and post-merge changes to render inputs beyond the bundle and root layout remain review responsibilities. | Plan 180-04 threat model | 2026-11-17 |

*These acceptances were already declared by the plans; this log records them and introduces no new risk acceptance.*

## Security Audit Trail

| Audit Date | Threats Total | Mitigations Verified | Open | Run By |
|------------|---------------|----------------------|------|--------|
| 2026-11-17 | 20 distinct | 16 | 0 | gsd-security-auditor (ASVS L1; `block_on: high`) |

Static source review only. No live tests or external actions were run during this audit. The current Admin catalog-provenance failure is recorded separately in `180-VALIDATION.md`; no favicon capture or rewrite was attempted.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-17
