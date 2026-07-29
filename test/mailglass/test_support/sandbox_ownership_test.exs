defmodule Mailglass.TestSupport.SandboxOwnershipTest.FakeAsyncModule do
  @moduledoc false
  # A plain module (NOT `use ExUnit.Case`) that satisfies exactly the
  # contract `SandboxOwnership`'s async guard checks —
  # `function_exported?(module, :__ex_unit__, 1)` returning
  # `%{async?: true}` — so the guard's real logic can be driven through the
  # `:calling_module_fun` injectable seam without needing an actual
  # `async: true` ExUnit.Case module (which would register empty tests with
  # the live ExUnit.Server and pollute suite counts for no reason).
  def __ex_unit__(:config), do: %{async?: true}
end

defmodule Mailglass.TestSupport.SandboxOwnershipTest.FakeSyncModule do
  @moduledoc false
  def __ex_unit__(:config), do: %{async?: false}
end

defmodule Mailglass.TestSupport.SandboxOwnershipTest do
  @moduledoc """
  Deterministic, mechanism-level regression test for HARNESS-01 / D-04.

  This file and `test/support/sandbox_ownership.ex` are the only two files
  plan `143-08`'s `Mailglass.Credo.NoRawSandboxOwnership` check allowlists —
  the mechanism this test pins cannot be proven without driving
  `Ecto.Adapters.SQL.Sandbox` directly against the real `Mailglass.TestRepo`
  pool. Do not "clean up" the direct calls below.

  `async: false` (D-11 reason 1: pool-mode mutation) — deliberately kept as
  the value the sibling file (`143-01`) already established, NOT flipped to
  `async: true`. Two independent reasons: these tests put the real, live
  `Mailglass.TestRepo` pool into a genuinely shared `{:shared, pid}` state,
  which is unsafe to run concurrently with any other `async: true` module
  sharing the same pool; and D-11/D-31 both forbid Phase 143 from changing
  any file's `async:` value at all (HARNESS-02's four-leg evidence is only
  interpretable if the async/sync split is byte-identical before and after).
  ExUnit runs `async: false` modules strictly serially and strictly after
  every `async: true` module has finished (`ExUnit.Runner.async_loop/4`), so
  this file's tests never overlap with anything else that shares the pool.

  This account does NOT claim a deterministic full-suite reproduction — see
  `143-MECHANISM.md` §7. It pins the mechanism against the real repo, once,
  reproducibly; the full-suite failure count is bounded by the healing paths
  and is not deterministic across seeds.
  """
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Mailglass.TestSupport.SandboxOwnership
  alias Mailglass.TestSupport.SandboxOwnershipTest.FakeAsyncModule

  setup do
    # This file obeys the invariant it is testing: the revert is registered
    # before any statement below that could raise, so a leaked pool never
    # survives past this file's own tests regardless of assertion outcome.
    on_exit(fn -> Sandbox.mode(Mailglass.TestRepo, :manual) end)
  end

  # ── probe/1 and baseline_tables_present?/1 (carried forward from 143-01;
  # unchanged by this plan's Task 1 per its own instruction) ──────────────

  test "reports :ok when the pool is already :manual" do
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  test "reports true for the real, migrated Mailglass.TestRepo schema" do
    assert SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo) == true
  end

  test "baseline_tables_present?/1 is callable from a process with no prior checkout, and leaves pool mode unchanged" do
    task = Task.async(fn -> SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo) end)

    assert Task.await(task) == true
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  # ── The four mechanism branches (D-04, 143-MECHANISM.md §2) ────────────

  # 1. Leak reproduces.
  test "leak reproduces: the next start_owner!(shared: true) raises the nested {:badmatch, :already_shared} term" do
    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)

    error =
      assert_raise(MatchError, fn ->
        Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
      end)

    # A top-level match on `{:badmatch, :already_shared}` would match
    # NOTHING — the badmatch happens inside the unlinked owner Agent's init
    # callback (sandbox.ex:451-458); `Agent.start/1` surfaces that crash as
    # `{:error, reason}`, and it is the OUTER `{:ok, pid} = Agent.start(...)`
    # match failure (sandbox.ex:451) that actually raises `MatchError` here,
    # with `reason` nested two levels inside its `:term`. CLAUDE.md forbids
    # matching errors by message string (#7) — this pins the structural term
    # `SandboxOwnership.LeakError`'s composed-error replacement must be
    # counted alongside (plan 143-08's classifier).
    assert %MatchError{term: {:error, {{:badmatch, :already_shared}, stacktrace}}} = error
    assert is_list(stacktrace)

    Sandbox.stop_owner(owner)
  end

  # 2. shared: false survives.
  test "shared: false survives a leaked shared owner (D-01 falsifiable prediction #3)" do
    leaked_owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert {:leaked, {:shared, ^leaked_owner}} = SandboxOwnership.probe(Mailglass.TestRepo)

    # sandbox.ex:460 takes the `allow/3` branch instead of the `mode/2`
    # branch when `shared: false` — it never touches manager.ex:153-154's
    # `Process.alive?` check, so it cannot observe (or be blocked by) the
    # leaked shared owner at all.
    async_owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: false)
    assert is_pid(async_owner)

    Sandbox.stop_owner(async_owner)
    Sandbox.stop_owner(leaked_owner)
  end

  # 3. stop_owner/1 heals.
  test "stop_owner/1 heals a leaked shared owner" do
    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)

    Sandbox.stop_owner(owner)

    # `assert_manual!/2` (not a bare `probe/1 == :ok`) — confirmed empirically
    # that `stop_owner/1` returning does NOT mean the ownership manager has
    # already unshared the pool: `GenServer.stop/1` waits for the owner
    # Agent's own termination, but `manager.ex`'s `unshare/2` fires one
    # message-passing hop later, after the manager's own monitor on the
    # checkout proxy delivers its `:DOWN`. `assert_manual!/2`'s bounded
    # settle window absorbs exactly that benign propagation delay.
    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__) == :ok
    fresh_owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert is_pid(fresh_owner)
    Sandbox.stop_owner(fresh_owner)
  end

  # 4. mode(repo, :auto) heals.
  test "mode(repo, :auto) then :manual heals a leaked shared owner" do
    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)

    # This is exactly why seed bisection converges on the wrong pair
    # (143-MECHANISM.md §1): the nine :auto-mode files HEAL a leak rather
    # than colliding with it, so the leaker and its victim are never
    # adjacent in the failure log.
    Sandbox.mode(Mailglass.TestRepo, :auto)
    Sandbox.mode(Mailglass.TestRepo, :manual)

    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__) == :ok
    fresh_owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert is_pid(fresh_owner)
    Sandbox.stop_owner(fresh_owner)
  end

  # ── The helper's own contract ───────────────────────────────────────────

  # 5. Release-first: a raise registered AFTER checkout!/1's own release
  # still runs — checkout!/1's release, registered first, still executes.
  @tag :release_first
  test "checkout!/1's release still runs even when a later-registered on_exit raises first" do
    owner = SandboxOwnership.checkout!(shared: true)
    assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)

    # Registered AFTER checkout!/1 returns, so ExUnit's on_exit LIFO
    # ordering runs THIS one first, simulating exactly the shape both
    # confirmed leak sites got wrong: work after acquisition that raises.
    # The invariant under test is that checkout!/1's own release — which was
    # registered BEFORE this callback — still runs regardless.
    ExUnit.Callbacks.on_exit(fn ->
      raise "deliberate: simulates work that raises after acquiring"
    end)

    # Force the on_exit chain to run NOW rather than waiting for the test to
    # end — `ExUnit.OnExitHandler.run/2` is the exact function
    # `ExUnit.Runner` itself calls after every test finishes. This is a
    # deliberate, version-pinned coupling to ExUnit internals, in the same
    # spirit as `SandboxOwnership.probe/1`'s `:sys.get_state/1` coupling:
    # there is no other way to observe "did the release run" synchronously,
    # from inside the single test this invariant must be provable within.
    result = ExUnit.OnExitHandler.run(self(), 5_000)

    assert {:error,
            %RuntimeError{message: "deliberate: simulates work that raises after acquiring"},
            _stack} =
             result

    # `run/2` takes (removes) this test's on_exit registrations from
    # ExUnit's internal table; re-register an empty entry so the real
    # end-of-test call the Runner makes afterward does not crash on a
    # missing entry.
    ExUnit.OnExitHandler.register(self())

    # And yet — the release DID run, despite running SECOND (LIFO) behind
    # the raising callback above. `assert_manual!/2` absorbs the same
    # benign stop_owner/1-vs-manager settle delay documented on tests 3/4.
    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__) == :ok
  end

  # 6. Async guard raises.
  test "checkout!(shared: true) raises when the calling module resolves to async: true" do
    error =
      assert_raise(
        RuntimeError,
        ~r/^Mailglass\.TestSupport\.SandboxOwnership: `checkout!\(shared: true\)` MUST NOT/,
        fn ->
          SandboxOwnership.checkout!(shared: true, calling_module_fun: fn -> FakeAsyncModule end)
        end
      )

    assert error.message =~ "Pass `shared: false` instead"
  end

  test "unsandboxed_module/1 raises when the setup context's :async is true" do
    error =
      assert_raise(
        RuntimeError,
        ~r/^Mailglass\.TestSupport\.SandboxOwnership: `setup :unsandboxed_module` MUST run/,
        fn ->
          SandboxOwnership.unsandboxed_module(%{async: true, module: __MODULE__})
        end
      )

    assert error.message =~ "async: false"
  end

  # 7. assert_manual!/2,3 raises LeakError.
  test "assert_manual!/2 returns :ok on a manual pool and raises LeakError on a shared one" do
    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__) == :ok

    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)

    error =
      assert_raise(SandboxOwnership.LeakError, fn ->
        SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__)
      end)

    assert error.caller == __MODULE__
    assert error.mode == {:shared, owner}

    Sandbox.stop_owner(owner)
  end

  test "assert_manual!/3's injectable :probe_fun raises LeakError from a synthetic result, no real leak needed" do
    assert_raise(SandboxOwnership.LeakError, fn ->
      SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__,
        probe_fun: fn _repo -> {:leaked, {:shared, self()}} end
      )
    end)

    # The real pool was never touched — still :manual.
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  # 8. live_holder/0.
  test "live_holder/0 returns the owner pid while shared and nil after a heal" do
    assert SandboxOwnership.live_holder(Mailglass.TestRepo) == nil

    owner = Sandbox.start_owner!(Mailglass.TestRepo, shared: true)
    assert SandboxOwnership.live_holder(Mailglass.TestRepo) == owner

    Sandbox.stop_owner(owner)
    # Settle the same benign stop_owner/1-vs-manager propagation delay
    # documented on tests 3/4 before reading live_holder/0 post-heal.
    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__) == :ok
    assert SandboxOwnership.live_holder(Mailglass.TestRepo) == nil
  end
end
