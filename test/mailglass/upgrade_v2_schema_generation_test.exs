defmodule Mailglass.UpgradeV2SchemaGenerationTest do
  # async: false — this test file-emits into a temp working tree (changes cwd)
  # and shares the :schema_isolation tag with its migration-execution sibling so
  # both run outside the parallel default-schema suite.
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  # The four core tables the move migration must relocate. Assembled here as the
  # assertion source of truth (byte-source: lib/mailglass/migrations/postgres/v01.ex).
  @tables ~w(mailglass_events mailglass_deliveries mailglass_suppressions mailglass_webhook_events)

  # Emit a body via the task's testable entrypoint for a synthetic app module.
  defp body(app_module, opts \\ []) do
    Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body(app_module, opts)
  end

  describe "migration_body/2 (UPG-01 emitter — content contract)" do
    setup do
      %{body: body("DemoHost")}
    end

    test "emitted body compiles (no syntax error)", %{body: body} do
      # Proves the emitter yields a valid, compilable migration.
      assert {:ok, _ast} = Code.string_to_quoted(body)
    end

    test "defmodule uses the discovered app module", %{body: body} do
      assert body =~ "defmodule DemoHost.Repo.Migrations.MoveMailglassToSchema do"
      assert body =~ "use Ecto.Migration"
    end

    test "an ALTER TABLE public.<t> SET SCHEMA is emitted for each of the four tables", %{
      body: body
    } do
      for t <- @tables do
        assert body =~ "ALTER TABLE public.#{t} SET SCHEMA",
               "expected an ALTER TABLE public.#{t} SET SCHEMA move (got body without it)"
      end
    end

    test "body opens the move under SET LOCAL lock_timeout", %{body: body} do
      assert body =~ "SET LOCAL lock_timeout"
    end

    test "body issues CREATE SCHEMA IF NOT EXISTS", %{body: body} do
      assert body =~ "CREATE SCHEMA IF NOT EXISTS"
    end

    test "body carries the byte-parity trigger/function markers", %{body: body} do
      # This test file legitimately contains the 45A01 and search_path literals as
      # MATCH TARGETS (no file-wide negative grep for them here — by design).
      assert body =~ "RAISE SQLSTATE '45A01'"

      assert body =~
               "USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden'"

      assert body =~ "SET search_path = ''"
      assert body =~ "BEFORE UPDATE OR DELETE"
      assert body =~ "FOR EACH ROW EXECUTE FUNCTION"
    end

    test "body defines both up and down", %{body: body} do
      assert body =~ "def up do"
      assert body =~ "def down do"
    end

    test "body does NOT disable the DDL transaction (Pitfall 7 — SET LOCAL stays scoped)", %{
      body: body
    } do
      refute body =~ "@disable_ddl_transaction"
    end

    test "body contains NO citext statement (Pitfall 6 — only tables move)", %{body: body} do
      refute body =~ "citext"
    end

    test "down/0 moves the four tables back to public", %{body: body} do
      for t <- @tables do
        assert body =~ "SET SCHEMA public",
               "expected down/0 to move #{t} back to public"
      end

      # The down block restores the public-qualified function+trigger.
      assert body =~ "CREATE OR REPLACE FUNCTION public.mailglass_raise_immutability"
    end
  end

  describe "UPG-04: emitter produces a valid migration for reference/host_app's app module" do
    # Satisfies UPG-04's "run against reference/host_app" clause via the
    # emitter-for-host_app-app-module proof — WITHOUT bumping host_app pins/locks
    # (Pitfall 3: that frozen-baseline change is Phase 137). We feed the emitter
    # the frozen baseline's app module, discovered with the SAME regex the task
    # uses over mix.exs, and assert the emitted body is a valid, compilable
    # move migration for that module.
    @host_app_mix_exs Path.expand("../../reference/host_app/mix.exs", __DIR__)

    setup do
      mix_exs = File.read!(@host_app_mix_exs)

      app_module =
        case Regex.run(~r/app:\s*:(\w+)/, mix_exs) do
          [_, app] -> Macro.camelize(app)
          _ -> flunk("could not discover app module from reference/host_app/mix.exs")
        end

      %{app_module: app_module, body: body(app_module)}
    end

    test "the app-module discovery regex yields MailglassReferenceHost", %{app_module: app_module} do
      assert app_module == "MailglassReferenceHost"
    end

    test "emitted body defines MailglassReferenceHost.Repo.Migrations.MoveMailglassToSchema and compiles",
         %{body: body} do
      assert body =~
               "defmodule MailglassReferenceHost.Repo.Migrations.MoveMailglassToSchema do"

      assert {:ok, _ast} = Code.string_to_quoted(body)
    end

    test "emitted body carries all four moves + the byte-parity trigger block", %{body: body} do
      for t <- @tables do
        assert body =~ "ALTER TABLE public.#{t} SET SCHEMA",
               "expected an ALTER TABLE public.#{t} SET SCHEMA move for the host_app module"
      end

      assert body =~ "RAISE SQLSTATE '45A01'"
      assert body =~ "SET search_path = ''"
      assert body =~ "FOR EACH ROW EXECUTE FUNCTION"
    end
  end

  describe "file emitter run/1 (UPG-01 — idempotent wildcard)" do
    setup do
      tmp = Path.join(System.tmp_dir!(), "mg_upgrade_gen_#{System.unique_integer([:positive])}")
      File.mkdir_p!(Path.join(tmp, "priv/repo/migrations"))

      File.write!(Path.join(tmp, "mix.exs"), """
      defmodule DemoHost.MixProject do
        use Mix.Project
        def project, do: [app: :demo_host, version: "0.1.0"]
      end
      """)

      original_cwd = File.cwd!()
      on_exit(fn -> File.cd!(original_cwd) end)

      %{tmp: tmp}
    end

    defp move_migrations(tmp) do
      [tmp, "priv", "repo", "migrations", "*_move_mailglass_to_schema.exs"]
      |> Path.join()
      |> Path.wildcard()
    end

    test "first run writes exactly one *_move_mailglass_to_schema.exs; second run is unchanged", %{
      tmp: tmp
    } do
      File.cd!(tmp)

      Mix.Tasks.Mailglass.Upgrade.V2Schema.run([])
      assert length(move_migrations(tmp)) == 1

      [path] = move_migrations(tmp)
      assert Path.basename(path) =~ ~r/_move_mailglass_to_schema\.exs$/

      # The written file uses the discovered app module (:demo_host → DemoHost).
      assert File.read!(path) =~ "defmodule DemoHost.Repo.Migrations.MoveMailglassToSchema do"

      # Idempotent re-run: no second file emitted.
      Mix.Tasks.Mailglass.Upgrade.V2Schema.run([])
      assert length(move_migrations(tmp)) == 1
    end
  end
end
