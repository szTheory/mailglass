defmodule Mailglass.Deliverability.MXTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.MX

  test "passes when mx hosts are present" do
    result =
      MX.analyze(%{
        domain: "example.com",
        records: [%{exchange: "mx1.example.com", preference: 10}]
      })

    assert [%{status: :pass, check: :mx_present}] = result.findings
    assert result.facts.posture == :mx_present
  end

  test "treats Null MX as explicit send-only posture" do
    result =
      MX.analyze(%{
        domain: "example.com",
        records: [%{exchange: ".", preference: 0}]
      })

    assert [%{status: :pass, check: :null_mx, observed: observed}] = result.findings
    assert observed =~ "Null MX"
    assert result.facts.posture == :null_mx
  end

  test "warns honestly when mx is missing" do
    result = MX.analyze(%{domain: "example.com", records: []})

    assert [%{status: :warn, check: :missing_records, remediation: remediation}] = result.findings
    assert remediation =~ "send-only"
    assert remediation =~ "Null MX"
    assert result.facts.posture == :no_mx
  end

  test "returns cannot_verify for malformed mx answers" do
    result =
      MX.analyze(%{
        domain: "example.com",
        records: [%{exchange: "mx1.example.com"}]
      })

    assert [%{status: :cannot_verify, check: :malformed_records}] = result.findings
    assert result.facts.posture == :cannot_verify
  end
end
