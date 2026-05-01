defmodule Mailglass.Deliverability.DKIMTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.DKIM

  test "selector absence becomes cannot_verify" do
    result = DKIM.analyze(%{selectors: []})

    assert [%{status: :cannot_verify, check: :selector_required}] = result.findings
  end

  test "revoked DKIM keys fail loudly" do
    result =
      DKIM.analyze(%{
        selectors: [
          %{
            selector: "mg2026",
            domain: "mg2026._domainkey.example.com",
            txt_records: ["v=DKIM1; k=rsa; p="]
          }
        ]
      })

    assert Enum.any?(result.findings, &(&1.status == :fail and &1.check == :revoked_key))
  end

  test "short keys warn but stay selector-specific" do
    result =
      DKIM.analyze(%{
        selectors: [
          %{
            selector: "short",
            domain: "short._domainkey.example.com",
            txt_records: ["v=DKIM1; k=rsa; p=QUJD"]
          }
        ]
      })

    assert Enum.any?(result.findings, &(&1.status == :warn and &1.check == :short_key))
    assert Enum.all?(result.findings, &(&1.area == :dkim))
  end

  test "malformed DKIM TXT answers do not crash the analyzer" do
    result =
      DKIM.analyze(%{
        selectors: [
          %{
            selector: "broken",
            domain: "broken._domainkey.example.com",
            txt_records: :not_a_list,
            cname: 12
          }
        ]
      })

    assert Enum.any?(result.findings, &(&1.status == :cannot_verify and &1.check == :malformed_selector_data))
  end

  test "delegating CNAME selectors are accepted without claiming domain-wide success" do
    result =
      DKIM.analyze(%{
        selectors: [
          %{
            selector: "esp",
            domain: "esp._domainkey.example.com",
            txt_records: [],
            cname: "esp.dkim.provider.test"
          }
        ]
      })

    assert Enum.any?(result.findings, &(&1.status == :pass and &1.check == :selector_cname_present))
    refute Enum.any?(result.findings, &(&1.title =~ "whole domain"))
  end
end
