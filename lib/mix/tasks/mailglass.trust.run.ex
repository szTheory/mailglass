defmodule Mix.Tasks.Mailglass.Trust.Run do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  @shortdoc "Run deterministic reference-host trust stages"

  @moduledoc since: "1.3.0"
  @moduledoc """
  Run the canonical deterministic trust-runner stage pipeline.

  This task is the only supported journey orchestrator entrypoint for local and CI
  trust checks in Phase 57.

  ## Usage

      mix mailglass.trust.run
      mix mailglass.trust.run --dry-run
      mix mailglass.trust.run --host-root reference/host_app
      mix mailglass.trust.run --checkpoint-out tmp/mailglass_trust_runner/checkpoint.json

  ## Options

    * `--checkpoint-out` - optional JSON output path for deterministic stage records.
    * `--host-root` - reference host app root (defaults to `reference/host_app`).
    * `--dry-run` - emits deterministic stage records without running stage checks.
  """

  @stage_pipeline [:install, :preview, :send, :webhook_ingest, :operator_troubleshooting]
  @allowed_statuses ["completed", "dry_run"]

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [checkpoint_out: :string, host_root: :string, dry_run: :boolean]
      )

    validate_cli!(opts, rest, invalid)

    host_root =
      opts
      |> Keyword.get(:host_root, "reference/host_app")
      |> Path.expand(File.cwd!())

    checkpoint_out =
      opts
      |> Keyword.get(:checkpoint_out)
      |> resolve_optional_path()

    dry_run? = opts[:dry_run] == true

    ensure_host_root!(host_root)

    stage_records =
      host_root
      |> build_stage_records(dry_run?)
      |> validate_stage_records!()

    write_checkpoint(checkpoint_out, host_root, dry_run?, stage_records)
    emit_stage_records(stage_records, checkpoint_out)
  end

  defp validate_cli!(opts, rest, invalid) do
    if rest != [] do
      runner_error!("unexpected positional arguments #{Enum.join(rest, " ")}")
    end

    if invalid != [] do
      invalid_flags =
        invalid
        |> Enum.map(fn {key, _value} -> "--#{key}" end)
        |> Enum.join(", ")

      runner_error!("unknown option(s) #{invalid_flags}")
    end

    for {key, value} <- [host_root: opts[:host_root], checkpoint_out: opts[:checkpoint_out]] do
      if is_binary(value) and String.trim(value) == "" do
        runner_error!("--#{key |> to_string() |> String.replace("_", "-")} cannot be blank")
      end
    end

    :ok
  end

  defp resolve_optional_path(nil), do: nil
  defp resolve_optional_path(path), do: Path.expand(path, File.cwd!())

  defp ensure_host_root!(host_root) do
    unless File.dir?(host_root) do
      runner_error!("host root not found at #{host_root}")
    end
  end

  defp build_stage_records(host_root, dry_run?) do
    Enum.map(@stage_pipeline, fn stage_key ->
      signal = stage_signal(stage_key, host_root, dry_run?)

      if is_nil(signal) do
        runner_error!("missing required stage signal #{inspect(stage_key)}")
      end

      %{
        "stage_key" => Atom.to_string(stage_key),
        "status" => signal_to_status(signal)
      }
    end)
  end

  defp stage_signal(_stage_key, _host_root, true), do: :dry_run

  defp stage_signal(:install, host_root, false) do
    require_file!(host_root, "mix.exs", :install)
    :verified
  end

  defp stage_signal(:preview, host_root, false) do
    require_file!(host_root, "README.md", :preview)
    :verified
  end

  defp stage_signal(:send, host_root, false) do
    require_file!(host_root, "lib/mailglass_reference_host_web/router.ex", :send)
    :verified
  end

  defp stage_signal(:webhook_ingest, host_root, false) do
    require_file!(host_root, "config/runtime.exs", :webhook_ingest)
    :verified
  end

  defp stage_signal(:operator_troubleshooting, host_root, false) do
    require_file!(host_root, "SCOPE.md", :operator_troubleshooting)
    :verified
  end

  defp stage_signal(_stage_key, _host_root, false), do: nil

  defp signal_to_status(:verified), do: "completed"
  defp signal_to_status(:dry_run), do: "dry_run"
  defp signal_to_status(_other), do: nil

  defp require_file!(host_root, relative_path, stage_key) do
    file_path = Path.join(host_root, relative_path)

    unless File.exists?(file_path) do
      runner_error!(
        "missing required stage signal #{inspect(stage_key)} (expected file #{relative_path} under #{host_root})"
      )
    end
  end

  defp validate_stage_records!(stage_records) do
    expected_stage_keys = Enum.map(@stage_pipeline, &Atom.to_string/1)
    actual_stage_keys = Enum.map(stage_records, &Map.fetch!(&1, "stage_key"))

    if actual_stage_keys != expected_stage_keys do
      runner_error!(
        "deterministic stage order drifted. expected #{inspect(expected_stage_keys)}, got #{inspect(actual_stage_keys)}"
      )
    end

    Enum.each(expected_stage_keys, fn stage_key ->
      unless Enum.any?(stage_records, &(&1["stage_key"] == stage_key)) do
        runner_error!("missing required stage signal #{inspect(stage_key)}")
      end
    end)

    case Enum.find(stage_records, &(&1["status"] not in @allowed_statuses)) do
      nil ->
        stage_records

      stage_record ->
        runner_error!(
          "invalid stage status #{inspect(stage_record["status"])} for #{inspect(stage_record["stage_key"])}"
        )
    end
  end

  defp write_checkpoint(nil, _host_root, _dry_run?, _stage_records), do: :ok

  defp write_checkpoint(checkpoint_out, host_root, dry_run?, stage_records) do
    payload = %{
      "generated_by" => "mailglass.trust.run",
      "host_root" => host_root,
      "dry_run" => dry_run?,
      "stage_count" => length(stage_records),
      "stages" => stage_records
    }

    checkpoint_out
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(checkpoint_out, Jason.encode_to_iodata!(payload, pretty: true))
  end

  defp emit_stage_records(stage_records, checkpoint_out) do
    Enum.each(stage_records, fn stage_record ->
      Mix.shell().info(
        "trust_runner stage=#{stage_record["stage_key"]} status=#{stage_record["status"]}"
      )
    end)

    if checkpoint_out do
      Mix.shell().info("trust_runner checkpoint_out=#{checkpoint_out}")
    end
  end

  defp runner_error!(message), do: Mix.raise("Trust runner blocked: #{message}")
end
