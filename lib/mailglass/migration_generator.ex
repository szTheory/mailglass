defmodule Mailglass.MigrationGenerator do
  @moduledoc false

  @type package_spec :: %{
          required(:task_name) => String.t(),
          required(:install_suffix) => String.t(),
          required(:install_module_suffix) => String.t(),
          required(:migration_module) => module(),
          required(:current_version) => (-> pos_integer())
        }

  @spec run(package_spec(), [String.t()]) :: :ok
  def run(spec, argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv, strict: [repo: :string])

    if rest != [] or invalid != [] do
      Mix.raise("Installation blocked: unexpected args for #{spec.task_name}")
    end

    repo = resolve_repo!(opts[:repo])

    generate_initial!(spec, repo)
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

  defp generate_initial!(spec, repo) do
    pattern = Path.join(migrations_path(repo), "*_#{spec.install_suffix}.exs")

    case pattern |> Path.wildcard() |> Enum.sort() |> List.first() do
      nil ->
        path = migration_path(repo, spec.install_suffix)
        write_new!(path, install_source(spec, repo))
        Mix.shell().info("created #{path}")

      path ->
        Mix.shell().info("unchanged #{path}")
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

  defp migration_path(repo, suffix) do
    Path.join(migrations_path(repo), "#{timestamp()}_#{suffix}.exs")
  end

  defp migrations_path(repo), do: Ecto.Migrator.migrations_path(repo)

  defp timestamp do
    DateTime.utc_now()
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

  defp migration_module(repo, suffix), do: Module.concat([repo, Migrations, suffix])
end
