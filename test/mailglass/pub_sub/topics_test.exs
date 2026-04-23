defmodule Mailglass.PubSub.TopicsTest do
  use ExUnit.Case, async: true

  alias Mailglass.PubSub.Topics

  describe "events/1" do
    test "returns 'mailglass:events:<tenant_id>'" do
      assert Topics.events("acme") == "mailglass:events:acme"
    end

    test "output starts with 'mailglass:'" do
      assert String.starts_with?(Topics.events("tenant-x"), "mailglass:")
    end
  end

  describe "events/2" do
    test "returns 'mailglass:events:<tenant_id>:<delivery_id>'" do
      assert Topics.events("acme", "01HXYZ") == "mailglass:events:acme:01HXYZ"
    end

    test "output starts with 'mailglass:'" do
      assert String.starts_with?(Topics.events("acme", "01HXYZ"), "mailglass:")
    end
  end

  describe "deliveries/1" do
    test "returns 'mailglass:deliveries:<tenant_id>'" do
      assert Topics.deliveries("acme") == "mailglass:deliveries:acme"
    end

    test "output starts with 'mailglass:'" do
      assert String.starts_with?(Topics.deliveries("acme"), "mailglass:")
    end
  end

  describe "prefix invariant" do
    test "all topic builder outputs are prefixed with 'mailglass:'" do
      tenant_ids = ["acme", "tenant-a", "org_123", "t"]
      delivery_ids = ["01HXYZ", "uuid-1234", "d_999"]

      for tenant_id <- tenant_ids do
        assert String.starts_with?(Topics.events(tenant_id), "mailglass:")
        assert String.starts_with?(Topics.deliveries(tenant_id), "mailglass:")

        for delivery_id <- delivery_ids do
          assert String.starts_with?(Topics.events(tenant_id, delivery_id), "mailglass:")
        end
      end
    end
  end
end
