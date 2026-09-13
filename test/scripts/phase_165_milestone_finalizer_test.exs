defmodule Mailglass.Phase165MilestoneFinalizerTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @loader Path.join(@repo_root, "scripts/mailglass_finalize_milestone_loader.mjs")
  @finalizer Path.join(@repo_root, "scripts/finalize_milestone_v2_7.sh")
  @installed_loader "/Users/jon/.local/bin/mailglass-finalize-milestone"

  @tag :phase_165_tracer
  test "repository and installed milestone authority lanes are separate" do
    aliases = Mix.Project.config()[:aliases]

    assert Keyword.fetch!(aliases, :"verify.phase_165.repository") == [
             "test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check"
           ]

    assert Keyword.fetch!(aliases, :"verify.phase_165.installed_boundary") == [
             "test test/scripts/phase_165_milestone_finalizer_test.exs --only phase_165_installed_production_boundary --warnings-as-errors --no-deps-check"
           ]

    required = Keyword.fetch!(aliases, :"verify.ci_lane_contract") |> List.to_string()
    assert required =~ "--exclude phase_165_installed_production_boundary"
    refute required =~ @installed_loader
  end

  @tag :phase_165_tracer
  test "exact v2.7 fixture authenticates a closed stage and writes one ignored pass report" do
    fixture = milestone_fixture!("tracer")
    {output, 0} = run_fixture(fixture)

    assert output =~ "terminal evidence passed at #{fixture.oid}"

    report = fixture.report |> File.read!() |> Jason.decode!()
    assert report["status"] == "pass"
    assert report["milestone"] == "v2.7"
    assert report["expected_main_sha"] == fixture.oid
    assert report["components"]["ci"]["attempt"] == 1
    assert Enum.all?(report["components"]["schedules"], &(&1["event"] == "schedule"))

    assert File.exists?(fixture.report)

    assert {_, 1} =
             System.cmd(
               "git",
               [
                 "-C",
                 fixture.repo,
                 "ls-files",
                 "--error-unmatch",
                 "--",
                 "tmp/phase-165-finalize.fixture/report.json"
               ],
               stderr_to_stdout: true
             )

    assert {_, 0} =
             System.cmd(
               "git",
               [
                 "-C",
                 fixture.repo,
                 "check-ignore",
                 "-q",
                 "--",
                 "tmp/phase-165-finalize.fixture/report.json"
               ],
               stderr_to_stdout: true
             )
  end

  @tag :phase_165_tracer
  test "loader exposes the required trust-boundary functions and exact token" do
    source = File.read!(@loader)

    for name <- [
          "buildInstallationProposal",
          "authenticateClosedManifest",
          "selectExactAttemptOneCi",
          "selectNaturalSchedules",
          "writeTerminalReport"
        ] do
      assert source =~ "export function #{name}"
    end

    node = System.find_executable("node") || flunk("node executable is required")
    assert {output, 1} = System.cmd(node, [@loader, "2.7"], stderr_to_stdout: true)
    assert output =~ "expected exact milestone token v2.7"
  end

  @tag :phase_165_hostile
  test "stale audit authority fails closed before terminal report publication" do
    fixture = milestone_fixture!("stale-audit")
    audit = Path.join(fixture.repo, ".planning/milestones/v2.7-MILESTONE-AUDIT.md")

    File.write!(
      audit,
      Regex.replace(
        ~r/^audited_head: [0-9a-f]{40}$/m,
        File.read!(audit),
        "audited_head: 0000000000000000000000000000000000000000"
      )
    )

    git!(fixture.repo, ["add", "--", ".planning/milestones/v2.7-MILESTONE-AUDIT.md"])
    git!(fixture.repo, ["commit", "-q", "-m", "forge stale audit"])
    fixture = %{fixture | oid: git!(fixture.repo, ["rev-parse", "HEAD"]) |> String.trim()}

    {output, status} = run_fixture(fixture)

    assert status != 0
    assert output =~ "stale audit"
    refute File.exists?(fixture.report)
  end

  @tag :phase_165_hostile
  test "audit scores, validation status, and policy-debt disclosure fail independently" do
    cases = [
      {"requirements", "requirements: 16/16", "requirements: 15/16",
       "requirements score is not 16/16"},
      {"phases", "phases: 5/5", "phases: 4/5", "phase score is not 5/5"},
      {"integration", "integration: 16/16", "integration: 15/16", "integration score is not 16/16"},
      {"flows", "flows: 5/5", "flows: 4/5", "flow score is not 5/5"},
      {"policy-debt", "14-PR accepted policy debt", "policy debt omitted",
       "omits accepted 14-PR policy debt"}
    ]

    for {name, old, replacement, diagnostic} <- cases do
      fixture = milestone_fixture!("audit-#{name}")

      fixture =
        mutate_fixture!(fixture, ".planning/milestones/v2.7-MILESTONE-AUDIT.md", fn body ->
          String.replace(body, old, replacement)
        end)

      assert_failure(fixture, %{}, diagnostic)
    end

    fixture = milestone_fixture!("validation")

    fixture =
      mutate_fixture!(
        fixture,
        ".planning/milestones/v2.7-phases/163-fixture/163-VALIDATION.md",
        &String.replace(&1, "status: validated", "status: draft")
      )

    assert_failure(fixture, %{}, "archived phase 163 is not validated")
  end

  @tag :phase_165_hostile
  test "incomplete, legacy-quick, and mixed live/archive layouts fail closed" do
    incomplete = milestone_fixture!("missing-phase")

    git!(incomplete.repo, [
      "rm",
      "-q",
      "-r",
      ".planning/milestones/v2.7-phases/165-fixture"
    ])

    git!(incomplete.repo, ["commit", "-q", "-m", "remove archived phase"])
    incomplete = refresh_oid(incomplete)
    assert_failure(incomplete, %{}, "archived phase layout is not exactly phases 161-165")

    quick = milestone_fixture!("legacy-quick")
    quick = add_fixture_file!(quick, ".planning/milestones/v2.7-quick/001.md", "legacy quick\n")
    assert_failure(quick, %{}, "legacy quick-task")

    mixed = milestone_fixture!("mixed-layout")
    mixed = add_fixture_file!(mixed, ".planning/phases/164-live/164-VALIDATION.md", "live\n")
    assert_failure(mixed, %{}, "live/archive lifecycle disagreement")
  end

  @tag :phase_165_hostile
  test "dirty and moving repository authority fails before or after report publication" do
    dirty = milestone_fixture!("dirty-entry")
    File.write!(Path.join(dirty.repo, "untracked-dirt"), "dirty\n")
    assert_failure(dirty, %{}, "repository is not clean")

    before_dispatch = milestone_fixture!("move-before-dispatch")

    assert_failure(
      before_dispatch,
      %{"fixtureMutation" => "move-before-dispatch"},
      "authority commit changed before Bash dispatch"
    )

    after_report = milestone_fixture!("move-after-report")

    {output, status} =
      run_fixture(after_report, %{"fixtureMutation" => "move-after-report"})

    assert status != 0
    assert output =~ "authority commit changed after report write"
    assert Jason.decode!(File.read!(after_report.report))["status"] == "blocked"

    dirty_after = milestone_fixture!("dirty-after-report")

    {output, status} =
      run_fixture(dirty_after, %{"fixtureMutation" => "dirty-after-report"})

    assert status != 0
    assert output =~ "stable porcelain changed after report write"
    assert Jason.decode!(File.read!(dirty_after.report))["status"] == "blocked"
  end

  @tag :phase_165_hostile
  test "caller-selected, rerun, and wrong-identity CI evidence fails closed" do
    fixture = milestone_fixture!("ci-selection")
    assert_failure(fixture, %{"ciRunId" => 101}, "caller-selected or unsupported fixture input")

    base = ci_run(fixture)

    for {name, mutation, diagnostic} <- [
          {"rerun", %{"attempt" => 2}, "expected one exact attempt-1 normal push CI"},
          {"dispatch", %{"event" => "workflow_dispatch"},
           "expected one exact attempt-1 normal push CI"},
          {"sha", %{"headSha" => String.duplicate("f", 40)},
           "expected one exact attempt-1 normal push CI"},
          {"branch", %{"headBranch" => "feature"}, "expected one exact attempt-1 normal push CI"}
        ] do
      assert_failure(
        fixture,
        %{"ciRuns" => [Map.merge(base, mutation)]},
        diagnostic <> " record for authority OID",
        name
      )
    end
  end

  @tag :phase_165_hostile
  test "manual, rerun, wrong-branch, and wrong-SHA schedules fail closed" do
    fixture = milestone_fixture!("schedule-selection")
    schedules = schedule_runs(fixture)

    for {name, mutation} <- [
          {"manual", %{"event" => "workflow_dispatch"}},
          {"rerun", %{"attempt" => 2}},
          {"branch", %{"headBranch" => "feature"}},
          {"sha", %{"headSha" => String.duplicate("e", 40)}}
        ] do
      hostile = List.update_at(schedules, 0, &Map.merge(&1, mutation))

      assert_failure(
        fixture,
        %{"scheduleRuns" => hostile},
        "expected one natural attempt-1 Post Publish schedule for authority OID",
        name
      )
    end
  end

  @tag :phase_165_hostile
  test "tracked terminal output fails before staged finalizer dispatch" do
    fixture = milestone_fixture!("tracked-output")
    tracked = "tmp/tracked-output/report.json"
    write!(fixture.repo, tracked, "tracked\n")
    git!(fixture.repo, ["add", "-f", "--", tracked])
    git!(fixture.repo, ["commit", "-q", "-m", "track terminal output target"])
    fixture = refresh_oid(%{fixture | report: Path.join(fixture.repo, tracked)})

    {output, status} = run_fixture(fixture, %{"reportRelative" => tracked})
    assert status != 0
    assert output =~ "terminal report target is tracked"
    assert File.read!(fixture.report) == "tracked\n"
  end

  @tag :phase_165_hostile
  test "installation proposal admits only absence or one safe regular predecessor" do
    fixture = milestone_fixture!("proposal")
    root = Path.join(Path.dirname(fixture.repo), "installation")
    File.mkdir_p!(root)
    absent = Path.join(root, "absent")

    absent_proposal = installation_proposal(fixture, absent)
    assert absent_proposal["predecessor"]["disposition"] == "create"
    assert absent_proposal["mode"] == "0500"
    assert length(absent_proposal["runtime_closure"]) == 8
    assert absent_proposal["rollback"]["action"] == "remove_created"

    safe = Path.join(root, "safe")
    File.write!(safe, "prior\n")
    File.chmod!(safe, 0o500)
    safe_proposal = installation_proposal(fixture, safe)
    assert safe_proposal["predecessor"]["disposition"] == "backup_replace"
    assert safe_proposal["predecessor"]["sha256"] =~ ~r/^[0-9a-f]{64}$/
    assert safe_proposal["rollback"]["action"] == "restore_backup"

    unsafe = Path.join(root, "unsafe")
    File.write!(unsafe, "unsafe\n")
    File.chmod!(unsafe, 0o777)
    assert {:error, diagnostic} = installation_proposal_result(fixture, unsafe)
    assert diagnostic =~ "unsafe mode"

    directory = Path.join(root, "directory")
    File.mkdir_p!(directory)
    assert {:error, diagnostic} = installation_proposal_result(fixture, directory)
    assert diagnostic =~ "unsafe predecessor kind"

    symlink = Path.join(root, "symlink")
    File.ln_s!(safe, symlink)
    assert {:error, diagnostic} = installation_proposal_result(fixture, symlink)
    assert diagnostic =~ "unsafe predecessor kind"
  end

  @tag :phase_165_hostile
  test "installed-byte mismatch fails the external self-check" do
    fixture = milestone_fixture!("installed-byte-mismatch")
    installed = Path.join(Path.dirname(fixture.repo), "mailglass-finalize-milestone")
    File.write!(installed, File.read!(@loader) <> "\n// forged byte\n")
    File.chmod!(installed, 0o500)

    assert {output, 1} =
             System.cmd(
               installed,
               ["--self-check", "--repo", fixture.repo, "--expected-source-oid", fixture.oid],
               stderr_to_stdout: true
             )

    assert output =~ "installed-byte mismatch"
  end

  describe "installed milestone production boundary" do
    @describetag :phase_165_installed_production_boundary

    test "installed command has the approved executable identity" do
      assert File.regular?(@installed_loader)

      assert {"mailglass-finalize-milestone-loader 1\n", 0} =
               System.cmd(@installed_loader, ["--version"], stderr_to_stdout: true)
    end
  end

  defp milestone_fixture!(name) do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-phase-165-#{name}-#{System.unique_integer([:positive])}"
      )

    repo = Path.join(root, "repo")
    File.mkdir_p!(repo)
    on_exit(fn -> File.rm_rf!(root) end)

    git!(repo, ["init", "-q", "-b", "main"])
    git!(repo, ["config", "user.email", "phase165@example.invalid"])
    git!(repo, ["config", "user.name", "Phase 165 Fixture"])
    git!(repo, ["remote", "add", "origin", "git@github.com:szTheory/mailglass.git"])

    write!(repo, ".gitignore", "/tmp/\n")
    write!(repo, "scripts/mailglass_finalize_milestone_loader.mjs", File.read!(@loader), 0o755)
    write!(repo, "scripts/finalize_milestone_v2_7.sh", File.read!(@finalizer), 0o755)
    write!(repo, ".planning/milestones/v2.7-ROADMAP.md", "# v2.7 archived roadmap\n")
    write!(repo, ".planning/milestones/v2.7-REQUIREMENTS.md", "# v2.7 requirements\n16/16\n")

    write!(
      repo,
      ".planning/milestones/v2.7-MILESTONE-AUDIT.md",
      """
      ---
      status: passed
      audited_head: AUDIT_HEAD
      ---
      requirements: 16/16
      phases: 5/5
      integration: 16/16
      flows: 5/5
      14-PR accepted policy debt
      """
    )

    write!(repo, ".planning/MILESTONES.md", "v2.7 archived\n")
    write!(repo, ".planning/PROJECT.md", "v2.7 completed and archived\n")
    write!(repo, ".planning/STATE.md", "v2.7 archived\n")
    write!(repo, ".planning/state.json", ~s({"milestone":"v2.7","status":"archived"}\n))

    for phase <- 161..165 do
      slug = "#{phase}-fixture"

      write!(
        repo,
        ".planning/milestones/v2.7-phases/#{slug}/#{phase}-VALIDATION.md",
        "---\nstatus: validated\n---\n"
      )

      write!(
        repo,
        ".planning/milestones/v2.7-phases/#{slug}/#{phase}-SUMMARY.md",
        "---\nstatus: complete\n---\n"
      )
    end

    git!(repo, ["add", "."])
    git!(repo, ["commit", "-q", "-m", "canonical v2.7 audit fixture"])
    audit_oid = git!(repo, ["rev-parse", "HEAD"]) |> String.trim()
    audit_path = Path.join(repo, ".planning/milestones/v2.7-MILESTONE-AUDIT.md")
    File.write!(audit_path, String.replace(File.read!(audit_path), "AUDIT_HEAD", audit_oid))
    git!(repo, ["add", "--", ".planning/milestones/v2.7-MILESTONE-AUDIT.md"])
    git!(repo, ["commit", "-q", "-m", "final archived v2.7 fixture"])
    oid = git!(repo, ["rev-parse", "HEAD"]) |> String.trim()

    %{
      repo: repo,
      oid: oid,
      report: Path.join(repo, "tmp/phase-165-finalize.fixture/report.json")
    }
  end

  defp mutate_fixture!(fixture, relative, transform) do
    path = Path.join(fixture.repo, relative)
    File.write!(path, transform.(File.read!(path)))
    git!(fixture.repo, ["add", "--", relative])
    git!(fixture.repo, ["commit", "-q", "-m", "hostile fixture #{relative}"])
    refresh_oid(fixture)
  end

  defp add_fixture_file!(fixture, relative, contents) do
    write!(fixture.repo, relative, contents)
    git!(fixture.repo, ["add", "--", relative])
    git!(fixture.repo, ["commit", "-q", "-m", "hostile fixture #{relative}"])
    refresh_oid(fixture)
  end

  defp refresh_oid(fixture) do
    %{fixture | oid: git!(fixture.repo, ["rev-parse", "HEAD"]) |> String.trim()}
  end

  defp ci_run(fixture) do
    %{
      "databaseId" => 101,
      "workflowName" => "CI",
      "event" => "push",
      "attempt" => 1,
      "headBranch" => "main",
      "headSha" => fixture.oid,
      "status" => "completed",
      "conclusion" => "success"
    }
  end

  defp schedule_runs(fixture) do
    for {id, workflow} <- [
          {201, "Post Publish"},
          {202, "Release Please"},
          {203, "Repository Hygiene"}
        ] do
      ci_run(fixture)
      |> Map.merge(%{"databaseId" => id, "workflowName" => workflow, "event" => "schedule"})
    end
  end

  defp assert_failure(fixture, overrides, diagnostic, label \\ nil) do
    {output, status} = run_fixture(fixture, overrides)
    assert status != 0, "#{label || diagnostic} unexpectedly succeeded"
    assert output =~ diagnostic, "#{label || diagnostic} emitted: #{output}"
    refute File.exists?(fixture.report)
  end

  defp installation_proposal(fixture, destination) do
    case installation_proposal_result(fixture, destination) do
      {:ok, proposal} -> proposal
      {:error, diagnostic} -> flunk("installation proposal failed: #{diagnostic}")
    end
  end

  defp installation_proposal_result(fixture, destination) do
    node = System.find_executable("node") || flunk("node executable is required")
    loader_url = "file://#{@loader}"

    script = """
    import { buildInstallationProposal } from #{Jason.encode!(loader_url)};
    const proposal = buildInstallationProposal({
      repo: #{Jason.encode!(fixture.repo)},
      authorityOid: #{Jason.encode!(fixture.oid)},
      destination: #{Jason.encode!(destination)}
    });
    console.log(JSON.stringify(proposal));
    """

    case System.cmd(node, ["--input-type=module", "--eval", script],
           cd: @repo_root,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, output |> String.trim() |> Jason.decode!()}
      {output, _status} -> {:error, output}
    end
  end

  defp run_fixture(fixture, overrides \\ %{}) do
    node = System.find_executable("node") || flunk("node executable is required")
    loader_url = "file://#{@loader}"

    base = %{
      "headBranch" => "main",
      "headSha" => fixture.oid,
      "status" => "completed",
      "conclusion" => "success",
      "attempt" => 1
    }

    defaults = %{
      "repo" => fixture.repo,
      "authorityOid" => fixture.oid,
      "reportRelative" => "tmp/phase-165-finalize.fixture/report.json",
      "ciRuns" => [
        Map.merge(base, %{"databaseId" => 101, "workflowName" => "CI", "event" => "push"})
      ],
      "scheduleRuns" =>
        [
          {201, "Post Publish"},
          {202, "Release Please"},
          {203, "Repository Hygiene"}
        ]
        |> Enum.map(fn {id, workflow} ->
          Map.merge(base, %{"databaseId" => id, "workflowName" => workflow, "event" => "schedule"})
        end),
      "expectedScheduleNames" => ["Post Publish", "Release Please", "Repository Hygiene"]
    }

    options = Map.merge(defaults, overrides)

    script = """
    import { runFixtureFinalization } from #{Jason.encode!(loader_url)};
    const result = runFixtureFinalization(#{Jason.encode!(options)});
    console.log(result.output);
    """

    System.cmd(node, ["--input-type=module", "--eval", script],
      cd: @repo_root,
      stderr_to_stdout: true
    )
  end

  defp write!(repo, relative, contents, mode \\ nil) do
    path = Path.join(repo, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    if mode, do: File.chmod!(path, mode)
    path
  end

  defp git!(repo, args) do
    case System.cmd("git", ["-C", repo | args], stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end
