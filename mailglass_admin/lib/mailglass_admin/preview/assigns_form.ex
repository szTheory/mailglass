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
    | `atom`            | disabled text input (v0.1 — URL edit only)  |
    | `DateTime`        | `<input type="datetime-local">`             |
    | `Date`            | `<input type="date">`                       |
    | struct            | `<textarea>` JSON (struct label)            |
    | `map`             | `<textarea>` JSON (plain map)               |
    | fallback          | disabled `<input>` "(unsupported type)"     |

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
    <form phx-change="assigns_changed" class="assigns-form space-y-4">
      <%= for {key, value} <- Enum.sort_by(@scenario_assigns, fn {k, _} -> Atom.to_string(k) end) do %>
        <.field key={key} value={value} />
      <% end %>

      <div class="flex gap-2">
        <button type="button" class="btn btn-primary btn-sm" phx-click="render_preview">
          Render preview
        </button>
        <button type="button" class="btn btn-ghost btn-sm" phx-click="reset_assigns">
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
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
      <input
        type="text"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={@value}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # integer -> number input, step 1
  def field(%{value: v} = assigns) when is_integer(v) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
      <input
        type="number"
        step="1"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={Integer.to_string(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # float -> number input, step any
  def field(%{value: v} = assigns) when is_float(v) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
      <input
        type="number"
        step="any"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={Float.to_string(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # boolean -> checkbox
  def field(%{value: v} = assigns) when is_boolean(v) do
    ~H"""
    <label class="label cursor-pointer justify-start gap-3">
      <input
        type="checkbox"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value="true"
        checked={@value}
        class="checkbox checkbox-sm"
      />
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
    </label>
    """
  end

  # DateTime -> datetime-local
  def field(%{value: %DateTime{}} = assigns) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
      <input
        type="datetime-local"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={DateTime.to_iso8601(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # Date -> date
  def field(%{value: %Date{}} = assigns) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)}</span>
      <input
        type="date"
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={Date.to_iso8601(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # struct -> JSON textarea with struct label
  def field(%{value: %{__struct__: _}} = assigns) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">
        {humanize(@key)} <span class="text-xs text-secondary font-mono">({inspect(@value.__struct__)})</span>
      </span>
      <textarea
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        class="textarea textarea-bordered textarea-sm w-full font-mono text-xs"
        rows="3"
      >{inspect(@value, pretty: true, limit: :infinity)}</textarea>
    </label>
    """
  end

  # atom -> disabled text input (v0.1; v0.5 ships atom-space form_hints select)
  def field(%{value: v} = assigns) when is_atom(v) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">
        {humanize(@key)} <span class="text-xs text-secondary">(atom)</span>
      </span>
      <input
        type="text"
        disabled
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={inspect(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # plain map -> JSON textarea
  def field(%{value: v} = assigns) when is_map(v) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">{humanize(@key)} <span class="text-xs text-secondary font-mono">(map)</span></span>
      <textarea
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        class="textarea textarea-bordered textarea-sm w-full font-mono text-xs"
        rows="3"
      >{inspect(@value, pretty: true, limit: :infinity)}</textarea>
    </label>
    """
  end

  # fallback — disabled inspect
  def field(assigns) do
    ~H"""
    <label class="form-control w-full">
      <span class="label-text text-sm font-normal">
        {humanize(@key)} <span class="text-xs text-secondary">(unsupported type)</span>
      </span>
      <input
        type="text"
        disabled
        name={"assigns[" <> Atom.to_string(@key) <> "]"}
        value={inspect(@value)}
        class="input input-bordered input-sm w-full"
      />
    </label>
    """
  end

  # snake_case_atom -> "Snake case atom" (sentence case per UI-SPEC line 97)
  defp humanize(atom) when is_atom(atom) do
    [first | rest] = atom |> Atom.to_string() |> String.split("_")
    String.capitalize(first) <> " " <> Enum.join(rest, " ")
  end
end
