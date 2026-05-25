---
phase: 49
slug: inbound-runtime-operator-tooling
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `49-RESEARCH.md` § Validation Architecture (per-deliverable test seams).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mailglass_inbound/test/test_helper.exs` + `config/test.exs` (Ecto SQL Sandbox) |
| **Quick run command** | `cd mailglass_inbound && mix test --seed 0 <touched_file>` |
| **Full suite command** | `cd mailglass_inbound && mix test --seed 0` |
| **Estimated runtime** | ~TBD seconds (planner to confirm) |

> Note (project memory): full `mailglass_inbound` suite intermittently flakes (DB pool tcp recv:closed) via a phase-45 1000-iter property test — use `--seed 0` or scope per-file for deterministic green.

---

## Sampling Rate

- **After every task commit:** Run `{quick run command}` (scoped to touched test file)
- **After every plan wave:** Run `{full suite command}`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** {N} seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | REQ-{XX} | T-{N}-01 / — | {expected secure behavior or "N/A"} | unit | `{command}` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `{tests/test_file.exs}` — stubs for REQ-{XX}
- [ ] `{test/support fixtures}` — fake router w/ conflicting routes (doctor); concurrent-load helper (rate limiter); over-window seeded dataset (pruner); suppressed-sender + store-error fixture (degrade-OPEN); pre-migration record (Signals struct default)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| {behavior} | REQ-{XX} | {reason} | {steps} |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < {N}s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
