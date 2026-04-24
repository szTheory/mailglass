defmodule MailglassAdmin.PreviewLive do
  @moduledoc """
  The single dev-preview LiveView surface (PREV-03..PREV-05).

  Mounted by `MailglassAdmin.Router.mailglass_admin_routes/2`. Two live
  actions:

    * `:index` at `/` — no scenario selected. Renders the empty-state
      card with copy `"Select a scenario from the sidebar to preview it."`
      per 05-UI-SPEC Copywriting Contract line 465.
    * `:show` at `/:mailable/:scenario` — renders the full preview:
      sidebar, main pane header, device + dark toggles, assigns form,
      HTML/Text/Raw/Headers tab strip.

  ## PubSub + LiveReload

  On connected-socket mount, subscribes to
  `MailglassAdmin.PubSub.Topics.admin_reload/0`
  (`"mailglass:admin:reload"`) iff
  `MailglassAdmin.OptionalDeps.PhoenixLiveReload` is loaded. Re-discovers
  mailables + re-renders the current scenario on each broadcast and
  surfaces a flash `"Reloaded: {basename}"`.

  ## Error handling

  Errors match by STRUCT per CLAUDE.md pitfall #7 — never by message
  string. `%Mailglass.TemplateError{}` surfaces as an in-pane error
  card; the dashboard stays live. Discovery's `{:error, stacktrace}`
  return (Plan 04) flows through `handle_params/3` into the same error
  card.

  ## No PII in telemetry

  v0.1 emits NO telemetry. The cost of shipping the wrong whitelist once
  is permanent (PII leaks into adopter handlers). v0.5 adds a
  `mailables_count` counter after whitelist review.

  Preview NEVER calls `Mailglass.Outbound.deliver/2` — per CLAUDE.md
  pitfall #4 the admin boundary's `exports: [Router]` already
  structurally prevents it, but the principle is reinforced here.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.LiveView

  alias MailglassAdmin.Components
  alias MailglassAdmin.Preview.AssignsForm
  alias MailglassAdmin.Preview.DeviceFrame
  alias MailglassAdmin.Preview.Discovery
  alias MailglassAdmin.Preview.Sidebar
  alias MailglassAdmin.Preview.Tabs
  alias MailglassAdmin.PubSub.Topics

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) and live_reload_available?() do
      pubsub = socket.endpoint.config(:pubsub_server)
      if pubsub, do: Phoenix.PubSub.subscribe(pubsub, Topics.admin_reload())
    end

    socket =
      socket
      |> assign_new(:mailables, fn -> [] end)
      |> assign(:current_mailable, nil)
      |> assign(:current_scenario, nil)
      |> assign(:current_assigns, %{})
      |> assign(:device_width, 768)
      |> assign(:dark_chrome, false)
      |> assign(:active_tab, :html)
      |> assign(:render_nonce, System.unique_integer([:positive]))
      |> assign(:html_body, "")
      |> assign(:text_body, "")
      |> assign(:raw_envelope, "")
      |> assign(:headers, [])
      |> assign(:render_error, nil)
      |> assign(:page_title, "Preview")

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"mailable" => mod_str, "scenario" => name_str}, _uri, socket) do
    with {:ok, mailable} <- safe_mailable_atom(mod_str),
         {:ok, scenario} <- safe_scenario_atom(name_str),
         {:ok, defaults} <-
           lookup_scenario_defaults(socket.assigns.mailables, mailable, scenario) do
      socket =
        socket
        |> assign(:current_mailable, mailable)
        |> assign(:current_scenario, scenario)
        |> assign(:current_assigns, defaults)
        |> assign(:page_title, "mailglass — " <> to_string(scenario))
        |> rerender()

      {:noreply, socket}
    else
      {:error, {:preview_props_raised, msg}} ->
        mailable = mailable_from_str(mod_str)

        {:noreply,
         socket
         |> assign(:current_mailable, mailable)
         |> assign(:current_scenario, :__error__)
         |> assign(:render_error, msg)
         |> assign(:page_title, "mailglass — error")}

      _ ->
        {:noreply,
         socket
         |> assign(:current_mailable, nil)
         |> assign(:current_scenario, nil)
         |> put_flash(:error, "Scenario not found")}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:current_mailable, nil)
     |> assign(:current_scenario, nil)
     |> assign(:page_title, "mailglass — Preview")}
  end

  @impl true
  def handle_event("assigns_changed", %{"assigns" => params}, socket) do
    merged = merge_assigns(socket.assigns.current_assigns, params)
    {:noreply, socket |> assign(:current_assigns, merged) |> rerender()}
  end

  def handle_event("set_device", %{"width" => w}, socket) do
    case Integer.parse(w) do
      {width, _} ->
        # Bump :render_nonce to force a fresh iframe id — the iframe
        # uses phx-update="ignore" so LiveView won't update its style
        # in place; only a new element id re-renders the element with
        # the new @device_width inline style (05-UI-SPEC line 307).
        {:noreply,
         socket
         |> assign(:device_width, width)
         |> assign(:render_nonce, System.unique_integer([:positive]))}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_dark", _params, socket) do
    {:noreply, assign(socket, :dark_chrome, not socket.assigns.dark_chrome)}
  end

  def handle_event("set_tab", %{"tab" => t}, socket) do
    case safe_tab_atom(t) do
      {:ok, tab} -> {:noreply, assign(socket, :active_tab, tab)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event("reset_assigns", _params, socket) do
    case lookup_scenario_defaults(
           socket.assigns.mailables,
           socket.assigns.current_mailable,
           socket.assigns.current_scenario
         ) do
      {:ok, defaults} ->
        {:noreply, socket |> assign(:current_assigns, defaults) |> rerender()}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("render_preview", _params, socket) do
    {:noreply, rerender(socket)}
  end

  @impl true
  # Message-shape note: `{:mailglass_live_reload, path}` is the mailglass-scoped
  # reload tag. NOT `{:phoenix_live_reload, topic, path}` — Phoenix.LiveView
  # 1.1's Channel intercepts the `:phoenix_live_reload` tuple before it
  # reaches the view's handle_info (deps/phoenix_live_view/.../channel.ex:346).
  # Adopter's `config :my_app, MyAppWeb.Endpoint, live_reload: [notify: [...]]`
  # config wires file events to PubSub broadcasts; the README documents the
  # `{:mailglass_live_reload, path}` payload contract.
  def handle_info({:mailglass_live_reload, path}, socket) do
    mailables = Discovery.discover(:auto_scan)
    socket = assign(socket, :mailables, mailables)

    socket =
      if socket.assigns.current_scenario && socket.assigns.current_scenario != :__error__,
        do: rerender(socket),
        else: socket

    {:noreply, put_flash(socket, :info, "Reloaded: " <> Path.basename(path))}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div
      data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
      class="min-h-screen bg-base-100 flex"
    >
      <aside class="w-80 bg-base-200 border-r border-base-300 p-6 hidden md:block">
        <Sidebar.sidebar
          mailables={@mailables}
          current_mailable={@current_mailable}
          current_scenario={@current_scenario}
        />
      </aside>

      <main class="flex-1 p-8">
        <%= cond do %>
          <% @render_error -> %>
            <div class="card border-2 border-error bg-base-100 p-6 rounded-box max-w-prose mx-auto">
              <div class="flex items-center gap-2 mb-3">
                <Components.icon name="hero-exclamation-circle" class="w-5 h-5 text-error" />
                <h2 class="text-base font-bold text-base-content">
                  preview_props/0 raised an error
                </h2>
              </div>
              <pre class="font-mono text-xs text-error whitespace-pre-wrap overflow-auto max-h-80 bg-base-200 p-3 rounded">{@render_error}</pre>
              <p class="mt-3 text-sm text-secondary">
                Fix the error in <code class="font-mono text-xs">{inspect(@current_mailable)}</code>
                and save the file to reload.
              </p>
            </div>
          <% @current_scenario -> %>
            <header class="flex items-center justify-between mb-6 gap-4 flex-wrap">
              <h1 class="text-xl font-bold text-base-content tracking-tight">
                {inspect(@current_mailable)}
                <span class="text-secondary font-normal">· {@current_scenario}</span>
              </h1>
              <div class="flex gap-4 items-center">
                <DeviceFrame.device_frame device_width={@device_width} />
                <button
                  type="button"
                  phx-click="toggle_dark"
                  aria-label={
                    if @dark_chrome, do: "Switch to light mode", else: "Switch to dark mode"
                  }
                  class="btn btn-ghost btn-sm btn-square"
                >
                  <Components.icon
                    name={if @dark_chrome, do: "hero-sun", else: "hero-moon"}
                    class="w-5 h-5"
                  />
                </button>
              </div>
            </header>

            <AssignsForm.assigns_form scenario_assigns={@current_assigns} />

            <div class="mt-6">
              <Tabs.tabs
                active_tab={@active_tab}
                html_body={@html_body}
                text_body={@text_body}
                raw_envelope={@raw_envelope}
                headers={@headers}
                device_width={@device_width}
                render_nonce={@render_nonce}
              />
            </div>
          <% true -> %>
            <div class="card bg-base-200 p-8 rounded-box text-center max-w-prose mx-auto">
              <Components.icon
                name="hero-envelope"
                class="w-10 h-10 text-secondary mx-auto mb-3"
              />
              <h2 class="text-base font-bold text-base-content mb-2">Select a scenario</h2>
              <p class="text-sm text-secondary">
                Select a scenario from the sidebar to preview it.
              </p>
            </div>
        <% end %>
      </main>

      <%= if Phoenix.Flash.get(@flash, :info) do %>
        <Components.flash kind={:success} message={Phoenix.Flash.get(@flash, :info)} />
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp live_reload_available? do
    Code.ensure_loaded?(MailglassAdmin.OptionalDeps.PhoenixLiveReload)
  end

  defp safe_mailable_atom(str) do
    {:ok, String.to_existing_atom("Elixir." <> str)}
  rescue
    ArgumentError -> :error
  end

  defp safe_scenario_atom(str) do
    {:ok, String.to_existing_atom(str)}
  rescue
    ArgumentError -> :error
  end

  defp safe_tab_atom(t) when t in ["html", "text", "raw", "headers"] do
    {:ok, String.to_existing_atom(t)}
  end

  defp safe_tab_atom(_), do: :error

  defp mailable_from_str(str) do
    String.to_existing_atom("Elixir." <> str)
  rescue
    ArgumentError -> nil
  end

  # Flag the preview_props-raised branch separately from the generic
  # not-found branch so handle_params/3 can route to the error card.
  defp lookup_scenario_defaults(mailables, mod, scenario) do
    case Enum.find(mailables, fn {m, _} -> m == mod end) do
      {_, list} when is_list(list) ->
        case Keyword.fetch(list, scenario) do
          {:ok, defaults} -> {:ok, defaults}
          :error -> :error
        end

      {_, {:error, msg}} ->
        {:error, {:preview_props_raised, msg}}

      _ ->
        :error
    end
  end

  # merge form params (strings) back into the assigns map, respecting the
  # type of the default value. Unknown keys (atoms not in current_assigns)
  # are ignored — adopter cannot grow the assigns namespace from the form.
  defp merge_assigns(current, params) when is_map(params) do
    Enum.reduce(params, current, fn {k, v}, acc ->
      key = safe_key_atom(k)

      if key && Map.has_key?(acc, key) do
        Map.put(acc, key, coerce(acc[key], v))
      else
        acc
      end
    end)
  end

  defp safe_key_atom(k) when is_binary(k) do
    String.to_existing_atom(k)
  rescue
    ArgumentError -> nil
  end

  defp coerce(default, incoming) when is_integer(default) and is_binary(incoming) do
    case Integer.parse(incoming) do
      {n, _} -> n
      :error -> default
    end
  end

  defp coerce(default, incoming) when is_float(default) and is_binary(incoming) do
    case Float.parse(incoming) do
      {n, _} -> n
      :error -> default
    end
  end

  defp coerce(default, incoming) when is_boolean(default) do
    incoming == "true" or incoming == true
  end

  defp coerce(_default, incoming), do: incoming

  # The Mailglass.Renderer pipeline invocation. This is the SAME pipeline
  # production sends use — no placeholder shape divergence (PREV-03).
  defp rerender(socket) do
    mod = socket.assigns.current_mailable
    scenario = socket.assigns.current_scenario
    assigns_map = socket.assigns.current_assigns

    try do
      case build_and_render(mod, scenario, assigns_map) do
        {:ok, rendered} ->
          email = rendered.swoosh_email

          socket
          |> assign(:html_body, email.html_body || "")
          |> assign(:text_body, email.text_body || "")
          |> assign(:raw_envelope, raw_envelope(email))
          |> assign(:headers, swoosh_headers(email))
          |> assign(:render_nonce, System.unique_integer([:positive]))
          |> assign(:render_error, nil)

        {:error, %Mailglass.TemplateError{} = err} ->
          # Match by struct — never by message string (CLAUDE.md pitfall #7).
          assign(socket, :render_error, Exception.message(err))

        {:error, other} ->
          assign(socket, :render_error, inspect(other))
      end
    rescue
      e ->
        assign(socket, :render_error, Exception.format(:error, e, __STACKTRACE__))
    end
  end

  defp build_and_render(mod, scenario, assigns_map)
       when is_atom(mod) and is_atom(scenario) and is_map(assigns_map) do
    msg = apply(mod, scenario, [assigns_map])
    # Fully-qualified call site for auditability — this is the ONE place
    # PreviewLive reaches into the core render pipeline. Matches the
    # production send path; PREV-03 "no placeholder shape divergence".
    Mailglass.Renderer.render(msg)
  end

  defp build_and_render(_mod, _scenario, _assigns), do: {:error, :invalid_selection}

  # Best-effort RFC 5322 envelope. Swoosh has no public encode/1 in 1.25,
  # so v0.1 inspect-fallbacks. The Raw tab shows Message-ID / Content-Type /
  # boundary markers via explicit Swoosh.Email fields rather than a full
  # MIME serialization.
  defp raw_envelope(%Swoosh.Email{} = email) do
    headers = swoosh_headers(email)

    lines = [
      format_header("From", format_address(email.from)),
      format_header("To", format_addresses(email.to)),
      format_header("Subject", email.subject || ""),
      format_header("MIME-Version", "1.0"),
      format_header(
        "Content-Type",
        "multipart/alternative; boundary=\"mailglass_preview_boundary\""
      )
      | Enum.map(headers, fn {k, v} -> format_header(to_string(k), to_string(v)) end)
    ]

    Enum.join(lines, "\n") <>
      "\n\n" <>
      "--mailglass_preview_boundary\n" <>
      "Content-Type: text/plain; charset=utf-8\n\n" <>
      (email.text_body || "") <>
      "\n--mailglass_preview_boundary\n" <>
      "Content-Type: text/html; charset=utf-8\n\n" <>
      (email.html_body || "") <>
      "\n--mailglass_preview_boundary--\n"
  end

  defp raw_envelope(_), do: ""

  defp format_header(name, value), do: name <> ": " <> value

  defp format_address(nil), do: ""
  defp format_address({"", addr}), do: addr
  defp format_address({name, addr}), do: name <> " <" <> addr <> ">"
  defp format_address(addr) when is_binary(addr), do: addr
  defp format_address(other), do: inspect(other)

  defp format_addresses(list) when is_list(list) do
    list |> Enum.map(&format_address/1) |> Enum.join(", ")
  end

  defp format_addresses(other), do: format_address(other)

  # Swoosh.Email.headers is map-shaped in 1.25+; normalize to tuples for
  # the Headers tab. Auto-inject Message-ID + Date so the Headers tab
  # always shows the canonical envelope rows even if the mailable
  # doesn't set them explicitly.
  defp swoosh_headers(%Swoosh.Email{} = email) do
    base =
      case email.headers do
        %{} = m -> Enum.to_list(m)
        list when is_list(list) -> list
        _ -> []
      end

    ensure_header(ensure_header(base, "Message-ID", generate_message_id()), "Date", rfc2822_date())
  end

  defp swoosh_headers(_), do: []

  defp ensure_header(headers, name, default) do
    if Enum.any?(headers, fn {k, _} -> to_string(k) == name end) do
      headers
    else
      headers ++ [{name, default}]
    end
  end

  defp generate_message_id do
    "<preview-" <>
      Integer.to_string(System.unique_integer([:positive])) <>
      "@mailglass.dev>"
  end

  defp rfc2822_date do
    # Best-effort RFC 2822 timestamp. Not strictly RFC-compliant at v0.1
    # (no weekday name); the Headers tab's contract is "row exists with
    # name + non-empty value", not "passes rfc2822 grammar".
    DateTime.utc_now() |> DateTime.to_string()
  end
end
