---
phase: "183"
slug: "docs-packaging-and-launch-prep"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-17"
---

# Phase 183 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Legal search record to public claims | Agent-editable evidence must not authorize unsupported legal claims | Search status and public product copy |
| Pinned archive to repository assets | Downloaded members must match the reviewed archive before writes | Brand assets and their hashes |
| Producer manifest to required validation | Producer-reported metrics and paths are untrusted | Catalog paths, screenshots and raster metrics |
| Drafts to owner-controlled instructions | Pending recommendations cannot silently become canonical policy | Proposed `CLAUDE.md` and `PRODUCT.md` edits |
| Immutable external image URL to local pinned bytes | Renderer refs must identify the reviewed source blob without trusting mutable network content | README image URLs and SVG bytes |
| Source config/assets to generated docs | Hooks and CSS must preserve renderer security and native theme/font behavior | ExDoc assets and generated HTML |
| Prose scanner to public compatibility names | Mechanical rewriting must not rename wire/API contracts | Source prose, modules and headers |
| Package globs/goldens to actual tarballs | A reviewed list alone does not prove payload or license completeness | Hex package contents |
| Generated filesystem output to validator | Require fresh explicit package roots and complete package membership instead of ambient ignored docs | Output paths, pinned media, generated HTML |
| Generated pages to headless browser | Serve only pinned immutable image bytes and deny unrelated network requests | README assets and browser requests |
| CI wiring to merge/release verdict | Preserve fatal validation and the required CI Green dependency | Docs job result and required-check policy |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-183-01 | Elevation of privilege | Trademark gate CLI/decision | high | mitigate | Requires complete register entries, clearance invariants, bounded dates, and rejects production date/path injection; denial regression covers the current caution record (`scripts/brand_trademark_gate.exs`, `test/scripts/brand_trademark_gate_test.exs`) | closed |
| T-183-02 | Spoofing | Encoded public trademark claims | high | mitigate | Decodes symbols/entities, always denies registered claims, and hash-binds the only rule-text exception; encoded mutation cases are covered (`scripts/brand_trademark_gate.exs`, `test/scripts/brand_trademark_gate_test.exs`) | closed |
| T-183-03 | Tampering | Brand pin archive extraction/update | high | mitigate | Validates archive/member/hash/conflict invariants before atomic writes; refusal-purity and idempotence tests cover failure paths (`scripts/brand_pin.exs`, `test/scripts/brand_pin_test.exs`) | closed |
| T-183-04 | Tampering | Favicon catalog | high | mitigate | Confines paths, binds source/served hashes, and recomputes raster metrics; traversal, forgery, missing-engine and pixel mutations are covered (`mailglass_admin/test/support/favicon_catalog.ex`, `mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs`) | closed |
| T-183-05 | Denial of service | PNG decoder/browser producer | medium | mitigate | Caps image bytes, dimensions, inflation and chunks; uses serial headless capture and bounds engine time (`mailglass_admin/test/support/favicon_catalog.ex`, `mailglass_admin/e2e/favicon-capture.cjs`) | closed |
| T-183-06 | Elevation of privilege | Owner sign-off patches | medium | mitigate | Keeps both owner drafts pending, checks they apply cleanly, and rejects half-applied state; canonical owner files have no phase diff (`test/scripts/brand_design_md_test.exs`) | closed |
| T-183-07 | Tampering | README external image refs | high | mitigate | Requires exact immutable host/ref/path and equality among Git blob, current pin and source bytes; wrong host/ref/path mutations are covered (`scripts/brand_docs_check.exs`, `test/scripts/readme_image_contract_test.exs`) | closed |
| T-183-08 | Tampering | Generated ExDoc assets/hooks | medium | mitigate | Checks generated media bytes, restricts CSS to syntax colors, and verifies the local class-driven hook without OS/network behavior (`scripts/brand_docs_check.exs`, `brandbook/exdoc/theme-mark.js`) | closed |
| T-183-09 | Elevation of privilege | Mechanical source prose edits | medium | mitigate | Masks structural module/wire/code identifiers and scans multiline Gettext values, including plural continuations; regression fixtures cover those boundaries (`scripts/brand_name_lint.exs`, `test/scripts/brand_name_lint_test.exs`) | closed |
| T-183-10 | Information disclosure | Hex package payload | high | mitigate | Validates actual unpacked packages against goldens, digest coverage and forbidden roots; checks exact pinned Admin fonts/OFL/logo/favicon (`test/mailglass/publish/brand_asset_allowlist_test.exs`, `lib/mix/tasks/mailglass.publish.check.ex`) | closed |
| T-183-11 | Spoofing | Generated public trademark claims | high | mitigate | Scans generated core/Admin/Inbound output through the hardened current-record gate without coupling it to package publication (`scripts/brand_docs_check.exs`, `test/scripts/brand_trademark_gate_test.exs`) | closed |
| T-183-12 | Tampering | Generated docs output selection | medium | mitigate | Builds fresh core/Admin/Inbound outputs serially, requires an explicit output root, and rejects any missing package or pinned asset (`scripts/verify_brand_docs.sh`, `ci/contracts/brand_docs_output_test.exs`) | closed |
| T-183-13 | Tampering | Required CI docs verdict | high | mitigate | The existing required docs job invokes the all-package gate with fatal error propagation and remains required by CI Green; structural mutation tests cover the job, prerequisites and dependency edge (`.github/workflows/ci.yml`, `test/scripts/brand_docs_ci_wiring_test.exs`) | closed |
| T-183-14 | Information disclosure | Local generated-page browser requests | medium | mitigate | Browser mode serves only exact Git-blob assets verified against the pin and aborts other network requests (`mailglass_admin/e2e/docs-theme-contract.cjs`) | closed |
| T-183-15 | Denial of service | Temporary docs build lifecycle | low | mitigate | Uses one unique temporary directory, serial builds, bounded failure propagation and cleanup limited to its own output root (`scripts/verify_brand_docs.sh`) | closed |
| T-183-SC | Tampering | Package-manager installs | high | mitigate | Adds no new package names or Mix lock changes. The Playwright 1.65.1 update was explicitly owner-approved (`HANDOFF.json` in commit `1d9050d9`); package-lock integrity pins remain in place and CI uses `npm ci` with the local locked CLI | closed |

*The plans contain three rows for T-183-SC; they represent one distinct threat and are recorded once here.*

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-17 | 16 distinct (18 plan rows) | 16 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-17

## Security Audit 2026-11-17

| Metric | Count |
|---|---|
| Threats found | 16 |
| Closed | 16 |
| Open | 0 |
