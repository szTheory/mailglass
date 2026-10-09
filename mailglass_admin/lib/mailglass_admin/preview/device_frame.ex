defmodule MailglassAdmin.Preview.DeviceFrame do
  @moduledoc """
  CSS-pixel-width segmented control: three buttons (375 / 768 / 1024) that
  drive the iframe's inline `width` style per 05-UI-SPEC lines 267-280.

  The component renders ONLY the toggle buttons — the iframe itself lives
  inside `MailglassAdmin.Preview.Tabs` so the chosen width propagates to
  the iframe's inline style.

  Accessibility: uses `role="group"` with a CSS-pixel `aria-label`
  and `aria-pressed` on each button per 05-UI-SPEC Accessibility
  Interactions lines 509-514.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  attr :device_width, :integer, values: [375, 768, 1024], default: 768

  @doc """
  Renders the 3-button CSS-pixel frame-width control.
  """
  @doc since: "0.1.0"
  def device_frame(assigns) do
    ~H"""
    <div class="join" role="group" aria-label="Preview frame width in CSS pixels">
      <button
        type="button"
        phx-click="set_device"
        phx-value-width="375"
        aria-pressed={to_string(@device_width == 375)}
        class={["btn btn-sm min-h-11 join-item", button_classes(@device_width == 375)]}
      >
        375 CSS px
      </button>
      <button
        type="button"
        phx-click="set_device"
        phx-value-width="768"
        aria-pressed={to_string(@device_width == 768)}
        class={["btn btn-sm min-h-11 join-item", button_classes(@device_width == 768)]}
      >
        768 CSS px
      </button>
      <button
        type="button"
        phx-click="set_device"
        phx-value-width="1024"
        aria-pressed={to_string(@device_width == 1024)}
        class={["btn btn-sm min-h-11 join-item", button_classes(@device_width == 1024)]}
      >
        1024 CSS px
      </button>
    </div>
    """
  end

  defp button_classes(true), do: "btn-primary"
  defp button_classes(false), do: "btn-ghost"
end
