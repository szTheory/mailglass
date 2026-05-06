defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers

  describe "README.md contract" do
    test "installation snippet targets the current stable surface" do
      blocks = extract_code_blocks("README.md")
      install_block = Enum.find(blocks, &(&1 =~ "mix mailglass.install"))

      assert install_block
      assert install_block =~ "mix ecto.migrate"
      refute Enum.any?(blocks, &String.contains?(&1, "mix verify.phase_07"))

      readme = File.read!("README.md")
      assert readme =~ "{:mailglass, \"~> 0.3\"}"
      assert readme =~ "docs/api_stability.md"
      assert readme =~ "guides/compatibility-and-deprecations.md"
      assert readme =~ "guides/upgrading-to-v1_0.md"
      assert readme =~ "`mailglass_inbound` is outside the `v1.x` stability promise"
      refute readme =~ "v0.1 in development"
      refute readme =~ "{:mailglass, \"~> 0.2\"}"
      refute readme =~ "v0.3 public surface"
    end

    test "Quickstart snippet compiles" do
      blocks = extract_code_blocks("README.md")
      mailable_code = Enum.find(blocks, &(&1 =~ "defmodule MyApp.UserMailer"))

      assert mailable_code
      assert mailable_code =~ "|> to(user.email)"
      assert {:ok, _quoted} = Code.string_to_quoted(mailable_code)
    end

    test "README mentions the shipped runtime routing terms without deferred-scope promises" do
      readme = File.read!("README.md")

      assert readme =~ "tenancy callbacks"
      assert readme =~ "adapter_ref"
      refute readme =~ "round-robin"
      refute readme =~ "failover"
    end

    test "admin README points to the canonical admin contract and excludes UI internals" do
      admin = File.read!("mailglass_admin/README.md")

      assert admin =~ "docs/operator-trust.md"
      assert admin =~ "docs/api_stability.md"
      assert admin =~ "docs/compatibility-and-deprecations.md"
      assert admin =~ "MailglassAdmin.Auth"
      assert admin =~ "Stable DOM/component/LiveView implementation APIs"
      refute admin =~ "{:mailglass, \"~> 0.1\"}"
      refute admin =~ "{:mailglass_admin, \"~> 0.1\"}"
    end
  end

  describe "Task existence" do
    test "referenced tasks are available" do
      assert Mix.Task.get("mailglass.install")
      assert Mix.Task.get("mailglass.suppressions.resync")
      assert Mix.Task.get("mailglass.webhooks.prune")
      assert Mix.Task.get("mailglass.docs.check")
    end
  end

  describe "Guide contracts" do
    test "Getting Started compiles" do
      code = extract_block_after_heading("guides/getting-started.md", "4) Send your first message")
      assert code
      assert code =~ "|> to(user.email)"
      refute code =~ "Swoosh.Email.to"
      assert {:ok, _quoted} = Code.string_to_quoted(code)
    end

    test "Config examples are valid" do
      code = extract_block_after_heading("guides/getting-started.md", "2) Configure mailglass")
      assert code
      assert code =~ "config :mailglass"
      assert code =~ "repo:"
      assert code =~ "adapter:"
    end

    test "Multi-tenancy routing example parses and documents the shipped adapter_ref surface" do
      blocks = extract_code_blocks("guides/multi-tenancy.md")
      tenancy_code = Enum.find(blocks, &String.contains?(&1, "resolve_outbound_adapter_ref"))

      assert tenancy_code
      assert tenancy_code =~ ":default"
      assert {:ok, _quoted} = Code.string_to_quoted(tenancy_code)

      guide = File.read!("guides/multi-tenancy.md")
      assert guide =~ "config :mailglass, adapters:"
      assert guide =~ "single-tenant"
      assert guide =~ "Different ESP per tenant"
      assert guide =~ "different credentials"
      assert guide =~ "different stream or domain routes"
      assert guide =~ "adapter_ref"
      refute guide =~ "round-robin"
      refute guide =~ "failover"
      refute guide =~ "registry process"
      refute guide =~ "cache invalidation"
    end

    test "Phase 33 support docs use the shipped telemetry and repair vocabulary" do
      telemetry = File.read!("guides/telemetry.md")
      troubleshooting = File.read!("guides/webhook-troubleshooting.md")
      webhooks = File.read!("guides/webhooks.md")
      admin = File.read!("mailglass_admin/README.md")
      stale_deliver = "[:mailglass, :" <> "deliver]"
      stale_reconcile = "[:mailglass, :" <> "reconcile]"
      stale_metadata_key = "metadata." <> "function"

      assert telemetry =~ "[:mailglass, :render, :message"
      assert telemetry =~ "[:mailglass, :outbound, :dispatch"
      assert telemetry =~ "[:mailglass, :webhook, :ingest"
      assert telemetry =~ "[:mailglass, :webhook, :reconcile"
      refute telemetry =~ stale_deliver
      refute telemetry =~ stale_reconcile
      refute telemetry =~ stale_metadata_key

      assert troubleshooting =~ "canonical incident guide"
      assert troubleshooting =~ "Exact webhook reference sections"
      assert troubleshooting =~ "provider lifecycle facts"
      assert troubleshooting =~ "replay facts"
      assert troubleshooting =~ "reconcile facts"

      assert webhooks =~ "provider lifecycle facts, replay facts, and reconcile facts"
      assert webhooks =~ "Replay acts on one exact stored webhook row"
      assert webhooks =~ "background-first sweep"

      assert admin =~ "provider lifecycle facts"
      assert admin =~ "replay facts"
      assert admin =~ "reconcile facts"
      assert admin =~ "mix mailglass.reconcile"
      assert admin =~ "exact stored webhook target"
    end

    test "MAINTAINING.md pins the required versus advisory verification contract" do
      maintaining = File.read!("MAINTAINING.md")

      assert maintaining =~ "scripts/verify_support_contract.sh"
      assert maintaining =~ "Support Contract Core"
      assert maintaining =~ "Support Contract Admin"
      assert maintaining =~ "Compile No Optional Deps"
      assert maintaining =~ "Core Full Suite Advisory"
      assert maintaining =~ "Provider Compatibility Advisory"
      assert maintaining =~ "Provider Live Advisory"
      assert maintaining =~ "cron and `workflow_dispatch` canary"
      assert maintaining =~ "not a merge blocker"
      assert maintaining =~ "guides/compatibility-and-deprecations.md"
    end

    test "compatibility and upgrade guides are wired into Tier 1 docs" do
      compatibility = File.read!("guides/compatibility-and-deprecations.md")
      upgrade = File.read!("guides/upgrading-to-v1_0.md")
      testing = File.read!("guides/testing.md")
      trust_doc = File.read!("mailglass_admin/docs/operator-trust.md")
      docs_check = File.read!("lib/mix/tasks/mailglass.docs.check.ex")

      assert compatibility =~ "stable lane"
      assert compatibility =~ "support matrix"
      assert compatibility =~ "upgrading-to-v1_0.md"

      assert upgrade =~ "canonical latest-`0.x` to `1.0` upgrade guide"
      assert upgrade =~ "subordinate references"
      assert upgrade =~ "proof artifact"

      assert testing =~ "## deliver/2 baseline"
      assert testing =~ "Fake.allow/2"
      assert trust_doc =~ "## Stable seams"
      assert trust_doc =~ "new work"
      assert docs_check =~ "\"guides/testing.md\""
      assert docs_check =~ "\"mailglass_admin/docs/operator-trust.md\""
    end

    test "phase 38 prepublish proof bundle captures package, docs, and sibling release truth" do
      proof =
        File.read!(
          ".planning/phases/38-release-rehearsal-and-proof-artifacts/38-01-PREPUBLISH-PROOF.md"
        )

      assert proof =~ "## Tarball/package truth"
      assert proof =~ "## HexDocs input truth"
      assert proof =~ "## Sibling release truth"
      assert proof =~ "## Release rehearsal evidence"
      assert proof =~ ".planning/publish/mailglass-publish-summary.json"
      assert proof =~ ".planning/publish/mailglass_admin-publish-summary.json"
      assert proof =~ "groups_for_extras"
      assert proof =~ "source_url"
      assert proof =~ "source_ref"
      assert proof =~ ".release-please-manifest.json"
      assert proof =~ ".github/workflows/publish-hex.yml"
      assert proof =~ ".github/workflows/post-publish-smoke.yml"
    end
  end
end
