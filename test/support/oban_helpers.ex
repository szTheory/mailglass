defmodule Mailglass.ObanHelpers do
  @moduledoc """
  Runtime setup for Oban's `oban_jobs` table in the test DB.

  The mailglass project does not ship an Oban migration in `priv/repo/migrations/`
  — adopters bring their own Oban migration. For the test suite's `@tag oban: :manual`
  and `@tag oban: :inline` tests to function, the `oban_jobs` table must exist.

  `maybe_create_oban_jobs/0` is called from `test_helper.exs` after the mailglass
  migrations run. It delegates to `Oban.Migrations.up/1` (IF NOT EXISTS semantics),
  so repeated calls on a warmed DB are a no-op.

  ## Requirements for `@tag oban: :manual` tests

  1. `async: false` — enforced by the I-12 guard in `Mailglass.MailerCase`.
  2. `oban_jobs` table in the test DB — ensured by this helper at test_helper.exs start.
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

  No-op when Oban is not loaded or when the table already exists (Oban migrations
  use CREATE TABLE IF NOT EXISTS semantics). Safe to call on every test run.
  """
  def maybe_create_oban_jobs do
    if Code.ensure_loaded?(Oban.Migrations) do
      Ecto.Migrator.with_repo(Mailglass.TestRepo, fn _repo ->
        Oban.Migrations.up()
      end)
    end
  rescue
    _ -> :ok
  end
end
