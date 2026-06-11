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
| 82-01-01 | 01 | 1 | LOGO-02, LOGO-03, LOGO-04 | T-82-01 / T-82-03 / T-82-04 | Option SVGs parse, use unique accessible IDs, stay draft evidence, and avoid unsafe constructs without rejecting the SVG namespace URL | svg parse + grep | `test -f brandbook/assets/options/option-a-folded-pane.svg && test -f brandbook/assets/options/option-b-pane-lines.svg && test -f brandbook/assets/options/option-c-inspection-pane.svg && xmllint --noout brandbook/assets/options/*.svg && rg -n 'mg-option-a-title|mg-option-a-desc|mg-option-b-title|mg-option-b-desc|mg-option-c-title|mg-option-c-desc|role="img"|viewBox' brandbook/assets/options/*.svg && ! rg -n '<script|<image|foreignObject|data:|base64|(^|[[:space:]<])(?:xlink:href|href|src)\s*=\s*(?:"|\x27)https?://|url\(\s*(?:"|\x27)?https?://|@font-face|font-face' brandbook/assets/options/*.svg` | missing until task | pending |
| 82-01-02 | 01 | 1 | LOGO-02, LOGO-03, LOGO-04 | T-82-03 / T-82-04 | Option review compares credible directions and keeps drafts distinct from final assets | markdown + source grep | `test -f brandbook/logo-options.md && rg -n 'BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06|folded pane|message-lines|inspection pane|option-a-folded-pane.svg|option-b-pane-lines.svg|option-c-inspection-pane.svg|16px|32px|wordmark-first|forbidden trope|currentColor|reversed|unique ID|Maintainer review|Selected direction|Recommended final refinement' brandbook/logo-options.md && ! rg -n 'approved final|final brand launch|logo pack|export kit' brandbook/logo-options.md` | missing until task | pending |
| 82-02-01 | 02 | 2 | LOGO-02 | T-82-06 / T-82-07 / T-82-08 | Maintainer selection/refinement is recorded before final assets are claimed | manual gate + source grep | `test -f brandbook/logo-options.md && xmllint --noout brandbook/assets/options/*.svg && rg -n 'Rejected Prior Rounds|Fresh Visual Evidence|Direction G|Direction H|Direction I|Direction J|Direction K|Direction L|Direction M|Direction N|Direction O|Direction P|Direction Q|Direction R|header checksum|email source|16px|32px|Maintainer Review|Selected direction|Recommended Final Refinement' brandbook/logo-options.md` | yes | pending |
| 82-03-01 | 03 | 3 | LOGO-01, LOGO-03, LOGO-04 | T-82-10 / T-82-11 | Final five SVGs parse, use unique accessible IDs, avoid unsafe constructs, and preserve final metaphor | svg parse + grep | `xmllint --noout brandbook/assets/logo-primary.svg brandbook/assets/logo-mark.svg brandbook/assets/logo-monochrome.svg brandbook/assets/favicon.svg brandbook/assets/social-avatar.svg && rg -n 'mg-logo-primary-title|mg-logo-primary-desc|mg-logo-mark-title|mg-logo-mark-desc|mg-logo-monochrome-title|mg-logo-monochrome-desc|mg-favicon-title|mg-favicon-desc|mg-social-avatar-title|mg-social-avatar-desc|role="img"|viewBox' brandbook/assets/*.svg && ! rg -n 'id="title"|id="desc"|<script|<image|foreignObject|data:|base64|(^|[[:space:]<])(?:xlink:href|href|src)\s*=\s*(?:"|\x27)https?://|url\(\s*(?:"|\x27)?https?://|@font-face|font-face' brandbook/assets/*.svg brandbook/assets/options/*.svg && rg -n '<text|font-family="Inter Tight|font-weight="700"' brandbook/assets/logo-primary.svg && ! rg -n '<text' brandbook/assets/logo-mark.svg brandbook/assets/logo-monochrome.svg brandbook/assets/favicon.svg brandbook/assets/social-avatar.svg && rg -n 'currentColor' brandbook/assets/logo-monochrome.svg` | yes | pending |
| 82-03-02 | 03 | 3 | LOGO-01, LOGO-02, LOGO-03, LOGO-04 | T-82-12 / T-82-13 | Brandbook wording reflects Phase 82 logo approval without pulling Phase 83/84 work into scope | markdown/html grep | `rg -n 'Selected direction|Final refinement|Maintainer review|BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06|16px|32px|monochrome|currentColor|reversed|social avatar|favicon' brandbook/logo-options.md && rg -n 'logo-options.md|wordmark-first|mark is secondary|Phase 82|paper plane|mailbox|chat bubble|send arrow|glossy app icon' brandbook/brand-book.md && rg -n 'Phase 82|approved|logo-options|assets/logo-primary.svg|assets/logo-mark.svg|assets/social-avatar.svg' brandbook/index.html && rg -n 'logo-options.md|assets/options|SVG logos|Markdown and HTML guidance' brandbook/README.md && ! rg -n 'Phase 83.*complete|Phase 84.*complete|final brand launch|logo pack|export kit' brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md` | partial | pending |
| 82-03-03 | 03 | 3 | LOGO-01, LOGO-02, LOGO-03, LOGO-04 | T-82-10 / T-82-11 / T-82-14 | Final Phase 82 checks pass and out-of-scope product/package/public surfaces remain unchanged | full source assertions + boundary diff | `git diff --check -- brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/assets && xmllint --noout brandbook/assets/*.svg brandbook/assets/options/*.svg && rg -n 'BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06|Selected direction|Final refinement|16px|32px|currentColor|reversed|unique ID|Phase 82' brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md && rg -n 'paper plane|mailbox|chat bubble|send arrow|glossy app icon|mascot' brandbook/logo-options.md brandbook/brand-book.md && ! rg -n '<script|<image|foreignObject|data:|base64|(^|[[:space:]<])(?:xlink:href|href|src)\s*=\s*(?:"|\x27)https?://|url\(\s*(?:"|\x27)?https?://|@font-face|font-face' brandbook/assets/*.svg brandbook/assets/options/*.svg && git diff --exit-code -- README.md mix.exs mailglass_admin/mix.exs mailglass_admin/lib mailglass_admin/assets mailglass_admin/priv/static/mailglass-logo.svg .github` | partial | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] No Phase 82 test framework install is required; the phase uses existing local CLI tools.
- [ ] No Phase 82 committed validation script should be created; Phase 84 owns executable SVG/HTML/file-size/package/contrast gates.
- [ ] Option SVG files under `brandbook/assets/options/` include rejected A-F evidence and active G-R first-principles evidence for LOGO-02 review.
- [ ] Manual visual review is required because grep cannot prove a mark avoids all ambiguous visual readings.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer compares credible directions before final selection/refinement | LOGO-02 | A source artifact can prove options exist, but human visual review decides whether they are credible | Read `brandbook/logo-options.md`; inspect active G-R option SVGs; confirm the first-principles set is compared and the selected/refined direction is recorded. |
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
