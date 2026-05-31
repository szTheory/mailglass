---
phase: 52
slug: trust-scope-lock-reference-host-baseline
researched: 2026-05-27
status: complete
confidence: high
posture: decisive scope lock + thin maintained reference host baseline
---

# Phase 52 Research: Trust Scope Lock + Reference Host Baseline

**Researched:** 2026-05-27  
**Domain:** reference-host baseline, trust-scope governance, contract-boundary enforcement  
**Confidence:** HIGH

## Summary

Phase 52 should establish one maintained, committed Phoenix reference host artifact that proves adopter bootstrapping and integration shape without expanding product scope. The host must be clearly distinct from installer fixtures, use only documented public seams, and ship enforceable scope boundaries so it cannot drift into a second product surface.

The decisive recommendation is:

1. Create one committed Ecto-capable host artifact under `reference/host_app` (not `test/example`).
2. Integrate only through stable seams (`mix mailglass.install`, `Mailglass.deliver/2` family, `MailglassAdmin.Router` macros, `MailglassInbound.Ingress.Plug`).
3. Add deterministic scope/boundary contract tests in the repo so HOST-01/HOST-02/HOST-03 fail closed when drift occurs.

## User Constraints (from `52-CONTEXT.md`)

### Locked Decisions

- **D-01:** Maintain a dedicated committed reference host app artifact separate from installer fixtures (`test/example` remains fixture-only).
- **D-02:** Integration must use documented public seams only.
- **D-03:** No internal-module coupling and no copied provider internals.
- **D-04:** Baseline is Ecto-capable and suitable for full trust journey handoff to Phase 53.
- **D-05:** Existing no-ecto post-publish smoke remains separate and unchanged.
- **D-06:** Ship explicit proof-scope allowlist and non-goals for the host app.
- **D-07:** Enforce boundaries through deterministic checks, not prose alone.
- **D-08:** Keep open hackney smoke issue as tracked dependency risk; do not fold into Phase 52 implementation scope.

### Claude's Discretion

- Final directory naming and internal layout for the reference host artifact.
- Exact enforcement mechanism shape (contract tests vs docs-check extension), provided checks are deterministic and repo-enforced.
- Minimal demo/seed data needed for host bootstrap.

### Deferred (Out of Scope for Phase 52)

- Provider-matrix broadening in v1.3.
- `SEED-003-ecosystem-integrations` promotion.
- `gen_smtp` listener/transport-class expansion.
- Closing the hackney post-publish smoke reliability debt (tracked for later OPS/EVID closeout).
- New product features in the reference host beyond trust-baseline proof.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `HOST-01` | Adopter can boot one maintained Phoenix reference host app from clean checkout using documented setup and published package constraints. | Commit a dedicated host at `reference/host_app` with its own README setup contract and deterministic boot command (`deps.get -> ecto.create -> ecto.migrate -> compile --warnings-as-errors`). |
| `HOST-02` | Reference host integrates through documented public Mailglass seams only, with no copied provider internals. | Add boundary contract tests that assert allowed seams are present and known internal-module patterns are absent. |
| `HOST-03` | Reference host includes explicit proof-scope allowlist and non-goals so it does not become a second product. | Add `reference/host_app/SCOPE.md` plus a scope-lock contract test validating required allowlist/non-goal tokens and forbidden expansion language. |

## Project Constraints

- Preserve v1.3 scope lock: trust proof only; no breadth expansion.
- Keep fast release smoke contract intact (`post-publish-smoke` no-ecto lane).
- Respect public contract posture from:
  - `docs/api_stability.md`
  - `mailglass_admin/docs/api_stability.md`
  - `mailglass_inbound/docs/api_stability.md`
- Keep this as planning/governance work, not a feature expansion phase.
- Remain Phoenix/Ecto/Postgres-first, no Node toolchain, no compatibility-surface widening.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Why |
|------------|--------------|----------------|-----|
| Maintained reference host artifact | `reference/host_app` | phase docs | Keeps trust host explicit, committed, and adopter-readable. |
| Clean checkout boot contract | host README + boot contract test | CI/local verification commands | Prevents "works only locally" drift. |
| Public seam-only integration | boundary contract tests | API stability docs | Enforces stable/internal split mechanically. |
| Scope allowlist and non-goals governance | `SCOPE.md` + scope contract test | review checklist | Prevents accidental second-product growth. |
| Risk carry-forward visibility | phase docs + assumptions log | later Phase 56 closeout | Keeps hackney issue tracked without scope hijack. |

## Standard Stack

