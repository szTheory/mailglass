defmodule MailglassAdmin.Components do
  @moduledoc """
  Brand-book-aligned shared UI atoms used throughout mailglass_admin.

  ## Components

    * `icon/1` — Heroicon via the vendored `heroicons.js` Tailwind plugin
      (Phoenix 1.8 installer convention). Classes matching the pattern
      `hero-<name>` are resolved at build time into inline SVG.
    * `logo/1` — brand v2 mailglass typemark rendered inline so it follows the
      active admin theme; the stable `logo.svg` route remains served from
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

  alias Phoenix.LiveView.JS

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
  Renders the brand v2 mailglass typemark inline.

  The mark is the two-pane `m` followed by the lettering, drawn as four outlined
  paths copied byte for byte from the pinned lockup in `brandbook/v2`. The
  lettering takes `currentColor`, so it inherits the page text role. The two
  panes carry `.mg-logo-glass` and the overlap carries `.mg-logo-overlap`; those
  rules read the `--mg-logo-glass` and `--mg-logo-overlap` roles from the active
  theme block on the page root. The logo therefore follows the theme the admin
  chose, including an explicit dark theme on a light OS, and never depends on
  the operating-system scheme.

  Do not render the logo as an `<img>`: the brand book forbids inverting the
  light file on a dark ground. The public `logo.svg` route is served by
  `MailglassAdmin.Controllers.Assets` at `<mount>/logo.svg` and is the pinned
  light file, for embeds that cannot read the theme tokens.
  """
  @doc since: "0.1.0"
  def logo(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="34.0 -840.0 5323.8 1092.0"
      width="1000"
      height="205"
      role="img"
      aria-label="mailglass"
      class={@class}
    >
      <path
        fill="currentColor"
        d="M2787.7 252Q2655.7 252 2573.2 198.2Q2490.8 144.5 2475.6 49H2633.1Q2658 132.1 2783.4 132.1Q2866.5 132.1 2910.6 93.7Q2954.8 55.2 2954.8 -16.3V-101.8H2949.8Q2923.7 -52.1 2874.9 -26Q2826.1 0 2758.4 0Q2673.6 0 2610.9 -37.5Q2548.2 -75 2513.9 -143.8Q2479.6 -212.6 2479.6 -306Q2479.6 -446.4 2556.5 -529.2Q2633.4 -612 2767.7 -612Q2842.2 -612 2895.3 -583.9Q2948.4 -555.7 2979.7 -503.9H3021.7V-600H3174.6V-451.1H3100.1V-13.6Q3100.1 112.9 3018.9 182.5Q2937.6 252 2787.7 252ZM3742.8 11Q3637.9 11 3578.4 -40.1Q3518.9 -91.2 3518.9 -174.9Q3518.9 -262.7 3579.7 -310.6Q3640.4 -358.6 3754.2 -358.6H3936.6V-382.9Q3936.6 -492.9 3808.8 -492.9Q3700.5 -492.9 3677.8 -415.3H3529.2Q3547.5 -511.1 3619.7 -561.6Q3692 -612 3809.4 -612Q3940.6 -612 4009.8 -552.3Q4079.1 -492.6 4079.1 -378.9V-148.9H4149.6V0H3996.7V-96.1H3954.7Q3923.7 -45.2 3871.1 -17.1Q3818.6 11 3742.8 11ZM1430.8 11Q1325.9 11 1266.4 -40.1Q1206.9 -91.2 1206.9 -174.9Q1206.9 -262.7 1267.7 -310.6Q1328.4 -358.6 1442.2 -358.6H1624.6V-382.9Q1624.6 -492.9 1496.8 -492.9Q1388.5 -492.9 1365.8 -415.3H1217.2Q1235.5 -511.1 1307.7 -561.6Q1380 -612 1497.4 -612Q1628.6 -612 1697.8 -552.3Q1767.1 -492.6 1767.1 -378.9V-148.9H1837.6V0H1684.7V-96.1H1642.7Q1611.7 -45.2 1559.1 -17.1Q1506.6 11 1430.8 11ZM4496.3 12Q4366.3 12 4291.4 -42.5Q4216.4 -96.9 4210 -194.7H4354.7Q4362.3 -147.7 4398.1 -125.2Q4433.8 -102.7 4502.3 -102.7Q4616.8 -102.7 4616.8 -169.5Q4616.8 -196.7 4599.4 -212.1Q4582.1 -227.4 4541.3 -235L4408.5 -260.2Q4232.7 -293.9 4232.7 -426Q4232.7 -511.3 4299.8 -561.6Q4366.9 -612 4484.5 -612Q4603.3 -612 4672.8 -560.3Q4742.2 -508.7 4749.8 -415.3H4605.8Q4595.4 -459.8 4564.7 -480.4Q4533.9 -501 4476.8 -501Q4426.3 -501 4399.1 -485.1Q4372 -469.3 4372 -438.3Q4372 -415.3 4389.1 -401Q4406.2 -386.7 4442.7 -379.8L4577.6 -353.9Q4669.7 -336.1 4712.7 -294.3Q4755.8 -252.4 4755.8 -181.4Q4755.8 -90.1 4688.8 -39.1Q4621.8 12 4496.3 12ZM5098.3 12Q4968.3 12 4893.4 -42.5Q4818.4 -96.9 4812 -194.7H4956.7Q4964.3 -147.7 5000.1 -125.2Q5035.8 -102.7 5104.3 -102.7Q5218.8 -102.7 5218.8 -169.5Q5218.8 -196.7 5201.4 -212.1Q5184.1 -227.4 5143.3 -235L5010.5 -260.2Q4834.7 -293.9 4834.7 -426Q4834.7 -511.3 4901.8 -561.6Q4968.9 -612 5086.5 -612Q5205.3 -612 5274.8 -560.3Q5344.2 -508.7 5351.8 -415.3H5207.8Q5197.4 -459.8 5166.7 -480.4Q5135.9 -501 5078.8 -501Q5028.3 -501 5001.1 -485.1Q4974 -469.3 4974 -438.3Q4974 -415.3 4991.1 -401Q5008.2 -386.7 5044.7 -379.8L5179.6 -353.9Q5271.7 -336.1 5314.7 -294.3Q5357.8 -252.4 5357.8 -181.4Q5357.8 -90.1 5290.8 -39.1Q5223.8 12 5098.3 12ZM2226.7 0V-840H2375.7V0ZM3271.7 0V-840H3420.7V0ZM2795.1 -129.7Q2867.1 -129.7 2909.1 -170.1Q2951.1 -210.6 2951.1 -279.6V-333.7Q2951.1 -402.1 2908.8 -442.2Q2866.4 -482.3 2795.1 -482.3Q2716.4 -482.3 2672.5 -435.9Q2628.6 -389.4 2628.6 -305.4Q2628.6 -221.4 2672.5 -175.5Q2716.4 -129.7 2795.1 -129.7ZM1940.7 0V-600H2089.7V0ZM3764.6 -103.7Q3813.7 -103.7 3852.6 -122.2Q3891.6 -140.7 3914.1 -172.3Q3936.6 -203.9 3936.6 -242.6V-257.2H3761.8Q3660.7 -257.2 3660.7 -181.9Q3660.7 -145.2 3688.4 -124.4Q3716.1 -103.7 3764.6 -103.7ZM1452.6 -103.7Q1501.7 -103.7 1540.6 -122.2Q1579.6 -140.7 1602.1 -172.3Q1624.6 -203.9 1624.6 -242.6V-257.2H1449.8Q1348.7 -257.2 1348.7 -181.9Q1348.7 -145.2 1376.4 -124.4Q1404.1 -103.7 1452.6 -103.7ZM2015.3 -666.2Q1980.4 -666.2 1955.9 -690.6Q1931.3 -715 1931.3 -749.9Q1931.3 -784.8 1955.8 -809.3Q1980.2 -833.8 2015.1 -833.8Q2049.9 -833.8 2074.5 -809.4Q2099 -785 2099 -750.1Q2099 -715.2 2074.6 -690.7Q2050.2 -666.2 2015.3 -666.2Z"
      />
      <path
        class="mg-logo-glass"
        d="M337 -462C251.9 -462 183 -393.1 183 -308V0H34V-308C34 -475.3 169.7 -611 337 -611C428.2 -611 510 -570.7 565.5 -507C519.1 -453.8 491 -384.2 491 -308C491 -393.1 422.1 -462 337 -462Z"
      />
      <path
        class="mg-logo-glass"
        d="M1097 -308V0H948V-308C948 -393.1 879.1 -462 794 -462C708.9 -462 640 -393.1 640 -308C640 -384.2 611.9 -453.8 565.5 -507C621 -570.7 702.8 -611 794 -611C961.3 -611 1097 -475.3 1097 -308Z"
      />
      <path
        class="mg-logo-overlap"
        d="M640 -308V0H491V-308C491 -384.2 519.1 -453.8 565.5 -507C611.9 -453.8 640 -384.2 640 -308Z"
      />
    </svg>
    """
  end

  # Delivery-status pane marks (Phase 182, D-10): five portrait panes, one per delivery
  # class, drawn from the brand book's `svg.stm` fragments. The geometry below is copied
  # literally from the pinned status-marks data in the repository's brand directory, the
  # same way the logo paths above are copied byte for byte: the Hex package ships `lib`,
  # `priv/static` and `docs` only, so lib code must not read repo files outside the
  # package. The pinned data stays the truth, and phase182_status_marks_test.exs fails
  # when this data and the pinned data differ.
  #
  # Colours are the book's `--mk-<role>` roles, bound to admin tokens by
  # `@status_mark_roles`, and are painted with attributes, so the marks add no CSS class
  # and the compiled bundle does not change.
  @status_mark_shapes %{
    sent: [
      %{
        "fill" => "none",
        "height" => 108,
        "stroke" => "ink",
        "stroke_width" => 12,
        "tag" => "rect",
        "width" => 88,
        "x" => 6,
        "y" => 6
      },
      %{"d" => "M6 60H94V114H6Z", "fill" => "ink", "tag" => "path"}
    ],
    delivered: [
      %{"fill" => "ok", "height" => 120, "tag" => "rect", "width" => 100},
      %{
        "d" => "M24 62L43 82L77 38",
        "fill" => "none",
        "stroke" => "surf",
        "stroke_width" => 13,
        "tag" => "path"
      }
    ],
    delayed: [
      %{
        "fill" => "none",
        "height" => 108,
        "stroke" => "warn",
        "stroke_width" => 12,
        "tag" => "rect",
        "width" => 88,
        "x" => 6,
        "y" => 6
      },
      %{
        "d" => "M50 24V62L72 78",
        "fill" => "none",
        "stroke" => "warn",
        "stroke_width" => 12,
        "tag" => "path"
      }
    ],
    failed: [
      %{"fill" => "bad", "height" => 120, "tag" => "rect", "width" => 100},
      %{
        "d" => "M60 0L40 48L62 68L44 120",
        "fill" => "none",
        "stroke" => "surf",
        "stroke_width" => 12,
        "tag" => "path"
      }
    ],
    not_sent: [
      %{
        "fill" => "none",
        "height" => 108,
        "stroke" => "mute",
        "stroke_width" => 12,
        "tag" => "rect",
        "width" => 88,
        "x" => 6,
        "y" => 6
      },
      %{"d" => "M0 120L100 0", "stroke" => "mute", "stroke_width" => 12, "tag" => "path"}
    ]
  }

  @status_mark_roles %{
    "bad" => "error-text",
    "ink" => "text",
    "mute" => "text-muted",
    "ok" => "success-text",
    "surf" => "surface",
    "warn" => "warning-text"
  }

  # Row marks are 20 px tall and detail marks 44 px; the panes are 100:120, so the widths
  # are 17 and 37. The book never draws a mark under 14 px.
  @status_mark_sizes %{row: {17, 20}, detail: {37, 44}}

  @doc false
  def status_mark_shapes, do: @status_mark_shapes

  @doc false
  def status_mark_roles, do: @status_mark_roles

  attr(:class, :atom, values: [:sent, :delivered, :delayed, :failed, :not_sent], required: true)
  attr(:size, :atom, values: [:row, :detail], default: :row)

  @doc """
  Renders one delivery-status pane mark as an inline SVG.

  The mark is decoration. The status word beside it is the accessible name, so the
  SVG is `aria-hidden` and carries no `aria-label` and no `title`: status meaning
  never lives in a mark's colour or in an attribute alone. The five marks differ in
  shape (half-filled frame, filled with a check, frame with a clock hand, filled with
  a crack, struck-through frame), so they stay distinct in greyscale. Use it through
  the status badge, beside its word.
  """
  @doc since: "2.8.0"
  def status_mark(assigns) do
    {width, height} = Map.fetch!(@status_mark_sizes, assigns.size)

    assigns =
      assigns
      |> assign(:width, width)
      |> assign(:height, height)
      |> assign(:shapes, Map.fetch!(@status_mark_shapes, assigns.class))

    ~H"""
    <svg
      width={@width}
      height={@height}
      viewBox="0 0 100 120"
      aria-hidden="true"
      focusable="false"
    >
      <%= for shape <- @shapes do %>
        <rect
          :if={shape["tag"] == "rect"}
          x={shape["x"]}
          y={shape["y"]}
          width={shape["width"]}
          height={shape["height"]}
          fill={status_mark_paint(shape["fill"])}
          stroke={status_mark_paint(shape["stroke"])}
          stroke-width={shape["stroke_width"]}
        />
        <path
          :if={shape["tag"] == "path"}
          d={shape["d"]}
          fill={status_mark_paint(shape["fill"])}
          stroke={status_mark_paint(shape["stroke"])}
          stroke-width={shape["stroke_width"]}
        />
      <% end %>
    </svg>
    """
  end

  defp status_mark_paint(nil), do: nil
  defp status_mark_paint("none"), do: "none"

  defp status_mark_paint(role),
    do: "var(--mg-color-#{Map.fetch!(@status_mark_roles, role)})"

  attr(:kind, :atom, values: [:info, :success, :warning, :error], default: :info)
  attr(:flash_key, :atom, default: nil)
  attr(:message, :string, required: true)
  attr(:placement, :atom, values: [:toast, :inline], default: :toast)

  @doc """
  Renders a brand-voice flash message in a daisyUI toast wrapper.

  Used for LiveReload notifications ("Reloaded: {file}") and other
  transient signals. Includes `role="status"` + `aria-live="polite"`
  per the 05-UI-SPEC Accessibility Interactions contract.
  """
  @doc since: "0.1.0"
  def flash(assigns) do
    assigns =
      assign(assigns, :live_role, if(assigns.kind == :error, do: "alert", else: "status"))

    ~H"""
    <div
      id={"flash-#{@kind}"}
      class={
        if @placement == :toast,
          do: "toast toast-top toast-end mg-toast mg-layer-toast"
      }
      role={@live_role}
      aria-live={if @kind == :error, do: "assertive", else: "polite"}
      aria-atomic="true"
    >
      <div class={["motion-reveal alert flex items-start gap-sm text-body", alert_class(@kind)]}>
        <.icon name="hero-arrow-path" class="w-4 h-4" />
        <span class="min-w-0 flex-1 break-words [overflow-wrap:anywhere]">{@message}</span>
        <button
          type="button"
          phx-click="lv:clear-flash"
          phx-value-key={Atom.to_string(@flash_key || @kind)}
          aria-label={"Dismiss #{flash_kind_label(@kind)} message"}
          class="mg-focus-ring flex min-h-11 min-w-11 shrink-0 items-center justify-center rounded-field"
        >
          <.icon name="hero-x-mark" class="h-4 w-4" />
        </button>
      </div>
    </div>
    """
  end

  defp flash_kind_label(:info), do: "information"
  defp flash_kind_label(:success), do: "success"
  defp flash_kind_label(:warning), do: "warning"
  defp flash_kind_label(:error), do: "error"

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
    <span class="badge badge-warning badge-sm gap-1 text-label">
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

  Keep labels short (one or two words). The label truncates as a layout safety
  net only; there is no tooltip and no long-label state to maintain. A label
  long enough to truncate should be shortened rather than accommodated.
  """
  @doc since: "1.8.0"
  def nav_link(%{disabled: true} = assigns) do
    ~H"""
    <span
      role="link"
      aria-disabled="true"
      tabindex="-1"
      class={[
        "flex min-h-11 items-center gap-sm rounded-field px-sm text-body",
        "text-secondary opacity-100"
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="mg-nav-label truncate">{@label}</span>
    </span>
    """
  end

  def nav_link(%{navigate: false} = assigns) do
    ~H"""
    <.link
      href={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field px-sm text-body transition-colors ease-out",
        "duration-(--duration-fast)",
        nav_link_class(@active)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="mg-nav-label truncate">{@label}</span>
    </.link>
    """
  end

  def nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field px-sm text-body transition-colors ease-out",
        "duration-(--duration-fast)",
        nav_link_class(@active)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-5 w-5 shrink-0" />
      <span class="mg-nav-label truncate">{@label}</span>
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
      class="flex min-h-11 items-center rounded-field px-sm text-body text-secondary opacity-100"
      {@rest}
    >
      <span class="mg-nav-label truncate" title={@label}>{@label}</span>
    </span>
    """
  end

  def nav_pill(%{navigate: false} = assigns) do
    ~H"""
    <.link
      href={@href}
      aria-current={@active && "page"}
      class={[
        "mg-focus-ring flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-(--duration-fast)",
        nav_pill_class(@active)
      ]}
      {@rest}
    >
      <span class="mg-nav-label truncate" title={@label}>{@label}</span>
    </.link>
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
      <span class="mg-nav-label truncate" title={@label}>{@label}</span>
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
      aria-label="Appearance"
      class="flex min-h-11 flex-wrap items-center gap-xs rounded-box border border-base-300 bg-base-200 p-xs text-label"
      disabled={@disabled}
      {@rest}
    >
      <label
        :for={option <- theme_options()}
        title={option.label}
        class={[
          "mg-focus-ring-within mg-state-layer relative flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-xs rounded-field px-sm",
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
        <.icon name={option.icon} class="pointer-events-none h-5 w-5 shrink-0" />
        <span class="pointer-events-none">{option.label}</span>
      </label>
    </fieldset>
    """
  end

  attr(:id, :string, default: nil)
  attr(:label, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:severity, :atom, values: [:neutral, :info, :success, :warning, :error], default: :neutral)
  attr(:severity_label, :string, default: nil)
  attr(:show_severity, :boolean, default: true)
  attr(:state, :atom, values: [:ready, :empty, :loading, :unavailable], default: :ready)
  attr(:empty_text, :string, default: "No data yet")
  attr(:loading_text, :string, default: "Resolving")
  attr(:unavailable_text, :string, default: "Unavailable")
  attr(:hint, :string, default: nil)
  attr(:compact, :boolean, default: false)
  slot(:label_help)
  attr(:rest, :global, default: %{})

  @doc """
  Renders a canonical stat card with wrapping label/value and severity.

  Severity is a closed set. Compact summaries retain the severity description
  for assistive technology while presenting the counts without card chrome.
  """
  @doc since: "1.8.0"
  def stat_card(assigns) do
    assigns =
      assigns
      |> assign(:display_value, stat_display_value(assigns))
      |> assign(
        :hint_id,
        (assigns.id || Map.get(assigns.rest, :"data-testid") ||
           "stat-#{:erlang.phash2({assigns.label, assigns.hint})}") <> "-help"
      )
      |> assign(
        :display_severity_label,
        assigns.severity_label || stat_severity_label(assigns.severity)
      )

    ~H"""
    <article
      id={@id}
      class={[
        if(@compact,
          do: "mg-stat-compact min-w-0",
          else: "min-w-0 rounded-box border border-base-300 bg-base-200 p-md"
        )
      ]}
      aria-busy={if @state == :loading, do: "true"}
      {@rest}
    >
      <div class="flex min-w-0 items-start justify-between gap-sm">
        <p class={[
          "flex min-w-0 flex-wrap items-center gap-xs text-label text-secondary",
          !@compact && "font-bold uppercase"
        ]}>
          <span class="min-w-0 break-words [overflow-wrap:anywhere]">{@label}</span>
          <span :if={@label_help != []} class="inline-flex shrink-0">
            {render_slot(@label_help)}
          </span>
          <span
            :if={present?(@hint)}
            class="inline-flex shrink-0"
          >
            <.field_help id={@hint_id} label={@label} text={@hint} />
          </span>
        </p>
      </div>
      <p class={[
        "mt-xs font-bold tabular-nums whitespace-normal text-base-content [overflow-wrap:anywhere]",
        if(@compact, do: "text-heading", else: "mono break-all text-display")
      ]}>
        {@display_value}
      </p>
      <p
        :if={@show_severity}
        class={[
          "mt-sm inline-flex items-center gap-xs text-label font-bold",
          @compact && "sr-only",
          stat_severity_class(@severity)
        ]}
      >
        <.icon name={stat_severity_icon(@severity)} class="h-4 w-4 shrink-0" />
        <span>{@display_severity_label}</span>
      </p>
    </article>
    """
  end

  @doc "A collection title and optional result count above its bordered table or mobile list."
  attr(:title, :string, default: nil)
  attr(:count, :integer, default: nil)
  attr(:count_label, :string, default: nil)
  attr(:count_testid, :string, default: nil)
  attr(:rest, :global)

  def collection_header(assigns) do
    ~H"""
    <div class="mb-sm flex min-w-0 flex-wrap items-baseline gap-x-sm gap-y-xs" {@rest}>
      <h2 :if={@title} class="text-body font-bold text-base-content">
        {@title}
        <span
          :if={not is_nil(@count)}
          data-testid={@count_testid}
          aria-label={@count_label}
          class="font-normal tabular-nums text-secondary"
        >
          ({@count})
        </span>
      </h2>
      <span
        :if={is_nil(@title) and not is_nil(@count)}
        data-testid={@count_testid}
        aria-label={@count_label}
        class="text-label tabular-nums text-secondary"
      >
        ({@count})
      </span>
    </div>
    """
  end

  @doc "Message identity shared by quick views and full detail, with contextual outcome help."
  attr(:subject, :string, default: nil)
  attr(:recipient, :string, default: nil)
  attr(:status, :atom, required: true)
  attr(:context, :atom, required: true)
  attr(:id, :string, required: true)

  attr(:delivery_row, :map,
    default: nil,
    doc: "an operator delivery row; with `context: :delivery` it draws the class badge"
  )

  attr(:heading_tag, :string, values: ["h2", "h3"], default: "h2")

  def message_identity(assigns) do
    ~H"""
    <div class="min-w-0 space-y-sm">
      <p :if={not is_nil(@subject)} class="text-label font-bold text-secondary">Subject</p>
      <div class="flex min-w-0 flex-wrap items-center gap-sm">
        <.dynamic_tag
          tag_name={@heading_tag}
          class="min-w-0 max-w-full text-heading font-bold text-base-content [overflow-wrap:anywhere]"
        >
          {if @subject == "", do: "(No subject)", else: @subject || @recipient || "Message"}
        </.dynamic_tag>
        <.delivery_badge
          :if={@context == :delivery and not is_nil(@delivery_row)}
          row={@delivery_row}
        />
        <.outcome_badge
          :if={@context != :delivery or is_nil(@delivery_row)}
          id={@id}
          status={@status}
          context={@context}
        />
      </div>
      <p :if={not is_nil(@subject)} class="text-body text-secondary [overflow-wrap:anywhere]">
        {recipient_label(@context)}
        <span class="text-base-content">{@recipient || recipient_missing(@context)}</span>
      </p>
      <p :if={is_nil(@subject)} class="text-label text-secondary">Subject not recorded</p>
    </div>
    """
  end

  # Inbound messages carry only the SMTP envelope recipient here; the header To list
  # lives on the full detail, so the line says "Delivered to" rather than "To".
  defp recipient_label(:inbound), do: "Delivered to"
  defp recipient_label(_context), do: "To"

  defp recipient_missing(:inbound), do: "Not recorded by provider"
  defp recipient_missing(_context), do: "Recipient not recorded"

  @doc "Technical identifiers remain available without dominating message inspection."
  attr(:id, :string, required: true)
  attr(:divider?, :boolean, default: true)
  attr(:collapsible, :boolean, default: true)
  slot(:inner_block, required: true)

  def technical_details(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={if @collapsible, do: "details", else: "div"}
      id={@id}
      class={["min-w-0", @divider? && "border-t border-base-300 pt-sm"]}
    >
      <summary
        :if={@collapsible}
        class="mg-focus-ring min-h-11 cursor-pointer content-center rounded-field text-label font-bold text-secondary"
      >
        Technical details
      </summary>
      <dl class={[
        "grid min-w-0 gap-md text-body [&>div]:min-w-0 [&_dd]:[overflow-wrap:anywhere]",
        @collapsible && "mt-sm sm:grid-cols-2"
      ]}>
        {render_slot(@inner_block)}
      </dl>
    </.dynamic_tag>
    """
  end

  attr(:id, :string, required: true)
  attr(:title_id, :string, required: true)
  attr(:description_id, :string, required: true)
  attr(:close_id, :string, required: true)
  attr(:close_event, :string, required: true)
  attr(:described_by, :string, default: nil)
  slot(:title, required: true)
  slot(:description, required: true)
  slot(:body, required: true)
  slot(:actions, required: true)

  @doc "Shared accessible presentation shell for domain-specific replay reviews."
  def replay_dialog(assigns) do
    ~H"""
    <div
      class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim mg-overscroll-contain fixed inset-0 flex items-center justify-center overflow-hidden p-md"
      phx-remove={
        JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0"})
      }
    >
      <div
        id={@id}
        data-testid={@id}
        role="dialog"
        aria-modal="true"
        aria-labelledby={@title_id}
        aria-describedby={Enum.join(Enum.reject([@description_id, @described_by], &is_nil/1), " ")}
        tabindex="-1"
        phx-hook="ModalFocusTrap"
        phx-mounted={JS.focus(to: "##{@close_id}")}
        phx-window-keydown={@close_event}
        phx-key="Escape"
        class="motion-overlay mg-layer-overlay-panel mg-inbound-replay-dialog relative my-md w-full shrink-0 overflow-y-auto rounded-box border border-base-300 bg-base-100 p-lg shadow-overlay"
        phx-remove={
          JS.hide(
            time: 150,
            transition: {"ease-out duration-150", "opacity-100 scale-100", "opacity-0 scale-[0.98]"}
          )
        }
      >
        <span tabindex="0" aria-hidden="true" data-focus-trap="start"></span>
        <div class="flex items-start justify-between gap-md">
          <div class="min-w-0 space-y-sm">
            <h2 id={@title_id} class="text-heading font-bold text-base-content">
              {render_slot(@title)}
            </h2>
            <p id={@description_id} class="text-body text-secondary">
              {render_slot(@description)}
            </p>
          </div>
          <button
            id={@close_id}
            type="button"
            phx-click={@close_event}
            aria-label="Close"
            class="mg-focus-ring btn btn-ghost min-h-11 min-w-11 shrink-0 px-md"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>

        {render_slot(@body)}
        {render_slot(@actions)}
        <span tabindex="0" aria-hidden="true" data-focus-trap="end"></span>
      </div>
    </div>
    """
  end

  @doc "Short module name with the exact identity available through contextual help."
  attr(:value, :string, required: true)
  attr(:id, :string, required: true)
  attr(:segments, :integer, default: 1)

  def module_identity(assigns) do
    assigns =
      assign(
        assigns,
        :short_name,
        assigns.value |> String.split(".") |> Enum.take(-assigns.segments) |> Enum.join(".")
      )

    ~H"""
    <.field_help
      id={@id}
      label={@short_name}
      text={@value}
      trigger_text={@short_name}
      trigger_class="text-base-content"
    />
    """
  end

  attr(:record, :map, required: true)
  attr(:id, :string, required: true)

  def mailbox_identity(assigns) do
    full_name = matched_mailbox_label(assigns.record)

    {label, explanation, matched?} =
      case full_name do
        "Unrouted" ->
          {full_name,
           "None of the routing rules matched this email, so it wasn't sent to a mailbox. Open the message to see which rules were checked.",
           false}

        "No execution recorded" ->
          {full_name, "No processing attempt is recorded for this message.", false}

        "Unavailable" ->
          {"Not recorded",
           if(Map.get(assigns.record, :outcome) == :failed,
             do:
               "Processing failed, but no mailbox name was saved for this attempt. Open the message to inspect the error.",
             else:
               "No mailbox name was saved for this processing attempt. Open the message to inspect its processing history."
           ), false}

        mailbox ->
          {mailbox |> String.split(".") |> List.last(), mailbox, true}
      end

    icon =
      case full_name do
        "Unrouted" -> "hero-minus-circle"
        "Unavailable" -> "hero-question-mark-circle"
        "No execution recorded" -> "hero-clock"
        _ -> nil
      end

    assigns =
      assign(assigns, label: label, explanation: explanation, matched?: matched?, icon: icon)

    ~H"""
    <.field_help
      id={@id}
      label={@label}
      text={@explanation}
      trigger_text={@label}
      trigger_icon={@icon}
      trigger_class={if @matched?, do: "text-base-content", else: "text-secondary"}
    />
    """
  end

  defp matched_mailbox_label(record) do
    case {Map.get(record, :outcome), Map.get(record, :mailbox)} do
      {:no_match, _mailbox} -> "Unrouted"
      {nil, _mailbox} -> "No execution recorded"
      {_outcome, mailbox} when is_binary(mailbox) and mailbox != "" -> mailbox
      {_outcome, _mailbox} -> "Unavailable"
    end
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
      <p class="max-w-prose break-words text-body text-secondary [overflow-wrap:anywhere]">{@body}</p>
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

  defp nav_link_class(true), do: "mg-nav-current font-bold text-base-content"

  defp nav_link_class(false),
    do: "text-secondary hover:bg-base-100/60 hover:text-base-content"

  defp nav_pill_class(true), do: "mg-nav-current font-bold text-base-content"
  defp nav_pill_class(false), do: "text-secondary hover:text-base-content"

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
  attr(:compact, :boolean, default: false)
  attr(:columns, :integer, default: 4, values: [3, 4])
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
      <legend class={
        if @compact, do: "sr-only", else: "text-label font-bold uppercase text-secondary"
      }>
        {@title}
      </legend>
      <div class="grid min-w-0 gap-md">
        <p :if={@description} class="max-w-prose text-pretty text-body text-secondary">
          {@description}
        </p>
        <div class={[
          "grid grid-cols-1 gap-md sm:grid-cols-2",
          if(@compact,
            do: if(@columns == 3, do: "xl:grid-cols-3", else: "xl:grid-cols-4"),
            else: "lg:grid-cols-3 xl:grid-cols-5"
          )
        ]}>
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
  attr(:help_display, :atom, values: [:inline, :tooltip], default: :inline)
  attr(:error, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:display_value, :string, default: nil)
  attr(:submit_readonly, :boolean, default: true)

  attr(:rest, :global,
    default: %{},
    include: ~w(autocomplete inputmode list max min pattern placeholder step)
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
      <div class="relative flex items-center gap-xs">
        <label for={@control_id} class="text-label font-bold text-base-content">{@label}</label>
        <.field_help
          :if={present?(@help) and @help_display == :tooltip}
          id={@help_id}
          label={@label}
          text={@help}
        />
      </div>

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

      <p :if={@help && @help_display == :inline} id={@help_id} class="text-label text-secondary">
        {@help}
      </p>

      <p
        :if={@error_text}
        id={@error_id}
        role="alert"
        class="flex items-start gap-xs text-label text-error"
      >
        <.icon name="hero-exclamation-circle" class="mt-xs h-4 w-4 shrink-0" />
        <span>
          <span class="font-bold">Action needed:</span> {@error_text}
        </span>
      </p>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:text, :string, required: true)

  attr(:trigger_text, :string, default: nil)
  attr(:trigger_class, :string, default: nil)
  attr(:trigger_icon, :string, default: nil)
  slot(:trigger_content)

  @doc "Optional field help, available on hover, keyboard focus, or tap."
  def field_help(assigns) do
    active_trigger = "##{assigns.id}-trigger:is(:hover,:focus,[aria-expanded=true])"
    assigns = assign(assigns, :active_trigger, active_trigger)

    ~H"""
    <span class="mg-field-help inline-flex min-w-0 max-w-full">
      <button
        id={@id <> "-trigger"}
        type="button"
        aria-label={if @trigger_text, do: @label, else: "Help for #{@label}"}
        aria-describedby={@id}
        aria-expanded="false"
        aria-controls={@id <> "-tooltip"}
        phx-click={
          JS.toggle_attribute({"aria-expanded", "true", "false"})
          |> JS.remove_attribute("data-dismissed")
        }
        phx-focus={JS.remove_attribute("data-dismissed")}
        phx-blur={JS.remove_attribute("data-dismissed")}
        phx-click-away={JS.set_attribute({"aria-expanded", "false"})}
        phx-window-keydown={
          JS.set_attribute({"data-dismissed", "true"}, to: @active_trigger)
          |> JS.set_attribute({"aria-expanded", "false"}, to: @active_trigger)
        }
        phx-key="Escape"
        class={[
          "mg-focus-ring inline-flex items-center rounded-field hover:text-base-content",
          if(@trigger_text,
            do: "min-h-11 min-w-0 max-w-full gap-xs text-left text-body",
            else: "h-6 w-6 shrink-0 justify-center text-secondary"
          ),
          @trigger_class
        ]}
      >
        <.icon :if={@trigger_icon} name={@trigger_icon} class="h-4 w-4 shrink-0" />
        <span
          :if={@trigger_text && @trigger_content == []}
          class="min-w-0 break-words [overflow-wrap:anywhere]"
        >
          {@trigger_text}
        </span>
        {render_slot(@trigger_content)}
        <.icon
          :if={!@trigger_text && @trigger_content == []}
          name="hero-information-circle"
          class="h-4 w-4"
        />
      </button>
      <span id={@id} class="sr-only">{@text}</span>
      <span
        id={@id <> "-tooltip"}
        role="tooltip"
        aria-hidden="true"
        class="mg-field-help-tooltip [overflow-wrap:anywhere]"
      >
        {@text}
      </span>
    </span>
    """
  end

  defp stat_display_value(%{state: :empty, empty_text: empty_text}), do: empty_text
  defp stat_display_value(%{state: :loading, loading_text: loading_text}), do: loading_text

  defp stat_display_value(%{state: :unavailable, unavailable_text: unavailable_text}),
    do: unavailable_text

  defp stat_display_value(%{value: nil, empty_text: empty_text}), do: empty_text
  defp stat_display_value(%{value: value}), do: to_string(value)

  defp stat_severity_icon(:neutral), do: "hero-minus-circle"
  defp stat_severity_icon(:info), do: "hero-information-circle"
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
  `nil` maps to `:missing_history`, which is a display-only state. All other atoms
  pass through unchanged.
  """
  @doc since: "1.5.0"
  @spec normalize_inbound_outcome(atom() | nil) :: atom() | nil
  def normalize_inbound_outcome(:accept), do: :accepted
  def normalize_inbound_outcome(:reject), do: :rejected
  def normalize_inbound_outcome(:bounce), do: :bounced
  def normalize_inbound_outcome(nil), do: :missing_history
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
      :no_change,
      :missing_history,
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

  attr(:context, :atom,
    values: [:delivery, :inbound, nil],
    default: nil,
    doc:
      "`:delivery` shows the pane mark for the four atoms whose label is a class word; " <>
        "`:inbound` and nil never do"
  )

  attr(:delivery_class, :atom,
    values: [nil, :sent, :delivered, :delayed, :failed, :not_sent],
    default: nil,
    doc: "a delivery class computed by the caller; renders the pane mark and `word`"
  )

  attr(:word, :string, default: nil, doc: "the class word shown beside the mark")

  @doc """
  Unified delivery, inbound, and timeline status badge. Renders an outline Heroicon
  (decorative, aria-hidden) and a text label inside a daisyUI badge container.

  The base badge class is always emitted by this component — call sites must NOT
  prepend 'badge' or 'badge badge-sm'. Use size: :sm (default) for list rows;
  size: :md for detail headers.

  This is the only place a delivery-status pane mark is drawn beside a word. With
  `delivery_class` set, or with `context: :delivery` and one of `:sent`, `:queued`,
  `:delivered`, `:failed` (the atoms whose label is a class word), the badge shows the
  pane mark and the word, wrapped in `data-mg-status`. Every other atom, and every
  inbound or context-free badge, keeps its Heroicon and word. The mark is decoration:
  the word is the accessible name.
  """
  @doc since: "1.5.0"
  def status_badge(assigns) do
    assigns = assign(assigns, :mark, mark_branch(assigns))

    ~H"""
    <span
      :if={@mark}
      data-mg-status={@mark.class}
      class="badge badge-outline badge-md text-label whitespace-nowrap"
      style={"color: var(--mg-color-#{@mark.role})"}
    >
      <.status_mark class={@mark.class} size={:row} />{@mark.word}
    </span>
    <span
      :if={!@mark}
      data-mg-context={@context == :inbound && "inbound"}
      class={["badge text-label whitespace-nowrap", size_class(@size), status_class(@status)]}
    >
      <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>{status_label(@status)}
    </span>
    """
  end

  # The atoms whose Copy label is a class word. Only with an explicit :delivery context:
  # an inbound :failed is a mailbox outcome and keeps its Heroicon.
  @mark_atoms [:sent, :queued, :delivered, :failed]

  # Word colour per class, from the brand roles. The mark paints with the same roles, so
  # a word keeps the book 4.5:1 pair on the surface.
  @status_word_roles %{
    sent: "text",
    delivered: "success-text",
    delayed: "warning-text",
    failed: "error-text",
    not_sent: "text-muted"
  }

  defp mark_branch(%{delivery_class: class, word: word}) when not is_nil(class) do
    %{class: class, word: word, role: Map.fetch!(@status_word_roles, class)}
  end

  defp mark_branch(%{context: :delivery, status: status}) when status in @mark_atoms do
    class = MailglassAdmin.StatusMap.classify(status)
    %{class: class, word: status_label(status), role: Map.fetch!(@status_word_roles, class)}
  end

  defp mark_branch(_assigns), do: nil

  attr(:row, :map, required: true, doc: "one operator delivery row from the list or get_delivery")
  attr(:size, :atom, values: [:row, :detail], default: :row)

  @doc """
  The status badge for one operator delivery row: the pane mark and the class word.

  A thin wrapper: it picks the class and the word from `MailglassAdmin.Copy` and calls
  `status_badge/1`, which draws the mark. A row without the `:bounced_at` key comes from
  a core that predates the lifecycle fields, so it gets the Unknown badge and never a
  confident class word.
  """
  @doc since: "2.8.0"
  def delivery_badge(assigns) do
    ~H"""
    <%= if Map.has_key?(@row, :bounced_at) do %>
      <.status_badge
        status={class_status(MailglassAdmin.StatusMap.delivery_class(@row))}
        delivery_class={MailglassAdmin.StatusMap.delivery_class(@row)}
        word={MailglassAdmin.Copy.delivery_class_word(@row)}
        context={:delivery}
        size={badge_size(@size)}
      />
    <% else %>
      <.status_badge status={:unknown} size={badge_size(@size)} />
    <% end %>
    """
  end

  # The status atom a class stands for. status_badge reads it only for its required
  # attribute: with a delivery class set, the class and word decide the render.
  defp class_status(:sent), do: :sent
  defp class_status(:delivered), do: :delivered
  defp class_status(:delayed), do: :deferred
  defp class_status(:failed), do: :failed
  defp class_status(:not_sent), do: :suppressed

  defp badge_size(:row), do: :sm
  defp badge_size(:detail), do: :md

  @doc """
  True when the row's latest recorded event has a word of its own, one that is not the
  class word already shown by the badge. A row that predates the lifecycle fields has
  no class word, so its latest event is always worth showing.
  """
  @doc since: "2.8.0"
  def latest_event_differs?(row) do
    case Map.get(row, :last_event_type) do
      nil ->
        false

      event ->
        not Map.has_key?(row, :bounced_at) or
          status_label(event) != MailglassAdmin.Copy.delivery_class_word(row)
    end
  end

  attr(:verdict, :map,
    required: true,
    doc: "the map from `MailglassAdmin.Copy.delivery_verdict/2`"
  )

  attr(:form, :atom, values: [:full, :line], default: :full)
  attr(:id, :string, required: true)

  @doc """
  Renders one delivery verdict. The verdict is computed once, in `MailglassAdmin.Copy`;
  this component only draws it, so a row, the Quick view and Full detail cannot disagree.

  The full form leads with the pane mark and the class word, then the sentence, the
  recorded cause when there is one, the rule line, the notes and the next step. The
  line form (Quick view) is the mark, the word, the sentence and the rule line: it has
  no event history, so it never shows a cause or a next step. A verdict with no class
  shows only its sentence.
  """
  @doc since: "2.8.0"
  def delivery_verdict(%{verdict: %{class: :undetermined}} = assigns) do
    ~H"""
    <section id={@id} data-testid="delivery-verdict" data-verdict-class="undetermined">
      <p class="text-body text-secondary">
        <.verdict_segment :for={segment <- @verdict.sentence} segment={segment} />
      </p>
    </section>
    """
  end

  def delivery_verdict(%{form: :line} = assigns) do
    ~H"""
    <section
      id={@id}
      data-testid="delivery-verdict-line"
      data-verdict-class={@verdict.class}
      class="min-w-0 space-y-xs"
    >
      <p class="flex min-w-0 items-center gap-sm text-body font-bold text-base-content">
        <.status_mark class={@verdict.class} size={:row} /><span>{@verdict.word}</span>
      </p>
      <p class="text-body text-base-content [overflow-wrap:anywhere]">
        <.verdict_segment :for={segment <- @verdict.sentence} segment={segment} />
      </p>
      <p :if={@verdict.rule} class="text-label text-secondary [overflow-wrap:anywhere]">
        {@verdict.rule}
      </p>
    </section>
    """
  end

  def delivery_verdict(assigns) do
    ~H"""
    <section
      id={@id}
      data-testid="delivery-verdict"
      data-verdict-class={@verdict.class}
      aria-labelledby={@id <> "-word"}
      class="min-w-0 space-y-sm"
    >
      <div class="flex min-w-0 items-center gap-sm">
        <.status_mark class={@verdict.class} size={:detail} />
        <h3 id={@id <> "-word"} class="text-heading font-bold text-base-content">
          {@verdict.word}
        </h3>
      </div>
      <p class="text-body text-base-content [overflow-wrap:anywhere]">
        <.verdict_segment :for={segment <- @verdict.sentence} segment={segment} />
      </p>
      <p
        :if={@verdict.cause}
        data-testid="delivery-verdict-cause"
        class="text-body text-base-content [overflow-wrap:anywhere]"
      >
        {@verdict.cause}
      </p>
      <p :if={@verdict.rule} class="text-body font-bold text-base-content [overflow-wrap:anywhere]">
        {@verdict.rule}
      </p>
      <p :for={note <- @verdict.notes} class="text-body text-secondary [overflow-wrap:anywhere]">
        {note}
      </p>
      <div :if={@verdict.next_step} class="min-w-0 space-y-xs">
        <h4 class="text-label font-bold text-secondary">Next step</h4>
        <p class="text-body text-base-content [overflow-wrap:anywhere]">{@verdict.next_step}</p>
        <a
          :if={@verdict.next_link}
          href={@verdict.next_link.href}
          class="mg-focus-ring inline-flex min-h-11 items-center text-body font-bold text-primary underline"
        >
          {@verdict.next_link.label}
        </a>
      </div>
    </section>
    """
  end

  # A sentence is plain text and zoned timestamps, so every time on a verdict goes
  # through the same timestamp component as the rest of the screen.
  attr(:segment, :any, required: true)

  defp verdict_segment(%{segment: {:time, at}} = assigns) do
    assigns = assign(assigns, :at, at)

    ~H"""
    <.timestamp at={@at} />
    """
  end

  defp verdict_segment(assigns) do
    ~H"""
    {@segment}
    """
  end

  attr(:id, :string, required: true)
  attr(:status, :atom, required: true)
  attr(:context, :atom, values: [:delivery, :inbound], required: true)

  def outcome_badge(assigns) do
    ~H"""
    <.field_help
      id={@id}
      label={status_label(@status)}
      trigger_text={status_label(@status)}
      text={outcome_help(@context, @status)}
    >
      <:trigger_content>
        <.status_badge status={@status} size={:sm} context={@context} />
      </:trigger_content>
    </.field_help>
    """
  end

  @doc false
  def outcome_description(context, status), do: outcome_help(context, status)

  defp outcome_help(:inbound, :accepted), do: "A mailbox processed and accepted this message."

  defp outcome_help(:inbound, :no_match),
    do: "No routing rule matched, so this message was not sent to a mailbox."

  defp outcome_help(:inbound, :ignore),
    do: "The mailbox deliberately skipped this message without rejecting it."

  defp outcome_help(:inbound, :no_change),
    do: "The mailbox processed this message without changing its state."

  defp outcome_help(:inbound, :rejected),
    do: "The mailbox rejected this message. Open it to inspect the recorded reason."

  defp outcome_help(:inbound, :bounced),
    do:
      "The mailbox returned a bounce result for this message. Open it to inspect the recorded reason."

  defp outcome_help(:inbound, :failed),
    do: "Mailbox processing failed. Open the message to inspect the error."

  defp outcome_help(:inbound, :missing_history),
    do: "No mailbox processing attempt is recorded for this message."

  defp outcome_help(:delivery, :queued), do: "This message is waiting to be sent to the provider."

  defp outcome_help(:delivery, :dispatched),
    do:
      "This message was handed to the provider. Delivery to the recipient has not been confirmed."

  defp outcome_help(:delivery, :delivered),
    do:
      "The provider reported that the recipient's mail server accepted this message. This does not confirm it reached the inbox or was read."

  defp outcome_help(:delivery, :opened),
    do:
      "The provider recorded an open. Image loading, privacy features, or automated activity can trigger this signal."

  defp outcome_help(:delivery, :clicked),
    do:
      "The provider recorded a link click. Security scanners or other automated activity can trigger this signal."

  defp outcome_help(:delivery, :failed),
    do:
      "Sending failed before a successful handoff to the provider. Open the delivery to inspect the error."

  defp outcome_help(:delivery, :bounced),
    do:
      "The provider reported that this message could not be delivered. Open the delivery to inspect the bounce reason."

  defp outcome_help(:delivery, :rejected),
    do: "The provider rejected this message. Open the delivery to inspect the recorded reason."

  defp outcome_help(:delivery, :deferred),
    do: "The provider reported a temporary delivery delay. Delivery has not been confirmed."

  defp outcome_help(:delivery, :suppressed),
    do: "Sending to this recipient was blocked by a suppression rule."

  defp outcome_help(:delivery, :complained),
    do: "The provider reported a spam complaint for this message."

  defp outcome_help(:delivery, :unsubscribed),
    do: "The provider recorded an unsubscribe for this recipient."

  defp outcome_help(:delivery, :autoresponded),
    do:
      "The provider reported an automatic reply, such as an out-of-office response. This does not confirm that a person read the message."

  defp outcome_help(_, _), do: "Open the message to inspect its recorded processing history."

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
    :unsubscribed,
    :autoresponded
  ]

  @doc """
  The lifecycle state the operator Deliveries badge should display for a delivery.

  The core `Delivery.status` is a stable adopter snapshot that stops at `:sent`
  (handed off to the provider) and never advances. For the operator view we surface
  the latest delivery or engagement result instead: a downstream event
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

  def delivery_display_status(%{delivery_confirmed: true}), do: :delivered

  def delivery_display_status(%{status: :queued, last_event_type: event})
      when event in [:queued, nil],
      do: :queued

  # In-flight: status :sent / handed-off with no downstream outcome yet.
  def delivery_display_status(_delivery), do: :dispatched

  attr(:at, :any, required: true, doc: "a UTC %DateTime{} or nil")
  attr(:class, :string, default: "", doc: "extra classes for the rendered timestamp")

  attr(:copyable, :boolean,
    default: true,
    doc: "whether the timestamp copies its exact UTC value"
  )

  @doc """
  Renders a machine-readable <time> in the browser's local timezone. When copyable,
  the timestamp itself is a keyboard-accessible control that copies the exact UTC
  value and announces the result. `nil` renders an unavailable sentinel.
  """
  @doc since: "1.7.0"
  def timestamp(%{at: nil} = assigns) do
    ~H"""
    Unavailable
    """
  end

  def timestamp(assigns) do
    ~H"""
    <span :if={@copyable} class="mg-field-help inline-flex max-w-full">
      <button
        type="button"
        data-timestamp-copy="true"
        data-copy-value={utc_string(@at)}
        aria-label={"Copy timestamp as UTC: #{utc_string(@at)}"}
        class={["mg-timestamp-copy-trigger mg-focus-ring", @class]}
      >
        <time
          datetime={DateTime.to_iso8601(@at)}
          data-local-time="true"
          data-utc={utc_string(@at)}
          class="tabular-nums"
        >
          {utc_string(@at)}
        </time>
      </button>
      <span role="tooltip" aria-hidden="true" class="mg-field-help-tooltip [overflow-wrap:anywhere]">
        {utc_string(@at)} • Click to copy
      </span>
    </span>
    <time
      :if={!@copyable}
      datetime={DateTime.to_iso8601(@at)}
      data-local-time="true"
      data-utc={utc_string(@at)}
      title={utc_string(@at)}
      aria-label={"Recorded at #{utc_string(@at)}"}
      class={["tabular-nums", @class]}
    >
      {utc_string(@at)}
    </time>
    """
  end

  @doc """
  A visible identifier doubles as its copy control, using the shared toast. The
  accessible name is "Copy <label>: <value>", so the visible text is part of the
  name (WCAG 2.5.3 Label in Name), matching the timestamp copy control.
  """
  attr(:value, :string, required: true)
  attr(:label, :string, required: true)

  def copy_value(assigns) do
    ~H"""
    <button
      type="button"
      data-copy-value={@value}
      data-copy-toast={@label <> " copied."}
      aria-label={"Copy #{@label}: #{@value}"}
      title="Click to copy"
      class="mg-timestamp-copy-trigger mg-focus-ring mono max-w-full break-all text-left text-label text-secondary"
    >
      {@value}
    </button>
    """
  end

  attr(:value, :string, required: true)
  attr(:label, :string, required: true)

  def copy_button(assigns) do
    ~H"""
    <span class="inline-flex flex-wrap items-center gap-xs">
      <button
        type="button"
        class="btn btn-ghost min-h-11 mg-focus-ring"
        data-copy-value={@value}
        aria-label={@label}
      >
        {@label}
      </button>
      <span role="status" aria-live="polite" aria-atomic="true" data-copy-status></span>
    </span>
    """
  end

  @doc false
  def timestamp_value(%DateTime{} = at), do: utc_string(at)

  defp utc_string(%DateTime{} = at) do
    base = Calendar.strftime(at, "%Y-%m-%d %H:%M:%S")
    {microseconds, precision} = at.microsecond

    fraction =
      if precision > 0 do
        digits = microseconds |> Integer.to_string() |> String.pad_leading(6, "0")
        "." <> binary_part(digits, 0, precision)
      else
        ""
      end

    base <> fraction <> " UTC"
  end

  defp size_class(:sm), do: "badge-sm"
  defp size_class(:md), do: "badge-md"

  defp status_class(status), do: MailglassAdmin.Copy.status_class_or_unknown(status)
  defp status_icon(status), do: MailglassAdmin.Copy.status_icon_or_unknown(status)
  defp status_label(status), do: MailglassAdmin.Copy.status_label_or_unknown(status)

  @doc """
  Masks a recipient email for operator display (PII minimization).

  The ONE audited masking definition in the admin package: both
  `MailglassAdmin.Operator.DeliveriesList` (outbound) and the inbound
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
