defmodule Mailglass.Events.Reconciler do
  @moduledoc """
  Pure Ecto query functions for orphan-webhook reconciliation (D-19).

  Phase 2 scope: query functions only. Phase 4 wraps these in
  `Mailglass.Oban.Reconciler` at `{:cron, "*/15 * * * *"}` cadence
  (D-20). Phase 2 has no Oban dep.

  ## What "orphan" means

  A webhook event arrives for a `provider_message_id` before the
  delivery row has committed its `provider_message_id` field
  (empirical: SendGrid + Postmark p99 webhook latency is 5-30s;
  dispatch commits are ms-scale but the window is real). Phase 4's
  webhook plug inserts the event with `delivery_id = nil` and
  `needs_reconciliation = true` rather than failing.

  ## Reconciliation semantics (research §6.1 note)

  `needs_reconciliation` lives on the event row, not the delivery,
  and the immutability trigger prevents UPDATE on events. The Phase 4
  worker's exact mechanic (emit a `:reconciled` event + update
  delivery projection vs. only update projection) is Phase 4's call.
  Phase 2 exposes the primitives either approach needs:

  - `find_orphans/1` — query events awaiting reconciliation
  - `attempt_link/2` — look up the matching delivery (by `provider`
    + `provider_message_id` in raw_payload / metadata)
  """

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery

  import Ecto.Query

  # Default retention window: 7 days. Orphans older than this are
  # considered dead (admin dashboard surfaces via telemetry).
  @default_max_age_minutes 7 * 24 * 60

  @doc """
  Returns events awaiting reconciliation (delivery_id is NULL +
  needs_reconciliation = true), ordered oldest first.

  ## Options

  - `:tenant_id` — scope to a specific tenant. Default: all tenants.
  - `:limit` — max rows returned. Default: 100.
  - `:max_age_minutes` — ignore orphans older than this (integer).
    Default: 10_080 (7 days).

  Uses the partial index `mailglass_events_needs_reconcile_idx`
  (Plan 02) for efficient scans.
  """
  @doc since: "0.1.0"
  @spec find_orphans(keyword()) :: [Event.t()]
  def find_orphans(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id)
    limit = Keyword.get(opts, :limit, 100)
    max_age_minutes = Keyword.get(opts, :max_age_minutes, @default_max_age_minutes)

    cutoff = DateTime.add(DateTime.utc_now(), -max_age_minutes * 60, :second)

    query =
      from(e in Event,
        where: e.needs_reconciliation == true and is_nil(e.delivery_id),
        where: e.inserted_at >= ^cutoff,
        order_by: [asc: e.inserted_at],
        limit: ^limit
      )

    query =
      case tenant_id do
        nil -> query
        tid when is_binary(tid) -> where(query, [e], e.tenant_id == ^tid)
      end

    Mailglass.Repo.all(query)
  end

  @doc """
  Attempts to locate the matching `%Delivery{}` for an orphan event
  via `(provider, provider_message_id)`. The provider + message id are
  extracted from the event's `raw_payload` or `metadata` (Phase 4
  webhook handler populates both conventions; Phase 2 supports either).

  Returns `{:ok, {delivery, event}}` when matched;
  `{:error, :delivery_not_found}` when no delivery with the
  (provider, provider_message_id) pair exists.

  Pure query — does NOT mutate anything. Phase 4's Oban worker
  decides whether to emit a `:reconciled` event and/or update the
  delivery projection after this returns success.

  Emits `[:mailglass, :persist, :reconcile, :link, :*]` with
  `tenant_id` metadata (PII-free per D-31 whitelist).
  """
  @doc since: "0.1.0"
  @spec attempt_link(Event.t()) ::
          {:ok, {Delivery.t(), Event.t()}}
          | {:error, :delivery_not_found | :malformed_payload}
  def attempt_link(%Event{} = event) do
    Mailglass.Telemetry.persist_span(
      [:reconcile, :link],
      %{tenant_id: event.tenant_id},
      fn ->
        provider = extract(event, "provider")
        provider_message_id = extract(event, "provider_message_id")

        cond do
          is_nil(provider) or is_nil(provider_message_id) ->
            {:error, :malformed_payload}

          true ->
            query =
              from(d in Delivery,
                where: d.provider == ^provider and d.provider_message_id == ^provider_message_id,
                limit: 1
              )

            case Mailglass.Repo.one(query) do
              nil -> {:error, :delivery_not_found}
              %Delivery{} = delivery -> {:ok, {delivery, event}}
            end
        end
      end
    )
  end

  defp extract(%Event{raw_payload: rp, metadata: md}, key) when is_binary(key) do
    extract_from(rp, key) || extract_from(md, key)
  end

  defp extract_from(nil, _key), do: nil
  defp extract_from(map, key) when is_map(map), do: Map.get(map, key)
end
