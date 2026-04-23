defmodule Mailglass.Adapters.FakeConcurrencyTest do
  use ExUnit.Case, async: false

  @moduletag :phase_03_uat

  alias Mailglass.Adapters.Fake

  @n_processes 50
  @msgs_per_process 5

  # ──────────────────────────────────────────────────────────────
  # Test 14: 50 parallel processes, zero cross-process leakage
  # ──────────────────────────────────────────────────────────────
  describe "Test 14: concurrency — N processes, zero cross-process leakage" do
    test "#{@n_processes} parallel owners each see only their own #{@msgs_per_process} messages" do
      results =
        1..@n_processes
        |> Task.async_stream(
          fn i ->
            Fake.checkout()

            tenant_id = "tenant-#{i}"
            messages =
              for j <- 1..@msgs_per_process do
                email =
                  Swoosh.Email.new(
                    to: "user-#{i}-#{j}@example.com",
                    from: "noreply@acme.com",
                    subject: "Test #{i}-#{j}"
                  )

                Mailglass.Message.new(email,
                  mailable: Mailglass.FakeFixtures.TestMailer,
                  tenant_id: tenant_id
                )
              end

            Enum.each(messages, fn msg ->
              {:ok, _} = Fake.deliver(msg, [])
            end)

            own_records = Fake.deliveries(owner: self())
            result = {i, length(own_records), Enum.map(own_records, & &1.message.tenant_id)}

            Fake.checkin()
            result
          end,
          max_concurrency: @n_processes,
          timeout: 10_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      # Every process should have exactly @msgs_per_process deliveries
      Enum.each(results, fn {i, count, tenant_ids} ->
        assert count == @msgs_per_process,
               "Process #{i} expected #{@msgs_per_process} deliveries, got #{count}"

        # All deliveries in this bucket belong to the same tenant
        unique_tenants = Enum.uniq(tenant_ids)

        assert unique_tenants == ["tenant-#{i}"],
               "Process #{i} has cross-tenant leakage: #{inspect(unique_tenants)}"
      end)

      total = Enum.sum(Enum.map(results, fn {_, count, _} -> count end))
      assert total == @n_processes * @msgs_per_process,
             "Expected #{@n_processes * @msgs_per_process} total deliveries, got #{total}"
    end
  end
end
