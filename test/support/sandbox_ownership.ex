defmodule Mailglass.TestSupport.SandboxOwnership do
  @moduledoc """
  Probes the Ecto Sandbox pool for a leaked ownership mode at an `async: false`
  module boundary (HARNESS-01, D-06, D-08).

  Background: `db_connection`'s ownership manager (`manager.ex:148-172`) can end
  up holding `{:shared, pid}` after a test raised between acquiring shared mode
  and registering its `on_exit` release — the pool never gets checked back in.
  The next `async: false` module's `Ecto.Adapters.SQL.Sandbox.start_owner!(shared:
  true)` then raises `{:badmatch, :already_shared}` at
  `ecto_sql/lib/ecto/adapters/sql/sandbox.ex:458`, 200+ failures away from the
  test that actually leaked.

  `Mailglass.TestSupport.SuiteTruthFormatter` calls `probe/1` at every
  `:module_finished` boundary of an `async: false` module so the leaking module
  is named the instant it happens, rather than inferred from a distant victim.

  ## Why `probe/1` reads `:sys.get_state/1` instead of calling `Sandbox.mode/2`

  An earlier version of this module called
  `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)` and matched its return value,
  reasoning that "the return value alone can't distinguish already-manual from
  leaked-and-healed, but at least it's *some* signal." That reasoning was
  wrong, and fatally so for this phase: `manager.ex:161-172`'s catch-all
  clause matches ANY current mode and always replies `:ok` — there is no
  input for which that call returns anything else. A probe built on it can
  *never* observe a leak; the ledger would read `0 record(s)` forever whether
  or not leaks occur, and the call itself checks in every live connection and
  overwrites the pool's mode on every single `async: false` module boundary —
  a suite-wide auto-heal that would mask the exact bug HARNESS-01 exists to
  expose. Confirmed live: putting the pool in `{:shared, pid}` and calling
  that version of `probe/1` returned `:ok`, and the leak was gone afterward.

  There is no public, read-only "what mode is this pool in?" function on
  either `Ecto.Adapters.SQL.Sandbox` or `DBConnection.Ownership` — `mode/2` is
  the only exposed entry point, and it is a write. `probe/1` instead reads the
  ownership manager's own process state directly via `:sys.get_state/1`, which
  sends no `GenServer.call` message and triggers no `handle_call` clause — it
  is the OTP-sanctioned way to inspect a process's state without a side
  effect. The state map's `:mode` key (`manager.ex:105-115`, `:auto | :manual
  | {:shared, pid}`) is `@moduledoc false`/private to `db_connection`, so this
  coupling is deliberate and version-pinned; confirmed empirically against
  this repo's `mix.lock` `db_connection` version: `:manual` on a clean pool,
  `{:shared, pid}` on a leaked one, unchanged across repeated reads, and a
  leak observed this way is *still* there afterward (a second
  `start_owner!(shared: true)` still raises `{:badmatch, :already_shared}`).

  The ownership manager's pid is looked up the same way `Sandbox` itself does
  internally (`sandbox.ex:636-651`'s private `lookup_meta!/1`), via the public
  `Ecto.Adapter.lookup_meta/1`.

  **Healing is out of scope for this probe.** `probe/1` never mutates the
  pool. A future wave may add a distinct, explicitly-named, opt-in heal
  step (Wave 2's `SandboxOwnership.checkout!/1` recurrence guard) — it must
  never be a side effect of observation.

  ## Usage

      # In `Mailglass.TestSupport.SuiteTruthFormatter`'s `:module_finished` handler:
      Mailglass.TestSupport.SandboxOwnership.probe(Mailglass.TestRepo)
  """

  @doc """
  Reads `repo`'s Sandbox pool ownership mode without mutating it.

  Returns `:ok` when the pool is already `:manual` (the expected steady state
  between `async: false` module boundaries). Returns `{:leaked, mode}` for any
  other observed mode — `{:shared, pid}` (the ownership-leak class HARNESS-01
  names) or `:auto` (a module that switched pool-wide auto mode and never
  restored it). A probe that cannot observe its subject must never report
  green: if the ownership manager cannot be found for `repo` at all, that is
  reported as `{:leaked, :cannot_verify}` rather than treated as `:ok`.
  """
  @spec probe(module()) :: :ok | {:leaked, term()}
  def probe(repo \\ Mailglass.TestRepo) do
    case current_mode(repo) do
      :manual -> :ok
      other -> {:leaked, other}
    end
  end

  defp current_mode(repo) do
    case Ecto.Adapter.lookup_meta(repo) do
      %{pid: manager_pid} when is_pid(manager_pid) ->
        %{mode: mode} = :sys.get_state(manager_pid)
        mode

      _ ->
        :cannot_verify
    end
  rescue
    # `:sys.get_state/1` raises if the manager pid is gone (e.g. the repo was
    # stopped between checkout and probe). Report it, never report green.
    _ -> :cannot_verify
  end
end
