defmodule MailglassAdmin.Layouts do
  @moduledoc false

  use Phoenix.Component

  # Submodule auto-classifies into the `MailglassAdmin` root boundary
  # declared in `lib/mailglass_admin.ex`; `classify_to:` is reserved for
  # mix tasks and protocol implementations and is not used here.

  # this plan ships `MailglassAdmin.Controllers.Assets`; until then the css/js
  # helpers below fall back to the "pending" placeholders via the runtime
  # `function_exported?/3` guards. Declaring the forward reference here
  # keeps `mix compile --warnings-as-errors` green.
  @compile {:no_warn_undefined, [MailglassAdmin.Controllers.Assets]}

  embed_templates "layouts/*"

  # Asset URL helpers. Phoenix.Component.embed_templates compiles templates
  # at compile time; calling MailglassAdmin.Controllers.Assets.css_hash/0
  # directly inside the HEEx template would fail this plan compile because
  # this plan has not shipped the controller yet. The helpers are evaluated
  # at RENDER time via `<%= css_url() %>`, so the function_exported?/3
  # guard picks up the real hash automatically once this plan lands.
  #
  defp css_url(assigns) do
    if Code.ensure_loaded?(MailglassAdmin.Controllers.Assets) and
         function_exported?(MailglassAdmin.Controllers.Assets, :css_hash, 0) do
      mounted_asset_url(assigns, "css-" <> MailglassAdmin.Controllers.Assets.css_hash())
    else
      mounted_asset_url(assigns, "css-pending.css")
    end
  end

  # `:mount_path` is seeded on every admin socket by
  # `MailglassAdmin.MountPathHook` and flows into the root layout as a socket
  # assign — the only mount-aware value reliably available here as of
  # phoenix_live_view 1.2, where the root layout no longer receives `@conn`.
  defp mounted_asset_url(%{mount_path: mount_path}, filename) when is_binary(mount_path) do
    Path.join(mount_path, filename)
  end

  # Fallback for older LiveView (1.1.x) renders that still pass `@conn`.
  defp mounted_asset_url(%{conn: %Plug.Conn{request_path: request_path}}, filename) do
    request_path
    |> asset_mount_path()
    |> Path.join(filename)
  end

  defp mounted_asset_url(_assigns, filename), do: filename

  defp asset_mount_path(request_path), do: MailglassAdmin.MountPath.base(request_path)

  defp js_inline do
    if Code.ensure_loaded?(MailglassAdmin.Controllers.Assets) and
         function_exported?(MailglassAdmin.Controllers.Assets, :js_body, 0) do
      MailglassAdmin.Controllers.Assets.js_body()
    else
      ""
    end
  end

  # Prefer the LiveView's parsed theme socket assign (set by PreviewLive and
  # flowing into the root layout in every LiveView version); fall back to the
  # conn query string on older (1.1.x) renders that still expose `@conn`.
  defp root_theme(%{admin_chrome_theme: theme}) when theme in [:dark, :light],
    do: explicit_theme_attr(Atom.to_string(theme))

  defp root_theme(%{conn: %Plug.Conn{query_string: query_string}}) do
    query_string
    |> URI.decode_query()
    |> Map.get("theme")
    |> explicit_theme_attr()
  end

  defp root_theme(_assigns), do: nil

  defp explicit_theme_attr(theme) when theme in ["dark", "mailglass-dark"], do: "mailglass-dark"
  defp explicit_theme_attr(theme) when theme in ["light", "mailglass-light"], do: "mailglass-light"
  defp explicit_theme_attr(_theme), do: nil
end
