defmodule Mailglass.DocsCheckTaskTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @tracked_paths [
    "README.md",
    "guides/preview.md",
    "mailglass_admin/README.md",
    "MAINTAINING.md",
    "mailglass_inbound/docs/inbound-install.md"
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

    File.write!(
      preview_path,
      File.read!(preview_path) <> "\n\nThis workflow offers guaranteed client parity.\n"
    )

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

  test "blocks trust-runner internals being presented as stable public contract" do
    maintaining_path = "MAINTAINING.md"

    File.write!(
      maintaining_path,
      File.read!(maintaining_path) <>
        "\n\nMix.Tasks.Mailglass.Trust.Run is a stable public API guarantee.\n"
    )

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run([])
      end)
    end
  end

  test "--path scopes Tier 1 surface checks to selected docs" do
    File.write!("README.md", File.read!("README.md") <> "\n\nmix verify.phase_07\n")

    assert capture_io(fn ->
             Mix.Tasks.Mailglass.Docs.Check.run(["--path", "guides/preview.md"])
           end) =~ "[mailglass.docs.check] OK"
  end

  test "blocks install docs from promoting deferred providers into the stable provider contract" do
    install_path = "mailglass_inbound/docs/inbound-install.md"

    File.write!(
      install_path,
      File.read!(install_path) <>
        "\n\nThe four supported providers are `:postmark`, `:sendgrid`, `:mailgun`, and `:ses`.\n"
    )

    assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
      capture_io(:stderr, fn ->
        Mix.Tasks.Mailglass.Docs.Check.run(["--path", install_path])
      end)
    end
  end
end
