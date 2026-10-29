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
  """
  @spec build([{module(), reflection()}]) :: labels()
  def build(mailables) when is_list(mailables) do
    Enum.reduce(mailables, %{modules: %{}, scenarios: %{}}, fn {mod, reflection}, acc ->
      acc
      |> put_in([:modules, mod], leaf(mod))
      |> put_scenarios(mod, reflection)
    end)
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
    Enum.reduce(reflection, acc, fn {scenario, _defaults}, inner ->
      put_in(inner, [:scenarios, {mod, scenario}], humanize(scenario))
    end)
  end

  defp put_scenarios(acc, _mod, _reflection), do: acc

  defp leaf(mod), do: mod |> inspect() |> String.split(".") |> List.last()
end
