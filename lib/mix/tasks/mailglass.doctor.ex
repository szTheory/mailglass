defmodule Mix.Tasks.Mailglass.Doctor do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  @shortdoc "Run a static webhook-wiring check on the host app's endpoint"

  @moduledoc since: "1.12.0"
  @moduledoc """
  Run a static webhook-wiring check on the host app's `endpoint.ex`.

  Verifies that `Mailglass.Webhook.CachingBodyReader` is wired as the
  `:body_reader` on the managed `Plug.Parsers` block. The scan is OFFLINE:
  it reads `endpoint.ex` off disk and does NOT boot the host application.

  ## Usage

      mix mailglass.doctor

  ## Exit codes (three-state)

    * `0` — CachingBodyReader is wired (webhooks will verify correctly)
    * `1` — CachingBodyReader is absent — run `mix mailglass.install` to fix
    * `2` — cannot diagnose (endpoint.ex not found or OTP app not detectable)

  ## Notes

  This task does NOT start the application (`Mix.Task.run("app.start")` is
  deliberately absent). The scan is static so it works inside the install-fixture
  harness and in CI without a running database.
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv, strict: [verbose: :boolean])

    validate_cli!(opts, rest, invalid)

    result = Mailglass.Installer.Doctor.run([])

    result
    |> render_output(opts)
    |> Mix.shell().info()

    exit({:shutdown, exit_code(result.summary)})
  end

  # Mix.raise is reserved for CLI MISUSE only (bad flags / positional args).
  # Check findings are surfaced via the three-state exit code, never Mix.raise
  # (otherwise exit 2 becomes unreachable).
  defp validate_cli!(_opts, rest, invalid) do
    if rest != [] do
      Mix.raise("Mailglass doctor blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags = invalid |> Enum.map(fn {key, _value} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Mailglass doctor blocked: unknown option(s) #{invalid_flags}")
    end

    :ok
  end

  defp render_output(%{summary: summary, findings: findings}, opts) do
    verbose? = Keyword.get(opts, :verbose, false)

    lines =
      Enum.flat_map(findings, fn finding ->
        status_label =
          status_label(finding.status, Map.get(finding[:evidence] || %{}, :cannot_diagnose))

        base = ["#{status_label} #{finding.title}"]

        if verbose? or finding.status != :pass do
          base ++ ["  #{finding.observed}"] ++ maybe_remediation(finding)
        else
          base
        end
      end)

    summary_line =
      "mailglass.doctor: pass=#{summary.pass} fail=#{summary.fail} " <>
        "cannot_diagnose=#{Map.get(summary, :cannot_diagnose, 0)}"

    Enum.join(lines ++ [summary_line], "\n")
  end

  defp maybe_remediation(%{remediation: r}) when r != "", do: ["  Remediation: #{r}"]
  defp maybe_remediation(_), do: []

  defp status_label(:pass, _), do: "[pass]"
  defp status_label(:warn, _), do: "[warn]"
  defp status_label(:fail, true), do: "[cannot_diagnose]"
  defp status_label(:fail, _), do: "[fail]"

  # 2 = cannot-diagnose (endpoint missing / app not detectable) — checked FIRST.
  # 1 = >= 1 fail finding.
  # 0 = otherwise (all pass).
  defp exit_code(summary) do
    cond do
      Map.get(summary, :cannot_diagnose, 0) > 0 -> 2
      Map.get(summary, :fail, 0) > 0 -> 1
      true -> 0
    end
  end
end
