defmodule Mailglass.DataCase do
  @moduledoc """
  ExUnit case template for mailglass tests that touch the database.

  Sets up an `Ecto.Adapters.SQL.Sandbox` checkout per test, stamps a
  default tenant for the process (`"test-tenant"` — overridable via
  `@tag tenant: "..."` or `with_tenant/2`), and imports `Ecto.Query`
  + `Ecto.Changeset` for convenience.

  ## Usage

      defmodule Mailglass.MyThingTest do
        use Mailglass.DataCase, async: true
        # ...
      end

  Async is opt-in. Property tests (Plan 05) run `async: false`.

  Tenant stamping routes through `Mailglass.Tenancy.put_current/1` so
  test-side tenant plumbing is indistinguishable from production.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Mailglass.TestRepo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Mailglass.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    # Probe the checked-out connection for a stale citext OID.
    #
    # `migration_test.exs` drops and recreates the citext extension to prove the
    # down/up round-trip. The recreated extension gets a new OID from Postgres.
    # Pool workers alive during the drop retain the pre-drop OID, surfacing on
    # the next citext query as:
    #
    #   (Postgrex.Error) ERROR XX000 (internal_error)
    #   cache lookup failed for type NNNNNN
    #
    # `disconnect_on_error_codes: [:internal_error]` in config/test.exs converts
    # the error into a pool disconnect+reconnect; the reconnected worker
    # re-bootstraps its type cache against the live DB.
    #
    # The probe runs AFTER `start_owner!` on the checked-out sandbox connection.
    # If the probe fails (stale OID), `disconnect_on_error_codes` fires: the
    # connection disconnects and DBConnection.Ownership automatically reconnects
    # it while preserving the ownership token. The test body then uses the clean,
    # reconnected connection. On a warm (already-clean) DB the probe succeeds
    # immediately with no side-effects.
    #
    # This is the same pattern as `persistence_integration_test.exs`'s
    # `probe_until_clean/5` — loop up to pool_size times to handle the worst-case
    # where the reconnected worker itself was stale and needed a second cycle.
    for _ <- 1..5 do
      try do
        Mailglass.TestRepo.query!("SELECT 'probe'::citext")
      rescue
        # disconnect_on_error_codes fires; ownership auto-reconnects
        Postgrex.Error -> :ok
      end
    end

    # Stamp a default tenant per D-40 so tests exercise the
    # "tenant stamped" code path, not the SingleTenant fallback.
    # Tests that want to exercise the fallback can @tag tenant: :unset.
    tenant_id = Map.get(tags, :tenant, "test-tenant")

    unless tenant_id == :unset do
      Mailglass.Tenancy.put_current(tenant_id)
    end

    :ok
  end

  @doc """
  Runs `fun` with a scoped tenant_id override for this test.
  Delegates to `Mailglass.Tenancy.with_tenant/2`; restores the prior
  tenant on return (or raise).
  """
  @spec with_tenant(String.t(), (-> any())) :: any()
  def with_tenant(tenant_id, fun), do: Mailglass.Tenancy.with_tenant(tenant_id, fun)
end
