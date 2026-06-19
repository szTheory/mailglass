defmodule MailglassAdmin.OptionalDeps.MailglassInboundTest do
  use ExUnit.Case, async: true

  Code.ensure_loaded?(MailglassInbound) ||
    Code.require_file("../../../../mailglass_inbound/lib/mailglass_inbound.ex", __DIR__)

  alias MailglassAdmin.OptionalDeps.MailglassInbound

  defmodule InboundTenantReadModel do
    def list_tenants(context, opts) do
      send(context.test_pid, {:inbound_context, context, opts})

      [
        %{id: "tenant-b", label: "tenant-b"},
        %{id: "tenant-a", label: "tenant-a"},
        %{id: "tenant-a", label: "tenant-a"}
      ]
    end
  end

  describe "list_tenants/2" do
    test "surfaces inbound tenant ids through the runtime apply gateway when mailglass_inbound is loaded" do
      context = %{subject_id: "operator-1", test_pid: self()}

      assert MailglassInbound.list_tenants(context, read_model: InboundTenantReadModel) == [
               %{id: "tenant-a", label: "tenant-a"},
               %{id: "tenant-b", label: "tenant-b"}
             ]

      assert_received {:inbound_context, ^context, [read_model: InboundTenantReadModel]}
    end
  end
end
