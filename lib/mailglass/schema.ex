defmodule Mailglass.Schema do
  @moduledoc """
  Stamps mailglass-wide schema conventions onto a module.

  Three module attributes, no behaviour injection, no magic — consistent
  with 's "pluggable behaviours over magic" DNA. Consumed by
  `Mailglass.Outbound.Delivery`, `Mailglass.Events.Event`, and
  `Mailglass.Suppression.Entry`.

  ## Usage

      defmodule Mailglass.MyThing do
        use Mailglass.Schema

        schema "mailglass_my_things" do
          field :name, :string
          timestamps(type: :utc_datetime_usec)
        end
      end

  Stamped attributes per :

  - `@primary_key {:id, UUIDv7, autogenerate: true}`
  - `@foreign_key_type :binary_id`
  - `@timestamps_opts [type: :utc_datetime_usec]`
  """
  @doc since: "0.1.0"
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
