defmodule Mix.Tasks.Mailglass.Docs.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Checks Tier 1 docs for stability-contract drift"

  @moduledoc since: "0.3.0"
  @moduledoc """
  Fail the build if Tier 1 docs leak internal IDs or drift away from the
  canonical stability-contract story. The checks are deterministic and scoped
  to release-blocking docs only.

  ## Usage

      mix mailglass.docs.check
      mix mailglass.docs.check --path "guides/**/*.md"

  Exits 0 if clean. Raises with `Delivery blocked: ...` brand-voice
  message if any internal ID is found.
  """

  use Mix.Task

  @banned_patterns [~r/\bD-\d{2,3}\b/, ~r/\bLINT-\d{2}\b/]
  @tier1_paths [
    "README.md",
    "mailglass_admin/README.md",
    "mailglass_inbound/README.md",
    "guides/preview.md",
    "guides/testing.md",
    "mailglass_admin/docs/operator-trust.md",
    "mailglass_inbound/docs/api_stability.md",
    "mailglass_inbound/docs/postmark_ingress.md",
    "mailglass_inbound/docs/sendgrid_ingress.md",
    "guides/compatibility-and-deprecations.md",
    "guides/upgrading-to-v1_0.md",
    "guides/getting-started.md",
    "guides/upgrading-from-v0_1.md",
    "guides/migration-from-swoosh.md",
    "guides/authoring-mailables.md",
    "guides/unsubscribe.md",
    "guides/dkim-setup.md",
    "guides/webhooks.md",
    "guides/webhook-troubleshooting.md",
    "MAINTAINING.md",
    "reference/host_app/README.md",
    "reference/host_app/SCOPE.md",
    "mailglass_inbound/docs/inbound-install.md",
    "mailglass_inbound/docs/inbound-testing.md",
    "mailglass_inbound/docs/inbound-operator.md",
    "mailglass_inbound/docs/inbound-mailgun.md",
    "mailglass_inbound/docs/inbound-ses.md",
    "mailglass_inbound/docs/inbound-routing-debug.md"
  ]
  @preview_boundary_paths ["guides/preview.md", "mailglass_admin/README.md"]
  @preview_confidence_regex ~r/preview-pipeline confidence\s+only/i
  @cross_client_parity_regex ~r/cross-client parity/i
  @allowed_cross_client_parity_regex ~r/(?:does(?:\s+\*\*not\*\*|\s+not)\s+claim|not)\s+cross-client parity/i
  @trust_entry_paths [
    "reference/host_app/README.md",
    "reference/host_app/SCOPE.md",
    "MAINTAINING.md",
    "guides/webhooks.md",
    "guides/webhook-troubleshooting.md",
    "mailglass_admin/docs/operator-trust.md"
  ]
  @trust_internal_detail_regex ~r/(?:Mix\.Tasks\.Mailglass\.Trust\.Run|trust-runner|checkpoint internals|provider modules)/i
  @trust_contract_claim_regex ~r/(?:stable public API(?: guarantee)?|public API guarantee|is API-contract truth|canonical contract truth)/i
  @allowed_non_contract_framing_regex ~r/(?:implementation detail|usage-proof evidence only|not API-contract truth|not canonical contract truth)/i
  @internal_id_exempt_paths MapSet.new(@trust_entry_paths)
  @tier1_surface_rules %{
    "README.md" => %{
      required: [
        "docs/api_stability.md",
        "guides/compatibility-and-deprecations.md",
        "guides/upgrading-to-v1_0.md",
        "mix mailglass.install",
        "mailglass_inbound` is outside the `v1.x` stability promise"
      ],
      forbidden: [
        "~> 0.1",
        "~> 0.2",
        "verify.phase_07",
        "v0.1 in development",
        "v0.3 public surface"
      ]
    },
    "mailglass_admin/README.md" => %{
      required: [
        "docs/operator-trust.md",
        "docs/api_stability.md",
        "docs/compatibility-and-deprecations.md",
        "MailglassAdmin.Auth",
        "Stable DOM/component/LiveView implementation APIs"
      ],
      forbidden: [
        "{:mailglass, \"~> 0.1\"}",
        "{:mailglass_admin, \"~> 0.1\"}",
        "guaranteed client parity"
      ]
    },
    "guides/preview.md" => %{
      required: [
        "preview-pipeline confidence only"
      ],
      forbidden: [
        "guaranteed client parity"
      ]
    },
    "mailglass_inbound/README.md" => %{
      required: [
        "canonical adoption lane",
        "subordinate to this README path",
        "MailglassInbound.Ingress.CachingBodyReader",
        "Oban-backed execution is the durable path",
        "Task.Supervisor fallback is bounded best-effort only",
        "mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors",
        "docs/inbound-operator.md",
        "docs/inbound-testing.md",
        "../guides/compatibility-and-deprecations.md"
      ],
      forbidden: [
        "mix mailglass.install",
        "public replay API",
        "operator UI",
        "docs/compatibility-and-deprecations.md"
      ]
    },
    "guides/testing.md" => %{
      required: [
        "## deliver/2 baseline",
        "## deliver_later/2 baseline",
        "## Optional Oban lanes",
        "## Cross-process and browser ownership",
        "## PubSub and webhook assertions",
        "## Footguns and strict-CI posture",
        "last_mail/0",
        "wait_for_mail/1",
        "Fake.allow/2",
        "shared/global",
        "async: false",
        "oban_jobs"
      ],
      forbidden: [
        "returns the last delivered message in the current process mailbox"
      ]
    },
    "mailglass_admin/docs/operator-trust.md" => %{
      required: [
        "## Stable seams",
        "## Session contract",
        "## Authorization timing",
        "## Replay semantics",
        "## Intentionally internal",
        "MailglassAdmin.Router",
        "MailglassAdmin.Auth",
        "`authorize/2` callback",
        "subject_id",
        "tenant_id",
        "auth_method",
        "recent_auth_at",
        ":operator_access",
        ":destructive_action",
        "new work",
        "no change",
        "Replay and reconcile are intentionally distinct",
        "it is not",
        "does not silently reroute",
        "public replay runtime API",
        "docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract",
        "implementation detail"
      ],
      forbidden: []
    },
    "reference/host_app/README.md" => %{
      required: [
        "usage-proof evidence only",
        "not API-contract truth",
        "docs/api_stability.md",
        "mailglass_admin/docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract",
        "implementation details"
      ],
      forbidden: [
        "stable public API guarantee"
      ]
    },
    "reference/host_app/SCOPE.md" => %{
      required: [
        "usage-proof evidence only",
        "not API-contract truth",
        "second product surface",
        "fixture seed",
        "docs/api_stability.md",
        "mailglass_admin/docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract"
      ],
      forbidden: [
        "is API-contract truth"
      ]
    },
    "MAINTAINING.md" => %{
      required: [
        "usage-proof artifacts",
        "not API-contract truth",
        "docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract"
      ],
      forbidden: [
        "stable public API guarantee"
      ]
    },
    "mailglass_inbound/docs/api_stability.md" => %{
      required: [
        "MailglassInbound.Execution.Worker",
        "Task.Supervisor fallback being bounded best-effort only when Oban is absent",
        "replay remaining distinct from fresh receive semantics"
      ],
      forbidden: [
        "public replay API is stable",
        "%Oban.Job{}"
      ]
    },
    "mailglass_inbound/docs/postmark_ingress.md" => %{
      required: [
        "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}",
        "duplicate",
        "Task.Supervisor fallback is bounded best-effort only"
      ],
      forbidden: [
        "Mailbox.process/1 runs during ingress",
        "public replay API"
      ]
    },
    "mailglass_inbound/docs/sendgrid_ingress.md" => %{
      required: [
        "raw MIME",
        "basic auth",
        "Task.Supervisor fallback is bounded best-effort only",
        "execution outcomes do not control provider retries"
      ],
      forbidden: [
        "signed multipart verification shipped",
        "re-ingest of provider payloads"
      ]
    },
    "guides/compatibility-and-deprecations.md" => %{
      required: [
        "stable lane",
        "compatibility lane",
        "warnings-as-errors",
        "mailglass_inbound",
        "mailglass_inbound/docs/api_stability.md",
        "Reachability is not a compatibility promise.",
        "## Inbound deprecation-DX inventory",
        "Support-until horizon",
        "Proof artifact"
      ],
      forbidden: ["Phase 37", "v0.1 in development"]
    },
    "guides/upgrading-to-v1_0.md" => %{
      required: [
        "canonical latest-`0.x` to `1.0` upgrade guide",
        "support-until version",
        "proof artifact",
        "Mailglass.Outbound.send/2",
        "mix mailglass.upgrade.v0_2"
      ],
      forbidden: [
        "authoritative migration path from the v0.1 mailable API to the v0.2 public surface"
      ]
    },
    "guides/getting-started.md" => %{
      required: ["mix mailglass.install", "|> to(user.email)", "|> subject(\"Welcome\")"],
      forbidden: ["verify.phase_07", "Mailglass.Message.update_swoosh(fn", "Swoosh.Email.to("]
    },
    "guides/upgrading-from-v0_1.md" => %{
      required: [
        "subordinate codemod reference",
        "upgrading-to-v1_0.md",
        "mix mailglass.upgrade.v0_2 --apply",
        "Mailglass.Message.update_swoosh/2",
        "`attachment/2` -> `attach/2`"
      ],
      forbidden: ["git checkout .", "msg()"]
    },
    "guides/migration-from-swoosh.md" => %{
      required: [
        "subordinate raw-Swoosh migration reference",
        "upgrading-to-v1_0.md",
        "{:mailglass, \"~> 0.3\"}",
        "Mailglass still accepts a plain `%Swoosh.Email{}`",
        "assert {:ok, _delivery} = Mailglass.deliver(email)"
      ],
      forbidden: ["Add `:mailglass` to your `mix.exs` and run `mix mailglass.install`."]
    },
    "guides/authoring-mailables.md" => %{
      required: [
        "|> put_tag(\"billing\")",
        "Use `update_swoosh/2` only",
        "Swoosh.Email.put_provider_option"
      ],
      forbidden: [
        "Mailglass.Message.update_swoosh(fn email ->\n      email\n      |> Swoosh.Email.to("
      ]
    },
    "guides/unsubscribe.md" => %{
      required: [
        "mix mailglass.gen.unsubscribe",
        "POST /mailglass/unsubscribe/:token",
        "previous_secrets"
      ],
      forbidden: []
    },
    "guides/dkim-setup.md" => %{
      required: ["List-Unsubscribe-Post", "SendGrid", "list-unsubscribe-post"],
      forbidden: []
    },
    "guides/webhooks.md" => %{
      required: [
        "Trust boundary: this page is operational usage guidance, not canonical",
        "docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract",
        "implementation detail"
      ],
      forbidden: [
        "stable public API guarantee"
      ]
    },
    "guides/webhook-troubleshooting.md" => %{
      required: [
        "This page is only the webhook-specific entry shim",
        "docs/api_stability.md",
        "mailglass_inbound/docs/api_stability.md",
        "mix verify.stability_contract",
        "implementation detail"
      ],
      forbidden: [
        "stable public API guarantee"
      ]
    },
    "mailglass_inbound/docs/inbound-install.md" => %{
      required: [
        "canonical inbound adoption lane",
        "that README path",
        "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}",
        "use MailglassInbound.Router",
        "@behaviour MailglassInbound.Mailbox",
        "mix ecto.migrate",
        "async: false",
        "The stable provider lanes in this slice are `:postmark` and `:sendgrid`.",
        "not part of the current stable provider contract",
        "../../guides/compatibility-and-deprecations.md"
      ],
      forbidden: [
        "mix mailglass.install",
        "docs/compatibility-and-deprecations.md",
        "The four supported providers are `:postmark`, `:sendgrid`, `:mailgun`, and"
      ]
    },
    "mailglass_inbound/docs/inbound-testing.md" => %{
      required: [
        "use MailglassInbound.MailboxCase, async: false",
        "assert_inbound_received",
        "Test.Ingress.receive_inbound",
        "async: false",
        "Process-local capture contract",
        "one-assertion-per-drive rule",
        "consumes",
        "drive two messages to make two assertions",
        "StreamData"
      ],
      forbidden: []
    },
    "mailglass_inbound/docs/inbound-operator.md" => %{
      required: [
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
        "not a fresh provider receipt",
        "not silently reroute to another mailbox",
        "not a public replay runtime",
        "retention:"
      ],
      forbidden: []
    },
    "mailglass_inbound/docs/inbound-mailgun.md" => %{
      required: [
        "signing_key",
        "HMAC-SHA256",
        "MailglassInbound.Ingress.CachingBodyReader"
      ],
      forbidden: []
    },
    "mailglass_inbound/docs/inbound-ses.md" => %{
      required: [
        "ex_aws_s3",
        "S3Fetcher.ExAwsS3",
        "sweet_xml",
        "SubscribeURL",
        "SubscriptionConfirmation"
      ],
      forbidden: []
    },
    "mailglass_inbound/docs/inbound-routing-debug.md" => %{
      required: [
        "routing-trace",
        "__mailglass_inbound_routes__",
        "mix mailglass.inbound.doctor",
        "envelope"
      ],
      forbidden: []
    }
  }

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [path: :string])
    validate_cli!(rest, invalid)

    paths = docs_paths(opts)

    issues =
      leak_issues(paths)
      |> Kernel.++(tier1_surface_issues(paths))
      |> Kernel.++(preview_boundary_issues(paths))
      |> Kernel.++(trust_boundary_issues(paths))

    if issues == [] do
      Mix.shell().info("[mailglass.docs.check] OK — Tier 1 docs match the stability contract.")
      :ok
    else
      Enum.each(issues, &emit_issue/1)
      Mix.raise("Delivery blocked: #{length(issues)} Tier 1 docs issue(s) found.")
    end
  end

  defp validate_cli!([], []), do: :ok

  defp validate_cli!(rest, invalid) do
    cond do
      rest != [] ->
        Mix.raise("Delivery blocked: unexpected argument(s) #{inspect(rest)}.")

      invalid != [] ->
        Mix.raise("Delivery blocked: invalid flag(s) #{inspect(invalid)}.")
    end
  end

  defp docs_paths(opts) do
    case opts[:path] do
      nil -> @tier1_paths
      path -> Path.wildcard(path)
    end
  end

  defp leak_issues(paths) do
    Enum.flat_map(paths, fn path ->
      if MapSet.member?(@internal_id_exempt_paths, path) do
        []
      else
        content = File.read!(path)

        Enum.flat_map(@banned_patterns, fn re ->
          re
          |> Regex.scan(content)
          |> Enum.map(fn [token | _] -> {:internal_id, path, token} end)
        end)
      end
    end)
  end

  defp tier1_surface_issues(paths) do
    selected_paths = MapSet.new(paths)

    @tier1_surface_rules
    |> Enum.filter(fn {path, _rules} -> MapSet.member?(selected_paths, path) end)
    |> Enum.flat_map(fn {path, rules} ->
      content = File.read!(path)

      required_issues =
        Enum.flat_map(rules.required, fn token ->
          if String.contains?(content, token), do: [], else: [{:missing, path, token}]
        end)

      forbidden_issues =
        Enum.flat_map(rules.forbidden, fn token ->
          if String.contains?(content, token), do: [{:stale, path, token}], else: []
        end)

      required_issues ++ forbidden_issues
    end)
  end

  defp preview_boundary_issues(paths) do
    selected_paths = MapSet.new(paths)

    @preview_boundary_paths
    |> Enum.filter(&MapSet.member?(selected_paths, &1))
    |> Enum.flat_map(fn path ->
      content = File.read!(path)

      confidence_issues =
        if Regex.match?(@preview_confidence_regex, content) do
          []
        else
          [{:missing_boundary, path, "preview-pipeline confidence only"}]
        end

      parity_issues =
        content
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.flat_map(fn {line, line_number} ->
          if Regex.match?(@cross_client_parity_regex, line) and
               not Regex.match?(@allowed_cross_client_parity_regex, line) do
            [{:parity_overreach, path, line_number, String.trim(line)}]
          else
            []
          end
        end)

      confidence_issues ++ parity_issues
    end)
  end

  defp trust_boundary_issues(paths) do
    selected_paths = MapSet.new(paths)

    @trust_entry_paths
    |> Enum.filter(&MapSet.member?(selected_paths, &1))
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        if Regex.match?(@trust_internal_detail_regex, line) and
             Regex.match?(@trust_contract_claim_regex, line) and
             not nearby_non_contract_framing?(path, line_number) do
          [{:trust_overreach, path, line_number, String.trim(line)}]
        else
          []
        end
      end)
    end)
  end

  defp nearby_non_contract_framing?(path, line_number) do
    lines = path |> File.read!() |> String.split("\n")
    first_line = max(line_number - 1, 1)
    last_line = min(line_number + 1, length(lines))

    lines
    |> Enum.slice((first_line - 1)..(last_line - 1))
    |> Enum.any?(&Regex.match?(@allowed_non_contract_framing_regex, &1))
  end

  defp emit_issue({:internal_id, path, token}) do
    Mix.shell().error("[mailglass.docs.check] internal ID #{inspect(token)} found in #{path}")
  end

  defp emit_issue({:missing, path, token}) do
    Mix.shell().error(
      "[mailglass.docs.check] required Tier 1 token missing in #{path}: #{inspect(token)}"
    )
  end

  defp emit_issue({:stale, path, token}) do
    Mix.shell().error(
      "[mailglass.docs.check] stale Tier 1 token found in #{path}: #{inspect(token)}"
    )
  end

  defp emit_issue({:parity_overreach, path, line_number, line}) do
    Mix.shell().error(
      "[mailglass.docs.check] parity-overreach wording found in #{path}:#{line_number}: #{inspect(line)}"
    )
  end

  defp emit_issue({:missing_boundary, path, token}) do
    Mix.shell().error(
      "[mailglass.docs.check] preview-boundary wording missing in #{path}: #{inspect(token)}"
    )
  end

  defp emit_issue({:trust_overreach, path, line_number, line}) do
    Mix.shell().error(
      "[mailglass.docs.check] trust-boundary overreach in #{path}:#{line_number}: #{inspect(line)}"
    )
  end
end
