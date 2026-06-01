defmodule MailglassDemo.Repo.Migrations.InstallMailglass do
  use Ecto.Migration

  def up, do: Mailglass.Migration.up()
  def down, do: Mailglass.Migration.down()
end
