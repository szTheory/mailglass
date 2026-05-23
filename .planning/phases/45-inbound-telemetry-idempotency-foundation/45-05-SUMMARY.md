---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 05
subsystem: lint-enforcement
tags: [credo, optional-deps, telemetry, gen_smtp, gap-closure]
gap_closure: true
requires: []
provides:
  - "NoBareOptionalDepReference catches bare :mimemail / :gen_smtp_client calls outside the gateway (CR-01 closed)"
  - "TelemetryEventConvention catches under-segmented / wrong-rooted :telemetry.span/3 inbound prefixes (WR-02 closed)"
affects:
  - ".credo.exs (gated_modules now keyed on gen_smtp Erlang atoms)"
  - "credo_checks/telemetry_event_convention.ex (span-aware walk clause)"
tech-stack:
  added: []
  patterns:
    - "Erlang-atom call-site keying for optional-dep gateways with no Elixir module (gen_smtp)"
    - "Dual walk/5 clauses (execute + span) sharing a threshold-parameterized validate helper (mirrors NoPiiInTelemetryMeta)"
    - "min_segments - 1 off-by-one threshold for :telemetry.span/3 prefixes (runtime appends :start/:stop/:exception)"
key-files:
  created: []
  modified:
    - .credo.exs
    - credo_checks/telemetry_event_convention.ex
    - test/mailglass/credo/no_bare_optional_dep_reference_test.exs
    - test/mailglass/credo/telemetry_event_convention_test.exs
decisions:
  - "Fixed CR-01 config-only: added :mimemail/:gen_smtp_client atom keys to .credo.exs; rejected the root_module/1 generalization alternative because the check already resolves bare-atom roots (line 105) — the only defect was the missing map keys. credo_checks/no_bare_optional_dep_reference.ex left byte-for-byte unchanged."
  - "Refactored TelemetryEventConvention's shared root/length validation into a private validate/8 helper parameterized by threshold + trigger so the execute and span clauses cannot drift; the issue message keeps reporting min_segments (operators reason in final event-name terms, not prefix length)."
  - "Regression tests thread the activating param explicitly: NoBare passes the atom-keyed gated_modules (pinning check behavior independent of .credo.exs drift) with a default-params negative control; Telemetry passes the configured required_root: [:mailglass, :mailglass_inbound] (the default root :mailglass alone would make an inbound case pass for the wrong reason)."
metrics:
  duration: "~10 min"
  completed: 2026-05-23
  tasks_completed: 2
  files_modified: 4
requirements: [MIME-02, TELE-06]
---

# Phase 45 Plan 05: Credo Guard Gap-Closure (CR-01 + WR-02) Summary

Made the two custom Credo guards actually fire for their stated targets: keyed `gated_modules` on gen_smtp's real Erlang call-site atoms (`:mimemail`, `:gen_smtp_client`) and added a `:telemetry.span/3`-aware walk clause to `TelemetryEventConvention`, each backed by regression tests that pass for the RIGHT reason (the activating param is threaded in, with a negative control proving the default does not catch).

## What Was Built

### Task 1 — CR-01 (BLOCKER): bare gen_smtp atom references now caught

`NoBareOptionalDepReference` keyed `gated_modules` on the phantom alias `GenSmtp`, but gen_smtp is an Erlang library with no `GenSmtp` Elixir module — it is reached only via the atoms `:mimemail` and `:gen_smtp_client`. `Map.fetch(gated_modules, :mimemail)` always missed, so a bare `:mimemail.decode(...)` outside the gateway passed `mix credo --strict`.

- **`.credo.exs`** — added `:mimemail => Mailglass.OptionalDeps.GenSmtp` and `:gen_smtp_client => Mailglass.OptionalDeps.GenSmtp` to `gated_modules`; retained the `GenSmtp => [...]` alias key (inbound `mime.ex` reaches the gateway via an alias whose root resolves to `GenSmtp`). Expanded the explanatory comment to record why gen_smtp is keyed on Erlang atoms.
- **`credo_checks/no_bare_optional_dep_reference.ex`** — unchanged (git diff confirms). `root_module/1` (line 105) already returns `{:ok, :mimemail}` for the bare-atom path; the missing map keys were the only defect.
- **Test** — added a `run_check/3` arity threading explicit params; cases (a) bare `:mimemail.decode` outside the gateway with the explicit atom-keyed param + in-scope `lib/mailglass/...` filename asserts one issue mentioning the gateway; (b) the same call inside `Mailglass.OptionalDeps.GenSmtp` asserts zero; (c) bare `:gen_smtp_client.send` asserts one issue; (d) negative control — the same `:mimemail` source run via the default-params `run_check/2` asserts `== []`, proving the atom-key param is what activates the catch. The four pre-existing tests are unchanged and still use the original `run_check/2`.

