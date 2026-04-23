defmodule Mailglass.Outbound.DeliveryIdempotencyKeyTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.Outbound.Delivery
  alias Mailglass.TestRepo

  @tenant "test-tenant"

  describe "migration — column and index exist" do
    test "mailglass_deliveries has idempotency_key column" do
      result =
        Ecto.Adapters.SQL.query!(
          TestRepo,
          """
          SELECT column_name, data_type, is_nullable
          FROM information_schema.columns
          WHERE table_name = 'mailglass_deliveries'
            AND column_name = 'idempotency_key'
          """,
          []
        )

      assert length(result.rows) == 1,
             "Expected idempotency_key column to exist on mailglass_deliveries"

      [[col_name, data_type, _nullable]] = result.rows
      assert col_name == "idempotency_key"
      assert data_type == "text"
    end

    test "mailglass_deliveries has status column" do
      result =
        Ecto.Adapters.SQL.query!(
          TestRepo,
          """
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_name = 'mailglass_deliveries'
            AND column_name = 'status'
          """,
          []
        )

      assert length(result.rows) == 1, "Expected status column to exist on mailglass_deliveries"
    end

    test "mailglass_deliveries has last_error column" do
      result =
        Ecto.Adapters.SQL.query!(
          TestRepo,
          """
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_name = 'mailglass_deliveries'
            AND column_name = 'last_error'
          """,
          []
        )

      assert length(result.rows) == 1, "Expected last_error column on mailglass_deliveries"
    end

    test "partial UNIQUE index on idempotency_key exists" do
      result =
        Ecto.Adapters.SQL.query!(
          TestRepo,
          """
          SELECT indexname, indexdef
          FROM pg_indexes
          WHERE tablename = 'mailglass_deliveries'
            AND indexname = 'mailglass_deliveries_idempotency_key_unique_idx'
          """,
          []
        )

      assert length(result.rows) == 1,
             "Expected mailglass_deliveries_idempotency_key_unique_idx index to exist"

      [[_name, indexdef]] = result.rows
      # Postgres wraps the predicate in parens in indexdef output
      assert indexdef =~ "idempotency_key IS NOT NULL"
    end
  end

  describe "Delivery.changeset/1 — idempotency_key" do
    test "casts idempotency_key when supplied" do
      attrs = valid_attrs(%{idempotency_key: "sha256abc123"})
      changeset = Delivery.changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :idempotency_key) == "sha256abc123"
    end

    test "idempotency_key defaults to nil when not supplied" do
      attrs = valid_attrs(%{})
      changeset = Delivery.changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :idempotency_key) == nil
    end

    test "unique_constraint is declared for idempotency_key" do
      # Two deliveries with same non-nil idempotency_key should conflict.
      ik = "unique-key-#{System.unique_integer()}"
      attrs = valid_attrs(%{idempotency_key: ik})

      {:ok, _d1} = attrs |> Delivery.changeset() |> TestRepo.insert()

      assert {:error, changeset} = attrs |> Delivery.changeset() |> TestRepo.insert()
      assert changeset.errors[:idempotency_key] != nil
    end

    test "two deliveries with nil idempotency_key both succeed (partial index ignores nulls)" do
      attrs = valid_attrs(%{idempotency_key: nil})

      {:ok, d1} = attrs |> Delivery.changeset() |> TestRepo.insert()
      {:ok, d2} = attrs |> Delivery.changeset() |> TestRepo.insert()

      refute d1.id == d2.id
      assert is_nil(d1.idempotency_key)
      assert is_nil(d2.idempotency_key)
    end
  end

  describe "Delivery.changeset/1 — status (I-01)" do
    test "Delivery.__schema__(:fields) includes :status AND :last_error" do
      fields = Delivery.__schema__(:fields)
      assert :status in fields
      assert :last_error in fields
    end

    test "inserting a new Delivery without status yields status: :queued (default)" do
      attrs = valid_attrs(%{})
      {:ok, delivery} = attrs |> Delivery.changeset() |> TestRepo.insert()

      assert delivery.status == :queued
    end

    test "changeset casts :status when valid" do
      attrs = valid_attrs(%{status: :sent})
      changeset = Delivery.changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :status) == :sent
    end

    test "changeset rejects invalid :status atoms" do
      attrs = valid_attrs(%{status: :teleporting})
      changeset = Delivery.changeset(attrs)

      refute changeset.valid?
      assert changeset.errors[:status] != nil
    end

    test "changeset casts :last_error when supplied" do
      attrs = valid_attrs(%{last_error: %{type: "adapter_failure", message: "err"}})
      changeset = Delivery.changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :last_error) == %{type: "adapter_failure", message: "err"}
    end
  end

  describe "Generators.delivery_fixture/1 — idempotency_key" do
    test "populates idempotency_key when :idempotency_key opt supplied" do
      ik = "gen-key-#{System.unique_integer()}"
      delivery = Mailglass.Generators.delivery_fixture(idempotency_key: ik)
      assert delivery.idempotency_key == ik
    end

    test "defaults to nil when :idempotency_key not supplied" do
      delivery = Mailglass.Generators.delivery_fixture([])
      assert is_nil(delivery.idempotency_key)
    end
  end

  defp valid_attrs(overrides) do
    Map.merge(
      %{
        tenant_id: @tenant,
        mailable: "MyApp.UserMailer.welcome/1",
        stream: :transactional,
        recipient: "user@example.com",
        last_event_type: :queued,
        last_event_at: DateTime.utc_now()
      },
      overrides
    )
  end
end
