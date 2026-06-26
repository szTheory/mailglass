---
phase: 116
slug: fixtures-idempotent-ratchet-arm
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-20
---

# Phase 116 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 116-RESEARCH.md "## Validation Architecture". Source-of-truth decisions live in 116-CONTEXT.md (D-01..D-12).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Elixir)** | ExUnit (admin app), Elixir ~1.18 / OTP 27 |
| **Framework (browser)** | `@playwright/test ^1.59.1` (admin `e2e/` + demo `assets/e2e/`) + net-new `@axe-core/playwright ^4.11.2` (resolves 4.11.3; test-only devDep) |
| **Config file** | `mailglass_admin/playwright.config.cjs`, `reference/demo_app/assets/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/axe_baseline_test.exs test/mailglass_admin/ratchet_baseline_test.exs` |
| **Full suite command** | `cd mailglass_admin && mix mailglass_admin.assets.build && npm run test:operator-browser` + scoped `mix test` (avoid ~57 unrelated Oban worktree failures; run on main) |
| **Estimated runtime** | ~60–180s (ExUnit comparators fast; Playwright matrix dominates) |

---

## Sampling Rate

- **After every task commit:** Run the targeted ExUnit file(s) touched (`axe_baseline_test.exs`, `persona_*_test.exs`, `bucket_a_coverage_test.exs`) + `mailglass_admin/scripts/check-conformance.sh`.
- **After every plan wave:** Run scoped admin `mix test` (avoid bare `mix test` — ~57 unrelated Oban worktree failures per MEMORY) + `npm run test:operator-browser`.
- **Before `/gsd-verify-work`:** Full Playwright matrix (admin + ≥1 demo run) green + all THREE baseline comparators green (54-cell ratchet, 9-cell axe, Bucket-A manifest). Run on **main**, not a worktree (execute-phase worktrees impractical — deps/_build gitignored, per MEMORY).
- **Max feedback latency:** ~180 seconds (quick ExUnit comparator path < 30s).

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| RATCHET-01 | cohort seeds 3 personas; `list_tenants/2` shows ≥2; helios-void absent (zero-Delivery) | integration (ExUnit) | `mix test test/.../persona_cohort_test.exs` | ❌ W0 |
| RATCHET-01 | drift-guard: 3 materializers (demo seed, admin test-support, gallery) agree on persona names + 8 edge cases | unit (ExUnit) | `mix test test/.../persona_drift_guard_test.exs` | ❌ W0 |
| RATCHET-02 | gallery specimens render at 320/390/768/wide × {light,dark,system}, no overflow; stable testids preserved | structural (Playwright resize loop over SAME testids) | `npm run test:operator-browser` (gallery spec) | ⚠️ extend `structural.spec.js` |
| RATCHET-03 | interaction pillar binary gates: panel-above-scrim / scroll-chaining / focus-restore / layout-jump (CLS) | structural (Playwright, binary pass/fail) | `npm run test:operator-browser` | ⚠️ extend `structural.spec.js` |
| RATCHET-03 | axe baseline meet-or-beat: 9 surface×theme cells, schema_version 1, fail-closed missing-cell + per-rule diff | ExUnit comparator (clone of ratchet) | `mix test test/mailglass_admin/axe_baseline_test.exs` | ❌ W0 |
| RATCHET-04 | ≥1 run vs rich demo data; `current → prior` promoted; 54-cell re-score green (meet-or-beat, zero regression) | Playwright (demo) + ExUnit ratchet | `cd reference/demo_app/assets && npm run test:e2e` + admin ratchet test | ⚠️ extend `demo.spec.js` |
| RATCHET-05 | 24 Bucket-A defects each have a live guard; manifest asserts each cited guard physically exists (fail-closed) | ExUnit manifest + grep gates + Playwright | `mix test test/.../bucket_a_coverage_test.exs` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements — front-loaded in Wave 1 `tdd` tasks

> There is no separate pre-Wave-0 in this phase. Test/baseline scaffolds are front-loaded into the
> Wave-1 `tdd="true"` tasks (and the Wave-2 producer/comparator tasks they unblock), so every MISSING
> reference is created by the task that consumes it before any later wave samples it. The annotation in
> brackets names the discharging plan/task. `wave_0_complete: true` reflects this front-loaded design,
> not a literal completed pre-wave.

- [x] `reference/demo_app/lib/mailglass_demo/personas.ex` — declarative persona spec (RATCHET-01) → **116-01 Task 1 (tdd)**
- [x] `mailglass_admin/test/support/operator_fixtures.ex` — `seed_persona_cohort!/0` (RATCHET-01) → **116-01 Task 2 (tdd)**
- [x] test-only path-dep entry in `mailglass_admin/mix.exs` (`only: [:test]`) (RATCHET-01) — **verify `mix deps.get && mix compile` (Assumption A1)** → **116-01 Task 2 (tdd)**
- [x] persona drift-guard test (RATCHET-01 / D-07) → **116-01 Task 3 (tdd)**
- [x] `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` — clone of `ratchet_baseline_test.exs` comparator (RATCHET-03) → **116-02 (tdd-first comparator)**
- [x] `mailglass_admin/docs/axe-baseline.json` — 9-cell schema-1 baseline, seeded by producer spec (RATCHET-03) → **116-02**
- [x] `mailglass_admin/e2e/axe-baseline.spec.js` — producer spec regenerating `current.violations` (RATCHET-03) → **116-02**
- [x] `npm install --save-dev @axe-core/playwright@^4.11.2` in `mailglass_admin/` + commit lockfile if tracked → **116-02 (single install task, with legitimacy checkpoint)**
- [x] `mailglass_admin/test/.../bucket_a_coverage_test.exs` executable manifest + `.planning/research/v1.13/BUCKET-A-LEDGER.md` human mirror (RATCHET-05) → **116-05 Task 3**
- [x] 6 net-new Bucket-A guards (A3, A4/A23, A16-system, A21, A22, A11) → **116-05 Tasks 1-2**

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | All phase behaviors have automated verification (ExUnit comparators + Playwright structural/axe + grep gates). | — |

*All phase behaviors have automated verification — this phase IS verification infrastructure.*

---

## Open Validation Risks (from RESEARCH Assumptions Log)

- **A1 (MEDIUM):** test-only path dep compilability not yet compiled — first Wave-0 task must run `mix deps.get && mix compile`; fall back to extracting a minimal `Personas` module if a mailglass/phoenix version conflict surfaces.
- **A5 (open):** confirm the demo webServer boot AND `/demo/evidence/reset` token POST both run `DemoData.reset!` → `Personas.seed!` (else RATCHET-04 cohort absent at harness boot).
- **A2:** `system` theme cell must render distinct DOM from `light` (app-theme=system + `emulateMedia colorScheme:dark`); else `system` rows are redundant (baseline still valid).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (front-loaded into Wave-1 `tdd` tasks + Wave-2 producers; see annotated rows above)
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** signed-off (2026-06-20) — 100% automated verify, no watch-mode, <180s latency, sampling continuity intact, all MISSING references front-loaded into the Wave-1 tdd tasks that consume them.
