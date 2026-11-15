defmodule MailglassAdmin.Phase182JourneyTest do
  @moduledoc """
  Required-lane proof of the "password reset never arrived" journey (Phase 182,
  BRADM-01, D-20). This file grows one describe per step of the journey across the
  Phase 182 plans; this plan owns the summary.

  The summary buckets every delivery by `MailglassAdmin.StatusMap.delivery_class/1`
  (D-07): Needs attention is failed + delayed + not sent, Delivered is delivered,
  Awaiting confirmation is sent (queued included). A bounce followed by an open is
  Failed, so it is counted under Needs attention and never under Delivered.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Operator.Deliveries
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.StatusMap
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"
  @base_path "/ops/mail"
  @attention_classes [:failed, :delayed, :not_sent]

  describe "summary (D-07)" do
    test "counts every seeded delivery under the bucket its class names", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      classes =
        Map.new(ids, fn {case_id, id} ->
          row = Deliveries.get_delivery(%{tenant_id: @tenant_id, delivery_id: id}, [])
          {case_id, StatusMap.delivery_class(row)}
        end)

      expected_attention =
        Enum.count(classes, fn {_case, class} -> class in @attention_classes end)

      expected_delivered = Enum.count(classes, fn {_case, class} -> class == :delivered end)
      expected_awaiting = Enum.count(classes, fn {_case, class} -> class == :sent end)

      # Non-vacuity: the seed spans every bucket, and the bounce then open row is Failed.
      assert expected_attention > 0 and expected_delivered > 0 and expected_awaiting > 0
      assert classes.bounce_then_open == :failed
      assert expected_attention + expected_delivered + expected_awaiting == map_size(ids)

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == expected_attention
      assert summary_count(html, :delivered) == expected_delivered
      assert summary_count(html, :awaiting) == expected_awaiting
    end

    test "a bounce followed by an open is Needs attention, not Delivered", %{conn: conn} do
      OperatorFixtures.reset!()

      insert_delivery!(%{
        recipient: "pw-bounce-then-open@example.com",
        status: :sent,
        last_event_type: :opened,
        bounced_at: DateTime.add(DateTime.utc_now(), -5, :hour),
        terminal: true
      })

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == 1
      assert summary_count(html, :delivered) == 0
      assert summary_count(html, :awaiting) == 0
    end
  end

  # -- helpers (only what this file calls: the admin lane is --warnings-as-errors) --

  defp deliveries_path do
    @base_path <> "?" <> URI.encode_query(%{"tenant_id" => @tenant_id, "view" => "deliveries"})
  end

  # The integer inside the summary stat card `#delivery-summary-<key>`.
  defp summary_count(html, key) do
    [value] =
      html
      |> Floki.parse_document!()
      |> Floki.find("#delivery-summary-#{key} p.tabular-nums")
      |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

    value |> String.replace(",", "") |> String.to_integer()
  end

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      mailable: "MailglassAdmin.Fixtures.AccountMailer",
      stream: :transactional,
      recipient: "operator@example.com",
      provider: "postmark",
      provider_message_id: "pm_default",
      status: :sent,
      last_event_type: :sent,
      last_event_at: DateTime.add(DateTime.utc_now(), -1, :hour),
      metadata: %{"subject" => "Reset your password"}
    }

    attrs
    |> Enum.into(defaults)
    |> Delivery.changeset()
    |> MailglassAdmin.TestRepo.insert!()
  end
end
