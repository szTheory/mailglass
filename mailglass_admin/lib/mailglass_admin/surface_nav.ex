defmodule MailglassAdmin.SurfaceNav do
  @moduledoc false

  # One `nav` landmark holding, in DOM order: the optional Preview Back link,
  # the Account scope group (header + Health, Deliveries, Inbound), and the
  # Preview link below a divider. The group is the thing the Account control
  # scopes, so Preview (which reads no Account data) sits outside it (D-09).

  use Phoenix.Component

  alias MailglassAdmin.Components

  @scoped_items [
    %{key: :overview, label: "Health", icon: "hero-check-circle"},
    %{key: :deliveries, label: "Deliveries", icon: "hero-paper-airplane"},
    %{key: :inbound, label: "Inbound", icon: "hero-inbox-arrow-down"}
  ]

  @preview_item %{key: :preview, label: "Preview", icon: "hero-eye"}

  attr(:active, :atom, values: [:preview, :overview, :deliveries, :inbound], required: true)
  attr(:preview_path, :string, default: nil)
  attr(:overview_path, :string, default: nil)
  attr(:deliveries_path, :string, default: nil)
  attr(:inbound_path, :string, default: nil)
  attr(:inbound_available?, :boolean, default: false)
  attr(:layout, :atom, values: [:sidebar, :mobile], default: :sidebar)
  attr(:return_href, :string, default: nil)
  attr(:return_label, :string, default: nil)

  # `:preview` is the safe default: a call site that forgets to pass the Account
  # header shows no Account identity rather than a fake one (D-11).
  attr(:scope, :atom, values: [:account, :preview], default: :preview)

  # The group is named by one label element, not by the whole header: the
  # `:account` header also holds the sr-only `tenant_id`, which must not become
  # part of the group's accessible name (D-13). The slot receives the id its
  # label element must carry (`:let={label_id}`).
  slot(:scope_header)

  def nav(assigns) do
    scoped = visible_items(assigns, @scoped_items)
    preview = visible_items(assigns, [@preview_item])

    assigns =
      assigns
      |> assign(:scoped_items, scoped)
      |> assign(:preview_items, preview)
      |> assign(:description, description(scoped))
      |> assign(:header_id, "surface-nav-scope-header-#{assigns.layout}")
      |> assign(:label_id, "surface-nav-scope-label-#{assigns.layout}")
      |> assign(:desc_id, "surface-nav-scope-desc-#{assigns.layout}")
      |> assign(:caption_id, "surface-nav-preview-caption-#{assigns.layout}")

    ~H"""
    <nav
      class={nav_class(@layout)}
      aria-label="Mailglass sections"
      data-testid={"surface-nav-#{@layout}"}
    >
      <.link
        :if={@return_href && @return_label}
        href={@return_href}
        data-testid="preview-return-link"
        data-layout={@layout}
        class="mg-focus-ring inline-flex min-h-11 items-center gap-xs rounded-field px-sm text-body text-secondary transition-colors hover:text-base-content"
      >
        <Components.icon name="hero-arrow-uturn-left" class="h-4 w-4 shrink-0" />
        <span>{@return_label}</span>
      </.link>
      <div
        data-account-scope
        role="group"
        data-testid="surface-nav-scope-group"
        data-layout={@layout}
        aria-labelledby={if @scope == :account, do: @label_id, else: @header_id}
        aria-describedby={@scope == :account && @desc_id}
        class="w-full rounded-box border border-base-300 bg-base-100"
      >
        <div id={@header_id} class="relative border-b border-base-300 p-sm md:static">
          <%= if @scope == :account do %>
            {render_slot(@scope_header, @label_id)}
          <% else %>
            <p data-testid="preview-scope-label" class="text-label font-bold text-secondary">
              Scoped to an Account
            </p>
          <% end %>
        </div>
        <div data-testid="surface-nav-scope-items" class={scoped_class(@layout)}>
          <%= for item <- @scoped_items do %>
            <Components.nav_link
              :if={@layout == :sidebar}
              label={item.label}
              icon={item.icon}
              href={item.path}
              active={@active == item.key}
              navigate={false}
            />
            <Components.nav_pill
              :if={@layout == :mobile}
              label={item.label}
              href={item.path}
              active={@active == item.key}
              navigate={false}
            />
          <% end %>
        </div>
        <span
          :if={@scope == :account}
          id={@desc_id}
          data-testid="surface-nav-scope-description"
          class="sr-only"
        >
          {@description}
        </span>
      </div>
      <div
        :if={@preview_items != []}
        data-testid="surface-nav-preview-block"
        class={preview_block_class(@layout)}
      >
        <%= for item <- @preview_items do %>
          <Components.nav_link
            :if={@layout == :sidebar}
            label={item.label}
            icon={item.icon}
            href={item.path}
            active={@active == item.key}
            navigate={false}
            aria-describedby={@caption_id}
          />
          <Components.nav_pill
            :if={@layout == :mobile}
            label={item.label}
            href={item.path}
            active={@active == item.key}
            navigate={false}
            aria-describedby={@caption_id}
          />
        <% end %>
        <p
          id={@caption_id}
          data-testid="surface-nav-preview-caption"
          class={caption_class(@layout)}
        >
          Not tied to an Account
        </p>
      </div>
    </nav>
    """
  end

  defp visible_items(assigns, items) do
    Enum.flat_map(items, fn item ->
      case item_path(assigns, item.key) do
        nil -> []
        path -> [Map.put(item, :path, path)]
      end
    end)
  end

  # "Applies to Health, Deliveries and Inbound." derived from what is rendered,
  # so it never names an absent Inbound (D-13).
  defp description(items) do
    labels = Enum.map(items, & &1.label)

    case Enum.split(labels, -1) do
      {[], []} -> ""
      {[], [only]} -> "Applies to #{only}."
      {init, [last]} -> "Applies to #{Enum.join(init, ", ")} and #{last}."
    end
  end

  defp item_path(assigns, :preview), do: blank_to_nil(assigns.preview_path)
  defp item_path(assigns, :overview), do: blank_to_nil(assigns.overview_path)
  defp item_path(assigns, :deliveries), do: blank_to_nil(assigns.deliveries_path)

  defp item_path(assigns, :inbound) do
    if assigns.inbound_available? do
      blank_to_nil(assigns.inbound_path)
    end
  end

  defp nav_class(:sidebar), do: "flex flex-col gap-xs"
  defp nav_class(:mobile), do: "flex flex-col gap-xs"

  defp scoped_class(:sidebar), do: "flex flex-col gap-xs p-xs"
  defp scoped_class(:mobile), do: "flex flex-wrap items-center gap-xs p-xs"

  defp preview_block_class(:sidebar), do: "mt-md border-t border-base-300 pt-md"

  defp preview_block_class(:mobile),
    do: "mt-md flex flex-wrap items-center gap-x-sm gap-y-xs border-t border-base-300 pt-md"

  defp caption_class(:sidebar), do: "px-sm text-label text-secondary"
  defp caption_class(:mobile), do: "min-w-0 text-label text-secondary"

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
