defmodule Mailglass.Scripts.CiNodeTestRequiresContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @guard_path Path.join(@repo_root, "test_js/support/ci-require-guard.cjs")

  test "every ci.yml node --test file loads with only the packages its job installed earlier" do
    ci = File.read!(@ci_path)
    node = System.find_executable("node") || flunk("node is required to run the ci.yml node --test resolvability contract")
    steps = node_test_steps(ci)

    assert length(steps) >= 3, "expected at least three ci.yml node --test steps, found #{length(steps)}"

    demo_step = Enum.find(steps, &(&1.job == "demo_browser_evidence" and String.contains?(&1.name, "Storybook evidence")))
    assert demo_step, "demo_browser_evidence Storybook node --test step was not parsed"
    assert demo_step.allowed_roots == [], "Demo's audit step installs nothing and must not create an allowed root"
    assert "mailglass_admin/e2e/support/storybook-axe.test.cjs" in demo_step.files

    operator_step = Enum.find(steps, &(&1.job == "operator_browser_gate" and String.contains?(&1.name, "CI monitor")))
    assert operator_step, "operator_browser_gate CI monitor node --test step was not parsed"
    assert operator_step.allowed_roots == [], "the monitor test runs before npm ci and must have no allowed root"

    for step <- steps, file <- step.files do
      result = run_load_only(node, [file], step.allowed_roots)
      violations = Enum.filter(result.records, &String.starts_with?(&1, "violation\t"))
      absolute_file = Path.expand(file, @repo_root)
      loaded = Enum.any?(result.records, &(&1 == "loaded\t#{absolute_file}"))

      detail =
        [
          "job #{step.job}, step #{step.name}, file #{file}",
          "exit: #{result.status}",
          "violations: #{Enum.join(violations, "; ")}",
          "output: #{result.output}"
        ]
        |> Enum.join("\n")

      assert result.status == 0, detail
      assert violations == [], detail
      assert loaded, "#{detail}\nmissing loaded record for #{absolute_file}"
    end
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
              [%{job: job_id, name: step.name, files: files, allowed_roots: roots_before_step} | node_steps]
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

      if Enum.member?(tokens, "--test") and Enum.any?(tokens, &(&1 == "node" or String.ends_with?(&1, "/node"))) do
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
    |> Enum.flat_map(fn command ->
      tokens = String.split(command, ~r/\s+/, trim: true)
      npm_index = Enum.find_index(tokens, &(&1 == "npm" or String.ends_with?(&1, "/npm")))

      if npm_index do
        npm_args = Enum.drop(tokens, npm_index + 1)
        install? = Enum.any?(npm_args, &(&1 in ["ci", "install"]))

        if install? do
          prefix =
            case Enum.find_index(npm_args, &(&1 == "--prefix")) do
              nil -> Enum.find_value(npm_args, &String.replace_prefix(&1, "--prefix=", ""))
              index -> Enum.at(npm_args, index + 1)
            end

          [Path.expand(prefix || working_directory, @repo_root)]
        else
          []
        end
      else
        []
      end
    end)
  end

  defp command_segments(run), do: String.split(run, ~r/[;&|]/, trim: true)

  defp run_load_only(node, files, allowed_roots) do
    record_path = Path.join(System.tmp_dir!(), "ci-require-guard-#{System.unique_integer([:positive])}.log")

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

    records = if File.exists?(record_path), do: File.read!(record_path) |> String.split("\n", trim: true), else: []
    File.rm(record_path)

    %{output: output, status: status, records: records}
  end
end
