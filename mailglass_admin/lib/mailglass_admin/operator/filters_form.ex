defmodule MailglassAdmin.Operator.FiltersForm do
  @moduledoc """
  Compact filter controls for the operator deliveries screen.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:committed_search, :string, default: "")

  @doc """
  The email search, the first control on the Activity screen at every width. It sits
  above the collapsible filter panel, inside the same form, so the operator can type the
  customer's address before opening any filter.
  """
  def search_field(assigns) do
    ~H"""
    <Components.filter_field
      field={@form[:search]}
      type={:search}
      label="Email address"
      help="Also matches subjects."
      placeholder="Subject or recipient"
      autocomplete="off"
      enterkeyhint="search"
      data-committed={@committed_search}
      phx-debounce="300"
      phx-hook="FilterSearchSync"
    />
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:provider_options, :list, default: [])
  attr(:event_values, :list, required: true)
  attr(:window_options, :list, required: true)
  attr(:errors, :map, default: %{})

  @doc "The remaining filters: time window, latest event and provider."
  def other_fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      compact
      columns={4}
    >
      <Components.filter_field
        field={@form[:window_hours]}
        type={:select}
        label="Time window"
        help="Show emails with activity during this period."
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
        options={enum_options(@event_values, @form[:event].value)}
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

  # A rejected enum value stays selected as a "Not applied" option so the select never
  # shows its prompt beside its "was not applied" error (D-12). The option is enabled on
  # purpose: a disabled option is left out of form submission, so the next change event
  # would post no value and silently clear the filter.
  defp enum_options(values, current) do
    listed = enum_options(values)
    current = current |> to_string() |> String.trim()

    if current != "" and not Enum.any?(listed, fn {_label, value} -> value == current end) do
      [{"Not applied: " <> current, current} | listed]
    else
      listed
    end
  end

  defp enum_options(values) do
    Enum.map(values, &{label(&1), Atom.to_string(&1)})
  end

  defp field_error(errors, field), do: Map.get(errors, field)
end
