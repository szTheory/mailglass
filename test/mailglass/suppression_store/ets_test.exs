defmodule Mailglass.SuppressionStore.ETSTest do
  use ExUnit.Case, async: false

  alias Mailglass.SuppressionStore.ETS
  alias Mailglass.Suppression.Entry

  setup do
    # Ensure the ETS supervisor is running and table exists
    assert Process.whereis(Mailglass.SuppressionStore.ETS.TableOwner) != nil,
           "SuppressionStore.ETS.TableOwner must be running"

    ETS.reset()
    :ok
  end

  describe "check/2 — empty table" do
    test "Test 1: returns :not_suppressed for unknown address" do
      result = ETS.check(%{tenant_id: "t1", address: "a@b.c", stream: :transactional}, [])
      assert result == :not_suppressed
    end
  end

  describe "record/2 + check/2 — address scope" do
    test "Test 2: record then check returns {:suppressed, %Entry{scope: :address}}" do
      assert {:ok, %Entry{scope: :address}} =
               ETS.record(
                 %{
                   tenant_id: "t1",
                   address: "a@b.c",
                   scope: :address,
                   reason: :manual,
                   source: "test"
                 },
                 []
               )

      result = ETS.check(%{tenant_id: "t1", address: "a@b.c"}, [])
      assert {:suppressed, %Entry{scope: :address}} = result
    end

    test "Test 3: re-record same (tenant_id, address, scope) updates reason (UPSERT)" do
      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "t1",
            address: "upsert@b.c",
            scope: :address,
            reason: :manual,
            source: "test"
          },
          []
        )

      {:ok, updated} =
        ETS.record(
          %{
            tenant_id: "t1",
            address: "upsert@b.c",
            scope: :address,
            reason: :complaint,
            source: "test"
          },
          []
        )

      assert updated.reason == :complaint

      {:suppressed, entry} = ETS.check(%{tenant_id: "t1", address: "upsert@b.c"}, [])
      assert entry.reason == :complaint
    end
  end

  describe "record/2 + check/2 — domain scope" do
    test "Test 4: domain-scope entry suppresses any address at that domain" do
      {:ok, _} =
        ETS.record(
          %{tenant_id: "t1", address: "spam.com", scope: :domain, reason: :manual, source: "test"},
          []
        )

      result = ETS.check(%{tenant_id: "t1", address: "anyone@spam.com"}, [])
      assert {:suppressed, %Entry{scope: :domain}} = result
    end
  end

  describe "record/2 + check/2 — address_stream scope" do
    test "Test 5: address_stream scope only matches when stream key is present and matches" do
      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "t1",
            address: "stream@b.c",
            scope: :address_stream,
            stream: :bulk,
            reason: :unsubscribe,
            source: "test"
          },
          []
        )

      # With matching stream: suppressed
      result_with_stream = ETS.check(%{tenant_id: "t1", address: "stream@b.c", stream: :bulk}, [])
      assert {:suppressed, %Entry{scope: :address_stream}} = result_with_stream

      # Without stream key: not suppressed (no stream = only :address/:domain scopes checked)
      result_no_stream = ETS.check(%{tenant_id: "t1", address: "stream@b.c"}, [])
      assert result_no_stream == :not_suppressed

      # With different stream: not suppressed
      result_wrong_stream =
        ETS.check(%{tenant_id: "t1", address: "stream@b.c", stream: :transactional}, [])

      assert result_wrong_stream == :not_suppressed
    end
  end

  describe "check/2 — expiry filter" do
    test "Test 6: expired entries are not returned by check/2" do
      past = DateTime.add(Mailglass.Clock.utc_now(), -3600, :second)

      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "t1",
            address: "expired@b.c",
            scope: :address,
            reason: :manual,
            source: "test",
            expires_at: past
          },
          []
        )

      result = ETS.check(%{tenant_id: "t1", address: "expired@b.c"}, [])
      assert result == :not_suppressed
    end
  end

  describe "supervision — TableOwner crash + restart (Test 11)" do
    test "after killing TableOwner, supervisor restarts it with empty table" do
      # Record an entry to confirm state
      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "t1",
            address: "crash@b.c",
            scope: :address,
            reason: :manual,
            source: "test"
          },
          []
        )

      assert {:suppressed, _} = ETS.check(%{tenant_id: "t1", address: "crash@b.c"}, [])

      owner_pid = Process.whereis(Mailglass.SuppressionStore.ETS.TableOwner)
      assert is_pid(owner_pid)

      # Kill TableOwner
      Process.exit(owner_pid, :kill)

      # Poll for restart (max 500ms)
      new_pid =
        Enum.find_value(1..50, fn _ ->
          Process.sleep(10)
          pid = Process.whereis(Mailglass.SuppressionStore.ETS.TableOwner)
          if pid && pid != owner_pid, do: pid
        end)

      assert is_pid(new_pid), "TableOwner should restart within 500ms"

      # ETS table is fresh — prior entry gone
      result = ETS.check(%{tenant_id: "t1", address: "crash@b.c"}, [])
      assert result == :not_suppressed
    end
  end
end