| Component | Role | Status |
|-----------|------|--------|
| Phoenix 1.8+, Elixir 1.18+, OTP 27+, Ecto/Postgres | host baseline runtime contract | locked project stack |
| `mix mailglass.install` | canonical public install seam | stable |
| `Mailglass.deliver/2` family | canonical delivery API seam | stable |
| `MailglassAdmin.Router.mailglass_admin_routes/2` and `mailglass_operator_routes/2` | canonical admin/operator mount seams | stable |
| `MailglassInbound.Ingress.Plug` | canonical inbound ingress seam | stable (inbound package-local contract) |
| ExUnit contract tests under `test/reference_host/` | deterministic boundary/scope enforcement | recommended for Phase 52 |

## Recommended Plan Split

### Plan 52-01: Commit maintained reference host baseline (HOST-01)

- Create `reference/host_app` as the dedicated maintained host artifact.
- Add setup README with one canonical boot flow from clean checkout.
- Ensure Ecto-capable baseline (migration + repo setup path present).
- Keep fixture boundary explicit: do not repurpose `test/example`.

### Plan 52-02: Enforce public seam boundary (HOST-02)

- Add `test/reference_host/public_seams_contract_test.exs`.
- Positive assertions: required stable seams appear in host wiring/docs.
- Negative assertions: known internal modules/provider internals are absent.
- Add deterministic grep-based forbidden pattern list to keep fail-closed behavior.

### Plan 52-03: Lock proof scope and non-goals (HOST-03)

- Add `reference/host_app/SCOPE.md` with explicit:
  - scope allowlist
  - non-goals
  - deferred items
- Add `test/reference_host/scope_lock_contract_test.exs` to enforce required tokens and forbidden expansion terms.
- Reference milestone non-goals directly so scope lock survives future edits.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Host drifts into "second product" | milestone scope creep | explicit `SCOPE.md` + scope-lock contract test (required/forbidden tokens). |
| Internal-module coupling enters host | contract trust regression | boundary test with forbidden internal module patterns tied to api_stability docs. |
| Fast smoke and deep trust lanes get conflated | release window slows and trust signal blurs | keep no-ecto post-publish smoke unchanged; Phase 52 host is additive baseline only. |
| Reference host accidentally treated as fixture | adopter confusion | hard separation: `reference/host_app` maintained, `test/example` fixture-only. |
| Hackney smoke debt hijacks phase scope | delayed HOST closure | track as explicit dependency risk in docs; leave implementation to later OPS/EVID phase. |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit contract tests + deterministic command checks |
| Quick run | `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors` |
| Full phase run | `mix test test/reference_host/boot_contract_test.exs test/reference_host/public_seams_contract_test.exs test/reference_host/scope_lock_contract_test.exs --warnings-as-errors` |

### Requirement Mapping

| Req ID | Verification focus | Concrete command(s) |
|--------|--------------------|---------------------|
| `HOST-01` | clean checkout boot + documented setup path | `cd reference/host_app && mix deps.get && mix ecto.create && mix ecto.migrate && mix compile --warnings-as-errors` and `mix test test/reference_host/boot_contract_test.exs --warnings-as-errors` |
| `HOST-02` | stable-seam-only integration; no internals | `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors` and `rg "Mailglass\\.(Repo|Outbound\\.Projector|OptionalDeps)|MailglassInbound\\.Ingress\\.Providers|MailglassAdmin\\.Operator\\.Mount" reference/host_app` (expect no matches) |
| `HOST-03` | scope allowlist/non-goals are explicit and enforced | `mix test test/reference_host/scope_lock_contract_test.exs --warnings-as-errors` and `rg "Provider-matrix broadening|SEED-003|gen_smtp|second product" reference/host_app/SCOPE.md` (must match expected non-goal declarations) |

### Phase Gate

- All three requirement-mapped checks pass with `--warnings-as-errors`.
- `reference/host_app` exists and is bootable with documented commands.
- Scope and boundary contract tests are committed and green.

## Assumptions Log

| # | Assumption | Risk if wrong | Handling |
|---|------------|---------------|----------|
| A1 | `reference/host_app` is acceptable as canonical host location. | low | planner can rename path without changing architecture. |
| A2 | Adding `test/reference_host/*_contract_test.exs` is acceptable for enforcement. | low | fallback is equivalent deterministic checker script if needed. |
| A3 | Phase 52 should be additive to current smoke lanes, not a replacement. | medium | explicitly enforced by D-05 and roadmap scope lock. |
| A4 | Scope lock should include explicit references to deferred v1.3 non-goals. | low | keeps future planning drift visible and testable. |

## Sources

### Primary

- `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/METHODOLOGY.md`
- `docs/api_stability.md`
- `mailglass_admin/docs/api_stability.md`
- `mailglass_inbound/docs/api_stability.md`
- `.github/workflows/post-publish-smoke.yml`
- `test/mailglass/install/install_first_preview_smoke_test.exs`
- `test/example/README.md`
- `lib/mix/tasks/mailglass.install.ex`

### Secondary

- `lib/mix/tasks/mailglass.docs.check.ex` (existing deterministic docs-boundary enforcement pattern)

## RESEARCH COMPLETE
