defmodule Mailglass.SchemaPrefixHardeningTest do
  # async: false because this module drops/recreates the configured schema and
  # switches the SQL Sandbox to :auto for migration setup.
  use ExUnit.Case, async: false

  @moduletag :schema_prefix

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.Clock
  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo
  alias Mailglass.TestRepo
  alias Mailglass.Tenancy
  alias Mailglass.Webhook.Replay
  alias Mailglass.Webhook.WebhookEvent

  @endpoint Mailglass.SchemaPrefixHardeningTest.TestEndpoint
  @prefix "mailglass"
  @tenant_id "schema-prefix-hardening-tenant"

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
      key: "_mailglass_schema_prefix_unsubscribe_test",
      signing_salt: "schema-prefix-unsubscribe-test"
    )

    plug(TestRouter)
  end

  defmodule PrefixedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass"

    def up do
      Mailglass.Migration.up(prefix: @prefix, repo: Mailglass.TestRepo)
    end

    def down do
      Mailglass.Migration.down(prefix: @prefix, repo: Mailglass.TestRepo)
    end
  end

  import Phoenix.ConnTest

  setup_all do
    {:ok, _} = Application.ensure_all_started(:phoenix)

    Application.put_env(:mailglass, TestEndpoint, endpoint_config())

    case TestEndpoint.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1). Its revert to :manual is
  # registered FIRST (this setup runs before the one below), so it runs LAST
  # — the file's own restore on_exit (registered second, below) still
  # executes while :auto is in effect.
  setup :unsandboxed_module

  setup do
    prior_mailglass_env = Application.get_all_env(:mailglass)

    Application.put_env(:mailglass, :schema, @prefix)
    Application.put_env(:mailglass, TestEndpoint, endpoint_config())
    Application.put_env(:mailglass, :compliance, compliance_config())
    :persistent_term.erase({Mailglass.Config, :schema})

    # 143-MECHANISM.md § "The three-class inventory" names this file as a
    # candidate for BOTH Class B (config_schema_drift — flips Config.schema()
    # per-test) and Class A (baseline_missing — drops/restores public.
    # mailglass_* tables). The drift/restore defect is left deliberately
    # unchanged here; closing it is plan 143-07's job.
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
      end)

    Tenancy.put_current(@tenant_id)

    on_exit(fn ->
      _ = TestRepo.query("RESET search_path")
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])
      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext")

      Application.put_all_env(mailglass: prior_mailglass_env)
      :persistent_term.erase({Mailglass.Config, :schema})
      restore_suite_baseline_schema()
    end)

    :ok
  end

  test "Webhook.Replay projection update targets configured schema without search_path help" do
    provider_message_id = "msg-schema-prefix-#{System.unique_integer([:positive])}"

    delivery =
      insert_delivery!(
        provider_message_id: provider_message_id,
        last_event_at: DateTime.add(Clock.utc_now(), -60, :second)
      )

    webhook_event =
      insert_webhook_event!(
        provider_event_id: "postmark-schema-prefix-#{System.unique_integer([:positive])}",
        raw_payload: %{
          "RecordType" => "Delivery",
          "MessageID" => provider_message_id,
          "ID" => System.unique_integer([:positive])
        }
      )

    force_public_search_path!()

    assert {:ok, result} =
             Replay.execute(%{
               tenant_id: @tenant_id,
               webhook_event_id: webhook_event.id,
               delivery_id: delivery.id,
               actor: %{subject_id: "schema-prefix-proof"}
             })

    assert result.status == :replayed
    assert result.delivery_id == delivery.id
    assert result.new_event_count == 1

    assert_configured_delivery_projected!(delivery.id)
    assert_public_delivery_absent!(delivery.id)
  end

  test "Webhook.Replay raw projector callback passes explicit configured-schema opts" do
    source = File.read!("lib/mailglass/webhook/replay.ex")

    assert source =~ "changeset = Projector.update_projections(delivery, inserted_event)"
    assert source =~ "repo.update(changeset, Repo.multi_opts())"
  end

  test "unsubscribe replay conflict lookup targets configured schema without search_path help" do
    delivery = insert_delivery!(provider_message_id: "msg-unsubscribe-schema-prefix")
    token = Unsubscribe.sign_token(delivery.id)

    force_public_search_path!()

    first = post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})
    second = post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})

    assert response(first, 200) == ""
    assert response(second, 200) == ""

    assert_configured_unsubscribe_event_count!(delivery.id, 1)
    assert_public_unsubscribe_event_count!(delivery.id, 0)
  end

  test "unsubscribe raw conflict lookup passes explicit configured-schema opts" do
    source = File.read!("lib/mailglass/compliance/unsubscribe_controller.ex")

    assert source =~ "repo.one!(query, Repo.multi_opts())"
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      mailable: "Mailglass.SchemaPrefixHardeningMailer",
      stream: :transactional,
      recipient: "schema-prefix@example.com",
      provider: "postmark",
      provider_message_id: "msg-#{System.unique_integer([:positive])}",
      last_event_type: :sent,
      last_event_at: Clock.utc_now(),
      status: :sent,
      metadata: %{}
    }

    {:ok, delivery} =
      defaults
      |> Map.merge(Map.new(attrs))
      |> Delivery.changeset()
      |> Repo.insert()

    delivery
  end

  defp insert_webhook_event!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      provider: "postmark",
      provider_event_id: "webhook-#{System.unique_integer([:positive])}",
      event_type_raw: "Delivery",
      event_type_normalized: "delivered",
      status: :succeeded,
      raw_payload: %{"RecordType" => "Delivery"},
      received_at: Clock.utc_now(),
      processed_at: Clock.utc_now()
    }

    {:ok, webhook_event} =
      defaults
      |> Map.merge(Map.new(attrs))
      |> WebhookEvent.changeset()
      |> Repo.insert()

    webhook_event
  end

  defp force_public_search_path! do
    _ = TestRepo.query!("SET search_path TO public", [])
    :ok
  end

  defp assert_configured_delivery_projected!(delivery_id) do
    %{rows: rows} =
      TestRepo.query!(
        """
        SELECT last_event_type::text, delivered_at IS NOT NULL, terminal
        FROM #{@prefix}.mailglass_deliveries
        WHERE id = $1
        """,
        [Ecto.UUID.dump!(delivery_id)]
      )

    assert rows == [["delivered", true, true]]
  end

  defp assert_public_delivery_absent!(delivery_id) do
    %{rows: [[count]]} =
      TestRepo.query!(
        """
        SELECT COUNT(*)
        FROM public.mailglass_deliveries
        WHERE id = $1
        """,
        [Ecto.UUID.dump!(delivery_id)]
      )

    assert count == 0
  end

  defp assert_configured_unsubscribe_event_count!(delivery_id, expected_count) do
    assert unsubscribe_event_count(@prefix, delivery_id) == expected_count
  end

  defp assert_public_unsubscribe_event_count!(delivery_id, expected_count) do
    assert unsubscribe_event_count("public", delivery_id) == expected_count
  end

  defp unsubscribe_event_count(schema, delivery_id) when schema in [@prefix, "public"] do
    %{rows: [[count]]} =
      TestRepo.query!(
        """
        SELECT COUNT(*)
        FROM #{schema}.mailglass_events
        WHERE delivery_id = $1
          AND type = 'unsubscribed'
          AND idempotency_key = $2
        """,
        [Ecto.UUID.dump!(delivery_id), "unsubscribe:#{delivery_id}"]
      )

    count
  end

  defp endpoint_config do
    [
      http: [ip: {127, 0, 0, 1}, port: 0],
      secret_key_base: String.duplicate("abcdef0123456789", 4),
      server: false,
      render_errors: [formats: [html: Mailglass.TestUnsubscribeErrors], layout: false],
      pubsub_server: Mailglass.PubSub,
      live_view: [signing_salt: "schema-prefix-live"]
    ]
  end

  defp compliance_config do
    [
      endpoint: TestEndpoint,
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60,
      lifecycle: Mailglass.Lifecycle.Noop
    ]
  end

  defp restore_suite_baseline_schema do
    if System.get_env("MAILGLASS_SCHEMA") in [nil, "", "public"] do
      :ok
    else
      {:ok, _} = TestRepo.query("DELETE FROM public.schema_migrations WHERE version < 100")

      migrations_path = Path.join(:code.priv_dir(:mailglass), "repo/migrations")

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
        end)

      :ok
    end
  end
end
