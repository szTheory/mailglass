defmodule Mailglass.GeneratedHost.Journey do
  @moduledoc false
  @compile {:no_warn_undefined,
            [GeneratedHost.CaptureStore, GeneratedHost.SampleMailable, GeneratedHostWeb.Endpoint]}

  alias Mailglass.GeneratedHost.HostTemplate

  @mailglass_tables ~w(
    mailglass_events
    mailglass_deliveries
    mailglass_outbound_payloads
    mailglass_suppressions
    mailglass_webhook_events
  )

  @queue_schema_controls ~w(
    instance_unavailable schema_wrong
  )

  @input_controls ~w(
    zero_recipient to_cc duplicate_recipient multiple_recipients unsupported_attachment
    unsupported_payload unsupported_provider_options oversized_json
  )

  # No @spec: every stage adds a different closed set of proof keys. With the
  # repository's :underspecs Dialyzer flag, `map()` is an inaccurate supertype
  # of that inferred union. Dialyzer still infers and checks every call site.
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
      :docs -> start_host!(proof)
      :async_parity -> async_parity!(proof)
      :negative_controls -> negative_controls!(proof, opts)
      :feedback -> feedback!(proof)
      :feedback_unsubscribe -> proof |> feedback!() |> one_click!()
      :readiness -> operator_readiness!(proof)
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
    Map.put(proof, :negative_controls, results)
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

  # These controls are deliberately limited to failures this running generated
  # host can truthfully create. Optional dependency absence and alternate Oban
  # queue configurations require a separately built host, so they are not
  # represented as successful evidence here.
  defp negative_result!("instance_unavailable") do
    message = generated_host_call!([GeneratedHost, SampleMailable], :async_message)

    with_mailglass_env(:async_adapter, :unavailable_adapter, fn ->
      case Mailglass.Outbound.deliver_later(message) do
        {:error,
         %Mailglass.SendError{
           type: :adapter_failure,
           context: %{reason_class: :instance_unavailable}
         }} ->
          {"instance_unavailable", "rejected"}

        other ->
          raise "generated-host unavailable-instance control returned #{inspect(other)}"
      end
    end)
  end

  defp negative_result!("schema_wrong") do
    wrong_schema = "generated_host_missing_#{System.unique_integer([:positive])}"

    try do
      with_mailglass_env(:schema, wrong_schema, fn ->
        :persistent_term.erase({Mailglass.Config, :schema})
        readiness = Mailglass.ProductionPreflight.run()

        case Enum.find(readiness.checks, &(&1.id == :schema_access)) do
          %{status: :failed} -> {"schema_access_failed", "rejected"}
          other -> raise "generated-host wrong-schema control returned #{inspect(other)}"
        end
      end)
    after
      :persistent_term.erase({Mailglass.Config, :schema})
    end
  end

  defp negative_result!(name) when name in @input_controls do
    message = generated_host_call!([GeneratedHost, SampleMailable], :input_message, [name])
    assert_input_rejected!(name, Mailglass.Outbound.deliver_later(message))
  end

  defp with_mailglass_env(key, value, fun) when is_function(fun, 0) do
    previous = Application.get_env(:mailglass, key, :__missing__)
    Application.put_env(:mailglass, key, value)

    try do
      fun.()
    after
      if previous == :__missing__,
        do: Application.delete_env(:mailglass, key),
        else: Application.put_env(:mailglass, key, previous)
    end
  end

  defp assert_input_rejected!(name, {:error, %Mailglass.SendError{} = error}) do
    {type, reason_class} = input_error_shape(name)

    unless error.type == type and error.context[:reason_class] == reason_class do
      raise(
        "generated-host input control returned the wrong error: #{name} #{inspect(error)}"
      )
    end

    {Atom.to_string(reason_class), "rejected"}
  end

  defp assert_input_rejected!(name, other),
    do: raise("generated-host input control was not rejected: #{name} #{inspect(other)}")

  defp input_error_shape(name)
       when name in ["zero_recipient", "to_cc", "duplicate_recipient", "multiple_recipients"],
       do: {:preflight_rejected, :recipient_count_invalid}

  defp input_error_shape(name)
       when name in [
              "unsupported_attachment",
              "unsupported_payload",
              "unsupported_provider_options",
              "oversized_json"
            ],
       do: {:serialization_failed, :invalid_envelope}

  defp effect_snapshot(schema) do
    repo = Application.fetch_env!(:mailglass, :repo)
    table = quote_identifier(schema)

    %{
      jobs: count!(repo, "SELECT count(*) FROM public.oban_jobs"),
      deliveries: count!(repo, "SELECT count(*) FROM #{table}.mailglass_deliveries"),
      events: count!(repo, "SELECT count(*) FROM #{table}.mailglass_events"),
      payloads: count!(repo, "SELECT count(*) FROM #{table}.mailglass_outbound_payloads"),
      captures: length(generated_host_call!([GeneratedHost, CaptureStore], :all)),
      renders: generated_host_call!([GeneratedHost, CaptureStore], :render_count),
      tasks: supervised_task_count()
    }
  end

  defp count!(repo, sql, params \\ []) do
    {:ok, %{rows: [[count]]}} = repo.query(sql, params)
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
      generated_host_call!([GeneratedHost, SampleMailable], :sync_message)
      |> Mailglass.Outbound.deliver()

    [sync_capture] = generated_host_call!([GeneratedHost, CaptureStore], :all)

    {:ok, async_delivery} =
      generated_host_call!([GeneratedHost, SampleMailable], :async_message)
      |> Mailglass.Outbound.deliver_later()

    inserted_job = inserted_job!(repo, async_delivery.id)

    settled =
      poll_until!(fn ->
        captures = generated_host_call!([GeneratedHost, CaptureStore], :all)

        case terminal_snapshot(repo, proof.schema, async_delivery.id, inserted_job.id, captures) do
          %{terminal?: true} = snapshot -> {:ok, snapshot}
          _ -> :retry
        end
      end)

    [^sync_capture, async_capture] = generated_host_call!([GeneratedHost, CaptureStore], :all)

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
    wait_for_endpoint!()
    proof
  end

  defp feedback!(proof) do
    start_host!(proof)
    before = feedback_snapshot(proof.schema)
    payload = postmark_payload()
    valid = http_post!("/webhooks/postmark", payload, postmark_headers(:valid))
    after_valid = feedback_snapshot(proof.schema)

    unless valid.status == 200 and valid.body_bytes == 0 and
             after_valid.webhook_events == before.webhook_events + 1 and
             after_valid.events == before.events + 1 do
      raise "generated-host signed feedback did not commit its durable facts"
    end

    forged = http_post!("/webhooks/postmark", payload, postmark_headers(:forged))
    after_forged = feedback_snapshot(proof.schema)

    unless forged.status == 401 and forged.body_bytes == 0 and after_forged == after_valid do
      raise "generated-host forged feedback had effects or an unexpected privacy response"
    end

    Map.put(proof, :feedback, %{
      valid_status: valid.status,
      valid_body_bytes: valid.body_bytes,
      forged_status: forged.status,
      forged_body_bytes: forged.body_bytes,
      ingress_event_count: after_valid.webhook_events,
      ledger_event_count: after_valid.events,
      forged_effects_zero: true
    })
  end

  defp one_click!(proof) do
    repo = Application.fetch_env!(:mailglass, :repo)
    table = quote_identifier(proof.schema)
    captures_before = length(generated_host_call!([GeneratedHost, CaptureStore], :all))

    {:ok, delivery} =
      generated_host_call!([GeneratedHost, SampleMailable], :bulk_message)
      |> Mailglass.Outbound.deliver()

    one_click_path = one_click_path!()
    first = http_post!(one_click_path, "List-Unsubscribe=One-Click", one_click_headers())
    second = http_post!(one_click_path, "List-Unsubscribe=One-Click", one_click_headers())
    {event_count, suppression_count} = one_click_pair_counts!(repo, table, delivery.id)

    unless first == %{status: 200, body_bytes: 0} and second == %{status: 200, body_bytes: 0} and
             {event_count, suppression_count} == {1, 1} do
      raise "generated-host one-click replay did not converge to one canonical pair"
    end

    matching =
      Mailglass.Outbound.deliver(
        generated_host_call!([GeneratedHost, SampleMailable], :bulk_message)
      )

    captures_after_matching = length(generated_host_call!([GeneratedHost, CaptureStore], :all))

    transactional =
      Mailglass.Outbound.deliver(
        generated_host_call!([GeneratedHost, SampleMailable], :sync_message)
      )

    unrelated =
      Mailglass.Outbound.deliver(
        generated_host_call!([GeneratedHost, SampleMailable], :operational_message)
      )

    captures_after_controls = length(generated_host_call!([GeneratedHost, CaptureStore], :all))

    unless suppressed?(matching) and captures_after_matching == captures_before + 1 and
             sendable?(transactional) and sendable?(unrelated) and
             captures_after_controls == captures_before + 3 do
      raise "generated-host one-click suppression scope widened or failed to block matching public send"
    end

    Map.put(proof, :one_click, %{
      first_status: first.status,
      first_body_bytes: first.body_bytes,
      replay_status: second.status,
      replay_body_bytes: second.body_bytes,
      canonical_event_count: event_count,
      canonical_suppression_count: suppression_count,
      matching_send: "suppressed",
      transactional_send: "sent",
      unrelated_stream_send: "sent",
      matching_capture_growth: captures_after_matching - (captures_before + 1),
      control_capture_growth: captures_after_controls - captures_after_matching
    })
  end

  defp operator_readiness!(proof) do
    start_host!(proof)
    readiness = Mailglass.ProductionPreflight.run()
    anonymous = http_get!("/ops/mail", [])

    authenticated =
      http_get!("/ops/mail", [
        {~c"authorization",
         String.to_charlist(
           "Basic " <> Base.encode64("generated-operator:generated-operator-password")
         )}
      ])

    unless readiness.status == :ready and anonymous.status == 401 and authenticated.status == 200 do
      raise "generated-host operator readiness did not enforce authentication or pass production preflight"
    end

    Map.put(proof, :operator_readiness, %{
      preflight_ready: true,
      anonymous_status: anonymous.status,
      authenticated_status: authenticated.status
    })
  end

  defp wait_for_endpoint!(attempts \\ 40)
  defp wait_for_endpoint!(0), do: raise("generated-host endpoint did not boot for HTTP proof")

  defp wait_for_endpoint!(attempts) do
    case :gen_tcp.connect(~c"127.0.0.1", endpoint_port!(), [:binary, active: false], 100) do
      {:ok, socket} ->
        :gen_tcp.close(socket)

      {:error, _} ->
        Process.sleep(25)
        wait_for_endpoint!(attempts - 1)
    end
  end

  defp http_post!(path, body, headers) when is_binary(path) and is_binary(body) do
    :inets.start()

    request =
      {~c"http://127.0.0.1:#{endpoint_port!()}#{path}", headers,
       ~c"application/x-www-form-urlencoded", body}

    case :httpc.request(:post, request, [timeout: 5_000], body_format: :binary) do
      {:ok, {{_version, status, _reason}, _headers, response_body}} ->
        %{status: status, body_bytes: byte_size(response_body)}

      {:error, reason} ->
        raise "generated-host HTTP request failed: #{inspect(reason)}"
    end
  end

  defp http_get!(path, headers) when is_binary(path) and is_list(headers) do
    :inets.start()

    case :httpc.request(
           :get,
           {~c"http://127.0.0.1:#{endpoint_port!()}#{path}", headers},
           [timeout: 5_000],
           body_format: :binary
         ) do
      {:ok, {{_version, status, _reason}, _headers, response_body}} ->
        %{status: status, body_bytes: byte_size(response_body)}

      {:error, reason} ->
        raise "generated-host HTTP request failed: #{inspect(reason)}"
    end
  end

  defp postmark_headers(:valid),
    do: [{~c"authorization", ~c"Basic Z2VuZXJhdGVkLWhvc3Q6Z2VuZXJhdGVkLWhvc3Qtc2lnbmF0dXJl"}]

  defp postmark_headers(:forged), do: [{~c"authorization", ~c"Basic Zm9yZ2VkOmZvcmdlZA=="}]
  defp one_click_headers, do: [{~c"content-type", ~c"application/x-www-form-urlencoded"}]

  defp endpoint_port! do
    GeneratedHostWeb.Endpoint
    |> apply(:config, [:http])
    |> Keyword.fetch!(:port)
  end

  defp postmark_payload do
    Jason.encode!(%{
      "RecordType" => "Delivery",
      "MessageID" => "generated-host-feedback-event",
      "Recipient" => "proof-recipient@example.test",
      "DeliveredAt" => "2026-08-03T00:00:00Z"
    })
  end

  defp feedback_snapshot(schema) do
    repo = Application.fetch_env!(:mailglass, :repo)
    table = quote_identifier(schema)

    %{
      webhook_events: count!(repo, "SELECT count(*) FROM #{table}.mailglass_webhook_events"),
      events: count!(repo, "SELECT count(*) FROM #{table}.mailglass_events")
    }
  end

  defp one_click_path! do
    generated_host_call!([GeneratedHost, CaptureStore], :all)
    |> List.last()
    |> Map.fetch!(:headers)
    |> Enum.find_value(fn
      ["List-Unsubscribe", "<" <> url] ->
        uri = URI.parse(String.trim_trailing(url, ">"))
        uri.path <> if(uri.query, do: "?" <> uri.query, else: "")

      _ ->
        nil
    end)
    |> case do
      nil -> raise "generated-host bulk delivery omitted List-Unsubscribe header"
      path -> path
    end
  end

  defp one_click_pair_counts!(repo, table, delivery_id) do
    event_count =
      count!(
        repo,
        "SELECT count(*) FROM #{table}.mailglass_events WHERE delivery_id::text = $1 AND type = 'unsubscribed'",
        [delivery_id]
      )

    suppression_count =
      count!(
        repo,
        "SELECT count(*) FROM #{table}.mailglass_suppressions WHERE source = 'compliance:one_click'"
      )

    {event_count, suppression_count}
  end

  defp suppressed?({:error, %Mailglass.SuppressedError{}}), do: true
  defp suppressed?(_), do: false
  defp sendable?({:ok, _delivery}), do: true
  defp sendable?(_), do: false

  # These modules belong to the disposable Phoenix host and are compiled only
  # after this maintainer-side journey has been copied into it. Resolve them at
  # the runtime boundary so Dialyzer does not mistake that deliberate lifecycle
  # for calls to missing modules in the mailglass project itself.
  defp generated_host_call!(module_parts, function, arguments \\ []) do
    module_parts
    |> Module.concat()
    |> apply(function, arguments)
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
