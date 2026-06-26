defmodule Storybook.Primitives.StatCard do
  @moduledoc false
  # Canonical stat card: label, no-wrap value, severity. Theme-sensitive (surface
  # + severity color). Template-level data-theme bridge per PROJECT D-08. Covers
  # the gallery's full severity + state enumeration (structural.spec.js): neutral/
  # info/success/warning/error + empty/loading/unavailable + long-label/long-value.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Components.stat_card/1

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
      # Severity sweep (light + dark anchors)
      %Variation{
        id: :neutral_light,
        attributes: %{label: "Suppressions", value: 0, severity: :neutral}
      },
      %Variation{
        id: :neutral_dark,
        template: @dark_template,
        attributes: %{label: "Suppressions", value: 0, severity: :neutral}
      },
      %Variation{id: :info, attributes: %{label: "Queued", value: 12, severity: :info}},
      %Variation{
        id: :success_light,
        attributes: %{label: "Delivered", value: "1,204", severity: :success}
      },
      %Variation{
        id: :success_dark,
        template: @dark_template,
        attributes: %{label: "Delivered", value: "1,204", severity: :success}
      },
      %Variation{id: :warning, attributes: %{label: "Deferred", value: 7, severity: :warning}},
      %Variation{
        id: :error_light,
        attributes: %{label: "Bounced", value: 38, severity: :error}
      },
      %Variation{
        id: :error_dark,
        template: @dark_template,
        attributes: %{label: "Bounced", value: 38, severity: :error}
      },
      # Lifecycle states
      %Variation{id: :empty, attributes: %{label: "Complaints", state: :empty}},
      %Variation{id: :loading, attributes: %{label: "Delivered", state: :loading}},
      %Variation{id: :unavailable, attributes: %{label: "Open rate", state: :unavailable}},
      # Overflow stress
      %Variation{
        id: :long_label,
        attributes: %{
          label: "Provider-acknowledged deliverability over the trailing 30 days",
          value: 99,
          severity: :success
        }
      },
      %Variation{
        id: :long_value,
        attributes: %{label: "Events", value: "9,007,199,254,740,991", severity: :info}
      }
    ]
  end
end
