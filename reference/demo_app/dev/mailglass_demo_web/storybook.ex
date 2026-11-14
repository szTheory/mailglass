defmodule MailglassDemoWeb.Storybook do
  @moduledoc """
  Dev-only PhoenixStorybook backend for the mailglass_admin component review surface.

  Hand-written per PROJECT D-07 — `mix phx.gen.storybook` is deliberately NOT run
  because the default scaffold introduces a `storybook.css`/`storybook.js` esbuild
  watcher build path. This phase reuses the already-served committed admin bundle as
  the sandbox stylesheet instead, so the zero-Node adopter guarantee and the
  `priv/static/app.css` drift gate (`mix verify.preview`) are both preserved.

  ## Sandbox styling (D-07)

  `css_path` is a REMOTE URL string — the absolute path of the served committed admin
  bundle route, `/dev/mail/css-<md5>`. PhoenixStorybook emits it as a plain `<link>` in
  the sandbox iframe; it is NOT a filesystem path and NOT a new asset build. The md5 is
  resolved at compile time from `MailglassAdmin.Controllers.Assets.css_hash/0` (the same
  hash the live admin layout uses), so the URL cache-busts whenever the bundle changes.

  `sandbox_class: "mg-admin-root"` matches the class the admin shell roots carry
  (`operator/shell.ex`, `preview_live.ex`), so component CSS scoped under `.mg-admin-root`
  resolves inside the explorer. Retained quick-view and Delivery investigation stories
  explicitly own their local
  `data-theme` (`mailglass-light`/`mailglass-dark`) and selected preference; they never
  write the authenticated host preference or use a CSS class→data-theme alias.

  `js_path` combines production hook definitions with a Demo-only adapter that gives
  each retained quick-view and Delivery investigation iframe root explicit
  Light/Dark/System ownership. The adapter uses `matchMedia` locally and creates no
  socket or host preference. Its guarded hash
  route is declared only while the dev-only PhoenixStorybook dependency is available;
  no Admin bootstrap or esbuild watcher is added to `config/dev.exs`.

  This module and every `*.story.exs` live in the DEMO app, never under
  `mailglass_admin/lib/` (D-06) — the admin package's `:files` glob would otherwise
  tarball them to adopters and break their compile, since `phoenix_storybook` is a
  dev-only dep absent from the shipped package.
  """

  @theme_adapter_js ~S"""
  window.storybook = window.storybook || {}
  window.storybook.Hooks = window.MailglassAdminHooks

  ;(() => {
    const ownerSelectors = [
      '[data-theme-owner="quick-view-story"]',
      '[data-theme-owner="delivery-investigation-story"]'
    ]
    const ownerSelector = ownerSelectors.join(",")
    const media = window.matchMedia("(prefers-color-scheme: dark)")
    const activeRoots = new Map()

    function osPreference() {
      return media.matches ? "dark" : "light"
    }

    function applyPreference(root, preference) {
      const selected = ["light", "dark", "system"].includes(preference) ? preference : "system"
      const os = osPreference()
      const resolved = selected === "system" ? os : selected
      root.dataset.themePreference = selected
      root.dataset.themeOs = os
      root.dataset.themeResolved = resolved
      root.dataset.theme = resolved === "dark" ? "mailglass-dark" : "mailglass-light"
    }

    function initialize(root) {
      if (activeRoots.has(root)) return

      const preferenceName = root.dataset.themeOwner === "delivery-investigation-story"
        ? "delivery-investigation-review-theme"
        : "quick-view-review-theme"
      const selectedRadio = root.querySelector('input[name="' + preferenceName + '"]:checked')
      const initialPreference = selectedRadio?.value || root.dataset.themePreference || "system"
      const onChange = event => {
        const input = event.target
        if (input instanceof HTMLInputElement && input.name === preferenceName && input.checked) {
          applyPreference(root, input.value)
        }
      }
      const onSystemChange = () => applyPreference(root, root.dataset.themePreference || initialPreference)

      root.addEventListener("change", onChange)
      media.addEventListener("change", onSystemChange)
      activeRoots.set(root, { onChange, onSystemChange })
      applyPreference(root, initialPreference)
    }

    function dispose(root) {
      const listeners = activeRoots.get(root)
      if (!listeners) return
      root.removeEventListener("change", listeners.onChange)
      media.removeEventListener("change", listeners.onSystemChange)
      activeRoots.delete(root)
    }

    function reviewRootsWithin(node) {
      if (!(node instanceof Element)) return []
      return [
        ...(node.matches(ownerSelector) ? [node] : []),
        ...node.querySelectorAll(ownerSelector)
      ]
    }

    function scan() {
      document.querySelectorAll(ownerSelector).forEach(initialize)
    }

    const observer = new MutationObserver(records => {
      for (const record of records) {
        record.removedNodes.forEach(node => reviewRootsWithin(node).forEach(dispose))
        record.addedNodes.forEach(node => reviewRootsWithin(node).forEach(initialize))
      }
    })
    observer.observe(document.documentElement, { childList: true, subtree: true })
    scan()

    window.addEventListener("pagehide", () => {
      observer.disconnect()
      Array.from(activeRoots.keys()).forEach(dispose)
    }, { once: true })
  })();
  """

  @review_hooks MailglassAdmin.Controllers.Assets.hooks_body()
  @review_js @review_hooks <> "\n" <> @theme_adapter_js
  @review_js_hash Base.encode16(:crypto.hash(:md5, @review_js), case: :lower)
  @configured_review_js_hash "d7201408b8ccd6015cc463b47b90d8b1"

  if @review_js_hash != @configured_review_js_hash do
    raise "Update the Storybook review JS path hash to #{@review_js_hash}"
  end

  use PhoenixStorybook,
    otp_app: :mailglass_demo,
    content_path: Path.expand("../../storybook", __DIR__),
    # Remote URL of the served committed admin bundle (D-07). NOT a filesystem path.
    css_path: "/dev/mail/css-" <> MailglassAdmin.Controllers.Assets.css_hash(),
    js_path: "/dev/storybook-review-js-d7201408b8ccd6015cc463b47b90d8b1",
    sandbox_class: "mg-admin-root",
    title: "mailglass admin"

  @doc false
  def js_body, do: @review_js

  @doc false
  def js_hash, do: @review_js_hash

  @doc false
  def init(:js), do: :js

  @doc false
  def call(conn, :js) do
    if conn.path_params["md5"] == @review_js_hash do
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/javascript; charset=utf-8")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> Plug.Conn.send_resp(200, @review_js)
      |> Plug.Conn.halt()
    else
      conn
      |> Plug.Conn.send_resp(404, "")
      |> Plug.Conn.halt()
    end
  end
end
