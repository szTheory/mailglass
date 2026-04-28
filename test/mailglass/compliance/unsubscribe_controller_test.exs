defmodule Mailglass.Compliance.UnsubscribeControllerTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Generators

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
end
