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
  carrying the `?tenant_id=` and `?theme=` params so the tenant scope AND the
  active theme survive cross-surface navigation. `active` tells us which surface
  we're on so we can recover the operator root (the inbound screen's `base_path`
  has a trailing `/inbound` to strip).

  Only `tenant_id` is carried across surfaces — it is the shared scoping
  dimension. Surface-specific filters (delivery vs inbound status sets) are
  intentionally left behind, since they don't translate between surfaces.
  """
  def surface_paths(base_path, active, dark_chrome, tenant_id \\ nil) do
    root = operator_root(base_path, active)
    query = build_query(tenant_id, dark_chrome)

    %{
      deliveries: root <> query,
      inbound: path_join(root, "inbound") <> query
    }
  end

  @doc "True when the request carries an explicit dark-theme selection."
  def dark_chrome?(params) when is_map(params),
    do: theme_choice(params) == :dark

  def dark_chrome?(_params), do: false

  @doc """
  Normalizes the URL theme query value into the shell's three-choice picker state.

  `:system` is represented by absence of an explicit theme query value.
  """
  def theme_choice(params) when is_map(params) do
    case Map.get(params, "theme") do
      value when value in ["dark", "mailglass-dark"] -> :dark
      value when value in ["light", "mailglass-light"] -> :light
      _value -> :system
    end
  end

  def theme_choice(_params), do: :system

  @doc """
  Builds the push_patch target for setting the theme picker value on the current
  URL while preserving unrelated query params.

  The `system` choice removes the explicit `theme` query key.
  """
  def set_theme_path(uri, theme) when is_binary(uri) and is_binary(theme) do
    parsed = URI.parse(uri)
    path = parsed.path || "/"

    query =
      (parsed.query || "")
      |> URI.query_decoder()
      |> Enum.reject(fn {key, _value} -> key == "theme" end)
      |> maybe_append_theme(theme)

    case URI.encode_query(query) do
      "" -> path
      encoded -> path <> "?" <> encoded
    end
  end

  @doc """
  Builds the push_patch target for the theme toggle: flips the `theme` param on
  the CURRENT url, preserving every other filter/selection param.
  """
  def toggle_theme_path(uri, currently_dark?) when is_binary(uri) do
    set_theme_path(uri, if(currently_dark?, do: "system", else: "dark"))
  end

  defp maybe_append_theme(query, theme) when theme in ["light", "dark"],
    do: query ++ [{"theme", theme}]

  defp maybe_append_theme(query, _theme), do: query

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
  # (tenant_id then theme) so paths are deterministic for tests.
  defp build_query(tenant_id, dark_chrome) do
    pairs =
      [
        {"tenant_id", blank_to_nil(tenant_id)},
        {"theme", if(dark_chrome, do: "dark", else: nil)}
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    case pairs do
      [] -> ""
      pairs -> "?" <> URI.encode_query(pairs)
    end
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  attr :active, :atom, values: [:deliveries, :inbound], required: true
  attr :deliveries_path, :string, required: true
  attr :inbound_path, :string, required: true
  attr :inbound_available?, :boolean, default: false
  attr :dark_chrome, :boolean, default: false
  attr :theme_choice, :atom, values: [:system, :light, :dark], default: :system
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
      class="mg-admin-root flex min-h-screen bg-base-100 text-base-content"
    >
      <aside class="hidden w-60 shrink-0 flex-col border-r border-base-300 bg-base-200 md:flex">
        <div class="flex items-center gap-sm border-b border-base-300 px-md py-md">
          <Components.logo class="h-6 w-auto" />
          <span class="text-label font-bold uppercase text-secondary">
            Operator
          </span>
        </div>

        <nav class="flex flex-col gap-xs p-sm" aria-label="Operator sections">
          <Components.nav_link
            label="Deliveries"
            icon="hero-paper-airplane"
            href={@deliveries_path}
            active={@active == :deliveries}
          />
          <Components.nav_link
            :if={@inbound_available?}
            label="Inbound"
            icon="hero-inbox-arrow-down"
            href={@inbound_path}
            active={@active == :inbound}
          />
        </nav>

        <div class="mt-auto border-t border-base-300 p-sm">
          <Components.theme_picker selected={@theme_choice} event="set_theme" />
        </div>
      </aside>

      <div class="flex min-w-0 flex-1 flex-col">
        <header class="flex flex-wrap items-center justify-between gap-sm border-b border-base-300 bg-base-200 px-md py-sm md:bg-base-100">
          <div class="flex items-center gap-sm md:hidden">
            <Components.logo class="h-6 w-auto" />
          </div>

          <nav class="flex items-center gap-xs md:hidden" aria-label="Operator sections">
            <Components.nav_pill
              label="Deliveries"
              href={@deliveries_path}
              active={@active == :deliveries}
            />
            <Components.nav_pill
              :if={@inbound_available?}
              label="Inbound"
              href={@inbound_path}
              active={@active == :inbound}
            />
          </nav>

          <div class="flex items-center gap-sm">
            <Components.tenant_chip tenant={@tenant} />
            <span class="md:hidden">
              <Components.theme_picker selected={@theme_choice} event="set_theme" />
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

  @doc """
  Renders the orientation strip for an operator surface — a persistent, symptom-first
  guidance panel that appears when no record is selected. Each surface has frozen
  per-surface copy keyed on the most common operator questions for that surface.

  Placed after `defp flash_region/1` as the last function component in the module.
  No motion classes — born token-clean.
  """
  attr :surface, :atom, values: [:deliveries, :inbound, :preview], required: true

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
