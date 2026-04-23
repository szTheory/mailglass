defmodule Mailglass.Generators do
  @moduledoc """
  StreamData generators for mailglass schemas (attr maps, not structs).

  Used by property tests (Plan 05 `idempotency_convergence_test`) and
  schema tests (Plan 03). Generators emit attr maps the schema's
  `changeset/1` accepts.
  """
  use ExUnitProperties

  @anymail_event_types ~w[queued sent rejected failed bounced deferred
                          delivered autoresponded opened clicked
                          complained unsubscribed subscribed unknown
                          dispatched suppressed]a

  @streams ~w[transactional operational bulk]a
  @scopes ~w[address domain address_stream]a
  @reasons ~w[hard_bounce complaint unsubscribe manual policy invalid_recipient]a

  @doc "Generates `Mailglass.Events.Event.changeset/1`-compatible attr maps."
  def event_attrs(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")

    gen all type <- member_of(@anymail_event_types),
            occurred_at_offset_sec <- integer(-60..60),
            idempotency_key <-
              one_of([
                constant(nil),
                string(:alphanumeric, min_length: 8, max_length: 32)
              ]),
            delivery_id <- one_of([constant(nil), constant(Ecto.UUID.generate())]) do
      %{
        type: type,
        tenant_id: tenant_id,
        occurred_at: DateTime.add(DateTime.utc_now(), occurred_at_offset_sec, :second),
        idempotency_key: idempotency_key,
        delivery_id: delivery_id,
        raw_payload: %{},
        normalized_payload: %{},
        metadata: %{}
      }
    end
  end

  @doc "Generates `Mailglass.Outbound.Delivery.changeset/1`-compatible attr maps."
  def delivery_attrs(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")

    gen all stream <- member_of(@streams),
            local <- string(:alphanumeric, min_length: 3, max_length: 12),
            domain <- string(:alphanumeric, min_length: 3, max_length: 12),
            mailable_mod <- string(:alphanumeric, min_length: 3, max_length: 20),
            now = DateTime.utc_now() do
      %{
        tenant_id: tenant_id,
        mailable: "MyApp.#{mailable_mod}Mailer.welcome/1",
        stream: stream,
        recipient: "#{local}@#{domain}.test",
        recipient_domain: "#{domain}.test",
        last_event_type: :queued,
        last_event_at: now,
        metadata: %{}
      }
    end
  end

  @doc """
  Inserts a `%Mailglass.Outbound.Delivery{}` fixture into the test repo and returns it.

  Accepts the same keys as `Delivery.changeset/1`, plus:
  - `:idempotency_key` — explicit key; defaults to `nil`
  - `:tenant_id` — defaults to `"test-tenant"`

  Must be called from within a `Mailglass.DataCase` sandbox checkout.
  """
  def delivery_fixture(opts \\ []) do
    attrs = %{
      tenant_id: Keyword.get(opts, :tenant_id, "test-tenant"),
      mailable: Keyword.get(opts, :mailable, "Mailglass.FakeFixtures.TestMailer"),
      stream: Keyword.get(opts, :stream, :transactional),
      recipient: Keyword.get(opts, :recipient, "fixture@example.com"),
      last_event_type: Keyword.get(opts, :last_event_type, :queued),
      last_event_at: Keyword.get(opts, :last_event_at, Mailglass.Clock.utc_now()),
      metadata: Keyword.get(opts, :metadata, %{}),
      idempotency_key: Keyword.get(opts, :idempotency_key)
    }

    {:ok, delivery} =
      attrs
      |> Mailglass.Outbound.Delivery.changeset()
      |> Mailglass.TestRepo.insert()

    delivery
  end

  @doc "Generates `Mailglass.Suppression.Entry.changeset/1`-compatible attr maps."
  def suppression_attrs(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")

    gen all scope <- member_of(@scopes),
            reason <- member_of(@reasons),
            local <- string(:alphanumeric, min_length: 3, max_length: 12),
            domain <- string(:alphanumeric, min_length: 3, max_length: 12),
            stream <- member_of(@streams) do
      stream_value = if scope == :address_stream, do: stream, else: nil

      %{
        tenant_id: tenant_id,
        address: "#{local}@#{domain}.test",
        scope: scope,
        stream: stream_value,
        reason: reason,
        source: "test",
        metadata: %{}
      }
    end
  end
end
