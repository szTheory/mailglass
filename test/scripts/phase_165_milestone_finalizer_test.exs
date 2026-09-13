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
    git!(repo, ["commit", "-q", "-m", "archived v2.7 fixture"])
    oid = git!(repo, ["rev-parse", "HEAD"]) |> String.trim()

    %{
      repo: repo,
      oid: oid,
      report: Path.join(repo, "tmp/phase-165-finalize.fixture/report.json")
    }
  end

  defp run_fixture(fixture) do
    node = System.find_executable("node") || flunk("node executable is required")
    loader_url = "file://#{@loader}"

    script = """
    import { runFixtureFinalization } from #{Jason.encode!(loader_url)};
    const oid = #{Jason.encode!(fixture.oid)};
    const base = {headBranch: "main", headSha: oid, status: "completed", conclusion: "success", attempt: 1};
    const result = runFixtureFinalization({
      repo: #{Jason.encode!(fixture.repo)},
      authorityOid: oid,
      reportRelative: "tmp/phase-165-finalize.fixture/report.json",
      ciRuns: [{...base, databaseId: 101, workflowName: "CI", event: "push"}],
      scheduleRuns: [
        {...base, databaseId: 201, workflowName: "Post Publish", event: "schedule"},
        {...base, databaseId: 202, workflowName: "Release Please", event: "schedule"},
        {...base, databaseId: 203, workflowName: "Repository Hygiene", event: "schedule"}
      ],
      expectedScheduleNames: ["Post Publish", "Release Please", "Repository Hygiene"]
    });
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
