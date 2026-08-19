defmodule Mailglass.Scripts.RequiredChecksTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @guard_release_trigger_path Path.expand(
                                "../../.github/workflows/guard-release-trigger.yml",
                                __DIR__
                              )

  # Phase 27 stability-lock lanes (now behind CI Green, NOT in REQUIRED_CHECKS).
  @v1_0_lock_entries [
    "Support Contract Core (Elixir 1.18 / OTP 27)",
    "Support Contract Admin (Elixir 1.18 / OTP 27)",
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  ]

  # The canonical set of required leaf display names that ci_green.needs must cover.
  # Read from the single Elixir-side source (Mailglass.CILanes, test/support/ci_lanes.ex)
  # so the required-lane identity is defined once and shared with the MIXCI-03
  # parity-drift test (D-LD-10). test/support is in elixirc_paths(:test), so the module
  # is compiled before this test and is available at module-attribute (compile) time.
  @required_leaf_names Mailglass.CIPolicy.load!()
                       |> Mailglass.CIPolicy.active_required_lanes()
                       |> Enum.map(& &1.name)
                       |> MapSet.new()
  @structural_change_dependency "changes"

  test "REQUIRED_CHECKS array and print_expected_text bullets stay in sync" do
    source = File.read!(@script_path)

    array_set = parse_required_checks(source)
    bullet_set = parse_print_expected_bullets(source)

    # Guard against a vacuous pass: if the script's structure changes so a parser
    # returns nothing, both sets would be empty and the difference check below
    # would pass while detecting no drift at all.
    assert MapSet.size(array_set) > 0,
           "parsed no REQUIRED_CHECKS entries — parser or script format changed"

    assert MapSet.size(bullet_set) > 0,
           "parsed no print_expected_text bullets — parser or script format changed"

    only_in_array = MapSet.difference(array_set, bullet_set)
    only_in_bullets = MapSet.difference(bullet_set, array_set)

    assert MapSet.size(only_in_array) == 0 and MapSet.size(only_in_bullets) == 0,
           "REQUIRED_CHECKS and print_expected_text heredoc have drifted:\n" <>
             "  In array but missing from heredoc: #{inspect(MapSet.to_list(only_in_array))}\n" <>
             "  In heredoc but missing from array: #{inspect(MapSet.to_list(only_in_bullets))}"
  end

  test "REQUIRED_CHECKS contains exactly {CI Green, Guard Release Trigger} (GATE-01)" do
    source = File.read!(@script_path)
    array_set = parse_required_checks(source)

    expected = MapSet.new(["CI Green", "Guard Release Trigger"])

    only_in_actual = MapSet.difference(array_set, expected)
    only_in_expected = MapSet.difference(expected, array_set)

    assert MapSet.size(only_in_actual) == 0 and MapSet.size(only_in_expected) == 0,
           "REQUIRED_CHECKS must be exactly {CI Green, Guard Release Trigger}:\n" <>
             "  Extra in REQUIRED_CHECKS: #{inspect(MapSet.to_list(only_in_actual))}\n" <>
             "  Missing from REQUIRED_CHECKS: #{inspect(MapSet.to_list(only_in_expected))}"
  end

  test "required check identity derives from Guard Release Trigger's parsed display name" do
    required_checks = parse_required_checks(File.read!(@script_path))
    guard_job = extract_job_block(File.read!(@guard_release_trigger_path), "guard_release_trigger")
    display_name = parse_job_display_name(guard_job)

    assert guard_job != "", "guard_release_trigger job parser returned an empty block"
    assert display_name != "", "guard-release-trigger display-name parser returned an empty result"
    assert MapSet.member?(required_checks, display_name)

    historical_id = String.replace(guard_job, "Guard Release Trigger", "guard-release-trigger")

    refute MapSet.member?(required_checks, parse_job_display_name(historical_id)),
           "historical YAML job id must not be treated as the protected display-name context"
  end

  test "Phase 27 stability-lock entries are in ci_green.needs (not REQUIRED_CHECKS)" do
    source = File.read!(@script_path)
    ci_source = File.read!(@ci_yml_path)

    array_set = parse_required_checks(source)
    needs_keys = parse_ci_green_needs(ci_source)
    job_names = parse_ci_job_names(ci_source)
    needs_display = MapSet.new(needs_keys, fn key -> Map.fetch!(job_names, key) end)

    Enum.each(@v1_0_lock_entries, fn entry ->
      refute MapSet.member?(array_set, entry),
             "Phase 27 stability-lock entry should NOT be in REQUIRED_CHECKS (it moved behind CI Green): #{inspect(entry)}"

      assert MapSet.member?(needs_display, entry),
             "Phase 27 stability-lock entry missing from ci_green.needs display names: #{inspect(entry)}"
    end)
  end

  test "clean-baseline lane is NOT a required branch-protection check AND NOT in ci_green.needs (D-04)" do
    source = File.read!(@script_path)
    ci_source = File.read!(@ci_yml_path)

    array_set = parse_required_checks(source)
    needs_keys = parse_ci_green_needs(ci_source)
    job_names = parse_ci_job_names(ci_source)
    needs_display = MapSet.new(needs_keys, fn key -> Map.fetch!(job_names, key) end)

    clean_baseline = "Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)"

    refute MapSet.member?(array_set, clean_baseline),
           "#{clean_baseline} must NOT be in REQUIRED_CHECKS (D-04)"

    refute MapSet.member?(needs_display, clean_baseline),
           "#{clean_baseline} must NOT be in ci_green.needs display names (D-04)"
  end

  test "ci_green.needs carries changes exactly once as a structural dependency and required leaves set-equal the registry (GATE-03)" do
    ci_source = File.read!(@ci_yml_path)

    assert_ci_green_needs_contract!(ci_source)
  end

  test "negative controls: removing changes or a required leaf makes the ci_green needs contract fail" do
    ci_source = File.read!(@ci_yml_path)

    assert_ci_green_needs_contract!(ci_source)

    without_changes = String.replace(ci_source, "      - changes\n", "", global: false)

    assert_raise ExUnit.AssertionError, fn ->
      assert_ci_green_needs_contract!(without_changes)
    end

    without_required_leaf = String.replace(ci_source, "      - hex_audit\n", "", global: false)

    assert_raise ExUnit.AssertionError, fn ->
      assert_ci_green_needs_contract!(without_required_leaf)
    end
  end

  test "negative control: deleting the CI Green policy invocation makes its contract fail" do
    ci_source = File.read!(@ci_yml_path)

    assert_ci_green_policy_invocation!(ci_source)

    without_invocation =
      String.replace(ci_source, "bash scripts/ci_green_policy.sh", "true", global: false)

    assert_raise ExUnit.AssertionError, fn ->
      assert_ci_green_policy_invocation!(without_invocation)
    end
  end

  test "no required CI leaf is permanently if:-disabled (GATE-03)" do
    ci_source = File.read!(@ci_yml_path)

    needs_keys =
      ci_source
      |> parse_ci_green_needs()
      |> MapSet.delete(@structural_change_dependency)

    job_ifs = parse_ci_job_ifs(ci_source)

    Enum.each(needs_keys, fn key ->
      case Map.get(job_ifs, key) do
        nil ->
          :ok

        if_expr ->
          trimmed = String.trim(if_expr)

          permanently_disabled =
            trimmed == "false" or
              trimmed == "${{ false }}" or
              trimmed == "false == true" or
              trimmed == "1 == 2"

          refute permanently_disabled,
                 "Required CI leaf '#{key}' has a permanently-false if: condition (#{inspect(if_expr)}). " <>
                   "A constant-false if: causes the lane to always be skipped, silently degrading CI Green."
      end
    end)
  end

  test "Installer Host Smoke retains its public identity and executes both adopter proofs" do
    installer_job = extract_job_block(File.read!(@ci_yml_path), "installer_host_smoke")

    assert installer_job != "", "installer_host_smoke job parser returned an empty block"
    assert parse_job_display_name(installer_job) == "Installer Host Smoke"
    assert String.contains?(installer_job, "bash scripts/consumer_install_smoke.sh")
    assert String.contains?(installer_job, "bash scripts/generated_ecto_host_proof.sh")
    assert String.contains?(installer_job, "postgres:16-alpine")
  end

  test "core deterministic suite retains exact full-root command and inventory identity" do
    source = File.read!(@ci_yml_path)
    assert_core_deterministic_suite!(source)

    narrowed =
      String.replace(
        source,
        "run: mix test --warnings-as-errors",
        "run: mix test test/mailglass --warnings-as-errors",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_core_deterministic_suite!(narrowed) end

    for setup_fragment <- [
          "            mailglass_inbound/deps\n",
          "            reference/host_app/deps\n",
          "            reference/demo_app/deps\n",
          "      - name: Install inbound deps\n        working-directory: mailglass_inbound\n        run: mix deps.get --check-locked\n",
          "      - name: Install reference host deps\n        working-directory: reference/host_app\n        env:\n          MIX_ENV: dev\n        run: mix deps.get --check-locked\n",
          "      - name: Install demo deps\n        working-directory: reference/demo_app\n        run: mix deps.get --check-locked\n"
        ] do
      missing_setup = String.replace(source, setup_fragment, "", global: true)

      assert_raise ExUnit.AssertionError, fn ->
        assert_core_deterministic_suite!(missing_setup)
      end
    end
  end

  test "Phase 159 policy manifest exactly captures active, target, and advisory identities" do
    policy = Mailglass.CIPolicy.load!()

    assert Mailglass.CIPolicy.active_required_ids(policy) ==
             MapSet.new(Enum.map(policy.target_required, & &1.id))

    assert Mailglass.CIPolicy.target_behaviors(policy) ==
             MapSet.new([
               :formatting,
               :warning_and_no_optional_builds,
               :deterministic_core_suite,
               :deterministic_inbound_suite,
               :support_contracts,
               :mix_tasks,
               :credo_and_conformance,
               :core_dialyzer,
               :inbound_dialyzer,
               :docs,
               :audits,
               :trust,
               :installer_proofs
             ])
  end

  test "Phase 159 policy manifest rejects omitted target behavior and advisory promotion" do
    policy = Mailglass.CIPolicy.load!()

    without_docs = %{
      policy
      | active_required: List.delete(policy.active_required, "docs_warnings_as_errors"),
        target_required: Enum.reject(policy.target_required, &(&1.behavior == :docs))
    }

    assert_raise ArgumentError, ~r/missing target required behavior/, fn ->
      Mailglass.CIPolicy.validate!(without_docs)
    end

    promoted_advisory =
      update_in(policy.target_required, fn lanes ->
        lanes ++
          [
            %{
              id: "operator_browser_gate",
              name: "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)",
              behavior: :docs,
              ci_only_reason: "advisory"
            }
          ]
      end)

    assert_raise ArgumentError, ~r/target required and advisory lane IDs overlap/, fn ->
      Mailglass.CIPolicy.validate!(promoted_advisory)
    end
  end

  test "required leaves retain manifest names and cannot opt out with continue-on-error" do
    source = File.read!(@ci_yml_path)
    assert_required_leaf_integrity!(source)

    lanes = Mailglass.CIPolicy.load!() |> Mailglass.CIPolicy.active_required_lanes()

    renamed =
      String.replace(source, lanes |> hd() |> Map.fetch!(:name), "Renamed Required Lane",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_required_leaf_integrity!(renamed) end

    opted_out =
      String.replace(
        source,
        "  format_check:\n",
        "  format_check:\n    continue-on-error: true\n",
        global: false
      )

    assert_raise ExUnit.AssertionError, fn -> assert_required_leaf_integrity!(opted_out) end
  end

  test "advisory identities remain visible and cannot enter CI Green" do
    policy = Mailglass.CIPolicy.load!()

    expected =
      MapSet.new(
        ~w(operator_browser_gate demo_browser_evidence preview_capture_advisory provider_live core_full_suite_next_toolchain_advisory trust_lane_clean_baseline branch_protection_advisory publish_hex)
      )

    assert MapSet.new(policy.advisory) == expected
    assert MapSet.disjoint?(Mailglass.CIPolicy.active_required_ids(policy), expected)

    ci_source = File.read!(@ci_yml_path)
    ci_needs = parse_ci_green_needs(ci_source)

    for id <-
          ~w(operator_browser_gate demo_browser_evidence preview_capture_advisory trust_lane_clean_baseline branch_protection_advisory) do
      assert ci_source =~ "  #{id}:\n"
      refute MapSet.member?(ci_needs, id)
    end

    assert File.read!(Path.expand("../../.github/workflows/provider-live.yml", __DIR__)) =~
             "  provider_live:\n"

    assert File.read!(Path.expand("../../.github/workflows/advisory-matrix.yml", __DIR__)) =~
             "  core_full_suite_next_toolchain_advisory:\n"

    assert File.read!(Path.expand("../../.github/workflows/publish-hex.yml", __DIR__)) =~
             "  publish-core:\n"
  end

  test "promotion-ready manifest rejects a missing active target and malformed local parity declaration" do
    policy = Mailglass.CIPolicy.load!()

    missing_active = %{policy | active_required: tl(policy.active_required)}

    assert_raise ArgumentError, ~r/requires active required and target required IDs to match/, fn ->
      Mailglass.CIPolicy.validate!(missing_active)
    end

    [lane | rest] = policy.target_required
    malformed = %{policy | target_required: [Map.put(lane, :ci_only_reason, "conflict") | rest]}

    assert_raise ArgumentError, ~r/exactly one of local_alias or ci_only_reason/, fn ->
      Mailglass.CIPolicy.validate!(malformed)
    end
  end

  # ---------------------------------------------------------------------------
  # Parsers
  # ---------------------------------------------------------------------------

  defp parse_required_checks(source) do
    [_before, rest] = String.split(source, "REQUIRED_CHECKS=(\n", parts: 2)
    [chunk | _] = String.split(rest, "\n)", parts: 2)

    Regex.scan(~r/"([^"]+)"/, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end

  defp assert_required_leaf_integrity!(source) do
    jobs = Mailglass.CIYaml.job_names(source)
    lanes = Mailglass.CIPolicy.load!() |> Mailglass.CIPolicy.active_required_lanes()

    Enum.each(lanes, fn lane ->
      assert Map.fetch!(jobs, lane.id) == lane.name,
             "required job #{lane.id} display name drifted from the policy manifest"

      refute extract_job_block(source, lane.id) =~ ~r/^    continue-on-error:\s*true\s*$/m,
             "required job #{lane.id} must not continue on error"
    end)
  end

  defp assert_core_deterministic_suite!(source) do
    lane =
      Mailglass.CIPolicy.load!().target_required
      |> Enum.find(&(&1.id == "core_deterministic_suite"))

    assert lane.name == "Core Deterministic Suite (Elixir 1.18 / OTP 27)"
    assert lane.behavior == :deterministic_core_suite
    assert lane.local_alias == "mix test --warnings-as-errors"

    job = extract_job_block(source, lane.id)
    assert job =~ "    name: #{lane.name}\n"
    assert length(Regex.scan(~r/^        run: mix test --warnings-as-errors$/m, job)) == 1
    refute job =~ ~r/^        run: mix test .*--(?:exclude|only|seed)/m

    for required_fragment <- [
          "            mailglass_inbound/deps\n",
          "            reference/host_app/deps\n",
          "            reference/demo_app/deps\n",
          "      - name: Install inbound deps\n        working-directory: mailglass_inbound\n        run: mix deps.get --check-locked\n",
          "      - name: Install reference host deps\n        working-directory: reference/host_app\n        env:\n          MIX_ENV: dev\n        run: mix deps.get --check-locked\n",
          "      - name: Install demo deps\n        working-directory: reference/demo_app\n        run: mix deps.get --check-locked\n"
        ] do
      assert job =~ required_fragment
    end
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
      _ -> ""
    end
  end

  defp parse_job_display_name(job_block) do
    case Regex.run(~r/^    name: (.+)$/m, job_block) do
      [_, name] -> String.trim(name)
      _ -> ""
    end
  end

  defp parse_print_expected_bullets(source) do
    [_before, rest] =
      String.split(source, "cat <<'TEXT'\nExpected required status checks:\n", parts: 2)

    [chunk | _] = String.split(rest, "\n\nExpected non-context branch protection fields:", parts: 2)

    Regex.scan(~r/^  - (.+)$/m, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end

  defp assert_ci_green_needs_contract!(ci_source) do
    needs_list = parse_ci_green_needs_list(ci_source)
    needs_keys = MapSet.new(needs_list)
    job_names = parse_ci_job_names(ci_source)

    assert Enum.count(needs_list, &(&1 == @structural_change_dependency)) == 1,
           "ci_green.needs must contain changes exactly once as its structural dependency"

    assert MapSet.size(needs_keys) > 1,
           "parse_ci_green_needs returned no leaf dependencies — ci.yml format changed or ci_green job missing"

    assert map_size(job_names) > 0,
           "parse_ci_job_names returned empty — ci.yml format changed or no jobs found"

    all_job_keys = MapSet.new(Map.keys(job_names))
    undefined_keys = MapSet.difference(needs_keys, all_job_keys)

    assert MapSet.size(undefined_keys) == 0,
           "ci_green.needs references nonexistent jobs: #{inspect(MapSet.to_list(undefined_keys))}"

    leaf_keys = MapSet.delete(needs_keys, @structural_change_dependency)
    needs_display = MapSet.new(leaf_keys, fn key -> Map.fetch!(job_names, key) end)

    only_in_needs = MapSet.difference(needs_display, @required_leaf_names)
    only_in_required = MapSet.difference(@required_leaf_names, needs_display)

    assert MapSet.size(only_in_needs) == 0 and MapSet.size(only_in_required) == 0,
           "ci_green required-leaf display names do not match the required leaf set:\n" <>
             "  Extra in needs (not in required set): #{inspect(MapSet.to_list(only_in_needs))}\n" <>
             "  Missing from needs (in required set): #{inspect(MapSet.to_list(only_in_required))}"
  end

  defp assert_ci_green_policy_invocation!(ci_source) do
    ci_green = extract_job_block(ci_source, "ci_green")

    assert ci_green =~ "bash scripts/ci_green_policy.sh",
           "ci_green must delegate its aggregate decision to scripts/ci_green_policy.sh"

    assert ci_green =~ "${{ needs.changes.result }}",
           "ci_green policy invocation must receive the changes job result"

    assert ci_green =~ "${{ needs.changes.outputs.code }}",
           "ci_green policy invocation must receive the exact changes code output"

    for leaf <- MapSet.to_list(@required_leaf_names) do
      {job_key, _display_name} =
        ci_source
        |> parse_ci_job_names()
        |> Enum.find(fn {_key, display_name} -> display_name == leaf end)

      assert ci_green =~ "#{job_key}=${{ needs.#{job_key}.result }}",
             "ci_green policy invocation must receive required leaf #{job_key}"
    end
  end

  # Returns a MapSet of job KEY strings listed under ci_green.needs.
  defp parse_ci_green_needs(source) do
    source
    |> parse_ci_green_needs_list()
    |> MapSet.new()
  end

  defp parse_ci_green_needs_list(source) do
    case String.split(source, "\n  ci_green:\n", parts: 2) do
      [_, rest] ->
        lines = String.split(rest, "\n")

        {needs_lines, _} =
          Enum.reduce_while(lines, {[], false}, fn line, {acc, in_needs} ->
            cond do
              # New top-level job definition signals we have left ci_green's block.
              Regex.match?(~r/^  [a-z_]+:$/, line) and not in_needs ->
                {:halt, {acc, false}}

              # Inside needs block: collect list items.
              in_needs ->
                cond do
                  Regex.match?(~r/^      - ([a-z_]+)$/, line) ->
                    [[_, key]] = Regex.scan(~r/^      - ([a-z_]+)$/, line)
                    {:cont, {[key | acc], true}}

                  true ->
                    {:halt, {acc, false}}
                end

              # Detect start of needs: section (4-space indent).
              String.trim(line) == "needs:" ->
                {:cont, {acc, true}}

              true ->
                {:cont, {acc, false}}
            end
          end)

        Enum.reverse(needs_lines)

      _ ->
        []
    end
  end

  # Returns a map of job_key => display_name for every job defined in ci.yml.
  defp parse_ci_job_names(source) do
    lines = String.split(source, "\n")

    {result, _current_key} =
      Enum.reduce(lines, {%{}, nil}, fn line, {acc, current_key} ->
        cond do
          # Top-level job key (2-space indent, identifier, colon, no trailing content)
          Regex.match?(~r/^  ([a-z_]+):$/, line) ->
            [[_, key]] = Regex.scan(~r/^  ([a-z_]+):$/, line)
            {acc, key}

          # name: line immediately inside a job (4-space indent)
          current_key != nil and Regex.match?(~r/^    name: (.+)$/, line) ->
            [[_, name]] = Regex.scan(~r/^    name: (.+)$/, line)
            {Map.put(acc, current_key, String.trim(name)), current_key}

          true ->
            {acc, current_key}
        end
      end)

    result
  end

  # Returns a map of job_key => if_expression for jobs that have an if: clause.
  defp parse_ci_job_ifs(source) do
    lines = String.split(source, "\n")

    {result, _current_key} =
      Enum.reduce(lines, {%{}, nil}, fn line, {acc, current_key} ->
        cond do
          # Top-level job key
          Regex.match?(~r/^  ([a-z_]+):$/, line) ->
            [[_, key]] = Regex.scan(~r/^  ([a-z_]+):$/, line)
            {acc, key}

          # if: line at job level (4-space indent)
          current_key != nil and Regex.match?(~r/^    if: (.+)$/, line) ->
            [[_, if_expr]] = Regex.scan(~r/^    if: (.+)$/, line)
            {Map.put(acc, current_key, String.trim(if_expr)), current_key}

          true ->
            {acc, current_key}
        end
      end)

    result
  end
end
