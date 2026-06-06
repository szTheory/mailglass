---
phase: 82
slug: logo-and-svg-asset-system
status: active
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-06
---

# Phase 82 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing CLI checks plus manual visual review: `git diff --check`, `xmllint`, `rg` |
| **Config file** | None for Phase 82; committed validation scripts are deferred to Phase 84 |
| **Quick run command** | `git diff --check -- brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/assets && xmllint --noout brandbook/assets/*.svg brandbook/assets/options/*.svg` |
| **Full suite command** | Quick run command plus Phase 82 source assertions, banned SVG construct checks, and out-of-scope diff checks |
| **Estimated runtime** | Less than 30 seconds for phase-specific automated checks |

---

## Sampling Rate

- **After every task commit:** Run the quick command after option SVGs exist, then run the task-specific `rg` checks from the Per-Task Verification Map.
- **After every plan wave:** Run the full suite command and manually review the final mark at 16px, 32px, monochrome, and reversed/dark contexts.
- **Before `$gsd-verify-work`:** Phase-specific checks must pass, manual logo review must be recorded, and out-of-scope paths must be unchanged.
- **Max feedback latency:** 30 seconds for Phase 82-specific automated checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | LOGO-02, LOGO-03 | T-82-03 / T-82-04 | Option review compares credible directions and keeps drafts distinct from final assets | markdown + svg parse | `test -f brandbook/logo-options.md && rg -n 'BRAND-GAP-04|folded pane|message-lines|inspection pane|Selected direction|16px|32px|paper plane|send arrow' brandbook/logo-options.md && xmllint --noout brandbook/assets/options/*.svg` | missing until task | pending |
| 82-01-02 | 01 | 1 | LOGO-02, LOGO-03 | T-82-03 / T-82-04 | Maintainer selection/refinement is recorded before final assets are claimed | manual gate | `rg -n 'Selected direction|Final refinement|Maintainer review|Decision' brandbook/logo-options.md` | missing until task | pending |
| 82-01-03 | 01 | 1 | LOGO-01, LOGO-03, LOGO-04 | T-82-01 / T-82-02 / T-82-04 | Final five SVGs parse, use unique accessible IDs, avoid unsafe constructs, and preserve final metaphor | svg parse + grep | `xmllint --noout brandbook/assets/logo-primary.svg brandbook/assets/logo-mark.svg brandbook/assets/logo-monochrome.svg brandbook/assets/favicon.svg brandbook/assets/social-avatar.svg && rg -n 'mg-logo-primary-title|mg-logo-mark-title|mg-logo-monochrome-title|mg-favicon-title|mg-social-avatar-title|role=\"img\"|viewBox' brandbook/assets/*.svg && ! rg -n '<script|<image|foreignObject|data:|base64|https?://|@font-face|font-face' brandbook/assets/*.svg brandbook/assets/options/*.svg` | yes | pending |
| 82-01-04 | 01 | 1 | LOGO-01, LOGO-03, LOGO-04 | T-82-02 / T-82-04 | Primary lockup stays editable with live text; compact assets remain path/shape-only where practical; monochrome remains currentColor | source grep | `rg -n '<text|font-family=\"Inter Tight|font-weight=\"700\"' brandbook/assets/logo-primary.svg && ! rg -n '<text' brandbook/assets/logo-mark.svg brandbook/assets/logo-monochrome.svg brandbook/assets/favicon.svg brandbook/assets/social-avatar.svg && rg -n 'currentColor' brandbook/assets/logo-monochrome.svg` | yes | pending |
| 82-01-05 | 01 | 1 | LOGO-01, LOGO-02, LOGO-03, LOGO-04 | T-82-03 / T-82-05 | Brandbook wording reflects Phase 82 logo approval without pulling future phases into scope | markdown/html grep + boundary diff | `rg -n 'Phase 82|logo-options|approved|small-size|monochrome|reversed|currentColor|BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06' brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/logo-options.md && git diff --exit-code -- README.md mix.exs mailglass_admin/mix.exs mailglass_admin/lib mailglass_admin/assets mailglass_admin/priv/static/mailglass-logo.svg` | partial | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] No Phase 82 test framework install is required; the phase uses existing local CLI tools.
- [ ] No Phase 82 committed validation script should be created; Phase 84 owns executable SVG/HTML/file-size/package/contrast gates.
- [ ] Option SVG files under `brandbook/assets/options/` are missing before Task 1 and should be created as part of LOGO-02 evidence.
- [ ] Manual visual review is required because grep cannot prove a mark avoids all ambiguous visual readings.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer compares credible directions before final selection/refinement | LOGO-02 | A source artifact can prove options exist, but human visual review decides whether they are credible | Read `brandbook/logo-options.md`; inspect option SVGs; confirm at least three directions are compared and the selected/refined direction is recorded. |
| Final mark avoids banned email tropes | LOGO-03 | Grep cannot prove the shape does not read as a paper plane, send arrow, mailbox, chat bubble, mascot, or glossy app icon | Inspect final `logo-mark.svg`, `favicon.svg`, `logo-monochrome.svg`, and `social-avatar.svg` at normal size, 32px, and 16px. |
| Small-size and reversed use are acceptable | LOGO-03, LOGO-04 | XML parse cannot prove visual clarity | View favicon/mark at 16px and 32px, monochrome/currentColor, and reversed on dark background; confirm final disposition is documented in `logo-options.md` or brandbook copy. |
| Phase boundary is preserved | LOGO-01 through LOGO-04 | Source diff can show changed paths, but a maintainer must confirm scope did not creep in prose | Confirm no root README, package, product/admin implementation, release workflow, raster export, font binary, PDF, or validation-script work was added. |

---

## Validation Sign-Off

- [x] All planned tasks have `<automated>` verify commands or explicit manual-only justification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Phase 82-specific checks use existing CLI tools and do not install packages.
- [x] No watch-mode flags.
- [x] Feedback latency < 30 seconds for Phase 82-specific automated checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending

