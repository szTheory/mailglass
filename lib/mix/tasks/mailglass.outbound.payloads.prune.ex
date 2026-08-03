defmodule Mix.Tasks.Mailglass.Outbound.Payloads.Prune do
  use Boundary, classify_to: Mailglass

  @shortdoc "Prune one tenant's expired outbound payload batch"

  @moduledoc """
  Manually run one bounded, tenant-explicit outbound payload prune batch.

  This is the universal operational path: it works whether or not Oban is
  installed, and calls the same `Mailglass.Outbound.PayloadPruner.prune/1`
  function as the optional scheduled worker.

  ## Usage

      mix mailglass.outbound.payloads.prune --tenant TENANT_ID

  `--tenant` is required. The task never defaults or enumerates tenants. Its
  output contains aggregate lifecycle state and reason counts only.
  """

  use Mix.Task

  alias Mailglass.Outbound.PayloadPruner

  @impl Mix.Task
  def run(argv) do
    {opts, _rest, _invalid} = OptionParser.parse(argv, strict: [tenant: :string])
    tenant_id = required_tenant!(opts[:tenant])

    unless Process.whereis(Mailglass.Supervisor) do
      case Application.ensure_all_started(:mailglass) do
        {:ok, _started} ->
          :ok

        {:error, reason} ->
          Mix.raise("could not start mailglass for payload pruning: #{inspect(reason)}")
      end
    end

    # Keep this operational adapter on the same public core function,
    # `PayloadPruner.prune/1`, without widening the Outbound boundary exports.
    case apply(PayloadPruner, :prune, [[tenant_id: tenant_id]]) do
      {:ok, count} ->
        Mix.shell().info(
          "Outbound payload prune complete: expired=#{count} retention_expired=#{count}"
        )

      {:error, :tenant_required} ->
        Mix.raise("--tenant TENANT_ID is required")

      {:error, reason} ->
        Mix.raise("outbound payload prune failed: #{inspect(reason)}")
    end
  end

  defp required_tenant!(tenant_id) when is_binary(tenant_id) do
    if String.trim(tenant_id) == "",
      do: Mix.raise("--tenant TENANT_ID is required"),
      else: tenant_id
  end

  defp required_tenant!(_tenant_id), do: Mix.raise("--tenant TENANT_ID is required")
end
