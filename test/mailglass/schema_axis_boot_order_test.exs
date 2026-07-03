defmodule Mailglass.SchemaAxisBootOrderTest do
  # FAIL-CLOSED boot-order proof for the CI schema matrix axis (Success
  # Criterion 7 / D-06). config/runtime.exs reads MAILGLASS_SCHEMA (test env) to
  # override `config :mailglass, :schema`, and test_helper.exs migrates the whole
  # suite at boot via `Ecto.Migrator.run` -> `Mailglass.Migration.up/0` ->
  # `Config.schema/0`. A boot-ORDER regression (migrating under "public" BEFORE
  # the override applies) would silently no-op the mailglass axis while
  # `Config.schema/0` still returned "mailglass" — a false green.
  #
  # This test makes the axis fail closed by asserting the append-only
  # `mailglass_events` table PHYSICALLY EXISTS in the SCHEMA THE SUITE BOOTED
  # UNDER (`Config.schema/0`) — not merely that the string resolves. Under
  # MAILGLASS_SCHEMA=mailglass, `mailglass.mailglass_events` must be present in
  # the `mailglass` schema; under the default (unset) axis it must be present in
  # `public`. Either way the physical table proves the boot migration landed in
  # the resolved schema.
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  alias Mailglass.TestRepo

  setup do
    # Read-only metadata probe against information_schema — check out a sandbox
    # connection so the query has a connection owner (the suite runs the pool in
    # :manual ownership mode).
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  test "boot migration physically created mailglass_events under Config.schema/0 (fail-closed)" do
    schema = Mailglass.Config.schema()

    assert table_exists_in_schema?(schema, "mailglass_events"),
           "FAIL-CLOSED: the append-only mailglass_events table must PHYSICALLY " <>
             "exist in the '#{schema}' schema post-boot. Config.schema/0 returned " <>
             "'#{schema}', but no #{schema}.mailglass_events table is present — the " <>
             "boot migration did not land in the resolved schema (a boot-order " <>
             "no-op would migrate under 'public' before the MAILGLASS_SCHEMA " <>
             "override applies, silently no-op'ing the CI axis)."

    # Extra assurance for the mailglass axis specifically: when the override is
    # active, the physical table is in `mailglass` (not `public`) — the exact
    # invariant the D-06 matrix axis exercises.
    if System.get_env("MAILGLASS_SCHEMA") == "mailglass" do
      assert schema == "mailglass",
             "MAILGLASS_SCHEMA=mailglass must resolve Config.schema/0 to \"mailglass\""

      assert table_exists_in_schema?("mailglass", "mailglass_events"),
             "under MAILGLASS_SCHEMA=mailglass, mailglass.mailglass_events must " <>
               "physically exist in the mailglass schema"
    end
  end

  # Schema-aware existence probe, parameterized on table_schema (the
  # migration_test.exs `table_exists_in_schema?/2` pattern, which hardcodes
  # neither 'public' nor 'mailglass').
  defp table_exists_in_schema?(schema, table_name) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_name = $1 AND table_schema = $2
        """,
        [table_name, schema]
      )

    rows != []
  end
end
