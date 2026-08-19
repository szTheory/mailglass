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

  # `Ecto.Query.from/2` is a macro — required (not imported) so the one call
  # site below stays visibly qualified and no bare `from/2` enters this file's
  # namespace alongside its many non-query helpers.
  require Ecto.Query

  # A synthetic ExUnit context is all the async guards read, so the guard's
  # real logic is driven with a plain map. No fake `__ex_unit__/1` module is
  # needed (and none exists any more): the guard no longer resolves a module
  # and interrogates it — it reads `:async` out of the context it is handed.
  @async_context %{async: true, module: Mailglass.SomePretendAsyncTest}
  @sync_context %{async: false, module: Mailglass.SomePretendSyncTest}

  # D-31 Class D fixture. A faithful copy of the shape the two `unsubscribe`
  # test modules install — the ONLY thing that matters is that `scope/2` binds
  # `as: :scoped`, because `Mailglass.Operator.SupportSummary` already binds
  # `as: :orphan` on the same query. Kept here, in the mechanism test, so the
  # end-to-end reproduction below does not depend on either of those modules
  # continuing to define such a resolver.
  defmodule ScopedAliasTenancy do
    @behaviour Mailglass.Tenancy

    import Ecto.Query

    @impl true
    def scope(queryable, _context), do: from(row in queryable, as: :scoped)
  end

  setup_all context do
    # `ExUnit.Runner` merges `%{module: module, async: async?}` into the
    # setup_all context too — runner.ex:301 on Elixir v1.18.4, runner.ex:317
    # on v1.19.5, the same expression in both. This is the one place the
    # process-label mechanism could NEVER have reached on ANY version
    # (`Process.set_label/1` is called only for the per-test process, and only
    # from 1.19.0), so capturing it here is a direct pin on the new
    # mechanism's strictly-wider coverage. Asserted in a test below.
    %{setup_all_context: Map.take(context, [:async, :module])}
  end

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
    # (143-MECHANISM.md §1): the :auto-mode files HEAL a leak rather than
    # colliding with it, so the leaker and its victim are never adjacent in
    # the failure log. (MECHANISM counted nine of them; there are eight now —
    # idempotency_convergence_test.exs moved to a shared, non-transactional
    # checkout!/1. The healing property is a property of the mode, not of the
    # count, so this test is unaffected.)
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
  test "checkout!/1's release still runs even when a later-registered on_exit raises first",
       context do
    owner = SandboxOwnership.checkout!(shared: true, context: context)
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

  # 6. Async guard raises — the real violation, read straight off the context.
  test "checkout!(shared: true) raises when the context's :async is true" do
    error =
      assert_raise(
        RuntimeError,
        ~r/^Mailglass\.TestSupport\.SandboxOwnership: `checkout!\(shared: true\)` MUST NOT/,
        fn -> SandboxOwnership.checkout!(shared: true, context: @async_context) end
      )

    assert error.message =~ "Pass `shared: false` instead"
    # Names the module at fault, taken from the context's own `:module` key.
    assert error.message =~ "Mailglass.SomePretendAsyncTest"

    # The guard fires before `start_owner!/2`, so the real pool is untouched.
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  # 6b. FAIL-CLOSED, but only against a MISUSE — never against a healthy caller.
  #
  # The subject is now supplied by construction: every `shared: true` call site
  # passes the ExUnit context, and ExUnit puts `:async` in every setup /
  # setup_all context on every supported Elixir. So this branch is reachable
  # only by omitting `context:` entirely, or by passing something that is not
  # an ExUnit context. It is NOT reachable by "the runtime declined to
  # volunteer the caller", which is precisely the shape that took every gating
  # CI lane down on 1.18.4 (see the module's "Async guards" docs).
  test "checkout!(shared: true) raises when no context is supplied at all" do
    for opts <- [
          [shared: true],
          [shared: true, context: nil],
          [shared: true, context: :not_a_map],
          [shared: true, context: %{}]
        ] do
      error = assert_raise(RuntimeError, fn -> SandboxOwnership.checkout!(opts) end)

      assert error.message =~ "without an ExUnit context carrying a boolean `:async`"
      assert error.message =~ "context: tags"
    end

    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  test "checkout!(shared: true) raises when :async is present but not a boolean" do
    # An unanswerable question must not be silently answered "no".
    assert_raise(RuntimeError, ~r/without an ExUnit context carrying a boolean `:async`/, fn ->
      SandboxOwnership.checkout!(shared: true, context: %{async: :maybe, module: __MODULE__})
    end)

    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  test "checkout!(shared: true) is permitted when the context's :async is false" do
    # The positive control for the fail-closed tests above: a context that DOES
    # answer the question with `false` still gets through. Without this, a
    # guard that raised unconditionally would pass every test above — which is
    # exactly what the 1.19-only process-label mechanism did on CI.
    owner = SandboxOwnership.checkout!(shared: true, context: @sync_context)

    assert is_pid(owner)
    assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)
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

  test "unsandboxed_module/1 raises when the context carries no boolean :async" do
    # Previously `Map.get(context, :async, false)` — an absent key was silently
    # answered "not async", indistinguishable from a genuine `async: false`.
    # The pool would have gone to :auto on the word of a guard that never ran.
    for absent <- [%{}, %{module: __MODULE__}, %{async: nil}, %{async: :maybe}] do
      assert_raise(RuntimeError, ~r/no boolean `:async` key/, fn ->
        SandboxOwnership.unsandboxed_module(absent)
      end)
    end

    # Positive control: a real `async: false` context still switches the pool.
    # (Reverted immediately — this file's own module-level `on_exit`, plus the
    # revert `unsandboxed_module/1` itself registers, restore :manual.)
    assert SandboxOwnership.unsandboxed_module(%{async: false, module: __MODULE__}) == :ok
  end

  # ── Caller resolution is version-independent (the 1.18.4 CI regression) ──
  #
  # Commits 8a11392/355e7eb resolved the guard's subject from
  # `Process.get(:"$process_label")`. `ExUnit.Runner` only sets that label from
  # **Elixir 1.19.0** (CHANGELOG "#### ExUnit — Set a process label for each
  # test"; runner.ex:443 on v1.19.0; ZERO `set_label` occurrences anywhere in
  # v1.18.4's runner.ex). Every gating CI lane runs 1.18.4/OTP 27, so the
  # subject resolved to `nil` on 100% of gating runs and the fail-closed branch
  # fired on every healthy shared checkout — dozens of unrelated modules.
  #
  # These two tests are the regression guard. They fail if caller resolution
  # ever silently degrades to `nil` again, and they do it on BOTH toolchains:
  # the first erases the process label so the test runs in the exact 1.18.4
  # shape even on 1.19.x, and the second pins the ExUnit contract the new
  # mechanism actually depends on.

  test "the async guard classifies correctly with NO process label present at all" do
    prior = Process.get(:"$process_label")
    Process.delete(:"$process_label")

    try do
      # This process is now indistinguishable from a 1.18.4 test process.
      assert Process.get(:"$process_label") == nil

      # A real violation is still caught...
      assert_raise(RuntimeError, ~r/MUST NOT/, fn ->
        SandboxOwnership.checkout!(shared: true, context: @async_context)
      end)

      # ...and a healthy caller is still let through. THIS is the assertion
      # that fails on the pre-fix code: with no label to read, the old guard
      # classified `:unknown` and raised on a caller that had done nothing
      # wrong. Nothing here consults the process dictionary any more.
      owner = SandboxOwnership.checkout!(shared: true, context: @sync_context)
      assert is_pid(owner)
      assert {:leaked, {:shared, ^owner}} = SandboxOwnership.probe(Mailglass.TestRepo)
    after
      if prior, do: Process.put(:"$process_label", prior)
    end
  end

  test "ExUnit supplies the guard's subject in every context, on every supported Elixir",
       context do
    # The per-test context (runner.ex:279 on v1.18.4, :292-293 on v1.19.5).
    assert is_boolean(context.async)
    assert is_atom(context.module)
    assert context.async == false
    assert context.module == __MODULE__

    # The setup_all context (runner.ex:301 on v1.18.4, :317 on v1.19.5) — the
    # one the process label never covered on ANY version.
    assert context.setup_all_context == %{async: false, module: __MODULE__}
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

  # 7b. mode_manual!/2 is succeed-or-raise, not succeed-or-hand-back.
  #
  # `Sandbox.mode/2` is spec'd `:ok | :already_shared | :not_owner |
  # :not_found`, and all three of this repo's call sites discard the return
  # value. Before this pair of tests existed, a refusal was silently dropped:
  # the suite could boot against a pool whose mode was never established and
  # report nothing. Both refusal branches are unreachable on today's
  # dependency versions (Ecto documents :manual as always successful;
  # db_connection's manager replies :ok on both :manual clauses), which is
  # exactly why the guard needs a synthetic driver to be provable at all —
  # and exactly why an unproven guard here would be indistinguishable from
  # no guard.
  test "mode_manual!/2 returns :ok against the real pool and leaves it :manual" do
    assert SandboxOwnership.mode_manual!(Mailglass.TestRepo) == :ok
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  test "mode_manual!/2 raises LeakError when the ownership manager refuses the write" do
    for refusal <- [:already_shared, :not_owner, :not_found] do
      error =
        assert_raise(SandboxOwnership.LeakError, fn ->
          SandboxOwnership.mode_manual!(Mailglass.TestRepo,
            caller: __MODULE__,
            mode_fun: fn _repo, :manual -> refusal end
          )
        end)

      assert error.caller == __MODULE__
      assert error.refused_with == refusal

      # The message must name the refusal and must NOT render it in the
      # "the pool is still <mode>" sentence — a refusal code is not a pool
      # mode, and reporting it as one would state a fact nobody observed.
      message = Exception.message(error)
      assert message =~ "refused with #{inspect(refusal)}"
      refute message =~ "the pool is still"
    end

    # The real pool was never touched — still :manual.
    assert SandboxOwnership.probe(Mailglass.TestRepo) == :ok
  end

  test "mode_manual!/2's refusal raises the SAME LeakError the D-17 tally counts" do
    # Load-bearing for ROADMAP criterion 3. If the refusal raised a bespoke
    # exception instead, `SuiteTruthFormatter.signature/1` would classify it
    # `:other`, the `:already_shared` tally would stay at zero, and the leak
    # would be reported under a name nothing is watching.
    error =
      assert_raise(SandboxOwnership.LeakError, fn ->
        SandboxOwnership.mode_manual!(Mailglass.TestRepo,
          caller: __MODULE__,
          mode_fun: fn _repo, :manual -> :already_shared end
        )
      end)

    assert Mailglass.TestSupport.SuiteTruthFormatter.signature({:error, error, []}) ==
             :already_shared
  end

  test "restart_repo_after_global_type_change!/2 runs stop, start, and auto mode in order" do
    test_pid = self()

    assert :ok =
             SandboxOwnership.restart_repo_after_global_type_change!(:fake_repo,
               caller: __MODULE__,
               stop_fun: fn repo ->
                 send(test_pid, {:restart_step, :stop, repo})
                 :ok
               end,
               start_fun: fn repo ->
                 send(test_pid, {:restart_step, :start, repo})
                 {:ok, self()}
               end,
               unlink_fun: fn pid ->
                 send(test_pid, {:restart_step, :unlink, pid})
                 true
               end,
               mode_fun: fn repo, mode ->
                 send(test_pid, {:restart_step, :mode, repo, mode})
                 :ok
               end
             )

    assert_receive {:restart_step, :stop, :fake_repo}
    assert_receive {:restart_step, :start, :fake_repo}
    assert_receive {:restart_step, :unlink, _pid}
    assert_receive {:restart_step, :mode, :fake_repo, :auto}
  end

  test "restart_repo_after_global_type_change!/2 fails closed at each operation" do
    assert_raise RuntimeError, ~r/could not stop.*:busy/, fn ->
      SandboxOwnership.restart_repo_after_global_type_change!(:fake_repo,
        caller: __MODULE__,
        stop_fun: fn _repo -> :busy end
      )
    end

    assert_raise RuntimeError, ~r/could not start.*:boom/, fn ->
      SandboxOwnership.restart_repo_after_global_type_change!(:fake_repo,
        caller: __MODULE__,
        stop_fun: fn _repo -> :ok end,
        start_fun: fn _repo -> {:error, :boom} end
      )
    end

    assert_raise RuntimeError, ~r/could not restore_auto_mode.*:not_owner/, fn ->
      SandboxOwnership.restart_repo_after_global_type_change!(:fake_repo,
        caller: __MODULE__,
        stop_fun: fn _repo -> :ok end,
        start_fun: fn _repo -> {:ok, self()} end,
        unlink_fun: fn _pid -> true end,
        mode_fun: fn _repo, :auto -> :not_owner end
      )
    end

    assert_raise RuntimeError, ~r/could not unlink.*false/, fn ->
      SandboxOwnership.restart_repo_after_global_type_change!(:fake_repo,
        caller: __MODULE__,
        stop_fun: fn _repo -> :ok end,
        start_fun: fn _repo -> {:ok, self()} end,
        unlink_fun: fn _pid -> false end
      )
    end
  end

  # 7c. Exhausted-bound classification (CI run 30555218236, job 90913824954,
  # seed 79310 -- the single failure on that advisory leg).
  #
  # `checkout!/1`'s on_exit calls `stop_owner/1` (a synchronous
  # `GenServer.stop/1`) and then `assert_manual!/3`, so its own owner is
  # guaranteed DEAD by the time the assertion runs. Whether the ownership
  # manager had also processed the proxy's :DOWN within the ~150ms bound was
  # decided by CI runner load, not by whether anything leaked -- so the same
  # code raised on a loaded 2-core runner and passed locally. These tests pin
  # the discriminator that replaced the coin flip.
  test "assert_manual!/3 raises when the bound is exhausted and the shared holder is ALIVE" do
    # The HARNESS-01 class: manager.ex:153-154 replies :already_shared to the
    # next start_owner!(shared: true), which badmatches at sandbox.ex:458.
    # This MUST still raise -- it is the whole point of the guard.
    live = spawn(fn -> Process.sleep(:infinity) end)
    on_exit(fn -> Process.exit(live, :kill) end)

    error =
      assert_raise(SandboxOwnership.LeakError, fn ->
        SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__,
          probe_fun: fn _repo -> {:leaked, {:shared, live}} end,
          attempts: 2,
          interval_ms: 1
        )
      end)

    assert error.mode == {:shared, live}
  end

  test "assert_manual!/3 passes when the bound is exhausted and the shared holder is DEAD" do
    # Provably NOT the collision class: manager.ex:156-157 (`share_and_reply/3`)
    # transparently replaces a dead shared owner, so the next shared
    # acquisition succeeds. The manager has merely not processed the proxy's
    # :DOWN yet, and manager.ex:241-243 runs owner_down/2 and unshare/2
    # together -- the state is transient and self-clearing by construction.
    dead = spawn(fn -> :ok end)
    ref = Process.monitor(dead)
    assert_receive {:DOWN, ^ref, :process, ^dead, _}
    refute Process.alive?(dead)

    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__,
             probe_fun: fn _repo -> {:leaked, {:shared, dead}} end,
             attempts: 2,
             interval_ms: 1
           ) == :ok
  end

  test "assert_manual!/3 still raises for every non-shared unhealed mode" do
    # The dead-holder carve-out is scoped to {:shared, pid} ONLY. `:auto` and
    # `:cannot_verify` have no liveness to appeal to, so non-observation still
    # routes to a visible failure rather than to green.
    for mode <- [:auto, :cannot_verify] do
      assert_raise(SandboxOwnership.LeakError, fn ->
        SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__,
          probe_fun: fn _repo -> {:leaked, mode} end,
          attempts: 2,
          interval_ms: 1
        )
      end)
    end
  end

  test "assert_manual!/3 spends its full bound before accepting the dead-holder proof" do
    # A clean `:manual` reading is preferred; the liveness proof is only ever
    # the fallback. Without this, a future edit could take the carve-out on the
    # first probe and stop giving the manager any chance to settle.
    dead = spawn(fn -> :ok end)
    ref = Process.monitor(dead)
    assert_receive {:DOWN, ^ref, :process, ^dead, _}

    {:ok, counter} = Agent.start_link(fn -> 0 end)
    on_exit(fn -> if Process.alive?(counter), do: Agent.stop(counter) end)

    assert SandboxOwnership.assert_manual!(Mailglass.TestRepo, __MODULE__,
             probe_fun: fn _repo ->
               Agent.update(counter, &(&1 + 1))
               {:leaked, {:shared, dead}}
             end,
             attempts: 5,
             interval_ms: 1
           ) == :ok

    assert Agent.get(counter, & &1) == 5,
           "assert_manual!/3 must exhaust all 5 attempts before accepting the dead-holder " <>
             "proof — a carve-out taken on the first probe would stop absorbing the benign " <>
             "propagation delay it exists to absorb."
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

  # ── with_schema!/2 (143-07, D-31 Class B) ───────────────────────────────

  # 9. Restore-first: a raise registered AFTER with_schema!/2's own restore
  # still runs — with_schema!/2's restore, registered first, still executes.
  # The exact shape both confirmed Class B candidates got wrong: override,
  # then work that can raise, then a trailing restore that gets skipped.
  test "with_schema!/2 restores the captured schema even when work after it raises" do
    # The boot schema is axis-dependent ("public" on the default suite,
    # "mailglass" under the CI schema-isolation axis) — capture it live
    # rather than hardcoding either value, so this test passes on both.
    original = Mailglass.Config.schema()

    assert_raise RuntimeError,
                 "deliberate: simulates work that raises after the override",
                 fn ->
                   SandboxOwnership.with_schema!("with_schema_bang_raise_test_schema")
                   raise "deliberate: simulates work that raises after the override"
                 end

    # `with_schema!/2` already took effect before the raise above — confirm
    # the override was genuinely applied, not skipped.
    # (Read via the same seam `with_schema!/2` itself uses.)
    assert Mailglass.Config.schema() == "with_schema_bang_raise_test_schema"

    # Force the on_exit chain to run NOW, same technique test 5 (above) uses
    # to observe checkout!/1's release synchronously from inside one test.
    result = ExUnit.OnExitHandler.run(self(), 5_000)
    ExUnit.OnExitHandler.register(self())

    assert result == :ok

    # And yet — the restore DID run, despite the raise happening AFTER
    # with_schema!/2 returned. The restore was registered BEFORE the raise
    # ever ran, so it survives regardless.
    assert Mailglass.Config.schema() == original
  end

  # ────────────────────────────────────────────────────────────────
  # D-31 Class D — with_app_env!/2, the Application-env restore seam
  #
  # `@leaked_key` is deliberately a name no `config/*.exs` declares and no
  # library code reads, so these tests can add and remove it without any
  # effect on the rest of the suite. That absence at boot is also the exact
  # precondition the defect needs — see the non-vacuity test below.
  # ────────────────────────────────────────────────────────────────

  @leaked_key :with_app_env_bang_test_key

  # NON-VACUITY, by mutation, in one test: the banned idiom is reinstated
  # verbatim and shown to LEAK, then the seam is shown to remove the same key
  # under the same conditions. If `with_app_env!/2` ever silently degrades into
  # a merge, the second half fails while the first half keeps passing — so this
  # test cannot pass for the wrong reason.
  test "put_all_env/1 CANNOT remove an added key; with_app_env!/2 can (the D-31 Class D mutation)" do
    refute Keyword.has_key?(Application.get_all_env(:mailglass), @leaked_key),
           "precondition: #{inspect(@leaked_key)} must be absent at boot for this mechanism to exist"

    # ── Half 1: the idiom this seam replaces, spelled out exactly as the seven
    # migrated modules spelled it. This is the bug, reproduced.
    captured = Application.get_all_env(:mailglass)
    Application.put_env(:mailglass, @leaked_key, LeakedByPutAllEnv)
    Application.put_all_env(mailglass: captured)

    assert Application.get_env(:mailglass, @leaked_key) == LeakedByPutAllEnv,
           "put_all_env/1 is documented to MERGE; if this assertion ever fails, Elixir's " <>
             "semantics changed and the seam's rationale must be re-read, not deleted"

    Application.delete_env(:mailglass, @leaked_key)

    # ── Half 2: the same sequence through the seam.
    SandboxOwnership.with_app_env!(:mailglass)
    Application.put_env(:mailglass, @leaked_key, LeakedByPutAllEnv)

    assert Application.get_env(:mailglass, @leaked_key) == LeakedByPutAllEnv

    # Force this test's on_exit chain to run NOW, the same technique the
    # `checkout!/1` and `with_schema!/2` tests above use to observe a
    # registered restore synchronously from inside the test that registered it.
    assert ExUnit.OnExitHandler.run(self(), 5_000) == :ok
    ExUnit.OnExitHandler.register(self())

    refute Keyword.has_key?(Application.get_all_env(:mailglass), @leaked_key),
           "with_app_env!/2 must DELETE a key that was absent at capture, not merely overwrite it"
  end

  test "with_app_env!/2 restores a key the test DELETED, closing the compositional trap" do
    # This is the half that makes the defect a composition rather than a local
    # slip. `unsubscribe_property_test.exs` deleted `:tenancy` in its own
    # `on_exit` as local hardening; that left a HOLE, and any module whose
    # snapshot was taken afterwards then had no `:tenancy` key to write back —
    # so its own merging restore could no longer remove the resolver it
    # installed. Restoring exactly means no sibling ever inherits the hole.
    # Driven on `@leaked_key` rather than on the real `:tenancy`, deliberately.
    # An earlier draft asserted `Application.get_env(:mailglass, :tenancy) !=
    # nil` as its precondition, on the reasoning that `config/test.exs:19` pins
    # it — and that assertion FAILED in the full suite, because some other
    # module leaves `:tenancy` holding `nil` before this file runs (recorded as
    # an open residual finding). A mechanism test whose result depends on which
    # modules ran before it is not a mechanism test. This version establishes
    # its own precondition and is order-independent.
    SandboxOwnership.with_app_env!(:mailglass)

    Application.put_env(:mailglass, @leaked_key, :present_before_capture)
    captured = Application.get_all_env(:mailglass)

    Application.delete_env(:mailglass, @leaked_key)
    refute Keyword.has_key?(Application.get_all_env(:mailglass), @leaked_key)

    SandboxOwnership.restore_app_env!(:mailglass, captured)

    assert Application.get_env(:mailglass, @leaked_key) == :present_before_capture

    # And the outer `with_app_env!/2` still removes it, since it was absent at
    # THAT capture — the two restores compose without either one clobbering
    # the other's subject.
    assert ExUnit.OnExitHandler.run(self(), 5_000) == :ok
    ExUnit.OnExitHandler.register(self())

    refute Keyword.has_key?(Application.get_all_env(:mailglass), @leaked_key)
  end

  test "with_app_env!/2's restore runs even when work after it raises" do
    SandboxOwnership.with_app_env!(:mailglass)

    assert_raise RuntimeError, "deliberate: simulates work that raises after the capture", fn ->
      Application.put_env(:mailglass, @leaked_key, LeakedByRaise)
      raise "deliberate: simulates work that raises after the capture"
    end

    assert Application.get_env(:mailglass, @leaked_key) == LeakedByRaise

    assert ExUnit.OnExitHandler.run(self(), 5_000) == :ok
    ExUnit.OnExitHandler.register(self())

    refute Keyword.has_key?(Application.get_all_env(:mailglass), @leaked_key)
  end

  # The verification half. A restore that cannot confirm it landed must not
  # report success. Driven through the injectable `:read_fun` seam rather than
  # by staging a real concurrent write — see that option's @doc for why the
  # raise is otherwise unreachable, and why passing a one-key "unsatisfiable"
  # capture does NOT reach it (that path succeeds, and nukes the env).
  test "restore_app_env!/3 raises, naming the drifted keys, when the restore cannot be confirmed" do
    live = Application.get_all_env(:mailglass)

    error =
      assert_raise RuntimeError, ~r/did not land/, fn ->
        SandboxOwnership.restore_app_env!(:mailglass, live,
          read_fun: fn _app -> [{@leaked_key, :written_by_a_concurrent_process}] end
        )
      end

    # Named in both directions, and by KEY only — values must never reach this
    # message (T-143-01); it is printed into CI logs and `:compliance`'s test
    # fixtures are secret-shaped.
    assert Exception.message(error) =~ inspect(@leaked_key)
    refute Exception.message(error) =~ "written_by_a_concurrent_process"

    # The real env was never touched: the seam replaces only the verification
    # READ, so a failing verification here cannot corrupt the suite.
    assert Enum.sort(Application.get_all_env(:mailglass)) == Enum.sort(live)
  end

  # END-TO-END: the failure CI actually reported, reproduced at the exact line
  # that raises it. `Tenancy.scope/2` resolves its implementation through
  # `Application.get_env(:mailglass, :tenancy)` — global state — and
  # `Mailglass.Operator.SupportSummary` binds `as: :orphan` on the query it
  # then hands to `Tenancy.scope/2`. A leaked resolver that binds `as: :scoped`
  # therefore raises `Ecto.Query.CompileError` for every LATER module in the
  # run, not for the module that leaked.
  #
  # Driven through `Tenancy.scope/2` on a query with the same `as: :orphan`
  # binding rather than through `SupportSummary.summarize_tenant/1`: the alias
  # conflict is raised while BUILDING the query, before any database access, so
  # this reproduces the real mechanism without needing a Sandbox checkout this
  # module deliberately does not take. The companion test below pins the
  # `as: :orphan` binding in the real module, so this fixture cannot drift away
  # from the code it stands in for.
  test "a leaked :scoped tenancy resolver raises the CI CompileError; with_app_env!/2 prevents it" do
    boot_tenancy = Application.get_env(:mailglass, :tenancy)
    orphan_query = Ecto.Query.from(event in Mailglass.Events.Event, as: :orphan)

    SandboxOwnership.with_app_env!(:mailglass)

    # Direction 1 — the defect is real, and this is its verbatim shape.
    Application.put_env(:mailglass, :tenancy, ScopedAliasTenancy)

    error =
      assert_raise Ecto.Query.CompileError, fn ->
        Mailglass.Tenancy.scope(orphan_query, "leak-probe-tenant")
      end

    # The STRUCT is the match that matters (CLAUDE.md) and `assert_raise` above
    # already made it. These two message assertions only distinguish WHICH
    # alias collision fired — `Ecto.Query.CompileError` carries no structured
    # field naming the two bindings, so there is no struct-level way to tell
    # this collision from any other. Backticks included deliberately: Ecto's
    # real message is "can't apply alias `:scoped`, binding in `from` is
    # already aliased to `:orphan`". The CI quote recorded in
    # `143-12-SUMMARY.md` and `deferred-items.md` drops them; asserting the
    # unbackticked form silently never matches.
    assert Exception.message(error) =~ "alias `:scoped`"
    assert Exception.message(error) =~ "already aliased to `:orphan`"

    # Direction 2 — the seam removes it. Same call, no raise.
    assert ExUnit.OnExitHandler.run(self(), 5_000) == :ok
    ExUnit.OnExitHandler.register(self())

    assert Application.get_env(:mailglass, :tenancy) == boot_tenancy
    assert %Ecto.Query{} = Mailglass.Tenancy.scope(orphan_query, "leak-probe-tenant")
  end

  # Pins the fixture above to the real code. If `SupportSummary` ever stops
  # binding `as: :orphan`, the reproduction above becomes a story about a
  # binding nothing uses — still a true statement about `Tenancy.scope/2`, but
  # no longer the CI failure it claims to reproduce. Same source-reading
  # contract idiom `schema_isolation_integration_test.exs` already uses.
  test "SupportSummary still binds as: :orphan — the other half of the CI collision" do
    source = File.read!("lib/mailglass/operator/support_summary.ex")

    assert source =~ "as: :orphan",
           "the leaked-resolver reproduction above is keyed on SupportSummary binding " <>
             "`as: :orphan` on the query it passes to Tenancy.scope/2"
  end

  # 10. The composed "did not take effect" raise, driven through the
  # injectable :schema_fun seam rather than a real Application-env race.
  #
  # `:schema_fun` also stands in for `with_schema!/2`'s OWN capture read (the
  # same seam serves both), so this test's cleanup restores the real
  # Application env directly rather than relying on `with_schema!/2`'s own
  # on_exit — that on_exit captured the synthetic mismatched value below, not
  # the true boot schema, by construction of this test.
  test "with_schema!/2 raises a composed message when the override does not take effect" do
    original = Mailglass.Config.schema()

    on_exit(fn ->
      Application.put_env(:mailglass, :schema, original)
      :persistent_term.erase({Mailglass.Config, :schema})
    end)

    error =
      assert_raise(
        RuntimeError,
        ~r/^Mailglass\.TestSupport\.SandboxOwnership: with_schema!\("mismatch-target"\) did not/,
        fn ->
          SandboxOwnership.with_schema!("mismatch-target",
            schema_fun: fn -> "wrong-value-a-real-race-would-never-guarantee" end
          )
        end
      )

    assert error.message =~ "Config.schema/0 still returns"
    assert error.message =~ "wrong-value-a-real-race-would-never-guarantee"
  end

  # ── baseline_tables_present?/1's missing-relation paths, driven through
  # the with_schema!/2 seam rather than by actually dropping real tables
  # (143-07, D-31 Class A) ─────────────────────────────────────────────────

  # 11. `{false, missing}` — pointed at a schema that genuinely has none of
  # the three baseline relations, without touching the real migrated schema
  # at all. This is the exact mechanism migration_test.exs's,
  # upgrade_v2_schema_migration_test.exs's, and
  # schema_prefix_hardening_test.exs's own restore-verification on_exit
  # blocks depend on.
  test "baseline_tables_present?/1 reports {false, missing} for a schema with none of the four baseline relations" do
    SandboxOwnership.with_schema!("with_schema_bang_baseline_missing_test_schema")

    assert {false, missing} = SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo)

    assert Enum.sort(missing) ==
             Enum.sort(
               ~w(mailglass_deliveries mailglass_events mailglass_suppressions mailglass_webhook_events)
             )
  end

  # 12. THE INSTRUMENT GAP, pinned. `@baseline_relations` omitted
  # `mailglass_events` — the append-only ledger, and the very first relation the
  # CI logs named as missing. Every `baseline_tables_present?/1` call site
  # therefore reported a restore it had not verified: a schema holding the other
  # three relations but NOT the ledger read back as `true`.
  #
  # This test builds exactly that schema and asserts the probe now SEES the gap.
  # Deleting `mailglass_events` from `@baseline_relations` makes this test fail
  # (it is the mutation check for that fix, expressed as a permanent test rather
  # than a one-off experiment).
  test "baseline_tables_present?/1 names mailglass_events when it is the ONLY absent relation" do
    schema = "baseline_relations_ledger_gap_test_schema"

    on_exit(fn ->
      SandboxOwnership.unsandboxed(fn ->
        Ecto.Adapters.SQL.query!(Mailglass.TestRepo, ~s(DROP SCHEMA IF EXISTS "#{schema}" CASCADE))
      end)
    end)

    SandboxOwnership.unsandboxed(fn ->
      Ecto.Adapters.SQL.query!(Mailglass.TestRepo, ~s(CREATE SCHEMA IF NOT EXISTS "#{schema}"))

      # Every baseline relation EXCEPT mailglass_events. A probe blind to the
      # ledger reports `true` here; a complete one reports the ledger missing.
      for table <- ~w(mailglass_deliveries mailglass_suppressions mailglass_webhook_events) do
        Ecto.Adapters.SQL.query!(
          Mailglass.TestRepo,
          ~s|CREATE TABLE IF NOT EXISTS "#{schema}"."#{table}" (id uuid PRIMARY KEY)|
        )
      end
    end)

    SandboxOwnership.with_schema!(schema)

    assert SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo) ==
             {false, ["mailglass_events"]}
  end

  # ── scratch_schema!/2 (143 gap closure, D-31 Class A) ────────────────────

  # 13. The live schema is refused, and the raise NAMES the module at fault and
  # the schema it was about to destroy — the whole point of the guard is that the
  # failure lands here rather than as a 42P01 in an innocent module later.
  test "scratch_schema!/2 raises when the requested prefix IS the live schema" do
    error =
      assert_raise(SandboxOwnership.ScratchSchemaError, fn ->
        SandboxOwnership.scratch_schema!("mailglass",
          caller: Mailglass.SomePretendSchemaIsolationTest,
          schema_fun: fn -> "mailglass" end
        )
      end)

    assert error.caller == Mailglass.SomePretendSchemaIsolationTest
    assert error.requested == "mailglass"
    assert error.live_schema == "mailglass"
    assert error.reason == :live_schema

    message = Exception.message(error)
    assert message =~ "Mailglass.SomePretendSchemaIsolationTest"
    assert message =~ "LIVE schema"
    assert message =~ "mailglass_shipped_path_test"
  end

  # 14. "public" is refused even on an axis where it is NOT the live schema —
  # it holds the citext extension the whole suite depends on.
  test "scratch_schema!/2 raises for \"public\" even when the live schema is something else" do
    error =
      assert_raise(SandboxOwnership.ScratchSchemaError, fn ->
        SandboxOwnership.scratch_schema!("public",
          caller: Mailglass.SomePretendSchemaIsolationTest,
          schema_fun: fn -> "mailglass" end
        )
      end)

    assert error.reason == :public
    assert Exception.message(error) =~ "shared ambient schema"
  end

  # 15. The pass-through path: a genuinely scratch name is returned unchanged so
  # it can be used pipe-first / bound in `setup`.
  test "scratch_schema!/2 returns a genuinely scratch name unchanged" do
    assert SandboxOwnership.scratch_schema!("mailglass_some_scratch_test",
             caller: __MODULE__,
             schema_fun: fn -> "mailglass" end
           ) == "mailglass_some_scratch_test"
  end

  # 16. NON-VACUITY for the five migrated modules: every one of the five
  # scratch-schema modules must declare a prefix this guard actually accepts on
  # BOTH axes. Reading the literals out of the sources means a future edit that
  # re-types "mailglass" (or "public") into any of them fails HERE, at a named
  # assertion, rather than only on the axis where it happens to be destructive.
  test "all five scratch-schema modules declare a prefix that is scratch on both axes" do
    sources = [
      "test/mailglass/schema_prefix_hardening_test.exs",
      "test/mailglass/schema_isolation_immutability_test.exs",
      "test/mailglass/schema_isolation_integration_test.exs",
      "test/mailglass/upgrade_v2_schema_migration_test.exs",
      "test/mailglass/migration_test.exs"
    ]

    for source <- sources do
      declared =
        source
        |> File.read!()
        |> then(&Regex.scan(~r/@(?:prefix|scratch_schema)\s+"([^"]+)"/, &1))
        |> Enum.map(fn [_, name] -> name end)
        |> Enum.uniq()

      assert declared != [],
             "#{source} declares no @prefix/@scratch_schema — the regex above must be " <>
               "updated if the declaration shape changed"

      for name <- declared do
        # Both axes, driven through the real guard rather than re-implemented.
        for live <- ~w(public mailglass) do
          assert SandboxOwnership.scratch_schema!(name,
                   caller: source,
                   schema_fun: fn -> live end
                 ) == name
        end
      end
    end
  end

  # ── assert_baseline_intact!/3 (143 gap closure, D-31 Class A) ────────────

  # 17. The real, migrated schema passes.
  test "assert_baseline_intact!/3 returns :ok against the real migrated schema" do
    assert SandboxOwnership.assert_baseline_intact!(Mailglass.TestRepo, __MODULE__) == :ok
  end

  # 18. A missing relation raises, naming the caller and the relation.
  test "assert_baseline_intact!/3 raises BaselineError naming the caller and the missing relations" do
    error =
      assert_raise(SandboxOwnership.BaselineError, fn ->
        SandboxOwnership.assert_baseline_intact!(Mailglass.TestRepo, Mailglass.SomePretendTest,
          baseline_fun: fn _repo -> {false, ["mailglass_events"]} end,
          schema_fun: fn -> "mailglass" end
        )
      end)

    message = Exception.message(error)
    assert message =~ "Mailglass.SomePretendTest"
    assert message =~ "mailglass_events"
    assert message =~ ~s("mailglass")
  end

  # 19. `:cannot_verify` raises just as loudly — a check that cannot observe its
  # subject must never report success.
  test "assert_baseline_intact!/3 raises BaselineError on :cannot_verify, never :ok" do
    error =
      assert_raise(SandboxOwnership.BaselineError, fn ->
        SandboxOwnership.assert_baseline_intact!(Mailglass.TestRepo, Mailglass.SomePretendTest,
          baseline_fun: fn _repo -> {:cannot_verify, "42P01"} end,
          schema_fun: fn -> "mailglass" end
        )
      end)

    message = Exception.message(error)
    assert message =~ "could not verify"
    assert message =~ "42P01"
    assert message =~ "must never"
  end

  # ── with_search_path!/3 — the sanctioned `search_path` seam (D-31 Class A, the
  # confirmed root cause). This file is one of the three modules
  # `Mailglass.Credo.NoRawSearchPathMutation` allowlists, because proving the
  # seam requires driving the raw statements it exists to replace. ────────────

  # 20. The override is genuinely in effect inside the block.
  test "with_search_path!/3 applies the override for the duration of the block" do
    auto_mode!()

    observed =
      SandboxOwnership.with_search_path!(
        "public",
        fn ->
          %{rows: [[value]]} = Mailglass.TestRepo.query!("SHOW search_path", [])
          value
        end,
        caller: __MODULE__
      )

    assert observed == "public"
  end

  # 21. THE regression: the pool must not be left poisoned. A session-level
  # `SET` persists on the physical connection for its lifetime, so the failure
  # this pins is a LATER, unrelated test drawing that connection and raising
  # 42P01 on an unqualified relation name. Reading the value back on a fresh
  # checkout is the observation that would have caught the original defect.
  test "with_search_path!/3 leaves no poisoned connection behind, even when the block raises" do
    auto_mode!()
    before = live_search_path()

    assert_raise RuntimeError, "boom", fn ->
      SandboxOwnership.with_search_path!("public", fn -> raise "boom" end, caller: __MODULE__)
    end

    assert live_search_path() == before

    for _ <- 1..20, do: assert(live_search_path() == before)
  end

  # 22. A restore that cannot be observed to have landed must NOT be reported as
  # success. Driven through the injectable verification read so the raise path is
  # provable without genuinely poisoning the suite's pool.
  test "with_search_path!/3 raises SearchPathError when the restore does not land" do
    auto_mode!()

    error =
      assert_raise(SandboxOwnership.SearchPathError, fn ->
        SandboxOwnership.with_search_path!("public", fn -> :ok end,
          caller: Mailglass.SomePretendTest,
          search_path_fun: fn _repo -> "public" end
        )
      end)

    message = Exception.message(error)
    assert message =~ "Mailglass.SomePretendTest"
    assert message =~ "search_path"
    assert message =~ "42P01"
  end

  # The three tests above run under pool-wide `:auto` deliberately, not as a
  # convenience: `:auto` is the ONLY mode the poisoning defect exists in. Every
  # query checks a connection out of the 10-slot pool and hands it straight
  # back, which is what let a session-level `SET` escape into the pool and fail
  # an unrelated test later. Pinning these tests to `:manual` would test a mode
  # in which the bug cannot occur. The revert to `:manual` is already registered
  # by this file's own `setup` on_exit (which runs after every test), matching
  # the ordering discipline the module under test enforces.
  defp auto_mode!, do: :ok = Sandbox.mode(Mailglass.TestRepo, :auto)

  # Reads the search_path on a FRESH pool checkout — deliberately not the pinned
  # one `with_search_path!/3` used, since the whole defect was that the poisoned
  # connection went back into the pool for someone else to draw.
  defp live_search_path do
    %{rows: [[value]]} = Mailglass.TestRepo.query!("SHOW search_path", [])
    value
  end
end
