defmodule MailglassInbound.Ports.Core do
  @moduledoc false

  @doc false
  @spec safe_broadcast(String.t(), term()) :: :ok
  defdelegate safe_broadcast(topic, payload), to: Mailglass.Ports.PubSub

  @doc false
  @spec with_job_tenant(map(), (-> term())) :: term()
  def with_job_tenant(%{args: %{"mailglass_tenant_id" => tenant_id}}, fun)
      when is_binary(tenant_id) and is_function(fun, 0),
      do: Mailglass.Tenancy.with_tenant(tenant_id, fun)

  def with_job_tenant(_job, fun) when is_function(fun, 0), do: fun.()

  @doc false
  @spec suppressed_sender?(String.t(), String.t()) :: boolean()
  defdelegate suppressed_sender?(tenant_id, address), to: Mailglass.Ports.Suppression
end
