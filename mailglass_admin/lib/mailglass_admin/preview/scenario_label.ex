defmodule MailglassAdmin.Preview.ScenarioLabel do
  @moduledoc false

  # Pure label table for the Preview selector (Phase 178, PRVUX-07).
  #
  # Discovery returns raw module and scenario atoms. The selector shows a
  # humanized primary label, the Mailable as secondary context, and the exact
  # technical identity as visible monospace text. This module owns the
  # humanizing rule and the lookups the selector renders from. It only reads
  # atoms Discovery already returned; no atom is ever created from a label.
  #
  # Every function here is total. An unknown module or scenario falls back to
  # the module leaf or the raw atom string, and nothing in this module emits
  # diagnostics.

  @type reflection :: list() | :no_previews | {:error, term()}

  @type labels :: %{
          modules: %{module() => String.t()},
          scenarios: %{{module(), atom()} => String.t()}
        }

  @doc """
  Humanizes a snake_case scenario atom into sentence case.

  Splits on underscores, drops empty segments (so `__` collapses), and
  capitalizes only the first segment. An atom with no non-empty segment (`:_`)
  keeps its raw string.
  """
  @spec humanize(atom()) :: String.t()
  def humanize(atom) when is_atom(atom) do
    raw = Atom.to_string(atom)

    case raw |> String.split("_") |> Enum.reject(&(&1 == "")) do
      [] -> raw
      [first | rest] -> Enum.join([String.capitalize(first) | rest], " ")
    end
  end

  @doc """
  Exact technical identity of a scenario: the Mailable function that defines
  it. The render-error scenario has no function, so it is the module alone.
  """
  @spec technical(module(), atom() | nil) :: String.t()
  def technical(mod, :__error__), do: inspect(mod)
  def technical(mod, nil), do: inspect(mod)
  def technical(mod, scenario), do: inspect(mod) <> "." <> Atom.to_string(scenario)

  @doc """
  Builds the label table for a `Discovery.discover/1` result.

  Within one Mailable, scenarios whose humanized labels collide (compared
  NFC-normalized and downcased) use their raw atom string as the primary label.
  Mailables that share a leaf across namespaces get the shortest trailing
  namespace suffix that tells them apart. A repeated module entry keeps its
  first occurrence. Over any input the `{module_label, primary_label}` pairs
  are unique.
  """
  @spec build([{module(), reflection()}]) :: labels()
  def build(mailables) when is_list(mailables) do
    entries = Enum.uniq_by(mailables, fn {mod, _reflection} -> mod end)

    %{
      modules: entries |> Enum.map(&elem(&1, 0)) |> module_labels(),
      scenarios:
        Enum.reduce(entries, %{}, fn {mod, reflection}, acc ->
          put_scenarios(acc, mod, reflection)
        end)
    }
  end

  @doc """
  Visible Mailable label: the module leaf unless a leaf collision needed more
  namespace to tell two Mailables apart.
  """
  @spec module_label(labels(), module()) :: String.t()
  def module_label(%{modules: modules}, mod), do: Map.get(modules, mod) || leaf(mod)

  @doc """
  Visible primary label for a scenario. Unknown scenarios fall back to the raw
  atom string.
  """
  @spec scenario_label(labels(), module(), atom()) :: String.t()
  def scenario_label(_labels, _mod, :__error__), do: "render error"

  def scenario_label(%{scenarios: scenarios}, mod, scenario) when is_atom(scenario),
    do: Map.get(scenarios, {mod, scenario}) || Atom.to_string(scenario)

  defp put_scenarios(acc, mod, reflection) when is_list(reflection) do
    humanized =
      for {scenario, _defaults} <- reflection, is_atom(scenario), into: %{} do
        {scenario, humanize(scenario)}
      end

    collisions = humanized |> Map.values() |> Enum.frequencies_by(&collision_key/1)

    Enum.reduce(humanized, acc, fn {scenario, label}, inner ->
      primary =
        if Map.fetch!(collisions, collision_key(label)) > 1,
          do: Atom.to_string(scenario),
          else: label

      Map.put(inner, {mod, scenario}, primary)
    end)
  end

  defp put_scenarios(acc, _mod, _reflection), do: acc

  # Two labels that differ only by case or Unicode normalization form look the
  # same to a reader, so they count as one label.
  defp collision_key(label) do
    case :unicode.characters_to_nfc_binary(label) do
      normalized when is_binary(normalized) -> String.downcase(normalized)
      _invalid -> String.downcase(label)
    end
  end

  defp module_labels(mods) do
    mods
    |> Enum.group_by(&leaf/1)
    |> Enum.flat_map(fn
      {leaf, [mod]} -> [{mod, leaf}]
      {_leaf, group} -> disambiguate(group)
    end)
    |> Map.new()
  end

  # Smallest trailing-segment count that makes every label in a leaf-sharing
  # group unique, applied to every member. Falls back to the full name.
  defp disambiguate(group) do
    segments = Map.new(group, fn mod -> {mod, mod |> inspect() |> String.split(".")} end)
    longest = segments |> Map.values() |> Enum.map(&length/1) |> Enum.max()

    unique_depth =
      Enum.find(1..longest, fn depth ->
        labels = Enum.map(group, &suffix(Map.fetch!(segments, &1), depth))
        labels == Enum.uniq(labels)
      end)

    case unique_depth do
      nil -> Enum.map(group, &{&1, inspect(&1)})
      depth -> Enum.map(group, &{&1, suffix(Map.fetch!(segments, &1), depth)})
    end
  end

  defp suffix(segments, depth), do: segments |> Enum.take(-depth) |> Enum.join(".")

  defp leaf(mod), do: mod |> inspect() |> String.split(".") |> List.last()
end
