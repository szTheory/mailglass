defmodule MailglassAdmin.PreviewLive do
  @moduledoc """
  The single dev-preview LiveView surface.

  Mounted by `MailglassAdmin.Router.mailglass_admin_routes/2`. Two live
  actions:

    * `:index` at `/` — no scenario selected. Renders the start page: a
      value statement, a "Preview the first Mailable" deep link, and a legend of
      the tool's affordances. When auto-scan finds zero mailables, renders the
      actionable "No Mailables discovered" empty state instead.
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
  return (this plan) flows through `handle_params/3` into the same error
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
      |> assign(:admin_chrome_theme, nil)
      |> assign(:preview_frame_dark_chrome, false)
      |> assign(:base_path, nil)
      |> assign(:mount_path, nil)
      |> assign(:page_uri, nil)
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
  def handle_params(%{"mailable" => mod_str, "scenario" => name_str} = params, uri, socket) do
    {device_width, admin_chrome_theme} = normalize_capture_url_state(params, socket)
    base_path = uri_path(uri)

    with {:ok, mailable} <- safe_mailable_atom(mod_str),
         {:ok, scenario} <- safe_scenario_atom(name_str),
         {:ok, defaults} <-
           lookup_scenario_defaults(socket.assigns.mailables, mailable, scenario) do
      current_assigns =
        if socket.assigns.current_mailable == mailable and
             socket.assigns.current_scenario == scenario do
          socket.assigns.current_assigns
        else
          defaults
        end

      socket =
        socket
        |> assign(:current_mailable, mailable)
        |> assign(:current_scenario, scenario)
        |> assign(:current_assigns, current_assigns)
        |> assign(:device_width, device_width)
        |> assign(:admin_chrome_theme, admin_chrome_theme)
        |> assign(:base_path, base_path)
        |> assign(:page_uri, uri)
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
         |> assign(:device_width, device_width)
         |> assign(:admin_chrome_theme, admin_chrome_theme)
         |> assign(:base_path, base_path)
         |> assign(:page_uri, uri)
         |> assign(:render_error, msg)
         |> assign(:page_title, "mailglass — error")}

      _ ->
        {:noreply,
         socket
         |> assign(:current_mailable, nil)
         |> assign(:current_scenario, nil)
         |> assign(:base_path, nil)
         |> assign(:page_uri, uri)
         |> put_flash(:error, "Scenario not found")}
    end
  end

  def handle_params(params, uri, socket) do
    {:noreply,
     socket
     |> assign(:current_mailable, nil)
     |> assign(:current_scenario, nil)
     |> assign(:base_path, nil)
     |> assign(:admin_chrome_theme, parse_admin_chrome_theme(params["theme"]))
     |> assign(:page_uri, uri)
     |> assign(:page_title, "mailglass — Preview")}
  end

  @impl true
  def handle_event("assigns_changed", %{"assigns" => params}, socket) do
    merged = merge_assigns(socket.assigns.current_assigns, params)
    {:noreply, socket |> assign(:current_assigns, merged) |> rerender()}
  end

  def handle_event("set_device", %{"width" => w}, socket) do
    width = parse_device_width_param(w)

    # Bump :render_nonce to force a fresh iframe id — the iframe uses
    # phx-update="ignore" so LiveView won't update its style in place;
    # only a new element id re-renders the element with the new
    # @device_width inline style (05-UI-SPEC line 307).
    {:noreply,
     socket
     |> assign(:device_width, width)
     |> assign(:render_nonce, System.unique_integer([:positive]))
     |> sync_patch_capture_url_state()}
  end

  def handle_event("toggle_preview_frame_theme", _params, socket) do
    {:noreply,
     assign(
       socket,
       :preview_frame_dark_chrome,
       not socket.assigns.preview_frame_dark_chrome
     )}
  end

  def handle_event("toggle_theme", _params, socket) do
    {:noreply,
     redirect(
       socket,
       to: preview_theme_path(socket, admin_chrome_dark?(socket.assigns.admin_chrome_theme))
     )}
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
      data-testid="preview-shell"
      data-theme={admin_theme_attr(@admin_chrome_theme)}
      class="mg-admin-root min-h-screen bg-base-100 text-base-content px-md py-lg md:px-lg md:py-xl"
    >
      <div class="grid gap-lg md:grid-cols-[20rem_1fr]">
        <aside
          data-testid="preview-sidebar-desktop"
          class="hidden md:block rounded-box border border-base-300 bg-base-200 p-md"
        >
          <Sidebar.sidebar
            mailables={@mailables}
            current_mailable={@current_mailable}
            current_scenario={@current_scenario}
            device_width={@device_width}
            admin_chrome_theme={@admin_chrome_theme}
            mount_path={@mount_path}
          />
        </aside>

        <main class="min-w-0 space-y-lg">
          <section
            data-testid="preview-mobile-mailables"
            class="md:hidden rounded-box border border-base-300 bg-base-200 p-md"
          >
            <Sidebar.sidebar
              mailables={@mailables}
              current_mailable={@current_mailable}
              current_scenario={@current_scenario}
              device_width={@device_width}
              admin_chrome_theme={@admin_chrome_theme}
              mount_path={@mount_path}
            />
          </section>

          <%= cond do %>
            <% @render_error -> %>
              <div
                data-testid="preview-render-error"
                class="rounded-box border border-error bg-base-200 p-lg"
              >
                <div class="flex items-center gap-sm mb-md">
                  <Components.icon name="hero-exclamation-circle" class="w-5 h-5 text-error" />
                  <h1 class="text-heading font-bold text-base-content">
                    preview_props/0 raised an error
                  </h1>
                </div>
                <p class="text-body text-secondary">
                  Fix the error in
                  <code class="font-mono text-label">{inspect(@current_mailable)}</code>
                  and save the file to reload.
                </p>
                <pre class="mt-md font-mono text-label text-error whitespace-pre-wrap overflow-auto max-h-80 bg-base-100 p-md rounded-box border border-base-300"><code>{@render_error}</code></pre>
              </div>
            <% @current_scenario -> %>
              <header class="flex items-start justify-between gap-md flex-wrap">
                <h1 class="min-w-0 break-words text-heading font-bold text-base-content">
                  {inspect(@current_mailable)}
                  <span class="text-secondary font-normal">· {@current_scenario}</span>
                </h1>
                <div data-testid="preview-header-controls" class="flex gap-sm items-center">
                  <DeviceFrame.device_frame device_width={@device_width} />
                  <button
                    type="button"
                    data-testid="preview-admin-theme-toggle"
                    phx-click="toggle_theme"
                    aria-label={
                      if admin_chrome_dark?(@admin_chrome_theme),
                        do: "Switch admin chrome to light theme",
                        else: "Switch admin chrome to dark theme"
                    }
                    class="mg-focus-ring btn btn-ghost btn-sm btn-square min-h-11 min-w-11"
                  >
                    <Components.icon
                      name={
                        if admin_chrome_dark?(@admin_chrome_theme), do: "hero-sun", else: "hero-moon"
                      }
                      class="w-5 h-5"
                    />
                  </button>
                  <button
                    type="button"
                    data-testid="preview-frame-theme-toggle"
                    phx-click="toggle_preview_frame_theme"
                    aria-label={
                      if @preview_frame_dark_chrome,
                        do: "Switch preview frame to light chrome",
                        else: "Switch preview frame to dark chrome"
                    }
                    class="mg-focus-ring btn btn-ghost btn-sm btn-square min-h-11 min-w-11"
                  >
                    <Components.icon
                      name={if @preview_frame_dark_chrome, do: "hero-sun", else: "hero-moon"}
                      class="w-5 h-5"
                    />
                  </button>
                </div>
              </header>

              <AssignsForm.assigns_form scenario_assigns={@current_assigns} />

              <Tabs.tabs
                active_tab={@active_tab}
                html_body={@html_body}
                text_body={@text_body}
                raw_envelope={@raw_envelope}
                headers={@headers}
                device_width={@device_width}
                render_nonce={@render_nonce}
                preview_frame_dark_chrome={@preview_frame_dark_chrome}
              />
            <% @mailables == [] -> %>
              <MailglassAdmin.Operator.Shell.orientation_strip surface={:preview} />
              <div
                data-testid="preview-empty-mailables"
                class="mx-auto max-w-prose rounded-box border border-base-300 bg-base-200 p-lg"
              >
                <Components.icon name="hero-magnifying-glass" class="mb-md h-10 w-10 text-secondary" />
                <h1 class="mb-sm text-heading font-bold text-base-content">
                  No Mailables discovered
                </h1>
                <p class="text-body text-secondary">
                  Preview scans loaded modules that use Mailglass.Mailable. Nothing was found yet.
                </p>
                <ul class="mt-md grid gap-sm text-body text-secondary">
                  <li class="flex items-start gap-sm">
                    <Components.icon
                      name="hero-check-circle"
                      class="mt-0.5 h-4 w-4 shrink-0 text-primary"
                    />
                    <span>
                      Confirm the module calls
                      <code class="mono text-label">use Mailglass.Mailable</code>
                      and is compiled and loaded.
                    </span>
                  </li>
                  <li class="flex items-start gap-sm">
                    <Components.icon
                      name="hero-check-circle"
                      class="mt-0.5 h-4 w-4 shrink-0 text-primary"
                    />
                    <span>
                      Or pass an explicit list to the router: <code class="mono text-label">mailglass_admin_routes "/mail", mailables: [MyApp.UserMailer]</code>.
                    </span>
                  </li>
                </ul>
                <a
                  href="https://hexdocs.pm/mailglass_admin/MailglassAdmin.Router.html"
                  class="mg-focus-ring btn btn-ghost mt-md min-h-11"
                >
                  Read preview setup
                </a>
              </div>
            <% true -> %>
              <div
                data-testid="preview-start"
                class="mx-auto max-w-prose space-y-lg"
              >
                <div class="rounded-box border border-base-300 bg-base-200 p-lg">
                  <Components.icon name="hero-envelope-open" class="mb-md h-10 w-10 text-primary" />
                  <h1 class="mb-sm text-heading font-bold text-base-content">
                    Render a real Message before you send it
                  </h1>
                  <p class="text-body text-secondary">
                    Pick a Mailable from the sidebar to render it through the same pipeline your production sends use.
                  </p>
                  <.link
                    :if={first_previewable(@mailables)}
                    patch={first_scenario_path(@mount_path, @mailables, @admin_chrome_theme)}
                    class="motion-reveal mg-focus-ring btn btn-primary mt-md min-h-11"
                  >
                    Preview the first Mailable
                  </.link>
                </div>

                <dl class="grid gap-sm sm:grid-cols-2">
                  <.legend_item icon="hero-window" title="HTML, Text, Raw & Headers">
                    Switch tabs to inspect each part of the rendered Message.
                  </.legend_item>
                  <.legend_item icon="hero-device-phone-mobile" title="Device widths">
                    Check mobile, tablet, and desktop rendering at 375 / 768 / 1024px.
                  </.legend_item>
                  <.legend_item icon="hero-moon" title="Light & dark">
                    Toggle admin chrome and the preview frame independently.
                  </.legend_item>
                  <.legend_item icon="hero-pencil-square" title="Editable assigns">
                    Edit the scenario's assigns inline and re-render instantly.
                  </.legend_item>
                </dl>
              </div>
          <% end %>
        </main>
      </div>

      <%= if Phoenix.Flash.get(@flash, :info) do %>
        <Components.flash kind={:success} message={Phoenix.Flash.get(@flash, :info)} />
      <% end %>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  # Start-page legend tile: one affordance of the preview tool, explained.
  defp legend_item(assigns) do
    ~H"""
    <div class="flex items-start gap-sm rounded-box border border-base-300 bg-base-100 p-4">
      <Components.icon name={@icon} class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
      <div class="min-w-0">
        <dt class="text-body font-bold text-base-content">{@title}</dt>
        <dd class="mt-1 text-body text-secondary">{render_slot(@inner_block)}</dd>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # First mailable that exposes at least one previewable scenario (healthy
  # reflection = keyword list of {scenario, defaults}). Used to fast-path the
  # start page's "Preview the first Mailable" deep link.
  defp first_previewable(mailables) do
    Enum.find_value(mailables, fn
      {mod, [{scenario, _defaults} | _]} -> {mod, scenario}
      _ -> nil
    end)
  end

  # Absolute path matching the sidebar's scenario links. Built from the
  # known mount path (`/dev/mail`, `/admin/preview`, …) rather than a relative
  # `./` reference — the mount path has no trailing slash, so a relative URL
  # would resolve against the parent and drop the final segment.
  defp first_scenario_path(mount_path, mailables, admin_chrome_theme) do
    case first_previewable(mailables) do
      {mod, scenario} ->
        path =
          MailglassAdmin.Preview.Sidebar.scenario_base_path(mount_path, mod, scenario)

        case theme_query_param(admin_chrome_theme) do
          nil -> path
          theme -> path <> "?theme=" <> theme
        end

      nil ->
        "#"
    end
  end

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

  defp parse_device_width_param(value) when is_integer(value) and value in [375, 768, 1024],
    do: value

  defp parse_device_width_param(value) when is_binary(value) do
    case Integer.parse(value) do
      {width, ""} when width in [375, 768, 1024] -> width
      _ -> 768
    end
  end

  defp parse_device_width_param(_), do: 768

  defp parse_admin_chrome_theme("dark"), do: :dark
  defp parse_admin_chrome_theme("mailglass-dark"), do: :dark
  defp parse_admin_chrome_theme("light"), do: :light
  defp parse_admin_chrome_theme("mailglass-light"), do: :light
  defp parse_admin_chrome_theme(_), do: nil

  defp admin_theme_attr(:dark), do: "mailglass-dark"
  defp admin_theme_attr(:light), do: "mailglass-light"
  defp admin_theme_attr(_theme), do: nil

  defp admin_chrome_dark?(:dark), do: true
  defp admin_chrome_dark?(_theme), do: false

  defp normalize_capture_url_state(params, socket) do
    width =
      case Map.fetch(params, "width") do
        {:ok, width_param} -> parse_device_width_param(width_param)
        :error -> socket.assigns.device_width
      end

    admin_chrome_theme =
      case Map.fetch(params, "theme") do
        {:ok, theme_param} -> parse_admin_chrome_theme(theme_param)
        :error -> socket.assigns.admin_chrome_theme
      end

    {width, admin_chrome_theme}
  end

  defp sync_patch_capture_url_state(socket) do
    current_mailable = socket.assigns.current_mailable
    current_scenario = socket.assigns.current_scenario

    if is_atom(current_mailable) and is_atom(current_scenario) and current_scenario != :__error__ and
         is_binary(socket.assigns.base_path) do
      push_patch(
        socket,
        to:
          build_capture_url(
            socket.assigns.base_path,
            Integer.to_string(socket.assigns.device_width),
            theme_query_param(socket.assigns.admin_chrome_theme)
          )
      )
    else
      socket
    end
  end

  defp build_capture_url(base_path, width, nil), do: base_path <> "?width=" <> width

  defp build_capture_url(base_path, width, theme),
    do: base_path <> "?width=" <> width <> "&theme=" <> theme

  defp preview_theme_path(socket, currently_dark?) do
    page_uri = socket.assigns.page_uri || socket.assigns.mount_path || "/dev/mail"
    parsed = URI.parse(page_uri)
    path = parsed.path || socket.assigns.mount_path || "/dev/mail"

    return_to =
      path
      |> append_query_without_theme(parsed.query || "")

    theme = if currently_dark?, do: "system", else: "dark"
    mount_path = socket.assigns.mount_path || "/dev/mail"

    String.trim_trailing(mount_path, "/") <>
      "/theme/" <> theme <> "?" <> URI.encode_query([{"return_to", return_to}])
  end

  defp append_query_without_theme(path, query) do
    query =
      query
      |> URI.query_decoder()
      |> Enum.reject(fn {key, _value} -> key == "theme" end)
      |> URI.encode_query()

    case query do
      "" -> path
      query -> path <> "?" <> query
    end
  end

  defp theme_query_param(:dark), do: "dark"
  defp theme_query_param(:light), do: "light"
  defp theme_query_param(_theme), do: nil

  defp uri_path(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{path: path} when is_binary(path) -> path
      _ -> nil
    end
  end

  defp uri_path(_), do: nil

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

    ensure_header(
      ensure_header(base, "Message-ID", generate_message_id()),
      "Date",
      rfc2822_date()
    )
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
