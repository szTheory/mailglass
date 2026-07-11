defmodule MailglassAdmin.Preview.Tabs do
  @moduledoc """
  Tabs function component: HTML · Text · Raw · Headers tab strip plus
  the matching content pane per 05-UI-SPEC lines 220-228 + 294-352.

    * **HTML** (default) — sandboxed iframe with `srcdoc={@html_body}`.
      Width driven by `@device_width` (375 / 768 / 1024). `phx-update="ignore"`
      + nonce-based `id` forces a fresh iframe on every re-render so email
      CSS never bleeds between scenarios.
    * **Text** — `<pre class="font-mono text-label">` with `@text_body`.
    * **Raw** — `<pre>` with the RFC 5322 envelope string.
    * **Headers** — two-column table: header name (mono, bold) + value.

  Tab strip uses `role="tablist"` / `role="tab"` / `aria-selected` per
  05-UI-SPEC Accessibility Interactions lines 509-514.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.Component

  attr(:active_tab, :atom, values: [:html, :text, :raw, :headers], default: :html)
  attr(:html_body, :string, default: "")
  attr(:text_body, :string, default: "")
  attr(:raw_envelope, :string, default: "")
  attr(:headers, :list, default: [])
  attr(:device_width, :integer, default: 768)
  attr(:render_nonce, :integer, required: true)
  attr(:preview_frame_dark_chrome, :boolean, default: false)

  @doc """
  Renders the tab strip + the active tab's content pane.
  """
  @doc since: "0.1.0"
  def tabs(assigns) do
    ~H"""
    <div class="space-y-4">
      <div
        role="tablist"
        data-testid="preview-tab-strip"
        class="flex border-b border-base-300"
        aria-label="Preview format"
      >
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="html"
          id="tab-btn-html"
          aria-selected={to_string(@active_tab == :html)}
          aria-controls="tab-panel-html"
          class={[
            "mg-focus-ring-inset px-4 py-2 min-h-11 text-body transition-colors",
            tab_classes(@active_tab == :html)
          ]}
        >
          HTML
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="text"
          id="tab-btn-text"
          aria-selected={to_string(@active_tab == :text)}
          aria-controls="tab-panel-text"
          class={[
            "mg-focus-ring-inset px-4 py-2 min-h-11 text-body transition-colors",
            tab_classes(@active_tab == :text)
          ]}
        >
          Text
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="raw"
          id="tab-btn-raw"
          aria-selected={to_string(@active_tab == :raw)}
          aria-controls="tab-panel-raw"
          class={[
            "mg-focus-ring-inset px-4 py-2 min-h-11 text-body transition-colors",
            tab_classes(@active_tab == :raw)
          ]}
        >
          Raw
        </button>
        <button
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab="headers"
          id="tab-btn-headers"
          aria-selected={to_string(@active_tab == :headers)}
          aria-controls="tab-panel-headers"
          class={[
            "mg-focus-ring-inset px-4 py-2 min-h-11 text-body transition-colors",
            tab_classes(@active_tab == :headers)
          ]}
        >
          Headers
        </button>
      </div>

      <div
        id={"tab-panel-" <> Atom.to_string(@active_tab)}
        data-preview-frame-theme={
          preview_frame_theme_attr(@active_tab, @preview_frame_dark_chrome)
        }
        data-theme={preview_frame_data_theme_attr(@active_tab, @preview_frame_dark_chrome)}
        data-testid="preview-pane"
        role="tabpanel"
        aria-labelledby={"tab-btn-" <> Atom.to_string(@active_tab)}
        class="motion-tab-swap rounded-box border border-base-300 bg-base-200 p-md"
      >
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

  attr(:active_tab, :atom, required: true)
  attr(:html_body, :string, default: "")
  attr(:text_body, :string, default: "")
  attr(:raw_envelope, :string, default: "")
  attr(:headers, :list, default: [])
  attr(:device_width, :integer, required: true)
  attr(:render_nonce, :integer, required: true)

  def tab_content(%{active_tab: :html} = assigns) do
    ~H"""
    <div class="overflow-auto">
      <%= if @html_body == "" do %>
        <p class="text-body text-secondary py-lg text-center">
          No HTML body — this Mailable's template returned empty content.
        </p>
      <% else %>
        <iframe
          srcdoc={@html_body}
          sandbox="allow-same-origin"
          style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: var(--color-base-100);"}
          phx-update="ignore"
          id={"preview-iframe-" <> Integer.to_string(@render_nonce)}
          title="Email HTML preview"
        />
      <% end %>
    </div>
    """
  end

  def tab_content(%{active_tab: :text} = assigns) do
    ~H"""
    <pre class="font-mono text-label leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto h-150 whitespace-pre-wrap">{@text_body}</pre>
    """
  end

  def tab_content(%{active_tab: :raw} = assigns) do
    ~H"""
    <pre class="font-mono text-label leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto h-150 whitespace-pre">{@raw_envelope}</pre>
    """
  end

  def tab_content(%{active_tab: :headers} = assigns) do
    ~H"""
    <div class="overflow-auto h-150">
      <table class="table table-sm w-full">
        <thead>
          <tr>
            <th class="font-mono text-label text-secondary w-48">Header</th>
            <th class="font-mono text-label text-secondary">Value</th>
          </tr>
        </thead>
        <tbody>
          <%= for {name, value} <- @headers do %>
            <tr class="hover:bg-base-200">
              <td class="font-mono text-label font-bold text-base-content align-top">
                {to_string(name)}
              </td>
              <td class="font-mono text-label text-base-content break-all">{to_string(value)}</td>
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

  defp preview_frame_theme_attr(tab, dark_chrome) when tab in [:html, :text],
    do: if(dark_chrome, do: "dark", else: "light")

  defp preview_frame_theme_attr(_tab, _dark_chrome), do: nil

  defp preview_frame_data_theme_attr(tab, dark_chrome) when tab in [:html, :text],
    do: if(dark_chrome, do: "mailglass-dark", else: "mailglass-light")

  defp preview_frame_data_theme_attr(_tab, _dark_chrome), do: nil
end
