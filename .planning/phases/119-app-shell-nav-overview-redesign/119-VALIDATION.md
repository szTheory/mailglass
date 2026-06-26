---
phase: 119
slug: app-shell-nav-overview-redesign
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-26
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (operator browser e2e) |
| **Config file** | `mailglass_admin/mix.exs` (test alias) + `mailglass_admin/playwright.config.js` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/components/token_parity_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix test && npm run test:operator-browser` |
| **Estimated runtime** | ~90 seconds (ExUnit) + ~2-4 min (Playwright operator gate) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (TokenParityTest — the asset-bundle landmine gate)
- **After every plan wave:** Run the full suite command (ExUnit + operator Playwright gate)
- **Before `/gsd-verify-work`:** Full suite must be green, including the two flipped judgment gates
- **Max feedback latency:** ~90 seconds (quick) / ~5 min (full)

---

## Per-Task Verification Map

> Populated by the planner during planning. Each SHELL-01/02/03 task maps to an automated
> verify: TokenParityTest (asset bundle), the operator Playwright gate (`operator.spec.js`),
> and the two judgment gates (`judgment.spec.js`: `nav-active-correctness`, `no-nav-duplication`).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | SHELL-01/02/03 | — | N/A | e2e/unit | TBD by planner | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No new test framework needed — ExUnit + Playwright operator gate already established.
- [ ] `judgment.spec.js` already carries the two drafted gates (`test.fixme`) from Phase 118 — flip to `test`.
- [ ] `operator.spec.js:352-368` (VERIF-02) already exists — rewrite (do not add new file).

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Emil-Kowalski-grade motion feel across light/dark/system | SHELL-03 / matrix | Subjective motion polish; reduced-motion is automated, "feel" is not | Click between Overview/Deliveries/Inbound in `make demo`; confirm transform/opacity-only transitions, instant under reduced-motion |
| Apple-deliberate IA judgment (redundancy / least-surprise) | SHELL-02 | Taste-level; persona-critic harness (Phase 118) covers it, not a structural assert | Run the persona-critic review surface against the redesigned Overview |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s (quick gate)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
