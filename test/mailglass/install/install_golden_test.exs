defmodule Mailglass.Install.GoldenTest do
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  @fixture_readme Path.expand("../../example/README.md", __DIR__)
  @accept_golden_env "MIX_INSTALLER_ACCEPT_GOLDEN"

  test "fresh install snapshot stays stable" do
    fixture_root = new_fixture_root!("golden-fresh")
    run_install!(fixture_root, [])

    actual_snapshot =
      fixture_root
      |> snapshot_tree!()
      |> normalize_snapshot()

    assert_snapshot_matches_or_refresh!("GOLDEN_FRESH", actual_snapshot)
  end

  test "--no-admin snapshot stays stable" do
    fixture_root = new_fixture_root!("golden-no-admin")
    run_install!(fixture_root, ["--no-admin"])

    actual_snapshot =
      fixture_root
      |> snapshot_tree!()
      |> normalize_snapshot()

    assert_snapshot_matches_or_refresh!("GOLDEN_NO_ADMIN", actual_snapshot)
  end

  defp assert_snapshot_matches_or_refresh!(key, actual_snapshot) do
    expected_snapshot = read_snapshot!(key)

    cond do
      expected_snapshot == actual_snapshot ->
        :ok

      accept_golden_refresh?() ->
        write_snapshot!(key, actual_snapshot)
        :ok

      true ->
        assert expected_snapshot == actual_snapshot,
               """
               Installer golden snapshot mismatch for #{key}.

               Refresh with:
                 #{@accept_golden_env}=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors
               """
    end
  end

  defp read_snapshot!(key) do
    readme = File.read!(@fixture_readme)
    start_marker = "<!-- #{key}_START -->"
    end_marker = "<!-- #{key}_END -->"

    {_before_start, after_start} =
      split_once!(readme, start_marker, "start marker #{start_marker} not found")

    {body, _after_end} =
      split_once!(after_start, end_marker, "end marker #{end_marker} not found")

    String.trim(body)
  end

  defp write_snapshot!(key, snapshot) do
    readme = File.read!(@fixture_readme)
    start_marker = "<!-- #{key}_START -->"
    end_marker = "<!-- #{key}_END -->"

    {before_start, after_start} =
      split_once!(readme, start_marker, "start marker #{start_marker} not found")

    {_old_body, after_end} =
      split_once!(after_start, end_marker, "end marker #{end_marker} not found")

    updated =
      before_start <>
        start_marker <>
        "\n" <>
        snapshot <>
        "\n" <>
        end_marker <>
        after_end

    File.write!(@fixture_readme, updated)
  end

  defp split_once!(value, marker, error_message) do
    case String.split(value, marker, parts: 2) do
      [left, right] -> {left, right}
      _ -> raise error_message
    end
  end

  defp accept_golden_refresh? do
    System.get_env(@accept_golden_env) == "1"
  end
end
