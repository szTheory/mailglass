---
phase: 158
slug: simplify-architecture-without-breaking-adopters
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-17
---

# Phase 158 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Mix xref, Boundary, existing core/inbound stability contracts |
| Core quick | `mix test test/scripts/architecture_boundary_test.exs test/mailglass/runtime_test.exs test/mailglass/config_test.exs test/mailglass/outbound_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` |
| Inbound quick | `cd mailglass_inbound && mix test test/mailglass_inbound/architecture_port_test.exs test/mailglass_inbound/config_schema_test.exs test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` |
| Compile proof | `mix compile --no-optional-deps --warnings-as-errors` and `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` |
| Cycle proof | `mix xref graph --format cycles --label compile-connected` in both project roots, wrapped by a fail-closed architecture command |
| Full phase gates | `mix ci`; `cd mailglass_inbound && mix ci`; formatter checks in both roots |

Tests are red first inside the tracer task that owns them. Static architecture checks must include a non-vacuous negative control: a fixture/synthetic production edge or a mutation helper must prove core-to-inbound references and undeclared inbound core imports fail the guard. No check may merely assert that the current tree happens to be clean.

## Plan / Wave Verification Map

| Plan | Wave | Requirements | Focused proof |
|---|---:|---|---|
| 158-01 | 1 | ARCH-01, ARCH-02, ARCH-04 | first end-to-end Runtime/Config tracer, compatibility characterization, cycle removal, and non-vacuous xref/package-edge guard |
| 158-02 | 2 | ARCH-02, ARCH-04 | full Runtime adoption and Config parity across boot/cold-cache/application-env override paths |
| 158-03 | 2 | ARCH-03, ARCH-06 | declared core ports, inbound production edge inventory, package-local optional integration ownership |
| 158-04 | 3 | ARCH-04 | Outbound façade delegates to independently owned preflight, persistence, routing, and dispatch collaborators |
| 158-05 | 3 | ARCH-05 | core webhook and inbound ingress thin Plug façades over closed package-local outcomes |
| 158-06 | 4 | ARCH-01..ARCH-06 | package-independence, no-optional compile, stability/public seam, and no-UI scope integration gate |

## Wave 0 Requirements

- [ ] `test/scripts/architecture_boundary_test.exs` — runs/parses architecture guard and proves negative controls fail.
- [ ] `test/mailglass/runtime_test.exs` — Runtime construction, cache reset, invalid config, and Config parity characterization.
- [ ] `mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs` — production-only edge inventory and declared-port allowlist.
- [ ] Existing core outbound/webhook and inbound Plug tests gain characterization assertions for return/status/broadcast/ordering before production extraction.

Wave 0 is part of Plan 158-01. No production refactor begins before the characterization and anti-vacuity tests are failing for the old shape.

## Per-Task Verification Map

| Task | Plan | Requirement | Behavior under proof | Automated command |
|---|---|---|---|---|
| 01-01 | 01 | ARCH-01 | Existing core SCC is absent; both package graphs clean; forbidden fixture edge fails | core architecture script test + both xref commands |
| 01-02 | 01 | ARCH-02, ARCH-04 | First runtime-backed Config accessor preserves current schema/config behavior | core runtime/config focused test |
| 02-01 | 02 | ARCH-02 | Runtime owns validation/cache; Config remains equivalent through invalid/cold/override cases | core runtime/config focused test |
| 02-02 | 02 | ARCH-04 | Application boot consumes Runtime without changing public façade errors | core config/application tests |
| 03-01 | 03 | ARCH-03, ARCH-06 | Inbound production references only declared core ports; core has no inbound production dependency | core/inbound architecture contracts + no-optional compiles |
| 03-02 | 03 | ARCH-03, ARCH-06 | PubSub/job/shared primitive ownership is singular and optional gateways stay package-local | inbound port + optional-dep tests |
| 04-01 | 04 | ARCH-04 | Outbound sync tracer preserves result/status/transaction/dispatch contract after collaborator extraction | core outbound focused tests |
| 04-02 | 04 | ARCH-04 | Async/batch/replay route behavior remains through façade delegates | core outbound + stability tests |
| 05-01 | 05 | ARCH-05 | Webhook Plug retains verification-first and post-commit broadcast/status outcome | core webhook Plug tests |
| 05-02 | 05 | ARCH-05 | Inbound Plug retains exact provider status policy, verification order, and post-commit execution/broadcast | inbound Plug tests |
| 06-01 | 06 | ARCH-01..06 | Independently compiled packages expose no forbidden edge/cycle and no public seam drift | all focused contracts + no-optional compiles |
| 06-02 | 06 | ARCH-01..06 | Full suites and diff scope demonstrate no admin/operator UI edits | both `mix ci`, format checks, `git diff --check` |

## Manual-Only Verifications

None. The phase is source/contract/refactor work; all acceptance claims have a runnable command. Generated-host proof remains Phase 160 release evidence, not a substitute for the Phase 158 package-independence gate.

## Validation Sign-Off

- [x] Every requirement maps to an automated proof.
- [x] Architecture gates require negative controls, not only an empty current output.
- [x] Characterization precedes extraction for Runtime/Config, Outbound, and both Plugs.
- [x] No-optional compilation and independent package compilation are explicit gates.
- [x] Admin/operator UI paths are excluded from planned file ownership.
- [x] No package install or manual checkpoint is required.
