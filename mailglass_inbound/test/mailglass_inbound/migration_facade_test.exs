defmodule MailglassInbound.MigrationFacadeTest do
  use ExUnit.Case, async: true

  defmodule TransactionalRepo do
    def __adapter__, do: Ecto.Adapters.Postgres
    def in_transaction?, do: true
  end

  test "rejects a forged non-transactional wrapper flag for up and down" do
    opts = [repo: TransactionalRepo, non_transactional_wrapper: true]

    for operation <- [:up, :down] do
      assert_raise ArgumentError,
                   ~r/@disable_ddl_transaction true; refusing concurrent DDL inside a transaction/,
                   fn -> apply(MailglassInbound.Migration, operation, [opts]) end
    end
  end
end
