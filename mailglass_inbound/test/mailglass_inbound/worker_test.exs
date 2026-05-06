defmodule MailglassInbound.WorkerTest do
  use ExUnit.Case, async: false

  defmodule Loader do
    def load(%{"inbound_record_id" => record_id, "inbound_evidence_id" => evidence_id, "source" => source}) do
      Process.put(:mailglass_inbound_worker_load_args, {record_id, evidence_id, source})

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

  test "restores tenancy-safe worker args and returns :ok for successful executions" do
    job = %Oban.Job{
      args: %{
        "inbound_record_id" => "record-123",
        "inbound_evidence_id" => "evidence-123",
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
             {"record-123", "evidence-123", "fresh"}

    assert Keyword.get(Process.get(:mailglass_inbound_worker_execute_opts, []), :source) == :fresh
  end

  test "maps failed shared execution outcomes to retryable oban errors" do
    job = %Oban.Job{
      args: %{
        "inbound_record_id" => "record-123",
        "inbound_evidence_id" => "evidence-123",
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
end
