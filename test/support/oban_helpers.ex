defmodule Mailglass.ObanHelpers do
  @moduledoc """
  Runtime setup for Oban's `oban_jobs` table in the test DB.

  The mailglass project does not ship an Oban migration in `priv/repo/migrations/`
  — adopters bring their own Oban migration. For the test suite's `@tag oban: :manual`
  and `@tag oban: :inline` tests to function, the `oban_jobs` table must exist.
  Both lanes require `async: false`.

  `maybe_create_oban_jobs/0` is called from `test_helper.exs` after the core
  migrations and repo startup. It runs a tiny test-only migration that delegates
  to `Oban.Migrations.up/1`, so Oban's migration code executes inside Ecto's
  migration runner instead of failing with "could not find migration runner
  process".

  ## Requirements for `@tag oban: :manual` tests

  1. `async: false` — enforced by the I-12 guard in `Mailglass.MailerCase`.
  2. `oban_jobs` table must exist in the test DB — ensured by this helper at test_helper.exs start.
  3. Oban >= 2.18 in deps (listed in `mix.exs` as `{:oban, "~> 2.21", optional: true}`).

  ## Usage

      @tag oban: :manual
      test "job is enqueued" do
        msg = TestMailer.welcome("test@example.com")
        assert {:ok, %Delivery{status: :queued}} = Outbound.deliver_later(msg)
        assert_enqueued(worker: Mailglass.Outbound.Worker)
      end

  `assert_enqueued/1` is provided by `use Oban.Testing, repo: Mailglass.TestRepo`
  in the test module.
  """

  @doc """
  Ensures the `oban_jobs` table exists in the test DB.

  No-op when Oban is not loaded or when the Ecto migration version has already
  been recorded. Safe to call on every test run.
  """
  def maybe_create_oban_jobs do
    if Code.ensure_loaded?(Oban.Migrations) do
      Ecto.Migrator.up(
        Mailglass.TestRepo,
        20_260_527_000_001,
        Mailglass.ObanHelpers.TestObanMigration,
        log: false
      )
    end
  end

  defmodule TestObanMigration do
    @moduledoc false
    use Ecto.Migration

    def up, do: Oban.Migrations.up()
    def down, do: Oban.Migrations.down()
  end
end
