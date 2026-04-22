---
phase: 01-foundation
plan: 02
subsystem: infra
tags: [errors, defexception, jason, api-stability, core-01, phase-1, wave-2]

requires:
  - phase: 01-01
    provides: "Project scaffold + Mailglass facade with flat root Boundary + elixirc_options no_warn_undefined with Jason available; test/mailglass/error_test.exs stub with @moduletag :skip + 3 flunk placeholders ready to de-skip."
provides:
  - "Mailglass.Error namespace + behaviour module exporting @type t union, @callback type/1 + retryable?/1, and public helpers is_error?/1, kind/1, retryable?/1, root_cause/1"
  - "Six sibling defexception modules under lib/mailglass/errors/ — SendError, TemplateError, SignatureError, SuppressedError, RateLimitError, ConfigError — each with @behaviour Mailglass.Error, closed @types atom list, __types__/0 accessor, new/2 builder, brand-voice format_message/2, and @derive {Jason.Encoder, only: [:type, :message, :context]} guarding :cause from PII leakage"
  - "Per-kind field specializations: SendError.delivery_id, SignatureError.provider, RateLimitError.retry_after_ms"
  - "docs/api_stability.md — adopter-facing contract locking the closed :type atom sets (D-07), Jason.Encoder shape (T-PII-002), and adapter return shape stub"
  - "test/mailglass/error_test.exs de-skipped with 18 assertions covering raisability, struct + :type discrimination, __types__/0 ↔ api_stability.md parity for all six modules, Jason.Encoder :cause exclusion, Mailglass.Error helpers, and brand-voice discipline"
affects: [phase-01-plan-03-config-telemetry-repo-idempotency, phase-01-plan-04-optional-deps, phase-01-plan-05-components, phase-01-plan-06-renderer, phase-2-persistence-tenancy, phase-3-outbound, phase-4-webhooks, phase-5-admin, phase-6-credo, phase-7-installer]

tech-stack:
  added:
    - "Mailglass.Error behaviour contract (narrow: type/1 + retryable?/1)"
    - "Six defexception structs each deriving Jason.Encoder on [:type, :message, :context]"
  patterns:
    - "Sibling-per-kind defexception: each error gets its own module under lib/mailglass/errors/, @behaviour Mailglass.Error, closed @types atom list exposed via __types__/0, new/2 builder with guard `when type in @types`, brand-voice defp format_message/2"
    - "Per-kind field specializations only where Dialyzer precision is justified (delivery_id on SendError, provider on SignatureError, retry_after_ms on RateLimitError) — common [:type, :message, :cause, :context] shape everywhere else"
    - "Jason.Encoder discipline: @derive {Jason.Encoder, only: [:type, :message, :context]} on every error struct; :cause and per-kind fields deliberately omitted from JSON output (T-PII-002)"
    - "api_stability.md as a first-class product artifact that tests assert against — __types__/0 per module mirrors the documented atom set; additions require CHANGELOG + @since, removals require major bump"
    - "Error struct-discrimination in tests via err.__struct__ == Mod rather than literal `match?(%Mod{}, err)` — Elixir 1.19's static type checker narrows terms to the known struct, so the literal pattern trips --warnings-as-errors on any assertion that proves non-match at compile time"

key-files:
  created:
    - "lib/mailglass/error.ex — namespace + behaviour module (not a struct)"
    - "lib/mailglass/errors/send_error.ex — :adapter_failure | :rendering_failed | :preflight_rejected | :serialization_failed + :delivery_id"
    - "lib/mailglass/errors/template_error.ex — :heex_compile | :missing_assign | :helper_undefined | :inliner_failed"
    - "lib/mailglass/errors/signature_error.ex — :missing | :malformed | :mismatch | :timestamp_skew + :provider"
    - "lib/mailglass/errors/suppressed_error.ex — :address | :domain | :tenant_address"
    - "lib/mailglass/errors/rate_limit_error.ex — :per_domain | :per_tenant | :per_stream + :retry_after_ms"
    - "lib/mailglass/errors/config_error.ex — :missing | :invalid | :conflicting | :optional_dep_missing"
    - "docs/api_stability.md — locked :type atom sets for all six errors + Jason.Encoder contract + adapter return shape stub"
  modified:
    - "test/mailglass/error_test.exs — @moduletag :skip removed; 3 flunk stubs replaced with 18 real assertions"

