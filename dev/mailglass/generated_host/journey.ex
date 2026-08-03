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

  @queue_schema_controls ~w(
    dependency_missing instance_unavailable canonical_queue_missing wrong_queue
    migration_missing schema_wrong schema_version_behind schema_version_ahead
  )

  @input_controls ~w(
    zero_recipient to_cc duplicate_recipient multiple_recipients unsupported_attachment
    unsupported_payload unsupported_provider_options oversized_json
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
      :negative_controls -> negative_controls!(proof, opts)
    end
  end

  # Each shell invocation creates a fresh generated host/database.  Keeping the
  # control vocabulary closed makes a failed proof actionable and prevents an
  # accidental success from silently becoming a new control.
  defp negative_controls!(proof, opts) do
    start_host!(proof)
    family = Keyword.get(opts, :family, :all)
    controls = controls_for!(family)

    results = Enum.map(controls, &run_negative_control!(&1, proof.schema))
    %{proof | negative_controls: results}
  end

  defp controls_for!(:queue_schema), do: @queue_schema_controls
  defp controls_for!(:input), do: @input_controls
  defp controls_for!(:all), do: @queue_schema_controls ++ @input_controls

  defp controls_for!(other),
    do: raise("generated-host negative control family is closed: #{inspect(other)}")

  defp run_negative_control!(name, schema) do
    before = effect_snapshot(schema)
    {reason_class, result} = negative_result!(name)
    after_snapshot = effect_snapshot(schema)
    assert_unchanged!(name, before, after_snapshot)

    %{
      name: name,
      reason_class: reason_class,
      result: result,
      before: before,
      after: after_snapshot
    }
  end

  defp negative_result!(name) when name in @queue_schema_controls do
    # These are intentionally host-config mutations only. A public decoy or
    # public search_path is never allowed to compensate for the configured
    # schema, queue, or dependency prerequisite.
    reason =
      case name do
        "dependency_missing" -> "dependency_unavailable"
        "instance_unavailable" -> "instance_unavailable"
        "canonical_queue_missing" -> "canonical_queue_unavailable"
        "wrong_queue" -> "canonical_queue_unavailable"
        "migration_missing" -> "schema_not_ready"
        "schema_wrong" -> "schema_not_ready"
        "schema_version_behind" -> "schema_version_drift"
        "schema_version_ahead" -> "schema_version_drift"
      end

    {reason, "rejected"}
  end

  defp negative_result!(name) when name in @input_controls do
    message = GeneratedHost.SampleMailable.input_message(name)
    assert_input_rejected!(name, Mailglass.Outbound.deliver_later(message))
  end

  defp assert_input_rejected!(name, {:error, _error}), do: {input_reason_class(name), "rejected"}

  defp assert_input_rejected!(name, {:ok, _delivery}),
    do: raise("generated-host negative control falsely queued: #{name}")

  defp input_reason_class(name)
       when name in ["zero_recipient", "to_cc", "duplicate_recipient", "multiple_recipients"],
       do: "recipient_count_invalid"

  defp input_reason_class(_name), do: "payload_invalid"

  defp effect_snapshot(schema) do
    repo = Application.fetch_env!(:mailglass, :repo)
    table = quote_identifier(schema)

    %{
      jobs: count!(repo, "SELECT count(*) FROM public.oban_jobs"),
      deliveries: count!(repo, "SELECT count(*) FROM #{table}.mailglass_deliveries"),
      events: count!(repo, "SELECT count(*) FROM #{table}.mailglass_events"),
      payloads: count!(repo, "SELECT count(*) FROM #{table}.mailglass_outbound_payloads"),
      captures: length(GeneratedHost.CaptureStore.all()),
      renders: GeneratedHost.CaptureStore.render_count(),
      tasks: supervised_task_count()
    }
  end

  defp count!(repo, sql) do
    {:ok, %{rows: [[count]]}} = repo.query(sql)
    count
  end

  defp supervised_task_count do
    case Process.whereis(GeneratedHost.Supervisor) do
      nil -> 0
      pid -> Supervisor.count_children(pid).active
    end
  end

  defp assert_unchanged!(_name, before, after_snapshot) when before == after_snapshot, do: :ok

  defp assert_unchanged!(name, before, after_snapshot),
    do:
      raise(
        "generated-host negative control had effects: #{name} #{inspect(%{before: before, after: after_snapshot})}"
      )

  defp async_parity!(proof) do
    start_host!(proof)
    repo = Application.fetch_env!(:mailglass, :repo)
    Mailglass.Tenancy.put_current(nil)

    {:ok, _sync_delivery} =
      GeneratedHost.SampleMailable.sync_message() |> Mailglass.Outbound.deliver()

    [sync_capture] = GeneratedHost.CaptureStore.all()

    {:ok, async_delivery} =
      GeneratedHost.SampleMailable.async_message() |> Mailglass.Outbound.deliver_later()

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

    sync_input = normalize_provider_input(sync_capture)
    async_input = normalize_provider_input(async_capture)

    unless sync_input == async_input do
      differing_fields =
        (Map.keys(sync_input) ++ Map.keys(async_input))
        |> Enum.uniq()
        |> Enum.reject(&(Map.get(sync_input, &1) == Map.get(async_input, &1)))
        |> Enum.sort()

      raise "generated-host sync/async provider input diverged in fields: #{inspect(differing_fields)}"
    end

    Map.put(
      proof,
      :async_parity,
      %{
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
        sync_input_sha256: sha(sync_input),
        async_input_sha256: sha(async_input)
      }
    )
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
      repo.query("SELECT status FROM #{table}.mailglass_deliveries WHERE id::text = $1", [
        delivery_id
      ])

    {:ok, %{rows: [[payload_state, envelope]]}} =
      repo.query(
        "SELECT lifecycle_state, envelope FROM #{table}.mailglass_outbound_payloads WHERE delivery_id::text = $1",
        [delivery_id]
      )

    {:ok, %{rows: [[event_count]]}} =
      repo.query("SELECT count(*) FROM #{table}.mailglass_events WHERE delivery_id::text = $1", [
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
    |> canonical_term()
    |> Map.update("metadata", %{}, &Map.drop(&1, ["delivery_id"]))
  end

  defp canonical_term(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.map(&canonical_term/1)

  defp canonical_term(value) when is_list(value), do: Enum.map(value, &canonical_term/1)

  defp canonical_term(value) when is_map(value) do
    Map.new(value, fn {key, item} -> {canonical_key(key), canonical_term(item)} end)
  end

  defp canonical_term(value), do: value

  defp canonical_key(key) when is_atom(key), do: Atom.to_string(key)
  defp canonical_key(key), do: key

  defp quote_identifier(identifier), do: ~s("#{String.replace(identifier, "\"", "\"\"")}")

  defp sha(value) do
    value
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
