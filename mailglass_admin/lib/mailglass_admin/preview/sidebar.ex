defmodule MailglassAdmin.Preview.Sidebar do
  @moduledoc """
  Sidebar function component: mailable list with collapsible scenario
  groups + status badges.

  Renders the structure documented in 05-UI-SPEC §Sidebar structure
  (lines 188-207 + 234-263). Branches on the second element of each
  `{mod, reflection}` tuple from `MailglassAdmin.Preview.Discovery.discover/1`:

    * `list when is_list(list)` — healthy mailable; render `<details>/<summary>`
      with scenario links. Active scenario gets a 3px Glass left border;
      inactive gets `border-transparent` + hover state.
    * `:no_previews` — stub mailable; shows the literal copy
      "No previews defined" per UI-SPEC Copywriting Contract line 457.
    * `{:error, _}` — preview_props/0 raised during discovery; shows a
      warning badge (via `MailglassAdmin.Components.badge/1`).

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :mailables, :list, required: true
  attr :current_mailable, :atom, default: nil
  attr :current_scenario, :atom, default: nil

  @doc """
  Renders the mailable sidebar.

  `mailables` is the list of `{module, reflection}` tuples produced by
  `MailglassAdmin.Preview.Discovery.discover/1`. `current_mailable` and
  `current_scenario` drive the active-item highlight.
  """
  @doc since: "0.1.0"
  def sidebar(assigns) do
    ~H"""
    <div class="space-y-4">
      <h1 class="text-base font-bold text-base-content tracking-tight">Mailers</h1>

      <ul class="space-y-1">
        <%= for {mod, reflection} <- @mailables do %>
          <li>
            <.mailable_entry
              mod={mod}
              reflection={reflection}
              current_mailable={@current_mailable}
              current_scenario={@current_scenario}
            />
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr :mod, :atom, required: true
  attr :reflection, :any, required: true
  attr :current_mailable, :atom, default: nil
  attr :current_scenario, :atom, default: nil

  # Function component dispatched by reflection shape. Phoenix.Component
  # requires `def` (not `defp`) for `<.mailable_entry ... />` invocation.
  def mailable_entry(%{reflection: list} = assigns) when is_list(list) do
    ~H"""
    <details open={@current_mailable == @mod}>
      <summary class="flex items-center gap-2 px-3 py-2 min-h-11 text-sm font-bold text-base-content cursor-pointer hover:bg-base-200 rounded transition-colors">
        <span class="truncate">{inspect(@mod)}</span>
      </summary>
      <ul class="mt-1 ml-2">
        <%= for {scenario_name, _defaults} <- @reflection do %>
          <li>
            <.link
              patch={scenario_path(@mod, scenario_name)}
              class={[
                "flex items-center gap-2 px-3 py-2 min-h-11 text-sm truncate transition-colors",
                scenario_classes(@current_mailable, @current_scenario, @mod, scenario_name)
              ]}
            >
              {Atom.to_string(scenario_name)}
            </.link>
          </li>
        <% end %>
      </ul>
    </details>
    """
  end

  def mailable_entry(%{reflection: :no_previews} = assigns) do
    ~H"""
    <div class="flex items-center gap-2 px-3 py-2 min-h-11 text-sm text-secondary">
      <span class="truncate">{inspect(@mod)}</span>
      <Components.badge variant={:stub} />
      <span class="sr-only">No previews defined</span>
    </div>
    """
  end

  def mailable_entry(%{reflection: {:error, _msg}} = assigns) do
    ~H"""
    <.link
      patch={broken_path(@mod)}
      class="flex items-center gap-2 px-3 py-2 min-h-11 text-sm text-base-content hover:bg-base-200 rounded transition-colors"
    >
      <span class="truncate">{inspect(@mod)}</span>
      <Components.badge variant={:warning} />
    </.link>
    """
  end

  # Relative path helpers — browser resolves against the current LiveView's
  # document URL, so these work under any adopter mount path (`/dev/mail`,
  # `/admin/preview`, etc.).
  defp scenario_path(mod, scenario) do
    "./" <> inspect(mod) <> "/" <> Atom.to_string(scenario)
  end

  defp broken_path(mod) do
    "./" <> inspect(mod) <> "/__error__"
  end

  # Active-item highlight: matches current mailable AND scenario.
  defp scenario_classes(current_mod, current_scenario, mod, scenario)
       when current_mod == mod and current_scenario == scenario do
    "border-l-[3px] border-primary bg-base-200 text-base-content font-normal"
  end

  defp scenario_classes(_current_mod, _current_scenario, _mod, _scenario) do
    "border-l-[3px] border-transparent text-secondary hover:bg-base-200"
  end
end
