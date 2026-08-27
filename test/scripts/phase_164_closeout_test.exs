defmodule Mailglass.Scripts.Phase164CloseoutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/closeout_repository_truth.sh")

  test "a complete exact-main fixture emits a pass report and each authority is non-vacuous" do
    fixture = fixture!()

    assert {_, 0} = run(fixture)
    assert {:ok, report} = fixture.output |> File.read!() |> Jason.decode()
    assert report["schema"] == "mailglass.repository-closeout/v1"
    assert report["status"] == "pass"
    assert report["head_sha"] == fixture.sha
    assert report["origin_main_sha"] == fixture.sha
    assert report["ci_run_id"] == "123"
    assert Map.has_key?(report, "captured_at")
    assert Map.has_key?(report, "components")

    policy_blocked = fixture!(:hygiene_blocked)
    assert {_, 0} = run(policy_blocked)
    assert {:ok, blocked_report} = policy_blocked.output |> File.read!() |> Jason.decode()
    assert blocked_report["status"] == "pass"
    assert blocked_report["components"]["hygiene"]["status"] == "blocked"

    for mutation <- [:hygiene, :preservation, :ledger, :ci, :scheduled] do
      changed = fixture!(mutation)
      assert {_, status} = run(changed)
      assert status != 0, "#{mutation} must not be vacuous"
    end
  end

  test "branch, remote identity, porcelain dirt, and malformed external JSON fail closed" do
    for mutation <- [:branch, :divergent, :dirty, :malformed_hygiene] do
      fixture = fixture!(mutation)
      assert {_, status} = run(fixture)
      assert status != 0
      assert {:ok, report} = fixture.output |> File.read!() |> Jason.decode()
      assert report["status"] != "pass"
    end
  end

  test "pending, cannot-check, stale, mismatched, and incomplete blocked scheduled evidence cannot pass" do
    for mutation <- [
          :scheduled_pending,
          :scheduled_cannot_check,
          :scheduled_stale,
          :scheduled_mismatched,
          :scheduled_blocked_incomplete
        ] do
      fixture = fixture!(mutation)
      assert {_, status} = run(fixture)
      assert status != 0
      assert {:ok, %{"status" => status_text}} = fixture.output |> File.read!() |> Jason.decode()
      refute status_text == "pass"
    end
  end

  test "the CLI rejects missing, unknown, and non-positive CI run IDs with usage status" do
    fixture = fixture!()

    for args <- [[], ["--repo", fixture.repo], ["--ci-run-id", "0"], ["--unknown", "value"]] do
      {_, status} = System.cmd("bash", [@script | args], stderr_to_stdout: true)
      assert status == 2
    end
  end

  defp run(fixture) do
    System.cmd(
      "bash",
      [
        @script,
        "--repo",
        fixture.repo,
        "--ledger",
        fixture.ledger,
        "--ci-run-id",
        "123",
        "--output",
        fixture.output
      ],
      env: [{"PATH", "#{fixture.bin}:#{System.fetch_env!("PATH")}"}],
      stderr_to_stdout: true
    )
  end

  defp fixture!(mutation \\ :pass) do
    root = Path.join(System.tmp_dir!(), "mailglass-closeout-#{System.unique_integer([:positive])}")
    repo = Path.join(root, "repo")
    remote = Path.join(root, "origin.git")
    bin = Path.join(root, "bin")
    output = Path.join(root, "report/report.json")
    ledger = Path.join(repo, "ledger.tsv")
    File.rm_rf!(root)
    File.mkdir_p!(bin)
    File.mkdir_p!(Path.join(repo, "scripts"))
    File.mkdir_p!(remote)
    git!(repo, ["init", "-b", "main"])
    git!(repo, ["config", "user.email", "test@example.test"])
    git!(repo, ["config", "user.name", "Closeout Test"])
    File.write!(Path.join(repo, "tracked.txt"), "base\n")
    File.write!(ledger, ledger_contents())
    write_fixture_scripts!(repo, bin, mutation)
    git!(repo, ["add", "."])
    git!(repo, ["commit", "-m", "base"])
    sha = git!(repo, ["rev-parse", "HEAD"])
    git!(remote, ["init", "--bare"])
    git!(repo, ["remote", "add", "origin", remote])
    git!(repo, ["push", "-u", "origin", "main"])

    case mutation do
      :branch ->
        git!(repo, ["checkout", "-b", "other"])

      :divergent ->
        git!(repo, ["commit", "--allow-empty", "-m", "divergent"])

      :dirty ->
        File.write!(Path.join(repo, "untracked.txt"), "dirt\n")

      :ledger ->
        File.write!(ledger, String.replace(ledger_contents(), "retain", "destroy", global: false))

      _ ->
        :ok
    end

    %{repo: repo, bin: bin, output: output, ledger: ledger, sha: sha}
  end

  defp write_fixture_scripts!(repo, bin, mutation) do
    hygiene =
      case mutation do
        :malformed_hygiene -> "{not-json"
        :hygiene -> ~s({"status":"cannot-check","reason":"not_clean"})
        :hygiene_blocked ->
          ~s({"status":"blocked","reason":"expected_policy_gate","checks":[{"name":"release","status":"blocked","message":"retained proposal","details":{"pr":222}}]})

        _ -> ~s({"status":"pass","reason":"clean"})
      end

    ci_sha = if mutation == :ci, do: String.duplicate("b", 40), else: "$(git rev-parse HEAD)"
    scheduled = scheduled_script_json(mutation)

    hygiene_exit = if mutation == :hygiene_blocked, do: 1, else: 0

    File.write!(
      Path.join(bin, "mix"),
      "#!/usr/bin/env bash\nprintf '%s\\n' '#{hygiene}'\nexit #{hygiene_exit}\n"
    )

    File.write!(
      Path.join(bin, "node"),
      "#!/usr/bin/env bash\nprintf '%s\\n' 'ci_monitor: diagnostic' >&2\nprintf '{\\\"headSha\\\":\\\"%s\\\",\\\"status\\\":\\\"completed\\\",\\\"conclusion\\\":\\\"success\\\"}\\n' \"#{ci_sha}\"\n"
    )

    File.chmod!(Path.join(bin, "mix"), 0o755)
    File.chmod!(Path.join(bin, "node"), 0o755)

    File.write!(
      Path.join(repo, "scripts/verify_workspace_evidence.sh"),
      "#!/usr/bin/env bash\nexit #{if(mutation == :preservation, do: 1, else: 0)}\n"
    )

    File.write!(
      Path.join(repo, "scripts/scheduled_control_evidence.sh"),
      "#!/usr/bin/env bash\nhead=$(git rev-parse HEAD)\nmkdir -p \"$(dirname \"$3\")\"\nprintf '#{scheduled}\\n' \"$head\" \"$head\" \"$head\" > \"$3\"\nexit 0\n"
    )

    File.chmod!(Path.join(repo, "scripts/verify_workspace_evidence.sh"), 0o755)
    File.chmod!(Path.join(repo, "scripts/scheduled_control_evidence.sh"), 0o755)
  end

  defp scheduled_script_json(mutation) do
    status =
      if mutation in [:scheduled, :scheduled_pending, :scheduled_cannot_check],
        do: String.replace(to_string(mutation), "scheduled_", ""),
        else: "pass"

    evidence_valid = mutation not in [:scheduled_mismatched, :scheduled_blocked_incomplete]
    head = if mutation == :scheduled_mismatched, do: String.duplicate("c", 40), else: "%s"
    result_status = if mutation == :scheduled_blocked_incomplete, do: "blocked", else: status

    updated =
      if mutation == :scheduled_stale,
        do: "2000-01-01T00:00:00Z",
        else: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    payload =
      if mutation == :scheduled_blocked_incomplete,
        do: "",
        else: ",\\\"payload_sha256\\\":\\\"abc\\\""

    "{\\\"status\\\":\\\"#{status}\\\",\\\"reason\\\":\\\"ok\\\",\\\"evidence_valid\\\":#{evidence_valid},\\\"expected_main_sha\\\":\\\"%s\\\",\\\"controls\\\":[{\\\"evidence_valid\\\":#{evidence_valid},\\\"source_run\\\":{\\\"event\\\":\\\"schedule\\\",\\\"status\\\":\\\"completed\\\",\\\"head_branch\\\":\\\"main\\\",\\\"head_sha\\\":\\\"#{head}\\\",\\\"updated_at\\\":\\\"#{updated}\\\"},\\\"result\\\":{\\\"status\\\":\\\"#{result_status}\\\",\\\"reason\\\":\\\"ok\\\",\\\"workflow_sha\\\":\\\"%s\\\"#{payload}}}]}"
  end

  defp ledger_contents do
    "stable_id\tsubject\tkind\tproducer\tstate\tauthority\treproducibility\tcurrentness\tdurable_consumer\tevidence\tdisposition\trationale\nD-01\tproof\tproof\tproducer\ttracked\tauthority\treproducible\tcurrent\tconsumer\tevidence\tretain\trationale\n"
  end

  defp git!(directory, arguments) do
    {output, 0} = System.cmd("git", arguments, cd: directory, stderr_to_stdout: true)
    String.trim(output)
  end
end
