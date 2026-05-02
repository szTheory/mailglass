defmodule Mailglass.Migrations.Postgres.V04 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    alter table(:mailglass_deliveries, prefix: prefix) do
      add(:adapter_ref, :text)
    end
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    alter table(:mailglass_deliveries, prefix: prefix) do
      remove(:adapter_ref)
    end
  end
end
