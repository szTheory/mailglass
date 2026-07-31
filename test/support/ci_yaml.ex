defmodule Mailglass.CIYaml do
  @moduledoc """
  Text-level `.github/workflows/ci.yml` parsers shared by CI lane-truth meta-tests
  (TRUTH-07 / TRUTH-09).

  Consumed by `test/scripts/lane_classification_drift_test.exs` (Phase 141), which
  needs to enumerate every `ci.yml` job — including matrix jobs — from outside
  `test/scripts/required_checks_test.exs`, whose equivalent parsers are private.

  ## Accepted debt: NOT a refactor target for `required_checks_test.exs`

  `required_checks_test.exs:219-267` already implements `parse_ci_job_names/1` and
  `parse_ci_job_ifs/1` as private (`defp`) functions with the same reduce-over-lines
  shape as `job_names/1` below. This module does **not** absorb them, and
  `required_checks_test.exs` is **not** refactored to delegate here. GATE-03 (the
  `ci_green.needs` set-equality test in that file) is load-bearing for this phase's
  own correctness — refactoring its parsers mid-phase risks exactly the collateral
  damage this milestone exists to prevent (RESEARCH.md § "Parser reuse"). The
  ~20-line duplication is accepted debt, recorded here rather than silently repeated.

  ## The two name spaces (RESEARCH F1)

  `job_names/1` and `matrix_job_names/1` return YAML `name:` field values — the
  *declared* display name for a job. `gate-ci-green` (`publish-hex.yml`) instead reads
  *runtime* job names from the GitHub Actions REST API, and for a job with a
  `strategy:` block, GitHub appends the matrix value(s) to that declared name at
  runtime, e.g. `Dialyzer (Elixir 1.18 / OTP 27)` reports live as
  `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`. A consumer that matches a matrix job's
  declared name with `===` against a runtime name will never see it match — this is
  why `matrix_job_names/1` exists: so callers can identify which declared names need
  prefix (not exact-equality) matching downstream.

  ### The deliberate wrinkle: `expanded_matrix_job_names/1` returns RUNTIME names

  `expanded_matrix_job_names/1` (Phase 143 / D-24) is the one function here that does
  **not** belong to the declared-name space. It expands `strategy.matrix.include:`
  rows into the job's `name:` template and returns the strings GitHub reports live.
  It exists because a set-equality drift test built on declared names would be
  **vacuous** for `advisory-matrix.yml`: that file's two Core Full Suite jobs
  interpolate a byte-identical `name:` template, so `job_names/1` collapses them and a
  registry-versus-YAML comparison would claim four-leg coverage while proving two.

  The two spaces are kept in one module rather than split because they are two
  readings of the *same* `name:` lines; separating them would hide the relationship.
  Which space a function belongs to is stated in its own `@doc`.

  ### The suffix rule, and how confident we are in it

  **Observed (verified against live GitHub API responses, RESEARCH.md § "Runtime vs
  Declared Job Names"):** `ci.yml`'s `dialyzer` job declares a *static*
  `name: Dialyzer (Elixir 1.18 / OTP 27)` over a `strategy.matrix` and reports live as
  `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`; `advisory-matrix.yml`'s jobs
  interpolate every matrix axis into their `name:` and report live with **no** appended
  suffix.

  **Inferred from those two cases (not from documentation):** GitHub appends a
  ` (<matrix values>)` suffix only when a job's `name:` contains no matrix expression.
  The two outcomes above are verified; the *rule* connecting them is an inference from
  n=2. `expanded_matrix_job_names/1` therefore refuses to guess: given a job that has
  matrix rows but whose `name:` interpolates nothing, it raises rather than returning a
  name it cannot compute — a parser that cannot observe its subject must not report
  success.
  """

  # Indent-anchored, because this module deliberately takes no YAML dependency (see
  # the accepted-debt section above). The indentation these anchor on is
  # `advisory-matrix.yml`'s and `ci.yml`'s house style: 2-space job keys, 4-space job
  # fields, 8-space `include:`, 10-space include-row heads, 12-space row continuations.
  #
  # `job_names/1` and `matrix_job_names/1` inline their own copies of the job-key and
  # `name:` anchors. That duplication is deliberate and NOT collapsed here: both are
  # load-bearing for the required-lane drift assertions today, and rewriting a working
  # parser to share a constant is exactly the collateral risk the accepted-debt note
  # above declines to take mid-phase.
  @job_key_regex ~r/^  ([a-z_]+):$/
  @matrix_include_regex ~r/^        include:$/
  @matrix_row_head_regex ~r/^          - ([a-z_]+): (.+)$/
  @matrix_row_cont_regex ~r/^            ([a-z_]+): (.+)$/
  @comment_regex ~r/^\s*#/
  @matrix_placeholder_regex ~r/\$\{\{\s*matrix\.([a-z_]+)\s*\}\}/

  @doc """
  Returns `%{job_key => display_name}` for every top-level job defined in the raw
  `ci.yml` source string.

  A job key is a 2-space-indented `identifier:` line; its display name is the
  4-space-indented `name: ...` line immediately inside it. Note that `on:` sub-keys
  (`push`, `pull_request`, `workflow_dispatch`) match the same 2-space job-key regex
  but never carry a 4-space `name:` line of their own, so they never enter the
  returned map.
  """
  @spec job_names(String.t()) :: %{String.t() => String.t()}
  def job_names(source) do
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

  @doc """
  Returns a `MapSet` of the display names (see `job_names/1`) of every job in the raw
  `ci.yml` source string that declares a `strategy:` block (i.e. a matrix job).

  Display names, not job keys, are returned deliberately: every downstream consumer
  (the lane-classification drift test's matrix-lane prefix-safety assertion) compares
  against display-name registries, not job keys.
  """
  @spec matrix_job_names(String.t()) :: MapSet.t(String.t())
  def matrix_job_names(source) do
    lines = String.split(source, "\n")

    {matrix_keys, _current_key} =
      Enum.reduce(lines, {MapSet.new(), nil}, fn line, {acc, current_key} ->
        cond do
          # Top-level job key (2-space indent, identifier, colon, no trailing content)
          Regex.match?(~r/^  ([a-z_]+):$/, line) ->
            [[_, key]] = Regex.scan(~r/^  ([a-z_]+):$/, line)
            {acc, key}

          # strategy: line at job level (4-space indent)
          current_key != nil and Regex.match?(~r/^    strategy:$/, line) ->
            {MapSet.put(acc, current_key), current_key}

          true ->
            {acc, current_key}
        end
      end)

    names = job_names(source)

    matrix_keys
    |> Enum.map(fn key -> Map.get(names, key) end)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  @doc """
  Returns a `MapSet` of the **runtime** display names of every job in the raw workflow
  source string — the strings GitHub reports through the Actions REST API, not the
  declared `name:` templates the other functions in this module return (see the
  moduledoc's "two name spaces" section).

  For a job with `strategy.matrix.include:` rows, each row is substituted into the
  job's `name:` template and one runtime name is emitted per row. For a job with no
  matrix rows, the declared name *is* the runtime name and is emitted unchanged.

  For `.github/workflows/advisory-matrix.yml` this returns exactly seven names:
  two Core Full Suite legs, two next-toolchain legs, one Provider Compatibility leg,
  and two Inbound Full Suite legs.

  ## Raises rather than guessing

  `ArgumentError` when the source cannot be expanded honestly, because a lane registry
  built from a silently-wrong name set is worse than a failed parse:

    * a job whose `name:` interpolates `${{ matrix.<axis> }}` but for which no
      `include:` row was parsed — either the workflow uses a `matrix:` shape this
      parser does not read, or the indentation anchors above have drifted;
    * a job with matrix rows whose `name:` interpolates nothing — GitHub then appends
      a ` (<matrix values>)` suffix whose exact spelling this parser cannot compute
      (see the suffix-rule section in the moduledoc). `ci.yml`'s `dialyzer` job is
      exactly this shape, which is why this function is scoped to
      `advisory-matrix.yml` and `matrix_job_names/1` remains the right tool for
      `ci.yml`;
    * a `${{ matrix.<axis> }}` placeholder naming an axis absent from an include row.
  """
  @spec expanded_matrix_job_names(String.t()) :: MapSet.t(String.t())
  def expanded_matrix_job_names(source) do
    rows_by_key = matrix_include_rows(source)

    source
    |> job_names()
    |> Enum.flat_map(fn {key, template} ->
      expand_job_name(key, template, Map.get(rows_by_key, key, []))
    end)
    |> MapSet.new()
  end

  defp expand_job_name(key, template, []) do
    if Regex.match?(@matrix_placeholder_regex, template) do
      raise ArgumentError,
            "Job name expansion failed: job `#{key}` declares a name that interpolates a " <>
              "matrix axis (#{inspect(template)}) but no `strategy.matrix.include:` row was " <>
              "parsed for it. Either the workflow expresses its matrix in a shape " <>
              "Mailglass.CIYaml does not read, or this module's indentation anchors have " <>
              "drifted from the file. Fix the parser — do not delete the job from the registry."
    end

    [template]
  end

  defp expand_job_name(key, template, rows) do
    unless Regex.match?(@matrix_placeholder_regex, template) do
      raise ArgumentError,
            "Job name expansion failed: job `#{key}` has #{length(rows)} matrix include " <>
              "row(s) but its name (#{inspect(template)}) interpolates no matrix axis. " <>
              "GitHub then appends a ` (<matrix values>)` suffix to the runtime name, and " <>
              "this parser cannot compute that spelling — returning the bare template would " <>
              "silently hand a registry a name that never matches at runtime."
    end

    Enum.map(rows, &substitute_matrix_values(key, template, &1))
  end

  defp substitute_matrix_values(key, template, row) do
    Regex.replace(@matrix_placeholder_regex, template, fn _full, axis ->
      case Map.fetch(row, axis) do
        {:ok, value} ->
          value

        :error ->
          raise ArgumentError,
                "Job name expansion failed: job `#{key}`'s name interpolates " <>
                  "`${{ matrix.#{axis} }}`, but the include row #{inspect(row)} defines no " <>
                  "`#{axis}` key. The runtime name for that leg cannot be computed."
      end
    end)
  end

  # Returns `%{job_key => [%{axis => value}, ...]}` for every job declaring
  # `strategy.matrix.include:` rows, in file order. Same reduce-over-lines shape as
  # `matrix_job_names/1`, extended with an in-include? flag and a row accumulator:
  # a row opens on a 10-space `- key: value` head and absorbs 12-space continuations
  # until the next head, and the include block closes on the first non-blank,
  # non-comment line that is neither.
  defp matrix_include_rows(source) do
    source
    |> String.split("\n")
    |> Enum.reduce(%{key: nil, in_include?: false, row: nil, rows: %{}}, &scan_include_line/2)
    |> flush_row()
    |> Map.fetch!(:rows)
    |> Map.new(fn {key, rows} -> {key, Enum.reverse(rows)} end)
  end

  defp scan_include_line(line, acc) do
    cond do
      # Checked first: a comment inside an include block must not close it, and the
      # blocks in advisory-matrix.yml carry several paragraphs of them.
      Regex.match?(@comment_regex, line) ->
        acc

      Regex.match?(@job_key_regex, line) ->
        [[_, key]] = Regex.scan(@job_key_regex, line)
        acc |> flush_row() |> Map.merge(%{key: key, in_include?: false})

      acc.key != nil and Regex.match?(@matrix_include_regex, line) ->
        acc |> flush_row() |> Map.put(:in_include?, true)

      acc.in_include? and Regex.match?(@matrix_row_head_regex, line) ->
        [[_, axis, value]] = Regex.scan(@matrix_row_head_regex, line)
        acc |> flush_row() |> Map.put(:row, %{axis => strip_quotes(value)})

      acc.in_include? and Regex.match?(@matrix_row_cont_regex, line) ->
        [[_, axis, value]] = Regex.scan(@matrix_row_cont_regex, line)
        Map.update!(acc, :row, &Map.put(&1 || %{}, axis, strip_quotes(value)))

      acc.in_include? and String.trim(line) != "" ->
        acc |> flush_row() |> Map.put(:in_include?, false)

      true ->
        acc
    end
  end

  defp flush_row(%{row: nil} = acc), do: acc

  defp flush_row(%{key: key, row: row, rows: rows} = acc) do
    %{acc | row: nil, rows: Map.update(rows, key, [row], &[row | &1])}
  end

  defp strip_quotes(value), do: value |> String.trim() |> String.trim("\"")
end
