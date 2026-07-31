defmodule Mix.Tasks.Mailglass.Repo.Hygiene do
  use Boundary, classify_to: Mailglass
  use Mix.Task

  @shortdoc "Audit Mailglass repo release hygiene"

  @moduledoc since: "1.3.0"
  @moduledoc """
  Audits repository release hygiene before release or milestone work.

  ## Usage

      mix mailglass.repo.hygiene --check
      mix mailglass.repo.hygiene --check --format json
      mix mailglass.repo.hygiene --apply

  `--check` is read-only. `--apply` only performs deterministic local cleanup:
  it creates a preservation branch when local state is dirty or ahead of its
  upstream. It does not delete work or merge PRs.
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [check: :boolean, apply: :boolean, format: :string],
        aliases: [c: :check]
      )

    validate_cli!(opts, rest, invalid)

    mode = if opts[:apply], do: :apply, else: :check
    format = opts[:format] || "text"
    repo = File.cwd!()

    result =
      if mode == :apply do
        apply_safe_actions(repo)
        audit(repo)
      else
        audit(repo)
      end

    emit(result, format)

    if result.status != :pass do
      exit({:shutdown, 1})
    end
  end

  def audit(repo) do
    checks = [
      git_state(repo),
      ci_state(repo),
      branch_protection(repo),
      pull_requests(repo),
      stale_branches(repo),
      release_workflows(repo)
    ]

    %{
      status: status(checks),
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      repo: repo,
      checks: checks
    }
  end

  defp validate_cli!(opts, rest, invalid) do
    if opts[:check] && opts[:apply] do
      Mix.raise("Delivery blocked: choose either --check or --apply, not both.")
    end

    if opts[:format] && opts[:format] not in ["text", "json"] do
      Mix.raise("Delivery blocked: --format must be text or json.")
    end

    if rest != [] do
      Mix.raise("Delivery blocked: unknown args #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      flags = invalid |> Enum.map(fn {key, _} -> "--#{key}" end) |> Enum.join(", ")
      Mix.raise("Delivery blocked: unknown args #{flags}")
    end
  end

  defp apply_safe_actions(repo) do
    state = git_state(repo)

    dirty? = get_in(state, [:details, :dirty]) == true
    ahead = get_in(state, [:details, :ahead]) || 0

    if dirty? || ahead > 0 do
      branch = "preserve/repo-hygiene-#{timestamp()}"
      {_, 0} = git(repo, ["branch", branch])
      Mix.shell().info("Created preservation branch #{branch}.")
    else
      Mix.shell().info("No local preservation branch needed.")
    end
  end

  defp git_state(repo) do
    dirty_output = git_output(repo, ["status", "--porcelain"])
    branch = git_output(repo, ["branch", "--show-current"]) |> String.trim()

    {ahead, behind, upstream_status} =
      case git(repo, ["rev-list", "--left-right", "--count", "@{upstream}...HEAD"]) do
        {output, 0} ->
          [behind, ahead] =
            output
            |> String.trim()
            |> String.split(~r/\s+/, trim: true)
            |> Enum.map(&String.to_integer/1)

          {ahead, behind, :ok}

        {output, _} ->
          {0, 0, %{status: "unknown", message: String.trim(output)}}
      end

    dirty? = String.trim(dirty_output) != ""

    details = %{
      branch: branch,
      dirty: dirty?,
      ahead: ahead,
      behind: behind,
      upstream: upstream_status
    }

    case upstream_status do
      :ok ->
        blocked? = dirty? || ahead > 0 || behind > 0

        check(
          :git_state,
          if(blocked?, do: :blocked, else: :pass),
          if(blocked?,
            do: "Local git state is not release-clean.",
            else: "Local git state is clean and aligned with upstream."
          ),
          details
        )

      _ ->
        unknown(
          :git_state,
          "Git upstream comparison could not be established; configure a resolvable upstream and retry.",
          details
        )
    end
  end

  defp ci_state(repo) do
    branch = git_output(repo, ["branch", "--show-current"]) |> String.trim()
    sha = git_output(repo, ["rev-parse", "HEAD"]) |> String.trim()

    cond do
      System.find_executable("gh") == nil ->
        unknown(:ci_state, "GitHub CLI is not installed; CI state was not checked.", %{sha: sha})

      true ->
        args = [
          "run",
          "list",
          "--workflow",
          "ci.yml",
          "--branch",
          branch,
          "--limit",
          "1",
          "--json",
          "headSha,conclusion,status,url"
        ]

        case cmd(repo, "gh", args) do
          {json, 0} ->
            run = json |> Jason.decode!() |> List.first()

            ci_details = %{branch: branch, sha: sha, latest: run}

            if run && run["headSha"] == sha && run["status"] == "completed" &&
                 run["conclusion"] == "success" do
              check(:ci_state, :pass, "Latest CI is green on this SHA.", ci_details)
            else
              check(
                :ci_state,
                :blocked,
                "No successful ci.yml run was found on this SHA.",
                ci_details
              )
            end

          {output, _} ->
            unknown(:ci_state, "GitHub CI state was not checked.", %{error: String.trim(output)})
        end
    end
  end

  defp branch_protection(repo) do
    script = Path.join(repo, "scripts/verify-branch-protection.sh")

    cond do
      !File.exists?(script) ->
        unknown(:branch_protection, "Branch-protection verifier is missing.", %{})

      System.find_executable("gh") == nil ->
        unknown(
          :branch_protection,
          "GitHub CLI is not installed; install gh before verifying branch protection.",
          %{}
        )

      System.get_env("GH_TOKEN") in [nil, ""] ->
        unknown(
          :branch_protection,
          "GH_TOKEN is missing; set a token with branch-protection read access before verifying.",
          %{}
        )

      true ->
        case cmd(repo, script, ["main"]) do
          {output, 0} ->
            check(:branch_protection, :pass, "Branch protection matches expected rules.", %{
              output: String.trim(output)
            })

          {output, _} ->
            trimmed_output = String.trim(output)

            if String.starts_with?(trimmed_output, "DRIFT:") do
              check(
                :branch_protection,
                :blocked,
                "Branch protection differs from expected rules.",
                %{
                  output: trimmed_output
                }
              )
            else
              unknown(
                :branch_protection,
                "Branch protection could not be verified; check GitHub access and retry.",
                %{output: trimmed_output}
              )
            end
        end
    end
  end

  defp pull_requests(repo) do
    if System.find_executable("gh") == nil do
      unknown(:pull_requests, "GitHub CLI is not installed; open PRs were not checked.", %{})
    else
      args = [
        "pr",
        "list",
        "--state",
        "open",
        "--limit",
        "100",
        "--json",
        "number,title,isDraft,headRefName,updatedAt,mergeStateStatus"
      ]

      case cmd(repo, "gh", args) do
        {json, 0} ->
          prs = Jason.decode!(json)

          status =
            if Enum.empty?(prs) do
              :pass
            else
              :blocked
            end

          check(:pull_requests, status, pr_message(prs), %{
            open_count: length(prs),
            prs: prs
          })

        {output, _} ->
          unknown(:pull_requests, "Open PR state was not checked.", %{error: String.trim(output)})
      end
    end
  end

  defp stale_branches(repo) do
    {output, status} =
      git(repo, [
        "for-each-ref",
        "refs/heads",
        "--format=%(refname:short)|%(upstream:short)|%(committerdate:unix)"
      ])

    if status != 0 do
      unknown(:stale_branches, "Local branches were not checked.", %{error: String.trim(output)})
    else
      now = DateTime.utc_now() |> DateTime.to_unix()
      max_age = 30 * 24 * 60 * 60

      branches =
        output
        |> String.split("\n", trim: true)
        |> Enum.map(&parse_branch/1)
        |> Enum.reject(&(&1.name == "main"))

      stale = Enum.filter(branches, &(now - &1.committed_at > max_age))

      check(
        :stale_branches,
        :pass,
        "Local branch inventory captured.",
        %{stale_count: length(stale), stale: stale}
      )
    end
  end

  defp release_workflows(repo) do
    release_please = read(repo, ".github/workflows/release-please.yml")
    publish_hex = read(repo, ".github/workflows/publish-hex.yml")
    smoke = read(repo, ".github/workflows/post-publish-smoke.yml")

    findings =
      []
      |> require_text(
        release_please,
        "RELEASE_PLEASE_PAT",
        "release-please uses RELEASE_PLEASE_PAT"
      )
      |> require_text(publish_hex, "workflow_dispatch", "publish-hex keeps fallback dispatch")
      |> require_text(
        publish_hex,
        "needs: [gate-ci-green, publish-core, publish-inbound]",
        "admin waits on inbound publish"
      )
      |> require_text(smoke, "mailglass_inbound", "post-publish smoke checks inbound package")

    status =
      if Enum.all?(findings, & &1.pass) do
        :pass
      else
        :blocked
      end

    check(:release_workflows, status, "Release workflow readiness checked.", %{findings: findings})
  end

  defp require_text(findings, source, text, label) do
    [%{label: label, pass: String.contains?(source, text)} | findings]
  end

  defp read(repo, path) do
    repo
    |> Path.join(path)
    |> File.read()
    |> case do
      {:ok, contents} -> contents
      {:error, _} -> ""
    end
  end

  defp pr_message([]), do: "No open PRs."
  defp pr_message(prs), do: "#{length(prs)} open PR(s) require disposition before release."

  defp parse_branch(line) do
    [name, upstream, committed_at] = String.split(line, "|", parts: 3)

    %{
      name: name,
      upstream: blank_to_nil(upstream),
      committed_at: String.to_integer(committed_at)
    }
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp status(checks) do
    if Enum.all?(checks, &(&1.status == :pass)), do: :pass, else: :blocked
  end

  defp check(name, status, message, details) do
    %{name: name, status: status, message: message, details: details}
  end

  defp unknown(name, message, details) do
    check(name, :unknown, message, details)
  end

  defp emit(result, "json") do
    result
    |> encode_statuses()
    |> Jason.encode!(pretty: true)
    |> Mix.shell().info()
  end

  defp emit(result, "text") do
    Mix.shell().info("Repo hygiene: #{result.status}")

    Enum.each(result.checks, fn check ->
      Mix.shell().info("#{check.status} #{check.name}: #{check.message}")
    end)
  end

  defp encode_statuses(%{checks: checks} = result) do
    %{result | status: to_string(result.status), checks: Enum.map(checks, &encode_statuses/1)}
  end

  defp encode_statuses(%{status: status} = check), do: %{check | status: to_string(status)}

  defp timestamp do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601(:basic)
    |> String.replace("Z", "")
  end

  defp git_output(repo, args) do
    repo
    |> git(args)
    |> elem(0)
  end

  defp git(repo, args), do: cmd(repo, "git", args)

  defp cmd(repo, executable, args) do
    System.cmd(executable, args, cd: repo, stderr_to_stdout: true)
  end
end