key-decisions:
  - "Struct-discrimination tests use __struct__ module comparison (err.__struct__ == Mailglass.TemplateError) instead of `match?(%Mailglass.TemplateError{}, err)`. Elixir 1.19's new type checker narrows the term to %Mailglass.SendError{} at compile time, so the literal mismatch becomes a typing violation under --warnings-as-errors. Runtime struct-module comparison tests the same property (the discriminator is the struct module) without tripping the compile-time narrowing. The contract is still pattern-match-by-struct at call sites; the test just asserts the contract through a path the type system accepts."
  - "RateLimitError.new/2 accepts both :context.retry_after_ms (for message formatting) and a top-level :retry_after_ms option (to populate the struct field). The plan's example showed setting the struct field via `%RateLimitError{err | retry_after_ms: 5000}` rebinding, but a direct option on new/2 is clearer for callers and tested the same way. Both paths remain supported."
  - "root_cause/1 special-cases non-mailglass causes: when the cause is a plain Exception without a :cause field (e.g. %RuntimeError{}), walking stops and returns that exception. Mailglass errors chain naturally; third-party exceptions terminate the walk."

patterns-established:
  - "Sibling-per-kind defexception with @behaviour Mailglass.Error: closed @types atom list, __types__/0 accessor, new/2 with `when type in @types` guard, defp format_message/2 for brand-voice strings, @impl true for Exception's message/1, @impl Mailglass.Error for type/1 + retryable?/1. Phase 2+ error modules (EventLedgerImmutableError, etc.) follow this exact shape."
  - "api_stability.md as a tested contract: every closed atom set documented there has a corresponding __types__/0 assertion in the module's test file. Phase 2+ adds Delivery status enum, Event type enum, Suppression.scope — each lands with its own api_stability.md section and __types__/0 equivalent."
  - "Jason.Encoder :only whitelist on every serializable struct (not just errors). The pattern of `@derive {Jason.Encoder, only: [:type, :message, :context]}` before `defexception` is the baseline; adopters who need the full cause chain walk it via Mailglass.Error.root_cause/1 explicitly (T-PII-002 in the threat model)."

requirements-completed: [CORE-01]

duration: 5min
completed: 2026-04-22
---

# Phase 1 Plan 2: Error Hierarchy Summary

**Six sibling defexception modules under `Mailglass.*` with closed `:type` atom sets, a narrow `Mailglass.Error` behaviour contract, Jason.Encoder cause-exclusion (T-PII-002), and a tested `docs/api_stability.md` adopter contract — the zero-dep error foundation every downstream module returns.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-22T14:39:04Z
- **Completed:** 2026-04-22T14:43:49Z
- **Tasks:** 2 / 2
- **Files created:** 8 (error.ex + 6 error structs + api_stability.md)
- **Files modified:** 1 (error_test.exs — de-skipped)

## Accomplishments

- `Mailglass.Error` namespace + behaviour module with `@type t` union, `@callback type/1 + retryable?/1`, and public helpers `is_error?/1`, `kind/1`, `retryable?/1`, `root_cause/1` (D-02)
- Six sibling `defexception` modules (SendError, TemplateError, SignatureError, SuppressedError, RateLimitError, ConfigError), each with closed `@types` atom list exposed via `__types__/0`, `new/2` builder with guard `when type in @types`, and brand-voice `defp format_message/2` (D-01, D-07, D-08)
- Per-kind fields: `SendError.delivery_id`, `SignatureError.provider`, `RateLimitError.retry_after_ms` with a defaulted non-negative integer (D-04)
- `@derive {Jason.Encoder, only: [:type, :message, :context]}` on every error — `:cause` and per-kind fields deliberately omitted to prevent PII leakage through recursive adapter-struct serialization (D-06 / T-PII-002)
- Retry policy encoded via `@impl Mailglass.Error retryable?/1` per D-09: SignatureError / ConfigError / SuppressedError / TemplateError → `false`; RateLimitError → `true`; SendError `:adapter_failure` → `true` else `false`
- `docs/api_stability.md` locks the six closed atom sets as the adopter contract; `test/mailglass/error_test.exs` asserts each `__types__/0` matches verbatim
- 18 real test assertions replace the three `flunk` stubs; `mix test --warnings-as-errors` exits 0 with 39 total tests (18 pass + 21 still-skipped Wave 0 stubs from Plan 01-01, 0 failures)

