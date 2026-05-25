defmodule Mix.Tasks.Mailglass.Inbound.PruneTest do
  @moduledoc """
  CLI tests for `mix mailglass.inbound.prune` (IOPS-03).

  Asserts the task runs `Internal.Prune.prune/0` SYNCHRONOUSLY whether or not
  Oban is present (no exit-1-when-Oban-absent gate — D-49-28), `--dry-run` reports
  scope without deleting, the destructive typed-confirmation tier (D-49-10), and
  `--yes` skips the prompt.

  A stub prune (opt-injected) records invocations so we can prove the task always
  calls `prune/0` (no Oban gate) and never calls it under `--dry-run`.
  """

  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.TestRepo

  defmodule StubPrune do
    def prune do
      Process.put(:stub_prune_called, true)

      {:ok,
       %{
         records_deleted: 3,
         evidence_deleted: 2,
         fresh_runs_deleted: 1,
         replay_runs_deleted: 1,
         status: :ok
       }}
    end
  end

  setup do
    :ok = Sandbox.checkout(TestRepo, sandbox: false)
    Process.delete(:stub_prune_called)
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(shell) end)
    :ok
  end

  describe "runs synchronously regardless of Oban" do
    test "--yes runs prune/0 with no Oban-availability gate" do
      run(["--yes"])
      assert Process.get(:stub_prune_called) == true
    end

    test "an affirmative typed confirmation runs prune/0" do
      send(self(), {:mix_shell_input, :prompt, "yes"})
      run([])
      assert Process.get(:stub_prune_called) == true
    end

    test "a declined confirmation does NOT run prune/0" do
      send(self(), {:mix_shell_input, :prompt, "no"})
      run([])
      assert Process.get(:stub_prune_called) != true
    end
  end

  describe "--dry-run" do
    test "reports scope and never invokes prune/0" do
      {_code, output} = run_with_io(["--dry-run"])
      assert Process.get(:stub_prune_called) != true
      assert output =~ ~r/dry.?run/i or output =~ "would"
    end
  end

  describe "output" do
    test "--yes prints per-table deletion counts" do
      {_code, output} = run_with_io(["--yes"])
      assert output =~ "records"
      assert output =~ "3"
    end
  end

  # ---- helpers --------------------------------------------------------------

  defp run(argv) do
    Mix.Task.reenable("mailglass.inbound.prune")

    try do
      Mix.Tasks.Mailglass.Inbound.Prune.run(argv ++ ["--no-start"],
        prune: StubPrune,
        repo: TestRepo
      )
    catch
      :exit, {:shutdown, _n} -> :ok
    end
  end

  defp run_with_io(argv) do
    Mix.Task.reenable("mailglass.inbound.prune")

    {code, output} =
      ExUnit.CaptureIO.with_io(fn ->
        try do
          Mix.Tasks.Mailglass.Inbound.Prune.run(argv ++ ["--no-start"],
            prune: StubPrune,
            repo: TestRepo
          )
          0
        catch
          :exit, {:shutdown, n} -> n
        end
      end)

    {code, output}
  end
end
