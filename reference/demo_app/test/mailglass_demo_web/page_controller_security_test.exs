defmodule MailglassDemoWeb.PageControllerSecurityTest do
  use MailglassDemo.ConnCase, async: false

  alias MailglassDemo.DemoData

  setup do
    previous_token = System.get_env("DEMO_EVIDENCE_RESET_TOKEN")
    System.put_env("DEMO_EVIDENCE_RESET_TOKEN", "test-demo-reset-token")

    on_exit(fn ->
      if previous_token do
        System.put_env("DEMO_EVIDENCE_RESET_TOKEN", previous_token)
      else
        System.delete_env("DEMO_EVIDENCE_RESET_TOKEN")
      end
    end)
  end

  test "login only redirects to local operator paths", %{conn: conn} do
    conn = get(conn, "/demo/login", %{"return_to" => "//evil.example/phish"})

    assert redirected_to(conn) == "/ops/mail?tenant_id=#{DemoData.tenant_id()}"
  end

  test "login preserves allowed operator paths", %{conn: conn} do
    conn = get(conn, "/demo/login", %{"return_to" => "/ops/mail/inbound?tenant_id=northstar"})

    assert redirected_to(conn) == "/ops/mail/inbound?tenant_id=northstar"
  end

  test "evidence reset requires the configured reset token", %{conn: conn} do
    conn = post(conn, "/demo/evidence/reset")

    assert json_response(conn, 403) == %{"error" => "forbidden"}
  end

  test "evidence reset accepts the configured reset token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("x-mailglass-demo-reset-token", "test-demo-reset-token")
      |> post("/demo/evidence/reset")

    assert %{
             "status" => "ok",
             "warning" => "Destructive demo reset endpoint: truncates and reseeds demo evidence tables."
           } = json_response(conn, 200)
  end
end
