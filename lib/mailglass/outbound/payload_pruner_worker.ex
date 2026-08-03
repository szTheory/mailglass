if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Outbound.PayloadPrunerWorker do
    @moduledoc """
    Optional Oban entrypoint for one tenant's bounded payload-prune batch.

    The worker carries only `mailglass_tenant_id`; it does not enumerate or
    default tenants. Schedule it from an adopter-owned Oban cron using the
    existing `:mailglass_maintenance` queue. The manual Mix task remains
    available when Oban is not installed.
    """

    use Oban.Worker, queue: :mailglass_maintenance

    alias Mailglass.Outbound.PayloadPruner

    @doc since: "2.4.1"
    @spec available?() :: true
    def available?, do: true

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"mailglass_tenant_id" => tenant_id} = args})
        when is_binary(tenant_id) and map_size(args) == 1 do
      case PayloadPruner.prune(tenant_id: tenant_id) do
        {:ok, _count} -> :ok
        {:error, :tenant_required} -> {:cancel, :tenant_required}
        {:error, reason} -> {:error, reason}
      end
    end

    def perform(_job), do: {:cancel, :tenant_required}
  end
else
  defmodule Mailglass.Outbound.PayloadPrunerWorker do
    @moduledoc """
    Availability stub for the optional scheduled payload-pruning entrypoint.

    Run `mix mailglass.outbound.payloads.prune --tenant TENANT_ID` manually or
    from system cron when Oban is absent.
    """

    @doc since: "2.4.1"
    @spec available?() :: false
    def available?, do: false
  end
end
