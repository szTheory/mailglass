# Conditionally compiled — the entire `defmodule` is elided when `:sigra` is
# absent, so `Mailglass.OptionalDeps.Sigra` does not exist at all without the
# dep. Callers must guard via `Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra)`
# before referencing it. This mirrors the accrue pattern for Sigra integration.
if Code.ensure_loaded?(Sigra) do
  defmodule Mailglass.OptionalDeps.Sigra do
    @moduledoc """
    Gateway for the optional Sigra integration (`{:sigra, "~> 0.2"}`).

    Sigra provides distributed tracing primitives that mailglass hooks into
    for cross-boundary span propagation. When sigra is present, this module
    is compiled and `available?/0` returns `true`. When absent, the module
    does not exist at all.

    Unlike the other gateways (which always compile), the Sigra module is
    **conditionally compiled** because Sigra itself cannot be referenced at
    all — even in `no_warn_undefined` — in environments that use Sigra's own
    compile-time module discovery. Callers check existence via
    `Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra)`, not `available?/0`
    directly.
    """

    @compile {:no_warn_undefined, [Sigra]}

    @doc """
    Returns `true`. This module is only compiled when `:sigra` is loaded,
    so its mere existence implies availability.
    """
    @doc since: "0.1.0"
    @spec available?() :: boolean()
    def available?, do: true
  end
end
