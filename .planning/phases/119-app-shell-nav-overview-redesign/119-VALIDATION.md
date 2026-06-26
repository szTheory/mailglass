---
phase: 119
slug: app-shell-nav-overview-redesign
status: draft
nyquist_compliant: true
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
| 119-01 T0 (Wave-0 scaffolds) | 119-01 | 0 | SHELL-01/02 | — | N/A (assertions only) | e2e scaffold | `cd mailglass_admin && grep -n 'status=failed\|status=suppressed\|orientation-strip-overview' e2e/operator.spec.js` | ✅ operator.spec.js exists | ⬜ pending |
| 119-01 T1 (nav active + Overview identity) | 119-01 | 1 | SHELL-01 | T-119-01 | tenant_id preserved in `@overview_path` (surface_paths) | unit | `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/components_test.exs` | ✅ existing | ⬜ pending |
| 119-01 T2 (Overview triage + drill-through + empty-pane orientation) | 119-01 | 1 | SHELL-02 | T-119-02 | drill-through `build_path/4` keeps tenant scope; closed-set `@status_values` | unit/render | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/token_parity_test.exs` | ✅ existing | ⬜ pending |
| 119-01 T3 (microcopy + motion) | 119-01 | 1 | SHELL-03 | — | N/A | unit/static | `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs && grep -c '@keyframes' assets/css/app.css` (no new keyframes) | ✅ existing | ⬜ pending |
| 119-02 T1 (VERIF-02 rewrite) | 119-02 | 2 | SHELL-02 (D-09) | — | N/A | e2e | `cd mailglass_admin && npm run test:operator-browser -- -g "operator overview"` | ✅ operator.spec.js | ⬜ pending |
| 119-02 T2 (flip + fix judgment gates) | 119-02 | 2 | SHELL-01/02 (D-09) | — | N/A | e2e | `cd mailglass_admin && npm run test:operator-browser -- e2e/judgment.spec.js` | ✅ judgment.spec.js | ⬜ pending |

**Asset-rebuild note (D-12):** the chosen no-rebuild path (icon `hero-chart-bar` already embedded; `hover:border-primary` already in the committed `priv/static/app.css`; `block`/`rounded-box`/`mg-focus-ring`/motion tokens all pre-existing) introduces **zero new Tailwind classes**, so **no `mix assets.build` and no bundle commit are required**. TokenParityTest is still run after the code change as a tripwire to prove the bundle was not disturbed.

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
