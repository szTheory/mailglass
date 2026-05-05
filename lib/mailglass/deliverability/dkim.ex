defmodule Mailglass.Deliverability.DKIM do
  @moduledoc """
  Explicit-selector DKIM analyzer.
  """

  @short_key_threshold 128

  @type analysis_result :: %{
          required(:findings) => [map()],
          required(:facts) => map()
        }

  @spec analyze(map(), keyword()) :: analysis_result()
  def analyze(dkim_facts, _opts \\ []) when is_map(dkim_facts) do
    selectors = Map.get(dkim_facts, :selectors, [])

    case selectors do
      [] ->
        %{
          findings: [
            finding(
              :cannot_verify,
              :selector_required,
              "DKIM selectors were not provided",
              "DNS alone cannot prove DKIM coverage unless you name the selectors your mail stream actually uses.",
              "No explicit DKIM selectors were supplied for this domain.",
              "Re-run the doctor with one or more explicit DKIM selectors from your ESP or sending domain setup."
            )
          ],
          facts: Map.put(dkim_facts, :checked_selector_count, 0)
        }

      _ ->
        {findings, normalized_selectors} =
          Enum.reduce(selectors, {[], []}, fn selector_entry, {acc_findings, acc_selectors} ->
            {selector_findings, normalized_selector} = analyze_selector(selector_entry)
            {acc_findings ++ selector_findings, acc_selectors ++ [normalized_selector]}
          end)

        findings =
          if findings == [] do
            [
              finding(
                :pass,
                :selectors_present,
                "DKIM selector records are present",
                "Mailglass can confirm that every explicit selector published DNS material without guessing provider folklore.",
                "Validated #{length(normalized_selectors)} explicit DKIM selector records.",
                "Keep using explicit selectors when auditing DKIM changes."
              )
              |> with_evidence(%{selectors: Enum.map(normalized_selectors, &selector_label/1)})
            ]
          else
            findings
          end

        %{
          findings: findings,
          facts:
            dkim_facts
            |> Map.put(:selectors, normalized_selectors)
            |> Map.put(:checked_selector_count, length(normalized_selectors))
        }
    end
  end

  defp analyze_selector(selector_entry) when is_map(selector_entry) do
    selector = Map.get(selector_entry, :selector)
    txt_records = Map.get(selector_entry, :txt_records, [])
    cname = Map.get(selector_entry, :cname)

    normalized_selector =
      selector_entry
      |> Map.put(:txt_records, normalize_txt_records(txt_records))
      |> Map.put(:cname, normalize_cname(cname))

    cond do
      not is_binary(selector) or String.trim(selector) == "" ->
        selector_issue(
          normalized_selector,
          :cannot_verify,
          :invalid_selector,
          "Selector entry is malformed"
        )

      malformed_txt?(txt_records) or malformed_cname?(cname) ->
        selector_issue(
          normalized_selector,
          :cannot_verify,
          :malformed_selector_data,
          "Selector #{selector} returned malformed TXT or CNAME data"
        )

      normalized_selector.txt_records == [] and is_nil(normalized_selector.cname) ->
        selector_issue(
          normalized_selector,
          :fail,
          :missing_selector_record,
          "Selector #{selector} published no TXT or CNAME record"
        )

      true ->
        selector_findings =
          []
          |> maybe_add_cname_presence(normalized_selector)
          |> maybe_add_txt_findings(normalized_selector)

        {selector_findings, normalized_selector}
    end
  end

  defp analyze_selector(selector_entry) do
    normalized_selector = %{
      selector: nil,
      domain: nil,
      txt_records: [],
      cname: nil,
      raw: selector_entry
    }

    {
      [
        finding(
          :cannot_verify,
          :malformed_selector_data,
          "Selector entry is malformed",
          "The analyzer can only make selector-specific claims when the collected DKIM facts have the expected shape.",
          "Received a non-map DKIM selector entry.",
          "Retry the doctor and inspect the collected DKIM facts before trusting this result."
        )
      ],
      normalized_selector
    }
  end

  defp maybe_add_cname_presence(findings, %{selector: selector, cname: cname})
       when is_binary(cname) and cname != "" do
    findings ++
      [
        finding(
          :pass,
          :selector_cname_present,
          "Selector #{selector} delegates by CNAME",
          "A DKIM selector may legitimately delegate to provider-managed DNS by CNAME.",
          "Found CNAME #{cname} for selector #{selector}.",
          "Verify the delegated target is the selector your ESP expects."
        )
        |> with_evidence(%{selector: selector, cname: cname})
      ]
  end

  defp maybe_add_cname_presence(findings, _selector), do: findings

  defp maybe_add_txt_findings(findings, %{txt_records: []}), do: findings

  defp maybe_add_txt_findings(findings, selector) do
    dkim_records = Enum.filter(selector.txt_records, &dkim_record?/1)

    case dkim_records do
      [] ->
        findings ++
          [
            finding(
              :fail,
              :missing_dkim_txt,
              "Selector #{selector.selector} has no DKIM TXT payload",
              "A selector without a DKIM TXT payload cannot be validated from DNS alone.",
              "Found TXT answers for #{selector.selector} but none started with v=DKIM1.",
              "Publish a valid v=DKIM1 TXT record or a delegating CNAME for this selector."
            )
          ]

      [_first, _second | _rest] = records ->
        findings ++
          [
            finding(
              :fail,
              :multiple_dkim_txt,
              "Selector #{selector.selector} published multiple DKIM TXT records",
              "Multiple DKIM TXT payloads at one selector create ambiguity and can break verification.",
              "Found #{length(records)} DKIM TXT records for selector #{selector.selector}.",
              "Collapse the selector to one DKIM TXT record."
            )
            |> with_evidence(%{selector: selector.selector, records: records})
          ]

      [record] ->
        analyze_dkim_record(findings, selector, record)
    end
  end

  defp analyze_dkim_record(findings, selector, record) do
    case parse_tag_string(record, "DKIM1") do
      {:error, reason} ->
        findings ++
          [
            finding(
              :cannot_verify,
              :malformed_dkim_record,
              "Selector #{selector.selector} has malformed DKIM tags",
              "Malformed DKIM TXT data prevents a trustworthy selector-specific conclusion.",
              "Could not parse #{selector.selector}: #{format_parse_error(reason)}.",
              "Fix the DKIM tag syntax for this selector and retry."
            )
            |> with_evidence(%{selector: selector.selector, record: record})
          ]

      {:ok, tags} ->
        findings
        |> maybe_add_revoked_key(selector, tags)
        |> maybe_add_short_key_warning(selector, tags)
        |> maybe_add_legacy_warning(selector, tags)
        |> maybe_add_selector_pass(selector, tags)
    end
  end

  defp maybe_add_revoked_key(findings, selector, tags) do
    if Map.get(tags, "p") == "" do
      findings ++
        [
          finding(
            :fail,
            :revoked_key,
            "Selector #{selector.selector} is revoked",
            "A DKIM selector with an empty p= value is explicitly revoked and cannot validate signatures.",
            "Found v=DKIM1 with an empty p= value for selector #{selector.selector}.",
            "Publish an active key for this selector or stop using it in your mail stream."
          )
          |> with_evidence(%{selector: selector.selector, domain: selector.domain})
        ]
    else
      findings
    end
  end

  defp maybe_add_short_key_warning(findings, selector, tags) do
    case Map.get(tags, "p") do
      value when is_binary(value) and value != "" ->
        value
        |> Base.decode64(ignore: :whitespace)
        |> case do
          {:ok, decoded} when byte_size(decoded) < @short_key_threshold ->
            findings ++
              [
                finding(
                  :warn,
                  :short_key,
                  "Selector #{selector.selector} uses a short DKIM key",
                  "Short DKIM keys are weaker and more likely to be rejected by modern mailbox-provider guidance.",
                  "Decoded p= for selector #{selector.selector} to #{byte_size(decoded)} bytes.",
                  "Rotate this selector to a stronger DKIM key, ideally 2048-bit RSA or equivalent provider guidance."
                )
                |> with_evidence(%{selector: selector.selector, decoded_bytes: byte_size(decoded)})
              ]

          _ ->
            findings
        end

      _ ->
        findings
    end
  end

  defp maybe_add_legacy_warning(findings, selector, tags) do
    algorithms =
      tags
      |> Map.get("h", "")
      |> String.downcase()

    if algorithms != "" and String.contains?(algorithms, "sha1") do
      findings ++
        [
          finding(
            :warn,
            :legacy_hash,
            "Selector #{selector.selector} still advertises SHA-1",
            "SHA-1 is legacy cryptography and should not remain part of a modern DKIM posture.",
            "Found h=#{Map.get(tags, "h")} for selector #{selector.selector}.",
            "Publish a DKIM record that advertises sha256 only."
          )
          |> with_evidence(%{selector: selector.selector, algorithms: Map.get(tags, "h")})
        ]
    else
      findings
    end
  end

  defp maybe_add_selector_pass(findings, selector, tags) do
    statuses = Enum.map(findings, & &1.status)

    if :fail in statuses or :cannot_verify in statuses do
      findings
    else
      findings ++
        [
          finding(
            :pass,
            :selector_record_present,
            "Selector #{selector.selector} published DKIM material",
            "Mailglass can confirm this selector has DNS material without claiming the whole domain passes DKIM in production.",
            observed_selector(selector, tags),
            "Confirm your ESP signs mail with this selector and rotate keys on your normal schedule."
          )
          |> with_evidence(%{
            selector: selector.selector,
            domain: selector.domain,
            tags: Map.take(tags, ["k", "h", "t"])
          })
        ]
    end
  end

  defp selector_issue(selector, status, check, observed) do
    {
      [
        finding(
          status,
          check,
          "Selector #{selector_label(selector)} could not be trusted",
          "DKIM findings stay selector-specific and explicit about uncertainty.",
          observed,
          "Inspect the selector DNS entry directly and repair it before trusting DKIM coverage."
        )
        |> with_evidence(%{selector: selector.selector, domain: selector.domain})
      ],
      selector
    }
  end

  defp normalize_txt_records(records) when is_list(records) do
    if Enum.all?(records, &is_binary/1), do: records, else: []
  end

  defp normalize_txt_records(_records), do: []

  defp normalize_cname(cname) when is_binary(cname) do
    case String.trim(cname) do
      "" -> nil
      value -> value
    end
  end

  defp normalize_cname(_cname), do: nil

  defp malformed_txt?(records), do: not (is_list(records) and Enum.all?(records, &is_binary/1))
  defp malformed_cname?(nil), do: false
  defp malformed_cname?(cname), do: not is_binary(cname)

  defp dkim_record?(record) when is_binary(record) do
    String.match?(String.trim(record), ~r/^v=DKIM1(?:\s*;|$)/i)
  end

  defp dkim_record?(_record), do: false

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

  defp observed_selector(selector, tags) do
    key_type = Map.get(tags, "k", "rsa")
    "Found selector #{selector.selector} with DKIM key type #{key_type}."
  end

  defp selector_label(%{selector: selector}) when is_binary(selector) and selector != "",
    do: selector

  defp selector_label(_selector), do: "unknown"

  defp format_parse_error(:missing_version_tag), do: "missing v=DKIM1"
  defp format_parse_error(:empty_record), do: "empty record"
  defp format_parse_error(:blank_tag_key), do: "blank tag key"
  defp format_parse_error({:invalid_segment, segment}), do: "invalid segment #{inspect(segment)}"
  defp format_parse_error(other), do: inspect(other)

  defp finding(status, check, title, why_it_matters, observed, remediation) do
    %{
      area: :dkim,
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
