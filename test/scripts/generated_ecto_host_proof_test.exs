defmodule Mailglass.Scripts.GeneratedEctoHostProofTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/generated_ecto_host_proof.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

  @required_script_snippets [
    "mix phx.new host --module Host --app host",
    "config :mailglass, repo: Host.Repo",
    "config :mailglass_inbound, repo: Host.Repo",
    "mailglass.gen.migration --repo Host.Repo",
    "mailglass.inbound.gen.migration --repo Host.Repo",
    "Mailglass.Migration.up(repo: Host.Repo, version: 5)",
    "MailglassInbound.Migration.up(repo: Host.Repo, version: 1)",
    "@disable_ddl_transaction true",
    "@disable_migration_lock true",
    "non_transactional_wrapper: true",
    "mix ecto.migrate -r Host.Repo",
    "Persist.persist(handoff, repo: Host.Repo, routes: [])",
    "Persist.backfill_sha256(repo: Host.Repo, prefix: \"mailglass\", limit: 1)",
    "raw_signed_body = <<0, 255, 13, 10",
    "Mailglass.Migrations.Postgres.V06.concurrent_indexes()",
    "MailglassInbound.Migrations.Postgres.V02.concurrent_indexes()",
    "EXPLAIN (FORMAT JSON)",
    "i.indisvalid",
    "error.postgres.code != :division_by_zero",
    "DELETE FROM schema_migrations WHERE version = $1",
    "mix ecto.rollback -r Host.Repo",
    "run_journey core_first core inbound",
    "run_journey inbound_first inbound core",
    "${SCRATCH_DATABASE}_${journey_name}",
    "FIRST_ROLLBACK_PACKAGE",
    "additive rollback removed prior relation"
  ]

  test "generated Ecto host proof pins the public generator-to-Postgres journey" do
    source = File.read!(@script_path)

    Enum.each(@required_script_snippets, fn snippet ->
      assert String.contains?(source, snippet),
             "generated-host proof is missing required journey anchor: #{inspect(snippet)}"
    end)

    refute String.contains?(source, "--no-ecto"),
           "the proof must generate a real Ecto host, not a compile-only host"

    refute String.contains?(source, "Mailglass.TestRepo"),
           "the proof must use only the generated host's Repo"

    refute Regex.match?(~r/create table\(:mailglass_|CREATE TABLE\s+mailglass_/i, source),
           "the proof must exercise generated package wrappers, not hand-write package DDL"
  end

  test "negative controls prove every public host-proof anchor is load-bearing" do
    source = File.read!(@script_path)

    Enum.each(@required_script_snippets, fn snippet ->
      mutated = String.replace(source, snippet, "")

      refute Enum.all?(@required_script_snippets, &String.contains?(mutated, &1)),
             "removing #{inspect(snippet)} must invalidate the proof contract"
    end)
  end

  test "generated-host proof pins opposing generation and rollback orders" do
    source = File.read!(@script_path)

    assert source =~ "core_first|inbound_first"
    assert source =~ "mailglass.gen.migration --repo Host.Repo"
    assert source =~ "mailglass.inbound.gen.migration --repo Host.Repo"
    assert source =~ "run_journey core_first core inbound"
    assert source =~ "run_journey inbound_first inbound core"
    assert source =~ "FIRST_ROLLBACK_PACKAGE"
    assert source =~ "5 = Mailglass.Migration.migrated_version"
    assert source =~ "1 = MailglassInbound.Migration.migrated_version"
  end

  test "generated-host proof owns only a newly-created private scratch directory" do
    source = File.read!(@script_path)

    assert source =~ "if [ -n \"${WORK_DIR:-}\" ]; then"
    assert source =~ "WORK_DIR is not accepted"
    assert source =~ "mktemp -d \"${TMPDIR:-/tmp}/mailglass-generated-ecto-host.XXXXXX\""
    assert source =~ "rm -rf \"${WORK_DIR}\""
    refute source =~ "rm -rf \"${HOST_DIR}\""

    assert_raise ExUnit.AssertionError, fn ->
      assert_owned_scratch_contract!(
        String.replace(source, "WORK_DIR is not accepted", "caller directory is accepted",
          global: false
        )
      )
    end

    assert_raise ExUnit.AssertionError, fn ->
      assert_owned_scratch_contract!(
        String.replace(source, "mailglass-generated-ecto-host.XXXXXX", "caller-supplied.XXXXXX",
          global: false
        )
      )
    end
  end

  test "Installer Host Smoke retains its identity and runs both adopter proofs" do
    ci_source = File.read!(@ci_yml_path)
    installer_job = extract_job_block(ci_source, "installer_host_smoke")

    assert installer_job != "", "installer_host_smoke job parser returned an empty block"
    assert String.contains?(installer_job, "name: Installer Host Smoke")
    assert String.contains?(installer_job, "bash scripts/consumer_install_smoke.sh")
    assert String.contains?(installer_job, "bash scripts/generated_ecto_host_proof.sh")
    assert String.contains?(installer_job, "postgres:16-alpine")
    assert String.contains?(installer_job, "DATABASE_URL")
    refute Regex.match?(~r/generated_ecto_host_proof\.sh\s*\n?\s*if:/, installer_job)
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
      _ -> ""
    end
  end

  defp assert_owned_scratch_contract!(source) do
    assert source =~ "if [ -n \"${WORK_DIR:-}\" ]; then"
    assert source =~ "WORK_DIR is not accepted"
    assert source =~ "mktemp -d \"${TMPDIR:-/tmp}/mailglass-generated-ecto-host.XXXXXX\""
    assert source =~ "rm -rf \"${WORK_DIR}\""
    refute source =~ "rm -rf \"${HOST_DIR}\""
  end
end
