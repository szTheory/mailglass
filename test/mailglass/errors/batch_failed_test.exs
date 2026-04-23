defmodule Mailglass.Error.BatchFailedTest do
  use ExUnit.Case, async: true

  alias Mailglass.Error.BatchFailed

  describe "__types__/0" do
    test "returns [:partial_failure, :all_failed]" do
      assert BatchFailed.__types__() == [:partial_failure, :all_failed]
    end
  end

  describe "struct shape" do
    test "is a defexception matchable with type and failures fields" do
      delivery = %Mailglass.Outbound.Delivery{
        id: Ecto.UUID.generate(),
        tenant_id: "t",
        mailable: "TestMailer",
        stream: :transactional,
        recipient: "a@b.com"
      }

      err = BatchFailed.new(:partial_failure, context: %{count: 3}, failures: [delivery])

      assert %BatchFailed{type: :partial_failure, failures: [_delivery]} = err
      assert err.failures == [delivery]
    end

    test "Jason.Encoder derives on [:type, :message, :context] — no :failures or :cause in JSON" do
      err = BatchFailed.new(:partial_failure, context: %{count: 2}, failures: [])
      json = Jason.encode!(err)
      decoded = Jason.decode!(json)

      assert Map.has_key?(decoded, "type")
      assert Map.has_key?(decoded, "message")
      assert Map.has_key?(decoded, "context")
      refute Map.has_key?(decoded, "failures")
      refute Map.has_key?(decoded, "cause")
    end
  end

  describe "new/2" do
    test "builds :partial_failure struct with message (brand voice)" do
      delivery = %Mailglass.Outbound.Delivery{
        id: Ecto.UUID.generate(),
        tenant_id: "t",
        mailable: "TestMailer",
        stream: :transactional,
        recipient: "a@b.com"
      }

      err =
        BatchFailed.new(:partial_failure,
          context: %{count: 3},
          failures: [delivery]
        )

      assert err.type == :partial_failure
      assert err.message =~ "partially failed"
      refute err.message =~ "Oops"
    end

    test "builds :all_failed struct" do
      err = BatchFailed.new(:all_failed, context: %{count: 5}, failures: [])
      assert err.type == :all_failed
      assert err.message =~ "failed"
    end

    test "is raisable as an exception" do
      err = BatchFailed.new(:partial_failure, failures: [])

      assert_raise BatchFailed, fn ->
        raise err
      end
    end
  end

  describe "retryable?/1" do
    test "returns true for batch failures (individual deliveries may retry)" do
      err = BatchFailed.new(:partial_failure, failures: [])
      assert BatchFailed.retryable?(err) == true
    end
  end
end
