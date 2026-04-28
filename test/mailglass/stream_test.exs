defmodule Mailglass.StreamTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mailglass.{Message, Stream}

  describe "valid?/1" do
    test "returns true for valid streams" do
      assert Stream.valid?(:transactional)
      assert Stream.valid?(:operational)
      assert Stream.valid?(:bulk)
    end

    test "returns false for invalid streams" do
      refute Stream.valid?(:other)
      refute Stream.valid?("bulk")
      refute Stream.valid?(nil)
    end
  end

  describe "policy_check/1" do
    property "allows valid combinations and explicitly rejects :bulk without mailable" do
      check all(
              stream <- member_of([:transactional, :operational, :bulk]),
              tenant_id <- one_of([string(:alphanumeric), constant(nil)]),
              mailable <- one_of([constant(DummyMailable), constant(nil)])
            ) do
        msg = %Message{
          stream: stream,
          tenant_id: tenant_id,
          mailable: mailable,
          swoosh_email: Swoosh.Email.new()
        }

        if stream == :bulk and is_nil(mailable) do
          assert {:error, %Mailglass.StreamPolicyError{}} = Stream.policy_check(msg)
        else
          assert :ok = Stream.policy_check(msg)
        end
      end
    end

    test "returns :ok for :transactional" do
      msg = %Message{stream: :transactional, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      assert :ok = Stream.policy_check(msg)
    end

    test "returns :ok for :operational" do
      msg = %Message{stream: :operational, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      assert :ok = Stream.policy_check(msg)
    end

    test "returns :ok for :bulk when mailable is present" do
      msg = %Message{
        stream: :bulk,
        tenant_id: "t1",
        mailable: DummyMailable,
        swoosh_email: Swoosh.Email.new()
      }

      assert :ok = Stream.policy_check(msg)
    end

    test "returns {:error, %StreamPolicyError{}} for :bulk missing mailable" do
      msg = %Message{
        stream: :bulk,
        tenant_id: "t1",
        mailable: nil,
        swoosh_email: Swoosh.Email.new()
      }

      assert {:error,
              %Mailglass.StreamPolicyError{
                type: :stream_policy_violated,
                detail: %{rule: :bulk_requires_mailable}
              }} = Stream.policy_check(msg)
    end

    test "emits [:mailglass, :outbound, :stream_policy, :stop] with whitelisted metadata" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass, :outbound, :stream_policy, :stop]
        ])

      msg = %Message{stream: :bulk, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      Stream.policy_check(msg)

      assert_receive {[:mailglass, :outbound, :stream_policy, :stop], ^ref, %{duration_us: _},
                      %{tenant_id: "t1", stream: :bulk}}

      :telemetry.detach(ref)
    end

    test "pattern-matches only on %Mailglass.Message{} — raw map raises FunctionClauseError" do
      # Use apply/3 to bypass Elixir 1.18+ static type-narrowing warning.
      # The type checker correctly flags the mismatch at compile time; at runtime
      # the function clause still raises. Same pattern as struct-discrimination
      # tests documented in STATE.md decisions.
      assert_raise FunctionClauseError, fn ->
        apply(Stream, :policy_check, [%{stream: :bulk}])
      end
    end
  end
end
