defmodule Mailglass.Docs.UnsubscribeGuideTest do
  use ExUnit.Case, async: true

  describe "guides/unsubscribe.md contract" do
    test "pins the canonical router mount and route shape" do
      guide = File.read!("guides/unsubscribe.md") |> String.replace("\n", " ")

      assert guide =~ ~s(mailglass_router_routes "/mailglass")
      assert guide =~ "GET /mailglass/unsubscribe/:token"
      assert guide =~ "POST /mailglass/unsubscribe/:token"
      assert guide =~ ~s(mount_path: "/mailglass/unsubscribe")
    end

    test "documents the read-only generator contract" do
      guide = File.read!("guides/unsubscribe.md") |> String.replace("\n", " ")

      assert guide =~ "mix mailglass.gen.unsubscribe"
      assert guide =~ "copies zero files"
    end

    test "keeps the built-in GET page, redirect escape hatch, and replay UAT steps load-bearing" do
      guide = File.read!("guides/unsubscribe.md") |> String.replace("\n", " ")

      assert guide =~ "renders a built-in confirmation page by default"
      assert guide =~ "If `redirect` is configured, GET redirects to that path"
      assert guide =~ "One-click POST check"
      assert guide =~ "Replay POST check"
      assert guide =~ "byte-empty `200`"
    end

    test "locks the exact one-click convergence, privacy, and RFC attribution contract" do
      guide = File.read!("guides/unsubscribe.md") |> String.replace("\n", " ")

      assert guide =~ "byte-empty `200`"
      assert guide =~ "byte-empty `500`"
      assert guide =~ "privacy-preserving no-op"
      assert guide =~ "RFC 8058 requires the HTTPS POST and no redirect"
      assert guide =~ "Mailglass owns the byte-empty `200` privacy compatibility contract"
      assert guide =~ "canonical `:unsubscribed` event"
      assert Regex.match?(~r/immutable\s+`:address_stream` suppression/, guide)
      assert Regex.match?(~r/Delivery-derived normalized address and originating\s+stream/, guide)
      assert Regex.match?(~r/Replays and concurrent POSTs converge/, guide)
      assert guide =~ "created convergence runs effects; replays do not"
    end

    test "documents compatible lifecycle hooks as separate best-effort post-commit work" do
      guide = File.read!("guides/unsubscribe.md")

      assert guide =~ "handle_event(Ecto.Multi.new(), attrs)"
      assert guide =~ "After the primary convergence commits"
      assert guide =~ "separate, best-effort transaction"
      refute guide =~ "extend the durable unsubscribe transaction"
      refute guide =~ "receive the in-flight `Ecto.Multi`"
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
