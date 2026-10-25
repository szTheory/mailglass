defmodule MailglassAdmin.Operator.FiltersForm do
  @moduledoc """
  Compact filter controls for the operator deliveries screen.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:provider_options, :list, default: [])
  attr(:event_values, :list, required: true)
  attr(:window_options, :list, required: true)
  attr(:errors, :map, default: %{})

  def fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      compact
      columns={4}
    >
      <Components.filter_field
        field={@form[:search]}
        label="Search"
        help="Find deliveries by recipient email address or subject."
        help_display={:tooltip}
        placeholder="Subject or recipient"
      />

      <Components.filter_field
        field={@form[:window_hours]}
        type={:select}
        label="Time window"
        help="Show deliveries with activity during this period."
        help_display={:tooltip}
        error={field_error(@errors, "window_hours")}
        options={window_options(@window_options, @form[:window_hours].value)}
      />

      <Components.filter_field
        field={@form[:event]}
        type={:select}
        label="Latest recorded event"
        help="Filter by the latest event recorded for each delivery."
        help_display={:tooltip}
        error={field_error(@errors, "event")}
        prompt="Any status"
        options={enum_options(@event_values)}
      />

      <Components.filter_field
        field={@form[:provider]}
        type={:select}
        label="Provider"
        help="Filter by the sending provider recorded for this account."
        help_display={:tooltip}
        error={field_error(@errors, "provider")}
        prompt="Any provider"
        options={@provider_options}
      />
    </Components.filter_section>
    """
  end

  defp window_options(options, value) do
    value = to_string(value || "")

    if Enum.any?(options, fn {_label, hours} -> to_string(hours) == value end) do
      options
    else
      [{"Custom period (#{value} hours)", value} | options]
    end
  end

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp enum_options(values) do
    Enum.map(values, &{label(&1), Atom.to_string(&1)})
  end

  defp field_error(errors, field), do: Map.get(errors, field)
end
