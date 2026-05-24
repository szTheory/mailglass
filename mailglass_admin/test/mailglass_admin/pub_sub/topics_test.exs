defmodule MailglassAdmin.PubSub.TopicsTest do
  @moduledoc """
  V8 — topic-builder parity (CONTEXT D-48-11). The admin is a CONSUMER of the
  inbound `inbound_record_inserted/1` stream; a subscribe built by the admin
  builder MUST match a broadcast built by the inbound builder, or the operator
  dashboard silently never sees new inbound mail. This asserts the two builders
  return byte-identical strings — without an inbound→admin compile dependency
  (the admin reaches the inbound builder only here, in test).
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.PubSub.Topics

  test "admin_reload/0 is the prefixed LiveReload topic" do
    assert Topics.admin_reload() == "mailglass:admin:reload"
  end

  describe "inbound_record_inserted/1 parity with the inbound builder (V8)" do
    test "matches MailglassInbound.PubSub.Topics.inbound_record_inserted/1 for an arbitrary tenant" do
      tenant_id = "tenant-#{System.unique_integer([:positive])}"

      assert Topics.inbound_record_inserted(tenant_id) ==
               MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
    end

    test "matches across several tenant id shapes" do
      for tenant_id <- ["default", "acme-corp", "uuid-019e5af3-2a74", "tenant with spaces"] do
        assert Topics.inbound_record_inserted(tenant_id) ==
                 MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
      end
    end

    test "is prefixed mailglass:inbound:" do
      assert Topics.inbound_record_inserted("acme") == "mailglass:inbound:acme"
    end
  end
end
