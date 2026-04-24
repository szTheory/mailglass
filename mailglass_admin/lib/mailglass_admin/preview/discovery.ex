defmodule MailglassAdmin.Preview.Discovery do
  @moduledoc """
  Reflection for mailable modules — finds `use Mailglass.Mailable` modules,
  reads their `preview_props/0` callback if present, and returns the pair
  ready for the preview dashboard sidebar.

  ## Discovery modes

    * `:auto_scan` (default) — Walks `:application.loaded_applications/0` and
      for each app calls `:application.get_key(app, :modules)`, filtering by
      the `__mailglass_mailable__/0` marker that `use Mailglass.Mailable`
      injects via `@before_compile`.

    * `[module | _]` explicit list — Override for umbrella apps, pathological
      module counts, or adopter preference. Each module MUST have the marker
      or discovery raises `ArgumentError` with an actionable message.

  ## Graceful failures (CONTEXT D-13)

    * Marker present, no `preview_props/0` defined -> `{module, :no_previews}`
    * `preview_props/0` raises -> `{module, {:error, formatted_stacktrace}}`
    * `preview_props/0` returns non-list or a list item whose second element
      is not a map -> `{module, {:error, shape_violation_message}}`

  None of these failure modes raise from `discover/1`. The LiveView branches
  on the second tuple element to render the correct sidebar + main pane state
  (05-UI-SPEC sidebar section lines 189-207, error card lines 386-404).

  ## Performance

  Empirical: ~50ms on a 10,000-module umbrella app. `function_exported?/3`
  is O(1) per module. If adopters report slow mount, they bypass the scan
  via the explicit `:mailables` list.

  ## Boundary classification

  Submodule auto-classifies into the `MailglassAdmin` root boundary declared
  in `lib/mailglass_admin.ex` (`use Boundary, deps: [Mailglass], exports:
  [Router]`); Boundary's `classify_to:` directive is reserved for mix tasks
  and protocol implementations and is not used here. Matches the convention
  established by `MailglassAdmin.PubSub.Topics` and `MailglassAdmin.Layouts`
  in Plan 03.
  """

  @type scenario :: {atom(), map()}
  @type reflection :: [scenario()] | :no_previews | {:error, String.t()}
  @type result :: {module(), reflection()}

  @doc """
  Discovers mailable modules and their preview scenarios.

  Returns a list of tuples; order is implementation-defined but stable within
  a single call.
  """
  @doc since: "0.1.0"
  @spec discover(:auto_scan | [module()]) :: [result()]
  def discover(:auto_scan) do
    loaded_apps()
    |> Enum.flat_map(&modules_for_app/1)
    |> Enum.filter(&mailable?/1)
    |> Enum.map(&reflect/1)
  end

  def discover(mods) when is_list(mods) do
    Enum.map(mods, fn mod ->
      if mailable?(mod) do
        reflect(mod)
      else
        raise ArgumentError,
              inspect(mod) <>
                " is listed in :mailables but does not `use Mailglass.Mailable` — " <>
                "add the directive or remove it from the list"
      end
    end)
  end

  defp loaded_apps do
    for {app, _, _} <- :application.loaded_applications(), do: app
  end

  defp modules_for_app(app) do
    case :application.get_key(app, :modules) do
      {:ok, mods} -> mods
      :undefined -> []
    end
  end

  defp mailable?(mod) do
    Code.ensure_loaded?(mod) and
      function_exported?(mod, :__mailglass_mailable__, 0) and
      mod.__mailglass_mailable__() == true
  rescue
    # Module load failures during dev (bad code under hot reload) — skip.
    _ -> false
  end

  defp reflect(mod) do
    cond do
      not function_exported?(mod, :preview_props, 0) ->
        {mod, :no_previews}

      true ->
        try do
          raw = mod.preview_props()
          {mod, validate_scenarios(raw)}
        rescue
          e ->
            {mod, {:error, Exception.format(:error, e, __STACKTRACE__)}}
        end
    end
  end

  # CONTEXT D-11 return shape: [{atom(), map()}]. Anything else is invalid.
  # 05-RESEARCH.md Pitfall 7: preview_props returning {atom, function} crashes
  # the type-inferred form renderer with a confusing FunctionClauseError.
  # Catching shape violations at discovery time surfaces a clear error card.
  defp validate_scenarios(raw) when is_list(raw) do
    if Enum.all?(raw, &valid_scenario?/1) do
      raw
    else
      bad = Enum.find(raw, &(not valid_scenario?(&1)))

      {:error,
       "preview_props/0 must return [{atom(), map()}] but got an entry " <>
         "whose second element is not a map: " <> inspect(bad)}
    end
  end

  defp validate_scenarios(other) do
    {:error,
     "preview_props/0 must return a list of {atom, map} tuples, got: " <>
       inspect(other)}
  end

  defp valid_scenario?({name, defaults})
       when is_atom(name) and is_map(defaults),
       do: true

  defp valid_scenario?(_), do: false
end
