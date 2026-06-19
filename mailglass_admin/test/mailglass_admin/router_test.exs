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

  @theme_cookie "mailglass_admin_theme"

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
    test "sets explicit light cookie on the mounted operator path and redirects back", %{conn: conn} do
      conn =
        get(
          conn,
          "/ops/mail/theme/light?return_to=" <>
            URI.encode_www_form("/ops/mail?tenant_id=acme&provider=postmark")
        )

      assert redirected_to(conn) == "/ops/mail?tenant_id=acme&provider=postmark"
      [set_cookie] = Plug.Conn.get_resp_header(conn, "set-cookie")
      assert set_cookie =~ "#{@theme_cookie}=light"
      assert set_cookie =~ "path=/ops/mail"
      refute set_cookie =~ "domain="
    end

    test "sets explicit dark cookie on the mounted operator path", %{conn: conn} do
      conn = get(conn, "/ops/mail/theme/dark?return_to=/ops/mail/inbound?tenant_id=acme")

      [set_cookie] = Plug.Conn.get_resp_header(conn, "set-cookie")
      assert set_cookie =~ "#{@theme_cookie}=dark"
      assert set_cookie =~ "path=/ops/mail"
    end

    test "system deletes explicit cookie and redirects to sanitized relative path", %{conn: conn} do
      conn = get(conn, "/ops/mail/theme/system?return_to=/ops/mail?tenant_id=acme")

      assert redirected_to(conn) == "/ops/mail?tenant_id=acme"
      [set_cookie] = Plug.Conn.get_resp_header(conn, "set-cookie")
      assert set_cookie =~ "#{@theme_cookie}="
      assert set_cookie =~ "max-age=0"
      assert set_cookie =~ "path=/ops/mail"
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
        |> get("/dev/mail")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-light">|
    end

    test "explicit dark cookie themes first HTML response without query param", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> get("/dev/mail")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end

    test "system query takes precedence over cookie and emits no root data-theme", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> get("/dev/mail?theme=system")

      html = html_response(conn, 200)
      assert html =~ ~s|<html lang="en">|
      refute html =~ ~s|data-theme="system"|
      refute html =~ ~s|data-theme="mailglass-dark"|
    end

    test "explicit query takes precedence over the cookie", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
        |> get("/dev/mail?theme=light")

      assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-light">|
    end

    test "invalid cookie values resolve to system with no root data-theme", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=sepia")
        |> get("/dev/mail")

      html = html_response(conn, 200)
      assert html =~ ~s|<html lang="en">|
      refute html =~ ~s|data-theme="mailglass-light"|
      refute html =~ ~s|data-theme="mailglass-dark"|
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

      assert Enum.sort(Map.keys(session)) == ["live_session_name", "mailables"],
             "__preview_session__/2 must return exactly the whitelisted keys, got #{inspect(Map.keys(session))}"
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
               # D-48-07: compile-time opt (an atom, never cookie-sourced) surfaced
               # so the operator LiveView can reflect declared inbound routes for the
               # routing-trace card. nil here because no `inbound_router` opt is passed.
               "inbound_router" => nil
             }
    end

    @tag :session_isolation
    test "operator session preserves nil optional session keys while requiring subject_id", %{conn: conn} do
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
