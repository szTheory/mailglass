defmodule Mailglass.Deliverability.SPFTest do
  use ExUnit.Case, async: false

  alias Mailglass.Deliverability.SPF
  alias Mailglass.TestSupport.DeliverabilityResolverStub

  setup do
    DeliverabilityResolverStub.reset()
    :ok
  end

  test "fails when the domain publishes no SPF record" do
    result = SPF.analyze(%{domain: "example.com", txt_records: ["google-site-verification=abc"]})

    assert [%{status: :fail, check: :missing_record}] = result.findings
  end

  test "fails loudly when multiple SPF records exist" do
    result =
      SPF.analyze(%{
        domain: "example.com",
        txt_records: ["v=spf1 include:_spf.one.test -all", "v=spf1 include:_spf.two.test -all"]
      })

    assert [%{status: :fail, check: :multiple_records, evidence: %{spf_records: records}}] =
             result.findings

    assert length(records) == 2
  end

  test "fails on malformed SPF syntax" do
    result =
      SPF.analyze(%{
        domain: "example.com",
        txt_records: ["v=spf1 include:mail.example.com ??? -all"]
      })

    assert [%{status: :fail, check: :malformed_record, observed: observed}] = result.findings
    assert observed =~ "unknown term"
  end

  test "warns when the SPF record does not end in -all" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{"_spf.provider.test" => {:ok, ["v=spf1 -all"]}}
    })

    result =
      SPF.analyze(
        %{
          domain: "example.com",
          txt_records: ["v=spf1 include:_spf.provider.test ~all"]
        },
        resolver: DeliverabilityResolverStub
      )

    assert Enum.any?(result.findings, &(&1.status == :warn and &1.check == :weak_terminal_policy))
    refute Enum.any?(result.findings, &(&1.status == :fail))
  end

  test "warns when lookup pressure is near the RFC ceiling and tracks visited includes" do
    root_domain = "example.com"
    include_domains = for index <- 1..8, do: "include#{index}.example.test"

    DeliverabilityResolverStub.put_fixtures(%{
      txt:
        Map.new(include_domains, fn domain ->
          {domain, {:ok, ["v=spf1 -all"]}}
        end)
    })

    result =
      SPF.analyze(
        %{
          domain: root_domain,
          txt_records: [
            "v=spf1 " <> Enum.map_join(include_domains, " ", &"include:#{&1}") <> " -all"
          ]
        },
        resolver: DeliverabilityResolverStub
      )

    assert Enum.any?(result.findings, &(&1.status == :warn and &1.check == :lookup_limit_near))
    assert result.facts.lookup_count == 8
    assert result.facts.visited_includes == include_domains
  end

  test "fails once lookup pressure reaches ten terms" do
    root_domain = "example.com"
    include_domains = for index <- 1..10, do: "include#{index}.example.test"

    DeliverabilityResolverStub.put_fixtures(%{
      txt:
        Map.new(include_domains, fn domain ->
          {domain, {:ok, ["v=spf1 -all"]}}
        end)
    })

    result =
      SPF.analyze(
        %{
          domain: root_domain,
          txt_records: [
            "v=spf1 " <> Enum.map_join(include_domains, " ", &"include:#{&1}") <> " -all"
          ]
        },
        resolver: DeliverabilityResolverStub
      )

    assert Enum.any?(result.findings, &(&1.status == :fail and &1.check == :lookup_limit_exceeded))
    refute Enum.any?(result.findings, &(&1.status == :pass))
    assert result.facts.lookup_count == 10
  end

  test "warns when nested includes resolve to empty results" do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "first.example.test" => {:error, :nxdomain},
        "second.example.test" => {:error, :nxdomain}
      }
    })

    result =
      SPF.analyze(
        %{
          domain: "example.com",
          txt_records: ["v=spf1 include:first.example.test include:second.example.test -all"]
        },
        resolver: DeliverabilityResolverStub
      )

    assert Enum.any?(result.findings, &(&1.status == :warn and &1.check == :void_lookup_pressure))
    assert result.facts.void_lookup_count == 2
  end
end
