defmodule Mailglass.StreamTest do
  use ExUnit.Case, async: true

  alias Mailglass.{Message, Stream}

  describe "policy_check/1" do
    test "returns :ok for :transactional" do
      msg = %Message{stream: :transactional, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      assert :ok = Stream.policy_check(msg)
    end

    test "returns :ok for :operational" do
      msg = %Message{stream: :operational, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      assert :ok = Stream.policy_check(msg)
    end

    test "returns :ok for :bulk" do
      msg = %Message{stream: :bulk, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      assert :ok = Stream.policy_check(msg)
    end

    test "emits [:mailglass, :outbound, :stream_policy, :stop] with whitelisted metadata" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass, :outbound, :stream_policy, :stop]
        ])

      msg = %Message{stream: :bulk, tenant_id: "t1", swoosh_email: Swoosh.Email.new()}
      Stream.policy_check(msg)

      assert_receive {[:mailglass, :outbound, :stream_policy, :stop], ^ref,
                      %{duration_us: _}, %{tenant_id: "t1", stream: :bulk}}

      :telemetry.detach(ref)
    end

    test "pattern-matches only on %Mailglass.Message{} — raw map raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Stream.policy_check(%{stream: :bulk})
      end
    end
  end
end
