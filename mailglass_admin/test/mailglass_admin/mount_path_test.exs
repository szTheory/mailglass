defmodule MailglassAdmin.MountPathTest do
  @moduledoc """
  Pure coverage for `MailglassAdmin.MountPath.base/1` — the absolute
  mount-base recovery used to build mount-aware nav + asset URLs (so they
  never rely on relative `./` resolution, which drops the mount's final
  segment because the mount path has no trailing slash).
  """
  use ExUnit.Case, async: true

  alias MailglassAdmin.MountPath

  describe "base/1" do
    test "index path is its own mount base" do
      assert MountPath.base("/dev/mail") == "/dev/mail"
      assert MountPath.base("/admin/preview") == "/admin/preview"
    end

    test "show path drops the trailing mailable + scenario segments" do
      assert MountPath.base("/dev/mail/MyApp.UserMailer/welcome") == "/dev/mail"
      assert MountPath.base("/admin/preview/MyApp.UserMailer/welcome") == "/admin/preview"
    end

    test "preview_props error path drops mailable + __error__" do
      assert MountPath.base("/dev/mail/MyApp.UserMailer/__error__") == "/dev/mail"
    end

    test "gallery and inbound drop only their own trailing segment" do
      assert MountPath.base("/dev/mail/gallery") == "/dev/mail"
      assert MountPath.base("/ops/mail/inbound") == "/ops/mail"
    end

    test "single-segment and root mounts" do
      assert MountPath.base("/mail") == "/mail"
      assert MountPath.base("/mail/MyApp.UserMailer/welcome") == "/mail"
    end

    test "nil / non-binary returns root" do
      assert MountPath.base(nil) == "/"
      assert MountPath.base(:nope) == "/"
    end
  end

  describe "module_segment?/1" do
    test "recognizes module-like segments (with or without Elixir. prefix)" do
      assert MountPath.module_segment?("MyApp.UserMailer")
      assert MountPath.module_segment?("Elixir.MyApp.UserMailer")
    end

    test "rejects plain path segments" do
      refute MountPath.module_segment?("mail")
      refute MountPath.module_segment?("welcome")
      refute MountPath.module_segment?("gallery")
    end
  end
end
