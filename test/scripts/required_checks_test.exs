defmodule Mailglass.Scripts.RequiredChecksTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)
  @v1_0_lock_entries [
    "Support Contract Core (Elixir 1.18 / OTP 27)",
    "Support Contract Admin (Elixir 1.18 / OTP 27)",
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  ]

  test "REQUIRED_CHECKS array and print_expected_text bullets stay in sync" do
    source = File.read!(@script_path)

    array_set = parse_required_checks(source)
    bullet_set = parse_print_expected_bullets(source)

    # Guard against a vacuous pass: if the script's structure changes so a parser
    # returns nothing, both sets would be empty and the difference check below
    # would pass while detecting no drift at all.
    assert MapSet.size(array_set) > 0, "parsed no REQUIRED_CHECKS entries — parser or script format changed"
    assert MapSet.size(bullet_set) > 0, "parsed no print_expected_text bullets — parser or script format changed"

    only_in_array = MapSet.difference(array_set, bullet_set)
    only_in_bullets = MapSet.difference(bullet_set, array_set)

    assert MapSet.size(only_in_array) == 0 and MapSet.size(only_in_bullets) == 0,
           "REQUIRED_CHECKS and print_expected_text heredoc have drifted:\n" <>
             "  In array but missing from heredoc: #{inspect(MapSet.to_list(only_in_array))}\n" <>
             "  In heredoc but missing from array: #{inspect(MapSet.to_list(only_in_bullets))}"
  end

  test "REQUIRED_CHECKS contains every Phase 27 stability-lock entry" do
    source = File.read!(@script_path)
    array_set = parse_required_checks(source)

    Enum.each(@v1_0_lock_entries, fn entry ->
      assert MapSet.member?(array_set, entry),
             "Phase 27 stability-lock entry missing from REQUIRED_CHECKS: #{inspect(entry)}"
    end)
  end

  defp parse_required_checks(source) do
    [_before, rest] = String.split(source, "REQUIRED_CHECKS=(\n", parts: 2)
    [chunk | _] = String.split(rest, "\n)", parts: 2)

    Regex.scan(~r/"([^"]+)"/, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end

  defp parse_print_expected_bullets(source) do
    [_before, rest] = String.split(source, "cat <<'TEXT'\nExpected required status checks:\n", parts: 2)
    [chunk | _] = String.split(rest, "\n\nExpected non-context branch protection fields:", parts: 2)

    Regex.scan(~r/^  - (.+)$/m, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end
end
