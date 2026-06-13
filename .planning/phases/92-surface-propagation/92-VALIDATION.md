---
phase: 92
slug: surface-propagation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 92 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell assertions plus existing Elixir/Phoenix admin verification |
| **Config file** | `mailglass_admin/mix.exs` for `verify.preview`; none for README/brandbook source checks |
| **Quick run command** | `rg 'brandbook/examples/readme-header.svg' README.md && rg -n '<text|font-family|url\\(|href=' brandbook/examples/readme-header.svg || true` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` plus PNG dimension/size checks |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-specific source assertion in the
  plan task.
- **After every plan wave:** Run the plan-level verification block.
- **Before `$gsd-verify-work`:** README, PNG, brandbook docs, and admin preview
  checks must be green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 92-01-01 | 01 | 1 | SURF-01 | T-92-01 | README references only repo-local canonical SVG | source | `rg 'brandbook/examples/readme-header.svg' README.md` | ✅ | ⬜ pending |
| 92-01-02 | 01 | 1 | SURF-02 | T-92-02 | Committed PNG is bounded to the single allowed binary | file metadata | `identify -format '%wx%h' brandbook/examples/og-card.png && stat -f%z brandbook/examples/og-card.png` | ✅ after task | ⬜ pending |
| 92-01-03 | 01 | 1 | SURF-02 | T-92-03 | Upload docs do not imply nonexistent API automation | source | `rg 'Social preview|Upload an image|Settings' brandbook/README.md` | ✅ | ⬜ pending |
| 92-02-01 | 02 | 1 | SURF-03 | T-92-04 | Admin logo is outlined, font-free, and theme-safe | source + package gate | `rg -n '<text|font-family' mailglass_admin/priv/static/mailglass-logo.svg && exit 1 || true; cd mailglass_admin && mix verify.preview` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- Playwright CLI is installed locally for the PNG export command.
- ImageMagick `identify` is installed locally for PNG dimension checks.
- `mailglass_admin` already owns `mix verify.preview`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Upload `brandbook/examples/og-card.png` as the repository social preview | SURF-02 | GitHub documents this as Settings UI upload and exposes no documented write API | In GitHub, open repository Settings, scroll to Social preview, click Edit, choose Upload an image, and select `brandbook/examples/og-card.png`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft 2026-06-13
