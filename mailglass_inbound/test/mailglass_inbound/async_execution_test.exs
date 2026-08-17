defmodule MailglassInbound.AsyncExecutionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage

  defmodule TestMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route(TestMailbox, recipient: "support@example.com")
  end

  defmodule OtherMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule OtherRouter do
    use MailglassInbound.Router

    route(OtherMailbox, recipient: "other@example.com")
  end

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

  defmodule WorkerLoader do
    def load(_args) do
      {:ok,
       %{
         status: :inserted,
         route: %{status: :matched, mailbox: TestMailbox},
         message: %InboundMessage{tenant_id: "tenant-123", provider: :postmark},
         inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
         inbound_evidence: %{
           id: "evidence-123",
           verification_facts: MailglassInbound.AsyncExecutionTest.route_binding()
         }
       }}
    end
  end

  defmodule WorkerExecution do
    def execute(_persisted, _opts \\ []) do
      send(Application.fetch_env!(:mailglass_inbound, :async_execution_test_pid), :worker_executed)
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
    prior_router = Application.get_env(:mailglass_inbound, :router)
    :persistent_term.erase({:mailglass_inbound, :fallback_warning_emitted})
    Process.delete(:mailglass_inbound_async_worker)
    Process.delete(:mailglass_inbound_async_enqueue_attrs)
    Application.put_env(:mailglass_inbound, :async_execution_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:mailglass_inbound, :async_execution_test_pid)

      if is_nil(prior_router) do
        Application.delete_env(:mailglass_inbound, :router)
      else
        Application.put_env(:mailglass_inbound, :router, prior_router)
      end
    end)

    :ok
  end

  test "dispatches fresh persisted execution through internal oban worker without exposing job structs" do
    persisted = persisted_payload()

    assert {:ok, %{status: :queued, mode: :oban}} =
             Execution.dispatch(persisted, optional_deps: ObanGateway, router: TestRouter)

    assert Process.get(:mailglass_inbound_async_worker) == MailglassInbound.Execution.Worker

    assert Process.get(:mailglass_inbound_async_enqueue_attrs) == %{
             "inbound_record_id" => "record-123",
             "inbound_evidence_id" => "evidence-123",
             "route_status" => "matched",
             "mailbox" => "Elixir.MailglassInbound.AsyncExecutionTest.TestMailbox",
             "source" => "fresh",
             "mailglass_tenant_id" => "tenant-123"
           }
  end

  test "Plug-only router authority survives enqueue and authorizes the worker without global config" do
    Application.delete_env(:mailglass_inbound, :router)
    persisted = persisted_payload()

    assert {:ok, %{status: :queued, mode: :oban}} =
             Execution.dispatch(persisted, optional_deps: ObanGateway, router: TestRouter)

    args = Process.get(:mailglass_inbound_async_enqueue_attrs)
    assert is_map(args)

    registry = Process.whereis(MailglassInbound.Execution.RouterRegistry)
    Process.exit(registry, :kill)
    wait_for_registry(registry)

    assert :ok =
             MailglassInbound.Execution.Worker.perform(%Oban.Job{args: args},
               loader: WorkerLoader,
               execution: WorkerExecution
             )

    assert_received :worker_executed
  end

  test "durable evidence rejects a job switched to another registered router mailbox" do
    persisted = persisted_payload()

    assert {:ok, %{status: :queued, mode: :oban}} =
             Execution.dispatch(persisted, optional_deps: ObanGateway, router: TestRouter)

    assert {:ok, _} = MailglassInbound.Execution.RouterRegistry.register_router(OtherRouter)

    args =
      Process.get(:mailglass_inbound_async_enqueue_attrs)
      |> Map.put("mailbox", Atom.to_string(OtherMailbox))

    assert {:cancel, :permanent_failure} =
             MailglassInbound.Execution.Worker.perform(%Oban.Job{args: args},
               loader: WorkerLoader,
               execution: WorkerExecution
             )

    refute_received :worker_executed
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
      route: %{status: :matched, mailbox: TestMailbox},
      message: %InboundMessage{
        tenant_id: "tenant-123",
        provider: :postmark,
        envelope_recipient: "support@example.com"
      },
      inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
      inbound_evidence: %{id: "evidence-123", verification_facts: route_binding()}
    }
  end

  def route_binding do
    %{
      "mailglass_execution_route" => %{
        "status" => "matched",
        "mailbox" => Atom.to_string(TestMailbox),
        "router" => Atom.to_string(TestRouter)
      }
    }
  end

  defp wait_for_registry(old_pid, attempts \\ 50)
  defp wait_for_registry(_old_pid, 0), do: :ok

  defp wait_for_registry(old_pid, attempts) do
    case Process.whereis(MailglassInbound.Execution.RouterRegistry) do
      pid when is_pid(pid) and pid != old_pid ->
        :ok

      _ ->
        Process.sleep(10)
        wait_for_registry(old_pid, attempts - 1)
    end
  end
end
