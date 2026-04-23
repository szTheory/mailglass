defmodule Mailglass.Webhook.CachingBodyReaderTest do
  # Plain ExUnit.Case — no DB, no global env mutation. Safe for async.
  use ExUnit.Case, async: true

  alias Mailglass.Webhook.CachingBodyReader

  describe "read_body/2 single-chunk path" do
    test "returns {:ok, body, conn} and stores raw body in conn.private[:raw_body]" do
      body = ~s({"event":"delivered"})
      conn = Plug.Test.conn(:post, "/", body)

      {:ok, returned_body, conn} = CachingBodyReader.read_body(conn, [])

      assert returned_body == body
      assert conn.private[:raw_body] == body
      assert is_binary(conn.private[:raw_body])
    end

    test "preserves empty bodies as binary <<>>" do
      conn = Plug.Test.conn(:post, "/", "")
      {:ok, body, conn} = CachingBodyReader.read_body(conn, [])
      assert body == ""
      assert conn.private[:raw_body] == ""
      assert is_binary(conn.private[:raw_body])
    end
  end

  describe "read_body/2 multi-chunk accumulation" do
    # Plug.Test cannot synthesize the `{:more, _, _}` return directly —
    # `Plug.Test.conn/3` delivers the entire body in one `{:ok, _, _}`
    # call. To exercise the iodata-accumulation branch structurally, we
    # pre-populate `conn.private[:raw_body]` with iodata (simulating a
    # prior `{:more, _, _}` call) and verify the final `{:ok, _, _}`
    # flattens the accumulated iodata into a binary.
    test "flattens prior iodata accumulator into a binary on final {:ok, _, _}" do
      initial_iodata = ["{\"events\":["]
      incoming_body = "{\"more\":true}"

      conn =
        :post
        |> Plug.Test.conn("/", incoming_body)
        |> Plug.Conn.put_private(:raw_body, initial_iodata)

      {:ok, body, conn} = CachingBodyReader.read_body(conn, [])

      assert body == incoming_body
      assert is_binary(conn.private[:raw_body])
      assert conn.private[:raw_body] == IO.iodata_to_binary([initial_iodata, incoming_body])
    end

    test "handles nil initial raw_body (first-chunk case) as empty <<>>" do
      body = "chunk1"
      conn = Plug.Test.conn(:post, "/", body)
      # No put_private call — simulates the very first chunk.
      refute Map.has_key?(conn.private, :raw_body)

      {:ok, returned, conn} = CachingBodyReader.read_body(conn, [])
      assert returned == body
      assert conn.private[:raw_body] == body
    end
  end

  describe "read_body/2 storage location contract" do
    test "uses conn.private (library-reserved), never conn.assigns" do
      conn = Plug.Test.conn(:post, "/", ~s({}))
      {:ok, _body, conn} = CachingBodyReader.read_body(conn, [])

      assert Map.has_key?(conn.private, :raw_body)
      refute Map.has_key?(conn.assigns, :raw_body)
    end
  end
end
