defmodule MailglassAdmin.SurfaceNav do
  @moduledoc false

  use Phoenix.Component

  alias MailglassAdmin.Components

  @items [
    %{key: :overview, label: "Health", icon: "hero-check-circle"},
    %{key: :preview, label: "Preview", icon: "hero-eye"},
    %{key: :deliveries, label: "Deliveries", icon: "hero-paper-airplane"},
    %{key: :inbound, label: "Inbound", icon: "hero-inbox-arrow-down"}
  ]

  attr(:active, :atom, values: [:preview, :overview, :deliveries, :inbound], required: true)
  attr(:preview_path, :string, default: nil)
  attr(:overview_path, :string, default: nil)
  attr(:deliveries_path, :string, default: nil)
  attr(:inbound_path, :string, default: nil)
  attr(:inbound_available?, :boolean, default: false)
  attr(:layout, :atom, values: [:sidebar, :mobile], default: :sidebar)

  def nav(assigns) do
    assigns = assign(assigns, :items, visible_items(assigns))

    ~H"""
    <nav
      class={nav_class(@layout)}
      aria-label="Mailglass sections"
      data-testid={"surface-nav-#{@layout}"}
    >
      <%= for item <- @items do %>
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
    </nav>
    """
  end

  defp visible_items(assigns) do
    Enum.flat_map(@items, fn item ->
      case item_path(assigns, item.key) do
        nil -> []
        path -> [Map.put(item, :path, path)]
      end
    end)
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
  defp nav_class(:mobile), do: "flex flex-wrap items-center gap-xs"

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
