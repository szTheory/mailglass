defmodule Mix.Tasks.Mailglass.Repo.HygieneTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Mix.Tasks.Mailglass.Repo.Hygiene

  test "reports a clean repo with release workflow readiness as pass" do
    repo = git_repo!()
    write_release_workflows!(repo)

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "initial")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

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

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "initial")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    json =
      result
      |> normalize_statuses()
      |> Jason.encode!()

    assert Jason.decode!(json)["status"] == "pass"
  end

  test "reports missing branch-protection verifier as cannot-check and aggregate non-success" do
    repo = ready_repo!()

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :blocked
    assert check(result, :branch_protection).status == :unknown
    assert check(result, :branch_protection).message =~ "verifier is missing"
  end

  test "reports missing gh as cannot-check with prerequisite recovery" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")

    result =
      with_env("PATH", "/usr/bin:/bin", fn ->
        with_env("GH_TOKEN", "test-token", fn -> Hygiene.audit(repo) end)
      end)

    assert result.status == :blocked
    assert check(result, :branch_protection).status == :unknown
    assert check(result, :branch_protection).message =~ "gh"
  end

  test "reports missing GH_TOKEN as cannot-check with prerequisite recovery" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")

    result =
      with_hygiene_environment(repo, fn ->
        with_env("GH_TOKEN", nil, fn -> Hygiene.audit(repo) end)
      end)

    assert result.status == :blocked
    assert check(result, :branch_protection).status == :unknown
    assert check(result, :branch_protection).message =~ "GH_TOKEN"
  end

  test "reports inaccessible verifier output as cannot-check rather than drift" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'HTTP 403: forbidden' >&2\nexit 1\n")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :blocked
    assert check(result, :branch_protection).status == :unknown
    assert check(result, :branch_protection).message =~ "could not be verified"
  end

  test "reports canonical DRIFT output as verified branch-protection drift" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'DRIFT: expected rules differ' >&2\nexit 1\n")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :blocked
    assert check(result, :branch_protection).status == :blocked
    assert check(result, :branch_protection).message =~ "differs from expected"
  end

  test "reports clean branch protection as pass with JSON-safe distinct statuses" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :pass
    assert check(result, :branch_protection).status == :pass
    assert Jason.decode!(Jason.encode!(normalize_statuses(result)))["status"] == "pass"

    {text, json} =
      with_hygiene_environment(repo, fn ->
        in_repo(repo, fn ->
          {
            capture_io(fn -> Hygiene.run(["--check"]) end),
            capture_io(fn -> Hygiene.run(["--check", "--format", "json"]) end)
          }
        end)
      end)

    assert text =~ "Repo hygiene: pass"
    assert text =~ "pass branch_protection:"
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

  defp ready_repo! do
    repo = git_repo!()
    write_release_workflows!(repo)
    commit_all!(repo, "initial")
    repo
  end

  defp write_branch_protection_verifier!(repo, body) do
    scripts = Path.join(repo, "scripts")
    File.mkdir_p!(scripts)
    verifier = Path.join(scripts, "verify-branch-protection.sh")
    File.write!(verifier, "#!/usr/bin/env bash\nset -eu\n#{body}")
    File.chmod!(verifier, 0o755)
  end

  defp with_hygiene_environment(_repo, fun) do
    bin =
      Path.join(
        System.tmp_dir!(),
        "mailglass-repo-hygiene-bin-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(bin)
    gh = Path.join(bin, "gh")

    File.write!(gh, """
    #!/usr/bin/env bash
    if [ "$1" = "run" ]; then
      printf '[{"headSha":"%s","conclusion":"success","status":"completed","url":"https://example.test/run"}]\\n' "$(git rev-parse HEAD)"
    else
      echo '[]'
    fi
    """)

    File.chmod!(gh, 0o755)

    try do
      with_env("PATH", "#{bin}:#{System.get_env("PATH")}", fn ->
        with_env("GH_TOKEN", "test-token", fun)
      end)
    after
      File.rm_rf!(bin)
    end
  end

  defp with_env(key, value, fun) do
    previous = System.get_env(key)
    if value, do: System.put_env(key, value), else: System.delete_env(key)

    try do
      fun.()
    after
      if previous, do: System.put_env(key, previous), else: System.delete_env(key)
    end
  end

  defp in_repo(repo, fun) do
    previous = File.cwd!()
    File.cd!(repo)

    try do
      fun.()
    after
      File.cd!(previous)
    end
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
