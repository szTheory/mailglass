defmodule Mailglass.ReferenceHost.ScopeLockContractTest do
  use ExUnit.Case, async: true

  @host_app_root Path.expand("../../reference/host_app", __DIR__)
  @scope_path Path.expand("../../reference/host_app/SCOPE.md", __DIR__)
  @readme_path Path.expand("../../reference/host_app/README.md", __DIR__)

  test "HOST-03 required scope headings and lock tokens remain present" do
    scope = File.read!(@scope_path)

    required_tokens = [
      "## In Scope",
      "## Non-Goals",
      "## Deferred",
      "install",
      "preview",
      "send",
      "webhook ingest",
      "operator troubleshooting",
      "Provider-matrix broadening",
      "SEED-003-ecosystem-integrations promotion",
      "gen_smtp listener expansion",
      "second product surface",
      "OPS-01/OPS-02 smoke reliability closure remains outside Phase 52"
    ]

    Enum.each(required_tokens, fn token ->
      assert String.contains?(scope, token),
             "HOST-03 scope drift: required token missing #{inspect(token)}"
    end)
  end

  test "HOST-03 forbids scope-expansion language and requires README pointer" do
    scope = File.read!(@scope_path)
    readme = File.read!(@readme_path)

    forbidden_tokens = [
      "multi-provider matrix",
      "new product feature",
      "marketing email",
      "gen_smtp roadmap in v1.3",
      "SEED-003 included in this phase"
    ]

    Enum.each(forbidden_tokens, fn token ->
      refute String.contains?(scope, token),
             "HOST-03 scope drift: forbidden expansion token present #{inspect(token)}"
    end)

    assert String.contains?(readme, "Scope contract: see reference/host_app/SCOPE.md"),
           "HOST-03 scope drift: README scope pointer missing"
  end

  test "HOST-03 blocks rich demo markers from reference host app sources" do
    forbidden_tokens = ["MailglassDemo", "Northstar Ops", "demo dashboard"]

    files =
      Path.wildcard(Path.join(@host_app_root, "**/*"))
      |> Enum.filter(&File.regular?/1)

    hits =
      for file <- files,
          content = File.read!(file),
          token <- forbidden_tokens,
          String.contains?(content, token) do
        {file, token}
      end

    assert hits == [],
           "HOST-03 scope drift: reference/host_app contains rich-demo markers #{inspect(hits)}"
  end
end
