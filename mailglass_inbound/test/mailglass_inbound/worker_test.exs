defmodule MailglassInbound.WorkerTest do
  use ExUnit.Case, async: false

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
         inbound_evidence: %{id: evidence_id}
       }}
    end
  end

  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
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
         inbound_evidence: %{id: "evidence-123"}
       }}
    end
  end

  defmodule SourceExecution do
    def execute(_persisted, opts \\ []) do
      Process.put(:mailglass_inbound_worker_source_execute_opts, opts)
      {:ok, %{outcome: :accept}}
    end
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
end
