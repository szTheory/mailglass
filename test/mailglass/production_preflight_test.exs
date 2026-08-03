defmodule Mailglass.ProductionPreflightTest do
  use ExUnit.Case, async: false

  alias Mailglass.ProductionPreflight

  defmodule OperatorAuth do
    def authorize(:operator_access, %{actor: %{subject_id: "operator-1"}}),
      do: {:ok, %{actor: %{subject_id: "operator-1"}, assigns: %{}}}

    def authorize(_action, _context), do: {:error, :unauthorized, %{}}
  end

  setup do
    original = Application.get_all_env(:mailglass)

    on_exit(fn ->
      Application.get_all_env(:mailglass)
      |> Enum.each(fn {key, _value} -> Application.delete_env(:mailglass, key) end)

      Enum.each(original, fn {key, value} -> Application.put_env(:mailglass, key, value) end)
      :persistent_term.erase({Mailglass.Config, :schema})
    end)

    :ok
  end

  test "reports every failed prerequisite by stable name without exposing configured secrets" do
    Application.put_env(:mailglass, :repo, MissingRepo)
    Application.put_env(:mailglass, :schema, "mailglass")
    Application.put_env(:mailglass, :adapter, MissingAdapter)
    Application.put_env(:mailglass, :postmark, basic_auth: {"operator", "preflight-secret"})
    Application.put_env(:mailglass, :async_adapter, :task_supervisor)
    Application.put_env(:mailglass, :outbound_payload_maintenance, :none)
    Application.put_env(:mailglass, :operator, auth: MissingOperatorAuth)

    result = ProductionPreflight.run()

    assert result.status == :failed

    assert Enum.map(result.checks, & &1.id) == [
             :repo_access,
             :schema_access,
             :migration_version,
             :delivery_adapter,
             :webhook_signing,
             :outbound_queue,
             :payload_maintenance,
             :operator_mount
           ]

    assert Enum.all?(result.checks, &(&1.status == :failed))
    assert Enum.all?(result.checks, &(is_binary(&1.remediation) and &1.remediation != ""))
    refute inspect(result) =~ "preflight-secret"
  end

  test "accepts an explicit manual payload-maintenance fallback and a named operator auth callback" do
    Application.put_env(:mailglass, :outbound_payload_maintenance, :manual)
    Application.put_env(:mailglass, :operator, auth: OperatorAuth)

    assert Mailglass.Config.outbound_payload_maintenance() == :manual
    assert Mailglass.Config.operator_auth() == OperatorAuth
  end

  test "does not make ordinary application startup invoke production preflight" do
    refute Process.whereis(Mailglass.ProductionPreflight)
    assert function_exported?(Mailglass.Application, :start, 2)
  end
end
