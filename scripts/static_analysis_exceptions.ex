defmodule Mailglass.Quality.StaticAnalysisExceptions do
  @moduledoc false

  @nesting "Credo.Check.Refactor.Nesting"
  @cyclomatic "Credo.Check.Refactor.CyclomaticComplexity"

  def check!(root \\ File.cwd!(), today \\ Date.utc_today()) do
    ledger = load_ledger!(root)
    validate_policy!(ledger, today)
    validate_credo_config!(root)
    validate_dialyzer_ledger!(root, ledger, today)

    actual = credo_issues!(root) |> aggregate()

    expected =
      Map.new(ledger.credo, fn {file, function, check, score, occurrences} ->
        {{file, function, check}, %{score: score, occurrences: occurrences}}
      end)

    compare!(expected, actual)
    :ok
  end

  def aggregate(issues) do
    Enum.reduce(issues, %{}, fn issue, acc ->
      check = Map.fetch!(issue, "check")
      key = {Map.fetch!(issue, "filename"), Map.fetch!(issue, "scope"), check}
      score = score!(check, Map.fetch!(issue, "message"))

      Map.update(acc, key, %{score: score, occurrences: 1}, fn current ->
        %{score: max(current.score, score), occurrences: current.occurrences + 1}
      end)
    end)
  end

  def compare!(expected, actual) do
    new_keys = Map.keys(actual) -- Map.keys(expected)
    dead_keys = Map.keys(expected) -- Map.keys(actual)

    regressions =
      for {key, value} <- actual,
          baseline = expected[key],
          baseline &&
            (value.score > baseline.score || value.occurrences > baseline.occurrences),
          do: {key, baseline, value}

    problems = []
    problems = if new_keys == [], do: problems, else: [{:new_exceptions, new_keys} | problems]
    problems = if dead_keys == [], do: problems, else: [{:dead_exceptions, dead_keys} | problems]
    problems = if regressions == [], do: problems, else: [{:regressions, regressions} | problems]

    if problems != [],
      do: raise("static-analysis ledger mismatch: #{inspect(Enum.reverse(problems))}")

    :ok
  end

  defp load_ledger!(root) do
    path = Path.join(root, "config/static_analysis_exceptions.exs")
    {ledger, _binding} = Code.eval_file(path)

    unless is_map(ledger) and is_list(ledger[:credo]) do
      raise "static-analysis ledger is malformed"
    end

    keys =
      Enum.map(ledger.credo, fn {file, function, check, score, occurrences} ->
        unless File.regular?(Path.join(root, file)), do: raise("dead static-analysis file: #{file}")
        unless check in [@nesting, @cyclomatic], do: raise("unknown Credo check: #{check}")
        unless is_binary(function) and function != "", do: raise("missing function for #{file}")
        unless is_integer(score) and score > 0, do: raise("invalid score for #{file}:#{function}")
        unless is_integer(occurrences) and occurrences > 0, do: raise("invalid occurrence count")
        {file, function, check}
      end)

    if length(keys) != MapSet.size(MapSet.new(keys)), do: raise("duplicate static-analysis entry")
    ledger
  end

  defp validate_dialyzer_ledger!(root, ledger, today) do
    expected =
      MapSet.new(ledger.dialyzer, fn {package, file, description, owner, reason, expires_on} ->
        unless package in [".", "mailglass_admin", "mailglass_inbound"],
          do: raise("unknown Dialyzer package: #{package}")

        unless File.regular?(Path.join([root, package, file])),
          do: raise("dead Dialyzer target: #{package}/#{file}")

        unless owner != "" and reason != "", do: raise("Dialyzer metadata missing for #{file}")

        unless match?(%Date{}, expires_on) and Date.after?(expires_on, today),
          do: raise("Dialyzer exception expired for #{file}")

        {package, file, description}
      end)

    actual =
      [".", "mailglass_admin", "mailglass_inbound"]
      |> Enum.flat_map(fn package ->
        path = Path.join([root, package, ".dialyzer_ignore.exs"])
        {entries, _binding} = Code.eval_file(path)
        Enum.map(entries, fn {file, description} -> {package, file, description} end)
      end)
      |> MapSet.new()

    unless expected == actual do
      raise "Dialyzer ledger mismatch: missing=#{inspect(MapSet.difference(expected, actual))} " <>
              "unregistered=#{inspect(MapSet.difference(actual, expected))}"
    end
  end

  defp validate_policy!(ledger, today) do
    unless is_binary(ledger[:owner]) and ledger.owner != "", do: raise("ledger owner missing")
    unless is_binary(ledger[:reason]) and ledger.reason != "", do: raise("ledger reason missing")

    unless match?(%Date{}, ledger[:expires_on]) and Date.after?(ledger.expires_on, today) do
      raise "static-analysis ledger expired"
    end
  end

  defp validate_credo_config!(root) do
    source = File.read!(Path.join(root, ".credo.exs"))

    for check <- ["Nesting", "CyclomaticComplexity"] do
      if Regex.match?(~r/\{Credo\.Check\.Refactor\.#{check},\s*false\}/, source) do
        raise "global #{check} disable is forbidden"
      end
    end
  end

  defp credo_issues!(root) do
    args = [
      "credo",
      "--strict",
      "--config-file",
      "config/quality/credo_ratchet.exs",
      "--format=json"
    ]

    {output, _status} = System.cmd("mix", args, cd: root, stderr_to_stdout: false)

    case Jason.decode(output) do
      {:ok, %{"issues" => issues}} when is_list(issues) -> issues
      _ -> raise "Credo ratchet did not produce valid JSON"
    end
  end

  defp score!(@nesting, message) do
    capture_score!(message, ~r/was (\d+)/)
  end

  defp score!(@cyclomatic, message) do
    capture_score!(message, ~r/complexity is (\d+)/)
  end

  defp score!(check, _message), do: raise("unexpected ratchet check: #{check}")

  defp capture_score!(message, regex) do
    case Regex.run(regex, message, capture: :all_but_first) do
      [score] -> String.to_integer(score)
      _ -> raise "cannot parse Credo score: #{message}"
    end
  end
end
