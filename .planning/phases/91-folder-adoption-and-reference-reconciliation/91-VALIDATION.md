---
phase: 91
slug: folder-adoption-and-reference-reconciliation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-12
---

# Phase 91 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Phase-local Bash gate adapted from Phase 90 |
| **Config file** | none - script-local constants, including `BB="brandbook"` |
| **Quick run command** | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` |
| **Full suite command** | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` when the task touches `brandbook/`, `brandbook-fable/`, active brand pointers, or the phase gate.
- **After every plan wave:** Run `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` and the active reference sweep recorded in `91-gate-evidence.md`.
- **Before `$gsd-verify-work`:** The phase gate must be green and `91-gate-evidence.md` must record the gate output, reference sweep, ignored-file preflight, and release-safety proof.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 91-01-01 | 91-01 | 0 | FOLD-01, FOLD-02, FOLD-03 | T-91-01 / T-91-02 / T-91-03 | Canonical path, active references, and release-safe evidence are machine-checked before adoption work is accepted. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | No - Plan 91-01 creates gate and evidence file | pending |
| 91-02-01 | 91-02 | 1 | FOLD-01, FOLD-03 | T-91-01 | The canonical `brandbook/` contains fable artifacts, `brandbook-fable/` is absent, codex-only files are absent, and ignored `.DS_Store` files are not staged. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | Gate created in Wave 0 | pending |
| 91-03-01 | 91-03 | 2 | FOLD-02, FOLD-03 | T-91-02 | Active tracked pointers name `brandbook/brand-book.md`; stale `brandbook-fable/` references are limited to explicit historical/provenance allowlists. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` plus recorded `rg` sweep | Gate created in Wave 0 | pending |
| 91-04-01 | 91-04 | 3 | FOLD-01, FOLD-02, FOLD-03 | T-91-01 / T-91-03 | The re-pathed v1.9 gate validates the adopted canonical folder and release-safety proof is recorded. | bash/integration | `bash .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` | Gate created in Wave 0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` - adapted from the Phase 90 gate with `BB="brandbook"` and Check 9 changed to post-adoption invariants.
- [ ] `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` - records ignored-file preflight, gate output, active reference sweep, and release-safety proof.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No Release Please PR was created from Phase 91 commits. | FOLD-01, FOLD-02, FOLD-03 | This is a repository-hosting automation outcome, not a local file invariant. | After Phase 91 commits land, inspect GitHub PRs or `gh pr list --search "release-please"` and record the result in `91-gate-evidence.md`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 30 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 creates the gate and each planned task maps to an automated verification.

**Approval:** pending
