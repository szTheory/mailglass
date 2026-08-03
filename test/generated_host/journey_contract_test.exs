defmodule Mailglass.GeneratedHost.JourneyContractTest do
  use ExUnit.Case, async: true

  @project_root Path.expand("../..", __DIR__)

  test "generated-host runner is stock Phoenix/Ecto, package-shaped, and stage-selectable" do
    script = File.read!(Path.join(@project_root, "scripts/generated_host_proof.sh"))

    assert script =~ "set -euo pipefail"
    assert script =~ "mix phx.new"
    refute script =~ "--no-ecto"
    assert script =~ "DEP_MODE=local|hex"
    assert script =~ "mix hex.build"
    assert script =~ "--stage"
    assert script =~ "KEEP_HOST_ON_FAILURE"
  end

  test "host-owned journey uses public migration APIs and qualified catalog proof" do
    journey = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/journey.ex"))
    template = File.read!(Path.join(@project_root, "dev/mailglass/generated_host/host_template.ex"))

    assert journey =~ "mailglass.gen.migration"
    assert journey =~ "Mailglass.Migration.migrated_version()"
    refute journey =~ "Mailglass.Migrations.Postgres.current_version"
    assert journey =~ "information_schema.tables"
    assert journey =~ "table_schema"
    assert template =~ "config/config.exs"
    assert template =~ "lib/generated_host/repo.ex"
  end

  test "checkpoint is deterministic and contains only hashed bounded evidence" do
    payload =
      Mailglass.GeneratedHost.Checkpoint.encode(%{
        dependency_mode: "local",
        source_sha: "abc123",
        packages: [%{"name" => "mailglass", "identity_sha256" => String.duplicate("a", 64)}],
        stages: [
          %{
            "name" => "install",
            "status" => "passed",
            "command_sha256" => String.duplicate("b", 64)
          }
        ]
      })

    assert payload["schema_version"] == "generated_host_proof.v1"
    assert payload["overall_status"] == "passed"
    assert payload["checkpoint_sha256"] =~ ~r/\A[0-9a-f]{64}\z/
    refute inspect(payload) =~ "recipient"
  end

  test "validator rejects privacy leaks and impossible successful stage claims" do
    validator = Path.join(@project_root, "scripts/check_generated_host_proof.sh")

    checkpoint =
      Path.join(
        System.tmp_dir!(),
        "generated-host-invalid-#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(checkpoint) end)

    File.write!(
      checkpoint,
      ~s({"schema_version":"generated_host_proof.v1","overall_status":"passed","stages":[{"name":"install","status":"failed","recipient":"a@example.com"}]})
    )

    {_output, status} =
      System.cmd("bash", [validator, "--checkpoint", checkpoint], stderr_to_stdout: true)

    assert status != 0
  end
end
