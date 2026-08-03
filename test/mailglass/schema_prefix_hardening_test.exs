defmodule Mailglass.SchemaPrefixHardeningTest do
  # async: false because this module drops/recreates the configured schema and
  # switches the SQL Sandbox to :auto for migration setup.
  use ExUnit.Case, async: false

  @moduletag :schema_prefix

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1, with_schema!: 1]

  alias Mailglass.TestSupport.SandboxOwnership
  alias Mailglass.Clock
  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Repo
  alias Mailglass.TestRepo
  alias Mailglass.Tenancy
  alias Mailglass.Webhook.Replay
  alias Mailglass.Webhook.WebhookEvent

  @endpoint Mailglass.SchemaPrefixHardeningTest.TestEndpoint
  # A SCRATCH schema name unique to this module — NEVER the live schema
  # `Mailglass.Config.schema/0` resolves to, and never "public". Until the 143
  # gap-closure pass this was the literal "mailglass", which is harmless on the
  # default `public` axis (disjoint from the baseline) but IS the live baseline
  # schema under `MAILGLASS_SCHEMA=mailglass` — so the setup below CASCADE-
  # dropped the migration baseline out from under the rest of the run, surfacing
  # as 42P01 in unrelated victim modules hundreds of tests later. Naming
  # precedent: `mailglass_shipped_path_test` in
  # test/mailglass/shipped_migration_divergence_test.exs. The
  # `SandboxOwnership.scratch_schema!/2` call in `setup` enforces this
  # structurally, so re-typing "mailglass" here raises at THIS module.
  #
  # The proof this file carries is unaffected by the rename: it asserts that
  # runtime writes land in the CONFIGURED schema (whatever it is spelled) and
  # not in `public`, with the connection's search_path forced to `public`.
  @prefix "mailglass_prefix_hardening_test"
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

    @prefix "mailglass_prefix_hardening_test"

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
    # Registered FIRST, so it runs LAST (`on_exit` is reverse-registration
    # order) — the whole-env restore must land after `with_schema!/1`'s own
    # narrower `:schema` restore, not before it, or it would put back the env
    # this module captured and then be overwritten. It restores exactly,
    # including REMOVING `:compliance` and this module's `TestEndpoint` key,
    # neither of which appears in any `config/*.exs`; the previous
    # `Application.put_all_env/1` merged and so left both behind. See
    # `SandboxOwnership.with_app_env!/2`.
    SandboxOwnership.with_app_env!(:mailglass)

    # FIRST, before `with_schema!/1` below: assert @prefix is genuinely scratch.
    # Ordering is load-bearing — `with_schema!/1` makes Config.schema/0 return
    # @prefix, after which this guard could no longer observe the schema the rest
    # of the suite needs. See `SandboxOwnership.scratch_schema!/2`'s own docs.
    prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)

    # Registered BEFORE `with_schema!/1` so it runs AFTER that restore
    # (`on_exit` runs in reverse registration order) — the baseline must be
    # verified against the BOOT schema, not against this module's own override.
    # Read-only: it observes and names, it never restores (D-31).
    on_exit(fn -> SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__) end)

    # 143-MECHANISM.md § "The three-class inventory" names this file as a
    # candidate for BOTH Class B (config_schema_drift — flips Config.schema()
    # per-test) and Class A (baseline_missing — drops/restores public.
    # mailglass_* tables). Class B is closed here via the restore-first
    # `with_schema!/2` seam (143-07); Class A is closed by the scratch-prefix
    # rename above, which means this module no longer touches the baseline at
    # all — verified on every test by the `assert_baseline_intact!/2` registered
    # immediately above.
    with_schema!(prefix)

    Application.put_env(:mailglass, TestEndpoint, endpoint_config())
    Application.put_env(:mailglass, :compliance, compliance_config())

    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
      end)

    Tenancy.put_current(@tenant_id)

    on_exit(fn ->
      # The `RESET` this block used to issue is GONE, not merely moved. It was
      # documented as harmless belt-and-braces, but it was its own pool checkout
      # landing on an arbitrary connection — it could neither be relied on nor
      # read as evidence that no connection was poisoned, which is precisely the
      # "reads as a guarantee, is not one" shape this phase exists to remove.
      # The actual guarantee is `SandboxOwnership.with_search_path!/3`'s
      # same-connection, verified restore. Its removal was confirmed
      # non-load-bearing empirically: both CI seeds stay green on both axes
      # without it.
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])
      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext SCHEMA public")

      :persistent_term.erase({Mailglass.Config, :schema})

      # No baseline restoration happens here, and none is needed: the DROP above
      # targets this module's own scratch schema, which no other module or axis
      # ever uses. The previous version of this file dropped the literal
      # "mailglass" — the live baseline under MAILGLASS_SCHEMA=mailglass — and
      # then re-migrated it from here. Not dropping the baseline in the first
      # place removes the whole failure mode instead of trying to undo it, and
      # it also removes this teardown's `DELETE FROM public.schema_migrations
      # WHERE version < 100`, a global mutation every test in this file used to
      # perform. The `assert_baseline_intact!/2` registered at the top of
      # `setup` (so it runs LAST, after the Application-env restore above)
      # verifies the baseline on every test.
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

    result =
      with_public_search_path!(fn ->
        assert {:ok, result} =
                 Replay.execute(%{
                   tenant_id: @tenant_id,
                   webhook_event_id: webhook_event.id,
                   delivery_id: delivery.id,
                   actor: %{subject_id: "schema-prefix-proof"}
                 })

        result
      end)

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

    {first, second} =
      with_public_search_path!(fn ->
        {post(build_conn(), "/mailglass/unsubscribe/#{token}", %{}),
         post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})}
      end)

    assert response(first, 200) == ""
    assert response(second, 200) == ""

    assert_configured_unsubscribe_event_count!(delivery.id, 1)
    assert_public_unsubscribe_event_count!(delivery.id, 0)
    assert_configured_unsubscribe_suppression_count!(delivery, 1)
    assert_public_unsubscribe_suppression_count!(delivery, 0)
  end

  test "unsubscribe raw conflict lookup passes explicit configured-schema opts" do
    source = File.read!("lib/mailglass/compliance/unsubscribe_convergence.ex")

    assert source =~ "repo.one(query, Repo.multi_opts())"
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

  # Routes this file's ONE legitimate `search_path` override through the
  # sanctioned seam rather than issuing the SQL here. The seam pins one pooled
  # connection for the whole block, restores the prior value on that same
  # connection, and re-reads it to verify the restore landed — see
  # `SandboxOwnership.with_search_path!/3`'s own docs for the full mechanism
  # (session-level `SET` poisons a pooled connection; the next unrelated test to
  # draw it fails with 42P01). `Mailglass.Credo.NoRawSearchPathMutation` fails
  # the build if this is ever re-typed as raw SQL here.
  defp with_public_search_path!(fun) when is_function(fun, 0) do
    SandboxOwnership.with_search_path!("public", fun, repo: TestRepo, caller: __MODULE__)
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

  # Rule 1 fix (143-07): under the CI schema-isolation axis
  # (MAILGLASS_SCHEMA=mailglass), `public.mailglass_deliveries` does not
  # exist at all when this test runs before anything else has transiently
  # created it — a stronger form of "the row is not in public" than an
  # empty table, not a failure. A raw `TestRepo.query!` against a missing
  # relation raises 42P01 instead of asserting anything; check existence
  # first, matching `schema_isolation_integration_test.exs`'s
  # `public_table_exists?/1` pattern.
  defp assert_public_delivery_absent!(delivery_id) do
    assert public_delivery_count(delivery_id) == 0
  end

  defp public_delivery_count(delivery_id) do
    if public_table_exists?("mailglass_deliveries") do
      %{rows: [[count]]} =
        TestRepo.query!(
          """
          SELECT COUNT(*)
          FROM public.mailglass_deliveries
          WHERE id = $1
          """,
          [Ecto.UUID.dump!(delivery_id)]
        )

      count
    else
      0
    end
  end

  defp public_table_exists?(table) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
        """,
        [table]
      )

    rows != []
  end

  defp assert_configured_unsubscribe_event_count!(delivery_id, expected_count) do
    assert unsubscribe_event_count(@prefix, delivery_id) == expected_count
  end

  defp assert_public_unsubscribe_event_count!(delivery_id, expected_count) do
    assert unsubscribe_event_count("public", delivery_id) == expected_count
  end

  defp assert_configured_unsubscribe_suppression_count!(delivery, expected_count) do
    assert unsubscribe_suppression_count(@prefix, delivery) == expected_count
  end

  defp assert_public_unsubscribe_suppression_count!(delivery, expected_count) do
    assert unsubscribe_suppression_count("public", delivery) == expected_count
  end

  # Rule 1 fix (143-07): same "table may not exist under the mailglass axis"
  # reasoning as `assert_public_delivery_absent!/1` above — only applies to
  # the "public" branch, since `@prefix` (the configured schema) always
  # exists by the time these tests run.
  defp unsubscribe_event_count(schema, delivery_id) when schema in [@prefix, "public"] do
    if schema == "public" and not public_table_exists?("mailglass_events") do
      0
    else
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
  end

  defp unsubscribe_suppression_count(schema, delivery) when schema in [@prefix, "public"] do
    if schema == "public" and not public_table_exists?("mailglass_suppressions") do
      0
    else
      %{rows: [[count]]} =
        TestRepo.query!(
          """
          SELECT COUNT(*)
          FROM #{schema}.mailglass_suppressions
          WHERE tenant_id = $1
            AND address = $2
            AND scope = 'address_stream'
            AND stream = $3
            AND reason = 'unsubscribe'
          """,
          [delivery.tenant_id, String.downcase(delivery.recipient), Atom.to_string(delivery.stream)]
        )

      count
    end
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
end
