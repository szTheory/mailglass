defmodule MailglassAdmin.Preview.Tabs do
  @moduledoc """
  Four output representations from the developer preview: renderer HTML and
  plaintext, an illustrative MIME-shaped preview, and preview header values.

  The HTML panel displays the result in a script-disabled browser iframe. It
  describes browser rendering only and does not certify email-client output.
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

  @doc "Renders the tab strip and its four labelled output panels."
  @doc since: "0.1.0"
  def tabs(assigns) do
    assigns =
      assign(assigns, :panels, [
        {:html, "HTML"},
        {:text, "Text"},
        {:raw, "Raw"},
        {:headers, "Headers"}
      ])

    ~H"""
    <div class="space-y-4">
      <div
        role="tablist"
        data-testid="preview-tab-strip"
        class="flex flex-wrap border-b border-base-300"
        aria-label="Preview format"
      >
        <button
          :for={{tab, label} <- @panels}
          role="tab"
          type="button"
          phx-click="set_tab"
          phx-value-tab={Atom.to_string(tab)}
          id={"tab-btn-" <> Atom.to_string(tab)}
          aria-selected={to_string(@active_tab == tab)}
          aria-controls={"tab-panel-" <> Atom.to_string(tab)}
          class={[
            "mg-focus-ring-inset px-4 py-2 min-h-11 text-body transition-colors",
            tab_classes(@active_tab == tab)
          ]}
        >
          {label}
        </button>
      </div>

      <div
        :for={{tab, _label} <- @panels}
        id={"tab-panel-" <> Atom.to_string(tab)}
        hidden={@active_tab != tab}
        data-preview-frame-theme={preview_frame_theme_attr(tab, @preview_frame_dark_chrome)}
        data-theme={preview_frame_data_theme_attr(tab, @preview_frame_dark_chrome)}
        data-testid="preview-pane"
        role="tabpanel"
        aria-labelledby={"tab-btn-" <> Atom.to_string(tab)}
        tabindex="0"
        class="motion-tab-swap min-w-0 rounded-box border border-base-300 bg-base-200 p-md"
      >
        <.tab_content
          active_tab={tab}
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
    <div class="min-w-0 space-y-sm">
      <p class="text-label text-secondary">
        Renderer HTML. Browser rendering only; this does not show how an email client will render it.
      </p>
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
            title="Email HTML preview — browser rendering only"
          />
        <% end %>
      </div>
    </div>
    """
  end

  def tab_content(%{active_tab: :text} = assigns) do
    ~H"""
    <div class="min-w-0 space-y-sm">
      <p class="text-label text-secondary">Renderer plaintext</p>
      <pre class="font-mono text-label leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto max-h-150 whitespace-pre-wrap break-words">{@text_body}</pre>
    </div>
    """
  end

  def tab_content(%{active_tab: :raw} = assigns) do
    ~H"""
    <div class="min-w-0 space-y-sm">
      <p class="text-label text-secondary">
        Illustrative MIME-shaped preview. This is not serialized wire bytes or provider output.
      </p>
      <pre class="font-mono text-label leading-relaxed text-base-content bg-base-200 p-4 rounded-box overflow-auto max-h-150 whitespace-pre">{@raw_envelope}</pre>
    </div>
    """
  end

  def tab_content(%{active_tab: :headers} = assigns) do
    ~H"""
    <div class="min-w-0 space-y-sm">
      <p class="text-label text-secondary">
        Preview header values. Message-ID and Date are generated for this preview when the scenario does not provide them.
      </p>
      <div class="overflow-auto max-h-150">
        <table class="table table-sm w-full">
          <thead>
            <tr>
              <th class="font-mono text-label text-secondary w-48">Header</th>
              <th class="font-mono text-label text-secondary">Preview value</th>
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
    </div>
    """
  end

  defp tab_classes(true), do: "font-bold border-b-2 border-primary text-base-content"
  defp tab_classes(false), do: "text-secondary hover:bg-base-200"

  defp preview_frame_theme_attr(tab, dark_chrome) when tab in [:html, :text],
    do: if(dark_chrome, do: "dark", else: "light")

  defp preview_frame_theme_attr(_tab, _dark_chrome), do: nil

  defp preview_frame_data_theme_attr(tab, dark_chrome) when tab in [:html, :text],
    do: if(dark_chrome, do: "mailglass-dark", else: "mailglass-light")

  defp preview_frame_data_theme_attr(_tab, _dark_chrome), do: nil
end
