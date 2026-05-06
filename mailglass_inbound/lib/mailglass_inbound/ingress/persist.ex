defmodule MailglassInbound.Ingress.Persist do
  @moduledoc false

  import Ecto.Query

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Router.Matcher

  @type handoff_t :: %{
          required(:tenant_id) => String.t(),
          required(:provider) => atom() | String.t(),
          required(:message) => InboundMessage.t(),
          required(:evidence) => map()
        }

  @spec persist(handoff_t(), keyword()) :: {:ok, map()} | {:error, term()}
  def persist(%{tenant_id: tenant_id, provider: provider, message: %InboundMessage{} = message} = handoff, opts)
      when is_binary(tenant_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)

    result =
      repo.transact(fn ->
        case load_duplicate(repo, tenant_id, provider, message.provider_message_id) do
          %InboundRecord{} = record ->
            {:ok,
             %{
               status: :duplicate,
               inbound_record: record,
               inbound_evidence: nil
             }}

          nil ->
            with {:ok, record} <- insert_record(repo, tenant_id, provider, message),
                 {:ok, evidence} <- insert_evidence(repo, tenant_id, provider, record, handoff.evidence) do
              {:ok,
               %{
                 status: :inserted,
                 inbound_record: record,
                 inbound_evidence: evidence
               }}
            end
        end
      end)

    case result do
      {:ok, payload} ->
        route_result = route_compatibility(message, opts)

        {:ok,
         payload
         |> Map.put(:route, route_result)
         |> Map.put(:message, message)}

      other ->
        other
    end
  end

  defp load_duplicate(_repo, _tenant_id, _provider, nil), do: nil

  defp load_duplicate(repo, tenant_id, provider, provider_message_id) do
    provider = to_string(provider)

    query =
      from(record in InboundRecord,
        where:
          record.tenant_id == ^tenant_id and
            record.provider == ^provider and
            record.provider_message_id == ^provider_message_id,
        limit: 1
      )

    repo.one(query)
  end

  defp insert_record(repo, tenant_id, provider, message) do
    attrs = %{
      tenant_id: tenant_id,
      provider: to_string(provider),
      provider_message_id: message.provider_message_id,
      message_id: message.message_id,
      envelope_recipient: message.envelope_recipient,
      from: message.from,
      to: message.to,
      cc: message.cc,
      bcc: message.bcc,
      reply_to: message.reply_to,
      subject: message.subject,
      headers: message.headers,
      sent_at: message.sent_at,
      received_at: message.received_at || DateTime.utc_now(),
      text_body: message.text_body,
      html_body: message.html_body,
      attachments: message.attachments
    }

    changeset = InboundRecords.change_inbound_record(attrs)

    case repo.insert(changeset) do
      {:ok, record} ->
        {:ok, record}

      {:error, changeset} = error ->
        if duplicate_constraint?(changeset) do
          case load_duplicate(repo, tenant_id, provider, message.provider_message_id) do
            %InboundRecord{} = record -> {:ok, record}
            nil -> error
          end
        else
          error
        end
    end
  end

  defp insert_evidence(repo, tenant_id, provider, record, evidence) do
    attrs = %{
      tenant_id: tenant_id,
      provider: to_string(provider),
      inbound_record_id: record.id,
      raw_payload: Map.get(evidence, :raw_payload, %{}),
      raw_headers: Map.get(evidence, :raw_headers, %{}),
      raw_mime: Map.get(evidence, :raw_mime),
      verification_facts: Map.get(evidence, :verification_facts, %{}),
      parse_warnings: Map.get(evidence, :parse_warnings, %{}),
      attachment_blobs: Map.get(evidence, :attachment_blobs, %{})
    }

    attrs
    |> InboundRecords.change_inbound_evidence()
    |> repo.insert()
  end

  defp route_compatibility(message, opts) do
    routes =
      cond do
        Keyword.has_key?(opts, :routes) -> Keyword.fetch!(opts, :routes)
        Keyword.has_key?(opts, :router) -> Keyword.fetch!(opts, :router).__mailglass_inbound_routes__()
        true -> []
      end

    case Matcher.match(routes, message) do
      {:ok, route} -> %{status: :matched, mailbox: route.mailbox}
      :no_match -> %{status: :no_match}
    end
  end

  defp duplicate_constraint?(changeset) do
    Enum.any?(changeset.errors, fn
      {:provider_message_id, {_msg, opts}} -> opts[:constraint_name] == "mailglass_inbound_records_postmark_idempotency_idx"
      _ -> false
    end)
  end
end