## Task Commits

1. **Task 1: Mailglass.Error namespace + six defexception modules** — `0d0ca21` (feat)
2. **Task 2: api_stability.md + wired error_test.exs** — `417f7e1` (docs)

_Task 1 was marked `tdd="true"` in the plan; however, the RED gate was pre-established by Plan 01-01 which committed `test/mailglass/error_test.exs` with `@moduletag :skip` + 3 `flunk("not yet implemented")` placeholders. Task 1 satisfied the GREEN gate by implementing all seven modules so `mix compile --warnings-as-errors` and `mix test test/mailglass/error_test.exs` both exit 0. Task 2's docs commit then unskipped and expanded the test suite to 18 assertions._

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/mailglass/error.ex` | Namespace + behaviour module; @type t union, callbacks, is_error?/kind/retryable?/root_cause helpers |
| `lib/mailglass/errors/send_error.ex` | `:adapter_failure` (retryable) / `:rendering_failed` / `:preflight_rejected` / `:serialization_failed` + `:delivery_id` field |
| `lib/mailglass/errors/template_error.ex` | `:heex_compile` / `:missing_assign` / `:helper_undefined` / `:inliner_failed` |
| `lib/mailglass/errors/signature_error.ex` | `:missing` / `:malformed` / `:mismatch` / `:timestamp_skew` + `:provider` field |
| `lib/mailglass/errors/suppressed_error.ex` | `:address` / `:domain` / `:tenant_address` (never retryable; mirrors `Suppression.scope`) |
| `lib/mailglass/errors/rate_limit_error.ex` | `:per_domain` / `:per_tenant` / `:per_stream` + `:retry_after_ms` field (default 0, always retryable) |
| `lib/mailglass/errors/config_error.ex` | `:missing` / `:invalid` / `:conflicting` / `:optional_dep_missing` (never retryable; Config.validate_at_boot! raises this in Plan 03) |
| `docs/api_stability.md` | Adopter-facing contract: closed `:type` atom sets for all six errors + Jason.Encoder shape (T-PII-002) + adapter return shape stub |
| `test/mailglass/error_test.exs` | `@moduletag :skip` removed; 18 real assertions replace three `flunk` stubs |

## Decisions Made

- **Struct-discrimination tests use `__struct__` module comparison instead of literal `match?(%Mailglass.TemplateError{}, err)`.** Elixir 1.19.5's type checker statically narrows `err` to `%Mailglass.SendError{}` after `Mailglass.SendError.new/2`, so the literal pattern-match-against-different-struct becomes a typing violation under `--warnings-as-errors`. The runtime contract (pattern-match by struct at call sites) is unchanged; the test uses `err.__struct__ == Mailglass.TemplateError` to prove the same discrimination property through a path the type system accepts. See Deviations #1 below.
- **`RateLimitError.new/2` accepts both `:context.retry_after_ms` and a top-level `:retry_after_ms` option.** The plan showed setting the struct field via `%RateLimitError{err | retry_after_ms: 5000}` rebinding, which is awkward for callers. Adding `:retry_after_ms` as a direct option on `new/2` keeps the struct field populated correctly while the context map still carries the value for message formatting. Both paths are supported; callers can pass one, both, or neither.
- **`root_cause/1` terminates gracefully on non-mailglass causes.** When the cause is a plain `Exception` without its own `:cause` field (e.g., a `%RuntimeError{}` wrapped by a `SendError`), walking stops at that exception and returns it. Mailglass errors chain naturally through their `:cause` field; third-party exceptions become leaves. This is the pragmatic interpretation — the alternative (requiring every wrapped exception to have `:cause`) would force adopters to hand-wrap every third-party error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `refute match?(%Mailglass.TemplateError{}, err)` fails Elixir 1.19's type checker under `--warnings-as-errors`**

- **Found during:** Task 2 verification (`mix test test/mailglass/error_test.exs --warnings-as-errors`)
- **Issue:** Elixir 1.19.5 introduced a static type checker that narrows terms through function calls. After `err = Mailglass.SendError.new(:adapter_failure)`, the checker knows `err` is a `%Mailglass.SendError{}`, so the literal `refute match?(%Mailglass.TemplateError{}, err)` triggers a typing violation ("dynamic(%Mailglass.SendError{...})" vs `%Mailglass.TemplateError{}`). The test intent is correct — at runtime, the struct module IS the discriminator — but the compile-time check treats the statically-known mismatch as a bug. Tests passed (18/18) but `--warnings-as-errors` aborted the suite.
- **Fix:** Replaced `refute match?(%Mailglass.TemplateError{}, err)` with `refute err.__struct__ == Mailglass.TemplateError`. Proves the same discrimination property (struct module is the contract) through a runtime expression the type checker does not statically narrow. The contract at call sites (pattern-match-by-struct) is unchanged.
- **Files modified:** `test/mailglass/error_test.exs` (single line)
- **Verification:** `mix test test/mailglass/error_test.exs --warnings-as-errors` exits 0 with 18 tests / 0 failures; full `mix test --warnings-as-errors` exits 0 with 39 tests / 0 failures / 21 still-skipped.
- **Committed in:** `417f7e1` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 - bug in test assertion syntax)
**Impact on plan:** Scope unchanged. The fix preserved the exact test intent by restating the assertion through an expression the Elixir 1.19 type checker accepts. No implementation code was modified as a result; the change is isolated to a single test line.

## Issues Encountered

- **Pre-existing OTLP exporter warning at test boot.** The `opentelemetry_exporter` Logger.warning carried over from Plan 01-01 — it fires at application start because `:opentelemetry` is loaded as an optional dep via `mix deps.get` but its exporter is not. Not a compile warning (does not affect `--warnings-as-errors`); documented here only for continuity. Resolves when adopters add `{:opentelemetry_exporter, "~> 1.7"}` to their own deps.

## Self-Check

- File verification:
  - FOUND: `lib/mailglass/error.ex`
  - FOUND: `lib/mailglass/errors/send_error.ex`
  - FOUND: `lib/mailglass/errors/template_error.ex`
  - FOUND: `lib/mailglass/errors/signature_error.ex`
  - FOUND: `lib/mailglass/errors/suppressed_error.ex`
  - FOUND: `lib/mailglass/errors/rate_limit_error.ex`
  - FOUND: `lib/mailglass/errors/config_error.ex`
  - FOUND: `docs/api_stability.md`
  - FOUND: `test/mailglass/error_test.exs` (modified, de-skipped)
- Commit verification:
  - FOUND: `0d0ca21` (Task 1)
  - FOUND: `417f7e1` (Task 2)
- Gate verification:
  - `mix compile --warnings-as-errors` exits 0
  - `mix compile --no-optional-deps --warnings-as-errors` exits 0
  - `mix test test/mailglass/error_test.exs --warnings-as-errors` exits 0 with 18 tests / 0 failures
  - `mix test --warnings-as-errors` exits 0 with 39 tests / 0 failures / 21 skipped (Wave 0 stubs)
  - grep confirms: `defexception` + `@derive {Jason.Encoder, only: [:type, :message, :context]}` + `__types__` in `send_error.ex`; `SendError` present in `docs/api_stability.md`

## Self-Check: PASSED

## Next Phase Readiness

- Plan 01-03 (Config + Telemetry + Repo + IdempotencyKey) can now raise `Mailglass.ConfigError.new(:missing, context: %{key: :repo})` and `Mailglass.ConfigError.new(:optional_dep_missing, context: %{dep: :oban})` directly. The `no_warn_undefined` entry `{Mailglass.Config, :validate_at_boot!, 0}` in `mix.exs` remains — it becomes a no-op once Plan 03 ships Config.
- Plan 01-04 (OptionalDeps) has a concrete error to raise when a gated call happens without the dep loaded.
- Plan 01-05 (Components) can raise `Mailglass.TemplateError.new(:missing_assign, context: %{assign: name})` from the default render path.
- Plan 01-06 (Renderer) consumes `{:error, %Mailglass.TemplateError{}}` and `{:error, %Mailglass.SendError{type: :rendering_failed}}` from the render pipeline.
- Phase 2 (Persistence) consumes `%Mailglass.ConfigError{}` from `Mailglass.Repo.repo/0` when `:repo` is unset, and introduces its own `EventLedgerImmutableError` following the sibling-defexception pattern established here.

---
*Phase: 01-foundation*
*Completed: 2026-04-22*
