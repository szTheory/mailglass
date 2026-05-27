defmodule Mailglass.DocsCheckTaskTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @tracked_paths [
    "README.md",
    "guides/preview.md",
    "mailglass_admin/README.md"
  ]

  setup do
    originals =
      Map.new(@tracked_paths, fn path ->
        {path, File.read!(path)}
      end)

    on_exit(fn ->
      Enum.each(originals, fn {path, content} ->
        File.write!(path, content)
      end)
    end)

    :ok
  end

  test "blocks stale Tier 1 surface markers in README.md" do
    readme_path = "README.md"
    File.write!(readme_path, File.read!(readme_path) <> "\n\nmix verify.phase_07\n")

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run([])
      end)
    end
  end

  test "blocks parity-overreach wording in guides/preview.md" do
    preview_path = "guides/preview.md"
    File.write!(preview_path, File.read!(preview_path) <> "\n\nThis workflow offers guaranteed client parity.\n")

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run([])
      end)
    end
  end

  test "blocks unqualified cross-client parity wording in admin README" do
    admin_path = "mailglass_admin/README.md"
    File.write!(admin_path, File.read!(admin_path) <> "\n\nCross-client parity for every client.\n")

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run([])
      end)
    end
  end
end
