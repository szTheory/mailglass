defmodule Mailglass.Clock do
  @moduledoc """
  The single legitimate source of wall-clock time in mailglass (TEST-05).
  Phase 6 `LINT-12 NoDirectDateTimeNow` forbids `DateTime.utc_now/0`
  outside this module.

  ## Three-tier resolution (D-07)

  1. If `Process.get(:mailglass_clock_frozen_at)` is a `%DateTime{}` → return it.
  2. Else if `Application.get_env(:mailglass, :clock)` is set → delegate to
     that impl's `utc_now/0`.
  3. Else delegate to `Mailglass.Clock.System.utc_now/0` (wraps `DateTime.utc_now/0`).

  Per-process isolation makes `async: true` tests safe — freezing the
  clock in one test does not affect sibling tests. Runtime (not
  compile-time) impl config so host apps don't recompile for test
  harnesses.
  """

  @process_key :mailglass_clock_frozen_at

  @doc "Returns the process-frozen time if set, else delegates to the configured impl."
  @doc since: "0.1.0"
  @spec utc_now() :: DateTime.t()
  def utc_now do
    case Process.get(@process_key) do
      nil -> impl().utc_now()
      %DateTime{} = frozen -> frozen
    end
  end

  defp impl do
    case Application.get_env(:mailglass, :clock) do
      nil -> Mailglass.Clock.System
      mod when is_atom(mod) -> mod
    end
  end
end
