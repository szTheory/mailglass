defmodule Mailglass.Scripts.BrandDocsCIWiringTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @root_contract_path Path.join(@repo_root, "test/scripts/brand_docs_contract_test.exs")
  @output_contract_path Path.join(@repo_root, "ci/contracts/brand_docs_output_test.exs")

  test "the required docs job builds and checks three locked package outputs" do
    source = File.read!(@ci_path)

    assert_docs_wiring!(source)

    root_contract = File.read!(@root_contract_path)
    refute root_contract =~ "package_doc_dir"
    refute root_contract =~ "all real package outputs"
    assert File.regular?(@output_contract_path)
    refute Path.relative_to(@output_contract_path, @repo_root) |> String.starts_with?("test/")
  end

  test "negative controls reject commented commands, unlocked deps, missing CI Green edges, and continue-on-error" do
    source = File.read!(@ci_path)
    assert_docs_wiring!(source)

    without_invocation =
      String.replace(
        source,
        "      - name: Build docs\n        run: bash scripts/verify_brand_docs.sh",
        "      - name: Build docs\n        # run: bash scripts/verify_brand_docs.sh\n        run: true",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_docs_wiring!(without_invocation) end

    without_core_locked_deps =
      String.replace(
        source,
        "      - name: Install deps\n        run: MIX_ENV=dev mix deps.get --check-locked",
        "      - name: Install deps\n        # run: MIX_ENV=dev mix deps.get --check-locked\n        run: mix deps.get",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_docs_wiring!(without_core_locked_deps) end

    without_inbound_deps =
      String.replace(
        source,
        "        working-directory: mailglass_inbound\n        run: MIX_ENV=dev mix deps.get --check-locked",
        "        working-directory: mailglass_inbound\n        run: mix deps.get",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_docs_wiring!(without_inbound_deps) end

    without_ci_green_edge =
      String.replace(source, "      - docs_warnings_as_errors\n", "", global: false)

    assert_raise ExUnit.AssertionError, fn -> assert_docs_wiring!(without_ci_green_edge) end

    without_continue_on_error =
      String.replace(
        source,
        "      - name: Build docs\n        run: bash scripts/verify_brand_docs.sh",
        "      - name: Build docs\n        continue-on-error: true\n        run: bash scripts/verify_brand_docs.sh",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_docs_wiring!(without_continue_on_error) end
  end

  defp assert_docs_wiring!(source) do
    names = Mailglass.CIYaml.job_names(source)

    assert Map.get(names, "docs_warnings_as_errors") ==
             "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
           "required docs job key/display identity changed"

    docs_job = extract_job_block(source, "docs_warnings_as_errors")
    assert docs_job != "", "docs_warnings_as_errors job is missing"

    steps = step_blocks(docs_job)

    assert has_run_step?(steps, "Install deps", "MIX_ENV=dev mix deps.get --check-locked"),
           "core dev dependencies must be locked before the docs build"

    assert has_working_directory_step?(steps, "Install Admin deps", "mailglass_admin"),
           "Admin dev dependencies must be locked in the required docs job"

    assert has_working_directory_step?(steps, "Install Inbound deps", "mailglass_inbound"),
           "Inbound dev dependencies must be locked in the required docs job"

    assert has_run_step?(steps, "Build docs", "bash scripts/verify_brand_docs.sh"),
           "the required docs job must run the fail-fast all-package validation script"

    assert has_run_step?(
             steps,
             "Validate guides have no leaked internal IDs (REL-02)",
             "mix mailglass.docs.check"
           ),
           "the existing core guide validation must remain in the required docs job"

    refute docs_job =~ ~r/^\s*continue-on-error:/m,
           "the required docs job must propagate failures"

    ci_green = extract_job_block(source, "ci_green")

    assert ci_green =~ ~r/^      - docs_warnings_as_errors\s*$/m,
           "CI Green must retain the required docs job edge"
  end

  defp has_run_step?(steps, step_name, run_value) do
    Enum.any?(steps, fn step ->
      has_step_name?(step, step_name) and active_run_value?(step, run_value)
    end)
  end

  defp has_working_directory_step?(steps, step_name, directory) do
    Enum.any?(steps, fn step ->
      has_step_name?(step, step_name) and
        Regex.match?(~r/^        working-directory: #{Regex.escape(directory)}[ \t]*$/m, step) and
        active_run_value?(step, "MIX_ENV=dev mix deps.get --check-locked")
    end)
  end

  defp has_step_name?(step, step_name) do
    Regex.match?(~r/^      - name: #{Regex.escape(step_name)}[ \t]*$/m, step)
  end

  # These expected commands are single-line YAML scalars. Anchor the `run` key at
  # the step-field indentation so comments, names, and other fields cannot satisfy
  # a command assertion. A trailing YAML comment is allowed after the exact value.
  defp active_run_value?(step, run_value) do
    Regex.match?(
      ~r/^        run:[ \t]*#{Regex.escape(run_value)}(?:[ \t]+#.*)?[ \t]*$/m,
      step
    )
  end

  defp step_blocks(job) do
    job
    |> String.split("\n      - name: ")
    |> Enum.drop(1)
    |> Enum.map(&("      - name: " <> &1))
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
      _ -> ""
    end
  end
end
