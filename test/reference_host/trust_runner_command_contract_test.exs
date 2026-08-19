defmodule Mailglass.ReferenceHost.TrustRunnerCommandContractTest do
  use ExUnit.Case, async: true

  @mix_path Path.expand("../../mix.exs", __DIR__)
  @task_path Path.expand("../../dev/mix/tasks/mailglass.trust.run.ex", __DIR__)
  @readme_path Path.expand("../../reference/host_app/README.md", __DIR__)
  @scope_path Path.expand("../../reference/host_app/SCOPE.md", __DIR__)
  @generated_host_script_path Path.expand("../../scripts/generated_ecto_host_proof.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @webhook_proof_path Path.expand(
                        "../../dev/mailglass/reference_host/webhook_operator_proof.ex",
                        __DIR__
                      )
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

  test "Phase 61 boundary language is pinned for reference host docs" do
    readme = File.read!(@readme_path)
    scope = File.read!(@scope_path)
    docs_with_content = [{@readme_path, readme}, {@scope_path, scope}]

    readme_required_tokens = [
      "usage-proof evidence only",
      "mix verify.stability_contract",
      "docs/api_stability.md",
      "mailglass_admin/docs/api_stability.md",
      "mailglass_inbound/docs/api_stability.md"
    ]

    Enum.each(readme_required_tokens, fn token ->
      assert String.contains?(readme, token),
             "Phase boundary drift: required README token missing #{inspect(token)}"
    end)

    scope_required_tokens = [
      "not API-contract truth",
      "second product surface",
      "fixture seed"
    ]

    Enum.each(scope_required_tokens, fn token ->
      assert String.contains?(scope, token),
             "Phase boundary drift: required SCOPE token missing #{inspect(token)}"
    end)

    overreach_phrases = [
      "is API-contract truth",
      "are API-contract truth",
      "is a fixture seed",
      "are fixture seeds"
    ]

    Enum.each(overreach_phrases, fn phrase ->
      refute token_present?(docs_with_content, phrase),
             "Phase boundary drift: overreach phrase present #{inspect(phrase)}"
    end)
  end

  test "REL-01 generated-host command exposes a fail-closed checkpoint validator" do
    source = File.read!(@generated_host_script_path)

    for token <- [
          "--validate-checkpoints",
          "fresh_install",
          "sync_send",
          "atomic_enqueue",
          "worker_run",
          "persisted_outcome"
        ] do
      assert String.contains?(source, token),
             "REL-01 generated-host command is missing #{inspect(token)}"
    end
  end

  test "REL-01 trust proof selects one explicit coherent prepublication provenance" do
    source = File.read!(@webhook_proof_path)
    ci_source = File.read!(@ci_yml_path)

    assert source =~ "MAILGLASS_REFERENCE_HOST_PACKAGE_MODE"
    assert source =~ "MAILGLASS_CORE_WORKSPACE_EBIN"
    assert source =~ "MAILGLASS_INBOUND_WORKSPACE_EBIN"
    assert source =~ "add_workspace_core_code_path!"
    assert source =~ "add_workspace_inbound_code_path!"
    assert source =~ ~s("prepublication")
    assert source =~ ~s("published")
    refute source =~ "nil -> :published"
    assert source =~ "must explicitly select prepublication provenance"
    assert source =~ "exact all-published trust proof is reserved for Phase 160 Plan 06"

    refute source =~ "require_local_ingress_plug!"
    refute source =~ "ingress/verified_request.ex"
    refute source =~ "ingress/pipeline.ex"
    refute source =~ "ports/core.ex"
    assert source =~ "Path.dirname(loaded_path) == ebin_path"

    repo_head_job =
      extract_job_block(ci_source, "trust_lane_repo_head", "trust_lane_clean_baseline")

    assert repo_head_job =~ "MAILGLASS_REFERENCE_HOST_PACKAGE_MODE: prepublication"
    assert repo_head_job =~ "MAILGLASS_CORE_WORKSPACE_EBIN"
    assert repo_head_job =~ "MAILGLASS_INBOUND_WORKSPACE_EBIN"
    assert repo_head_job =~ "working-directory: mailglass_inbound"
  end

  defp extract_job_block(source, job_key, next_job_key) do
    [_, rest] = String.split(source, "  #{job_key}:\n", parts: 2)
    [job, _] = String.split(rest, "\n  #{next_job_key}:\n", parts: 2)
    job
  end

  defp token_present?(files_with_content, token) do
    Enum.any?(files_with_content, fn {_path, content} -> String.contains?(content, token) end)
  end
end
