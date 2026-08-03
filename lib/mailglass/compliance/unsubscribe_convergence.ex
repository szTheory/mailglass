defmodule Mailglass.Compliance.UnsubscribeConvergence do
  @moduledoc false

  import Ecto.Query

  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo
  alias Mailglass.Suppression.Entry

  @suppression_conflict_target {
    :unsafe_fragment,
    "(tenant_id, address, scope, COALESCE(stream, ''))"
  }

  @spec run(Delivery.t()) ::
          {:ok, %{status: :created | :already_converged, event: Event.t(), suppression: Entry.t()}}
          | {:error, term()}
  def run(%Delivery{} = delivery) do
    delivery
    |> convergence_multi()
    |> Repo.multi()
    |> classify_result()
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
      {:ok, canonical_event(repo, changes.unsubscribe_event, delivery)}
    end)
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
      {:ok, canonical_suppression(repo, changes.unsubscribe_suppression, delivery)}
    end)
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
            canonical_suppression: suppression
          }}
       ) do
    status =
      if inserted_event.inserted_at || inserted_suppression.inserted_at,
        do: :created,
        else: :already_converged

    {:ok, %{status: status, event: event, suppression: suppression}}
  end

  defp classify_result({:error, step, reason, changes}), do: {:error, {step, reason, changes}}

  defp canonical_event(_repo, %Event{inserted_at: %DateTime{}} = event, _delivery), do: event

  defp canonical_event(repo, %Event{inserted_at: nil}, %Delivery{} = delivery) do
    query =
      from(event in Event,
        where:
          event.delivery_id == ^delivery.id and event.type == :unsubscribed and
            event.idempotency_key == ^unsubscribe_idempotency_key(delivery),
        limit: 1
      )

    repo.one!(query, Repo.multi_opts())
  end

  defp canonical_suppression(_repo, %Entry{inserted_at: %DateTime{}} = suppression, _delivery),
    do: suppression

  defp canonical_suppression(repo, %Entry{inserted_at: nil}, %Delivery{} = delivery) do
    query =
      from(suppression in Entry,
        where:
          suppression.tenant_id == ^delivery.tenant_id and
            suppression.address == ^String.downcase(delivery.recipient) and
            suppression.scope == :address_stream and suppression.stream == ^delivery.stream and
            suppression.reason == :unsubscribe,
        limit: 1
      )

    repo.one!(query, Repo.multi_opts())
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

  defp unsubscribe_idempotency_key(%Delivery{id: delivery_id}), do: "unsubscribe:#{delivery_id}"
end
