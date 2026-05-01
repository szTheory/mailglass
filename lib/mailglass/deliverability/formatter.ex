defmodule Mailglass.Deliverability.Formatter do
  @moduledoc """
  Shared human and JSON renderers for deliverability results.
  """

  @section_order [:spf, :dkim, :dmarc, :mx, :bimi]

  @spec render_human(Mailglass.Deliverability.Result.t(), keyword()) :: String.t()
  def render_human(result, opts \\ []) when is_map(result) and is_list(opts) do
    verbose? = Keyword.get(opts, :verbose?, false)

    [
      summary_line(result),
      Enum.map_join(@section_order, "\n\n", &render_section(&1, result.findings, verbose?))
    ]
    |> Enum.join("\n\n")
  end

  @spec render_json(Mailglass.Deliverability.Result.t()) :: String.t()
  def render_json(result) when is_map(result) do
    Jason.encode!(result)
  end

  defp summary_line(result) do
    summary = result.summary

    "#{result.domain}: #{summary.pass} pass, #{summary.warn} warn, #{summary.fail} fail, #{summary.cannot_verify} cannot_verify"
  end

  defp render_section(area, findings, verbose?) do
    area_findings = Enum.filter(findings, &(&1.area == area))

    lines =
      case area_findings do
        [] ->
          ["No findings."]

        _ ->
          Enum.flat_map(area_findings, &render_finding(&1, verbose?))
      end

    [section_label(area) | lines]
    |> Enum.join("\n")
  end

  defp render_finding(finding, verbose?) do
    base_lines = [
      "[#{finding.status}] #{finding.title}",
      "Why it matters: #{finding.why_it_matters}",
      "Observed: #{finding.observed}",
      "Remediation: #{finding.remediation}"
    ]

    case verbose? and Map.has_key?(finding, :evidence) do
      true -> base_lines ++ ["Evidence: " <> inspect(finding.evidence, pretty: true, limit: :infinity)]
      false -> base_lines
    end
  end

  defp section_label(:spf), do: "SPF"
  defp section_label(:dkim), do: "DKIM"
  defp section_label(:dmarc), do: "DMARC"
  defp section_label(:mx), do: "MX"
  defp section_label(:bimi), do: "BIMI"
end
