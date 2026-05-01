defmodule Mailglass.Deliverability.FormatterTest do
  use ExUnit.Case, async: true

  alias Mailglass.Deliverability.{Formatter, Result}

  test "renders sections in SPF, DKIM, DMARC, MX, BIMI order" do
    output = Formatter.render_human(sample_result())

    indices =
      Enum.map(["\n\nSPF\n", "\n\nDKIM\n", "\n\nDMARC\n", "\n\nMX\n", "\n\nBIMI\n"], fn heading ->
        output
        |> :binary.match(heading)
        |> elem(0)
      end)

    assert indices == Enum.sort(indices)
  end

  test "verbose output includes evidence while default output does not" do
    result = sample_result()

    refute Formatter.render_human(result) =~ "Evidence:"
    assert Formatter.render_human(result, verbose?: true) =~ "Evidence:"
  end

  test "json output preserves schema_version and result shape" do
    output = Formatter.render_json(sample_result())

    assert output =~ "\"schema_version\":1"
    assert output =~ "\"summary\""
    assert output =~ "\"findings\""
    assert output =~ "\"resolver_errors\""
  end

  defp sample_result do
    {:ok, result} =
      Result.new(
        domain: "example.com",
        findings: [
          %{
            area: :spf,
            check: :policy,
            status: :pass,
            title: "SPF is present",
            why_it_matters: "Mailbox providers expect a sender policy.",
            observed: "Found v=spf1 -all.",
            remediation: "No action required.",
            evidence: %{record: "v=spf1 -all"}
          },
          %{
            area: :dkim,
            check: :selector_required,
            status: :cannot_verify,
            title: "DKIM selectors were not provided",
            why_it_matters: "DKIM needs explicit selector context.",
            observed: "No selectors were supplied.",
            remediation: "Re-run with explicit selectors."
          },
          %{
            area: :dmarc,
            check: :monitoring_policy,
            status: :warn,
            title: "DMARC policy is monitoring-only",
            why_it_matters: "BIMI and spoofing resistance improve with enforcement.",
            observed: "Found p=none.",
            remediation: "Move toward quarantine or reject."
          },
          %{
            area: :mx,
            check: :mx_present,
            status: :pass,
            title: "MX records are published",
            why_it_matters: "Inbound routing stays explicit.",
            observed: "Found one MX host.",
            remediation: "No action required."
          },
          %{
            area: :bimi,
            check: :missing_record,
            status: :warn,
            title: "BIMI record is not published",
            why_it_matters: "BIMI is optional but useful for readiness.",
            observed: "Found no BIMI TXT record.",
            remediation: "Publish one record if you want BIMI readiness guidance."
          }
        ],
        facts: %{
          spf: %{txt_records: ["v=spf1 -all"]},
          dkim: %{selectors: []},
          dmarc: %{txt_records: ["v=DMARC1; p=none"]},
          mx: %{records: [%{exchange: "mx1.example.com", preference: 10}]},
          bimi: %{txt_records: []}
        },
        resolver_errors: [
          %{lookup: :txt, domain: "_dmarc.example.com", reason: :timeout}
        ]
      )

    result
  end
end
