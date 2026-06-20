defmodule MailglassDemo.DemoData do
  @moduledoc false

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias Mailglass.Webhook.WebhookEvent
  alias MailglassDemo.Repo
  alias MailglassInbound.InboundRecords

  @tenant "northstar"
  @empty_tenant "empty-tenant"

  # The seed anchor is resolved at reset! time, not compile time: a fixed
  # date ages the seeded evidence out of the operator surfaces' recency
  # windows (every list renders its empty state once the hardcoded day falls
  # out of range). Determinism is carried by IDs/counts/offsets — see
  # DemoDataResetTest.deterministic_keys/0 — never by absolute timestamps.
  @anchor_key :mailglass_demo_seed_anchor

  def tenant_id, do: @tenant
  def empty_tenant_id, do: @empty_tenant

  def reset! do
    Process.put(@anchor_key, DateTime.truncate(DateTime.utc_now(), :second))
    truncate!()
    seed_outbound!()
    seed_inbound!()
    # RATCHET-01 / D-06: materialize the persona stress cohort from the single
    # declarative spec. northstar is seeded by seed_outbound!/seed_inbound!
    # above (Personas.seed! no-ops it); this adds fjordline-aps (single
    # Delivery, non-ASCII / long-ID / null edge cases) and leaves helios-void
    # absent (zero deliveries — the no-data edge). Runs at every harness boot
    # via seeds.exs, which also serves RATCHET-04.
    MailglassDemo.Personas.seed!(Repo)
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
        metadata: %{
          "persona" => "operations lead",
          "journey" => "team invite",
          "scenario" => "invite_admin"
        }
      })

    event!(invite, :sent, minutes_ago(25), %{"provider" => "postmark", "source" => "api"})
    event!(invite, :delivered, minutes_ago(18), %{"provider" => "postmark", "source" => "webhook"})

    magic_link =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.magic_link",
        stream: :transactional,
        recipient: "alex.rivera@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-magic-link-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: minutes_ago(16),
        metadata: %{
          "persona" => "security admin",
          "journey" => "auth",
          "scenario" => "magic_link"
        }
      })

    event!(magic_link, :sent, minutes_ago(22), %{"provider" => "postmark", "source" => "api"})

    event!(magic_link, :delivered, minutes_ago(16), %{
      "provider" => "postmark",
      "source" => "webhook"
    })

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
        metadata: %{
          "invoice_id" => "INV-2026-0601",
          "plan" => "scale",
          "scenario" => "receipt_paid"
        }
      })

    receipt_webhook = webhook!("postmark", "pm-demo-receipt-001", "demo-receipt-delivery", 7101)
    event!(receipt, :sent, minutes_ago(50), replay_metadata(receipt_webhook, receipt))
    event!(receipt, :delivered, minutes_ago(44), %{"provider" => "postmark", "source" => "webhook"})

    payment_failed =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.BillingMailer.payment_failed",
        stream: :operational,
        recipient: "billing@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-payment-failed-001",
        status: :failed,
        last_event_type: :bounced,
        last_event_at: minutes_ago(20),
        metadata: %{
          "invoice_id" => "INV-2026-0602",
          "retry_window" => "24h",
          "scenario" => "payment_failed"
        }
      })

    event!(payment_failed, :sent, minutes_ago(24), %{"provider" => "postmark", "source" => "api"})

    event!(payment_failed, :bounced, minutes_ago(20), %{
      "provider" => "postmark",
      "classification" => "mailbox_full"
    })

    usage_alert =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.usage_alert",
        stream: :operational,
        recipient: "ops@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-usage-001",
        status: :failed,
        last_event_type: :bounced,
        last_event_at: minutes_ago(8),
        metadata: %{
          "threshold" => "85%",
          "support_case" => "CASE-1842",
          "scenario" => "usage_alert"
        }
      })

    usage_webhook =
      webhook!(
        "sendgrid",
        "sg-demo-usage-001",
        "demo-usage-bounce",
        7102,
        "Bounce",
        "bounced"
      )

    event!(usage_alert, :sent, minutes_ago(12), replay_metadata(usage_webhook, usage_alert))

    # A transient deferral before the hard bounce — exercises the amber
    # `deferred` timeline state and gives this delivery a richer multi-step
    # lifecycle (sent -> deferred -> bounced).
    event!(usage_alert, :deferred, minutes_ago(10), %{
      "provider" => "sendgrid",
      "classification" => "temporary_failure"
    })

    event!(usage_alert, :bounced, minutes_ago(8), %{
      "provider" => "sendgrid",
      "classification" => "mailbox_full"
    })

    incident_update =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.incident_update",
        stream: :operational,
        recipient: "ops@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-incident-001",
        status: :suppressed,
        last_event_type: :suppressed,
        last_event_at: minutes_ago(5),
        metadata: %{
          "incident" => "INC-7741",
          "status" => "monitoring",
          "scenario" => "incident_update"
        }
      })

    event!(incident_update, :suppressed, minutes_ago(5), %{
      "provider" => "mailglass",
      "reason" => "manual",
      "scenario" => "incident_update"
    })

    suppression!(
      incident_update.recipient,
      :manual,
      "support-case:1842",
      %{"scenario" => "incident_update", "reason" => "manual suppression"}
    )

    # --- Breadth seed: 9 missing event-type deliveries (GAP-16) ---

    queued_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "queued@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-badge-queued-001",
        status: :sent,
        last_event_type: :queued,
        last_event_at: minutes_ago(132),
        metadata: %{"scenario" => "badge_queued"}
      })

    event!(queued_d, :queued, minutes_ago(133), %{"provider" => "postmark", "source" => "api"})

    rejected_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "rejected@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-badge-rejected-001",
        status: :failed,
        last_event_type: :rejected,
        last_event_at: minutes_ago(134),
        metadata: %{"scenario" => "badge_rejected"}
      })

    event!(rejected_d, :sent, minutes_ago(135), %{"provider" => "postmark", "source" => "api"})

    event!(rejected_d, :rejected, minutes_ago(134), %{
      "provider" => "postmark",
      "classification" => "domain_block"
    })

    autoresponded_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "autoresponded@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-badge-autoresponded-001",
        status: :sent,
        last_event_type: :autoresponded,
        last_event_at: minutes_ago(136),
        metadata: %{"scenario" => "badge_autoresponded"}
      })

    event!(autoresponded_d, :sent, minutes_ago(137), %{"provider" => "sendgrid", "source" => "api"})

    event!(autoresponded_d, :autoresponded, minutes_ago(136), %{
      "provider" => "sendgrid",
      "classification" => "out_of_office"
    })

    opened_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.BillingMailer.receipt_paid",
        stream: :operational,
        recipient: "opened@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-badge-opened-001",
        status: :sent,
        last_event_type: :opened,
        last_event_at: minutes_ago(138),
        metadata: %{"scenario" => "badge_opened"}
      })

    event!(opened_d, :delivered, minutes_ago(139), %{"provider" => "postmark", "source" => "webhook"})

    event!(opened_d, :opened, minutes_ago(138), %{
      "provider" => "postmark",
      "user_agent" => "Outlook/16.0"
    })

    clicked_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.BillingMailer.receipt_paid",
        stream: :operational,
        recipient: "clicked@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-badge-clicked-001",
        status: :sent,
        last_event_type: :clicked,
        last_event_at: minutes_ago(140),
        metadata: %{"scenario" => "badge_clicked"}
      })

    event!(clicked_d, :delivered, minutes_ago(141), %{"provider" => "postmark", "source" => "webhook"})

    event!(clicked_d, :clicked, minutes_ago(140), %{
      "provider" => "postmark",
      "url" => "https://demo.example/cta"
    })

    complained_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.usage_alert",
        stream: :operational,
        recipient: "complained@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-badge-complained-001",
        status: :failed,
        last_event_type: :complained,
        last_event_at: minutes_ago(142),
        metadata: %{"scenario" => "badge_complained"}
      })

    event!(complained_d, :delivered, minutes_ago(143), %{"provider" => "sendgrid", "source" => "webhook"})

    event!(complained_d, :complained, minutes_ago(142), %{
      "provider" => "sendgrid",
      "classification" => "spam_complaint"
    })

    unsubscribed_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.usage_alert",
        stream: :operational,
        recipient: "unsubscribed@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-badge-unsubscribed-001",
        status: :sent,
        last_event_type: :unsubscribed,
        last_event_at: minutes_ago(144),
        metadata: %{"scenario" => "badge_unsubscribed"}
      })

    event!(unsubscribed_d, :delivered, minutes_ago(145), %{"provider" => "sendgrid", "source" => "webhook"})

    event!(unsubscribed_d, :unsubscribed, minutes_ago(144), %{
      "provider" => "sendgrid",
      "classification" => "list_unsubscribe"
    })

    subscribed_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "subscribed@northstar-ops.example",
        provider: "sendgrid",
        provider_message_id: "sg-demo-badge-subscribed-001",
        status: :sent,
        last_event_type: :subscribed,
        last_event_at: minutes_ago(146),
        metadata: %{"scenario" => "badge_subscribed"}
      })

    event!(subscribed_d, :subscribed, minutes_ago(146), %{
      "provider" => "sendgrid",
      "classification" => "list_subscribe"
    })

    unknown_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "unknown@northstar-ops.example",
        provider: "postmark",
        provider_message_id: "pm-demo-badge-unknown-001",
        status: :sent,
        last_event_type: :unknown,
        last_event_at: minutes_ago(148),
        metadata: %{"scenario" => "badge_unknown"}
      })

    event!(unknown_d, :unknown, minutes_ago(148), %{
      "provider" => "postmark",
      "raw_type" => "ProprietaryEvent"
    })

    # --- Truncation stress delivery: recipient local-part >= 80 chars (D-08 / GAP-16) ---

    stress_d =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient:
          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@northstar-stress.example",
        provider: "postmark",
        provider_message_id: "pm-demo-truncation-stress-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: minutes_ago(150),
        metadata: %{"scenario" => "truncation_stress"}
      })

    event!(stress_d, :sent, minutes_ago(151), %{"provider" => "postmark", "source" => "api"})

    event!(stress_d, :delivered, minutes_ago(150), %{
      "provider" => "postmark",
      "source" => "webhook"
    })

    # --- Replay-outcome events: all 3 branches (D-05 / GAP-13) ---

    event!(receipt, :webhook_replay_succeeded, minutes_ago(121), %{
      "provider" => "postmark",
      "outcome" => "replayed",
      "webhook_event_id" => "demo-replay-wh-001"
    })

    event!(receipt, :webhook_replay_succeeded, minutes_ago(122), %{
      "provider" => "postmark",
      "outcome" => "noop",
      "webhook_event_id" => "demo-replay-wh-002"
    })

    event!(usage_alert, :webhook_replay_failed, minutes_ago(123), %{
      "provider" => "sendgrid",
      "failure_reason" => "webhook_event_not_found"
    })

    # --- Orphan events: both reconcile-facts branches (D-06 / GAP-13) ---

    # Orphan A: will be pointed to by a :reconciled event (reconciled_count > 0)
    {:ok, orphan_a} =
      %{
        tenant_id: @tenant,
        delivery_id: nil,
        type: :sent,
        occurred_at: minutes_ago(128),
        needs_reconciliation: true,
        idempotency_key: "demo-orphan-reconciled-001",
        metadata: %{
          "provider" => "sendgrid",
          "provider_event_id" => "sg-orphan-a",
          "webhook_event_id" => "00000000-0000-0000-0000-000000000001",
          "provider_message_id" => "sg-orphan-msg-001"
        },
        normalized_payload: %{}
      }
      |> Event.changeset()
      |> Repo.insert()

    # Orphan B: no :reconciled event points to it (still_unmatched_count > 0)
    %{
      tenant_id: @tenant,
      delivery_id: nil,
      type: :sent,
      occurred_at: minutes_ago(129),
      needs_reconciliation: true,
      idempotency_key: "demo-orphan-unmatched-001",
      metadata: %{
        "provider" => "sendgrid",
        "provider_event_id" => "sg-orphan-b",
        "webhook_event_id" => "00000000-0000-0000-0000-000000000002",
        "provider_message_id" => "sg-orphan-msg-002"
      },
      normalized_payload: %{}
    }
    |> Event.changeset()
    |> Repo.insert!()

    # :reconciled event — links orphan_a to the invite delivery
    %{
      tenant_id: @tenant,
      delivery_id: invite.id,
      type: :reconciled,
      occurred_at: minutes_ago(127),
      idempotency_key: "reconciled:" <> to_string(orphan_a.id),
      metadata: %{
        "reconciled_from_event_id" => to_string(orphan_a.id),
        "reconciled_provider" => "sendgrid",
        "reconciled_provider_event_id" => "sg-demo-reconciled-event-001"
      },
      normalized_payload: %{}
    }
    |> Event.changeset()
    |> Repo.insert!()

    # --- Failed-ingest WebhookEvent: triggers Tier-1 failed_ingest support card (GAP-13) ---

    %{
      tenant_id: @tenant,
      provider: "sendgrid",
      provider_event_id: "sg-demo-failed-ingest-001",
      event_type_raw: "Bounce",
      event_type_normalized: "bounced",
      status: :failed,
      raw_payload: %{"RecordType" => "Bounce", "error" => "parse_failure"},
      received_at: minutes_ago(124),
      processed_at: minutes_ago(124)
    }
    |> WebhookEvent.changeset()
    |> Repo.insert!()
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
        headers: %{"x-demo-priority" => "high", "x-demo-scenario" => "support_reply"},
        metadata: %{"scenario" => "support_reply"}
      })

    evidence = inbound_evidence!(support, %{"provider" => "mailgun", "signature" => "verified"})
    inbound_run!(support, evidence, :fresh, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
    inbound_run!(support, evidence, :replay, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")

    refund =
      inbound_record!(%{
        provider: "mailgun",
        provider_message_id: "mg-demo-refund-001",
        envelope_recipient: "billing@demo.mailglass.local",
        from: [%{"name" => "Andre Mills", "address" => "andre.mills@northstar-ops.example"}],
        to: [%{"address" => "billing@demo.mailglass.local"}],
        subject: "[billing] Refund request for INV-2026-0602",
        text_body: "Please process a refund because the card was charged twice.",
        headers: %{"x-demo-priority" => "medium", "x-demo-scenario" => "refund_request"},
        metadata: %{"scenario" => "refund_request"}
      })

    refund_evidence =
      inbound_evidence!(refund, %{"provider" => "mailgun", "signature" => "verified"})

    inbound_run!(
      refund,
      refund_evidence,
      :fresh,
      :bounce,
      "MailglassDemoWeb.Inbound.SupportMailbox",
      "mailbox_full"
    )

    inbound_run!(
      refund,
      refund_evidence,
      :replay,
      :bounce,
      "MailglassDemoWeb.Inbound.SupportMailbox",
      "mailbox_full"
    )

    spam =
      inbound_record!(%{
        provider: "postmark",
        provider_message_id: "pm-demo-spam-001",
        envelope_recipient: "support@demo.mailglass.local",
        from: [%{"address" => "bulk-sender@spam.local"}],
        to: [%{"address" => "support@demo.mailglass.local"}],
        subject: "[promo] Buy follower bundles now",
        text_body: "Limited-time offer from a blocked sender.",
        headers: %{"x-demo-priority" => "low", "x-demo-scenario" => "spam_reject"},
        metadata: %{"scenario" => "spam_reject"}
      })

    spam_evidence =
      inbound_evidence!(spam, %{"provider" => "postmark", "signature" => "verified"})

    inbound_run!(
      spam,
      spam_evidence,
      :fresh,
      :reject,
      "MailglassDemoWeb.Inbound.SupportMailbox",
      "spam"
    )

    no_match =
      inbound_record!(%{
        provider: "postmark",
        provider_message_id: "pm-inbound-demo-nomatch-001",
        envelope_recipient: "unknown@demo.mailglass.local",
        from: [%{"address" => "vendor@partners.example"}],
        to: [%{"address" => "unknown@demo.mailglass.local"}],
        subject: "Unrouted vendor notice",
        text_body: "This recipient intentionally does not match a route.",
        headers: %{"x-demo-scenario" => "inbound_no_match"},
        metadata: %{"scenario" => "inbound_no_match"}
      })

    no_match_evidence =
      inbound_evidence!(no_match, %{"provider" => "postmark", "signature" => "verified"})

    inbound_run!(no_match, no_match_evidence, :fresh, :no_match, nil)

    # --- :ignore inbound outcome (D-04 / GAP-16) ---
    # inbound_record!/1 hardcodes received_at: minutes_ago(5), so call InboundRecords API directly.
    {:ok, ignore_record} =
      InboundRecords.insert_inbound_record(%{
        tenant_id: @tenant,
        provider: "postmark",
        provider_message_id: "pm-demo-inbound-ignore-001",
        envelope_recipient: "support@demo.mailglass.local",
        from: [%{"address" => "autoresponder@partner-crm.example"}],
        to: [%{"address" => "support@demo.mailglass.local"}],
        subject: "RE: Your request has been noted",
        text_body: "This is an automated acknowledgement. No action is required.",
        headers: %{"x-demo-scenario" => "inbound_ignore"},
        metadata: %{"scenario" => "inbound_ignore"},
        attachments: [],
        received_at: minutes_ago(30)
      })

    ignore_evidence =
      inbound_evidence!(ignore_record, %{"provider" => "postmark", "signature" => "verified"})

    # :ignore requires mailbox present + failure: %{} — pass outcome: :ignore directly
    inbound_run!(
      ignore_record,
      ignore_evidence,
      :fresh,
      :ignore,
      "MailglassDemoWeb.Inbound.SpamMailbox"
    )

    # --- :failed inbound outcome + truncation stress subject >= 150 chars (D-04 / D-08 / GAP-16) ---
    {:ok, failed_record} =
      InboundRecords.insert_inbound_record(%{
        tenant_id: @tenant,
        provider: "mailgun",
        provider_message_id: "mg-demo-inbound-failed-001",
        envelope_recipient: "support@demo.mailglass.local",
        from: [%{"address" => "noreply@vendor-platform.example"}],
        to: [%{"address" => "support@demo.mailglass.local"}],
        subject:
          "This is a very long subject line for a vendor notification that was not expected and has exceeded the maximum subject line length that the truncation column can display without ellipsis overflow occurring here",
        text_body: "Automated vendor notification that failed to be parsed by the mailbox router.",
        headers: %{"x-demo-scenario" => "inbound_failed"},
        metadata: %{"scenario" => "inbound_failed"},
        attachments: [],
        received_at: minutes_ago(35)
      })

    failed_evidence =
      inbound_evidence!(failed_record, %{"provider" => "mailgun", "signature" => "verified"})

    # :failed outcome requires execution_failure with non-empty map — call insert_execution_run directly
    {:ok, _failed_run} =
      InboundRecords.insert_execution_run(%{
        tenant_id: @tenant,
        inbound_record_id: failed_record.id,
        inbound_evidence_id: failed_evidence.id,
        source: :fresh,
        executed_at: minutes_ago(36),
        metadata: %{"demo" => true},
        execution_failure: %{"reason" => "parse_error", "provider" => "mailgun"}
      })
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

  defp webhook!(
         provider,
         message_id,
         provider_event_id,
         event_id,
         event_type_raw \\ "Delivery",
         event_type_normalized \\ "delivered"
       ) do
    %{
      tenant_id: @tenant,
      provider: provider,
      provider_event_id: provider_event_id,
      event_type_raw: event_type_raw,
      event_type_normalized: event_type_normalized,
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

  defp suppression!(address, reason, source, metadata) do
    %{
      tenant_id: @tenant,
      address: address,
      scope: :address,
      reason: reason,
      source: source,
      metadata: metadata
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

  defp inbound_run!(record, evidence, source, outcome, mailbox, outcome_reason \\ nil) do
    attrs = %{
      tenant_id: @tenant,
      inbound_record_id: record.id,
      inbound_evidence_id: evidence.id,
      source: source,
      outcome: outcome,
      outcome_reason: outcome_reason,
      mailbox: mailbox,
      executed_at: minutes_ago(if(source == :replay, do: 2, else: 4)),
      metadata: %{"demo" => true}
    }

    {:ok, run} = InboundRecords.insert_execution_run(attrs)
    run
  end

  defp replay_metadata(webhook, delivery) do
    %{
      "provider" => delivery.provider,
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

  defp minutes_ago(minutes), do: DateTime.add(seed_anchor(), -minutes, :minute)

  defp seed_anchor do
    Process.get(@anchor_key) || DateTime.truncate(DateTime.utc_now(), :second)
  end
end
