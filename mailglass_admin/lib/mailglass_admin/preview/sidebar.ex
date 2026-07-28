defmodule MailglassAdmin.Preview.Sidebar do
  @moduledoc """
  Content-level email preview pickers with always-visible scenario groups and
  status badges. `picker/1` renders the full browse directory for the preview
  index; `menu/1` renders the compact document-selector control for individual
  preview pages.

  Branches on the second element of each
  `{mod, reflection}` tuple from `MailglassAdmin.Preview.Discovery.discover/1`:

    * `list when is_list(list)` — healthy mailable; render a static group label
      with scenario links. Active scenario gets a Glass left border;
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
  attr(:testid, :string, default: "preview-mailables-picker")

  @doc """
  Renders the email preview picker.

  `mailables` is the list of `{module, reflection}` tuples produced by
  `MailglassAdmin.Preview.Discovery.discover/1`. `current_mailable` and
  `current_scenario` drive the active-item highlight.
  """
  @doc since: "0.1.0"
  def picker(assigns) do
    ~H"""
    <section
      data-testid={@testid}
      data-picker-variant="directory"
      class="motion-reveal rounded-box border border-base-300 bg-base-200 p-md md:p-lg"
    >
      <div class="mb-md flex flex-wrap items-start justify-between gap-sm">
        <div class="min-w-0">
          <p class="text-label font-bold uppercase text-primary">Email previews</p>
          <h2 class="mt-xs text-heading font-bold text-base-content">Choose an email</h2>
        </div>
        <span class="rounded-field border border-base-300 bg-base-100 px-sm py-xs text-label font-bold text-secondary">
          {email_count_label(@mailables)}
        </span>
      </div>

      <ul class="grid gap-sm">
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
    </section>
    """
  end

  attr(:mailables, :list, required: true)
  attr(:current_mailable, :atom, default: nil)
  attr(:current_scenario, :atom, default: nil)
  attr(:device_width, :integer, default: 768)
  attr(:admin_chrome_theme, :atom, default: nil)
  attr(:mount_path, :string, default: nil)
  attr(:testid, :string, default: "preview-mailables-picker")

  @doc """
  Renders a compact grouped menu for switching the current email preview.

  This variant is intended for scenario pages, where the email itself is the
  primary content and the picker should behave like a document selector rather
  than a second navigation column.
  """
  def menu(assigns) do
    {_namespace, leaf} = current_mailable_parts(assigns.current_mailable)

    assigns =
      assigns
      |> assign(:current_leaf, leaf)
      |> assign(:current_scenario_label, current_scenario_label(assigns.current_scenario))
      |> assign(:current_title, current_title(assigns.current_mailable, assigns.current_scenario))

    ~H"""
    <details
      data-testid={@testid}
      data-picker-variant="menu"
      class="group relative mg-layer-dropdown min-w-0 w-full sm:max-w-md"
    >
      <summary
        data-testid="preview-email-menu-trigger"
        class="mg-focus-ring flex min-h-11 w-full max-w-full cursor-pointer list-none items-center gap-sm rounded-field border border-base-300 bg-base-100 px-sm py-xs text-left transition-colors ease-out duration-(--duration-fast) hover:bg-base-200 [&::-webkit-details-marker]:hidden"
      >
        <span class="min-w-0 flex-1">
          <span class="block text-label font-bold uppercase text-primary">Email preview</span>
          <span class="block truncate text-body font-bold text-base-content" title={@current_title}>
            {@current_leaf}
            <span :if={@current_scenario_label} class="font-normal text-secondary">
              · {@current_scenario_label}
            </span>
          </span>
        </span>
        <span
          data-testid="preview-email-menu-affordance"
          class="ml-xs flex h-8 w-8 shrink-0 items-center justify-center text-secondary transition-transform ease-out duration-(--duration-fast) group-open:rotate-180"
        >
          <span
            aria-hidden="true"
            class="h-2 w-2 rotate-45 border-r-2 border-b-2 border-current"
          >
          </span>
        </span>
      </summary>

      <div
        data-testid="preview-email-menu-panel"
        class="absolute left-0 mt-1 max-h-[70vh] w-full overflow-auto rounded-box border border-base-300 bg-base-100 p-xs shadow-overlay"
      >
        <ul class="grid gap-xs">
          <%= for {mod, reflection} <- @mailables do %>
            <li class="py-xs">
              <.mailable_menu_entry
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
    </details>
    """
  end

  @doc false
  def sidebar(assigns), do: picker(assigns)

  attr(:mod, :atom, required: true)
  attr(:reflection, :any, required: true)
  attr(:current_mailable, :atom, default: nil)
  attr(:current_scenario, :atom, default: nil)
  attr(:device_width, :integer, default: 768)
  attr(:admin_chrome_theme, :atom, default: nil)
  attr(:mount_path, :string, default: nil)

  def mailable_menu_entry(%{reflection: list} = assigns) when is_list(list) do
    ~H"""
    <div class="grid gap-xs">
      <.mailable_menu_label mod={@mod} />
      <ul data-testid="preview-email-menu-scenario-list" class="grid gap-0.5 pl-sm">
        <%= for {scenario_name, _defaults} <- @reflection do %>
          <li>
            <.link
              patch={
                scenario_path(@mount_path, @mod, scenario_name, @device_width, @admin_chrome_theme)
              }
              aria-current={
                scenario_selected?(@current_mailable, @current_scenario, @mod, scenario_name) &&
                  "page"
              }
              data-testid={
                if scenario_selected?(@current_mailable, @current_scenario, @mod, scenario_name),
                  do: "preview-email-menu-active-option",
                  else: "preview-email-menu-option"
              }
              class={[
                "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field px-sm py-xs text-body transition-colors ease-out duration-(--duration-fast)",
                menu_scenario_classes(@current_mailable, @current_scenario, @mod, scenario_name)
              ]}
            >
              <span class="min-w-0 flex-1 truncate">{Atom.to_string(scenario_name)}</span>
              <Components.icon
                :if={scenario_selected?(@current_mailable, @current_scenario, @mod, scenario_name)}
                name="hero-check"
                class="h-4 w-4 shrink-0 text-primary"
              />
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mailable_menu_entry(%{reflection: :no_previews} = assigns) do
    ~H"""
    <div class="grid gap-xs">
      <.mailable_menu_label mod={@mod} />
      <div data-testid="preview-email-menu-scenario-list" class="grid gap-0.5 pl-sm">
        <div class="flex min-h-11 items-center gap-sm rounded-field px-sm py-xs text-body text-secondary">
          <span class="min-w-0 flex-1 truncate">No previews defined</span>
          <Components.badge variant={:stub} />
        </div>
      </div>
    </div>
    """
  end

  def mailable_menu_entry(%{reflection: {:error, _msg}} = assigns) do
    ~H"""
    <div class="grid gap-xs">
      <.mailable_menu_label mod={@mod} />
      <div data-testid="preview-email-menu-scenario-list" class="grid gap-0.5 pl-sm">
        <.link
          patch={broken_path(@mount_path, @mod)}
          title="This Mailable raised while rendering"
          class="mg-focus-ring flex min-h-11 items-center gap-sm rounded-field px-sm py-xs text-body text-secondary transition-colors ease-out duration-(--duration-fast) hover:bg-base-200 hover:text-base-content"
        >
          <span class="min-w-0 flex-1 truncate">Render error</span>
          <Components.badge variant={:warning} />
          <span class="sr-only">This Mailable raised while rendering</span>
        </.link>
      </div>
    </div>
    """
  end

  defp mailable_menu_label(assigns) do
    {_namespace, leaf} = module_parts(assigns.mod)
    assigns = assign(assigns, leaf: leaf)

    ~H"""
    <div
      data-testid="preview-email-menu-group-label"
      class="min-w-0 px-sm pt-xs pb-0 text-label font-bold uppercase text-secondary"
      title={inspect(@mod)}
    >
      <span class="block truncate">{@leaf}</span>
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
    <div class="space-y-1">
      <div class="flex items-center gap-2 px-3 py-2 min-h-11 text-body font-bold text-base-content">
        <.mailable_label mod={@mod} />
      </div>
      <ul class="ml-2">
        <%= for {scenario_name, _defaults} <- @reflection do %>
          <li>
            <.link
              patch={
                scenario_path(@mount_path, @mod, scenario_name, @device_width, @admin_chrome_theme)
              }
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
    </div>
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

  defp current_mailable_parts(nil), do: {nil, "Choose an email"}
  defp current_mailable_parts(mod), do: module_parts(mod)

  defp current_scenario_label(nil), do: nil
  defp current_scenario_label(:__error__), do: "render error"
  defp current_scenario_label(scenario), do: Atom.to_string(scenario)

  defp current_title(nil, _scenario), do: "Choose an email preview"

  defp current_title(mod, scenario) do
    {_namespace, leaf} = current_mailable_parts(mod)

    leaf <>
      case current_scenario_label(scenario) do
        nil -> ""
        label -> " · " <> label
      end
  end

  defp email_count_label(mailables) do
    count =
      Enum.reduce(mailables, 0, fn
        {_mod, scenarios}, acc when is_list(scenarios) -> acc + length(scenarios)
        _other, acc -> acc
      end)

    if count == 1, do: "1 email", else: Integer.to_string(count) <> " emails"
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
  defp scenario_path(mount_path, mod, scenario, width, _admin_chrome_theme) do
    scenario_base_path(mount_path, mod, scenario) <>
      "?width=" <>
      Integer.to_string(width)
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

  defp scenario_selected?(current_mod, current_scenario, mod, scenario),
    do: current_mod == mod and current_scenario == scenario

  defp menu_scenario_classes(current_mod, current_scenario, mod, scenario) do
    if scenario_selected?(current_mod, current_scenario, mod, scenario) do
      "bg-primary/5 text-base-content"
    else
      "text-secondary hover:bg-base-200 hover:text-base-content"
    end
  end
end
