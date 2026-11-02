defmodule MailglassAdmin.AssetsTest do
  @moduledoc """
  RED-by-default coverage for PREV-06 asset controller contract: compile-time
  bundle reads, MD5 hash cache-busting, content-type + immutable cache
  headers, font allowlist (path-traversal defense), logo serving.

  Plan 05 lands `MailglassAdmin.Controllers.Assets` per 05-PATTERNS.md §"controllers/assets.ex"
  + 05-RESEARCH.md Pattern 2 (verbatim Phoenix.LiveDashboard.Controllers.Assets
  pattern) and turns these RED tests green.
  """

  use MailglassAdmin.EndpointCase, async: true

  describe "GET /dev/mail/css-<hash>" do
    test "serves app.css with text/css content-type and immutable cache", %{conn: conn} do
      hash = MailglassAdmin.Controllers.Assets.css_hash()
      conn = get(conn, "/dev/mail/css-#{hash}")

      assert conn.status == 200

      content_type = get_resp_header(conn, "content-type") |> List.first()

      assert content_type =~ "text/css",
             "expected content-type to start with text/css, got #{inspect(content_type)}"

      cache_control = get_resp_header(conn, "cache-control") |> List.first()
      assert cache_control == "public, max-age=31536000, immutable"

      assert is_binary(conn.resp_body)

      assert byte_size(conn.resp_body) > 1000,
             "compiled app.css should be > 1KB"
    end
  end

  describe "GET /dev/mail/js-<hash>" do
    test "serves concatenated phoenix.js + phoenix_live_view.js", %{conn: conn} do
      hash = MailglassAdmin.Controllers.Assets.js_hash()
      conn = get(conn, "/dev/mail/js-#{hash}")

      assert conn.status == 200

      assert conn.resp_body =~ "Phoenix",
             "bundled JS must contain phoenix.js exports (look for literal 'Phoenix')"

      assert conn.resp_body =~ "LiveView",
             "bundled JS must contain phoenix_live_view.js exports (look for literal 'LiveView')"
    end
  end

  describe "GET /dev/mail/fonts/<name>" do
    test "serves allowlisted inter-400.woff2 with font/woff2 content-type", %{conn: conn} do
      conn = get(conn, "/dev/mail/fonts/inter-400.woff2")

      assert conn.status == 200

      content_type = get_resp_header(conn, "content-type") |> List.first()

      assert content_type =~ "font/woff2",
             "font content-type must be font/woff2, got #{inspect(content_type)}"
    end

    test "rejects path traversal attempts with 404", %{conn: conn} do
      conn = get(conn, "/dev/mail/fonts/..%2F..%2Fetc%2Fpasswd")

      assert conn.status == 404,
             "font path traversal must return 404 (allowlist rejects non-whitelisted names)"
    end
  end

  describe "GET /dev/mail/logo.svg" do
    test "serves logo with image/svg+xml content-type", %{conn: conn} do
      conn = get(conn, "/dev/mail/logo.svg")

      assert conn.status == 200

      content_type = get_resp_header(conn, "content-type") |> List.first()
      assert content_type =~ "image/svg+xml"
    end
  end

  describe "GET favicon.svg" do
    test "serves the small-size brand mark from both admin mounts", %{conn: conn} do
      favicon = File.read!(Application.app_dir(:mailglass_admin, "priv/static/favicon.svg"))
      hash = MailglassAdmin.Controllers.Assets.favicon_hash()

      assert hash == Base.encode16(:crypto.hash(:md5, favicon), case: :lower)

      for mount <- ["/dev/mail", "/ops/mail", "/alt/dev/console", "/secure/console"] do
        response = get(conn, "#{mount}/favicon.svg?v=#{hash}")

        assert response.status == 200
        assert get_resp_header(response, "content-type") == ["image/svg+xml"]

        assert get_resp_header(response, "cache-control") == [
                 "public, max-age=31536000, immutable"
               ]

        assert response.resp_body == favicon
        assert response.resp_body =~ ~s(viewBox="0 0 16 16")
        assert response.resp_body =~ "prefers-color-scheme: dark"
      end
    end
  end

  describe "shared hook JavaScript" do
    test "serves the same production hook bytes without an Admin socket bootstrap" do
      admin_js = MailglassAdmin.Controllers.Assets.js_body()

      assert admin_js =~ "window.MailglassAdminHooks",
             "Admin JS should register and use the shared production hook asset"

      hooks_body = MailglassAdmin.Controllers.Assets.hooks_body()
      hooks_hash = MailglassAdmin.Controllers.Assets.hooks_hash()

      assert length(:binary.matches(admin_js, hooks_body)) == 1
      assert admin_js =~ "new LiveView.LiveSocket"
      assert admin_js =~ "liveSocket.connect()"
      assert hooks_hash == Base.encode16(:crypto.hash(:md5, hooks_body), case: :lower)

      response =
        Plug.Test.conn(:get, "/dev/storybook-hooks-#{hooks_hash}")
        |> MailglassAdmin.Controllers.Assets.call(MailglassAdmin.Controllers.Assets.init(:hooks))

      assert response.status == 200

      assert get_resp_header(response, "content-type") == [
               "application/javascript; charset=utf-8"
             ]

      assert get_resp_header(response, "cache-control") == [
               "public, max-age=31536000, immutable"
             ]

      assert response.resp_body =~ hooks_body
      assert response.resp_body =~ "window.storybook.Hooks"
      refute response.resp_body =~ "new LiveView.LiveSocket"
      refute response.resp_body =~ "Phoenix.Socket"
      refute response.resp_body =~ "phoenix_live_view.js"
    end
  end
end
