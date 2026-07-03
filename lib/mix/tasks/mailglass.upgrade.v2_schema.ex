defmodule Mix.Tasks.Mailglass.Upgrade.V2Schema do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  @shortdoc "Generate the 2.0 schema-isolation move migration"

  @moduledoc """
  Generates a Route B move migration that relocates mailglass's four core tables
  from `public` into a dedicated `mailglass` schema — the recommended upgrade path
  for adopters running the 1.x `public` install who are moving to mailglass 2.0.

  The emitted migration is metadata-only and transactional:

    * `SET LOCAL lock_timeout = '5s'` so the move fails fast (SQLSTATE `55P03`)
      rather than queueing behind a long reader holding `ACCESS EXCLUSIVE` — retry
      `mix ecto.migrate` off-peak.
    * `CREATE SCHEMA IF NOT EXISTS "mailglass"`, then `ALTER TABLE public.<t> SET
      SCHEMA "mailglass"` for all four core tables (indexes, constraints, and
      sequences move with each table; the table comment survives the OID move).
    * the append-only immutability function does NOT move with the table (it is a
      distinct `pg_proc` object), so the migration drops and recreates it
      schema-qualified — byte-parity with the shipped fresh-install DDL, so a moved
      database is indistinguishable from a freshly-installed one.

  A working `down/0` reverses the move: it returns all four tables to `public` and
  restores the `public`-qualified function and trigger.

  The task is idempotent — re-running it prints `unchanged <path>` and does not
  emit a second migration.

      mix mailglass.upgrade.v2_schema

  Options:

    * `--schema <name>` — target schema (default `mailglass`). Validated as a
      Postgres unquoted identifier before it is interpolated into the migration.
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [schema: :string])

    if rest != [] or invalid != [] do
      Mix.raise("Upgrade blocked: unexpected args for mailglass.upgrade.v2_schema")
    end

    schema = opts[:schema] || "mailglass"
    # Never interpolate an unvalidated identifier into the emitted SQL — gate it
    # through the single unquoted-identifier chokepoint first.
    Mailglass.Identifier.validate!(schema, :schema)

    case existing_move_migration() do
      nil ->
        path =
          Path.join(["priv", "repo", "migrations", "#{timestamp()}_move_mailglass_to_schema.exs"])

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, migration_body(current_app_module(), schema: schema))

        Mix.shell().info("created #{path}")

      path ->
        Mix.shell().info("unchanged #{path}")
    end

    :ok
  end

  defp existing_move_migration do
    ["priv", "repo", "migrations", "*_move_mailglass_to_schema.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
    |> List.first()
  end

  defp timestamp do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  @doc """
  Returns the move-migration source for `app_module` as a string.

  Exposed so tests can assert the emitted body without a full filesystem run.
  Accepts `:schema` (default `"mailglass"`); the value is assumed pre-validated
  by `run/1` via `Mailglass.Identifier.validate!/2`.
  """
  @spec migration_body(String.t(), keyword()) :: String.t()
  def migration_body(app_module, opts \\ []) do
    schema = opts[:schema] || "mailglass"

    # Read the version marker at generation time so the emitted COMMENT stays
    # version-agnostic (A1 — never hard-code '5'). `ALTER TABLE … SET SCHEMA`
    # preserves obj_description, but we re-assert it explicitly after the move so
    # the moved DB reports its version even if a future PG changes that behavior
    # (T-136-04 — a lost marker would re-run v01..vNN into the moved schema).
    version = Mailglass.Migrations.Postgres.current_version()

    """
    defmodule #{app_module}.Repo.Migrations.MoveMailglassToSchema do
      use Ecto.Migration

      @schema "#{schema}"

      def up do
        execute "SET LOCAL lock_timeout = '5s'"
        execute ~s(CREATE SCHEMA IF NOT EXISTS "\#{@schema}")

        # Move each table explicitly (indexes/constraints/sequences move with it).
        execute ~s(ALTER TABLE public.mailglass_events SET SCHEMA "\#{@schema}")
        execute ~s(ALTER TABLE public.mailglass_deliveries SET SCHEMA "\#{@schema}")
        execute ~s(ALTER TABLE public.mailglass_suppressions SET SCHEMA "\#{@schema}")
        execute ~s(ALTER TABLE public.mailglass_webhook_events SET SCHEMA "\#{@schema}")

        # The immutability FUNCTION does not move with the table — recreate it qualified.
        execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON "\#{@schema}".mailglass_events)
        execute ~s|DROP FUNCTION IF EXISTS public.mailglass_raise_immutability()|

        execute \"\"\"
        CREATE OR REPLACE FUNCTION "\#{@schema}".mailglass_raise_immutability()
        RETURNS trigger
        LANGUAGE plpgsql
        SET search_path = ''
        AS $$
        BEGIN
          RAISE SQLSTATE '45A01'
            USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
        END;
        $$;
        \"\"\"

        execute \"\"\"
        CREATE TRIGGER mailglass_events_immutable_trigger
          BEFORE UPDATE OR DELETE ON "\#{@schema}".mailglass_events
          FOR EACH ROW EXECUTE FUNCTION "\#{@schema}".mailglass_raise_immutability();
        \"\"\"

        # Re-assert the version marker under the moved schema (defense-in-depth).
        execute ~s(COMMENT ON TABLE "\#{@schema}".mailglass_events IS '#{version}')
      end

      def down do
        execute "SET LOCAL lock_timeout = '5s'"

        # Move each table back to public explicitly.
        execute ~s(ALTER TABLE "\#{@schema}".mailglass_events SET SCHEMA public)
        execute ~s(ALTER TABLE "\#{@schema}".mailglass_deliveries SET SCHEMA public)
        execute ~s(ALTER TABLE "\#{@schema}".mailglass_suppressions SET SCHEMA public)
        execute ~s(ALTER TABLE "\#{@schema}".mailglass_webhook_events SET SCHEMA public)

        execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON public.mailglass_events)
        execute ~s|DROP FUNCTION IF EXISTS "\#{@schema}".mailglass_raise_immutability()|

        execute \"\"\"
        CREATE OR REPLACE FUNCTION public.mailglass_raise_immutability()
        RETURNS trigger
        LANGUAGE plpgsql
        SET search_path = ''
        AS $$
        BEGIN
          RAISE SQLSTATE '45A01'
            USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
        END;
        $$;
        \"\"\"

        execute \"\"\"
        CREATE TRIGGER mailglass_events_immutable_trigger
          BEFORE UPDATE OR DELETE ON public.mailglass_events
          FOR EACH ROW EXECUTE FUNCTION public.mailglass_raise_immutability();
        \"\"\"

        execute ~s(COMMENT ON TABLE public.mailglass_events IS '#{version}')

        # The tables are back in public and the schema is now empty — drop it
        # (RESTRICT, not CASCADE) so a reversed DB is indistinguishable from a
        # never-moved 1.x install. IF EXISTS keeps re-runs safe.
        execute ~s(DROP SCHEMA IF EXISTS "\#{@schema}")
      end
    end
    """
  end

  defp current_app_module do
    mix_exs = File.read!("mix.exs")

    case Regex.run(~r/app:\s*:(\w+)/, mix_exs) do
      [_, app] -> Macro.camelize(app)
      _ -> "Example"
    end
  end
end
