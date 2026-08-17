defmodule Mailglass.Migration do
  @moduledoc """
  Public migration API for mailglass.

  Adopters consume this via a single 8-line wrapper file that
  `mix mailglass.gen.migration` emits:

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
    # Inject the configured schema as the migration prefix (MIGR-01). Use
    # `Keyword.put_new` so an explicit caller `:prefix` (the test harness, or
    # an adopter running a targeted migration) still wins over the config
    # default. The dispatcher's `with_defaults/2` supplies "public" + identifier
    # validation downstream for callers who pass neither.
    opts = Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
    migrator(opts).up(opts)
  end

  @doc "Rolls back migrations down to the target version (default: 0)."
  @doc since: "0.1.0"
  @spec down(keyword()) :: :ok
  def down(opts \\ []) when is_list(opts) do
    # Same runtime-prefix injection as `up/1` (MIGR-01) — explicit caller
    # `:prefix` wins via `Keyword.put_new`.
    opts = Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
    migrator(opts).down(opts)
  end

  @doc """
  Returns the currently-applied migration version (0 only when its anchor is absent).

  This function is safe to call outside an `Ecto.Migrator` context —
  unlike `up/1` / `down/1`, it does not rely on the migration runner
  process (it issues a single `pg_catalog.obj_description` query against
  the configured Repo and returns an integer). Raises
  `Mailglass.MigrationVersionError` when catalog metadata cannot be trusted.
  """
  @doc since: "0.1.0"
  @spec migrated_version(keyword()) :: non_neg_integer()
  def migrated_version(opts \\ []) when is_list(opts) do
    # Inject the configured schema as the query prefix (same MIGR-01 default
    # `up/1`/`down/1` already apply above) — an explicit caller `:prefix`
    # still wins via `Keyword.put_new`. Without this, a caller on a non-
    # default schema (e.g. the `mailglass` schema-isolation axis) silently
    # queried `public.mailglass_events`'s pg_class comment instead of the
    # configured schema's, always reporting 0 even when fully migrated.
    opts = Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
    # Inject the configured Repo so the dispatcher can run the version
    # query without needing an active `use Ecto.Migration` runner.
    opts = Keyword.put_new(opts, :repo, resolve_repo(opts))
    migrator(opts).migrated_version(opts)
  end

  # Resolves the version dispatcher based on the configured Repo's adapter.
  # Postgres-only at v0.1 per PROJECT.md — MySQL/SQLite are out of scope.
  defp migrator(opts) do
    case resolve_repo(opts).__adapter__() do
      Ecto.Adapters.Postgres ->
        Mailglass.Migrations.Postgres

      other ->
        raise Mailglass.ConfigError.new(:invalid,
                context: %{key: :repo, adapter: other, reason: "Postgres only at v0.1"}
              )
    end
  end

  defp resolve_repo(opts) do
    case Keyword.get(opts, :repo) || Application.get_env(:mailglass, :repo) do
      nil -> raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})
      mod when is_atom(mod) -> mod
    end
  end
end
