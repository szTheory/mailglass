defmodule MailglassAdmin.Inbound.ReadResult do
  @moduledoc false

  @type result(value) :: {:ok, value} | {:error, :read_unavailable}

  @doc """
  Converts expected gateway failure shapes into one safe operator-facing state.

  Only explicit error tuples and database connection failures are classified as
  unavailable. Other exceptions remain visible to maintainers.
  """
  @spec fetch((-> value)) :: result(value) when value: term()
  def fetch(read) when is_function(read, 0) do
    case read.() do
      {:error, _reason} -> {:error, :read_unavailable}
      value -> {:ok, value}
    end
  rescue
    _error in DBConnection.ConnectionError -> {:error, :read_unavailable}
  end
end
