defmodule MailglassDemo.CatalogSeed do
  @moduledoc """
  Seeds the four delivery cases the before-catalog needs and `MailglassDemo.DemoData`
  does not carry, then prints the case map for all ten catalog cases.

  Called only by the before-catalog run (`reference/demo_app/assets/catalog/`), after
  every reset: `DemoData.reset!/0` truncates the tables, so this module always runs
  against a freshly reset database. It is never called from `DemoData`, `seeds.exs`
  or an e2e spec, and it adds no HTTP endpoint.

  The four cases are inserted on tenant `northstar` through the real changesets:

    * `typo-bounce`: a hard bounce to a typo domain, with `reject_reason: :invalid`
    * `send-failed`: a send-time `:failed` delivery with the adapter's own `last_error`
    * `sent-no-report`: dispatched, with no later provider report
    * `unicode-recipient`: a delivered message to a recipient with non-ASCII letters

  The catalog records what the screens say today, gaps included. This module therefore
  seeds no retry timing and no explanatory copy: the only error text is the synthetic
  adapter error stored in `last_error` on the failed delivery, and the two cases with
  no rejection and no error carry only a subject and a scenario in their metadata.

  Provider ids and idempotency keys use the `pm-cat-` / `demo-delivery-cat-` /
  `demo-event-cat-` prefixes so nothing collides with `DemoData`.

  The six `DemoData` cases are looked up read-only (exactly one row each, or the seed
  raises) so the case map names the delivery ids the capture run opens.
  """

  import Ecto.Query, only: [from: 2]

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias MailglassDemo.Repo

  @tenant "northstar"
  @sentinel "CATALOG_CASES_JSON="

  # slug => {source-row lookup} for the six cases DemoData already seeds.
  @demo_cases [
    {"nil-reason-bounce", {:provider_message_id, "pm-demo-payment-failed-001"}},
    {"deferred-no-retry", {:provider_message_id, "sg-demo-badge-deferred-001"}},
    # The invite row stays as the catalog's delivered-without-open example; the receipt
    # row also has valid replay linkage and is covered by the operator journey.
    {"delivered-no-open", {:provider_message_id, "pm-demo-invite-001"}},
    {"long-recipient", {:provider_message_id, "pm-demo-truncation-stress-001"}},
    {"complained", {:provider_message_id, "sg-demo-badge-complained-001"}},
    {"manual-suppressed", {:scenario, "incident_update"}}
  ]

  @doc "The sentinel the driver looks for on stdout."
  def sentinel, do: @sentinel

  @doc """
  Inserts the four catalog cases and prints one `CATALOG_CASES_JSON=<json>` line.

  Raises, before printing, if any inserted row does not read back with the expected
  values or any `DemoData` lookup does not match exactly one row.
  """
  def seed! do
    anchor = DateTime.utc_now() |> DateTime.truncate(:second)

    seeded = [
      {"typo-bounce", typo_bounce!(anchor)},
      {"send-failed", send_failed!(anchor)},
      {"sent-no-report", sent_no_report!(anchor)},
      {"unicode-recipient", unicode_recipient!(anchor)}
    ]

    seeded_cases =
      Map.new(seeded, fn {slug, delivery} -> {slug, case_entry("catalog_seed", delivery)} end)

    demo_cases =
      Map.new(@demo_cases, fn {slug, lookup} -> {slug, case_entry("demo_data", lookup!(lookup))} end)

    cases = Map.merge(seeded_cases, demo_cases)
    verify_seeded!(cases)

    payload = %{"seed_anchor_utc" => DateTime.to_iso8601(anchor), "cases" => cases}
    IO.puts(@sentinel <> Jason.encode!(payload))
    :ok
  end

  defp typo_bounce!(anchor) do
    delivery =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "maya.okafor@northstr.example",
        provider: "postmark",
        provider_message_id: "pm-cat-typo-bounce-001",
        status: :sent,
        last_event_type: :bounced,
        last_event_at: minutes_ago(anchor, 17),
        metadata: %{
          "scenario" => "catalog_typo_bounce",
          "subject" => "Welcome to Northstar Logistics, Maya"
        }
      })

    event!(delivery, :sent, minutes_ago(anchor, 18), %{"provider" => "postmark", "source" => "api"})

    event!(
      delivery,
      :bounced,
      minutes_ago(anchor, 17),
      %{"provider" => "postmark", "source" => "webhook"},
      reject_reason: :invalid
    )

    delivery
  end

  defp send_failed!(anchor) do
    delivery =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.OperationsMailer.usage_alert",
        stream: :operational,
        recipient: "dispatch@northstar.example",
        provider: nil,
        provider_message_id: nil,
        status: :failed,
        last_event_type: :failed,
        last_event_at: minutes_ago(anchor, 14),
        last_error: %{
          type: :adapter_error,
          module: "Mailglass.SendError",
          message: "The adapter closed the connection before the provider accepted the message."
        },
        idempotency_key: "demo-delivery-cat-send-failed-001",
        metadata: %{
          "scenario" => "catalog_send_failed",
          "subject" => "Northstar Logistics weekly shipment digest"
        }
      })

    event!(
      delivery,
      :failed,
      minutes_ago(anchor, 14),
      %{"provider" => "mailglass", "source" => "api"},
      key_id: "cat-send-failed-001"
    )

    delivery
  end

  defp sent_no_report!(anchor) do
    delivery =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.BillingMailer.receipt_paid",
        stream: :operational,
        recipient: "finance@northstar.example",
        provider: "postmark",
        provider_message_id: "pm-cat-sent-no-report-001",
        status: :sent,
        last_event_type: :sent,
        last_event_at: minutes_ago(anchor, 9),
        metadata: %{
          "scenario" => "catalog_sent_no_report",
          "subject" => "Northstar Logistics onboarding checklist"
        }
      })

    event!(delivery, :sent, minutes_ago(anchor, 9), %{"provider" => "postmark", "source" => "api"})

    delivery
  end

  defp unicode_recipient!(anchor) do
    delivery =
      delivery!(%{
        mailable: "MailglassDemoWeb.Mailers.AccountMailer.invite_admin",
        stream: :transactional,
        recipient: "zoë.müller@northstar.example",
        provider: "postmark",
        provider_message_id: "pm-cat-unicode-recipient-001",
        status: :sent,
        last_event_type: :delivered,
        last_event_at: minutes_ago(anchor, 30),
        metadata: %{
          "scenario" => "catalog_unicode_recipient",
          "subject" => "Your Northstar Logistics workspace is ready"
        }
      })

    event!(delivery, :sent, minutes_ago(anchor, 31), %{"provider" => "postmark", "source" => "api"})

    event!(delivery, :delivered, minutes_ago(anchor, 30), %{
      "provider" => "postmark",
      "source" => "webhook"
    })

    delivery
  end

  defp delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant,
      adapter_ref: Delivery.default_adapter_ref(),
      terminal: false,
      idempotency_key: "demo-delivery-#{attrs[:provider_message_id]}"
    }

    defaults
    |> Map.merge(attrs)
    |> Delivery.changeset()
    |> Repo.insert!()
  end

  # Mirrors DemoData.event!/4: insert the ledger event, then project it onto the
  # delivery so `terminal` and the lifecycle timestamps stay consistent.
  defp event!(delivery, type, occurred_at, metadata, opts \\ []) do
    key_source = Keyword.get(opts, :key_id, delivery.provider_message_id)

    event =
      %{
        tenant_id: @tenant,
        delivery_id: delivery.id,
        type: type,
        occurred_at: occurred_at,
        reject_reason: Keyword.get(opts, :reject_reason),
        idempotency_key: "demo-event-cat-#{key_source}-#{type}-#{DateTime.to_unix(occurred_at)}",
        metadata: metadata,
        normalized_payload: %{"recipient" => delivery.recipient}
      }
      |> Event.changeset()
      |> Repo.insert!()

    Repo.get!(Delivery, delivery.id)
    |> Mailglass.Outbound.Projector.update_projections(event)
    |> Repo.update!()

    event
  end

  defp lookup!({:provider_message_id, id}) do
    rows =
      Repo.all(from(d in Delivery, where: d.tenant_id == ^@tenant and d.provider_message_id == ^id))

    exactly_one!(rows, "provider_message_id #{id}")
  end

  defp lookup!({:scenario, scenario}) do
    rows =
      Repo.all(
        from(d in Delivery,
          where: d.tenant_id == ^@tenant and fragment("?->>'scenario' = ?", d.metadata, ^scenario)
        )
      )

    exactly_one!(rows, "metadata scenario #{scenario}")
  end

  defp exactly_one!([delivery], _label), do: delivery

  defp exactly_one!(rows, label) do
    raise "CatalogSeed: expected exactly one northstar delivery for #{label}, found #{length(rows)}"
  end

  # Values are read back from the stored row, never restated from the insert attrs.
  defp case_entry(source, %Delivery{id: id}) do
    delivery = Repo.get!(Delivery, id)

    %{
      "source" => source,
      "delivery_id" => delivery.id,
      "provider_message_id" => delivery.provider_message_id,
      "recipient" => delivery.recipient,
      "scenario" => Map.get(delivery.metadata, "scenario"),
      "status" => Atom.to_string(delivery.status),
      "reject_reason" => reject_reason(delivery),
      "last_error_present" => not is_nil(delivery.last_error),
      "metadata_keys" => delivery.metadata |> Map.keys() |> Enum.sort()
    }
  end

  defp reject_reason(%Delivery{} = delivery) do
    reason =
      Repo.one(
        from(e in Event,
          where: e.delivery_id == ^delivery.id and e.type == ^delivery.last_event_type,
          order_by: [desc: e.occurred_at],
          limit: 1,
          select: e.reject_reason
        )
      )

    if is_nil(reason), do: nil, else: Atom.to_string(reason)
  end

  defp verify_seeded!(cases) do
    expect!(cases, "typo-bounce", %{"reject_reason" => "invalid", "status" => "sent"})

    expect!(cases, "send-failed", %{
      "status" => "failed",
      "reject_reason" => nil,
      "last_error_present" => true
    })

    expect!(cases, "sent-no-report", %{
      "status" => "sent",
      "reject_reason" => nil,
      "last_error_present" => false
    })

    expect!(cases, "unicode-recipient", %{"reject_reason" => nil, "last_error_present" => false})

    for slug <- ["typo-bounce", "send-failed", "sent-no-report", "unicode-recipient"] do
      expect!(cases, slug, %{"source" => "catalog_seed", "metadata_keys" => ["scenario", "subject"]})
    end

    if map_size(cases) != 10,
      do: raise("CatalogSeed: expected ten catalog cases, built #{map_size(cases)}")
  end

  defp expect!(cases, slug, expected) do
    actual = Map.fetch!(cases, slug)

    for {key, want} <- expected do
      got = Map.fetch!(actual, key)

      if got != want do
        raise "CatalogSeed: case #{slug} read back #{key}=#{inspect(got)}, expected #{inspect(want)}"
      end
    end
  end

  defp minutes_ago(anchor, minutes), do: DateTime.add(anchor, -minutes, :minute)
end
