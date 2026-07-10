defmodule MailglassAdmin.RouterTest do
  @moduledoc """
  RED-by-default coverage for PREV-02: the `mailglass_admin_routes/2` macro
  and the `__session__/2` whitelisted session callback.

  Plan 03 lands `MailglassAdmin.Router` with the macro expansion from
  05-RESEARCH.md §"Pattern 1" (lines 348-453) and the CONTEXT D-08 /
  Oban-Web-style `__session__/2` callback that NEVER passes the adopter's
  `conn.private.plug_session` through.
  """

  use MailglassAdmin.EndpointCase, async: false

  @theme_cookie MailglassAdmin.Theme.cookie_name()
  @legacy_theme_cookie MailglassAdmin.Theme.legacy_cookie_name()

  describe "router macro expansion" do
    test "keeps preview routes isolated from the production operator mount" do
      routes = MailglassAdmin.TestAdopter.Router.__routes__()

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/css-:md5"
             end),
             "expected GET /dev/mail/css-:md5 asset route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/js-:md5"
             end),
             "expected GET /dev/mail/js-:md5 asset route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/fonts/:name"
             end),
             "expected GET /dev/mail/fonts/:name asset route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/logo.svg"
             end),
             "expected GET /dev/mail/logo.svg asset route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail"
             end),
             "expected LIVE /dev/mail index route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/:mailable/:scenario"
             end),
             "expected LIVE /dev/mail/:mailable/:scenario show route"

      refute Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/dev/mail/operator"
             end),
             "preview mount should no longer ship the operator route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/ops/mail"
             end),
             "expected LIVE /ops/mail operator route"

      assert Enum.any?(routes, fn r ->
               r.verb == :get and r.path == "/ops/mail/theme/:theme"
             end),
             "expected GET /ops/mail/theme/:theme persistence route"
    end
  end

  describe "theme persistence route" do
    test "sets explicit light cookie on the root path and redirects back", %{
      conn: conn
    } do
      conn =
        get(
          conn,
          "/ops/mail/theme/light?return_to=" <>
            URI.encode_www_form("/ops/mail?tenant_id=acme&provider=postmark")
        )

      assert redirected_to(conn) == "/ops/mail?tenant_id=acme&provider=postmark"
      set_cookies = Plug.Conn.get_resp_header(conn, "set-cookie")

      assert Enum.any?(set_cookies, fn cookie ->
               cookie =~ "#{@theme_cookie}=light" and cookie =~ "path=/" and
                 not String.contains?(cookie, "domain=")
             end)

      assert Enum.any?(set_cookies, fn cookie ->
               cookie =~ "#{@legacy_theme_cookie}=" and cookie =~ "max-age=0" and
                 cookie =~ "path=/ops/mail"
             end)
    end

    test "sets explicit dark cookie on the root path", %{conn: conn} do
      conn = get(conn, "/ops/mail/theme/dark?return_to=/ops/mail/inbound?tenant_id=acme")

      set_cookies = Plug.Conn.get_resp_header(conn, "set-cookie")

      assert Enum.any?(set_cookies, fn cookie ->
               cookie =~ "#{@theme_cookie}=dark" and cookie =~ "path=/"
             end)
    end

    test "system stores explicit system preference and redirects to sanitized relative path", %{
      conn: conn
    } do
      conn = get(conn, "/ops/mail/theme/system?return_to=/ops/mail?tenant_id=acme")

      assert redirected_to(conn) == "/ops/mail?tenant_id=acme"
      set_cookies = Plug.Conn.get_resp_header(conn, "set-cookie")

      assert Enum.any?(set_cookies, fn cookie ->
               cookie =~ "#{@theme_cookie}=system" and cookie =~ "path=/"
             end)

      assert Enum.any?(set_cookies, fn cookie ->
               cookie =~ "#{@legacy_theme_cookie}=" and cookie =~ "max-age=0" and
                 cookie =~ "path=/ops/mail"
             end)
    end

    test "strips legacy theme query from return_to", %{conn: conn} do
      conn =
        get(
          conn,
          "/ops/mail/theme/dark?return_to=" <>
            URI.encode_www_form("/ops/mail?tenant_id=acme&theme=light")
        )

      assert redirected_to(conn) == "/ops/mail?tenant_id=acme"
    end

    test "rejects external return urls", %{conn: conn} do
      conn = get(conn, "/ops/mail/theme/dark?return_to=https://evil.example/phish")

      assert redirected_to(conn) == "/ops/mail"
    end
  end

  describe "root layout theme persistence" do
    test "explicit light cookie themes first HTML response without query param", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=light")
        |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-light">|
    end

    test "explicit dark cookie themes first HTML response without query param", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end

    test "legacy cookie name still themes first HTML response", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@legacy_theme_cookie}=light")
        |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-light">|
    end

    test "invalid cookie values resolve to system with no root data-theme", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=sepia")
        |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      html = html_response(conn, 200)
      assert html =~ ~s|<html lang="en">|
      refute html =~ ~r|<html[^>]+data-theme=|
    end
  end

  describe "whitelisted session callbacks" do
    @tag :session_isolation
    test "preview session never returns adopter session keys", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => 42,
          "csrf_token" => "secret"
        })

      session =
        MailglassAdmin.Router.__preview_session__(conn,
          mailables: :auto_scan,
          live_session_name: :test_session
        )

      refute Map.has_key?(session, "current_user_id"),
             "adopter `current_user_id` must never leak into admin session"

      refute Map.has_key?(session, "csrf_token"),
             "adopter `csrf_token` must never leak into admin session"

      assert Enum.sort(Map.keys(session)) == [
               "admin_chrome_theme_cookie",
               "live_session_name",
               "mailables",
               "navigation"
             ],
             "__preview_session__/2 must return exactly the whitelisted keys, got #{inspect(Map.keys(session))}"

      assert session["navigation"] == %{}
    end

    test "preview session exposes configured sibling nav paths", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{})

      session =
        MailglassAdmin.Router.__preview_session__(conn,
          mailables: :auto_scan,
          live_session_name: :test_session,
          navigation: [
            overview_path: "/ops/mail?tenant_id=acme",
            deliveries_path: "/ops/mail?tenant_id=acme&view=deliveries",
            inbound_path: "/ops/mail/inbound?tenant_id=acme"
          ]
        )

      assert session["navigation"] == %{
               overview_path: "/ops/mail?tenant_id=acme",
               deliveries_path: "/ops/mail?tenant_id=acme&view=deliveries",
               inbound_path: "/ops/mail/inbound?tenant_id=acme"
             }
    end

    @tag :session_isolation
    test "operator session only returns the explicit auth whitelist", %{conn: conn} do
      recent_auth_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => "operator-1",
          "tenant_id" => "tenant-a",
          "auth_method" => "password",
          "recent_auth_at" => recent_auth_at,
          "csrf_token" => "secret"
        })

      session =
        MailglassAdmin.Router.__operator_session__(conn,
          auth: MailglassAdmin.TestOperatorAuth,
          session: [
            subject_id: "current_user_id",
            tenant_id: "tenant_id",
            auth_method: "auth_method",
            recent_auth_at: "recent_auth_at"
          ],
          live_session_name: :mailglass_admin_operator,
          unauthorized_path: "/login",
          on_mount: []
        )

      refute Map.has_key?(session, "current_user_id")
      refute Map.has_key?(session, "csrf_token")

      assert session == %{
               "subject_id" => "operator-1",
               "tenant_id" => "tenant-a",
               "auth_method" => "password",
               "recent_auth_at" => recent_auth_at,
               "live_session_name" => :mailglass_admin_operator,
               "admin_chrome_theme_cookie" => nil,
               "navigation" => %{},
               # D-48-07: compile-time opt (an atom, never cookie-sourced) surfaced
               # so the operator LiveView can reflect declared inbound routes for the
               # routing-trace card. nil here because no `inbound_router` opt is passed.
               "inbound_router" => nil
             }
    end

    @tag :session_isolation
    test "operator session preserves nil optional session keys while requiring subject_id", %{
      conn: conn
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => "operator-2"
        })

      session =
        MailglassAdmin.Router.__operator_session__(conn,
          auth: MailglassAdmin.TestOperatorAuth,
          session: [
            subject_id: "current_user_id",
            tenant_id: nil,
            auth_method: nil,
            recent_auth_at: nil
          ],
          live_session_name: :mailglass_admin_operator,
          unauthorized_path: "/login",
          on_mount: []
        )

      assert session["subject_id"] == "operator-2"
      assert session["tenant_id"] == nil
      assert session["auth_method"] == nil
      assert session["recent_auth_at"] == nil
    end

    test "operator session exposes configured preview nav path", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => "operator-3"
        })

      session =
        MailglassAdmin.Router.__operator_session__(conn,
          auth: MailglassAdmin.TestOperatorAuth,
          session: [
            subject_id: "current_user_id",
            tenant_id: nil,
            auth_method: nil,
            recent_auth_at: nil
          ],
          live_session_name: :mailglass_admin_operator,
          unauthorized_path: "/login",
          on_mount: [],
          navigation: [
            preview_path: "/dev/mail"
          ]
        )

      assert session["navigation"] == %{preview_path: "/dev/mail"}
    end
  end

  describe "router opts validation" do
    test "unknown opts raise ArgumentError at compile time" do
      assert_raise ArgumentError, ~r/invalid opts for mailglass_admin_routes\/2/, fn ->
        Code.eval_string("""
        defmodule InvalidOptsRouter do
          use Phoenix.Router
          import MailglassAdmin.Router

          mailglass_admin_routes "/x", bogus: true
        end
        """)
      end
    end

    test "operator mount accepts tuple-form on_mount hooks and rejects unknown opts" do
      routes = MailglassAdmin.TestAdopter.Router.__routes__()

      assert Enum.any?(routes, &(&1.path == "/ops/mail"))

      assert_raise ArgumentError, ~r/invalid opts for mailglass_operator_routes\/2/, fn ->
        Code.eval_string("""
        defmodule InvalidOperatorOptsRouter do
          use Phoenix.Router
          import Phoenix.LiveView.Router
          import MailglassAdmin.Router

          scope "/ops" do
            pipe_through :browser
            mailglass_operator_routes "/mail", bogus: true
          end
        end
        """)
      end
    end
  end
end
