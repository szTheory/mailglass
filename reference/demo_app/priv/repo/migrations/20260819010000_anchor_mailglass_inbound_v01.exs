defmodule MailglassDemo.Repo.Migrations.AnchorMailglassInboundV01 do
  use Ecto.Migration

  # The demo predates mailglass_inbound's package-owned migration dispatcher.
  # Its historical migrations built the V01-equivalent tables directly, so
  # record that known baseline before handing future upgrades to the package.
  def up do
    execute("COMMENT ON TABLE mailglass.mailglass_inbound_records IS '1'")
  end

  def down do
    execute("COMMENT ON TABLE mailglass.mailglass_inbound_records IS NULL")
  end
end
