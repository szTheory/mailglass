defmodule Mailglass.TestRepo do
  @moduledoc """
  Test-only Ecto Repo for mailglass's own test suite.

  Configured in `config/test.exs`. Points at the `mailglass_test`
  Postgres database. Adopters do NOT use this module — it exists so
  mailglass can exercise its own migrations and schemas.

  Migrations are driven by `Mailglass.Migration.up/0` (Plan 02) via
  the synthetic `priv/repo/migrations/00000000000001_mailglass_init.exs`
  file. The same `Mailglass.Migration.up/0` that adopters call.
  """
  use Ecto.Repo,
    otp_app: :mailglass,
    adapter: Ecto.Adapters.Postgres
end
