defmodule MailglassAdmin.Preview.AssignsForm do
  @moduledoc """
  Type-inferred assigns form per 05-UI-SPEC §"Assigns form — type-inferred
  fields" (lines 354-368) + 05-RESEARCH.md lines 1470-1571.

  Walks scenario defaults and edits only values with a lossless scalar parser:

    | Type              | Input                                       |
    |-------------------|---------------------------------------------|
    | `binary` (String) | `<input type="text">`                       |
    | `integer`         | `<input type="number" step="1">`            |
    | `float`           | `<input type="number" step="any">`          |
    | `boolean`         | `<input type="checkbox">`                   |
    | `atom`            | read-only Elixir value                      |
    | `DateTime`        | read-only Elixir value                      |
    | `Date`            | `<input type="date">`                       |
    | struct / `map`    | read-only Elixir value                      |
    | fallback          | read-only display row "(unsupported type)"  |

  Form fires `phx-change="assigns_changed"` on every field edit; the
  LiveView re-calls the mailable function with updated assigns and pipes
  through `Mailglass.Renderer.render/1`.

  Supported scalar changes render live. Reset restores the scenario defaults.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  attr :scenario_assigns, :map, required: true
  attr :draft_assigns, :map, default: %{}
  attr :field_errors, :map, default: %{}

  @doc """
  Renders the assigns form for the current scenario.
  """
  @doc since: "0.1.0"
  def assigns_form(assigns) do
    ~H"""
    <form
      id="preview-assigns-form"
      phx-change="assigns_changed"
      data-testid="preview-assigns-form"
      class="assigns-form space-y-4 rounded-box border border-base-300 bg-base-200 p-md"
    >
      <%= if editable_values?(@scenario_assigns) do %>
        <.field
          :for={{key, value} <- Enum.sort_by(@scenario_assigns, fn {k, _} -> Atom.to_string(k) end)}
          key={key}
          value={value}
          draft={Map.get(@draft_assigns, key)}
          error={Map.get(@field_errors, key)}
        />
      <% else %>
        <p data-testid="preview-no-editable-assigns" class="text-body text-secondary">
          There are no editable values here. Edit this scenario's defaults in its Mailable.
        </p>
      <% end %>

      <div class="flex flex-wrap gap-2">
        <button type="button" class="btn btn-ghost min-h-11 px-5" phx-click="reset_assigns">
          Reset assigns
        </button>
      </div>
    </form>
    """
  end

  attr :key, :atom, required: true
  attr :value, :any, required: true
  attr :draft, :any, default: nil
  attr :error, :string, default: nil

  # binary -> text input
  def field(%{value: v} = assigns) when is_binary(v) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} />
      <input
        id={@control_id}
        type="text"
        name={@control_name}
        value={@input_value}
        phx-debounce="150"
        aria-describedby={@described_by}
        aria-invalid={if @error, do: "true", else: nil}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
      <.field_error :if={@error} id={@error_id} text={@error} />
    </div>
    """
  end

  # integer -> number input, step 1
  def field(%{value: v} = assigns) when is_integer(v) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} />
      <input
        id={@control_id}
        type="number"
        step="1"
        name={@control_name}
        value={@input_value}
        aria-describedby={@described_by}
        aria-invalid={if @error, do: "true", else: nil}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
      <.field_error :if={@error} id={@error_id} text={@error} />
    </div>
    """
  end

  # float -> number input, step any
  def field(%{value: v} = assigns) when is_float(v) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} />
      <input
        id={@control_id}
        type="number"
        step="any"
        name={@control_name}
        value={@input_value}
        aria-describedby={@described_by}
        aria-invalid={if @error, do: "true", else: nil}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
      <.field_error :if={@error} id={@error_id} text={@error} />
    </div>
    """
  end

  # boolean -> checkbox
  def field(%{value: v} = assigns) when is_boolean(v) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <input type="hidden" name={@control_name} value="false" />
      <input
        id={@control_id}
        type="checkbox"
        name={@control_name}
        value="true"
        checked={@value}
        aria-describedby={@described_by}
        aria-invalid={if @error, do: "true", else: nil}
        class="checkbox checkbox-sm"
      />
      <.field_label
        for={@control_id}
        text={@label}
        class="label cursor-pointer justify-start gap-sm px-0"
      />
      <.field_help id={@help_id} text={@help_text} />
      <.field_error :if={@error} id={@error_id} text={@error} />
    </div>
    """
  end

  # DateTime is read-only because datetime-local loses timezone semantics.
  def field(%{value: %DateTime{}} = assigns) do
    assigns |> assign_control_metadata() |> assign(:type_badge, "DateTime") |> readonly_field()
  end

  # Date -> date
  def field(%{value: %Date{}} = assigns) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} />
      <input
        id={@control_id}
        type="date"
        name={@control_name}
        value={@input_value}
        aria-describedby={@described_by}
        aria-invalid={if @error, do: "true", else: nil}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
      <.field_error :if={@error} id={@error_id} text={@error} />
    </div>
    """
  end

  # Structs have no general-purpose form round-trip contract.
  def field(%{value: %{__struct__: _}} = assigns) do
    assigns
    |> assign_control_metadata()
    |> assign(:type_badge, inspect(assigns.value.__struct__))
    |> readonly_field()
  end

  # atom -> read-only display row
  def field(%{value: v} = assigns) when is_atom(v) do
    assigns
    |> assign_control_metadata()
    |> assign(:type_badge, "atom")
    |> readonly_field()
  end

  # Plain maps have no general-purpose form round-trip contract.
  def field(%{value: v} = assigns) when is_map(v) do
    assigns |> assign_control_metadata() |> assign(:type_badge, "map") |> readonly_field()
  end

  # fallback — read-only inspect
  def field(assigns) do
    assigns
    |> assign_control_metadata()
    |> assign(:type_badge, "unsupported type")
    |> readonly_field()
  end

  attr :for, :string, required: true
  attr :text, :string, required: true
  attr :badge, :string, default: nil
  attr :class, :string, default: "label px-0 pb-1"

  defp field_label(assigns) do
    ~H"""
    <label for={@for} class={@class}>
      <span class="label-text text-body font-normal">
        {@text}
        <span :if={@badge} class="text-label text-secondary font-mono">({@badge})</span>
      </span>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :text, :string, required: true

  defp field_help(assigns) do
    ~H"""
    <p id={@id} class="mt-1 text-label text-secondary">{@text}</p>
    """
  end

  attr :id, :string, required: true
  attr :text, :string, required: true

  defp field_error(assigns) do
    ~H"""
    <p id={@id} class="mt-1 text-label text-error">{@text}</p>
    """
  end

  defp readonly_field(assigns) do
    ~H"""
    <div class="form-control w-full">
      <p id={@label_id} class="label px-0 pb-1">
        <span class="label-text text-body font-normal">
          {@label} <span class="text-label text-secondary font-mono">({@type_badge})</span>
        </span>
      </p>
      <div
        id={@control_id}
        data-readonly-display="true"
        aria-labelledby={@label_id}
        aria-describedby={@help_id}
        aria-readonly="true"
        class="rounded-box border border-base-300 bg-base-200 p-3 font-mono text-label text-base-content"
      >
        {inspect(@value)}
      </div>
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
  end

  defp assign_control_metadata(assigns) do
    key = assigns.key

    assigns
    |> assign(:control_id, control_id(key))
    |> assign(:control_name, control_name(key))
    |> assign(:help_id, help_id(key))
    |> assign(:label_id, label_id(key))
    |> assign(:error_id, error_id(key))
    |> assign(:label, humanize(key))
    |> assign(:input_value, Map.get(assigns, :draft) || assigns.value)
    |> assign(:described_by, described_by(key, Map.get(assigns, :error)))
    |> assign(:help_text, help_text_for(assigns.value))
  end

  # Per-field help describes the value type and how to edit it — not a
  # restatement of the label (the old "Preview assign value for X." boilerplate
  # repeated the field name under every control and added no information).
  defp help_text_for(value) do
    cond do
      is_boolean(value) -> "Toggle on or off."
      is_binary(value) -> "Text value."
      is_integer(value) -> "Whole number."
      is_float(value) -> "Decimal number."
      is_struct(value, DateTime) -> "Read-only; edit it in the Mailable scenario."
      is_struct(value, Date) -> "Date."
      is_struct(value) or is_map(value) -> "Read-only; edit it in the Mailable scenario."
      is_atom(value) -> "Read-only; edit it in the Mailable scenario."
      true -> "Read-only; edit it in the Mailable scenario."
    end
  end

  defp editable_values?(assigns),
    do: Enum.any?(assigns, fn {_key, value} -> editable_value?(value) end)

  defp editable_value?(value),
    do:
      is_binary(value) or is_integer(value) or is_float(value) or is_boolean(value) or
        is_struct(value, Date)

  defp control_id(key), do: "assigns-" <> Atom.to_string(key)
  defp control_name(key), do: "assigns[" <> Atom.to_string(key) <> "]"
  defp help_id(key), do: control_id(key) <> "-help"
  defp error_id(key), do: control_id(key) <> "-error"
  defp described_by(key, nil), do: help_id(key)
  defp described_by(key, _error), do: help_id(key) <> " " <> error_id(key)
  defp label_id(key), do: control_id(key) <> "-label"

  # snake_case_atom -> "Snake case atom" (sentence case per UI-SPEC line 97)
  defp humanize(atom) when is_atom(atom) do
    [first | rest] = atom |> Atom.to_string() |> String.split("_")
    Enum.join([String.capitalize(first) | rest], " ")
  end
end
