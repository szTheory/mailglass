defmodule MailglassInbound.Execution do
  @moduledoc false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.Mailbox

  @spec execute(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def execute(persisted, opts \\ [])

  def execute(%{status: :inserted} = persisted, opts) when is_list(opts) do
    records = Keyword.get(opts, :inbound_records, InboundRecords)
    attrs = execution_attrs(persisted)
    normalized_result = normalize_result(attrs)

    with {:ok, _run} <- records.insert_execution_run(attrs) do
      {:ok, normalized_result}
    end
  end

  def execute(%{status: status}, _opts) when status in [:duplicate], do: {:ok, %{status: :skipped}}

  defp execution_attrs(%{
         route: %{status: :no_match},
         message: %InboundMessage{} = message,
         inbound_record: inbound_record,
         inbound_evidence: inbound_evidence
       }) do
    %{
      tenant_id: message.tenant_id || inbound_record.tenant_id,
      inbound_record_id: inbound_record.id,
      inbound_evidence_id: inbound_evidence.id,
      source: :fresh,
      mailbox: nil,
      mailbox_outcome: :no_match
    }
  end

  defp execution_attrs(%{
         route: %{status: :matched, mailbox: mailbox},
         message: %InboundMessage{} = message,
         inbound_record: inbound_record,
         inbound_evidence: inbound_evidence
       }) do
    mailbox_name = Atom.to_string(mailbox)

    %{
      tenant_id: message.tenant_id || inbound_record.tenant_id,
      inbound_record_id: inbound_record.id,
      inbound_evidence_id: inbound_evidence.id,
      source: :fresh,
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
end
