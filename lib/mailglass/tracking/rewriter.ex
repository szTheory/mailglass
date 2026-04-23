defmodule Mailglass.Tracking.Rewriter do
  @moduledoc """
  Pure HTML transform: open-pixel injection + click link rewriting (TRACK-03).

  Called by `Mailglass.Tracking.rewrite_if_enabled/1` AFTER `Mailglass.Renderer.render/1`.
  Operates on the CSS-inlined HTML string; returns a rewritten HTML string.
  Plaintext body is NEVER modified (D-36 — plaintext readers often go
  through text-only proxies; leaving original URLs serves user trust).

  ## Skip list (D-36)

  - `mailto:`, `tel:`, `sms:`, `data:`, `javascript:` schemes
  - `#fragment` hrefs (same-page anchors)
  - scheme-less relative URLs (e.g. `/signup`)
  - `<a data-mg-notrack>` (attribute stripped from final HTML)
  - Any `<a>` inside `<head>` (prefetch, canonical)
  - Any href equal to the List-Unsubscribe URL (v0.5 hook reserved)

  ## Pixel injection (D-37)

  Markup: `<img src="..." width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0;" />`
  Position: LAST child of `<body>`. Missing `<body>` → appended at root.
  `alt=""` prevents screen-reader announcement.
  """

  alias Mailglass.Tracking.Token

  @doc """
  Rewrites an HTML string applying open-pixel injection and/or click link rewriting
  based on the provided flags.

  ## Options

  - `:flags` — `%{opens: boolean, clicks: boolean}` (required)
  - `:delivery_id` — delivery UUID for token encoding (required)
  - `:tenant_id` — tenant scope for token encoding (required)
  - `:endpoint` — Phoenix.Token endpoint or secret binary (optional, falls back to config)
  """
  @doc since: "0.1.0"
  @spec rewrite(html :: String.t(), opts :: keyword()) :: String.t()
  def rewrite(html, opts) when is_binary(html) and is_list(opts) do
    flags = Keyword.fetch!(opts, :flags)
    delivery_id = Keyword.fetch!(opts, :delivery_id)
    tenant_id = Keyword.fetch!(opts, :tenant_id)
    endpoint = Keyword.get(opts, :endpoint, Mailglass.Tracking.endpoint())

    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> maybe_rewrite_links(flags, delivery_id, tenant_id, endpoint)
        |> maybe_inject_pixel(flags, delivery_id, tenant_id, endpoint)
        |> Floki.raw_html()

      {:error, _} ->
        require Logger

        Logger.debug(
          "[mailglass] Tracking.Rewriter: Floki.parse_document failed; returning HTML unchanged"
        )

        html
    end
  end

  # --- Link rewriting ---

  defp maybe_rewrite_links(doc, %{clicks: true}, delivery_id, tenant_id, endpoint) do
    # Walk the tree and rewrite <a> tags.
    # We collect head children first so we can skip them during traversal.
    head_hrefs = collect_head_hrefs(doc)

    Floki.traverse_and_update(doc, fn
      {"a", attrs, children} ->
        if in_head_context?(attrs, head_hrefs) do
          {"a", attrs, children}
        else
          rewrite_anchor(attrs, children, delivery_id, tenant_id, endpoint)
        end

      other ->
        other
    end)
  end

  defp maybe_rewrite_links(doc, _flags, _d, _t, _e), do: doc

  # Collect all href values found in <head> children so we can skip them
  # during the full tree traversal. This handles the edge case where
  # an <a> tag appears inside <head> (rare but valid in some HTML5 contexts).
  defp collect_head_hrefs(doc) do
    case Floki.find(doc, "head a") do
      [] ->
        MapSet.new()

      head_anchors ->
        head_anchors
        |> Enum.flat_map(fn {"a", attrs, _} ->
          case List.keyfind(attrs, "href", 0) do
            {"href", href} -> [href]
            nil -> []
          end
        end)
        |> MapSet.new()
    end
  end

  # Check if an anchor is in head context. For v0.1, we use a simplified
  # approach: if the href appears in the collected head hrefs set, skip it.
  # This correctly handles the test case where head contains <link rel="canonical">
  # (a <link> tag, not <a>), so head_hrefs will be empty and all body <a> tags rewrite.
  defp in_head_context?(attrs, head_hrefs) do
    case List.keyfind(attrs, "href", 0) do
      {"href", href} -> MapSet.member?(head_hrefs, href)
      nil -> false
    end
  end

  defp rewrite_anchor(attrs, children, delivery_id, tenant_id, endpoint) do
    cond do
      has_notrack?(attrs) ->
        # Strip data-mg-notrack, do NOT rewrite href
        {"a", strip_notrack(attrs), children}

      true ->
        case List.keyfind(attrs, "href", 0) do
          {"href", href} ->
            if skip_rewrite?(href) do
              {"a", attrs, children}
            else
              new_token = Token.sign_click(endpoint, delivery_id, tenant_id, href)
              new_url = "#{tracking_scheme()}://#{tracking_host()}/c/#{new_token}"
              new_attrs = List.keyreplace(attrs, "href", 0, {"href", new_url})
              {"a", new_attrs, children}
            end

          nil ->
            {"a", attrs, children}
        end
    end
  end

  defp skip_rewrite?(href) when is_binary(href) do
    uri = URI.parse(href)

    cond do
      # Explicit non-http/https schemes
      uri.scheme in ["mailto", "tel", "sms", "data", "javascript"] -> true
      # Fragment-only hrefs
      String.starts_with?(href, "#") -> true
      # Scheme-less relative URLs: no scheme and no host
      is_nil(uri.scheme) and is_nil(uri.host) -> true
      true -> false
    end
  end

  defp has_notrack?(attrs), do: List.keyfind(attrs, "data-mg-notrack", 0) != nil

  defp strip_notrack(attrs), do: List.keydelete(attrs, "data-mg-notrack", 0)

  # --- Pixel injection ---

  defp maybe_inject_pixel(doc, %{opens: true}, delivery_id, tenant_id, endpoint) do
    token = Token.sign_open(endpoint, delivery_id, tenant_id)
    host = tracking_host()
    scheme = tracking_scheme()
    pixel_url = "#{scheme}://#{host}/o/#{token}.gif"

    pixel_tag =
      {"img",
       [
         {"src", pixel_url},
         {"width", "1"},
         {"height", "1"},
         {"alt", ""},
         {"style", "display:block;width:1px;height:1px;border:0;"}
       ], []}

    insert_into_body_end(doc, pixel_tag)
  end

  defp maybe_inject_pixel(doc, _flags, _d, _t, _e), do: doc

  defp insert_into_body_end(doc, tag) do
    doc
    |> Floki.traverse_and_update(fn
      {"body", attrs, children} -> {"body", attrs, children ++ [tag]}
      other -> other
    end)
    |> then(fn transformed ->
      # If no <body> was found in the traversal, append at root level
      body_found =
        Enum.any?(transformed, fn
          {"body", _, _} -> true
          {"html", _, children} -> Enum.any?(children, &match?({"body", _, _}, &1))
          _ -> false
        end)

      if body_found do
        transformed
      else
        transformed ++ [tag]
      end
    end)
  end

  # --- Config helpers ---

  defp tracking_host do
    case Application.get_env(:mailglass, :tracking, [])[:host] do
      host when is_binary(host) ->
        host

      _ ->
        raise Mailglass.ConfigError.new(:tracking_host_missing, context: %{})
    end
  end

  defp tracking_scheme do
    Application.get_env(:mailglass, :tracking, [])[:scheme] || "https"
  end

end
