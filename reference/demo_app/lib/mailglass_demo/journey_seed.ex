defmodule MailglassDemo.JourneySeed do
  @moduledoc """
  Seeds the password-reset rows the Phase 182 after-catalog and its browser journey need.

  The job is "a customer says the password reset never arrived". Neither `MailglassDemo.DemoData`
  nor `MailglassDemo.CatalogSeed` carries a password-reset mailable, so this module adds six
  rows on tenant `northstar`, each a different honest answer to that question:

    * `pw-sent-no-report`: handed to the provider, no later provider report
    * `pw-typo-bounce`: a bounce the provider classified as an invalid address
    * `pw-bounce-then-open`: a bounce, then an open report afterwards
    * `pw-nil-reason-bounce`: a bounce the provider gave no reason for
    * `pw-deferred`: the receiving server asked to try again later, nothing final recorded
    * `pw-suppressed`: stopped by a suppression entry before any send

  Called only by the after-catalog run (`reference/demo_app/assets/catalog/`), after the guarded
  reset and `MailglassDemo.CatalogSeed.seed!/0`. It is never called from `DemoData`, `seeds.exs`
  or an e2e spec (`DemoData.reset!/0` truncates the tables, so the advisory `./e2e` lanes never
  see these rows) and it adds no HTTP endpoint. `DemoData`, `CatalogSeed` and
  `reference/persona_spec/personas.ex` are not edited: the persona drift guard reads them.

  Every row goes through the real changesets, and each event is projected onto its delivery with
  `Mailglass.Outbound.Projector.update_projections/2`, so `bounced_at`, `terminal` and
  `suppressed_at` are the values the product itself would store. The case map printed for the
  driver is read back from the stored rows, never restated from the insert attributes.

  The stop line applies to the seed too: no retry timing and no explanatory copy is stored. The
  only text on a row is a subject and a scenario name, and the only event metadata is the
  provider name and the source of the event.

  Provider ids and idempotency keys use the `pm-jrn-`, `demo-delivery-jrn-` and
  `demo-event-jrn-` prefixes so nothing collides with `DemoData` (`pm-demo-`) or `CatalogSeed`
  (`pm-cat-`). Every recipient is on `northstar.example`, a reserved domain.
  """

  import Ecto.Query, only: [from: 2]

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry
  alias MailglassDemo.Repo

  @tenant "northstar"
  @sentinel "JOURNEY_CASES_JSON="
  @mailable "MailglassDemoWeb.Mailers.AccountMailer.password_reset"
  @subject "Reset your password"
  @slugs ~w(pw-sent-no-report pw-typo-bounce pw-bounce-then-open pw-nil-reason-bounce pw-deferred pw-suppressed)

  @doc "The sentinel the driver looks for on stdout."
  def sentinel, do: @sentinel

  @doc "The six case slugs, in the order they are seeded."
  def slugs, do: @slugs

  @doc """
  Inserts the six password-reset rows and prints one sentinel line holding the case map as JSON.

  Raises, before printing, if any inserted row does not read back with the expected values.
  """
  def seed! do
    anchor = DateTime.utc_now() |> DateTime.truncate(:second)

    seeded = [
      {"pw-sent-no-report", sent_no_report!(anchor)},
      {"pw-typo-bounce", typo_bounce!(anchor)},
      {"pw-bounce-then-open", bounce_then_open!(anchor)},
      {"pw-nil-reason-bounce", nil_reason_bounce!(anchor)},
      {"pw-deferred", deferred!(anchor)},
      {"pw-suppressed", suppressed!(anchor)}
    ]

    cases = Map.new(seeded, fn {slug, delivery} -> {slug, case_entry(delivery)} end)
    verify_seeded!(cases)

    payload = %{"seed_anchor_utc" => DateTime.to_iso8601(anchor), "cases" => cases}
    IO.puts(@sentinel <> Jason.encode!(payload))
    :ok
  end

  defp sent_no_report!(anchor) do
    delivery = reset_delivery!("pw-sent-no-report", :sent, :sent, anchor, 42)
    event!(delivery, :sent, minutes_ago(anchor, 42), postmark_api())
    delivery
  end

  defp typo_bounce!(anchor) do
    delivery = reset_delivery!("pw-typo-bounce", :sent, :bounced, anchor, 35)
    event!(delivery, :sent, minutes_ago(anchor, 36), postmark_api())
    event!(delivery, :bounced, minutes_ago(anchor, 35), postmark_webhook(), reject_reason: :invalid)
    delivery
  end

  defp bounce_then_open!(anchor) do
    delivery = reset_delivery!("pw-bounce-then-open", :sent, :opened, anchor, 28)
    event!(delivery, :sent, minutes_ago(anchor, 33), postmark_api())
    event!(delivery, :bounced, minutes_ago(anchor, 31), postmark_webhook(), reject_reason: :bounced)
    event!(delivery, :opened, minutes_ago(anchor, 28), postmark_webhook())
    delivery
  end

  defp nil_reason_bounce!(anchor) do
    delivery = reset_delivery!("pw-nil-reason-bounce", :sent, :bounced, anchor, 24)
    event!(delivery, :sent, minutes_ago(anchor, 25), postmark_api())
    event!(delivery, :bounced, minutes_ago(anchor, 24), postmark_webhook())
    delivery
  end

  defp deferred!(anchor) do
    delivery = reset_delivery!("pw-deferred", :sent, :deferred, anchor, 18)
    event!(delivery, :sent, minutes_ago(anchor, 19), postmark_api())
    event!(delivery, :deferred, minutes_ago(anchor, 18), postmark_webhook())
    delivery
  end

  defp suppressed!(anchor) do
    delivery =
      delivery!(%{
        mailable: @mailable,
        stream: :transactional,
        recipient: "pw-suppressed@northstar.example",
        provider: nil,
        provider_message_id: nil,
        status: :suppressed,
        last_event_type: :suppressed,
        last_event_at: minutes_ago(anchor, 12),
        idempotency_key: "demo-delivery-jrn-pw-suppressed",
        metadata: metadata("pw-suppressed")
      })

    event!(
      delivery,
      :suppressed,
      minutes_ago(anchor, 12),
      %{"provider" => "mailglass", "source" => "api"},
      key_id: "pw-suppressed"
    )

    %{
      tenant_id: @tenant,
      address: delivery.recipient,
      scope: :address,
      reason: :hard_bounce,
      source: "journey-seed",
      metadata: %{"scenario" => "journey_pw_suppressed"}
    }
    |> Entry.changeset()
    |> Repo.insert!()

    delivery
  end

  # A provider-handed row. `status` and `last_event_type` are set to their final values up front
  # (as DemoData does); `event!/5` then projects each event so the lifecycle timestamps and the
  # `terminal` latch match what the product would store.
  defp reset_delivery!(slug, status, last_event_type, anchor, last_event_minutes_ago) do
    delivery!(%{
      mailable: @mailable,
      stream: :transactional,
      recipient: "#{slug}@northstar.example",
      provider: "postmark",
      provider_message_id: "pm-jrn-#{slug}-001",
      status: status,
      last_event_type: last_event_type,
      last_event_at: minutes_ago(anchor, last_event_minutes_ago),
      idempotency_key: "demo-delivery-jrn-#{slug}",
      metadata: metadata(slug)
    })
  end

  defp metadata(slug) do
    %{"scenario" => "journey_" <> String.replace(slug, "-", "_"), "subject" => @subject}
  end

  defp postmark_api, do: %{"provider" => "postmark", "source" => "api"}
  defp postmark_webhook, do: %{"provider" => "postmark", "source" => "webhook"}

  defp delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant,
      adapter_ref: Delivery.default_adapter_ref(),
      terminal: false
    }

    defaults
    |> Map.merge(attrs)
    |> Delivery.changeset()
    |> Repo.insert!()
  end

  # Mirrors CatalogSeed.event!/5: insert the ledger event, then project it onto the
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
        idempotency_key: "demo-event-jrn-#{key_source}-#{type}-#{DateTime.to_unix(occurred_at)}",
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

  # Values are read back from the stored row, never restated from the insert attrs.
  defp case_entry(%Delivery{id: id}) do
    delivery = Repo.get!(Delivery, id)

    %{
      "source" => "journey_seed",
      "delivery_id" => delivery.id,
      "provider_message_id" => delivery.provider_message_id,
      "recipient" => delivery.recipient,
      "scenario" => Map.get(delivery.metadata, "scenario"),
      "status" => Atom.to_string(delivery.status),
      "last_event_type" => Atom.to_string(delivery.last_event_type),
      "bounced" => not is_nil(delivery.bounced_at),
      "terminal" => delivery.terminal,
      "suppressed" => not is_nil(delivery.suppressed_at),
      "bounce_reject_reason" => bounce_reject_reason(delivery),
      "suppression_reason" => suppression_reason(delivery),
      "last_error_present" => not is_nil(delivery.last_error),
      "metadata_keys" => delivery.metadata |> Map.keys() |> Enum.sort()
    }
  end

  # The reason on the most recent bounced event, nil when the row has no bounce or the provider
  # gave none. A bounce followed by an open still reports the bounce's own reason.
  defp bounce_reject_reason(%Delivery{} = delivery) do
    reason =
      Repo.one(
        from(e in Event,
          where: e.delivery_id == ^delivery.id and e.type == :bounced,
          order_by: [desc: e.occurred_at],
          limit: 1,
          select: e.reject_reason
        )
      )

    if is_nil(reason), do: nil, else: Atom.to_string(reason)
  end

  defp suppression_reason(%Delivery{recipient: recipient}) do
    reason =
      Repo.one(
        from(e in Entry,
          where: e.tenant_id == ^@tenant and e.address == ^recipient,
          limit: 1,
          select: e.reason
        )
      )

    if is_nil(reason), do: nil, else: Atom.to_string(reason)
  end

  defp verify_seeded!(cases) do
    expect!(cases, "pw-sent-no-report", %{
      "status" => "sent",
      "last_event_type" => "sent",
      "bounced" => false,
      "terminal" => false,
      "bounce_reject_reason" => nil
    })

    expect!(cases, "pw-typo-bounce", %{
      "last_event_type" => "bounced",
      "bounced" => true,
      "terminal" => true,
      "bounce_reject_reason" => "invalid"
    })

    expect!(cases, "pw-bounce-then-open", %{
      "last_event_type" => "opened",
      "bounced" => true,
      "terminal" => true,
      "bounce_reject_reason" => "bounced"
    })

    expect!(cases, "pw-nil-reason-bounce", %{
      "last_event_type" => "bounced",
      "bounced" => true,
      "terminal" => true,
      "bounce_reject_reason" => nil
    })

    expect!(cases, "pw-deferred", %{
      "last_event_type" => "deferred",
      "bounced" => false,
      "terminal" => false,
      "bounce_reject_reason" => nil
    })

    expect!(cases, "pw-suppressed", %{
      "status" => "suppressed",
      "last_event_type" => "suppressed",
      "suppressed" => true,
      "terminal" => true,
      "suppression_reason" => "hard_bounce"
    })

    for slug <- @slugs do
      expect!(cases, slug, %{
        "source" => "journey_seed",
        "last_error_present" => false,
        "metadata_keys" => ["scenario", "subject"]
      })
    end

    if map_size(cases) != 6,
      do: raise("JourneySeed: expected six journey cases, built #{map_size(cases)}")
  end

  defp expect!(cases, slug, expected) do
    actual = Map.fetch!(cases, slug)

    for {key, want} <- expected do
      got = Map.fetch!(actual, key)

      if got != want do
        raise "JourneySeed: case #{slug} read back #{key}=#{inspect(got)}, expected #{inspect(want)}"
      end
    end
  end

  defp minutes_ago(anchor, minutes), do: DateTime.add(anchor, -minutes, :minute)
end
