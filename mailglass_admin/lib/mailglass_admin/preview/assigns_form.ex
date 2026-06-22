defmodule MailglassAdmin.Preview.AssignsForm do
  @moduledoc """
  Type-inferred assigns form per 05-UI-SPEC §"Assigns form — type-inferred
  fields" (lines 354-368) + 05-RESEARCH.md lines 1470-1571.

  Walks the scenario defaults map and renders an input per key dispatched
  by the Elixir type of the default value:

    | Type              | Input                                       |
    |-------------------|---------------------------------------------|
    | `binary` (String) | `<input type="text">`                       |
    | `integer`         | `<input type="number" step="1">`            |
    | `float`           | `<input type="number" step="any">`          |
    | `boolean`         | `<input type="checkbox">`                   |
    | `atom`            | read-only display row (URL edit only)       |
    | `DateTime`        | `<input type="datetime-local">`             |
    | `Date`            | `<input type="date">`                       |
    | struct            | `<textarea>` JSON (struct label)            |
    | `map`             | `<textarea>` JSON (plain map)               |
    | fallback          | read-only display row "(unsupported type)"  |

  Form fires `phx-change="assigns_changed"` on every field edit; the
  LiveView re-calls the mailable function with updated assigns and pipes
  through `Mailglass.Renderer.render/1`.

  Action buttons use the verb+noun copy locked in 05-UI-SPEC Copywriting
  Contract lines 453-458: "Render preview" + "Reset assigns". The voice
  test greps the rendered HTML for these exact strings.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  attr :scenario_assigns, :map, required: true

  @doc """
  Renders the assigns form for the current scenario.
  """
  @doc since: "0.1.0"
  def assigns_form(assigns) do
    ~H"""
    <form
      phx-change="assigns_changed"
      data-testid="preview-assigns-form"
      class="assigns-form space-y-4 rounded-box border border-base-300 bg-base-200 p-md"
    >
      <%= for {key, value} <- Enum.sort_by(@scenario_assigns, fn {k, _} -> Atom.to_string(k) end) do %>
        <.field key={key} value={value} />
      <% end %>

      <div class="flex flex-wrap gap-2">
        <button type="button" class="btn btn-primary min-h-11 px-5" phx-click="render_preview">
          Render preview
        </button>
        <button type="button" class="btn btn-ghost min-h-11 px-5" phx-click="reset_assigns">
          Reset assigns
        </button>
      </div>
    </form>
    """
  end

  attr :key, :atom, required: true
  attr :value, :any, required: true

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
        value={@value}
        aria-describedby={@help_id}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
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
        value={Integer.to_string(@value)}
        aria-describedby={@help_id}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
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
        value={Float.to_string(@value)}
        aria-describedby={@help_id}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
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
        aria-describedby={@help_id}
        class="checkbox checkbox-sm"
      />
      <.field_label
        for={@control_id}
        text={@label}
        class="label cursor-pointer justify-start gap-sm px-0"
      />
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
  end

  # DateTime -> datetime-local
  def field(%{value: %DateTime{}} = assigns) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} />
      <input
        id={@control_id}
        type="datetime-local"
        name={@control_name}
        value={DateTime.to_iso8601(@value)}
        aria-describedby={@help_id}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
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
        value={Date.to_iso8601(@value)}
        aria-describedby={@help_id}
        class="input input-bordered input-sm w-full"
      />
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
  end

  # struct -> JSON textarea with struct label
  def field(%{value: %{__struct__: _}} = assigns) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} badge={inspect(@value.__struct__)} />
      <textarea
        id={@control_id}
        name={@control_name}
        aria-describedby={@help_id}
        class="textarea textarea-bordered textarea-sm w-full font-mono text-label"
        rows="3"
      >{inspect(@value, pretty: true, limit: :infinity)}</textarea>
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
  end

  # atom -> read-only display row (v0.1; v0.5 ships atom-space form_hints select)
  def field(%{value: v} = assigns) when is_atom(v) do
    assigns
    |> assign_control_metadata()
    |> assign(:type_badge, "atom")
    |> readonly_field()
  end

  # plain map -> JSON textarea
  def field(%{value: v} = assigns) when is_map(v) do
    assigns = assign_control_metadata(assigns)

    ~H"""
    <div class="form-control w-full">
      <.field_label for={@control_id} text={@label} badge="map" />
      <textarea
        id={@control_id}
        name={@control_name}
        aria-describedby={@help_id}
        class="textarea textarea-bordered textarea-sm w-full font-mono text-label"
        rows="3"
      >{inspect(@value, pretty: true, limit: :infinity)}</textarea>
      <.field_help id={@help_id} text={@help_text} />
    </div>
    """
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
    |> assign(:label, humanize(key))
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
      is_struct(value, DateTime) -> "Date and time."
      is_struct(value, Date) -> "Date."
      is_struct(value) or is_map(value) -> "Edit as JSON, then re-render."
      is_atom(value) -> "Set this in the URL; read-only here."
      true -> "Read-only."
    end
  end

  defp control_id(key), do: "assigns-" <> Atom.to_string(key)
  defp control_name(key), do: "assigns[" <> Atom.to_string(key) <> "]"
  defp help_id(key), do: control_id(key) <> "-help"
  defp label_id(key), do: control_id(key) <> "-label"

  # snake_case_atom -> "Snake case atom" (sentence case per UI-SPEC line 97)
  defp humanize(atom) when is_atom(atom) do
    [first | rest] = atom |> Atom.to_string() |> String.split("_")
    Enum.join([String.capitalize(first) | rest], " ")
  end
end
