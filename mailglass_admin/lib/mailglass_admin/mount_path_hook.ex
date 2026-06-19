defmodule MailglassAdmin.MountPathHook do
  @moduledoc """
  `on_mount` hook that records the absolute mount-base path the admin surface
  is mounted at (`/dev/mail`, `/admin/preview`, `/ops/mail`, …) on the socket
  as `:mount_path`, so the root layout and navigation links can build
  ABSOLUTE URLs.

  It ALSO resolves the admin chrome theme into `:admin_chrome_theme`
  (`:dark | :light | nil`) so the root layout themes correctly on EVERY admin
  surface. URL `?theme=` wins for the current response, then the explicit
  namespaced cookie seeded through the router session callback. `system` is
  always represented by `nil`.

  ## Why this is load-bearing

  As of `phoenix_live_view` 1.2 the root layout no longer receives `@conn` —
  only the rendering LiveView's own socket assigns flow into it (see
  `Phoenix.LiveView.Controller.live_render/3`, which renders the root layout
  with `Map.merge(socket_assigns, …)`). Asset/nav URLs derived from `@conn`
  therefore silently fall back to relative paths, and because the mount path
  has no trailing slash the browser drops its final segment — 404-ing the
  stylesheet (unstyled page) and every sidebar link.

  The mount base is only knowable from the request `uri`, which is available
  in `handle_params` (not `mount`), so this hook attaches a `:handle_params`
  lifecycle hook rather than computing once at mount. It runs for every admin
  surface (preview + operator + inbound) via the Router macro.

  Returns `{:cont, socket}` unconditionally — it only records context and
  never authorizes or halts.

  ## Boundary classification

  Submodule auto-classifies into the `MailglassAdmin` root boundary.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MailglassAdmin.MountPath
  alias Phoenix.LiveView.Socket

  @doc """
  Seeds `:mount_path` and attaches the `:handle_params` hook that keeps it
  current. Accepts any first arg so it works both as a bare module hook
  (`:default`) and a `{module, opts}` hook.
  """
  @spec on_mount(term(), map() | :not_mounted_at_router, map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(_arg, _params, session, socket) do
    cookie_theme = explicit_cookie_theme(session)

    socket =
      socket
      |> assign(:mount_path, nil)
      |> assign(:admin_chrome_theme, cookie_theme)
      |> assign(:admin_chrome_theme_cookie, cookie_theme)
      |> Phoenix.LiveView.attach_hook(:mailglass_mount_path, :handle_params, &put_mount_path/3)

    {:cont, socket}
  end

  defp put_mount_path(params, uri, socket) do
    path = uri |> URI.parse() |> Map.get(:path)

    {:cont,
     socket
     |> assign(:mount_path, MountPath.base(path))
     |> assign(:admin_chrome_theme, resolve_theme(params, socket.assigns[:admin_chrome_theme_cookie]))}
  end

  defp parse_theme(theme) when theme in ["dark", "mailglass-dark"], do: :dark
  defp parse_theme(theme) when theme in ["light", "mailglass-light"], do: :light
  defp parse_theme(_theme), do: nil

  defp explicit_cookie_theme(%{"admin_chrome_theme_cookie" => theme}), do: parse_theme(theme)
  defp explicit_cookie_theme(_session), do: nil

  defp resolve_theme(params, cookie_theme) do
    if Map.has_key?(params, "theme") do
      parse_theme(params["theme"])
    else
      cookie_theme
    end
  end
end
