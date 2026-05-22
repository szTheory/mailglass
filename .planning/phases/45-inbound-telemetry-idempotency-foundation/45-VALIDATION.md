---
phase: 45
slug: inbound-telemetry-idempotency-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-22
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `45-RESEARCH.md` → "Validation Architecture". Per-task rows are
> filled in by the planner/executor as `*-PLAN.md` files land.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData 1.3.0 (`use ExUnitProperties`) |
| **Config file** | `mailglass_inbound/test/test_helper.exs` (minimal today — Wave 0 extends it with real Postgres + migrations) |
| **Quick run command** | `cd mailglass_inbound && mix test --exclude property` |
| **Full suite command** | `cd mailglass_inbound && mix test` (requires Wave-0 Postgres) |
| **Property gate** | `cd mailglass_inbound && mix test --only property` (1000-run convergence; needs DB) |
| **Estimated runtime** | unit subset ~seconds; property gate minutes (1000 runs) |

---

## Sampling Rate

- **After every task commit:** `cd mailglass_inbound && mix test --exclude property` + `mix credo --strict` (from root)
- **After every plan wave:** `cd mailglass_inbound && mix test` (full, incl. property) + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo --strict`
- **Before `/gsd:verify-work`:** Full inbound suite green (incl. 1000-run property) + Credo green across BOTH packages
- **Max feedback latency:** ~30s for the unit subset (property gate excluded from the fast loop)

---

## Per-Task Verification Map

> Filled during planning/execution. Requirement→test mapping below is the contract;
> task IDs are assigned when `*-PLAN.md` files are written.

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| TELE-01 | ingress span start/stop/exc, PII-free meta | unit | `mix test mailglass_inbound/test/.../telemetry_test.exs` | ❌ W0 |
| TELE-02 | route span matched/no_match/candidate_count | unit | `mix test test/.../telemetry_test.exs` | ❌ W0 |
| TELE-03 | execution span covers Oban + Task paths; mailbox/outcome/source | unit | `mix test test/.../telemetry_test.exs` | ❌ W0 |
| TELE-04 | persist span; operation insert/dedup_skip; record_type | unit | `mix test test/.../telemetry_test.exs` | ❌ W0 |
| TELE-05 | raising handler does not break business logic | unit | `mix test test/.../telemetry_test.exs` | ❌ W0 |
| TELE-06 | metadata passes NoPIIInTelemetry across both packages | lint | `mix credo --strict` (after `.credo.exs` widened to inbound) | n/a (CI) |
| TELE-07 | post-commit broadcast on per-tenant topic; LINT-06 ok | unit | `mix test test/.../pub_sub/topics_test.exs` + `mix credo --strict` | ❌ W0 |
| TELE-08 | 1000-replay convergence: 1 InboundRecord + 1 fresh ExecutionRun | property | `cd mailglass_inbound && mix test --only property` | ❌ W0 (DB) |
| MIME-01 | parse RFC 5322 → stable internal repr | unit | `mix test mailglass_inbound/test/.../mime_test.exs` | ❌ W0 |
| MIME-02 | gated through GenSmtp; degraded fallback returns MIMEError | unit | `mix test test/.../mime_test.exs` + `mix compile --no-optional-deps --warnings-as-errors` | ❌ W0 |
| MIME-04 | malformed payloads never raise; structured error | unit | `mix test test/.../mime_test.exs` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Inbound has **no real test database** today (every existing inbound test uses an in-memory
`FakeRepo`/`ReplayRepo` stub), and root Credo **never lints `mailglass_inbound/`**. Both must be
built before TELE-06 and TELE-08 can be validated:

- [ ] `mailglass_inbound/test/support/test_repo.ex` — `MailglassInbound.TestRepo` (Ecto + Postgres) — required by TELE-08
- [ ] `mailglass_inbound/config/test.exs` — `config :mailglass_inbound, :repo, ...` + Postgres credentials (mirror core)
- [ ] `mailglass_inbound/test/test_helper.exs` — run all 4 inbound migrations via `Ecto.Migrator`; start repo + sandbox manager
- [ ] (optional) `mailglass_inbound/test/support/data_case.ex` or `property_case` — shared sandbox setup
- [ ] Credo coverage for `mailglass_inbound/` — widen root `.credo.exs` `included`, verify it actually lints inbound, reconcile `TelemetryEventConvention` `required_root`
- [ ] CI: inbound test job with `postgres:16-alpine` service (or fold into existing job)
- [ ] `mailglass_inbound/mix.exs` — add `{:gen_smtp, "~> 1.3", optional: true}` (test/dev availability of `:mimemail`)
- [ ] `mailglass_inbound/docs/api_stability.md` — add `MailglassInbound.MIMEError` + `MailglassInbound.PubSub.Topics` to the stable inventory (docs_contract_test asserts it)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | All phase behaviors have automated verification (unit + lint + property). |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (test DB + Credo coverage)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (unit subset)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
