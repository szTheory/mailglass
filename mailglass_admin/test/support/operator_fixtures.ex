defmodule MailglassAdmin.TestSupport.OperatorFixtures do
  @moduledoc false

  alias Mailglass.Events.Event
  alias Mailglass.IdempotencyKey
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.TestRepo
  alias Mailglass.Webhook.WebhookEvent

  @tenant_id "browser-tenant"

  def seed_browser_scenario! do
    reset!()

    selected_delivery =
      insert_delivery!(%{
        recipient: "browser-selected@example.com",
        provider: "postmark",
        provider_message_id: "pm_browser_selected",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: hours_ago(1),
        mailable: "Mailglass.Example.BrowserMailer"
      })

    insert_event!(selected_delivery, %{
      type: :sent,
      occurred_at: hours_ago(3),
      metadata: %{provider: "postmark", source: "api"}
    })

    insert_event!(selected_delivery, %{
      type: :delivered,
      occurred_at: hours_ago(2),
      metadata: %{provider: "postmark", source: "webhook"}
    })

    insert_suppression!(%{
      tenant_id: @tenant_id,
      address: selected_delivery.recipient,
      scope: :address,
      reason: :manual,
      source: "ops:review"
    })

    exact_delivery =
      insert_delivery!(%{
        recipient: "browser-exact@example.com",
        provider: "postmark",
        provider_message_id: "pm_browser_exact",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: hours_ago(2),
        mailable: "Mailglass.Example.BrowserMailer"
      })

    exact_webhook =
      insert_webhook_event!(%{
        provider_event_id: "browser-exact-delivery",
        raw_payload: raw_postmark_payload("pm_browser_exact", 901)
      })

    insert_linked_event!(exact_delivery, exact_webhook, "browser-exact-child")

    ambiguous_delivery =
      insert_delivery!(%{
        recipient: "browser-ambiguous@example.com",
        provider: "postmark",
        provider_message_id: "pm_browser_ambiguous",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: hours_ago(2),
        mailable: "Mailglass.Example.BrowserMailer"
      })

    ambiguous_first =
      insert_webhook_event!(%{
        provider_event_id: "browser-ambiguous-delivery-1",
        raw_payload: raw_postmark_payload("pm_browser_ambiguous", 902)
      })

    ambiguous_second =
      insert_webhook_event!(%{
        provider_event_id: "browser-ambiguous-delivery-2",
        raw_payload: raw_postmark_payload("pm_browser_ambiguous", 903)
      })

    insert_linked_event!(ambiguous_delivery, ambiguous_first, "browser-ambiguous-child-1")
    insert_linked_event!(ambiguous_delivery, ambiguous_second, "browser-ambiguous-child-2")

    noop_delivery =
      insert_delivery!(%{
        recipient: "browser-noop@example.com",
        provider: "postmark",
        provider_message_id: "pm_browser_noop",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: hours_ago(2),
        mailable: "Mailglass.Example.BrowserMailer"
      })

    noop_webhook =
      insert_webhook_event!(%{
        provider_event_id: "browser-noop-delivery",
        raw_payload: raw_postmark_payload("pm_browser_noop", 904)
      })

    insert_linked_event!(noop_delivery, noop_webhook, "browser-noop-child")

    insert_event!(noop_delivery, %{
      type: :delivered,
      idempotency_key:
        IdempotencyKey.for_webhook_event(:postmark, "Delivery:904:2026-05-01T00:00:00Z", 0),
      metadata:
        linked_replay_metadata(
          noop_webhook,
          "Delivery:904:2026-05-01T00:00:00Z",
          noop_delivery.provider_message_id
        )
    })

    insert_delivery!(%{
      recipient: "browser-other@example.com",
      provider: "sendgrid",
      provider_message_id: "sg_browser_other",
      status: :failed,
      last_event_type: :failed,
      last_event_at: hours_ago(6),
      mailable: "Mailglass.Example.BrowserMailer"
    })

    # GAP-13: seed one inbound record for the browser scenario so the MOTION-02
    # regression gate (operator.spec.js) can navigate the inbound detail pane.
    # received_at: hours_ago(10) keeps this record older than all delivery rows
    # (oldest delivery is hours_ago(6)) — D-07 row-index stability preserved.
    inbound_record =
      insert_inbound_record!(%{
        provider_message_id: "pm_browser_inbound_001",
        envelope_recipient: "support@browser-scenario.example",
        subject: "Browser scenario support request",
        from: [%{"address" => "user@browser-test.example"}],
        to: [%{"address" => "support@browser-scenario.example"}],
        received_at: hours_ago(10)
      })

    inbound_evidence = insert_inbound_evidence!(inbound_record.id)
    insert_inbound_run!(inbound_record.id, inbound_evidence.id)

    %{
      tenant_id: @tenant_id,
      selected_recipient: selected_delivery.recipient
    }
  end

  def reset! do
    TestRepo.query!(
      "TRUNCATE TABLE mailglass_inbound_replay_runs, mailglass_inbound_evidence, mailglass_inbound_records, mailglass_webhook_events, mailglass_events, mailglass_suppressions, mailglass_deliveries RESTART IDENTITY CASCADE"
    )

    :ok
  end

  def tenant_id, do: @tenant_id

  def exact_recipient, do: "browser-exact@example.com"
  def ambiguous_recipient, do: "browser-ambiguous@example.com"
  def noop_recipient, do: "browser-noop@example.com"

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
      TestRepo.query!(
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

  defp insert_inbound_record!(attrs) do
    defaults = %{
      id: Ecto.UUID.generate(),
      tenant_id: @tenant_id,
      provider: "postmark",
      provider_message_id: nil,
      message_id: nil,
      envelope_recipient: nil,
      subject: nil,
      from: [],
      to: [],
      cc: [],
      bcc: [],
      reply_to: [],
      headers: %{},
      sent_at: nil,
      text_body: nil,
      html_body: nil,
      attachments: [],
      suppression_flagged: false,
      received_at: DateTime.utc_now(),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    row = Enum.into(attrs, defaults)

    _ =
      Ecto.Adapters.SQL.query!(
        TestRepo,
        """
        INSERT INTO mailglass_inbound_records
          (id, tenant_id, provider, provider_message_id, message_id, envelope_recipient,
           subject, "from", "to", cc, bcc, reply_to, headers, sent_at, received_at,
           text_body, html_body, attachments, suppression_flagged, inserted_at, updated_at)
        VALUES
          ($1::uuid, $2, $3, $4, $5, $6, $7, $8::jsonb, $9::jsonb, $10::jsonb, $11::jsonb,
           $12::jsonb, $13, $14, $15, $16, $17, $18::jsonb, $19, $20, $21)
        """,
        [
          Ecto.UUID.dump!(row.id),
          row.tenant_id,
          row.provider,
          row.provider_message_id,
          row.message_id,
          row.envelope_recipient,
          row.subject,
          Jason.encode!(row.from),
          Jason.encode!(row.to),
          Jason.encode!(row.cc),
          Jason.encode!(row.bcc),
          Jason.encode!(row.reply_to),
          row.headers,
          row.sent_at,
          row.received_at,
          row.text_body,
          row.html_body,
          Jason.encode!(row.attachments),
          row.suppression_flagged,
          row.inserted_at,
          row.updated_at
        ]
      )

    %{id: row.id, tenant_id: row.tenant_id, subject: row.subject}
  end

  defp insert_inbound_evidence!(inbound_record_id) do
    id = Ecto.UUID.generate()
    now = DateTime.utc_now()

    _ =
      Ecto.Adapters.SQL.query!(
        TestRepo,
        """
        INSERT INTO mailglass_inbound_evidence
          (id, tenant_id, provider, inbound_record_id, raw_payload, raw_headers,
           raw_mime, verification_facts, parse_warnings, attachment_blobs,
           inserted_at, updated_at)
        VALUES
          ($1::uuid, $2, $3, $4::uuid, $5, $6, $7, $8, $9, $10, $11, $12)
        """,
        [
          Ecto.UUID.dump!(id),
          @tenant_id,
          "postmark",
          Ecto.UUID.dump!(inbound_record_id),
          %{},
          %{},
          nil,
          %{},
          %{},
          %{},
          now,
          now
        ]
      )

    %{id: id}
  end

  defp insert_inbound_run!(inbound_record_id, inbound_evidence_id) do
    id = Ecto.UUID.generate()
    now = DateTime.utc_now()

    _ =
      Ecto.Adapters.SQL.query!(
        TestRepo,
        """
        INSERT INTO mailglass_inbound_replay_runs
          (id, tenant_id, replay_id, mailbox, outcome, outcome_reason, failure,
           executed_at, metadata, inbound_record_id, inbound_evidence_id, source,
           inserted_at, updated_at)
        VALUES
          ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10::uuid, $11::uuid, $12, $13, $14)
        """,
        [
          Ecto.UUID.dump!(id),
          @tenant_id,
          nil,
          "Mailglass.Example.BrowserMailbox",
          "accept",
          nil,
          %{},
          now,
          %{},
          Ecto.UUID.dump!(inbound_record_id),
          Ecto.UUID.dump!(inbound_evidence_id),
          "fresh",
          now,
          now
        ]
      )

    %{id: id}
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours, :hour)

  defp raw_postmark_payload(provider_message_id, message_id_suffix) do
    %{
      "RecordType" => "Delivery",
      "MessageID" => provider_message_id,
      "ID" => message_id_suffix,
      "DeliveredAt" => "2026-05-01T00:00:00Z"
    }
  end

  defp linked_replay_metadata(webhook_event, child_provider_event_id, provider_message_id) do
    %{
      "provider" => "postmark",
      "provider_event_id" => child_provider_event_id,
      "webhook_event_id" => webhook_event.id,
      "webhook_provider_event_id" => webhook_event.provider_event_id,
      "message_id" => provider_message_id,
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
end
