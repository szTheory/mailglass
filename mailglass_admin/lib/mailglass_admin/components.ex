defmodule MailglassAdmin.Components do
  @moduledoc """
  Brand-book-aligned shared UI atoms used throughout mailglass_admin.

  ## Components

    * `icon/1` — Heroicon via the vendored `heroicons.js` Tailwind plugin
      (Phoenix 1.8 installer convention). Classes matching the pattern
      `hero-<name>` are resolved at build time into inline SVG.
    * `logo/1` — mailglass wordmark served from `priv/static/mailglass-logo.svg`
      via `MailglassAdmin.Controllers.Assets`.
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
  Renders the mailglass logo. The `src` is relative so the browser
  resolves it against the current document URL — the logo is served by
  `MailglassAdmin.Controllers.Assets` at `<mount>/logo.svg`.
  """
  @doc since: "0.1.0"
  def logo(assigns) do
    ~H"""
    <img src="logo.svg" alt="mailglass" class={@class} />
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
    <div class="toast toast-top toast-end z-50" role="status" aria-live="polite">
      <div class={["alert text-sm gap-2 py-2 px-3", alert_class(@kind)]}>
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
      <.icon name="hero-exclamation-triangle" class="w-3 h-3" />
      Error
    </span>
    """
  end

  def badge(%{variant: :stub} = assigns) do
    ~H"""
    <span class="text-secondary text-xs">—</span>
    """
  end

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
