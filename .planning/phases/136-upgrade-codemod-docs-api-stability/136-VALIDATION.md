---
phase: 136
slug: upgrade-codemod-docs-api-stability
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-03
---

# Phase 136 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `136-RESEARCH.md` → `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (shipped; `test/test_helper.exs` boots `Mailglass.TestRepo`) |
| **Config file** | `config/test.exs` (pins `:schema` `"public"`) |
| **Quick run command** | `mix test <touched_file> --seed 0` |
| **Full suite command** | `MAILGLASS_SCHEMA=mailglass mix test --only schema_isolation --seed 0` + default-schema `mix test --seed 0` |
| **Estimated runtime** | ~20–40 seconds (targeted files); full both-axis pass longer |

---

## Sampling Rate

- **After every task commit:** Run `mix test <touched_file> --seed 0` (the `:schema_isolation` DDL tests are `async: false` and require `--seed 0` per the determinism memory)
- **After every plan wave:** `MAILGLASS_SCHEMA=mailglass mix test --only schema_isolation --seed 0` + `mix test --seed 0`
- **Before `/gsd-verify-work`:** Both axes green + `mix format --check-formatted` + `mix credo --strict` (path-scoped to `lib/`)
- **Max feedback latency:** ~40 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 136-01-01 | 01 | 1 | UPG-01 | — | Task emits a compilable, idempotent move migration: all four `ALTER … SET SCHEMA`, byte-parity trigger/function (`SET search_path=''` / `45A01`), `SET LOCAL lock_timeout`, working `down/0` | unit | `mix test test/mailglass/upgrade_v2_schema_generation_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 136-02-01 | 02 | 2 | UPG-01/04 | — | Generated migration over a 1.x `public` seed moves all four tables to `mailglass.*`; 45A01 fires under moved schema with NO `search_path` pin; version-comment + citext survive; `down` reverses to `public` | integration (DDL, `async: false`) | `mix test test/mailglass/upgrade_v2_schema_migration_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 136-03-01 | 03 | 1 | UPG-02 | — | `guides/upgrading-to-v2_0.md` contains Route A, Route B, `create_schema:false` grants SQL, `public.mailglass_*` grep checklist, `lock_timeout`/retry posture | doc-token | `mix test test/mailglass/upgrade_v2_docs_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 136-03-02 | 03 | 1 | UPG-03 | — | Both api_stability docs (core + inbound) document `:schema` as a stable 2.0 surface + tenancy-vs-schema orthogonality prose | doc-token | `mix test test/mailglass/upgrade_v2_docs_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 136-03-03 | 03 | 1 | UPG-02 (release gate) | — | `guides/upgrading-to-v2_0.md` present in `.planning/publish/mailglass-files.expected` (sorted) + wired into `mix.exs` extras/groups_for_extras | allowlist/doc | `mix test test/mailglass/upgrade_v2_docs_test.exs --seed 0` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/upgrade_v2_schema_generation_test.exs` — UPG-01 emitter (compilable body, idempotent wildcard, byte-parity block, no `@disable_ddl_transaction`)
- [ ] `test/mailglass/upgrade_v2_schema_migration_test.exs` — UPG-01/04 execution; clone `test/mailglass/schema_isolation_immutability_test.exs` skeleton (seed `public` → apply generated migration → assert move + 45A01-no-path-pin + citext + comment survival + `down` reverses)
- [ ] `test/mailglass/upgrade_v2_docs_test.exs` — UPG-02/03 doc-token + allowlist presence
- [ ] No framework install needed — ExUnit + TestRepo already boot.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | All phase behaviors have automated verification. |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 40s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
