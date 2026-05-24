defmodule MailglassAdmin.InboundLiveTest do
  @moduledoc """
  InboundLive shell behaviour (Wave 1, plan 48-02).

  Covers V1 (tenant-required-or-empty + no cross-tenant leak), V5 masking-half
  (recipient masked by default), record selection (push_patch with inbound_id,
  in-place detail render), URL-as-state filters, and the no-selection copy. The
  route mounts in the operator `live_session` (same Operator.Mount + Auth gate as
  OperatorLive), so unauthenticated access is rejected by the existing seam.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.TestSupport.InboundFixtures

  @tenant_id "test-tenant"
  @other_tenant "other-tenant"
  @base_path "/ops/mail/inbound"

  describe "inbound surface" do
    test "renders the no-selection prompt and masks recipients by default (V5)", %{conn: conn} do
      conn = operator_conn(conn)
      %{record: record} = InboundFixtures.seed_matched!(@tenant_id, recipient: "alice@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Recent inbound records"
      assert html =~ ~s(data-testid="inbound-master-detail")
      # V5 masking half: masked by default, raw recipient never rendered.
      assert html =~ "a****@e******.com"
      refute html =~ "alice@example.com"
      # No-selection copy verbatim.
      assert html =~
               "Select an inbound record to inspect its routing, execution timeline, and raw source."

      refute html =~ "Execution timeline"
      # Record id IS rendered (it is not PII) so selection works.
      assert html =~ record.id
    end

    test "blank tenant renders the empty state and leaks no other-tenant id or recipient (V1)", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      # Seed a record under a DIFFERENT tenant; a blank tenant must not surface it.
      %{record: other} =
        InboundFixtures.seed_matched!(@other_tenant, recipient: "secret@elsewhere.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => ""}))

      assert html =~ "No inbound records"

      assert html =~
               "No inbound records match these filters. Clear the filters or wait for the next inbound message."

      # No cross-tenant leak — neither the foreign id nor the foreign recipient.
      refute html =~ other.id
      refute html =~ "secret@elsewhere.com"
      refute html =~ "s*****@e*******.com"
    end

    test "a tenant query returns only that tenant's rows (V1 isolation)", %{conn: conn} do
      conn = operator_conn(conn)

      %{record: mine} = InboundFixtures.seed_matched!(@tenant_id, recipient: "mine@example.com")
      %{record: theirs} = InboundFixtures.seed_matched!(@other_tenant, recipient: "theirs@example.com")

      {:ok, _view, html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      assert html =~ mine.id
      refute html =~ theirs.id
    end

    test "selecting a record renders the detail header + timeline in place with URL state", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      %{record: record} =
        InboundFixtures.seed_matched!(@tenant_id, recipient: "selected@example.com")

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> element("button[phx-value-id='#{record.id}']")
      |> render_click()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "inbound_id" => record.id,
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ ~s(data-testid="inbound-detail-header")
      assert html =~ ~s(data-testid="inbound-timeline")
      assert html =~ "Execution timeline"
      assert html =~ "MyApp.Mailboxes.SupportMailbox"
      # Fresh + replay source badges both appear (V matched seed).
      assert html =~ "Fresh"
      assert html =~ "Replay"
      assert html =~ ~s(aria-selected="true")
      # Detail still masks the recipient.
      assert html =~ "s*******@e******.com"
      refute html =~ "selected@example.com"
    end

    test "filters live in the URL and survive a re-mount", %{conn: conn} do
      conn = operator_conn(conn)

      matching =
        InboundFixtures.seed_matched!(@tenant_id,
          recipient: "match@example.com",
          provider: "mailgun"
        )

      _other =
        InboundFixtures.seed_no_match!(@tenant_id,
          recipient: "skip@example.com",
          provider: "ses"
        )

      {:ok, view, _html} = live(conn, inbound_path(%{"tenant_id" => @tenant_id}))

      view
      |> form("#inbound-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "mailgun",
          "outcome" => "accept",
          "window_hours" => "168",
          "search" => ""
        }
      )
      |> render_submit()

      assert_patch(
        view,
        inbound_path(%{
          "tenant_id" => @tenant_id,
          "provider" => "mailgun",
          "outcome" => "accept",
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ matching.record.id
      assert html =~ ~s(value="mailgun")
      assert html =~ ~s(<option value="accept" selected)

      # Re-mount from the URL: filters survive.
      {:ok, _view2, html2} =
        live(
          conn,
          inbound_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "mailgun",
            "outcome" => "accept",
            "window_hours" => "168"
          })
        )

      assert html2 =~ ~s(value="mailgun")
      assert html2 =~ ~s(<option value="accept" selected)
    end

    test "an unselectable foreign-tenant record id surfaces the detail-error band, not a leak", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      %{record: foreign} = InboundFixtures.seed_matched!(@other_tenant)

      {:ok, _view, html} =
        live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => foreign.id}))

      assert html =~ ~s(data-testid="inbound-detail-error")
      assert html =~ "Inbound data could not be loaded."
    end

    test "rejects mounts without an authorized actor (operator Auth gate)", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} =
               live(conn, inbound_path(%{"tenant_id" => @tenant_id}))
    end
  end

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> @base_path
      query -> @base_path <> "?" <> query
    end
  end

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
    |> then(fn conn ->
      Plug.Test.init_test_session(conn, Map.merge(get_session_map(conn), session))
    end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
  end
end
