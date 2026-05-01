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
        "selector1._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=abc"]},
        "selector2._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=def"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: ".", preference: 0}]}},
      cname: %{
        "selector1._domainkey.example.com" => {:ok, "dkim.provider.test"},
        "selector2._domainkey.example.com" => {:ok, "dkim2.provider.test"},
        "default._bimi.example.com" => {:error, :nxdomain}
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
        "_dmarc.example.com" => {:ok, ["v=DMARC1; p=none"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: ".", preference: 0}]}},
      cname: %{"default._bimi.example.com" => {:ok, "bimi.examplecdn.test"}}
    })

    assert {:ok, result} =
             Deliverability.run(
               domain: "example.com",
               resolver: DeliverabilityResolverStub
             )

    assert result.schema_version == 1
    assert result.summary == %{pass: 0, warn: 0, fail: 0, cannot_verify: 0}
    assert result.facts |> Map.keys() |> Enum.sort() == [:bimi, :dkim, :dmarc, :mx, :spf]
    assert result.facts.spf.txt_records == ["v=spf1 -all"]
    assert result.facts.dkim == %{selectors: []}
    assert result.facts.dmarc.txt_records == ["v=DMARC1; p=none"]
    assert result.facts.mx.records == [%{exchange: ".", preference: 0}]
    assert result.facts.bimi.cname == "bimi.examplecdn.test"
  end

  test "captures resolver_errors as data instead of crashing" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:error, :timeout},
        "_dmarc.example.com" => {:error, :servfail},
        "selector1._domainkey.example.com" => {:error, :malformed_answer}
      },
      mx: %{"example.com" => {:error, :nxdomain}},
      cname: %{
        "selector1._domainkey.example.com" => {:error, :timeout},
        "default._bimi.example.com" => {:error, :nxdomain}
      }
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
               domain: "default._bimi.example.com",
               reason: :nxdomain,
               context: %{area: :bimi}
             },
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
end
