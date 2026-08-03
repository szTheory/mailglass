defmodule Mailglass.Compliance.UnsubscribeController do
  @moduledoc """
  Core RFC 8058 unsubscribe controller.

  GET renders the built-in confirmation page by default or redirects to the
  configured escape hatch. POST handling lands in the next task.
  """

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Compliance.UnsubscribeConvergence
  alias Mailglass.Compliance.UnsubscribeHTML
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo
  alias Mailglass.Tenancy

  @doc false
  def show(conn, %{"token" => token}) do
    with {:ok, %{delivery_id: delivery_id}} <- Unsubscribe.verify_token(token),
         %Delivery{} = delivery <- fetch_delivery(delivery_id) do
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
        |> UnsubscribeConvergence.run()
        |> respond_to_unsubscribe(conn)

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
         %Delivery{} = delivery <- fetch_delivery(delivery_id) do
      {:ok, delivery}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid}
    end
  end

  defp fetch_delivery(delivery_id) do
    Tenancy.audit_unscoped_bypass(%{
      reason: :unsubscribe_token_delivery_lookup,
      resource: :delivery
    })

    Repo.get(Delivery, delivery_id, scope: :unscoped)
  end

  defp respond_to_unsubscribe({:ok, _convergence}, conn) do
    send_resp(conn, 200, "")
  end

  defp respond_to_unsubscribe({:error, _reason}, conn) do
    send_resp(conn, 500, "")
  end
end
