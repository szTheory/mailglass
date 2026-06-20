defmodule MailglassInbound.RateLimiter.TableOwner do
  @moduledoc """
  Init-and-idle GenServer owning the `:mailglass_inbound_rate_limit` ETS table
  (cloned from `Mailglass.RateLimiter.TableOwner`, the design contract crash semantics). Owns
  nothing beyond ETS table creation — no `handle_call/3`, `handle_cast/2`, or
  `handle_info/2`. Hot-path reads/writes happen directly from caller processes
  via `:ets.update_counter/4` — NO GenServer mailbox serialization.

  ## ETS opts (OTP 27+) — copied verbatim from core

  - `:set` — single-entry-per-key bucket
  - `:public` — cross-process read/write without owner-forwarding
  - `:named_table` — caller references `:mailglass_inbound_rate_limit` directly
  - `read_concurrency: true` — hot read path optimization
  - `write_concurrency: :auto` — OTP 27 flag for lock striping
  - `decentralized_counters: true` — OTP 27 flag, per-scheduler counters

  ## Crash semantics (the design contract)

  If this process crashes, BEAM deletes the ETS table. Supervisor restarts
  TableOwner; `init/1` calls `:ets.new/2` anew. Counter state resets to empty —
  acceptable per the design contract: "rate-limit state is not load-bearing across crashes."
  Worst case is 1 minute of burst allowance until refill restarts.

  ## Reserved-singleton note

  This module uses `name: __MODULE__`. It is library-internal machinery (not a
  user-facing singleton) and is the documented reserved-singleton
  exception, mirroring `Mailglass.RateLimiter.TableOwner`. The inbound ETS table
  must be a process-stable named table so the limiter hot path can reach it
  without a registry lookup.
  """
  use GenServer

  @table :mailglass_inbound_rate_limit

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    {name, _init_opts} = Keyword.pop(opts, :name, __MODULE__)
    start_opts = if is_nil(name), do: [], else: [name: name]
    GenServer.start_link(__MODULE__, :ok, start_opts)
  end

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
  @doc since: "1.2.0"
  def table, do: @table
end
