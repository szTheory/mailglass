defmodule MailglassInbound.Operator.Formatter do
  @moduledoc """
  Shared human and JSON renderers for inbound operator results (the design contract).

  Cloned from `Mailglass.Deliverability.Formatter` (`render_human/2` +
  `render_json/1`), adapted to the locked the design contract finding shape
  `%{check, status, title, observed, remediation, evidence}` (no `:why_it_matters`,
  no `:area`). The summary line is `"N pass, N warn, N fail"`, plus a trailing
  `", N cannot diagnose"` only when the summary carries a non-zero
  `:cannot_diagnose` count (WR-04 — a cannot-diagnose state is a distinct
  disposition from a failed check, so it is no longer folded into the `fail`
  tally). It also still drives the doctor's exit code (2).

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
    base =
      "#{Map.get(summary, :pass, 0)} pass, #{Map.get(summary, :warn, 0)} warn, #{Map.get(summary, :fail, 0)} fail"

    # WR-04: only surface the cannot-diagnose count when there is one, so a normal
    # run keeps the familiar "N pass, N warn, N fail" line.
    case Map.get(summary, :cannot_diagnose, 0) do
      n when is_integer(n) and n > 0 -> base <> ", #{n} cannot diagnose"
      _ -> base
    end
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
