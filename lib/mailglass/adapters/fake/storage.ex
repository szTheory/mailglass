defmodule Mailglass.Adapters.Fake.Storage do
  @moduledoc """
  GenServer owning the `:mailglass_fake_mailbox` ETS table. Mirrors
  `Swoosh.Adapters.Sandbox.Storage` pattern: the GenServer handles ownership
  mutations (`checkout`, `checkin`, `allow`, `set_shared`, `find_owner`,
  `{:DOWN, ...}`) but READS happen directly against ETS to bypass the mailbox.

  ## State

  - `:owners` — MapSet of currently-checked-out owner pids.
  - `:allowed` — map `allowed_pid => owner_pid` for allow-list delegation
    (LiveView, Playwright, Oban worker processes).
  - `:shared` — single owner pid for global-mode tests (set via `set_shared/1`).
  - `:monitors` — map `monitor_ref => pid` for auto-cleanup on DOWN.

  ## ETS table

  `:mailglass_fake_mailbox` — `[:set, :named_table, :public, {:read_concurrency, true}]`.
  Keys: owner pid. Values: list of records (prepended on each push, so newest is head).

  ## Divergences from `Swoosh.Adapters.Sandbox.Storage`

  1. Table name: `:mailglass_fake_mailbox` (not `:swoosh_sandbox_emails`).
  2. Stored value: `%{message: %Mailglass.Message{}, delivery_id: binary(),
     provider_message_id: binary(), recorded_at: DateTime.t()}` — not a bare email.
  3. `send(owner_pid, {:mail, msg})` — not `{:email, email}`.
  4. `push/2` accepts `owner_pid + record_map`; stores full record in ETS.
  """

  use GenServer

  @table :mailglass_fake_mailbox

  # ──────────────────────────────────────────────────────────────
  # Public API — mirrors Swoosh.Sandbox.Storage surface.
  # ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def checkout, do: GenServer.call(__MODULE__, {:checkout, self()})
  def checkin, do: GenServer.call(__MODULE__, {:checkin, self()})
  def allow(owner_pid, allowed_pid), do: GenServer.call(__MODULE__, {:allow, owner_pid, allowed_pid})
  def set_shared(pid), do: GenServer.call(__MODULE__, {:set_shared, pid})
  def get_shared, do: GenServer.call(__MODULE__, :get_shared)
  def find_owner(callers), do: GenServer.call(__MODULE__, {:find_owner, callers})
  def push(owner_pid, record), do: GenServer.call(__MODULE__, {:push, owner_pid, record})

  @doc "Removes all entries from the ETS table (used by `Fake.clear(:all)`)."
  def flush, do: GenServer.call(__MODULE__, :flush)

  # Direct ETS reads — bypass the mailbox for hot paths (no serialization).

  @doc "Returns all records for the given owner pid. Newest first."
  def all(owner_pid) do
    case :ets.lookup(@table, owner_pid) do
      [{^owner_pid, records}] -> records
      [] -> []
    end
  end

  @doc "Removes the ETS entry for the given owner pid."
  def clear(owner_pid) do
    :ets.delete(@table, owner_pid)
    :ok
  end

  # ──────────────────────────────────────────────────────────────
  # GenServer callbacks
  # ──────────────────────────────────────────────────────────────

  @impl GenServer
  def init(_opts) do
    :ets.new(@table, [:set, :named_table, :public, {:read_concurrency, true}])
    {:ok, %{owners: MapSet.new(), allowed: %{}, shared: nil, monitors: %{}}}
  end

  @impl GenServer
  def handle_call({:checkout, pid}, _from, state) do
    if MapSet.member?(state.owners, pid) do
      # Already checked out — idempotent, return :ok
      {:reply, :ok, state}
    else
      ref = Process.monitor(pid)
      :ets.insert(@table, {pid, []})

      new_state = %{
        state
        | owners: MapSet.put(state.owners, pid),
          monitors: Map.put(state.monitors, ref, pid)
      }

      {:reply, :ok, new_state}
    end
  end

  def handle_call({:checkin, pid}, _from, state) do
    {:reply, :ok, do_checkin(pid, state)}
  end

  def handle_call({:allow, owner_pid, allowed_pid}, _from, state) do
    ref = Process.monitor(allowed_pid)

    new_state = %{
      state
      | allowed: Map.put(state.allowed, allowed_pid, owner_pid),
        monitors: Map.put(state.monitors, ref, allowed_pid)
    }

    {:reply, :ok, new_state}
  end

  def handle_call({:set_shared, pid}, _from, state), do: {:reply, :ok, %{state | shared: pid}}
  def handle_call(:get_shared, _from, state), do: {:reply, state.shared, state}

  def handle_call({:find_owner, callers}, _from, state) do
    result =
      Enum.find_value(callers, fn pid ->
        cond do
          MapSet.member?(state.owners, pid) -> {:ok, pid}
          owner = Map.get(state.allowed, pid) -> {:ok, owner}
          true -> nil
        end
      end)

    {:reply, result || :no_owner, state}
  end

  def handle_call({:push, owner_pid, record}, _from, state) do
    existing =
      case :ets.lookup(@table, owner_pid) do
        [{^owner_pid, records}] -> records
        [] -> []
      end

    :ets.insert(@table, {owner_pid, [record | existing]})
    # Notify owner: {:mail, msg} — not {:email, email} (divergence #3)
    send(owner_pid, {:mail, record.message})
    {:reply, :ok, state}
  end

  def handle_call(:flush, _from, state) do
    :ets.delete_all_objects(@table)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    if Map.has_key?(state.monitors, ref) do
      {:noreply, do_checkin(pid, state)}
    else
      {:noreply, state}
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Private helpers
  # ──────────────────────────────────────────────────────────────

  defp do_checkin(pid, state) do
    :ets.delete(@table, pid)

    {to_demonitor, monitors} =
      Enum.split_with(state.monitors, fn {_ref, p} -> p == pid end)

    Enum.each(to_demonitor, fn {ref, _} -> Process.demonitor(ref, [:flush]) end)

    allowed =
      state.allowed
      |> Enum.reject(fn {allowed_pid, owner_pid} ->
        owner_pid == pid or allowed_pid == pid
      end)
      |> Map.new()

    shared = if state.shared == pid, do: nil, else: state.shared

    %{
      state
      | owners: MapSet.delete(state.owners, pid),
        monitors: Map.new(monitors),
        allowed: allowed,
        shared: shared
    }
  end
end
