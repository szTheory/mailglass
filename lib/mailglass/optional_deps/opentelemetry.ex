defmodule Mailglass.OptionalDeps.OpenTelemetry do
  @moduledoc """
  Gateway for the optional OpenTelemetry dependency (`{:opentelemetry, "~> 1.7"}`).

  OpenTelemetry integration is **adopter-owned** (D-32). The
  `opentelemetry_telemetry` bridge auto-connects any
  `[:mailglass, _, _, _, :start | :stop]` telemetry pair to OTel spans via
  the `:telemetry_span_context` metadata that `:telemetry.span/3` injects.
  Mailglass does **not** ship an `attach_otel/0` helper — that would duplicate
  a third-party contract and create cross-SDK maintenance burden.

  This gateway exists only for future internal gating (e.g. so Config can
  refuse conflicting OTel settings when the dep is absent).

  The erlang-atom modules `:otel_tracer` and `:otel_span` are the canonical
  ensure-loaded targets; `Code.ensure_loaded?/1` works equivalently for
  Elixir and Erlang module atoms.
  """

  @compile {:no_warn_undefined, [:otel_tracer, :otel_span]}

  @doc """
  Returns `true` when `:opentelemetry` (`:otel_tracer`) is loaded.

  Uses `:otel_tracer` as the probe because it is the stable API surface; the
  package name (`:opentelemetry`) does not expose a top-level module.
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(:otel_tracer)
end
