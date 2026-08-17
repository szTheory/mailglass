defmodule Mailglass.MigrationGenerator do
  @moduledoc false

  @type package_spec :: %{
          required(:task_name) => String.t(),
          required(:install_suffix) => String.t(),
          required(:upgrade_suffix) => String.t(),
          required(:install_module_suffix) => String.t(),
          required(:upgrade_module_suffix) => String.t(),
          required(:migration_module) => module(),
          required(:initial_version) => (-> pos_integer()),
          required(:current_version) => (-> pos_integer())
        }

  @spec run(package_spec(), [String.t()], keyword()) :: :ok
  def run(spec, argv, options \\ []) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [repo: :string, upgrade: :boolean, from: :string, repair_legacy: :boolean]
      )

    if rest != [] or invalid != [] do
      Mix.raise("Installation blocked: unexpected args for #{spec.task_name}")
    end

    repo = resolve_repo!(opts[:repo])

    cond do
      opts[:repair_legacy] ->
        generate_legacy_repair!(spec, repo, options)

      opts[:upgrade] ->
        generate_upgrade!(spec, repo, opts[:from], options)

      opts[:from] ->
        Mix.raise("Installation blocked: --from requires --upgrade")

      true ->
        generate_initial!(spec, repo, options)
    end
  end

  defp resolve_repo!(repo_text) do
    app = Mix.Project.config()[:app]
    repos = Application.get_env(app, :ecto_repos, [])

    case repo_text do
      nil ->
        case repos do
          [repo] when is_atom(repo) ->
            repo

          [] ->
            Mix.raise(
              "Installation blocked: no configured Ecto repos; pass --repo for a configured repo"
            )

          _ ->
            Mix.raise(
              "Installation blocked: exactly one configured Ecto repo is required; pass --repo"
            )
        end

      text ->
        case Enum.find(repos, &(is_atom(&1) and inspect(&1) == text)) do
          nil -> Mix.raise("Installation blocked: --repo #{text} is not configured for this host")
          repo -> repo
        end
    end
  end

  defp generate_initial!(spec, repo, options) do
    pattern = Path.join(migrations_path(repo), "*_#{spec.install_suffix}.exs")

    case pattern |> Path.wildcard() |> Enum.sort() |> List.first() do
      nil ->
        path = migration_path(repo, spec.install_suffix, options)
        write_new!(path, install_source(spec, repo))
        Mix.shell().info("created #{path}")

      path ->
        Mix.shell().info("unchanged #{path}")
    end
  end

  defp generate_upgrade!(spec, repo, from, options) do
    prior_version =
      case from do
        nil -> live_prior_version!(spec, repo, options)
        version -> validate_prior_version!(spec, version)
      end

    path = migration_path(repo, spec.upgrade_suffix, options)
    write_new!(path, upgrade_source(spec, repo, prior_version))
    Mix.shell().info("created #{path}")
  end

  defp generate_legacy_repair!(spec, repo, options) do
    app_module = Map.get(spec, :legacy_app_module, current_app_module())
    prefix = Map.get(spec, :legacy_prefix, "public")
    pattern = Path.join(migrations_path(repo), "*_#{spec.install_suffix}.exs")
    candidates = pattern |> Path.wildcard() |> Enum.sort()

    case candidates do
      [legacy_path] ->
        with_repo = Keyword.get(options, :with_repo, &Ecto.Migrator.with_repo/2)

        case with_repo.(repo, fn started_repo ->
               Mailglass.Migrations.LegacyToy.preflight!(
                 started_repo,
                 prefix,
                 legacy_path,
                 app_module
               )
             end) do
          {:ok, :ok, _started_apps} ->
            path = migration_path(repo, "mailglass_legacy_repair", options)
            write_new!(path, legacy_repair_source(repo, prefix))
            Mix.shell().info("created #{path}")

          {:error, reason} ->
            Mix.raise(
              "Installation blocked: legacy repo could not start (#{inspect(reason)}); no migration was written"
            )

          result ->
            Mix.raise(
              "Installation blocked: legacy preflight failed (#{inspect(result)}); no migration was written"
            )
        end

      [] ->
        Mix.raise("Installation blocked: legacy source is missing; no migration was written")

      _ ->
        Mix.raise(
          "Installation blocked: multiple legacy source candidates are ambiguous; no migration was written"
        )
    end
  end

  defp live_prior_version!(spec, repo, options) do
    with_repo = Keyword.get(options, :with_repo, &Ecto.Migrator.with_repo/2)

    case with_repo.(repo, fn started_repo ->
           spec.migration_module.migrated_version(repo: started_repo)
         end) do
      {:ok, version, _started_apps} when is_integer(version) ->
        validate_prior_version!(spec, version, :live)

      {:error, reason} ->
        Mix.raise("Installation blocked: could not inspect the selected repo: #{inspect(reason)}")

      result ->
        Mix.raise("Installation blocked: could not inspect the selected repo: #{inspect(result)}")
    end
  end

  defp validate_prior_version!(spec, from, source \\ :offline) do
    version =
      case from do
        version when is_integer(version) ->
          version

        text ->
          case Integer.parse(text) do
            {version, ""} -> version
            _ -> Mix.raise("Installation blocked: --from must be an integer package schema version")
          end
      end

    initial_version = spec.initial_version.()
    current_version = spec.current_version.()

    cond do
      version == 0 ->
        Mix.raise(absent_anchor_message(source))

      version < initial_version or version >= current_version ->
        Mix.raise(no_upgrade_message(source, version, initial_version, current_version))

      true ->
        version
    end
  end

  defp absent_anchor_message(:offline),
    do:
      "Installation blocked: --upgrade --from 0 means no package anchor exists; run initial generation without --upgrade"

  defp absent_anchor_message(:live),
    do: "Installation blocked: no package anchor exists; run initial generation without --upgrade"

  defp no_upgrade_message(:offline, version, initial_version, current_version),
    do:
      "Installation blocked: no offline upgrade is available from #{version}; choose a version from #{initial_version} through #{current_version - 1}"

  defp no_upgrade_message(:live, version, initial_version, current_version),
    do:
      "Installation blocked: no live upgrade is available from #{version}; choose a version from #{initial_version} through #{current_version - 1}"

  defp write_new!(path, source) do
    File.mkdir_p!(Path.dirname(path))

    case File.write(path, source, [:exclusive]) do
      :ok ->
        :ok

      {:error, :eexist} ->
        Mix.raise(
          "Installation blocked: migration timestamp collision at #{path}; no file was changed"
        )

      {:error, reason} ->
        Mix.raise("Installation blocked: could not write #{path}: #{:file.format_error(reason)}")
    end
  end

  defp migration_path(repo, suffix, options) do
    Path.join(migrations_path(repo), "#{timestamp(options)}_#{suffix}.exs")
  end

  defp migrations_path(repo), do: Ecto.Migrator.migrations_path(repo)

  defp timestamp(options) do
    case Keyword.fetch(options, :now) do
      {:ok, now} when is_function(now, 0) -> now.()
      :error -> DateTime.utc_now()
    end
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp install_source(spec, repo) do
    """
    defmodule #{inspect(migration_module(repo, spec.install_module_suffix))} do
      use Ecto.Migration

      def up, do: #{inspect(spec.migration_module)}.up()
      def down, do: #{inspect(spec.migration_module)}.down()
    end
    """
  end

  defp upgrade_source(spec, repo, prior_version) do
    """
    defmodule #{inspect(migration_module(repo, spec.upgrade_module_suffix))} do
      use Ecto.Migration

      def up, do: #{inspect(spec.migration_module)}.up()
      def down, do: #{inspect(spec.migration_module)}.down(version: #{prior_version})
    end
    """
  end

  defp legacy_repair_source(repo, prefix) do
    """
    defmodule #{inspect(migration_module(repo, "MailglassLegacyRepair"))} do
      use Ecto.Migration

      def up, do: Mailglass.Migration.repair_legacy_up(repo: #{inspect(repo)}, prefix: #{inspect(prefix)}, create_schema: false)
      def down, do: Mailglass.Migration.repair_legacy_down(repo: #{inspect(repo)}, prefix: #{inspect(prefix)}, create_schema: false)
    end
    """
  end

  defp current_app_module do
    Mix.Project.config()[:app]
    |> Atom.to_string()
    |> Macro.camelize()
  end

  defp migration_module(repo, suffix), do: Module.concat([repo, Migrations, suffix])
end
