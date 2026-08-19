defmodule MailglassDemo.Repo.Migrations.UpgradeMailglassInbound do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    MailglassInbound.Migration.up(
      repo: MailglassDemo.Repo,
      non_transactional_wrapper: true
    )
  end

  def down do
    MailglassInbound.Migration.down(
      repo: MailglassDemo.Repo,
      version: 1,
      non_transactional_wrapper: true
    )
  end
end
