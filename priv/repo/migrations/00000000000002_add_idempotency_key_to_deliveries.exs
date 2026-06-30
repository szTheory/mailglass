defmodule Mailglass.TestRepo.Migrations.AddIdempotencyKeyToDeliveries do
  use Ecto.Migration

  # Reconciled to a no-op: the deliveries idempotency_key / status / last_error
  # columns and the partial unique index are now owned by the SHIPPED dispatcher
  # version step `Mailglass.Migrations.Postgres.V05`, which the preceding
  # `00000000000001_mailglass_init.exs` already applies via
  # `Mailglass.Migration.up/0` (now @current_version 5).
  #
  # This eliminates the divergence at its source — there is exactly ONE
  # definition of the deliveries idempotency DDL (V05), exercised identically by
  # the internal TestRepo path and the adopter dispatcher path
  # (see shipped_migration_divergence_test.exs). Re-running V05 here would
  # double-apply and raise `duplicate_column`, so this file is intentionally
  # inert. It is retained (rather than deleted) so the flat-file migration
  # ordering and the existing `schema_migrations` history stay stable for
  # `Ecto.Migrator.run(:up/:down, all: true)` round-trips.
  def up, do: :ok
  def down, do: :ok
end
