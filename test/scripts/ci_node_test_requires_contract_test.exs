defmodule Mailglass.Scripts.CiNodeTestRequiresContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @guard_path Path.join(@repo_root, "test_js/support/ci-require-guard.cjs")

  setup do
    node =
      System.find_executable("node") ||
        flunk("node is required to run the ci.yml node --test resolvability contract")

    dir =
      Path.join(System.tmp_dir!(), "ci-node-require-guard-#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    %{node: node, dir: dir}
  end

  test "every ci.yml node --test file loads with only the packages its job installed earlier",
       ctx do
    ci = File.read!(@ci_path)
    steps = node_test_steps(ci)

    assert length(steps) >= 3,
           "expected at least three ci.yml node --test steps, found #{length(steps)}"

    demo_step =
      Enum.find(
        steps,
        &(&1.job == "demo_browser_evidence" and String.contains?(&1.name, "Storybook evidence"))
      )

    assert demo_step, "demo_browser_evidence Storybook node --test step was not parsed"

    assert demo_step.allowed_roots == [],
           "Demo's audit step installs nothing and must not create an allowed root"

    assert "mailglass_admin/e2e/support/storybook-axe.test.cjs" in demo_step.files

    operator_step =
      Enum.find(
        steps,
        &(&1.job == "operator_browser_gate" and String.contains?(&1.name, "CI monitor"))
      )

    assert operator_step, "operator_browser_gate CI monitor node --test step was not parsed"

    assert operator_step.allowed_roots == [],
           "the monitor test runs before npm ci and must have no allowed root"

    for step <- steps do
      result = run_load_only(ctx.node, step.files, step.allowed_roots)
      violations = Enum.filter(result.records, &String.starts_with?(&1, "violation\t"))

      missing_loaded =
        Enum.reject(step.files, fn file ->
          absolute_file = Path.expand(file, @repo_root)
          Enum.any?(result.records, &(&1 == "loaded\t#{absolute_file}"))
        end)

      detail =
        [
          "job #{step.job}, step #{step.name}, files #{Enum.join(step.files, ", ")}",
          "exit: #{result.status}",
          "violations: #{Enum.join(violations, "; ")}",
          "output: #{result.output}"
        ]
        |> Enum.join("\n")

      assert result.status == 0, detail
      assert violations == [], detail

      assert missing_loaded == [],
             "#{detail}\nmissing loaded records for #{Enum.join(missing_loaded, ", ")}"
    end
  end

  test "guard rejects a top-level package require outside allowed roots", ctx do
    {fixture, _package_root} = write_package_fixture(ctx.dir, "top-level")
    result = run_load_only(ctx.node, [fixture], [])
    violation = Enum.find(result.records, &String.starts_with?(&1, "violation\t"))

    assert result.status != 0, result.output
    assert violation =~ "\tmailglass-guard-fixture-pkg\t"
    assert violation =~ fixture
    assert "loaded\t#{fixture}" in result.records
  end

  test "guard permits a top-level package require inside an allowed root", ctx do
    {fixture, package_root} = write_package_fixture(ctx.dir, "allowed-root")
    result = run_load_only(ctx.node, [fixture], [package_root])

    assert result.status == 0, result.output
    assert Enum.reject(result.records, &String.starts_with?(&1, "violation\t")) == result.records
    assert "loaded\t#{fixture}" in result.records
  end

  test "guard permits an unused lazy package require outside allowed roots", ctx do
    {fixture, _package_root} = write_package_fixture(ctx.dir, "lazy-require")

    File.write!(
      fixture,
      "const test = require(\"node:test\");\n" <>
        "function loadFixture() { return require(\"mailglass-guard-fixture-pkg\"); }\n" <>
        "test(\"guard no-match fixture\", () => {});\n"
    )

    result = run_load_only(ctx.node, [fixture], [])

    assert result.status == 0, result.output
    assert Enum.reject(result.records, &String.starts_with?(&1, "violation\t")) == result.records
    assert "loaded\t#{fixture}" in result.records
  end

  defp write_package_fixture(dir, name) do
    package_root = Path.join(dir, name)
    package_dir = Path.join([package_root, "node_modules", "mailglass-guard-fixture-pkg"])
    File.mkdir_p!(package_dir)
    File.write!(Path.join(package_dir, "index.js"), "module.exports = \"fixture\";\n")

    fixture = Path.join(package_root, "#{name}.test.cjs")

    File.write!(
      fixture,
      "const test = require(\"node:test\");\n" <>
        "require(\"mailglass-guard-fixture-pkg\");\n" <>
        "test(\"guard no-match fixture\", () => {});\n"
    )

    {fixture, package_root}
  end

  defp node_test_steps(ci) do
    jobs_text =
      case String.split(ci, "\njobs:\n", parts: 2) do
        [_, jobs] -> jobs
        _ -> flunk("could not find the jobs section in .github/workflows/ci.yml")
      end

    jobs_text
    |> String.split("\n")
    |> Enum.reduce({nil, [], []}, fn line, {job, lines, jobs} ->
      case Regex.run(~r/^  ([a-zA-Z0-9_-]+):\s*$/, line) do
        [_, job_id] ->
          jobs = if job, do: [{job, Enum.reverse(lines)} | jobs], else: jobs
          {job_id, [], jobs}

        _ ->
          {job, [line | lines], jobs}
      end
    end)
    |> then(fn {job, lines, jobs} ->
      jobs = if job, do: [{job, Enum.reverse(lines)} | jobs], else: jobs
      Enum.reverse(jobs)
    end)
    |> Enum.flat_map(fn {job_id, job_lines} ->
      job_lines
      |> step_chunks()
      |> Enum.reduce({[], []}, fn step, {install_roots, node_steps} ->
        roots_before_step = Enum.reverse(install_roots)

        node_steps =
          case node_test_files(step.run) do
            [] ->
              node_steps

            files ->
              [
                %{job: job_id, name: step.name, files: files, allowed_roots: roots_before_step}
                | node_steps
              ]
          end

        new_roots = npm_install_roots(step.run, step.working_directory)
        {Enum.reverse(new_roots) ++ install_roots, node_steps}
      end)
      |> elem(1)
    end)
    |> Enum.reverse()
  end

  defp step_chunks(job_lines) do
    case Enum.find_index(job_lines, &(&1 == "    steps:")) do
      nil ->
        []

      index ->
        job_lines
        |> Enum.drop(index + 1)
        |> Enum.reduce({[], []}, fn line, {current, steps} ->
          if String.starts_with?(line, "      - ") do
            steps = if current == [], do: steps, else: [Enum.reverse(current) | steps]
            {[line], steps}
          else
            if current == [], do: {current, steps}, else: {[line | current], steps}
          end
        end)
        |> then(fn {current, steps} ->
          steps = if current == [], do: steps, else: [Enum.reverse(current) | steps]
          Enum.reverse(steps)
        end)
        |> Enum.map(&parse_step/1)
    end
  end

  defp parse_step(lines) do
    name =
      case Enum.find_value(lines, &Regex.run(~r/^      - name:\s*(.+)$/, &1)) do
        [_, value] -> value
        _ -> "(unnamed step)"
      end

    working_directory =
      case Enum.find_value(lines, &Regex.run(~r/^        working-directory:\s*(\S+)\s*$/, &1)) do
        [_, value] -> Path.expand(value, @repo_root)
        _ -> @repo_root
      end

    run =
      case Enum.find_index(lines, &String.starts_with?(&1, "        run:")) do
        nil ->
          ""

        index ->
          line = Enum.at(lines, index)
          value = line |> String.split("run:", parts: 2) |> List.last() |> String.trim()

          if value in ["|", ">", "|-", ">-"] do
            lines
            |> Enum.drop(index + 1)
            |> Enum.take_while(&(&1 == "" or String.starts_with?(&1, "          ")))
            |> Enum.map(&String.trim/1)
            |> Enum.join(" ")
          else
            value
          end
      end

    %{name: name, run: run, working_directory: working_directory}
  end

  defp node_test_files(run) do
    run
    |> command_segments()
    |> Enum.find_value([], fn command ->
      tokens = String.split(command, ~r/\s+/, trim: true)

      if Enum.member?(tokens, "--test") and
           Enum.any?(tokens, &(&1 == "node" or String.ends_with?(&1, "/node"))) do
        tokens
        |> Enum.drop_while(&(&1 != "--test"))
        |> Enum.drop(1)
        |> Enum.take_while(&(&1 not in ["&&", ";", "|"]))
        |> Enum.reject(&String.starts_with?(&1, "-"))
      else
        nil
      end
    end)
  end

  defp npm_install_roots(run, working_directory) do
    run
    |> command_segments()
    |> Enum.flat_map(&npm_install_roots_for_command(&1, working_directory))
  end

  defp npm_install_roots_for_command(command, working_directory) do
    tokens = String.split(command, ~r/\s+/, trim: true)

    case Enum.find_index(tokens, &(&1 == "npm" or String.ends_with?(&1, "/npm"))) do
      nil ->
        []

      npm_index ->
        npm_install_root(Enum.drop(tokens, npm_index + 1), working_directory)
    end
  end

  defp npm_install_root(args, working_directory) do
    if Enum.any?(args, &(&1 in ["ci", "install"])) do
      prefix = npm_prefix(args)
      [Path.expand(prefix || working_directory, @repo_root)]
    else
      []
    end
  end

  defp npm_prefix(args) do
    case Enum.find_index(args, &(&1 == "--prefix")) do
      nil ->
        Enum.find_value(args, fn
          <<"--prefix=", prefix::binary>> -> prefix
          _ -> nil
        end)

      index ->
        Enum.at(args, index + 1)
    end
  end

  defp command_segments(run), do: String.split(run, ~r/[;&|]/, trim: true)

  defp run_load_only(node, files, allowed_roots) do
    record_path =
      Path.join(System.tmp_dir!(), "ci-require-guard-#{System.unique_integer([:positive])}.log")

    {output, status} =
      System.cmd(
        node,
        ["--test", "--test-name-pattern=^__mailglass_ci_require_guard_no_match__$" | files],
        cd: @repo_root,
        stderr_to_stdout: true,
        env: [
          {"NODE_OPTIONS", "--require #{@guard_path}"},
          {"MAILGLASS_REQUIRE_GUARD_ALLOWED", Enum.join(allowed_roots, ":")},
          {"MAILGLASS_REQUIRE_GUARD_RECORD", record_path}
        ]
      )

    records =
      if File.exists?(record_path),
        do: File.read!(record_path) |> String.split("\n", trim: true),
        else: []

    File.rm(record_path)

    %{output: output, status: status, records: records}
  end
end
