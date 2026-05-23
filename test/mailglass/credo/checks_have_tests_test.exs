defmodule Mailglass.Credo.ChecksHaveTestsTest do
  use ExUnit.Case, async: true

  # Meta-guard: every custom Credo check under credo_checks/ must have a matching
  # regression test under test/mailglass/credo/. This makes the "claimed-but-inert
  # guard" defect class self-detecting — a check registered in .credo.exs with no
  # test would otherwise pass CI silently while never proving it actually fires.
  # Naming convention: credo_checks/<name>.ex => test/mailglass/credo/<name>_test.exs.
  # No allowlist / @known_uncovered: every check carries a real test, period.
  test "every custom Credo check has a matching regression test" do
    missing =
      "credo_checks/*.ex"
      |> Path.wildcard()
      |> Enum.map(fn check_path ->
        base = Path.basename(check_path, ".ex")
        {check_path, "test/mailglass/credo/#{base}_test.exs"}
      end)
      |> Enum.reject(fn {_check_path, test_path} -> File.exists?(test_path) end)

    assert missing == [],
           "Custom Credo checks missing a regression test:\n" <>
             Enum.map_join(missing, "\n", fn {check_path, test_path} ->
               "  #{check_path} -> expected #{test_path}"
             end)
  end
end
