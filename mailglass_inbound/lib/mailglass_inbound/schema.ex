defmodule MailglassInbound.Schema do
  @moduledoc """
  Stamps `mailglass_inbound` schema conventions onto internal persistence modules.

  Mirrors the core package conventions while keeping the storage boundary local
  to `mailglass_inbound`.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
