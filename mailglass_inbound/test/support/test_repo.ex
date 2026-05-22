defmodule MailglassInbound.TestRepo do
  @moduledoc """
  Test-only Ecto Repo for the `mailglass_inbound` test suite.

  Configured in `config/test.exs`. Points at the `mailglass_inbound_test`
  Postgres database. Adopters do NOT use this module — it exists so
  `mailglass_inbound` can exercise its own migrations and schemas (notably the
  ingress dedupe unique index) against a real Postgres database.

  `config :mailglass_inbound, :repo, MailglassInbound.TestRepo` makes the
  `MailglassInbound.Repo` facade resolve to this repo in the test env. The repo
  is started in `test/test_helper.exs` after migrations run; it is not added to
  any application supervision tree and never uses `name: __MODULE__`.
  """
  use Ecto.Repo,
    otp_app: :mailglass_inbound,
    adapter: Ecto.Adapters.Postgres
end
