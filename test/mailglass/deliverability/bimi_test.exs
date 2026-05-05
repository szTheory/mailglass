defmodule Mailglass.Deliverability.BIMITest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.BIMI

  test "missing BIMI is a warn, not a fail" do
    result =
      BIMI.analyze(
        %{domain: "default._bimi.example.com", txt_records: []},
        dmarc_posture: :enforcement
      )

    assert [%{status: :warn, check: :missing_record}] = result.findings
  end

  test "warns when dmarc is not enforcing enough for bimi readiness" do
    result =
      BIMI.analyze(
        %{
          domain: "default._bimi.example.com",
          txt_records: ["v=BIMI1; l=https://cdn.example.com/logo.svg"]
        },
        dmarc_posture: :monitoring
      )

    assert Enum.any?(result.findings, &(&1.check == :dmarc_prerequisite and &1.status == :warn))
    assert result.facts.dmarc_posture == :monitoring
  end

  test "explains l= and a= caveats without claiming display certainty" do
    result =
      BIMI.analyze(
        %{
          domain: "default._bimi.example.com",
          txt_records: ["v=BIMI1; l=https://cdn.example.com/logo.svg"]
        },
        dmarc_posture: :enforcement
      )

    assert Enum.any?(result.findings, &(&1.check == :logo_location_present and &1.status == :pass))

    assert Enum.any?(
             result.findings,
             &(&1.check == :certificate_location_missing and &1.status == :warn)
           )

    assert Enum.any?(
             result.findings,
             &(&1.check == :provider_caveat and &1.observed =~ "l=https://cdn.example.com/logo.svg")
           )
  end
end
