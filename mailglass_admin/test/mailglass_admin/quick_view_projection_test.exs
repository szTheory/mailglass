defmodule MailglassAdmin.QuickViewProjectionTest do
  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Operator.Deliveries
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

    assert persisted.last_event_at == expected.last_event_at

    persisted_html =
      render_component(&DeliveryQuickView.quick_view/1,
        Map.put(pure, :delivery, persisted)
      )

    pure_html = render_component(&DeliveryQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      assert html =~ expected.recipient
      assert html =~ expected.subject
      assert html =~ "Fjordline A/S"
      assert html =~ expected.provider_message_id
      assert html =~ expected.mailable
    end
  end

  test "normal Inbound pure facts match the tenant-scoped production projection" do
    pure = QuickViewScenarios.inbound(:northstar_normal)
    expected = pure.record

    %{record: inserted} =
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: expected.envelope_recipient,
        subject: expected.subject,
        received_at: expected.received_at
      )

    Tenancy.put_current(expected.tenant_id)

    page =
      MailglassInbound.list_records_page(
        %{tenant_id: expected.tenant_id, window_hours: 168},
        per_page: 20
      )

    assert [persisted] = page.entries
    assert persisted.id == inserted.id
    assert persisted.tenant_id == expected.tenant_id
    assert persisted.envelope_recipient == expected.envelope_recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.outcome == expected.outcome
    assert persisted.received_at == expected.received_at
    assert persisted.mailbox == expected.mailbox

    persisted_html =
      render_component(&InboundQuickView.quick_view/1,
        Map.put(pure, :record, persisted)
      )

    pure_html = render_component(&InboundQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      assert html =~ expected.envelope_recipient
      assert html =~ expected.subject
      assert html =~ "Northstar"
      assert html =~ String.upcase(expected.provider)
      assert html =~ "SupportMailbox"
    end
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
end
