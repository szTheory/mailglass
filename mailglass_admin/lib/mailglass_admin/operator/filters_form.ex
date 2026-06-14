defmodule MailglassAdmin.Operator.FiltersForm do
  @moduledoc """
  Compact filter controls for the operator deliveries screen.
  """

  use Phoenix.Component

  attr :form, Phoenix.HTML.Form, required: true
  attr :status_values, :list, required: true
  attr :event_values, :list, required: true
  attr :window_options, :list, required: true

  def fields(assigns) do
    ~H"""
    <label class="form-control">
      <span class="mb-1 text-label font-bold uppercase text-secondary">
        Tenant
      </span>
      <input
        type="text"
        name={@form[:tenant_id].name}
        value={@form[:tenant_id].value}
        class="input input-bordered min-h-11 w-full"
        placeholder="tenant-123"
      />
    </label>

    <label class="form-control">
      <span class="mb-1 text-label font-bold uppercase text-secondary">
        Provider
      </span>
      <input
        type="text"
        name={@form[:provider].name}
        value={@form[:provider].value}
        class="input input-bordered min-h-11 w-full"
        placeholder="postmark"
      />
    </label>

    <label class="form-control">
      <span class="mb-1 text-label font-bold uppercase text-secondary">
        Status
      </span>
      <select
        name={@form[:status].name}
        class="select select-bordered min-h-11 w-full"
      >
        <option value="">Any status</option>
        <%= for status <- @status_values do %>
          <option value={Atom.to_string(status)} selected={@form[:status].value == Atom.to_string(status)}>
            {label(status)}
          </option>
        <% end %>
      </select>
    </label>

    <label class="form-control">
      <span class="mb-1 text-label font-bold uppercase text-secondary">
        Event
      </span>
      <select
        name={@form[:event].name}
        class="select select-bordered min-h-11 w-full"
      >
        <option value="">Any event</option>
        <%= for event <- @event_values do %>
          <option value={Atom.to_string(event)} selected={@form[:event].value == Atom.to_string(event)}>
            {label(event)}
          </option>
        <% end %>
      </select>
    </label>

    <label class="form-control">
      <span class="mb-1 text-label font-bold uppercase text-secondary">
        Window
      </span>
      <select
        name={@form[:window_hours].name}
        class="select select-bordered min-h-11 w-full"
      >
        <%= for {copy, value} <- @window_options do %>
          <option value={value} selected={@form[:window_hours].value == value}>
            {copy}
          </option>
        <% end %>
      </select>
    </label>
    """
  end

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
