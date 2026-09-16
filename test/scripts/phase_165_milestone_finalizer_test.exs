defmodule Mailglass.Phase165MilestoneFinalizerTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @loader Path.join(@repo_root, "scripts/mailglass_finalize_milestone_loader.mjs")
  @finalizer Path.join(@repo_root, "scripts/finalize_milestone_v2_7.sh")
  @fixture_loader Path.join(@repo_root, "test/support/mailglass_milestone_finalizer_fixture.mjs")
  # The runbook lives under the live phase directory until v2.7 is archived, after which
  # `milestone complete` MOVES it into the milestone archive. Both locations are the same
  # authored bytes; resolving either keeps this lane honest across the archive boundary
  # instead of going red the moment the milestone it describes is closed.
  @finalization_runbook_candidates [
                                     ".planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md",
                                     ".planning/milestones/v2.7-phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md"
                                   ]
                                   |> Enum.map(&Path.join(@repo_root, &1))
  @installed_loader "/Users/jon/.local/bin/mailglass-finalize-milestone"

  @tag :phase_165_tracer
  test "repository and installed milestone authority lanes are separate" do
    aliases = Mix.Project.config()[:aliases]

    assert Keyword.fetch!(aliases, :"verify.phase_165.repository") == [
             "test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --include phase_165_controlled_host --warnings-as-errors --no-deps-check"
           ]

    assert Keyword.fetch!(aliases, :"verify.phase_165.installed_boundary") == [
             "test test/scripts/phase_165_milestone_finalizer_test.exs --only phase_165_installed_production_boundary --warnings-as-errors --no-deps-check"
           ]

    required = Keyword.fetch!(aliases, :"verify.ci_lane_contract") |> List.to_string()
    assert required =~ "--exclude phase_165_installed_production_boundary"

    # Every test that EXECUTES the loader validates a pinned closed runtime by absolute
    # path and digest, so it can only pass on the controlled maintainer host. The shared
    # lane excludes them; `verify.phase_165.repository` still runs them in full. Pinned
    # here so the isolation cannot silently widen or disappear.
    assert required =~ "--exclude phase_165_controlled_host"

    # The base ExUnit exclusion in test_helper.exs keeps controlled-host proof out of
    # every root process, including bare `mix test`. Only this one alias opts back in.
    repository = Keyword.fetch!(aliases, :"verify.phase_165.repository") |> List.to_string()
    assert repository =~ "--include phase_165_controlled_host"
    refute repository =~ "--exclude phase_165_controlled_host"

    helper = File.read!(Path.join(@repo_root, "test/test_helper.exs"))
    assert helper =~ ":phase_165_controlled_host"

    refute required =~ @installed_loader
  end

  @tag :phase_165_tracer
  @tag :phase_165_controlled_host
  test "exact v2.7 fixture authenticates a closed stage without emitting terminal pass evidence" do
    fixture = milestone_fixture!("tracer")
    {output, 0} = run_fixture(fixture)

    assert output =~ "fixture evidence validated at #{fixture.oid}"

    report = fixture.report |> File.read!() |> Jason.decode!()
    assert report["schema"] == "mailglass-finalize-milestone-fixture-v1"
    assert report["status"] == "fixture-only"
    refute report["schema"] == "mailglass-finalize-milestone-report-v1"
    assert report["milestone"] == "v2.7"
    assert report["expected_main_sha"] == fixture.oid
    assert report["executable"]["sha256"] =~ ~r/^[0-9a-f]{64}$/
    assert report["executable"]["source_oid"] == fixture.oid
    assert length(report["runtime_closure"]) == 5
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
          "recordInstallationApproval",
          "installApprovedExecutable",
          "rollbackApprovedInstallation",
          "authenticateApprovedInstallation",
          "authenticateClosedManifest",
          "selectExactAttemptOneCi",
          "selectNaturalSchedules",
          "verifyInstalledExecutable"
        ] do
      assert source =~ "export function #{name}"
    end

    refute source =~ "runFixtureFinalization"
    refute source =~ "writeTerminalReport"

    finalizer = File.read!(@finalizer)
    refute finalizer =~ ~s|if [ "${MAILGLASS_MILESTONE_FIXTURE:-}" != 1 ]|
    assert finalizer =~ ~s|"$MAILGLASS_GIT" -C "$repo" fetch origin main|

    node = System.find_executable("node") || flunk("node executable is required")
    assert {output, 1} = System.cmd(node, [@loader, "2.7"], stderr_to_stdout: true)
    assert output =~ "expected exact milestone token v2.7"
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "actual canonical audit schema is accepted and a wrong milestone fails closed" do
    fixture = milestone_fixture!("canonical-audit")
    assert {_, 0} = run_fixture(fixture)

    wrong = milestone_fixture!("wrong-audit-milestone")

    wrong =
      mutate_fixture!(wrong, ".planning/milestones/v2.7-MILESTONE-AUDIT.md", fn body ->
        String.replace(body, "milestone: v2.7", "milestone: v2.6")
      end)

    assert_failure(wrong, %{}, "canonical audit milestone is not v2.7")
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "audit scores, validation status, and policy-debt disclosure fail independently" do
    cases = [
      {"requirements", "requirements: 16/16", "requirements: 15/16",
       "requirements score is not 16/16"},
      {"phases", "phases: 5/5", "phases: 4/5", "phase score is not 5/5"},
      {"integration", "integration: 16/16", "integration: 15/16", "integration score is not 16/16"},
      {"flows", "flows: 5/5", "flows: 4/5", "flow score is not 5/5"}
    ]

    for {name, old, replacement, diagnostic} <- cases do
      fixture = milestone_fixture!("audit-#{name}")

      fixture =
        mutate_fixture!(fixture, ".planning/milestones/v2.7-MILESTONE-AUDIT.md", fn body ->
          String.replace(body, old, replacement) <>
            "\nExplanatory prose retains the non-authoritative expected token: #{old}\n"
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

    assert_failure(fixture, %{}, "archived phase 163 status is not validated")

    duplicate = milestone_fixture!("audit-duplicate-score")

    duplicate =
      mutate_fixture!(duplicate, ".planning/milestones/v2.7-MILESTONE-AUDIT.md", fn body ->
        String.replace(
          body,
          "  requirements: 16/16",
          "  requirements: 16/16\n  requirements: 16/16"
        )
      end)

    assert_failure(duplicate, %{}, "requirements score is missing or duplicated")
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "lifecycle prose cannot impersonate authoritative archived state" do
    cases = [
      {"state", ".planning/STATE.md",
       fn body ->
         String.replace(body, "status: archived", "status: active") <>
           "\nv2.7 is not archived; the word archived is explanatory only.\n"
       end, "state status is not archived"},
      {"project", ".planning/PROJECT.md",
       fn body ->
         String.replace(body, "## Completed Milestone:", "## Proposed Milestone:") <>
           "\nThe phrase Completed Milestone: v2.7 Repository Stewardship & Operational Hygiene is not authoritative.\n"
       end, "project omits the completed v2.7 record"},
      {"milestones", ".planning/MILESTONES.md",
       fn body ->
         String.replace(body, "(Completed:", "(Not completed:") <>
           "\nv2.7 archived appears only in prose.\n"
       end, "milestone ledger omits the completed v2.7 record"},
      # A hand-written stub carrying the word "archived" is not machine state. This is
      # the exact shape the pre-repair assertion accepted, and no publisher emits it.
      {"state-json-stub", ".planning/state.json",
       fn _body -> ~s({"milestone":"v2.7","status":"archived"}\n) end,
       "machine state does not agree that v2.7 is archived"},
      # A canonical contract that still lists live phases has not been archived.
      {"state-json-live-phase", ".planning/state.json",
       fn body ->
         String.replace(
           body,
           ~s("phases":[]),
           ~s("phases":[{"number":"165","name":"Fixture","status":"complete"}])
         )
       end, "machine state does not agree that v2.7 is archived"}
    ]

    for {name, relative, mutation, diagnostic} <- cases do
      fixture = milestone_fixture!("lifecycle-#{name}")
      fixture = mutate_fixture!(fixture, relative, mutation)
      assert_failure(fixture, %{}, diagnostic)
    end

    for {name, relative, phrase, diagnostic} <- [
          {"state-debt", ".planning/STATE.md",
           "Repository hygiene remains policy-blocked by 14 open PRs as accepted operational debt.\n",
           "state omits the accepted 14-PR policy debt"},
          {"project-debt", ".planning/PROJECT.md",
           "The 14 open PRs remain disclosed accepted repository-hygiene policy debt.\n",
           "project omits the accepted 14-PR policy debt"}
        ] do
      fixture = milestone_fixture!(name)
      fixture = mutate_fixture!(fixture, relative, &String.replace(&1, phrase, ""))
      assert_failure(fixture, %{}, diagnostic)
    end
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
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
  @tag :phase_165_controlled_host
  test "stale live ledgers and absent retrospective evidence fail closed" do
    roadmap = milestone_fixture!("stale-live-roadmap")

    roadmap =
      mutate_fixture!(roadmap, ".planning/ROADMAP.md", fn body ->
        body <> "\n## Phase 165: stale live milestone detail\n"
      end)

    assert_failure(roadmap, %{}, "live ROADMAP retains stale v2.7 phase detail")

    requirements = milestone_fixture!("live-requirements")

    requirements =
      add_fixture_file!(requirements, ".planning/REQUIREMENTS.md", "# stale v2.7 requirements\n")

    assert_failure(requirements, %{}, "live REQUIREMENTS.md remains after milestone archive")

    retrospective = milestone_fixture!("missing-retrospective")
    git!(retrospective.repo, ["rm", "-q", "--", ".planning/RETROSPECTIVE.md"])
    git!(retrospective.repo, ["commit", "-q", "-m", "remove milestone retrospective"])
    retrospective = refresh_oid(retrospective)
    assert_failure(retrospective, %{}, ".planning/RETROSPECTIVE.md is missing from the worktree")
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "false or missing Nyquist validation fields fail closed" do
    for {name, transform, diagnostic} <- [
          {"nyquist-false",
           &String.replace(&1, "nyquist_compliant: true", "nyquist_compliant: false"),
           "archived phase 163 Nyquist compliance is not true"},
          {"nyquist-missing", &String.replace(&1, "nyquist_compliant: true\n", ""),
           "archived phase 163 Nyquist compliance is missing or duplicated"},
          {"wave-zero-false",
           &String.replace(&1, "wave_0_complete: true", "wave_0_complete: false"),
           "archived phase 163 Wave 0 completion is not true"},
          {"wave-zero-missing", &String.replace(&1, "wave_0_complete: true\n", ""),
           "archived phase 163 Wave 0 completion is missing or duplicated"}
        ] do
      fixture = milestone_fixture!(name)

      fixture =
        mutate_fixture!(
          fixture,
          ".planning/milestones/v2.7-phases/163-fixture/163-VALIDATION.md",
          transform
        )

      assert_failure(fixture, %{}, diagnostic)
    end
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
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
  @tag :phase_165_controlled_host
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
  @tag :phase_165_controlled_host
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
  @tag :phase_165_controlled_host
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
  @tag :phase_165_controlled_host
  test "report boundary rejects symlinked parents and existing ignored targets without overwrite" do
    symlinked = milestone_fixture!("symlinked-report-parent")
    outside = Path.join(Path.dirname(symlinked.repo), "outside-report-root")
    File.mkdir_p!(Path.join(symlinked.repo, "tmp"))
    File.mkdir_p!(outside)
    File.ln_s!(outside, Path.join(symlinked.repo, "tmp/symlinked"))

    {output, status} = run_fixture(symlinked, %{"reportRelative" => "tmp/symlinked/report.json"})
    assert status != 0
    assert output =~ "fixture report parent is not one physical directory"
    refute File.exists?(Path.join(outside, "report.json"))

    existing = milestone_fixture!("existing-report")
    existing_path = Path.join(existing.repo, "tmp/existing/report.json")
    File.mkdir_p!(Path.dirname(existing_path))
    File.write!(existing_path, "do-not-overwrite\n")

    {output, status} = run_fixture(existing, %{"reportRelative" => "tmp/existing/report.json"})
    assert status != 0
    assert output =~ "terminal report target already exists"
    assert File.read!(existing_path) == "do-not-overwrite\n"
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "a second fixture invocation is rejected and cannot rewrite its first receipt" do
    fixture = milestone_fixture!("one-shot")
    assert {_, 0} = run_fixture(fixture)
    first = File.read!(fixture.report)

    {output, status} = run_fixture(fixture)
    assert status != 0
    assert output =~ "terminal report target already exists"
    assert File.read!(fixture.report) == first
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "a transient evidence query failure releases no receipt and identical retry succeeds" do
    fixture = milestone_fixture!("transient-query-retry")
    marker = Path.join(physical_dir!(Path.dirname(fixture.repo)), "transient-query.marker")
    options = %{"transientQueryMarker" => marker}

    {output, status} = run_fixture(fixture, options)
    assert status != 0
    assert output =~ "transient read-only evidence query failed"
    refute File.exists?(fixture.report)
    refute File.exists?(Path.dirname(fixture.report))

    assert {output, 0} = run_fixture(fixture, options)
    assert output =~ "fixture evidence validated"
    assert File.exists?(fixture.report)
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "caller PATH cannot shadow shell utilities" do
    fixture = milestone_fixture!("path-shadow")
    shadow = Path.join(Path.dirname(fixture.repo), "shadow-bin")
    marker = Path.join(Path.dirname(fixture.repo), "shadow-executed")
    File.mkdir_p!(shadow)

    for name <- ["grep", "mktemp"] do
      path = Path.join(shadow, name)
      File.write!(path, "#!/bin/bash\nprintf shadow > #{marker}\nexit 91\n")
      File.chmod!(path, 0o700)
    end

    hostile_path = shadow <> ":" <> System.fetch_env!("PATH")
    assert {_, 0} = run_fixture(fixture, %{}, [{"PATH", hostile_path}])
    refute File.exists?(marker)
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "installation proposal admits only absence or one safe regular predecessor" do
    fixture = milestone_fixture!("proposal")
    root = Path.join(Path.dirname(fixture.repo), "installation")
    File.mkdir_p!(root)
    root = physical_dir!(root)
    absent = Path.join(root, "absent")

    absent_proposal = installation_proposal(fixture, absent)
    assert absent_proposal["repository"] == physical_dir!(fixture.repo)
    assert absent_proposal["source_oid"] == fixture.oid
    assert absent_proposal["proposal_digest"] =~ ~r/^[0-9a-f]{64}$/
    assert absent_proposal["predecessor"]["disposition"] == "create"
    assert absent_proposal["mode"] == "0500"
    assert length(absent_proposal["runtime_closure"]) == 5
    assert Enum.all?(absent_proposal["runtime_closure"], &(&1["sha256"] =~ ~r/^[0-9a-f]{64}$/))
    assert Enum.all?(absent_proposal["runtime_closure"], &is_binary(&1["version"]))
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

    physical_parent = Path.join(root, "physical-parent")
    linked_parent = Path.join(root, "linked-parent")
    File.mkdir_p!(physical_parent)
    File.ln_s!(physical_parent, linked_parent)

    assert {:error, diagnostic} =
             installation_proposal_result(fixture, Path.join(linked_parent, "destination"))

    assert diagnostic =~ "installation destination parent is not one physical directory"

    assert {:error, diagnostic} = installation_proposal_override_result(fixture, absent)
    assert diagnostic =~ "caller-selected installation proposal authority"

    dirty = milestone_fixture!("dirty-proposal-authority")
    dirty_destination = Path.join(physical_dir!(Path.dirname(dirty.repo)), "dirty-proposal")
    File.write!(Path.join(dirty.repo, "untracked-proposal-dirt"), "dirty\n")
    assert {:error, diagnostic} = installation_proposal_result(dirty, dirty_destination)
    assert diagnostic =~ "repository is not clean"
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "fresh exact approval atomically installs and authenticated rollback restores predecessor" do
    fixture = milestone_fixture!("approved-install")
    root = physical_dir!(Path.dirname(fixture.repo))
    destination = Path.join(root, "approved-install-destination")
    File.write!(destination, "prior approved executable\n")
    File.chmod!(destination, 0o500)

    assert {:ok, result} = installation_lifecycle_result(fixture, destination, "approve")
    assert result["approval"]["proposal_digest"] == result["proposal"]["proposal_digest"]
    assert result["installation"]["approval_digest"] == result["approval"]["approval_digest"]
    assert result["authenticated"]["receipt"]["status"] == "installed"
    assert result["rollback"]["status"] == "rolled_back"
    assert File.read!(destination) == "prior approved executable\n"

    rejected = milestone_fixture!("rejected-install-approval")

    rejected_destination =
      Path.join(physical_dir!(Path.dirname(rejected.repo)), "rejected-destination")

    assert {:error, diagnostic} =
             installation_lifecycle_result(rejected, rejected_destination, "wrong")

    assert diagnostic =~ "fresh exact installation approval statement is missing"
    refute File.exists?(rejected_destination)

    tampered = milestone_fixture!("tampered-install-proposal")

    tampered_destination =
      Path.join(physical_dir!(Path.dirname(tampered.repo)), "tampered-destination")

    assert {:error, diagnostic} =
             installation_lifecycle_result(tampered, tampered_destination, "tamper")

    assert diagnostic =~ "installation proposal authentication failed"
    refute File.exists?(tampered_destination)
  end

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
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

  @tag :phase_165_hostile
  @tag :phase_165_controlled_host
  test "installed verifier rejects a symlink even when its target bytes are approved" do
    fixture = milestone_fixture!("installed-symlink")
    root = physical_dir!(Path.dirname(fixture.repo))
    installed = Path.join(root, "approved-loader")
    symlink = Path.join(root, "linked-loader")
    File.write!(installed, File.read!(@loader))
    File.chmod!(installed, 0o500)
    File.ln_s!(installed, symlink)

    assert {:error, diagnostic} = installed_verification_result(fixture, symlink)
    assert diagnostic =~ "installed executable is not one physical regular file"
  end

  @tag :phase_165_tag_omission_fixture
  test "runbook tag omission restores exact config bytes and fails closed at each seam" do
    section = runbook_tag_omission_section!()

    success = tag_omission_fixture!("success")
    {preview_output, 0} = run_tag_omission(success, section, ["preview"])
    [_, approved_sha] = Regex.run(~r/approved_preview_sha256=([0-9a-f]{64})/, preview_output)
    assert File.read!(success.config) == success.original

    assert {output, 0} = run_tag_omission(success, section, ["confirm", approved_sha])
    assert output =~ "canonical archive confirmed"
    assert File.read!(success.config) == success.original
    assert File.read!(success.log) =~ "--confirm"

    initialization = tag_omission_fixture!("initialization-failure")

    assert {output, status} =
             run_tag_omission(initialization, section, ["preview"], %{"STUB_INIT_FAIL" => "1"})

    assert status != 0
    assert output =~ "init.complete-milestone failed"
    assert File.read!(initialization.config) == initialization.original
    refute File.read!(initialization.log) =~ "--confirm"

    archive = tag_omission_fixture!("archive-failure")
    {preview_output, 0} = run_tag_omission(archive, section, ["preview"])
    [_, approved_sha] = Regex.run(~r/approved_preview_sha256=([0-9a-f]{64})/, preview_output)

    assert {output, status} =
             run_tag_omission(archive, section, ["confirm", approved_sha], %{
               "STUB_ARCHIVE_FAIL" => "1"
             })

    assert status != 0
    assert output =~ "canonical archive confirmation failed"
    assert File.read!(archive.config) == archive.original

    restoration = tag_omission_fixture!("restoration-failure")
    {preview_output, 0} = run_tag_omission(restoration, section, ["preview"])
    [_, approved_sha] = Regex.run(~r/approved_preview_sha256=([0-9a-f]{64})/, preview_output)

    assert {output, status} =
             run_tag_omission(restoration, section, ["confirm", approved_sha], %{
               "PHASE_165_RESTORE_COMMAND" => restoration.restore,
               "STUB_RESTORE_FAIL" => "1"
             })

    assert status != 0
    assert output =~ "configured restoration command failed"
    assert File.read!(restoration.config) == restoration.original
    refute File.read!(restoration.log) =~ "--confirm"

    after_confirm = tag_omission_fixture!("restoration-failure-after-confirm")
    {preview_output, 0} = run_tag_omission(after_confirm, section, ["preview"])
    [_, approved_sha] = Regex.run(~r/approved_preview_sha256=([0-9a-f]{64})/, preview_output)

    assert {output, status} =
             run_tag_omission(after_confirm, section, ["confirm", approved_sha], %{
               "PHASE_165_RESTORE_COMMAND" => after_confirm.restore,
               "STUB_RESTORE_FAIL_AFTER" => "2",
               "STUB_RESTORE_COUNTER" => after_confirm.restore_counter
             })

    assert status != 0
    assert output =~ "configured restoration command failed"
    assert File.read!(after_confirm.config) == after_confirm.original
    assert File.read!(after_confirm.log) =~ "--confirm"

    false_success = tag_omission_fixture!("restoration-false-success")

    assert {output, status} =
             run_tag_omission(false_success, section, ["preview"], %{
               "PHASE_165_RESTORE_COMMAND" => false_success.restore,
               "STUB_RESTORE_FALSE_SUCCESS" => "1"
             })

    assert status != 0
    assert output =~ "returned success with wrong bytes"
    assert File.read!(false_success.config) == false_success.original
    refute File.read!(false_success.log) =~ "--confirm"

    false_success_after = tag_omission_fixture!("restoration-false-success-after-confirm")
    {preview_output, 0} = run_tag_omission(false_success_after, section, ["preview"])
    [_, approved_sha] = Regex.run(~r/approved_preview_sha256=([0-9a-f]{64})/, preview_output)

    assert {output, status} =
             run_tag_omission(false_success_after, section, ["confirm", approved_sha], %{
               "PHASE_165_RESTORE_COMMAND" => false_success_after.restore,
               "STUB_RESTORE_FALSE_SUCCESS_AFTER" => "2",
               "STUB_RESTORE_COUNTER" => false_success_after.restore_counter
             })

    assert status != 0
    assert output =~ "returned success with wrong bytes"
    assert File.read!(false_success_after.config) == false_success_after.original
    assert File.read!(false_success_after.log) =~ "--confirm"
  end

  describe "installed milestone production boundary" do
    @describetag :phase_165_installed_production_boundary

    test "installed command proves exact path, kind, mode, owner, bytes, and runtime closure" do
      assert {:ok, stat} = File.lstat(@installed_loader)
      assert stat.type == :regular
      assert Bitwise.band(stat.mode, 0o777) == 0o500

      authority_oid = git!(@repo_root, ["rev-parse", "HEAD"]) |> String.trim()

      assert {output, 0} =
               System.cmd(
                 @installed_loader,
                 ["--self-check", "--repo", @repo_root, "--expected-source-oid", authority_oid],
                 stderr_to_stdout: true
               )

      assert output =~ "executable=#{@installed_loader}"
      assert output =~ "loader_sha256="
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
      milestone: v2.7
      audited: 2026-09-13T00:00:00Z
      status: passed
      scores:
        requirements: 16/16
        phases: 5/5
        integration: 16/16
        flows: 5/5
      gaps:
        requirements: []
        integration: []
        flows: []
      nyquist:
        compliant_phases: [161, 162, 163, 164, 165]
        partial_phases: []
        not_validated_phases: []
        missing_phases: []
        overall: compliant
      tech_debt:
        - phase: milestone
          items:
            - Repository hygiene remains policy-blocked by 14 open PRs.
      ---
      Canonical audit workflow output fixture.
      """
    )

    write!(
      repo,
      ".planning/MILESTONES.md",
      "## v2.7 Repository Stewardship & Operational Hygiene (Completed: 2026-09-13)\n"
    )

    write!(
      repo,
      ".planning/ROADMAP.md",
      "- ✅ **v2.7 Repository Stewardship & Operational Hygiene** — Phases 161-165 (shipped 2026-09-13) — [archive](milestones/v2.7-ROADMAP.md)\n"
    )

    write!(
      repo,
      ".planning/RETROSPECTIVE.md",
      "# Retrospective: mailglass\n\n## Milestone: v2.7 — Repository Stewardship & Operational Hygiene\n"
    )

    write!(
      repo,
      ".planning/PROJECT.md",
      "## Completed Milestone: v2.7 Repository Stewardship & Operational Hygiene\n\nThe 14 open PRs remain disclosed accepted repository-hygiene policy debt.\n"
    )

    write!(
      repo,
      ".planning/STATE.md",
      "---\nmilestone: v2.7\nstatus: archived\n---\n\nRepository hygiene remains policy-blocked by 14 open PRs as accepted operational debt.\n"
    )

    # Canonical GSD state-contract shape (frozen key set, empty live-phase list after
    # archival) -- deliberately NOT a hand-written {"status":"archived"} stub, which no
    # publisher emits and which previously made this lane green against fiction.
    write!(
      repo,
      ".planning/state.json",
      ~s({"contract":"1.0.0","flavor":"core","milestone":"v2.7","phases":[],"next":{"command":"/gsd:new-milestone"},"updated_at":"2026-09-15T00:00:00.000Z"}\n)
    )

    for phase <- 161..165 do
      slug = "#{phase}-fixture"

      write!(
        repo,
        ".planning/milestones/v2.7-phases/#{slug}/#{phase}-VALIDATION.md",
        "---\nstatus: validated\nnyquist_compliant: true\nwave_0_complete: true\n---\n"
      )

      write!(
        repo,
        ".planning/milestones/v2.7-phases/#{slug}/#{phase}-SUMMARY.md",
        "---\nstatus: complete\n---\n"
      )
    end

    git!(repo, ["add", "."])
    git!(repo, ["commit", "-q", "-m", "canonical v2.7 audit fixture"])
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

    loader_url =
      "file://#{Path.join(fixture.repo, "scripts/mailglass_finalize_milestone_loader.mjs")}"

    git!(fixture.repo, ["update-ref", "refs/remotes/origin/main", fixture.oid])

    script = """
    import { buildInstallationProposal } from #{Jason.encode!(loader_url)};
    const proposal = buildInstallationProposal({
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

  defp installation_lifecycle_result(fixture, destination, mode) do
    node = System.find_executable("node") || flunk("node executable is required")

    loader_url =
      "file://#{Path.join(fixture.repo, "scripts/mailglass_finalize_milestone_loader.mjs")}"

    control = Path.join(physical_dir!(Path.dirname(fixture.repo)), "install-control-#{mode}")
    proposal_path = Path.join(control, "proposal.json")
    approval_path = Path.join(control, "approval.json")
    installation_path = Path.join(control, "installation.json")
    rollback_path = Path.join(control, "rollback.json")
    git!(fixture.repo, ["update-ref", "refs/remotes/origin/main", fixture.oid])

    script = """
    import {
      authenticateApprovedInstallation,
      installApprovedExecutable,
      recordInstallationApproval,
      rollbackApprovedInstallation,
      writeInstallationProposal
    } from #{Jason.encode!(loader_url)};
    import { chmodSync, readFileSync, writeFileSync } from "node:fs";
    const proposal = writeInstallationProposal({
      destination: #{Jason.encode!(destination)},
      outputPath: #{Jason.encode!(proposal_path)}
    });
    const statement = #{Jason.encode!(mode)} === "wrong"
      ? "not approved"
      : `approve exact mailglass-finalize-milestone installation ${proposal.proposal_digest}`;
    const approval = recordInstallationApproval({
      proposalPath: #{Jason.encode!(proposal_path)},
      approvalPath: #{Jason.encode!(approval_path)},
      proposalDigest: proposal.proposal_digest,
      approvalStatement: statement
    });
    if (#{Jason.encode!(mode)} === "tamper") {
      const changed = JSON.parse(readFileSync(#{Jason.encode!(proposal_path)}, "utf8"));
      changed.source_sha256 = "f".repeat(64);
      chmodSync(#{Jason.encode!(proposal_path)}, 0o600);
      writeFileSync(#{Jason.encode!(proposal_path)}, JSON.stringify(changed));
      chmodSync(#{Jason.encode!(proposal_path)}, 0o400);
    }
    const installation = installApprovedExecutable({
      proposalPath: #{Jason.encode!(proposal_path)},
      approvalPath: #{Jason.encode!(approval_path)},
      installationReceiptPath: #{Jason.encode!(installation_path)},
      proposalDigest: proposal.proposal_digest
    });
    const authenticated = authenticateApprovedInstallation({
      proposalPath: #{Jason.encode!(proposal_path)},
      approvalPath: #{Jason.encode!(approval_path)},
      installationReceiptPath: #{Jason.encode!(installation_path)},
      proposalDigest: proposal.proposal_digest
    });
    const rollback = rollbackApprovedInstallation({
      proposalPath: #{Jason.encode!(proposal_path)},
      approvalPath: #{Jason.encode!(approval_path)},
      installationReceiptPath: #{Jason.encode!(installation_path)},
      rollbackReceiptPath: #{Jason.encode!(rollback_path)},
      proposalDigest: proposal.proposal_digest
    });
    console.log(JSON.stringify({proposal, approval, installation, authenticated, rollback}));
    """

    case System.cmd(node, ["--input-type=module", "--eval", script],
           cd: @repo_root,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, output |> String.trim() |> Jason.decode!()}
      {output, _status} -> {:error, output}
    end
  end

  defp installation_proposal_override_result(fixture, destination) do
    node = System.find_executable("node") || flunk("node executable is required")

    loader_url =
      "file://#{Path.join(fixture.repo, "scripts/mailglass_finalize_milestone_loader.mjs")}"

    script = """
    import { buildInstallationProposal } from #{Jason.encode!(loader_url)};
    buildInstallationProposal({
      repo: #{Jason.encode!(fixture.repo)},
      authorityOid: #{Jason.encode!(fixture.oid)},
      destination: #{Jason.encode!(destination)}
    });
    """

    case System.cmd(node, ["--input-type=module", "--eval", script],
           cd: @repo_root,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, output}
      {output, _status} -> {:error, output}
    end
  end

  defp installed_verification_result(fixture, executable) do
    node = System.find_executable("node") || flunk("node executable is required")
    loader_url = "file://#{@loader}"

    script = """
    import { verifyInstalledExecutable } from #{Jason.encode!(loader_url)};
    const evidence = verifyInstalledExecutable({
      repo: #{Jason.encode!(fixture.repo)},
      expectedSourceOid: #{Jason.encode!(fixture.oid)},
      executable: #{Jason.encode!(executable)}
    });
    console.log(JSON.stringify(evidence));
    """

    case System.cmd(node, ["--input-type=module", "--eval", script],
           cd: @repo_root,
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, output |> String.trim() |> Jason.decode!()}
      {output, _status} -> {:error, output}
    end
  end

  defp physical_dir!(path) do
    case System.cmd("/bin/pwd", ["-P"], cd: path, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      {output, status} -> flunk("could not resolve physical fixture path (#{status}): #{output}")
    end
  end

  defp finalization_runbook! do
    case Enum.filter(@finalization_runbook_candidates, &File.regular?/1) do
      [path] ->
        path

      [] ->
        flunk(
          "165-FINALIZATION.md is missing from both the live phase directory and the v2.7 archive"
        )

      many ->
        flunk("165-FINALIZATION.md is ambiguous — present at #{Enum.join(many, " and ")}")
    end
  end

  defp runbook_tag_omission_section! do
    source = File.read!(finalization_runbook!())

    case Regex.run(
           ~r/^# phase165:tag-omission:start\n(?<section>.*?)^# phase165:tag-omission:end$/ms,
           source,
           capture: ["section"]
         ) do
      [section] -> section
      _ -> flunk("stable tag-omission runbook markers are missing or ambiguous")
    end
  end

  defp tag_omission_fixture!(name) do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-phase-165-tag-omission-#{name}-#{System.unique_integer([:positive])}"
      )

    repo = Path.join(root, "repo")
    config = Path.join(repo, ".planning/config.json")
    log = Path.join(root, "gsd.log")
    stub = Path.join(root, "gsd-stub")
    restore = Path.join(root, "restore-stub")
    restore_counter = Path.join(root, "restore-counter")
    File.mkdir_p!(Path.dirname(config))
    original = ~s({"mode":"yolo","git":{"branching_strategy":"none"}}\n)
    File.write!(config, original)
    on_exit(fn -> File.rm_rf!(root) end)

    File.write!(
      stub,
      """
      #!/bin/bash
      set -eu
      printf '%s\\n' "$*" >> "$STUB_LOG"
      /usr/bin/jq -e '.git.create_tag == false' "$PHASE_165_REPO/.planning/config.json" >/dev/null
      if [ "$*" = "query init.complete-milestone" ]; then
        [ "${STUB_INIT_FAIL:-0}" != 1 ] || exit 71
        printf '%s\\n' '{"section_manifest":{"included":["archive"],"excluded":["git-tag"]}}'
      elif [[ "$*" == *"--dry-run"* ]]; then
        printf '%s\\n' '{"dry_run":true,"version":"v2.7","would_archive":{"audit":{"source":".planning/v2.7-MILESTONE-AUDIT.md","target":".planning/milestones/v2.7-MILESTONE-AUDIT.md"},"phases":["161-a","162-b","163-c","164-d","165-e"],"phases_archive_skipped":false,"quick":[]}}'
      elif [[ "$*" == *"--confirm"* ]]; then
        [ "${STUB_ARCHIVE_FAIL:-0}" != 1 ] || exit 72
        printf '%s\\n' '{"version":"v2.7","archived":{"roadmap":true,"requirements":true,"audit":true,"phases":true,"phases_archive_skipped":false,"quick":false}}'
      else
        exit 73
      fi
      """
    )

    File.write!(
      restore,
      """
      #!/bin/bash
      set -eu
      if [ -n "${STUB_RESTORE_COUNTER:-}" ]; then
        count=0
        [ ! -f "$STUB_RESTORE_COUNTER" ] || count=$(cat "$STUB_RESTORE_COUNTER")
        count=$((count + 1))
        printf '%s\n' "$count" > "$STUB_RESTORE_COUNTER"
        [ -z "${STUB_RESTORE_FAIL_AFTER:-}" ] || [ "$count" -lt "$STUB_RESTORE_FAIL_AFTER" ] || exit 75
      fi
      [ "${STUB_RESTORE_FAIL:-0}" != 1 ] || exit 74
      if [ "${STUB_RESTORE_FALSE_SUCCESS:-0}" = 1 ]; then
        printf '%s\n' '{"wrong":true}' > "$2"
        exit 0
      fi
      if [ -n "${STUB_RESTORE_FALSE_SUCCESS_AFTER:-}" ] &&
         [ "$count" -ge "$STUB_RESTORE_FALSE_SUCCESS_AFTER" ]; then
        printf '%s\n' '{"wrong":true}' > "$2"
        exit 0
      fi
      cp -- "$1" "$2"
      """
    )

    File.chmod!(stub, 0o700)
    File.chmod!(restore, 0o700)
    File.write!(log, "")

    %{
      repo: repo,
      config: config,
      original: original,
      log: log,
      stub: stub,
      restore: restore,
      restore_counter: restore_counter
    }
  end

  defp run_tag_omission(fixture, section, args, overrides \\ %{}) do
    script = section <> "\nphase_165_complete_milestone_without_tag \"$@\"\n"
    script_path = Path.join(Path.dirname(fixture.repo), "run-section.sh")
    File.write!(script_path, script)

    env =
      %{
        "PHASE_165_GSD_RUN" => fixture.stub,
        "PHASE_165_REPO" => fixture.repo,
        "STUB_LOG" => fixture.log
      }
      |> Map.merge(overrides)
      |> Map.to_list()

    System.cmd("/bin/bash", [script_path | args],
      cd: fixture.repo,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_fixture(fixture, overrides \\ %{}, process_env \\ []) do
    node = System.find_executable("node") || flunk("node executable is required")
    fixture_loader_url = "file://#{@fixture_loader}"

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
    import { runFixtureFinalization } from #{Jason.encode!(fixture_loader_url)};
    const result = runFixtureFinalization(#{Jason.encode!(options)});
    console.log(result.output);
    """

    System.cmd(node, ["--input-type=module", "--eval", script],
      cd: @repo_root,
      env: process_env,
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
