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
end
