defmodule Mailglass.Outbound.Persistence do
  @moduledoc false

  alias Mailglass.{Clock, Events, Message, Repo, Telemetry}
  alias Mailglass.Outbound.{Delivery, Preflight, Projector}

  def persist_queued(%Message{} = rendered, adapter_ref) do
    idempotency_key = idempotency_key(rendered)
    tenant_id = rendered.tenant_id

    Telemetry.persist_outbound_multi_span(
      %{step_name: :persist_queued, tenant_id: tenant_id},
      fn ->
        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            :delivery,
            Delivery.changeset(%Delivery{id: Preflight.delivery_id!(rendered)}, %{
              tenant_id: tenant_id,
              mailable: inspect(rendered.mailable),
              stream: rendered.stream,
              recipient: Preflight.primary_recipient(rendered),
              recipient_domain: recipient_domain(rendered),
              adapter_ref: adapter_ref,
              status: :queued,
              last_event_type: :queued,
              last_event_at: Clock.utc_now(),
              metadata: rendered.metadata || %{},
              idempotency_key: idempotency_key
            }),
            Repo.multi_opts()
          )
          |> Events.append_multi(:event_queued, fn %{delivery: delivery} ->
            %{
              tenant_id: tenant_id,
              delivery_id: delivery.id,
              type: :queued,
              occurred_at: Clock.utc_now(),
              idempotency_key: idempotency_key,
              normalized_payload: %{}
            }
          end)
        )
      end
    )
  end

  def persist_dispatched(
        %Delivery{} = delivery,
        %{message_id: provider_message_id, provider_response: _response},
        %Message{}
      ) do
    event_occurred_at = Clock.utc_now()

    event_attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at,
      normalized_payload: %{provider_message_id: provider_message_id}
    }

    event_for_projection = %Events.Event{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :dispatched,
      occurred_at: event_occurred_at
    }

    Telemetry.persist_outbound_multi_span(
      %{step_name: :persist_dispatched, tenant_id: delivery.tenant_id},
      fn ->
        Repo.multi(
          Ecto.Multi.new()
          |> Ecto.Multi.update(
            :delivery,
            Projector.update_projections(delivery, event_for_projection)
            |> Ecto.Changeset.change(%{
              status: :sent,
              last_event_type: :dispatched,
              provider_message_id: provider_message_id,
              dispatched_at: event_occurred_at
            }),
            Repo.multi_opts()
          )
          |> Events.append_multi(:event_dispatched, event_attrs)
        )
      end
    )
  end

  def base_delivery_attrs(%Message{} = rendered, idempotency_key, adapter_ref) do
    %{
      tenant_id: rendered.tenant_id,
      mailable: inspect(rendered.mailable),
      stream: rendered.stream,
      recipient: Preflight.primary_recipient(rendered),
      recipient_domain: recipient_domain(rendered),
      adapter_ref: adapter_ref,
      status: :queued,
      last_event_type: :queued,
      last_event_at: Clock.utc_now(),
      metadata:
        Map.merge(rendered.metadata || %{}, %{
          rendered_html: rendered.swoosh_email.html_body,
          rendered_text: rendered.swoosh_email.text_body,
          subject: rendered.swoosh_email.subject,
          headers: rendered.swoosh_email.headers || %{}
        }),
      idempotency_key: idempotency_key
    }
  end

  def idempotency_key(%Message{} = message) do
    content_hash =
      :crypto.hash(:sha256, [
        message.swoosh_email.text_body || "",
        message.swoosh_email.html_body || ""
      ])
      |> Base.encode16(case: :lower)

    :crypto.hash(:sha256, [
      message.tenant_id || "",
      "|",
      inspect(message.mailable),
      "|",
      Preflight.primary_recipient(message),
      "|",
      content_hash
    ])
    |> Base.encode16(case: :lower)
  end

  defp recipient_domain(message) do
    case String.split(Preflight.primary_recipient(message), "@", parts: 2) do
      [_, domain] -> String.downcase(domain)
      _ -> ""
    end
  end
end
