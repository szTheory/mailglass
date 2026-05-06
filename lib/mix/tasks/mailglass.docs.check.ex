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
    "guides/testing.md",
    "mailglass_admin/docs/operator-trust.md",
    "guides/compatibility-and-deprecations.md",
    "guides/upgrading-to-v1_0.md",
    "guides/getting-started.md",
    "guides/upgrading-from-v0_1.md",
    "guides/migration-from-swoosh.md",
    "guides/authoring-mailables.md",
    "guides/unsubscribe.md",
    "guides/dkim-setup.md",
    "guides/webhooks.md"
  ]
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
        "{:mailglass_admin, \"~> 0.1\"}"
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
        "Replay and reconcile are intentionally distinct"
      ],
      forbidden: []
    },
    "guides/compatibility-and-deprecations.md" => %{
      required: [
        "stable lane",
        "compatibility lane",
        "warnings-as-errors",
        "mailglass_inbound"
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
      forbidden: ["authoritative migration path from the v0.1 mailable API to the v0.2 public surface"]
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
        "Mailglass v0.3 projects suppressions automatically",
        "[:mailglass, :suppression, :auto_added, :stop]",
        "mix mailglass.suppressions.resync --tenant-id <tenant>"
      ],
      forbidden: [
        "Until v0.5 ships first-class auto-suppression",
        "MyApp.Suppressions.maybe_add(provider, type)"
      ]
    }
  }

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [path: :string])
    validate_cli!(rest, invalid)

    paths = docs_paths(opts)

    issues =
      leak_issues(paths)
      |> Kernel.++(tier1_surface_issues())

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
      content = File.read!(path)

      Enum.flat_map(@banned_patterns, fn re ->
        re
        |> Regex.scan(content)
        |> Enum.map(fn [token | _] -> {:internal_id, path, token} end)
      end)
    end)
  end

  defp tier1_surface_issues do
    Enum.flat_map(@tier1_surface_rules, fn {path, rules} ->
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
end
