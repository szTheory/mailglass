defmodule Mailglass.Outbound.Routes do
  @moduledoc false

  alias Mailglass.{Config, Message, Tenancy}
  alias Mailglass.Outbound.Delivery

  def resolve_sync(%Message{} = rendered, opts) do
    case Keyword.fetch(opts, :adapter) do
      {:ok, override} ->
        with {:ok, adapter} <- normalize_adapter(override) do
          {:ok, %{adapter: adapter, adapter_ref: persisted_ref(adapter)}}
        end

      :error ->
        case Keyword.fetch(opts, :adapter_ref) do
          {:ok, ref} -> named_route(ref)
          :error -> tenancy_or_default(rendered, :sync)
        end
    end
  end

  def resolve_async(%Message{} = rendered, opts) do
    case Keyword.fetch(opts, :adapter) do
      {:ok, override} ->
        with {:ok, adapter} <- normalize_adapter(override) do
          case persisted_ref(adapter) do
            nil -> error(:queued_adapter_override_not_persistable)
            ref -> {:ok, ref}
          end
        end

      :error ->
        case Keyword.fetch(opts, :adapter_ref) do
          {:ok, ref} -> with {:ok, _} <- named_adapter(ref), do: {:ok, stringify(ref)}
          :error -> resolve_async_tenancy(rendered)
        end
    end
  end

  def resolve_persisted(nil), do: default_adapter()

  def resolve_persisted(ref) do
    if ref == Delivery.default_adapter_ref(), do: default_adapter(), else: named_adapter(ref)
  end

  defp resolve_async_tenancy(rendered) do
    case tenancy_outcome(rendered, :async) do
      :default -> {:ok, Delivery.default_adapter_ref()}
      {:ok, ref} -> with {:ok, _} <- named_adapter(ref), do: {:ok, stringify(ref)}
      {:error, error} -> {:error, error}
    end
  end

  defp tenancy_or_default(rendered, mode) do
    case tenancy_outcome(rendered, mode) do
      :default ->
        with {:ok, adapter} <- default_adapter(),
             do: {:ok, %{adapter: adapter, adapter_ref: Delivery.default_adapter_ref()}}

      {:ok, ref} ->
        named_route(ref)

      {:error, error} ->
        {:error, error}
    end
  end

  defp tenancy_outcome(rendered, mode) do
    case Tenancy.resolve_outbound_adapter_ref(%{
           tenant_id: rendered.tenant_id,
           message: rendered,
           mode: mode
         }) do
      :default -> :default
      {:ok, ref} when is_atom(ref) or is_binary(ref) -> {:ok, ref}
      other -> error(:invalid_adapter_ref_callback, returned: inspect(other))
    end
  end

  defp named_route(ref),
    do:
      with(
        {:ok, adapter} <- named_adapter(ref),
        do: {:ok, %{adapter: adapter, adapter_ref: stringify(ref)}}
      )

  defp default_adapter do
    {:ok, Config.default_adapter()}
  rescue
    error in [Mailglass.ConfigError, NimbleOptions.ValidationError] ->
      config_error(:adapter, nil, error)
  end

  defp named_adapter(ref) do
    {:ok, Config.resolve_adapter_ref(ref)}
  rescue
    error in [Mailglass.ConfigError, NimbleOptions.ValidationError] ->
      config_error(:adapters, ref, error)
  end

  defp normalize_adapter(module) when is_atom(module), do: {:ok, {module, []}}

  defp normalize_adapter({module, opts}) when is_atom(module) and is_list(opts) do
    if Keyword.keyword?(opts), do: {:ok, {module, opts}}, else: invalid_adapter()
  end

  defp normalize_adapter(_), do: invalid_adapter()
  defp invalid_adapter, do: {:error, Mailglass.ConfigError.new(:invalid, context: %{key: :adapter})}

  defp persisted_ref(adapter) do
    cond do
      match?({:ok, ^adapter}, default_adapter()) ->
        Delivery.default_adapter_ref()

      ref =
          Enum.find_value(Config.adapters(), fn {key, value} ->
            if value == adapter, do: stringify(key)
          end) ->
        ref

      true ->
        nil
    end
  rescue
    _ -> nil
  end

  defp stringify(ref) when is_atom(ref), do: Atom.to_string(ref)
  defp stringify(ref) when is_binary(ref), do: ref

  defp config_error(_key, _ref, %Mailglass.ConfigError{} = error), do: {:error, error}

  defp config_error(key, ref, error),
    do:
      {:error,
       Mailglass.ConfigError.new(:invalid,
         context: %{key: key, adapter_ref: ref, reason: Exception.message(error)}
       )}

  defp error(reason, extra \\ []),
    do:
      {:error,
       Mailglass.SendError.new(:adapter_failure, context: Map.new([reason_class: reason] ++ extra))}
end
