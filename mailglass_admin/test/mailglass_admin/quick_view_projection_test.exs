defmodule MailglassAdmin.QuickViewProjectionTest do
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Operator.Deliveries
  alias Mailglass.Events.Event
  alias Mailglass.Tenancy
  alias MailglassAdmin.Inbound.QuickView, as: InboundQuickView
  alias MailglassAdmin.OptionalDeps.MailglassInbound
  alias MailglassAdmin.Operator.QuickView, as: DeliveryQuickView
  alias MailglassAdmin.TestSupport.{InboundFixtures, OperatorFixtures}
  alias MailglassDemo.QuickViewScenarios

  test "Fjordline Delivery pure facts match the tenant-scoped production projection" do
    OperatorFixtures.seed_persona_cohort!()
    Tenancy.put_current("fjordline-aps")

    page =
      Deliveries.list_recent_deliveries_page(
        %{tenant_id: "fjordline-aps", window_hours: 168},
        per_page: 20
      )

    assert [persisted] = page.entries
    assert page.total_count == 1

    pure = QuickViewScenarios.delivery(:fjordline_single_unicode)
    expected = pure.delivery

    assert persisted.tenant_id == "fjordline-aps"
    assert persisted.recipient == expected.recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.provider_message_id == expected.provider_message_id
    assert persisted.mailable == expected.mailable
    assert persisted.status == expected.status
    assert persisted.last_event_type == expected.last_event_type

    # These timestamps are independently anchored by each materializer.
    assert %DateTime{} = persisted.last_event_at
    assert %DateTime{} = expected.last_event_at
    assert pure.position == %{index: 1, total: page.total_count}

    # The persona's legitimate nil reject reason is outside this list projection.
    assert %Event{reject_reason: nil} =
             TestRepo.one(
               from(event in Event,
                 where: event.tenant_id == "fjordline-aps" and event.type == :delivered,
                 select: event
               )
             )

    persisted_html =
      render_component(
        &DeliveryQuickView.quick_view/1,
        Map.put(pure, :delivery, persisted)
      )

    pure_html = render_component(&DeliveryQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.recipient
      assert text =~ expected.subject
      assert text =~ "Fjordline A/S"
      assert text =~ "POSTMARK"
      assert text =~ "Delivered"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
  end

  test "normal Inbound facts match the scoped production projection at position 3 of 6" do
    pure = QuickViewScenarios.inbound(:northstar_normal)
    expected = pure.record

    newer_times = [
      DateTime.add(expected.received_at, 3_600),
      DateTime.add(expected.received_at, 1_800)
    ]

    older_times = [
      DateTime.add(expected.received_at, -1_800),
      DateTime.add(expected.received_at, -3_600),
      DateTime.add(expected.received_at, -5_400)
    ]

    Enum.each(newer_times ++ older_times, fn received_at ->
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: "neighbor-#{DateTime.to_unix(received_at)}@northstar.example",
        subject: "Neighbor record",
        received_at: received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )
    end)

    %{record: inserted} =
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: expected.envelope_recipient,
        subject: expected.subject,
        received_at: expected.received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )

    Tenancy.put_current(expected.tenant_id)

    page =
      MailglassInbound.list_records_page(
        %{tenant_id: expected.tenant_id, window_hours: 168},
        per_page: 20
      )

    assert page.total_count == 6
    index = Enum.find_index(page.entries, &(&1.id == inserted.id))
    assert index == 2
    persisted = Enum.at(page.entries, index)
    assert persisted.id == inserted.id
    assert persisted.tenant_id == expected.tenant_id
    assert persisted.envelope_recipient == expected.envelope_recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.outcome == expected.outcome

    assert DateTime.truncate(persisted.received_at, :second) ==
             DateTime.truncate(expected.received_at, :second)

    assert persisted.mailbox == expected.mailbox

    persisted_html =
      render_component(
        &InboundQuickView.quick_view/1,
        Map.put(pure, :record, persisted)
      )

    pure_html = render_component(&InboundQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.envelope_recipient
      assert text =~ expected.subject
      assert text =~ pure.account_labels[expected.tenant_id]
      assert text =~ String.upcase(expected.provider)
      assert text =~ "Accepted"
      assert text =~ "SupportMailbox"
      assert text =~ "3 of 6"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
    assert pure.position == %{index: index + 1, total: page.total_count}
  end

  test "Unicode Inbound facts stay exact and foreign Account rows remain excluded" do
    pure = QuickViewScenarios.inbound(:fjordline_single_unicode)
    expected = pure.record

    %{record: inserted} =
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: expected.envelope_recipient,
        subject: expected.subject,
        received_at: expected.received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )

    %{record: foreign} =
      InboundFixtures.seed_matched!("other-account",
        provider: "postmark",
        recipient: "foreign@example.test",
        subject: "Foreign Account message",
        received_at: expected.received_at
      )

    Tenancy.put_current(expected.tenant_id)

    page =
      MailglassInbound.list_records_page(
        %{tenant_id: expected.tenant_id, window_hours: 168},
        per_page: 20
      )

    assert [persisted] = page.entries
    assert page.total_count == 1
    assert persisted.id == inserted.id
    assert persisted.tenant_id == expected.tenant_id
    assert persisted.envelope_recipient == expected.envelope_recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.outcome == expected.outcome

    assert DateTime.truncate(persisted.received_at, :second) ==
             DateTime.truncate(expected.received_at, :second)

    assert persisted.mailbox == expected.mailbox

    persisted_html =
      render_component(
        &InboundQuickView.quick_view/1,
        Map.put(pure, :record, persisted)
      )

    pure_html = render_component(&InboundQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.envelope_recipient
      assert text =~ expected.subject
      assert text =~ pure.account_labels[expected.tenant_id]
      assert text =~ String.upcase(expected.provider)
      assert text =~ "Accepted"
      assert text =~ "SupportMailbox"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
    refute Enum.any?(page.entries, &(&1.id == foreign.id))
    assert pure.position == %{index: 1, total: page.total_count}
  end

  test "Helios stays absent and unavailable Inbound remains an honest rendering-only state" do
    OperatorFixtures.seed_persona_cohort!()
    Tenancy.put_current("helios-void")

    delivery_page =
      Deliveries.list_recent_deliveries_page(
        %{tenant_id: "helios-void", window_hours: 168},
        per_page: 20
      )

    assert delivery_page.entries == []

    assert Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)

    inbound_page =
      MailglassInbound.list_records_page(%{tenant_id: "helios-void", window_hours: 168},
        per_page: 20
      )

    assert inbound_page.entries == []

    unavailable = QuickViewScenarios.inbound(:selected_unavailable)
    assert unavailable.record == nil
    assert unavailable.detail_error == :read_unavailable

    html = render_component(&InboundQuickView.quick_view/1, unavailable)
    assert html =~ "temporarily unavailable"
    refute html =~ "SupportMailbox"
    refute html =~ "Record ID"
  end

  defp rendered_text(html), do: Regex.replace(~r/<[^>]*>/, html, "")
end
