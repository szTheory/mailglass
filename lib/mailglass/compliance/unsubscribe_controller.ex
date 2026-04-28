defmodule Mailglass.Compliance.UnsubscribeController do
  @moduledoc """
  Core RFC 8058 unsubscribe controller.

  GET renders the built-in confirmation page by default or redirects to the
  configured escape hatch. POST handling lands in the next task.
  """

  use Phoenix.Controller, formats: [:html]

  import Ecto.Query
  import Plug.Conn

  alias Mailglass.Compliance
  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Compliance.UnsubscribeHTML
  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Outbound.Projector
  alias Mailglass.Repo
  alias Mailglass.Tenancy

  @doc false
  def show(conn, %{"token" => token}) do
    with {:ok, %{delivery_id: delivery_id}} <- Unsubscribe.verify_token(token),
         %Delivery{} = delivery <- Repo.get(Delivery, delivery_id) do
      maybe_redirect_or_render(conn, delivery)
    else
      {:error, :expired} -> failure(conn, 410, "unsubscribe token expired")
      {:error, :invalid} -> failure(conn, 404, "unsubscribe token invalid")
      nil -> failure(conn, 404, "unsubscribe token invalid")
    end
  end

  @doc false
  def unsubscribe(conn, %{"token" => token}) do
    case resolve_delivery(token) do
      {:ok, delivery} ->
        delivery
        |> append_unsubscribe_event()
        |> respond_to_unsubscribe(conn, delivery)

      {:error, :expired} ->
        send_resp(conn, 200, "")

      {:error, :invalid} ->
        send_resp(conn, 200, "")
    end
  end

  defp maybe_redirect_or_render(conn, delivery) do
    if redirect_path = Mailglass.Config.compliance_redirect() do
      redirect(conn, to: redirect_path)
    else
      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> put_view(html: UnsubscribeHTML)
      |> render(:confirm, recipient: delivery.recipient)
    end
  end

  defp failure(conn, status, message) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, "<!doctype html><html><body>#{message}</body></html>")
  end

  defp resolve_delivery(token) do
    with {:ok, %{delivery_id: delivery_id}} <- Unsubscribe.verify_token(token),
         %Delivery{} = delivery <- Repo.get(Delivery, delivery_id) do
      {:ok, delivery}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid}
    end
  end

  defp append_unsubscribe_event(%Delivery{} = delivery) do
    Tenancy.with_tenant(delivery.tenant_id, fn ->
      delivery
      |> unsubscribe_multi()
      |> Repo.multi()
    end)
  end

  defp unsubscribe_multi(%Delivery{} = delivery) do
    attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :unsubscribed,
      idempotency_key: unsubscribe_idempotency_key(delivery),
      normalized_payload: %{source: :unsubscribe}
    }

    Ecto.Multi.new()
    |> Events.append_multi(:unsubscribe_event, attrs)
    |> Ecto.Multi.run(:unsubscribe_event_record, fn repo, changes ->
      {:ok, canonical_event(repo, changes.unsubscribe_event, delivery)}
    end)
    |> Compliance.configured_lifecycle().handle_event(%{
      delivery_id: delivery.id,
      tenant_id: delivery.tenant_id,
      event: :unsubscribed
    })
  end

  defp canonical_event(_repo, %Event{inserted_at: %DateTime{}} = event, _delivery), do: event

  defp canonical_event(repo, %Event{inserted_at: nil}, %Delivery{} = delivery) do
    repo.one!(
      from event in Event,
        where:
          event.delivery_id == ^delivery.id and
            event.type == :unsubscribed and
            event.idempotency_key == ^unsubscribe_idempotency_key(delivery),
        limit: 1
    )
  end

  defp respond_to_unsubscribe({:ok, %{unsubscribe_event_record: event}}, conn, delivery) do
    Projector.broadcast_delivery_updated(delivery, event.type, %{
      tenant_id: delivery.tenant_id,
      event_id: event.id
    })

    send_resp(conn, 200, "")
  end

  defp respond_to_unsubscribe({:error, _step, _reason, _changes}, conn, _delivery) do
    send_resp(conn, 500, "")
  end

  defp unsubscribe_idempotency_key(%Delivery{id: delivery_id}), do: "unsubscribe:#{delivery_id}"
end
