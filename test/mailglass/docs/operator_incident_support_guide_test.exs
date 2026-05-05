defmodule Mailglass.OperatorIncidentSupportGuideTest do
  use ExUnit.Case, async: true

  @guide_path "guides/operator-incident-support.md"

  describe "operator incident support guide" do
    test "exposes symptom-first entrypoints for the shipped support prompts" do
      guide = File.read!(@guide_path)

      assert guide =~ "customer says the email never arrived"
      assert guide =~ "provider is retrying or timing out"
      assert guide =~ "orphan backlog is growing"
      assert guide =~ "replay completed but nothing changed"
    end

    test "separates provider lifecycle facts, replay facts, and reconcile facts in each stage" do
      guide = File.read!(@guide_path)

      assert guide =~ "## Delivery send and provider lifecycle facts"
      assert guide =~ "## Webhook signature and ingest facts"
      assert guide =~ "## Orphan backlog and reconcile facts"
      assert guide =~ "## Replay and reconcile repair actions"

      assert guide =~ "### Provider lifecycle facts"
      assert guide =~ "### Replay facts"
      assert guide =~ "### Reconcile facts"
    end

    test "includes honesty notes and current telemetry vocabulary" do
      guide = File.read!(@guide_path)

      assert guide =~ "Mailglass can tell you this"
      assert guide =~ "Mailglass cannot tell you this"
      assert guide =~ "[:mailglass, :webhook, :ingest"
      assert guide =~ "[:mailglass, :outbound, :dispatch"

      refute guide =~ "[:mailglass, :deliver]"
      refute guide =~ "[:mailglass, :reconcile]"
      refute guide =~ "alice@example.com"
      refute guide =~ "raw_payload"
    end
  end
end
