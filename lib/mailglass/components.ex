defmodule Mailglass.Components do
  @moduledoc """
  HEEx function components for transactional email composition.

  ## Components

    * Layout: `container/1`, `section/1`, `row/1`, `column/1`
    * Content: `heading/1`, `text/1`, `button/1`, `link/1`
    * Atomic:  `img/1`, `hr/1`, `preheader/1`

  ## Theme

  All brand-token attributes (`:tone`, `:variant`, `:bg`) resolve via
  `Mailglass.Components.Theme.color/1` and `.font/1` at render time. The theme
  is cached in `:persistent_term` by `Mailglass.Config.validate_at_boot!/0`
  (D-19); reads are O(1).

  ## MSO / Outlook VML

  Per D-11, VML is used surgically:

    * `button/1` — `<v:roundrect>` bulletproof button with mso-hide:all HTML fallback
    * `row/1` / `column/1` — ghost-table `<!--[if mso]>` conditionals
    * all other components — pure HTML + inline CSS

  ## Plaintext extraction

  Each content component emits `data-mg-plaintext="<strategy>"` on its root
  node. `Mailglass.Renderer.to_plaintext/1` (Plan 06) walks the tree keyed
  off these markers. A terminal Floki pass strips all `data-mg-*` attributes
  from the final HTML wire (D-22).
  """

  use Phoenix.Component

  alias Mailglass.Components.{CSS, Theme}

  @global_includes ~w(id data-testid aria-label aria-hidden)
  @link_global_includes ~w(id data-testid aria-label aria-hidden href target)

  # ---------------------------------------------------------------------------
  # preheader/1 — no VML, hidden preview text
  # ---------------------------------------------------------------------------

  attr(:text, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(id))

  @doc """
  Renders an email preheader — the hidden snippet that email clients show in
  inbox previews.

  Styled to be invisible (`display:none`, `mso-hide:all`) and padded with
  zero-width chars to push additional content out of Gmail's preview pull
  (D-15). Carries `data-mg-plaintext="skip"` so the plaintext walker
  excludes it from the text body.
  """
  @doc since: "0.1.0"
  def preheader(assigns) do
    ~H"""
    <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;"
         aria-hidden="true"
         data-mg-plaintext="skip"
         {@rest}>{@text}&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;&#8199;&#65279;&zwnj;</div>
    """
  end

  # ---------------------------------------------------------------------------
  # container/1 — 600px centered table, no VML
  # ---------------------------------------------------------------------------

  attr(:bg, :string, values: ~w(paper mist ink custom), default: "paper")
  attr(:bg_hex, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc "Renders a 600px-wide centered email container table (D-11)."
  @doc since: "0.1.0"
  def container(assigns) do
    assigns = assign(assigns, :bg_color, resolve_bg(assigns.bg, assigns.bg_hex))

    ~H"""
    <table role="presentation" width="100%" border="0" cellpadding="0" cellspacing="0"
           style={CSS.merge_style("width:100%;background-color:#{@bg_color};", @class)}>
      <tr>
        <td align="center">
          <table role="presentation" width="600" border="0" cellpadding="0" cellspacing="0"
                 style="max-width:600px;width:100%;mso-table-lspace:0pt;mso-table-rspace:0pt;">
            <tr>
              <td {@rest}>
                {render_slot(@inner_block)}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
    """
  end

  # ---------------------------------------------------------------------------
  # section/1 — full-width inner padding table, no VML
  # ---------------------------------------------------------------------------

  attr(:bg, :string, values: ~w(paper mist ink custom), default: "paper")
  attr(:bg_hex, :string, default: nil)
  attr(:padding, :string, default: "20px")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc "Renders a full-width email section with padded inner cell."
  @doc since: "0.1.0"
  def section(assigns) do
    assigns = assign(assigns, :bg_color, resolve_bg(assigns.bg, assigns.bg_hex))

    ~H"""
    <table role="presentation" width="100%" border="0" cellpadding="0" cellspacing="0"
           style={CSS.merge_style("width:100%;background-color:#{@bg_color};", @class)}>
      <tr>
        <td style={"padding:#{@padding};mso-line-height-rule:exactly;"} {@rest}>
          {render_slot(@inner_block)}
        </td>
      </tr>
    </table>
    """
  end

  # ---------------------------------------------------------------------------
  # row/1 — VML ghost-table for Outlook multi-column layout
  # ---------------------------------------------------------------------------

  attr(:gap, :integer, default: 0)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc """
  Renders a row that holds `column/1` children.

  Emits a `<!--[if mso]><table role="presentation">` ghost table so classic
  Outlook aligns columns side-by-side instead of stacking them (D-11).
  """
  @doc since: "0.1.0"
  def row(assigns) do
    gap_style = if assigns.gap > 0, do: "gap:#{assigns.gap}px;", else: ""

    # HEEx treats the contents of <!-- --> as literal text and does NOT
    # interpolate expressions inside them. For VML we must build the MSO
    # conditional blocks as raw HTML strings and embed them via {@mso_open}
    # / {@mso_close} so the interpolation happens outside the comment scope.
    mso_open =
      Phoenix.HTML.raw(
        ~s(<!--[if mso]><table role="presentation" width="100%" border="0" cellpadding="0" cellspacing="#{assigns.gap}"><tr><![endif]-->)
      )

    mso_close = Phoenix.HTML.raw("<!--[if mso]></tr></table><![endif]-->")

    assigns =
      assigns
      |> assign(:gap_style, gap_style)
      |> assign(:mso_open, mso_open)
      |> assign(:mso_close, mso_close)

    ~H"""
    {@mso_open}<div style={CSS.merge_style("max-width:100%;font-size:0;" <> @gap_style, @class)} {@rest}>{render_slot(@inner_block)}</div>{@mso_close}
    """
  end

  # ---------------------------------------------------------------------------
  # column/1 — VML ghost-td paired with row/1
  # ---------------------------------------------------------------------------

  attr(:width, :any, default: :auto)
  attr(:valign, :string, values: ~w(top middle bottom), default: "top")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc """
  Renders a column inside a `row/1`. Emits a `<!--[if mso]><td>` ghost-td
  conditional wrapper so classic Outlook respects the column layout.
  """
  @doc since: "0.1.0"
  def column(assigns) do
    width_attr =
      case assigns.width do
        :auto -> ""
        n when is_integer(n) -> Integer.to_string(n)
        s when is_binary(s) -> s
      end

    inline_width_style =
      case assigns.width do
        :auto -> ""
        n when is_integer(n) -> "width:#{n}px;"
        s when is_binary(s) -> "width:#{s};"
      end

    # MSO comments must be raw-embedded (see row/1 comment).
    width_mso_attr = if width_attr == "", do: "", else: ~s( width="#{width_attr}")

    mso_open =
      Phoenix.HTML.raw(
        ~s(<!--[if mso]><td valign="#{assigns.valign}"#{width_mso_attr}><![endif]-->)
      )

    mso_close = Phoenix.HTML.raw("<!--[if mso]></td><![endif]-->")

    assigns =
      assigns
      |> assign(:inline_width_style, inline_width_style)
      |> assign(:mso_open, mso_open)
      |> assign(:mso_close, mso_close)

    ~H"""
    {@mso_open}<div style={CSS.merge_style("display:inline-block;vertical-align:#{@valign};#{@inline_width_style}", @class)} data-mg-column="true" {@rest}>{render_slot(@inner_block)}</div>{@mso_close}
    """
  end

  # ---------------------------------------------------------------------------
  # heading/1 — no VML; dynamic h1..h4 tag
  # ---------------------------------------------------------------------------

  attr(:level, :integer, values: [1, 2, 3, 4], default: 1)
  attr(:align, :string, values: ~w(left center right), default: "left")
  attr(:tone, :string, values: ~w(ink glass slate), default: "ink")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc """
  Renders an `<h1>`..`<h4>` heading with brand-tone color and email-safe
  `mso-line-height-rule:exactly`.
  """
  @doc since: "0.1.0"
  def heading(assigns) do
    assigns =
      assigns
      |> assign(:hx_style, heading_style(assigns))
      |> assign(:plaintext_strategy, "heading_block_#{assigns.level}")

    case assigns.level do
      1 ->
        ~H"""
        <h1 style={CSS.merge_style(@hx_style, @class)} data-mg-plaintext={@plaintext_strategy} {@rest}>{render_slot(@inner_block)}</h1>
        """

      2 ->
        ~H"""
        <h2 style={CSS.merge_style(@hx_style, @class)} data-mg-plaintext={@plaintext_strategy} {@rest}>{render_slot(@inner_block)}</h2>
        """

      3 ->
        ~H"""
        <h3 style={CSS.merge_style(@hx_style, @class)} data-mg-plaintext={@plaintext_strategy} {@rest}>{render_slot(@inner_block)}</h3>
        """

      4 ->
        ~H"""
        <h4 style={CSS.merge_style(@hx_style, @class)} data-mg-plaintext={@plaintext_strategy} {@rest}>{render_slot(@inner_block)}</h4>
        """
    end
  end

  defp heading_style(%{tone: tone, align: align}) do
    "color:#{Theme.color(String.to_atom(tone))};" <>
      "text-align:#{align};" <>
      "mso-line-height-rule:exactly;" <>
      "margin:0 0 16px 0;" <>
      "font-family:#{Theme.font(:display)};"
  end

  # ---------------------------------------------------------------------------
  # text/1 — no VML, <p>
  # ---------------------------------------------------------------------------

  attr(:size, :string, values: ~w(sm base lg), default: "base")
  attr(:tone, :string, values: ~w(ink slate), default: "ink")
  attr(:align, :string, values: ~w(left center right), default: "left")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)
  slot(:inner_block, required: true)

  @doc "Renders a paragraph with brand-tone color and size variant."
  @doc since: "0.1.0"
  def text(assigns) do
    font_size = Map.fetch!(%{"sm" => "13px", "base" => "16px", "lg" => "18px"}, assigns.size)

    base_style =
      "font-size:#{font_size};" <>
        "color:#{Theme.color(String.to_atom(assigns.tone))};" <>
        "text-align:#{assigns.align};" <>
        "mso-line-height-rule:exactly;" <>
        "margin:0 0 16px 0;" <>
        "font-family:#{Theme.font(:body)};" <>
        "line-height:1.5;"

    assigns = assign(assigns, :base_style, base_style)

    ~H"""
    <p style={CSS.merge_style(@base_style, @class)} data-mg-plaintext="text" {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ---------------------------------------------------------------------------
  # button/1 — SURGICAL VML FLAGSHIP: <v:roundrect> bulletproof button (D-10)
  # ---------------------------------------------------------------------------

  attr(:variant, :string, values: ~w(primary secondary ghost), default: "primary")
  attr(:tone, :string, values: ~w(glass ink slate), default: "glass")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @link_global_includes)
  slot(:inner_block, required: true)

  @doc """
  Renders a bulletproof button with a `<v:roundrect>` VML wrapper for classic
  Outlook and an `<a>` HTML fallback carrying `mso-hide:all` so Outlook hides
  it in favour of the VML version (D-10).

  Content components exclude `:style` from `:global` per D-17.
  """
  @doc since: "0.1.0"
  def button(assigns) do
    btn_color = Theme.color(String.to_atom(assigns.tone))
    body_font = Theme.font(:body)
    text_color = button_text_color(assigns.variant)
    bg_color = button_bg_color(assigns.variant, btn_color)
    border_color = btn_color

    html_style =
      "display:inline-block;" <>
        "padding:12px 24px;" <>
        "background-color:#{bg_color};" <>
        "color:#{text_color};" <>
        "text-decoration:none;" <>
        "font-family:#{body_font};" <>
        "font-size:16px;" <>
        "font-weight:600;" <>
        "border:1px solid #{border_color};" <>
        "border-radius:4px;" <>
        "mso-hide:all;"

    # HEEx does not interpolate expressions inside `<!-- ... -->` comments, so
    # the VML block is pre-rendered to a raw string. The slot content is
    # rendered once (via Phoenix.Component.render_slot) and injected into
    # both branches so author-supplied label text appears in classic Outlook
    # (via <center>) and every other client (via <a>). The `<!--[if !mso]><!-->`
    # boundary terminates the comment per HTML parser rules — HEEx respects
    # that boundary, so the <a> fallback uses normal HEEx interpolation.
    href = Map.get(assigns.rest, :href, "#")
    slot_binary = render_slot_to_binary(assigns.inner_block, assigns)
    href_escaped = escape_attr(href)

    vml_block =
      ~s(<!--[if mso]>) <>
        ~s(<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" ) <>
        ~s(xmlns:w="urn:schemas-microsoft-com:office:word" ) <>
        ~s(href="#{href_escaped}" ) <>
        ~s(style="height:44px;v-text-anchor:middle;width:200px;" ) <>
        ~s(arcsize="8%" fillcolor="#{bg_color}" strokecolor="#{border_color}">) <>
        ~s(<w:anchorlock/>) <>
        ~s(<center style="font-family:#{body_font};font-size:16px;color:#{text_color};font-weight:600;">) <>
        slot_binary <>
        ~s(</center></v:roundrect>) <>
        ~s(<![endif]-->)

    assigns =
      assigns
      |> assign(:html_style, html_style)
      |> assign(:vml_block, Phoenix.HTML.raw(vml_block))

    ~H"""
    {@vml_block}<!--[if !mso]><!--><a style={CSS.merge_style(@html_style, @class)} data-mg-plaintext="link_pair" {@rest}>{render_slot(@inner_block)}</a><!--<![endif]-->
    """
  end

  # Renders an inner_block slot to an escaped binary suitable for injection
  # into a raw HTML string. `Phoenix.Component.render_slot/2` is a macro that
  # expects to run inside a ~H context, so we call the underlying
  # `__render_slot__/3` with a nil `changed` tracker (the slot is rendered
  # unconditionally — this is a one-shot server render, not a LiveView patch).
  defp render_slot_to_binary(slot, _assigns) do
    Phoenix.Component.__render_slot__(nil, slot, nil)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp escape_attr(value) when is_binary(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp button_text_color("ghost"), do: "#0D1B2A"
  defp button_text_color(_), do: "#F8FBFD"

  defp button_bg_color("primary", color), do: color
  defp button_bg_color("secondary", _color), do: "#EAF6FB"
  defp button_bg_color("ghost", _color), do: "transparent"

  # ---------------------------------------------------------------------------
  # img/1 — no VML; alt required at compile time (D-18)
  # ---------------------------------------------------------------------------

  attr(:src, :string, required: true)
  attr(:alt, :string, required: true)
  attr(:width, :integer, default: nil)
  attr(:height, :integer, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(id data-testid))

  @doc """
  Renders an `<img>` tag. The `:alt` attribute is required at compile time
  (D-18) — authors must pass `alt=""` for decorative images.
  """
  @doc since: "0.1.0"
  def img(assigns) do
    ~H"""
    <img src={@src}
         alt={@alt}
         width={@width}
         height={@height}
         style={CSS.merge_style("-ms-interpolation-mode:bicubic;max-width:100%;border:0;display:block;", @class)}
         data-mg-plaintext="text"
         {@rest} />
    """
  end

  # ---------------------------------------------------------------------------
  # link/1 — no VML; inline color on <a> AND wrapping <span>
  # ---------------------------------------------------------------------------

  attr(:tone, :string, values: ~w(glass ink), default: "glass")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @link_global_includes)
  slot(:inner_block, required: true)

  @doc """
  Renders an inline text link. Sets the tone color both on the `<a>` and the
  wrapping `<span>` so email clients that strip one still render the other
  (D-11).
  """
  @doc since: "0.1.0"
  def link(assigns) do
    link_color = Theme.color(String.to_atom(assigns.tone))
    body_font = Theme.font(:body)

    a_style =
      "color:#{link_color};" <>
        "text-decoration:underline;" <>
        "font-family:#{body_font};"

    span_style = "color:#{link_color};text-decoration:underline;"

    assigns =
      assigns
      |> assign(:a_style, a_style)
      |> assign(:span_style, span_style)

    ~H"""
    <a style={CSS.merge_style(@a_style, @class)} data-mg-plaintext="link_pair" {@rest}>
      <span style={@span_style}>{render_slot(@inner_block)}</span>
    </a>
    """
  end

  # ---------------------------------------------------------------------------
  # hr/1 — no VML; zero-height table with 1px border-top
  # ---------------------------------------------------------------------------

  attr(:tone, :string, values: ~w(mist slate), default: "mist")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: @global_includes)

  @doc """
  Renders an email-safe horizontal rule: a zero-height `<table>` with a 1px
  `border-top` on the inner `<td>` (D-11).
  """
  @doc since: "0.1.0"
  def hr(assigns) do
    hr_color = Theme.color(String.to_atom(assigns.tone))
    td_base = "height:0;border-top:1px solid #{hr_color};font-size:0;line-height:0;"
    assigns = assign(assigns, :td_style, CSS.merge_style(td_base, assigns.class))

    ~H"""
    <table role="presentation" width="100%" border="0" cellpadding="0" cellspacing="0"
           style="width:100%;margin:16px 0;" {@rest}>
      <tr>
        <td style={@td_style} data-mg-plaintext="divider">&nbsp;</td>
      </tr>
    </table>
    """
  end

  # ---------------------------------------------------------------------------
  # private helpers
  # ---------------------------------------------------------------------------

  defp resolve_bg("custom", bg_hex) when is_binary(bg_hex), do: bg_hex
  defp resolve_bg("custom", _), do: "#FFFFFF"
  defp resolve_bg(bg, _bg_hex) when is_binary(bg), do: Theme.color(String.to_atom(bg))
end
