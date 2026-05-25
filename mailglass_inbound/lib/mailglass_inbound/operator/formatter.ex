defmodule MailglassInbound.Operator.Formatter do
  @moduledoc """
  Shared human and JSON renderers for inbound operator results (D-49-04).

  Cloned from `Mailglass.Deliverability.Formatter` (`render_human/2` +
  `render_json/1`), adapted to the locked D-49-05 finding shape
  `%{check, status, title, observed, remediation, evidence}` (no `:why_it_matters`,
  no `:area`). The summary line is `"N pass, N warn, N fail"`; cannot-diagnose is
  surfaced via the doctor's exit code (2), not a tally column.

  `render_json/1` emits ONE machine-parseable object
  `%{summary: %{pass, warn, fail}, findings: [...]}` — never a bare list.
  """

  @type finding :: %{
          required(:check) => atom(),
          required(:status) => :pass | :warn | :fail,
          required(:title) => String.t(),
          required(:observed) => String.t(),
          required(:remediation) => String.t(),
          optional(:evidence) => map()
        }

  @type result :: %{
          required(:summary) => map(),
          required(:findings) => [finding()]
        }

  @doc """
  Render a doctor result as human-readable text: a summary line followed by every
  finding (`[status] title` + observed/remediation), joined with blank lines. When
  `verbose?: true`, findings carrying `:evidence` append a pretty-printed dump.
  """
  @spec render_human(result(), keyword()) :: String.t()
  def render_human(result, opts \\ []) when is_map(result) and is_list(opts) do
    verbose? = Keyword.get(opts, :verbose?, false)

    [
      summary_line(result),
      Enum.map_join(result.findings, "\n\n", &render_finding(&1, verbose?))
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  @doc """
  Render a doctor result as one JSON object `%{summary, findings}`.
  """
  @spec render_json(result()) :: String.t()
  def render_json(result) when is_map(result) do
    Jason.encode!(%{summary: result.summary, findings: result.findings})
  end

  defp summary_line(%{summary: summary}) do
    "#{Map.get(summary, :pass, 0)} pass, #{Map.get(summary, :warn, 0)} warn, #{Map.get(summary, :fail, 0)} fail"
  end

  defp render_finding(finding, verbose?) do
    base_lines = [
      "[#{finding.status}] #{finding.title}",
      "Observed: #{finding.observed}",
      "Remediation: #{finding.remediation}"
    ]

    lines =
      case verbose? and Map.has_key?(finding, :evidence) do
        true ->
          base_lines ++ ["Evidence: " <> inspect(finding.evidence, pretty: true, limit: :infinity)]

        false ->
          base_lines
      end

    Enum.join(lines, "\n")
  end
end
