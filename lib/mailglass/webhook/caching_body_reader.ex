defmodule Mailglass.Webhook.CachingBodyReader do
  @moduledoc """
  Custom `Plug.Parsers` `:body_reader` that preserves raw request
  bytes in `conn.private[:raw_body]` for HMAC verification while
  still allowing JSON parsing downstream.

  Accumulates iodata across `{:more, _, _}` chunks and flattens on
  the final `{:ok, _, _}` — required for SendGrid batch payloads up
  to 128 events (~3 MB). Configure `Plug.Parsers` with
  `length: 10_000_000` (10 MB cap; ~2 MB headroom over the default).

  ## Footgun: `Plug.Parsers.MULTIPART` does NOT honor `:body_reader`

  Plug issue #884. Mailglass providers POST JSON, so this is
  irrelevant for the library — but adopters adding `:multipart` to
  the same parsers config will silently bypass this reader.
  Documented in `guides/webhooks.md`.

  ## Storage location

  Bytes land in `conn.private[:raw_body]`. The `conn.private` map is
  library-reserved (off the adopter `assigns` contract), matching
  `LatticeStripe.Webhook.CacheBodyReader` convention. Mailglass
  diverges from accrue's `conn.assigns` cons-list per CONTEXT D-09
  — `private` is the right boundary for library-reserved data.

  ## Adopter-side wiring

      # my_app_web/endpoint.ex
      plug Plug.Parsers,
        parsers: [:json],
        pass: ["*/*"],
        json_decoder: Jason,
        body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
        length: 10_000_000
  """

  @doc """
  Plug `:body_reader` MFA entry point. Wraps `Plug.Conn.read_body/2`
  and accumulates iodata into `conn.private[:raw_body]`.

  Returns `Plug.Conn.read_body/2`-shaped tuples:
  - `{:ok, body, conn}` — final chunk; `raw_body` flattened to binary
  - `{:more, body, conn}` — more chunks pending; `raw_body` is iodata
  - `{:error, reason}` — propagated unchanged
  """
  @doc since: "0.1.0"
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
