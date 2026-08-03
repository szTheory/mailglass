defmodule Mailglass.NoOptionalDepsPublicSendProbe do
  @moduledoc false

  alias Mailglass.{Message, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.{Delivery, Payload}

  def run do
    %{build_root: build_root, ebins: ebins, optional_apps: optional_apps} = manifests!()

    audit_code_path!(build_root, ebins)
    audit_optional_apps!(optional_apps)
    audit_absent_modules!()

    configure!()
    start_runtime!()
    migrate!()

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

    IO.puts("no-optional-deps public send runtime proof passed")
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
  end

  defp configure! do
    config_path = Path.join(required_env!("MAILGLASS_NO_OPTIONAL_REPO_ROOT"), "config/config.exs")
    config = Config.Reader.read!(config_path, env: :test)
    Application.put_all_env(config)

    repo_config =
      Application.fetch_env!(:mailglass, TestRepo)
      |> Keyword.put(:pool, DBConnection.ConnectionPool)

    Application.put_env(:mailglass, TestRepo, repo_config)
  end

  defp start_runtime! do
    {:ok, _} = Application.ensure_all_started(:mailglass)
    {:ok, _} = TestRepo.start_link()
  end

  defp migrate! do
    version = 20_260_803_150_009

    case Ecto.Migrator.up(TestRepo, version, __MODULE__.Migration, log: false) do
      :ok -> :ok
      :already_up -> :ok
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
    {:ok, %{rows: [[count]]}} = TestRepo.query("SELECT COUNT(*) FROM #{qualified_table}")
    count
  end

  defp oban_jobs_observation! do
    {:ok, %{rows: [[table]]}} = TestRepo.query("SELECT to_regclass('public.oban_jobs')")

    case table do
      nil -> :missing
      _ -> count!("public.oban_jobs")
    end
  end

  defp standard_library_ebin?(path) do
    otp_lib = :code.lib_dir(:kernel) |> List.to_string() |> Path.dirname() |> Path.dirname()
    elixir_lib = :code.lib_dir(:elixir) |> List.to_string() |> Path.dirname() |> Path.dirname()
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

    def up, do: Mailglass.Migration.up(repo: Mailglass.TestRepo)
  end
end

Mailglass.NoOptionalDepsPublicSendProbe.run()
