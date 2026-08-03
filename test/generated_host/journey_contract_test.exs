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
end
