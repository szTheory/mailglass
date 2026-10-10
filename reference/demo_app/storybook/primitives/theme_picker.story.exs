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
      %Variation{
        id: :system_selected_light,
        attributes: %{selected: :system, name: "storybook_theme_system_selected_light"}
      },
      %Variation{
        id: :system_selected_dark,
        template: @dark_template,
        attributes: %{selected: :system, name: "storybook_theme_system_selected_dark"}
      },
      %Variation{
        id: :light_selected,
        attributes: %{selected: :light, name: "storybook_theme_light_selected"}
      },
      %Variation{
        id: :dark_selected,
        template: @dark_template,
        attributes: %{selected: :dark, name: "storybook_theme_dark_selected"}
      },
      %Variation{
        id: :disabled,
        attributes: %{
          selected: :system,
          disabled: true,
          name: "storybook_theme_disabled"
        }
      }
    ]
  end
end
