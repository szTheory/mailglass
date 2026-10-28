defmodule MailglassAdmin.Phase177ReturnNavigationTest do
  @moduledoc """
  Phase 177 UXF-10 tracer: Operator -> Preview -> Operator keeps the Account
  through host-configured navigation only (D-01..D-06).

  Hrefs are compared as decoded query lists, never raw strings, because HEEx
  renders `&amp;`.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase177

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @tenant_id "test-tenant"
  @preview_base "/dev/mail"

  describe "Phase 177 operator mints the Preview return context" do
    test "Phase 177 Health mints return_surface=overview in both nav layouts", %{conn: conn} do
      {:ok, _view, html} = live(operator_conn(conn), "/ops/mail?tenant_id=tenant-b")

      for layout <- ["sidebar", "mobile"] do
        href = preview_href(html, layout)
        {path, pairs} = decode(href)

        assert path == @preview_base

        assert Enum.sort(pairs) == [
                 {"return_surface", "overview"},
                 {"return_tenant_id", "tenant-b"}
               ]

        refute List.keymember?(pairs, "tenant_id", 0)
      end
    end

    test "Phase 177 Deliveries mints return_surface=deliveries", %{conn: conn} do
      {:ok, _view, html} =
        live(operator_conn(conn), "/ops/mail?tenant_id=tenant-b&view=deliveries")

      {path, pairs} = decode(preview_href(html, "sidebar"))

      assert path == @preview_base

      assert Enum.sort(pairs) == [
               {"return_surface", "deliveries"},
               {"return_tenant_id", "tenant-b"}
             ]
    end

    test "Phase 177 Inbound mints return_surface=inbound", %{conn: conn} do
      {:ok, _view, html} = live(operator_conn(conn), "/ops/mail/inbound?tenant_id=tenant-b")

      {path, pairs} = decode(preview_href(html, "sidebar"))

      assert path == @preview_base
      assert Enum.sort(pairs) == [{"return_surface", "inbound"}, {"return_tenant_id", "tenant-b"}]
    end

    test "Phase 177 with no Account selected the Preview href is the configured path", %{
      conn: conn
    } do
      {:ok, _view, html} = live(operator_conn(conn), "/ops/mail")

      assert preview_href(html, "sidebar") == @preview_base
      assert preview_href(html, "mobile") == @preview_base
    end
  end

  describe "Phase 177 Preview keeps the context across the index redirect" do
    test "Phase 177 index redirect keeps return_surface and return_tenant_id", %{conn: conn} do
      conn = preview_conn(conn)

      assert {:error, {:redirect, %{to: to}}} =
               live(conn, @preview_base <> "?return_surface=overview&return_tenant_id=tenant-b")

      {path, pairs} = decode(to)
      assert String.starts_with?(path, @preview_base <> "/")
      assert {"return_surface", "overview"} in pairs
      assert {"return_tenant_id", "tenant-b"} in pairs
    end

    test "Phase 177 index redirect without context stays byte-identical", %{conn: conn} do
      conn = preview_conn(conn)

      assert {:error, {:redirect, %{to: to}}} = live(conn, @preview_base)
      assert to =~ ~r{^/dev/mail/[^?]+\?width=\d+$}
    end

    test "Phase 177 Back to Health is first in nav and names no Account", %{conn: conn} do
      conn = preview_conn(conn)

      {:error, {:redirect, %{to: to}}} =
        live(conn, @preview_base <> "?return_surface=overview&return_tenant_id=tenant-b")

      {:ok, _view, html} = live(conn, to)
      {:ok, doc} = Floki.parse_fragment(html)

      links =
        Floki.find(
          doc,
          ~s([data-testid="surface-nav-sidebar"][aria-label="Mailglass sections"] a)
        )

      first = hd(links)
      assert Floki.attribute(first, "data-testid") == ["preview-return-link"]
      assert first |> Floki.text() |> String.trim() == "Back to Health"
      assert Floki.attribute(first, "href") == ["/ops/mail?tenant_id=tenant-b"]

      # The id appears only inside href attribute values.
      stripped = strip_href_values(html)
      refute stripped =~ "tenant-b"
    end

    test "Phase 177 Back to Deliveries and Back to Inbound use the configured entries", %{
      conn: conn
    } do
      conn = preview_conn(conn)

      for {surface, label, href} <- [
            {"deliveries", "Back to Deliveries", "/ops/mail?tenant_id=tenant-b&view=deliveries"},
            {"inbound", "Back to Inbound", "/ops/mail/inbound?tenant_id=tenant-b"}
          ] do
        {:error, {:redirect, %{to: to}}} =
          live(conn, @preview_base <> "?return_surface=#{surface}&return_tenant_id=tenant-b")

        {:ok, _view, html} = live(conn, to)
        {:ok, doc} = Floki.parse_fragment(html)

        [first | _] = Floki.find(doc, ~s([data-testid="surface-nav-sidebar"] a))
        assert first |> Floki.text() |> String.trim() == label
        assert decode(hd(Floki.attribute(first, "href"))) == decode(href)
      end
    end

    test "Phase 177 tampered params render direct entry without a Back link", %{conn: conn} do
      conn = preview_conn(conn)
      {:error, {:redirect, %{to: to}}} = live(conn, @preview_base)

      for query <- [
            "return_surface=evil&return_tenant_id=tenant-b",
            "return_surface=overview",
            "return_surface=overview&return_tenant_id=",
            "return_surface[]=overview&return_tenant_id=tenant-b"
          ] do
        {:ok, _view, html} = live(conn, base_without_query(to) <> "?width=768&" <> query)
        refute html =~ "preview-return-link"
        refute html =~ "tenant-b"
      end
    end

    test "Phase 177 arrival on the Back link re-enters the operator with the Account", %{
      conn: conn
    } do
      {:error, {:redirect, %{to: to}}} =
        live(
          preview_conn(conn),
          @preview_base <> "?return_surface=overview&return_tenant_id=tenant-b"
        )

      {:ok, _view, preview_html} = live(preview_conn(conn), to)
      {:ok, doc} = Floki.parse_fragment(preview_html)

      back_href =
        doc
        |> Floki.find(~s([data-testid="preview-return-link"]))
        |> hd()
        |> Floki.attribute("href")
        |> hd()

      {:ok, view, _html} = live(operator_conn(conn), back_href)

      assert has_element?(view, ~s([data-testid="operator-account-label"]), "tenant-b")
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp preview_conn(conn) do
    Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
  end

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    base = %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    }

    Plug.Test.init_test_session(conn, Map.merge(base, session))
  end

  defp preview_href(html, layout) do
    {:ok, doc} = Floki.parse_fragment(html)

    doc
    |> Floki.find(~s([data-testid="surface-nav-#{layout}"] a))
    |> Enum.find(fn link -> link |> Floki.text() |> String.trim() == "Preview" end)
    |> Floki.attribute("href")
    |> hd()
  end

  defp decode(href) do
    uri = URI.parse(href)
    {uri.path, uri.query |> Kernel.||("") |> URI.query_decoder() |> Enum.to_list()}
  end

  defp base_without_query(path), do: path |> String.split("?") |> hd()

  defp strip_href_values(html) do
    Regex.replace(~r/href="[^"]*"/, html, ~s(href=""))
  end
end
