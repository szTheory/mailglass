defmodule Mailglass.ReferenceHost.TrustRunnerCommandContractTest do
  use ExUnit.Case, async: true

  @mix_path Path.expand("../../mix.exs", __DIR__)
  @task_path Path.expand("../../lib/mix/tasks/mailglass.trust.run.ex", __DIR__)
  @readme_path Path.expand("../../reference/host_app/README.md", __DIR__)
  @claim_boundary "reference-host trust-journey confidence only; signed Postmark webhook verification and no-match operator diagnosis proven by deterministic runner evidence"

  test "JOUR-01 canonical command and deterministic stages are pinned" do
    files_with_content = [
      {@mix_path, File.read!(@mix_path)},
      {@task_path, File.read!(@task_path)}
    ]

    required_tokens = [
      "verify.reference_host.journey",
      "mailglass.trust.run",
      "install",
      "preview",
      "send",
      "webhook_ingest",
      "operator_troubleshooting"
    ]

    Enum.each(required_tokens, fn token ->
      assert token_present?(files_with_content, token),
             "JOUR-01 command drift: required token missing #{inspect(token)}"
    end)
  end

  test "JOUR-03 and JOUR-04 completed proof language is pinned" do
    readme = File.read!(@readme_path)

    required_tokens = [
      "mix verify.reference_host.journey",
      "signed Postmark webhook verification",
      "no-match operator diagnosis",
      @claim_boundary,
      "JOUR-03",
      "JOUR-04"
    ]

    Enum.each(required_tokens, fn token ->
      assert String.contains?(readme, token),
             "Phase boundary drift: required token missing #{inspect(token)}"
    end)

    retired_phrase = Enum.join(["deferred", " to Phase 58"])
    refute String.contains?(readme, retired_phrase)
  end

  defp token_present?(files_with_content, token) do
    Enum.any?(files_with_content, fn {_path, content} -> String.contains?(content, token) end)
  end
end
