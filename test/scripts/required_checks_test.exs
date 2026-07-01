defmodule Mailglass.Scripts.RequiredChecksTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

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
  @required_leaf_names MapSet.new(Mailglass.CILanes.required_lanes())

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

  test "ci_green.needs set-equality: every key resolves to a defined job and display names match required leaf set (GATE-03)" do
    ci_source = File.read!(@ci_yml_path)

    needs_keys = parse_ci_green_needs(ci_source)
    job_names = parse_ci_job_names(ci_source)

    # Anti-vacuity guards for the new parsers.
    assert MapSet.size(needs_keys) > 0,
           "parse_ci_green_needs returned empty — ci.yml format changed or ci_green job missing"

    assert map_size(job_names) > 0,
           "parse_ci_job_names returned empty — ci.yml format changed or no jobs found"

    # (i) Every key in ci_green.needs must be a real defined job.
    all_job_keys = MapSet.new(Map.keys(job_names))
    undefined_keys = MapSet.difference(needs_keys, all_job_keys)

    assert MapSet.size(undefined_keys) == 0,
           "ci_green.needs references nonexistent jobs: #{inspect(MapSet.to_list(undefined_keys))}"

    # (ii) needs_display must set-equal @required_leaf_names.
    needs_display = MapSet.new(needs_keys, fn key -> Map.fetch!(job_names, key) end)

    only_in_needs = MapSet.difference(needs_display, @required_leaf_names)
    only_in_required = MapSet.difference(@required_leaf_names, needs_display)

    assert MapSet.size(only_in_needs) == 0 and MapSet.size(only_in_required) == 0,
           "ci_green.needs display names do not match required leaf set:\n" <>
             "  Extra in needs (not in required set): #{inspect(MapSet.to_list(only_in_needs))}\n" <>
             "  Missing from needs (in required set): #{inspect(MapSet.to_list(only_in_required))}"
  end

  test "no required CI leaf is permanently if:-disabled (GATE-03)" do
    ci_source = File.read!(@ci_yml_path)

    needs_keys = parse_ci_green_needs(ci_source)
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

  defp parse_print_expected_bullets(source) do
    [_before, rest] =
      String.split(source, "cat <<'TEXT'\nExpected required status checks:\n", parts: 2)

    [chunk | _] = String.split(rest, "\n\nExpected non-context branch protection fields:", parts: 2)

    Regex.scan(~r/^  - (.+)$/m, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end

  # Returns a MapSet of job KEY strings listed under ci_green.needs.
  defp parse_ci_green_needs(source) do
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

        MapSet.new(needs_lines)

      _ ->
        MapSet.new()
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
