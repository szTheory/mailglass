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

  describe "Phase 177 context survives every Preview URL builder" do
    @scenario_base "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
    @return_query "return_surface=deliveries&return_tenant_id=tenant-b"

    test "Phase 177 width patch keeps both return params", %{conn: conn} do
      {:ok, view, _html} =
        live(preview_conn(conn), @scenario_base <> "?width=768&" <> @return_query)

      render_click(view, "set_device", %{"width" => "375"})
      path = assert_patch(view)

      {patched_path, pairs} = decode(path)
      assert patched_path == @scenario_base

      assert Enum.sort(pairs) == [
               {"return_surface", "deliveries"},
               {"return_tenant_id", "tenant-b"},
               {"width", "375"}
             ]

      assert has_element?(view, ~s([data-testid="preview-return-link"]))
    end

    test "Phase 177 width patch twice keeps each return key once", %{conn: conn} do
      {:ok, view, _html} =
        live(preview_conn(conn), @scenario_base <> "?width=768&" <> @return_query)

      render_click(view, "set_device", %{"width" => "375"})
      first = assert_patch(view)
      render_click(view, "set_device", %{"width" => "375"})
      second = assert_patch(view)

      assert first == second

      {_path, pairs} = decode(second)
      keys = Enum.map(pairs, &elem(&1, 0))

      for key <- ["width", "return_surface", "return_tenant_id"] do
        assert Enum.count(keys, &(&1 == key)) == 1
      end

      assert has_element?(view, ~s([data-testid="preview-return-link"]))
    end

    test "Phase 177 width patch without context stays width only", %{conn: conn} do
      {:ok, view, _html} = live(preview_conn(conn), @scenario_base <> "?width=768")

      render_click(view, "set_device", %{"width" => "375"})
      assert_patch(view, @scenario_base <> "?width=375")
      refute has_element?(view, ~s([data-testid="preview-return-link"]))
    end

    test "Phase 177 scenario links and broken link carry both return params", %{conn: conn} do
      {:ok, view, html} =
        live(preview_conn(conn), @scenario_base <> "?width=768&" <> @return_query)

      {:ok, doc} = Floki.parse_fragment(html)

      hrefs =
        doc
        |> Floki.find("a[data-phx-link=patch]")
        |> Enum.flat_map(&Floki.attribute(&1, "href"))
        |> Enum.filter(&String.starts_with?(&1, @preview_base <> "/"))

      assert hrefs != []

      for href <- hrefs do
        {_path, pairs} = decode(href)
        assert {"return_surface", "deliveries"} in pairs, href
        assert {"return_tenant_id", "tenant-b"} in pairs, href
      end

      assert Enum.any?(hrefs, &String.contains?(&1, "__error__"))
      assert render(view) =~ "preview-return-link"
    end

    test "Phase 177 scenario links stay byte-identical without context", %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), @scenario_base <> "?width=768")
      {:ok, doc} = Floki.parse_fragment(html)

      hrefs =
        doc
        |> Floki.find("a[data-phx-link=patch]")
        |> Enum.flat_map(&Floki.attribute(&1, "href"))
        |> Enum.filter(&String.starts_with?(&1, @preview_base <> "/"))

      assert hrefs != []
      refute Enum.any?(hrefs, &String.contains?(&1, "return_"))
      assert (@scenario_base <> "?width=768") in hrefs
    end

    test "Phase 177 nav items resolve to their own configured entries with the Account", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live(preview_conn(conn), @scenario_base <> "?width=768&" <> @return_query)

      for layout <- ["sidebar", "mobile"] do
        assert nav_href(html, layout, "Health") == "/ops/mail?tenant_id=tenant-b"

        assert nav_href(html, layout, "Deliveries") ==
                 "/ops/mail?tenant_id=tenant-b&view=deliveries"

        assert nav_href(html, layout, "Inbound") == "/ops/mail/inbound?tenant_id=tenant-b"

        {path, pairs} = decode(nav_href(html, layout, "Preview"))
        assert path == @preview_base

        assert Enum.sort(pairs) == [
                 {"return_surface", "deliveries"},
                 {"return_tenant_id", "tenant-b"}
               ]
      end
    end

    test "Phase 177 nav items are the static host paths on direct entry", %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), @scenario_base <> "?width=768")

      assert nav_href(html, "sidebar", "Health") == "/ops/mail?tenant_id=browser-tenant"

      assert nav_href(html, "sidebar", "Deliveries") ==
               "/ops/mail?tenant_id=browser-tenant&view=deliveries"

      assert nav_href(html, "sidebar", "Inbound") == "/ops/mail/inbound?tenant_id=browser-tenant"
      assert nav_href(html, "sidebar", "Preview") == @preview_base
    end

    test "Phase 177 theme round trip keeps the Back link", %{conn: conn} do
      {:ok, view, _html} =
        live(preview_conn(conn), @scenario_base <> "?width=768&" <> @return_query)

      render_click(view, "set_theme", %{"theme" => "dark"})
      {to, _flash} = assert_redirect(view)

      {theme_path, pairs} = decode(to)
      assert theme_path == @preview_base <> "/theme/dark"
      {"return_to", return_to} = List.keyfind(pairs, "return_to", 0)

      {return_path, return_pairs} = decode(return_to)
      assert return_path == @scenario_base
      assert {"return_surface", "deliveries"} in return_pairs
      assert {"return_tenant_id", "tenant-b"} in return_pairs

      themed_conn = get(preview_conn(conn), to)
      location = redirected_to(themed_conn)
      assert decode(location) == decode(return_to)

      {:ok, _view, html} = live(recycle(themed_conn), location)

      {:ok, doc} = Floki.parse_fragment(html)
      [first | _] = Floki.find(doc, ~s([data-testid="surface-nav-sidebar"] a))
      assert first |> Floki.text() |> String.trim() == "Back to Deliveries"
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

  defp nav_href(html, layout, label) do
    {:ok, doc} = Floki.parse_fragment(html)

    doc
    |> Floki.find(~s([data-testid="surface-nav-#{layout}"] a))
    |> Enum.find(fn link -> link |> Floki.text() |> String.trim() == label end)
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
