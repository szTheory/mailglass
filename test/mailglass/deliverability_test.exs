defmodule Mailglass.DeliverabilityTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability
  alias Mailglass.TestSupport.DeliverabilityResolverStub

  setup do
    DeliverabilityResolverStub.reset()

    on_exit(fn ->
      DeliverabilityResolverStub.reset()
    end)

    :ok
  end

  test "rejects missing or blank domains" do
    assert {:error, :blank_domain} = Deliverability.run([])
    assert {:error, :blank_domain} = Deliverability.run(domain: "   ")
  end

  test "passes dkim_selectors through without guessing" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:ok, ["v=spf1 -all"]},
        "_dmarc.example.com" => {:ok, ["v=DMARC1; p=none"]},
        "selector1._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=YWJj"]},
        "selector2._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=ZGVm"]},
        "default._bimi.example.com" => {:ok, ["v=BIMI1; l=https://cdn.example.com/logo.svg"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: ".", preference: 0}]}},
      cname: %{
        "selector1._domainkey.example.com" => {:ok, "dkim.provider.test"},
        "selector2._domainkey.example.com" => {:ok, "dkim2.provider.test"}
      }
    })

    assert {:ok, result} =
             Deliverability.run(
               domain: "Example.COM",
               dkim_selectors: ["selector1", "selector2"],
               resolver: DeliverabilityResolverStub
             )

    assert result.domain == "example.com"
    assert result.dkim_selectors == ["selector1", "selector2"]
    assert Enum.map(result.facts.dkim.selectors, & &1.selector) == ["selector1", "selector2"]
  end

  test "returns the stable result shape with all protocol fact buckets" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:ok, ["v=spf1 -all"]},
        "_dmarc.example.com" => {:ok, ["v=DMARC1; p=none"]},
        "default._bimi.example.com" => {:ok, ["v=BIMI1; l=https://cdn.example.com/logo.svg"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: ".", preference: 0}]}}
    })

    assert {:ok, result} =
             Deliverability.run(
               domain: "example.com",
               resolver: DeliverabilityResolverStub
             )

    assert result.schema_version == 1
    assert result.summary == %{pass: 3, warn: 8, fail: 0, cannot_verify: 1}
    assert result.facts |> Map.keys() |> Enum.sort() == [:bimi, :dkim, :dmarc, :mx, :spf]
    assert result.facts.spf.txt_records == ["v=spf1 -all"]
    assert result.facts.dkim.checked_selector_count == 0
    assert result.facts.dmarc.txt_records == ["v=DMARC1; p=none"]
    assert result.facts.mx.records == [%{exchange: ".", preference: 0}]
    assert result.facts.bimi.txt_records == ["v=BIMI1; l=https://cdn.example.com/logo.svg"]
  end

  test "captures resolver_errors as data instead of crashing" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:error, :timeout},
        "_dmarc.example.com" => {:error, :servfail},
        "selector1._domainkey.example.com" => {:error, :malformed_answer},
        "default._bimi.example.com" => {:error, :nxdomain}
      },
      mx: %{"example.com" => {:error, :nxdomain}},
      cname: %{"selector1._domainkey.example.com" => {:error, :timeout}}
    })

    assert {:ok, result} =
             Deliverability.run(
               domain: "example.com",
               dkim_selectors: ["selector1"],
               resolver: DeliverabilityResolverStub
             )

    assert Enum.sort_by(result.resolver_errors, &{&1.lookup, &1.domain, &1.reason}) == [
             %{
               lookup: :cname,
               domain: "selector1._domainkey.example.com",
               reason: :timeout,
               context: %{area: :dkim, selector: "selector1"}
             },
             %{
               lookup: :mx,
               domain: "example.com",
               reason: :nxdomain,
               context: %{area: :mx}
             },
             %{
               lookup: :txt,
               domain: "_dmarc.example.com",
               reason: :servfail,
               context: %{area: :dmarc}
             },
             %{
               lookup: :txt,
               domain: "default._bimi.example.com",
               reason: :nxdomain,
               context: %{area: :bimi}
             },
             %{
               lookup: :txt,
               domain: "example.com",
               reason: :timeout,
               context: %{area: :spf}
             },
             %{
               lookup: :txt,
               domain: "selector1._domainkey.example.com",
               reason: :malformed_answer,
               context: %{area: :dkim, selector: "selector1"}
             }
           ]
  end

  test "aggregates all five analyzers and threads dmarc posture into bimi" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:ok, ["v=spf1 include:_spf.example.net -all"]},
        "_dmarc.example.com" => {:ok, ["v=DMARC1; p=none"]},
        "selector1._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=YWJj"]},
        "default._bimi.example.com" => {:ok, ["v=BIMI1; l=https://cdn.example.com/logo.svg"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: "mx1.example.com", preference: 10}]}},
      cname: %{"selector1._domainkey.example.com" => {:ok, "selector1.provider.example"}}
    })

    assert {:ok, result} =
             Deliverability.run(
               domain: "example.com",
               dkim_selectors: ["selector1"],
               resolver: DeliverabilityResolverStub
             )

    assert Enum.map(result.findings, & &1.area) |> Enum.uniq() == [:spf, :dkim, :dmarc, :mx, :bimi]
    assert Enum.any?(result.findings, &(&1.area == :bimi and &1.check == :dmarc_prerequisite))
    assert result.facts.dmarc.posture == :monitoring
    assert result.facts.bimi.dmarc_posture == :monitoring
  end
end
