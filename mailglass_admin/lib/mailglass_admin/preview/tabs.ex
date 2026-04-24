defmodule MailglassAdmin.Preview.Tabs do
  @moduledoc """
  Tabs function component: HTML · Text · Raw · Headers tab strip plus
  the matching content pane per 05-UI-SPEC lines 220-228 + 294-352.

    * **HTML** (default) — sandboxed iframe with `srcdoc={@html_body}`.
      Width driven by `@device_width` (375 / 768 / 1024). `phx-update="ignore"`
      + nonce-based `id` forces a fresh iframe on every re-render so email
      CSS never bleeds between scenarios.
    * **Text** — `<pre class="font-mono text-xs">` with `@text_body`.
    * **Raw** — `<pre>` with the RFC 5322 envelope string.
    * **Headers** — two-column table: header name (mono, bold) + value.

  Tab strip uses `role="tablist"` / `role="tab"` / `aria-selected` per
  05-UI-SPEC Accessibility Interactions lines 509-514.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  attr :active_tab, :atom, values: [:html, :text, :raw, :headers], default: :html
  attr :html_body, :string, default: ""
  attr :text_body, :string, default: ""
  attr :raw_envelope, :string, default: ""
  attr :headers, :list, default: []
  attr :device_width, :integer, default: 768
  attr :render_nonce, :integer, required: true

  @doc """
  Renders the tab strip + the active tab's content pane.
  """
  @doc since: "0.1.0"
  def tabs(assigns) do
    ~H"""
    <div class="space-y-4">
      <div role="tablist" class="flex border-b border-base-300" aria-label="Preview format">
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="html"
          aria-selected={to_string(@active_tab == :html)}
          class={["px-4 py-2 min-h-10 text-sm transition-colors", tab_classes(@active_tab == :html)]}
        >
          HTML
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="text"
          aria-selected={to_string(@active_tab == :text)}
          class={["px-4 py-2 min-h-10 text-sm transition-colors", tab_classes(@active_tab == :text)]}
        >
          Text
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="raw"
          aria-selected={to_string(@active_tab == :raw)}
          class={["px-4 py-2 min-h-10 text-sm transition-colors", tab_classes(@active_tab == :raw)]}
        >
          Raw
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="headers"
          aria-selected={to_string(@active_tab == :headers)}
          class={["px-4 py-2 min-h-10 text-sm transition-colors", tab_classes(@active_tab == :headers)]}
        >
          Headers
        </button>
      </div>

      <div>
        <.tab_content
          active_tab={@active_tab}
          html_body={@html_body}
          text_body={@text_body}
          raw_envelope={@raw_envelope}
          headers={@headers}
          device_width={@device_width}
          render_nonce={@render_nonce}
        />
      </div>
    </div>
    """
  end

  attr :active_tab, :atom, required: true
  attr :html_body, :string, default: ""
  attr :text_body, :string, default: ""
  attr :raw_envelope, :string, default: ""
  attr :headers, :list, default: []
  attr :device_width, :integer, required: true
  attr :render_nonce, :integer, required: true

  def tab_content(%{active_tab: :html} = assigns) do
    ~H"""
    <div class="overflow-auto">
      <iframe
        srcdoc={@html_body}
        sandbox="allow-same-origin"
        style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: #ffffff;"}
        phx-update="ignore"
        id={"preview-iframe-" <> Integer.to_string(@render_nonce)}
        title="Email HTML preview"
      />
    </div>
    """
  end

  def tab_content(%{active_tab: :text} = assigns) do
    ~H"""
    <pre class="font-mono text-xs leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto h-[600px] whitespace-pre-wrap">{@text_body}</pre>
    """
  end

  def tab_content(%{active_tab: :raw} = assigns) do
    ~H"""
    <pre class="font-mono text-xs leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto h-[600px] whitespace-pre">{@raw_envelope}</pre>
    """
  end

  def tab_content(%{active_tab: :headers} = assigns) do
    ~H"""
    <div class="overflow-auto h-[600px]">
      <table class="table table-sm w-full">
        <thead>
          <tr>
            <th class="font-mono text-xs text-secondary w-48">Header</th>
            <th class="font-mono text-xs text-secondary">Value</th>
          </tr>
        </thead>
        <tbody>
          <%= for {name, value} <- @headers do %>
            <tr class="hover:bg-base-200">
              <td class="font-mono text-xs font-bold text-base-content align-top">{to_string(name)}</td>
              <td class="font-mono text-xs text-base-content break-all">{to_string(value)}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp tab_classes(true),
    do: "font-bold border-b-2 border-primary text-base-content"

  defp tab_classes(false),
    do: "text-secondary hover:bg-base-200"
end
