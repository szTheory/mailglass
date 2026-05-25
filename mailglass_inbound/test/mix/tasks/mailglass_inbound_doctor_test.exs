defmodule Mix.Tasks.Mailglass.Inbound.DoctorTest do
  @moduledoc """
  CLI tests for `mix mailglass.inbound.doctor` (IOPS-01, MIME-03).

  Asserts the THREE-STATE exit code explicitly (Pitfall 6):

    * 0 = all pass (or pass+warn without --strict)
    * 1 = >= 1 fail (or any warn under --strict)
    * 2 = cannot-diagnose (no router configured)

  Plus human/JSON output parity and CLI-misuse Mix.raise (bad --format).
  The router is supplied via `:mailglass_inbound, :router` app env (set per test,
  restored on_exit) so the task reflects a fixture router DNS-free.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO, only: [capture_io: 1, with_io: 1]

  defmodule GoodMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule CleanRouter do
    use MailglassInbound.Router
    route(Mix.Tasks.Mailglass.Inbound.DoctorTest.GoodMailbox, recipient: "support@example.com")
  end

  defmodule SubsumptionRouter do
    use MailglassInbound.Router
    route(Mix.Tasks.Mailglass.Inbound.DoctorTest.GoodMailbox, recipient: nil)
    route(Mix.Tasks.Mailglass.Inbound.DoctorTest.GoodMailbox, recipient: "specific@example.com")
  end

  defmodule WarnRouter do
    # regex-vs-regex overlap -> a single :warn finding, no :fail.
    use MailglassInbound.Router
    route(Mix.Tasks.Mailglass.Inbound.DoctorTest.GoodMailbox, recipient: ~r/support@.*/)
    route(Mix.Tasks.Mailglass.Inbound.DoctorTest.GoodMailbox, recipient: ~r/.*@example\.com/)
  end

  setup do
    prior = Application.get_env(:mailglass_inbound, :router)
    on_exit(fn -> restore(:router, prior) end)
    :ok
  end

  describe "exit codes (three-state)" do
    test "exits 0 when all checks pass" do
      Application.put_env(:mailglass_inbound, :router, CleanRouter)

      assert {0, _output} = run_task([])
    end

    test "exits 1 when a check fails (broad-before-narrow subsumption)" do
      Application.put_env(:mailglass_inbound, :router, SubsumptionRouter)

      assert {1, _output} = run_task([])
    end

    test "exits 0 on warnings without --strict" do
      Application.put_env(:mailglass_inbound, :router, WarnRouter)

      assert {0, _output} = run_task([])
    end

    test "exits 1 on warnings WITH --strict (warn promotes to fail)" do
      Application.put_env(:mailglass_inbound, :router, WarnRouter)

      assert {1, _output} = run_task(["--strict"])
    end

    test "exits 2 (cannot-diagnose) when no router is configured" do
      Application.delete_env(:mailglass_inbound, :router)

      assert {2, _output} = run_task([])
    end
  end

  describe "output formats" do
    test "human output includes a summary line with pass/warn/fail" do
      Application.put_env(:mailglass_inbound, :router, CleanRouter)

      {_code, output} = run_task([])
      assert output =~ "pass"
      assert output =~ "warn"
      assert output =~ "fail"
    end

    test "json output is one parseable object with summary + findings (parity)" do
      Application.put_env(:mailglass_inbound, :router, CleanRouter)

      {_code, output} = run_task(["--format", "json"])
      decoded = Jason.decode!(output)

      assert %{"summary" => summary, "findings" => findings} = decoded
      assert Map.has_key?(summary, "pass")
      assert Map.has_key?(summary, "warn")
      assert Map.has_key?(summary, "fail")
      assert is_list(findings)
    end
  end

  describe "CLI misuse" do
    test "an invalid --format raises Mix.Error (not a findings exit)" do
      Application.put_env(:mailglass_inbound, :router, CleanRouter)

      assert_raise Mix.Error, ~r/format/i, fn ->
        run_task!(["--format", "yaml"])
      end
    end

    test "an unexpected positional argument raises Mix.Error" do
      Application.put_env(:mailglass_inbound, :router, CleanRouter)

      assert_raise Mix.Error, fn ->
        run_task!(["surprise"])
      end
    end
  end

  # ---- helpers --------------------------------------------------------------

  # Runs the task, capturing stdout and the {:shutdown, N} exit code.
  defp run_task(argv) do
    Mix.Task.reenable("mailglass.inbound.doctor")
    Mix.Task.reenable("app.start")

    {code, output} =
      with_io(fn ->
        try do
          Mix.Tasks.Mailglass.Inbound.Doctor.run(argv)
          0
        catch
          :exit, {:shutdown, n} -> n
        end
      end)

    {code, String.trim_trailing(output)}
  end

  # Runs the task WITHOUT swallowing Mix.Error (for CLI-misuse assertions).
  defp run_task!(argv) do
    Mix.Task.reenable("mailglass.inbound.doctor")
    Mix.Task.reenable("app.start")

    capture_io(fn -> Mix.Tasks.Mailglass.Inbound.Doctor.run(argv) end)
  end

  defp restore(key, nil), do: Application.delete_env(:mailglass_inbound, key)
  defp restore(key, value), do: Application.put_env(:mailglass_inbound, key, value)
end
