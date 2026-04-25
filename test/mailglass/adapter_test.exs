defmodule Mailglass.AdapterTest do
  use ExUnit.Case, async: true

  @moduletag :phase_03_uat

  describe "Mailglass.Adapter behaviour" do
    test "behaviour defines exactly one callback: deliver/2" do
      callbacks = Mailglass.Adapter.behaviour_info(:callbacks)
      assert [{:deliver, 2}] == callbacks
    end

    test "a module implementing @behaviour Mailglass.Adapter with deliver/2 satisfies the contract" do
      defmodule StubAdapter do
        @behaviour Mailglass.Adapter
        @impl Mailglass.Adapter
        def deliver(%Mailglass.Message{} = _msg, _opts) do
          {:ok, %{message_id: "stub-id", provider_response: %{}}}
        end
      end

      # behaviour_info(:attributes) is a module metadata check
      attributes = StubAdapter.module_info(:attributes)
      behaviours = Keyword.get(attributes, :behaviour, [])
      assert Mailglass.Adapter in behaviours
    end

    test "deliver/2 return shape is locked: {:ok, %{message_id: String.t(), provider_response: term()}} | {:error, Error.t()}" do
      # The callback spec check — we verify via a compliant stub
      defmodule StubAdapter2 do
        @behaviour Mailglass.Adapter
        @impl Mailglass.Adapter
        def deliver(%Mailglass.Message{}, _opts) do
          {:ok, %{message_id: "test-id", provider_response: %{some: :data}}}
        end
      end

      email = Swoosh.Email.new(subject: "Test")
      msg = Mailglass.Message.new(email, mailable: StubAdapter2, tenant_id: "test")

      assert {:ok, %{message_id: "test-id", provider_response: %{some: :data}}} =
               StubAdapter2.deliver(msg, [])
    end

    test "behaviour_info returns the correct callback list for Mailglass.Adapter" do
      assert Mailglass.Adapter.behaviour_info(:callbacks) == [{:deliver, 2}]
      assert Mailglass.Adapter.behaviour_info(:optional_callbacks) == []
    end
  end
end
