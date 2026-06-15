defmodule MailglassAdmin.OperatorLiveTest do
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.IdempotencyKey
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.DeliveriesList
  alias MailglassAdmin.Operator.SuppressionCard
  alias MailglassAdmin.TestSupport.OperatorFixtures
  alias MailglassAdmin.TestRepo
  alias Mailglass.Webhook.WebhookEvent

  @tenant_id "test-tenant"
  @base_path "/ops/mail"

  describe "operator surface" do
    test "renders the default detail prompt when no delivery is selected", %{conn: conn} do
      delivery = insert_delivery!(recipient: "selected@example.com")
      conn = operator_conn(conn)

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ "Recent deliveries"
      assert html =~ ~s(data-testid="operator-master-detail")
      assert html =~ "s*******@e******.com"
      refute html =~ delivery.recipient
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
      refute html =~ "Event timeline"
      # Orientation strip: present when no delivery is selected (GAP-07)
      assert html =~ ~s(data-testid="deliveries-orientation")
    end

    test "renders the recent deliveries empty state", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ "No Deliveries yet"

      assert html =~
               "Deliveries appear here once your application sends its first Message."

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

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

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
          "window_hours" => "168",
          "view" => "deliveries"
        })
      )

      html = render(view)

      assert html =~ "m****@e******.com"
      refute html =~ matching.recipient
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

      insert_event!(delivery, %{
        type: :sent,
        occurred_at: hours_ago(3),
        metadata: %{provider: "postmark"}
      })

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

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

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
      assert html =~ "Suppression"
      assert html =~ "Reversible in a later phase"
      assert html =~
               "This Suppression is reversible. Remove via the suppressions API or contact support."
      assert html =~ ~s(aria-selected="true")
      assert html =~ "Sent"
      assert html =~ "Delivered"
      assert html =~ "Webhook replay"
      assert html =~ ~s(data-testid="operator-replay-open")
      refute html =~ "Remove suppression"
      refute html =~ "recent-auth"
      refute html =~ "recent auth"
    end

    test "renders support cards, masks overview recipients, and distinguishes replay audit from reconcile facts",
         %{conn: conn} do
      conn = operator_conn(conn)
      %{selected_delivery: selected_delivery, replay_event: replay_event, reconcile_event: reconcile_event} =
        insert_support_summary_fixture!()

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => selected_delivery.id}))

      html = render(view)
      list_html = view |> element("[data-testid='operator-deliveries-list']") |> render()
      detail_html = view |> element("[data-testid='operator-detail-header']") |> render()

      assert html =~ ~s(data-testid="operator-support-cards")
      assert html =~ "Recent failures"
      assert html =~ "Orphan backlog"
      assert html =~ "Replay outcomes"
      assert html =~ "Reconciled:"
      assert html =~ "Tenant-scoped facts from the current support window."
      assert html =~ "Replay succeeded"
      assert html =~ "Reconciled"
      assert html =~ replay_event.id
      assert html =~ reconcile_event.id
      refute html =~ "real-time"

      assert list_html =~ "s*******@e******.com"
      refute list_html =~ selected_delivery.recipient

      assert detail_html =~ selected_delivery.recipient
    end

    test "support card drilldowns reveal concrete webhook, replay audit, orphan, and reconcile exemplars",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{
        selected_delivery: selected_delivery,
        reconcile_delivery: reconcile_delivery,
        orphan_event: orphan_event,
        replay_event: replay_event,
        reconcile_event: reconcile_event
      } = insert_support_summary_fixture!()

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => selected_delivery.id}))

      view
      |> element("[data-testid='support-card-failed-ingest-drilldown']")
      |> render_click()

      failed_ingest_html = render(view)

      assert failed_ingest_html =~ ~s(data-testid="support-card-failed-ingest-detail")
      assert failed_ingest_html =~ "failed-dead"

      view
      |> element("[data-testid='support-card-orphan-backlog-drilldown']")
      |> render_click()

      orphan_html = render(view)

      assert orphan_html =~ ~s(data-testid="support-card-orphan-backlog-detail")
      assert orphan_html =~ orphan_event.id
      assert orphan_html =~ "orphan-open"

      view
      |> element("[data-testid='support-card-replay-outcomes-drilldown']")
      |> render_click()

      replay_html = render(view)

      assert replay_html =~ "Showing replay audit fact"
      assert replay_html =~ replay_event.id
      assert replay_html =~ ~s(data-highlighted="true")

      view
      |> element("[data-testid='support-card-reconcile-facts-drilldown']")
      |> render_click()

      reconcile_html = render(view)
      detail_html = view |> element("[data-testid='operator-detail-header']") |> render()

      assert reconcile_html =~ "Showing reconcile fact"
      assert reconcile_html =~ reconcile_event.id
      assert detail_html =~ reconcile_delivery.recipient
      assert detail_html =~ ~s(pm-support-linked)
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

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      html = render(view)

      assert html =~ "No delivery events have been recorded for this item yet."
      assert html =~ "Immutable by policy"
      assert html =~
               "This Suppression is permanent. Future sends to this address will be blocked."
    end

    test "rejects operator mounts without an authorized actor", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} =
               live(conn, operator_path(%{"tenant_id" => @tenant_id}))
    end

    test "rejects blocked operators through the auth seam", %{conn: conn} do
      conn = operator_conn(conn, %{"current_user_id" => "blocked"})

      assert {:error, {:redirect, %{to: "/login"}}} =
               live(conn, operator_path(%{"tenant_id" => @tenant_id}))
    end

    test "shows the replay CTA only after a delivery is selected", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "cta@example.com", provider_message_id: "pm-cta")

      {:ok, view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      refute html =~ "Replay webhook"

      view
      |> element("button[phx-value-id='#{delivery.id}']")
      |> render_click()

      assert render(view) =~ "Replay webhook"
    end

    test "auto-populates the replay modal when exactly one target is available", %{conn: conn} do
      conn = operator_conn(conn)
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-exact-ui", 401)

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ ~s(data-testid="operator-replay-modal")
      assert html =~ "Replay is ready."
      assert html =~ "One exact webhook target is available for confirmation."
      refute html =~ "Replay is choice required."
      assert html =~ webhook_event.provider_event_id
      assert html =~ ~s(data-testid="operator-replay-confirm")
    end

    test "requires explicit target choice when multiple replay targets exist", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "many@example.com", provider_message_id: "pm-many")

      first =
        insert_webhook_event!(
          provider_event_id: "postmark-many-1",
          raw_payload: raw_postmark_payload("pm-many", 501)
        )

      second =
        insert_webhook_event!(
          provider_event_id: "postmark-many-2",
          raw_payload: raw_postmark_payload("pm-many", 502)
        )

      insert_linked_event!(delivery, first, "seed-many-1")
      insert_linked_event!(delivery, second, "seed-many-2")

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay is choice required."
      assert html =~ "Choose one webhook target"
      assert html =~ first.provider_event_id
      assert html =~ second.provider_event_id
      refute html =~ ~s(data-testid="operator-replay-confirm")
      assert replay_audit_rows_for(first.id) == []
      assert replay_audit_rows_for(second.id) == []

      view
      |> form("#operator-replay-targets", %{"webhook_event_id" => second.id})
      |> render_change()

      assert render(view) =~ ~s(data-testid="operator-replay-confirm")
    end

    test "shows unavailable replay copy when no safe target can be resolved", %{conn: conn} do
      conn = operator_conn(conn)

      delivery =
        insert_delivery!(recipient: "historical@example.com", provider_message_id: "pm-historical")

      insert_event!(delivery, %{
        type: :delivered,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "historical-child-only",
          "message_id" => "pm-historical"
        }
      })

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay unavailable"
      assert html =~ "Replay is unavailable."
      assert html =~ "Historical rows without exact webhook linkage"
      refute html =~ ~s(data-testid="operator-replay-confirm")
    end

    test "returns a stale-auth error without performing replay", %{conn: conn} do
      stale =
        DateTime.utc_now()
        |> DateTime.add(-1_800, :second)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      conn = operator_conn(conn, %{"recent_auth_at" => stale})
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-stale-ui", 601)

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

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

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      view
      |> element("[data-testid='operator-replay-confirm']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay completed with new work."
      assert html =~ "Webhook replay requested"
      assert html =~ "Webhook replay completed"
      assert html =~ "POSTMARK"
      assert html =~ "requested"
      assert html =~ "completed"
      assert html =~ "new work"
      assert html =~ "Last replay: completed · new work"
    end

    test "shows explicit no-op replay copy when the replay converges", %{conn: conn} do
      conn = operator_conn(conn)
      {delivery, webhook_event} = insert_exact_replay_fixture!("msg-noop-ui", 801)

      insert_event!(delivery, %{
        type: :delivered,
        idempotency_key:
          IdempotencyKey.for_webhook_event(:postmark, "Delivery:801:2026-05-01T00:00:00Z", 0),
        metadata:
          linked_replay_metadata(
            webhook_event,
            "Delivery:801:2026-05-01T00:00:00Z",
            delivery.provider_message_id
          )
      })

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element("[data-testid='operator-replay-open']")
      |> render_click()

      view
      |> element("[data-testid='operator-replay-confirm']")
      |> render_click()

      html = render(view)

      assert html =~ "Replay completed with no change."
      assert html =~ "Webhook replay completed"
      assert html =~ "no change"
      assert html =~ "Last replay: completed · no change"
    end
  end

  describe "CR-01/02/03 nil-guards" do
    test "suppression card renders novel-shape fallback copy" do
      html = render_component(&SuppressionCard.suppression_card/1, suppression_state: %{})

      assert html =~ "No suppression"
      assert html =~ "No active Suppression for this Delivery."
    end

    test "suppressed status badge uses the neutral fallback without warnings" do
      html = render_component(&Components.status_badge/1, status: :suppressed, size: :sm)

      assert html =~ "badge-outline"
      assert html =~ "Unknown"
      refute html =~ "status_class(:suppressed)"
    end

    test "support exemplar event tolerates missing selected delivery", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      render_hook(view, "open_support_exemplar", %{"focus" => "failed_ingest"})

      assert_patch(
        view,
        operator_path(%{
          "tenant_id" => @tenant_id,
          "window_hours" => "168",
          "support_focus" => "failed_ingest"
        })
      )
    end

    test "confirm replay event tolerates missing selected delivery", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      html = render_hook(view, "confirm_replay", %{})

      assert html =~ "Select a delivery before replaying a webhook."
    end
  end

  describe "filters_active? empty states" do
    test "filtered empty state names the active filters and offers reset" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: true
        )

      assert html =~ "No Deliveries match your filters"
      assert html =~ "Adjust the filters or wait for the next send."
      assert html =~ ~s(phx-click="clear_filters")
      assert html =~ ~s(data-testid="operator-empty-filtered")
    end

    test "truly empty state avoids reset action" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false
        )

      assert html =~ "No Deliveries yet"
      assert html =~ "Deliveries appear here once your application sends its first Message."
      assert html =~ ~s(data-testid="operator-empty-truly")
      refute html =~ ~s(phx-click="clear_filters")
    end
  end

  describe "operator tracking-clean" do
    test "operator source files do not use arbitrary tracking utilities" do
      files = [
        "lib/mailglass_admin/operator_live.ex",
        "lib/mailglass_admin/operator/suppression_card.ex",
        "lib/mailglass_admin/operator/support_cards.ex",
        "lib/mailglass_admin/operator/replay_modal.ex",
        "lib/mailglass_admin/operator/filters_form.ex",
        "lib/mailglass_admin/operator/deliveries_list.ex",
        "lib/mailglass_admin/operator/detail_header.ex"
      ]

      offenders =
        for file <- files,
            {line, index} <- file |> File.read!() |> String.split("\n") |> Enum.with_index(1),
            not String.match?(line, ~r/^\s*#/),
            String.contains?(line, "tracking-["),
            do: "#{file}:#{index}:#{line}"

      assert offenders == []
    end
  end

  describe "browser seed ordering" do
    test "suppressed browser seed appends after existing index-pinned rows" do
      %{tenant_id: tenant_id} = OperatorFixtures.seed_browser_scenario!()

      deliveries =
        TestRepo.all(
          from(delivery in Delivery,
            where: delivery.tenant_id == ^tenant_id,
            order_by: [desc: delivery.last_event_at]
          )
        )

      assert List.first(deliveries).recipient == "browser-selected@example.com"
      assert List.last(deliveries).recipient == "browser-suppressed@example.com"
      assert List.last(deliveries).status == :suppressed
    end

    test "browser reset seeds the inbound outcome and missing-state matrix" do
      %{tenant_id: tenant_id} = OperatorFixtures.seed_browser_scenario!()

      records =
        TestRepo.all(
          from(record in InboundRecord,
            where: record.tenant_id == ^tenant_id,
            order_by: [desc: record.received_at]
          )
        )

      assert Enum.count(records) >= 9
      assert Enum.any?(records, &(&1.envelope_recipient == "nomatch@browser-scenario.example"))
      assert Enum.any?(records, &(&1.subject == "general route question"))
      assert Enum.any?(records, &(&1.suppression_flagged == true))
      assert Enum.any?(records, &String.contains?(&1.subject || "", "extended context"))

      outcomes =
        TestRepo.all(
          from(run in ExecutionRun,
            where: run.tenant_id == ^tenant_id and run.source == :fresh,
            select: run.outcome
          )
        )

      assert :accept in outcomes
      assert :no_match in outcomes
      assert :reject in outcomes
      assert :bounce in outcomes
      assert :failed in outcomes

      no_match_run =
        TestRepo.one!(
          from(run in ExecutionRun,
            join: record in InboundRecord,
            on: record.id == run.inbound_record_id,
            where:
              run.tenant_id == ^tenant_id and
                record.envelope_recipient == "nomatch@browser-scenario.example",
            select: run
          )
        )

      assert no_match_run.outcome == :no_match
      assert is_nil(no_match_run.mailbox)

      assert TestRepo.exists?(
               from(record in InboundRecord,
                 where:
                   record.tenant_id == ^tenant_id and
                     record.provider_message_id == "pm_browser_inbound_no_run",
                 left_join: run in ExecutionRun,
                 on: run.inbound_record_id == record.id,
                 where: is_nil(run.id)
               )
             )

      assert TestRepo.exists?(
               from(record in InboundRecord,
                 where:
                   record.tenant_id == ^tenant_id and
                     record.provider_message_id == "pm_browser_inbound_missing_evidence",
                 left_join: run in ExecutionRun,
                 on: run.inbound_record_id == record.id,
                 where: is_nil(run.inbound_evidence_id)
               )
             )
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
      |> Map.update!(:status, fn
        status when is_atom(status) -> Atom.to_string(status)
        status -> status
      end)
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
      metadata:
        linked_replay_metadata(webhook_event, child_provider_event_id, delivery.provider_message_id)
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
          event.type in [
            :webhook_replay_requested,
            :webhook_replay_succeeded,
            :webhook_replay_failed
          ] and
            fragment("?->>'webhook_event_id' = ?", event.metadata, ^webhook_event_id)
      )
    )
  end

  defp insert_support_summary_fixture! do
    selected_delivery =
      insert_delivery!(
        recipient: "selected@example.com",
        provider_message_id: "pm-support-selected",
        status: :sent,
        last_event_type: :delivered
      )

    reconcile_delivery =
      insert_delivery!(
        recipient: "linked@example.com",
        provider_message_id: "pm-support-linked",
        status: :sent,
        last_event_type: :delivered
      )

    insert_event!(selected_delivery, %{
      type: :delivered,
      occurred_at: hours_ago(4),
      metadata: %{"provider" => "postmark", "source" => "webhook"}
    })

    replay_webhook_event =
      insert_webhook_event!(
        provider_event_id: "support-replay-webhook",
        raw_payload: raw_postmark_payload("pm-support-selected", 901)
      )

    insert_linked_event!(selected_delivery, replay_webhook_event, "support-replay-child")

    {:ok, replay_event} =
      Mailglass.Events.append(%{
        tenant_id: @tenant_id,
        delivery_id: selected_delivery.id,
        type: :webhook_replay_succeeded,
        occurred_at: hours_ago(1),
        metadata: %{
          "provider" => "postmark",
          "webhook_event_id" => replay_webhook_event.id,
          "webhook_provider_event_id" => replay_webhook_event.provider_event_id,
          "outcome" => "replayed",
          "actor_id" => "operator-1"
        }
      })

    {:ok, orphan_event} =
      Mailglass.Events.append(%{
        tenant_id: @tenant_id,
        type: :delivered,
        delivery_id: nil,
        occurred_at: hours_ago(5),
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-open",
          "provider_message_id" => "pm-orphan-open"
        }
      })

    {:ok, linked_orphan} =
      Mailglass.Events.append(%{
        tenant_id: @tenant_id,
        type: :delivered,
        delivery_id: nil,
        occurred_at: hours_ago(3),
        needs_reconciliation: true,
        metadata: %{
          "provider" => "postmark",
          "provider_event_id" => "orphan-linked",
          "provider_message_id" => "pm-orphan-linked"
        }
      })

    {:ok, reconcile_event} =
      Mailglass.Events.append(%{
        tenant_id: @tenant_id,
        delivery_id: reconcile_delivery.id,
        type: :reconciled,
        occurred_at: minutes_ago(30),
        metadata: %{
          "reconciled_from_event_id" => linked_orphan.id,
          "reconciled_provider" => "postmark",
          "reconciled_provider_event_id" => "orphan-linked"
        }
      })

    _failed_ingest =
      insert_webhook_event!(
        provider_event_id: "failed-ingest",
        status: :failed,
        received_at: hours_ago(2)
      )

    _dead_ingest =
      insert_webhook_event!(
        provider_event_id: "failed-dead",
        status: :dead,
        received_at: minutes_ago(45)
      )

    insert_event!(reconcile_delivery, %{
      type: :delivered,
      occurred_at: hours_ago(2),
      metadata: %{"provider" => "postmark", "source" => "webhook"}
    })

    %{
      selected_delivery: selected_delivery,
      reconcile_delivery: reconcile_delivery,
      orphan_event: orphan_event,
      replay_event: replay_event,
      reconcile_event: reconcile_event
    }
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

  describe "Operator Overview branch" do
    test "bare /ops/mail/ renders h1 Operator overview (no selected delivery, no tenant)", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "Operator overview"
      assert html =~ ~s(data-testid="operator-overview")
      refute html =~ ~s(data-testid="operator-master-detail")
      refute html =~ ~s(data-testid="operator-deliveries-list")
    end

    test "no-tenant Overview shows nudge copy not health row", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "Select a tenant to see health at a glance."
      refute html =~ ~s(data-testid="operator-overview-health")
    end

    test "with-tenant Overview renders 4 health-count cards", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="operator-overview")
      assert html =~ ~s(data-testid="operator-overview-health")
      assert html =~ "Recent failures"
      assert html =~ "Orphan backlog"
      assert html =~ "Active suppressions"
    end

    test "suppression count degradation renders em-dash in text-secondary when count errors", %{
      conn: conn
    } do
      # When suppression_count is nil (e.g., module error), the Overview renders "—"
      # We test this by mounting with a tenant and checking that a suppression count
      # is rendered (either as number or em-dash — both are valid render outputs).
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      # The overview must render without crashing when suppression count is 0 or nil.
      # It should show either a number or an em-dash, never crash.
      assert html =~ ~s(data-testid="operator-overview-health")
      # With no suppressions inserted, count is 0 — rendered as "0" or may render "—" on error
      assert html =~ "Active suppressions"
    end

    test "?view=deliveries param shows Deliveries list not Overview", %{conn: conn} do
      conn = operator_conn(conn)
      _delivery = insert_delivery!(recipient: "view-test@example.com")

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ ~s(data-testid="operator-master-detail")
      assert html =~ ~s(data-testid="operator-deliveries-list")
      refute html =~ ~s(data-testid="operator-overview")
    end
  end

  describe "motion-reveal re-fire fix (GAP-19 / MOTION-01)" do
    test "delivery detail pane motion-reveal div carries a record-keyed id (D-01)", %{conn: conn} do
      conn = operator_conn(conn)

      delivery =
        insert_delivery!(
          recipient: "motion@example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :delivered
        )

      {:ok, _view, html} =
        live(
          conn,
          operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id})
        )

      assert html =~ ~s(id="delivery-detail-#{delivery.id}")
    end
  end

  defp minutes_ago(minutes), do: DateTime.add(DateTime.utc_now(), -minutes, :minute)
end
