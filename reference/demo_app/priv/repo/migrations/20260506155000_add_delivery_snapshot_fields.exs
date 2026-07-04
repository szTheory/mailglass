defmodule MailglassDemo.Repo.Migrations.AddDeliverySnapshotFields do
  use Ecto.Migration

  # No-op as of mailglass v2.0.
  #
  # This migration used to add `idempotency_key`, `status`, and `last_error` to
  # `mailglass_deliveries` plus the `mailglass_deliveries_idempotency_key_unique_idx`
  # partial unique index. As of v2.0 the core install (`Mailglass.Migration.up/0`,
  # run by the preceding `20260506150000_install_mailglass` migration) creates all
  # three columns AND that exact index first-class in `Mailglass.Migrations.Postgres.V05`
  # (character-for-character the same `where: "idempotency_key IS NOT NULL"` predicate).
  #
  # Re-adding them here now collides:
  #   ** (Postgrex.Error) ERROR 42701 (duplicate_column)
  #      column "idempotency_key" of relation "mailglass_deliveries" already exists
  #
  # The migration is kept (not deleted) so its version stays recorded in
  # `schema_migrations` for DBs that already ran the old body. There is nothing
  # left for the demo to provide, so both directions are intentionally empty.

  def up, do: :ok

  def down, do: :ok
end
