defmodule MailglassAdmin.RootThemeOwnershipContractTest do
  @moduledoc """
  BRPIPE-02 required-lane proof: `<html>` is the only owner of the admin theme.

  A nested theme attribute re-declares the whole `--color-*` and `--mg-*` token
  set inside its subtree, so the region repaints with the wrong tokens whenever
  it disagrees with the cookie or the OS scheme. These tests count the theme
  attribute in every dead-render document the admin returns, per theme mode.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @theme_cookie MailglassAdmin.Theme.cookie_name()
  @tenant_id "test-tenant"
  @preview_path "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
  @operator_path "/ops/mail?tenant_id=" <> @tenant_id
  @inbound_path "/ops/mail/inbound?tenant_id=" <> @tenant_id

  # {cookie value (nil = no cookie = system), expected owners, expected root value}
  @modes [
    {"dark", 1, "mailglass-dark"},
    {"light", 1, "mailglass-light"},
    {nil, 0, nil}
  ]

  describe "document-level theme ownership" do
    for {cookie, count, value} <- @modes do
      mode = cookie || "system"

      test "preview show document carries #{count} theme owner for #{mode}", %{conn: conn} do
        {:ok, _view, html} = live(with_theme(conn, unquote(cookie)), @preview_path)
        assert_root_only(html, unquote(count), unquote(value), "preview show")
      end

      test "operator document carries #{count} theme owner for #{mode}", %{conn: conn} do
        conn = conn |> operator_conn() |> with_theme(unquote(cookie))
        {:ok, _view, html} = live(conn, @operator_path)
        assert_root_only(html, unquote(count), unquote(value), "operator")
      end

      test "inbound document carries #{count} theme owner for #{mode}", %{conn: conn} do
        conn = conn |> operator_conn() |> with_theme(unquote(cookie))
        {:ok, _view, html} = live(conn, @inbound_path)
        assert_root_only(html, unquote(count), unquote(value), "inbound")
      end
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp assert_root_only(html, count, value, surface) do
    owners = html |> Floki.parse_document!() |> Floki.find("[data-theme]")
    occurrences = length(Regex.scan(~r/\sdata-theme=/, html))

    assert length(owners) == count and occurrences == count,
           "#{surface}: expected #{count} data-theme owner(s), found #{length(owners)} " <>
             "element(s) and #{occurrences} attribute occurrence(s). " <>
             "Only the root <html> may own the theme."

    case owners do
      [] ->
        :ok

      [{tag, attrs, _children}] ->
        assert tag == "html", "#{surface}: the single theme owner is <#{tag}>, expected <html>"
        assert List.keyfind(attrs, "data-theme", 0) == {"data-theme", value}
    end
  end

  defp with_theme(conn, nil), do: conn

  defp with_theme(conn, cookie),
    do: Plug.Conn.put_req_header(conn, "cookie", "#{@theme_cookie}=#{cookie}")

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
    |> then(fn conn ->
      Plug.Test.init_test_session(conn, Map.merge(get_session_map(conn), session))
    end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
  end
end
