defmodule MailglassAdmin.Inbound.FiltersForm do
  @moduledoc """
  Compact filter controls for the inbound records screen.

  Sibling of `MailglassAdmin.Operator.FiltersForm` (the design contract). The mailbox-outcome
  select offers exactly the internal execution-run outcome set
  (`[:no_match, :accept, :ignore, :reject, :bounce, :failed]`) — the same closed
  set the read-model casts against (V5 input-validation allow-list).
  """

  use Phoenix.Component

  attr :form, Phoenix.HTML.Form, required: true
  attr :outcome_values, :list, required: true
  attr :window_options, :list, required: true

  def fields(assigns) do
    ~H"""
    <label class="form-control">
      <span class="mb-1 text-label uppercase font-bold text-secondary">
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
      <span class="mb-1 text-label uppercase font-bold text-secondary">
        Provider
      </span>
      <input
        type="text"
        name={@form[:provider].name}
        value={@form[:provider].value}
        class="input input-bordered min-h-11 w-full"
        placeholder="mailgun"
      />
    </label>

    <label class="form-control">
      <span class="mb-1 text-label uppercase font-bold text-secondary">
        Mailbox outcome
      </span>
      <select
        name={@form[:outcome].name}
        class="select select-bordered min-h-11 w-full"
      >
        <option value="">Any outcome</option>
        <%= for outcome <- @outcome_values do %>
          <option
            value={Atom.to_string(outcome)}
            selected={@form[:outcome].value == Atom.to_string(outcome)}
          >
            {label(outcome)}
          </option>
        <% end %>
      </select>
    </label>

    <label class="form-control">
      <span class="mb-1 text-label uppercase font-bold text-secondary">
        Time window
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

    <label class="form-control">
      <span class="mb-1 text-label uppercase font-bold text-secondary">
        Search
      </span>
      <input
        type="text"
        name={@form[:search].name}
        value={@form[:search].value}
        class="input input-bordered min-h-11 w-full"
        placeholder="subject or recipient"
      />
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
