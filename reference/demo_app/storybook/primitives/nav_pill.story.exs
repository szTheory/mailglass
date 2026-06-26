defmodule Storybook.Primitives.NavPill do
  @moduledoc false
  # Compact operator navigation pill. Theme-sensitive (active pill paints the
  # Glass accent). Template-level data-theme bridge per PROJECT D-08.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Components.nav_pill/1

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
      %Variation{id: :active_light, attributes: %{label: "Overview", href: "#", active: true}},
      %Variation{
        id: :active_dark,
        template: @dark_template,
        attributes: %{label: "Overview", href: "#", active: true}
      },
      %Variation{id: :inactive_light, attributes: %{label: "Deliveries", href: "#", active: false}},
      %Variation{
        id: :inactive_dark,
        template: @dark_template,
        attributes: %{label: "Deliveries", href: "#", active: false}
      },
      %Variation{id: :disabled, attributes: %{label: "Inbound", href: "#", disabled: true}},
      %Variation{
        id: :long_label,
        attributes: %{label: "Deliverability and reputation overview", href: "#", active: false}
      }
    ]
  end
end
