---
phase: 81
slug: brandbook-source-and-token-system
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-06
register_authored_at_plan_time: true
source_plan: 81-01-PLAN.md
source_summary: 81-01-SUMMARY.md
---

# Phase 81 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Direct-open brandbook HTML | `brandbook/index.html` opens directly from disk and must not load remote scripts, CDN assets, or external content. | Local brandbook HTML, local favicon, local CSS, local SVG/specimen references; low sensitivity brand/docs content. |
| Brandbook to product admin UI | Phase 81 brandbook tokens and copy guide docs, collateral, examples, and future mapping without replacing implemented admin UI mechanics. | Brand/token guidance crossing toward future product mapping; implementation authority remains `mailglass_admin/docs/design-system.md`. |
| Draft asset status | Phase 81 may reference existing local logo/specimen evidence, but approval of logos, specimens, copy, and validation proof remains assigned to Phases 82-84. | Draft brand asset status and downstream phase ownership. |
| Token usage guidance | Raw palette values and semantic roles cross from source artifacts into future docs, examples, and design decisions. | Color/state/callout guidance, including text versus non-text use and Phase 84 contrast-validation constraints. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-81-01 | Information disclosure / Tampering | `brandbook/index.html`, `brandbook/tokens.css` | mitigate | Direct-open HTML remains local-only and script-free; CSS has no imports, font-face declarations, external URLs, or CDN references. | closed |
| T-81-02 | Tampering / Repudiation | `brandbook/brand-book.md`, `brandbook/index.html` | mitigate | Source artifacts explicitly state current assets are draft inputs and route logo/specimen/copy/proof approval to Phases 82-84. | closed |
| T-81-03 | Tampering / Maintainability | `brandbook/brand-book.md`, `brandbook/tokens.json`, `brandbook/index.html` | mitigate | Source artifacts name `mailglass_admin/docs/design-system.md` as the implemented product UI source of truth and state the brandbook is not a second admin UI framework. | closed |
| T-81-04 | Accessibility / Denial of use | `brandbook/brand-book.md`, `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/index.html` | mitigate | Token guidance distinguishes text from non-text, border, background, icon, and accent use; info callout text usage remains deferred to Phase 84 contrast validation. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Mitigation Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-81-01 | `brandbook/index.html:7` keeps local favicon; `brandbook/index.html:8` keeps local `tokens.css`; `! rg -n 'https?://|<script|cdn' brandbook/index.html brandbook/tokens.css` exits 0. |
| T-81-02 | `brandbook/brand-book.md:13` documents draft-input source status; `brandbook/index.html:354` says logo, specimen, copy, and proof remain draft evidence until Phases 82-84; `brandbook/index.html:430`, `458`, and `484` preserve the Phase 82/83/84 routing. |
| T-81-03 | `brandbook/brand-book.md:179`, `brandbook/tokens.json:7`, and `brandbook/index.html:424` identify `mailglass_admin/docs/design-system.md` as the implemented admin UI constraint source and reject a second admin UI framework. |
| T-81-04 | `brandbook/brand-book.md:169` distinguishes text from non-text, border, and background use; `brandbook/tokens.json:70`, `75`, and `76` defer unvalidated info text pairs to Phase 84; `brandbook/index.html:417` repeats the text/non-text caution. |

---

## Summary Threat Flags

No additional `## Threat Flags` entries were present in `81-01-SUMMARY.md`. The Phase 81 security register is the plan-time `<threat_model>` from `81-01-PLAN.md`, with validation mapping in `81-VALIDATION.md`.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit 2026-06-06

| Metric | Count |
|--------|-------|
| Threats found | 4 |
| Closed | 4 |
| Open | 0 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-06 | 4 | 4 | 0 | Codex inline `gsd-secure-phase` |

---

## Verification Commands

| Command | Result |
|---------|--------|
| `git diff --check -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css` | pass |
| `jq -e . brandbook/tokens.json` | pass |
| `xmllint --html --noout brandbook/index.html` | pass; HTML5 element diagnostics are expected and the command exits 0 |
| `rg -n 'href="tokens.css"\|href="assets/favicon.svg"\|Mailglass makes email visible\|Mail you can see through\|BRAND-GAP-12\|BRAND-GAP-08\|BRAND-GAP-01\|Phase 82\|Phase 83\|Phase 84\|semantic roles\|raw hex\|mailglass_admin/docs/design-system.md' brandbook/index.html` | pass |
| `! rg -n 'https?://\|<script\|cdn' brandbook/index.html brandbook/tokens.css` | pass |
| `git diff --exit-code -- brandbook/assets brandbook/examples brandbook/README.md README.md mix.exs mailglass_admin/mix.exs mailglass_admin/lib mailglass_admin/assets mailglass_admin/docs/design-system.md` | pass |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-06
