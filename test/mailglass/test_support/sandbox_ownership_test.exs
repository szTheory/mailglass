defmodule Mailglass.TestSupport.SandboxOwnershipTest do
  # async: false (D-11 reason 1: pool-mode mutation) — this file puts the
  # real Mailglass.TestRepo Sandbox pool into a genuinely leaked {:shared,
  # pid} state to prove `probe/1` observes it. A real leak/heal cycle has no
  # synthetic-payload substitute; see `suite_truth_formatter_test.exs` for the
  # injectable-probe_fun coverage of the formatter itself.
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Mailglass.TestSupport.SandboxOwnership

  setup do
    # Regardless of assertion outcome, never leave the shared pool that this
    # file intentionally creates in place for the rest of the suite.
    on_exit(fn -> Sandbox.mode(Mailglass.TestRepo, :manual) end)
  end

  test "reports :ok when the pool is already :manual" do
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  # Regression (coordinator-reported #1): an earlier `probe/1` called
  # `Sandbox.mode(repo, :manual)` directly, which unconditionally heals and
  # always replies `:ok` — so `{:leaked, term}` was unreachable for exactly
  # the leak class this phase is about. This test fails against that
  # implementation (it would see `:ok`, not `{:leaked, {:shared, ^owner}}`).
  test "observes a genuine {:shared, pid} leak — reports it, does not cure it" do
    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)

    assert {:leaked, {:shared, leaked_pid}} = SandboxOwnership.probe(Mailglass.TestRepo)
    assert leaked_pid == owner

    # Regression (coordinator-reported #2): observing must not itself heal.
    # A second shared acquisition attempt must still raise the exact
    # `{:badmatch, :already_shared}` the real bug produces — proving the
    # probe call above did not check the leaked owner in.
    assert_raise MatchError, fn ->
      Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    end

    # And the manager's mode is still exactly what it was before either probe
    # call — repeated reads are idempotent, not just the first one.
    assert {:leaked, {:shared, ^leaked_pid}} = SandboxOwnership.probe(Mailglass.TestRepo)

    Sandbox.stop_owner(owner)
  end
end
