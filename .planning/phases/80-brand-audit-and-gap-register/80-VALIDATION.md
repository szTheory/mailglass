---
phase: 80
slug: brand-audit-and-gap-register
status: active
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-06
---

# Phase 80 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing CLI checks plus Markdown review: `jq`, `xmllint`, `rg`, and `git diff --check` |
| **Config file** | None for Phase 80; committed brandbook-specific validation scripts are deferred to Phase 84 |
| **Quick run command** | `git diff --check -- brandbook/brand-audit.md && jq -e . brandbook/tokens.json && xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg && xmllint --html --noout brandbook/index.html` |
| **Full suite command** | `mix test` for project smoke plus the quick run command and audit/register grep checks below |
| **Estimated runtime** | ~30-60 seconds for quick checks; project test runtime depends on local Mix state |

---

## Sampling Rate

- **After every task commit:** Run the quick run command and the relevant `rg` checks from the Per-Task Verification Map.
- **After every plan wave:** Run the full suite command, then manually review the register against BRAND-01 and BRAND-02.
- **Before `$gsd-verify-work`:** Full suite and audit/register checks must be green, and manual schema review must confirm no unintended Phase 81-84 implementation edits.
- **Max feedback latency:** 60 seconds for Phase 80-specific checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | BRAND-01 | T-80-01 | N/A - docs/register artifact only | markdown grep | `rg -n 'draft input|draft inputs|not approved|KEEP|TIGHTEN|REWORK|ADD|REMOVE|BRAND-GAP-[0-9]+' brandbook/brand-audit.md` | yes | pending |
| 80-01-02 | 01 | 1 | BRAND-01 | T-80-02 | Register schema has explicit closeout pressure | markdown grep | `rg -n 'Severity|Surface|Evidence|Rationale|Target|Closeout|acceptance|BRAND-GAP-[0-9]+' brandbook/brand-audit.md` | yes | pending |
| 80-01-03 | 01 | 1 | BRAND-02 | T-80-03 | All required public surfaces are named for stress testing | markdown grep | `rg -n 'GitHub|README|Hex\\.pm|HexDocs|docs UI|code|terminal|landing|social|favicon|monochrome|dark|light|diagram|UI states' brandbook/brand-audit.md` | yes | pending |
| 80-01-04 | 01 | 1 | BRAND-01, BRAND-02 | T-80-04 | Audit does not introduce unsafe asset or package changes | source diff | `git diff --check -- brandbook/brand-audit.md && git diff --exit-code -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css brandbook/assets brandbook/examples README.md mix.exs mailglass_admin/mix.exs` | yes | pending |
| 80-01-05 | 01 | 1 | BRAND-02 | T-80-05 | Existing static brand assets still parse while audit rows defer implementation fixes | cli parse | `jq -e . brandbook/tokens.json && xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg && xmllint --html --noout brandbook/index.html` | yes | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] No Phase 80 test framework install is required; the phase uses existing local CLI tools.
- [ ] No Phase 80 brandbook validation script should be created; Phase 84 owns executable JSON, SVG, HTML, package, file-size, and contrast gates.
- [ ] No Phase 80 contrast checker should be committed; the audit should name contrast/token risks and hand them to Phase 81/84.
- [ ] No Phase 80 package tarball checker should be committed; the audit should preserve the "brandbook out of tarballs by default" policy and hand executable proof to Phase 84.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Candid executive judgment is specific and not taste-only | BRAND-01 | Judgment quality and downstream usefulness require human reading | Read `brandbook/brand-audit.md`; confirm every actionable row affects a required surface, later phase handoff, brand consistency, accessibility, repo hygiene, or future verification. |
| Register rows are closeout-ready | BRAND-01 | Markdown grep can prove tokens exist, but not that evidence/rationale are meaningful | Review each `BRAND-GAP-*` row; confirm severity, surface, evidence, rationale, target phase, and closeout cue are populated and cite local evidence or authoritative sources. |
| Required surface matrix is complete | BRAND-02 | Grep can prove terms are present, but not that each surface was actually stress-tested | Confirm the audit matrix has one row or clearly equivalent entry for GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page, social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states. |
| Phase boundary is preserved | BRAND-01, BRAND-02 | Source diff can show changed files, but a maintainer must confirm no scope creep in prose | Confirm Phase 80 edits only the audit/register artifact and routes final tokens, logo choices, copy refresh, and validation scripts to Phases 81-84. |

---

## Validation Sign-Off

- [ ] All plan tasks have `<automated>` verify commands or explicit manual-only justification.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Phase 80-specific checks use existing CLI tools and do not install packages.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 60 seconds for Phase 80-specific checks.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
