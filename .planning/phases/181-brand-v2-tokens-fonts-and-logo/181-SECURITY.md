---
phase: "181"
slug: brand-v2-tokens-fonts-and-logo
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-17"
---

# Phase 181 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Pinned brand archive to repository | Reviewed source bytes become shipped fonts, logos, icons, and tokens | Archive members and SHA-256 digests |
| Brand tokens to generated Admin CSS | Token sources become the public rendered palette and typography | CSS declarations and font bytes |
| Static assets to browser | Asset routes select bundled font and image content | Request path and immutable asset names |
| SVG source to rendered UI | Pinned SVG artwork is inlined or shipped as a static file | SVG markup and token references |
| Elixir source to rendered text | Glyph scan constrains characters used in UI copy | Source strings and rendered glyphs |
| Accessibility evidence to CI | Axe baseline controls a required quality gate | Findings, fingerprints, and approval history |
| Phase changes to core dependencies | Brand phase must not alter core contracts or lockfiles | Source diffs and dependency manifests |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-181-01 | Tampering | Token provenance | medium | mitigate | Token parity checks compare palette sources, recompute derived values, and include mutation cases (`token_parity_test.exs`) | closed |
| T-181-02 | Tampering | Admin bundle | high | mitigate | Required support-contract lane checks freshly built CSS against committed bytes; token tests cover all three blocks | closed |
| T-181-03 | Repudiation | Contrast contracts / axe baseline | medium | mitigate | Contrast mappings and coverage are checked with mutations; axe baseline remains forward-only | closed |
| T-181-04 | Tampering | Brand archive pin | high | mitigate | Expected commit, archive digest, size, ZIP paths, and shipped file hashes are checked before acceptance (`brand_pin.exs`, `brand_pin_test.exs`) | closed |
| T-181-05 | Tampering / Information Disclosure | Static font routes | high | mitigate | A six-name closed asset map serves pinned bytes and returns a bodyless 404 for unknown/retired paths; tests cover traversal and retired names | closed |
| T-181-06 | Information Disclosure | Font loading | medium | mitigate | Contract test rejects remote URLs and imports; source and current CSS contain no remote font references | closed |
| T-181-07 | Repudiation / Legal | Font licenses and package payload | medium | mitigate | License texts are pinned, listed in expected package files, and checked against actual package contents | closed |
| T-181-08 | Denial of Service / Integrity | Immutable font caching | low | accept | Distinct font filenames avoid stale v1 cache entries; same-name byte replacement remains unsupported because responses are immutable for a year | closed |
| T-181-09 | Tampering | Vendored icon rules | low | mitigate | Used Heroicon names must resolve to fixed bundled SVG rules; missing-rule mutation is covered | closed |
| T-181-10 | Repudiation | Glyph scan | medium | mitigate | AST-based scan covers the complete library tree with exact file/codepoint exceptions and stale-exception checks | closed |
| T-181-11 | Tampering / Elevation of Privilege | Logo SVG content | high | mitigate | Tests bind pinned, shipped, and rendered SVGs and reject active content; current inline logo paths match the pinned asset | closed |
| T-181-12 | Tampering | Logo and favicon copies | medium | mitigate | Byte-identity tests keep shipped logo and favicon aligned with the pinned source | closed |
| T-181-13 | Repudiation | Axe baseline changes | medium | mitigate | A forward-only ratchet rejects baseline regression; history and current cells show no color-contrast finding | closed |
| T-181-14 | Tampering | Core API stability | high | mitigate | Historical phase diff through `644412c3` is empty for declared core paths; VML preservation has a regression test. Later-phase core edits are outside this claim | closed |
| T-181-SC | Tampering | Dependency scope | high | mitigate | Historical phase diff is empty for the four declared lockfiles; the later Playwright upgrade is a separate subsequent change | closed |

*Status: open · closed · open below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-181-01 | T-181-08 | Font responses use immutable caching and distinct filenames. Future font byte changes must use new filenames; stale cache entries under a reused filename remain an accepted low risk in this bounded design. | Plan 181-02 threat model | 2026-11-17 |

*This acceptance was declared in Plan 181-02 and is recorded here; it is not a new risk acceptance.*

## Security Audit Trail

| Audit Date | Threats Total | Mitigations Verified | Accepted | Open | Run By |
|------------|---------------|----------------------|----------|------|--------|
| 2026-11-17 | 15 distinct | 14 | 1 low | 0 | gsd-security-auditor (ASVS L1; `block_on: high`) |

Source inspection and read-only byte/hash comparisons only; no suites were rerun. The Admin catalog-provenance failure is recorded separately in `181-VALIDATION.md`; favicon evidence was not changed.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-17
