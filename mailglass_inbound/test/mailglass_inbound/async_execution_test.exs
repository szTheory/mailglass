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

  defmodule RefusingTaskSupervisor do
    def start_child(_name, _fun, _opts \\ []), do: {:error, :max_children}
  end

  defmodule ExitingTaskSupervisor do
    def start_child(_name, _fun, _opts \\ []), do: exit(:noproc)
  end

  defmodule RecordingExecution do
    def execute(persisted, _opts \\ []) do
      send(self(), {:execution_payload, persisted})
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule BarrierExecution do
    def execute(_persisted, _opts \\ []) do
      parent = Application.fetch_env!(:mailglass_inbound, :async_execution_test_pid)
      send(parent, :held)

      receive do
        :release -> {:ok, %{outcome: :accept}}
      end
    end
  end

  defmodule WarningGateway do
    def runner, do: :task_supervisor
  end

  setup do
    :persistent_term.erase({:mailglass_inbound, :fallback_warning_emitted})
    Process.delete(:mailglass_inbound_async_worker)
    Process.delete(:mailglass_inbound_async_enqueue_attrs)
    Application.put_env(:mailglass_inbound, :async_execution_test_pid, self())

    on_exit(fn -> Application.delete_env(:mailglass_inbound, :async_execution_test_pid) end)

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
             "route_status" => "matched",
             "mailbox" => "Elixir.MailglassInbound.AsyncExecutionTest",
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

  test "real supervisor refuses the eleventh held fallback task with a typed error" do
    name = String.to_atom("mailglass_inbound_dispatch_test_#{System.unique_integer([:positive])}")
    start_supervised!({Task.Supervisor, name: name, max_children: 10})
    persisted = persisted_payload()

    for _ <- 1..10 do
      assert {:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}} =
               Execution.dispatch(persisted,
                 execution: BarrierExecution,
                 optional_deps: FallbackGateway,
                 task_supervisor: Task.Supervisor,
                 task_supervisor_name: name
               )

      assert_receive :held
    end

    assert {:error, %Mailglass.SendError{type: :dispatch_unavailable} = error} =
             Execution.dispatch(persisted,
               execution: BarrierExecution,
               optional_deps: FallbackGateway,
               task_supervisor: Task.Supervisor,
               task_supervisor_name: name
             )

    assert error.context == %{reason_class: :capacity_reached}

    for {_id, pid, _type, _modules} <- Supervisor.which_children(name), is_pid(pid) do
      send(pid, :release)
    end
  end

  test "fallback normalizes supervisor errors and exits to typed unavailable failures" do
    persisted = persisted_payload()

    for supervisor <- [RefusingTaskSupervisor, ExitingTaskSupervisor] do
      assert {:error, %Mailglass.SendError{type: :dispatch_unavailable} = error} =
               Execution.dispatch(persisted,
                 optional_deps: FallbackGateway,
                 task_supervisor: supervisor
               )

      assert error.context in [
               %{reason_class: :capacity_reached},
               %{reason_class: :supervisor_unavailable}
             ]
    end
  end

  test "fallback mode emits an honest warning once per node" do
    log =
      capture_log(fn ->
        assert :ok ==
                 MailglassInbound.Application.maybe_warn_fallback_mode(
                   optional_deps: WarningGateway
                 )

        assert :ok ==
                 MailglassInbound.Application.maybe_warn_fallback_mode(
                   optional_deps: WarningGateway
                 )
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
