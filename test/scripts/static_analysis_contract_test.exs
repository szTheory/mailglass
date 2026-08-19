defmodule Mailglass.Scripts.StaticAnalysisContractTest do
  use ExUnit.Case, async: true

  Code.require_file(Path.expand("../../scripts/static_analysis_exceptions.ex", __DIR__))

  alias Mailglass.Quality.StaticAnalysisExceptions, as: Exceptions

  test "ratchet accepts only an exact non-growing baseline" do
    key = {"lib/example.ex", "Example.run", "Credo.Check.Refactor.Nesting"}
    baseline = %{key => %{score: 3, occurrences: 1}}

    assert :ok = Exceptions.compare!(baseline, baseline)

    assert_raise RuntimeError, ~r/new_exceptions/, fn ->
      Exceptions.compare!(%{}, baseline)
    end

    assert_raise RuntimeError, ~r/dead_exceptions/, fn ->
      Exceptions.compare!(baseline, %{})
    end

    assert_raise RuntimeError, ~r/regressions/, fn ->
      Exceptions.compare!(baseline, %{key => %{score: 4, occurrences: 1}})
    end
  end

  test "aggregates multiple findings by function, check, maximum score, and count" do
    issue = %{
      "filename" => "lib/example.ex",
      "scope" => "Example.run",
      "check" => "Credo.Check.Refactor.Nesting",
      "message" => "Function body is nested too deep (max depth is 2, was 3)."
    }

    assert %{
             {"lib/example.ex", "Example.run", "Credo.Check.Refactor.Nesting"} => %{
               score: 3,
               occurrences: 2
             }
           } = Exceptions.aggregate([issue, issue])
  end

  test "repository ledger rejects global disables and carries expiry metadata" do
    source = File.read!(Path.expand("../../.credo.exs", __DIR__))
    refute source =~ "{Credo.Check.Refactor.Nesting, false}"
    refute source =~ "{Credo.Check.Refactor.CyclomaticComplexity, false}"

    {ledger, _binding} =
      Code.eval_file(Path.expand("../../config/static_analysis_exceptions.exs", __DIR__))

    assert ledger.owner != ""
    assert ledger.reason != ""
    assert Date.after?(ledger.expires_on, Date.utc_today())
    assert ledger.credo != []
    assert ledger.dialyzer != []

    assert Enum.all?(ledger.dialyzer, fn {_package, _file, _description, owner, reason, expiry} ->
             owner != "" and reason != "" and Date.after?(expiry, Date.utc_today())
           end)
  end

  test "inbound Dialyzer owns a strict package-local PLT and ignore file" do
    mix_source = File.read!(Path.expand("../../mailglass_inbound/mix.exs", __DIR__))
    ci_source = File.read!(Path.expand("../../.github/workflows/ci.yml", __DIR__))
    ignore_checker = File.read!(Path.expand("../../scripts/check_dialyzer_ignore.sh", __DIR__))

    assert mix_source =~ ~s(ignore_file_strict: ".dialyzer_ignore.exs")
    assert mix_source =~ "list_unused_filters: true"
    assert mix_source =~ "mailglass_inbound.plt"
    assert mix_source =~ "plt_add_apps: [:ex_unit, :mix]"

    assert ci_source =~ "inbound_dialyzer:"
    assert ci_source =~ "cache-namespace: mailglass-inbound-dialyzer"
    assert ci_source =~ "working-directory: mailglass_inbound"
    assert ignore_checker =~ ~s("mailglass_inbound/.dialyzer_ignore.exs")

    refute File.read!(Path.expand("../../mailglass_inbound/.dialyzer_ignore.exs", __DIR__)) =~
             "lib/mailglass/"
  end
end
