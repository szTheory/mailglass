defmodule Mailglass.Migration do
  @moduledoc """
  Public migration API for mailglass.

  Adopters consume this via a single 8-line wrapper file that
  `mix mailglass.gen.migration` (Phase 7) emits:

      defmodule MyApp.Repo.Migrations.AddMailglass do
        use Ecto.Migration
        def up, do: Mailglass.Migration.up()
        def down, do: Mailglass.Migration.down()
      end

  The wrapper stays stable across mailglass versions; per-version DDL
  lives in `Mailglass.Migrations.Postgres.VNN` modules, dispatched by
  `Mailglass.Migrations.Postgres` tracking the current version in the
  `pg_class` comment on `mailglass_events`.

  Postgres-only at v0.1 per PROJECT.md (MySQL/SQLite out of scope).
  """

  @doc "Runs all pending migrations up to the latest version."
  @doc since: "0.1.0"
  @spec up(keyword()) :: :ok
  def up(opts \\ []) when is_list(opts) do
    migrator().up(opts)
  end

  @doc "Rolls back migrations down to the target version (default: 0)."
  @doc since: "0.1.0"
  @spec down(keyword()) :: :ok
  def down(opts \\ []) when is_list(opts) do
    migrator().down(opts)
  end

  @doc "Returns the currently-applied migration version (0 if none)."
  @doc since: "0.1.0"
  @spec migrated_version(keyword()) :: non_neg_integer()
  def migrated_version(opts \\ []) when is_list(opts) do
    migrator().migrated_version(opts)
  end

  # Resolves the version dispatcher based on the configured Repo's adapter.
  # Postgres-only at v0.1 per PROJECT.md — MySQL/SQLite are out of scope.
  defp migrator do
    repo =
      case Application.get_env(:mailglass, :repo) do
        nil -> raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})
        mod when is_atom(mod) -> mod
      end

    case repo.__adapter__() do
      Ecto.Adapters.Postgres ->
        Mailglass.Migrations.Postgres

      other ->
        raise Mailglass.ConfigError.new(:invalid,
                context: %{key: :repo, adapter: other, reason: "Postgres only at v0.1"}
              )
    end
  end
end
