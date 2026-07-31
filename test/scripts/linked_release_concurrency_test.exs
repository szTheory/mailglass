defmodule Mailglass.Scripts.LinkedReleaseConcurrencyTest do
  use ExUnit.Case, async: true

  @publish_path Path.expand("../../.github/workflows/publish-hex.yml", __DIR__)
  @smoke_path Path.expand("../../.github/workflows/post-publish-smoke.yml", __DIR__)
  @shared_group "mailglass-linked-release-fanout"
  @packages ["mailglass", "mailglass_admin", "mailglass_inbound"]

  test "linked release workflows share one static non-cancelling concurrency block" do
    publish_concurrency = extract_top_level_concurrency!(File.read!(@publish_path))
    smoke_concurrency = extract_top_level_concurrency!(File.read!(@smoke_path))

    assert publish_concurrency.group == @shared_group
    assert smoke_concurrency.group == @shared_group
    assert publish_concurrency.cancel_in_progress == false
    assert smoke_concurrency.cancel_in_progress == false
  end

  test "old ref and tag scoped concurrency expressions are rejected" do
    publish_source = File.read!(@publish_path)
    smoke_source = File.read!(@smoke_path)

    ref_scoped_publish =
      String.replace(publish_source, @shared_group, "publish-hex-${{ github.ref }}")

    tag_scoped_smoke =
      String.replace(
        smoke_source,
        @shared_group,
        "post-publish-smoke-${{ github.event.inputs.tag || github.event.release.tag_name || github.ref }}"
      )

    refute valid_static_concurrency?(ref_scoped_publish)
    refute valid_static_concurrency?(tag_scoped_smoke)
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

  defp valid_static_concurrency?(source) do
    concurrency = extract_top_level_concurrency!(source)

    concurrency.group == @shared_group and
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
      |> Enum.take_while(fn line -> line == "  #{job_name}:" or not Regex.match?(~r/^  [a-z][a-z0-9-]*:$/, line) end)
      |> Enum.join("\n")

    assert String.trim(job) != "", "#{job_name} job block must not be empty"
    job
  end
end
