defmodule Mailglass.Credo.NoUnscopedTenantQueryInLibTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoUnscopedTenantQueryInLib

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags tenanted Repo query when function has no tenancy scope call" do
    source = """
    defmodule Mailglass.Outbound.BadTenantScope do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery
      alias Mailglass.Repo

      def list do
        Repo.all(from(d in Delivery, select: d.id))
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_tenant_scope.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.Tenancy.scope/2")
  end

  test "does not flag tenanted Repo query when function calls Mailglass.Tenancy.scope/2" do
    source = """
    defmodule Mailglass.Outbound.GoodTenantScope do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery
      alias Mailglass.Repo

      def list(tenant_context) do
        query = from(d in Delivery, select: d.id)
        scoped_query = Mailglass.Tenancy.scope(query, tenant_context)
        Repo.all(scoped_query)
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/good_tenant_scope.ex") == []
  end

  test "does not flag tenanted Repo query when scope is applied inline at call site" do
    source = """
    defmodule Mailglass.Outbound.GoodInlineTenantScope do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery
      alias Mailglass.Repo

      def list(tenant_context) do
        Repo.all(Mailglass.Tenancy.scope(from(d in Delivery, select: d.id), tenant_context))
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/good_inline_tenant_scope.ex") == []
  end

  test "flags unscoped tenanted query even when same function also has scoped query" do
    source = """
    defmodule Mailglass.Outbound.MixedTenantScope do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery
      alias Mailglass.Repo

      def list(tenant_context) do
        Repo.all(Mailglass.Tenancy.scope(from(d in Delivery, select: d.id), tenant_context))
        Repo.all(from(d in Delivery, select: d.id))
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/mixed_tenant_scope.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.Tenancy.scope/2")
  end

  test "does not flag explicit scope: :unscoped bypass" do
    source = """
    defmodule Mailglass.Events.AdminReadback do
      import Ecto.Query
      alias Mailglass.Events.Event
      alias Mailglass.Repo

      def list_unscoped do
        Repo.one(from(e in Event, select: e.id), scope: :unscoped)
      end
    end
    """

    assert run_check(source, "lib/mailglass/events/admin_readback.ex") == []
  end

  test "does not flag query for non-tenanted schema" do
    source = """
    defmodule Mailglass.Outbound.NonTenantedRead do
      import Ecto.Query
      alias Mailglass.Repo

      defmodule User do
        use Ecto.Schema
        schema "users" do
        end
      end

      def list_users do
        Repo.all(from(u in User, select: u.id))
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/non_tenanted_read.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.Fixture.BadTenantScope do
      import Ecto.Query
      alias Mailglass.Outbound.Delivery
      alias Mailglass.Repo

      def list do
        Repo.all(from(d in Delivery))
      end
    end
    """

    assert run_check(source, "test/support/no_unscoped_tenant_query_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoUnscopedTenantQueryInLib.run([])
  end
end
