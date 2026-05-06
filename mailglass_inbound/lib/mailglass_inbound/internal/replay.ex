defmodule MailglassInbound.Internal.Replay do
  @moduledoc false

  import Ecto.Query

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Mailbox

  @matched_outcomes [:accept, :ignore, :reject, :bounce]

  @spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    execution_hook = Keyword.get(opts, :execution)
    inbound_records = Keyword.get(opts, :inbound_records, InboundRecords)

    with %InboundRecord{} = record <- load_record(repo, inbound_record_id),
         %InboundEvidence{} = evidence <- load_evidence(repo, inbound_record_id),
         {:ok, mailbox} <- resolve_mailbox(repo, inbound_record_id),
         payload = replay_payload(record, evidence, mailbox),
         :ok <- run_execution_hook(execution_hook, payload),
         {:ok, outcome_attrs} <- execute_mailbox(payload),
         {:ok, _run} <- inbound_records.insert_replay_run(outcome_attrs) do
      {:ok, normalize_result(outcome_attrs)}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
      {:hook_error, reason} -> {:error, reason}
    end
  end

  defp load_record(repo, inbound_record_id) do
    query =
      from(record in InboundRecord,
        where: record.id == ^inbound_record_id,
        limit: 1
      )

    repo.one(query)
  end

  defp load_evidence(repo, inbound_record_id) do
    query =
      from(evidence in InboundEvidence,
        where: evidence.inbound_record_id == ^inbound_record_id,
        limit: 1
      )

    repo.one(query)
  end

  defp resolve_mailbox(repo, inbound_record_id) do
    case latest_matched_fresh_run(repo, inbound_record_id) do
      %ExecutionRun{mailbox: mailbox} when is_binary(mailbox) and mailbox != "" ->
        {:ok, mailbox_module(mailbox)}

      nil ->
        case latest_fresh_run(repo, inbound_record_id) do
          %ExecutionRun{outcome: :no_match} ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}

          nil ->
            {:error, {:replay_mailbox_missing, %{reason: :execution_history_missing}}}

          _other ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}
        end
    end
  end

  defp latest_matched_fresh_run(repo, inbound_record_id) do
    query =
      from(run in ExecutionRun,
        where:
          run.inbound_record_id == ^inbound_record_id and
            run.source == :fresh and
            not is_nil(run.mailbox) and
            run.outcome in ^@matched_outcomes,
        order_by: [desc: run.inserted_at],
        limit: 1
      )

    repo.one(query)
  end

  defp latest_fresh_run(repo, inbound_record_id) do
    query =
      from(run in ExecutionRun,
        where: run.inbound_record_id == ^inbound_record_id and run.source == :fresh,
        order_by: [desc: run.inserted_at],
        limit: 1
      )

    repo.one(query)
  end

  defp replay_payload(record, evidence, mailbox) do
    message = build_message(record)

    %{
      status: :inserted,
      message: message,
      inbound_record: record,
      inbound_evidence: evidence,
      route: %{status: :matched, mailbox: mailbox}
    }
  end

  defp build_message(record) do
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
      attachments: record.attachments
    }
  end

  defp run_execution_hook(nil, _payload), do: :ok

  defp run_execution_hook(execution_hook, payload) do
    case execution_hook.execute(payload) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:hook_error, reason}
    end
  end

  defp execute_mailbox(%{
         route: %{status: :matched, mailbox: mailbox},
         message: %InboundMessage{} = message,
         inbound_record: inbound_record,
         inbound_evidence: inbound_evidence
       }) do
    mailbox_name = Atom.to_string(mailbox)

    attrs = %{
      tenant_id: message.tenant_id || inbound_record.tenant_id,
      inbound_record_id: inbound_record.id,
      inbound_evidence_id: inbound_evidence.id,
      source: :replay,
      mailbox: mailbox_name
    }

    {:ok, classify_mailbox_result(attrs, mailbox, message)}
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
    changeset = InboundRecords.change_replay_run(attrs)

    %{
      outcome: Ecto.Changeset.get_field(changeset, :outcome),
      outcome_reason: Ecto.Changeset.get_field(changeset, :outcome_reason),
      failure: Ecto.Changeset.get_field(changeset, :failure)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
    |> Map.new()
  end

  defp mailbox_module("Elixir." <> _rest = mailbox), do: String.to_existing_atom(mailbox)
  defp mailbox_module(mailbox), do: mailbox |> String.split(".") |> Module.concat()

  defp normalize_provider(provider) when is_binary(provider), do: String.to_atom(provider)
  defp normalize_provider(provider), do: provider
end
