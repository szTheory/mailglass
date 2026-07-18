defmodule MailglassAdmin.Operator.FiltersForm do
  @moduledoc """
  Compact filter controls for the operator deliveries screen.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:account_options, :list, default: [])
  attr(:provider_options, :list, default: [])
  attr(:event_values, :list, required: true)
  attr(:window_options, :list, required: true)
  attr(:errors, :map, default: %{})

  def fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      description="Show email activity for one account, then narrow by provider, status, or time."
    >
      <Components.filter_field
        field={@form[:tenant_id]}
        type={:select}
        label="Account"
        help="Account maps to tenant_id in code and URLs."
        error={field_error(@errors, "tenant_id")}
        prompt="Choose account"
        options={@account_options}
      />

      <Components.filter_field
        field={@form[:provider]}
        type={:select}
        label="Provider"
        help="Filter by the sending provider recorded for this account."
        error={field_error(@errors, "provider")}
        prompt="Any provider"
        options={@provider_options}
      />

      <Components.filter_field
        field={@form[:event]}
        type={:select}
        label="Status"
        help="Filter by the message's latest delivery status."
        error={field_error(@errors, "event")}
        prompt="Any status"
        options={enum_options(@event_values)}
      />

      <Components.filter_field
        field={@form[:window_hours]}
        type={:select}
        label="Time window"
        help="Limit results to recent delivery activity."
        error={field_error(@errors, "window_hours")}
        options={@window_options}
      />
    </Components.filter_section>
    """
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
