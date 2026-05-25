---
phase: 49
slug: inbound-runtime-operator-tooling
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
populated: 2026-05-25
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `49-RESEARCH.md` § Validation Architecture (per-deliverable test seams).
> Populated from the three written plans after the plan-checker pass (0 blockers, 2026-05-25).
> `wave_0_complete` stays `false` until the Wave 0 RED scaffolds are created and run during
> `/gsd:execute-phase 49`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18) + StreamData 1.3 (property tests) |
| **Config file** | `mailglass_inbound/test/test_helper.exs` + `config/test.exs` (Postgres-backed `MailglassInbound.TestRepo`, Ecto SQL Sandbox) |
| **Quick run command** | `cd mailglass_inbound && mix test <touched_test_file> --seed 0` |
| **Full suite command** | `cd mailglass_inbound && mix test --seed 0` |
| **Sync requirement** | Rate limiter + pruner + config tests MUST be `async: false` (shared ETS table + Application-env mutation + DB CASCADE truncation — mirror core `RateLimiterTest`/`PrunerTest`). |

> Note (project memory): the full `mailglass_inbound` suite intermittently flakes (DB pool
> `tcp recv:closed`) via a phase-45 1000-iter property test — use `--seed 0` or scope per-file
> for deterministic green, and exclude that flake from phase pass/fail.

---

## Sampling Rate

- **After every task commit:** Run the scoped quick command for the touched test file(s).
- **After every plan wave:** Run the full suite (`cd mailglass_inbound && mix test --seed 0`).
- **Before `/gsd:verify-work`:** Full suite must be green (modulo the known phase-45 flake).
- **Max feedback latency:** scoped per-file runs return in seconds (measured at execution).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | IOPS-04 | T-49-01..05 | RED scaffolds: rate-limit/config/plug tests (capacity trip, forgery-budget, PII-free span) | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/config_test.exs test/mailglass_inbound/rate_limiter_test.exs --seed 0` (expect RED) | ❌ W0 | ⬜ pending |
| 49-01-02 | 01 | 1 | IOPS-04 | T-49-01 / T-49-02 | Config validates locked key shape (`:infinity` ok); rate-limiter buckets trip in tenant→recipient→sender_domain order; PII-free telemetry | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/config_test.exs test/mailglass_inbound/rate_limiter_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |
| 49-01-03 | 01 | 1 | IOPS-04 | T-49-03 / T-49-04 | Post-verify limit → 429 + `retry-after`; forged request → 401 with budget intact (rate limit applied after signature verify) | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |
| 49-02-01 | 02 | 2 | IOPS-05 | T-49-06..10 | RED scaffolds: signals struct/predicate, suppression-flag persist, degrade-OPEN, no-auto-bounce, PII-free span | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/inbound_message_test.exs --seed 0` (expect RED) | ❌ W0 | ⬜ pending |
| 49-02-02 | 02 | 2 | IOPS-05 | T-49-06 | `Signals` default `suppression_flagged: false` (no KeyError); `suppression_flagged?/1` predicate; pattern-match on `%Signals{}` | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/inbound_message_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |
| 49-02-03 | 02 | 2 | IOPS-05 | T-49-07..10 | `suppression_flagged` computed at persist; degrade-OPEN on store error (persist still succeeds, flag false); no auto-bounce; list projection; PII-free span | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/internal/operator/records_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |
| 49-03-01 | 03 | 2 | IOPS-01, IOPS-02, IOPS-03, MIME-03 | T-49-11..17 | RED scaffolds + fixtures (fake routers w/ conflict pairs, fake mailbox w/wo `process/1`, over-window seed) for doctor/replay/prune | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/internal/doctor_test.exs test/mailglass_inbound/internal/prune_test.exs --seed 0` (expect RED) | ❌ W0 | ⬜ pending |
| 49-03-02 | 03 | 2 | IOPS-01, MIME-03 | T-49-11..13 | Doctor DNS-free 3-state exit (0/1/2), human+JSON parity, route-conflict detection naming `router.ex:LINE`, MIME backend name+vsn (warn when absent) | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/internal/doctor_test.exs test/mix/tasks/mailglass_inbound_doctor_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |
| 49-03-03 | 03 | 2 | IOPS-02, IOPS-03 | T-49-14..17 | Replay selector AND-combine, `[y/N]` default-No, `--yes` skips, appends `source: :replay`; prune LIMIT-1000 batched, session advisory-lock single-run, child-first order, `:infinity` disables, per-table telemetry counts | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/internal/prune_test.exs test/mix/tasks/mailglass_inbound_replay_test.exs test/mix/tasks/mailglass_inbound_prune_test.exs --seed 0` (GREEN) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · File Exists: `❌ W0` = created by the plan's Wave 0 (`-01`) scaffold task during execution.*

Cross-cutting gates (every plan's `<verification>` block):
- `cd /Users/jon/projects/mailglass && mix credo --strict` green (telemetry whitelist + no-PII; **run credo, do not grep**).
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` green (Oban/gen_smtp gated). **Do NOT** run `--no-optional-deps --force` on the shared `_build` (project memory).

---

## Wave 0 Requirements

Each plan's `-01` task creates the failing (RED) test files the implementation tasks then turn GREEN:

- [ ] `mailglass_inbound/test/mailglass_inbound/config_test.exs`, `rate_limiter_test.exs`, `ingress/plug_test.exs` (extended) — stubs for IOPS-04
- [ ] `mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs` (extended), `ingress/persist_test.exs` (extended), `internal/operator/records_test.exs` (extended) — stubs for IOPS-05
- [ ] `mailglass_inbound/test/mailglass_inbound/internal/doctor_test.exs`, `internal/prune_test.exs`, `test/mix/tasks/mailglass_inbound_doctor_test.exs`, `mailglass_inbound_replay_test.exs`, `mailglass_inbound_prune_test.exs` + fixtures (fake routers/mailboxes, over-window seed) — stubs for IOPS-01/02/03 + MIME-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification. Notes: doctor is DNS-free by design (no live network in tests); rate-limiter concurrency uses `Task.async_stream`; the prune cross-session advisory-lock test has a telemetry/log-assertion fallback if session-level locking is intractable under the Ecto sandbox (per RESEARCH).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (plan-checker Dim 8a)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (each plan = 3 tasks, all carry `--seed 0` verify)
- [x] Wave 0 covers all MISSING references (each plan's `-01` scaffold creates the files its `-02`/`-03` tasks turn GREEN — plan-checker Dim 8d)
- [x] No watch-mode flags
- [ ] Feedback latency < Ns (measured at execution)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-25 (plan-checker: 0 blockers, 3 warnings — none gating). `wave_0_complete` and per-task Status remain pending until `/gsd:execute-phase 49` runs the Wave 0 scaffolds.
