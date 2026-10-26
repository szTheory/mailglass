defmodule Mailglass.Scripts.PublishCiSelfHealTest do
  # Executes `ensure-live-ci-runs`' github-script body under Node against a fake
  # Actions API. Evidence: publish run 40379381910 blocked at gate-ci-green because
  # the tag SHA (f2c91e40, a `.planning`-only commit) had a ci.yml push run whose
  # required lanes were all path-skipped, and the self-heal only dispatched when NO
  # run existed. A skipped or cancelled run must now be treated like "no run".
  use ExUnit.Case, async: true

  @publish_path Path.expand("../../.github/workflows/publish-hex.yml", __DIR__)
  @step "Ensure completed ci.yml and advisory-matrix.yml runs exist on protected SHA"

  @ci_lanes [
    "Support Contract Core (Elixir 1.18 / OTP 27)",
    "Support Contract Admin (Elixir 1.18 / OTP 27)",
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
    "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
    "Installer Host Smoke",
    "Hex Audit (Elixir 1.18 / OTP 27)",
    "Deps Audit (Elixir 1.18 / OTP 27)",
    "Mix Task Tests (Elixir 1.18 / OTP 27)"
  ]
  @am_lanes [
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema public)",
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
  ]

  # Fake Actions API + virtual clock. Runs are newest-first per workflow; a
  # dispatch prepends the scenario's `on_dispatch` run for that workflow.
  @harness ~S"""
  const fs = require('fs');
  const [scriptPath, scenarioPath] = process.argv.slice(2);
  const script = fs.readFileSync(scriptPath, 'utf8');
  const sc = JSON.parse(fs.readFileSync(scenarioPath, 'utf8'));
  let clock = Date.parse('2026-10-26T18:00:00Z');
  const FakeDate = { now: () => clock, parse: (s) => Date.parse(s) };
  const fakeSetTimeout = (fn, ms) => { clock += ms; fn(); };
  const out = { dispatches: [], failed: null, warnings: [] };
  let nextId = 900;
  const runs = sc.runs;
  const jobs = {};
  for (const wf of Object.keys(runs)) for (const r of runs[wf]) jobs[r.id] = r.jobs;
  const github = {
    rest: { actions: {
      listWorkflowRuns: async ({ workflow_id }) => {
        const list = (runs[workflow_id] || []).map((r) => ({ ...r }));
        return { data: { total_count: list.length, workflow_runs: list } };
      },
      listJobsForWorkflowRun: async () => { throw new Error('use paginate'); },
      createWorkflowDispatch: async ({ workflow_id, ref }) => {
        out.dispatches.push(`${workflow_id}@${ref}`);
        const tpl = (sc.on_dispatch || {})[workflow_id];
        if (tpl) {
          const run = { ...tpl, id: nextId++, event: 'workflow_dispatch',
                        created_at: new Date(clock).toISOString() };
          jobs[run.id] = tpl.jobs;
          runs[workflow_id] = [run, ...(runs[workflow_id] || [])];
        }
      }
    } },
    paginate: async (_fn, { run_id }) => (jobs[run_id] || []).map((j) => ({ ...j }))
  };
  const core = {
    info: () => {},
    warning: (m) => out.warnings.push(m),
    setFailed: (m) => { out.failed = m; },
    setOutput: () => {}
  };
  const context = { eventName: 'workflow_dispatch', repo: { owner: 'o', repo: 'r' } };
  const env = { RESOLVED_SHA: 'a'.repeat(40), RESOLVED_REF: 'v9.9.9', CANDIDATE_DIGEST: 'd',
                RELEASE_TAG: 'v9.9.9', USE_CONTROL_SHA_FOR_CI_RECOVERY: 'false',
                SKIP_CORE_FULL_SUITE_GATE: 'false' };
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
  const body = new AsyncFunction('github', 'context', 'core', 'process', 'setTimeout', 'Date', script);
  body(github, context, core, { env }, fakeSetTimeout, FakeDate)
    .then(() => { process.stdout.write(JSON.stringify(out)); })
    .catch((e) => { process.stderr.write(String(e.stack)); process.exit(2); });
  """

  setup do
    node = System.find_executable("node")
    if is_nil(node), do: flunk("node is required to execute the github-script body")

    dir = Path.join(System.tmp_dir!(), "self-heal-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    File.write!(Path.join(dir, "harness.cjs"), @harness)
    %{node: node, dir: dir, script: step_script!(File.read!(@publish_path))}
  end

  test "path-skipped required lanes are dispatched once on the tag and the fresh run is awaited",
       ctx do
    result = run(ctx, ctx.script, scenario(ci: run_with(@ci_lanes, "skipped")))

    assert result["dispatches"] == ["ci.yml@v9.9.9"]
    assert result["failed"] == nil
    assert Enum.any?(result["warnings"], &(&1 =~ "did not run its gating lane(s)"))
  end

  test "a cancelled run is re-dispatched; usable runs dispatch nothing", ctx do
    cancelled = %{run_with(@ci_lanes, "success") | "conclusion" => "cancelled"}
    assert run(ctx, ctx.script, scenario(ci: cancelled))["dispatches"] == ["ci.yml@v9.9.9"]

    result = run(ctx, ctx.script, scenario([]))
    assert result["dispatches"] == []
    assert result["failed"] == nil
  end

  test "skipped advisory-matrix gating legs are re-dispatched too", ctx do
    result = run(ctx, ctx.script, scenario(am: run_with(@am_lanes, "skipped")))
    assert result["dispatches"] == ["advisory-matrix.yml@v9.9.9"]
  end

  test "a failed required lane is a verdict, never re-dispatched", ctx do
    red = run_with(@ci_lanes, "success", %{"Installer Host Smoke" => "failure"})
    result = run(ctx, ctx.script, scenario(ci: red))

    assert result["dispatches"] == []
    assert result["failed"] == nil
  end

  test "an unusable self-heal run is handed to the gate, not re-dispatched in a loop", ctx do
    result =
      run(
        ctx,
        ctx.script,
        scenario(
          ci: run_with(@ci_lanes, "skipped"),
          on_dispatch: %{"ci.yml" => run_with(@ci_lanes, "skipped")}
        )
      )

    assert result["dispatches"] == ["ci.yml@v9.9.9"]
    assert result["failed"] == nil
    assert Enum.any?(result["warnings"], &(&1 =~ "the self-heal run is unusable too"))
  end

  test "a dispatched run that never appears fails closed at the deadline", ctx do
    result =
      run(ctx, ctx.script, scenario(ci: run_with(@ci_lanes, "skipped"), on_dispatch: %{}))

    assert result["dispatches"] == ["ci.yml@v9.9.9"]
    assert result["failed"] =~ "Delivery blocked: no completed, usable run of ci.yml"
  end

  test "negative control: the pre-fix absence-only self-heal ignores skipped lanes", ctx do
    absence_only =
      String.replace(
        ctx.script,
        "return !job || job.conclusion === 'skipped' || job.conclusion === 'cancelled';",
        "return !job;"
      )

    refute absence_only == ctx.script
    result = run(ctx, absence_only, scenario(ci: run_with(@ci_lanes, "skipped")))
    assert result["dispatches"] == []
  end

  test "self-heal lane lists equal the gate's REQUIRED_LANES and Core Full Suite gating legs" do
    source = File.read!(@publish_path)
    script = step_script!(source)

    assert js_strings(script, "'ci.yml': [") == js_strings(source, "const REQUIRED_LANES = [")

    assert js_strings(script, "'advisory-matrix.yml': [") ==
             js_strings(source, "const ADVISORY_MATRIX_GATING_LANES = [")

    assert MapSet.new(js_strings(script, "'ci.yml': [")) == MapSet.new(@ci_lanes)
  end

  defp scenario(opts) do
    %{
      "runs" => %{
        "ci.yml" => [Keyword.get(opts, :ci, run_with(@ci_lanes, "success"))],
        "advisory-matrix.yml" => [Keyword.get(opts, :am, run_with(@am_lanes, "success"))]
      },
      "on_dispatch" =>
        Keyword.get(opts, :on_dispatch, %{
          "ci.yml" => run_with(@ci_lanes, "success"),
          "advisory-matrix.yml" => run_with(@am_lanes, "success")
        })
    }
  end

  defp run_with(lanes, conclusion, overrides \\ %{}) do
    %{
      "id" => System.unique_integer([:positive]),
      "event" => "push",
      "status" => "completed",
      "conclusion" => "success",
      "created_at" => "2026-10-26T17:00:00Z",
      "html_url" => "https://example.invalid/run",
      "jobs" =>
        Enum.map(lanes, fn lane ->
          %{"name" => lane, "conclusion" => Map.get(overrides, lane, conclusion)}
        end)
    }
  end

  defp run(ctx, script, scenario) do
    script_path = Path.join(ctx.dir, "script-#{System.unique_integer([:positive])}.js")
    scenario_path = Path.join(ctx.dir, "scenario-#{System.unique_integer([:positive])}.json")
    File.write!(script_path, script)
    File.write!(scenario_path, Jason.encode!(scenario))

    {out, status} =
      System.cmd(ctx.node, [Path.join(ctx.dir, "harness.cjs"), script_path, scenario_path],
        stderr_to_stdout: true
      )

    assert status == 0, out
    Jason.decode!(out)
  end

  defp step_script!(source) do
    [_, after_name] = String.split(source, "- name: #{@step}\n", parts: 2)
    [_, after_script] = String.split(after_name, "          script: |\n", parts: 2)

    after_script
    |> String.split("\n")
    |> Enum.take_while(&(&1 == "" or String.starts_with?(&1, "            ")))
    |> Enum.map_join("\n", &String.replace_prefix(&1, "            ", ""))
  end

  defp js_strings(source, opener) do
    [_, rest] = String.split(source, opener, parts: 2)
    [chunk | _] = String.split(rest, "]", parts: 2)
    Regex.scan(~r/'([^']*)'/, chunk, capture: :all_but_first) |> List.flatten()
  end
end
