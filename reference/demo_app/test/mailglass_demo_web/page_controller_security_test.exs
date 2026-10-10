defmodule MailglassDemoWeb.PageControllerSecurityTest do
  use MailglassDemo.ConnCase, async: false

  alias MailglassDemo.DemoData

  setup do
    previous_token = System.get_env("DEMO_EVIDENCE_RESET_TOKEN")
    previous_project_id = System.get_env("DEMO_EVIDENCE_PROJECT_ID")
    System.put_env("DEMO_EVIDENCE_RESET_TOKEN", "test-demo-reset-token")
    System.delete_env("DEMO_EVIDENCE_PROJECT_ID")

    on_exit(fn ->
      if previous_token do
        System.put_env("DEMO_EVIDENCE_RESET_TOKEN", previous_token)
      else
        System.delete_env("DEMO_EVIDENCE_RESET_TOKEN")
      end

      if previous_project_id do
        System.put_env("DEMO_EVIDENCE_PROJECT_ID", previous_project_id)
      else
        System.delete_env("DEMO_EVIDENCE_PROJECT_ID")
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

  test "health keeps its body and omits a missing evidence project identity", %{conn: conn} do
    conn = get(conn, "/health")

    assert response(conn, 200) == "ok"
    refute get_resp_header(conn, "x-mailglass-evidence-project-id") != []
  end

  test "health exposes only a strict disposable evidence project identity", %{conn: conn} do
    System.put_env("DEMO_EVIDENCE_PROJECT_ID", "mailglass-evidence-20261010093046-123-456")

    conn = get(conn, "/health")

    assert response(conn, 200) == "ok"
    assert get_resp_header(conn, "x-mailglass-evidence-project-id") == [
             "mailglass-evidence-20261010093046-123-456"
           ]
  end

  test "health omits malformed evidence project identities", %{conn: conn} do
    System.put_env("DEMO_EVIDENCE_PROJECT_ID", "mailglass-demo")

    conn = get(conn, "/health")

    assert response(conn, 200) == "ok"
    assert get_resp_header(conn, "x-mailglass-evidence-project-id") == []
  end

  test "evidence reset denies requests without the configured reset token", %{conn: conn} do
    System.put_env("DEMO_EVIDENCE_PROJECT_ID", "mailglass-evidence-20261010093046-123-456")

    conn = post(conn, "/demo/evidence/reset")

    assert json_response(conn, 403) == %{"error" => "forbidden"}
  end

  test "evidence reset denies token-only requests without a disposable project marker", %{conn: conn} do
    conn =
      conn
      |> put_req_header("x-mailglass-demo-reset-token", "test-demo-reset-token")
      |> post("/demo/evidence/reset")

    assert json_response(conn, 403) == %{"error" => "forbidden"}
  end

  test "evidence reset denies malformed project markers", %{conn: conn} do
    System.put_env("DEMO_EVIDENCE_PROJECT_ID", "mailglass-demo")

    conn =
      conn
      |> put_req_header("x-mailglass-demo-reset-token", "test-demo-reset-token")
      |> post("/demo/evidence/reset")

    assert json_response(conn, 403) == %{"error" => "forbidden"}
  end

  test "evidence reset accepts the configured token only for a disposable project", %{conn: conn} do
    System.put_env("DEMO_EVIDENCE_PROJECT_ID", "mailglass-evidence-20261010093046-123-456")

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
