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
  alias MailglassAdmin.OperatorLive
  alias MailglassAdmin.StatusMap
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"
  @base_path "/ops/mail"
  @attention_classes [:failed, :delayed, :not_sent]
  @undetermined "Status cannot be fully determined with this mailglass version."

  # {label, delivery attrs, bucket the single row must land in}. One row per class,
  # plus the rows D-07 says leave Needs attention (a complaint or an unsubscribe with
  # no delivery problem behind it) and queued, which is Awaiting.
  @bucket_rows [
    {"sent", %{last_event_type: :sent}, :awaiting},
    {"queued", %{status: :queued, last_event_type: :queued}, :awaiting},
    {"delivered", %{last_event_type: :delivered, delivered_at: :hours_ago_2, terminal: true},
     :delivered},
    {"delayed", %{last_event_type: :deferred}, :attention},
    {"failed", %{last_event_type: :bounced, bounced_at: :hours_ago_2, terminal: true},
     :attention},
    {"not sent", %{last_event_type: :suppressed, suppressed_at: :hours_ago_2, terminal: true},
     :attention},
    {"complained with no delivery problem",
     %{last_event_type: :complained, complained_at: :hours_ago_2, terminal: true}, :awaiting},
    {"unsubscribed with no delivery problem", %{last_event_type: :unsubscribed}, :awaiting}
  ]

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

  describe "summary re-bucket (C-16)" do
    for {label, attrs, bucket} <- @bucket_rows do
      test "#{label} lands in #{bucket} and nowhere else", %{conn: conn} do
        OperatorFixtures.reset!()
        insert_delivery!(resolve_times(unquote(Macro.escape(attrs))))

        {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
        html = render(view)

        counts = Map.new([:attention, :delivered, :awaiting], &{&1, summary_count(html, &1)})

        assert counts ==
                 Map.merge(%{attention: 0, delivered: 0, awaiting: 0}, %{unquote(bucket) => 1}),
               "#{unquote(label)} should count once under #{unquote(bucket)}, got #{inspect(counts)}"
      end
    end

    test "Needs attention is exactly failed, delayed and not sent", %{conn: conn} do
      OperatorFixtures.reset!()

      for {label, attrs, _bucket} <- @bucket_rows do
        slug = label |> String.replace(~r/[^a-z]+/, "-") |> String.trim("-")

        insert_delivery!(
          attrs
          |> resolve_times()
          |> Map.merge(%{
            recipient: "bucket-#{slug}@example.com",
            provider_message_id: "pm_bucket_#{slug}"
          })
        )
      end

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == 3
      assert summary_count(html, :delivered) == 1
      assert summary_count(html, :awaiting) == 4
    end
  end

  describe "summary without lifecycle keys (D-06)" do
    test "an outcome group from an older core reads undetermined, never a count" do
      three_field_group = %{
        status: :sent,
        last_event_type: :opened,
        delivery_confirmed: false,
        count: 1
      }

      assert {:undetermined, @undetermined} =
               OperatorLive.delivery_summary(%{outcome_groups: [three_field_group]})
    end

    test "one group missing the key makes the whole summary undetermined" do
      complete = %{
        status: :sent,
        last_event_type: :sent,
        delivery_confirmed: false,
        bounced_at: nil,
        terminal: nil,
        complained_at: nil,
        suppressed_at: nil,
        count: 2
      }

      old = Map.drop(complete, [:bounced_at, :terminal, :complained_at, :suppressed_at])

      assert {:undetermined, @undetermined} =
               OperatorLive.delivery_summary(%{outcome_groups: [complete, old]})
    end

    test "groups that carry the keys, and an empty page, keep the three counts" do
      complete = %{
        status: :sent,
        last_event_type: :opened,
        delivery_confirmed: false,
        bounced_at: true,
        terminal: true,
        complained_at: nil,
        suppressed_at: nil,
        count: 3
      }

      for page <- [%{outcome_groups: [complete]}, %{outcome_groups: []}, %{}] do
        assert [{:delivered, _, _, _}, {:attention, _, _, _}, {:awaiting, _, _, _}] =
                 OperatorLive.delivery_summary(page)
      end

      assert [{:delivered, _, 0, _}, {:attention, _, 3, _}, {:awaiting, _, 0, _}] =
               OperatorLive.delivery_summary(%{outcome_groups: [complete]})
    end
  end

  # -- helpers (only what this file calls: the admin lane is --warnings-as-errors) --

  # Rows are declared at compile time, so a timestamp is a marker resolved at runtime.
  defp resolve_times(attrs) do
    Map.new(attrs, fn
      {key, :hours_ago_2} -> {key, DateTime.add(DateTime.utc_now(), -2, :hour)}
      pair -> pair
    end)
  end

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
