defmodule Mailglass.Compliance.UnsubscribeControllerTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Compliance.UnsubscribeConvergence
  alias Mailglass.Events.Event
  alias Mailglass.Generators
  alias Mailglass.Suppression.Entry
  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership
  alias Mailglass.Tenancy

  import Ecto.Query
  import Plug.Conn

  defmodule TestRouter do
    use Phoenix.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:put_secure_browser_headers)
    end

    scope "/" do
      pipe_through(:browser)

      get("/mailglass/unsubscribe/:token", Mailglass.Compliance.UnsubscribeController, :show)

      post(
        "/mailglass/unsubscribe/:token",
        Mailglass.Compliance.UnsubscribeController,
        :unsubscribe
      )
    end
  end

  defmodule TestEndpoint do
    use Phoenix.Endpoint, otp_app: :mailglass

    plug(Plug.Session,
      store: :cookie,
      key: "_mailglass_unsubscribe_test",
      signing_salt: "unsubscribe-test"
    )

    plug(TestRouter)
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
    # Restores exactly, including REMOVING the three keys this module ADDS and
    # no `config/*.exs` declares — `:compliance`, `:unsubscribe_test_pid`, and
    # the `TestEndpoint` module key. `Application.put_all_env/1` (the previous
    # restore) merges, so all three survived into every later module in the
    # run. See `SandboxOwnership.with_app_env!/2`.
    SandboxOwnership.with_app_env!(:mailglass)

    Application.put_env(:mailglass, TestEndpoint,
      http: [ip: {127, 0, 0, 1}, port: 0],
      secret_key_base: String.duplicate("abcdef0123456789", 4),
      server: false,
      render_errors: [formats: [html: Mailglass.TestUnsubscribeErrors], layout: false],
      pubsub_server: Mailglass.PubSub,
      live_view: [signing_salt: "unsubscribe-live"]
    )

    Application.put_env(:mailglass, :tracking,
      endpoint: "tracking-endpoint",
      host: "localhost",
      salts: ["test-salt"]
    )

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
      Application.put_env(
        :mailglass,
        :compliance,
        Keyword.put(
          Application.fetch_env!(:mailglass, :compliance),
          :redirect,
          "/settings/unsubscribe"
        )
      )

      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      conn = get(conn, "/mailglass/unsubscribe/#{token}")

      assert redirected_to(conn, 302) == "/settings/unsubscribe"
    end

    test "returns structured 410 for expired tokens", %{conn: conn} do
      Application.put_env(
        :mailglass,
        :compliance,
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

    test "returns structured 404 for tampered tokens", %{conn: conn} do
      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      tampered = tamper_token!(token)

      conn = get(conn, "/mailglass/unsubscribe/#{tampered}")

      assert response(conn, 404) =~ "invalid"
    end
  end

  describe "POST /mailglass/unsubscribe/:token" do
    @describetag :post_flow

    test "converges a delivery-derived canonical event and immutable stream suppression", %{
      conn: conn
    } do
      delivery = Generators.delivery_fixture(stream: :bulk, recipient: "Recipient@Example.com")
      token = Unsubscribe.sign_token(delivery.id)

      conn = post(conn, "/mailglass/unsubscribe/#{token}", %{})

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "location") == []

      events =
        TestRepo.all(
          from(event in Event,
            where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
          )
        )

      assert length(events) == 1
      event = hd(events)
      assert event.idempotency_key == "unsubscribe:#{delivery.id}"

      [suppression] = suppressions_for(delivery)
      assert suppression.tenant_id == delivery.tenant_id
      assert suppression.address == "recipient@example.com"
      assert suppression.scope == :address_stream
      assert suppression.stream == :bulk
      assert suppression.reason == :unsubscribe
      assert suppression.source == "compliance:one_click"

      assert suppression.metadata == %{
               "delivery_id" => delivery.id,
               "event_id" => event.id,
               "event_type" => "unsubscribed"
             }
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

      assert [_event] = events_for(delivery)
      assert [_suppression] = suppressions_for(delivery)
    end

    test "expired POST returns 200 without redirecting or writing an event", %{conn: conn} do
      Application.put_env(
        :mailglass,
        :compliance,
        Keyword.put(Application.fetch_env!(:mailglass, :compliance), :max_age, 1)
      )

      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      Process.sleep(1_100)

      conn = post(conn, "/mailglass/unsubscribe/#{token}", %{})

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "location") == []

      count =
        TestRepo.aggregate(
          from(event in Event,
            where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
          ),
          :count
        )

      assert count == 0
    end

    test "tampered POST returns 200 without redirecting or writing an event", %{conn: conn} do
      delivery = Generators.delivery_fixture()
      token = Unsubscribe.sign_token(delivery.id)
      tampered = tamper_token!(token)

      conn = post(conn, "/mailglass/unsubscribe/#{tampered}", %{})

      assert response(conn, 200) == ""
      assert get_resp_header(conn, "location") == []

      count =
        TestRepo.aggregate(
          from(event in Event,
            where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
          ),
          :count
        )

      assert count == 0
    end

    test "repairs an event-only legacy state and reports created", %{conn: conn} do
      delivery = Generators.delivery_fixture(stream: :bulk)
      insert_unsubscribe_event!(delivery)

      assert {:ok, %{status: :created, event: %Event{}, suppression: %Entry{}}} =
               Tenancy.with_tenant(delivery.tenant_id, fn ->
                 UnsubscribeConvergence.run(delivery)
               end)

      result_conn = post(conn, "/mailglass/unsubscribe/#{Unsubscribe.sign_token(delivery.id)}", %{})
      assert response(result_conn, 200) == ""
      assert [_event] = events_for(delivery)
      assert [_suppression] = suppressions_for(delivery)
    end

    test "repairs a suppression-only legacy state and reports created", %{conn: conn} do
      delivery = Generators.delivery_fixture(stream: :operational)
      insert_unsubscribe_suppression!(delivery)

      assert {:ok, %{status: :created, event: %Event{}, suppression: %Entry{}}} =
               Tenancy.with_tenant(delivery.tenant_id, fn ->
                 UnsubscribeConvergence.run(delivery)
               end)

      result_conn = post(conn, "/mailglass/unsubscribe/#{Unsubscribe.sign_token(delivery.id)}", %{})
      assert response(result_conn, 200) == ""
      assert [_event] = events_for(delivery)
      assert [_suppression] = suppressions_for(delivery)
    end

    test "returns empty 500 and rolls back both facts after the event step", %{conn: conn} do
      Application.put_env(:mailglass, :unsubscribe_convergence_failure_step, :after_event)

      delivery = Generators.delivery_fixture(stream: :bulk)
      result_conn = post(conn, "/mailglass/unsubscribe/#{Unsubscribe.sign_token(delivery.id)}", %{})

      assert response(result_conn, 500) == ""
      assert events_for(delivery) == []
      assert suppressions_for(delivery) == []
    end
  end

  defp tamper_token!(token) when is_binary(token) do
    tampered =
      token
      |> String.split(".")
      |> List.update_at(-1, &mutate_segment!/1)
      |> Enum.join(".")

    case Unsubscribe.verify_token(tampered) do
      {:error, :invalid} -> tampered
      other -> raise "expected tampered token to be invalid, got: #{inspect(other)}"
    end
  end

  defp mutate_segment!(segment) when is_binary(segment) and segment != "" do
    replacement = if String.first(segment) == "A", do: "B", else: "A"
    String.replace_prefix(segment, String.first(segment), replacement)
  end

  defp events_for(delivery) do
    TestRepo.all(
      from(event in Event,
        where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
      )
    )
  end

  defp suppressions_for(delivery) do
    TestRepo.all(
      from(suppression in Entry,
        where:
          suppression.tenant_id == ^delivery.tenant_id and
            suppression.address == ^String.downcase(delivery.recipient) and
            suppression.scope == :address_stream and suppression.stream == ^delivery.stream and
            suppression.reason == :unsubscribe
      )
    )
  end

  defp insert_unsubscribe_event!(delivery) do
    {:ok, _event} =
      TestRepo.insert(
        Event.changeset(%{
          tenant_id: delivery.tenant_id,
          delivery_id: delivery.id,
          type: :unsubscribed,
          occurred_at: Mailglass.Clock.utc_now(),
          idempotency_key: "unsubscribe:#{delivery.id}",
          normalized_payload: %{source: :unsubscribe}
        })
      )
  end

  defp insert_unsubscribe_suppression!(delivery) do
    {:ok, _suppression} =
      TestRepo.insert(
        Entry.changeset(%{
          tenant_id: delivery.tenant_id,
          address: delivery.recipient,
          scope: :address_stream,
          stream: delivery.stream,
          reason: :unsubscribe,
          source: "compliance:one_click",
          metadata: %{}
        })
      )
  end
end
