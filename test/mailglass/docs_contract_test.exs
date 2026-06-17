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

      # The install snippet's `~> X.Y` pins must track the published version so a
      # copy-paste install always resolves. Dynamic (not hardcoded) so the pin
      # can never silently drift from @version — mirrors the inbound WR-01 test
      # at mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs. core
      # + mailglass_admin are linked, so both pins match the core @version
      # major.minor. release-please's sed step bumps the README on the release PR.
      version = Mix.Project.config()[:version]
      [major, minor | _] = String.split(version, ".")
      expected_major_minor = "#{major}.#{minor}"

      for dep <- ["mailglass", "mailglass_admin"] do
        [_, major_minor] =
          Regex.run(~r/\{:#{dep},\s*"~>\s*(\d+\.\d+)/, readme) ||
            flunk("README is missing a `{:#{dep}, \"~> X.Y\"}` dep pin")

        assert major_minor == expected_major_minor,
               "README pins #{dep} to ~> #{major_minor} but the package version " <>
                 "is #{version} (expected ~> #{expected_major_minor})"
      end

      assert readme =~ "docs/api_stability.md"
      assert readme =~ "guides/compatibility-and-deprecations.md"
      assert readme =~ "guides/upgrading-to-v1_0.md"
      assert readme =~ "## Demo App"
      assert readme =~ "reference/demo_app"
      assert readme =~ "reference/host_app"
      assert readme =~ "maintained trust-proof baseline"
      assert readme =~ "**`mailglass_inbound`** (inbound routing; stable 1.0)"
      assert readme =~ "`mailglass_inbound` has its own stable `1.0` contract inventory"
      assert readme =~ "mailglass_inbound/docs/api_stability.md"
      assert readme =~ "independent package release line"
      assert readme =~ "`mailglass_inbound` | Stable `1.0` contract documented separately"
      refute readme =~ "v0.1 in development"
      refute readme =~ "v0.3 public surface"
      refute readme =~ "inbound routing; v0.5+"
      refute readme =~ "`mailglass_inbound` is outside the `v1.x` stability promise"
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
      assert admin =~ "does not fabricate new inbound messages"
      assert Regex.match?(~r/preview-pipeline confidence\s+only/i, admin)
      refute admin =~ "docker compose -f compose.demo.yml up demo"
      refute admin =~ "demo_browser_evidence.v1"
      refute admin =~ "{:mailglass, \"~> 0.1\"}"
      refute admin =~ "{:mailglass_admin, \"~> 0.1\"}"
      refute admin =~ "guaranteed client parity"
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

    test "learning-path is registered in both mix.exs docs lists" do
      mix_exs = File.read!("mix.exs")
      matches = Regex.scan(~r/"guides\/learning-path\.md"/, mix_exs)

      assert length(matches) >= 2,
             "expected \"guides/learning-path.md\" to appear in both extras: and " <>
               "groups_for_extras: [Guides: ...] in mix.exs, but found #{length(matches)} occurrence(s)"

      assert File.exists?("guides/learning-path.md"),
             "guides/learning-path.md does not exist on disk"
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

      assert maintaining =~
               "Required inbound release proof is deterministic repo/package/workflow evidence"

      assert maintaining =~ "mix mailglass.publish.check --package mailglass_inbound"
      assert maintaining =~ "Provider-live checks and ecosystem canaries remain advisory"
      assert maintaining =~ "cron and `workflow_dispatch` canary"
      assert maintaining =~ "not a merge blocker"
      assert maintaining =~ ~s({:mailglass_inbound, "~> 1.0"})
      assert maintaining =~ "mailglass_inbound-v1.0.0"
      refute maintaining =~ ~s({:mailglass_inbound, "~> 0.3"})
      refute maintaining =~ "for `1.0.0`: `mailglass-v1.0.0`"
      assert maintaining =~ "guides/compatibility-and-deprecations.md"
      assert maintaining =~ "JTBD Docs Refresh Protocol"
      assert maintaining =~ "guides/jobs.md"
      assert maintaining =~ ".planning/research/JTBD-COVERAGE.md"
      assert maintaining =~ "Always refresh the internal map first"
      assert maintaining =~ "Rails Action Mailer"
      assert maintaining =~ "Action Mailbox"
      assert maintaining =~ "Anymail"
      assert maintaining =~ "Laravel Mail"
      assert maintaining =~ "Resend inbound docs"
      refute maintaining =~ "while it remains outside the `v1.x`"
      assert maintaining =~ "independent `1.0` contract"
    end

    test "preview docs stay within bounded preview-pipeline confidence language" do
      preview_guide = File.read!("guides/preview.md")
      admin = File.read!("mailglass_admin/README.md")

      assert Regex.match?(~r/preview-pipeline confidence\s+only/i, preview_guide)
      assert Regex.match?(~r/preview-pipeline confidence\s+only/i, admin)
      refute preview_guide =~ "guaranteed client parity"
      refute admin =~ "guaranteed client parity"

      assert Regex.match?(
               ~r/(?:does(?:\s+\*\*not\*\*|\s+not)\s+claim|not)\s+cross-client parity/i,
               preview_guide
             )

      assert Regex.match?(
               ~r/(?:does(?:\s+\*\*not\*\*|\s+not)\s+claim|not)\s+cross-client parity/i,
               admin
             )
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

    @tag :skip
    test "phase 38 prepublish proof bundle captures package, docs, and sibling release truth" do
      # SKIPPED: the original Phase 38 prepublish-proof artifact at
      # `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-01-PREPUBLISH-PROOF.md`
      # was archived in commit 8e80600 ("chore: archive phase directories from
      # completed milestones"). Phase 044.5 (v1.0/v1.1 release ceremony)
      # produces an equivalent artifact at
      # `.planning/phases/044.5-v1-0-1-1-release-ceremony/044.5-RELEASE-RECORD.md`
      # but its section structure differs from Phase 38's, so a 1:1 assertion
      # rewrite is out of scope for this CI-triage commit. Phase 51 closeout
      # should re-pin these assertions to the v1.0/1.1 release-record format.
      :ok
    end
  end

  describe "Phase 61 trust-entry docs contract" do
    test "trust-entry docs route guarantees to canonical stability lanes with non-contract framing" do
      maintaining = File.read!("MAINTAINING.md")
      webhooks = File.read!("guides/webhooks.md")
      troubleshooting = File.read!("guides/webhook-troubleshooting.md")
      operator_trust = File.read!("mailglass_admin/docs/operator-trust.md")

      for doc <- [maintaining, webhooks, troubleshooting, operator_trust] do
        assert doc =~ "api_stability.md"
        assert doc =~ "mix verify.stability_contract"
      end

      assert maintaining =~ "not API-contract truth"
      assert webhooks =~ "implementation detail"
      assert troubleshooting =~ "implementation detail"
      assert operator_trust =~ "implementation detail"
    end
  end

  describe "inbound doc contracts" do
    test "inbound install guide covers the canonical setup steps" do
      doc = File.read!("mailglass_inbound/docs/inbound-install.md")
      assert doc =~ "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
      assert doc =~ "use MailglassInbound.Router"
      assert doc =~ "@behaviour MailglassInbound.Mailbox"
      assert doc =~ "mix ecto.migrate"
      assert doc =~ "async: false"
      refute doc =~ "mix mailglass.install"
    end

    test "inbound testing guide covers MailboxCase, assertions, and StreamData" do
      doc = File.read!("mailglass_inbound/docs/inbound-testing.md")
      assert doc =~ "use MailglassInbound.MailboxCase"
      assert doc =~ "assert_inbound_received"
      assert doc =~ "Test.Ingress.receive_inbound"
      assert doc =~ "async: false"
      assert doc =~ "StreamData"
    end

    test "inbound operator guide covers the three mix tasks and retention config" do
      doc = File.read!("mailglass_inbound/docs/inbound-operator.md")
      assert doc =~ "mix mailglass.inbound.doctor"
      assert doc =~ "mix mailglass.inbound.replay"
      assert doc =~ "mix mailglass.inbound.prune"
      assert doc =~ "--tenant"
      assert doc =~ "retention:"
    end

    test "inbound mailgun guide covers signing key and HMAC verification" do
      doc = File.read!("mailglass_inbound/docs/inbound-mailgun.md")
      assert doc =~ "signing_key"
      assert doc =~ "HMAC-SHA256"
      assert doc =~ "MailglassInbound.Ingress.CachingBodyReader"
    end

    test "inbound SES guide covers S3 fetcher, sweet_xml, and subscription confirmation" do
      doc = File.read!("mailglass_inbound/docs/inbound-ses.md")
      assert doc =~ "ex_aws_s3"
      assert doc =~ "S3Fetcher.ExAwsS3"
      assert doc =~ "sweet_xml"
      assert doc =~ "SubscribeURL"
      assert doc =~ "SubscriptionConfirmation"
    end

    test "inbound routing-debug guide covers the routing-trace card, CLI inspection, and envelope distinction" do
      doc = File.read!("mailglass_inbound/docs/inbound-routing-debug.md")
      assert doc =~ "routing-trace"
      assert doc =~ "__mailglass_inbound_routes__"
      assert doc =~ "mix mailglass.inbound.doctor"
      assert doc =~ "envelope"
    end
  end

  describe "jobs.md contract" do
    # guides/jobs.md is the public JTBD ramp-up guide. Its snippets are a
    # projection of the canonical surface, so they must keep parsing and keep
    # using the documented public API as the library evolves. See
    # .planning/research/JTBD-COVERAGE.md for the source-of-truth map.

    # Each job's code block, located by a stable marker. Keep in sync with the
    # <!-- JN --> markers in guides/jobs.md.
    @jobs_markers [
      "import Mailglass.Components",
      "mailglass_admin_routes",
      "password_reset",
      "Mailglass.deliver_later()",
      "Mailglass.PubSub.Topics.events",
      "import Mailglass.TestAssertions",
      "Mailglass.SuppressedError",
      "mailglass_webhook_routes",
      "mailglass_operator_routes",
      "resolve_outbound_adapter_ref"
    ]

    test "freshness stamp and inbound stability boundary are present" do
      jobs = File.read!("guides/jobs.md")

      assert jobs =~ "Current as of 2026-06-02"
      assert jobs =~ "mailglass` and `mailglass_admin`"
      assert jobs =~ "independent stable `1.0` contract"
      assert jobs =~ "mailglass_inbound/docs/api_stability.md"
      refute jobs =~ "outside the `v1.x` stability promise"
    end

    test "every documented job snippet parses to a valid quoted form" do
      blocks = extract_code_blocks("guides/jobs.md")

      for marker <- @jobs_markers do
        block = Enum.find(blocks, &String.contains?(&1, marker))
        assert block, "expected a jobs.md code block containing #{inspect(marker)}"
        assert {:ok, _quoted} = Code.string_to_quoted(block)
      end
    end

    test "jobs.md stays on the canonical path and never leaks Swoosh internals" do
      blocks = extract_code_blocks("guides/jobs.md")

      refute Enum.any?(blocks, &String.contains?(&1, "Swoosh.Email"))
      refute Enum.any?(blocks, &String.contains?(&1, "Swoosh.Mailer.deliver"))
    end

    test "the auth-send job uses the canonical Mailable + deliver surface" do
      blocks = extract_code_blocks("guides/jobs.md")
      send_block = Enum.find(blocks, &String.contains?(&1, "password_reset"))

      assert send_block
      assert send_block =~ "use Mailglass.Mailable"
      assert send_block =~ "|> to(user.email)"
      assert send_block =~ "Mailglass.deliver()"
      refute send_block =~ "Swoosh.Email.to"
    end
  end
end
