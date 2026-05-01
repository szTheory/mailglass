defmodule Mailglass.Deliverability.DMARCTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.DMARC

  test "p=none is a warn, not a fail" do
    result =
      DMARC.analyze(%{
        domain: "_dmarc.example.com",
        txt_records: ["v=DMARC1; p=none; rua=mailto:dmarc@example.com"]
      })

    assert Enum.any?(result.findings, &(&1.status == :warn and &1.check == :monitoring_policy))
    refute Enum.any?(result.findings, &(&1.status == :fail and &1.check == :monitoring_policy))
    assert result.facts.posture == :monitoring
  end

  test "multiple DMARC records fail loudly" do
    result =
      DMARC.analyze(%{
        domain: "_dmarc.example.com",
        txt_records: ["v=DMARC1; p=none", "v=DMARC1; p=reject"]
      })

    assert [%{status: :fail, check: :multiple_records}] = result.findings
  end

  test "malformed tag syntax fails" do
    result =
      DMARC.analyze(%{
        domain: "_dmarc.example.com",
        txt_records: ["v=DMARC1; p"]
      })

    assert [%{status: :fail, check: :malformed_record}] = result.findings
  end

  test "reject posture passes and emits alignment/reporting advisories" do
    result =
      DMARC.analyze(%{
        domain: "_dmarc.example.com",
        txt_records: [
          "v=DMARC1; p=reject; adkim=s; aspf=s; rua=mailto:dmarc@example.com; sp=reject"
        ]
      })

    assert Enum.any?(result.findings, &(&1.status == :pass and &1.check == :enforcement_policy))
    assert Enum.any?(result.findings, &(&1.check == :adkim_present))
    assert Enum.any?(result.findings, &(&1.check == :aspf_present))
    assert Enum.any?(result.findings, &(&1.check == :rua_present))
    assert Enum.any?(result.findings, &(&1.check == :subdomain_policy_present))
    assert result.facts.posture == :enforcement
  end
end
