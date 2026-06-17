---
phase: 103
slug: verification-idempotent-closeout
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-06-16
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 103-RESEARCH.md "Validation Architecture". This is a closeout/verification
> phase — the only code edits are to `ratchet_baseline_test.exs` + `ui-baseline-scores.json`;
> everything else is confirming existing gates and reconciling docs.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 / OTP 27) + Playwright (Node 22, admin only) |
| **Config file** | `mailglass_admin/playwright.config.cjs`; mix aliases in `mailglass_admin/mix.exs:180-194` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.support_contract.admin && mix verify.preview` |
| **Estimated runtime** | ~60–120 seconds (ratchet unit ~3s; full battery + assets build + bundle-clean ~2min) |

---

## Sampling Rate

- **After every task commit:** Run the relevant single gate (e.g. the ratchet unit test after JSON/test edits; the specific conformance script after a register/doc change).
- **After every plan wave:** Run `cd mailglass_admin && mix verify.support_contract.admin` + the three conformance shell scripts.
- **Before `/gsd:verify-work`:** Full battery must be green — `mix verify.support_contract.admin`, `mix verify.preview`, both conformance scripts, the root motion script, and the Playwright structural spec.
- **Max feedback latency:** ~5 seconds for the ratchet unit gate (the only modified test surface); ~2 min for the full battery.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| ratchet-restructure | RATCHET-01 | 1 | RATCHET-01 | T-103-01 (vacuous gate) | Anti-vacuity run_id guard fails loud if prior==current | unit | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` | ✅ (needs D-01/03/04 edits + Pitfall-1 coverage-test fix) | ⬜ pending |
| gap-reconcile | RATCHET-02 | 2 | RATCHET-02 | — | Flips honest (finding absent in live code) | doc + live-code grep | grep cites per D-08 (no automated register test) | ✅ live code | ⬜ pending |
| token-parity | — | 3 | token-parity | — | Admin theme values match brandbook tokens | unit | bundled in `mix verify.support_contract.admin` (`token_parity_test.exs`) | ✅ | ⬜ pending |
| conformance | — | 3 | conformance (5 gates) | T-103-02 (release train) | No design-system violations in lib/ | shell | `bash mailglass_admin/scripts/check-conformance.sh` | ✅ | ⬜ pending |
| conformance-advisory | — | 3 | type-lg/xl + track | — | No large type / arbitrary tracking | shell | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | ✅ | ⬜ pending |
| motion-gate | — | 3 | motion (Phase 74 frozen) | — | No banned animation/easing in lib + app.css | shell | `bash scripts/check_motion_conformance.sh` | ✅ | ⬜ pending |
| structural | — | 3 | structural (6 pillar facts) | — | Focus rings, ARIA, ≥44px, weights, reduced-motion | e2e | `cd mailglass_admin && npm run test:operator-browser` (`--workers=1`) | ✅ | ⬜ pending |
| bundle-clean | — | 3 | bundle-clean | T-103-02 | No uncommitted `priv/static/` drift | shell | `git diff --exit-code priv/static/` (inside `mix verify.preview`) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No Wave 0 framework install needed — all gate scripts, aliases, and test files exist. The only "new" test surface is **modifications** to `ratchet_baseline_test.exs` (activate comparator call site, bump `schema_version == 1` → `== 2`, add anti-vacuity run_id guard, and fix the two 36-cell coverage tests at lines 51-81 per RESEARCH Pitfall 1, which read `get_in(b, ["surfaces", ...])` and break under the `{prior,current}` restructure). These are edits to an existing file, not net-new files.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 18-cell PNG re-run + fresh re-score → populate `current` block | RATCHET-01 | PNGs gitignored (D-07 bans pixel-diff); re-score is a structured/LLM review of rendered screens, not an automated assertion | Run `mailglass_admin/scripts/ui-audit.sh`; score 36 cells (surface×pillar×theme) per Seed Run Procedure Step 3; write into `ui-baseline-scores.json` `current` block with `run_id: 2026-06-16-phase-103` |
| GAP register row flips (open → fixed) | RATCHET-02 | Honesty rule (D-09): a flip requires the finding be ABSENT in live code at the cited component:line — a human/agent judgement, not a test | For each of GAP-01/04/06/07/08/09, confirm the cited line (D-08) matches live code, flip status, stamp `run_id`, preserve `first_seen_run` |
| Milestone audit regeneration | CLOSE | `gsd-audit-milestone` skill reads per-phase `*-VERIFICATION.md` and overwrites the audit | Run LAST (D-14/D-15) after register reconciled + ratchet activated; confirm it flips `gaps_found → passed` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are listed in Manual-Only with explicit instructions
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (gate battery covers every wave)
- [ ] Wave 0 covers all MISSING references (none — infrastructure exists)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s for the ratchet unit gate
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner once tasks map cleanly)

**Approval:** pending
