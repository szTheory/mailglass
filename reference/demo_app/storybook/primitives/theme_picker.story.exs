defmodule Storybook.Primitives.ThemePicker do
  @moduledoc false
  # Three-choice theme picker (System/Light/Dark). Theme-sensitive (selected
  # segment paints the Glass accent). Template-level data-theme bridge per
  # PROJECT D-08. Covers the gallery's selection + disabled states.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Components.theme_picker/1

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
      %Variation{id: :system_selected_light, attributes: %{selected: :system}},
      %Variation{
        id: :system_selected_dark,
        template: @dark_template,
        attributes: %{selected: :system}
      },
      %Variation{id: :light_selected, attributes: %{selected: :light}},
      %Variation{
        id: :dark_selected,
        template: @dark_template,
        attributes: %{selected: :dark}
      },
      %Variation{id: :disabled, attributes: %{selected: :system, disabled: true}}
    ]
  end
end
