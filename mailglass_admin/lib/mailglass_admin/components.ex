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

  attr :name, :string, required: true
  attr :class, :any, default: nil

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

  attr :class, :any, default: nil

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

  attr :kind, :atom, values: [:info, :success, :warning, :error], default: :info
  attr :message, :string, required: true

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

  attr :variant, :atom, values: [:warning, :stub], required: true

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

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :rest, :global, default: %{}

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

  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :rest, :global, default: %{}

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
      class="flex min-h-11 items-center rounded-field px-sm text-body text-secondary opacity-100"
      {@rest}
    >
      <span class="truncate" title={@label}>{@label}</span>
    </span>
    """
  end

  def nav_pill(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-(--duration-fast)",
        nav_pill_class(@active)
      ]}
      {@rest}
    >
      <span class="truncate" title={@label}>{@label}</span>
    </.link>
    """
  end

  attr :tenant, :string, default: nil
  attr :rest, :global, default: %{}

  @doc """
  Renders the read-only tenant context chip.

  The chip intentionally does not expose switching, loading, or navigation
  behavior in Phase 110.
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
      <span :if={!@tenant}>No tenant selected</span>
    </span>
    """
  end

  attr :selected, :atom, values: [:system, :light, :dark], default: :system
  attr :name, :string, default: "theme"
  attr :disabled, :boolean, default: false
  attr :event, :string, default: nil
  attr :target, :any, default: nil
  attr :rest, :global, default: %{}

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
      class="inline-flex min-h-11 items-stretch gap-xs rounded-field border border-base-300 bg-base-200 p-xs text-body"
      disabled={@disabled}
      {@rest}
    >
      <legend class="sr-only">Theme</legend>
      <label
        :for={option <- theme_options()}
        class={[
          "mg-focus-ring flex min-h-11 min-w-11 cursor-pointer items-center gap-xs rounded-field px-sm transition-colors ease-out duration-(--duration-fast)",
          theme_option_class(@selected == option.theme, @disabled)
        ]}
      >
        <input
          type="radio"
          name={@name}
          value={option.value}
          checked={@selected == option.theme}
          disabled={@disabled}
          phx-click={@event}
          phx-target={@target}
          phx-value-theme={if @event, do: option.value}
          class="mg-focus-ring h-4 w-4"
        />
        <span class="whitespace-nowrap">{option.label}</span>
      </label>
    </fieldset>
    """
  end

  attr :id, :string, default: nil
  attr :label, :string, required: true
  attr :value, :any, default: nil
  attr :severity, :atom, values: [:neutral, :info, :success, :warning, :error], default: :neutral
  attr :severity_label, :string, default: nil
  attr :state, :atom, values: [:ready, :empty, :loading, :unavailable], default: :ready
  attr :empty_text, :string, default: "No data yet"
  attr :loading_text, :string, default: "Resolving"
  attr :unavailable_text, :string, default: "Unavailable"
  attr :rest, :global, default: %{}

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
      class="min-w-0 rounded-box border border-base-300 bg-base-200 p-md"
      aria-busy={if @state == :loading, do: "true"}
      {@rest}
    >
      <p class="truncate text-label font-bold uppercase text-secondary" title={@label}>{@label}</p>
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

  defp nav_link_class(true), do: "border-primary bg-base-100 font-bold text-base-content"

  defp nav_link_class(false),
    do: "border-transparent text-secondary hover:bg-base-100/60 hover:text-base-content"

  defp nav_pill_class(true), do: "bg-primary/10 font-bold text-base-content"
  defp nav_pill_class(false), do: "text-secondary hover:text-base-content"

  defp tenant_chip_title(nil), do: "Tenant currently in view"
  defp tenant_chip_title(tenant), do: "Tenant currently in view: " <> tenant

  defp theme_options do
    [
      %{theme: :system, value: "system", label: "System"},
      %{theme: :light, value: "light", label: "Light"},
      %{theme: :dark, value: "dark", label: "Dark"}
    ]
  end

  defp theme_option_class(_selected, true), do: "text-secondary opacity-100"

  defp theme_option_class(true, false),
    do: "border border-primary bg-base-100 font-bold text-base-content"

  defp theme_option_class(false, false),
    do: "border border-transparent text-secondary hover:bg-base-100 hover:text-base-content"

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

  attr :status, :atom,
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

  attr :size, :atom, values: [:sm, :md], default: :sm

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

  defp size_class(:sm), do: "badge-sm"
  defp size_class(:md), do: "badge-md"

  defp status_class(:dispatched), do: "badge-primary"
  defp status_class(:queued), do: "badge-primary"
  defp status_class(:sent), do: "badge-primary"
  defp status_class(:delivered), do: "badge-success"
  defp status_class(:deferred), do: "badge-warning"
  defp status_class(:bounced), do: "badge-error"
  defp status_class(:failed), do: "badge-error"
  defp status_class(:rejected), do: "badge-error"
  defp status_class(:complained), do: "badge-error"
  defp status_class(:unsubscribed), do: "badge-warning"
  defp status_class(:opened), do: "badge-success"
  defp status_class(:clicked), do: "badge-success"
  defp status_class(:autoresponded), do: "badge-outline"
  defp status_class(:unknown), do: "badge-outline"
  defp status_class(:accepted), do: "badge-success"
  defp status_class(:no_match), do: "badge-warning"
  defp status_class(:ignore), do: "badge-outline"
  defp status_class(:failed_ingest), do: "badge-error"
  defp status_class(:webhook_replay_requested), do: "badge-outline"
  defp status_class(:webhook_replay_succeeded), do: "badge-success"
  defp status_class(:webhook_replay_failed), do: "badge-error"
  defp status_class(:reconciled), do: "badge-warning"

  # Fallback for phantom atoms (e.g. :suppressed) and nil — render neutral outline per UI-SPEC Conflict 1
  defp status_class(_status), do: "badge-outline"

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

  # Fallback for phantom atoms (e.g. :suppressed) and nil — render question mark per UI-SPEC Conflict 1
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

  # Fallback for phantom atoms (e.g. :suppressed) and nil — render "Unknown" per UI-SPEC Conflict 1
  defp status_label(_status), do: "Unknown"

  @doc """
  Masks a recipient email for operator display (PII minimization, the design contract).

  The ONE audited masking definition in the admin package: both
  `MailglassAdmin.Operator.DeliveriesList` (outbound) and the this milestone phase inbound
  components call this so there is never a second, drifting copy. Keeps the first
  grapheme of each segment and stars the rest, preserving the email shape:

      mask_recipient("alice@example.com") #=> "a****@e******.com"
      mask_recipient(nil)                 #=> "Unavailable"
  """
  @doc since: "0.2.0"
  @spec mask_recipient(String.t() | nil) :: String.t()
  def mask_recipient(nil), do: "Unavailable"

  def mask_recipient(recipient) when is_binary(recipient) do
    case String.split(recipient, "@", parts: 2) do
      [local, domain] -> mask_email(local, domain)
      _ -> mask_value(recipient)
    end
  end

  @doc """
  Masks the `local`/`domain` halves of an already-split email address. Public so
  the inbound components can mask address-shaped values that are pre-split.
  """
  @doc since: "0.2.0"
  @spec mask_email(String.t(), String.t()) :: String.t()
  def mask_email(local, domain) do
    case String.split(domain, ".", parts: 2) do
      [label, suffix] -> mask_value(local) <> "@" <> mask_value(label) <> "." <> suffix
      _ -> mask_value(local) <> "@" <> mask_value(domain)
    end
  end

  @doc """
  Masks a single value: keeps the first grapheme, stars the rest. Public so other
  admin surfaces reuse the one masking primitive rather than reinventing it.
  """
  @doc since: "0.2.0"
  @spec mask_value(String.t()) :: String.t()
  def mask_value(value) do
    value
    |> String.graphemes()
    |> case do
      [] -> ""
      [first | rest] -> first <> String.duplicate("*", length(rest))
    end
  end
end
