defmodule Mailglass.Webhook.Replay do
  @moduledoc """
  Canonical tenant-scoped webhook replay command.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Mailglass.{Clock, Events, IdempotencyKey, Repo, Tenancy}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.{Delivery, Projector}
  alias Mailglass.Webhook.WebhookEvent
  @auto_suppress_module Mailglass.Suppression.AutoSuppress

  @provider_modules %{
    postmark: Mailglass.Webhook.Providers.Postmark,
    sendgrid: Mailglass.Webhook.Providers.SendGrid,
    mailgun: Mailglass.Webhook.Providers.Mailgun,
    ses: Mailglass.Webhook.Providers.SES,
    resend: Mailglass.Webhook.Providers.Resend
  }

  @type actor :: %{required(:subject_id) => term(), optional(atom()) => term()}
  @type outcome_status :: :replayed | :noop

  @type success_result :: %{
          status: outcome_status(),
          tenant_id: String.t(),
          webhook_event_id: Ecto.UUID.t(),
          provider: atom(),
          delivery_id: Ecto.UUID.t() | nil,
          requested_audit_event_id: Ecto.UUID.t(),
          succeeded_audit_event_id: Ecto.UUID.t(),
          replayed_event_count: non_neg_integer(),
          new_event_count: non_neg_integer(),
          orphan_event_count: non_neg_integer()
        }

  @spec execute(map()) :: {:ok, success_result()} | {:error, term()}
  def execute(attrs) when is_map(attrs) do
    with {:ok, params} <- normalize_params(attrs),
         {:ok, webhook_event} <- fetch_target(params.tenant_id, params.webhook_event_id),
         {:ok, requested_audit} <- append_requested_audit(params, webhook_event) do
      with {:ok, raw_body} <- encode_raw_payload(webhook_event.raw_payload),
           {:ok, provider} <- provider_atom(webhook_event.provider),
           {:ok, normalized_events} <- normalize_events(provider, raw_body) do
        run_replay(params, webhook_event, provider, normalized_events, requested_audit)
      else
        {:error, reason} = err ->
          append_failed_audit(params, webhook_event, requested_audit.id, reason)
          err
      end
    else
      {:error, :webhook_event_not_found} = err ->
        err

      {:error, reason} = err ->
        maybe_append_failed_audit(attrs, reason)
        err
    end
  end

  defp run_replay(params, webhook_event, provider, normalized_events, requested_audit) do
    result =
      Repo.transact(fn ->
        _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
        _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

        multi =
          Multi.new()
          |> append_events_for_each(normalized_events, provider, webhook_event)
          |> update_projections_for_each(normalized_events, webhook_event.tenant_id)
          |> Multi.run(:outcome_summary, fn _repo, changes ->
            {:ok, summarize_replay(changes, normalized_events)}
          end)
          |> Events.append_multi(:replay_success_audit, fn changes ->
            outcome = Map.fetch!(changes, :outcome_summary)
            success_audit_attrs(params, webhook_event, requested_audit.id, outcome)
          end)

        case Repo.multi(multi) do
          {:ok, changes} ->
            {:ok, build_success_result(params, webhook_event, requested_audit, changes)}

          {:error, _step, reason, _changes} ->
            {:error, reason}
        end
      end)

    case result do
      {:ok, replay_result} ->
        {:ok, replay_result}

      {:error, reason} = err ->
        append_failed_audit(params, webhook_event, requested_audit.id, reason)
        err
    end
  end

  defp normalize_params(
         %{tenant_id: tenant_id, webhook_event_id: webhook_event_id, actor: actor} = attrs
       )
       when is_binary(tenant_id) and tenant_id != "" and is_binary(webhook_event_id) and
              webhook_event_id != "" and is_map(actor) do
    actor = normalize_actor(actor)

    case valid_subject_id(Map.get(actor, :subject_id)) do
      {:ok, subject_id} ->
        {:ok,
         %{
           tenant_id: tenant_id,
           webhook_event_id: webhook_event_id,
           actor: Map.put(actor, :subject_id, subject_id),
           delivery_id: Map.get(attrs, :delivery_id) || Map.get(attrs, "delivery_id")
         }}

      :error ->
        {:error, :invalid_params}
    end
  end

  defp normalize_params(_attrs), do: {:error, :invalid_params}

  defp normalize_actor(actor) do
    Map.new(actor, fn
      {"subject_id", value} -> {:subject_id, value}
      {"tenant_id", value} -> {:tenant_id, value}
      pair -> pair
    end)
  end

  defp valid_subject_id(value) when value in [nil, ""], do: :error

  defp valid_subject_id(value) do
    if String.Chars.impl_for(value) && to_string(value) != "" do
      {:ok, value}
    else
      :error
    end
  end

  defp fetch_target(tenant_id, webhook_event_id) do
    query =
      from(webhook_event in WebhookEvent,
        where: webhook_event.tenant_id == ^tenant_id and webhook_event.id == ^webhook_event_id,
        limit: 1
      )

    case Repo.one(Tenancy.scope(query, tenant_id)) do
      %WebhookEvent{} = webhook_event -> {:ok, webhook_event}
      nil -> {:error, :webhook_event_not_found}
    end
  end

  defp append_requested_audit(params, webhook_event) do
    Events.append(requested_audit_attrs(params, webhook_event))
  end

  defp append_failed_audit(params, webhook_event, requested_audit_event_id, reason) do
    _ =
      Events.append(
        failed_audit_attrs(
          params,
          webhook_event,
          requested_audit_event_id,
          classify_failure(reason)
        )
      )

    :ok
  end

  defp maybe_append_failed_audit(
         %{tenant_id: tenant_id, webhook_event_id: webhook_event_id, actor: actor} = attrs,
         reason
       )
       when is_binary(tenant_id) and is_binary(webhook_event_id) and is_map(actor) do
    with {:ok, params} <- normalize_params(attrs),
         {:ok, webhook_event} <- fetch_target(params.tenant_id, params.webhook_event_id) do
      append_failed_audit(params, webhook_event, nil, reason)
    end

    :ok
  end

  defp maybe_append_failed_audit(_attrs, _reason), do: :ok

  defp provider_atom(provider) when is_binary(provider) do
    case provider do
      "postmark" -> {:ok, :postmark}
      "sendgrid" -> {:ok, :sendgrid}
      "mailgun" -> {:ok, :mailgun}
      "ses" -> {:ok, :ses}
      "resend" -> {:ok, :resend}
      _ -> {:error, :unknown_provider}
    end
  end

  defp normalize_events(provider, raw_body) do
    module = Map.fetch!(@provider_modules, provider)

    {:ok, module.normalize(raw_body, [])}
  rescue
    _error -> {:error, :normalize_failed}
  end

  defp encode_raw_payload(%{"_raw" => raw}) when is_binary(raw), do: {:ok, raw}
  defp encode_raw_payload(%{"_batch" => batch}) when is_list(batch), do: Jason.encode(batch)
  defp encode_raw_payload(payload) when is_map(payload), do: Jason.encode(payload)
  defp encode_raw_payload(_payload), do: {:error, :invalid_raw_payload}

  defp requested_audit_attrs(params, webhook_event) do
    %{
      tenant_id: params.tenant_id,
      delivery_id: params.delivery_id,
      type: :webhook_replay_requested,
      occurred_at: Clock.utc_now(),
      metadata: audit_metadata(params, webhook_event, %{})
    }
  end

  defp success_audit_attrs(params, webhook_event, requested_audit_event_id, outcome) do
    %{
      tenant_id: params.tenant_id,
      delivery_id: params.delivery_id,
      type: :webhook_replay_succeeded,
      occurred_at: Clock.utc_now(),
      metadata:
        audit_metadata(params, webhook_event, %{
          "requested_audit_event_id" => requested_audit_event_id,
          "outcome" => Atom.to_string(outcome.status),
          "replayed_event_count" => outcome.replayed_event_count,
          "new_event_count" => outcome.new_event_count,
          "orphan_event_count" => outcome.orphan_event_count
        })
    }
  end

  defp failed_audit_attrs(params, webhook_event, requested_audit_event_id, failure_reason) do
    metadata =
      %{
        "outcome" => "failed",
        "failure_reason" => Atom.to_string(failure_reason)
      }
      |> maybe_put("requested_audit_event_id", requested_audit_event_id)

    %{
      tenant_id: params.tenant_id,
      delivery_id: params.delivery_id,
      type: :webhook_replay_failed,
      occurred_at: Clock.utc_now(),
      metadata: audit_metadata(params, webhook_event, metadata)
    }
  end

  defp audit_metadata(params, webhook_event, extra) do
    %{
      "actor_id" => to_string(params.actor.subject_id),
      "tenant_id" => params.tenant_id,
      "webhook_event_id" => webhook_event.id,
      "webhook_provider_event_id" => webhook_event.provider_event_id,
      "provider" => webhook_event.provider
    }
    |> maybe_put("delivery_id", params.delivery_id)
    |> maybe_put("actor_tenant_id", params.actor[:tenant_id])
    |> Map.merge(extra)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp append_events_for_each(multi, events, provider, webhook_event) do
    events
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {event, idx}, acc ->
      delivery_id = resolve_delivery_id(provider, event, webhook_event.tenant_id)

      Events.append_multi(acc, event_step_name(idx), %{
        type: event.type,
        tenant_id: webhook_event.tenant_id,
        delivery_id: delivery_id,
        needs_reconciliation: is_nil(delivery_id),
        idempotency_key:
          IdempotencyKey.for_webhook_event(provider, extract_event_provider_id(event), idx),
        metadata: replay_metadata(event.metadata || %{}, webhook_event),
        reject_reason: event.reject_reason,
        occurred_at: Clock.utc_now()
      })
    end)
  end

  defp update_projections_for_each(multi, events, tenant_id) do
    events
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {_event, idx}, acc ->
      acc
      |> Multi.run({:projector_categorize, idx}, fn _repo, changes ->
        inserted_event = Map.get(changes, event_step_name(idx))

        cond do
          is_nil(inserted_event) ->
            {:ok, :no_event_row}

          is_nil(inserted_event.delivery_id) ->
            {:ok, :orphan_skipped}

          true ->
            delivery_query =
              from(delivery in Delivery,
                where: delivery.id == ^inserted_event.delivery_id,
                limit: 1
              )

            case Repo.one(Tenancy.scope(delivery_query, tenant_id)) do
              nil -> {:ok, :orphan_skipped}
              %Delivery{} = delivery -> {:ok, {:matched, delivery, inserted_event}}
            end
        end
      end)
      |> Multi.run({:projector_apply, idx}, fn repo, changes ->
        case Map.get(changes, {:projector_categorize, idx}) do
          {:matched, delivery, inserted_event} ->
            changeset = Projector.update_projections(delivery, inserted_event)

            case repo.update(changeset, Repo.multi_opts()) do
              {:ok, _delivery} -> {:ok, {:matched, delivery, inserted_event}}
              {:error, reason} -> {:error, reason}
            end

          other ->
            {:ok, other}
        end
      end)
      |> Multi.run({:auto_suppress, idx}, fn repo, changes ->
        apply(@auto_suppress_module, :apply, [repo, Map.get(changes, {:projector_apply, idx})])
      end)
    end)
  end

  defp summarize_replay(changes, events) do
    event_rows =
      events
      |> Enum.with_index()
      |> Enum.map(fn {_event, idx} -> Map.get(changes, event_step_name(idx)) end)
      |> Enum.reject(&is_nil/1)

    new_event_count = Enum.count(event_rows, &match?(%Event{inserted_at: %DateTime{}}, &1))
    orphan_event_count = Enum.count(event_rows, &is_nil(&1.delivery_id))

    %{
      status: if(new_event_count == 0, do: :noop, else: :replayed),
      replayed_event_count: length(events),
      new_event_count: new_event_count,
      orphan_event_count: orphan_event_count
    }
  end

  defp build_success_result(params, webhook_event, requested_audit, changes) do
    outcome = Map.fetch!(changes, :outcome_summary)
    succeeded_audit = Map.fetch!(changes, :replay_success_audit)

    %{
      status: outcome.status,
      tenant_id: params.tenant_id,
      webhook_event_id: webhook_event.id,
      provider: String.to_atom(webhook_event.provider),
      delivery_id: params.delivery_id,
      requested_audit_event_id: requested_audit.id,
      succeeded_audit_event_id: succeeded_audit.id,
      replayed_event_count: outcome.replayed_event_count,
      new_event_count: outcome.new_event_count,
      orphan_event_count: outcome.orphan_event_count
    }
  end

  defp classify_failure(reason) when reason in [:normalize_failed, :invalid_raw_payload], do: reason
  defp classify_failure(:webhook_event_not_found), do: :webhook_event_not_found
  defp classify_failure(_reason), do: :replay_failed

  defp event_step_name(idx) when is_integer(idx) and idx >= 0, do: :"event_#{idx}"

  defp extract_event_provider_id(%Event{metadata: meta}) when is_map(meta) do
    meta["provider_event_id"] || Map.get(meta, :provider_event_id)
  end

  defp extract_event_provider_id(_event), do: nil

  defp replay_metadata(metadata, %WebhookEvent{} = webhook_event) when is_map(metadata) do
    metadata
    |> Map.put("webhook_event_id", webhook_event.id)
    |> maybe_put("webhook_provider_event_id", webhook_event.provider_event_id)
  end

  defp resolve_delivery_id(provider, %Event{metadata: meta}, tenant_id) when is_map(meta) do
    message_id =
      meta["sg_message_id"] || meta["message_id"] ||
        Map.get(meta, :sg_message_id) || Map.get(meta, :message_id)

    case message_id do
      id when is_binary(id) and id != "" ->
        query =
          from(delivery in Delivery,
            where:
              delivery.provider == ^Atom.to_string(provider) and delivery.provider_message_id == ^id,
            select: delivery.id,
            limit: 1
          )

        Repo.one(Tenancy.scope(query, tenant_id))

      _ ->
        nil
    end
  end

  defp resolve_delivery_id(_provider, _event, _tenant_id), do: nil
end
