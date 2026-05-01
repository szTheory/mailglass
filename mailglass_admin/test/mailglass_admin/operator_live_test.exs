defmodule MailglassAdmin.OperatorLiveTest do
  use Mailglass.AdminCase, async: false

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.TestRepo

  @tenant_id "test-tenant"
  @base_path "/dev/mail/operator"

  describe "operator surface" do
    test "renders the default detail prompt when no delivery is selected", %{conn: conn} do
      delivery = insert_delivery!(recipient: "selected@example.com")

      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Recent deliveries"
      assert html =~ delivery.recipient
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
      refute html =~ "Event timeline"
    end

    test "renders the recent deliveries empty state", %{conn: conn} do
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "No recent deliveries"
      assert html =~ "No recent deliveries match these filters. Clear the filters or wait for the next send."
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
    end

    test "applies filters through URL-backed state", %{conn: conn} do
      matching =
        insert_delivery!(
          recipient: "match@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered
        )

      _other =
        insert_delivery!(
          recipient: "skip@example.com",
          provider: "sendgrid",
          status: :failed,
          last_event_type: :failed
        )

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      view
      |> form("#operator-filters",
        filters: %{
          "tenant_id" => @tenant_id,
          "provider" => "postmark",
          "status" => "sent",
          "event" => "delivered",
          "window_hours" => "168"
        }
      )
      |> render_submit()

      assert_patch(
        view,
        operator_path(%{
          "tenant_id" => @tenant_id,
          "provider" => "postmark",
          "status" => "sent",
          "event" => "delivered",
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ matching.recipient
      refute html =~ "skip@example.com"
      assert html =~ ~s(value="postmark")
      assert html =~ ~s(<option value="sent" selected)
      assert html =~ ~s(<option value="delivered" selected)
    end

    test "selects a delivery and renders summary, timeline, reversible suppression copy, and read-only boundaries",
         %{conn: conn} do
      delivery =
        insert_delivery!(
          recipient: "selected@example.com",
          provider: "postmark",
          provider_message_id: "pm_123",
          status: :sent,
          last_event_type: :delivered,
          mailable: "Mailglass.Example.WelcomeMailer"
        )

      insert_event!(delivery, %{type: :sent, occurred_at: hours_ago(3), metadata: %{provider: "postmark"}})

      insert_event!(delivery, %{
        type: :delivered,
        occurred_at: hours_ago(2),
        metadata: %{provider: "postmark", source: "webhook"}
      })

      insert_suppression!(%{
        tenant_id: @tenant_id,
        address: delivery.recipient,
        scope: :address,
        reason: :manual,
        source: "ops:review"
      })

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      view
      |> element("button[phx-value-id='#{delivery.id}']")
      |> render_click()

      assert_patch(
        view,
        operator_path(%{
          "tenant_id" => @tenant_id,
          "delivery_id" => delivery.id,
          "window_hours" => "168"
        })
      )

      html = render(view)

      assert html =~ delivery.recipient
      assert html =~ "Event timeline"
      assert html =~ "Chronological order"
      assert html =~ "Mailglass.Example.WelcomeMailer"
      assert html =~ "pm_123"
      assert html =~ "Suppression state"
      assert html =~ "Reversible in a later phase"
      assert html =~ "This suppression is reversible in a later phase."
      assert html =~ "Sent"
      assert html =~ "Delivered"
      refute html =~ "Replay"
      refute html =~ "Remove suppression"
      refute html =~ "recent-auth"
      refute html =~ "recent auth"
    end

    test "renders no timeline events and immutable suppression copy when selected delivery has no events",
         %{conn: conn} do
      delivery =
        insert_delivery!(
          recipient: "complaint@example.com",
          provider: "resend",
          status: :suppressed,
          last_event_type: :suppressed
        )

      insert_suppression!(%{
        tenant_id: @tenant_id,
        address: delivery.recipient,
        scope: :address,
        reason: :complaint,
        source: "webhook:auto_suppress"
      })

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      html = render(view)

      assert html =~ "No delivery events have been recorded for this item yet."
      assert html =~ "Immutable by policy"
      assert html =~ "This suppression is immutable by policy."
    end
  end

  defp operator_path(params) do
    @base_path <> "?" <> URI.encode_query(params)
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      mailable: "Mailglass.Example.OperatorMailer",
      stream: :transactional,
      recipient: "operator@example.com",
      provider: "postmark",
      provider_message_id: "pm_default",
      status: :sent,
      last_event_type: :sent,
      last_event_at: hours_ago(1),
      metadata: %{}
    }

    attrs
    |> Enum.into(defaults)
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp insert_event!(delivery, attrs) do
    defaults = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      type: :sent,
      occurred_at: hours_ago(1),
      metadata: %{},
      normalized_payload: %{}
    }

    attrs
    |> Enum.into(defaults)
    |> Event.changeset()
    |> TestRepo.insert!()
  end

  defp insert_suppression!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      address: "suppressed@example.com",
      scope: :address,
      reason: :manual,
      source: "ops:review"
    }

    attrs
    |> Enum.into(defaults)
    |> Entry.changeset()
    |> TestRepo.insert!()
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours, :hour)
end
