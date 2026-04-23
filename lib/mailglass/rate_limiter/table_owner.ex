defmodule Mailglass.RateLimiter.TableOwner do
  @moduledoc """
  Init-and-idle GenServer owning the `:mailglass_rate_limit` ETS table
  (D-22). Owns nothing beyond ETS table creation — no `handle_call/3`,
  `handle_cast/2`, or `handle_info/2` implementations. Hot-path reads
  and writes happen directly from caller processes via
  `:ets.update_counter/4` — NO GenServer mailbox serialization.

  ## ETS opts (OTP 27+)

  - `:set` — single-entry-per-key bucket
  - `:public` — cross-process read/write without owner-forwarding
  - `:named_table` — caller references `:mailglass_rate_limit` directly
  - `read_concurrency: true` — hot read path optimization
  - `write_concurrency: :auto` — OTP 27 flag for lock striping
  - `decentralized_counters: true` — OTP 27 flag, per-scheduler counters

  ## Crash semantics (D-22)

  If this process crashes, BEAM deletes the ETS table. Supervisor
  restarts TableOwner; init/1 calls `:ets.new/2` anew. Counter state
  resets to empty — acceptable per D-22: "rate-limit state is not
  load-bearing across crashes." Worst case is 1 minute of burst
  allowance until refill restarts.

  ## LIB-05 note

  This module uses `name: __MODULE__`. It is library-internal
  machinery (not a user-facing singleton) and documented in
  `docs/api_stability.md` as a reserved singleton. Phase 6 `LINT-07
  NoDefaultModuleNameSingleton` has an allowlist entry for this
  module.
  """
  use GenServer

  @table :mailglass_rate_limit

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: :auto,
      decentralized_counters: true
    ])

    {:ok, %{}}
  end

  @doc "Returns the ETS table name. Public so tests can inspect state."
  @doc since: "0.1.0"
  @spec table() :: atom()
  def table, do: @table
end
