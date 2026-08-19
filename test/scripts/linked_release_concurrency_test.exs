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

      assert job =~ "mix hex.build"
      assert job =~ "CHECKSUM=$(shasum -a 256"
      refute job =~ "tar -xOf"
      assert job =~ "release_policy_hex_release_state.sh #{package} \"${VERSION}\" \"$CHECKSUM\""
      assert job =~ "skip=true"
      assert job =~ "steps.idempotency.outputs.skip != 'true'"
      assert job =~ ~r/nothing to do/i
    end)
  end

  test "protected exact-digest dispatch fans out core, admin, then independent inbound" do
    source = File.read!(@publish_path)
    core = extract_publish_job!(source, "mailglass")
    admin = extract_publish_job!(source, "mailglass_admin")
    inbound = extract_publish_job!(source, "mailglass_inbound")

    assert core =~ "needs: [gate-ci-green, prepublish-summary]"
    assert core =~ "github.event_name == 'workflow_dispatch'"
    assert core =~ "needs.prepublish-summary.outputs.authorized == 'true'"

    assert admin =~ "needs: [gate-ci-green, prepublish-summary, publish-core]"
    assert admin =~ "needs.gate-ci-green.result == 'success'"
    assert admin =~ "needs.publish-core.result == 'success'"

    assert admin =~
             "github.event.inputs.candidate_digest == needs.prepublish-summary.outputs.candidate_digest"

    refute admin =~ "publish-inbound]"

    assert inbound =~ "needs: [gate-ci-green, prepublish-summary, publish-core, publish-admin]"
    assert inbound =~ "github.event_name == 'workflow_dispatch'"
    assert inbound =~ "needs.prepublish-summary.outputs.authorized == 'true'"
    assert inbound =~ "needs.publish-admin.result == 'success'"
  end

  test "CI self-heal is a live-only predecessor while captured rehearsal uses the read-only gate" do
    source = File.read!(@publish_path)
    self_heal = extract_job!(source, "ensure-live-ci-runs")
    gate = extract_job!(source, "gate-ci-green")

    assert self_heal =~ "needs: [prepublish-summary]"
    assert self_heal =~ "github.event.inputs.dry_run != 'true'"
    assert self_heal =~ "needs.prepublish-summary.outputs.authorized == 'true'"
    assert self_heal =~ "actions: write"

    assert gate =~ "needs: [prepublish-summary, ensure-live-ci-runs]"
    assert gate =~ "always()"
    assert gate =~ "github.event.inputs.dry_run == 'true'"
    assert gate =~ "needs.prepublish-summary.outputs.pretag == 'true'"
    assert gate =~ "needs.ensure-live-ci-runs.result == 'success'"
    refute gate =~ "actions: write"
    refute gate =~ "createWorkflowDispatch"
  end

  test "all publish jobs preserve the protected environment and step-local credential" do
    source = File.read!(@publish_path)

    Enum.each(@packages, fn package ->
      job = extract_publish_job!(source, package)

      assert job =~ "environment: hex-publish"
      assert job =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    end)
  end

  test "only a successful ordered protected publish dispatches exact smoke inputs" do
    source = File.read!(@publish_path)
    handoff = extract_job!(source, "dispatch-post-publish-smoke")

    assert handoff =~ "needs: [prepublish-summary, publish-inbound]"
    assert handoff =~ "needs.publish-inbound.result == 'success'"
    assert handoff =~ "github.event.inputs.dry_run != 'true'"
    assert handoff =~ "needs.prepublish-summary.outputs.authorized == 'true'"
    assert handoff =~ "actions: write"
    assert handoff =~ "workflow_id: 'post-publish-smoke.yml'"
    assert handoff =~ "target_ref: process.env.TARGET_REF"
    assert handoff =~ "/^[0-9a-f]{40}$/"
  end

  test "prepublish summary uploads a credential-free Phase 148 proof artifact" do
    source = File.read!(@publish_path)
    prepublish = extract_job!(source, "prepublish-summary")

    assert prepublish =~ "test/mailglass/webhook/ingest_auto_suppress_test.exs"
    assert prepublish =~ "test/mailglass/suppression_test.exs"
    assert prepublish =~ "test/mailglass/docs_contract_test.exs"
    assert prepublish =~ "cd mailglass_admin"
    assert prepublish =~ "test/mailglass_admin/operator_live_test.exs"
    assert prepublish =~ "tmp/release-proof/phase-148.json"
    assert prepublish =~ "phase-148-release-proof-${{ github.run_id }}"
    assert prepublish =~ "retention-days: 90"
    assert prepublish =~ "if-no-files-found: error"
    assert prepublish =~ "actions/upload-artifact@"
    assert prepublish =~ "Validate automated release target"
    assert prepublish =~ ".planning/release-target.json"
    assert prepublish =~ "steps.release-target.outputs.core"
    assert prepublish =~ "steps.release-target.outputs.admin"
    assert prepublish =~ "steps.release-target.outputs.inbound"
    assert prepublish =~ "steps.release-target.outputs.active == 'true'"
    refute prepublish =~ "--arg core \"2.4.0\""
    refute prepublish =~ "--arg admin \"2.4.0\""
    refute prepublish =~ "--arg inbound \"2.1.1\""
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
