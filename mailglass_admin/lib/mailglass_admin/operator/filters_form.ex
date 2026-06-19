defmodule MailglassAdmin.Operator.FiltersForm do
  @moduledoc """
  Compact filter controls for the operator deliveries screen.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :form, Phoenix.HTML.Form, required: true
  attr :status_values, :list, required: true
  attr :event_values, :list, required: true
  attr :window_options, :list, required: true
  attr :errors, :map, default: %{}

  def fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      description="Narrow Deliveries without widening the tenant scope."
    >
      <Components.filter_field
        field={@form[:tenant_id]}
        label="Tenant"
        help="Filter to one tenant id."
        error={field_error(@errors, "tenant_id")}
        placeholder="tenant-123"
      />

      <Components.filter_field
        field={@form[:provider]}
        label="Provider"
        help="Filter by provider key, for example postmark."
        error={field_error(@errors, "provider")}
        placeholder="postmark"
      />

      <Components.filter_field
        field={@form[:status]}
        type={:select}
        label="Status"
        help="Filter by delivery status."
        error={field_error(@errors, "status")}
        prompt="Any status"
        options={enum_options(@status_values)}
      />

      <Components.filter_field
        field={@form[:event]}
        type={:select}
        label="Event"
        help="Filter by latest delivery event."
        error={field_error(@errors, "event")}
        prompt="Any event"
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
