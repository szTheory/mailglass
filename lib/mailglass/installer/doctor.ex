defmodule Mailglass.Installer.Doctor do
  @moduledoc """
  Static webhook-wiring check for the host app's endpoint.

  Reads `endpoint.ex` off disk (via `File.read!`) and checks whether the
  Mailglass `CachingBodyReader` body reader is wired. No app boot, no runtime
  reflection — the scan runs inside the install-fixture harness in CI.

  ## Exit-code mapping (three-state)

    * `summary.cannot_diagnose > 0` — endpoint.ex missing / app not detectable → exit 2
    * `summary.fail > 0`            — CachingBodyReader absent → exit 1
    * else                          — wired correctly → exit 0

  ## Usage

      Mailglass.Installer.Doctor.run([])
      # => %{summary: %{pass: 1, warn: 0, fail: 0, cannot_diagnose: 0}, findings: [...]}
  """

  alias Mailglass.Installer.Plan
  alias Mailglass.Installer.Templates

  @type finding :: %{
          check: atom(),
          status: :pass | :warn | :fail,
          title: String.t(),
          observed: String.t(),
          remediation: String.t(),
          evidence: map()
        }

  @type result :: %{summary: map(), findings: [finding()]}

  @doc """
  Runs the static endpoint-wiring scan and returns a result map.

  Options are accepted for API symmetry with the inbound doctor but are not
  currently used — the scan is static and unconditional.
  """
  @spec run(keyword()) :: result()
  def run(_opts \\ []) do
    otp_app = Plan.detect_otp_app()
    endpoint_path = "lib/#{otp_app}_web/endpoint.ex"

    findings =
      cond do
        not File.exists?(endpoint_path) ->
          [cannot_diagnose_finding(endpoint_path)]

        wired?(File.read!(endpoint_path)) ->
          [pass_finding(endpoint_path)]

        true ->
          [fail_finding(endpoint_path)]
      end

    %{summary: summarize(findings), findings: findings}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  @spec wired?(String.t()) :: boolean()
  defp wired?(contents) do
    String.contains?(contents, "body_reader") and
      String.contains?(contents, "Mailglass.Webhook.CachingBodyReader")
  end

  @spec pass_finding(String.t()) :: finding()
  defp pass_finding(endpoint_path) do
    %{
      check: :caching_body_reader_wired,
      status: :pass,
      title: "Webhook body reader is wired",
      observed:
        "#{endpoint_path} contains `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}`",
      remediation: "",
      evidence: %{endpoint_path: endpoint_path}
    }
  end

  @spec fail_finding(String.t()) :: finding()
  defp fail_finding(endpoint_path) do
    start_marker = Templates.endpoint_webhook_block_start()
    end_marker = Templates.endpoint_webhook_block_end()

    %{
      check: :caching_body_reader_wired,
      status: :fail,
      title: "Webhook body reader is NOT wired",
      observed:
        "#{endpoint_path} is missing `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}`. " <>
          "Without it, an unmanaged Plug.Parsers will consume the raw request body before Mailglass can verify " <>
          "webhook signatures, causing every inbound webhook to silently return 401 in production.",
      remediation:
        "Run `mix mailglass.install` (or `mix mailglass.install --force` if there is an existing " <>
          "`plug Plug.Parsers`). The installer inserts the managed parser block between " <>
          "`#{start_marker}` and `#{end_marker}` markers, above any existing parser.",
      evidence: %{endpoint_path: endpoint_path}
    }
  end

  @spec cannot_diagnose_finding(String.t()) :: finding()
  defp cannot_diagnose_finding(endpoint_path) do
    %{
      check: :caching_body_reader_wired,
      status: :fail,
      title: "Cannot diagnose — endpoint.ex not found",
      observed: "#{endpoint_path} does not exist. Cannot determine webhook-wiring status.",
      remediation:
        "Ensure you are running `mix mailglass.doctor` from the Phoenix host app root " <>
          "and that `#{endpoint_path}` exists.",
      evidence: %{endpoint_path: endpoint_path, cannot_diagnose: true}
    }
  end

  # Counts cannot_diagnose findings separately from fail (see evidence flag).
  # A cannot_diagnose finding maps to exit 2, a fail finding maps to exit 1,
  # ensuring the two error states are distinguishable in CI.
  @spec summarize([finding()]) :: map()
  defp summarize(findings) do
    base = %{pass: 0, warn: 0, fail: 0, cannot_diagnose: 0}

    Enum.reduce(findings, base, fn finding, acc ->
      if Map.get(finding[:evidence] || %{}, :cannot_diagnose) do
        Map.update!(acc, :cannot_diagnose, &(&1 + 1))
      else
        Map.update!(acc, finding.status, &(&1 + 1))
      end
    end)
  end
end
