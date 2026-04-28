defmodule Mailglass.DocsCheckTaskTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @readme_path "README.md"

  setup do
    original = File.read!(@readme_path)

    on_exit(fn ->
      File.write!(@readme_path, original)
    end)

    :ok
  end

  test "blocks stale Tier 1 surface markers in README.md" do
    File.write!(@readme_path, File.read!(@readme_path) <> "\n\nmix verify.phase_07\n")

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run([])
      end)
    end
  end
end
