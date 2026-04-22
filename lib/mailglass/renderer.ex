defmodule Mailglass.Renderer do
  @moduledoc """
  Pure-function render pipeline: HEEx → plaintext → CSS inlining → data-mg-* strip.

  All functions are side-effect free. No processes, no DB, no HTTP calls.

  ## Pipeline (D-15 — plaintext runs BEFORE CSS inlining)

  1. `render_html/2` — calls `Mailglass.TemplateEngine.HEEx.render/3`, returns HTML iodata
  2. `to_plaintext/1` — custom Floki walker on the pre-VML logical HTML
  3. `inline_css/1` — `Premailex.to_inline_css/2` (preserves MSO conditionals per D-14)
  4. `strip_mg_attributes/1` — removes all `data-mg-*` from the final HTML wire

  Plaintext MUST run on step-1 output (pre-CSS-inlining HTML), NOT on step-3 output.
  Premailex adds VML wrappers; the plaintext walker must not see them.

  ## Performance Target

  < 50ms end-to-end for a typical template (AUTHOR-03).

  ## Boundary

  `Mailglass.Renderer` cannot depend on `Mailglass.Outbound`, `Mailglass.Repo`,
  or any process. This is enforced by the `:boundary` compiler (CORE-07).
  """

  # Renderer is the first sub-boundary under the flat `Mailglass` root
  # (CORE-07). It may only reach into the modules that `Mailglass` explicitly
  # `exports`: `Message`, `Telemetry`, `Config`, `TemplateEngine`,
  # `TemplateEngine.HEEx`, `TemplateError`. Crucially it may NOT reach into
  # `Mailglass.Outbound`, `Mailglass.Repo`, or any process — those surfaces
  # land in later phases and are not exported to Renderer.
  use Boundary, deps: [Mailglass]

  alias Mailglass.Message
  alias Mailglass.Telemetry
  alias Mailglass.TemplateEngine.HEEx
  alias Mailglass.TemplateError

  @doc """
  Renders a `Mailglass.Message` through the full pipeline.

  Takes a Message whose `swoosh_email.html_body` is either a HEEx function
  component (`fn assigns -> ~H"..." end`) or a pre-rendered HTML string. Runs
  the configured pipeline and returns a Message with `swoosh_email.html_body`
  replaced by the final inlined HTML and `swoosh_email.text_body` populated
  with the auto-generated plaintext.

  The entire pipeline is wrapped in `Mailglass.Telemetry.render_span/2`.
  Metadata is whitelisted to `%{tenant_id, mailable}` — no PII per D-31.

  ## Examples

      component = fn _assigns -> ~H|<p>Hello</p>| end
      email = %Swoosh.Email{html_body: component}
      message = Mailglass.Message.new(email, mailable: MyMailer)
      {:ok, rendered} = Mailglass.Renderer.render(message)

  """
  @doc since: "0.1.0"
  @spec render(Message.t(), keyword()) ::
          {:ok, Message.t()} | {:error, TemplateError.t()}
  def render(%Message{} = message, opts \\ []) do
    metadata = %{
      tenant_id: message.tenant_id || "single_tenant",
      mailable: message.mailable
    }

    Telemetry.render_span(metadata, fn ->
      with {:ok, html_iodata} <- render_html(message, opts),
           html_binary = IO.iodata_to_binary(html_iodata),
           plaintext = to_plaintext(html_binary),
           {:ok, inlined_html} <- inline_css(html_binary) do
        final_html = strip_mg_attributes(inlined_html)

        updated_email = %{
          message.swoosh_email
          | html_body: final_html,
            text_body: plaintext
        }

        {:ok, %{message | swoosh_email: updated_email}}
      end
    end)
  end

  # --- Step 1: render the HEEx function component to HTML iodata ---

  defp render_html(%Message{swoosh_email: %{html_body: fun}}, opts)
       when is_function(fun, 1) do
    HEEx.render(fun, %{}, opts)
  end

  defp render_html(%Message{swoosh_email: %{html_body: html}}, _opts)
       when is_binary(html) do
    {:ok, html}
  end

  defp render_html(_message, _opts) do
    {:error,
     TemplateError.new(:heex_compile,
       context: %{
         reason:
           "message.swoosh_email.html_body must be a 1-arity function component or HTML string"
       }
     )}
  end

  # --- Step 2: custom Floki walker for plaintext (D-15, D-22) ---

  @doc """
  Extracts plaintext from HTML using `data-mg-plaintext` strategy attributes.

  Strategies (D-22):
    * `"skip"` — excludes the element and its children (preheader)
    * `"link_pair"` — emits `"Label (url)"` (button, link)
    * `"divider"` — emits `"\\n---\\n"` (hr)
    * `"heading_block_1"` — uppercase + blank lines (h1)
    * `"heading_block_2"` / `"_3"` / `"_4"` — title case + blank lines
    * `"text"` — raw text content; for `<img>`, uses the alt attribute
    * anything else (including missing) — recurses into children

  Runs on the pre-VML logical HTML tree so VML artifacts never leak into
  plaintext output.
  """
  @doc since: "0.1.0"
  @spec to_plaintext(String.t()) :: String.t()
  def to_plaintext(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        document
        |> extract_plaintext_nodes([])
        |> Enum.join("")
        |> normalize_whitespace()

      {:error, _reason} ->
        html |> Floki.text() |> normalize_whitespace()
    end
  end

  # Recursive tree walker that applies data-mg-plaintext strategies.
  defp extract_plaintext_nodes([], acc), do: Enum.reverse(acc)

  defp extract_plaintext_nodes([text | rest], acc) when is_binary(text) do
    extract_plaintext_nodes(rest, [text | acc])
  end

  defp extract_plaintext_nodes([{:comment, _content} | rest], acc) do
    extract_plaintext_nodes(rest, acc)
  end

  defp extract_plaintext_nodes([{:pi, _, _} | rest], acc) do
    extract_plaintext_nodes(rest, acc)
  end

  defp extract_plaintext_nodes([{tag, attrs, children} | rest], acc)
       when is_binary(tag) and is_list(attrs) and is_list(children) do
    strategy = get_strategy(attrs)
    result = apply_strategy(strategy, tag, attrs, children)
    extract_plaintext_nodes(rest, [result | acc])
  end

  defp extract_plaintext_nodes([_other | rest], acc) do
    extract_plaintext_nodes(rest, acc)
  end

  defp get_strategy(attrs) do
    case List.keyfind(attrs, "data-mg-plaintext", 0) do
      {_, strategy} -> strategy
      nil -> "default"
    end
  end

  # Strip all element children for "skip" — preheader text must never leak.
  defp apply_strategy("skip", _tag, _attrs, _children), do: ""

  defp apply_strategy("link_pair", _tag, attrs, children) do
    text = children |> Floki.text() |> String.trim()

    href =
      case List.keyfind(attrs, "href", 0) do
        {_, url} -> url
        nil -> ""
      end

    if href != "", do: "#{text} (#{href})\n", else: "#{text}\n"
  end

  defp apply_strategy("divider", _tag, _attrs, _children), do: "\n---\n"

  defp apply_strategy(<<"heading_block_", level::binary>>, _tag, _attrs, children) do
    text = children |> Floki.text() |> String.trim()

    formatted =
      case level do
        "1" -> String.upcase(text)
        _ -> text
      end

    "\n#{formatted}\n\n"
  end

  defp apply_strategy("text", tag, attrs, children) do
    # For <img>: use alt text; for anything else: element text content.
    case tag do
      "img" ->
        case List.keyfind(attrs, "alt", 0) do
          {_, alt} when alt != "" -> "#{alt}\n"
          _ -> ""
        end

      _ ->
        text = children |> Floki.text() |> String.trim()
        if text == "", do: "", else: "#{text}\n"
    end
  end

  # Skip script/style blocks entirely.
  defp apply_strategy(_default, "script", _attrs, _children), do: ""
  defp apply_strategy(_default, "style", _attrs, _children), do: ""
  defp apply_strategy(_default, "head", _attrs, _children), do: ""

  defp apply_strategy(_default, _tag, _attrs, children) do
    children
    |> extract_plaintext_nodes([])
    |> Enum.join("")
  end

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/[ \t]+/, " ")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
  end

  # --- Step 3: CSS inlining via Premailex (preserves MSO conditional comments) ---

  defp inline_css(html) when is_binary(html) do
    inlined = Premailex.to_inline_css(html)
    {:ok, inlined}
  rescue
    e ->
      {:error,
       TemplateError.new(:inliner_failed,
         cause: e,
         context: %{reason: Exception.message(e)}
       )}
  end

  # --- Step 4: strip all data-mg-* attributes from final HTML wire ---

  defp strip_mg_attributes(html) when is_binary(html) do
    Regex.replace(~r/\s+data-mg-[a-z-]+=(?:"[^"]*"|'[^']*'|[^\s>]*)/, html, "")
  end
end
