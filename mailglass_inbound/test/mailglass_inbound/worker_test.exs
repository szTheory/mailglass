defmodule MailglassInbound.WorkerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  defmodule Loader do
    def load(%{
          "inbound_record_id" => record_id,
          "inbound_evidence_id" => evidence_id,
          "source" => source,
          "route_status" => route_status,
          "mailbox" => mailbox
        }) do
      Process.put(
        :mailglass_inbound_worker_load_args,
        {record_id, evidence_id, source, route_status, mailbox}
      )

      {:ok,
       %{
         status: :inserted,
         route: %{status: :matched, mailbox: MailglassInbound.WorkerTest.AcceptMailbox},
         message: %MailglassInbound.InboundMessage{
           tenant_id: "tenant-123",
           provider: :postmark,
           envelope_recipient: "support@example.com"
         },
         inbound_record: %{id: record_id, tenant_id: "tenant-123"},
         inbound_evidence: %{
           id: evidence_id,
           verification_facts: MailglassInbound.WorkerTest.route_binding()
         }
       }}
    end
  end

  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule Router do
    use MailglassInbound.Router

    route(AcceptMailbox, recipient: "support@example.com")
  end

  defmodule LoadedProcessSentinel do
    def process(_message) do
      send(Application.fetch_env!(:mailglass_inbound, :worker_test_pid), :sentinel_invoked)
      :accept
    end
  end

  defmodule ExecutionSuccess do
    def execute(_persisted, opts \\ []) do
      Process.put(:mailglass_inbound_worker_execute_opts, opts)
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule ExecutionFailure do
    def execute(_persisted, _opts \\ []) do
      {:ok, %{outcome: :failed, failure: %{kind: :error, reason: "boom"}}}
    end
  end

  defmodule SourceLoader do
    def load(args) do
      Process.put(:mailglass_inbound_worker_source_load_args, args)

      {:ok,
       %{
         status: :inserted,
         route: %{status: :matched, mailbox: MailglassInbound.WorkerTest.AcceptMailbox},
         message: %MailglassInbound.InboundMessage{
           tenant_id: "tenant-123",
           provider: :postmark,
           envelope_recipient: "support@example.com"
         },
         inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
         inbound_evidence: %{
           id: "evidence-123",
           verification_facts: MailglassInbound.WorkerTest.route_binding()
         }
       }}
    end
  end

  defmodule SourceExecution do
    def execute(_persisted, opts \\ []) do
      Process.put(:mailglass_inbound_worker_source_execute_opts, opts)
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule LegacyBindingLoader do
    def load(args) do
      Process.put(:mailglass_inbound_worker_legacy_load_args, args)

      {:ok,
       %{
         status: :inserted,
         route: %{status: :matched, mailbox: MailglassInbound.WorkerTest.AcceptMailbox},
         message: %MailglassInbound.InboundMessage{tenant_id: "tenant-123", provider: :postmark},
         inbound_record: %{id: "record-123", tenant_id: "tenant-123"},
         inbound_evidence: %{id: "evidence-123", verification_facts: %{}}
       }}
    end
  end

  setup do
    prior_router = Application.get_env(:mailglass_inbound, :router)
    Application.put_env(:mailglass_inbound, :router, Router)
    Application.put_env(:mailglass_inbound, :worker_test_pid, self())

    on_exit(fn ->
      if is_nil(prior_router) do
        Application.delete_env(:mailglass_inbound, :router)
      else
        Application.put_env(:mailglass_inbound, :router, prior_router)
      end

      Application.delete_env(:mailglass_inbound, :worker_test_pid)
    end)
  end

  test "restores tenancy-safe worker args and returns :ok for successful executions" do
    job = %Oban.Job{
      args: %{
        "inbound_record_id" => "record-123",
        "inbound_evidence_id" => "evidence-123",
        "route_status" => "matched",
        "mailbox" => "Elixir.MailglassInbound.WorkerTest.AcceptMailbox",
        "source" => "fresh",
        "mailglass_tenant_id" => "tenant-123"
      }
    }

    assert :ok =
             MailglassInbound.Execution.Worker.perform(job,
               loader: Loader,
               execution: ExecutionSuccess
             )

    assert Process.get(:mailglass_inbound_worker_load_args) ==
             {"record-123", "evidence-123", "fresh", "matched",
              "Elixir.MailglassInbound.WorkerTest.AcceptMailbox"}

    assert Keyword.get(Process.get(:mailglass_inbound_worker_execute_opts, []), :source) == :fresh
  end

  test "maps failed shared execution outcomes to retryable oban errors" do
    job = %Oban.Job{
      args: %{
        "inbound_record_id" => "record-123",
        "inbound_evidence_id" => "evidence-123",
        "route_status" => "matched",
        "mailbox" => "Elixir.MailglassInbound.WorkerTest.AcceptMailbox",
        "source" => "fresh",
        "mailglass_tenant_id" => "tenant-123"
      }
    }

    assert {:error, %{kind: :error, reason: "boom"}} =
             MailglassInbound.Execution.Worker.perform(job,
               loader: Loader,
               execution: ExecutionFailure
             )
  end

  test "decodes every emitted source through the finite source map" do
    for {source, expected_source} <- [{"fresh", :fresh}, {"replay", :replay}] do
      assert :ok =
               MailglassInbound.Execution.Worker.perform(job_with_source(source),
                 loader: SourceLoader,
                 execution: SourceExecution
               )

      assert Keyword.fetch!(Process.get(:mailglass_inbound_worker_source_execute_opts), :source) ==
               expected_source
    end
  end

  test "defaults only absent source to fresh" do
    assert :ok =
             MailglassInbound.Execution.Worker.perform(job_with_source(:absent),
               loader: SourceLoader,
               execution: SourceExecution
             )

    assert Keyword.fetch!(Process.get(:mailglass_inbound_worker_source_execute_opts), :source) ==
             :fresh
  end

  test "cancels invalid sources before loading or executing without allocating atoms" do
    assert {:cancel, :permanent_failure} =
             MailglassInbound.Execution.Worker.perform(job_with_source("invalid-source-warmup"),
               loader: SourceLoader,
               execution: SourceExecution
             )

    refute Process.get(:mailglass_inbound_worker_source_load_args)
    refute Process.get(:mailglass_inbound_worker_source_execute_opts)
    atom_count = :erlang.system_info(:atom_count)

    for suffix <- 1..300 do
      assert {:cancel, :permanent_failure} =
               MailglassInbound.Execution.Worker.perform(
                 job_with_source("invalid-source-#{suffix}"),
                 loader: SourceLoader,
                 execution: SourceExecution
               )
    end

    assert :erlang.system_info(:atom_count) == atom_count

    assert {:cancel, :permanent_failure} =
             MailglassInbound.Execution.Worker.perform(job_with_source(123),
               loader: SourceLoader,
               execution: SourceExecution
             )

    refute Process.get(:mailglass_inbound_worker_source_load_args)
    refute Process.get(:mailglass_inbound_worker_source_execute_opts)
  end

  test "cancels a loaded non-mailbox process module before loader or mailbox invocation" do
    sentinel_mailbox = Atom.to_string(LoadedProcessSentinel)

    assert {:cancel, :permanent_failure} =
             MailglassInbound.Execution.Worker.perform(
               %Oban.Job{args: Map.put(job_with_source("fresh").args, "mailbox", sentinel_mailbox)},
               loader: Loader,
               execution: ExecutionSuccess
             )

    refute_received :sentinel_invoked
    assert Process.get(:mailglass_inbound_worker_load_args)
    refute Process.get(:mailglass_inbound_worker_execute_opts)
  end

  test "cancels contradictory no-match job data before loader or mailbox invocation" do
    args =
      job_with_source("fresh").args
      |> Map.put("route_status", "no_match")
      |> Map.put("mailbox", Atom.to_string(LoadedProcessSentinel))

    assert {:cancel, :permanent_failure} =
             MailglassInbound.Execution.Worker.perform(
               %Oban.Job{args: args},
               loader: Loader,
               execution: ExecutionSuccess
             )

    refute_received :sentinel_invoked
    assert Process.get(:mailglass_inbound_worker_load_args)
    refute Process.get(:mailglass_inbound_worker_execute_opts)
  end

  test "ignores legacy route authority selectors in favor of durable evidence" do
    args = Map.put(job_with_source("fresh").args, "route_authority", "Elixir.MissingRouter")

    assert :ok =
             MailglassInbound.Execution.Worker.perform(%Oban.Job{args: args},
               loader: Loader,
               execution: ExecutionSuccess
             )

    assert Process.get(:mailglass_inbound_worker_load_args)
    assert Process.get(:mailglass_inbound_worker_execute_opts)
  end

  test "cancels pre-binding jobs once and logs tenant-scoped replay recovery" do
    log =
      capture_log(fn ->
        assert {:cancel, :permanent_failure} =
                 MailglassInbound.Execution.Worker.perform(job_with_source("fresh"),
                   loader: LegacyBindingLoader,
                   execution: ExecutionSuccess
                 )
      end)

    assert Process.get(:mailglass_inbound_worker_legacy_load_args)
    refute Process.get(:mailglass_inbound_worker_execute_opts)
    assert log =~ "durable route binding is missing"
    assert log =~ "tenant-scoped"
    assert log =~ "replay"
  end

  defp job_with_source(:absent) do
    %Oban.Job{args: Map.delete(job_with_source("fresh").args, "source")}
  end

  defp job_with_source(source) do
    %Oban.Job{
      args: %{
        "inbound_record_id" => "record-123",
        "inbound_evidence_id" => "evidence-123",
        "route_status" => "matched",
        "mailbox" => "Elixir.MailglassInbound.WorkerTest.AcceptMailbox",
        "source" => source,
        "mailglass_tenant_id" => "tenant-123"
      }
    }
  end

  def route_binding do
    %{
      "mailglass_execution_route" => %{
        "status" => "matched",
        "mailbox" => Atom.to_string(AcceptMailbox),
        "router" => Atom.to_string(Router)
      }
    }
  end
end
