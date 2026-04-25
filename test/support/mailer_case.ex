defmodule Mailglass.MailerCase do
  @moduledoc """
  Shared ExUnit case template for mailable + outbound tests (TEST-02, D-06).

  ## Default setup

  - `Ecto.Adapters.SQL.Sandbox.start_owner!` with `shared: not tags[:async]`
  - `Mailglass.Adapters.Fake.checkout()`
  - `Mailglass.Tenancy.put_current("test-tenant")` (unless `@tag tenant: :unset`)
  - `Phoenix.PubSub.subscribe(Mailglass.PubSub, Topics.events(tenant_id))`
  - `Mailglass.Clock.Frozen.freeze(dt)` when `@tag frozen_at: dt`
  - Oban.Testing `:inline` mode by default; `@tag oban: :manual` opts into
    assert_enqueued/perform_job

  ## Supported tags

  - `@tag tenant: "acme"` — override the default `"test-tenant"`
  - `@tag tenant: :unset` — disable tenancy stamping (test unstamped-fail paths)
  - `@tag frozen_at: ~U[2026-01-01 00:00:00Z]` — freeze the clock for this test
  - `@tag oban: :manual` — disable inline mode; use assert_enqueued/perform_job.
    **REQUIRES `async: false`** — Oban.Testing mode is an
    `Application.put_env/3` setting (global); concurrent async tests would
    stomp each other (I-12). Tests WITHOUT the `:oban` tag never touch
    Oban.Testing and remain fully async-safe.
    **Requires `oban_jobs` table:** run `mix ecto.create` or `mix verify.phase_03`
    (which includes `ecto.drop + ecto.create`) before running `oban: :manual` tests.
  - `@tag async: false` — disable async (auto-enforced when `set_mailglass_global`
    is used OR when `@tag oban: ...` is present)

  ## Async tests and deliver_later/2

  `MailerCase` supports `async: true` (the default). For async tests that exercise
  `deliver_later/2`, pass `async_adapter: :task_supervisor` as a `deliver_later/2`
  option rather than relying on the global Application env:

      Outbound.deliver_later(msg, async_adapter: :task_supervisor)

  This is already supported at `outbound.ex` via `Keyword.get(opts, :async_adapter)`.
  Global Application env mutation is reserved for `async: false` tests only (HI-01 fix).

  ## Global mode opt-out

  `setup :set_mailglass_global` — mirrors `set_swoosh_global`. Forces
  `async: false`. `Fake.set_shared(self())`. Only use for tests that can't
  be isolated per-process (cross-process delivery without `allow/2`).

  ## Oban inline mode (D-08)

  When Oban is loaded, `deliver_later/2` enqueues a job. MailerCase sets
  Oban.Testing to `:inline` mode by default — the job executes synchronously
  before `deliver_later/2` returns, so `assert_mail_sent/0,1` works immediately
  without `perform_job/2` or `assert_enqueued/1`.

  Tests that need to assert on the Oban queue (e.g. backpressure tests) use
  `@tag oban: :manual` — but they MUST run with `async: false` (see I-12 note
  in the moduledoc).
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mailglass.TestAssertions
      alias Mailglass.{Adapters, Message, Outbound}
      alias Mailglass.Adapters.Fake

      # Expose set_mailglass_global/1 as a local function so `setup :set_mailglass_global`
      # works without a module prefix. Delegates to the MailerCase implementation.
      defdelegate set_mailglass_global(context), to: Mailglass.MailerCase
    end
  end

  setup tags do
    # I-12: Tests that set `@tag oban: :manual` must run async: false.
    # Oban.Testing mode is process-global state; concurrent async tests
    # with different :oban modes would stomp each other.
    oban_tagged? = Map.has_key?(tags, :oban)
    async? = Map.get(tags, :async, true)

    if oban_tagged? and async? do
      raise """
      Mailglass.MailerCase: tests using `@tag oban: ...` MUST run with `async: false`.
      Oban.Testing mode is a process-global setting — concurrent async tests
      would stomp each other. Set `use Mailglass.MailerCase, async: false` at the
      module level (or add `@tag async: false` to this test).
      """
    end

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not async?)

    # Probe the checked-out connection for a stale citext OID.
    # Same rationale and pattern as DataCase.setup — see that module for the
    # full explanation. MailerCase does not inherit DataCase, so the probe is
    # duplicated here.
    for _ <- 1..5 do
      try do
        Mailglass.TestRepo.query!("SELECT 'probe'::citext")
      rescue
        # disconnect_on_error_codes fires; ownership auto-reconnects
        Postgrex.Error -> :ok
      end
    end

    :ok = Mailglass.Adapters.Fake.checkout()

    tenant_id =
      case Map.get(tags, :tenant, "test-tenant") do
        :unset -> nil
        t when is_binary(t) -> t
      end

    if tenant_id, do: Mailglass.Tenancy.put_current(tenant_id)

    if frozen_at = tags[:frozen_at], do: Mailglass.Clock.Frozen.freeze(frozen_at)

    if tenant_id do
      Phoenix.PubSub.subscribe(
        Mailglass.PubSub,
        Mailglass.PubSub.Topics.events(tenant_id)
      )
    end

    # Snapshot the pre-setup :async_adapter value for faithful restore in on_exit (HI-01 fix).
    # If we unconditionally wrote :oban on restore, adopters who boot with :task_supervisor
    # would have it silently overwritten after every test. Snapshot before any mutation below.
    prior_async_adapter = Application.get_env(:mailglass, :async_adapter)

    # Async delivery mode (D-08, I-12).
    #
    # Default (no @tag oban:): use :task_supervisor so deliver_later/2 runs
    # the worker in a supervised Task that shares the test process's sandbox
    # connection. Because Fake.set_shared(self()) is applied below, the Task
    # can deliver into this test's ETS bucket — assert_mail_sent/1 works
    # synchronously after a brief Process.sleep (see wait_for_mail/1 for
    # async alternatives).
    #
    # @tag oban: :manual: start a supervised Oban instance in :manual mode.
    # deliver_later/2 enqueues a job but does NOT run it. Use assert_enqueued/1
    # + perform_job/2 for those tests. MUST be async: false (I-12).
    #
    # @tag oban: :inline: start a supervised Oban instance in :inline mode.
    # deliver_later/2 runs the worker synchronously. MUST be async: false (I-12).
    cond do
      oban_tagged? and Code.ensure_loaded?(Oban) ->
        oban_mode = Map.fetch!(tags, :oban)
        repo = Application.get_env(:mailglass, :repo, Mailglass.TestRepo)

        # Switch sandbox to shared mode so Oban's DB processes can check out
        # connections from the test process's pool. :manual mode was already
        # set by start_owner! (shared: true for async: false), but explicitly
        # setting {:shared, self()} makes this contract clear and ensures Oban
        # internal processes (which don't inherit $callers) can access the DB.
        Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

        ExUnit.Callbacks.start_supervised!(
          {Oban, testing: oban_mode, repo: repo, queues: [mailglass_outbound: 10]}
        )

        Mailglass.Adapters.Fake.set_shared(self())

      true ->
        # Default: task_supervisor path. Shared Fake so Task.Supervisor workers
        # deliver into this test's ETS bucket. Sandbox is shared for async: false
        # (start_owner! sets shared: not async? = shared: true). For async: true
        # tests, deliver_later is not expected to work across processes — use
        # Fake.allow/2 for cross-process cases.
        #
        # HI-01 fix: Only mutate global Application env for async: false tests.
        # Async tests running concurrently race on this global write. Async tests
        # that exercise deliver_later/2 must pass `async_adapter: :task_supervisor`
        # as a deliver_later/2 opt for per-call isolation (outbound.ex:331 already
        # honours Keyword.get(opts, :async_adapter)).
        unless async? do
          Application.put_env(:mailglass, :async_adapter, :task_supervisor)
        end

        Mailglass.Adapters.Fake.set_shared(self())
    end

    on_exit(fn ->
      Mailglass.Adapters.Fake.checkin()
      Mailglass.Adapters.Fake.set_shared(nil)
      Mailglass.Clock.Frozen.unfreeze()
      # HI-01 fix: restore :async_adapter to whatever it was before this test ran,
      # not unconditionally to :oban. Adopters who boot with :task_supervisor would
      # otherwise have it silently overwritten after every test's on_exit.
      if prior_async_adapter != nil do
        Application.put_env(:mailglass, :async_adapter, prior_async_adapter)
      else
        Application.delete_env(:mailglass, :async_adapter)
      end

      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    :ok
  end

  @doc """
  Sets Fake to global mode (mirrors `set_swoosh_global`). Requires
  `async: false`. The ONLY legitimate path to global mode.

  Usage: `setup :set_mailglass_global`

  Fake.set_shared(self()) enables any process (without explicit allow/2)
  to deliver into this test's ETS bucket. Use sparingly — prefer `allow/2`
  for targeted cross-process delegation (LiveView, Oban workers, Playwright).
  """
  @spec set_mailglass_global(ExUnit.Callbacks.test_context()) :: :ok
  def set_mailglass_global(context) do
    if Map.get(context, :async, true) do
      raise "Mailglass.MailerCase global mode requires async: false — " <>
              "set `use Mailglass.MailerCase, async: false` at the module level"
    end

    Mailglass.Adapters.Fake.set_shared(self())
    on_exit(fn -> Mailglass.Adapters.Fake.set_shared(nil) end)
    :ok
  end
end
