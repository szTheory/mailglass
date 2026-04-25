defmodule Mailglass.Adapters.Fake do
  @moduledoc """
  In-memory, time-advanceable test adapter (TRANS-02, D-01..D-03).

  **The merge-blocking release gate (D-13).** Every PR runs the full
  pipeline against this adapter. Mirrors `Swoosh.Adapters.Sandbox`:
  ownership-by-pid, `$callers` inheritance, `allow/2` for
  cross-process delegation (LiveView, Playwright, Oban worker), shared
  mode for global tests.

  ## Stored record shape

      %{
        message: %Mailglass.Message{},
        delivery_id: Ecto.UUID.t(),
        provider_message_id: String.t(),
        recorded_at: DateTime.t()
      }

  Records `%Mailglass.Message{}` (NOT raw `%Swoosh.Email{}`) so
  `assert_mail_sent(mailable: UserMailer)` can recover the originating
  Mailable. Tenant stamped from the message at record time.

  `provider_message_id` lets `trigger_event/3` look up the Delivery row
  by id and simulate a Phase-4 webhook event via the REAL
  `Events.append_multi/3 + Projector.update_projections/2` write path
  (D-03). This keeps the Fake in sync with the production write path.

  ## Public API

  - `deliveries/0,1` — list recorded deliveries (optionally filtered)
  - `last_delivery/0,1` — most recent (by insertion order)
  - `clear/0,1` — wipe current owner's bucket (`:all` wipes every bucket)
  - `trigger_event/3` — simulate a webhook-shaped event
  - `advance_time/1` — delegates to `Mailglass.Clock.Frozen.advance/1`
  - Ownership: `checkout/0`, `checkin/0`, `allow/2`, `set_shared/1`

  ## Async: true safety

  Ownership keys every ETS bucket by owner pid; each test is its own
  owner (via `Mailglass.MailerCase` setup, Plan 06). Cross-process
  deliveries (LiveView, Task.Supervisor, Oban worker) resolve via
  `$callers` or explicit `allow/2`.
  """

  @behaviour Mailglass.Adapter

  alias Mailglass.Adapters.Fake.Storage
  alias Mailglass.Outbound.Projector

  @impl Mailglass.Adapter
  def deliver(%Mailglass.Message{} = msg, _opts) do
    case resolve_owner() do
      {:ok, owner} ->
        record = %{
          message: msg,
          delivery_id: msg_delivery_id(msg),
          provider_message_id: generate_provider_message_id(),
          recorded_at: Mailglass.Clock.utc_now()
        }

        :ok = Storage.push(owner, record)
        {:ok, %{message_id: record.provider_message_id, provider_response: %{adapter: :fake}}}

      :no_owner ->
        raise """
        [Mailglass.Adapters.Fake] No owner registered for process #{inspect(self())}.

        To fix:
          - In tests: call `Mailglass.Adapters.Fake.checkout()` in your setup
            (or use `Mailglass.MailerCase` which handles this automatically).
          - For LiveView / Task / Oban: call `Mailglass.Adapters.Fake.allow(owner_pid, self())`
            from the owner process before delivery.
          - For global mode: call `Mailglass.Adapters.Fake.set_shared(self())`.
        """
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Ownership API — defdelegate to Storage
  # ──────────────────────────────────────────────────────────────

  defdelegate checkout(), to: Storage
  defdelegate checkin(), to: Storage
  defdelegate allow(owner_pid, allowed_pid), to: Storage
  defdelegate set_shared(pid), to: Storage
  defdelegate get_shared(), to: Storage

  # ──────────────────────────────────────────────────────────────
  # Delivery inspection API
  # ──────────────────────────────────────────────────────────────

  @doc """
  Returns all recorded deliveries for the current owner (or a specified owner).

  ## Options

  - `:owner` — pid; defaults to `self()`
  - `:tenant` — filter by `record.message.tenant_id`
  - `:mailable` — filter by `record.message.mailable`
  - `:recipient` — filter by any address in `record.message.swoosh_email.to`
  """
  @spec deliveries(keyword()) :: [map()]
  def deliveries(opts \\ []) do
    owner = Keyword.get(opts, :owner, self())
    # Storage stores newest-first; reverse to return oldest-first (chronological)
    Storage.all(owner) |> Enum.reverse() |> filter_records(opts)
  end

  @doc "Returns the most recent delivery for the current owner, or `nil`."
  @spec last_delivery(keyword()) :: map() | nil
  def last_delivery(opts \\ []) do
    case deliveries(opts) do
      [] -> nil
      records -> List.last(records)
    end
  end

  @doc """
  Clears recorded deliveries.

  - `clear()` — clears the current owner's bucket.
  - `clear([owner: pid])` — clears the specified owner's bucket.
  - `clear(:all)` — clears every owner's bucket (flushes the entire ETS table).
  """
  @spec clear(keyword() | :all) :: :ok
  def clear(:all), do: Storage.flush()

  def clear(opts) when is_list(opts) do
    owner = Keyword.get(opts, :owner, self())
    Storage.clear(owner)
    :ok
  end

  def clear, do: clear([])

  # ──────────────────────────────────────────────────────────────
  # Simulation API
  # ──────────────────────────────────────────────────────────────

  @doc """
  Simulates a webhook-shaped event for a previously-delivered message (D-03).

  Looks up the `%Delivery{}` row by `provider_message_id`, builds an
  `%Events.Event{}`, and runs it through
  `Events.append_multi/3 + Projector.update_projections/2` inside
  `Repo.transact/1`. This is the SAME write path Phase 4 webhook ingest
  uses — the Fake proves the production write path.

  After the transaction commits, broadcasts via
  `Projector.broadcast_delivery_updated/3` (D-04).

  ## Opts

  - `:occurred_at` — DateTime; defaults to `Mailglass.Clock.utc_now()`
  - `:reject_reason` — atom from the reject_reason closed set
  - `:metadata` — map stored in `Event.metadata` (Phase 4: `raw_payload`
    moved to `mailglass_webhook_events`; see D-15)

  ## Returns

  - `{:ok, %Events.Event{}}` on success
  - `{:error, :not_found}` if `provider_message_id` has no matching Delivery
  - `{:error, term()}` for other failures
  """
  @doc since: "0.1.0"
  @spec trigger_event(String.t(), atom(), keyword()) ::
          {:ok, Mailglass.Events.Event.t()} | {:error, term()}
  def trigger_event(provider_message_id, type, opts \\ [])
      when is_binary(provider_message_id) and is_atom(type) do
    with {:ok, delivery} <- lookup_by_provider_message_id(provider_message_id) do
      attrs = build_event_attrs(delivery, type, opts)

      result =
        Ecto.Multi.new()
        |> Mailglass.Events.append_multi(:event, attrs)
        |> Ecto.Multi.update(:delivery, fn %{event: event} ->
          Projector.update_projections(delivery, event)
        end)
        |> Mailglass.Repo.multi()

      case result do
        {:ok, %{event: event, delivery: updated}} ->
          Projector.broadcast_delivery_updated(updated, type, %{
            tenant_id: updated.tenant_id,
            delivery_id: updated.id
          })

          {:ok, event}

        {:error, _step, err, _changes} ->
          {:error, err}
      end
    end
  end

  @doc "Advances the process-local frozen clock. Delegates to `Mailglass.Clock.Frozen.advance/1`."
  @doc since: "0.1.0"
  @spec advance_time(integer()) :: DateTime.t()
  def advance_time(ms) when is_integer(ms), do: Mailglass.Clock.Frozen.advance(ms)

  # ──────────────────────────────────────────────────────────────
  # Private helpers
  # ──────────────────────────────────────────────────────────────

  defp resolve_owner do
    callers = [self() | List.wrap(Process.get(:"$callers"))]

    case Storage.find_owner(callers) do
      {:ok, _owner} = ok ->
        ok

      :no_owner ->
        case Storage.get_shared() do
          nil -> :no_owner
          shared -> {:ok, shared}
        end
    end
  end

  defp generate_provider_message_id do
    "fake-" <> (:crypto.strong_rand_bytes(12) |> Base.url_encode64(padding: false))
  end

  defp msg_delivery_id(%Mailglass.Message{metadata: %{delivery_id: id}}) when is_binary(id), do: id
  defp msg_delivery_id(_), do: Ecto.UUID.generate()

  defp filter_records(records, opts) do
    records
    |> filter_by(:tenant, opts, fn r, v -> r.message.tenant_id == v end)
    |> filter_by(:mailable, opts, fn r, v -> r.message.mailable == v end)
    |> filter_by(:recipient, opts, fn r, v -> matches_recipient?(r.message.swoosh_email, v) end)
  end

  defp filter_by(records, key, opts, pred) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> Enum.filter(records, &pred.(&1, value))
      :error -> records
    end
  end

  defp matches_recipient?(%Swoosh.Email{to: to}, target) do
    Enum.any?(to, fn
      {_, addr} -> addr == target
      addr when is_binary(addr) -> addr == target
    end)
  end

  defp matches_recipient?(_, _), do: false

  defp lookup_by_provider_message_id(pmid) do
    import Ecto.Query

    q =
      from(d in Mailglass.Outbound.Delivery,
        where: d.provider_message_id == ^pmid,
        limit: 1
      )

    case Mailglass.Repo.one(Mailglass.Tenancy.scope(q)) do
      nil -> {:error, :not_found}
      %Mailglass.Outbound.Delivery{} = d -> {:ok, d}
    end
  end

  defp build_event_attrs(%Mailglass.Outbound.Delivery{} = delivery, type, opts) do
    %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: type,
      occurred_at: Keyword.get(opts, :occurred_at, Mailglass.Clock.utc_now()),
      idempotency_key: "fake:" <> delivery.id <> ":" <> Atom.to_string(type),
      # Phase 4 V02 migration drops `mailglass_events.raw_payload` — store
      # caller-supplied metadata in the `:metadata` column (same shape,
      # right semantic home). Raw provider evidence lives in
      # `mailglass_webhook_events` when a real webhook drives the event.
      metadata: Keyword.get(opts, :metadata, %{}),
      normalized_payload: %{
        reject_reason: Keyword.get(opts, :reject_reason)
      }
    }
  end
end
