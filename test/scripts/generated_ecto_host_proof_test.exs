defmodule Mailglass.Scripts.GeneratedEctoHostProofTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/generated_ecto_host_proof.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @custom_modules_path Path.expand("../fixtures/generated_host/custom_modules.exs", __DIR__)

  @fresh_delivery_stages [
    "fresh_install",
    "sync_send",
    "atomic_enqueue",
    "worker_run",
    "persisted_outcome"
  ]

  @boundary_stages [
    "custom_modules",
    "multi_repo_prefixes",
    "upgrade",
    "rollback",
    "idempotent_rerun"
  ]

  @all_stages @fresh_delivery_stages ++ @boundary_stages

  @valid_attestations %{
    "fresh_install" => %{
      "core_first" => "install_order=core,inbound",
      "inbound_first" => "install_order=inbound,core"
    },
    "sync_send" => "delivery=sent;events=2",
    "atomic_enqueue" => "rollback=0,0,0;commit=1,1",
    "worker_run" => "job=completed",
    "persisted_outcome" => "delivery=sent;event=dispatched;events=2",
    "custom_modules" => "repos=postgres;adapter=generated",
    "multi_repo_prefixes" => "prefixes=isolated;migration_sources=2",
    "upgrade" => "versions=6,2;indexes=valid",
    "rollback" => "versions=5,1;host_marker=present",
    "idempotent_rerun" => "versions=5,1;host_marker=present"
  }

  @required_script_snippets [
    "mix phx.new host --module Host --app host",
    "config :mailglass, repo: Host.Repo",
    "config :mailglass_inbound, repo: Host.InboundRepo",
    "mailglass.gen.migration --repo Host.Repo",
    "mailglass.inbound.gen.migration --repo Host.InboundRepo",
    "Mailglass.Migration.up(repo: Host.Repo, version: 5)",
    "MailglassInbound.Migration.up(repo: Host.InboundRepo, version: 1)",
    "@disable_ddl_transaction true",
    "@disable_migration_lock true",
    "non_transactional_wrapper: true",
    "mix ecto.migrate -r Host.Repo",
    "Persist.persist(handoff, repo: Host.InboundRepo, routes: [])",
    "Persist.backfill_sha256(repo: Host.InboundRepo, prefix: \"mailglass_inbound\", limit: 1)",
    "raw_signed_body = <<0, 255, 13, 10",
    "Mailglass.Migrations.Postgres.V06.concurrent_indexes()",
    "MailglassInbound.Migrations.Postgres.V02.concurrent_indexes()",
    "EXPLAIN (FORMAT JSON)",
    "i.indisvalid",
    "error.postgres.code != :division_by_zero",
    "DELETE FROM core_schema_migrations WHERE version = $1",
    "DELETE FROM inbound_schema_migrations WHERE version = $1",
    "INBOUND_UPGRADE_VERSION",
    "inbound invalid-index retry did not converge",
    "inspect(Path.join(path, \"mailglass_inbound\"))",
    "mix ecto.rollback -r Host.Repo",
    "run_generator \"${first_package}\" \"${journey_url}\"",
    "run_generator \"${second_package}\" \"${journey_url}\"",
    "migrate_package \"${first_package}\" \"${journey_url}\" 1",
    "migrate_package \"${second_package}\" \"${journey_url}\" 2",
    "public.generated_host_install_order",
    "generated_host_atomic_enqueue_failure",
    "run_journey core_first core inbound",
    "run_journey inbound_first inbound core",
    "${SCRATCH_DATABASE}_${journey_name}",
    "FIRST_ROLLBACK_PACKAGE",
    "additive rollback removed prior relation"
  ]

  test "generated-host checkpoints fail closed on missing, duplicate, reordered, or equal-order evidence" do
    valid_rows =
      for {journey, journey_index} <- Enum.with_index(["core_first", "inbound_first"]),
          {stage, stage_index} <- Enum.with_index(@all_stages) do
        "#{journey_index * length(@all_stages) + stage_index + 1}|#{journey}|#{stage}|passed"
      end

    assert_checkpoint_result(valid_rows, 0)

    assert_checkpoint_result(List.delete_at(valid_rows, 2), :failure)
    assert_checkpoint_result(List.insert_at(valid_rows, 3, Enum.at(valid_rows, 2)), :failure)

    reordered =
      List.replace_at(valid_rows, 1, Enum.at(valid_rows, 2))
      |> List.replace_at(2, Enum.at(valid_rows, 1))

    assert_checkpoint_result(reordered, :failure)

    equal_order =
      List.update_at(valid_rows, 1, fn row ->
        [_order | rest] = String.split(row, "|")
        Enum.join(["1" | rest], "|")
      end)

    assert_checkpoint_result(equal_order, :failure)
  end

  test "generated-host checkpoint contract is closed and sanitized" do
    source = File.read!(@script_path)

    Enum.each(@all_stages, fn stage ->
      assert source =~ stage
    end)

    assert source =~ "--validate-checkpoints"
    assert source =~ "CHECKPOINT_FILE"
    assert source =~ "checkpoint"

    valid_rows =
      for {journey, journey_index} <- Enum.with_index(["core_first", "inbound_first"]),
          {stage, stage_index} <- Enum.with_index(@all_stages) do
        "#{journey_index * length(@all_stages) + stage_index + 1}|#{journey}|#{stage}|passed"
      end

    assert_checkpoint_result(
      List.replace_at(valid_rows, 1, "2|core_first|sync_send|recipient@example.com"),
      :failure
    )
  end

  test "scratch database namespace validator is fully anchored and rejects encoded/control suffixes" do
    assert_database_name_result("mailglass_generated_ecto_host_review_01", 0)

    for invalid <- [
          "mailglass_generated_ecto_host_bad-name",
          "mailglass_generated_ecto_host_bad%2Fescape",
          "mailglass_generated_ecto_host_bad\nsuffix",
          "prefix_mailglass_generated_ecto_host_valid",
          "mailglass_generated_ecto_host_valid.trailing",
          "mailglass_generated_ecto_host_"
        ] do
      assert_database_name_result(invalid, :failure)
    end
  end

  test "custom host modules are copied from one deterministic fixture and exercised at runtime" do
    source = File.read!(@script_path)
    fixture = File.read!(@custom_modules_path)

    for token <- [
          "defmodule Host.InboundRepo",
          "defmodule Host.GeneratedHostTenancy",
          "defmodule Host.GeneratedHostAdapter",
          "@behaviour Mailglass.Tenancy",
          "@behaviour Mailglass.Adapter"
        ] do
      assert fixture =~ token
    end

    assert source =~ "test/fixtures/generated_host/custom_modules.exs"
    assert source =~ "Host.InboundRepo"
    assert source =~ "mailglass_core"
    assert source =~ "mailglass_inbound"
    assert source =~ "Host.GeneratedHostTenancy"
  end

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

  test "package resolution preserves local-path default and fails closed in exact-Hex mode" do
    source = File.read!(@script_path)

    {path_deps, 0} =
      System.cmd(
        "bash",
        [@script_path, "--render-package-dependencies", "path", "/tmp/mailglass source"],
        stderr_to_stdout: true
      )

    assert path_deps =~ ~s({:mailglass, path: "/tmp/mailglass source", override: true})
    assert path_deps =~ ~s({:mailglass_inbound, path: "/tmp/mailglass source/mailglass_inbound"})
    refute path_deps =~ "mailglass_admin"
    refute path_deps =~ "git:"

    {hex_deps, 0} =
      System.cmd(
        "bash",
        [
          @script_path,
          "--render-package-dependencies",
          "exact_hex",
          "3.1.2",
          "3.1.2",
          "2.4.0"
        ],
        stderr_to_stdout: true
      )

    assert hex_deps =~ ~s({:mailglass, "== 3.1.2", override: true})
    assert hex_deps =~ ~s({:mailglass_admin, "== 3.1.2"})
    assert hex_deps =~ ~s({:mailglass_inbound, "== 2.4.0"})
    refute hex_deps =~ "path:"
    refute hex_deps =~ "git:"

    for invalid_args <- [
          ["exact_hex", "3.1", "3.1.2", "2.4.0"],
          ["exact_hex", "3.1.2-rc.1", "3.1.2", "2.4.0"],
          ["exact_hex", "3.1.2", "", "2.4.0"],
          ["hex", "3.1.2", "3.1.2", "2.4.0"]
        ] do
      {_output, status} =
        System.cmd("bash", [@script_path, "--render-package-dependencies" | invalid_args],
          stderr_to_stdout: true
        )

      assert status != 0
    end

    assert source =~ ~s(MAILGLASS_PACKAGE_MODE="${MAILGLASS_PACKAGE_MODE:-path}")
    assert source =~ "MAILGLASS_EXPECTED_CORE_VERSION"
    assert source =~ "check_clean_baseline_hex_only.sh"
    assert source =~ ~s(CHECKPOINT_OUTPUT="${MAILGLASS_GENERATED_HOST_CHECKPOINT_OUT:-}")
    assert source =~ "Generated-host checkpoint output must survive outside the scratch directory"
    assert source =~ ~s(validate_checkpoint_file "${checkpoint_output_path}")
  end

  test "runtime checkpoints consume closed sanitized attestations with executable mutations" do
    for journey <- ["core_first", "inbound_first"],
        {stage, configured_result} <- @valid_attestations do
      result =
        case configured_result do
          result_by_journey when is_map(result_by_journey) -> Map.fetch!(result_by_journey, journey)
          shared_result -> shared_result
        end

      assert_attestation_result(journey, stage, result, 0)

      for mutation <- ["", result <> ";forged", "verified"] do
        assert_attestation_result(journey, stage, mutation, :failure)
      end
    end

    assert_attestation_result("unknown", "fresh_install", "install_order=core,inbound", :failure)
    assert_attestation_result("core_first", "unknown", "verified", :failure)
  end

  test "generated-host proof pins opposing generation and rollback orders" do
    source = File.read!(@script_path)

    assert source =~ "core_first|inbound_first"
    assert source =~ "mailglass.gen.migration --repo Host.Repo"
    assert source =~ "mailglass.inbound.gen.migration --repo Host.InboundRepo"
    assert source =~ "run_journey core_first core inbound"
    assert source =~ "run_journey inbound_first inbound core"
    assert source =~ "run_generator \"${first_package}\" \"${journey_url}\""
    assert source =~ "run_generator \"${second_package}\" \"${journey_url}\""
    assert source =~ "migrate_package \"${first_package}\" \"${journey_url}\" 1"
    assert source =~ "migrate_package \"${second_package}\" \"${journey_url}\" 2"
    refute source =~ "run_generator core \"${journey_url}\""
    refute source =~ "run_generator inbound \"${journey_url}\""
    assert source =~ "FIRST_ROLLBACK_PACKAGE"
    assert source =~ "5 = Mailglass.Migration.migrated_version"
    assert source =~ "1 = MailglassInbound.Migration.migrated_version"
  end

  test "idempotent rollback probes allow the temporary Repo time to stop cleanly" do
    source = File.read!(@script_path)

    assert source =~ "idempotent_rollback_to"
    assert source =~ "Supervisor.stop(repo_pid, :normal, 30_000)"
    refute source =~ ~s(mix ecto.rollback -r Host.Repo --to "${core_upgrade_version}")
    refute source =~ ~s(mix ecto.rollback -r Host.InboundRepo --to "${inbound_upgrade_version}")
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

  defp assert_attestation_result(journey, stage, result, expected) do
    {_output, exit_code} =
      System.cmd(
        "bash",
        [@script_path, "--validate-attestation", journey, stage, result],
        stderr_to_stdout: true
      )

    case expected do
      0 -> assert exit_code == 0
      :failure -> assert exit_code != 0
    end
  end

  defp assert_database_name_result(database_name, expected) do
    {_output, exit_code} =
      System.cmd("bash", [@script_path, "--validate-database-name", database_name],
        stderr_to_stdout: true
      )

    case expected do
      0 -> assert exit_code == 0
      :failure -> assert exit_code != 0
    end
  end

  defp assert_checkpoint_result(rows, expected) do
    checkpoint_path =
      Path.join(
        System.tmp_dir!(),
        "mailglass-generated-host-checkpoint-#{System.unique_integer([:positive])}.txt"
      )

    File.write!(checkpoint_path, Enum.join(rows, "\n") <> "\n")

    {_output, exit_code} =
      System.cmd("bash", [@script_path, "--validate-checkpoints", checkpoint_path],
        stderr_to_stdout: true
      )

    File.rm!(checkpoint_path)

    case expected do
      0 -> assert exit_code == 0
      :failure -> assert exit_code != 0
    end
  end
end
