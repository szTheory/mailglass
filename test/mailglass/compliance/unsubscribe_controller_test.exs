defmodule Mailglass.Compliance.UnsubscribeControllerTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Events.Event
  alias Mailglass.Generators
  alias Mailglass.PubSub.Topics
  alias Mailglass.TestRepo

  import Ecto.Query
  import Plug.Conn

  defmodule TestRouter do
    use Phoenix.Router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :put_secure_browser_headers
    end

    scope "/" do
      pipe_through :browser

      get "/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :show
      post "/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :unsubscribe
    end
  end

  defmodule TestEndpoint do
    use Phoenix.Endpoint, otp_app: :mailglass

    plug Plug.Session,
      store: :cookie,
      key: "_mailglass_unsubscribe_test",
      signing_salt: "unsubscribe-test"

    plug TestRouter
  end

  defmodule RecordingLifecycle do
    @behaviour Mailglass.Lifecycle

    @impl true
    def handle_event(%Ecto.Multi{} = multi, attrs) do
      if pid = Application.get_env(:mailglass, :unsubscribe_test_pid) do
        send(pid, {:lifecycle_multi, Enum.map(multi.operations, &elem(&1, 0)), attrs})
      end

      Ecto.Multi.run(multi, :lifecycle_probe, fn _repo, _changes ->
        if pid = Application.get_env(:mailglass, :unsubscribe_test_pid) do
          send(pid, {:lifecycle_txn, attrs[:delivery_id]})
        end

        {:ok, :lifecycle_ran}
      end)
    end
  end

  import Phoenix.ConnTest

  @endpoint TestEndpoint

  setup_all do
    {:ok, _} = Application.ensure_all_started(:phoenix)

    Application.put_env(:mailglass, TestEndpoint,
      http: [ip: {127, 0, 0, 1}, port: 0],
      secret_key_base: String.duplicate("abcdef0123456789", 4),
      server: false,
      render_errors: [formats: [html: Mailglass.TestUnsubscribeErrors], layout: false],
      pubsub_server: Mailglass.PubSub,
      live_view: [signing_salt: "unsubscribe-live"]
    )

    _ = TestEndpoint.start_link()
    :ok
  end

  setup do
    prior_mailglass = Application.get_all_env(:mailglass)

    Application.put_env(:mailglass, TestEndpoint,
      http: [ip: {127, 0, 0, 1}, port: 0],
      secret_key_base: String.duplicate("abcdef0123456789", 4),
      server: false,
      render_errors: [formats: [html: Mailglass.TestUnsubscribeErrors], layout: false],
      pubsub_server: Mailglass.PubSub,
      live_view: [signing_salt: "unsubscribe-live"]
    )

    Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint", host: "localhost", salts: ["test-salt"])

    Application.put_env(:mailglass, :compliance,
      endpoint: TestEndpoint,
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60,
      lifecycle: Mailglass.Lifecycle.Noop
    )

    on_exit(fn ->
      Application.put_all_env(mailglass: prior_mailglass)
    end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "GET /mailglass/unsubscribe/:token" do
    @describetag :get_flow

    test "renders the built-in confirmation page by default", %{conn: conn} do
      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      conn = get(conn, "/mailglass/unsubscribe/#{token}")

      assert html_response(conn, 200) =~ "Unsubscribe"
      assert html_response(conn, 200) =~ delivery.recipient
    end

    test "redirects when compliance redirect is configured", %{conn: conn} do
      Application.put_env(:mailglass, :compliance,
        Keyword.put(Application.fetch_env!(:mailglass, :compliance), :redirect, "/settings/unsubscribe")
      )

      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      conn = get(conn, "/mailglass/unsubscribe/#{token}")

      assert redirected_to(conn, 302) == "/settings/unsubscribe"
    end

    test "returns structured 410 for expired tokens", %{conn: conn} do
      Application.put_env(:mailglass, :compliance,
        Keyword.put(Application.fetch_env!(:mailglass, :compliance), :max_age, 1)
      )

      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      Process.sleep(1_100)

      conn = get(conn, "/mailglass/unsubscribe/#{token}")

      assert response(conn, 410) =~ "expired"
    end

    test "returns structured 404 for invalid tokens", %{conn: conn} do
      conn = get(conn, "/mailglass/unsubscribe/not-a-real-token")

      assert response(conn, 404) =~ "invalid"
    end
  end

  describe "POST /mailglass/unsubscribe/:token" do
    @describetag :post_flow

    test "appends a single unsubscribed event, composes lifecycle, and broadcasts after commit", %{
      conn: conn
    } do
      Application.put_env(:mailglass, :unsubscribe_test_pid, self())

      Application.put_env(:mailglass, :compliance,
        Keyword.put(Application.fetch_env!(:mailglass, :compliance), :lifecycle, RecordingLifecycle)
      )

      delivery = Generators.delivery_fixture()
      delivery_id = delivery.id
      tenant_id = delivery.tenant_id
      token = Unsubscribe.sign_token(delivery.id)
      :ok = Phoenix.PubSub.subscribe(Mailglass.PubSub, Topics.events(tenant_id, delivery_id))

      conn = post(conn, "/mailglass/unsubscribe/#{token}", %{})

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "location") == []
      assert_receive {:lifecycle_multi, operations, %{delivery_id: ^delivery_id, event: :unsubscribed}}
      assert :unsubscribe_event in operations
      assert_receive {:lifecycle_txn, ^delivery_id}
      assert_receive {:delivery_updated, ^delivery_id, :unsubscribed, %{tenant_id: ^tenant_id}}

      events =
        TestRepo.all(
          from event in Event,
            where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
        )

      assert length(events) == 1
      assert hd(events).idempotency_key == "unsubscribe:#{delivery.id}"
    end

    test "replayed POST returns 200 without duplicating durable state", %{conn: conn} do
      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)

      first = post(conn, "/mailglass/unsubscribe/#{token}", %{})
      second = post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})

      assert response(first, 200) == ""
      assert response(second, 200) == ""

      count =
        TestRepo.aggregate(
          from(event in Event,
            where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
          ),
          :count
        )

      assert count == 1
    end
  end
end
