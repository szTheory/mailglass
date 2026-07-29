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

  ## Usage

      # In `Mailglass.TestSupport.SuiteTruthFormatter`'s `:module_finished` handler:
      Mailglass.TestSupport.SandboxOwnership.probe(Mailglass.TestRepo)
  """

  @doc """
  Resets `repo`'s Sandbox pool to `:manual` mode and reports what that call
  revealed.

  `Ecto.Adapters.SQL.Sandbox.mode/2` is NOT read-only: setting `:manual`
  unconditionally checks in every live connection and overwrites the pool's
  mode, whatever it was before (`manager.ex:161-172` — the catch-all clause
  matches any current mode and always replies `:ok`). On a genuinely leaked
  `{:shared, pid}` owner this both detects AND heals the leak in the same
  call — exactly what is wanted at a module boundary, since the remaining
  ~1200 tests still produce signal instead of cascading failures. But it also
  means the return value alone can never distinguish "the pool was already
  `:manual`" from "the pool was leaked and this call just fixed it" — both
  paths reply `:ok`. Do not attempt that distinction here.

  The discipline this probe exists to enforce is: match the return value
  rather than discard it (the mistake `mailer_case.ex`'s four now-deleted raw
  `Sandbox.mode(repo, {:shared, self()})` calls made — see D-07). `mode/2`'s
  own `@spec` documents `:ok | :already_shared | :not_owner | :not_found` as
  possible replies; anything other than the documented `:ok` is reported as
  `{:leaked, term}` rather than silently treated as success. A probe that
  cannot observe its subject must never report green.
  """
  @spec probe(module()) :: :ok | {:leaked, term()}
  def probe(repo \\ Mailglass.TestRepo) do
    case Ecto.Adapters.SQL.Sandbox.mode(repo, :manual) do
      :ok -> :ok
      other -> {:leaked, other}
    end
  end
end
