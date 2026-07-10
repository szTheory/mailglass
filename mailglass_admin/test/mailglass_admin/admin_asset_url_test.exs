defmodule MailglassAdmin.AdminAssetUrlTest do
  @moduledoc """
  First-HTML proof that admin stylesheet hrefs are rooted at the effective
  macro mount path for direct loads and deep links.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}

  @tenant_id "test-tenant"
  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

  @route_cases [
    %{
      name: "preview canonical scenario",
      path: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default",
      mount_root: "/dev/mail",
      access: :public
    },
    %{
      name: "preview canonical scenario query",
      path: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768",
      mount_root: "/dev/mail",
      access: :public
    },
    %{
      name: "preview scenario deep link",
      path: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375",
      mount_root: "/dev/mail",
      access: :public
    },
    %{
      name: "preview render-error deep link",
      path: "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__",
      mount_root: "/dev/mail",
      access: :public
    },
    %{
      name: "gallery direct load",
      path: "/dev/mail/gallery",
      mount_root: "/dev/mail",
      access: :public
    },
    %{
      name: "bare operator direct load",
      path: "/ops/mail",
      mount_root: "/ops/mail",
      access: :operator
    },
    %{
      name: "operator tenant query direct load",
      path: "/ops/mail?tenant_id=test-tenant",
      mount_root: "/ops/mail",
      access: :operator
    },
    %{
      name: "operator filter query deep link",
      path: "/ops/mail?tenant_id=test-tenant&view=deliveries&status=failed",
      mount_root: "/ops/mail",
      access: :operator
    },
    %{
      name: "bare inbound direct load",
      path: "/ops/mail/inbound",
      mount_root: "/ops/mail",
      access: :operator
    },
    %{
      name: "inbound query deep link",
      path: "/ops/mail/inbound?tenant_id=test-tenant&provider=ses",
      mount_root: "/ops/mail",
      access: :operator
    },
    %{
      name: "alternate preview scenario deep link",
      path: "/alt/dev/console/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=768",
      mount_root: "/alt/dev/console",
      access: :public
    },
    %{
      name: "alternate operator query deep link",
      path: "/secure/console?tenant_id=test-tenant&view=deliveries",
      mount_root: "/secure/console",
      access: :operator
    },
    %{
      name: "alternate inbound query deep link",
      path: "/secure/console/inbound?tenant_id=test-tenant&provider=ses",
      mount_root: "/secure/console",
      access: :operator
    }
  ]

  setup %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
    {:ok, conn: conn}
  end

  describe "root-layout stylesheet hrefs on first HTML" do
    for route_case <- @route_cases do
      @route_case route_case

      test "#{route_case.name} emits a mount-rooted stylesheet href", %{conn: conn} do
        %{path: path, mount_root: mount_root} = @route_case

        html =
          conn
          |> conn_for(@route_case)
          |> get(path)
          |> html_response(200)

        href = stylesheet_href!(html)

        assert_stylesheet_href_rooted!(href, mount_root, path)
      end
    end
  end

  defp conn_for(conn, %{access: :public}), do: conn
  defp conn_for(conn, %{access: :operator}), do: operator_conn(conn)

  defp stylesheet_href!(html) do
    {:ok, doc} = Floki.parse_document(html)

    hrefs =
      doc
      |> Floki.find(~s(link[rel="stylesheet"]))
      |> Floki.attribute("href")

    case hrefs do
      [href] ->
        href

      [] ->
        flunk("expected first HTML to contain one root-layout stylesheet link")

      many ->
        flunk("expected one root-layout stylesheet link, got #{inspect(many)}")
    end
  end

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    conn
    |> Plug.Test.init_test_session(%{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
    |> then(fn conn -> Plug.Test.init_test_session(conn, get_session_map(conn)) end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
  end

  defp assert_stylesheet_href_rooted!(href, mount_root, path) do
    expected = Path.join(mount_root, "css-#{MailglassAdmin.Controllers.Assets.css_hash()}")

    assert href == expected,
           "expected #{path} to emit stylesheet href #{expected}, got #{inspect(href)}"

    assert String.starts_with?(href, "/"),
           "stylesheet href must be root-relative, got #{inspect(href)}"

    refute String.starts_with?(href, "//"),
           "stylesheet href must not be protocol-relative, got #{inspect(href)}"

    refute String.contains?(href, "://"),
           "stylesheet href must not be external, got #{inspect(href)}"

    refute String.starts_with?(href, "css-"),
           "stylesheet href must not be bare relative, got #{inspect(href)}"

    path_only = path |> URI.parse() |> Map.fetch!(:path)

    if path_only != mount_root do
      refute String.starts_with?(href, Path.join(path_only, "css-")),
             "stylesheet href must not be relative to nested route #{path_only}, got #{inspect(href)}"
    end

    refute String.contains?(href, "/gallery/css-"),
           "gallery segment leaked into stylesheet href #{inspect(href)}"

    refute String.contains?(href, "/inbound/css-"),
           "inbound segment leaked into stylesheet href #{inspect(href)}"

    refute String.contains?(href, "/__error__/css-"),
           "render-error segment leaked into stylesheet href #{inspect(href)}"

    refute Regex.match?(~r{/MailglassAdmin\.Fixtures\.[^/]+/[^/]+/css-}, href),
           "mailable/scenario segments leaked into stylesheet href #{inspect(href)}"
  end
end
