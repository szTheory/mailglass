defmodule MailglassAdmin.Controllers.ThemeController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias MailglassAdmin.MountPath

  @cookie_name "mailglass_admin_theme"
  @max_age 60 * 60 * 24 * 365

  def cookie_name, do: @cookie_name

  def set(conn, %{"theme" => theme} = params) do
    conn = fetch_query_params(conn)
    mount_path = mount_path(conn.request_path)
    return_to = sanitized_return_to(params["return_to"] || conn.query_params["return_to"], mount_path)

    conn
    |> persist_theme(theme, mount_path)
    |> redirect(to: return_to)
  end

  defp persist_theme(conn, theme, mount_path) when theme in ["light", "dark"] do
    put_resp_cookie(conn, @cookie_name, theme, cookie_opts(mount_path))
  end

  defp persist_theme(conn, _theme, mount_path) do
    delete_resp_cookie(conn, @cookie_name, cookie_opts(mount_path))
  end

  defp cookie_opts(path) do
    [
      path: path,
      max_age: @max_age,
      http_only: true,
      same_site: "Lax"
    ]
  end

  defp mount_path(request_path) do
    request_path
    |> String.replace(~r{/theme/[^/]+$}, "")
    |> MountPath.base()
  end

  defp sanitized_return_to(nil, mount_path), do: mount_path
  defp sanitized_return_to("", mount_path), do: mount_path

  defp sanitized_return_to(return_to, mount_path) when is_binary(return_to) do
    parsed = URI.parse(return_to)

    cond do
      parsed.scheme || parsed.host -> mount_path
      String.starts_with?(return_to, "//") -> mount_path
      not String.starts_with?(parsed.path || "", mount_path) -> mount_path
      true -> return_to
    end
  end
end
