defmodule Mailglass.Compliance.UnsubscribeConvergence do
  @moduledoc false

  import Ecto.Query

  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo
  alias Mailglass.Suppression.Entry
  alias Postgrex.Error, as: PostgrexError

  @suppression_conflict_target {
    :unsafe_fragment,
    "(tenant_id, address, scope, COALESCE(stream, ''))"
  }

  @suppression_returning_fields [
    :id,
    :tenant_id,
    :scope,
    :stream,
    :reason,
    :source,
    :expires_at,
    :metadata,
    :inserted_at
  ]

  @spec run(Delivery.t()) ::
          {:ok, %{status: :created | :already_converged, event: Event.t(), suppression: Entry.t()}}
          | {:error, term()}
  def run(%Delivery{} = delivery) do
    with_stale_type_retry(fn ->
      delivery
      |> convergence_multi()
      |> Repo.multi()
      |> classify_result()
    end)
  end

  defp convergence_multi(%Delivery{} = delivery) do
    event_attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :unsubscribed,
      idempotency_key: unsubscribe_idempotency_key(delivery),
      normalized_payload: %{source: :unsubscribe}
    }

    Ecto.Multi.new()
    |> Events.append_multi(:unsubscribe_event, event_attrs)
    |> Ecto.Multi.run(:canonical_event, fn repo, changes ->
      canonical_event(repo, changes.unsubscribe_event, delivery)
    end)
    |> maybe_inject_failure(:after_event)
    |> Ecto.Multi.run(:unsubscribe_suppression, fn repo, changes ->
      changes.canonical_event
      |> suppression_attrs(delivery)
      |> Entry.changeset()
      |> repo.insert(
        Repo.multi_opts(
          on_conflict: :nothing,
          conflict_target: @suppression_conflict_target,
          returning: true
        )
      )
    end)
    |> Ecto.Multi.run(:canonical_suppression, fn repo, changes ->
      with {:ok, suppression} <-
             canonical_suppression(repo, changes.unsubscribe_suppression, delivery) do
        ensure_permanent_unsubscribe(repo, suppression, delivery)
      end
    end)
    |> maybe_inject_failure(:after_suppression)
  end

  # `inserted_at` is the adapter-pinned DO NOTHING sentinel for both event and
  # suppression rows: their UUIDs are generated client-side, while this
  # DB-defaulted/read-after-write field stays nil when PostgreSQL returns no row.
  defp classify_result(
         {:ok,
          %{
            unsubscribe_event: inserted_event,
            canonical_event: event,
            unsubscribe_suppression: inserted_suppression,
            canonical_suppression: %{suppression: suppression, promoted?: promoted?}
          }}
       ) do
    status =
      if inserted_event.inserted_at || inserted_suppression.inserted_at || promoted?,
        do: :created,
        else: :already_converged

    {:ok, %{status: status, event: event, suppression: suppression}}
  end

  defp classify_result({:error, step, reason, changes}), do: {:error, {step, reason, changes}}

  defp canonical_event(_repo, %Event{inserted_at: %DateTime{}} = event, _delivery), do: {:ok, event}

  defp canonical_event(repo, %Event{inserted_at: nil}, %Delivery{} = delivery) do
    maybe_raise_refetch_failure!()

    query =
      from(event in Event,
        where:
          event.delivery_id == ^delivery.id and event.type == :unsubscribed and
            event.idempotency_key == ^unsubscribe_idempotency_key(delivery),
        limit: 1
      )

    case repo.one(query, Repo.multi_opts()) do
      %Event{} = event -> {:ok, event}
      nil -> {:error, :canonical_event_missing}
    end
  end

  defp canonical_suppression(_repo, %Entry{inserted_at: %DateTime{}} = suppression, _delivery),
    do: {:ok, suppression}

  defp canonical_suppression(repo, %Entry{inserted_at: nil}, %Delivery{} = delivery) do
    address = String.downcase(delivery.recipient)

    query =
      from(suppression in Entry,
        where:
          suppression.tenant_id == ^delivery.tenant_id and
            fragment("?::text", suppression.address) == ^address and
            suppression.scope == :address_stream and suppression.stream == ^delivery.stream,
        limit: 1,
        select: %{
          id: suppression.id,
          tenant_id: suppression.tenant_id,
          scope: suppression.scope,
          stream: suppression.stream,
          reason: suppression.reason,
          source: suppression.source,
          expires_at: suppression.expires_at,
          metadata: suppression.metadata,
          inserted_at: suppression.inserted_at
        }
      )

    case repo.one(query, Repo.multi_opts()) do
      suppression when is_map(suppression) ->
        {:ok, struct(Entry, Map.put(suppression, :address, address))}

      nil ->
        {:error, :canonical_suppression_missing}
    end
  end

  # An existing permanent suppression is already an effective opt-out and is
  # deliberately preserved.  A same-identity temporary row, however, would
  # let a valid one-click POST silently expire. Promote only that row in the
  # enclosing transaction so the event and its permanent enforcement fact are
  # still all-or-nothing. Complaint rows are permanent by schema invariant;
  # existing permanent unsubscribe rows are never rewritten.
  defp ensure_permanent_unsubscribe(_repo, %Entry{expires_at: nil} = suppression, _delivery),
    do: {:ok, %{suppression: suppression, promoted?: false}}

  defp ensure_permanent_unsubscribe(repo, %Entry{} = suppression, %Delivery{} = delivery) do
    address = String.downcase(delivery.recipient)

    promotion_query =
      from(entry in Entry,
        where:
          entry.id == ^suppression.id and entry.tenant_id == ^delivery.tenant_id and
            fragment("?::text", entry.address) == ^address and
            entry.scope == :address_stream and entry.stream == ^delivery.stream and
            not is_nil(entry.expires_at),
        select: entry
      )

    case repo.update_all(
           promotion_query,
           [set: [reason: :unsubscribe, expires_at: nil]],
           Repo.multi_opts(returning: @suppression_returning_fields)
         ) do
      {1, [%Entry{} = promoted]} ->
        {:ok, %{suppression: %{promoted | address: address}, promoted?: true}}

      {0, _} ->
        # PostgreSQL rechecks the predicate after a concurrent updater commits.
        # The losing transaction sees the permanent winner on this refetch.
        case canonical_suppression(repo, %Entry{inserted_at: nil}, delivery) do
          {:ok, %Entry{expires_at: nil} = canonical} ->
            {:ok, %{suppression: canonical, promoted?: false}}

          {:ok, _temporary} ->
            {:error, :canonical_suppression_not_permanent}

          error ->
            error
        end
    end
  end

  defp suppression_attrs(%Event{} = event, %Delivery{} = delivery) do
    %{
      tenant_id: delivery.tenant_id,
      address: delivery.recipient,
      scope: :address_stream,
      stream: delivery.stream,
      reason: :unsubscribe,
      source: "compliance:one_click",
      metadata: %{
        "delivery_id" => delivery.id,
        "event_id" => event.id,
        "event_type" => "unsubscribed"
      }
    }
  end

  # Test-only, process-local failure seam. This is compiled out of production:
  # no request can be changed by mutable application configuration at runtime.
  if Mix.env() == :test do
    defp maybe_inject_failure(multi, step) do
      Ecto.Multi.run(multi, {:failure_injection, step}, fn _repo, _changes ->
        case Process.get(:mailglass_unsubscribe_convergence_failure) do
          ^step -> {:error, :injected_convergence_failure}
          %{^step => {:raise, exception}} -> raise exception
          %{^step => {:exit, reason}} -> exit(reason)
          _ -> {:ok, :not_injected}
        end
      end)
    end
  else
    defp maybe_inject_failure(multi, _step), do: multi
  end

  if Mix.env() == :test do
    defp maybe_raise_refetch_failure! do
      case Process.get(:mailglass_unsubscribe_convergence_failure) do
        %{canonical_event_refetch: {:raise, exception}} -> raise exception
        _ -> :ok
      end
    end
  else
    defp maybe_raise_refetch_failure!, do: :ok
  end

  # Migration round-trips can replace PostgreSQL's citext OID while a pooled
  # connection still holds the old type metadata. The failed transaction is
  # rolled back before Postgrex disconnects that connection, so replaying the
  # complete idempotent convergence on a fresh checkout is safe. This mirrors
  # the suppression store's bounded stale-type recovery.
  @stale_type_retry_attempts 8

  defp with_stale_type_retry(fun, attempts_left \\ @stale_type_retry_attempts)
       when is_function(fun, 0) and is_integer(attempts_left) do
    fun.()
  rescue
    error in PostgrexError ->
      if stale_type_cache_error?(error) and attempts_left > 1 do
        with_stale_type_retry(fun, attempts_left - 1)
      else
        reraise error, __STACKTRACE__
      end
  end

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: :internal_error}}), do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: code}}) when code == "XX000",
    do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: :feature_not_supported}}),
    do: true

  defp stale_type_cache_error?(%PostgrexError{postgres: %{code: code}}) when code == "0A000",
    do: true

  defp stale_type_cache_error?(_), do: false

  defp unsubscribe_idempotency_key(%Delivery{id: delivery_id}), do: "unsubscribe:#{delivery_id}"
end
