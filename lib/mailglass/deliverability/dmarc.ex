defmodule Mailglass.Deliverability.DMARC do
  @moduledoc """
  Policy-aware DMARC analyzer.
  """

  @type analysis_result :: %{
          required(:findings) => [map()],
          required(:facts) => map()
        }

  @spec analyze(map(), keyword()) :: analysis_result()
  def analyze(dmarc_facts, _opts \\ []) when is_map(dmarc_facts) do
    domain = Map.get(dmarc_facts, :domain)
    txt_records = Map.get(dmarc_facts, :txt_records, [])
    dmarc_records = Enum.filter(txt_records, &dmarc_record?/1)

    case dmarc_records do
      [] ->
        %{
          findings: [
            finding(
              :fail,
              :missing_record,
              "DMARC record is missing",
              "Without DMARC, mailbox providers have no domain-level policy signal for spoofed mail.",
              "Found no TXT record that starts with v=DMARC1 at #{domain}.",
              "Publish exactly one DMARC TXT record at _dmarc for this domain."
            )
          ],
          facts: dmarc_facts
        }

      [_first, _second | _rest] = records ->
        %{
          findings: [
            finding(
              :fail,
              :multiple_records,
              "Multiple DMARC records were published",
              "DMARC permits exactly one record. Multiple records create an invalid policy surface.",
              "Found #{length(records)} DMARC TXT records at #{domain}.",
              "Collapse the DMARC policy to one TXT record."
            )
            |> with_evidence(%{records: records})
          ],
          facts: dmarc_facts
        }

      [record] ->
        analyze_record(dmarc_facts, record)
    end
  end

  defp analyze_record(dmarc_facts, record) do
    case parse_tag_string(record) do
      {:error, reason} ->
        %{
          findings: [
            finding(
              :fail,
              :malformed_record,
              "DMARC tag syntax is malformed",
              "Malformed DMARC tags leave receivers without a trustworthy policy.",
              "Could not parse #{inspect(record)}: #{format_parse_error(reason)}.",
              "Fix the DMARC tag syntax and retry."
            )
          ],
          facts: dmarc_facts
        }

      {:ok, tags} ->
        posture = posture(Map.get(tags, "p"))

        findings =
          []
          |> add_policy_finding(tags)
          |> add_alignment_finding(tags, "adkim")
          |> add_alignment_finding(tags, "aspf")
          |> add_reporting_finding(tags)
          |> add_subdomain_policy_finding(tags)

        %{
          findings: findings,
          facts:
            dmarc_facts
            |> Map.put(:record, record)
            |> Map.put(:tags, tags)
            |> Map.put(:posture, posture)
        }
    end
  end

  defp add_policy_finding(findings, %{"p" => "none"} = tags) do
    findings ++
      [
        finding(
          :warn,
          :monitoring_policy,
          "DMARC policy is monitoring-only",
          "p=none publishes DMARC but does not ask receivers to quarantine or reject spoofed mail.",
          "Found p=none in the DMARC record.",
          "Move to quarantine or reject after reviewing legitimate traffic."
        )
        |> with_evidence(%{policy: tags["p"]})
      ]
  end

  defp add_policy_finding(findings, %{"p" => "quarantine"} = tags) do
    findings ++
      [
        finding(
          :warn,
          :partial_enforcement,
          "DMARC policy is partial enforcement",
          "quarantine is stronger than monitoring but still stops short of full reject posture.",
          "Found p=quarantine in the DMARC record.",
          "Move to p=reject once legitimate traffic is aligned."
        )
        |> with_evidence(%{policy: tags["p"]})
      ]
  end

  defp add_policy_finding(findings, %{"p" => "reject"} = tags) do
    findings ++
      [
        finding(
          :pass,
          :enforcement_policy,
          "DMARC policy is enforcing",
          "p=reject is the strongest DMARC posture this DNS-only check can confirm.",
          "Found p=reject in the DMARC record.",
          "Maintain alignment across all legitimate mail sources."
        )
        |> with_evidence(%{policy: tags["p"]})
      ]
  end

  defp add_policy_finding(_findings, _tags) do
    [
      finding(
        :fail,
        :invalid_policy,
        "DMARC policy tag is invalid",
        "A DMARC record without a valid p= value cannot communicate receiver policy.",
        "The DMARC record did not contain a valid p=none, p=quarantine, or p=reject value.",
        "Set p=none, p=quarantine, or p=reject explicitly."
      )
    ]
  end

  defp add_alignment_finding(findings, tags, tag) do
    case Map.get(tags, tag) do
      nil ->
        findings ++
          [
            finding(
              :warn,
              String.to_atom("missing_#{tag}"),
              "#{String.upcase(tag)} alignment mode relies on the relaxed default",
              "Absent alignment tags default to relaxed mode, which is valid but less explicit for operators.",
              "No #{tag}= tag was present in the DMARC record.",
              "Set #{tag}=s or #{tag}=r explicitly so the intended alignment posture is documented."
            )
          ]

      value ->
        findings ++
          [
            finding(
              :pass,
              String.to_atom("#{tag}_present"),
              "#{String.upcase(tag)} alignment mode is explicit",
              "Explicit alignment tags make the DMARC policy easier to audit and reason about.",
              "Found #{tag}=#{value} in the DMARC record.",
              "No action required unless you intend to change alignment strictness."
            )
            |> with_evidence(%{tag => value})
          ]
    end
  end

  defp add_reporting_finding(findings, tags) do
    case Map.get(tags, "rua") do
      nil ->
        findings ++
          [
            finding(
              :warn,
              :missing_rua,
              "DMARC aggregate reporting is not configured",
              "Aggregate reports help validate alignment changes before you tighten enforcement.",
              "No rua= tag was present in the DMARC record.",
              "Add a monitored rua= mailbox if you want aggregate DMARC telemetry."
            )
          ]

      value ->
        findings ++
          [
            finding(
              :pass,
              :rua_present,
              "DMARC aggregate reporting is configured",
              "Aggregate reports provide visibility into legitimate and spoofed traffic patterns.",
              "Found rua=#{value} in the DMARC record.",
              "Keep the reporting mailbox monitored and working."
            )
            |> with_evidence(%{"rua" => value})
          ]
    end
  end

  defp add_subdomain_policy_finding(findings, tags) do
    case Map.get(tags, "sp") do
      nil ->
        findings ++
          [
            finding(
              :warn,
              :missing_sp,
              "DMARC subdomain policy is not explicit",
              "Absent sp= means subdomains inherit p=, which is valid but easy to overlook operationally.",
              "No sp= tag was present in the DMARC record.",
              "Set sp= explicitly if subdomains need a different posture or you want the inheritance to be obvious."
            )
          ]

      value ->
        findings ++
          [
            finding(
              :pass,
              :subdomain_policy_present,
              "DMARC subdomain policy is explicit",
              "An explicit sp= tag documents how subdomains should be treated.",
              "Found sp=#{value} in the DMARC record.",
              "No action required unless your subdomain policy should change."
            )
            |> with_evidence(%{"sp" => value})
          ]
    end
  end

  defp dmarc_record?(record) when is_binary(record) do
    String.match?(String.trim(record), ~r/^v=DMARC1(?:\s*;|$)/i)
  end

  defp dmarc_record?(_record), do: false

  defp parse_tag_string(record) do
    segments =
      record
      |> String.split(";", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case segments do
      ["v=DMARC1" | rest] ->
        parse_segments(rest, %{"v" => "DMARC1"})

      [first | _rest] ->
        if String.downcase(first) == "v=dmarc1" do
          parse_segments(tl(segments), %{"v" => "DMARC1"})
        else
          {:error, :missing_version_tag}
        end

      [] ->
        {:error, :empty_record}
    end
  end

  defp parse_segments([], tags), do: {:ok, tags}

  defp parse_segments([segment | rest], tags) do
    case String.split(segment, "=", parts: 2) do
      [key, value] ->
        key = String.downcase(String.trim(key))

        if key == "" do
          {:error, :blank_tag_key}
        else
          parse_segments(rest, Map.put(tags, key, String.trim(value)))
        end

      _ ->
        {:error, {:invalid_segment, segment}}
    end
  end

  defp posture("reject"), do: :enforcement
  defp posture("quarantine"), do: :partial_enforcement
  defp posture("none"), do: :monitoring
  defp posture(_policy), do: :invalid

  defp format_parse_error(:missing_version_tag), do: "missing v=DMARC1"
  defp format_parse_error(:empty_record), do: "empty record"
  defp format_parse_error(:blank_tag_key), do: "blank tag key"
  defp format_parse_error({:invalid_segment, segment}), do: "invalid segment #{inspect(segment)}"
  defp format_parse_error(other), do: inspect(other)

  defp finding(status, check, title, why_it_matters, observed, remediation) do
    %{
      area: :dmarc,
      check: check,
      status: status,
      title: title,
      why_it_matters: why_it_matters,
      observed: observed,
      remediation: remediation
    }
  end

  defp with_evidence(finding, evidence), do: Map.put(finding, :evidence, evidence)
end
