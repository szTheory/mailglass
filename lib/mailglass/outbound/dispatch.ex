defmodule Mailglass.Outbound.Dispatch do
  @moduledoc false

  alias Mailglass.{Message, Telemetry}
  alias Mailglass.Outbound.{Delivery, Persistence}

  def call_adapter(%Message{} = rendered, {adapter_module, adapter_opts}) do
    Telemetry.dispatch_span(
      %{
        tenant_id: rendered.tenant_id,
        mailable: rendered.mailable,
        provider: adapter_module
      },
      fn -> adapter_module.deliver(rendered, adapter_opts) end
    )
  end

  def call_adapter_or_persist_failure(
        %Delivery{} = delivery,
        %Message{} = rendered,
        adapter
      ) do
    case call_adapter(rendered, adapter) do
      {:ok, _result} = success ->
        success

      {:error, %{__exception__: true} = error} ->
        Persistence.persist_failed_by_id(delivery.id, error)
        {:error, error}

      {:error, other} ->
        error = Mailglass.SendError.new(:adapter_failure, context: %{wrapped: inspect(other)})
        Persistence.persist_failed_by_id(delivery.id, error)
        {:error, error}
    end
  end

  def async_mode(opts) when is_list(opts) do
    async_adapter = Keyword.get(opts, :async_adapter) || Mailglass.Config.async_adapter()

    if async_adapter != :task_supervisor and Mailglass.OptionalDeps.Oban.available?(),
      do: :oban,
      else: :task_supervisor
  end

  def enqueue_one(%Delivery{} = delivery, dispatch_by_id) when is_function(dispatch_by_id, 1) do
    case admit_task(delivery, dispatch_by_id) do
      :ok -> {:ok, %{delivery | status: :queued, last_event_type: :queued}}
      {:refused, error, _failed_delivery} -> {:error, error}
      {:error, persist_error} -> {:error, persist_error}
    end
  end

  def enqueue_many(deliveries, dispatch_by_id)
      when is_list(deliveries) and is_function(dispatch_by_id, 1) do
    Enum.reduce_while(deliveries, {:ok, %{}}, fn %Delivery{} = delivery, {:ok, updates} ->
      case admit_task(delivery, dispatch_by_id) do
        :ok ->
          {:cont, {:ok, updates}}

        {:refused, _error, failed_delivery} ->
          {:cont, {:ok, Map.put(updates, delivery.id, failed_delivery)}}

        {:error, persist_error} ->
          {:halt, {:error, persist_error}}
      end
    end)
  end

  defp admit_task(%Delivery{} = delivery, dispatch_by_id) do
    case Mailglass.Outbound.AsyncAdapter.dispatch(
           fn -> execute_task(delivery, dispatch_by_id) end,
           []
         ) do
      {:ok, _pid} -> :ok
      :ok -> :ok
      {:error, reason} -> persist_refusal(delivery, reason)
    end
  end

  defp execute_task(%Delivery{} = delivery, dispatch_by_id) do
    Mailglass.Tenancy.with_tenant(delivery.tenant_id, fn ->
      try do
        case dispatch_by_id.(delivery.id) do
          {:ok, _} -> :ok
          {:error, error} -> log_task_failure(delivery.id, error)
        end
      rescue
        error -> log_task_failure(delivery.id, error)
      end
    end)
  end

  defp persist_refusal(%Delivery{} = delivery, reason) do
    error =
      Mailglass.SendError.new(:dispatch_unavailable,
        retry_class: :transient,
        context: %{reason_class: refusal_reason(reason)},
        delivery_id: delivery.id
      )

    case Persistence.persist_failed_by_id(delivery.id, error) do
      {:ok, failed_delivery} -> {:refused, error, failed_delivery}
      {:error, persist_error} -> {:error, persist_error}
    end
  end

  defp refusal_reason(:max_children), do: :capacity_reached
  defp refusal_reason(:supervisor_unavailable), do: :supervisor_unavailable
  defp refusal_reason(_reason), do: :start_child_failed

  defp log_task_failure(delivery_id, error) do
    require Logger

    Logger.warning(
      "[mailglass] Task.Supervisor dispatch failed for #{delivery_id}: #{Exception.message(error)}"
    )
  end
end
