defmodule MailglassAdmin.OperatorLiveTest do
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.IdempotencyKey
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.TestRepo
  alias Mailglass.Webhook.WebhookEvent

  @tenant_id "test-tenant"
  @base_path "/ops/mail"

  describe "operator surface" do
    test "renders the default detail prompt when no delivery is selected", %{conn: conn} do
      delivery = insert_delivery!(recipient: "selected@example.com")
      conn = operator_conn(conn)

      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Recent deliveries"
      assert html =~ ~s(data-testid="operator-master-detail")
      assert html =~ delivery.recipient
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
      refute html =~ "Event timeline"
    end

    test "renders the recent deliveries empty state", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "No recent deliveries"
      assert html =~ "No recent deliveries match these filters. Clear the filters or wait for the next send."
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
    end

    test "applies filters through URL-backed state", %{conn: conn} do
      conn = operator_conn(conn)

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
      conn = operator_conn(conn)

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
      assert html =~ ~s(data-testid="operator-detail-header")
      assert html =~ ~s(data-testid="operator-timeline")
      assert html =~ ~s(data-testid="operator-suppression-card")
      assert html =~ "Mailglass.Example.WelcomeMailer"
      assert html =~ "pm_123"
      assert html =~ "Suppression state"
      assert html =~ "Reversible in a later phase"
      assert html =~ "This suppression is reversible in a later phase."
      assert html =~ ~s(aria-selected="true")
      assert html =~ "Sent"
      assert html =~ "Delivered"
      assert html =~ "Webhook replay"
      assert html =~ ~s(data-testid="operator-replay-open")
      refute html =~ "Remove suppression"
      refute html =~ "recent-auth"
      refute html =~ "recent auth"
    end

    test "renders no timeline events and immutable suppression copy when selected delivery has no events",
         %{conn: conn} do
      conn = operator_conn(conn)

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

    test "rejects operator mounts without an authorized actor", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))
    end

    test "rejects blocked operators through the auth seam", %{conn: conn} do
      conn = operator_conn(conn, %{"current_user_id" => "blocked"})

      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))
    end

    test "shows the replay CTA only after a delivery is selected", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "cta@example.com", provider_message_id: "pm-cta")

      {:ok, view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      refute html =~ "Replay webhook"

      view
      |> element("button[phx-value-id='#{delivery.id}']")
      |> render_click()

      assert render(view) =~ "Replay webhook"
    end

    test "auto-populates the replay modal when exactly one target is available", %{conn: conn} do
      conn = operator_conn(conn)
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-exact-ui", 401)

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ ~s(data-testid="operator-replay-modal")
      assert html =~ "one exact webhook target"
      assert html =~ webhook_event.provider_event_id
      assert html =~ ~s(data-testid="operator-replay-confirm")
    end

    test "requires explicit target choice when multiple replay targets exist", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "many@example.com", provider_message_id: "pm-many")
      first = insert_webhook_event!(provider_event_id: "postmark-many-1", raw_payload: raw_postmark_payload("pm-many", 501))
      second = insert_webhook_event!(provider_event_id: "postmark-many-2", raw_payload: raw_postmark_payload("pm-many", 502))

      insert_linked_event!(delivery, first, "seed-many-1")
      insert_linked_event!(delivery, second, "seed-many-2")

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ "Choose one webhook target"
      assert html =~ first.provider_event_id
      assert html =~ second.provider_event_id
      refute html =~ ~s(data-testid="operator-replay-confirm")

      view
      |> form("#operator-replay-targets", %{"webhook_event_id" => second.id})
      |> render_change()

      assert render(view) =~ ~s(data-testid="operator-replay-confirm")
    end

    test "shows unavailable replay copy when no safe target can be resolved", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "historical@example.com", provider_message_id: "pm-historical")

      insert_event!(delivery, %{
        type: :delivered,
        metadata: %{"provider" => "postmark", "provider_event_id" => "historical-child-only", "message_id" => "pm-historical"}
      })

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay unavailable"
      assert html =~ "Historical rows without exact webhook linkage"
      refute html =~ ~s(data-testid="operator-replay-confirm")
    end

    test "returns a stale-auth error without performing replay", %{conn: conn} do
      stale = DateTime.utc_now() |> DateTime.add(-1_800, :second) |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      conn = operator_conn(conn, %{"recent_auth_at" => stale})
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-stale-ui", 601)

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      view
      |> element("[data-testid='operator-replay-confirm']")
      |> render_click()

      html = render(view)

      assert html =~ "Recent authentication is required."
      assert replay_audit_rows_for(webhook_event.id) == []
    end

    test "executes replay in place and surfaces durable replay results inline", %{conn: conn} do
      conn = operator_conn(conn)
      {delivery, _webhook_event} = insert_exact_replay_fixture!("msg-success-ui", 701)

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      view
      |> element("[data-testid='operator-replay-confirm']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay completed and produced new work."
      assert html =~ "Webhook replay requested"
      assert html =~ "Webhook replay succeeded"
      assert html =~ "Last replay: succeeded"
    end

    test "shows explicit no-op replay copy when the replay converges", %{conn: conn} do
      conn = operator_conn(conn)
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-noop-ui", 801)

      insert_event!(delivery, %{
        type: :delivered,
        idempotency_key: IdempotencyKey.for_webhook_event(:postmark, "Delivery:801:2026-05-01T00:00:00Z", 0),
        metadata: linked_replay_metadata(webhook_event, "Delivery:801:2026-05-01T00:00:00Z", delivery.provider_message_id)
      })

      {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      view
      |> element("[data-testid='operator-replay-confirm']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay converged without new downstream work."
      assert html =~ "No new work"
      assert html =~ "Last replay: converged with no new work"
    end
  end

  defp operator_path(params) do
    @base_path <> "?" <> URI.encode_query(params)
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
    |> then(fn conn -> Plug.Test.init_test_session(conn, Map.merge(get_session_map(conn), session)) end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
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

  defp insert_webhook_event!(attrs) do
    defaults = %{
      id: Ecto.UUID.generate(),
      tenant_id: @tenant_id,
      provider: "postmark",
      provider_event_id: "webhook-#{System.unique_integer([:positive])}",
      event_type_raw: "Delivery",
      event_type_normalized: "delivered",
      status: "succeeded",
      raw_payload: %{"RecordType" => "Delivery"},
      received_at: DateTime.utc_now(),
      processed_at: DateTime.utc_now(),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    row =
      attrs
      |> Enum.into(defaults)
      |> Map.put_new(:updated_at, DateTime.utc_now())
      |> Map.put_new(:inserted_at, DateTime.utc_now())

    _ =
      Ecto.Adapters.SQL.query!(
        TestRepo,
        """
        INSERT INTO mailglass_webhook_events
          (id, tenant_id, provider, provider_event_id, event_type_raw, event_type_normalized,
           status, raw_payload, received_at, processed_at, inserted_at, updated_at)
        VALUES
          ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        """,
        [
          Ecto.UUID.dump!(row.id),
          row.tenant_id,
          row.provider,
          row.provider_event_id,
          row.event_type_raw,
          row.event_type_normalized,
          row.status,
          row.raw_payload,
          row.received_at,
          row.processed_at,
          row.inserted_at,
          row.updated_at
        ]
      )

    struct!(WebhookEvent, Map.put(row, :status, String.to_atom(row.status)))
  end

  defp insert_linked_event!(delivery, webhook_event, child_provider_event_id) do
    insert_event!(delivery, %{
      type: :sent,
      metadata: linked_replay_metadata(webhook_event, child_provider_event_id, delivery.provider_message_id)
    })
  end

  defp insert_suppression!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      address: "suppressed@example.com",
      scope: :address,
      reason: :manual,
      source: "ops:review",
      stream: nil
    }

    [row] =
      attrs
      |> Enum.into(defaults)
      |> Map.put(:id, Ecto.UUID.generate())
      |> Map.put(:metadata, %{})
      |> Map.put(:inserted_at, DateTime.utc_now())
      |> normalize_suppression_row()
      |> List.wrap()

    _ =
      Ecto.Adapters.SQL.query!(
        TestRepo,
        """
        INSERT INTO mailglass_suppressions
          (id, tenant_id, address, scope, stream, reason, source, expires_at, metadata, inserted_at)
        VALUES
          ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        """,
        [
          row.id,
          row.tenant_id,
          row.address,
          row.scope,
          row.stream,
          row.reason,
          row.source,
          row[:expires_at],
          row.metadata,
          row.inserted_at
        ]
      )
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours, :hour)

  defp insert_exact_replay_fixture!(provider_message_id, replay_id) do
    delivery =
      insert_delivery!(
        recipient: "replay-#{replay_id}@example.com",
        provider_message_id: provider_message_id,
        last_event_type: :sent
      )

    webhook_event =
      insert_webhook_event!(
        provider_event_id: "postmark-webhook-#{replay_id}",
        raw_payload: raw_postmark_payload(provider_message_id, replay_id)
      )

    insert_linked_event!(delivery, webhook_event, "seed-link-#{replay_id}")

    {delivery, webhook_event}
  end

  defp linked_replay_metadata(webhook_event, child_provider_event_id, provider_message_id) do
    %{
      "provider" => "postmark",
      "provider_event_id" => child_provider_event_id,
      "webhook_event_id" => webhook_event.id,
      "webhook_provider_event_id" => webhook_event.provider_event_id,
      "message_id" => provider_message_id
    }
  end

  defp raw_postmark_payload(provider_message_id, replay_id) do
    %{
      "RecordType" => "Delivery",
      "MessageID" => provider_message_id,
      "ID" => replay_id,
      "DeliveredAt" => "2026-05-01T00:00:00Z"
    }
  end

  defp replay_audit_rows_for(webhook_event_id) do
    TestRepo.all(
      from(event in Event,
        where:
          event.type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed] and
            fragment("?->>'webhook_event_id' = ?", event.metadata, ^webhook_event_id)
      )
    )
  end

  defp normalize_suppression_row(row) do
    row
    |> Map.update!(:id, &Ecto.UUID.dump!/1)
    |> Map.update!(:scope, &Atom.to_string/1)
    |> Map.update!(:reason, &Atom.to_string/1)
    |> Map.update!(:stream, fn
      nil -> nil
      stream -> Atom.to_string(stream)
    end)
  end
end
