defmodule Mailglass.Deliverability.BIMI do
  @moduledoc """
  BIMI readiness analyzer for the default selector only.
  """

  @type analysis_result :: %{
          required(:findings) => [map()],
          required(:facts) => map()
        }

  @spec analyze(map(), keyword()) :: analysis_result()
  def analyze(bimi_facts, opts \\ []) when is_map(bimi_facts) and is_list(opts) do
    domain = Map.get(bimi_facts, :domain)
    txt_records = Map.get(bimi_facts, :txt_records, [])
    dmarc_posture = Keyword.get(opts, :dmarc_posture)

    findings = dmarc_prerequisite_findings(dmarc_posture)

    cond do
      malformed_txt_records?(txt_records) ->
        %{
          findings:
            findings ++
              [
                finding(
                  :cannot_verify,
                  :malformed_records,
                  "BIMI DNS data could not be trusted",
                  "Malformed TXT answers make it unsafe to claim BIMI readiness.",
                  "Observed TXT answers at #{domain} but the data shape was not valid text.",
                  "Inspect the DNS answer directly and republish one valid BIMI TXT record."
                )
                |> with_evidence(%{txt_records: txt_records})
              ],
          facts:
            bimi_facts
            |> Map.put(:record, nil)
            |> Map.put(:tags, %{})
            |> Map.put(:dmarc_posture, dmarc_posture)
        }

      txt_records == [] ->
        %{
          findings:
            findings ++
              [
                finding(
                  :warn,
                  :missing_record,
                  "BIMI record is not published",
                  "Missing BIMI does not break mail delivery, but it means brand-indicator readiness is not configured.",
                  "Found no BIMI TXT record at #{domain}.",
                  "Publish one `v=BIMI1` TXT record at the default selector if you want BIMI readiness guidance."
                )
              ],
          facts:
            bimi_facts
            |> Map.put(:record, nil)
            |> Map.put(:tags, %{})
            |> Map.put(:dmarc_posture, dmarc_posture)
        }

      true ->
        analyze_record(bimi_facts, findings, dmarc_posture)
    end
  end

  defp analyze_record(bimi_facts, findings, dmarc_posture) do
    domain = Map.get(bimi_facts, :domain)
    bimi_records = Enum.filter(Map.get(bimi_facts, :txt_records, []), &bimi_record?/1)

    case bimi_records do
      [] ->
        %{
          findings:
            findings ++
              [
                finding(
                  :cannot_verify,
                  :missing_bimi_payload,
                  "BIMI TXT answers were present but not parseable as BIMI",
                  "TXT answers at the BIMI selector are only useful when one record starts with `v=BIMI1`.",
                  "Found TXT answers at #{domain}, but none started with `v=BIMI1`.",
                  "Replace the selector contents with one valid BIMI record."
                )
                |> with_evidence(%{txt_records: Map.get(bimi_facts, :txt_records, [])})
              ],
          facts:
            bimi_facts
            |> Map.put(:record, nil)
            |> Map.put(:tags, %{})
            |> Map.put(:dmarc_posture, dmarc_posture)
        }

      [_first, _second | _rest] = records ->
        %{
          findings:
            findings ++
              [
                finding(
                  :fail,
                  :multiple_records,
                  "Multiple BIMI records were published",
                  "The default BIMI selector should publish one record so mailbox providers do not see conflicting brand instructions.",
                  "Found #{length(records)} BIMI records at #{domain}.",
                  "Collapse the selector to one `v=BIMI1` TXT record."
                )
                |> with_evidence(%{records: records})
              ],
          facts:
            bimi_facts
            |> Map.put(:record, nil)
            |> Map.put(:tags, %{})
            |> Map.put(:dmarc_posture, dmarc_posture)
        }

      [record] ->
        case parse_tag_string(record, "BIMI1") do
          {:error, reason} ->
            %{
              findings:
                findings ++
                  [
                    finding(
                      :cannot_verify,
                      :malformed_record,
                      "BIMI tag syntax is malformed",
                      "Malformed BIMI tags prevent a trustworthy readiness claim.",
                      "Could not parse the BIMI record at #{domain}: #{format_parse_error(reason)}.",
                      "Fix the BIMI tag syntax and retry."
                    )
                    |> with_evidence(%{record: record})
                  ],
              facts:
                bimi_facts
                |> Map.put(:record, record)
                |> Map.put(:tags, %{})
                |> Map.put(:dmarc_posture, dmarc_posture)
            }

          {:ok, tags} ->
            %{
              findings: findings ++ content_findings(tags),
              facts:
                bimi_facts
                |> Map.put(:record, record)
                |> Map.put(:tags, tags)
                |> Map.put(:dmarc_posture, dmarc_posture)
            }
        end
    end
  end

  defp dmarc_prerequisite_findings(posture) when posture in [:partial_enforcement, :enforcement], do: []

  defp dmarc_prerequisite_findings(posture) do
    [
      finding(
        :warn,
        :dmarc_prerequisite,
        "BIMI needs DMARC enforcement first",
        "Mailbox providers generally expect DMARC enforcement before BIMI can be treated as ready.",
        "The shared DMARC result was #{format_posture(posture)}.",
        "Move DMARC to at least quarantine or reject before treating BIMI as ready."
      )
    ]
  end

  defp content_findings(tags) do
    []
    |> add_logo_finding(tags)
    |> add_certificate_finding(tags)
    |> add_provider_caveat(tags)
  end

  defp add_logo_finding(findings, %{"l" => logo_location} = tags) when logo_location != "" do
    findings ++
      [
        finding(
          :pass,
          :logo_location_present,
          "BIMI logo location is published",
          "The `l=` tag points mailbox providers to the hosted SVG asset used for BIMI evaluation.",
          "Found l=#{logo_location} in the BIMI record.",
          "Keep the hosted logo reachable, HTTPS-served, and aligned with the brand asset you intend receivers to evaluate."
        )
        |> with_evidence(%{tags: Map.take(tags, ["l", "a"])})
      ]
  end

  defp add_logo_finding(findings, _tags) do
    findings ++
      [
        finding(
          :fail,
          :missing_logo_location,
          "BIMI logo location is missing",
          "Without `l=`, mailbox providers have no BIMI logo location to evaluate.",
          "The BIMI record did not include an `l=` tag.",
          "Add an `l=` tag that points to the hosted SVG you want providers to inspect."
        )
      ]
  end

  defp add_certificate_finding(findings, %{"a" => certificate_location}) when certificate_location != "" do
    findings ++
      [
        finding(
          :pass,
          :certificate_location_present,
          "BIMI certificate location is published",
          "Some mailbox providers check `a=` for a Verified Mark Certificate or equivalent supporting credential.",
          "Found a=#{certificate_location} in the BIMI record.",
          "Keep the certificate URL current and aligned with your provider-specific BIMI rollout requirements."
        )
      ]
  end

  defp add_certificate_finding(findings, _tags) do
    findings ++
      [
        finding(
          :warn,
          :certificate_location_missing,
          "BIMI certificate location is not published",
          "Some providers can require a certificate or additional validation before they show a logo.",
          "The BIMI record did not include an `a=` tag.",
          "Check your mailbox-provider requirements and publish a certificate reference if your rollout needs one."
        )
      ]
  end

  defp add_provider_caveat(findings, tags) do
    findings ++
      [
        finding(
          :warn,
          :provider_caveat,
          "BIMI display still depends on mailbox-provider rules",
          "Publishing BIMI DNS data does not guarantee that every mailbox provider will display a logo.",
          observed_provider_caveat(tags),
          "Confirm provider-specific SVG, certificate, and reputation requirements before treating logo display as complete."
        )
      ]
  end

  defp observed_provider_caveat(tags) do
    logo = Map.get(tags, "l", "missing")
    certificate = Map.get(tags, "a", "missing")
    "Published BIMI with l=#{logo} and a=#{certificate}."
  end

  defp malformed_txt_records?(txt_records) do
    not (is_list(txt_records) and Enum.all?(txt_records, &is_binary/1))
  end

  defp bimi_record?(record) when is_binary(record) do
    String.match?(String.trim(record), ~r/^v=BIMI1(?:\s*;|$)/i)
  end

  defp bimi_record?(_record), do: false

  defp parse_tag_string(record, version) do
    segments =
      record
      |> String.split(";", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case segments do
      [first | rest] ->
        with true <- String.downcase(first) == "v=#{String.downcase(version)}",
             {:ok, tags} <- parse_segments(rest, %{}) do
          {:ok, Map.put(tags, "v", version)}
        else
          false -> {:error, :missing_version_tag}
          {:error, reason} -> {:error, reason}
        end

      [] ->
        {:error, :empty_record}
    end
  end

  defp parse_segments([], tags), do: {:ok, tags}

  defp parse_segments([segment | rest], tags) do
    case String.split(segment, "=", parts: 2) do
      [key, value] ->
        key = String.trim(key)

        if key == "" do
          {:error, :blank_tag_key}
        else
          parse_segments(rest, Map.put(tags, String.downcase(key), String.trim(value)))
        end

      _ ->
        {:error, {:invalid_segment, segment}}
    end
  end

  defp format_posture(:enforcement), do: "DMARC enforcement (`p=reject`)"
  defp format_posture(:partial_enforcement), do: "DMARC partial enforcement (`p=quarantine`)"
  defp format_posture(:monitoring), do: "DMARC monitoring (`p=none`)"
  defp format_posture(:invalid), do: "an invalid DMARC policy posture"
  defp format_posture(nil), do: "missing or unavailable DMARC posture"
  defp format_posture(other), do: inspect(other)

  defp format_parse_error(:missing_version_tag), do: "missing v=BIMI1"
  defp format_parse_error(:empty_record), do: "empty record"
  defp format_parse_error(:blank_tag_key), do: "blank tag key"
  defp format_parse_error({:invalid_segment, segment}), do: "invalid segment #{inspect(segment)}"
  defp format_parse_error(other), do: inspect(other)

  defp finding(status, check, title, why_it_matters, observed, remediation) do
    %{
      area: :bimi,
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
