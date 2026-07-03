defmodule Mailglass.UpgradeV2DocsTest do
  @moduledoc """
  Doc-token + release-gate assertions for the mailglass 2.0 schema-isolation
  upgrade docs (UPG-02 / UPG-03).

  Pure `File.read!` token checks — no DB, no compilation of docs. Every asserted
  literal is a MATCH TARGET only. This module deliberately does NOT add a
  file-wide negative grep for `public.mailglass_` or `45A01`, so it never becomes
  its own banned-token landmine (Pitfall 8).
  """
  use ExUnit.Case, async: true

  @guide "guides/upgrading-to-v2_0.md"
  @core_api "docs/api_stability.md"
  @inbound_api "mailglass_inbound/docs/api_stability.md"
  @allowlist ".planning/publish/mailglass-files.expected"
  @mix_exs "mix.exs"

  describe "UPG-02 — guides/upgrading-to-v2_0.md content" do
    setup do
      %{guide: File.read!(@guide)}
    end

    test "documents Route A (the one-line public opt-out)", %{guide: guide} do
      assert guide =~ "Route A"
      assert guide =~ ~s(config :mailglass, :schema, "public")
    end

    test "documents Route B (the generated move migration task)", %{guide: guide} do
      assert guide =~ "Route B"
      assert guide =~ "mix mailglass.upgrade.v2_schema"
    end

    test "documents the create_schema: false grants block", %{guide: guide} do
      assert guide =~ "create_schema: false"
      assert guide =~ "GRANT USAGE ON SCHEMA"
      assert guide =~ "ALTER DEFAULT PRIVILEGES"
    end

    test "documents the public.mailglass_ literal-SQL grep checklist", %{guide: guide} do
      assert guide =~ "public.mailglass_"
    end

    test "documents the lock_timeout + 55P03 retry posture", %{guide: guide} do
      assert guide =~ "lock_timeout"
      assert guide =~ "55P03"
    end
  end

  describe "UPG-03 — :schema documented as a stable 2.0 surface" do
    test "core api_stability documents config :mailglass, :schema with Since 2.0.0 and orthogonality" do
      core = File.read!(@core_api)
      assert core =~ "config :mailglass, :schema"
      assert core =~ "Since: 2.0.0"
      assert core =~ "orthogonal to `tenant_id`"
    end

    test "inbound api_stability documents config :mailglass_inbound, :schema with Since 2.0.0 and orthogonality" do
      inbound = File.read!(@inbound_api)
      assert inbound =~ "config :mailglass_inbound, :schema"
      assert inbound =~ "Since: 2.0.0"
      assert inbound =~ "orthogonal to `tenant_id`"
    end
  end

  describe "UPG-02 release gate — guide wired for publish + HexDocs" do
    test "guide is enumerated in the publish allowlist (exact line)" do
      lines =
        @allowlist
        |> File.read!()
        |> String.split("\n", trim: true)

      assert "guides/upgrading-to-v2_0.md" in lines
    end

    test "guide is wired into mix.exs (extras + groups_for_extras)" do
      assert File.read!(@mix_exs) =~ "guides/upgrading-to-v2_0.md"
    end
  end
end
