defmodule MailglassAdmin.PostInstallerSmokeTest do
  @moduledoc """
  Closes audit blocker G-4 — `admin_smoke_gate` CI job previously matched
  zero `@tag :admin_smoke` tests, so the gate passed vacuously even when
  the post-installer compile path was broken (the literal G-1 audit
  defect).

  This test exercises the path an adopter sees AFTER `mix mailglass.install`
  runs: the synthetic `MailglassAdmin.TestAdopter.Router` (defined in
  `mailglass_admin/test/support/endpoint_case.ex`) imports
  `MailglassAdmin.Router` and calls `mailglass_admin_routes "/mail"`
  inside a `/dev` scope — exactly the shape the installer's
  `router_mount_snippet/1` emits (per Phase 07.1 Plan 06 task 3).

  An HTTP `get/2` through the synthetic endpoint asserts the macro-
  expanded routes resolve and the LiveView renders without raising
  `UndefinedFunctionError` — the audit's literal G-1 failure mode.
  Marked `@tag :admin_smoke` so the CI gate
  (`.github/workflows/ci.yml` step "Run admin smoke gate") matches it.
  """

  use MailglassAdmin.EndpointCase, async: false

  @tag :admin_smoke
  test "post-installer compile path: GET /dev/mail/ resolves without UndefinedFunctionError",
       %{conn: conn} do
    conn = get(conn, "/dev/mail/")

    assert conn.status in [200, 302],
           "expected /dev/mail/ to render (200) or redirect (302) — got " <>
             "#{conn.status}; this likely means the post-installer compile " <>
             "path is broken (see audit G-1 / Phase 07.1 Plan 06 closure)"
  end

  @tag :admin_smoke
  test "post-installer route table: mailglass_admin_routes macro produces expected GET routes" do
    routes = MailglassAdmin.TestAdopter.Router.__routes__()

    assert Enum.any?(routes, fn r ->
             r.verb == :get and r.path == "/dev/mail/css-:md5"
           end),
           "expected GET /dev/mail/css-:md5 asset route from mailglass_admin_routes macro"

    assert Enum.any?(routes, fn r ->
             r.verb == :get and r.path == "/dev/mail"
           end),
           "expected GET /dev/mail live route from mailglass_admin_routes macro"
  end
end
