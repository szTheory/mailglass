defmodule MailglassAdmin.Theme do
  @moduledoc false

  alias MailglassAdmin.MountPath

  @cookie_name "mailglass_admin_theme_v2"
  @legacy_cookie_name "mailglass_admin_theme"
  @max_age 60 * 60 * 24 * 365

  @type choice :: :system | :light | :dark

  def cookie_name, do: @cookie_name
  def legacy_cookie_name, do: @legacy_cookie_name

  def cookie_opts do
    [
      path: "/",
      max_age: @max_age,
      http_only: true,
      same_site: "Lax"
    ]
  end

  def legacy_cookie_opts(path) when is_binary(path) and path != "" do
    cookie_opts()
    |> Keyword.put(:path, path)
  end

  def legacy_cookie_opts(_path), do: cookie_opts()

  def cookie_choice(value) when value in ["dark", "mailglass-dark"], do: :dark
  def cookie_choice(value) when value in ["light", "mailglass-light"], do: :light
  def cookie_choice(_value), do: :system

  def query_choice(value) when value in ["dark", "mailglass-dark"], do: {:ok, :dark}
  def query_choice(value) when value in ["light", "mailglass-light"], do: {:ok, :light}
  def query_choice("system"), do: {:ok, :system}
  def query_choice(_value), do: :error

  def segment(:dark), do: "dark"
  def segment(:light), do: "light"
  def segment(:system), do: "system"

  def segment(value) when value in ["dark", "light", "system"], do: value
  def segment(_value), do: "system"

  def cookie_value(:dark), do: "dark"
  def cookie_value(:light), do: "light"
  def cookie_value(:system), do: "system"

  def data_theme(:dark), do: "mailglass-dark"
  def data_theme(:light), do: "mailglass-light"
  def data_theme(_choice), do: nil

  def persistence_path(uri, theme) when is_binary(uri) do
    parsed = URI.parse(uri)
    path = parsed.path || "/"
    mount_base = MountPath.base(path)
    return_to = path |> append_query_without_theme(parsed.query || "")

    String.trim_trailing(mount_base, "/") <>
      "/theme/" <> segment(theme) <> "?" <> URI.encode_query([{"return_to", return_to}])
  end

  def legacy_query_redirect_path(params, uri) when is_map(params) and is_binary(uri) do
    if Map.has_key?(params, "theme") do
      parsed = URI.parse(uri)
      path = parsed.path || "/"
      return_to = path |> append_query_without_theme(parsed.query || "")

      case query_choice(Map.get(params, "theme")) do
        {:ok, choice} -> persistence_path(return_to, segment(choice))
        :error -> return_to
      end
    end
  end

  def legacy_query_redirect_path(_params, _uri), do: nil

  def strip_theme_query(path_or_uri) when is_binary(path_or_uri) do
    parsed = URI.parse(path_or_uri)
    path = parsed.path || "/"
    append_query_without_theme(path, parsed.query || "")
  end

  defp append_query_without_theme(path, query) do
    query =
      query
      |> URI.query_decoder()
      |> Enum.reject(fn {key, _value} -> key == "theme" end)
      |> URI.encode_query()

    case query do
      "" -> path
      query -> path <> "?" <> query
    end
  end
end
