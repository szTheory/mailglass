defmodule Mailglass.Properties.DeliverabilityStatusPropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Mailglass.Deliverability.Result

  @moduletag :property

  property "result summaries preserve the closed status domain and cannot_verify counts" do
    check all(
            statuses <- list_of(member_of(Result.statuses()), max_length: 40),
            max_runs: 75
          ) do
      findings =
        Enum.with_index(statuses)
        |> Enum.map(fn {status, index} -> finding(status, index) end)

      assert {:ok, result} =
               Result.new(
                 domain: "example.com",
                 findings: findings
               )

      assert Map.keys(result.summary) == [:pass, :warn, :fail, :cannot_verify]
      assert Enum.all?(result.findings, &Result.status?(&1.status))
      assert result.summary.cannot_verify == Enum.count(statuses, &(&1 == :cannot_verify))
      assert result.summary.pass == Enum.count(statuses, &(&1 == :pass))
      assert result.summary.warn == Enum.count(statuses, &(&1 == :warn))
      assert result.summary.fail == Enum.count(statuses, &(&1 == :fail))
    end
  end

  property "cannot_verify findings are never coerced into fail" do
    check all(
            count <- integer(1..25),
            max_runs: 40
          ) do
      findings =
        for index <- 1..count do
          finding(:cannot_verify, index)
        end

      assert {:ok, result} =
               Result.new(
                 domain: "example.com",
                 findings: findings
               )

      assert result.summary == %{pass: 0, warn: 0, fail: 0, cannot_verify: count}
      assert Enum.all?(result.findings, &(&1.status == :cannot_verify))
    end
  end

  defp finding(status, index) do
    %{
      area: Enum.at([:spf, :dkim, :dmarc, :mx, :bimi], rem(index, 5)),
      check: :"check_#{index}",
      status: status,
      title: "Finding #{index}",
      why_it_matters: "Shared contract stays honest about uncertainty.",
      observed: "Observed #{index}",
      remediation: "Remediate #{index}"
    }
  end
end
