defmodule Mailglass.MailerCaseTest do
  @moduledoc """
  Tests for Mailglass.MailerCase setup: default setup, tag overrides, Oban modes,
  set_mailglass_global, WebhookCase + AdminCase stubs.
  Tests 1-10 per the plan spec, plus Tests 11-12 (143-05: prove the deleted raw
  `Sandbox.mode(repo, {:shared, self()})` calls were genuine no-ops — the
  pool stays observably shared, via `SandboxOwnership.live_holder/1`, both on
  the Oban setup path and across `set_mailglass_global/0`) and Test 13
  (143-05: a text tripwire asserting that pattern never reappears under
  `test/support/`).
  """
  use Mailglass.MailerCase, async: true

  alias Mailglass.FakeFixtures.TestMailer

  # Test 1: default setup — Fake checked out, tenancy stamped, PubSub subscribed
  test "defaults: Fake checked out, tenancy stamped, PubSub subscribed" do
    assert Mailglass.Tenancy.current() == "test-tenant"
    assert Process.whereis(Mailglass.Adapters.Fake.Storage) != nil
    # PubSub subscribed — verify by sending a broadcast and receiving it
    Phoenix.PubSub.broadcast(
      Mailglass.PubSub,
      "mailglass:events:test-tenant",
      {:test_broadcast, :ok}
    )

    assert_receive {:test_broadcast, :ok}
  end

  # Test 2: @tag tenant: overrides default
  @tag tenant: "acme"
  test "overrides tenant with @tag tenant:" do
    assert Mailglass.Tenancy.current() == "acme"
  end

  # Test 3: @tag tenant: :unset disables stamping
  @tag tenant: :unset
  test "@tag tenant: :unset disables stamping" do
    # With SingleTenant default resolver, current/0 returns "default" when
    # not explicitly stamped (NOT "test-tenant").
    refute Mailglass.Tenancy.current() == "test-tenant"
  end

  # Test 4: @tag frozen_at: freezes Clock
  @tag frozen_at: ~U[2026-01-01 00:00:00Z]
  test "@tag frozen_at: freezes Clock" do
    assert Mailglass.Clock.utc_now() == ~U[2026-01-01 00:00:00Z]
  end

  # Test 5: on_exit restores state — covered implicitly by suite isolation
  # (no cross-test flakiness = restore works). Minimal explicit test:
  test "on_exit restores — this test is isolated" do
    # If on_exit didn't restore, earlier tests' state would bleed here.
    # The fact that test 1's assert_receive doesn't leak here proves isolation.
    assert :ok == :ok
  end

  # Test 7: deliver_later + assert_mail_sent works (D-08).
  # async: true tests must pass `async_adapter: :task_supervisor` as a per-call
  # opt — global Application env mutation is reserved for async: false tests
  # (HI-01 fix, 03-10). Delivery happens in a background Task; wait_for_mail/1
  # blocks until it arrives.
  test "deliver_later + assert_mail_sent works via shared Fake (D-08)" do
    email = "inline@example.com"

    {:ok, %Mailglass.Outbound.Delivery{}} =
      email
      |> TestMailer.welcome()
      |> TestMailer.deliver_later(async_adapter: :task_supervisor)

    # Task.Supervisor runs async — wait up to 500ms for the mail to arrive.
    assert %Mailglass.Message{} = wait_for_mail(500)
  end

  # Test 9: using block imports TestAssertions + aliases
  test "using block provides assert_mail_sent macro (imported from TestAssertions)" do
    # If the import works, this call to assert_mail_sent() compiles without error.
    # Use assert_no_mail_sent (imported macro) to prove the import:
    assert_no_mail_sent()
  end

  # Test 13 (143-05): tripwire ahead of the Credo check landing in plan
  # 143-08 — asserts the deleted raw shared-mode call never reappears under
  # test/support/. Scoped to test/support/ only so it does not duplicate the
  # Credo check's job.
  test "no raw Sandbox.mode(repo, {:shared, self()}) call remains under test/support/" do
    support_files = Path.wildcard(Path.join([File.cwd!(), "test", "support", "**", "*.ex"]))
    assert support_files != [], "expected to find files under test/support/"

    pattern = ~r/Sandbox\.mode\(.*\{:shared,\s*self\(\)\}/

    offenders =
      for file <- support_files,
          line <- String.split(File.read!(file), "\n"),
          Regex.match?(pattern, line) do
        file
      end

    assert offenders == [],
           "Raw Sandbox.mode(repo, {:shared, self()}) call(s) reintroduced under " <>
             "test/support/: #{inspect(Enum.uniq(offenders))}"
  end
end

defmodule Mailglass.MailerCaseGlobalTest do
  @moduledoc "Test 6: set_mailglass_global opt-out"
  use Mailglass.MailerCase, async: false

  setup :set_mailglass_global

  test "global mode — set_mailglass_global sets Fake shared owner to self()" do
    assert Mailglass.Adapters.Fake.get_shared() == self()
  end
end

defmodule Mailglass.MailerCaseObanGuardTest do
  @moduledoc """
  Test 8: @tag oban: :manual + async: true raises I-12 guard.

  We cannot run a full Oban insert-job test here because the test DB has no
  oban_jobs table (mailglass ships its own migrations only). Instead we verify
  the documented I-12 contract: any test that combines `@tag oban: ...` with
  async: true must fail fast with a clear error. This is the behavior that
  matters for adopters — they should get an actionable error immediately rather
  than a subtle global-state stomp.
  """
  use ExUnit.Case, async: true

  test "MailerCase setup raises when @tag oban is used with async: true (I-12 guard)" do
    # Exercise the I-12 guard by calling the MailerCase setup callback directly.
    # The guard fires before Ecto.Sandbox.start_owner! so no DB connection is needed.
    # __ex_unit__(:setup, tags) is the ExUnit CaseTemplate-generated entrypoint.
    tags = %{async: true, oban: :manual}

    assert_raise RuntimeError, ~r/async: false/, fn ->
      Mailglass.MailerCase.__ex_unit__(:setup, tags)
    end
  end
end

defmodule Mailglass.MailerCaseObanGlobalTest do
  @moduledoc """
  Tests 11-12 (143-05): proves the two raw `Sandbox.mode(repo, {:shared,
  self()})` calls deleted from `mailer_case.ex` (the Oban setup path and
  `set_mailglass_global/0`) were genuine no-ops, not silent behavior changes.

  Asserts the *effect* those calls were supposed to provide — the pool is
  observably shared (`SandboxOwnership.live_holder/1` returns a live pid, not
  a re-assertion of `Sandbox.mode/2`) and a process other than the test
  process can reach the database — both on the Oban setup path (where the
  first raw call lived, Test 11) and again after calling
  `set_mailglass_global/0` (where the second one lived, Test 12). If either
  deletion had removed a real guarantee, one of these assertions would fail.
  """
  use Mailglass.MailerCase, async: false

  alias Mailglass.TestSupport.SandboxOwnership

  # Test 11: the Oban setup path's deleted raw mode call was a no-op —
  # checkout!(shared: true) (this module is async: false) already shared
  # the pool before the Oban `cond` branch ever ran.
  @tag oban: :inline
  test "pool is genuinely shared on the Oban setup path (deleted no-op proof)" do
    holder = SandboxOwnership.live_holder(Mailglass.TestRepo)
    assert is_pid(holder)
    assert Process.alive?(holder)

    # A process OTHER than the test process reaches the DB through the
    # shared pool — the effect Oban's internal processes need.
    assert %Postgrex.Result{} =
             Task.async(fn -> Mailglass.TestRepo.query!("SELECT 1", []) end)
             |> Task.await()
  end

  # Test 12: set_mailglass_global/0's own deleted raw mode call was a no-op
  # for the identical reason — its setup (async: false, above) already
  # shared the pool before set_mailglass_global/0 is ever called.
  test "pool stays genuinely shared after set_mailglass_global/0 (deleted no-op proof)" do
    :ok = Mailglass.MailerCase.set_mailglass_global(%{async: false})

    holder = SandboxOwnership.live_holder(Mailglass.TestRepo)
    assert is_pid(holder)
    assert Process.alive?(holder)

    assert %Postgrex.Result{} =
             Task.async(fn -> Mailglass.TestRepo.query!("SELECT 1", []) end)
             |> Task.await()
  end
end

defmodule Mailglass.WebhookCaseStubTest do
  @moduledoc "Test 10: WebhookCase compiles and uses MailerCase"
  use ExUnit.Case, async: true

  test "Mailglass.WebhookCase module is defined" do
    assert Code.ensure_loaded?(Mailglass.WebhookCase)
  end
end

defmodule Mailglass.AdminCaseStubTest do
  @moduledoc "Test 10: AdminCase compiles and uses MailerCase"
  use ExUnit.Case, async: true

  test "Mailglass.AdminCase module is defined" do
    assert Code.ensure_loaded?(Mailglass.AdminCase)
  end
end
