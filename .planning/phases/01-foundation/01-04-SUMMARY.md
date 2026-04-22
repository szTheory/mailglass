---
phase: 01-foundation
plan: 04
subsystem: infra
tags: [message, struct, swoosh, optional-deps, oban, opentelemetry, mjml, gen_smtp, sigra, core-06, author-05, wave-2]

requires:
  - phase: 01-01
    provides: "Project scaffold with elixirc_options no_warn_undefined list covering Oban/Oban.Worker/Oban.Job/:otel_tracer/:otel_span/Mjml/:gen_smtp_client/Sigra at the project level — the per-module @compile declarations in this plan are defense-in-depth complementing that baseline. Optional deps (:oban, :opentelemetry, :mjml, :gen_smtp, :sigra) resolved in mix.lock so dep surface is available in dev/test."
  - phase: 01-02
    provides: "Mailglass.ConfigError with closed :type atom set including :optional_dep_missing — the error Plan 06's Renderer raises when MJML engine is configured but :mjml gateway's available?/0 returns false."
provides:
  - "Mailglass.Message — pure struct wrapping %Swoosh.Email{} with :mailable / :tenant_id / :stream / :tags / :metadata fields, plus new/2 builder; default stream :transactional"
  - "Mailglass.OptionalDeps — namespace module documenting the CORE-06 gateway pattern (compile-time @compile {:no_warn_undefined, [...]} scoped per module + runtime available?/0 via Code.ensure_loaded?/1) and enumerating the five gateways"
  - "Mailglass.OptionalDeps.Oban — gates {:oban, \"~> 2.21\"}; @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}; available?/0 :: boolean via Code.ensure_loaded?(Oban)"
  - "Mailglass.OptionalDeps.OpenTelemetry — gates {:opentelemetry, \"~> 1.7\"}; @compile on erlang-atom modules :otel_tracer and :otel_span; D-32 adopter-owned (no attach_otel/0)"
  - "Mailglass.OptionalDeps.Mjml — gates {:mjml, \"~> 5.3\"} (Rust NIF, Hex package :mjml, module Mjml — NOT :mrml); for AUTHOR-05 opt-in MJML template engine"
  - "Mailglass.OptionalDeps.GenSmtp — gates {:gen_smtp, \"~> 1.3\"}; entry is erlang atom :gen_smtp_client; for mailglass_inbound SMTP ingress (v0.5+)"
  - "Mailglass.OptionalDeps.Sigra — conditionally compiled (if Code.ensure_loaded?(Sigra) wraps defmodule); module does not exist when :sigra absent; callers guard via Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra)"
affects:
  - phase-01-plan-05-components
  - phase-01-plan-06-renderer
  - phase-2-persistence-tenancy
  - phase-3-outbound
  - phase-4-webhooks
  - phase-5-admin
  - phase-6-credo
  - phase-7-installer

tech-stack:
  added:
    - "Mailglass.Message canonical struct — the render pipeline's output type"
    - "Five Mailglass.OptionalDeps.* gateway modules implementing CORE-06 per-module granularity"
  patterns:
    - "Gateway module pattern per optional dep: @compile {:no_warn_undefined, [...]} as the first declaration after defmodule + @moduledoc; available?/0 :: boolean via Code.ensure_loaded?/1; the gated module list is the single authorized callsite (Phase 6 Credo NoBareOptionalDepReference enforces)"
    - "Conditional compilation pattern (Sigra): the entire defmodule wrapped in if Code.ensure_loaded?(Sigra) do ... end — the module does not exist at all when sigra absent, and callers probe existence via Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra) rather than rescuing UndefinedFunctionError on available?/0"
    - "Message wraps (does not replace) %Swoosh.Email{}. All email content stays in the inner Swoosh struct; Mailglass.Message adds domain metadata (mailable, tenant_id, stream, tags, adopter metadata) Swoosh does not model"
    - "Stream default :transactional — protects the auth/security invariant (no tracking on transactional streams per D-08 project-level) because any caller who forgets to set :stream gets the safe default"

key-files:
  created:
    - "lib/mailglass/message.ex — pure struct wrapping Swoosh.Email with mailglass-specific fields; new/2 builder with keyword opts; @type t and @type stream"
    - "lib/mailglass/optional_deps.ex — namespace-only moduledoc documenting the CORE-06 pattern and enumerating gateways"
    - "lib/mailglass/optional_deps/oban.ex — Oban gateway (available?/0 delegates to Code.ensure_loaded?(Oban))"
    - "lib/mailglass/optional_deps/opentelemetry.ex — :opentelemetry gateway (probes :otel_tracer)"
    - "lib/mailglass/optional_deps/mjml.ex — :mjml Rust NIF gateway (probes Mjml module)"
    - "lib/mailglass/optional_deps/gen_smtp.ex — :gen_smtp gateway (probes :gen_smtp_client erlang atom)"
    - "lib/mailglass/optional_deps/sigra.ex — :sigra gateway inside `if Code.ensure_loaded?(Sigra) do ... end` (conditionally compiled)"
  modified: []

