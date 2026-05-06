defmodule MailglassInbound.Internal.Replay do
  @moduledoc false

  import Ecto.Query

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord

  @matched_outcomes [:accept, :ignore, :reject, :bounce]

  @spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    execution = Keyword.get(opts, :execution, Execution)

    with %InboundRecord{} = record <- load_record(repo, inbound_record_id),
         %InboundEvidence{} = evidence <- load_evidence(repo, inbound_record_id),
         {:ok, mailbox} <- resolve_mailbox(repo, inbound_record_id),
         payload = replay_payload(record, evidence, mailbox),
         {:ok, result} <- execution.execute(payload, source: :replay) do
      {:ok, result}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
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
    message = Execution.message_from_record(record)

    %{
      status: :inserted,
      message: message,
      inbound_record: record,
      inbound_evidence: evidence,
      route: %{status: :matched, mailbox: mailbox}
    }
  end

  defp mailbox_module("Elixir." <> _rest = mailbox), do: String.to_existing_atom(mailbox)
  defp mailbox_module(mailbox), do: mailbox |> String.split(".") |> Module.concat()
end
