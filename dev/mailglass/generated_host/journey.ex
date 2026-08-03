defmodule Mailglass.GeneratedHost.Journey do
  @moduledoc false
  @compile {:no_warn_undefined, [GeneratedHost.CaptureStore, GeneratedHost.SampleMailable]}

  alias Mailglass.GeneratedHost.HostTemplate

  @mailglass_tables ~w(
    mailglass_events
    mailglass_deliveries
    mailglass_outbound_payloads
    mailglass_suppressions
    mailglass_webhook_events
  )

  @spec run!(keyword()) :: map()
  def run!(opts \\ []) do
    schema = Keyword.fetch!(opts, :schema)
    stage = Keyword.get(opts, :stage, :migrate)

    HostTemplate.install!(File.cwd!(), schema)
    Application.put_env(:mailglass, :repo, GeneratedHost.Repo)
    Application.put_env(:mailglass, :schema, schema)

    run_mix!(["mailglass.gen.migration"])
    run_mix!(["ecto.create"])
    run_mix!(["ecto.migrate"])

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.fetch_env!(:mailglass, :repo).start_link()
    proof = migration_proof!(schema)

    case stage do
      :migrate -> proof
      :boot -> start_host!(proof)
      :async_parity -> async_parity!(proof)
    end
  end

  defp async_parity!(proof) do
    start_host!(proof)
    repo = Application.fetch_env!(:mailglass, :repo)
    Mailglass.Tenancy.put_current(nil)

    {:ok, _sync_delivery} = GeneratedHost.SampleMailable.message() |> Mailglass.Outbound.deliver()
    [sync_capture] = GeneratedHost.CaptureStore.all()

    {:ok, async_delivery} =
      GeneratedHost.SampleMailable.message() |> Mailglass.Outbound.deliver_later()

    inserted_job = inserted_job!(repo, async_delivery.id)

    settled =
      poll_until!(fn ->
        captures = GeneratedHost.CaptureStore.all()

        case terminal_snapshot(repo, proof.schema, async_delivery.id, inserted_job.id, captures) do
          %{terminal?: true} = snapshot -> {:ok, snapshot}
          _ -> :retry
        end
      end)

    [^sync_capture, async_capture] = GeneratedHost.CaptureStore.all()

    unless normalize_provider_input(sync_capture) == normalize_provider_input(async_capture) do
      raise "generated-host sync/async provider input diverged"
    end

    %{
      proof
      | async_parity: %{
          job_inserted: true,
          job_terminal: settled.job_terminal,
          delivery_sent: settled.delivery_sent,
          payload_scrubbed: settled.payload_scrubbed,
          event_count: settled.event_count,
          capture_count: settled.capture_count,
          transition_order: [
            "job_inserted",
            "capture_recorded",
            "delivery_settled",
            "payload_scrubbed"
          ],
          sync_input_sha256: sha(normalize_provider_input(sync_capture)),
          async_input_sha256: sha(normalize_provider_input(async_capture))
        }
    }
  end

  defp start_host!(proof) do
    repo = Application.fetch_env!(:mailglass, :repo)
    :ok = repo.stop()
    {:ok, _} = Application.ensure_all_started(:generated_host)
    proof
  end

  defp run_mix!(args) do
    {output, status} = System.cmd("mix", args, stderr_to_stdout: true)

    if status != 0 do
      raise "generated-host command failed (#{Enum.join(args, " ")}): #{output}"
    end
  end

  defp migration_proof!(schema) do
    repo = Application.fetch_env!(:mailglass, :repo)

    {:ok, %{rows: rows}} =
      repo.query(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = $1 AND table_name = ANY($2)
        ORDER BY table_name
        """,
        [schema, @mailglass_tables]
      )

    actual_tables = Enum.map(rows, &hd/1) |> Enum.sort()
    expected_tables = Enum.sort(@mailglass_tables)

    if actual_tables != expected_tables do
      raise "generated-host migration table inventory drifted: #{inspect(actual_tables)}"
    end

    {:ok, %{rows: [[public_count]]}} =
      repo.query(
        "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = ANY($1)",
        [@mailglass_tables]
      )

    if public_count != 0 do
      raise "generated-host migration leaked Mailglass tables into public"
    end

    version = Mailglass.Migration.migrated_version()
    if version != 7, do: raise("generated-host migration version drifted: #{version}")

    %{schema: schema, tables: actual_tables, migrated_version: version}
  end

  defp inserted_job!(repo, delivery_id) do
    {:ok, %{rows: [[id, state]]}} =
      repo.query(
        "SELECT id, state FROM public.oban_jobs WHERE queue = $1 AND args->>'delivery_id' = $2 ORDER BY id DESC LIMIT 1",
        ["mailglass_outbound", delivery_id]
      )

    if state not in ["available", "scheduled", "executing", "completed"] do
      raise "generated-host Oban job was not inserted into normal queue"
    end

    %{id: id, state: state}
  end

  defp terminal_snapshot(repo, schema, delivery_id, job_id, captures) do
    table = quote_identifier(schema)

    {:ok, %{rows: [[job_state]]}} =
      repo.query("SELECT state FROM public.oban_jobs WHERE id = $1", [job_id])

    {:ok, %{rows: [[delivery_status]]}} =
      repo.query("SELECT status FROM #{table}.mailglass_deliveries WHERE id = $1::uuid", [
        delivery_id
      ])

    {:ok, %{rows: [[payload_state, envelope]]}} =
      repo.query(
        "SELECT lifecycle_state, envelope FROM #{table}.mailglass_outbound_payloads WHERE delivery_id = $1::uuid",
        [delivery_id]
      )

    {:ok, %{rows: [[event_count]]}} =
      repo.query("SELECT count(*) FROM #{table}.mailglass_events WHERE delivery_id = $1::uuid", [
        delivery_id
      ])

    %{
      terminal?:
        job_state == "completed" and delivery_status == "sent" and payload_state == "scrubbed" and
          is_nil(envelope) and event_count >= 2 and length(captures) >= 2,
      job_terminal: job_state == "completed",
      delivery_sent: delivery_status == "sent",
      payload_scrubbed: payload_state == "scrubbed" and is_nil(envelope),
      event_count: event_count,
      capture_count: length(captures)
    }
  end

  defp poll_until!(fun, attempts \\ 100)

  defp poll_until!(_fun, 0),
    do: raise("generated-host async proof timed out while polling normal Oban")

  defp poll_until!(fun, attempts) do
    case fun.() do
      {:ok, value} ->
        value

      :retry ->
        Process.sleep(50)
        poll_until!(fun, attempts - 1)
    end
  end

  defp normalize_provider_input(input) do
    input
    |> Map.drop([:provider_message_id])
    |> :erlang.term_to_binary()
  end

  defp quote_identifier(identifier), do: ~s("#{String.replace(identifier, "\"", "\"\"")}")
  defp sha(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
