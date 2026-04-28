defmodule Mailglass.Compliance.UnsubscribeController do
  @moduledoc """
  Core RFC 8058 unsubscribe controller.

  GET renders the built-in confirmation page by default or redirects to the
  configured escape hatch. POST handling lands in the next task.
  """

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Compliance.UnsubscribeHTML
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo

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
  def unsubscribe(conn, _params) do
    send_resp(conn, 200, "")
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
end
