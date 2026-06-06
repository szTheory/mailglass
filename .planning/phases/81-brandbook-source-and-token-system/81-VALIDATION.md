---
phase: 81
slug: brandbook-source-and-token-system
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
updated: 2026-06-06T05:28:25Z
---

# Phase 81 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing CLI checks: `git diff --check`, `jq`, `xmllint`, `rg` |
| **Config file** | None |
| **Quick run command** | `git diff --check -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css && jq -e . brandbook/tokens.json && xmllint --html --noout brandbook/index.html` |
| **Full suite command** | Quick run command plus Phase 81 `rg` source assertions and out-of-scope diff check |
| **Estimated runtime** | Less than 30 seconds for phase-specific checks |

---

## Sampling Rate

- **After every task commit:** Run the quick run command and task-specific `rg` checks.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Phase-specific checks must pass and out-of-scope files must be unchanged.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 81-01-01 | 01 | 1 | BOOK-02, BOOK-03, TOKEN-03 | T-81-02 / T-81-03 | Source brandbook preserves approved center, draft status, and admin boundary | markdown grep | `rg -n 'Mailglass makes email visible|glass is a metaphor|BRAND-GAP-01|BRAND-GAP-08|BRAND-GAP-12|draft input|not approved|mailglass_admin/docs/design-system.md|not.*second admin UI framework' brandbook/brand-book.md` | yes | green |
| 81-01-02 | 01 | 1 | TOKEN-01, TOKEN-02, TOKEN-03 | T-81-03 / T-81-04 | Token JSON prefers semantic roles and documents text/non-text state and callout usage | json + grep | `jq -e . brandbook/tokens.json && rg -n 'semantic roles|raw palette|text|non-text|callout|state|admin UI|Glass' brandbook/tokens.json` | yes | green |
| 81-01-03 | 01 | 1 | TOKEN-01, TOKEN-02 | T-81-04 | CSS exposes required role, focus, and motion primitives without adding a build step | css grep | `rg -n -- '--mg-(bg|surface|border|text|link|state|callout|code|font|space|radius|shadow|focus|duration)|prefers-reduced-motion|focus-visible' brandbook/tokens.css` | yes | green |
| 81-01-04 | 01 | 1 | BOOK-01, BOOK-03, TOKEN-03 | T-81-01 / T-81-02 / T-81-03 | Static HTML opens locally, avoids external references/scripts, and reflects draft status/admin boundary | html parse + grep | `xmllint --html --noout brandbook/index.html && rg -n 'draft|Phase 82|Phase 83|semantic roles|admin design-system|Mailglass makes email visible' brandbook/index.html && ! rg -n 'https?://|<script|cdn' brandbook/index.html` | yes | green |
| 81-01-05 | 01 | 1 | BOOK-01, BOOK-02, TOKEN-01, TOKEN-02, TOKEN-03 | T-81-01 / T-81-02 / T-81-03 / T-81-04 | Phase boundary preserved; no logo/specimen/public/package/product code changed | source diff | `git diff --exit-code -- brandbook/assets brandbook/examples brandbook/README.md README.md mix.exs mailglass_admin/mix.exs mailglass_admin/lib mailglass_admin/assets mailglass_admin/docs/design-system.md` | yes | green |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 81 requirements. No test framework, build tool, validation script, package manager, or browser automation needs to be added.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand source language remains concise and useful | BOOK-02, BOOK-03 | Grep can prove phrases exist, not that the source brandbook reads well | Read `brandbook/brand-book.md`; confirm it preserves the brand center, removes prompt-era friction, and does not overclaim downstream artifacts. |
| Token usage guidance is clear enough for future designers/engineers | TOKEN-01, TOKEN-02, TOKEN-03 | Role semantics and text/non-text usage require judgment | Read `tokens.json`, `tokens.css`, and the token section in `brandbook/brand-book.md`; confirm raw values are source values and examples route through semantic roles. |
| Static HTML honestly presents draft assets | BOOK-01 | HTML parse does not prove copy posture | Open `brandbook/index.html` directly from disk or inspect source; confirm logo/specimen sections are not described as approved final outputs. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 30s for phase-specific checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** verified 2026-06-06

## Validation Audit 2026-06-06

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All Phase 81 requirement mappings have automated verification commands, and the
commands were rerun successfully during the validation audit. No generated test
files were needed because the phase is covered by existing source, JSON, HTML,
grep, and boundary checks.
