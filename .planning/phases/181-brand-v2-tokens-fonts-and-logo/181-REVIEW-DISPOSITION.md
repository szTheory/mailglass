---
phase: 181-brand-v2-tokens-fonts-and-logo
review: 181-REVIEW.md
recorded: 2026-11-15
critical: 0
warning: 6
info: 5
---

# Phase 181 code review disposition

Advisory ledger. One row per finding in `181-REVIEW.md`. Every row defaults to `open`; a triaged
row names where it is tracked. Nothing here blocks phase completion (no Critical findings).

| ID | Severity | Status | Tracking |
|----|----------|--------|----------|
| WR-01 | Warning | open | brand_pin_test CLI cases touch the real tree; follow-up hardening |
| WR-02 | Warning | open | test-owned digest of the pin `{to, sha256}` list; follow-up |
| WR-03 | Warning | open | un-fingerprinted immutable caching of fonts and `/logo.svg`; follow-up |
| WR-04 | Warning | open | token parity does not check the `@media` wrapper; follow-up |
| WR-05 | Warning | open | `tokens.json` meta.notes overclaims parity scope; follow-up |
| WR-06 | Warning | deferred | `::placeholder` contrast (deferred-items.md item 1); Phase 182 |
| IN-01 | Info | deferred | `&rarr;` in foundations story (deferred-items.md item 2) |
| IN-02 | Info | open | `document.fonts.check` assertion weaker than it reads |
| IN-03 | Info | deferred | CLAUDE.md Brand & Voice still v1; prose rewrite is Phase 183 (D-23) |
| IN-04 | Info | open | no `.gitattributes` guard for byte-pinned text assets |
| IN-05 | Info | open | Assets moduledoc wording about `extend` |
