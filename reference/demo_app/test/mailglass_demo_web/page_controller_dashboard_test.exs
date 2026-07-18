defmodule MailglassDemoWeb.PageControllerDashboardTest do
  use MailglassDemo.ConnCase, async: false

  test "GET / renders the AtlasDesk click-around hub", %{conn: conn} do
    html = conn |> get("/") |> html_response(200)

    assert html =~ "Explore Mailglass in a working app"
    assert html =~ "AtlasDesk"
    assert html =~ "Preview emails"
    assert html =~ "Trace a sent email"
    assert html =~ "Follow an inbound message"
    assert html =~ "Reset seed data"

    assert html =~ "Email deliveries"
    assert html =~ "Email events"
    assert html =~ "Received emails"
    assert html =~ "Suppressed addresses"

    assert html =~ ~s(href="/dev/mail")
    assert html =~ ~s(href="/demo/login?return_to=/ops/mail?tenant_id=northstar")
    assert html =~ ~s(href="/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar")

    assert html =~
             "Destructive: restores the AtlasDesk demo evidence for the Northstar Logistics account."
  end
end
