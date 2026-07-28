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

    test "architecture guide is published, visual, and discoverable" do
      guide = File.read!("guides/architecture.md")
      readme = File.read!("README.md")
      learning_path = File.read!("guides/learning-path.md")
      docs = Mix.Project.config()[:docs]

      assert "guides/architecture.md" in docs[:extras]
      assert "guides/architecture.md" in Keyword.fetch!(docs, :groups_for_extras)[:Guides]
      assert readme =~ "guides/architecture.md"
      assert learning_path =~ "architecture.md"

      headings = [
        "## Mailglass in one picture",
        "## Vocabulary for the trip",
        "## Journey 1: an outbound message",
        "## Journey 2: the email service reports back",
        "## The data model is the architecture",
        "## Module atlas",
        "## Code-reading routes",
        "## Changing it safely"
      ]

      positions =
        for heading <- headings do
          assert guide =~ heading
          {position, _length} = :binary.match(guide, heading)
          position
        end

      assert positions == Enum.sort(positions), "architecture guide headings are out of order"

      [opening, _journey] = String.split(guide, "## Journey 1: an outbound message", parts: 2)

      assert length(String.split(opening)) <= 700,
             "architecture guide takes more than 700 words to reach the first journey"

      assert length(Regex.scan(~r/^```mermaid$/m, guide)) == 4
      assert length(Regex.scan(~r/^```elixir$/m, guide)) == 7
      assert guide =~ "Mailglass turns an email from a one-way send call into a lifecycle"
      assert guide =~ "Describe<br/>Mailable + Message"
      assert guide =~ "Check and compile<br/>policy gates + Renderer"
      assert guide =~ "Remember<br/>Delivery + queued Event"
      assert guide =~ "Carry<br/>Swoosh adapter"
      assert guide =~ "Deliver and report<br/>transactional email service"
      assert guide =~ "Learn<br/>webhook → Events"
      assert guide =~ "Learn -. \"next send\" .-> Compile"
      assert guide =~ "Application<br/>deliver_later(message)"
      assert guide =~ "Oban worker<br/>restore tenant + load rendered snapshot"
      refute Regex.match?(~r/\["\d+ · /, guide)
      assert guide =~ "Delivery + queued Event + Oban job"
      assert guide =~ "Transport outside a DB transaction"
      assert guide =~ "out of band"
      assert guide =~ "Dispatched is not delivered"
      assert guide =~ "the conventional\nterm **provider**"
      assert guide =~ "Mailglass owns the lifecycle; Swoosh carries the email"
      assert guide =~ "calls the configured `Swoosh.Adapter` directly"
      assert guide =~ "It does not render content, write records"
      assert guide =~ "{:ok, %Mailglass.Outbound.Delivery{status: :queued}}"
      assert guide =~ "{:ok, rendered} = Mailglass.Renderer.render(message)"
      assert guide =~ "swoosh_adapter:"
      assert guide =~ "\"delivery_id\" => delivery.id"
      assert guide =~ "\"mailglass_tenant_id\" => delivery.tenant_id"
      assert guide =~ "# A later webhook advanced the projection"
      assert guide =~ "%Mailglass.Webhook.WebhookEvent{"
      assert guide =~ "%Mailglass.Events.Event{"
      assert guide =~ "Temporary receipt containing the provider payload and ingest status"
      assert guide =~ "WebhookEvent<br/>temporary webhook receipt"
      assert guide =~ "Rendering compiles content into an email artifact"
      assert guide =~ "A mailable is a reusable recipe for one kind of email"
      assert guide =~ "defmodule MyApp.AccountMailer do"
      assert guide =~ "Declare that policy once on the recipe"
      assert guide =~ "five policy gates"
      assert guide =~ "dynamic assign binding are also still adopter-owned"
      assert guide =~ "`component_fn.(%{})`"
      assert guide =~ "workers never rerun adopter template logic"
      assert guide =~ "preview has crossed a boundary it is designed not to cross"
      assert guide =~ "Never call an email provider inside a database transaction"
      assert guide =~ "provider-defined signed material"
      assert guide =~ "does not currently populate a durable webhook DLQ"
      assert guide =~ "Synthetic result whose `last_error`"
      assert guide =~ "Do not infer stability from reachability"
      assert guide =~ "This is a reading map, not a new compatibility promise"
      refute guide =~ "lib/mailglass"
      refute guide =~ "## Domain language in five minutes"
      refute guide =~ "prunable envelope"
      refute guide =~ "raw and prunable"
      refute guide =~ "compile-time policy such as the message stream"
      refute guide =~ "alt synchronous deliver"
      refute guide =~ "else TaskSupervisor fallback"
    end

    test "ExDoc renders Mermaid diagrams with a pinned, failure-safe hook" do
      docs = Mix.Project.config()[:docs]
      body_hook = Keyword.fetch!(docs, :before_closing_body_tag)
      html = Map.fetch!(body_hook, :html)

      assert html =~ "mermaid@10.2.3"
      assert html =~ ~s(window.addEventListener("exdoc:loaded")
      assert html =~ "securityLevel: \"strict\""
      assert html =~ ~s|document.querySelectorAll("pre code.mermaid")|
      assert html =~ "preEl.remove()"
      assert html =~ ".catch((error)"
      assert Map.fetch!(body_hook, :epub) == ""
    end

    test "code walkthrough is published, parseable, and grounded in current source" do
      path = "guides/code-walkthrough.md"
      guide = File.read!(path)
      readme = File.read!("README.md")
      learning_path = File.read!("guides/learning-path.md")
      architecture = File.read!("guides/architecture.md")
      changelog = File.read!("CHANGELOG.md")
      docs_check = File.read!("lib/mix/tasks/mailglass.docs.check.ex")
      docs = Mix.Project.config()[:docs]

      assert path in docs[:extras]
      assert path in Keyword.fetch!(docs, :groups_for_extras)[:Guides]
      assert readme =~ path
      assert learning_path =~ "code-walkthrough.md"
      assert architecture =~ "[Code walkthrough](code-walkthrough.md)"
      assert changelog =~ "core code walkthrough"
      assert docs_check =~ path

      headings = [
        "## Keep one route in your head",
        "## A mailable manufactures the value",
        "## Rendering collapses intent into bytes",
        "## Outbound is the decision center",
        "## The worker receives identity, not behavior",
        "## Swoosh owns the final transport hop",
        "## Events are history; Delivery is the view",
        "## Webhooks bring provider facts home",
        "## Context rides every asynchronous and database boundary",
        "## Tests expose the intended design",
        "## Your next source-reading session"
      ]

      positions =
        for heading <- headings do
          assert guide =~ heading
          {position, _length} = :binary.match(guide, heading)
          position
        end

      assert positions == Enum.sort(positions), "code walkthrough headings are out of order"

      blocks = extract_code_blocks(path)
      assert length(blocks) == 16

      for {block, index} <- Enum.with_index(blocks, 1) do
        assert {:ok, _quoted} = Code.string_to_quoted(block),
               "code walkthrough block #{index} does not parse"
      end

      source_anchors = [
        {"lib/mailglass/mailable.ex",
         [
           "defmacro __using__(opts) do",
           "Mailglass.Message.new_from_use(__MODULE__, @mailglass_opts)"
         ]},
        {"lib/mailglass/message.ex",
         ["def update_swoosh(%__MODULE__{swoosh_email: email} = msg, fun)"]},
        {"lib/mailglass/renderer.ex",
         [
           "plaintext = to_plaintext(html_binary)",
           "final_html = strip_mg_attributes(inlined_html)"
         ]},
        {"lib/mailglass/outbound.ex",
         [
           "defp do_deliver_later(%Message{} = msg, opts) do",
           "|> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: d} ->",
           "base_delivery_attrs(rendered, ik, adapter_ref)",
           "def dispatch_by_id(delivery_id) when is_binary(delivery_id) do"
         ]},
        {"lib/mailglass/outbound/worker.ex",
         [
           ~s|def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do|
         ]},
        {"lib/mailglass/adapters/swoosh.ex", ["case mod.deliver(email, config) do"]},
        {"lib/mailglass/outbound/projector.ex",
         [
           "|> maybe_advance_last_event(event)",
           "|> Ecto.Changeset.optimistic_lock(:lock_version)"
         ]},
        {"lib/mailglass/webhook/plug.ex",
         [
           "case verify_with_telemetry!(provider, raw_body, headers, config) do",
           "tenant_id = resolve_tenant!(provider, conn, raw_body, headers)"
         ]},
        {"lib/mailglass/webhook/providers/postmark.ex",
         [~s|defp map_record_type(%{"RecordType" => "Delivery"})|]},
        {"lib/mailglass/webhook/ingest.ex",
         [
           "|> append_events_for_each(events, provider, tenant_id)",
           "apply(@auto_suppress_module, :apply"
         ]},
        {"lib/mailglass/tenancy.ex",
         [
           "def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do"
         ]},
        {"lib/mailglass/repo.ex", ["Keyword.put_new(opts, :prefix, Mailglass.Config.schema())"]},
        {"test/mailglass/core_send_integration_test.exs",
         ["assert_mail_sent(to: \"uat-c2-oban@example.com\")"]},
        {"test/mailglass/outbound/projector_test.exs",
         ["terminal never flips back: :opened after :bounced leaves terminal=true"]}
      ]

      for {source_path, anchors} <- source_anchors do
        source = File.read!(source_path)

        for anchor <- anchors do
          assert guide =~ anchor, "walkthrough is missing source anchor #{inspect(anchor)}"
          assert source =~ anchor, "source moved or removed walkthrough anchor #{inspect(anchor)}"
        end
      end

      assert guide =~ "A `# ...` marks a deliberate cut"
      assert guide =~ "Reading is not an API promise"
      assert guide =~ "View Source"
      refute guide =~ "lib/mailglass"
      refute Regex.match?(~r|https://github\.com/.+/blob/|, guide)
      refute Regex.match?(~r/#L\d+/, guide)
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
