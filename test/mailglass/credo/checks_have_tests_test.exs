defmodule Mailglass.Credo.ChecksHaveTestsTest do
  use ExUnit.Case, async: true

  # Meta-guard: every custom Credo check under credo_checks/ must have a matching
  # regression test under test/mailglass/credo/ AND be registered in .credo.exs.
  # Together these two dimensions make the "claimed-but-inert guard" defect class
  # self-detecting:
  #   1. A check with no test would pass CI silently while never proving it fires.
  #   2. A check defined under credo_checks/ but left out of .credo.exs's check
  #      list never runs under `mix credo` at all — it is inert. That blind spot
  #      is exactly what let StreamPolicyConsistent ship unregistered. The second
  #      test below closes it: an unregistered check now fails CI by name.
  # Naming convention: credo_checks/<name>.ex => test/mailglass/credo/<name>_test.exs
  # and module Mailglass.Credo.<Camelize(name)>.
  # No exclusion set is permitted in either dimension: every check carries a real
  # test AND a real registration, period.
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

  test "every custom Credo check is registered in .credo.exs" do
    registered = registered_check_modules()

    unregistered =
      "credo_checks/*.ex"
      |> Path.wildcard()
      |> Enum.map(&module_for_check_file/1)
      |> Enum.reject(&MapSet.member?(registered, &1))

    assert unregistered == [],
           "Defined-but-unregistered: " <>
             "the following custom Credo checks exist under credo_checks/ but are " <>
             "NOT registered in .credo.exs, so they never run under `mix credo` " <>
             "(inert guard):\n" <>
             Enum.map_join(unregistered, "\n", fn mod -> "  #{inspect(mod)}" end)
  end

  # Map a credo_checks/<name>.ex path to its module Mailglass.Credo.<Camelize(name)>.
  # credo_checks/stream_policy_consistent.ex -> Mailglass.Credo.StreamPolicyConsistent.
  defp module_for_check_file(path) do
    base = Path.basename(path, ".ex")
    Module.concat([Mailglass, Credo, Macro.camelize(base)])
  end

  # Build the set of modules actually registered in the live .credo.exs check
  # list. Mirrors credo_config_sentinel_test.exs's normalization so the two stay
  # consistent: the :checks value may be a flat keyword-style list of
  # {module, params} tuples OR grouped under :enabled/:extra/:disabled keys, and
  # an entry may be a {module, params} tuple OR a bare module atom.
  defp registered_check_modules do
    {config, _binding} = Code.eval_file(".credo.exs")

    config
    |> Map.fetch!(:configs)
    |> hd()
    |> Map.fetch!(:checks)
    |> flatten_checks()
    |> Enum.map(fn
      {mod, _params} -> mod
      mod when is_atom(mod) -> mod
    end)
    |> MapSet.new()
  end

  defp flatten_checks(checks) when is_list(checks) do
    if Keyword.keyword?(checks) and
         Enum.all?(Keyword.keys(checks), &(&1 in [:enabled, :extra, :disabled])) and
         checks != [] do
      checks
      |> Keyword.values()
      |> List.flatten()
    else
      checks
    end
  end
end
