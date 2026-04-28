defmodule Mailglass.Docs.UnsubscribeGuideTest do
  use ExUnit.Case, async: true

  describe "guides/unsubscribe.md contract" do
    test "pins the canonical router mount and route shape" do
      guide = File.read!("guides/unsubscribe.md")

      assert guide =~ ~s(mailglass_router_routes "/mailglass")
      assert guide =~ "GET /mailglass/unsubscribe/:token"
      assert guide =~ "POST /mailglass/unsubscribe/:token"
      assert guide =~ ~s(mount_path: "/mailglass/unsubscribe")
    end

    test "documents the read-only generator contract" do
      guide = File.read!("guides/unsubscribe.md")

      assert guide =~ "mix mailglass.gen.unsubscribe"
      assert guide =~ "copies zero files"
    end

    test "keeps the built-in GET page, redirect escape hatch, and replay UAT steps load-bearing" do
      guide = File.read!("guides/unsubscribe.md")

      assert guide =~ "renders a built-in confirmation page by default"
      assert guide =~ "If `redirect` is configured, GET redirects to that path"
      assert guide =~ "One-click POST check"
      assert guide =~ "Replay POST check"
      assert guide =~ "still returns `200`"
    end

    test "documents the previous_secrets rotation playbook" do
      guide = File.read!("guides/unsubscribe.md")

      assert guide =~ "previous_secrets"
      assert guide =~ "MAILGLASS_OLD_SECRET_KEY_BASE"
      assert guide =~ "old links valid"
    end
  end

  describe "published docs wiring" do
    test "includes the unsubscribe and DKIM guides in ExDoc extras" do
      docs = Mix.Project.config()[:docs]

      assert "guides/unsubscribe.md" in docs[:extras]
      assert "guides/dkim-setup.md" in docs[:extras]
      assert "guides/unsubscribe.md" in Keyword.fetch!(docs, :groups_for_extras)[:Guides]
      assert "guides/dkim-setup.md" in Keyword.fetch!(docs, :groups_for_extras)[:Guides]
    end
  end
end
