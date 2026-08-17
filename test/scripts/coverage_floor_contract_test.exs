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
  end

  test "checker fails closed if report validation is removed" do
    source = File.read!(@checker)

    refute String.replace(source, "coverage report missing", "report optional") =~
             "coverage report missing"
  end
end
