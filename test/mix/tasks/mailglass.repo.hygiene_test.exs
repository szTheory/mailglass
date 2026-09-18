defmodule Mix.Tasks.Mailglass.Repo.HygieneTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Mix.Tasks.Mailglass.Repo.Hygiene

  # D-34 (166-06 CTRL-05): cannot-check gets its own distinct, still-nonzero
  # exit code, separate from blocked. Exit 0 for a non-pass aggregate is
  # prohibited by construction (see the exit-code-split test below).
  @cannot_check_exit 2
  @blocked_exit 1

  test "reports a clean repo with release workflow readiness as pass" do
    repo = git_repo!()
    write_release_workflows!(repo)

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "initial")
    configure_upstream!(repo)

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :pass
    assert check(result, :git_state).status == :pass
    assert check(result, :release_workflows).status == :pass
  end

  test "blocks on dirty local state" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")
    commit_all!(repo, "add verifier")
    push_upstream!(repo)
    File.write!(Path.join(repo, "dirty.txt"), "dirty\n")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

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
    configure_upstream!(repo)

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    json =
      result
      |> normalize_statuses()
      |> Jason.encode!()

    assert Jason.decode!(json)["status"] == "pass"
  end

  test "reports missing branch-protection verifier as cannot-check and aggregate cannot-check" do
    repo = ready_repo!()

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :cannot_check
    assert check(result, :branch_protection).status == :cannot_check
    assert check(result, :branch_protection).message =~ "verifier is missing"
  end

  test "reports a missing git upstream as cannot-check and aggregate cannot-check" do
    repo = git_repo!()
    write_release_workflows!(repo)

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "initial")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :cannot_check
    assert check(result, :git_state).status == :cannot_check
    assert check(result, :git_state).message =~ "upstream comparison"
  end

  test "reports missing gh as cannot-check with prerequisite recovery" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")

    result =
      without_gh(fn ->
        with_env("GH_TOKEN", "test-token", fn -> Hygiene.audit(repo) end)
      end)

    assert result.status == :cannot_check
    assert check(result, :branch_protection).status == :cannot_check
    assert check(result, :branch_protection).message =~ "gh"
  end

  test "reports missing GH_TOKEN as cannot-check with prerequisite recovery" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")

    result =
      with_hygiene_environment(repo, fn ->
        with_env("GH_TOKEN", nil, fn -> Hygiene.audit(repo) end)
      end)

    assert result.status == :cannot_check
    assert check(result, :branch_protection).status == :cannot_check
    assert check(result, :branch_protection).message =~ "GH_TOKEN"
  end

  test "reports inaccessible verifier output as cannot-check rather than drift" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'HTTP 403: forbidden' >&2\nexit 1\n")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert result.status == :cannot_check
    assert check(result, :branch_protection).status == :cannot_check
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

  test "cannot-check takes precedence over a confirmed policy block" do
    repo = ready_repo!()
    File.write!(Path.join(repo, "dirty.txt"), "dirty\n")

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end)

    assert check(result, :git_state).status == :blocked
    assert check(result, :branch_protection).status == :cannot_check
    assert result.status == :cannot_check
  end

  test "renders cannot-check at text and JSON boundaries and exits nonzero" do
    repo = ready_repo!()

    {text, text_exit} = run_hygiene(repo, ["--check"])
    {json, json_exit} = run_hygiene(repo, ["--check", "--format", "json"])

    assert text_exit == {:shutdown, @cannot_check_exit}
    assert json_exit == {:shutdown, @cannot_check_exit}
    assert text =~ "Repo hygiene: cannot-check"
    assert text =~ "cannot-check branch_protection:"
    assert Jason.decode!(json)["status"] == "cannot-check"
    assert Jason.decode!(json)["reason"] =~ "verifier is missing"

    assert Enum.find(Jason.decode!(json)["checks"], &(&1["name"] == "branch_protection"))["status"] ==
             "cannot-check"
  end

  test "workflow summary reads aggregate result and checks from the audit JSON artifact" do
    workflow = File.read!(Path.expand("../../../.github/workflows/repo-hygiene.yml", __DIR__))

    assert workflow =~ "$RUNNER_TEMP/repo-hygiene.json"
    assert workflow =~ "scheduled_control_evidence.sh bind"
    assert workflow =~ "--control repo-hygiene"
    assert workflow =~ "tee -a \"$GITHUB_STEP_SUMMARY\""
    assert workflow =~ "if-no-files-found: error"
    assert workflow =~ "if: always()"
    refute workflow =~ "steps.hygiene.outcome"
  end

  test "reports clean branch protection as pass with JSON-safe distinct statuses" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")
    push_upstream!(repo)

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

  test "uses the detached checkout SHA to find a matching completed CI run" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")
    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    sha = git_output!(repo, ["rev-parse", "HEAD"])
    git!(repo, ["checkout", "--detach", sha])
    assert git_output!(repo, ["branch", "--show-current"]) == ""

    argv_log = Path.join(repo, "gh-argv.log")

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end,
        expected_sha: sha,
        argv_log: argv_log
      )

    assert check(result, :ci_state).status == :pass

    assert File.read!(argv_log) ==
             "run\nlist\n--workflow\nci.yml\n--commit\n#{sha}\n--limit\n1\n--json\nheadSha,conclusion,status,url\n"
  end

  test "blocks detached CI evidence when the returned run is absent, incomplete, failed, or on another SHA" do
    repo = ready_repo!()
    sha = git_output!(repo, ["rev-parse", "HEAD"])
    git!(repo, ["checkout", "--detach", sha])
    assert git_output!(repo, ["branch", "--show-current"]) == ""

    for response <- [
          "[]",
          "[{\"headSha\":\"#{sha}\",\"conclusion\":null,\"status\":\"in_progress\",\"url\":\"https://example.test/run\"}]",
          "[{\"headSha\":\"#{sha}\",\"conclusion\":\"failure\",\"status\":\"completed\",\"url\":\"https://example.test/run\"}]",
          "[{\"headSha\":\"#{String.duplicate("f", 40)}\",\"conclusion\":\"success\",\"status\":\"completed\",\"url\":\"https://example.test/run\"}]"
        ] do
      result =
        with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end,
          expected_sha: sha,
          response: response
        )

      assert check(result, :ci_state).status == :blocked
    end
  end

  test "reports an unavailable detached CI query as cannot-check" do
    repo = ready_repo!()
    sha = git_output!(repo, ["rev-parse", "HEAD"])
    git!(repo, ["checkout", "--detach", sha])
    assert git_output!(repo, ["branch", "--show-current"]) == ""

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end,
        expected_sha: sha,
        query_exit: 1
      )

    assert check(result, :ci_state).status == :cannot_check
    assert check(result, :ci_state).details.error =~ "unavailable"
  end

  test "bounds malformed and non-list successful CI responses as cannot-check JSON evidence" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")
    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    sha = git_output!(repo, ["rev-parse", "HEAD"])

    for {response, diagnostic} <- [
          {"{not-json", "malformed GitHub CI response"},
          {"{\"headSha\":\"#{sha}\"}", "unexpected GitHub CI response"}
        ] do
      result =
        with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end,
          expected_sha: sha,
          response: response
        )

      ci_state = check(result, :ci_state)
      assert result.status == :cannot_check
      assert ci_state.status == :cannot_check
      assert ci_state.details.sha == sha
      assert ci_state.message =~ diagnostic
      assert ci_state.message =~ "retry"

      {json, exit} = run_hygiene(repo, ["--check", "--format", "json"], response: response)
      decoded = Jason.decode!(json)

      assert exit == {:shutdown, @cannot_check_exit}
      assert decoded["status"] == "cannot-check"

      assert Enum.find(decoded["checks"], &(&1["name"] == "ci_state"))["status"] ==
               "cannot-check"
    end
  end

  test "bounds malformed and non-list successful PR responses as cannot-check JSON evidence" do
    repo = ready_repo!()
    write_branch_protection_verifier!(repo, "echo 'OK'\n")
    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    for {pr_response, diagnostic} <- [
          {"{not-json", "malformed GitHub PR response"},
          {"{\"number\":222}", "unexpected GitHub PR response"}
        ] do
      result =
        with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

      pull_requests = check(result, :pull_requests)
      assert result.status == :cannot_check
      assert pull_requests.status == :cannot_check
      assert pull_requests.message =~ diagnostic
      assert pull_requests.message =~ "retry"

      {json, exit} =
        run_hygiene(repo, ["--check", "--format", "json"], pr_response: pr_response)

      decoded = Jason.decode!(json)

      assert exit == {:shutdown, @cannot_check_exit}
      assert decoded["status"] == "cannot-check"
      assert decoded["reason"] =~ diagnostic

      assert Enum.find(decoded["checks"], &(&1["name"] == "pull_requests"))["status"] ==
               "cannot-check"
    end
  end

  # D-35 (166-06 CTRL-05): the PR predicate widens from any-open-PR to
  # "open more than 14 days OR failing a required check". Cases below pin the
  # new predicate's behavior; they must move in the same commit as the task
  # (D-35's own lockstep requirement).

  test "an empty open-PR list still concludes pass" do
    repo = ready_repo!()

    result = with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: "[]")

    assert check(result, :pull_requests).status == :pass
    assert check(result, :pull_requests).details.open_count == 0
    assert check(result, :pull_requests).details.prs == []
  end

  test "a freshly opened healthy PR does not turn it red" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    pr_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(3),
          "statusCheckRollup" => success_rollup()
        }
      ])

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

    pull_requests = check(result, :pull_requests)
    assert pull_requests.status == :pass
    assert pull_requests.details.open_count == 1
    assert result.status == :pass
  end

  test "a PR open for exactly 14 days is not blocked" do
    repo = ready_repo!()

    pr_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(14),
          "statusCheckRollup" => success_rollup()
        }
      ])

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

    assert check(result, :pull_requests).status == :pass
  end

  test "a PR open for 15 days is blocked with the age reason named" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    pr_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(15),
          "statusCheckRollup" => success_rollup()
        }
      ])

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

    pull_requests = check(result, :pull_requests)
    assert pull_requests.status == :blocked
    assert pull_requests.details.reason =~ "14-day"
    assert result.status == :blocked
  end

  test "a PR with a failing required check is blocked with the failing-check reason named" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    pr_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(1),
          "statusCheckRollup" => failure_rollup()
        }
      ])

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

    pull_requests = check(result, :pull_requests)
    assert pull_requests.status == :blocked
    assert pull_requests.details.reason =~ "failing"
    assert result.status == :blocked
  end

  test "a null or absent statusCheckRollup is treated as not-failing, not a crash" do
    repo = ready_repo!()

    null_rollup_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(1),
          "statusCheckRollup" => nil
        }
      ])

    absent_rollup_response =
      Jason.encode!([
        %{"number" => 222, "title" => "Candidate", "createdAt" => iso_days_ago(1)}
      ])

    for pr_response <- [null_rollup_response, absent_rollup_response] do
      result =
        with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: pr_response)

      assert check(result, :pull_requests).status == :pass
    end
  end

  test "a gh pr list query failure is cannot-check with the existing unavailable reason" do
    repo = ready_repo!()

    result =
      with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_query_exit: 1)

    pull_requests = check(result, :pull_requests)
    assert pull_requests.status == :cannot_check
    assert pull_requests.message == "Open PR state was not checked."
    assert result.status == :cannot_check
  end

  test "the cannot-check aggregate and the blocked aggregate exit with distinct nonzero codes, neither zero" do
    repo = ready_repo!()

    write_branch_protection_verifier!(
      repo,
      "echo 'OK: branch protection matches expected rules.'\n"
    )

    commit_all!(repo, "add verifier")
    push_upstream!(repo)

    stale_pr_response =
      Jason.encode!([
        %{
          "number" => 222,
          "title" => "Candidate",
          "createdAt" => iso_days_ago(15),
          "statusCheckRollup" => success_rollup()
        }
      ])

    {_blocked_output, blocked_exit} =
      run_hygiene(repo, ["--check", "--format", "json"], pr_response: stale_pr_response)

    {_cannot_check_output, cannot_check_exit} =
      run_hygiene(repo, ["--check", "--format", "json"], pr_query_exit: 1)

    assert {:shutdown, blocked_code} = blocked_exit
    assert {:shutdown, cannot_check_code} = cannot_check_exit
    assert blocked_code != 0
    assert cannot_check_code != 0
    assert blocked_code != cannot_check_code
    assert cannot_check_code == @cannot_check_exit
    assert blocked_code == @blocked_exit
  end

  defp check(result, name), do: Enum.find(result.checks, &(&1.name == name))

  defp iso_days_ago(days) do
    DateTime.utc_now()
    |> DateTime.add(-days * 24 * 60 * 60, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp success_rollup do
    [%{"__typename" => "CheckRun", "conclusion" => "SUCCESS"}]
  end

  defp failure_rollup do
    [
      %{"__typename" => "CheckRun", "conclusion" => "SUCCESS"},
      %{"__typename" => "CheckRun", "conclusion" => "FAILURE"}
    ]
  end

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
    configure_upstream!(repo)
    repo
  end

  defp configure_upstream!(repo) do
    remote = repo <> "-origin"
    File.rm_rf!(remote)
    File.mkdir_p!(remote)
    git!(remote, ["init", "--bare"])
    git!(repo, ["remote", "add", "origin", remote])
    git!(repo, ["push", "-u", "origin", "main"])
  end

  defp push_upstream!(repo), do: git!(repo, ["push", "origin", "main"])

  defp write_branch_protection_verifier!(repo, body) do
    scripts = Path.join(repo, "scripts")
    File.mkdir_p!(scripts)
    verifier = Path.join(scripts, "verify-branch-protection.sh")
    File.write!(verifier, "#!/usr/bin/env bash\nset -eu\n#{body}")
    File.chmod!(verifier, 0o755)
  end

  defp with_hygiene_environment(repo, fun, opts \\ []) do
    bin =
      Path.join(
        System.tmp_dir!(),
        "mailglass-repo-hygiene-bin-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(bin)
    gh = Path.join(bin, "gh")
    expected_sha = Keyword.get(opts, :expected_sha, git_output!(repo, ["rev-parse", "HEAD"]))

    response =
      Keyword.get(
        opts,
        :response,
        "[{\"headSha\":\"#{expected_sha}\",\"conclusion\":\"success\",\"status\":\"completed\",\"url\":\"https://example.test/run\"}]"
      )

    argv_log = Keyword.get(opts, :argv_log, Path.join(bin, "gh-argv.log"))
    query_exit = Keyword.get(opts, :query_exit, 0)
    pr_response = Keyword.get(opts, :pr_response, "[]")
    pr_query_exit = Keyword.get(opts, :pr_query_exit, 0)

    File.write!(gh, """
    #!/usr/bin/env bash
    set -eu

    if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
      if [ "#{pr_query_exit}" -ne 0 ]; then
        echo 'PR query unavailable' >&2
        exit #{pr_query_exit}
      fi

      echo '#{pr_response}'
      exit 0
    fi

    if [ "$1" != "run" ]; then
      echo 'invalid gh command' >&2
      exit 64
    fi

    printf '%s\\n' "$@" > #{argv_log}

    if [ "$#" -ne 10 ] || [ "$1" != "run" ] || [ "$2" != "list" ] ||
       [ "$3" != "--workflow" ] || [ "$4" != "ci.yml" ] ||
       [ "$5" != "--commit" ] || [ "$6" != "#{expected_sha}" ] ||
       [ "$7" != "--limit" ] || [ "$8" != "1" ] ||
       [ "$9" != "--json" ]; then
      echo 'invalid gh run list selector' >&2
      exit 64
    fi

    if [ "${10}" != "headSha,conclusion,status,url" ]; then
      echo 'invalid gh run list fields' >&2
      exit 64
    fi

    if [ "#{query_exit}" -ne 0 ]; then
      echo 'query unavailable' >&2
      exit #{query_exit}
    fi

    echo '#{response}'
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

  # A literal /usr/bin:/bin PATH is not a portable "gh missing" fixture:
  # GitHub's Ubuntu runner installs gh in /usr/bin, while Homebrew puts it
  # elsewhere on macOS. Build an explicit PATH containing the git prerequisite
  # and no gh binary so the test proves the same condition on every runner.
  defp without_gh(fun) do
    bin =
      Path.join(
        System.tmp_dir!(),
        "mailglass-repo-hygiene-no-gh-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(bin)
    File.ln_s!(System.find_executable("git"), Path.join(bin, "git"))

    try do
      with_env("PATH", bin, fun)
    after
      File.rm_rf!(bin)
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

  defp run_hygiene(repo, argv, opts \\ []) do
    with_hygiene_environment(
      repo,
      fn -> in_repo(repo, fn -> capture_hygiene_run(argv) end) end,
      opts
    )
  end

  defp capture_hygiene_run(argv) do
    test_process = self()

    output =
      capture_io(fn ->
        send(test_process, {:hygiene_exit, catch_exit(Hygiene.run(argv))})
      end)

    assert_receive {:hygiene_exit, exit}
    {output, exit}
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
        needs: [gate-ci-green, publish-core]
        if: needs.publish-core.result == 'skipped'
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

  defp git_output!(repo, args) do
    {output, 0} = System.cmd("git", args, cd: repo, stderr_to_stdout: true)
    String.trim(output)
  end

  defp normalize_statuses(%{checks: checks} = result) do
    %{result | status: to_string(result.status), checks: Enum.map(checks, &normalize_statuses/1)}
  end

  defp normalize_statuses(%{status: status} = check), do: %{check | status: to_string(status)}
end
