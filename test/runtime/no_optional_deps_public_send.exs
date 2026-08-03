defmodule Mailglass.NoOptionalDepsPublicSendProbe do
  @moduledoc false

  alias Mailglass.Message
  alias Mailglass.Outbound.{Delivery, Payload, PayloadPruner}
  require Logger

  @public_tables ~w(mailglass_suppressions mailglass_deliveries mailglass_events mailglass_outbound_payloads)

  defmodule Repo do
    use Ecto.Repo,
      otp_app: :mailglass,
      adapter: Ecto.Adapters.Postgres
  end

  def run do
    %{build_root: build_root, ebins: ebins, optional_apps: optional_apps} = manifests!()

    audit_code_path!(build_root, ebins)
    audit_optional_apps!(optional_apps)
    audit_absent_modules!()
    audit_optional_source_boundaries!()

    scratch_schema = scratch_schema!()
    configure!(scratch_schema)
    start_runtime!()
    public_before = public_snapshot!()
    migration_version = System.system_time(:microsecond)

    try do
      migrate!(migration_version)

      :ok = Mailglass.Adapters.Fake.checkout()
      before = observations!()

      message =
        Swoosh.Email.new()
        |> Swoosh.Email.from({"Runtime Probe", "from@example.com"})
        |> Swoosh.Email.to("no-optional-runtime@example.com")
        |> Swoosh.Email.subject("No optional dependency proof")
        |> Swoosh.Email.html_body("<p>body</p>")
        |> Swoosh.Email.text_body("body")
        |> Message.build(stream: :transactional)

      result = Mailglass.Outbound.deliver_later(message, async_adapter: :oban)

      unless match?(
               {:error,
                %Mailglass.SendError{
                  type: :adapter_failure,
                  context: %{reason_class: :dependency_unavailable}
                }},
               result
             ) do
        raise "expected typed dependency_unavailable result, got: #{inspect(result)}"
      end

      after_observations = observations!()

      unless before == after_observations do
        raise "dependency-free send caused durable, queue, provider, or task effects: " <>
                "before=#{inspect(before)} after=#{inspect(after_observations)}"
      end

      prove_payload_pruning_without_oban!()
      assert_public_snapshot!(public_before)

      IO.puts("no-optional-deps public send runtime proof passed")
    after
      cleanup_scratch!(scratch_schema, migration_version)
    end
  end

  defp manifests! do
    build_root = required_env!("MAILGLASS_NO_OPTIONAL_BUILD_ROOT") |> Path.expand()

    ebins =
      required_env!("MAILGLASS_NO_OPTIONAL_EBINS")
      |> String.split(":", trim: true)
      |> Enum.map(&Path.expand/1)
      |> MapSet.new()

    optional_apps =
      required_env!("MAILGLASS_NO_OPTIONAL_APPS")
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_atom/1)

    if MapSet.size(ebins) == 0 or optional_apps == [] or not Enum.member?(optional_apps, :oban) do
      raise "runtime manifests are incomplete"
    end

    Enum.each(ebins, &assert_under_build_root!(&1, build_root))
    %{build_root: build_root, ebins: ebins, optional_apps: optional_apps}
  end

  defp audit_code_path!(build_root, ebins) do
    Enum.each(:code.get_path(), fn path ->
      path = List.to_string(path) |> Path.expand()

      if Path.basename(path) == "ebin" and not standard_library_ebin?(path) do
        unless MapSet.member?(ebins, path) do
          raise "direct launcher exposed unmanifested ebin: #{path}"
        end

        assert_under_build_root!(path, build_root)
      end
    end)
  end

  defp audit_optional_apps!(apps) do
    Enum.each(apps, fn app ->
      case :code.lib_dir(app) do
        {:error, :bad_name} -> :ok
        {:error, _} -> :ok
        path -> raise "optional application is discoverable: #{app} at #{List.to_string(path)}"
      end
    end)
  end

  defp audit_absent_modules! do
    for module <- [Oban, Oban.Worker, Mailglass.Outbound.Worker] do
      if Code.ensure_loaded?(module), do: raise("optional module is loadable: #{inspect(module)}")
    end

    if Mailglass.Outbound.PayloadPrunerWorker.available?() do
      raise "optional payload pruner worker is available without Oban"
    end
  end

  defp audit_optional_source_boundaries! do
    repo_root = required_env!("MAILGLASS_NO_OPTIONAL_REPO_ROOT")

    guarded_oban_files =
      MapSet.new([
        "lib/mailglass.ex",
        "lib/mailglass/adapters/fake.ex",
        "lib/mailglass/adapters/fake/storage.ex",
        "lib/mailglass/application.ex",
        "lib/mailglass/config.ex",
        "lib/mailglass/events.ex",
        "lib/mailglass/events/reconciler.ex",
        "lib/mailglass/installer/plan.ex",
        "lib/mailglass/installer/templates.ex",
        "lib/mailglass/migrations/postgres/v01.ex",
        "lib/mailglass/optional_deps.ex",
        "lib/mailglass/optional_deps/oban.ex",
        "lib/mailglass/outbound.ex",
        "lib/mailglass/outbound/payload_pruner_worker.ex",
        "lib/mailglass/outbound/worker.ex",
        "lib/mailglass/production_preflight.ex",
        "lib/mailglass/suppression/escalation.ex",
        "lib/mailglass/tenancy.ex",
        "lib/mailglass/webhook/ingest.ex",
        "lib/mailglass/webhook/pruner.ex",
        "lib/mailglass/webhook/reconciler.ex",
        "lib/mailglass/webhook/router.ex",
        "lib/mix/tasks/mailglass.docs.check.ex",
        "lib/mix/tasks/mailglass.gen.inbound_route.ex",
        "lib/mix/tasks/mailglass.gen.inbound_router.ex",
        "lib/mix/tasks/mailglass.gen.mailable.ex",
        "lib/mix/tasks/mailglass.gen.mailbox.ex",
        "lib/mix/tasks/mailglass.install.ex",
        "lib/mix/tasks/mailglass.outbound.payloads.prune.ex",
        "lib/mix/tasks/mailglass.preflight.ex",
        "lib/mix/tasks/mailglass.reconcile.ex",
        "lib/mix/tasks/mailglass.upgrade.v0_2.ex",
        "lib/mix/tasks/mailglass.webhooks.prune.ex"
      ])

    repo_root
    |> Path.join("lib/**/*.ex")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      relative = Path.relative_to(path, repo_root)

      if File.read!(path) =~ ~r/\bOban(?:\.Worker|\.Job|\.)?\b/ and
           not MapSet.member?(guarded_oban_files, relative) do
        raise "unguarded Oban reference in #{relative}"
      end
    end)
  end

  defp configure!(scratch_schema) do
    config_path = Path.join(required_env!("MAILGLASS_NO_OPTIONAL_REPO_ROOT"), "config/config.exs")
    config = Config.Reader.read!(config_path, env: :test)

    Enum.each(config, fn {app, entries} ->
      Enum.each(entries, fn {key, value} -> Application.put_env(app, key, value) end)
    end)

    Application.put_env(:swoosh, :api_client, false)
    Application.put_env(:mailglass, :schema, scratch_schema)
    Logger.configure(level: :warning)

    repo_config =
      Application.fetch_env!(:mailglass, Mailglass.TestRepo)
      |> Keyword.put(:pool, DBConnection.ConnectionPool)

    Application.put_env(:mailglass, Repo, repo_config)
    Application.put_env(:mailglass, :repo, Repo)
  end

  defp start_runtime! do
    # Starting :mailglass through Application.ensure_all_started/1 would also
    # start Swoosh's configured HTTP-client application. The proof only needs
    # Mailglass's local supervisor closure and Ecto; start those explicitly so
    # the public fail-closed branch cannot be masked by transport boot wiring.
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    {:ok, _} = Application.ensure_all_started(:mix)
    {:ok, _} = Mailglass.Application.start(:normal, [])
    {:ok, _} = Repo.start_link()
  end

  defp migrate!(version) do
    case Ecto.Migrator.up(Repo, version, __MODULE__.Migration, log: false) do
      :ok -> :ok
      :already_up -> raise "isolated migration version collision: #{version}"
    end
  end

  defp scratch_schema! do
    schema = "mailglass_no_optional_#{System.unique_integer([:positive])}"
    validate_identifier!(schema)
    schema
  end

  defp cleanup_scratch!(schema, version) do
    validate_identifier!(schema)
    Repo.query!("DROP SCHEMA IF EXISTS #{inspect(schema)} CASCADE")
    Repo.query!("DELETE FROM public.schema_migrations WHERE version = $1", [version])
  end

  defp public_snapshot! do
    catalog =
      Repo.query!("""
      SELECT c.relname, c.relkind, pg_catalog.obj_description(c.oid, 'pg_class')
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname LIKE 'mailglass_%'
      ORDER BY c.relname, c.relkind
      """).rows

    counts =
      for table <- @public_tables do
        case Repo.query!("SELECT to_regclass($1)", ["public.#{table}"]).rows do
          [[nil]] ->
            {table, :missing}

          [[_relation]] ->
            %{rows: [[count]]} = Repo.query!("SELECT COUNT(*) FROM public.#{table}")
            {table, count}
        end
      end

    %{catalog: catalog, counts: counts}
  end

  defp assert_public_snapshot!(snapshot) do
    if public_snapshot!() != snapshot do
      raise "isolated no-optional runtime mutated the configured public catalog or rows"
    end
  end

  defp prove_payload_pruning_without_oban! do
    tenant_id = "runtime-prune-#{System.unique_integer([:positive])}"
    private_sentinel = "runtime-private-prune-sentinel@example.com"
    payload = expired_payload!(tenant_id, private_sentinel)

    case PayloadPruner.prune(tenant_id: tenant_id) do
      {:ok, 1} -> :ok
      _other -> raise "non-Oban payload pruner did not transition exactly one tenant batch"
    end

    mix_payload = expired_payload!(tenant_id, private_sentinel)

    output =
      capture_mix_output!(fn ->
        Mix.Tasks.Mailglass.Outbound.Payloads.Prune.run(["--tenant", tenant_id])
      end)

    expired = Mailglass.Repo.get(Payload, payload.id)
    mix_expired = Mailglass.Repo.get(Payload, mix_payload.id)

    unless expired.lifecycle_state == :expired and is_nil(expired.envelope) and
             mix_expired.lifecycle_state == :expired and is_nil(mix_expired.envelope) do
      raise "non-Oban payload pruner did not retain an expired tombstone"
    end

    unless output =~ "expired=1" and output =~ "retention_expired=1" do
      raise "manual payload pruner did not report aggregate state/reason counts: #{inspect(output)}"
    end

    if output =~ tenant_id or output =~ private_sentinel do
      raise "manual payload pruner leaked tenant or private payload data: #{inspect(output)}"
    end
  end

  defp expired_payload!(tenant_id, recipient) do
    now = DateTime.utc_now()

    {:ok, delivery} =
      %Delivery{}
      |> Delivery.changeset(%{
        tenant_id: tenant_id,
        mailable: "RuntimeProbe",
        stream: :transactional,
        recipient: recipient,
        last_event_type: :queued,
        last_event_at: now
      })
      |> Mailglass.Repo.insert()

    {:ok, payload} =
      Payload.changeset(%Payload{}, %{
        tenant_id: tenant_id,
        delivery_id: delivery.id,
        envelope_version: 2,
        envelope_digest: "runtime-prune-digest",
        envelope: %{"private" => "runtime-private-prune-sentinel"},
        lifecycle_state: :terminal,
        reason_class: :pre_dispatch_failure,
        expires_at: DateTime.add(now, -1, :second)
      })
      |> Mailglass.Repo.insert()

    payload
  end

  defp capture_mix_output!(fun) do
    prior_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    try do
      fun.()

      receive do
        {:mix_shell, :info, [message]} when is_binary(message) -> message
      after
        1_000 -> raise "manual payload pruner produced no Mix output"
      end
    after
      Mix.shell(prior_shell)
    end
  end

  defp observations! do
    schema = Mailglass.Config.schema()
    validate_identifier!(schema)

    %{
      deliveries: count!("#{schema}.mailglass_deliveries"),
      events: count!("#{schema}.mailglass_events"),
      payloads: count!("#{schema}.mailglass_outbound_payloads"),
      oban_jobs: oban_jobs_observation!(),
      fake_deliveries: length(Mailglass.Adapters.Fake.deliveries()),
      task_children: Task.Supervisor.children(Mailglass.TaskSupervisor)
    }
  end

  defp count!(qualified_table) do
    {:ok, %{rows: [[count]]}} = Repo.query("SELECT COUNT(*) FROM #{qualified_table}")
    count
  end

  defp oban_jobs_observation! do
    {:ok, %{rows: [[table]]}} = Repo.query("SELECT to_regclass('public.oban_jobs')")

    case table do
      nil -> :missing
      _ -> count!("public.oban_jobs")
    end
  end

  defp standard_library_ebin?(path) do
    otp_lib = :code.lib_dir(:kernel) |> List.to_string() |> Path.dirname() |> Path.dirname()
    elixir_lib = :code.lib_dir(:elixir) |> List.to_string() |> Path.expand() |> Path.dirname()

    path == otp_lib or String.starts_with?(path, otp_lib <> "/") or
      path == elixir_lib or String.starts_with?(path, elixir_lib <> "/")
  end

  defp assert_under_build_root!(path, build_root) do
    unless path == build_root or String.starts_with?(path, build_root <> "/") do
      raise "path escapes isolated build root: #{path}"
    end
  end

  defp validate_identifier!(identifier) do
    unless String.match?(identifier, ~r/^[a-z_][a-z0-9_]*$/) do
      raise "unsafe configured schema identifier"
    end
  end

  defp required_env!(key) do
    case System.get_env(key) do
      value when is_binary(value) and value != "" -> value
      _ -> raise "missing required runtime manifest: #{key}"
    end
  end

  defmodule Migration do
    use Ecto.Migration

    def up, do: Mailglass.Migration.up(repo: Mailglass.NoOptionalDepsPublicSendProbe.Repo)
  end
end

Mailglass.NoOptionalDepsPublicSendProbe.run()
