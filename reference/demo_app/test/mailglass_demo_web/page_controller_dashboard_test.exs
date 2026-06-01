defmodule MailglassDemoWeb.PageControllerDashboardTest do
  use MailglassDemo.ConnCase, async: false

  test "GET / renders the Northstar click-around hub", %{conn: conn} do
    html = conn |> get("/") |> html_response(200)

    assert html =~ "Northstar Ops"
    assert html =~ "Preview mailables"
    assert html =~ "Outbound operator"
    assert html =~ "Inbound operator"
    assert html =~ "Reset seed data"

    assert html =~ "Deliveries"
    assert html =~ "Ledger Events"
    assert html =~ "Inbound Records"
    assert html =~ "Suppressions"

    assert html =~ ~s(href="/dev/mail")
    assert html =~ ~s(href="/demo/login?return_to=/ops/mail?tenant_id=northstar")
    assert html =~ ~s(href="/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar")

    assert html =~
             "Destructive: truncates and reseeds deterministic demo evidence tables for tenant northstar."
  end
end
