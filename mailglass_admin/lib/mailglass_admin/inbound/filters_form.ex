defmodule MailglassAdmin.Inbound.FiltersForm do
  @moduledoc """
  Compact filter controls for the inbound records screen.

  Sibling of `MailglassAdmin.Operator.FiltersForm`. The mailbox-outcome
  select offers exactly the internal execution-run outcome set
  (`[:no_match, :accept, :ignore, :no_change, :reject, :bounce, :failed]`) — the same closed
  set the read-model casts against (V5 input-validation allow-list).
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:provider_options, :list, default: [])
  attr(:outcome_values, :list, required: true)
  attr(:window_options, :list, required: true)
  attr(:errors, :map, default: %{})
  attr(:committed_search, :string, default: "")

  def fields(assigns) do
    ~H"""
    <Components.filter_section
      title="Filters"
      compact
    >
      <Components.filter_field
        field={@form[:search]}
        label="Search"
        help="Find by subject, recipient, or provider message id."
        help_display={:tooltip}
        error={field_error(@errors, "search")}
        placeholder="Subject or recipient"
        autocomplete="off"
        enterkeyhint="search"
        data-committed={@committed_search}
        phx-debounce="300"
        phx-hook="FilterSearchSync"
      />

      <Components.filter_field
        field={@form[:window_hours]}
        type={:select}
        label="Time window"
        help="Limit results to recently received messages."
        help_display={:tooltip}
        error={field_error(@errors, "window_hours")}
        options={window_options(@window_options, @form[:window_hours].value)}
      />

      <Components.filter_field
        field={@form[:outcome]}
        type={:select}
        label="Mailbox outcome"
        help="Filter by the latest fresh mailbox outcome, including unrouted messages and no change. The summary is hidden while this filter is applied."
        help_display={:tooltip}
        error={field_error(@errors, "outcome")}
        prompt="Any outcome"
        options={enum_options(@outcome_values, @form[:outcome].value)}
      />

      <Components.filter_field
        field={@form[:provider]}
        type={:select}
        label="Provider"
        help="Filter by the inbound provider recorded for this account."
        help_display={:tooltip}
        error={field_error(@errors, "provider")}
        prompt="Any provider"
        options={@provider_options}
      />
    </Components.filter_section>
    """
  end

  # A rejected window stays selected as a custom option so the select never contradicts
  # its error message (D-12).
  defp window_options(options, value) do
    value = to_string(value || "")

    if Enum.any?(options, fn {_label, hours} -> to_string(hours) == value end) do
      options
    else
      [{"Custom period (#{value} hours)", value} | options]
    end
  end

  defp label(nil), do: "Unknown"

  defp label(:no_match), do: "Unrouted"
  defp label(:accept), do: "Accepted"
  defp label(:ignore), do: "Ignored"
  defp label(:no_change), do: "No change"
  defp label(:reject), do: "Rejected"
  defp label(:bounce), do: "Bounced"
  defp label(:failed), do: "Failed"

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
