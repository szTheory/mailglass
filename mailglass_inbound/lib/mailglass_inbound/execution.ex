defmodule MailglassInbound.Execution do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Mailglass.Tenancy
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Mailbox
  alias MailglassInbound.OptionalDeps.Oban, as: OptionalOban
  alias MailglassInbound.Repo

  @compile {:no_warn_undefined, [MailglassInbound.Execution.Worker]}

  defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

  @spec dispatch(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def dispatch(persisted, opts \\ [])

  def dispatch(%{status: :inserted} = persisted, opts) when is_list(opts) do
    optional_deps = Keyword.get(opts, :optional_deps, OptionalOban)
    source = Keyword.get(opts, :source, :fresh)

    case optional_deps.runner() do
      :oban ->
        worker = Keyword.get(opts, :worker, MailglassInbound.Execution.Worker)

        case optional_deps.enqueue_inbound_execution(worker, enqueue_attrs(persisted, source), opts) do
          {:ok, _job} -> {:ok, %{status: :queued, mode: :oban}}
          {:error, reason} -> {:error, reason}
        end

      :task_supervisor ->
        dispatch_task_supervisor(persisted, source, opts)
    end
  end

  def dispatch(%{status: :duplicate}, _opts), do: {:ok, %{status: :skipped}}

  @spec execute(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def execute(persisted, opts \\ [])

  def execute(%{status: :inserted} = persisted, opts) when is_list(opts) do
    records = Keyword.get(opts, :inbound_records, InboundRecords)
    source = Keyword.get(opts, :source, :fresh)
    attrs = execution_attrs(persisted, source)
    normalized_result = normalize_result(attrs)

    stop_metadata = %{
      mailbox: Map.get(attrs, :mailbox),
      outcome: Map.get(normalized_result, :outcome),
      source: source
    }

    MailglassInbound.Telemetry.execution_span(stop_metadata, fn ->
      result =
        with {:ok, _run} <- records.insert_execution_run(attrs) do
          {:ok, normalized_result}
        end

      {result, stop_metadata}
    end)
  end

  def execute(%{status: status}, _opts) when status in [:duplicate], do: {:ok, %{status: :skipped}}

  @spec load(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def load(job_args, opts \\ [])

  def load(
        %{
          "inbound_record_id" => inbound_record_id,
          "inbound_evidence_id" => inbound_evidence_id,
          "route_status" => route_status,
          "mailglass_tenant_id" => tenant_id
        } = job_args,
        opts
      )
      when is_binary(inbound_record_id) and is_binary(inbound_evidence_id) and
             is_binary(route_status) and is_binary(tenant_id) and tenant_id != "" and
             is_list(opts) do
    repo = Keyword.get(opts, :repo, Repo)

    with %InboundRecord{} = record <- load_record(repo, inbound_record_id, tenant_id),
         %InboundEvidence{} = evidence <-
           load_evidence(repo, inbound_evidence_id, inbound_record_id, tenant_id),
         {:ok, route} <- decode_route(route_status, Map.get(job_args, "mailbox")) do
      {:ok,
       %{
         status: :inserted,
         message: message_from_record(record),
         inbound_record: record,
         inbound_evidence: evidence,
         route: route
       }}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  def load(_job_args, _opts), do: {:error, :invalid_job_args}

  defp load_record(repo, inbound_record_id, tenant_id) do
    from(record in InboundRecord,
      where: record.id == ^inbound_record_id and record.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp load_evidence(repo, inbound_evidence_id, inbound_record_id, tenant_id) do
    from(evidence in InboundEvidence,
      where:
        evidence.id == ^inbound_evidence_id and
          evidence.inbound_record_id == ^inbound_record_id and
          evidence.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  @spec message_from_record(InboundRecord.t()) :: InboundMessage.t()
  def message_from_record(record) do
    %InboundMessage{
      tenant_id: record.tenant_id,
      provider: normalize_provider(record.provider),
      provider_message_id: record.provider_message_id,
      message_id: record.message_id,
      envelope_recipient: record.envelope_recipient,
      from: record.from,
      to: record.to,
      cc: record.cc,
      bcc: record.bcc,
      reply_to: record.reply_to,
      subject: record.subject,
      headers: record.headers,
      sent_at: record.sent_at,
      received_at: record.received_at,
      text_body: record.text_body,
      html_body: record.html_body,
      attachments: record.attachments,
      # IOPS-05: the single projection point — the persisted column becomes the
      # framework-owned typed signal the adopter reads. A pre-migration row reads
      # the DB default `false`, so this never produces nil/KeyError.
      signals: %MailglassInbound.InboundMessage.Signals{
        suppression_flagged: record.suppression_flagged
      }
    }
  end

  defp dispatch_task_supervisor(persisted, source, opts) do
    task_supervisor = Keyword.get(opts, :task_supervisor, Task.Supervisor)
    task_supervisor_name = Keyword.get(opts, :task_supervisor_name, MailglassInbound.TaskSupervisor)
    execution = Keyword.get(opts, :execution, __MODULE__)
    execution_opts = execution_opts(opts, source)

    _ = MailglassInbound.Application.maybe_warn_fallback_mode(opts)

    try do
      case task_supervisor.start_child(task_supervisor_name, fn ->
             _ = execution.execute(persisted, execution_opts)
             :ok
           end) do
        {:ok, _pid} ->
          {:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}}

        :ok ->
          {:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}}

        {:error, reason} ->
          {:error, dispatch_unavailable_error(reason)}

        _other ->
          {:error, dispatch_unavailable_error(:start_child_failed)}
      end
    rescue
      _error -> {:error, dispatch_unavailable_error(:supervisor_unavailable)}
    catch
      :exit, _reason -> {:error, dispatch_unavailable_error(:supervisor_unavailable)}
    end
  end

  defp dispatch_unavailable_error(reason) do
    Mailglass.SendError.new(:dispatch_unavailable,
      retry_class: :transient,
      context: %{reason_class: dispatch_reason_class(reason)}
    )
  end

  defp dispatch_reason_class(:max_children), do: :capacity_reached
  defp dispatch_reason_class(:noproc), do: :supervisor_unavailable
  defp dispatch_reason_class(:supervisor_unavailable), do: :supervisor_unavailable
  defp dispatch_reason_class(_reason), do: :start_child_failed

  defp enqueue_attrs(
         %{
           route: route,
           message: %InboundMessage{} = message,
           inbound_record: %{id: inbound_record_id},
           inbound_evidence: %{id: inbound_evidence_id}
         },
         source
       ) do
    %{
      "inbound_record_id" => inbound_record_id,
      "inbound_evidence_id" => inbound_evidence_id,
      "route_status" => route_status(route),
      "mailbox" => route_mailbox(route),
      "source" => Atom.to_string(source),
      "mailglass_tenant_id" => message.tenant_id
    }
  end

  defp execution_opts(opts, source) do
    []
    |> Keyword.put(:source, source)
    |> maybe_put(:inbound_records, Keyword.get(opts, :inbound_records))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp execution_attrs(
         %{
           route: %{status: :no_match},
           message: %InboundMessage{} = message,
           inbound_record: inbound_record,
           inbound_evidence: inbound_evidence
         },
         source
       ) do
    %{
      tenant_id: message.tenant_id || inbound_record.tenant_id,
      inbound_record_id: inbound_record.id,
      inbound_evidence_id: inbound_evidence.id,
      source: source,
      mailbox: nil,
      mailbox_outcome: :no_match
    }
  end

  defp execution_attrs(
         %{
           route: %{status: :matched, mailbox: mailbox},
           message: %InboundMessage{} = message,
           inbound_record: inbound_record,
           inbound_evidence: inbound_evidence
         },
         source
       ) do
    mailbox_name = Atom.to_string(mailbox)

    %{
      tenant_id: message.tenant_id || inbound_record.tenant_id,
      inbound_record_id: inbound_record.id,
      inbound_evidence_id: inbound_evidence.id,
      source: source,
      mailbox: mailbox_name
    }
    |> classify_mailbox_result(mailbox, message)
  end

  defp classify_mailbox_result(attrs, mailbox, message) do
    try do
      outcome = mailbox.process(message)

      if Mailbox.valid_outcome?(outcome) do
        Map.put(attrs, :mailbox_outcome, outcome)
      else
        Map.put(attrs, :execution_failure, %{kind: :invalid_return, value: inspect(outcome)})
      end
    rescue
      error ->
        Map.put(attrs, :execution_failure, %{
          kind: :error,
          error: inspect(error),
          reason: Exception.message(error)
        })
    catch
      :exit, reason ->
        Map.put(attrs, :execution_failure, %{kind: :exit, reason: inspect(reason)})

      :throw, reason ->
        Map.put(attrs, :execution_failure, %{kind: :throw, reason: inspect(reason)})
    end
  end

  defp normalize_result(attrs) do
    changeset = InboundRecords.change_execution_run(attrs)

    %{
      outcome: Ecto.Changeset.get_field(changeset, :outcome),
      outcome_reason: Ecto.Changeset.get_field(changeset, :outcome_reason),
      failure: Ecto.Changeset.get_field(changeset, :failure)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
    |> Map.new()
  end

  defp decode_route("no_match", _mailbox), do: {:ok, %{status: :no_match}}

  defp decode_route("matched", mailbox) when is_binary(mailbox) and mailbox != "" do
    {:ok, %{status: :matched, mailbox: mailbox_module(mailbox)}}
  rescue
    ArgumentError -> {:error, :invalid_job_args}
  end

  defp decode_route(_route_status, _mailbox), do: {:error, :invalid_job_args}

  defp mailbox_module("Elixir." <> _rest = mailbox), do: String.to_existing_atom(mailbox)

  defp mailbox_module(mailbox) when is_binary(mailbox),
    do: String.to_existing_atom("Elixir." <> mailbox)

  defp route_status(%{status: status}) when is_atom(status), do: Atom.to_string(status)
  defp route_status(_route), do: "unknown"

  defp route_mailbox(%{status: :matched, mailbox: mailbox}) when is_atom(mailbox) do
    Atom.to_string(mailbox)
  end

  defp route_mailbox(_route), do: nil

  defp normalize_provider(provider) when is_binary(provider), do: String.to_atom(provider)
  defp normalize_provider(provider), do: provider
end
