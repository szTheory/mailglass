defmodule MailglassAdmin.TestSupport.BrowserTimeoutEvidenceTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestSupport.BrowserTimeoutEvidence

  setup do
    previous = System.get_env("MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH")

    on_exit(fn ->
      if previous do
        System.put_env("MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH", previous)
      else
        System.delete_env("MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH")
      end
    end)

    :ok
  end

  test "records only a stable readiness stage and monotonic elapsed time" do
    path =
      Path.join(
        System.tmp_dir!(),
        "mailglass-browser-stage-#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}.ndjson"
      )

    on_exit(fn -> File.rm(path) end)
    System.put_env("MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH", path)

    assert :ok = BrowserTimeoutEvidence.record("fixtures_seeded", 1_234)

    assert path |> File.read!() |> String.trim() |> Jason.decode!() == %{
             "schema_version" => 1,
             "kind" => "stage",
             "lane" => "browser",
             "stage" => "fixtures_seeded",
             "elapsed_ms" => 1_234
           }
  end

  test "rejects free-form stage labels before writing evidence" do
    assert_raise ArgumentError, ~r/stable lowercase identifier/, fn ->
      BrowserTimeoutEvidence.record("recipient=private@example.test", 1)
    end
  end
end
