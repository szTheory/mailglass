defmodule Mailglass.Tracking.PlugTest do
  use Mailglass.DataCase, async: false

  import Plug.Conn
  import Plug.Test

  alias Mailglass.Tracking.Plug, as: TrackingPlug
  alias Mailglass.Tracking.Token

  @endpoint "mailglass-plug-test-secret"
  @tracking_host "track.test"

  defmodule Ledger do
    def append(attrs) do
      send(Application.fetch_env!(:mailglass, :tracking_test_pid), {:tracking_append, attrs})

      case Application.fetch_env!(:mailglass, :tracking_test_outcome) do
        :raise -> raise "ledger failure sentinel"
        outcome -> outcome
      end
    end
  end

  setup do
    original = Application.get_env(:mailglass, :tracking)
    original_ledger = Application.get_env(:mailglass, :tracking_event_ledger)
    original_pid = Application.get_env(:mailglass, :tracking_test_pid)
    original_outcome = Application.get_env(:mailglass, :tracking_test_outcome)

    Application.put_env(:mailglass, :tracking,
      salts: ["plug-salt-1"],
      max_age: 86_400,
      host: @tracking_host,
      scheme: "https",
      endpoint: @endpoint
    )

    Application.put_env(:mailglass, :tracking_event_ledger, Ledger)
    Application.put_env(:mailglass, :tracking_test_pid, self())
    Application.put_env(:mailglass, :tracking_test_outcome, {:ok, :recorded})

    on_exit(fn ->
      if original do
        Application.put_env(:mailglass, :tracking, original)
      else
        Application.delete_env(:mailglass, :tracking)
      end

      restore_env(:tracking_event_ledger, original_ledger)
      restore_env(:tracking_test_pid, original_pid)
      restore_env(:tracking_test_outcome, original_outcome)
    end)

    :ok
  end

  defp call(method, path) do
    conn(method, path)
    |> TrackingPlug.call(TrackingPlug.init([]))
  end

  defp restore_env(key, nil), do: Application.delete_env(:mailglass, key)
  defp restore_env(key, value), do: Application.put_env(:mailglass, key, value)

  defp attach_tracking_handler(events) do
    test_pid = self()
    handler_id = "tracking-telemetry-#{System.unique_integer()}"

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:tracking_telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
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

  test "successful open ledger append emits recorded telemetry" do
    attach_tracking_handler([
      [:mailglass, :tracking, :open, :recorded],
      [:mailglass, :tracking, :open, :failed]
    ])

    token = Token.sign_open(@endpoint, "delivery-open-recorded", "test-tenant")

    assert %Plug.Conn{status: 200} = call(:get, "/o/#{token}.gif")
    assert_receive {:tracking_append, %{delivery_id: "delivery-open-recorded", type: :opened}}

    assert_receive {:tracking_telemetry, [:mailglass, :tracking, :open, :recorded], %{count: 1},
                    %{delivery_id: "delivery-open-recorded", tenant_id: "test-tenant"}}

    refute_receive {:tracking_telemetry, [:mailglass, :tracking, :open, :failed], _, _}, 0
  end

  test "open ledger errors emit bounded failed telemetry without changing the GIF response" do
    Application.put_env(:mailglass, :tracking_test_outcome, {:error, :simulated_failure})

    attach_tracking_handler([
      [:mailglass, :tracking, :open, :recorded],
      [:mailglass, :tracking, :open, :failed]
    ])

    token = Token.sign_open(@endpoint, "delivery-open-failed", "test-tenant")

    assert %Plug.Conn{status: 200, resp_body: body} = call(:get, "/o/#{token}.gif")
    assert byte_size(body) == 43

    assert_receive {:tracking_telemetry, [:mailglass, :tracking, :open, :failed], %{count: 1},
                    %{
                      delivery_id: "delivery-open-failed",
                      tenant_id: "test-tenant",
                      failure_class: :append_error
                    }}

    refute_receive {:tracking_telemetry, [:mailglass, :tracking, :open, :recorded], _, _}, 0
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

  test "click ledger raises emit bounded failed telemetry without changing the redirect" do
    Application.put_env(:mailglass, :tracking_test_outcome, :raise)

    attach_tracking_handler([
      [:mailglass, :tracking, :click, :recorded],
      [:mailglass, :tracking, :click, :failed]
    ])

    target_url = "https://example.com/private-target"
    token = Token.sign_click(@endpoint, "delivery-click-failed", "test-tenant", target_url)

    assert %Plug.Conn{status: 302} = call(:get, "/c/#{token}")

    assert_receive {:tracking_telemetry, [:mailglass, :tracking, :click, :failed], %{count: 1},
                    %{
                      delivery_id: "delivery-click-failed",
                      tenant_id: "test-tenant",
                      failure_class: :exception
                    }}

    refute_receive {:tracking_telemetry, [:mailglass, :tracking, :click, :recorded], _, _}, 0
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
