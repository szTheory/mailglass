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

  attr(:mailables, :list, required: true)
  attr(:current_mailable, :atom, default: nil)
  attr(:current_scenario, :atom, default: nil)
  attr(:device_width, :integer, default: 768)
  attr(:admin_chrome_theme, :atom, default: nil)
  attr(:mount_path, :string, default: nil)

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
      <h2 class="text-body font-bold text-base-content">Mailables</h2>

      <ul class="space-y-1">
        <%= for {mod, reflection} <- @mailables do %>
          <li>
            <.mailable_entry
              mod={mod}
              reflection={reflection}
              current_mailable={@current_mailable}
              current_scenario={@current_scenario}
              device_width={@device_width}
              admin_chrome_theme={@admin_chrome_theme}
              mount_path={@mount_path}
            />
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr(:mod, :atom, required: true)
  attr(:reflection, :any, required: true)
  attr(:current_mailable, :atom, default: nil)
  attr(:current_scenario, :atom, default: nil)
  attr(:device_width, :integer, default: 768)
  attr(:admin_chrome_theme, :atom, default: nil)
  attr(:mount_path, :string, default: nil)

  # Function component dispatched by reflection shape. Phoenix.Component
  # requires `def` (not `defp`) for `<.mailable_entry ... />` invocation.
  def mailable_entry(%{reflection: list} = assigns) when is_list(list) do
    ~H"""
    <details open={@current_mailable == @mod}>
      <summary class="mg-focus-ring flex items-center gap-2 px-3 py-2 min-h-11 text-body font-bold text-base-content cursor-pointer hover:bg-base-200 rounded transition-colors">
        <.mailable_label mod={@mod} />
      </summary>
      <ul class="mt-1 ml-2">
        <%= for {scenario_name, _defaults} <- @reflection do %>
          <li>
            <.link
              patch={scenario_path(@mount_path, @mod, scenario_name, @device_width, @admin_chrome_theme)}
              class={[
                "mg-focus-ring flex items-center gap-2 px-3 py-2 min-h-11 text-body truncate transition-colors",
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
    <div class="flex items-center gap-2 px-3 py-2 min-h-11 text-body text-secondary">
      <.mailable_label mod={@mod} />
      <Components.badge variant={:stub} />
      <span class="sr-only">No previews defined</span>
    </div>
    """
  end

  def mailable_entry(%{reflection: {:error, _msg}} = assigns) do
    ~H"""
    <.link
      patch={broken_path(@mount_path, @mod)}
      title="This Mailable raised while rendering"
      class="mg-focus-ring flex items-center gap-2 px-3 py-2 min-h-11 text-body text-base-content hover:bg-base-200 rounded transition-colors"
    >
      <.mailable_label mod={@mod} />
      <Components.badge variant={:warning} />
      <span class="sr-only">This Mailable raised while rendering</span>
    </.link>
    """
  end

  attr(:mod, :atom, required: true)

  # Two-tier mailable label: the leaf module (what operators actually scan for)
  # reads prominently while the namespace is de-emphasized above it. Truncation
  # now bites the namespace, never the leaf — the old single-line `inspect/1`
  # truncated the meaningful end ("MailglassDemoWeb.Mailers.Accoun…").
  defp mailable_label(assigns) do
    {namespace, leaf} = module_parts(assigns.mod)
    assigns = assign(assigns, namespace: namespace, leaf: leaf)

    ~H"""
    <span class="flex min-w-0 flex-1 flex-col leading-tight" title={inspect(@mod)}>
      <span :if={@namespace} class="truncate text-label font-normal text-secondary">
        {@namespace}
      </span>
      <span class="truncate">{@leaf}</span>
    </span>
    """
  end

  # Splits a module into {namespace, leaf}. A single-segment module has no
  # namespace tier (nil), so it renders as a one-line label.
  defp module_parts(mod) do
    case String.split(inspect(mod), ".") do
      [single] -> {nil, single}
      parts -> {parts |> Enum.drop(-1) |> Enum.join("."), List.last(parts)}
    end
  end

  @doc """
  Absolute `/<mount>/<Mailable>/<scenario>` path (no query string).

  Shared by the sidebar links and `PreviewLive`'s start-page deep link so
  both build identical, mount-aware URLs. `mount_path` is the absolute base
  the admin surface is mounted at (`/dev/mail`, `/admin/preview`, …) as
  recovered by `MailglassAdmin.MountPath.base/1`.
  """
  @spec scenario_base_path(String.t() | nil, module(), atom() | String.t()) :: String.t()
  def scenario_base_path(mount_path, mod, scenario) do
    base = mount_path || ""
    base <> "/" <> inspect(mod) <> "/" <> to_string(scenario)
  end

  # Absolute scenario link helpers. The mount path has no trailing slash, so a
  # relative (`./`) reference would resolve against the parent directory and
  # drop the mount's final segment (e.g. `/dev/mail` -> `/dev/<Mailable>`),
  # 404-ing the `/:mailable/:scenario` route. Build absolute paths instead.
  defp scenario_path(mount_path, mod, scenario, width, admin_chrome_theme) do
    path =
      scenario_base_path(mount_path, mod, scenario) <>
        "?width=" <>
        Integer.to_string(width)

    case theme_param(admin_chrome_theme) do
      nil -> path
      theme -> path <> "&theme=" <> theme
    end
  end

  defp broken_path(mount_path, mod) do
    scenario_base_path(mount_path, mod, "__error__")
  end

  # Active-item highlight: matches current mailable AND scenario.
  defp scenario_classes(current_mod, current_scenario, mod, scenario)
       when current_mod == mod and current_scenario == scenario do
    "border-l-2 border-primary bg-base-200 text-base-content font-normal"
  end

  defp scenario_classes(_current_mod, _current_scenario, _mod, _scenario) do
    "border-l-2 border-transparent text-secondary hover:bg-base-200"
  end

  defp theme_param(:dark), do: "dark"
  defp theme_param(:light), do: "light"
  defp theme_param(_theme), do: nil
end
