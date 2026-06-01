defmodule MailglassDemo.DemoData do
  @moduledoc false

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Webhook.WebhookEvent
  alias MailglassDemo.Repo
  alias MailglassInbound.InboundRecords

  @tenant "northstar"
  @now ~U[2026-06-01 15:00:00Z]

  def tenant_id, do: @tenant

  def reset! do
    truncate!()
    seed_outbound!()
    seed_inbound!()
    :ok
  end

  def summary do
    %{
      tenant_id: @tenant,
      deliveries: Repo.aggregate(Delivery, :count),
      events: Repo.aggregate(Event, :count),
      inbound: count_table!("mailglass_inbound_records"),
      suppressions: Repo.aggregate(Entry, :count)
    }
  end

  defp seed_outbound! do
    invite =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "mira.chen@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-invite-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: minutes_ago(18),
        metadata: %{"persona" => "operations lead", "journey" => "team invite"}
      })

    event!(invite, :sent, minutes_ago(25), %{"provider" => "postmark", "source" => "api"})
    event!(invite, :delivered, minutes_ago(18), %{"provider" => "postmark", "source" => "webhook"})

    receipt =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.BillingMailer.receipt_paid",
        stream: :operational,
        recipient: "billing@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-receipt-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: minutes_ago(44),
        metadata: %{"invoice_id" => "INV-2026-0601", "plan" => "scale"}
      })

    receipt_webhook = webhook!("pm-demo-receipt-001", "demo-receipt-delivery", 7101)
    event!(receipt, :sent, minutes_ago(50), replay_metadata(receipt_webhook, receipt))
    event!(receipt, :delivered, minutes_ago(44), %{"provider" => "postmark", "source" => "webhook"})

    alert =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.usage_alert",
        stream: :operational,
        recipient: "ops@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-usage-001",
        status: :failed,
        last_event_type: :bounced,
        last_event_at: minutes_ago(8),
        metadata: %{"threshold" => "85%", "support_case" => "CASE-1842"}
      })

    event!(alert, :sent, minutes_ago(12), %{"provider" => "sendgrid", "source" => "api"})

    event!(alert, :bounced, minutes_ago(8), %{
      "provider" => "sendgrid",
      "classification" => "mailbox_full"
    })

    suppression!(alert.recipient, :manual, "support-case:1842")
  end

  defp seed_inbound! do
    support =
      inbound_record!(%{
        provider: "mailgun",
        provider_message_id: "mg-demo-support-001",
        envelope_recipient: "support@demo.mailglass.local",
        from: [%{"name" => "Mira Chen", "address" => "mira.chen@northstar-ops.example"}],
        to: [%{"address" => "support@demo.mailglass.local"}],
        subject: "[support] Invite email did not arrive",
        text_body: "Can you confirm whether the invite bounced or was suppressed?",
        headers: %{"x-demo-priority" => "high"}
      })

    evidence = inbound_evidence!(support, %{"provider" => "mailgun", "signature" => "verified"})
    inbound_run!(support, evidence, :fresh, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
    inbound_run!(support, evidence, :replay, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")

    no_match =
      inbound_record!(%{
        provider: "postmark",
        provider_message_id: "pm-inbound-demo-nomatch-001",
        envelope_recipient: "unknown@demo.mailglass.local",
        from: [%{"address" => "vendor@example.net"}],
        to: [%{"address" => "unknown@demo.mailglass.local"}],
        subject: "Unrouted vendor notice",
        text_body: "This recipient intentionally does not match a route."
      })

    no_match_evidence =
      inbound_evidence!(no_match, %{"provider" => "postmark", "signature" => "verified"})

    inbound_run!(no_match, no_match_evidence, :fresh, :no_match, nil)
  end

  defp delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant,
      adapter_ref: Delivery.default_adapter_ref(),
      terminal: false,
      idempotency_key: "demo-delivery-#{attrs.provider_message_id}"
    }

    attrs
    |> Map.merge(defaults)
    |> Delivery.changeset()
    |> Repo.insert!()
  end

  defp event!(delivery, type, occurred_at, metadata) do
    %{
      tenant_id: @tenant,
      delivery_id: delivery.id,
      type: type,
      occurred_at: occurred_at,
      idempotency_key:
        "demo-event-#{delivery.provider_message_id}-#{type}-#{DateTime.to_unix(occurred_at)}",
      metadata: metadata,
      normalized_payload: %{"recipient" => delivery.recipient}
    }
    |> Event.changeset()
    |> Repo.insert!()
  end

  defp webhook!(message_id, provider_event_id, event_id) do
    %{
      tenant_id: @tenant,
      provider: "postmark",
      provider_event_id: provider_event_id,
      event_type_raw: "Delivery",
      event_type_normalized: "delivered",
      status: :succeeded,
      raw_payload: %{
        "RecordType" => "Delivery",
        "MessageID" => message_id,
        "ID" => event_id,
        "DeliveredAt" => "2026-06-01T14:10:00Z"
      },
      received_at: minutes_ago(45),
      processed_at: minutes_ago(44)
    }
    |> WebhookEvent.changeset()
    |> Repo.insert!()
  end

  defp suppression!(address, reason, source) do
    %{
      tenant_id: @tenant,
      address: address,
      scope: :address,
      reason: reason,
      source: source,
      metadata: %{"demo" => true}
    }
    |> Entry.changeset()
    |> Repo.insert!()
  end

  defp inbound_record!(attrs) do
    {:ok, record} =
      attrs
      |> Map.merge(%{tenant_id: @tenant, received_at: minutes_ago(5), attachments: []})
      |> InboundRecords.insert_inbound_record()

    record
  end

  defp inbound_evidence!(record, verification_facts) do
    {:ok, evidence} =
      InboundRecords.insert_inbound_evidence(%{
        tenant_id: @tenant,
        inbound_record_id: record.id,
        provider: record.provider,
        raw_payload: %{"demo_record_id" => record.provider_message_id},
        raw_headers: record.headers || %{},
        verification_facts: verification_facts,
        parse_warnings: %{}
      })

    evidence
  end

  defp inbound_run!(record, evidence, source, outcome, mailbox) do
    attrs = %{
      tenant_id: @tenant,
      inbound_record_id: record.id,
      inbound_evidence_id: evidence.id,
      source: source,
      outcome: outcome,
      mailbox: mailbox,
      executed_at: minutes_ago(if(source == :replay, do: 2, else: 4)),
      metadata: %{"demo" => true}
    }

    {:ok, run} = InboundRecords.insert_execution_run(attrs)
    run
  end

  defp replay_metadata(webhook, delivery) do
    %{
      "provider" => "postmark",
      "provider_event_id" => "demo-receipt-child",
      "webhook_event_id" => webhook.id,
      "webhook_provider_event_id" => webhook.provider_event_id,
      "message_id" => delivery.provider_message_id
    }
  end

  defp truncate! do
    Repo.query!("""
    TRUNCATE TABLE
      mailglass_inbound_replay_runs,
      mailglass_inbound_evidence,
      mailglass_inbound_records,
      mailglass_webhook_events,
      mailglass_events,
      mailglass_suppressions,
      mailglass_deliveries
    RESTART IDENTITY CASCADE
    """)
  end

  defp count_table!(table) do
    %{rows: [[count]]} = Repo.query!("SELECT count(*) FROM #{table}")
    count
  end

  defp minutes_ago(minutes), do: DateTime.add(@now, -minutes, :minute)
end
