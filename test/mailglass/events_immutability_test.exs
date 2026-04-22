defmodule Mailglass.EventsImmutabilityTest do
  # async: false — these tests verify DB-level trigger behaviour with raw SQL
  # and cannot share the sandbox with concurrent schema-aware tests.
  use Mailglass.DataCase, async: false

  alias Mailglass.EventLedgerImmutableError
  alias Mailglass.TestRepo

  setup do
    # Insert one event row via raw SQL — schemas don't exist until Plan 03.
    # UUIDv7.generate/0 matches the phase PK standard (D-25, D-28).
    id = UUIDv7.generate()

    TestRepo.query!(
      """
      INSERT INTO mailglass_events
        (id, tenant_id, type, occurred_at, normalized_payload, metadata)
      VALUES
        ($1, $2, $3, $4, $5, $6)
      """,
      [
        uuid_binary(id),
        "test-tenant",
        "queued",
        DateTime.utc_now(),
        %{},
        %{}
      ]
    )

    {:ok, id: id}
  end

  test "UPDATE on mailglass_events via Mailglass.Repo.transact/1 raises EventLedgerImmutableError",
       %{id: id} do
    assert_raise EventLedgerImmutableError, fn ->
      Mailglass.Repo.transact(fn ->
        TestRepo.query!(
          "UPDATE mailglass_events SET type = 'delivered' WHERE id = $1",
          [uuid_binary(id)]
        )

        {:ok, :updated}
      end)
    end
  end

  test "DELETE on mailglass_events via Mailglass.Repo.transact/1 raises EventLedgerImmutableError",
       %{id: id} do
    assert_raise EventLedgerImmutableError, fn ->
      Mailglass.Repo.transact(fn ->
        TestRepo.query!(
          "DELETE FROM mailglass_events WHERE id = $1",
          [uuid_binary(id)]
        )

        {:ok, :deleted}
      end)
    end
  end

  test "translated error carries pg_code 45A01" do
    err =
      assert_raise EventLedgerImmutableError, fn ->
        Mailglass.Repo.transact(fn ->
          TestRepo.query!("UPDATE mailglass_events SET type = 'delivered'")
          {:ok, :updated}
        end)
      end

    assert err.pg_code == "45A01"
    assert err.type in [:update_attempt, :delete_attempt]
  end

  # Helper: UUID string → 16-byte binary for Postgrex parameter passing.
  defp uuid_binary(uuid_string) when is_binary(uuid_string) do
    {:ok, bin} = Ecto.UUID.dump(uuid_string)
    bin
  end
end
