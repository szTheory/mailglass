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
        Mix.raise(
          "Installation blocked: --repair-legacy is not available until Plan 155-04; no migration was written"
        )

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
    prior_version = validate_prior_version!(spec, from)
    path = migration_path(repo, spec.upgrade_suffix, options)
    write_new!(path, upgrade_source(spec, repo, prior_version))
    Mix.shell().info("created #{path}")
  end

  defp validate_prior_version!(_spec, nil),
    do: Mix.raise("Installation blocked: --upgrade requires --from VERSION")

  defp validate_prior_version!(spec, from) do
    case Integer.parse(from) do
      {version, ""} ->
        initial_version = spec.initial_version.()
        current_version = spec.current_version.()

        cond do
          version == 0 ->
            Mix.raise(
              "Installation blocked: --upgrade --from 0 means no package anchor exists; run initial generation without --upgrade"
            )

          version < initial_version or version >= current_version ->
            Mix.raise(
              "Installation blocked: no offline upgrade is available from #{version}; choose a version from #{initial_version} through #{current_version - 1}"
            )

          true ->
            version
        end

      _ ->
        Mix.raise("Installation blocked: --from must be an integer package schema version")
    end
  end

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

  defp migration_module(repo, suffix), do: Module.concat([repo, Migrations, suffix])
end
