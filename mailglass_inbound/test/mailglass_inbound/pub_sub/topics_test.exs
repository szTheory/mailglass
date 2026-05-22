defmodule MailglassInbound.PubSub.TopicsTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.PubSub.Topics

  describe "inbound_record_inserted/1" do
    test "returns the per-tenant inbound topic with the mailglass: prefix" do
      assert Topics.inbound_record_inserted("t_123") == "mailglass:inbound:t_123"
    end

    test "is tenant-specific so two tenants never collide" do
      refute Topics.inbound_record_inserted("tenant-a") ==
               Topics.inbound_record_inserted("tenant-b")
    end

    test "raises a FunctionClauseError on a non-binary tenant_id (is_binary guard)" do
      assert_raise FunctionClauseError, fn ->
        Topics.inbound_record_inserted(:not_a_binary)
      end

      assert_raise FunctionClauseError, fn ->
        Topics.inbound_record_inserted(nil)
      end
    end
  end
end
