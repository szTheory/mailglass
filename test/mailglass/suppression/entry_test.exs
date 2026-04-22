defmodule Mailglass.Suppression.EntryTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Suppression.Entry
  alias Mailglass.TestRepo

  describe "changeset/1 — required fields (MAIL-07 prevention)" do
    test "requires tenant_id, address, scope, reason, source (no scope default)" do
      changeset = Entry.changeset(%{})
      refute changeset.valid?

      for field <- [:tenant_id, :address, :scope, :reason, :source] do
        assert {_, [validation: :required]} = changeset.errors[field],
               "expected #{field} to be required"
      end
    end

    test "rejects unknown scope" do
      # D-08: :tenant_address removed pre-GA
      attrs = valid_attrs(%{scope: :tenant_address})
      changeset = Entry.changeset(attrs)
      refute changeset.valid?
      {msg, opts} = changeset.errors[:scope]
      assert msg == "is invalid"
      assert opts[:validation] == :inclusion
      assert is_list(opts[:enum])
    end

    test "rejects unknown reason" do
      attrs = valid_attrs(%{reason: :bikeshed})
      changeset = Entry.changeset(attrs)
      refute changeset.valid?
      {msg, opts} = changeset.errors[:reason]
      assert msg == "is invalid"
      assert opts[:validation] == :inclusion
      assert is_list(opts[:enum])
    end
  end

  describe "changeset/1 — scope/stream coupling (D-07)" do
    test "scope :address_stream REQUIRES stream" do
      attrs = valid_attrs(%{scope: :address_stream, stream: nil})
      changeset = Entry.changeset(attrs)
      refute changeset.valid?
      assert {"is required when scope is :address_stream", _} = changeset.errors[:stream]
    end

    test "scope :address REJECTS stream" do
      attrs = valid_attrs(%{scope: :address, stream: :bulk})
      changeset = Entry.changeset(attrs)
      refute changeset.valid?
      assert {msg, _} = changeset.errors[:stream]
      assert msg =~ "must be omitted when scope is :address"
      assert msg =~ "stream is only valid for :address_stream"
    end

    test "scope :domain REJECTS stream" do
      attrs = valid_attrs(%{scope: :domain, address: "example.com", stream: :bulk})
      changeset = Entry.changeset(attrs)
      refute changeset.valid?
      assert {msg, _} = changeset.errors[:stream]
      assert msg =~ "must be omitted when scope is :domain"
      assert msg =~ "stream is only valid for :address_stream"
    end

    test "scope :address_stream + stream :bulk is valid" do
      attrs = valid_attrs(%{scope: :address_stream, stream: :bulk})
      changeset = Entry.changeset(attrs)
      assert changeset.valid?
    end
  end

  describe "changeset/1 — address normalization" do
    test "downcases address on cast (defense in depth with citext)" do
      attrs = valid_attrs(%{address: "Alice@Example.COM"})
      changeset = Entry.changeset(attrs)
      assert get_change(changeset, :address) == "alice@example.com"
    end
  end

  describe "DB CHECK constraint (belt-and-suspenders)" do
    test "DB rejects scope=:address_stream with NULL stream when changeset bypassed" do
      # Bypass changeset to test the DB CHECK directly. This proves
      # the CHECK catches writes that skip the Elixir-layer validation.
      assert_raise Postgrex.Error, ~r/mailglass_suppressions_stream_scope_check/, fn ->
        TestRepo.query!(
          """
          INSERT INTO mailglass_suppressions
            (id, tenant_id, address, scope, stream, reason, source, metadata, inserted_at)
          VALUES
            ($1, 'test', 'x@y.test', 'address_stream', NULL, 'manual', 'test', '{}', now())
          """,
          [uuid_binary()]
        )
      end
    end

    test "DB rejects scope=:address with NON-NULL stream when changeset bypassed" do
      assert_raise Postgrex.Error, ~r/mailglass_suppressions_stream_scope_check/, fn ->
        TestRepo.query!(
          """
          INSERT INTO mailglass_suppressions
            (id, tenant_id, address, scope, stream, reason, source, metadata, inserted_at)
          VALUES
            ($1, 'test', 'x@y.test', 'address', 'bulk', 'manual', 'test', '{}', now())
          """,
          [uuid_binary()]
        )
      end
    end
  end

  describe "round-trip" do
    test "inserts and reloads address as lowercase" do
      attrs = valid_attrs(%{address: "ALICE@EXAMPLE.COM"})
      {:ok, entry} = attrs |> Entry.changeset() |> TestRepo.insert()
      reloaded = TestRepo.get!(Entry, entry.id)
      assert reloaded.address == "alice@example.com"
    end

    test "inserts scope :address_stream + stream :bulk" do
      attrs = valid_attrs(%{scope: :address_stream, stream: :bulk})
      {:ok, entry} = attrs |> Entry.changeset() |> TestRepo.insert()
      reloaded = TestRepo.get!(Entry, entry.id)
      assert reloaded.scope == :address_stream
      assert reloaded.stream == :bulk
    end

    test "UNIQUE index prevents duplicate (tenant, address, scope, stream)" do
      attrs = valid_attrs(%{})
      {:ok, _} = attrs |> Entry.changeset() |> TestRepo.insert()

      # Ecto intercepts Postgrex.Error for constraint violations and raises
      # Ecto.ConstraintError when the schema hasn't declared a matching
      # unique_constraint/3. Plan 06's SuppressionStore.Ecto will add
      # unique_constraint + on_conflict; for the raw schema test we prove
      # the index fires end-to-end by pattern-matching the index name.
      assert_raise Ecto.ConstraintError,
                   ~r/mailglass_suppressions_tenant_address_scope_idx/,
                   fn -> attrs |> Entry.changeset() |> TestRepo.insert() end
    end
  end

  describe "reflection" do
    test "closed atom sets" do
      assert Entry.__scopes__() == [:address, :domain, :address_stream]
      assert Entry.__streams__() == [:transactional, :operational, :bulk]
      assert :hard_bounce in Entry.__reasons__()
      # Sanity check: pre-GA-removed :tenant_address is NOT a scope
      refute :tenant_address in Entry.__scopes__()
    end
  end

  defp valid_attrs(overrides) do
    Map.merge(
      %{
        tenant_id: "test-tenant",
        address: "user@example.com",
        scope: :address,
        reason: :manual,
        source: "test",
        metadata: %{}
      },
      overrides
    )
  end

  defp uuid_binary do
    {:ok, bin} = Ecto.UUID.dump(Ecto.UUID.generate())
    bin
  end
end
