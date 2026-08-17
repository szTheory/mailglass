defmodule MailglassInbound.Execution.RouterRegistry do
  @moduledoc false

  use GenServer

  @type authority_id :: String.t()

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @spec register_router(module()) ::
          {:ok, authority_id()} | {:error, :invalid_router | :unavailable}
  def register_router(router) when is_atom(router) do
    with true <- Code.ensure_loaded?(router),
         true <- function_exported?(router, :__mailglass_inbound_routes__, 0) do
      register(Atom.to_string(router), router.__mailglass_inbound_routes__())
    else
      _ -> {:error, :invalid_router}
    end
  end

  def register_router(_router), do: {:error, :invalid_router}

  @spec resolve(authority_id(), String.t()) :: {:ok, module()} | {:error, term()}
  def resolve(authority_id, mailbox) when is_binary(authority_id) and is_binary(mailbox) do
    call({:resolve, authority_id, mailbox})
  end

  @spec resolve_any(String.t()) :: {:ok, module()} | {:error, term()}
  def resolve_any(mailbox) when is_binary(mailbox), do: call({:resolve_any, mailbox})

  defp register(authority_id, routes) when is_binary(authority_id) and is_list(routes) do
    case mailbox_index(routes) do
      {:ok, index} ->
        case call({:register, authority_id, index}) do
          :ok -> {:ok, authority_id}
          {:error, :unavailable} = error -> error
        end

      :error ->
        {:error, :invalid_router}
    end
  end

  defp call(message) do
    try do
      GenServer.call(__MODULE__, message)
    catch
      :exit, _reason -> {:error, :unavailable}
    end
  end

  @impl GenServer
  def init(:ok), do: {:ok, %{}}

  @impl GenServer
  def handle_call({:register, authority_id, index}, _from, authorities) do
    {:reply, :ok, Map.put(authorities, authority_id, index)}
  end

  def handle_call({:resolve, authority_id, mailbox}, _from, authorities) do
    case get_in(authorities, [authority_id, mailbox]) do
      module when is_atom(module) and not is_nil(module) ->
        {:reply, {:ok, module}, authorities}

      _ ->
        {:reply, {:error, :unavailable}, authorities}
    end
  end

  def handle_call({:resolve_any, mailbox}, _from, authorities) do
    module =
      authorities
      |> Map.values()
      |> Enum.find_value(fn index -> Map.get(index, mailbox) end)

    if is_atom(module) and not is_nil(module) do
      {:reply, {:ok, module}, authorities}
    else
      {:reply, {:error, :not_authorized}, authorities}
    end
  end

  defp mailbox_index(routes) do
    routes
    |> Enum.reduce_while(%{}, fn
      %{mailbox: module}, index when is_atom(module) ->
        {:cont, Map.put(index, Atom.to_string(module), module)}

      _route, _index ->
        {:halt, :error}
    end)
    |> case do
      :error -> :error
      index -> {:ok, index}
    end
  end
end