key-decisions:
  - "Mailglass.Message.new/2 accepts a full keyword list via Keyword.get with per-option defaults rather than a struct-update shortcut. This matches the plan's example, keeps the builder uniform regardless of how many opts are passed, and lets future fields slot in without callsite changes. Pattern-match on %Swoosh.Email{} guarantees the first arg is the right shape."
  - "Mailglass.OptionalDeps.Sigra stays conditionally compiled even though the project-level elixirc_options already includes Sigra in no_warn_undefined. The conditional wrapping is the accrue pattern Sigra itself expects — Sigra may run compile-time AST discovery that doesn't play well with always-compiled placeholder modules. available?/0 returning an unconditional `true` documents the invariant: the module's mere existence implies availability."
  - "OpenTelemetry gateway probes :otel_tracer (stable API surface) rather than the package name :opentelemetry (not a loadable module). This mirrors accrue/integrations/opentelemetry.ex and matches the PATTERNS.md example verbatim."
  - "Sigra gateway file opens with a comment explaining the conditional-compile pattern before the `if` guard. The file contains 2 occurrences of the literal `no_warn_undefined` string (inline comment + @compile attribute); downstream tooling that greps for a single @compile line should count the one inside the defmodule."

patterns-established:
  - "Gateway module shape: @moduledoc → @compile {:no_warn_undefined, [...]} → @doc + @doc since + @spec + def available?, do: Code.ensure_loaded?(Module). Five lines of logic, tight scope. Phase 3+ Outbound consumes Oban this way; Phase 6 Credo check NoBareOptionalDepReference flags any other callsite."
  - "Message canonical-struct shape: @type t as struct-literal with concrete field types; defstruct with required fields first (no default), then defaulted fields; new/2 builder that pattern-matches the wrapped external struct. Phase 2's Delivery, Event, Suppression schemas follow this shape (Ecto schemas rather than plain structs, but same field-order discipline)."

requirements-completed: [CORE-06, AUTHOR-05]

duration: 4min
completed: 2026-04-22
---

# Phase 1 Plan 4: Message Struct + Five OptionalDeps Gateways Summary

**`Mailglass.Message` wrapping `%Swoosh.Email{}` with `:mailable`/`:tenant_id`/`:stream`/`:tags`/`:metadata`, plus five `Mailglass.OptionalDeps.*` gateway modules implementing CORE-06 per-module compile-time + runtime optional-dep gating so `mix compile --no-optional-deps --warnings-as-errors` stays green.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-22T15:05:28Z
- **Completed:** 2026-04-22T15:09:00Z
- **Tasks:** 2 / 2
- **Files created:** 7 (1 Message + 1 namespace + 5 gateway modules)
- **Files modified:** 0

## Accomplishments

