defmodule Mailglass.TestSupport.TimeoutEvidenceTest do
  use ExUnit.Case, async: false

  alias Mailglass.TestSupport.TimeoutEvidence

  setup do
    keys = [
      "MAILGLASS_TIMEOUT_EVIDENCE_PATH",
      "MAILGLASS_TIMEOUT_EVIDENCE_COMMAND",
      "GITHUB_RUN_ID",
      "GITHUB_JOB",
      "GITHUB_SHA",
      "GITHUB_EVENT_NAME"
    ]

    previous = Map.new(keys, &{&1, System.get_env(&1)})

    on_exit(fn ->
      for {key, value} <- previous do
        if value, do: System.put_env(key, value), else: System.delete_env(key)
      end
    end)

    :ok
  end

  test "records an allowlisted SQLSTATE 57014 observation and re-raises the error" do
    path = temp_path("mailglass-timeout-evidence")
    on_exit(fn -> File.rm(path) end)

    System.put_env("MAILGLASS_TIMEOUT_EVIDENCE_PATH", path)

    error = %Postgrex.Error{
      message: "recipient=private@example.test statement=TRUNCATE secret_payload",
      postgres: %{
        code: :query_canceled,
        pg_code: "57014",
        severity: "ERROR",
        routine: "ProcessInterrupts",
        message: "canceling statement containing private@example.test"
      }
    }

    assert_raise Postgrex.Error, fn ->
      TimeoutEvidence.capture("webhook.iteration.truncate_webhook_events", fn -> raise error end)
    end

    [observation] = path |> File.read!() |> String.split("\n", trim: true)
    decoded = Jason.decode!(observation)

    assert decoded == %{
             "schema_version" => 1,
             "kind" => "postgres_error",
             "lane" => "database",
             "operation" => "webhook.iteration.truncate_webhook_events",
             "sqlstate" => "57014",
             "code" => "query_canceled",
             "severity" => "ERROR",
             "routine" => "ProcessInterrupts"
           }

    refute observation =~ "private@example.test"
    refute observation =~ "secret_payload"
    refute observation =~ "TRUNCATE"
  end

  test "initializes a versioned manifest bound to the exact CI identity" do
    path = temp_path("mailglass-timeout-manifest")
    on_exit(fn -> File.rm(path) end)

    System.put_env("MAILGLASS_TIMEOUT_EVIDENCE_PATH", path)
    System.put_env("MAILGLASS_TIMEOUT_EVIDENCE_COMMAND", "mix test --warnings-as-errors")
    System.put_env("GITHUB_RUN_ID", "4242")
    System.put_env("GITHUB_JOB", "core_deterministic_suite")
    System.put_env("GITHUB_SHA", String.duplicate("a", 40))
    System.put_env("GITHUB_EVENT_NAME", "pull_request")

    assert :ok = TimeoutEvidence.initialize!()

    [manifest] = path |> File.read!() |> String.split("\n", trim: true)
    decoded = Jason.decode!(manifest)

    assert Map.take(decoded, [
             "schema_version",
             "kind",
             "lane",
             "run_id",
             "job",
             "head_sha",
             "event_name",
             "command"
           ]) == %{
             "schema_version" => 1,
             "kind" => "manifest",
             "lane" => "database",
             "run_id" => "4242",
             "job" => "core_deterministic_suite",
             "head_sha" => String.duplicate("a", 40),
             "event_name" => "pull_request",
             "command" => "mix test --warnings-as-errors"
           }

    assert decoded["toolchain"] == %{
             "elixir" => System.version(),
             "otp" => System.otp_release()
           }

    assert %DateTime{} = DateTime.from_iso8601(decoded["captured_at"]) |> elem(1)
  end

  test "rejects operation labels that could carry free-form or sensitive data" do
    assert_raise ArgumentError, ~r/stable lowercase identifier/, fn ->
      TimeoutEvidence.capture("recipient=private@example.test TRUNCATE TABLE", fn -> :never end)
    end
  end

  defp temp_path(prefix) do
    Path.join(
      System.tmp_dir!(),
      "#{prefix}-#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}.ndjson"
    )
  end
end
