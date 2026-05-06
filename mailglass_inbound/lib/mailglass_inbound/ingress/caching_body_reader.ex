defmodule MailglassInbound.Ingress.CachingBodyReader do
  @moduledoc """
  Package-local `Plug.Parsers` body reader for inbound provider verification.

  Stores exact request bytes in `conn.private[:raw_body]` so the inbound plug
  can verify provider authenticity before any tenant or persistence work runs.
  """

  @spec read_body(Plug.Conn.t(), keyword()) ::
          {:ok, binary(), Plug.Conn.t()}
          | {:more, binary(), Plug.Conn.t()}
          | {:error, term()}
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        raw = IO.iodata_to_binary([conn.private[:raw_body] || <<>>, body])
        {:ok, body, Plug.Conn.put_private(conn, :raw_body, raw)}

      {:more, body, conn} ->
        raw = [conn.private[:raw_body] || <<>>, body]
        {:more, body, Plug.Conn.put_private(conn, :raw_body, raw)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
