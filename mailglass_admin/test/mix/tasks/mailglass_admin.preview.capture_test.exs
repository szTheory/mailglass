defmodule Mix.Tasks.MailglassAdmin.Preview.CaptureTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task_name "mailglass_admin.preview.capture"

  describe "mix mailglass_admin.preview.capture" do
    test "dry-run prints deterministic matrix plan for explicit mailables" do
      output_dir = tmp_output_dir("dry-run")

      output =
        run_task!([
          "--dry-run",
          "--base-url",
          "http://localhost:4000/dev/mail",
          "--output-dir",
          output_dir,
          "--theme",
          "dark",
          "--widths",
          "768,375",
          "--mailables",
          "MailglassAdmin.Fixtures.HappyMailer,MailglassAdmin.Fixtures.StubMailer"
        ])

      assert output =~ "Preview capture dry-run"
      assert output =~ "matrix entries: 4"
      assert output =~ "width(s): 375, 768"
      assert output =~ "theme(s): dark"
      assert output =~ "MailglassAdmin.Fixtures.HappyMailer:welcome_default width=375 theme=dark"
      assert output =~ "MailglassAdmin.Fixtures.HappyMailer:welcome_enterprise width=768 theme=dark"
      assert output =~ "skipped: 1"
      assert output =~ "MailglassAdmin.Fixtures.StubMailer -> no_previews"
      refute File.exists?(output_dir)
    end

    test "rejects unknown flags loudly" do
      assert_raise Mix.Error, ~r/unknown option\(s\)/, fn ->
        run_task!(["--wat"])
      end
    end

    test "rejects positional args loudly" do
      assert_raise Mix.Error, ~r/unexpected positional arguments/, fn ->
        run_task!(["extra"])
      end
    end

    test "rejects unsupported widths loudly" do
      assert_raise Mix.Error, ~r/unsupported widths 999/, fn ->
        run_task!(["--widths", "999"])
      end
    end

    test "rejects unsupported theme loudly" do
      assert_raise Mix.Error, ~r/unsupported theme/, fn ->
        run_task!(["--theme", "sepia"])
      end
    end
  end

  defp run_task!(argv) do
    Mix.Task.reenable(@task_name)
    Mix.Task.reenable("app.start")

    capture_io(fn ->
      Mix.Tasks.MailglassAdmin.Preview.Capture.run(argv)
    end)
  end

  defp tmp_output_dir(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "mailglass-admin-preview-capture-#{suffix}-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(path)
    path
  end
end
