defmodule MailglassAdmin.Inbound.FiltersForm do
  @moduledoc """
  Compact filter controls for the inbound records screen.

  Sibling of `MailglassAdmin.Operator.FiltersForm` (the design contract). The mailbox-outcome
  select offers exactly the internal execution-run outcome set
  (`[:no_match, :accept, :ignore, :reject, :bounce, :failed]`) — the same closed
  set the read-model casts against (V5 input-validation allow-list).
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :form, Phoenix.HTML.Form, required: true
  attr :outcome_values, :list, required: true
  attr :window_options, :list, required: true
  attr :errors, :map, default: %{}

  def fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      description="Narrow InboundMessages without widening the tenant scope."
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
        help="Filter by inbound provider key, for example mailgun."
        error={field_error(@errors, "provider")}
        placeholder="mailgun"
      />

      <Components.filter_field
        field={@form[:outcome]}
        type={:select}
        label="Mailbox outcome"
        help="Filter by routing outcome."
        error={field_error(@errors, "outcome")}
        prompt="Any outcome"
        options={enum_options(@outcome_values)}
      />

      <Components.filter_field
        field={@form[:window_hours]}
        type={:select}
        label="Time window"
        help="Limit results to recently received messages."
        error={field_error(@errors, "window_hours")}
        options={@window_options}
      />

      <Components.filter_field
        field={@form[:search]}
        label="Search"
        help="Find by subject, recipient, or provider message id."
        error={field_error(@errors, "search")}
        placeholder="subject or recipient"
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
