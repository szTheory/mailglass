defmodule Mailglass.Scripts.LinkedReleaseConcurrencyTest do
  use ExUnit.Case, async: true

  @publish_path Path.expand("../../.github/workflows/publish-hex.yml", __DIR__)
  @smoke_path Path.expand("../../.github/workflows/post-publish-smoke.yml", __DIR__)
  @publish_group "mailglass-linked-release-publish"
  @smoke_group "mailglass-linked-release-smoke"
  @packages ["mailglass", "mailglass_admin", "mailglass_inbound"]

  test "publish and smoke use distinct static non-cancelling concurrency blocks" do
    publish_concurrency = extract_top_level_concurrency!(File.read!(@publish_path))
    smoke_concurrency = extract_top_level_concurrency!(File.read!(@smoke_path))

    assert publish_concurrency.group == @publish_group
    assert smoke_concurrency.group == @smoke_group
    refute publish_concurrency.group == smoke_concurrency.group
    assert publish_concurrency.cancel_in_progress == false
    assert smoke_concurrency.cancel_in_progress == false
  end

  test "old ref and tag scoped concurrency expressions are rejected" do
    publish_source = File.read!(@publish_path)
    smoke_source = File.read!(@smoke_path)

    ref_scoped_publish =
      String.replace(publish_source, @publish_group, "publish-hex-${{ github.ref }}")

    tag_scoped_smoke =
      String.replace(
        smoke_source,
        @smoke_group,
        "post-publish-smoke-${{ github.event.inputs.tag || github.event.release.tag_name || github.ref }}"
      )

    refute valid_static_concurrency?(ref_scoped_publish, @publish_group)
    refute valid_static_concurrency?(tag_scoped_smoke, @smoke_group)
  end

  test "every package publish job keeps an observable already-published success no-op" do
    source = File.read!(@publish_path)

    Enum.each(@packages, fn package ->
      job = extract_publish_job!(source, package)

      assert job =~ "mix hex.info #{package} \"${VERSION}\""
      assert job =~ "Released:"
      assert job =~ "skip=true"
      assert job =~ "steps.idempotency.outputs.skip != 'true'"
      assert job =~ ~r/nothing to do/i
    end)
  end

  test "release events fan out only to the linked core and admin packages" do
    source = File.read!(@publish_path)
    core = extract_publish_job!(source, "mailglass")
    admin = extract_publish_job!(source, "mailglass_admin")
    inbound = extract_publish_job!(source, "mailglass_inbound")

    assert core =~ "needs: [gate-ci-green]"
    assert core =~ "github.event_name == 'release'"

    assert admin =~ "needs: [gate-ci-green, publish-core]"
    assert admin =~ "needs.gate-ci-green.result == 'success'"
    assert admin =~ "needs.publish-core.result == 'success'"
    assert admin =~ "github.event_name == 'release'"
    refute admin =~ "needs: [gate-ci-green, publish-core, publish-inbound]"

    refute inbound =~ "github.event_name == 'release'"
    assert inbound =~ "github.event_name == 'workflow_dispatch'"
  end

  test "all publish jobs preserve the protected environment and step-local credential" do
    source = File.read!(@publish_path)

    Enum.each(@packages, fn package ->
      job = extract_publish_job!(source, package)

      assert job =~ "environment: hex-publish"
      assert job =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    end)
  end

  test "prepublish summary proves the complete package-shaped Phase 153 candidate before credentials" do
    source = File.read!(@publish_path)
    prepublish = extract_job!(source, "prepublish-summary")

    assert prepublish =~ "scripts/resolve_release_packages.exs"
    assert prepublish =~ "DEP_MODE=local bash scripts/generated_host_proof.sh --stage all"
    assert prepublish =~ "mix ci"
    assert prepublish =~ "mix mailglass.publish.check --package \"$package\""
    assert prepublish =~ "candidate_sha"
    assert prepublish =~ "tmp/release-proof/phase-153.json"
    assert prepublish =~ "phase-153-release-proof-${{ github.run_id }}"
    assert prepublish =~ "retention-days: 90"
    assert prepublish =~ "if-no-files-found: error"
    assert prepublish =~ "actions/upload-artifact@"
    assert prepublish =~ "Validate automated release target"
    assert prepublish =~ ".planning/release-target.json"
    assert prepublish =~ "release_packages"
    assert prepublish =~ "steps.release-target.outputs.active == 'true'"
    refute prepublish =~ "HEX_API_KEY"
  end

  defp valid_static_concurrency?(source, expected_group) do
    concurrency = extract_top_level_concurrency!(source)

    concurrency.group == expected_group and
      concurrency.cancel_in_progress == false and
      not String.contains?(concurrency.group, ["github.ref", "tag", "inputs"])
  end

  defp extract_top_level_concurrency!(source) do
    matches =
      Regex.scan(
        ~r/^concurrency:\n  group: (.+)\n  cancel-in-progress: (true|false)$/m,
        source
      )

    assert length(matches) == 1,
           "expected exactly one top-level concurrency block, found #{length(matches)}"

    [[_full, group, cancel_in_progress]] = matches

    %{group: String.trim(group), cancel_in_progress: cancel_in_progress == "true"}
  end

  defp extract_publish_job!(source, package) do
    job_name =
      case package do
        "mailglass" -> "publish-core"
        "mailglass_admin" -> "publish-admin"
        "mailglass_inbound" -> "publish-inbound"
      end

    extract_job!(source, job_name)
  end

  defp extract_job!(source, job_name) do
    lines = String.split(source, "\n")

    matches =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _index} -> line == "  #{job_name}:" end)

    assert length(matches) == 1,
           "expected exactly one #{job_name} job header, found #{length(matches)}"

    [{_header, start_index}] = matches

    job =
      lines
      |> Enum.drop(start_index)
      |> Enum.take_while(fn line ->
        line == "  #{job_name}:" or not Regex.match?(~r/^  [a-z][a-z0-9-]*:$/, line)
      end)
      |> Enum.join("\n")

    assert String.trim(job) != "", "#{job_name} job block must not be empty"
    job
  end
end
