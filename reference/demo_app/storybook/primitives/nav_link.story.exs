defmodule Storybook.Primitives.NavLink do
  @moduledoc false
  # Desktop operator navigation link. Theme-sensitive (active state paints the
  # Glass accent + base-content), so every variation is wrapped at the TEMPLATE
  # level with data-theme on a .mg-admin-root root (PROJECT D-08). Light is the
  # default story template; dark variations override `template:` with the dark
  # root. Mirrors the gallery's nav_link state enumeration (structural.spec.js).
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Components.nav_link/1

  # Default (light) wrapper. `data-theme="mailglass-light"` is set here, not via a
  # CSS class alias. The bg-base-100 + p-md give the sandboxed primitive its
  # surface so contrast reads true.
  def template do
    """
    <div data-theme="mailglass-light" class="mg-admin-root bg-base-100 text-base-content p-md">
      <.psb-variation/>
    </div>
    """
  end

  @dark_template """
  <div data-theme="mailglass-dark" class="mg-admin-root bg-base-100 text-base-content p-md">
    <.psb-variation/>
  </div>
  """

  def variations do
    [
      %Variation{
        id: :active_light,
        attributes: %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: true}
      },
      %Variation{
        id: :active_dark,
        template: @dark_template,
        attributes: %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: true}
      },
      %Variation{
        id: :inactive_light,
        attributes: %{label: "Inbound", icon: "hero-inbox", href: "#", active: false}
      },
      %Variation{
        id: :inactive_dark,
        template: @dark_template,
        attributes: %{label: "Inbound", icon: "hero-inbox", href: "#", active: false}
      },
      %Variation{
        id: :disabled,
        attributes: %{label: "Suppressions", icon: "hero-no-symbol", href: "#", disabled: true}
      },
      %Variation{
        id: :long_label,
        attributes: %{
          label: "Operations and deliverability diagnostics overview",
          icon: "hero-chart-bar",
          href: "#",
          active: false
        }
      }
    ]
  end
end
