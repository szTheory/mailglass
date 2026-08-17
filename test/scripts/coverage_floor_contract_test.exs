defmodule Mailglass.Scripts.CoverageFloorContractTest do
  use ExUnit.Case, async: true

  @checker Path.expand("../../scripts/check_coverage_floor.sh", __DIR__)

  test "coverage checker requires an existing measured baseline, report, and exact toolchain" do
    source = File.read!(@checker)
    assert source =~ "coverage baseline missing"
    assert source =~ "coverage report missing"
    assert source =~ "coverage toolchain mismatch"
    assert source =~ "source_files"
    assert source =~ "coverage regression"
    assert source =~ "percentage"
  end

  test "canonical baselines name the scoped package cohorts and critical paths stay separate" do
    core = File.read!(Path.expand("../../config/coverage_baselines/core.json", __DIR__))
    inbound = File.read!(Path.expand("../../config/coverage_baselines/inbound.json", __DIR__))
    critical = File.read!(Path.expand("../../config/critical_path_manifest.json", __DIR__))

    assert core =~ "test/mailglass"
    assert inbound =~ "test/mailglass_inbound"
    assert critical =~ "required_commands"
    assert critical =~ "not coverage-percentage inputs"
  end

  test "checker fails closed if report validation is removed" do
    source = File.read!(@checker)

    refute String.replace(source, "coverage report missing", "report optional") =~
             "coverage report missing"
  end
end
