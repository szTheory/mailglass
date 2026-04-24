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

  describe "mailglass_admin_routes/2 macro expansion" do
    test "expands into four asset routes and two LiveView routes at `/dev/mail`" do
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
    end
  end

  describe "__session__/2 whitelisted callback (CONTEXT D-08)" do
    @tag :session_isolation
    test "never returns adopter session keys", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => 42,
          "csrf_token" => "secret"
        })

      session =
        MailglassAdmin.Router.__session__(conn,
          mailables: :auto_scan,
          live_session_name: :test_session
        )

      refute Map.has_key?(session, "current_user_id"),
             "adopter `current_user_id` must never leak into admin session"

      refute Map.has_key?(session, "csrf_token"),
             "adopter `csrf_token` must never leak into admin session"

      assert Enum.sort(Map.keys(session)) == ["live_session_name", "mailables"],
             "__session__/2 must return exactly the whitelisted keys, got #{inspect(Map.keys(session))}"
    end
  end

  describe "mailglass_admin_routes/2 opts validation (CONTEXT D-09)" do
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
  end
end
