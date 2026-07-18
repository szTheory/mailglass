defmodule MailglassAdmin.Components do
  @moduledoc """
  Brand-book-aligned shared UI atoms used throughout mailglass_admin.

  ## Components

    * `icon/1` — Heroicon via the vendored `heroicons.js` Tailwind plugin
      (Phoenix 1.8 installer convention). Classes matching the pattern
      `hero-<name>` are resolved at build time into inline SVG.
    * `logo/1` — sealed-flap mailglass lockup rendered inline so it inherits
      admin chrome color; the stable `logo.svg` route remains served from
      `priv/static/mailglass-logo.svg` via `MailglassAdmin.Controllers.Assets`.
    * `flash/1` — toast-style flash message for LiveReload + success
      notifications. Brand-voice: no "Oops!", no "Uh oh!"; specific and
      composed per brand book §5.
    * `badge/1` — sidebar status badge with two variants: `:warning`
      (preview_props/0 raised) and `:stub` (no preview_props defined).

  ## Brand voice enforcement

  Copy throughout these atoms follows the 05-UI-SPEC Copywriting
  Contract: clear, exact, confident, warm, technical — "a thoughtful
  maintainer." Banned phrases ("Oops", "Whoops", "Uh oh",
  "Something went wrong") never appear in this module; the voice test
  greps the rendered HTML to enforce the floor.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary declared in `lib/mailglass_admin.ex`;
  `classify_to:` is reserved for mix tasks and protocol implementations
  and is not used here.
  """

  use Phoenix.Component

  attr(:name, :string, required: true)
  attr(:class, :any, default: nil)

  @doc """
  Renders a Heroicon via the vendored `heroicons.js` Tailwind plugin.

  The plugin resolves classes matching `hero-<name>` into inline SVG at
  build time. Usage: `<.icon name="hero-envelope" class="w-5 h-5" />`.
  """
  @doc since: "0.1.0"
  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true"></span>
    """
  end

  attr(:class, :any, default: nil)

  @doc """
  Renders the sealed-flap mailglass lockup inline for theme-aware color.

  The public `logo.svg` route remains served by
  `MailglassAdmin.Controllers.Assets` at `<mount>/logo.svg`; the admin UI
  renders inline so the currentColor paths inherit `text-base-content` in
  light and dark chrome.
  """
  @doc since: "0.1.0"
  def logo(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="-12 -16 973 212"
      width="973"
      height="212"
      role="img"
      aria-label="mailglass"
      class={@class}
    >
      <g>
        <path
          data-part="mark"
          fill="currentColor"
          fill-rule="evenodd"
          d="M 0 44 L 140 44 L 140 140 L 0 140 Z M 14 58 L 126 58 L 70 92 Z M 70 104 A 36 36 0 1 1 70 176 A 36 36 0 1 1 70 104 Z"
        />
      </g>
      <g transform="translate(180 0)">
        <g transform="translate(0 0)">
          <path
            data-glyph="m"
            fill="currentColor"
            d="M 0 140 L 0 40 L 30 40 C 54.5 40 70 47 74 58 C 78 47 83 40 90 40 C 110 40 126 51.5 126 66 L 126 140 L 104 140 L 104 78 C 104 68 98.5 60 92 60 C 84 60 77 63 74 72 L 74 140 L 52 140 L 52 78 C 52 68 46.5 60 40 60 C 32 60 26.5 60.5 22 62 L 22 140 Z"
          />
        </g>
        <g transform="translate(154 0)">
          <path
            data-glyph="a"
            fill="currentColor"
            d="M 38 37 C 57 37 72 46 72 57 L 72 140 L 50 140 L 50 128 C 46.5 135 40 143 29 143 C 13 143 0 129 0 112 C 0 99 4 88 14 84 C 24 81 38 82 50 88 L 50 62 C 43 59 37 57 31 57 C 22 57 15 63 12 70 L 12 46 C 17 41 26 37 38 37 Z M 50 105 C 47 102.5 43 101 36 101 C 27.5 101 22 106 22 112.5 C 22 119.5 27.5 124 36 124 C 43 124 47 122 50 119 L 50 105 Z"
          />
        </g>
        <g transform="translate(257 0)">
          <path
            data-glyph="i"
            fill="currentColor"
            d="M 0 40 L 22 40 L 22 140 L 0 140 Z M 11 -7 C 18 -7 23.5 -1.5 23.5 5.5 C 23.5 12.5 18 18 11 18 C 4 18 -1.5 12.5 -1.5 5.5 C -1.5 -1.5 4 -7 11 -7 Z"
          />
        </g>
        <g transform="translate(310 0)">
          <path data-glyph="l" fill="currentColor" d="M 0 0 L 22 0 L 22 140 L 0 140 Z" />
        </g>
        <g transform="translate(360 0)">
          <path
            data-glyph="g"
            fill="currentColor"
            d="M 0 90 C 0 60.5 13.5 37 33 37 C 42 37 47.5 38.5 52 40 L 74 40 L 74 152 C 74 165.5 63 177 46 177 L 30 177 L 30 157 C 41 157 52 153 52 141 L 52 127 C 49 136 43 143 33 143 C 14.5 143 0 119.5 0 90 Z M 37 57 C 28.5 57 22 71.5 22 90 C 22 108.5 28.5 123 37 123 C 45.5 123 52 108.5 52 90 C 52 71.5 45.5 57 37 57 Z"
          />
        </g>
        <g transform="translate(465 0)">
          <path data-glyph="l" fill="currentColor" d="M 0 0 L 22 0 L 22 140 L 0 140 Z" />
        </g>
        <g transform="translate(515 0)">
          <path
            data-glyph="a"
            fill="currentColor"
            d="M 38 37 C 57 37 72 46 72 57 L 72 140 L 50 140 L 50 128 C 46.5 135 40 143 29 143 C 13 143 0 129 0 112 C 0 99 4 88 14 84 C 24 81 38 82 50 88 L 50 62 C 43 59 37 57 31 57 C 22 57 15 63 12 70 L 12 46 C 17 41 26 37 38 37 Z M 50 105 C 47 102.5 43 101 36 101 C 27.5 101 22 106 22 112.5 C 22 119.5 27.5 124 36 124 C 43 124 47 122 50 119 L 50 105 Z"
          />
        </g>
        <g transform="translate(615 0)">
          <path
            data-glyph="s"
            fill="currentColor"
            d="M 58 43 C 49.5 39 41 37 31 37 C 16 37 0 47 0 59 C 0 71 7 88 16 94 C 24 99.5 32 103 40 107.5 C 44.5 110 46.5 113.5 45.5 117 C 43.5 121.5 38 124 30.5 124 C 22 124 15 121.5 9.5 118 L 9.5 137 C 16 141 24 143 32 143 C 49.5 143 64 130 64 114 C 64 100 57 90.5 51 87 C 41.5 81.5 32 76.5 23 72 C 20.5 70.5 19.5 67.5 20 63 C 21.5 58.5 25 57 30 57 C 40 57.5 50 59 58 62 Z"
          />
        </g>
        <g transform="translate(705 0)">
          <path
            data-glyph="s"
            fill="currentColor"
            d="M 58 43 C 49.5 39 41 37 31 37 C 16 37 0 47 0 59 C 0 71 7 88 16 94 C 24 99.5 32 103 40 107.5 C 44.5 110 46.5 113.5 45.5 117 C 43.5 121.5 38 124 30.5 124 C 22 124 15 121.5 9.5 118 L 9.5 137 C 16 141 24 143 32 143 C 49.5 143 64 130 64 114 C 64 100 57 90.5 51 87 C 41.5 81.5 32 76.5 23 72 C 20.5 70.5 19.5 67.5 20 63 C 21.5 58.5 25 57 30 57 C 40 57.5 50 59 58 62 Z"
          />
        </g>
      </g>
    </svg>
    """
  end

  attr(:kind, :atom, values: [:info, :success, :warning, :error], default: :info)
  attr(:message, :string, required: true)

  @doc """
  Renders a brand-voice flash message in a daisyUI toast wrapper.

  Used for LiveReload notifications ("Reloaded: {file}") and other
  transient signals. Includes `role="status"` + `aria-live="polite"`
  per the 05-UI-SPEC Accessibility Interactions contract.
  """
  @doc since: "0.1.0"
  def flash(assigns) do
    ~H"""
    <div class="toast toast-top toast-end mg-layer-toast" role="status" aria-live="polite">
      <div class={["motion-reveal alert text-body gap-2 py-2 px-3", alert_class(@kind)]}>
        <.icon name="hero-arrow-path" class="w-4 h-4" />
        <span>{@message}</span>
      </div>
    </div>
    """
  end

  defp alert_class(:info), do: "alert-info"
  defp alert_class(:success), do: "alert-success"
  defp alert_class(:warning), do: "alert-warning"
  defp alert_class(:error), do: "alert-error"

  attr(:variant, :atom, values: [:warning, :stub], required: true)

  @doc """
  Sidebar status badge. Two variants:

    * `:warning` — preview_props/0 raised; shows an exclamation-triangle
      Heroicon + the literal copy "Error" (per 05-UI-SPEC Badge section).
    * `:stub` — mailable has no preview_props/0 defined; shows the "—"
      glyph in Slate (secondary) color.
  """
  @doc since: "0.1.0"
  def badge(%{variant: :warning} = assigns) do
    ~H"""
    <span class="badge badge-warning badge-sm gap-1">
      <.icon name="hero-exclamation-triangle" class="w-3 h-3" /> Error
    </span>
    """
  end

  def badge(%{variant: :stub} = assigns) do
    ~H"""
    <span class="text-secondary text-label">—</span>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:href, :string, required: true)
  attr(:active, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:navigate, :boolean, default: true)
  attr(:rest, :global, default: %{})

  @doc """
  Renders the desktop operator navigation link primitive.

  Disabled links are rendered as inert text with link semantics, `aria-disabled`,
  and no LiveView navigation attribute.
  """
  @doc since: "1.8.0"
  def nav_link(%{disabled: true} = assigns) do
    ~H"""
    <span
      role="link"
      aria-disabled="true"
      tabindex="-1"
      class={[
        "flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body",
        "border-transparent text-secondary opacity-100"
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="truncate" title={@label}>{@label}</span>
    </span>
    """
  end

  def nav_link(%{navigate: false} = assigns) do
    ~H"""
    <.link
      href={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out",
        "duration-(--duration-fast)",
        nav_link_class(@active)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="truncate" title={@label}>{@label}</span>
    </.link>
    """
  end

  def nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out",
        "duration-(--duration-fast)",
        nav_link_class(@active)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="truncate" title={@label}>{@label}</span>
    </.link>
    """
  end

  attr(:label, :string, required: true)
  attr(:href, :string, required: true)
  attr(:active, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:navigate, :boolean, default: true)
  attr(:rest, :global, default: %{})

  @doc """
  Renders the compact operator navigation pill primitive.

  Disabled pills are visibly inactive and expose `aria-disabled` without a
  LiveView navigation attribute.
  """
  @doc since: "1.8.0"
  def nav_pill(%{disabled: true} = assigns) do
    ~H"""
    <span
      role="link"
      aria-disabled="true"
      tabindex="-1"
      class="flex min-h-11 items-center rounded-field border-b-2 border-transparent px-sm text-body text-secondary opacity-100"
      {@rest}
    >
      <span class="truncate" title={@label}>{@label}</span>
    </span>
    """
  end

  def nav_pill(%{navigate: false} = assigns) do
    ~H"""
    <.link
      href={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center rounded-field border-b-2 px-sm text-body transition-colors ease-out duration-(--duration-fast)",
        nav_pill_class(@active)
      ]}
      {@rest}
    >
      <span class="truncate" title={@label}>{@label}</span>
    </.link>
    """
  end

  def nav_pill(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center rounded-field border-b-2 px-sm text-body transition-colors ease-out duration-(--duration-fast)",
        nav_pill_class(@active)
      ]}
      {@rest}
    >
      <span class="truncate" title={@label}>{@label}</span>
    </.link>
    """
  end

  attr(:tenant, :string, default: nil)
  attr(:rest, :global, default: %{})

  @doc """
  Renders the read-only account context chip.

  The chip intentionally does not expose switching, loading, or navigation
  behavior.
  """
  @doc since: "1.8.0"
  def tenant_chip(assigns) do
    ~H"""
    <span
      class="inline-flex min-h-11 max-w-full items-center gap-xs rounded-field border border-base-300 px-sm text-label text-secondary"
      title={tenant_chip_title(@tenant)}
      {@rest}
    >
      <.icon name="hero-building-office-2" class="h-4 w-4 shrink-0" />
      <span :if={@tenant} class="mono min-w-0 truncate font-bold text-base-content">{@tenant}</span>
      <span :if={!@tenant}>No account selected</span>
    </span>
    """
  end

  attr(:selected, :atom, values: [:system, :light, :dark], default: :system)
  attr(:name, :string, default: "theme")
  attr(:disabled, :boolean, default: false)
  attr(:event, :string, default: nil)
  attr(:target, :any, default: nil)
  attr(:rest, :global, default: %{})

  @doc """
  Renders the three-choice theme picker primitive.

  The primitive owns radio semantics only. Persistence, cookie naming, root
  theme resolution, browser storage, and first-paint behavior are downstream
  shell concerns.
  """
  @doc since: "1.8.0"
  def theme_picker(assigns) do
    ~H"""
    <fieldset
      class="inline-flex min-h-11 items-center gap-xs rounded-box border border-base-300 bg-base-200 p-xs text-label"
      disabled={@disabled}
      {@rest}
    >
      <legend class="sr-only">Theme</legend>
      <label
        :for={option <- theme_options()}
        title={option.label}
        class={[
          "mg-focus-ring-within mg-state-layer relative flex min-h-11 min-w-11 cursor-pointer items-center justify-center rounded-field px-sm",
          theme_option_class(@selected == option.theme, @disabled)
        ]}
      >
        <%!-- The radio is a transparent overlay filling the whole segment, so a
              click lands on the input itself and fires phx-click directly (a
              clipped sr-only input is not the click target — the label/span is,
              and LiveView's closest() only walks ancestors, never the input). --%>
        <input
          type="radio"
          name={@name}
          value={option.value}
          checked={@selected == option.theme}
          disabled={@disabled}
          aria-label={option.label}
          phx-click={@event}
          phx-target={@target}
          phx-value-theme={if @event, do: option.value}
          class="absolute inset-0 m-0 cursor-pointer appearance-none rounded-field opacity-0 disabled:cursor-default"
        />
        <.icon name={option.icon} class="pointer-events-none h-5 w-5" />
        <span class="sr-only">{option.label}</span>
      </label>
    </fieldset>
    """
  end

  attr(:id, :string, default: nil)
  attr(:label, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:severity, :atom, values: [:neutral, :info, :success, :warning, :error], default: :neutral)
  attr(:severity_label, :string, default: nil)
  attr(:state, :atom, values: [:ready, :empty, :loading, :unavailable], default: :ready)
  attr(:empty_text, :string, default: "No data yet")
  attr(:loading_text, :string, default: "Resolving")
  attr(:unavailable_text, :string, default: "Unavailable")
  attr(:hint, :string, default: nil)
  attr(:rest, :global, default: %{})

  @doc """
  Renders a canonical stat card with label, no-wrap value, and severity.

  Severity is a closed set and always renders as icon plus visible label plus
  semantic color.
  """
  @doc since: "1.8.0"
  def stat_card(assigns) do
    assigns =
      assigns
      |> assign(:display_value, stat_display_value(assigns))
      |> assign(
        :display_severity_label,
        assigns.severity_label || stat_severity_label(assigns.severity)
      )

    ~H"""
    <article
      id={@id}
      class={[
        "min-w-0 rounded-box border border-base-300 bg-base-200 p-md",
        present?(@hint) && "mg-stat-card-hint"
      ]}
      aria-busy={if @state == :loading, do: "true"}
      {@rest}
    >
      <div class="flex min-w-0 items-start justify-between gap-sm">
        <p class="flex min-w-0 items-center gap-xs text-label font-bold uppercase text-secondary">
          <span class="truncate" title={@label}>{@label}</span>
          <span
            :if={present?(@hint)}
            class="inline-flex shrink-0 text-secondary"
            aria-hidden="true"
          >
            <.icon name="hero-information-circle" class="h-3.5 w-3.5" />
          </span>
        </p>
      </div>
      <p :if={present?(@hint)} class="sr-only">{@hint}</p>
      <p :if={present?(@hint)} class="mg-stat-card-tooltip" aria-hidden="true">
        {@hint}
      </p>
      <p
        class="mono mt-xs truncate text-display font-bold tabular-nums whitespace-nowrap text-base-content"
        title={@display_value}
      >
        {@display_value}
      </p>
      <p class={[
        "mt-sm inline-flex items-center gap-xs text-label font-bold",
        stat_severity_class(@severity)
      ]}>
        <.icon name={stat_severity_icon(@severity)} class="h-4 w-4 shrink-0" />
        <span>{@display_severity_label}</span>
      </p>
    </article>
    """
  end

  attr(:kind, :atom, values: [:empty, :error, :permission_denied, :stale], required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:rest, :global, default: %{})

  @doc """
  Renders one of four distinct data-state templates.

  Each kind maps to a unique testid, icon, and icon color so that
  permission-denied is never mistaken for no-data, and error is never
  conflated with stale-data.

  ## Kinds

    * `:empty` — no records; rendered with `hero-inbox` and `text-secondary`
    * `:error` — unavailable/error; rendered with `hero-exclamation-circle` and `text-error`
    * `:permission_denied` — access restricted; rendered with `hero-lock-closed` and `text-warning`
    * `:stale` — data may be out of date; rendered with `hero-clock` and `text-secondary`
  """
  @doc since: "1.13.0"
  def data_state(assigns) do
    assigns =
      assign(assigns, :resolved_icon, assigns.icon || data_state_icon(assigns.kind))

    ~H"""
    <section
      data-testid={data_state_testid(@kind)}
      class="flex flex-col items-center gap-sm p-lg text-center"
      {@rest}
    >
      <.icon
        name={@resolved_icon}
        class={["h-8 w-8", data_state_icon_class(@kind)]}
      />
      <h3 class="text-body font-bold text-base-content">{@title}</h3>
      <p class="text-body text-secondary">{@body}</p>
    </section>
    """
  end

  defp data_state_testid(:empty), do: "data-state-empty"
  defp data_state_testid(:error), do: "data-state-error"
  defp data_state_testid(:permission_denied), do: "data-state-permission-denied"
  defp data_state_testid(:stale), do: "data-state-stale"

  defp data_state_icon(:empty), do: "hero-inbox"
  defp data_state_icon(:error), do: "hero-exclamation-circle"
  defp data_state_icon(:permission_denied), do: "hero-lock-closed"
  defp data_state_icon(:stale), do: "hero-clock"

  defp data_state_icon_class(:empty), do: "text-secondary"
  defp data_state_icon_class(:error), do: "text-error"
  defp data_state_icon_class(:permission_denied), do: "text-warning"
  defp data_state_icon_class(:stale), do: "text-secondary"

  attr(:padding, :atom, values: [:md, :lg], default: :md)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  @doc """
  Renders the thin group-surface shell: border, radius, surface tone, and outer
  padding only.

  This is the single source for the group-surface shell. It deliberately owns no
  layout engine — no header/footer/grid slots, no inter-card rhythm, no `dl`/`ol`
  spacing. `shadow-raised` and `data-group-card` are applied at call sites, not
  baked in here. Padding is the one closed knob (`:md` -> `p-md`, `:lg` -> `p-lg`).
  """
  @doc since: "1.13.0"
  def card(assigns) do
    ~H"""
    <div class={["rounded-box border border-base-300 bg-base-200", card_padding(@padding)]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp card_padding(:md), do: "p-md"
  defp card_padding(:lg), do: "p-lg"

  defp nav_link_class(true), do: "border-primary bg-base-100 font-bold text-base-content"

  defp nav_link_class(false),
    do: "border-transparent text-secondary hover:bg-base-100/60 hover:text-base-content"

  defp nav_pill_class(true), do: "border-primary bg-primary/10 font-bold text-base-content"
  defp nav_pill_class(false), do: "border-transparent text-secondary hover:text-base-content"

  defp tenant_chip_title(nil), do: "Account currently in view"
  defp tenant_chip_title(tenant), do: "Account currently in view: " <> tenant

  defp theme_options do
    [
      %{theme: :system, value: "system", label: "System", icon: "hero-window"},
      %{theme: :light, value: "light", label: "Light", icon: "hero-sun"},
      %{theme: :dark, value: "dark", label: "Dark", icon: "hero-moon"}
    ]
  end

  defp theme_option_class(_selected, true),
    do: "border border-transparent text-secondary opacity-60"

  defp theme_option_class(true, false),
    do: "border border-primary bg-base-100 text-base-content"

  defp theme_option_class(false, false),
    do: "border border-transparent text-secondary hover:bg-base-100/70 hover:text-base-content"

  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:rest, :global, default: %{})

  slot(:inner_block, required: true)

  @doc """
  Renders a visible filter control group.

  The primitive uses native fieldset/legend semantics so pages can group
  related filters without duplicating page-local label/control wrappers.
  """
  @doc since: "1.8.0"
  def filter_section(assigns) do
    ~H"""
    <fieldset class="min-w-0 w-full" {@rest}>
      <legend class="text-label font-bold uppercase text-secondary">{@title}</legend>
      <div class="grid min-w-0 gap-md">
        <p :if={@description} class="max-w-prose text-pretty text-body text-secondary">
          {@description}
        </p>
        <div class="grid grid-cols-1 gap-md sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {render_slot(@inner_block)}
        </div>
      </div>
    </fieldset>
    """
  end

  attr(:field, :any, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :atom, values: [:text, :number, :select, :textarea, :checkbox], default: :text)
  attr(:label, :string, required: true)
  attr(:help, :string, default: nil)
  attr(:error, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:display_value, :string, default: nil)
  attr(:submit_readonly, :boolean, default: true)

  attr(:rest, :global,
    default: %{},
    include: ~w(autocomplete inputmode max min pattern placeholder step)
  )

  @doc """
  Renders one explicit, labelled filter control.

  Defaults derive from `Phoenix.HTML.FormField` metadata when `field` is
  provided. Explicit `id`, `name`, and `value` remain supported for gallery
  and certification surfaces that render without a form struct.
  """
  @doc since: "1.8.0"
  def filter_field(assigns) do
    assigns =
      assigns
      |> assign_filter_field_metadata()
      |> assign(:native_readonly?, native_readonly?(assigns.type, assigns.readonly))
      |> assign(:display_readonly?, display_readonly?(assigns.type, assigns.readonly))

    ~H"""
    <div class="grid min-w-0 content-start gap-xs">
      <label for={@control_id} class="text-label font-bold text-base-content">{@label}</label>

      <input
        :if={@type in [:text, :number] and !@display_readonly?}
        id={@control_id}
        name={@control_name}
        type={Atom.to_string(@type)}
        value={@control_value}
        disabled={@disabled}
        readonly={@native_readonly?}
        aria-describedby={@described_by}
        aria-invalid={@invalid? && "true"}
        class={filter_input_class(@invalid?, @disabled, @native_readonly?)}
        {@rest}
      />

      <textarea
        :if={@type == :textarea and !@display_readonly?}
        id={@control_id}
        name={@control_name}
        disabled={@disabled}
        readonly={@native_readonly?}
        aria-describedby={@described_by}
        aria-invalid={@invalid? && "true"}
        class={filter_textarea_class(@invalid?, @disabled, @native_readonly?)}
        {@rest}
      >{filter_string_value(@control_value)}</textarea>

      <select
        :if={@type == :select and !@display_readonly?}
        id={@control_id}
        name={@control_name}
        disabled={@disabled}
        aria-describedby={@described_by}
        aria-invalid={@invalid? && "true"}
        class={filter_select_class(@invalid?, @disabled)}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        <option
          :for={option <- @normalized_options}
          value={option.value}
          selected={option.value == filter_string_value(@control_value)}
        >
          {option.label}
        </option>
      </select>

      <div :if={@type == :checkbox and !@display_readonly?} class="flex min-h-11 items-center gap-sm">
        <input
          type="hidden"
          name={@control_name}
          value="false"
          disabled={@disabled}
        />
        <input
          id={@control_id}
          name={@control_name}
          type="checkbox"
          value="true"
          checked={filter_checked?(@control_value)}
          disabled={@disabled}
          aria-describedby={@described_by}
          aria-invalid={@invalid? && "true"}
          class={filter_checkbox_class(@invalid?, @disabled)}
          {@rest}
        />
      </div>

      <div
        :if={@display_readonly?}
        id={@control_id}
        role="textbox"
        aria-readonly="true"
        tabindex="0"
        aria-describedby={@described_by}
        aria-invalid={@invalid? && "true"}
        class={filter_display_class(@invalid?)}
      >
        <span class="block text-label font-bold text-secondary">Read-only value</span>
        <span>{@display_text}</span>
      </div>

      <input
        :if={
          (@display_readonly? and @submit_readonly and @control_name) &&
            filter_string_value(@control_value) != ""
        }
        type="hidden"
        name={@control_name}
        value={@control_value}
      />

      <p :if={@help} id={@help_id} class="text-label text-secondary">{@help}</p>

      <p
        :if={@error_text}
        id={@error_id}
        role="alert"
        class="flex items-start gap-xs text-label text-error"
      >
        <.icon name="hero-exclamation-circle" class="mt-0.5 h-4 w-4 shrink-0" />
        <span>
          <span class="font-bold">Action needed:</span> {@error_text}
        </span>
      </p>
    </div>
    """
  end

  defp stat_display_value(%{state: :empty, empty_text: empty_text}), do: empty_text
  defp stat_display_value(%{state: :loading, loading_text: loading_text}), do: loading_text

  defp stat_display_value(%{state: :unavailable, unavailable_text: unavailable_text}),
    do: unavailable_text

  defp stat_display_value(%{value: nil, empty_text: empty_text}), do: empty_text
  defp stat_display_value(%{value: value}), do: to_string(value)

  defp stat_severity_icon(:neutral), do: "hero-minus-circle"
  defp stat_severity_icon(:info), do: "hero-question-mark-circle"
  defp stat_severity_icon(:success), do: "hero-check-circle"
  defp stat_severity_icon(:warning), do: "hero-exclamation-triangle"
  defp stat_severity_icon(:error), do: "hero-x-circle"

  defp stat_severity_label(:neutral), do: "All clear"
  defp stat_severity_label(:info), do: "Info"
  defp stat_severity_label(:success), do: "Healthy"
  defp stat_severity_label(:warning), do: "Needs attention"
  defp stat_severity_label(:error), do: "Problem"

  defp stat_severity_class(:neutral), do: "text-secondary"
  defp stat_severity_class(:info), do: "text-primary"
  defp stat_severity_class(:success), do: "text-success"
  defp stat_severity_class(:warning), do: "text-warning"
  defp stat_severity_class(:error), do: "text-error"

  defp assign_filter_field_metadata(assigns) do
    control_id = filter_control_id(assigns)
    error_text = filter_error_text(assigns)
    help_id = if present?(assigns.help), do: "#{control_id}-help"
    error_id = if present?(error_text), do: "#{control_id}-error"
    described_by = filter_described_by([help_id, error_id])
    normalized_options = normalize_filter_options(assigns.options)
    control_value = filter_control_value(assigns)

    assigns
    |> assign(:control_id, control_id)
    |> assign(:control_name, filter_control_name(assigns))
    |> assign(:control_value, control_value)
    |> assign(:error_text, error_text)
    |> assign(:invalid?, present?(error_text))
    |> assign(:help_id, help_id)
    |> assign(:error_id, error_id)
    |> assign(:described_by, described_by)
    |> assign(:normalized_options, normalized_options)
    |> assign(:display_text, filter_display_text(assigns, normalized_options, control_value))
  end

  defp filter_control_id(%{id: id}) when is_binary(id) and id != "", do: id
  defp filter_control_id(%{field: %{id: id}}) when is_binary(id) and id != "", do: id
  defp filter_control_id(%{label: label}), do: "filter_" <> filter_slug(label)

  defp filter_control_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp filter_control_name(%{field: %{name: name}}) when is_binary(name) and name != "", do: name
  defp filter_control_name(_assigns), do: nil

  defp filter_control_value(%{value: nil, field: %{value: value}}), do: value
  defp filter_control_value(%{value: value}), do: value

  defp filter_error_text(%{error: error}) do
    normalize_filter_error(error)
  end

  defp filter_error_text(%{field: %{errors: errors}}), do: normalize_filter_error(errors)
  defp filter_error_text(_assigns), do: nil

  defp normalize_filter_error(nil), do: nil
  defp normalize_filter_error(""), do: nil
  defp normalize_filter_error(error) when is_binary(error), do: error

  defp normalize_filter_error(errors) when is_list(errors) do
    errors
    |> Enum.map(&normalize_filter_error/1)
    |> Enum.find(&present?/1)
  end

  defp normalize_filter_error({message, _opts}), do: normalize_filter_error(message)
  defp normalize_filter_error(error), do: to_string(error)

  defp normalize_filter_options(options) do
    Enum.map(options, fn
      {label, value} ->
        %{label: to_string(label), value: filter_string_value(value)}

      %{label: label, value: value} ->
        %{label: to_string(label), value: filter_string_value(value)}

      %{label: label, key: value} ->
        %{label: to_string(label), value: filter_string_value(value)}

      value ->
        %{label: filter_option_label(value), value: filter_string_value(value)}
    end)
  end

  defp filter_display_text(%{display_value: display_value}, _options, _value)
       when is_binary(display_value) and display_value != "",
       do: display_value

  defp filter_display_text(_assigns, options, value) do
    value_string = filter_string_value(value)

    options
    |> Enum.find(%{label: value_string}, &(&1.value == value_string))
    |> Map.fetch!(:label)
  end

  defp filter_option_label(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp filter_option_label(value), do: to_string(value)

  defp filter_slug(label) do
    label
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp filter_described_by(ids) do
    ids
    |> Enum.filter(&present?/1)
    |> case do
      [] -> nil
      present_ids -> Enum.join(present_ids, " ")
    end
  end

  defp native_readonly?(type, true) when type in [:text, :number, :textarea], do: true
  defp native_readonly?(_type, _readonly), do: false

  defp display_readonly?(type, true) when type in [:select, :checkbox], do: true
  defp display_readonly?(_type, _readonly), do: false

  defp filter_checked?(value) when value in [true, "true", "1", 1, "on"], do: true
  defp filter_checked?(_value), do: false

  defp filter_string_value(nil), do: ""
  defp filter_string_value(value), do: to_string(value)

  defp filter_input_class(invalid?, disabled?, readonly?) do
    [
      "input input-bordered input-sm min-h-11 w-full text-body mg-focus-ring",
      invalid? && "input-error",
      disabled? && "bg-base-200 text-secondary opacity-100",
      readonly? && "bg-base-200 text-base-content"
    ]
  end

  defp filter_textarea_class(invalid?, disabled?, readonly?) do
    [
      "textarea textarea-bordered textarea-sm min-h-11 w-full text-body mg-focus-ring",
      invalid? && "textarea-error",
      disabled? && "bg-base-200 text-secondary opacity-100",
      readonly? && "bg-base-200 text-base-content"
    ]
  end

  defp filter_select_class(invalid?, disabled?) do
    [
      "select select-bordered select-sm min-h-11 w-full text-body mg-focus-ring",
      invalid? && "select-error",
      disabled? && "bg-base-200 text-secondary opacity-100"
    ]
  end

  defp filter_checkbox_class(invalid?, disabled?) do
    [
      "checkbox checkbox-sm mg-focus-ring",
      invalid? && "checkbox-error",
      disabled? && "opacity-100"
    ]
  end

  defp filter_display_class(invalid?) do
    [
      "min-h-11 rounded-field border border-base-300 bg-base-200 px-sm py-2 text-body text-base-content",
      "mg-focus-ring",
      invalid? && "border-error"
    ]
  end

  defp present?(value), do: is_binary(value) and value != ""

  @doc """
  Normalizes inbound @outcomes singular atoms to the canonical past-tense atoms expected by
  status_badge/1. The mailglass_inbound @outcomes schema (locked 1.0 contract) is never modified;
  normalization is admin-side only.

  Maps: `:accept` → `:accepted`, `:reject` → `:rejected`, `:bounce` → `:bounced`.
  All other atoms (including nil) pass through unchanged.
  """
  @doc since: "1.5.0"
  @spec normalize_inbound_outcome(atom() | nil) :: atom() | nil
  def normalize_inbound_outcome(:accept), do: :accepted
  def normalize_inbound_outcome(:reject), do: :rejected
  def normalize_inbound_outcome(:bounce), do: :bounced
  def normalize_inbound_outcome(atom), do: atom

  attr(:status, :atom,
    values: [
      :dispatched,
      :queued,
      :sent,
      :delivered,
      :deferred,
      :bounced,
      :failed,
      :rejected,
      :complained,
      :unsubscribed,
      :opened,
      :clicked,
      :autoresponded,
      :unknown,
      :accepted,
      :no_match,
      :ignore,
      :failed_ingest,
      :webhook_replay_requested,
      :webhook_replay_succeeded,
      :webhook_replay_failed,
      :reconciled,
      :suppressed
    ],
    required: true
  )

  attr(:size, :atom, values: [:sm, :md], default: :sm)

  @doc """
  Unified delivery, inbound, and timeline status badge. Renders an outline Heroicon
  (decorative, aria-hidden) and a text label inside a daisyUI badge container.

  The base badge class is always emitted by this component — call sites must NOT
  prepend 'badge' or 'badge badge-sm'. Use size: :sm (default) for list rows;
  size: :md for detail headers.
  """
  @doc since: "1.5.0"
  def status_badge(assigns) do
    ~H"""
    <span class={["badge", size_class(@size), status_class(@status)]}>
      <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>{status_label(@status)}
    </span>
    """
  end

  # Downstream outcome events that supersede the dispatch snapshot — when one of these
  # is the delivery's latest event, it IS the status the operator should see.
  @downstream_outcomes [
    :delivered,
    :opened,
    :clicked,
    :bounced,
    :complained,
    :rejected,
    :deferred,
    :unsubscribed
  ]

  @doc """
  The lifecycle state the operator Deliveries badge should display for a delivery.

  The core `Delivery.status` is a stable adopter snapshot that stops at `:sent`
  (handed off to the provider) and never advances. For the operator view we surface
  the message's *furthest-known* state instead: a downstream event
  (delivered/opened/clicked/bounced/…) supersedes the dispatch snapshot, so the badge
  reflects what actually happened. The in-flight, handed-off-but-unconfirmed state
  renders as `:dispatched` ("Dispatched"). This is presentation only — it never
  mutates `Delivery.status`.
  """
  @doc since: "1.7.0"
  def delivery_display_status(%{last_event_type: event}) when event in @downstream_outcomes,
    do: event

  def delivery_display_status(%{status: :failed}), do: :failed
  def delivery_display_status(%{status: :suppressed}), do: :suppressed
  def delivery_display_status(%{last_event_type: :suppressed}), do: :suppressed

  def delivery_display_status(%{status: :queued, last_event_type: event})
      when event in [:queued, nil],
      do: :queued

  # In-flight: status :sent / handed-off with no downstream outcome yet.
  def delivery_display_status(_delivery), do: :dispatched

  attr(:at, :any, required: true, doc: "a UTC %DateTime{} or nil")
  attr(:class, :string, default: "", doc: "extra classes for the <time> element")

  @doc """
  Renders a UTC `%DateTime{}` as a `<time>` element the admin's local-time script
  progressively enhances: the server-rendered text is the canonical UTC string
  (`"YYYY-MM-DD HH:MM:SS UTC"`), and on the client the script rewrites the text to the
  viewer's local timezone, keeps the UTC in the `title` tooltip, and copies the UTC to
  the clipboard on click. With JS off (or before hydration) the UTC string stands on its
  own. `nil` renders the plain `"Pending"` sentinel (no `<time>`).
  """
  @doc since: "1.7.0"
  def timestamp(%{at: nil} = assigns) do
    ~H"""
    Pending
    """
  end

  def timestamp(assigns) do
    ~H"""
    <time
      datetime={DateTime.to_iso8601(@at)}
      data-local-time="true"
      data-utc={utc_string(@at)}
      title={utc_string(@at)}
      class={["mono cursor-pointer", @class]}
    >{utc_string(@at)}</time>
    """
  end

  defp utc_string(%DateTime{} = at), do: Calendar.strftime(at, "%Y-%m-%d %H:%M:%S UTC")

  defp size_class(:sm), do: "badge-sm"
  defp size_class(:md), do: "badge-md"

  @doc """
  Classifies an event/delivery status into a semantic tone.

  The single source of truth for status color across the admin package: the
  status badge (`status_class/1` below) and the operator/inbound timeline dots
  both derive from this, so a "Delivered" badge and its timeline dot can never
  disagree on which events read as success / error / warning / accent / neutral.
  """
  @spec status_tone(atom()) :: :success | :error | :warning | :accent | :neutral
  def status_tone(status)
      when status in [:delivered, :opened, :clicked, :accepted, :webhook_replay_succeeded],
      do: :success

  def status_tone(status)
      when status in [
             :bounced,
             :failed,
             :rejected,
             :complained,
             :failed_ingest,
             :webhook_replay_failed
           ],
      do: :error

  def status_tone(status)
      when status in [:deferred, :unsubscribed, :no_match, :reconciled, :suppressed],
      do: :warning

  def status_tone(status) when status in [:dispatched, :queued, :sent], do: :accent

  # Neutral: autoresponded, unknown, ignore, webhook_replay_requested, and any
  # unrecognized atom or nil (per UI-SPEC Conflict 1).
  def status_tone(_status), do: :neutral

  defp status_class(status), do: tone_badge_class(status_tone(status))

  defp tone_badge_class(:success), do: "badge-success"
  defp tone_badge_class(:error), do: "badge-error"
  defp tone_badge_class(:warning), do: "badge-warning"
  defp tone_badge_class(:accent), do: "badge-primary"
  defp tone_badge_class(:neutral), do: "badge-outline"

  defp status_icon(:dispatched), do: "hero-paper-airplane"
  defp status_icon(:queued), do: "hero-arrow-path"
  defp status_icon(:sent), do: "hero-paper-airplane"
  defp status_icon(:delivered), do: "hero-check-circle"
  defp status_icon(:deferred), do: "hero-exclamation-triangle"
  defp status_icon(:bounced), do: "hero-x-circle"
  defp status_icon(:failed), do: "hero-x-circle"
  defp status_icon(:rejected), do: "hero-x-circle"
  defp status_icon(:complained), do: "hero-exclamation-circle"
  defp status_icon(:unsubscribed), do: "hero-bell-slash"
  defp status_icon(:opened), do: "hero-envelope-open"
  defp status_icon(:clicked), do: "hero-hand-thumb-up"
  defp status_icon(:autoresponded), do: "hero-arrow-uturn-left"
  defp status_icon(:unknown), do: "hero-question-mark-circle"
  defp status_icon(:accepted), do: "hero-check-circle"
  defp status_icon(:no_match), do: "hero-exclamation-triangle"
  defp status_icon(:ignore), do: "hero-minus-circle"
  defp status_icon(:failed_ingest), do: "hero-exclamation-circle"
  defp status_icon(:webhook_replay_requested), do: "hero-arrow-path"
  defp status_icon(:webhook_replay_succeeded), do: "hero-check-circle"
  defp status_icon(:webhook_replay_failed), do: "hero-x-circle"
  defp status_icon(:reconciled), do: "hero-exclamation-triangle"
  defp status_icon(:suppressed), do: "hero-minus-circle"

  # Fallback for unrecognized atoms and nil — render question mark per UI-SPEC Conflict 1
  defp status_icon(_status), do: "hero-question-mark-circle"

  defp status_label(:dispatched), do: "Dispatched"
  defp status_label(:queued), do: "Queued"
  defp status_label(:sent), do: "Sent"
  defp status_label(:delivered), do: "Delivered"
  defp status_label(:deferred), do: "Deferred"
  defp status_label(:bounced), do: "Bounced"
  defp status_label(:failed), do: "Failed"
  defp status_label(:rejected), do: "Rejected"
  defp status_label(:complained), do: "Complained"
  defp status_label(:unsubscribed), do: "Unsubscribed"
  defp status_label(:opened), do: "Opened"
  defp status_label(:clicked), do: "Clicked"
  defp status_label(:autoresponded), do: "Autoresponded"
  defp status_label(:unknown), do: "Unknown"
  defp status_label(:accepted), do: "Accepted"
  defp status_label(:no_match), do: "No match"
  defp status_label(:ignore), do: "Ignored"
  defp status_label(:failed_ingest), do: "Ingest failed"
  defp status_label(:webhook_replay_requested), do: "Replay requested"
  defp status_label(:webhook_replay_succeeded), do: "Replay succeeded"
  defp status_label(:webhook_replay_failed), do: "Replay failed"
  defp status_label(:reconciled), do: "Reconciled"
  defp status_label(:suppressed), do: "Suppressed"

  # Fallback for unrecognized atoms and nil — render "Unknown" per UI-SPEC Conflict 1
  defp status_label(_status), do: "Unknown"

  @doc """
  Renders a recipient (or sender) email for operator display.

  The ONE audited recipient-display definition in the admin package: every
  outbound and inbound surface calls this so rendering can never drift into a
  second copy. The authenticated, tenant-scoped operator is privileged to see the
  full address, so it is shown verbatim — presentation-layer masking was retired
  2026-07-18 (reverses the phase-33 UI posture D-33-17/18; the telemetry/log PII
  rules D-33-15 are UNCHANGED). Only `nil` is softened, to a neutral placeholder
  so an absent address renders as a fact rather than a crash:

      recipient_display("alice@example.com") #=> "alice@example.com"
      recipient_display(nil)                 #=> "Unavailable"
  """
  @spec recipient_display(String.t() | nil) :: String.t()
  def recipient_display(nil), do: "Unavailable"
  def recipient_display(recipient) when is_binary(recipient), do: recipient
end
