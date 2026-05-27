defmodule Mix.Tasks.Mailglass.Repo.HygieneTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Mailglass.Repo.Hygiene

  test "reports a clean repo with release workflow readiness as pass" do
    repo = git_repo!()
    write_release_workflows!(repo)
    commit_all!(repo, "initial")

    result = Hygiene.audit(repo)

    assert result.status == :pass
    assert check(result, :git_state).status == :pass
    assert check(result, :release_workflows).status == :pass
  end

  test "blocks on dirty local state" do
    repo = git_repo!()
    write_release_workflows!(repo)
    commit_all!(repo, "initial")
    File.write!(Path.join(repo, "dirty.txt"), "dirty\n")

    result = Hygiene.audit(repo)

    assert result.status == :blocked

    git_state = check(result, :git_state)
    assert git_state.status == :blocked
    assert git_state.details.dirty == true
  end

  test "result is JSON encodable with string statuses" do
    repo = git_repo!()
    write_release_workflows!(repo)
    commit_all!(repo, "initial")

    result = Hygiene.audit(repo)

    json =
      result
      |> normalize_statuses()
      |> Jason.encode!()

    assert Jason.decode!(json)["status"] == "pass"
  end

  defp check(result, name), do: Enum.find(result.checks, &(&1.name == name))

  defp git_repo! do
    repo =
      Path.join(System.tmp_dir!(), "mailglass-repo-hygiene-#{System.unique_integer([:positive])}")

    File.rm_rf!(repo)
    File.mkdir_p!(repo)

    git!(repo, ["init", "-b", "main"])
    git!(repo, ["config", "user.email", "test@example.test"])
    git!(repo, ["config", "user.name", "Mailglass Test"])

    on_exit(fn -> File.rm_rf!(repo) end)

    repo
  end

  defp write_release_workflows!(repo) do
    workflows = Path.join(repo, ".github/workflows")
    File.mkdir_p!(workflows)

    File.write!(Path.join(workflows, "release-please.yml"), """
    token: ${{ secrets.RELEASE_PLEASE_PAT }}
    """)

    File.write!(Path.join(workflows, "publish-hex.yml"), """
    on: workflow_dispatch
    jobs:
      publish-admin:
        needs: [gate-ci-green, publish-core, publish-inbound]
    """)

    File.write!(Path.join(workflows, "post-publish-smoke.yml"), """
    mailglass_inbound
    """)
  end

  defp commit_all!(repo, message) do
    git!(repo, ["add", "-A"])
    git!(repo, ["commit", "-m", message])
  end

  defp git!(repo, args) do
    {_output, 0} = System.cmd("git", args, cd: repo, stderr_to_stdout: true)
  end

  defp normalize_statuses(%{checks: checks} = result) do
    %{result | status: to_string(result.status), checks: Enum.map(checks, &normalize_statuses/1)}
  end

  defp normalize_statuses(%{status: status} = check), do: %{check | status: to_string(status)}
end
