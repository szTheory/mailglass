defmodule Mailglass.Scripts.SetupActionContractTest do
  use ExUnit.Case, async: true

  @action Path.expand("../../.github/actions/setup-beam-mix/action.yml", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "setup action requires package-scoped locked identity" do
    assert_setup_contract!(File.read!(@action))
  end

  test "setup action contract rejects wildcard lock identity" do
    source = File.read!(@action)

    assert_raise ExUnit.AssertionError, fn ->
      assert_setup_contract!(
        String.replace(source, "hashFiles(inputs.lockfile)", "hashFiles('**/mix.lock)")
      )
    end
  end

  test "format check uses the shared root package setup without changing its check name" do
    source = File.read!(@ci)
    job = source |> String.split("  compile_warnings:", parts: 2) |> hd()

    assert job =~ "name: Format Check (Elixir 1.18 / OTP 27)"
    assert job =~ "uses: ./.github/actions/setup-beam-mix"
    assert job =~ "package-dir: ."
    assert job =~ "lockfile: mix.lock"
  end

  defp assert_setup_contract!(source) do
    for input <- ["package-dir:", "lockfile:", "mix-env:", "build-path:", "cache-namespace:"] do
      assert source =~ input
    end

    assert source =~ "version-file: .tool-versions"
    assert source =~ "version-type: strict"
    assert source =~ "hashFiles(inputs.lockfile)"
    assert source =~ "inputs.cache-namespace"
    assert source =~ "inputs.mix-env"
    assert source =~ "inputs.build-path"
    assert source =~ "mix deps.get --check-locked"
    refute source =~ "hashFiles('**/mix.lock')"
  end
end
