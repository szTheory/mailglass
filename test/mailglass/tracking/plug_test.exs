defmodule Mailglass.Tracking.PlugTest do
  use Mailglass.DataCase, async: false

  import Plug.Conn
  import Plug.Test

  alias Mailglass.Tracking.Plug, as: TrackingPlug
  alias Mailglass.Tracking.Token

  @endpoint "mailglass-plug-test-secret"
  @tracking_host "track.test"

  setup do
    original = Application.get_env(:mailglass, :tracking)

    Application.put_env(:mailglass, :tracking,
      salts: ["plug-salt-1"],
      max_age: 86_400,
      host: @tracking_host,
      scheme: "https",
      endpoint: @endpoint
    )

    on_exit(fn ->
      if original do
        Application.put_env(:mailglass, :tracking, original)
      else
        Application.delete_env(:mailglass, :tracking)
      end
    end)

    :ok
  end

  defp call(method, path) do
    conn(method, path)
    |> TrackingPlug.call(TrackingPlug.init([]))
  end

  # Test 1: GET /o/:token.gif with valid token returns 200 + image/gif + 43-byte GIF89a
  test "GET /o/:token.gif with valid token returns 200 + GIF89a body" do
    Mailglass.Tenancy.put_current("test-tenant")
    token = Token.sign_open(@endpoint, "delivery-abc", "test-tenant")

    conn = call(:get, "/o/#{token}.gif")

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> hd() =~ "image/gif"
    assert byte_size(conn.resp_body) == 43

    # Verify GIF89a magic bytes
    assert <<71, 73, 70, 56, 57, 97, _rest::binary>> = conn.resp_body
  end

  # Test 2: Valid open token response has correct no-cache headers
  test "GET /o/:token.gif with valid token sets no-cache + x-robots-tag headers" do
    Mailglass.Tenancy.put_current("test-tenant")
    token = Token.sign_open(@endpoint, "delivery-headers", "test-tenant")

    conn = call(:get, "/o/#{token}.gif")

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store, private, max-age=0"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]
    assert get_resp_header(conn, "x-robots-tag") == ["noindex"]
  end

  # Test 3: Invalid open token returns 204 (no enumeration per D-39)
  test "GET /o/:token.gif with invalid token returns 204 not 404" do
    conn = call(:get, "/o/garbage-invalid-token.gif")

    assert conn.status == 204
    assert conn.resp_body == ""
  end

  # Test 4: GET /c/:token with valid click token returns 302 with Location header
  test "GET /c/:token with valid click token returns 302 redirect to target_url" do
    Mailglass.Tenancy.put_current("test-tenant")
    target_url = "https://example.com/post/42"
    token = Token.sign_click(@endpoint, "delivery-click", "test-tenant", target_url)

    conn = call(:get, "/c/#{token}")

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [target_url]
  end

  # Test 5: GET /c/:token with invalid token returns 404
  test "GET /c/:token with invalid token returns 404" do
    conn = call(:get, "/c/garbage-click-token")

    assert conn.status == 404
  end

  # Test 6: TrackingPlug is mountable — init/1 returns opts, call/2 accepts a conn
  test "TrackingPlug.init/1 and call/2 satisfy the Plug contract" do
    opts = TrackingPlug.init([])

    conn = conn(:get, "/o/garbage.gif") |> TrackingPlug.call(opts)
    assert %Plug.Conn{} = conn
    assert conn.state == :sent
  end

  # Test 7: unmatched routes return 404
  test "unmatched route returns 404" do
    conn = call(:get, "/unknown/route")
    assert conn.status == 404
  end
end
