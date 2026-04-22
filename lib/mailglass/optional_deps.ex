defmodule Mailglass.OptionalDeps do
  @moduledoc """
  Namespace for optional dependency gateway modules.

  Each submodule gates one optional dependency behind a `Code.ensure_loaded?/1`
  check and exposes `available?/0`. The `@compile {:no_warn_undefined, ...}`
  declaration in each gateway module (and the corresponding project-level
  `elixirc_options` list in `mix.exs`) suppresses compiler warnings when the
  dep is absent, so `mix compile --no-optional-deps --warnings-as-errors`
  stays green across the full matrix.

  ## Pattern (CORE-06)

  - **Compile-time:** `@compile {:no_warn_undefined, [Module.Name, ...]}` as
    the first declaration inside the gateway module, scoped to exactly the
    modules the gateway wraps.
  - **Runtime:** `available?/0` delegates to `Code.ensure_loaded?/1` so callers
    can branch between the real dep and a degraded fallback without compiling
    against the optional dep.

  ## Gateway Modules

  - `Mailglass.OptionalDeps.Oban` — gates `{:oban, "~> 2.21"}`. Fallback for
    `deliver_later/2` is `Task.Supervisor` (lands Phase 3).
  - `Mailglass.OptionalDeps.OpenTelemetry` — gates `{:opentelemetry, "~> 1.7"}`.
    Adopter-owned bridge via `opentelemetry_telemetry` (D-32).
  - `Mailglass.OptionalDeps.Mjml` — gates `{:mjml, "~> 5.3"}` (Rust NIF). Used
    by `Mailglass.TemplateEngine.MJML` when adopters opt into MJML (AUTHOR-05).
  - `Mailglass.OptionalDeps.GenSmtp` — gates `{:gen_smtp, "~> 1.3"}`. Used by
    `mailglass_inbound` for SMTP relay ingress (v0.5+).
  - `Mailglass.OptionalDeps.Sigra` — gates `{:sigra, "~> 0.2"}`. The module is
    **conditionally compiled**: it only exists when `:sigra` is loaded.
    Callers must guard via `Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra)`.

  ## Lint Enforcement

  Phase 6 ships a custom Credo check (`NoBareOptionalDepReference`) that flags
  any direct reference to the gated modules outside their corresponding
  gateway module. The gateway is the single authorized callsite.
  """
end