- `Mailglass.Message` — pure struct with canonical 6-field shape (`:swoosh_email`, `:mailable`, `:tenant_id`, `:stream`, `:tags`, `:metadata`), `@type t` + `@type stream`, and `new/2` builder. Default `:stream` is `:transactional` so the auth/security invariant holds even when callers forget to specify it (D-08 project-level).
- Five `Mailglass.OptionalDeps.*` gateway modules, each following the accrue/sigra pattern exactly: `@compile {:no_warn_undefined, [...]}` scoped per-module, `available?/0 :: boolean()` via `Code.ensure_loaded?/1`. The namespace module `Mailglass.OptionalDeps` documents the pattern and enumerates all five.
- Sigra gateway is **conditionally compiled** (`if Code.ensure_loaded?(Sigra) do ... end`) — the module does not exist when `:sigra` is absent. Callers probe existence via `Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra)`.
- `mix compile --no-optional-deps --warnings-as-errors` exits 0 (THE CORE-06 enforcement gate); `mix compile --warnings-as-errors` also exits 0 with optional deps present; `mix test` unchanged at 58 tests + 1 property, 0 failures, 14 skipped.
- Requirements satisfied: **CORE-06** (optional-dep gateway pattern) and **AUTHOR-05** (MJML gateway in place ready for Plan 06's TemplateEngine to consume).

## Task Commits

Each task was committed atomically:

1. **Task 1: Mailglass.Message struct** — `68dba9a` (feat)
2. **Task 2: Mailglass.OptionalDeps namespace + 5 gateways** — `0da97ed` (feat)

**Plan metadata:** pending `docs(01-04)` commit after STATE.md + ROADMAP.md update.

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/mailglass/message.ex` | Pure struct `%Mailglass.Message{}` wrapping `%Swoosh.Email{}`; 6 fields; `@type t` + `@type stream`; `new/2` builder with keyword opts and stream-defaults-to-transactional invariant |
| `lib/mailglass/optional_deps.ex` | Namespace-only module; `@moduledoc` documents the CORE-06 compile-time + runtime pattern and enumerates all five gateways with dep version + purpose |
| `lib/mailglass/optional_deps/oban.ex` | `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}`; `available?/0` → `Code.ensure_loaded?(Oban)` |
| `lib/mailglass/optional_deps/opentelemetry.ex` | `@compile {:no_warn_undefined, [:otel_tracer, :otel_span]}`; `available?/0` probes `:otel_tracer` (stable API, not the package atom) |
| `lib/mailglass/optional_deps/mjml.ex` | `@compile {:no_warn_undefined, [Mjml]}`; `available?/0` probes `Mjml` — notes `:mjml` vs `:mrml` distinction |
| `lib/mailglass/optional_deps/gen_smtp.ex` | `@compile {:no_warn_undefined, [:gen_smtp_client]}`; `available?/0` probes the erlang-atom `:gen_smtp_client` (no Elixir `GenSmtp` module exists) |
| `lib/mailglass/optional_deps/sigra.ex` | Conditionally compiled inside `if Code.ensure_loaded?(Sigra) do ... end`; `available?/0` unconditionally returns `true` (the module's existence implies availability) |

## Decisions Made

- **`Mailglass.Message.new/2` uses `Keyword.get` with per-option defaults** rather than a struct-update shortcut. Uniform builder shape regardless of how many opts are passed; future fields slot in without callsite changes; pattern-match on `%Swoosh.Email{}` guards the input shape.
- **OpenTelemetry gateway probes `:otel_tracer`, not the package atom `:opentelemetry`** — the package name is not a loadable module. `:otel_tracer` is the stable API surface and matches the accrue/integrations precedent + PATTERNS.md line 814 verbatim.
- **Sigra gateway stays conditionally compiled** even though `Sigra` is already in the project-level `no_warn_undefined` list. Conditional compilation is the accrue-sigra pattern Sigra itself expects (compile-time AST discovery behavior); `available?/0 :: true` documents the invariant that module-existence ⇒ availability.

## Deviations from Plan

None — plan executed exactly as written. Both tasks completed with the code shapes specified in the `<action>` blocks (message struct fields, builder signature, and each gateway module's `@compile` directive and `available?/0` implementation match PATTERNS.md lines 768-853 and 858-889 verbatim, with expanded moduledocs for adopter-facing discoverability).

## Issues Encountered

- **All five optional deps report `available?: true` in dev/test** despite being marked `optional: true` in `mix.exs`. This is expected: Mix resolves and loads optional deps in the local `mix deps.get` graph regardless of the `optional: true` flag; that flag only controls whether the dep is required when mailglass is consumed as a Hex dependency by downstream adopters. The CI enforcement is `mix compile --no-optional-deps --warnings-as-errors`, which compiles without loading the optional deps and is the real test of the gateway pattern. That lane passed.
- **The OTLP exporter warning** (`OTLP exporter module opentelemetry_exporter not found`) continues to fire at test boot. Pre-existing since Plan 01 (documented in `01-01-SUMMARY.md` Issues Encountered); not a compile warning, so `--warnings-as-errors` unaffected.

## User Setup Required

None — no external service configuration required.

## Self-Check

- File verification:
  - FOUND: `lib/mailglass/message.ex`
  - FOUND: `lib/mailglass/optional_deps.ex`
  - FOUND: `lib/mailglass/optional_deps/oban.ex`
  - FOUND: `lib/mailglass/optional_deps/opentelemetry.ex`
  - FOUND: `lib/mailglass/optional_deps/mjml.ex`
  - FOUND: `lib/mailglass/optional_deps/gen_smtp.ex`
  - FOUND: `lib/mailglass/optional_deps/sigra.ex`
- Commit verification:
  - FOUND: `68dba9a` (Task 1 — Message struct)
  - FOUND: `0da97ed` (Task 2 — five OptionalDeps gateways)
- Gate verification:
  - PASSED: `mix compile --no-optional-deps --warnings-as-errors` exits 0
  - PASSED: `mix compile --warnings-as-errors` exits 0
  - PASSED: `mix test` exits 0 (58 tests + 1 property, 0 failures, 14 skipped — no regressions from 01-03 baseline)
  - PASSED: `grep -q "@compile {:no_warn_undefined, \[Oban" lib/mailglass/optional_deps/oban.ex`
  - PASSED: `grep -q "Code.ensure_loaded?(Oban)" lib/mailglass/optional_deps/oban.ex`
  - PASSED: `grep -q "defstruct" lib/mailglass/message.ex`

## Self-Check: PASSED

## Next Phase Readiness

- `Mailglass.Message` is ready for Plan 06's `Mailglass.Renderer.render/2` to consume as its output type. Plan 05 (Components) does not reference Message directly — it builds HEEx slots that Plan 06 assembles into a Message.
- `Mailglass.OptionalDeps.Mjml.available?/0` is ready for Plan 06's `Mailglass.TemplateEngine.MJML` to gate compile on (AUTHOR-05 opt-in path).
- `Mailglass.OptionalDeps.Oban.available?/0` is ready for Phase 3's `Mailglass.Outbound.deliver_later/2` to consult before dispatching an Oban job vs. falling back to `Task.Supervisor`.
- `Mailglass.OptionalDeps.OpenTelemetry.available?/0` is ready for future Config validation (refuses an OTel-requiring setting when the dep is absent; ConfigError `:optional_dep_missing` type already exists from Plan 02).
- Phase 6's `NoBareOptionalDepReference` Credo check has a stable set of gateway modules to whitelist as the authorized callsites.

---
*Phase: 01-foundation*
*Completed: 2026-04-22*
