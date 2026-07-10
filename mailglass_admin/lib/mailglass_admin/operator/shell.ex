defmodule MailglassAdmin.Operator.Shell do
  @moduledoc """
  Shared application shell for operator surfaces — the chrome wrapping both
  `MailglassAdmin.OperatorLive` (overview/deliveries) and `MailglassAdmin.InboundLive`
  (inbound records). The operator screens mount in the SAME operator `live_session`
  (one `Operator.Mount` + Auth gate). Preview can appear as a configured sibling
  nav link, but it remains a separate route/live-session boundary.

  Provides:

    * a shared topbar plus persistent sidebar that navigates BETWEEN surfaces
      (Health / Preview / Deliveries / Inbound) — navigation, not filtering.
      The Inbound item is conditionally
      omitted via `inbound_available?` (the same `OptionalDeps.MailglassInbound`
      gate the router uses to decide whether to emit the `/inbound` route), so an
      operator without the inbound package never sees a dead link.
    * a shell-owned theme picker. Theme persists as an admin preference cookie,
      so Deliveries↔Inbound navigation and refreshes keep the same chrome
      without adding app preference state to URLs.

  Nav links reset to each surface's base path (no `delivery_id`/`inbound_id`,
  no stale filters): switching surfaces is a fresh question, and inheriting a
  selected id across surfaces is the classic sidebar-nav footgun.

  This is internal UI — not part of the stable router/auth contract.
  """

  use Phoenix.Component

  alias MailglassAdmin.AdminShell
  alias MailglassAdmin.Components
  alias MailglassAdmin.SurfaceNav
  alias MailglassAdmin.Theme

  @doc """
  Whether the inbound surface is present — the SAME gate the router uses to
  decide whether to emit the `/inbound` route. Centralized here so the nav and
  the route never disagree.
  """
  def inbound_available? do
    Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound) and
      MailglassAdmin.OptionalDeps.MailglassInbound.available?()
  end

  @doc """
  Derives the `{deliveries, inbound}` nav paths from a screen's `base_path`,
  carrying only the shared `?tenant_id=` scope across surfaces. `active` tells
  us which surface we're on so we can recover the operator root (the inbound
  screen's `base_path` has a trailing `/inbound` to strip).

  Only `tenant_id` is carried across surfaces — it is the shared scoping
  dimension. Surface-specific filters (delivery vs inbound status sets) are
  intentionally left behind, since they don't translate between surfaces.
  """
  def surface_paths(base_path, active, _dark_chrome, tenant_id \\ nil) do
    root = operator_root(base_path, active)

    %{
      overview: root <> build_query(tenant_id),
      deliveries: root <> build_query(tenant_id, [{"view", "deliveries"}]),
      inbound: path_join(root, "inbound") <> build_query(tenant_id)
    }
  end

  @doc "True when the resolved theme selection is dark."
  def dark_chrome?(params, cookie \\ nil),
    do: theme_choice(params, cookie) == :dark

  @doc """
  Resolves the shell's three-choice picker state from the persisted preference
  cookie. URL `?theme=` is legacy input and is normalized before rendering.
  """
  def theme_choice(params, cookie \\ nil)

  def theme_choice(params, cookie) when is_map(params), do: Theme.cookie_choice(cookie)

  def theme_choice(_params, cookie), do: Theme.cookie_choice(cookie)

  @doc """
  Builds the target for setting the theme picker value through the HTTP
  persistence seam while preserving unrelated query params in `return_to`.

  The `system` choice removes the explicit `theme` query key.
  """
  def set_theme_path(uri, theme) when is_binary(uri) and is_binary(theme) do
    Theme.persistence_path(uri, theme)
  end

  @doc """
  Builds the push_patch target for the theme toggle: flips the `theme` param on
  the CURRENT url, preserving every other filter/selection param.
  """
  def toggle_theme_path(uri, currently_dark?) when is_binary(uri) do
    set_theme_path(uri, if(currently_dark?, do: "system", else: "dark"))
  end

  @doc """
  Builds a same-surface tenant switch path from the current URL.

  Tenant switches preserve compatible filters and theme while dropping selected
  record ids that cannot safely carry across tenants.
  """
  def tenant_switch_path(uri, tenant_id) when is_binary(uri) and is_binary(tenant_id) do
    parsed = URI.parse(uri)
    path = parsed.path || "/"

    query =
      [{"tenant_id", tenant_id}] ++
        preserved_switch_query(parsed.query || "")

    case URI.encode_query(query) do
      "" -> path
      encoded -> path <> "?" <> encoded
    end
  end

  defp operator_root(base_path, :inbound), do: trim_inbound(base_path)
  defp operator_root(base_path, :deliveries), do: base_path

  defp trim_inbound(base_path) do
    case String.replace_suffix(base_path, "/inbound", "") do
      "" -> "/"
      trimmed -> trimmed
    end
  end

  defp path_join("/", segment), do: "/" <> segment
  defp path_join(root, segment), do: String.trim_trailing(root, "/") <> "/" <> segment

  # Builds the shared query string for cross-surface nav. Order is fixed
  # (tenant_id, surface view) so paths are deterministic for tests.
  defp build_query(tenant_id, extra_pairs \\ []) do
    pairs =
      [
        {"tenant_id", blank_to_nil(tenant_id)},
        extra_pairs
      ]
      |> List.flatten()
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    case pairs do
      [] -> ""
      pairs -> "?" <> URI.encode_query(pairs)
    end
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  @switch_query_keys ~w(provider status event outcome window_hours search support_focus support_event_id support_webhook_event_id view)

  defp preserved_switch_query(query) do
    query
    |> URI.query_decoder()
    |> Enum.reject(fn {key, value} ->
      key == "tenant_id" or key not in @switch_query_keys or is_nil(blank_to_nil(value))
    end)
  end

  attr(:active, :atom, values: [:overview, :deliveries, :inbound], required: true)
  attr(:preview_path, :string, default: nil)
  attr(:overview_path, :string, required: true)
  attr(:deliveries_path, :string, required: true)
  attr(:inbound_path, :string, required: true)
  attr(:inbound_available?, :boolean, default: false)
  attr(:dark_chrome, :boolean, default: false)
  attr(:theme_choice, :atom, values: [:system, :light, :dark], default: :system)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:flash, :map, default: %{})
  slot(:inner_block, required: true)

  @doc """
  Renders the operator shell around a surface's body (passed as the inner block).
  """
  def shell(assigns) do
    ~H"""
    <AdminShell.shell
      testid="operator-shell"
      theme_attr={Theme.data_theme(@theme_choice)}
      sidebar_width_class="md:grid-cols-[15rem_1fr]"
      main_max_width_class="max-w-7xl"
    >
      <:actions>
        <Components.theme_picker selected={@theme_choice} event="set_theme" />
      </:actions>
      <:sidebar>
        <SurfaceNav.nav
          active={@active}
          preview_path={@preview_path}
          overview_path={@overview_path}
          deliveries_path={@deliveries_path}
          inbound_path={@inbound_path}
          inbound_available?={@inbound_available?}
        />
      </:sidebar>
      <:mobile_nav>
        <SurfaceNav.nav
          active={@active}
          layout={:mobile}
          preview_path={@preview_path}
          overview_path={@overview_path}
          deliveries_path={@deliveries_path}
          inbound_path={@inbound_path}
          inbound_available?={@inbound_available?}
        />
      </:mobile_nav>
      <:page_header>
        <h1 class="text-heading font-bold tracking-tight text-base-content">{@title}</h1>
        <p :if={@subtitle} class="text-body text-secondary">{@subtitle}</p>
      </:page_header>

      <.flash_region flash={@flash} />

      {render_slot(@inner_block)}
    </AdminShell.shell>
    """
  end

  attr(:flash, :map, default: %{})

  defp flash_region(assigns) do
    ~H"""
    <div
      :if={Phoenix.Flash.get(@flash, :info) || Phoenix.Flash.get(@flash, :error)}
      class="mb-lg space-y-sm"
    >
      <div
        :if={Phoenix.Flash.get(@flash, :info)}
        role="status"
        class="motion-reveal flex items-start gap-sm rounded-box border border-success bg-success/10 px-md py-sm text-body text-base-content"
      >
        <Components.icon name="hero-check-circle" class="mt-0.5 h-5 w-5 shrink-0 text-success" />
        <span>{Phoenix.Flash.get(@flash, :info)}</span>
      </div>
      <div
        :if={Phoenix.Flash.get(@flash, :error)}
        role="alert"
        class="motion-reveal flex items-start gap-sm rounded-box border border-error bg-error/10 px-md py-sm text-body text-base-content"
      >
        <Components.icon name="hero-exclamation-circle" class="mt-0.5 h-5 w-5 shrink-0 text-error" />
        <span>{Phoenix.Flash.get(@flash, :error)}</span>
      </div>
    </div>
    """
  end

  attr(:state, :atom, values: [:select_required, :none], required: true)
  attr(:tenant_options, :list, default: [])
  attr(:current_uri, :string, required: true)

  def tenant_selector(assigns) do
    ~H"""
    <section
      data-testid="tenant-selector"
      class="rounded-box border border-base-300 bg-base-200 p-lg"
    >
      <div class="flex items-start gap-sm">
        <Components.icon name="hero-building-office-2" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
        <div class="min-w-0 flex-1">
          <%= if @state == :none do %>
            <h2 class="text-heading font-bold text-base-content">No tenants available</h2>
            <p class="mt-sm text-body text-secondary">
              This operator does not have a tenant with mail activity yet. Send a Message with a tenant_id, or check the host tenant scope.
            </p>
          <% else %>
            <p class="text-label font-bold uppercase text-secondary">Tenant</p>
            <h2 class="mt-xs text-heading font-bold text-base-content">Select a tenant</h2>
            <p class="mt-sm text-body text-secondary">
              Choose a tenant to inspect its Deliveries and inbound routing. Tenant scope stays in the URL so refreshes and shared links keep the same view.
            </p>
            <div class="mt-md grid gap-sm">
              <.link
                :for={tenant <- @tenant_options}
                patch={tenant_switch_path(@current_uri, tenant.id)}
                class="mg-focus-ring flex min-h-11 items-center justify-between gap-md rounded-field border border-base-300 bg-base-100 px-md py-sm text-body hover:border-primary"
              >
                <span class="mono min-w-0 truncate font-bold text-base-content" title={tenant.label}>
                  {tenant.label}
                </span>
                <span class="shrink-0 text-label font-bold text-primary">Select tenant</span>
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders the orientation strip for an operator surface — a persistent, symptom-first
  guidance panel that appears when no record is selected. Each surface has frozen
  per-surface copy keyed on the most common operator questions for that surface.

  Placed after `defp flash_region/1` as the last function component in the module.
  No motion classes — born token-clean.
  """
  attr(:surface, :atom, values: [:deliveries, :inbound, :preview], required: true)

  def orientation_strip(assigns) do
    assigns = assign(assigns, :copy, copy_for(assigns.surface))

    ~H"""
    <div
      class="rounded-box border border-base-300 bg-base-200 p-md"
      data-testid={"#{@surface}-orientation"}
    >
      <div class="flex items-start gap-sm">
        <Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
        <div class="min-w-0">
          <h2 class="text-body font-bold text-base-content">{@copy.heading}</h2>
          <ul class="mt-2 grid gap-1 text-label text-secondary">
            <li :for={tip <- @copy.tips}>{tip}</li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp copy_for(:deliveries) do
    %{
      heading: "Deliveries",
      tips: [
        "Delivery never arrived? Start here.",
        "Replay changed nothing? View the event timeline.",
        "Address keeps getting blocked? Review the Suppression list."
      ]
    }
  end

  defp copy_for(:inbound) do
    %{
      heading: "Inbound",
      tips: [
        "InboundMessage didn't route as expected? Inspect the routing trace.",
        "No mailbox matched? Check the no-match record.",
        "Failed ingest? Review the provider signature log."
      ]
    }
  end

  defp copy_for(:preview) do
    %{
      heading: "Preview",
      tips: [
        "No mailables found? Define a mailable module in your app.",
        "Mailable not showing? Ensure it's compiled.",
        "Preview not rendering? Check your template syntax."
      ]
    }
  end
end
