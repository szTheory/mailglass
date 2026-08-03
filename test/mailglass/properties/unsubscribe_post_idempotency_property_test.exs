defmodule Mailglass.Properties.UnsubscribePostIdempotencyPropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  import Ecto.Query
  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1, with_app_env!: 1]
  require Phoenix.ConnTest

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Events.Event
  alias Mailglass.Generators
  alias Mailglass.TestRepo

  defmodule RecordingLifecycle do
    @behaviour Mailglass.Lifecycle

    @impl true
    def handle_event(%Ecto.Multi{} = multi, attrs) do
      if pid = Application.get_env(:mailglass, :unsubscribe_property_test_pid) do
        send(pid, {:created_effect, attrs.delivery_id})
      end

      multi
    end
  end

  defmodule TestRouter do
    use Phoenix.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:put_secure_browser_headers)
    end

    scope "/" do
      pipe_through(:browser)

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
      key: "_mailglass_unsubscribe_property_test",
      signing_salt: "unsubscribe-property-test"
    )

    plug(TestRouter)
  end

  @endpoint TestEndpoint
  @moduletag :property
  @moduletag timeout: :infinity

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

  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1). Its revert to :manual is
  # registered FIRST (this setup runs before the one below), so it runs LAST
  # — the file's own restore on_exit (registered second, below) still
  # executes while :auto is in effect.
  setup :unsandboxed_module

  setup do
    # Restores exactly, including REMOVING `:compliance` and this module's own
    # `TestEndpoint` module key — neither is in any `config/*.exs`, so the
    # previous `Application.put_all_env/1` restore (which merges) left both
    # behind for the rest of the run. See `SandboxOwnership.with_app_env!/2`.
    with_app_env!(:mailglass)

    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_deliveries CASCADE", [])

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

    on_exit(fn ->
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
      TestRepo.query!("TRUNCATE TABLE mailglass_deliveries CASCADE", [])
    end)

    :ok
  end

  property "replayed one-click POST requests converge to the same durable state as a single POST" do
    check all(
            replay_count <- integer(1..10),
            tenant_id <- string(:alphanumeric, min_length: 3, max_length: 12),
            recipient_local <- string(:alphanumeric, min_length: 3, max_length: 12),
            recipient_domain <- string(:alphanumeric, min_length: 3, max_length: 12),
            max_runs: 50
          ) do
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
      TestRepo.query!("TRUNCATE TABLE mailglass_deliveries CASCADE", [])

      delivery =
        Generators.delivery_fixture(
          tenant_id: tenant_id,
          recipient: "#{recipient_local}@#{recipient_domain}.test"
        )

      token = Unsubscribe.sign_token(delivery.id)
      path = "/mailglass/unsubscribe/#{token}"

      baseline_conn = Phoenix.ConnTest.post(Phoenix.ConnTest.build_conn(), path, %{})
      baseline_snapshot = durable_snapshot(delivery.id)

      assert Phoenix.ConnTest.response(baseline_conn, 200) == ""
      assert baseline_snapshot == [{"unsubscribe:#{delivery.id}", :unsubscribed}]

      replay_responses =
        for _ <- 1..replay_count do
          Phoenix.ConnTest.post(Phoenix.ConnTest.build_conn(), path, %{})
        end

      replay_snapshot = durable_snapshot(delivery.id)

      assert Enum.all?(replay_responses, &(Phoenix.ConnTest.response(&1, 200) == ""))
      assert replay_snapshot == baseline_snapshot
      assert length(replay_snapshot) == 1
    end
  end

  test "true concurrent POSTs converge to one event and one created-only lifecycle effect" do
    Application.put_env(
      :mailglass,
      :compliance,
      Keyword.put(Application.fetch_env!(:mailglass, :compliance), :lifecycle, RecordingLifecycle)
    )

    Application.put_env(:mailglass, :unsubscribe_property_test_pid, self())
    delivery = Generators.delivery_fixture(stream: :bulk, recipient: "Race@Example.com")
    path = "/mailglass/unsubscribe/#{Unsubscribe.sign_token(delivery.id)}"
    barrier = :counters.new(1, [])

    responses =
      1..4
      |> Task.async_stream(
        fn _ ->
          :counters.add(barrier, 1, 1)
          wait_for_barrier(barrier, 4)
          Phoenix.ConnTest.post(Phoenix.ConnTest.build_conn(), path, %{})
        end,
        max_concurrency: 4,
        timeout: 15_000
      )
      |> Enum.map(fn {:ok, conn} -> Phoenix.ConnTest.response(conn, 200) end)

    assert responses == ["", "", "", ""]
    assert durable_snapshot(delivery.id) == [{"unsubscribe:#{delivery.id}", :unsubscribed}]
    delivery_id = delivery.id
    assert_receive {:created_effect, ^delivery_id}
    refute_receive {:created_effect, _}
  end

  defp durable_snapshot(delivery_id) do
    TestRepo.all(
      from(event in Event,
        where: event.delivery_id == ^delivery_id and event.type == :unsubscribed,
        select: {event.idempotency_key, event.type}
      )
    )
  end

  defp wait_for_barrier(barrier, target) do
    if :counters.get(barrier, 1) == target do
      :ok
    else
      Process.sleep(5)
      wait_for_barrier(barrier, target)
    end
  end
end