### Task 2 — WR-02 (WARNING): inbound `:telemetry.span/3` prefixes now validated

`TelemetryEventConvention.walk/5` matched only `:telemetry.execute`. Every inbound event is `:telemetry.span/3`, so the widened `required_root: [:mailglass, :mailglass_inbound]` checked nothing.

- **`credo_checks/telemetry_event_convention.ex`** — added a second `walk/5` clause matching `{{:., _, [:telemetry, :span]}, meta, [event_ast, _metadata, _fun]}` (arity 3); validated against `min_segments - 1` (the runtime appends `:start`/`:stop`/`:exception`, so a span prefix is one segment shorter than the emitted event). Extracted the shared root/length validation into a private `validate/8` helper parameterized by `threshold` + `trigger` so the execute and span clauses share logic. The span path sets `trigger: ":telemetry.span"`; the message still reports `min_segments`. Non-literal (var) prefixes still produce no issue. Moduledoc updated to state both call forms are covered.
- **Test** — added a `run_check/2` arity; inbound-span cases run with the CONFIGURED `required_root: [:mailglass, :mailglass_inbound], min_segments: 4` (the default root is the bare `:mailglass` atom, so an inbound case run with defaults would pass for the wrong reason): (a) 3-seg `[:mailglass_inbound, :ingress, :request]` passes; (b) 2-seg prefix raises one issue; (c) non-mailglass `[:my_app, :ingress, :request]` raises one issue; (d) under-segmented `:telemetry.execute` raises one issue; (e) 4-seg execute passes. The three pre-existing tests still use the original `run_check/1`.

## Verification

Local `mix` cannot run the suite — inbound deps are unfetched and local Elixir 1.19 differs from CI 1.18 (per the plan's toolchain caveat, CI is the source of truth). Verification performed:

- **Source proofs (grep):** `.credo.exs` contains `:mimemail =>` and `:gen_smtp_client =>` atom keys plus the retained `GenSmtp =>` alias key; the check has a `[:telemetry, :span]` walk clause with the `min_segments - 1` threshold and a `validate` helper; both tests have the new arities and the activating params (`%{:mimemail => ...}` / `required_root: [:mailglass, :mailglass_inbound]`) and the `== []` negative control.
- **`git diff --exit-code credo_checks/no_bare_optional_dep_reference.ex`** → clean (check source byte-for-byte unchanged, per acceptance criteria).
- **AST probes (standalone `elixir`):** confirmed a bare `:mimemail.decode(raw)` parses to `{{:., _, [:mimemail, :decode]}, _, _}` and resolves through `root_module/1`'s atom path to `{:ok, :mimemail}` (the catch fires only because the atom key now exists); confirmed a `:telemetry.span([:mailglass_inbound, :ingress, :request], ...)` prefix matches the new span clause, is a 3-element literal atom list passing the `>= 3` threshold, and its root is a member of the configured root list (passes for the right reason; a 2-seg or non-mailglass prefix fails).
- **CI proof (deferred to CI run):** `mix test test/mailglass/credo/no_bare_optional_dep_reference_test.exs`, `mix test test/mailglass/credo/telemetry_event_convention_test.exs`, and `mix credo --strict` (credo_strict job).

## Deviations from Plan

None — plan executed exactly as written. No Rule 1-4 deviations, no auth gates, no architectural changes.

## Known Stubs

None.

## Notes for Downstream

- Recurrence backstops (check-coverage meta-test, `.credo.exs` config sentinel) and the two pre-existing uncovered-check regression tests live in plan 45-09 (wave 3) — this plan deliberately pins check BEHAVIOR (via threaded params) while 45-09 will pin the .credo.exs CONFIG.
- The `validate/8` helper is the single source of root/length logic for both telemetry call forms; future threshold changes should flow through it, not the per-clause walk heads.
