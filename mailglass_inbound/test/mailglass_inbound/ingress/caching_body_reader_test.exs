defmodule MailglassInbound.Ingress.CachingBodyReaderTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.Ingress.CachingBodyReader

  test "stores raw body in conn.private[:raw_body]" do
    body = ~s({"hello":"world"})
    conn = Plug.Test.conn(:post, "/", body)

    {:ok, returned_body, conn} = CachingBodyReader.read_body(conn, [])

    assert returned_body == body
    assert conn.private[:raw_body] == body
  end

  test "flattens prior iodata into a final binary" do
    conn =
      Plug.Test.conn(:post, "/", "chunk-2")
      |> Plug.Conn.put_private(:raw_body, ["chunk-1"])

    {:ok, body, conn} = CachingBodyReader.read_body(conn, [])

    assert body == "chunk-2"
    assert conn.private[:raw_body] == "chunk-1chunk-2"
  end
end
