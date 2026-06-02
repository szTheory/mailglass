defmodule MailglassAdmin.Operator.Shell do
  @moduledoc """
  Shared application shell for the operator surface — the chrome wrapping both
  `MailglassAdmin.OperatorLive` (deliveries) and `MailglassAdmin.InboundLive`
  (inbound records). The two screens mount in the SAME operator `live_session`
  (one `Operator.Mount` + Auth gate), so a shared shell is a within-surface
  concern, not a cross-mount one — it never reaches the dev-preview surface.

  Provides:

    * a persistent left sidebar that navigates BETWEEN surfaces (Deliveries /
      Inbound) — navigation, not filtering. The Inbound item is conditionally
      omitted via `inbound_available?` (the same `OptionalDeps.MailglassInbound`
      gate the router uses to decide whether to emit the `/inbound` route), so an
      operator without the inbound package never sees a dead link.
    * a read-only tenant-context chip (forensic trust: always show whose data is
      on screen).
    * a shell-owned theme toggle (the dark theme is fully built but was
      previously unreachable from the operator UI). Theme is carried in the URL
      `?theme=` param so it survives both Deliveries↔Inbound navigation and
      refresh — mirroring the preview surface's pattern.

  Nav links reset to each surface's base path (no `delivery_id`/`inbound_id`,
  no stale filters): switching surfaces is a fresh question, and inheriting a
  selected id across surfaces is the classic sidebar-nav footgun.

  This is internal UI — not part of the stable router/auth contract.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

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
  carrying the `?theme=` param so the active theme survives navigation. `active`
  tells us which surface we're on so we can recover the operator root (the
  inbound screen's `base_path` has a trailing `/inbound` to strip).
  """
  def surface_paths(base_path, active, dark_chrome) do
    root = operator_root(base_path, active)

    %{
      deliveries: with_theme(root, dark_chrome),
      inbound: with_theme(path_join(root, "inbound"), dark_chrome)
    }
  end

  @doc "True when the request carries an explicit dark-theme selection."
  def dark_chrome?(params) when is_map(params),
    do: Map.get(params, "theme") in ["dark", "mailglass-dark"]

  def dark_chrome?(_params), do: false

  @doc """
  Builds the push_patch target for the theme toggle: flips the `theme` param on
  the CURRENT url, preserving every other filter/selection param.
  """
  def toggle_theme_path(uri, currently_dark?) when is_binary(uri) do
    parsed = URI.parse(uri)
    query = URI.decode_query(parsed.query || "")

    query =
      if currently_dark?,
        do: Map.delete(query, "theme"),
        else: Map.put(query, "theme", "dark")

    path = parsed.path || "/"

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

  defp with_theme(path, true), do: path <> "?theme=dark"
  defp with_theme(path, false), do: path

  attr :active, :atom, values: [:deliveries, :inbound], required: true
  attr :deliveries_path, :string, required: true
  attr :inbound_path, :string, required: true
  attr :inbound_available?, :boolean, default: false
  attr :dark_chrome, :boolean, default: false
  attr :tenant, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  @doc """
  Renders the operator shell around a surface's body (passed as the inner block).
  """
  def shell(assigns) do
    ~H"""
    <div
      data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
      class="flex min-h-screen bg-base-100 text-base-content"
    >
      <aside class="hidden w-60 shrink-0 flex-col border-r border-base-300 bg-base-200 md:flex">
        <div class="flex items-center gap-sm border-b border-base-300 px-md py-md">
          <Components.logo class="h-6 w-auto" />
          <span class="text-label font-bold uppercase tracking-[0.12em] text-secondary">
            Operator
          </span>
        </div>

        <nav class="flex flex-col gap-xs p-sm" aria-label="Operator sections">
          <.nav_link
            label="Deliveries"
            icon="hero-paper-airplane"
            href={@deliveries_path}
            active={@active == :deliveries}
          />
          <.nav_link
            :if={@inbound_available?}
            label="Inbound"
            icon="hero-inbox-arrow-down"
            href={@inbound_path}
            active={@active == :inbound}
          />
        </nav>

        <div class="mt-auto border-t border-base-300 p-sm">
          <.theme_toggle dark_chrome={@dark_chrome} />
        </div>
      </aside>

      <div class="flex min-w-0 flex-1 flex-col">
        <header class="flex flex-wrap items-center justify-between gap-sm border-b border-base-300 bg-base-200 px-md py-sm md:bg-base-100">
          <div class="flex items-center gap-sm md:hidden">
            <Components.logo class="h-6 w-auto" />
          </div>

          <nav class="flex items-center gap-xs md:hidden" aria-label="Operator sections">
            <.nav_pill
              label="Deliveries"
              href={@deliveries_path}
              active={@active == :deliveries}
            />
            <.nav_pill
              :if={@inbound_available?}
              label="Inbound"
              href={@inbound_path}
              active={@active == :inbound}
            />
          </nav>

          <div class="flex items-center gap-sm">
            <.tenant_chip tenant={@tenant} />
            <span class="md:hidden">
              <.theme_toggle dark_chrome={@dark_chrome} />
            </span>
          </div>
        </header>

        <main class="min-w-0 flex-1 px-md py-lg md:px-lg md:py-xl">
          <div class="mx-auto max-w-7xl">
            <div class="mb-lg flex flex-col gap-xs">
              <h1 class="text-heading font-bold tracking-tight text-base-content">{@title}</h1>
              <p :if={@subtitle} class="text-body text-secondary">{@subtitle}</p>
            </div>

            <.flash_region flash={@flash} />

            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out",
        "duration-(--duration-fast)",
        if(@active,
          do: "border-primary bg-base-100 font-bold text-base-content",
          else: "border-transparent text-secondary hover:bg-base-100/60 hover:text-base-content"
        )
      ]}
    >
      <Components.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span>{@label}</span>
    </.link>
    """
  end

  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, required: true

  defp nav_pill(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-(--duration-fast)",
        if(@active,
          do: "bg-primary/10 font-bold text-base-content",
          else: "text-secondary hover:text-base-content"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end

  attr :tenant, :string, default: nil

  defp tenant_chip(assigns) do
    ~H"""
    <span
      class="inline-flex min-h-11 items-center gap-xs rounded-field border border-base-300 px-sm text-label text-secondary"
      title="Tenant currently in view"
    >
      <Components.icon name="hero-building-office-2" class="h-4 w-4 shrink-0" />
      <span :if={@tenant} class="mono font-bold text-base-content">{@tenant}</span>
      <span :if={!@tenant}>No tenant selected</span>
    </span>
    """
  end

  attr :dark_chrome, :boolean, required: true

  defp theme_toggle(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle_theme"
      aria-label={if @dark_chrome, do: "Switch to light theme", else: "Switch to dark theme"}
      class="btn btn-ghost btn-sm btn-square min-h-11"
    >
      <Components.icon
        name={if @dark_chrome, do: "hero-sun", else: "hero-moon"}
        class="h-5 w-5"
      />
    </button>
    """
  end

  attr :flash, :map, default: %{}

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
end
