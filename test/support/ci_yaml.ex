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

  Every function in this module returns YAML `name:` field values — the *declared*
  display name for a job. `gate-ci-green` (`publish-hex.yml`) instead reads *runtime*
  job names from the GitHub Actions REST API, and for a job with a `strategy:` block,
  GitHub appends the matrix value(s) to that declared name at runtime, e.g.
  `Dialyzer (Elixir 1.18 / OTP 27)` reports live as
  `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`. A consumer that matches a matrix job's
  declared name with `===` against a runtime name will never see it match — this is
  why `matrix_job_names/1` exists: so callers can identify which declared names need
  prefix (not exact-equality) matching downstream.
  """

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
end
