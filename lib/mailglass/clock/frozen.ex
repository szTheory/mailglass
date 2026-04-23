defmodule Mailglass.Clock.Frozen do
  @moduledoc """
  Test helper that freezes `Mailglass.Clock.utc_now/0` in the current
  process. Per-process isolation makes it `async: true`-safe.

  `Mailglass.Adapters.Fake.advance_time/1` delegates to `advance/1` — one
  mechanism, not two (D-03 + D-07).
  """

  @key :mailglass_clock_frozen_at

  @doc """
  Freezes the clock at the given `DateTime` in the current process.

  Returns the frozen `DateTime`. Subsequent calls to `Mailglass.Clock.utc_now/0`
  in this process return the frozen value until `unfreeze/0` is called.
  """
  @doc since: "0.1.0"
  @spec freeze(DateTime.t()) :: DateTime.t()
  def freeze(%DateTime{} = dt) do
    Process.put(@key, dt)
    dt
  end

  @doc """
  Advances the frozen clock by `ms` milliseconds in the current process.

  If no freeze is active, seeds from `DateTime.utc_now/0` then adds `ms`.
  Returns the new frozen `DateTime`.
  """
  @doc since: "0.1.0"
  @spec advance(integer()) :: DateTime.t()
  def advance(ms) when is_integer(ms) do
    current = Process.get(@key) || DateTime.utc_now()
    new = DateTime.add(current, ms, :millisecond)
    Process.put(@key, new)
    new
  end

  @doc """
  Clears the clock freeze in the current process.

  Returns `:ok`. Subsequent calls to `Mailglass.Clock.utc_now/0` delegate
  to the configured impl (or `Mailglass.Clock.System`).
  """
  @doc since: "0.1.0"
  @spec unfreeze() :: :ok
  def unfreeze do
    Process.delete(@key)
    :ok
  end
end
