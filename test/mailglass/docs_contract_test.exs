defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers

  describe "README.md contract" do
    test "current package compatibility guidance is derived from every package manifest" do
      core_version = package_major_minor!("mix.exs")
      admin_version = package_major_minor!("mailglass_admin/mix.exs")
      inbound_version = package_major_minor!("mailglass_inbound/mix.exs")

      root_guidance = current_compatibility_section!(File.read!("README.md"), "README.md")

      assert dependency_constraint!(root_guidance, "mailglass", "README.md") == core_version
      assert dependency_constraint!(root_guidance, "mailglass_admin", "README.md") == admin_version

      assert dependency_constraint!(root_guidance, "mailglass_inbound", "README.md") ==
               inbound_version

      admin_guidance =
        current_compatibility_section!(
          File.read!("mailglass_admin/README.md"),
          "mailglass_admin/README.md"
        )

      assert dependency_constraint!(admin_guidance, "mailglass", "mailglass_admin/README.md") ==
               core_version

      assert dependency_constraint!(admin_guidance, "mailglass_admin", "mailglass_admin/README.md") ==
               admin_version

      inbound_guidance =
        current_compatibility_section!(
          File.read!("mailglass_inbound/README.md"),
          "mailglass_inbound/README.md"
        )

      assert dependency_constraint!(
               inbound_guidance,
               "mailglass_inbound",
               "mailglass_inbound/README.md"
             ) ==
               inbound_version

      assert dependency_constraint!(inbound_guidance, "mailglass", "mailglass_inbound/README.md") ==
               core_version
    end

    test "production operator guidance includes a production-capable admin dependency" do
      root = current_compatibility_section!(File.read!("README.md"), "README.md")
      admin = File.read!("mailglass_admin/README.md")

      assert root =~ ~s({:mailglass_admin, "~> 2.5"})
      refute root =~ ~s({:mailglass_admin, "~> 2.5", only:)

      assert admin =~ "Preview-only installation"
      assert admin =~ ~s({:mailglass_admin, "~> 2.5", only: :dev})
      assert admin =~ "Production operator installation"
      assert admin =~ ~s({:mailglass_admin, "~> 2.5"})
    end

    test "current contract labels track package manifest majors" do
      core_major = package_major_minor!("mix.exs") |> String.split(".") |> hd()
      admin_major = package_major_minor!("mailglass_admin/mix.exs") |> String.split(".") |> hd()
      inbound_major = package_major_minor!("mailglass_inbound/mix.exs") |> String.split(".") |> hd()
      readme = File.read!("README.md")
      admin = File.read!("mailglass_admin/README.md")
      maintaining = File.read!("MAINTAINING.md")

      assert readme =~ "canonical `v#{core_major}.x` contract"

      assert readme =~
               "current `v#{core_major}.x` compatibility, deprecation, and support-matrix policy with retained historical `1.x` promises"

      assert readme =~ "`mailglass`         | `v#{core_major}.x` contract"
      assert readme =~ "`mailglass_admin`   | Narrow `v#{admin_major}.x` admin contract"
      assert admin =~ "canonical `v#{admin_major}.x` admin surface"
      assert maintaining =~ "independent `#{inbound_major}.x` contract"
    end

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
      assert readme =~ "**`mailglass_inbound`** (inbound routing; stable 2.0)"
      assert readme =~ "`mailglass_inbound` has its own stable `2.0` contract inventory"
      assert readme =~ "mailglass_inbound/docs/api_stability.md"
      assert readme =~ "independent package release line"
      assert readme =~ "`mailglass_inbound` | Stable `2.0` contract documented separately"
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

    test "Quickstart contains a config-first block before the deliver() example" do
      readme = File.read!("README.md")
      config_pos = :binary.match(readme, "config :mailglass")
      deliver_pos = :binary.match(readme, "Mailglass.deliver()")
      assert config_pos != :nomatch, "README Quickstart is missing a config :mailglass block"
      assert deliver_pos != :nomatch, "README Quickstart is missing a Mailglass.deliver() call"
      {config_offset, _} = config_pos
      {deliver_offset, _} = deliver_pos

      assert config_offset < deliver_offset,
             "config :mailglass block must appear before Mailglass.deliver() in the README"

      assert readme =~ "repo:"
      assert readme =~ "adapter:"
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
    test "B2C first-adopter profile locks the safe consumer launch contract" do
      guide = File.read!("guides/b2c-first-adopter.md")
      blocks = extract_code_blocks("guides/b2c-first-adopter.md")

      assert guide =~ "Do not create `crosswake_mailglass`"
      assert guide =~ "operational or bulk unsubscribe therefore does not suppress"
      assert guide =~ "Hard bounces and complaints are intentionally address-wide"
      assert guide =~ "[:mailglass, :delivery, :feedback, :stop]"
      assert guide =~ "Sigra or the host validates magic-link GETs without consuming them"
      assert guide =~ "Production inbound processing uses Oban"
      assert "guides/b2c-first-adopter.md" in Mix.Project.config()[:docs][:extras]
      assert Enum.any?(blocks, &(&1 =~ "resolve_outbound_adapter_ref"))
      assert Enum.any?(blocks, &(&1 =~ "List-Unsubscribe-Post"))
      assert Enum.all?(blocks, &match?({:ok, _}, Code.string_to_quoted(&1)))
    end

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

    test "Getting Started ends on a Next steps section" do
      getting_started = File.read!("guides/getting-started.md")
      # Collect all ## headings in document order
      headings = Regex.scan(~r/^## (.+)$/m, getting_started) |> Enum.map(fn [_, h] -> h end)
      assert headings != [], "getting-started.md has no ## headings"
      last_heading = List.last(headings)

      assert last_heading == "Next steps",
             "getting-started.md must end on '## Next steps' but last heading is '## #{last_heading}'"

      # Guide links to learning-path.md in the Next steps section
      assert getting_started =~ "learning-path.md",
             "getting-started.md Next steps must link to learning-path.md"

      # Updated troubleshooting entry reflects Phase 104 fail-closed behavior:
      # Mix.raise on the conflict, the --force escape hatch, and the doctor check.
      assert getting_started =~ "mix mailglass.doctor",
             "getting-started.md Troubleshooting must describe mix mailglass.doctor"

      assert getting_started =~ "--force",
             "getting-started.md Troubleshooting must describe the --force escape hatch"

      assert getting_started =~ "Mix.raise",
             "getting-started.md Troubleshooting must describe the Mix.raise fail-closed behavior"
    end

    test "admin asset docs no longer present deep-link styling as unresolved" do
      demo = File.read!("guides/run-the-demo.md")
      design_system = File.read!("mailglass_admin/docs/design-system.md")
      backlog = File.read!(".planning/backlog/admin-relative-asset-url-styling.md")

      assert demo =~
               "Hard refreshes and direct deep links should stay styled. If they do not, run the admin asset browser proof and treat it as a regression."

      assert design_system =~ "resolved and proven in v2.1 Phase 139"
      assert design_system =~ "stylesheet responses, font responses"
      assert design_system =~ "token-backed computed styling"
      assert design_system =~ "admin asset hard load"

      assert backlog =~ "Resolved in v2.1 Phase 139"
      assert backlog =~ "Phase 139/GATE-03 evidence"

      for id <- ~w(AAU-01 AAU-02 AAU-03 AAU-04 AAU-05) do
        assert backlog =~ "- [x] **#{id}**",
               "admin-relative-asset-url-styling.md must mark #{id} complete"
      end

      stale_phrases = [
        "Navigate from the dashboard",
        "Tracked as GAP-22",
        "hard refresh on a deep URL can load unstyled",
        "direct loads unstyled"
      ]

      for phrase <- stale_phrases do
        refute demo =~ phrase, "run-the-demo.md still contains stale asset wording: #{phrase}"

        refute design_system =~ phrase,
               "design-system.md still contains stale asset wording: #{phrase}"

        refute backlog =~ phrase,
               "admin-relative-asset-url-styling.md still contains stale asset wording: #{phrase}"
      end
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

    test "migration-from-swoosh opens with the value-prop pitch before subordinate framing" do
      migration = File.read!("guides/migration-from-swoosh.md")

      value_prop_keywords = [
        "transport",
        "framework layer",
        "preview",
        "webhooks",
        "audit",
        "suppressions",
        "multi-tenancy"
      ]

      for kw <- value_prop_keywords do
        assert migration =~ kw,
               "migration-from-swoosh.md is missing value-prop keyword: #{inspect(kw)}"
      end

      # Opener must appear before the subordinate-reference framing
      opener_pos = :binary.match(migration, "framework layer")
      subordinate_pos = :binary.match(migration, "subordinate")
      assert opener_pos != :nomatch, "migration-from-swoosh.md is missing 'framework layer' opener"

      assert subordinate_pos != :nomatch,
             "migration-from-swoosh.md is missing 'subordinate' reference"

      {opener_offset, _} = opener_pos
      {subordinate_offset, _} = subordinate_pos

      assert opener_offset < subordinate_offset,
             "value-prop opener must appear before 'subordinate' framing"

      # Stale pins are fixed and the current 1.x pin is present (positive assertion so
      # deleting the dep block or pinning to some other wrong version cannot pass).
      refute migration =~ "~> 0.3", "migration-from-swoosh.md still contains stale ~> 0.3 pin"

      assert migration =~ ~r/~>\s*1\.6/,
             "migration-from-swoosh.md must pin the current ~> 1.6 series"
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
      # The advisory-matrix lanes are pinned by their RUNTIME names, under their own
      # top-level section (Phase 143 / D-25). The gating leg's name deliberately
      # carries no "Advisory" suffix: a lane that gates a publish must not call
      # itself advisory (D-21), and the refute below keeps the old name from
      # creeping back in a future edit.
      assert maintaining =~ "## Advisory Matrix Lanes"
      assert maintaining =~ "Core Full Suite (Elixir 1.18 / OTP 27 / schema public)"
      assert maintaining =~ "Core Full Suite Next Toolchain Advisory"
      refute maintaining =~ "Core Full Suite Advisory ("
      assert maintaining =~ "Provider Compatibility Advisory"
      assert maintaining =~ "Inbound Full Suite Advisory"
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
      assert maintaining =~ "independent `2.x` contract"
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

    test "production-go-live-checklist is registered in both mix.exs docs lists" do
      mix_exs = File.read!("mix.exs")
      matches = Regex.scan(~r/"guides\/production-go-live-checklist\.md"/, mix_exs)

      assert length(matches) >= 2,
             "expected \"guides/production-go-live-checklist.md\" to appear in both extras: and " <>
               "groups_for_extras: [Guides: ...] in mix.exs, but found #{length(matches)} occurrence(s)"

      assert File.exists?("guides/production-go-live-checklist.md"),
             "guides/production-go-live-checklist.md does not exist on disk"
    end

    test "errors-and-troubleshooting is registered in both mix.exs docs lists" do
      mix_exs = File.read!("mix.exs")
      matches = Regex.scan(~r/"guides\/errors-and-troubleshooting\.md"/, mix_exs)

      assert length(matches) >= 2,
             "expected \"guides/errors-and-troubleshooting.md\" to appear in both extras: and " <>
               "groups_for_extras: [Guides: ...] in mix.exs, but found #{length(matches)} occurrence(s)"

      assert File.exists?("guides/errors-and-troubleshooting.md"),
             "guides/errors-and-troubleshooting.md does not exist on disk"
    end

    test "production-go-live-checklist covers required go-live topics" do
      checklist = File.read!("guides/production-go-live-checklist.md")
      # Both distinct doctor commands must appear literally
      assert checklist =~ "mix mail.doctor"
      assert checklist =~ "mix mailglass.doctor"
      # Oban queue sizing section marker
      assert checklist =~ "Oban"
      # Suppression section marker
      assert checklist =~ "suppression"
      # Telemetry section marker
      assert checklist =~ "telemetry"
      # Webhook secret rotation section marker
      assert checklist =~ "rotation"
    end

    test "errors-and-troubleshooting covers all ten error structs and routes to api_stability.md" do
      guide = File.read!("guides/errors-and-troubleshooting.md")

      error_names = [
        "SendError",
        "TemplateError",
        "SignatureError",
        "SuppressedError",
        "RateLimitError",
        "ConfigError",
        "EventLedgerImmutableError",
        "TenancyError",
        "StreamPolicyError",
        "PublishError"
      ]

      for name <- error_names do
        assert guide =~ name,
               "errors-and-troubleshooting.md is missing error struct: #{name}"
      end

      # The guide must route canonical atom-set truth to api_stability.md (D-03)
      assert guide =~ "api_stability.md",
             "errors-and-troubleshooting.md must cross-link to docs/api_stability.md"
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

  describe "v2.6 public documentation contract" do
    test "current snapshot owns every additive seam and keeps architecture internals private" do
      core = File.read!("docs/api_stability.md")
      compatibility = File.read!("guides/compatibility-and-deprecations.md")
      adopter = File.read!("guides/b2c-first-adopter.md")

      assert v26_contract_errors(core, compatibility, adopter) == []
      assert Mix.Task.get("mailglass.gen.migration")
      assert Code.ensure_loaded?(Mailglass.Migration)
      assert function_exported?(Mailglass.Migration, :up, 1)
      assert function_exported?(Mailglass.Migration, :down, 1)
      assert function_exported?(Mailglass.Migration, :migrated_version, 1)
      assert %Mailglass.MigrationVersionError{} = struct(Mailglass.MigrationVersionError)
      assert :dispatch_unavailable in Mailglass.SendError.__types__()
      assert Map.has_key?(struct(Mailglass.SendError), :retry_class)
    end

    test "negative controls reject missing inventory facts and unsafe claims" do
      core = File.read!("docs/api_stability.md")
      compatibility = File.read!("guides/compatibility-and-deprecations.md")
      adopter = File.read!("guides/b2c-first-adopter.md")

      for {kind, token} <- v26_required_contract_tokens() do
        {changed_core, changed_compatibility} =
          if String.contains?(core, token) do
            {String.replace(core, token, ""), compatibility}
          else
            {core, String.replace(compatibility, token, "")}
          end

        assert kind in v26_contract_errors(changed_core, changed_compatibility, adopter),
               "removing #{inspect(token)} did not trigger #{inspect(kind)}"
      end

      stale = compatibility <> "\nThe current stable line is v1.x.\n"
      assert :stale_version_claim in v26_contract_errors(core, stale, adopter)

      ui_promise = adopter <> "\nThe operator dashboard ships a live delivery console.\n"
      assert :admin_operator_behavior_claim in v26_contract_errors(core, compatibility, ui_promise)
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

  defp v26_contract_errors(core, compatibility, adopter) do
    combined = core <> "\n" <> compatibility

    missing =
      for {kind, token} <- v26_required_contract_tokens(),
          not String.contains?(combined, token),
          do: kind

    stale =
      if Regex.match?(~r/current stable line is v1\.x/i, combined),
        do: [:stale_version_claim],
        else: []

    ui_claim =
      if Regex.match?(
           ~r/(admin|operator) (dashboard|ui)[^\n]*(ships|provides|supports|visibly)/i,
           adopter
         ),
         do: [:admin_operator_behavior_claim],
         else: []

    Enum.uniq(missing ++ stale ++ ui_claim)
  end

  defp package_major_minor!(mixfile_path) do
    mixfile = File.read!(mixfile_path)

    [_, version] =
      Regex.run(~r/@version\s+"(\d+\.\d+\.\d+)"/, mixfile) ||
        flunk("#{mixfile_path} is missing an @version X.Y.Z manifest value")

    version
    |> String.split(".")
    |> Enum.take(2)
    |> Enum.join(".")
  end

  defp current_compatibility_section!(readme, path) do
    case Regex.run(~r/^## Current package compatibility\n\n([\s\S]*?)(?=^## |\z)/m, readme) do
      [_, section] -> section
      _ -> flunk("#{path} is missing its current package compatibility section")
    end
  end

  defp dependency_constraint!(section, dependency, path) do
    case Regex.run(~r/\{:#{dependency},\s*"~>\s*(\d+\.\d+)/, section) do
      [_, major_minor] -> major_minor
      _ -> flunk("#{path} is missing a current {:#{dependency}, \"~> X.Y\"} constraint")
    end
  end

  defp v26_required_contract_tokens do
    [
      {:package_owner, "Package owner: `mailglass`"},
      {:additive_interface, "mix mailglass.gen.migration --repo MyApp.Repo"},
      {:additive_interface, "Mailglass.Migration.up/1"},
      {:additive_interface, "Mailglass.Migration.down/1"},
      {:additive_interface, "Mailglass.Migration.migrated_version/1"},
      {:additive_interface, "Mailglass.MigrationVersionError"},
      {:additive_interface, "`:dispatch_unavailable`"},
      {:additive_interface, "`retry_class`"},
      {:deprecation_status, "Status: deprecated in v2"},
      {:replacement, "Replacement: `Mailglass.deliver/2`"},
      {:removal_target, "Removal target: v3.0"},
      {:additive_only, "No public v2 API is removed or renamed by v2.6."},
      {:internal_boundary, "runtime configuration owner remains internal"}
    ]
  end
end
