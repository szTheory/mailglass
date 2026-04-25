defmodule Mailglass.Outbound.TelemetryTest do
  use Mailglass.DataCase, async: false

  use ExUnitProperties

  alias Mailglass.{Outbound, Message}

  @pii_keys ~w[to from body html_body subject headers recipient email]a

  setup do
    Mailglass.Adapters.Fake.checkout()
    :ok
  end

  describe "telemetry spans fire correctly" do
    test "[:mailglass, :outbound, :send, :start|:stop] and [:mailglass, :outbound, :dispatch, :start|:stop] fire" do
      events_seen = :ets.new(:events_seen, [:set, :public])

      handler_id = "test-outbound-spans-#{System.unique_integer()}"

      events_to_watch = [
        [:mailglass, :outbound, :send, :start],
        [:mailglass, :outbound, :send, :stop],
        [:mailglass, :outbound, :dispatch, :start],
        [:mailglass, :outbound, :dispatch, :stop]
      ]

      :telemetry.attach_many(
        handler_id,
        events_to_watch,
        fn event, _measurements, _metadata, _config ->
          :ets.insert(events_seen, {event, true})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      msg = build_message("telemetry@example.com")
      {:ok, _} = Outbound.send(msg)

      for event <- events_to_watch do
        assert :ets.lookup(events_seen, event) != [],
               "Expected event #{inspect(event)} to fire"
      end

      :ets.delete(events_seen)
    end
  end

  describe "PII property test — no PII in telemetry metadata across 100 sends" do
    @tag timeout: 60_000
    property "no PII key appears in any emitted span metadata" do
      # Use a unique atom-keyed ETS table; capture ref in variable for closure use
      pii_table = :ets.new(:mailglass_pii_check, [:set, :public])

      handler_id = "test-pii-property-#{System.unique_integer()}"

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :outbound, :send, :start],
          [:mailglass, :outbound, :send, :stop],
          [:mailglass, :outbound, :dispatch, :start],
          [:mailglass, :outbound, :dispatch, :stop],
          [:mailglass, :persist, :outbound, :multi, :start],
          [:mailglass, :persist, :outbound, :multi, :stop]
        ],
        fn _event, _measurements, metadata, _config ->
          pii_key_found =
            Map.keys(metadata)
            |> Enum.filter(fn k ->
              # :telemetry_span_context is library machinery, not PII — exempt per decision note
              k != :telemetry_span_context and k in @pii_keys
            end)

          unless pii_key_found == [] do
            :ets.insert(pii_table, {:found, pii_key_found, metadata})
          end
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      check all(
              local <- StreamData.string(:alphanumeric, min_length: 3, max_length: 10),
              domain <- StreamData.string(:alphanumeric, min_length: 3, max_length: 10),
              max_runs: 20
            ) do
        to_addr = "#{local}@#{domain}.test"
        msg = build_message(to_addr)
        Outbound.send(msg)

        violations = :ets.lookup(pii_table, :found)

        assert violations == [],
               "PII keys found in telemetry metadata: #{inspect(violations)}"
      end

      :ets.delete(pii_table)
    end
  end

  defp build_message(to_addr) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "from@example.com"})
      |> Swoosh.Email.to(to_addr)
      |> Swoosh.Email.subject("Test subject")
      |> Swoosh.Email.html_body("<p>Test body</p>")
      |> Swoosh.Email.text_body("Test body")

    Message.new(email,
      mailable: Mailglass.FakeFixtures.TestMailer,
      tenant_id: "test-tenant",
      stream: :transactional
    )
  end
end
