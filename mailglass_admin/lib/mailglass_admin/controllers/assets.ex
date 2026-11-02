defmodule MailglassAdmin.Controllers.Assets do
  @moduledoc """
  Compile-time asset server for the mailglass_admin preview dashboard.

  Embeds `priv/static/app.css`, the concatenated Phoenix + Phoenix
  LiveView JS bundles, the logo and favicon SVGs, and the font woff2 subsets into
  module attributes at compile time via `@external_resource` +
  `File.read!/1`. Request-time cost is a single `Plug.Conn.send_resp/3`
  from the module-attribute bytes — no filesystem I/O, no Plug.Static
  in the chain.

  ## Caching

  Every response sets:

      cache-control: public, max-age=31536000, immutable

  MD5 hashes of the bundles are exposed via `css_hash/0` and `js_hash/0`
  so layouts can emit cache-busting URLs like `css-<hash>.css`. New
  builds produce new hashes → new URLs → bypass the immutable cache.

  ## Phoenix + LiveView JS not charged to our tarball

  `phoenix.js` and `phoenix_live_view.js` are read from their host
  packages' `priv/static/` directories via `Application.app_dir/2`.
  Those bytes are NOT in mailglass_admin's Hex tarball — adopters
  already pay for them via their own `:phoenix` + `:phoenix_live_view`
  deps. The 2 MB tarball gate only measures files we ship.

  ## Font allowlist

  `call(conn, :font)` hits the six-member `@allowed_fonts` guard before
  constructing a filesystem path. A path traversal attempt like
  `GET /fonts/..%2F..%2Fetc%2Fpasswd` fails the guard, falls through to
  `_ -> :error`, and returns 404 with an empty body. The 2-weights-per-
  family lock from 05-UI-SPEC lines 71-79 means the allowlist is small
  and stable; adding a seventh weight requires updating BOTH the
  `@allowed_fonts` list AND the brand test fixture.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary declared in `lib/mailglass_admin.ex`;
  `classify_to:` is reserved for mix tasks and protocol implementations
  and is not used here.
  """

  import Plug.Conn

  # ---- CSS bundle (compile-time embedded) ----
  @css_path Path.expand("../../../priv/static/app.css", __DIR__)
  @external_resource @css_path
  @css File.read!(@css_path)
  @css_hash Base.encode16(:crypto.hash(:md5, @css), case: :lower)

  # ---- JS bundle: phoenix.js + phoenix_live_view.js ----
  # Read from the host's already-installed priv dirs so they are NOT
  # charged to mailglass_admin's Hex tarball.
  @phoenix_js Application.app_dir(:phoenix, "priv/static/phoenix.js")
  @phoenix_live_view_js Application.app_dir(
                          :phoenix_live_view,
                          "priv/static/phoenix_live_view.js"
                        )
  @external_resource @phoenix_js
  @external_resource @phoenix_live_view_js
  @hooks_path Path.expand("../../../priv/static/hooks.js", __DIR__)
  @external_resource @hooks_path
  @hooks File.read!(@hooks_path)
  @hooks_hash Base.encode16(:crypto.hash(:md5, @hooks), case: :lower)
  @storybook_hooks_js @hooks <>
                        "\n;(() => {\n  window.storybook = window.storybook || {}\n  window.storybook.Hooks = window.MailglassAdminHooks\n})();\n"
  @live_socket_bootstrap """
  // js-enabled marker (set synchronously in <head>, before <body> paints): the
  // timestamp skeleton CSS is scoped to `.mg-js` so it only applies when JS will
  // localize. With JS off the class is absent and the server-rendered UTC shows.
  document.documentElement.classList.add("mg-js")

  ;(() => {
    const csrfToken = document
      .querySelector("meta[name='csrf-token']")
      ?.getAttribute("content")

    const Hooks = window.MailglassAdminHooks

    const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
      params: csrfToken ? { _csrf_token: csrfToken } : {},
      hooks: Hooks
    })

    window.liveSocket = liveSocket

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", () => liveSocket.connect(), { once: true })
    } else {
      liveSocket.connect()
    }
  })();

  // Show one concise timestamp in the browser's local timezone. The server-rendered
  // UTC value remains the no-JS fallback and the exact value stays in the title/data.
  // No phx-hook: a MutationObserver enhances timestamps inserted by LiveView patches.
  ;(() => {
    const FMT = {
      year: "numeric", month: "short", day: "numeric",
      hour: "numeric", minute: "2-digit"
    }

    function localize(el) {
      const iso = el.getAttribute("datetime")
      if (!iso) return
      const d = new Date(iso)
      if (isNaN(d.getTime())) return
      let localValue
      try {
        localValue = d.toLocaleString(undefined, FMT)
      } catch (_e) {
        return
      }
      if (!localValue) return
      el.textContent = localValue
      el.setAttribute("aria-label", `Recorded at ${localValue} local time`)
      el.dataset.localized = "1"
    }

    function localizeAll() {
      document
        .querySelectorAll("time[data-local-time]:not([data-localized])")
        .forEach(localize)
    }

    let scheduled = false
    function schedule() {
      if (scheduled) return
      scheduled = true
      requestAnimationFrame(() => { scheduled = false; localizeAll(); positionActiveFieldHelpTooltips() })
    }

    // Native account disclosure menus should dismiss when the operator clicks away.
    document.addEventListener("click", (e) => {
      const target = e.target
      const accountOption = target?.closest?.("[data-dismiss-menu]")
      if (accountOption) {
        accountOption.closest("details[data-dismiss-outside]")?.removeAttribute("open")
        return
      }
      if (target?.closest?.("details[data-dismiss-outside]")) return
      document.querySelectorAll("details[data-dismiss-outside][open]").forEach((menu) => {
        menu.removeAttribute("open")
      })
    })

    function positionFieldHelpTooltip(button) {
      const tooltipId = button.getAttribute("aria-controls")
      const tooltip = tooltipId ? document.getElementById(tooltipId) : button.closest(".mg-field-help")?.querySelector(".mg-field-help-tooltip")
      if (!tooltip) return

      const trigger = button.getBoundingClientRect()
      const panel = tooltip.getBoundingClientRect()
      const padding = 12
      const gap = 8
      const left = Math.min(
        Math.max(trigger.left + (trigger.width - panel.width) / 2, padding),
        Math.max(padding, window.innerWidth - panel.width - padding)
      )
      const below = trigger.bottom + gap
      const above = trigger.top - panel.height - gap
      const placement = below + panel.height <= window.innerHeight - padding || above < padding
        ? "bottom"
        : "top"
      const top = Math.max(padding, Math.min(
        placement === "bottom" ? below : above,
        window.innerHeight - panel.height - padding
      ))

      // Only write changed values: the observer also repairs styles removed by
      // LiveView patches, and identical writes would create a mutation loop.
      const styles = {
        position: "fixed", right: "auto", bottom: "auto",
        left: `${Math.round(left)}px`, top: `${Math.round(top)}px`, translate: "none"
      }
      for (const [property, value] of Object.entries(styles)) {
        if (tooltip.style[property] !== value) tooltip.style[property] = value
      }
      if (tooltip.dataset.placement !== placement) tooltip.dataset.placement = placement
      const arrow = `${Math.round(Math.max(12, Math.min(panel.width - 12,
        trigger.left + trigger.width / 2 - left)))}px`
      if (tooltip.style.getPropertyValue("--mg-tooltip-arrow-x") !== arrow) {
        tooltip.style.setProperty("--mg-tooltip-arrow-x", arrow)
      }
    }

    function positionActiveFieldHelpTooltips() {
      document
        .querySelectorAll(".mg-field-help button:is(:hover,:focus-visible,[aria-expanded=true])")
        .forEach(positionFieldHelpTooltip)
    }

    document.addEventListener("pointerover", (e) => {
      const button = e.target.closest && e.target.closest(".mg-field-help button")
      if (button) { button.removeAttribute("data-dismissed"); positionFieldHelpTooltip(button) }
    }, true)
    document.addEventListener("focusin", (e) => {
      const button = e.target.closest && e.target.closest(".mg-field-help button")
      if (button) { button.removeAttribute("data-dismissed"); positionFieldHelpTooltip(button) }
    }, true)
    document.addEventListener("click", (e) => {
      const button = e.target.closest && e.target.closest(".mg-field-help button")
      if (button) requestAnimationFrame(() => positionFieldHelpTooltip(button))
    }, true)
    document.addEventListener("keydown", (e) => {
      if (e.key !== "Escape") return
      document.querySelectorAll(".mg-field-help button:is(:hover,:focus-visible,[aria-expanded=true])").forEach(button => {
        button.setAttribute("data-dismissed", "true")
        if (button.hasAttribute("aria-expanded")) button.setAttribute("aria-expanded", "false")
      })
    })
    window.addEventListener("resize", positionActiveFieldHelpTooltips)
    window.addEventListener("scroll", positionActiveFieldHelpTooltips, true)

    // Native controls own Enter. Keep the Quick view's global shortcut from
    // opening full detail when a focused copy/help button or link is activated.
    document.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && e.target.closest?.(".mg-detail-panel") &&
          e.target.closest?.("button, a, input, select, textarea, summary")) {
        e.stopPropagation()
      }
    }, true)

    let toastTimer
    function showToast(message, isError = false) {
      const toast = document.getElementById("mg-copy-toast")
      const messageEl = toast?.querySelector("[data-copy-toast-message]")
      const alert = messageEl?.parentElement
      if (!toast || !messageEl || !alert) return

      window.clearTimeout(toastTimer)
      alert.classList.toggle("alert-success", !isError)
      alert.classList.toggle("alert-error", isError)
      messageEl.textContent = message
      toast.hidden = false
      toastTimer = window.setTimeout(() => { toast.hidden = true }, 2400)
    }

    // Server notifications share the same feedback surface as copy actions.
    window.addEventListener("phx:mailglass:toast", ({detail}) => {
      showToast(detail.message, detail.error === true)
    })

    // Copy controls remain functional after LiveView patches. Timestamp clicks use
    // the shared toast, as do clickable identifiers; other controls keep adjacent status.
    document.addEventListener("click", (e) => {
      const button = e.target.closest && e.target.closest("button[data-copy-value]")
      if (!button) return
      e.stopPropagation()
      e.preventDefault()
      document.querySelectorAll(".mg-field-help button[aria-expanded=true]").forEach((trigger) => {
        trigger.setAttribute("aria-expanded", "false")
      })
      document.querySelectorAll("details[data-dismiss-outside][open]").forEach((menu) => {
        menu.removeAttribute("open")
      })
      const timestampCopy = button.hasAttribute("data-timestamp-copy")
      const copyToast = timestampCopy ? "Timestamp copied as UTC." : button.getAttribute("data-copy-toast")
      const status = button.parentElement.querySelector("[data-copy-status]")
      const value = button.getAttribute("data-copy-value")
      if ((!copyToast && !status) || value === null) return

      if (status) status.textContent = ""
      Promise.resolve()
        .then(() => {
          if (!navigator.clipboard?.writeText) throw new Error("Clipboard unavailable")
          return navigator.clipboard.writeText(value)
        })
        .then(() => {
          if (copyToast) showToast(copyToast)
          else status.textContent = "Copied."
        })
        .catch(() => {
          const message = "Clipboard access failed. Select and copy the visible value manually."
          if (copyToast) showToast(message, true)
          else status.textContent = "Clipboard unavailable. Select and copy the visible value manually."
        })
    }, true)

    // While the Quick view overlay is open, its arrow keys drive prev/next record
    // navigation (LiveView phx-window-keydown). Cancel the browser's DEFAULT arrow
    // action so the keypress does not ALSO scroll the list/table underneath. This only
    // prevents the default scroll — LiveView's own keydown handler still fires, so
    // navigation is unaffected. Scoped to when `.mg-detail-panel` (the overlay) exists.
    document.addEventListener("keydown", (e) => {
      if (!e.key || e.key.indexOf("Arrow") !== 0) return
      if (document.querySelector(".mg-detail-panel")) e.preventDefault()
    })

    function start() {
      localizeAll()
      // Watch attributes + characterData too: when LiveView/morphdom patches a <time>
      // in place on connect it resets the text to UTC and strips data-localized — both
      // are attribute/characterData mutations (not childList), so a childList-only
      // observer would never re-localize and the cell would stay stuck at UTC.
      new MutationObserver(schedule).observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["data-localized", "datetime", "aria-expanded", "style"],
        characterData: true
      })
    }

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", start, { once: true })
    } else {
      start()
    }
  })();
  """
  @js Enum.map_join([@phoenix_js, @phoenix_live_view_js], "\n", &File.read!/1) <>
        "\n" <> @hooks <> "\n" <> @live_socket_bootstrap
  @js_hash Base.encode16(:crypto.hash(:md5, @js), case: :lower)

  # ---- Logo ----
  @logo_path Path.join([:code.priv_dir(:mailglass_admin), "static", "mailglass-logo.svg"])
  @external_resource @logo_path
  @logo File.read!(@logo_path)

  # ---- Favicon: the brand's small-size mark, with OS dark-mode support ----
  @favicon_path Path.join([:code.priv_dir(:mailglass_admin), "static", "favicon.svg"])
  @external_resource @favicon_path
  @favicon File.read!(@favicon_path)
  @favicon_hash Base.encode16(:crypto.hash(:md5, @favicon), case: :lower)

  @doc """
  MD5 hash (lowercase hex) of the embedded `priv/static/app.css` bytes.

  Used by `MailglassAdmin.Layouts.css_url/0` to build cache-busting URLs
  like `css-<hash>.css`. The macro's `get "/css-:md5", ...` route
  captures the hash in `conn.path_params["md5"]` but the handler does
  not currently validate it — browsers never emit stale URLs because
  the immutable cache drops when the rendered document URL changes.
  """
  @spec css_hash() :: String.t()
  def css_hash, do: @css_hash

  @doc """
  MD5 hash (lowercase hex) of the concatenated Phoenix + LiveView JS.

  Same cache-busting role as `css_hash/0`.
  """
  @spec js_hash() :: String.t()
  def js_hash, do: @js_hash

  @doc false
  @spec hooks_hash() :: String.t()
  def hooks_hash, do: @hooks_hash

  @doc false
  @spec hooks_body() :: binary()
  def hooks_body, do: @hooks

  @doc "Content hash used to version the embedded favicon URL."
  @spec favicon_hash() :: String.t()
  def favicon_hash, do: @favicon_hash

  @doc false
  @spec js_body() :: binary()
  def js_body, do: @js

  # Plug-controller dispatch per Phoenix Router macro expansion. The
  # Router emits `get "/css-:md5", MailglassAdmin.Controllers.Assets, :css`
  # which calls `init(:css)` once at compile time + `call(conn, :css)`
  # on every request.
  def init(action) when action in [:css, :js, :hooks, :font, :logo, :favicon], do: action

  def call(conn, :css), do: serve(conn, @css, "text/css; charset=utf-8")
  def call(conn, :js), do: serve(conn, @js, "application/javascript; charset=utf-8")

  def call(conn, :hooks),
    do: serve(conn, @storybook_hooks_js, "application/javascript; charset=utf-8")

  def call(conn, :logo), do: serve(conn, @logo, "image/svg+xml")
  def call(conn, :favicon), do: serve(conn, @favicon, "image/svg+xml")

  def call(conn, :font) do
    name = conn.params["name"]

    with {:ok, path} <- resolve_font(name),
         {:ok, bytes} <- File.read(path) do
      serve(conn, bytes, "font/woff2")
    else
      _ ->
        conn
        |> send_resp(404, "")
        |> halt()
    end
  end

  defp serve(conn, body, content_type) do
    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> send_resp(200, body)
    |> halt()
  end

  # Font allowlist — updated per 05-UI-SPEC lines 71-79 (2 weights per
  # family only). Earlier 05-RESEARCH.md drafts at lines 518-526 included
  # 500 and 600 weights; UI-SPEC revision collapsed to 400/700 exclusively.
  @allowed_fonts ~w(
    inter-400.woff2 inter-700.woff2
    inter-tight-400.woff2 inter-tight-700.woff2
    ibm-plex-mono-400.woff2 ibm-plex-mono-700.woff2
  )

  defp resolve_font(name) when name in @allowed_fonts do
    {:ok, Path.join([:code.priv_dir(:mailglass_admin), "static", "fonts", name])}
  end

  defp resolve_font(_), do: :error
end
