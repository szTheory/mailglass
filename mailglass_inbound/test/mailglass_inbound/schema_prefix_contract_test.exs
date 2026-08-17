defmodule MailglassInbound.SchemaPrefixContractTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.Config
  alias MailglassInbound.Execution
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Internal.Replay

  @schema_key {MailglassInbound.Config, :schema}

  defmodule CaptureRepo do
    @moduledoc false

    def one(queryable), do: one(queryable, [])

    def one(queryable, opts) do
      capture_queryable(queryable)
      capture(:one, opts)
      pop_result(:capture_repo_one_results, nil)
    end

    def get(queryable, id), do: get(queryable, id, [])

    def get(_queryable, _id, opts) do
      capture(:get, opts)
      pop_result(:capture_repo_get_results, nil)
    end

    def all(queryable), do: all(queryable, [])

    def all(_queryable, opts) do
      capture(:all, opts)
      pop_result(:capture_repo_all_results, [])
    end

    defp capture(function, opts) do
      calls = Process.get(:capture_repo_calls, [])
      Process.put(:capture_repo_calls, calls ++ [{function, opts}])
    end

    defp capture_queryable(queryable) do
      queryables = Process.get(:capture_repo_queryables, [])
      Process.put(:capture_repo_queryables, queryables ++ [queryable])
    end

    defp pop_result(key, default) do
      case Process.get(key, []) do
        [result | rest] ->
          Process.put(key, rest)
          result

        [] ->
          default
      end
    end
  end

  defmodule ExecutionStub do
    @moduledoc false

    def execute(payload, opts) do
      Process.put(:execution_payload, payload)
      Process.put(:execution_opts, opts)
      {:ok, %{status: :replayed}}
    end
  end

  defmodule TestMailbox do
    @moduledoc false
    @behaviour MailglassInbound.Mailbox

    def process(_message), do: :accept
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route(TestMailbox, recipient: "support@example.com")
  end

  setup do
    prior_schema = Application.fetch_env(:mailglass_inbound, :schema)
    prior_shell = Mix.shell()

    Application.put_env(:mailglass_inbound, :schema, "mg_contract")
    :persistent_term.erase(@schema_key)
    Mix.shell(Mix.Shell.Process)
    reset_capture_repo()

    on_exit(fn ->
      reset_capture_repo()
      :persistent_term.erase(@schema_key)
      Mix.shell(prior_shell)

      case prior_schema do
        {:ok, value} -> Application.put_env(:mailglass_inbound, :schema, value)
        :error -> Application.delete_env(:mailglass_inbound, :schema)
      end
    end)

    :ok
  end

  test "Internal.Replay.replay/2 passes schema prefix opts to raw repo one calls" do
    record_id = Ecto.UUID.generate()
    evidence_id = Ecto.UUID.generate()

    queue_one_results([
      inbound_record(record_id),
      inbound_evidence(evidence_id, record_id),
      execution_run(record_id, evidence_id)
    ])

    assert {:ok, %{status: :replayed}} =
             Replay.replay(record_id,
               tenant_id: "tenant-a",
               repo: CaptureRepo,
               router: TestRouter,
               execution: ExecutionStub
             )

    assert_prefixed_calls([:one, :one])
  end

  test "Execution.load/2 tenant-scopes both raw repo loads" do
    record_id = Ecto.UUID.generate()
    evidence_id = Ecto.UUID.generate()

    queue_one_results([
      inbound_record(record_id),
      inbound_evidence(evidence_id, record_id)
    ])

    assert {:ok, %{status: :inserted, route: %{status: :matched}}} =
             Execution.load(
               %{
                 "inbound_record_id" => record_id,
                 "inbound_evidence_id" => evidence_id,
                 "route_status" => "matched",
                 "mailglass_tenant_id" => "tenant-a",
                 "mailbox" => Atom.to_string(TestMailbox)
               },
               repo: CaptureRepo,
               router: TestRouter
             )

    assert_prefixed_calls([:one, :one])
    assert_tenant_scoped_execution_load_queries()
  end

  test "Execution.load/2 rejects unknown mailbox strings without creating atoms" do
    record_id = Ecto.UUID.generate()
    evidence_id = Ecto.UUID.generate()
    mailbox = "MailglassInbound.UnknownMailbox#{System.unique_integer([:positive])}"

    refute existing_atom?("Elixir." <> mailbox)

    queue_one_results([
      inbound_record(record_id),
      inbound_evidence(evidence_id, record_id)
    ])

    assert {:error, :invalid_job_args} =
             Execution.load(
               %{
                 "inbound_record_id" => record_id,
                 "inbound_evidence_id" => evidence_id,
                 "route_status" => "matched",
                 "mailglass_tenant_id" => "tenant-a",
                 "mailbox" => mailbox
               },
               repo: CaptureRepo
             )

    refute existing_atom?("Elixir." <> mailbox)
    assert_prefixed_calls([:one, :one])
  end

  test "Internal.Replay.replay/2 rejects unknown mailbox strings without creating atoms" do
    record_id = Ecto.UUID.generate()
    evidence_id = Ecto.UUID.generate()
    mailbox = "MailglassInbound.UnknownReplayMailbox#{System.unique_integer([:positive])}"

    refute existing_atom?("Elixir." <> mailbox)

    queue_one_results([
      inbound_record(record_id),
      inbound_evidence(evidence_id, record_id),
      execution_run(record_id, evidence_id, mailbox)
    ])

    assert {:ok, %{status: :replayed}} =
             Replay.replay(record_id,
               tenant_id: "tenant-a",
               repo: CaptureRepo,
               router: TestRouter,
               execution: ExecutionStub
             )

    refute existing_atom?("Elixir." <> mailbox)
    assert_prefixed_calls([:one, :one])
  end

  test "mix task selector resolution passes schema prefix opts to raw repo all call" do
    record_id = Ecto.UUID.generate()
    queue_all_result([record_id])

    Mix.Task.reenable("mailglass.inbound.replay")

    Mix.Tasks.Mailglass.Inbound.Replay.run(
      ["--tenant", "tenant-a", "--dry-run", "--no-start"],
      repo: CaptureRepo
    )

    assert_prefixed_calls([:all])
  end

  defp inbound_record(id) do
    %InboundRecord{
      id: id,
      tenant_id: "tenant-a",
      provider: "postmark",
      received_at: DateTime.utc_now()
    }
  end

  defp inbound_evidence(id, record_id) do
    %InboundEvidence{
      id: id,
      tenant_id: "tenant-a",
      inbound_record_id: record_id,
      provider: "postmark",
      verification_facts: %{
        "mailglass_execution_route" => %{
          "status" => "matched",
          "mailbox" => Atom.to_string(TestMailbox),
          "router" => Atom.to_string(TestRouter)
        }
      }
    }
  end

  defp execution_run(record_id, evidence_id, mailbox \\ Atom.to_string(TestMailbox)) do
    %ExecutionRun{
      id: Ecto.UUID.generate(),
      tenant_id: "tenant-a",
      inbound_record_id: record_id,
      inbound_evidence_id: evidence_id,
      source: :fresh,
      mailbox: mailbox,
      outcome: :accept
    }
  end

  defp queue_one_results(results), do: Process.put(:capture_repo_one_results, results)
  defp queue_all_result(result), do: Process.put(:capture_repo_all_results, [result])

  defp assert_prefixed_calls(expected_functions) do
    calls = Process.get(:capture_repo_calls, [])

    assert Enum.map(calls, fn {function, _opts} -> function end) == expected_functions

    for {_function, opts} <- calls do
      assert Keyword.get(opts, :prefix) == Config.schema()
    end
  end

  defp assert_tenant_scoped_execution_load_queries do
    [record_query, evidence_query] = Process.get(:capture_repo_queryables, [])

    assert MapSet.subset?(MapSet.new([:id, :tenant_id]), query_field_names(record_query))

    assert MapSet.subset?(
             MapSet.new([:id, :tenant_id, :inbound_record_id]),
             query_field_names(evidence_query)
           )
  end

  defp query_field_names(queryable) do
    queryable
    |> Map.fetch!(:wheres)
    |> Enum.reduce(MapSet.new(), fn %{expr: expr}, fields ->
      {_expr, expr_fields} =
        Macro.prewalk(expr, MapSet.new(), fn
          {{:., _, [{:&, _, [0]}, field]}, _, []} = node, fields when is_atom(field) ->
            {node, MapSet.put(fields, field)}

          node, fields ->
            {node, fields}
        end)

      MapSet.union(fields, expr_fields)
    end)
  end

  defp reset_capture_repo do
    Process.delete(:capture_repo_calls)
    Process.delete(:capture_repo_queryables)
    Process.delete(:capture_repo_one_results)
    Process.delete(:capture_repo_get_results)
    Process.delete(:capture_repo_all_results)
    Process.delete(:execution_payload)
    Process.delete(:execution_opts)
  end

  defp existing_atom?(name) do
    _atom = String.to_existing_atom(name)
    true
  rescue
    ArgumentError -> false
  end
end
