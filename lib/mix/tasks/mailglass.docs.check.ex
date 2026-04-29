defmodule Mix.Tasks.Mailglass.Docs.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Checks Tier 1 docs for leaked internal IDs and stale v0.3 surface drift"

  @moduledoc """
  Fail the build if Tier 1 docs leak internal IDs or drift back to known
  stale pre-v0.2 surface markers. The checks are deterministic and scoped
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
      required: ["{:mailglass, \"~> 0.3\"}", "mix mailglass.install", "RFC 8058 List-Unsubscribe"],
      forbidden: [
        "~> 0.1",
        "~> 0.2",
        "verify.phase_07",
        "v0.1 in development",
        "and — at v0.5 — RFC 8058"
      ]
    },
    "guides/getting-started.md" => %{
      required: ["mix mailglass.install", "|> to(user.email)", "|> subject(\"Welcome\")"],
      forbidden: ["verify.phase_07", "Mailglass.Message.update_swoosh(fn", "Swoosh.Email.to("]
    },
    "guides/upgrading-from-v0_1.md" => %{
      required: [
        "mix mailglass.upgrade.v0_2 --apply",
        "Mailglass.Message.update_swoosh/2",
        "`attachment/2` -> `attach/2`"
      ],
      forbidden: ["git checkout .", "msg()"]
    },
    "guides/migration-from-swoosh.md" => %{
      required: [
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
      Mix.shell().info("[mailglass.docs.check] OK — Tier 1 docs match the v0.3 release surface.")
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
