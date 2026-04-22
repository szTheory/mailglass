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

    # Stamp a default tenant per D-40 so tests exercise the
    # "tenant stamped" code path, not the SingleTenant fallback.
    # Tests that want to exercise the fallback can @tag tenant: :unset.
    tenant_id = Map.get(tags, :tenant, "test-tenant")

    unless tenant_id == :unset do
      # NOTE: Mailglass.Tenancy.put_current/1 ships in Plan 04.
      # Plan 04 updates this setup to call it. For Plan 01 we stash the
      # value directly into the process dict under the same key the
      # Tenancy module will use so tests written in Plans 02-03 work.
      Process.put(:mailglass_tenant_id, tenant_id)
    end

    :ok
  end

  @doc """
  Runs `fun` with a scoped tenant_id override for this test.
  Restores the prior tenant on return.
  """
  @spec with_tenant(String.t(), (-> any())) :: any()
  def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
    prior = Process.get(:mailglass_tenant_id)
    Process.put(:mailglass_tenant_id, tenant_id)

    try do
      fun.()
    after
      if prior,
        do: Process.put(:mailglass_tenant_id, prior),
        else: Process.delete(:mailglass_tenant_id)
    end
  end
end
