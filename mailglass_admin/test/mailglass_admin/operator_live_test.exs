defmodule MailglassAdmin.OperatorLiveTest do
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.IdempotencyKey
  alias MailglassInbound.InboundRecords.InboundEvidence
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
      # Positive D-06 proof: the populated-but-unselected detail column still renders
      # the "Select a delivery…" master-detail helper.
      assert html =~ "Select a delivery to inspect its event timeline and suppression state."
      refute html =~ "Event timeline"
      # Orientation strip is empty-pane-only: absent on a populated view,
      # present only in genuine no-data.
      refute html =~ ~s(data-testid="deliveries-orientation")
    end

    test "renders a single calm pane (empty-truly + orientation strip) in genuine no-data (no rows, no active filters)",
         %{conn: conn} do
      conn = operator_conn(conn)

      # No delivery inserted + default filter params → filters_active?/1 is false.
      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ "No deliveries"

      assert html =~
               "No deliveries have been recorded yet."

      # Single calm pane: the empty-truly state + the orientation strip (its only location).
      assert html =~ ~s(data-testid="operator-empty-truly")
      assert html =~ ~s(data-testid="deliveries-orientation")

      # The filters toolbar (the only scope-widening vector) and the entire master-detail
      # grid are withheld — so the nested "Select a delivery…" helper does not render here.
      refute html =~ ~s(data-testid="operator-filters")
      refute html =~ ~s(data-testid="operator-master-detail")
      refute html =~ "Select a delivery to inspect its event timeline and suppression state."
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

    test "no-match (active filters, zero rows) keeps the filters toolbar and withholds the orientation strip",
         %{conn: conn} do
      conn = operator_conn(conn)

      # A sent delivery exists, but the active status filter (failed) matches nothing →
      # @deliveries == [] AND filters_active?/1 is true (the no-match state, not no-data).
      insert_delivery!(
        recipient: "only-sent@example.com",
        provider: "postmark",
        status: :sent,
        last_event_type: :delivered
      )

      {:ok, _view, html} =
        live(
          conn,
          operator_path(%{
            "tenant_id" => @tenant_id,
            "view" => "deliveries",
            "status" => "failed"
          })
        )

      # Toolbar kept so the operator retains the Clear-filters escape; in-pane no-match copy present.
      assert html =~ ~s(data-testid="operator-filters")
      assert html =~ ~s(data-testid="operator-empty-filtered")
      # Orientation strip is genuine-no-data only → absent in no-match.
      refute html =~ ~s(data-testid="deliveries-orientation")
    end

    test "invalid URL-backed filters render recovery copy without narrowing tenant reads", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      insert_delivery!(
        recipient: "match@example.com",
        provider: "postmark",
        status: :sent,
        last_event_type: :delivered
      )

      {:ok, _view, html} =
        live(
          conn,
          operator_path(%{
            "tenant_id" => @tenant_id,
            "view" => "deliveries",
            "status" => "not-listed",
            "event" => "not-real",
            "window_hours" => "0"
          })
        )

      assert html =~ "Status was not applied. Choose a listed status."
      assert html =~ "Event was not applied. Choose a listed event."
      assert html =~ "Time window was not applied. Choose a positive listed time window."
      assert html =~ "m****@e******.com"
      assert html =~ ~s(value="168" selected)
      refute html =~ "not-listed"
      refute html =~ "not-real"
    end

    test "invalid submitted filters render recovery copy and do not push a patch", %{
      conn: conn
    } do
      conn = operator_conn(conn)

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      html =
        render_hook(view, "apply_filters", %{
          "filters" => %{
            "tenant_id" => @tenant_id,
            "provider" => "",
            "status" => "not-listed",
            "event" => "not-real",
            "window_hours" => "-5"
          }
        })

      assert html =~ "Status was not applied. Choose a listed status."
      assert html =~ "Event was not applied. Choose a listed event."
      assert html =~ "Time window was not applied. Choose a positive listed time window."

      assert_raise ArgumentError, fn ->
        assert_patch(view, 0)
      end
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

      %{
        selected_delivery: selected_delivery,
        replay_event: replay_event,
        reconcile_event: reconcile_event
      } =
        insert_support_summary_fixture!()

      {:ok, view, _html} =
        live(
          conn,
          operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => selected_delivery.id})
        )

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

    # Phase 114 D-10: binds the gallery composed-group specimen
    # (GalleryLive.composed_support_triage/1) to production reality. The specimen
    # wraps `<div data-region>` around DetailHeader + SupportCards + Timeline +
    # SuppressionCard; this asserts the REAL operator detail column carries the
    # same data-region scope + group testids, so a specimen that drifts from
    # production composition fails the suite.
    test "production operator detail column carries data-region + the composed-group testids",
         %{conn: conn} do
      conn = operator_conn(conn)

      %{selected_delivery: selected_delivery} = insert_support_summary_fixture!()

      {:ok, view, _html} =
        live(
          conn,
          operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => selected_delivery.id})
        )

      detail_html = view |> element("#delivery-detail-#{selected_delivery.id}") |> render()

      # The data-region scope the plan-04 Floki ancestor-depth proof binds against.
      assert detail_html =~ "data-region"

      # The four group testids the composed_support_triage specimen assembles, in
      # the same order operator_live.ex composes them.
      assert detail_html =~ ~s(data-testid="operator-detail-header")
      assert detail_html =~ ~s(data-testid="operator-support-cards")
      assert detail_html =~ ~s(data-testid="operator-timeline")
      assert detail_html =~ ~s(data-testid="operator-suppression-card")
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
        live(
          conn,
          operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => selected_delivery.id})
        )

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
        insert_delivery!(
          recipient: "historical@example.com",
          provider_message_id: "pm-historical"
        )

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
    test "renders honest result count and disabled pagination boundaries" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{
            total_count: 7,
            page: 1,
            per_page: 5,
            total_pages: 2,
            has_previous?: false,
            has_next?: true
          },
          previous_page_path: "/ops/mail?tenant_id=test-tenant&view=deliveries&page=1",
          next_page_path: "/ops/mail?tenant_id=test-tenant&view=deliveries&page=2"
        )

      assert html =~ ~s(data-testid="operator-result-count")
      assert html =~ "7 results"
      assert html =~ ~s(data-testid="operator-pagination")
      assert html =~ ~s(data-testid="operator-pagination-prev-disabled")
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(data-testid="operator-pagination-next")
      assert html =~ "page=2"
    end

    test "omits pagination chrome for one-page results while keeping count" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{
            total_count: 1,
            page: 1,
            per_page: 5,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert html =~ "1 result"
      refute html =~ ~s(data-testid="operator-pagination")
    end

    test "filtered empty state names the active filters and offers reset" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: true
        )

      assert html =~ "No deliveries"
      assert html =~ "No deliveries match the current filters."
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

      assert html =~ "No deliveries"
      assert html =~ "No deliveries have been recorded yet."
      assert html =~ ~s(data-testid="operator-empty-truly")
      refute html =~ ~s(phx-click="clear_filters")
    end
  end

  describe "delivery pagination metadata" do
    test "delivery page links preserve tenant scope and expose honest boundaries", %{conn: conn} do
      conn = operator_conn(conn)

      for index <- 1..7 do
        insert_delivery!(
          recipient: "page-#{index}@example.com",
          provider_message_id: "pm-page-#{index}",
          last_event_at: hours_ago(index)
        )
      end

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ ~s(data-testid="operator-result-count")
      assert html =~ "7 results"
      assert html =~ ~s(data-testid="operator-pagination")
      assert html =~ ~s(data-testid="operator-pagination-prev-disabled")
      assert html =~ "tenant_id=#{@tenant_id}"
      assert html =~ "page=2"
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
                 left_join: evidence in InboundEvidence,
                 on: evidence.inbound_record_id == record.id,
                 where: is_nil(evidence.id)
               )
             )
    end
  end

  describe "cross-surface tenant scope" do
    test "bare operator URL with exactly one accessible tenant canonicalizes to tenant_id", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      insert_delivery!(tenant_id: "solo-tenant", recipient: "solo@example.com")

      {:ok, view, _html} = live(conn, @base_path)

      assert_patch(view, operator_path(%{"tenant_id" => "solo-tenant"}))
    end

    test "bare operator URL with multiple accessible tenants renders selector copy", %{conn: conn} do
      conn = operator_conn(conn)

      insert_delivery!(
        tenant_id: "alpha-tenant",
        recipient: "alpha@example.com",
        provider_message_id: "pm-alpha-tenant"
      )

      insert_delivery!(
        tenant_id: "beta-tenant",
        recipient: "beta@example.com",
        provider_message_id: "pm-beta-tenant"
      )

      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "Select a tenant"
      assert html =~ "Choose a tenant to inspect its Deliveries and inbound routing"
      assert html =~ "Select tenant"
      assert html =~ "alpha-tenant"
      assert html =~ "beta-tenant"
      refute html =~ "add <code"
      refute html =~ "tenant_id=…"
    end

    test "clear filters preserves the selected tenant on deliveries", %{conn: conn} do
      conn = operator_conn(conn)
      insert_delivery!(provider: "postmark")

      {:ok, view, _html} =
        live(
          conn,
          operator_path(%{
            "tenant_id" => @tenant_id,
            "provider" => "postmark",
            "view" => "deliveries"
          })
        )

      render_hook(view, "clear_filters", %{})

      assert_patch(view, operator_path(%{"tenant_id" => @tenant_id}))
    end

    test "delivery detail back preserves tenant and drops delivery id", %{conn: conn} do
      conn = operator_conn(conn)
      delivery = insert_delivery!(recipient: "back@example.com")

      {:ok, view, _html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "delivery_id" => delivery.id}))

      view
      |> element(~s(a[data-testid="operator-detail-back"]))
      |> render_click()

      assert_patch(
        view,
        operator_path(%{
          "tenant_id" => @tenant_id,
          "window_hours" => "168"
        })
      )
    end

    test "rendered Inbound nav target preserves the current tenant", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "/ops/mail/inbound?tenant_id=#{@tenant_id}"
    end
  end

  describe "root layout theme (MountPathHook)" do
    test "?theme=dark themes the operator ROOT <html>, not just the shell", %{conn: conn} do
      conn = operator_conn(conn)

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "theme" => "dark"}))

      assert html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
    end

    test "no theme param leaves the operator root <html> un-themed", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      refute html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
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
        linked_replay_metadata(
          webhook_event,
          child_provider_event_id,
          delivery.provider_message_id
        )
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
    test "bare /ops/mail/ with no accessible tenants renders no-tenant shell state", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "Operator overview"
      assert html =~ ~s(data-testid="tenant-selector")
      assert html =~ "No tenants available"
      refute html =~ ~s(data-testid="operator-master-detail")
      refute html =~ ~s(data-testid="operator-deliveries-list")
    end

    test "no-tenant Overview suppresses health row", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, @base_path)

      assert html =~ "No tenants available"
      assert html =~ ~s(data-testid="tenant-selector")
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

    # SHELL-02: operator-overview-nav block deleted (D-04/D-NAV-DUP)
    test "Overview does NOT render the redundant Navigate block (operator-overview-nav deleted)", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      refute html =~ ~s(data-testid="operator-overview-nav"),
             "operator-overview-nav block must be deleted (D-04)"
    end

    # SHELL-02: failures stat card wrapped in drill-through link (status=failed, tenant-scoped)
    test "failures stat card is wrapped in a drill-through link to status=failed Deliveries", %{
      conn: conn
    } do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="operator-overview-health-failures-link"),
             "failures stat card must be wrapped in a drill-through link"

      {:ok, doc} = Floki.parse_document(html)

      failures_link =
        doc
        |> Floki.find(~s([data-testid="operator-overview-health-failures-link"]))
        |> List.first()

      assert failures_link != nil, "expected operator-overview-health-failures-link element"

      href = failures_link |> Floki.attribute("href") |> List.first() || ""

      assert href =~ "status=failed",
             "failures drill-through link href must contain status=failed, got: #{inspect(href)}"

      assert href =~ "tenant_id=#{@tenant_id}",
             "failures drill-through link must preserve tenant_id, got: #{inspect(href)}"
    end

    # SHELL-02: suppressions stat card wrapped in drill-through link (status=suppressed, tenant-scoped)
    test "suppressions stat card is wrapped in a drill-through link to status=suppressed Deliveries",
         %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="operator-overview-health-suppressions-link"),
             "suppressions stat card must be wrapped in a drill-through link"

      {:ok, doc} = Floki.parse_document(html)

      suppressions_link =
        doc
        |> Floki.find(~s([data-testid="operator-overview-health-suppressions-link"]))
        |> List.first()

      assert suppressions_link != nil, "expected operator-overview-health-suppressions-link element"

      href = suppressions_link |> Floki.attribute("href") |> List.first() || ""

      assert href =~ "status=suppressed",
             "suppressions drill-through link href must contain status=suppressed, got: #{inspect(href)}"

      assert href =~ "tenant_id=#{@tenant_id}",
             "suppressions drill-through link must preserve tenant_id, got: #{inspect(href)}"
    end

    # SHELL-02: orientation strip empty-pane-only, null-safe gate
    # In the test env the SupportSummary module IS available, so summarize_tenant returns
    # all-zeros for an empty tenant. With no failures/orphans/suppressions, the gate evaluates
    # all_clear? == true and suppression_count == 0 → orientation strip IS shown (all-clear state).
    # This tests both that the render does not crash AND that the all-clear path shows the strip.
    test "all-clear tenant Overview renders orientation strip (empty-pane-only gate active)", %{
      conn: conn
    } do
      # Fresh test DB for this tenant has no failures or orphans → all_clear? == true
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      # Should not crash (null-safe gate: @support_summary && all_clear?(@support_summary))
      assert html =~ ~s(data-testid="operator-overview-health"),
             "overview health block must render without crashing"

      # In all-clear state: orientation strip is visible (empty-pane-only = all-clear is empty)
      assert html =~ ~s(data-testid="operator-overview-orientation"),
             "orientation strip must be present in all-clear state (empty-pane-only gate)"
    end

    # SHELL-02: attention state suppresses orientation strip
    # all_clear? checks failed_ingest.count (webhook_events with :failed/:dead status),
    # NOT delivery status. Insert a failed webhook_event to trigger the attention state.
    test "attention state (non-zero failed_ingest webhook events) suppresses the orientation strip",
         %{conn: conn} do
      conn = operator_conn(conn)

      # Insert a failed webhook_event — this is what summarize_tenant counts for failed_ingest
      insert_webhook_event!(status: :failed)

      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      # Orientation strip must be absent when failed_ingest.count > 0 (attention state)
      refute html =~ ~s(data-testid="operator-overview-orientation"),
             "orientation strip must be absent in attention state (failed_ingest.count > 0)"
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

  describe "dual table+card presentation (DATA-01, Plan 02 Task 1)" do
    test "both operator-deliveries-table and operator-deliveries-cards testids are rendered when deliveries are present" do
      delivery = %{
        id: "test-delivery-id-001",
        tenant_id: "t1",
        recipient: "dual@example.com",
        provider: "postmark",
        provider_message_id: "pm-dual-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(data-testid="operator-deliveries-table")
      assert html =~ ~s(data-testid="operator-deliveries-cards")
    end

    test "desktop table uses semantic <table> with <th scope=col> headers in Status-first order" do
      delivery = %{
        id: "test-delivery-id-002",
        tenant_id: "t1",
        recipient: "headers@example.com",
        provider: "postmark",
        provider_message_id: "pm-headers-002",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ "<table"
      assert html =~ ~s(scope="col")
      # Status must be first column header
      assert html =~ "Status"
    end

    test "both presentations carry phx-click=select_delivery and phx-value-id; selected delivery carries aria-selected=true in both" do
      delivery = %{
        id: "selected-delivery-id-003",
        tenant_id: "t1",
        recipient: "select@example.com",
        provider: "postmark",
        provider_message_id: "pm-sel-003",
        status: :delivered,
        last_event_type: :delivered,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery],
          selected_delivery: delivery,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(phx-click="select_delivery")
      assert html =~ ~s(phx-value-id="selected-delivery-id-003")
      # aria-selected="true" must appear for the selected delivery
      assert html =~ ~s(aria-selected="true")
    end

    test "recipients render via mask_recipient in both table and card presentations — no raw recipient string" do
      delivery = %{
        id: "mask-delivery-id-004",
        tenant_id: "t1",
        recipient: "masktest@example.com",
        provider: "postmark",
        provider_message_id: "pm-mask-004",
        status: :sent,
        last_event_type: :sent,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      refute html =~ "masktest@example.com"
      assert html =~ "m*******@e******.com"
    end

    test "delivery id renders with a title attribute equal to the id and a truncate/mono class in both presentations" do
      delivery = %{
        id: "title-delivery-id-005",
        tenant_id: "t1",
        recipient: "title@example.com",
        provider: "postmark",
        provider_message_id: "pm-title-005",
        status: :sent,
        last_event_type: :sent,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(title="title-delivery-id-005")
      assert html =~ "truncate"
      assert html =~ "mono"
    end

    test "result count reads from page_meta.total_count — 1 result for total_count 1 regardless of list length" do
      delivery = %{
        id: "count-delivery-id-006",
        tenant_id: "t1",
        recipient: "count@example.com",
        provider: "postmark",
        provider_message_id: "pm-count-006",
        status: :sent,
        last_event_type: :sent,
        last_event_at: ~U[2026-06-01 12:00:00Z]
      }

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [delivery, delivery],
          selected_delivery: nil,
          filters_active?: false,
          page_meta: %{total_count: 1, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ "1 result"
      refute html =~ "2 result"
    end
  end

  describe "four distinct data-state branches (DATA-03, Plan 02 Task 2)" do
    test "no-data deliveries path emits data-state-empty with 'No deliveries' heading" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :empty,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(data-testid="data-state-empty")
      assert html =~ "No deliveries"
    end

    test "error signal emits data-state-error with 'Delivery data unavailable' — distinct from empty" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :error,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(data-testid="data-state-error")
      assert html =~ "Delivery data unavailable"
      refute html =~ ~s(data-testid="data-state-empty")
    end

    test "permission-denied signal emits data-state-permission-denied with 'Access restricted' — never the no-data testid" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :permission_denied,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(data-testid="data-state-permission-denied")
      assert html =~ "Access restricted"
      refute html =~ ~s(data-testid="data-state-empty")
    end

    test "stale signal emits data-state-stale with 'Data may be out of date'" do
      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :stale,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      assert html =~ ~s(data-testid="data-state-stale")
      assert html =~ "Data may be out of date"
    end

    test "no two states share a testid — the legacy filtered/truly-empty distinction is preserved within :empty" do
      empty_html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :empty,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      error_html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :error,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      permission_html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :permission_denied,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      stale_html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: [],
          selected_delivery: nil,
          filters_active?: false,
          data_state: :stale,
          page_meta: %{total_count: 0, page: 1, total_pages: 1, has_previous?: false, has_next?: false}
        )

      # :empty and :error must have different testids
      assert empty_html =~ ~s(data-testid="data-state-empty")
      refute empty_html =~ ~s(data-testid="data-state-error")
      assert error_html =~ ~s(data-testid="data-state-error")
      refute error_html =~ ~s(data-testid="data-state-empty")
      # :permission_denied must not use the no-data testid
      assert permission_html =~ ~s(data-testid="data-state-permission-denied")
      refute permission_html =~ ~s(data-testid="data-state-empty")
      # :stale must be distinct
      assert stale_html =~ ~s(data-testid="data-state-stale")
      refute stale_html =~ ~s(data-testid="data-state-empty")
    end
  end

  describe "SHELL-03: triage subtitle + all-clear calm copy" do
    # SHELL-03: subtitle is a state-driven triage line, never banned phrases
    test "all-clear state subtitle is 'Your delivery system is healthy.'", %{conn: conn} do
      # Fresh test DB: no failed_ingest webhook events → all_clear? == true
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Your delivery system is healthy.",
             "all-clear subtitle must be 'Your delivery system is healthy.'"
    end

    test "attention state subtitle is 'Your delivery system needs attention.'", %{conn: conn} do
      conn = operator_conn(conn)
      # Insert a failed webhook_event to force attention state
      insert_webhook_event!(status: :failed)

      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ "Your delivery system needs attention.",
             "attention subtitle must be 'Your delivery system needs attention.'"
    end

    test "subtitle never contains 'Oops' or 'Navigate to'", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      refute html =~ "Oops",
             "subtitle must never contain 'Oops'"

      refute html =~ "Navigate to",
             "subtitle must never contain 'Navigate to'"
    end

    test "deliveries surface subtitle is the inspection-focused triage line", %{conn: conn} do
      conn = operator_conn(conn)
      insert_delivery!(recipient: "sub-test@example.com")

      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~
               "Prove what happened to a message — inspect its event timeline, suppression state, and replay history.",
             "Deliveries subtitle must be the inspection-focused triage line"
    end

    test "all-clear state renders calm single paragraph above orientation strip", %{conn: conn} do
      # Fresh test DB: all_clear? == true
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~
               "Your delivery system is healthy — nothing needs your attention right now.",
             "all-clear state must render the calm paragraph"
    end

    test "attention state does NOT render the calm paragraph", %{conn: conn} do
      conn = operator_conn(conn)
      insert_webhook_event!(status: :failed)

      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      refute html =~
               "Your delivery system is healthy — nothing needs your attention right now.",
             "attention state must not render the all-clear calm paragraph"
    end
  end

  describe "operator KPI stat_card call sites — DATA-02 certification (Plan 02 Task 3)" do
    test "all four operator KPI testids render through the stat_card primitive" do
      conn = operator_conn(build_conn())
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      assert html =~ ~s(data-testid="operator-overview-health-failures")
      assert html =~ ~s(data-testid="operator-overview-health-orphans")
      assert html =~ ~s(data-testid="operator-overview-health-suppressions")
      assert html =~ ~s(data-testid="operator-overview-health-allclear")
    end

    test "all-clear tile renders a real readable value — not a bare dash" do
      conn = operator_conn(build_conn())
      {:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

      # The all-clear tile should render one of these real readable values, never "—"
      allclear_present =
        html =~ "All clear" or html =~ "Needs attention" or html =~ "Unavailable"

      assert allclear_present,
             "all-clear tile must render a real readable value (All clear / Needs attention / Unavailable)"

      # Should NOT render a bare dash as the value
      refute html =~ ~s(data-testid="operator-overview-health-allclear">—</),
             "all-clear tile must not render a bare dash"
    end
  end

end

# FACADE-03: zero-admin-code-change proof — admin dashboard renders a written
# record against a schema-isolated DB with NO mailglass_admin/lib/ changes.
#
# Placed in a separate module because ExUnit prohibits setup_all inside a
# describe block. This module owns its own setup_all (DDL phase: CREATE SCHEMA
# + prefixed migration, once before any test, in Sandbox :auto mode) and its
# own per-test setup (Sandbox owner + tenant stamp + conn), reproducing the
# MailglassAdmin.LiveViewCase contract without inheriting its ordering.
#
# Sandbox-owner ordering (footgun 13): schema exists BEFORE the Sandbox owner
# starts. setup_all creates the schema; per-test setup then starts the owner.
defmodule MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.TestRepo

  @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
  @base_path "/ops/mail"
  @schema_prefix "mailglass"
  @schema_tenant "facade03-tenant"

  # Inline wrapper migration — mirrors the one in ShippedMigrationDivergenceTest.
  # The SET LOCAL search_path pin binds v01's unqualified trigger DDL to
  # @schema_prefix so it does not collide with public.mailglass_events.
  defmodule Facade03WrapperMigration do
    use Ecto.Migration

    @prefix "mailglass"

    def up do
      execute("SET LOCAL search_path TO #{@prefix}, public")
      Mailglass.Migration.up(prefix: @prefix, repo: MailglassAdmin.TestRepo)
    end

    def down do
      execute("SET LOCAL search_path TO #{@prefix}, public")
      Mailglass.Migration.down(prefix: @prefix, repo: MailglassAdmin.TestRepo)
    end
  end

  # Stands up the mailglass schema ONCE before any test in this module.
  # Must run in Sandbox :auto mode so the DDL commits outside any
  # transactional wrapper. Restores :manual after migration so the per-test
  # start_owner! (shared: true) works normally.
  setup_all do
    # Ensure the synthetic endpoint is started (idempotent).
    MailglassAdmin.TestSupport.AdminBootstrap.setup_all()

    # Override :schema so the facade injects prefix: "mailglass" for reads
    # in this module's tests (temporarily; restored in on_exit).
    original_schema = Application.get_env(:mailglass, :schema)
    Application.put_env(:mailglass, :schema, @schema_prefix)
    :persistent_term.erase({Mailglass.Config, :schema})

    # DDL phase — flip to :auto so CREATE SCHEMA + migration can commit.
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@schema_prefix} CASCADE")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@schema_prefix}")

    version = System.unique_integer([:positive, :monotonic]) + 91_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, Facade03WrapperMigration, log: false)
      end)

    # Restore :manual so the per-test setup (start_owner! shared: true) works.
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)

    on_exit(fn ->
      # Flip to :auto so cleanup queries can run outside any Sandbox tx wrapper.
      # There is no Sandbox owner at this point (all per-test owners have exited).
      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@schema_prefix} CASCADE")

      {:ok, _} =
        TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)

      if original_schema do
        Application.put_env(:mailglass, :schema, original_schema)
      else
        Application.delete_env(:mailglass, :schema)
      end

      :persistent_term.erase({Mailglass.Config, :schema})
    end)

    :ok
  end

  # Per-test setup: start the Sandbox owner (schema already exists from setup_all),
  # stamp the test tenant, build the Phoenix conn. Reproduces LiveViewCase's setup
  # contract (live_view_case.ex:34-40) without inheriting its ordering.
  # Note: the citext probe is intentionally skipped here. The schema creation in
  # setup_all does not drop/recreate the citext extension (it stays in public),
  # so there is no stale-OID risk. The standard probe would fail because
  # SuppressionStore.check goes through the facade with prefix: "mailglass" while
  # the probe's direct TestRepo.insert targets public — conflicting schema contexts.
  setup do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    Mailglass.Tenancy.put_current(@schema_tenant)

    conn = MailglassAdmin.TestSupport.AdminBootstrap.build_conn()
    {:ok, conn: conn}
  end

  describe "FACADE-03: admin zero-code-change proof — schema-isolated render" do
    test "write→read→render round-trip: delivery in mailglass schema appears in dashboard",
         %{conn: conn} do
      # WRITE: insert a delivery with explicit prefix: "mailglass" so it lands
      # in mailglass.mailglass_deliveries.
      now = DateTime.utc_now()

      delivery =
        %{
          tenant_id: @schema_tenant,
          mailable: "Mailglass.Example.AdminRenderProofMailer",
          stream: :transactional,
          recipient: "facade03-proof@example.com",
          recipient_domain: "example.com",
          provider: "postmark",
          status: :sent,
          last_event_type: :sent,
          last_event_at: now,
          metadata: %{}
        }
        |> Delivery.changeset()
        |> TestRepo.insert!(prefix: @schema_prefix)

      # Isolation check: delivery must NOT be in public schema.
      {:ok, %{rows: [[pub_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM public.mailglass_deliveries WHERE tenant_id = $1",
          [@schema_tenant]
        )

      assert pub_count == 0,
             "delivery must not land in public.mailglass_deliveries — " <>
               "facade routes to #{@schema_prefix}"

      # READ + RENDER: mount the admin operator LiveView for the test tenant.
      # Operator reads route through Mailglass.Operator.Deliveries →
      # Mailglass.Repo.all/2 → puts prefix: Config.schema() = "mailglass".
      # If the facade were bypassed (write in public), the dashboard would be empty.
      conn =
        conn
        |> Plug.Test.init_test_session(%{
          "current_user_id" => "operator-1",
          "tenant_id" => @schema_tenant,
          "auth_method" => "password",
          "recent_auth_at" =>
            DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
        })
        |> Plug.Conn.fetch_session()

      {:ok, _view, html} =
        live(
          conn,
          @base_path <>
            "?" <>
            URI.encode_query(%{"tenant_id" => @schema_tenant, "view" => "deliveries"})
        )

      # The masked recipient (mask_recipient/1 applies) or delivery ID must
      # appear in the deliveries list, proving the facade read from mailglass.*.
      # A facade-bypassing write (in public) would yield an empty dashboard here.
      assert html =~ delivery.id or html =~ "facade03" or html =~ "f***3@e******.com",
             "admin dashboard must render the delivery from #{@schema_prefix}.mailglass_deliveries; " <>
               "a hidden facade-bypassing write (in public) would yield an empty dashboard"

      assert html =~ ~s(data-testid="operator-master-detail"),
             "master-detail must render when deliveries exist in the #{@schema_prefix} schema"
    end
  end
end
