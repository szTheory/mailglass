defmodule Mix.Tasks.Mailglass.Inbound.ReplayTest do
  @moduledoc """
  CLI tests for `mix mailglass.inbound.replay` (IOPS-02).

  Asserts: --record-id/--since/--tenant AND-combine into the right id set; per-id
  `Internal.Replay.replay/2` invoked once each; `[y/N]` defaults No (empty/"n" ->
  no replay) unless --yes; zero matches -> exit 0 with "nothing to replay";
  --dry-run reports scope with no replay; and (real DB) a replay appends an
  ExecutionRun with source: :replay (count before/after).

  Uses `Mix.Shell.Process` to drive/assert the confirmation prompt and a stub
  `Internal.Replay` (opt-injected) to count replay/2 calls without real execution.
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.TestRepo

  # Stub replay that records every id it is asked to replay (in call order).
  defmodule StubReplay do
    def replay(id, _opts \\ []) do
      ids = Process.get(:stub_replay_ids, [])
      Process.put(:stub_replay_ids, ids ++ [id])
      {:ok, %{outcome: :accept}}
    end
  end

  defmodule FailingReplay do
    def replay(id, _opts \\ []) do
      ids = Process.get(:stub_replay_ids, [])
      Process.put(:stub_replay_ids, ids ++ [id])
      {:error, :boom}
    end
  end

  setup do
    :ok = Sandbox.checkout(TestRepo)
    Process.delete(:stub_replay_ids)
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(shell) end)
    :ok
  end

  describe "selector resolution" do
    test "--tenant scopes the id set; --yes skips the prompt" do
      {:ok, a1} = insert_record("tenant-a")
      {:ok, _a2} = insert_record("tenant-a")
      {:ok, _b1} = insert_record("tenant-b")

      run(["--tenant", "tenant-a", "--yes"])

      replayed = Process.get(:stub_replay_ids, [])
      # Exactly the two tenant-a records, never tenant-b.
      assert length(replayed) == 2
      assert a1.id in replayed
    end

    test "--record-id targets exactly one record" do
      {:ok, target} = insert_record("tenant-a")
      {:ok, _other} = insert_record("tenant-a")

      run(["--tenant", "tenant-a", "--record-id", target.id, "--yes"])

      assert Process.get(:stub_replay_ids, []) == [target.id]
    end

    test "a foreign-tenant --record-id resolves to nothing (T-49-17 cross-tenant guard)" do
      {:ok, foreign} = insert_record("tenant-b")

      assert {0, output} =
               run_with_exit(["--tenant", "tenant-a", "--record-id", foreign.id, "--yes"])

      assert output =~ "nothing to replay"
      assert Process.get(:stub_replay_ids, []) == []
    end

    test "--since AND --tenant combine (only records after the cutoff in that tenant)" do
      old_at = DateTime.add(DateTime.utc_now(), -10 * 86_400, :second)
      new_at = DateTime.utc_now()

      {:ok, _old} = insert_record("tenant-a", received_at: old_at)
      {:ok, recent} = insert_record("tenant-a", received_at: new_at)
      {:ok, _foreign_recent} = insert_record("tenant-b", received_at: new_at)

      since = DateTime.add(DateTime.utc_now(), -1 * 86_400, :second) |> DateTime.to_iso8601()
      run(["--tenant", "tenant-a", "--since", since, "--yes"])

      assert Process.get(:stub_replay_ids, []) == [recent.id]
    end
  end

  describe "confirmation tier ([y/N] default No)" do
    test "an empty/declined answer performs NO replay" do
      {:ok, _r} = insert_record("tenant-a")

      # Mix.Shell.Process: a queued :no answer makes yes?/1 return false.
      send(self(), {:mix_shell_input, :yes?, false})
      run(["--tenant", "tenant-a"])

      assert Process.get(:stub_replay_ids, []) == []
    end

    test "an affirmative answer performs the replay" do
      {:ok, r} = insert_record("tenant-a")

      send(self(), {:mix_shell_input, :yes?, true})
      run(["--tenant", "tenant-a"])

      assert Process.get(:stub_replay_ids, []) == [r.id]
    end
  end

  describe "tenant requirement (T-49-17)" do
    test "--tenant is required — omitting it is a CLI error" do
      {:ok, _r} = insert_record("tenant-a")

      assert_raise Mix.Error, ~r/--tenant <id> is required/, fn ->
        Mix.Task.reenable("mailglass.inbound.replay")

        Mix.Tasks.Mailglass.Inbound.Replay.run(["--yes", "--no-start"],
          replay: StubReplay,
          repo: TestRepo
        )
      end

      assert Process.get(:stub_replay_ids, []) == []
    end
  end

  describe "edge cases" do
    test "zero matches exits 0 with 'nothing to replay'" do
      assert {0, output} = run_with_exit(["--tenant", "tenant-empty", "--yes"])
      assert output =~ "nothing to replay"
      assert Process.get(:stub_replay_ids, []) == []
    end

    test "--dry-run reports scope and performs no replay" do
      {:ok, _r} = insert_record("tenant-a")

      {_code, output} = run_with_exit(["--tenant", "tenant-a", "--dry-run"])
      assert output =~ "1 record"
      assert Process.get(:stub_replay_ids, []) == []
    end

    test "failed replays exit non-zero after reporting the failure count" do
      {:ok, r} = insert_record("tenant-a")

      assert {1, output} =
               run_with_exit(["--tenant", "tenant-a", "--record-id", r.id, "--yes"],
                 replay: FailingReplay
               )

      assert output =~ "replay failed for #{r.id}: :boom"
      assert output =~ "Inbound replay complete: replayed=0 failed=1"
      assert Process.get(:stub_replay_ids, []) == [r.id]
    end
  end

  describe "append-only lineage (real replay)" do
    test "a replay appends an ExecutionRun with source: :replay (no UPDATE)" do
      # Real DB path: seed the durable route binding written at ingress plus a
      # prior matched fresh run, then prove replay appends rather than updates.
      {:ok, record} = insert_record("tenant-a")
      {:ok, evidence} = insert_evidence("tenant-a", record.id)

      {:ok, _fresh} =
        InboundRecords.insert_execution_run(%{
          tenant_id: "tenant-a",
          inbound_record_id: record.id,
          inbound_evidence_id: evidence.id,
          source: :fresh,
          mailbox: Atom.to_string(ReplayCaptureMailbox),
          outcome: :accept
        })

      before = TestRepo.aggregate(ExecutionRun, :count)

      send(self(), {:mix_shell_input, :yes?, true})
      # Note: no `replay:` stub here — use the real Internal.Replay.
      run_real(["--tenant", "tenant-a", "--record-id", record.id])

      after_count = TestRepo.aggregate(ExecutionRun, :count)
      assert after_count == before + 1

      [latest] =
        ExecutionRun
        |> TestRepo.all()
        |> Enum.filter(&(&1.source == :replay))

      assert latest.source == :replay
    end
  end

  defmodule ReplayCaptureMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule ReplayCaptureRouter do
    use MailglassInbound.Router

    route(ReplayCaptureMailbox, recipient: "support@example.com")
  end

  # ---- helpers --------------------------------------------------------------

  defp run(argv) do
    Mix.Task.reenable("mailglass.inbound.replay")

    catch_exit_run(argv ++ ["--no-start"], replay: StubReplay, repo: TestRepo)
  end

  defp run_real(argv) do
    Mix.Task.reenable("mailglass.inbound.replay")
    catch_exit_run(argv ++ ["--no-start"], repo: TestRepo)
  end

  defp run_with_exit(argv) do
    run_with_exit(argv, replay: StubReplay)
  end

  defp run_with_exit(argv, opts) do
    Mix.Task.reenable("mailglass.inbound.replay")
    opts = Keyword.put_new(opts, :repo, TestRepo)

    code =
      try do
        Mix.Tasks.Mailglass.Inbound.Replay.run(argv ++ ["--no-start"], opts)
        0
      catch
        :exit, {:shutdown, n} -> n
      end

    {code, shell_output()}
  end

  defp shell_output do
    drain_shell([])
  end

  defp drain_shell(acc) do
    receive do
      {:mix_shell, kind, [msg]} when kind in [:info, :error] -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end

  defp catch_exit_run(argv, opts) do
    ExUnit.CaptureIO.capture_io(fn ->
      try do
        Mix.Tasks.Mailglass.Inbound.Replay.run(argv, opts)
      catch
        :exit, {:shutdown, _n} -> :ok
      end
    end)
  end

  defp insert_record(tenant_id, opts \\ []) do
    InboundRecords.insert_inbound_record(%{
      tenant_id: tenant_id,
      provider: "postmark",
      provider_message_id: "pmid-#{System.unique_integer([:positive])}",
      envelope_recipient: "support@example.com",
      subject: "Replay fixture",
      received_at: Keyword.get(opts, :received_at, DateTime.utc_now())
    })
  end

  defp insert_evidence(tenant_id, record_id) do
    InboundRecords.insert_inbound_evidence(%{
      tenant_id: tenant_id,
      inbound_record_id: record_id,
      provider: "postmark",
      raw_payload: %{"ok" => true},
      verification_facts: %{
        "mailglass_execution_route" => %{
          "status" => "matched",
          "mailbox" => Atom.to_string(ReplayCaptureMailbox),
          "router" => Atom.to_string(ReplayCaptureRouter)
        }
      }
    })
  end
end
