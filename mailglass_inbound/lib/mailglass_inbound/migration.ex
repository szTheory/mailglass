defmodule MailglassInbound.Migration do
  @moduledoc """
  Public migration API for mailglass_inbound.

  Adopters consume this via a single 8-line wrapper file that
  `mix mailglass.inbound.gen.migration` emits:

      defmodule MyApp.Repo.Migrations.MailglassInboundInstall do
        use Ecto.Migration
        def up, do: MailglassInbound.Migration.up()
        def down, do: MailglassInbound.Migration.down()
      end

  The wrapper stays stable across mailglass_inbound versions; per-version DDL
  lives in `MailglassInbound.Migrations.Postgres.VNN` modules, dispatched by
  `MailglassInbound.Migrations.Postgres` tracking the current version in the
  `pg_class` comment on `mailglass_inbound_records`.

  Postgres-only at v2.0 per PROJECT.md (MySQL/SQLite out of scope).
  Inbound maintains its own independent version anchor — separate from core's
  `mailglass_events` anchor — so both packages can evolve independently even in
  a shared schema (D-07).
  """

  @doc "Runs all pending inbound migrations up to the latest version."
  @doc since: "2.0.0"
  @spec up(keyword()) :: :ok
  def up(opts \\ []) when is_list(opts) do
    # Inject the configured schema as the migration prefix (INB-02). Use
    # `Keyword.put_new` so an explicit caller `:prefix` (the test harness, or
    # an adopter running a targeted migration) still wins over the config
    # default. The dispatcher's `with_defaults/2` supplies "public" + identifier
    # validation downstream for callers who pass neither.
    opts = Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())
    migrator().up(opts)
  end

  @doc "Rolls back inbound migrations down to the target version (default: 0)."
  @doc since: "2.0.0"
  @spec down(keyword()) :: :ok
  def down(opts \\ []) when is_list(opts) do
    # Same runtime-prefix injection as `up/1` (INB-02) — explicit caller
    # `:prefix` wins via `Keyword.put_new`.
    opts = Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())
    migrator().down(opts)
  end

  @doc """
  Returns the currently-applied inbound migration version (0 if none).

  This function is safe to call outside an `Ecto.Migrator` context —
  unlike `up/1` / `down/1`, it does not rely on the migration runner
  process (it issues a single pg_class query against the configured Repo
  and returns an integer). Anchored on `mailglass_inbound_records`, not
  `mailglass_events` (D-07: independent version lines).
  """
  @doc since: "2.0.0"
  @spec migrated_version(keyword()) :: non_neg_integer()
  def migrated_version(opts \\ []) when is_list(opts) do
    # Inject the configured Repo so the dispatcher can run the version
    # query without needing an active `use Ecto.Migration` runner.
    opts = Keyword.put_new(opts, :repo, resolve_repo())
    migrator().migrated_version(opts)
  end

  # Resolves the version dispatcher based on the configured Repo's adapter.
  # Postgres-only at v2.0 per PROJECT.md — MySQL/SQLite are out of scope.
  defp migrator do
    case resolve_repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        MailglassInbound.Migrations.Postgres

      other ->
        raise RuntimeError,
              "mailglass_inbound only supports the Postgres adapter; got #{inspect(other)}"
    end
  end

  defp resolve_repo do
    case Application.get_env(:mailglass_inbound, :repo) do
      nil ->
        raise RuntimeError,
              "mailglass_inbound requires config :mailglass_inbound, :repo to resolve its host repo"

      mod when is_atom(mod) ->
        mod
    end
  end
end
