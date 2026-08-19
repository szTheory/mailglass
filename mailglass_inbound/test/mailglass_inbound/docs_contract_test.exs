defmodule MailglassInbound.DocsContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @install_path Path.expand("../../docs/inbound-install.md", __DIR__)
  @stability_path Path.expand("../../docs/api_stability.md", __DIR__)
  @operator_path Path.expand("../../docs/inbound-operator.md", __DIR__)
  @testing_path Path.expand("../../docs/inbound-testing.md", __DIR__)
  @compatibility_path Path.expand("../../../guides/compatibility-and-deprecations.md", __DIR__)
  @changelog_path Path.expand("../../CHANGELOG.md", __DIR__)
  @mixfile_path Path.expand("../../mix.exs", __DIR__)
  @postmark_ingress_path Path.expand("../../docs/postmark_ingress.md", __DIR__)
  @sendgrid_ingress_path Path.expand("../../docs/sendgrid_ingress.md", __DIR__)
  @operator_trust_path Path.expand("../../../mailglass_admin/docs/operator-trust.md", __DIR__)

  test "docs inventory names the stable public modules for the inbound slice" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    stable = contract_section!(stability, "stable")

    for module_name <- [
          "MailglassInbound.InboundMessage",
          "MailglassInbound.Ingress.Plug",
          "MailglassInbound.Ingress.CachingBodyReader",
          "MailglassInbound.Router",
          "MailglassInbound.Mailbox"
        ] do
      assert readme =~ module_name
      assert stable =~ module_name
    end

    assert stability =~ "stable"
    assert stability =~ "internal"
    assert stability =~ "deferred"
  end

  test "docs inventory names the four Testing helpers shipped for adopters (ITEST-05)" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    testing = contract_section!(stability, "testing")
    stable = contract_section!(stability, "stable")
    internal = contract_section!(stability, "internal")
    deferred = contract_section!(stability, "deferred")

    for module_name <- [
          "MailglassInbound.TestAssertions",
          "MailglassInbound.MailboxCase",
          "MailglassInbound.Test.Ingress",
          "MailglassInbound.Fixtures"
        ] do
      assert readme =~ module_name
      assert testing =~ module_name
      refute stable =~ module_name
      refute internal =~ module_name
      refute deferred =~ module_name
    end

    # The helpers ship as a distinct adopter-facing Testing surface, kept out of
    # the runtime stable contract and out of the internal/deferred buckets.
    assert stability =~ "testing"
  end

  test "package docs describe canonical storage plus raw evidence without widening provider internals" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    postmark = File.read!(@postmark_ingress_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, postmark, sendgrid] do
      assert doc =~ "canonical"
      assert doc =~ "raw evidence"
      assert doc =~ "replay"
      refute doc =~ "public provider behaviour"
      refute doc =~ "public provider extension API"
      refute doc =~ "Conductor UI"
    end

    assert stability =~ "canonical"
    assert stability =~ "raw evidence"
    assert stability =~ "replay"
    assert stability =~ "public provider extension API"
    refute stability =~ "public provider behaviour"
    refute stability =~ "Conductor UI"
  end

  test "postmark docs describe the body_reader requirement and explicit duplicate semantics" do
    postmark = File.read!(@postmark_ingress_path)

    assert postmark =~ "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
    assert postmark =~ "MailglassInbound.Ingress.Plug"
    assert postmark =~ "duplicate"
    assert postmark =~ "route compatibility"
    refute postmark =~ "Mailbox.process/1 runs during ingress"
  end

  test "docs make the optional Oban seam explicit without making Oban mandatory" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)

    assert readme =~ "Oban-backed execution"
    assert readme =~ "Task.Supervisor fallback"
    assert readme =~ "best-effort only"
    assert readme =~ "replay or operator action"
    assert stability =~ "MailglassInbound.OptionalDeps.Oban"
    assert stability =~ "MailglassInbound.Execution.Worker"
    assert stability =~ "Task.Supervisor"
    assert stability =~ "not part of the stable contract"

    for doc <- [readme, stability] do
      refute doc =~ "Oban is required"
      refute doc =~ "%Oban.Job{}"
    end
  end

  test "sendgrid docs describe raw mime, basic auth, and persistence-before-execution posture" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, stability, sendgrid] do
      assert doc =~ "SendGrid"
      assert doc =~ "basic auth"
      assert doc =~ "raw MIME"
      assert doc =~ "before mailbox execution"
    end

    assert sendgrid =~ "execution outcomes do not control provider retries"
    assert sendgrid =~ "raw_mime_fingerprint"
  end

  test "readme gives one canonical manual setup lane and rejects installer framing" do
    readme = File.read!(@readme_path)

    assert readme =~ "mix deps.get"
    assert readme =~ "mix ecto.migrate"
    assert readme =~ "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
    assert readme =~ ~s(forward "/inbound/:tenant_id/postmark")
    assert readme =~ ~s(forward "/inbound/:tenant_id/sendgrid")
    assert readme =~ "router: MyApp.MailglassInboundRouter"
    assert readme =~ "Oban-backed execution is the durable path"
    assert readme =~ "Task.Supervisor fallback is bounded best-effort only"
    assert readme =~ "mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"

    refute readme =~ "mix mailglass.install"
    refute readme =~ "installer"
  end

  test "stability docs keep workers, queue details, and replay orchestration internal" do
    stability = File.read!(@stability_path)
    stable = contract_section!(stability, "stable")
    internal = contract_section!(stability, "internal")
    deferred = contract_section!(stability, "deferred")

    assert internal =~ "MailglassInbound.Execution.Worker"
    assert internal =~ "queue names"
    assert stability =~ "internal"
    assert deferred =~ "public replay API"

    refute stable =~ "MailglassInbound.Execution.Worker"
    refute stable =~ "queue names"
    refute stable =~ "public replay API"
    refute stable =~ "public worker contract"
  end

  test "stability docs pin the Phase 63 semantics-first inbound inventory" do
    stability = File.read!(@stability_path)
    stable = contract_section!(stability, "stable")
    testing = contract_section!(stability, "testing")
    internal = contract_section!(stability, "internal")
    deferred = contract_section!(stability, "deferred")

    for token <- [
          "## Contract Posture",
          "### `stable`",
          "### `testing`",
          "### `internal`",
          "### `deferred`",
          "ExDoc visibility",
          "module reachability",
          "do not define the contract"
        ] do
      assert stability =~ token
    end

    for token <- [
          "MailglassInbound.Ingress.Plug",
          ":postmark",
          ":sendgrid",
          ":mailgun",
          ":ses",
          "verify before tenant",
          "canonical normalized row plus raw evidence row persisted before mailbox execution",
          "duplicate acknowledgement from durable receive truth",
          "replay remaining distinct from fresh provider receipt",
          "mix mailglass.inbound.doctor",
          "mix mailglass.inbound.replay",
          "mix mailglass.inbound.prune",
          "MailglassInbound.MIMEError",
          "MailglassInbound.SignatureError",
          "MailglassInbound.S3FetchError"
        ] do
      assert stable =~ token
    end

    for testing_token <- [
          "MailglassInbound.Fixtures",
          "MailglassInbound.Test.Ingress",
          "MailglassInbound.TestAssertions",
          "MailglassInbound.MailboxCase"
        ] do
      assert testing =~ testing_token
    end

    for telemetry_family <- [
          "[:mailglass_inbound, :ingress, :request",
          "[:mailglass_inbound, :route, :match",
          "[:mailglass_inbound, :persist, :record",
          "[:mailglass_inbound, :execution, :run",
          "[:mailglass_inbound, :ingress, :rate_limit",
          "[:mailglass_inbound, :ingress, :suppression_flag",
          "[:mailglass_inbound, :prune, :sweep"
        ] do
      assert stability =~ telemetry_family
    end

    for internal_token <- [
          "MailglassInbound.Ingress.Provider",
          "MailglassInbound.Ingress.Providers.Postmark",
          "MailglassInbound.Ingress.Providers.Sendgrid",
          "MailglassInbound.Ingress.Providers.Mailgun",
          "MailglassInbound.Ingress.Providers.SES",
          "MailglassInbound.Internal.Doctor",
          "MailglassInbound.Internal.Replay",
          "MailglassInbound.Internal.Prune",
          "MailglassInbound.Execution.Worker",
          "MailglassInbound.Prune.Worker",
          "MailglassInbound.Router.Route",
          "queue names",
          "worker args",
          "direct Oban job shapes",
          "admin or operator UI implementation details"
        ] do
      assert internal =~ internal_token
      refute stable =~ internal_token
    end

    for deferred_token <- [
          "public replay API",
          "public replay rerouting controls",
          "public provider extension API",
          "public worker or queue contracts",
          "matcher expansion",
          "lifecycle callbacks",
          "multi-route fan-out",
          "synthetic inbound development UI",
          "gen_smtp",
          "ecosystem integrations"
        ] do
      assert deferred =~ deferred_token
      refute stable =~ deferred_token
    end

    for forbidden_claim <- [
          "stable provider module APIs",
          "public provider behaviour",
          "stable worker or queue contracts",
          "replay as fresh receive",
          "ExDoc visibility defines stability",
          "ExDoc visibility defines the contract"
        ] do
      refute stability =~ forbidden_claim
    end

    refute Regex.match?(~r/provider\s+module(s)?\s+(are|is)\s+(public|stable)\s+api/i, stable)
    refute Regex.match?(~r/(worker|queue).*(public|stable).*(contract|api)/i, stable)
    refute Regex.match?(~r/replay\s+(as|is|becomes)\s+fresh/i, stable)
    refute Regex.match?(~r/exdoc visibility.*(defines|is).*(stability|contract)/i, stability)
  end

  test "operator trust docs keep replay separate from fresh receive and public ui claims" do
    operator_trust = File.read!(@operator_trust_path)

    assert operator_trust =~ "fresh provider receipt"
    assert operator_trust =~ "Task.Supervisor fallback"
    assert operator_trust =~ "best-effort"
    assert operator_trust =~ "no_prior_match"
    assert operator_trust =~ "execution_history_missing"

    refute operator_trust =~ "public replay API"
    refute operator_trust =~ "operator UI already ships"
    refute operator_trust =~ "silent reroute"
  end

  test "operator docs lock command semantics, tenant guards, confirmations, and replay framing" do
    operator = File.read!(@operator_path)

    for token <- [
          "mix mailglass.inbound.doctor",
          "mix mailglass.inbound.replay",
          "mix mailglass.inbound.prune",
          "--tenant <id>",
          "--dry-run",
          "--yes",
          "Exit codes",
          "cross-tenant replay guard",
          "full word `yes`",
          "Type 'yes' to continue",
          "append-only lineage table",
          "it is not a fresh provider receipt",
          "not silently reroute to another mailbox"
        ] do
      assert operator =~ token
    end

    refute Regex.match?(~r/replay\s+(as|is|becomes)\s+fresh/i, operator)
    assert Regex.match?(~r/not\s+a\s+public\s+replay\s+runtime\s+api/i, operator)
  end

  test "testing docs lock MailboxCase harness and process-local one-assertion-per-drive semantics" do
    testing = File.read!(@testing_path)

    for token <- [
          "MailglassInbound.MailboxCase",
          "use MailglassInbound.MailboxCase, async: false",
          "always `use MailglassInbound.MailboxCase, async: false`",
          "Test.Ingress.receive_inbound",
          "Process-local capture contract",
          "capture tuple to the current test process",
          "that process mailbox",
          "one-assertion-per-drive rule",
          "consumes",
          "drive two messages to make two assertions"
        ] do
      assert testing =~ token
    end
  end

  test "install docs name all four stable provider lanes" do
    install = File.read!(@install_path)

    assert install =~
             "The four stable provider lanes are `:postmark`, `:sendgrid`, `:mailgun`, and `:ses`."
  end

  test "admin operator trust docs lock replay boundaries, canonical routing, and internal-ui framing" do
    operator_trust = File.read!(@operator_trust_path)

    for token <- [
          "new work",
          "no change",
          "mix verify.stability_contract",
          "docs/api_stability.md",
          "mailglass_inbound/docs/api_stability.md",
          "implementation detail",
          "does not silently reroute",
          "it is not",
          "public replay runtime API"
        ] do
      assert operator_trust =~ token
    end

    refute Regex.match?(~r/stable\s+(dom|component|liveview)/i, operator_trust)
    refute Regex.match?(~r/public\s+(dom|component|liveview)/i, operator_trust)
  end

  test "docs reject replay-as-fresh and unshipped verification claims" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    for doc <- [readme, stability, sendgrid] do
      refute doc =~ "replay as fresh receive"
      refute doc =~ "re-ingest provider payloads"
      refute doc =~ "signed multipart verification shipped"
      refute doc =~ "replay reroutes silently"
    end
  end

  test "docs exclude deferred matcher, mailbox lifecycle, and fan-out claims" do
    readme = File.read!(@readme_path)
    stability = File.read!(@stability_path)
    postmark = File.read!(@postmark_ingress_path)
    sendgrid = File.read!(@sendgrid_ingress_path)

    forbidden_claims = [
      "body matcher",
      "attachment matcher",
      "raw MIME matcher",
      "multi-match fan-out",
      "before_process",
      "after_process",
      "around_process",
      "handle_failed"
    ]

    for doc <- [readme, stability, postmark, sendgrid], claim <- forbidden_claims do
      refute doc =~ claim
    end
  end

  test "repo-root verification keeps inbound docs and release proof in the canonical lane" do
    root_mix = File.read!(Path.expand("../../../mix.exs", __DIR__))
    docs_check = File.read!(Path.expand("../../../lib/mix/tasks/mailglass.docs.check.ex", __DIR__))
    maintaining = File.read!(Path.expand("../../../MAINTAINING.md", __DIR__))

    assert root_mix =~
             "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"

    assert docs_check =~ "\"mailglass_inbound/README.md\""
    assert docs_check =~ "\"mailglass_inbound/docs/api_stability.md\""
    assert docs_check =~ "\"mailglass_inbound/docs/sendgrid_ingress.md\""
    assert maintaining =~ "mailglass_inbound"
    assert maintaining =~ "mix verify.stability_contract"
  end

  # WR-01: keep the README install snippet's `mailglass_inbound` dep pin from
  # drifting away from the published package version. The README's `~> X.Y`
  # major.minor must match `Mix.Project.config()[:version]` so a copy-pasted
  # install line always resolves against the artifact this repo publishes.
  test "readme mailglass_inbound dep pin major.minor matches the package version" do
    readme = File.read!(@readme_path)

    [_, major_minor] =
      Regex.run(~r/\{:mailglass_inbound,\s*"~>\s*(\d+\.\d+)/, readme) ||
        flunk("README is missing a `{:mailglass_inbound, \"~> X.Y\"}` dep pin")

    version = Mix.Project.config()[:version]
    [major, minor | _] = String.split(version, ".")

    assert major_minor == "#{major}.#{minor}",
           "README pins mailglass_inbound to ~> #{major_minor} but the package " <>
             "version is #{version} (expected ~> #{major}.#{minor})"
  end

  test "stable error docs lock the closed type sets to code in exact order" do
    stability = File.read!(@stability_path)

    assert_closed_type_set_matches_docs!(stability, MailglassInbound.MIMEError)
    assert_closed_type_set_matches_docs!(stability, MailglassInbound.SignatureError)
    assert_closed_type_set_matches_docs!(stability, MailglassInbound.S3FetchError)
  end

  test "README and install guide pins match current inbound and mailglass release lines" do
    readme = File.read!(@readme_path)
    install = File.read!(@install_path)
    mixfile = File.read!(@mixfile_path)

    expected_inbound_pin =
      Mix.Project.config()[:version]
      |> String.split(".")
      |> Enum.take(2)
      |> Enum.join(".")

    # The README/install guide tracks "what adopters install alongside inbound" =
    # the CORE RELEASE major.minor. release-please.yml's CORE_MM sed keeps the
    # README core pin synced to the core release (e.g. ~> 1.11 on the release
    # branch). This is intentionally DECOUPLED from the inbound compatibility
    # floor in mix.exs (which stays ~> 1.10 and >= 1.10.2 per LD-2) — the README
    # always points to the latest tested core, not the oldest admitted core.
    #
    # Source: .release-please-manifest.json .["."] (core version), falling back
    # to core mix.exs @version. Test file is in mailglass_inbound/test/mailglass_inbound/,
    # so repo root is three levels up (../../../).
    manifest_path = Path.expand("../../../.release-please-manifest.json", __DIR__)

    core_version =
      case File.read(manifest_path) do
        {:ok, json} ->
          case Jason.decode(json) do
            {:ok, %{"." => version}} -> version
            _ -> nil
          end

        _ ->
          nil
      end

    core_version =
      if core_version do
        core_version
      else
        core_mixfile = File.read!(Path.expand("../../../mix.exs", __DIR__))

        [_, v] =
          Regex.run(~r/@version\s+"(\d+\.\d+\.\d+)"/, core_mixfile) ||
            flunk("Could not determine core version from manifest or mix.exs")

        v
      end

    expected_mailglass_pin =
      core_version
      |> String.split(".")
      |> Enum.take(2)
      |> Enum.join(".")

    # Positive assertion: the inbound compatibility floor (from mix.exs's loosened
    # ~> 1.10 and >= 1.10.2 dep) must admit the current core release version.
    # This ensures the decoupling is intentional — any future accidental floor
    # tightening that would exclude a released core will trip this assertion.
    [_, floor_constraint] =
      Regex.run(~r/\{:mailglass,\s*"([^"]+)"/, mixfile) ||
        flunk(
          "mailglass_inbound/mix.exs is missing the mailglass dep (checked for MIX_PUBLISH form)"
        )

    assert Version.match?(core_version, floor_constraint),
           "The inbound compatibility floor (#{inspect(floor_constraint)}) does not admit " <>
             "core #{core_version} — floor must be widened or the release version reconciled"

    for {doc_name, doc} <- [{"README", readme}, {"install guide", install}] do
      [_, inbound_pin] =
        Regex.run(~r/\{:mailglass_inbound,\s*"~>\s*(\d+\.\d+)"/, doc) ||
          flunk("#{doc_name} is missing a mailglass_inbound ~> X.Y pin")

      [_, mailglass_pin] =
        Regex.run(~r/\{:mailglass,\s*"~>\s*(\d+\.\d+)"/, doc) ||
          flunk("#{doc_name} is missing a mailglass ~> X.Y pin")

      assert inbound_pin == expected_inbound_pin
      assert mailglass_pin == expected_mailglass_pin
    end
  end

  test "adoption path and compatibility routing stay canonical across README, install, and guide" do
    readme = File.read!(@readme_path)
    install = File.read!(@install_path)
    compatibility = File.read!(@compatibility_path)

    for doc <- [readme, install] do
      assert doc =~ "{MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
      assert doc =~ "mix deps.get"
      assert doc =~ "mix ecto.migrate"
      assert doc =~ "Oban"
      assert doc =~ "Task.Supervisor fallback"
    end

    assert readme =~ "canonical adoption lane"
    assert readme =~ "subordinate to this README path"
    assert readme =~ "docs/inbound-operator.md"
    assert readme =~ "docs/inbound-testing.md"
    assert readme =~ "../guides/compatibility-and-deprecations.md"

    assert install =~ "canonical inbound adoption lane"
    assert install =~ "Follow this sequence only as an expansion of"
    assert install =~ "that README path"
    assert install =~ "single authority"
    assert install =~ "inbound-testing.md"
    assert install =~ "inbound-operator.md"
    assert install =~ "../../guides/compatibility-and-deprecations.md"

    assert compatibility =~ "mailglass_inbound/docs/api_stability.md"
    assert compatibility =~ "stable/internal/deferred source"
    assert compatibility =~ "Reachability is not a compatibility promise."
    assert compatibility =~ "## mailglass_inbound compatibility"
    assert compatibility =~ "## Inbound deprecation-DX inventory"

    for required_heading <- [
          "| Surface | Bridge or replacement | Warning or migration channel | `--warnings-as-errors` impact | Support-until horizon | Proof artifact |"
        ] do
      assert compatibility =~ required_heading
    end

    refute compatibility =~ "Through `mailglass_inbound` `0.x`"
    assert compatibility =~ "Through `mailglass_inbound` `2.x`"

    for forbidden <- [
          "../docs/compatibility-and-deprecations.md",
          "docs/compatibility-and-deprecations.md",
          "mix mailglass.install",
          "installer path",
          "second canonical inbound adoption lane"
        ] do
      refute readme =~ forbidden
      refute install =~ forbidden
    end
  end

  test "stable/adoption prose forbids over-claims while deferred sections may name them" do
    stability = File.read!(@stability_path)
    readme = File.read!(@readme_path)
    install = File.read!(@install_path)
    changelog = File.read!(@changelog_path)

    stable = contract_section!(stability, "stable")
    deferred = contract_section!(stability, "deferred")

    [readme_active, readme_deferred] =
      split_once!(readme, "## Deferred Beyond This Slice", "README")

    [install_active, _install_next] = split_once!(install, "## What's next", "install guide")
    changelog_unreleased = changelog_section!(changelog, "Unreleased")

    # The `## [Unreleased]` section is the empty stub ("No unreleased changes
    # yet.") between releases, so a `refute ... =~` against it is vacuously
    # true and gives zero protection in the normal state (WR-01). We make that
    # explicit rather than silent: when the section is the stub, the test
    # records (via an explicit assertion) that the over-claim guard is dormant;
    # the moment a release-prep edit populates the section, the full guard
    # below runs against real content. This keeps the suite green in the
    # default empty state without pretending the refutes protect anything.
    #
    # Note: we deliberately do NOT fold *released* changelog sections into this
    # guard — released sections legitimately enumerate deferred boundaries in
    # negated form (e.g. "no ... worker/queue public contracts ... are
    # promised"), which the broad `refute_over_claims!/1` heuristics would
    # flag as false positives. The `stable`/`readme_active`/`install_active`
    # prose are the always-populated surfaces that must stay clean.
    changelog_unreleased_populated? = not changelog_unreleased_empty_stub?(changelog_unreleased)

    always_guarded = [stable, readme_active, install_active]

    guarded_docs =
      if changelog_unreleased_populated? do
        always_guarded ++ [changelog_unreleased]
      else
        # Visible record that the Unreleased over-claim guard is dormant
        # because the section is the default stub (WR-01: not a silent skip).
        assert changelog_unreleased_empty_stub?(changelog_unreleased),
               "Expected the Unreleased changelog section to be the empty stub; " <>
                 "populate it to engage the over-claim guard."

        always_guarded
      end

    for blocked <- [
          "public replay API",
          "public replay rerouting controls",
          "public provider extension API",
          "public worker or queue contracts"
        ] do
      for doc <- guarded_docs do
        refute doc =~ blocked
      end
    end

    for doc <- guarded_docs do
      refute_over_claims!(doc)
    end

    assert deferred =~ "public replay API"
    assert deferred =~ "public provider extension API"
    assert readme_deferred =~ "publicly stable replay/command-surface API"
  end

  test "v2.6 snapshot owns additive migration seams and has no inbound deprecation fiction" do
    stability = File.read!(@stability_path)
    install = File.read!(@install_path)

    assert inbound_v26_contract_errors(stability, install) == []
  end

  test "v2.6 negative controls reject missing ownership and fabricated lifecycle claims" do
    stability = File.read!(@stability_path)
    install = File.read!(@install_path)

    for {kind, token} <- inbound_v26_required_tokens() do
      {changed_stability, changed_install} =
        if String.contains?(stability, token) do
          {String.replace(stability, token, ""), install}
        else
          {stability, String.replace(install, token, "")}
        end

      assert kind in inbound_v26_contract_errors(changed_stability, changed_install),
             "removing #{inspect(token)} did not trigger #{inspect(kind)}"
    end

    fabricated =
      stability <> "\nStatus: deprecated in v2; remove MailglassInbound.Router in v3.0.\n"

    assert :fabricated_deprecation in inbound_v26_contract_errors(fabricated, install)

    ui_promise = install <> "\nThe operator UI ships inbound replay controls.\n"
    assert :admin_operator_behavior_claim in inbound_v26_contract_errors(stability, ui_promise)
  end

  defp contract_section!(document, section_name) do
    escaped = Regex.escape(section_name)
    pattern = ~r/^### `#{escaped}`\n([\s\S]*?)(?=^### `|^## |\z)/m

    case Regex.run(pattern, document) do
      [_, section] -> section
      _ -> flunk("Missing #{section_name} contract section")
    end
  end

  defp inbound_v26_contract_errors(stability, install) do
    combined = stability <> "\n" <> install

    missing =
      for {kind, token} <- inbound_v26_required_tokens(),
          not String.contains?(combined, token),
          do: kind

    fabricated =
      if Regex.match?(~r/Status: deprecated in v2[^\n]*MailglassInbound\./i, combined),
        do: [:fabricated_deprecation],
        else: []

    ui_claim =
      if Regex.match?(~r/(admin|operator) (dashboard|ui).*(ships|provides|supports)/i, combined),
        do: [:admin_operator_behavior_claim],
        else: []

    Enum.uniq(missing ++ fabricated ++ ui_claim)
  end

  defp inbound_v26_required_tokens do
    [
      {:package_owner, "Package owner: `mailglass_inbound`"},
      {:additive_interface, "mix mailglass.inbound.gen.migration --repo MyApp.Repo"},
      {:additive_interface, "MailglassInbound.Migration.up/1"},
      {:additive_interface, "MailglassInbound.Migration.down/1"},
      {:additive_interface, "MailglassInbound.Migration.migrated_version/1"},
      {:package_boundary, "independent migration history"},
      {:deprecation_status, "Active v2 deprecations: none"},
      {:removal_target, "v3 removal targets: none"},
      {:internal_boundary, "`MailglassInbound.Ingress.Pipeline` remains internal"}
    ]
  end

  defp split_once!(document, delimiter, doc_name) do
    parts = String.split(document, delimiter)

    assert length(parts) == 2,
           "#{doc_name} missing expected section delimiter #{inspect(delimiter)}"

    parts
  end

  defp refute_over_claims!(document) do
    document
    |> String.split(~r/\n\s*\n/)
    |> Enum.each(fn paragraph ->
      paragraph = Regex.replace(~r/\s+/, paragraph, " ")

      claim_scope =
        String.replace(
          paragraph,
          "the 1.x stability promise applies to `mailglass` + `mailglass_admin` only",
          ""
        )

      refute Regex.match?(~r/replay\s+(as|is|becomes)\s+fresh/i, paragraph)
      refute Regex.match?(~r/(worker|queue).*(stable|public).*(contract|api)/i, paragraph)
      refute Regex.match?(~r/provider.*module.*(stable|public).*(api|extension)/i, paragraph)
      refute Regex.match?(~r/operator\s+ui.*(ships|shipped|stable|public)/i, paragraph)

      refute Regex.match?(
               ~r/mailglass_inbound.*1\.x.*(stability|stable|compatibility)/i,
               claim_scope
             )
    end)
  end

  defp assert_closed_type_set_matches_docs!(document, module) do
    section = contract_section!(document, inspect(module))
    expected = Enum.map(module.__types__(), &"`#{inspect(&1)}`")

    assert [_, closed_set] =
             Regex.run(~r/Closed `:type` set:\n\n([\s\S]*?)\n\nDocumented guarantees:/, section),
           "Missing closed :type set list for #{inspect(module)}"

    documented =
      Regex.scan(~r/^- (`:[a-z0-9_]+`)/m, closed_set)
      |> Enum.map(fn [_, token] -> token end)

    assert documented == expected,
           """
           Closed `:type` set drift for #{inspect(module)}
           docs: #{inspect(documented)}
           code: #{inspect(expected)}
           """
  end

  defp changelog_section!(document, name) do
    escaped = Regex.escape(name)
    pattern = ~r/^## \[#{escaped}\]\n\n([\s\S]*?)(?=^## \[|\z)/m

    case Regex.run(pattern, document) do
      [_, section] -> section
      _ -> flunk("Missing changelog section #{name}")
    end
  end

  test "inbound release record exists, carries REL-03 field headers, and reads pending honestly" do
    # WR-03: the release record lives in repo-root `.planning/`, which is
    # excluded from the published package and embeds the dated phase number in
    # its path. When phase 73 is archived/moved (as the Phase 38 forms in this
    # same milestone were), a raw `File.read!` would raise an opaque
    # `File.Error` and turn the required stability-contract lane red. Resolve
    # the path defensively and, if it is missing, flunk with a readable message
    # that tells the maintainer to update this guard alongside the move — the
    # same stale-path failure mode the `.planning/phases/38-` refute below
    # exists to catch.
    record_path =
      Path.expand(
        "../../../.planning/milestones/v1.6-phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-RECORD.md",
        __DIR__
      )

    unless File.exists?(record_path) do
      flunk("""
      Inbound release record not found at:
        #{record_path}

      This path embeds the literal phase dir `73-inbound-1-0-publish-evidence`.
      If phase 73 was archived/moved (e.g. into `.planning/milestones/`), update
      this test's `record_path` to the new location so the REL-03 field-presence
      guard keeps running. Do not delete the guard.
      """)
    end

    record = File.read!(record_path)

    # WR-02/IN-02: assert on the exact field labels as they appear in the record
    # (trailing colon included) so the guard fails if a REL-03 field is renamed
    # or dropped. Bare substrings like "smoke"/"Fallback"/"60-minute" matched
    # prose anywhere and would pass even if the labeled field were removed.
    for header <- [
          "Tag:",
          "Publish workflow run URL:",
          "Fallback path used:",
          "Hex index confirmation:",
          "HexDocs URLs:",
          "Post-publish smoke run URL:",
          "60-minute outcome:"
        ] do
      assert record =~ header,
             "Expected 73-01-RELEASE-RECORD.md to contain REL-03 field label: #{inspect(header)}"
    end

    # WR-01: the pending-marker asserts are only an invariant while the record
    # is in its prepare-and-stage posture. The record is explicitly designed to
    # be filled in later (post-publish maintainer trigger replaces
    # `pending`/`not run` with real values). Gating the markers on the staged
    # posture — the way the `## [Unreleased]` over-claim guard above gates on
    # the empty-stub state — keeps this guard honest for the staging moment
    # without pinning the document to its empty state forever. Once the
    # maintainer cuts the tag and completes the record, the staged marker is
    # gone and these asserts correctly stand down instead of blocking the very
    # release-evidence update they certify.
    record_staged? = record =~ "Tag: mailglass_inbound-v1.0.0 (staged, not cut)"

    if record_staged? do
      assert record =~ "not run",
             "Expected staged 73-01-RELEASE-RECORD.md to carry 'not run' pending markers (Honest Surface Area)"

      assert record =~ "pending",
             "Expected staged 73-01-RELEASE-RECORD.md to carry 'pending' markers for post-publish fields"
    end

    maintaining =
      File.read!(Path.expand("../../../MAINTAINING.md", __DIR__))

    refute maintaining =~ ".planning/phases/38-",
           "MAINTAINING.md must not contain the stale .planning/phases/38- path (D-10 regression guard)"
  end

  # True when the `## [Unreleased]` section is the default between-releases
  # stub. Detecting it explicitly lets the over-claim guard skip the section
  # (vacuous to refute) instead of silently passing against an empty stub.
  defp changelog_unreleased_empty_stub?(section) do
    String.trim(section) == "No unreleased changes yet."
  end
end
