defmodule Mailglass.Deliverability.ResultTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.Result

  test "pins the closed status set" do
    assert Result.statuses() == [:pass, :warn, :fail, :cannot_verify]
    assert Result.status?(:cannot_verify)
    refute Result.status?(:unknown)
  end

  test "uses schema version 1" do
    assert {:ok, result} = Result.new(domain: "example.com")
    assert result.schema_version == 1
    assert result.schema_version == Result.schema_version()
  end

  test "computes summary buckets across mixed finding statuses" do
    assert {:ok, result} =
             Result.new(
               domain: "example.com",
               findings: [
                 finding(:pass, :spf, :record_present),
                 finding(:warn, :dmarc, :monitoring_only),
                 finding(:fail, :mx, :missing_records),
                 finding(:cannot_verify, :dkim, :selector_required),
                 finding(:cannot_verify, :bimi, :resolver_timeout)
               ]
             )

    assert result.summary == %{pass: 1, warn: 1, fail: 1, cannot_verify: 2}
  end

  test "rejects malformed finding status input" do
    assert {:error, {:invalid_status, :unknown}} =
             Result.new(
               domain: "example.com",
               findings: [finding(:unknown, :spf, :record_present)]
             )
  end

  test "rejects malformed findings that omit required prose fields" do
    assert {:error, {:invalid_finding, {:missing_keys, [:why_it_matters]}}} =
             Result.new(
               domain: "example.com",
               findings: [
                 %{
                   area: :spf,
                   check: :record_present,
                   status: :pass,
                   title: "SPF record present",
                   observed: "Found one SPF TXT record.",
                   remediation: "No action required."
                 }
               ]
             )
  end

  test "normalizes facts and resolver_errors without dropping empty summary buckets" do
    assert {:ok, result} =
             Result.new(
               domain: "example.com",
               facts: %{spf: %{records: ["v=spf1 -all"]}},
               resolver_errors: [
                 %{lookup: :txt, domain: "selector._domainkey.example.com", reason: :timeout}
               ]
             )

    assert result.summary == %{pass: 0, warn: 0, fail: 0, cannot_verify: 0}
    assert result.facts.spf == %{records: ["v=spf1 -all"]}
    assert result.facts.dkim == %{}
    assert result.resolver_errors == [
             %{lookup: :txt, domain: "selector._domainkey.example.com", reason: :timeout}
           ]
  end

  defp finding(status, area, check) do
    %{
      area: area,
      check: check,
      status: status,
      title: "Finding #{check}",
      why_it_matters: "This matters for deliverability truth.",
      observed: "Observed state for #{check}.",
      remediation: "Remediate #{check} if needed."
    }
  end
end
