defmodule Mailglass.NoOptionalDepsPublicSendTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.TestRepo

  @moduletag phase_151_task: "t151_06_02"
  @public_tables ~w(mailglass_suppressions mailglass_deliveries mailglass_events mailglass_outbound_payloads)

  test "the isolated runtime preserves the public catalog and never logs its private fixture" do
    before = public_snapshot!()

    {output, 0} =
      System.cmd("bash", ["scripts/no_optional_deps_runtime_smoke.sh"],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert public_snapshot!() == before
    refute output =~ "runtime-private-prune-sentinel"
  end

  defp public_snapshot! do
    catalog =
      TestRepo.query!("""
      SELECT c.relname, c.relkind, pg_catalog.obj_description(c.oid, 'pg_class')
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname LIKE 'mailglass_%'
      ORDER BY c.relname, c.relkind
      """).rows

    counts =
      for table <- @public_tables do
        case TestRepo.query!("SELECT to_regclass($1)", ["public.#{table}"]).rows do
          [[nil]] ->
            {table, :missing}

          [[_relation]] ->
            %{rows: [[count]]} = TestRepo.query!("SELECT COUNT(*) FROM public.#{table}")
            {table, count}
        end
      end

    %{catalog: catalog, counts: counts}
  end
end
