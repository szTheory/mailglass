defmodule MailglassAdmin.Controllers.ThemeController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias MailglassAdmin.MountPath
  alias MailglassAdmin.Theme

  def cookie_name, do: Theme.cookie_name()

  def set(conn, %{"theme" => theme} = params) do
    conn = fetch_query_params(conn)
    mount_path = mount_path(conn.request_path)

    return_to =
      sanitized_return_to(params["return_to"] || conn.query_params["return_to"], mount_path)

    conn
    |> persist_theme(theme, mount_path)
    |> redirect(to: return_to)
  end

  defp persist_theme(conn, theme, mount_path) when theme in ["light", "dark"] do
    conn
    |> put_resp_cookie(Theme.cookie_name(), theme, Theme.cookie_opts())
    |> delete_legacy_theme_cookies(mount_path)
  end

  defp persist_theme(conn, "system", mount_path) do
    conn
    |> put_resp_cookie(Theme.cookie_name(), Theme.cookie_value(:system), Theme.cookie_opts())
    |> delete_legacy_theme_cookies(mount_path)
  end

  defp persist_theme(conn, _theme, mount_path), do: persist_theme(conn, "system", mount_path)

  defp delete_legacy_theme_cookies(conn, mount_path) do
    conn
    |> delete_resp_cookie(Theme.legacy_cookie_name(), Theme.cookie_opts())
    |> delete_resp_cookie(Theme.legacy_cookie_name(), Theme.legacy_cookie_opts(mount_path))
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
      true -> Theme.strip_theme_query(return_to)
    end
  end
end
