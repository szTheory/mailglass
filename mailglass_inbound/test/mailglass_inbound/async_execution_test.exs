defmodule MailglassInbound.AsyncExecutionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage

  defmodule ObanGateway do
    def runner, do: :oban

    def enqueue_inbound_execution(worker, attrs, _opts \\ []) do
      Process.put(:mailglass_inbound_async_worker, worker)
      Process.put(:mailglass_inbound_async_enqueue_attrs, attrs)
      {:ok, %{id: 123, worker: worker}}
    end
  end

  defmodule FallbackGateway do
    def runner, do: :task_supervisor
  end

  defmodule FakeTaskSupervisor do
    def start_child(_name, fun, _opts \\ []) when is_function(fun, 0) do
      send(self(), :task_supervisor_started)
      fun.()
      {:ok, self()}
    end
  end

  defmodule RecordingExecution do
    def execute(persisted, _opts \\ []) do
      send(self(), {:execution_payload, persisted})
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule WarningGateway do
    def runner, do: :task_supervisor
  end

  setup do
    :persistent_term.erase({:mailglass_inbound, :fallback_warning_emitted})
    Process.delete(:mailglass_inbound_async_worker)
    Process.delete(:mailglass_inbound_async_enqueue_attrs)
    :ok
  end

  test "dispatches fresh persisted execution through internal oban worker without exposing job structs" do
    persisted = persisted_payload()

    assert {:ok, %{status: :queued, mode: :oban}} =
             Execution.dispatch(persisted, optional_deps: ObanGateway)

    assert Process.get(:mailglass_inbound_async_worker) == MailglassInbound.Execution.Worker

    assert Process.get(:mailglass_inbound_async_enqueue_attrs) == %{
             "inbound_record_id" => "record-123",
             "inbound_evidence_id" => "evidence-123",
             "source" => "fresh",
             "mailglass_tenant_id" => "tenant-123"
           }
  end

  test "falls back to bounded task supervisor execution and marks the dispatch as best effort" do
    persisted = persisted_payload()

    assert {:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}} =
             Execution.dispatch(persisted,
               execution: RecordingExecution,
               optional_deps: FallbackGateway,
               task_supervisor: FakeTaskSupervisor,
               task_supervisor_name: MailglassInbound.TaskSupervisor
             )

    assert_received :task_supervisor_started

    assert_received {:execution_payload,
                     %{inbound_record: %{id: "record-123"}, inbound_evidence: %{id: "evidence-123"}}}
  end

  test "fallback mode emits an honest warning once per node" do
    log =
      capture_log(fn ->
        assert :ok ==
                 MailglassInbound.Application.maybe_warn_fallback_mode(optional_deps: WarningGateway)

        assert :ok ==
                 MailglassInbound.Application.maybe_warn_fallback_mode(optional_deps: WarningGateway)
      end)

    assert log =~ "mailglass_inbound"
    assert log =~ "Task.Supervisor"
    assert log =~ "best-effort"
  end

  defp persisted_payload do
    %{
      status: :inserted,
      route: %{status: :matched, mailbox: MailglassInbound.AsyncExecutionTest},
      message: %InboundMessage{
        tenant_id: "tenant-123",
        provider: :postmark,
        envelope_recipient: "support@example.com"
      },
      inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
      inbound_evidence: %{id: "evidence-123"}
    }
  end
end
