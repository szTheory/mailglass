defmodule Mailglass.CompatibilityContractTest do
  use ExUnit.Case, async: true

  @compatibility_guide "guides/compatibility-and-deprecations.md"
  @upgrade_guide "guides/upgrading-to-v1_0.md"

  @inventory [
    %{
      surface: "Mailglass.Message.new/2",
      replacement: "native `Mailglass.Message` setters or `new_from_use/2`",
      warning_channel: "compiler deprecation via `@deprecated`",
      strict_ci: "unsafe to keep in new strict-CI code because the deprecation warning is real",
      support_until: "no earlier than `v2.0`",
      proof_artifact: "`lib/mailglass/message.ex`, this guide, compatibility guide"
    },
    %{
      surface: "Mailglass.Outbound.send/2",
      replacement: "`Mailglass.deliver/2`",
      warning_channel: "docs-only compatibility warning today",
      strict_ci: "compiles cleanly, but treat as non-canonical in new code",
      support_until: "no earlier than `v2.0`",
      proof_artifact: "`lib/mailglass/outbound.ex`, this guide, compatibility guide"
    },
    %{
      surface: "raw `%Swoosh.Email{}` with `Mailglass.deliver/2`",
      replacement: "`Mailglass.Message`/`Mailglass.Mailable`",
      warning_channel: "docs-only compatibility warning today",
      strict_ci: "compiles cleanly, but not preferred for new integrations",
      support_until: "no earlier than `v2.0`",
      proof_artifact: "`guides/migration-from-swoosh.md`, migration smoke test"
    },
    %{
      surface: "mix mailglass.upgrade.v0_2",
      replacement: "stable setter lane after rewrite",
      warning_channel: "task warnings for ambiguous unsupported calls",
      strict_ci: "neutral by itself; the resulting code must compile cleanly",
      support_until: "no earlier than `v2.0` while documented",
      proof_artifact: "`lib/mix/tasks/mailglass.upgrade.v0_2.ex`, this guide"
    },
    %{
      surface: "deprecated `verify.phase_*` aliases",
      replacement: "semantic `verify.*` aliases",
      warning_channel: "docs-only maintainer deprecation",
      strict_ci: "not relevant to adopter code; keep out of Tier 1 docs",
      support_until: "one release cycle as documented in repo comments",
      proof_artifact: "`mix.exs`, docs-check rules"
    }
  ]

  test "canonical compatibility guide preserves the stable-lane model and support matrix" do
    guide = File.read!(@compatibility_guide)

    assert guide =~ "`stable lane`"
    assert guide =~ "`compatibility lane`"
    assert guide =~ "| Elixir | `~> 1.18` |"
    assert guide =~ "| OTP | `27+` |"
    assert guide =~ "| Phoenix | `~> 1.8` |"
    assert guide =~ "| Phoenix LiveView | `~> 1.1` |"
    assert guide =~ "| Ecto / Ecto SQL | `~> 3.13` |"
    assert guide =~ "| PostgreSQL | 14+"
    assert guide =~ "`mailglass_inbound` | independent `1.0` contract"
  end

  test "retained compatibility inventory names replacement warning strict-ci horizon and proof" do
    guide = File.read!(@upgrade_guide)

    assert guide =~
             "| surface | replacement | warning channel | `--warnings-as-errors` impact | support-until version | proof artifact |"

    Enum.each(@inventory, fn entry ->
      assert guide =~ entry.surface
      assert guide =~ entry.replacement
      assert guide =~ entry.warning_channel
      assert guide =~ entry.strict_ci
      assert guide =~ entry.support_until
      assert guide =~ entry.proof_artifact
    end)
  end

  test "source-level docs and task metadata match the compatibility inventory" do
    message = File.read!("lib/mailglass/message.ex")
    outbound = File.read!("lib/mailglass/outbound.ex")
    task = File.read!("lib/mix/tasks/mailglass.upgrade.v0_2.ex")

    assert message =~ "deprecated"
    assert message =~ "compatibility path"
    assert message =~ "native Mailglass.Message setters"

    assert outbound =~ "compatibility bridge"
    assert outbound =~ "new adopter code should call `deliver/2`"
    assert outbound =~ "stable-lane front door"

    assert task =~ "guides/upgrading-to-v1_0.md"
    assert task =~ "canonical `0.x -> 1.0` migration path"
    assert task =~ "ambiguous-case migration guidance"
  end

  test "older guides remain subordinate to the canonical upgrade authority" do
    older = File.read!("guides/upgrading-from-v0_1.md")
    swoosh = File.read!("guides/migration-from-swoosh.md")

    assert older =~ "subordinate codemod reference"
    assert older =~ "upgrading-to-v1_0.md"

    assert swoosh =~ "subordinate raw-Swoosh migration reference"
    assert swoosh =~ "upgrading-to-v1_0.md"
    assert swoosh =~ "retained compatibility bridge"
  end
end
